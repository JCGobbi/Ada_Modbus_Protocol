with Ada.Real_Time;     use Ada.Real_Time;

with Serial_IO;         use Serial_IO;
with MBus_Frame.IO;     use MBus_Frame.IO;
with MBus_Frame.Errors; use MBus_Frame.Errors;
                        use MBus_Frame;
with Checking;          use Checking;

package body MBus_Functions is

   ---------------------
   -- MBus_Initialize --
   ---------------------

   procedure MBus_Initialize (MB_Mode    : MBus_Modes;
                              MB_Address : MBus_Server_Address;
                              MB_Port    : in out Serial_Port;
                              MB_Bps     : Baud_Rates;
                              MB_Parity  : Parities)
   is
      Max_Char_Timeout  : Time_Span;
      Min_Frame_Timeout : Time_Span;
      Response_Timeout  : Time_Span;
   begin
      -- The modbus protocol RTU, ASCII and TCP modes of operation are defined
      -- at MBus.ads. This mode may be changed at any time attending client
      -- solicitations configuring the buffer operation mode.
      MBus_Set_Mode (Outgoing, MB_Mode);
      MBus_Set_Mode (Incoming, MB_Mode);

      -- The Server_Address is a global variable defined at MBus.ads.
      Server_Address := MB_Address;

      -- The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
      -- serial channel are defined at Serial_IO.ads. This mode only affects the
      -- reception of data choosing the end of frame mode in the Get procedure at
      -- Serial_IO.Blocking.
      -- Serial for Modbus protocol
      Initialize (MB_Port);
      Configure (MB_Port,
                 Baud_Rate => MB_Bps,
                 Parity    => MB_Parity);

      case MB_Mode is
         when RTU =>
            Set_Serial_Mode (MB_Port, MBus_RTU);
         when ASC =>
            Set_Serial_Mode (MB_Port, MBus_ASCII);
         when TCP =>
            null;
      end case;

      -- Set the timeout for maximum inter-character time for modbus RTU operation.
      Max_Char_Timeout := Inter_Time (Bps => MB_Bps, Inter_Char => 15);
      Set_InterChar_Timeout (MB_Port, Max_Char_Timeout);

      -- Set the timeout for minimum inter-frame time for modbus RTU operation.
      -- This time must consider the inter-character elapsed time above.
      Min_Frame_Timeout := Inter_Time (Bps => MB_Bps, Inter_Char => 20);
      Set_InterFrame_Timeout (MB_Port, Min_Frame_Timeout);

      -- Set the timeout for response time for modbus RTU and ASCII operation.
      Response_Timeout := Milliseconds (2_000);
      Set_Response_Timeout (MB_Port, Response_Timeout);
   
   end MBus_Initialize;

   -----------------
   -- Write_Frame --
   -----------------

   procedure Write_Frame (Msg            : in out Message;
                          Server_Address : MBus_Server_Address;
                          Function_Code  : UInt8;
                          Data_Chain     : Block_8)
   is
      Check : UInt16;
   begin
      Await_Transmission_Complete (Msg); -- outgoing buffer
      Clear (Msg);
      -- Start writting modbus buffer
      MBus_Set_Address (Msg, Server_Address);
      MBus_Set_Function_Code (Msg, Function_Code);

      -- Test if data is not empty
      if Data_Chain'Length >= 1 then
         for i in 1 .. Data_Chain'Length loop
            MBus_Append_Data (Msg, Data_Chain(i));
         end loop;
      end if;

      -- Calculate the actual CRC
      case MBus_Get_Mode (Msg) is
         when RTU =>
            Check := 16#FFFF#;
            for i in 1 .. Get_Length (Msg) loop
               Update_CRC (Get_Content_At (Msg, i), Check);
            end loop;
         when ASC =>
            Check := 16#0000#;
            for i in 2 .. Get_Length (Msg) loop
               Check := Check + UInt16(Get_Content_At (Msg, i));
            end loop;
            Check := (16#00FF# - (Check and 16#00FF#)) - 1; -- 2's complement
         when TCP =>
            null;
      end case;
      -- Set checking in Msg
      MBus_Set_Checking (Msg, Check);

      Signal_Reception_Complete (Msg); -- modbus outgoing buffer

   end Write_Frame;
   
   ---------------------
   -- WriteSend_Frame --
   ---------------------

   procedure WriteSend_Frame (Msg            : in out Message;
                              Server_Address : MBus_Server_Address;
                              Function_Code  : UInt8;
                              Data_Chain     : Block_8)
   is
      Check : UInt16;
   begin
      Await_Transmission_Complete (Msg); -- outgoing buffer
      Clear (Msg);
      -- Start writting modbus buffer
      MBus_Set_Address (Msg, Server_Address);
      MBus_Set_Function_Code (Msg, Function_Code);

      -- Test if data is not empty
      if Data_Chain'Length >= 1 then
         for i in 1 .. Data_Chain'Length loop
            MBus_Append_Data (Msg, Data_Chain(i));
         end loop;
      end if;

      -- Calculate the actual CRC
      case MBus_Get_Mode (Msg) is
         when RTU =>
            Check := 16#FFFF#;
            for i in 1 .. Get_Length (Msg) loop
               Update_CRC (Get_Content_At (Msg, i), Check);
            end loop;
         when ASC =>
            Check := 16#0000#;
            for i in 2 .. Get_Length (Msg) loop
               Check := Check + UInt16(Get_Content_At (Msg, i));
            end loop;
            Check := (16#00FF# - (Check and 16#00FF#)) - 1; -- 2's complement
         when TCP =>
            null;
      end case;
      -- Set checking in Msg
      MBus_Set_Checking (Msg, Check);

      Signal_Reception_Complete (Msg); -- modbus outgoing buffer

      -- Send the frame from the MBus_Outcoming buffer to the Serial_Outcoming buffer,
      -- and to serial channel.
      Send_Frame (This => MBus_Port, Msg => Msg);
      
   end WriteSend_Frame;
   
   ----------------
   -- Read_Frame --
   ----------------

   procedure Read_Frame (Msg            : in out Message;
                         Server_Address : MBus_Server_Address;
                         Function_Code  : UInt8;
                         Data_Chain     : in out Block_8)
   is
   begin
      Await_Reception_Complete (Msg); -- modbus incoming buffer

      -- Process errors from the modbus incoming buffer frame
      Process_Error_Status (This => Msg,
                            Server_Address => Server_Address,
                            Function_Code => Function_Code);

      if not MBus_Has_Error (Msg, Invalid_Address) xor
         not MBus_Has_Error (Msg, Invalid_Function_Code) then
         
         -- Test if data is not empty
         case MBus_Get_Mode (Msg) is
            when RTU =>
               if Get_Length (Msg) > 4 then
                  -- The buffer has 1 address + 1 function + data + 2 CRC bytes.
                  -- MBus_Get_Data_At takes a byte starting at 5th position of buffer.
                  for i in 1 .. (Get_Length (Msg) - 6) loop
                    Data_Chain(i) := Get_Content_At (Msg, i + 4);
                  end loop;               
               end if;
            when ASC =>
               if Get_Length (Msg) > 9 then
                  -- The buffer has 1 start + 2 address + 2 function + data + 2 LRC + 2 end chars.
                  -- Data has an even number of chars.
                  -- MBus_Get_Data_At takes a pair of chars starting at 6th position of buffer.
                  for i in 1 .. ((Get_Length (Msg) - 11) / 2) loop
                     Data_Chain(i) := MBus_Get_Data_At (Msg, i + 2);
                  end loop;               
               end if;
            when TCP =>
               null;
         end case;
      end if;

      -- Save errors in the last position of Data
      Data_Chain(Data_Chain'Last) := UInt8(MBus_Errors_Detected (Msg));
      
      Signal_Transmission_Complete (Msg); -- incoming buffer

   end Read_Frame;

   -----------------------
   -- ReadReceive_Frame --
   -----------------------

   procedure ReadReceive_Frame (Msg            : in out Message;
                                Server_Address : MBus_Server_Address;
                                Function_Code  : UInt8;
                                Data_Chain     : in out Block_8)
   is
   begin
      -- Before doing this, we must get the modbus frame from the serial channel
      -- to the Incoming buffer.
      Receive_Frame (This => MBus_Port, Msg => Msg);
      Await_Reception_Complete (Msg); -- modbus incoming buffer

      -- Process errors from the modbus incoming buffer frame
      Process_Error_Status (This => Msg,
                            Server_Address => Server_Address,
                            Function_Code => Function_Code);

      if not MBus_Has_Error (Msg, Invalid_Address) xor
         not MBus_Has_Error (Msg, Invalid_Function_Code) then
         
         -- Test if data is not empty
         case MBus_Get_Mode (Msg) is
            when RTU =>
               if Get_Length (Msg) > 6 then
                  -- The buffer has 2 address + 2 function + data + 2 CRC bytes.
                  -- MBus_Get_Data_At takes a byte starting at 5th position of buffer.
                  for i in 1 .. (Get_Length (Msg) - 6) loop
                    Data_Chain(i) := Get_Content_At (Msg, i + 4);
                  end loop;               
               end if;
            when ASC =>
               if Get_Length (Msg) > 9 then
                  -- The buffer has 1 start + 2 address + 2 function + data + 2 LRC + 2 end chars.
                  -- Data has an even number of chars.
                  -- MBus_Get_Data_At takes a pair of chars starting at 6th position of buffer.
                  for i in 1 .. ((Get_Length (Msg) - 11) / 2) loop
                     Data_Chain(i) := MBus_Get_Data_At (Msg, i + 2);
                  end loop;               
               end if;
            when TCP =>
               null;
         end case;
      end if;

      -- Save errors in the last position of Data
      Data_Chain(Data_Chain'Last) := UInt8(MBus_Errors_Detected (Msg));
      
      Signal_Transmission_Complete (Msg); -- incoming buffer

   end ReadReceive_Frame;

end MBus_Functions;
