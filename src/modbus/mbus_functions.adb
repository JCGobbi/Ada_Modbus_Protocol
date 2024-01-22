with MBus_Frame.Errors; use MBus_Frame.Errors, MBus_Frame;
with Checking;          use Checking;

package body MBus_Functions is

   -----------------
   -- Write_Frame --
   -----------------

   procedure Write_Frame (Msg            : in out Message;
                          Server_Address : MBus_Server_Address;
                          Function_Code  : UInt8;
                          Data_Chain     : UInt8_Array)
   is
      Check : UInt16;
   begin
      Await_Transmission_Complete (Msg); --  modbus outgoing buffer
      Clear (Msg);
      --  Start writting modbus buffer
      MBus_Set_Address (Msg, Server_Address);
      MBus_Set_Function_Code (Msg, Function_Code);

      --  Test if data is not empty
      if Data_Chain'Length > 0 then
         for i in 1 .. Data_Chain'Length loop
            MBus_Append_Data (Msg, Data_Chain (i));
         end loop;
      end if;

      --  Calculate the actual CRC
      case MBus_Get_Mode (Msg) is
         when RTU =>
            Check := 16#FFFF#;
            for i in 1 .. Get_Length (Msg) loop
               Update_CRC (Get_Content_At (Msg, i), Check);
            end loop;
         when ASC =>
            Check := 16#0000#;
            --  The first character is ':'.
            for i in 2 .. Get_Length (Msg) loop
               Check := Check + UInt16 (Get_Content_At (Msg, i));
            end loop;
            Check := (16#00FF# - (Check and 16#00FF#)) - 1; -- 2's complement
         when TCP =>
            null;
      end case;
      --  Set checking in Msg
      MBus_Set_Checking (Msg, Check);

      Signal_Reception_Complete (Msg); --  modbus outgoing buffer

   end Write_Frame;

   ----------------
   -- Read_Frame --
   ----------------

   procedure Read_Frame (Msg            : in out Message;
                         Server_Address : MBus_Server_Address;
                         Function_Code  : UInt8;
                         Data_Chain     : in out UInt8_Array)
   is
   begin
      Await_Reception_Complete (Msg); -- modbus incoming buffer

      --  Process errors from the modbus incoming buffer frame.
      Process_Error_Status (Msg,
                            Server_Address => Server_Address,
                            Function_Code => Function_Code);

      if not MBus_Has_Error (Msg, Invalid_Address) xor
         not MBus_Has_Error (Msg, Invalid_Function_Code)
      then
         --  Test if message stack is not empty and read its data.
         case MBus_Get_Mode (Msg) is
            when RTU =>
               if Get_Length (Msg) > 4 then
                  --  The buffer has 1 address + 1 function + data + 2 CRC bytes.
                  --  MBus_Get_Data_At takes a byte starting at 3rd position of
                  --  buffer.
                  for i in 1 .. (Get_Length (Msg) - 4) loop
                     Data_Chain (i) := Get_Content_At (Msg, i + 2);
                  end loop;
               end if;
            when ASC =>
               if Get_Length (Msg) > 9 then
                  --  The buffer has 1 start + 2 address + 2 function + data +
                  --  2 LRC + 2 end chars. Data has an even number of chars.
                  --  MBus_Get_Data_At takes a pair of chars starting at 6th
                  --  position of buffer.
                  for i in 1 .. ((Get_Length (Msg) - 9) / 2) loop
                     Data_Chain (i) := MBus_Get_Data_At (Msg, i + 2);
                  end loop;
               end if;
            when TCP =>
               null;
         end case;
      end if;

      --  Save errors in the last position of Data
      Data_Chain (Data_Chain'Last) := UInt8 (MBus_Errors_Detected (Msg));

      Signal_Transmission_Complete (Msg); --  modbus incoming buffer

   end Read_Frame;

end MBus_Functions;
