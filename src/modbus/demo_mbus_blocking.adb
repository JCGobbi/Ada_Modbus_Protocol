with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with MBus_Task; pragma Unreferenced (MBus_Task);

with Ada.Real_Time;         use Ada.Real_Time;
with HAL;                   use HAL;
with STM32.USARTS;          use STM32.USARTS;

with Peripherals_Blocking;  use Peripherals_Blocking;
with Serial_IO.Blocking;    use Serial_IO.Blocking;
                            use Serial_IO;
with Message_Buffers;       use Message_Buffers;

with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO;
with MBus_Frame.Errors;     use MBus_Frame.Errors;
                            use MBus_Frame;

with MBus_Functions.Server; use MBus_Functions.Server;
                            use MBus_Functions;


procedure Demo_MBus_Blocking is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   MBus_Bps : constant Baud_Rates := 9_600;
   Term_Bps : constant Baud_Rates := 115_200;

   ------------------------------------------------
   -- The serial channel for MODBUS comunication --
   ------------------------------------------------

   -- For testing purposes, we may use the modbus protocol with each one
   -- of the two serial channels MBus_COM or Term_COM, setting it up inside
   -- MBus_Functions.ads:
   -- MBus_Port : Serial_Port renames Term_COM;

   -----------------------------------------
   -- Buffers for Terminal Serial Channel --
   -----------------------------------------

   Term_Incoming : aliased Message (Physical_Size => 1024);  -- arbitrary size
   Term_Outgoing : aliased Message (Physical_Size => 1024);  -- arbitrary size

   
   -- Set Function_Code
   Function_Code : constant MBus_Normal_Function_Code := 16#01#;
   
   ------------------------------
   -- Procedures and functions --
   ------------------------------

   procedure Send (This : String);
   -- Translate a string into a sequence of ASCII addresses and send the frame.
     
   procedure Send (This : String) is
      Pos : UInt8;
      CharPos : UInt8_Array (1 .. This'Length);
   begin
      for i in This'Range loop
         Pos := Character'Pos (This(i));
         CharPos (i) := Pos;
      end loop;      
      Await_Transmission_Complete (Term_Outgoing); -- outgoing buffer
      Set_Content (Term_Outgoing, To => CharPos);
      Signal_Reception_Complete (Term_Outgoing); -- outgoing buffer
      Await_Reception_Complete (Term_Outgoing); -- outgoing buffer
      Put (Term_COM, Term_Outgoing'Unchecked_Access);
      -- No need to wait for it here because the Put won't return until the
      -- message has been sent.
      Signal_Transmission_Complete (Term_Outgoing); -- outgoing buffer
   end Send;

begin
   -- The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
   -- serial channel are defined at Serial_IO.ads. This mode only affects the
   -- reception of data choosing the end of frame mode in the Get procedure at
   -- Serial_IO.Blocking.

   -- Configuration for Terminal console
   Initialize (Term_COM);
   Configure (Term_COM, Baud_Rate => Term_Bps, Parity => No_Parity);
   Set_Serial_Mode (Term_COM, Terminal);

   -- Configuration for modbus communication
   -- The Server_Address is a global variable defined at MBus.ads. Here we
   -- superpose the default address 1.
   MBus_Initialize (MB_Mode    => RTU,
                    MB_Address => 1,
                    MB_Port    => MBus_COM,
                    MB_Bps     => MBus_Bps,
                    MB_Parity  => Even_Parity);

   -- Set Server_Address
   Server_Address := 16#0A#;

   -- Start with both incoming and outgoing buffers empty,
   -- so there is no need to wait.
   Signal_Transmission_Complete (Term_Outgoing); -- outgoing buffer
   Signal_Transmission_Complete (Term_Incoming); -- incoming buffer

   Signal_Transmission_Complete (Outgoing); -- outgoing buffer
   
   Set_Terminator (Term_Incoming, To => ASCII.CR);

   Send ("Test terminal monitoring and modbus comunication in different"
         & " serial channels." & ASCII.CR & ASCII.LF);
   -- This test waits the receiving of a frame in the modbus serial channel,
   -- so you will need a modbus client connected to MBus_COM port.
   Send ("The terminal will only monitor the receipt of a modbus stream as"
         & " responding to a client request." & ASCII.CR & ASCII.LF);

   loop
      Send ("Choose the number that corresponds to a modbus RTU or"
            & " ASCII test protocol." & ASCII.CR & ASCII.LF);
      Send ("1 - Modbus RTU." & ASCII.CR & ASCII.LF);
      Send ("2 - Modbus ASCII." & ASCII.CR & ASCII.LF);
   
      Signal_Transmission_Complete (Term_Incoming); -- incoming buffer
      Receive_Frame (Term_COM, Term_Incoming);
      if Term_Incoming.MBus_Has_Error (Response_Timed_Out) then
         Send ("No valid option, please reset the board." & ASCII.CR & ASCII.LF);
      end if;

      Await_Reception_Complete (Term_Incoming); -- incoming buffer

      if (Get_Content_At (Term_Incoming, 1) = Character'Pos(Term_Incoming.Get_Terminator))
          or ((Get_Content_At (Term_Incoming, 1) /= Character'Pos('1'))
          and (Get_Content_At (Term_Incoming, 1) /= Character'Pos('2')))
      then
         Send ("No valid option, please try again." & ASCII.CR & ASCII.LF);
      else
         if Get_Content_At (Term_Incoming, 1) = Character'Pos('1') then
            Send ("Option 1 - Modbus RTU protocol." & ASCII.CR & ASCII.LF);
            MBus_Set_Mode (Incoming, RTU);
            MBus_Set_Mode (Outgoing, RTU);
            Set_Serial_Mode (MBus_COM, MBus_RTU);
         elsif Get_Content_At (Term_Incoming, 1) = Character'Pos('2') then
            Send ("Option 2 - Modbus ASCII protocol." & ASCII.CR & ASCII.LF);
            MBus_Set_Mode (Incoming, ASC);
            MBus_Set_Mode (Outgoing, ASC);
            Set_Serial_Mode (MBus_COM, MBus_ASCII);
         end if;

         Send ("Send a response to a Read_Discrete_Inputs with:"
               & ASCII.CR & ASCII.LF);
         Send ("Server_Address = 10, Function_Code = 15, Byte_Count = 08"
               & ASCII.CR & ASCII.LF);
         Send ("and Input_Status = (52, 175, 194, 147, 84, 103, 184, 224)."
               & ASCII.CR & ASCII.LF);

         -- Wait for the transmission of the modbus frame
         Send ("Waiting for a modbus ADU message from the client... "
               & ASCII.CR & ASCII.LF);
         Signal_Transmission_Complete (Incoming); -- incoming buffer
         -- Here the MBus_Task receives the autorization to receive the modbus
         -- frame, because the Receive_Frame task waits for this signal.
                  
         -- Send the modbus frame
         declare
            PosAddr  : constant UInt8 := 16#0A#;
            PosCnt   : constant UInt16 := 16#0008#;
            PosInput : constant UInt8_Array := (16#34#, 16#AF#, 16#C2#, 16#93#,
                                                16#54#, 16#67#, 16#B8#, 16#E0#);
         begin
            MBus_Read_Discrete_Inputs (Address       => PosAddr,
                                       Byte_Count    => PosCnt,
                                       Input_Status  => PosInput);
         end;

         Send ("Modbus ADU message transmited. " & ASCII.CR & ASCII.LF);

         -- For testing purposes
         Send ("MBus outgoing buffer length: "
               & Integer'Image(Get_Length(Outgoing))
               & ASCII.CR & ASCII.LF);
         Send ("Server Address: "
               & Integer'Image(Integer(MBus_Get_Address(Outgoing)))
               & ASCII.CR & ASCII.LF);
         Send ("Function Code: "
               & Integer'Image(Integer(MBus_Get_Function_Code(Outgoing)))
               & ASCII.CR & ASCII.LF);
         Send ("Byte Count: " 
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 3)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 4)))
               & ASCII.CR & ASCII.LF);
         Send ("Input Status: "
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 5)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 6)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 7)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 8)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 9)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 10)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 11)))
               & Integer'Image(Integer(MBus_Get_Data_At(Outgoing, 12)))
               & ASCII.CR & ASCII.LF);
         -- End testing

         Await_Reception_Complete (Incoming);
         Send ("MBus incoming buffer length: "
               & Integer'Image(Get_Length(Incoming))
               & ASCII.CR & ASCII.LF);
         -- Read the received modbus frame
         if Get_Length (Incoming) > 0 then

            if not Incoming.MBus_Has_Error (InterChar_Timed_Out) and
              not Incoming.MBus_Has_Error (InterFrame_Timed_Out) and
              not Incoming.MBus_Has_Error (Response_Timed_Out)
            then
               Send ("No time out detected." & ASCII.CR & ASCII.LF);
            end if;

            Send ("Server Address: "
                  & Integer'Image(Integer(MBus_Get_Address(Incoming)))
                  & ASCII.CR & ASCII.LF);
            Send ("Function Code: "
                  & Integer'Image(Integer(MBus_Get_Function_Code(Incoming)))
                  & ASCII.CR & ASCII.LF);
            Send ("Byte Count: " 
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 3)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 4)))
                  & ASCII.CR & ASCII.LF);
            Send ("Input Status: "
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 5)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 6)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 7)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 8)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 9)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 10)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 11)))
                  & Integer'Image(Integer(MBus_Get_Data_At(Incoming, 12)))
                  & ASCII.CR & ASCII.LF);

            declare
               Chain : UInt8_Array (1 .. Get_Length (Incoming));
            begin
               Read_Frame (Msg            => Incoming,
                           Server_Address => Server_Address,
                           Function_Code  => Function_Code,
                           Data_Chain     => Chain);
               Process_Error_Status (Incoming,
                                     Server_Address => Server_Address,
                                     Function_Code  => Function_Code);
            end;
         else
            if Incoming.MBus_Has_Error (InterChar_Timed_Out) then
               Send ("InterChar timed out. ");
            end if;
            if Incoming.MBus_Has_Error (InterFrame_Timed_Out) then
               Send ("InterFrame timed out. ");
            end if;
            if Incoming.MBus_Has_Error (Response_Timed_Out) then
               Send ("Response timed out.");
            end if;
            Send (ASCII.CR & ASCII.LF & "Wait for a new cycle."
                  & ASCII.CR & ASCII.LF);
         end if;
         MBus_Clear_Errors (Incoming);
         delay until Clock + Seconds(5); -- Wait 5.0 seconds before receive the next frame

      end if;
   end loop;
   
end Demo_MBus_Blocking;
