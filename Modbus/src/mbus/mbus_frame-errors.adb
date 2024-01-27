with Checking; use Checking;

package body MBus_Frame.Errors is

   --------------------------
   -- Process_Error_Status --
   --------------------------

   --  Test if received MODBUS frame in the modbus incoming buffer has errors and set
   --  Error_Status into its buffer.
   procedure Process_Error_Status (This : in out Message;
                                   Server_Address : MBus_Server_Address;
                                   Function_Code  : UInt8) is
      Check : UInt16;
   begin
      --  See if we're getting ':' start char and CR and LF end chars in modbus ASCII
      if MBus_Get_Mode (This) = ASC then
         if Get_Content_At (This, 1) /= Character'Pos (':') or -- ':' character
             Get_Content_At (This, Get_Length (This) - 1) /= 16#0D# or -- CR character
             Get_Content_At (This, Get_Length (This)) /= 16#0A# -- LF character
         then
            MBus_Note_Error (This, Invalid_Frame);
            --  Dischard the frame
         end if;
      end if;

      --  See if we're getting the correct server or broadcast address
      if (MBus_Get_Address (This) /= Server_Address) and (MBus_Get_Address (This) /= 0) then
         MBus_Note_Error (This, Invalid_Address);
         --  Dischard the frame
      end if;

      --  See if response from client is for the correct exception function code.
      --  If the server encounters some type of error, it sends to the client the
      --  function code + 16#80# and receives from the client this same error code
      --  with instructions.
      if MBus_Get_Function_Code (This) /= Function_Code then
         MBus_Note_Error (This, Invalid_Function_Code);
         --  Dischard the frame
      end if;

--      if (Get_Length (This) = 0) then
--         -- There is no comming modbus message
--         MBus_Note_Error (This, Frame_Empty);
--      end if;

      --  Calculate the actual CRC
      case MBus_Get_Mode (This) is
         when RTU =>
            Check := 16#FFFF#;
            for i in 1 .. (Get_Length (This) - 2) loop
               Update_CRC (Get_Content_At (This, i), Check);
            end loop;
         when ASC =>
            Check := 16#0000#;
            for i in 2 .. (Get_Length (This) - 4) loop
               Check := Check + UInt16 (Get_Content_At (This, i));
            end loop;
            Check := (16#00FF# - (Check and 16#00FF#)) - 1;
         when TCP =>
            null;
      end case;

      --  See if CRC or LRC is correct
      if Check /= MBus_Get_Checking (This) then
         MBus_Note_Error (This, Invalid_Checking);
         --  Dischard the frame
      end if;

   end Process_Error_Status;

   ----------------------------
   -- Process_Received_Errors --
   ----------------------------

   --  Process errors of the received MODBUS frame in the Error_Status of the modbus
   --  incoming buffer.
   procedure Process_Received_Errors (This : in out Message) is
   begin

      if MBus_Has_Error (This, Invalid_Address) then
         null;
      end if;

      if MBus_Has_Error (This, Invalid_Function_Code) then
         null;
      end if;

      if MBus_Has_Error (This, Invalid_Checking) then
         null;
      end if;

      if MBus_Has_Error (This, Invalid_Parity) then
         null;
      end if;

      if MBus_Has_Error (This, InterChar_Timed_Out) then
         null;
      end if;

      if MBus_Has_Error (This, InterFrame_Timed_Out) then
         null;
      end if;

      if MBus_Has_Error (This, Response_Timed_Out) then
         null;
      end if;

      if MBus_Has_Error (This, Invalid_Frame) then
         null;
      end if;

      MBus_Clear_Errors (This);

   end Process_Received_Errors;

end MBus_Frame.Errors;
