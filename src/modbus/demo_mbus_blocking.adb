--  This test waits the receiving of a frame in the modbus serial channel,
--  so you will need a modbus client connected to MBus_COM port.
--  The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
--  serial channel are defined at Serial_IO.ads. This mode only affects the
--  reception of data choosing the end of frame mode in the Receive procedure
--  at Serial_IO.Port.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with MBus_Task; pragma Unreferenced (MBus_Task);
--  The MBus_Task package contains the task that actually controls the reception
--  app so although it is not referenced directly in the main procedure, we need
--  it in the closure of the context clauses so that it will be included in the
--  executable.

with Ada.Real_Time;         use Ada.Real_Time;
with HAL;                   use HAL;
with STM32.USARTs;          use STM32.USARTs;

with Peripherals_Blocking;  use Peripherals_Blocking;
with Serial_IO.Blocking;    use Serial_IO.Blocking, Serial_IO;
with Message_Buffers;       use Message_Buffers;
with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO, MBus_Frame;

with MBus_Functions.Server; use MBus_Functions.Server, MBus_Functions;


procedure Demo_MBus_Blocking is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   MBus_Bps : constant Baud_Rates := 9_600;
   Term_Bps : constant Baud_Rates := 115_200;

   ------------------------------------------------
   -- The serial channel for MODBUS comunication --
   ------------------------------------------------

   --  For testing purposes, we may use the modbus protocol functions with each
   --  one of the two serial channels MBus_COM or Term_COM, setting it up inside
   --  Peripherals.ads: "MBus_Port : Serial_Port renames Term_COM;".

   -----------------------------------------
   -- Buffers for Terminal Serial Channel --
   -----------------------------------------

   Term_Incoming : aliased Message (Physical_Size => 1024);  -- arbitrary size
   Term_Outgoing : aliased Message (Physical_Size => 1024);  -- arbitrary size

   --  Defines the address of the server.
   Server_Address : constant MBus_Server_Address := 16#0A#;
   --  Defines function code
   Function_Code : constant MBus_Normal_Function_Code := Read_Discrete_Inputs;

   ------------------------------
   -- Procedures and functions --
   ------------------------------

   procedure Send_String (This : String);
   --  Receives a string of characters and put the character addresses into an
   --  UInt8 array. Then put this array into a Message buffer taking into
   --  account the buffer'flags of transmission/reception complete and send the
   --  frame to the Term_COM serial port.

   procedure Send_String (This : String) is
      CharPos : UInt8_Array (1 .. This'Length);
   begin
      for i in This'Range loop
         CharPos (i) := Character'Pos (This (i));
      end loop;
      Await_Transmission_Complete (Term_Outgoing);
      Set_Content (Term_Outgoing, To => CharPos);
      Signal_Reception_Complete (Term_Outgoing);
      Send_Frame (Term_COM, Term_Outgoing);
   end Send_String;

begin
   --  Configuration for Terminal console
   Initialize (Term_COM);
   Configure (Term_COM, Baud_Rate => Term_Bps, Parity => No_Parity);
   Set_Serial_Mode (Term_COM, Terminal);
   Configure_Timeout (Term_COM, MB_Bps => Term_Bps);

   --  Configuration for modbus communication.
   Initialize (MBus_COM);
   Configure (MBus_COM, Baud_Rate => MBus_Bps, Parity => Even_Parity);
   Configure_Timeout (MBus_COM, MB_Bps => MBus_Bps);

   --  Start with buffers empty, so there is no need to wait.
   Signal_Transmission_Complete (Term_Outgoing);
   Signal_Transmission_Complete (Outgoing);

   Set_Terminator (Term_Incoming, To => ASCII.CR);

   Send_String (ASCII.FF & "Test terminal and modbus comunications in different"
     & " serial channels. The terminal will only monitor the receipt of a modbus"
     & " stream as responding to a client request." & ASCII.LF & ASCII.CR);

   loop
      Send_String ("Choose the number that corresponds to a modbus RTU or"
        & " ASCII test protocol." & ASCII.CR & ASCII.LF);
      Send_String ("1 - Modbus RTU." & ASCII.CR & ASCII.LF);
      Send_String ("2 - Modbus ASCII." & ASCII.CR & ASCII.LF);

      Signal_Transmission_Complete (Term_Incoming);
      Receive_Frame (Term_COM, Term_Incoming);

      Await_Reception_Complete (Term_Incoming);

      if Term_Incoming.MBus_Has_Error (Response_Timed_Out) then
         Send_String ("Terminal response timed out, please reset the board."
           & ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF);
      end if;

      if (Get_Content_At (Term_Incoming, 1) = Character'Pos (Term_Incoming.Get_Terminator))
          or ((Get_Content_At (Term_Incoming, 1) /= Character'Pos ('1'))
          and (Get_Content_At (Term_Incoming, 1) /= Character'Pos ('2')))
      then
         Send_String ("No valid option, please try again."
                      & ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF);
      else
         if Get_Content_At (Term_Incoming, 1) = Character'Pos ('1') then
            Send_String ("Option 1 - Modbus RTU protocol." & ASCII.CR & ASCII.LF);
            MBus_Set_Mode (Incoming, RTU);
            MBus_Set_Mode (Outgoing, RTU);
            Set_Serial_Mode (MBus_COM, MBus_RTU);
         elsif Get_Content_At (Term_Incoming, 1) = Character'Pos ('2') then
            Send_String ("Option 2 - Modbus ASCII protocol." & ASCII.CR & ASCII.LF);
            MBus_Set_Mode (Incoming, ASC);
            MBus_Set_Mode (Outgoing, ASC);
            Set_Serial_Mode (MBus_COM, MBus_ASCII);
         end if;

         Send_String ("Send a response to a Read_Discrete_Inputs with:"
           & ASCII.CR & ASCII.LF);
         Send_String ("Server_Address = 10, Function_Code = 15, Byte_Count = 08"
           & ASCII.CR & ASCII.LF);
         Send_String ("and Input_Status = (52, 175, 194, 147, 84, 103, 184, 224)."
           & ASCII.CR & ASCII.LF);

         --  Wait for the transmission of the modbus frame
         Send_String ("Waiting for a modbus ADU message from the client... "
               & ASCII.CR & ASCII.LF);
         Signal_Transmission_Complete (Incoming); -- incoming buffer
         --  Here the MBus_Task receives the autorization to receive the modbus
         --  frame, because the Receive_Frame task waits for this signal. When
         --  it gets inter-frame or response timeout, the task ends receiving,
         --  then a new task cycle is started until it gets the first byte of
         --  a frame.

         --  Send the modbus frame
         declare
            PosCnt   : constant UInt16 := 16#0008#;
            PosInput : constant UInt8_Array (1 .. 8) :=
              (16#34#, 16#AF#, 16#C2#, 16#93#, 16#54#, 16#67#, 16#B8#, 16#E0#);
         begin
            MBus_Read_Discrete_Inputs (Address       => Server_Address,
                                       Byte_Count    => PosCnt,
                                       Input_Status  => PosInput);
         end;

         Send_String ("Modbus ADU message transmited. " & ASCII.CR & ASCII.LF);

         --  For testing purposes
         Send_String ("MBus outgoing buffer length: "
           & Integer'Image (Get_Length (Outgoing))
           & ASCII.CR & ASCII.LF);
         Send_String ("Server Address: "
           & Integer'Image (Integer (MBus_Get_Address (Outgoing)))
           & ASCII.CR & ASCII.LF);
         Send_String ("Function Code: "
           & Integer'Image (Integer (MBus_Get_Function_Code (Outgoing)))
           & ASCII.CR & ASCII.LF);
         Send_String ("Byte Count: "
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 3)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 4)))
           & ASCII.CR & ASCII.LF);
         Send_String ("Input Status: "
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 5)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 6)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 7)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 8)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 9)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 10)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 11)))
           & Integer'Image (Integer (MBus_Get_Data_At (Outgoing, 12)))
           & ASCII.CR & ASCII.LF);
         --  End testing

         Await_Reception_Complete (Incoming);
         Send_String ("MBus incoming buffer length: "
           & Integer'Image (Get_Length (Incoming)) & ASCII.CR & ASCII.LF);
         --  Read the received modbus frame
         if Get_Length (Incoming) > 0 then

            if not Incoming.MBus_Has_Error (InterChar_Timed_Out) and
              not Incoming.MBus_Has_Error (InterFrame_Timed_Out) and
              not Incoming.MBus_Has_Error (Response_Timed_Out)
            then
               Send_String ("No time out detected." & ASCII.CR & ASCII.LF);
            end if;

            Send_String ("Server Address: "
              & Integer'Image (Integer (MBus_Get_Address (Incoming)))
              & ASCII.CR & ASCII.LF);
            Send_String ("Function Code: "
              & Integer'Image (Integer (MBus_Get_Function_Code (Incoming)))
              & ASCII.CR & ASCII.LF);
            Send_String ("Byte Count: "
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 3)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 4)))
              & ASCII.CR & ASCII.LF);
            Send_String ("Input Status: "
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 5)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 6)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 7)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 8)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 9)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 10)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 11)))
              & Integer'Image (Integer (MBus_Get_Data_At (Incoming, 12)))
              & ASCII.CR & ASCII.LF);

            declare
               Chain : UInt8_Array (1 .. Get_Length (Incoming));
            begin
               Read_Frame (Msg            => Incoming,
                           Server_Address => Server_Address,
                           Function_Code  => Function_Code,
                           Data_Chain     => Chain);
            end;
         else
            if Incoming.MBus_Has_Error (InterChar_Timed_Out) then
               Send_String ("InterChar timed out. ");
            end if;
            if Incoming.MBus_Has_Error (InterFrame_Timed_Out) then
               Send_String ("InterFrame timed out. ");
            end if;
            if Incoming.MBus_Has_Error (Response_Timed_Out) then
               Send_String ("Response timed out." & ASCII.CR & ASCII.LF);
            end if;
         end if;
         MBus_Clear_Errors (Incoming);
         MBus_Clear_Errors (Term_Incoming);
         Send_String ("Wait for a new cycle."
           & ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF);
         delay until Clock + Seconds (3);
      end if;
   end loop;

end Demo_MBus_Blocking;
