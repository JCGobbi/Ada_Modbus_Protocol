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

with Peripherals;           use Peripherals;
with Serial_IO.Port;        use Serial_IO.Port, Serial_IO;
with Message_Buffers;       use Message_Buffers;
with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO, MBus_Frame;
with MBus_Functions.Server; use MBus_Functions;

procedure Demo_MBus is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   Term_Bps : constant Baud_Rates := 115_200;
   MBus_Bps : constant Baud_Rates := 9_600;

   ------------------------------------------------
   -- The serial channel for MODBUS comunication --
   ------------------------------------------------

   --  For testing purposes, we may use the modbus protocol functions with each
   --  one of the two serial channels MBus_COM or Term_COM, setting it up inside
   --  Peripherals.ads: "MBus_Port : Serial_Port renames Term_COM;".
   --  Or we may use the MODBUS library functions that need the serial port as
   --  argument.

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
      Await_Transmission_Complete (Term_COM.Outgoing_Msg.all);
      Set_Content (Term_COM.Outgoing_Msg.all, To => CharPos);
      Signal_Reception_Complete (Term_COM.Outgoing_Msg.all);
      Send_Frame (Term_COM);
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
   Signal_Transmission_Complete (Term_COM.Outgoing_Msg.all);
   Signal_Transmission_Complete (MBus_COM.Outgoing_Msg.all);

   Set_Terminator (Term_COM.Incoming_Msg.all, To => ASCII.CR);

   Send_String (ASCII.FF & "Test terminal and modbus comunications in different"
     & " serial channels. The terminal will only monitor the receipt of a modbus"
     & " stream as responding to a client request." & ASCII.LF & ASCII.CR);

   loop
      Send_String ("Choose the number that corresponds to a modbus RTU or"
        & " ASCII test protocol." & ASCII.LF & ASCII.CR);
      Send_String ("1 - Modbus RTU." & ASCII.LF & ASCII.CR);
      Send_String ("2 - Modbus ASCII." & ASCII.LF & ASCII.CR);

      Signal_Transmission_Complete (Term_COM.Incoming_Msg.all);
      Receive_Frame (Term_COM);

      Await_Reception_Complete (Term_COM.Incoming_Msg.all);

      if MBus_Has_Error (Term_COM.Incoming_Msg.all, Response_Timed_Out) then
         Send_String ("Terminal response timed out."
                      & ASCII.LF & ASCII.CR & ASCII.LF & ASCII.CR);
      end if;

      if (Get_Content_At (Term_COM.Incoming_Msg.all, 1) =
          Character'Pos (Get_Terminator (Term_COM.Incoming_Msg.all)))
          or ((Get_Content_At (Term_COM.Incoming_Msg.all, 1) /= Character'Pos ('1'))
          and (Get_Content_At (Term_COM.Incoming_Msg.all, 1) /= Character'Pos ('2')))
      then
         Send_String ("No valid option, please try again."
           & ASCII.LF & ASCII.CR & ASCII.LF & ASCII.CR);
      else
         if Get_Content_At (Term_COM.Incoming_Msg.all, 1) = Character'Pos ('1') then
            Send_String ("Option 1 - Modbus RTU protocol." & ASCII.LF & ASCII.CR);
            MBus_Set_Mode (MBus_COM.Incoming_Msg.all, RTU);
            MBus_Set_Mode (MBus_COM.Outgoing_Msg.all, RTU);
            Set_Serial_Mode (MBus_COM, MBus_RTU);
         elsif Get_Content_At (Term_COM.Incoming_Msg.all, 1) = Character'Pos ('2') then
            Send_String ("Option 2 - Modbus ASCII protocol." & ASCII.LF & ASCII.CR);
            MBus_Set_Mode (MBus_COM.Incoming_Msg.all, ASC);
            MBus_Set_Mode (MBus_COM.Outgoing_Msg.all, ASC);
            Set_Serial_Mode (MBus_COM, MBus_ASCII);
         end if;

         Send_String ("Send a response to a Read_Discrete_Inputs with:"
           & ASCII.LF & ASCII.CR);
         Send_String ("Server_Address = 10, Function_Code = 02, Byte_Count = 08"
           & ASCII.LF & ASCII.CR);
         Send_String ("Input_Status = (52, 175, 194, 147, 84, 103, 184, 224)."
           & ASCII.LF & ASCII.CR);
         Send_String ("Waiting for a modbus ADU message from the client... "
           & ASCII.LF & ASCII.CR);

         Signal_Transmission_Complete (MBus_COM.Incoming_Msg.all);
         --  Here the MBus_Task receives the autorization to receive the modbus
         --  frame, because the Receive_Frame task waits for this signal. When
         --  it gets inter-frame or response timeout, the task ends receiving,
         --  then a new task cycle is started until it gets the first byte of
         --  a frame.

         --  Send a response to a Read_Discrete_Inputs with
         --  Server_Address = 16#0A#, Function_Code = 16#02#,
         --  Byte_Count = 16#0008# and
         --  Input_Status = (16#34#, 16#AF#, 16#C2#, 16#93#,
         --                  16#54#, 16#67#, 16#B8#, 16#E0#).
         declare
            PosCnt   : constant UInt16 := 16#0008#;
            PosInput : constant UInt8_Array (1 .. 8) :=
              (16#34#, 16#AF#, 16#C2#, 16#93#, 16#54#, 16#67#, 16#B8#, 16#E0#);
         begin
            --  Use library MODBUS functions to send directly to MODBUS serial
            --  port.
            Server.MBus_Read_Discrete_Inputs
                     (MBus_COM,
                      Address      => Server_Address,
                      Byte_Count   => PosCnt,
                      Input_Status => PosInput);
         end;

         Send_String ("Modbus ADU message transmited. " & ASCII.LF & ASCII.CR);

         --  For testing purposes
         Send_String ("MBus outgoing buffer length: "
           & Integer'Image (Get_Length (MBus_COM.Outgoing_Msg.all))
           & ASCII.LF & ASCII.CR);
         Send_String ("Server Address: "
           & Integer'Image (Integer (MBus_Get_Address (MBus_COM.Outgoing_Msg.all)))
           & ASCII.LF & ASCII.CR);
         Send_String ("Function Code: "
           & Integer'Image (Integer (MBus_Get_Function_Code (MBus_COM.Outgoing_Msg.all)))
           & ASCII.LF & ASCII.CR);
         Send_String ("Byte Count: "
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 3)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 4)))
           & ASCII.LF & ASCII.CR);
         Send_String ("Input Status: "
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 5)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 6)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 7)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 8)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 9)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 10)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 11)))
           & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Outgoing_Msg.all, 12)))
           & ASCII.LF & ASCII.CR);
         --  End testing

         Await_Reception_Complete (MBus_COM.Incoming_Msg.all);
         Send_String ("MBus incoming buffer length: "
           & Integer'Image (Get_Length (MBus_COM.Incoming_Msg.all)) & ASCII.LF & ASCII.CR);
         --  Read the received modbus frame
         if Get_Length (MBus_COM.Incoming_Msg.all) > 0 then

            if not MBus_Has_Error (MBus_COM.Incoming_Msg.all, InterChar_Timed_Out) and
              not MBus_Has_Error (MBus_COM.Incoming_Msg.all, InterFrame_Timed_Out) and
              not MBus_Has_Error (MBus_COM.Incoming_Msg.all, Response_Timed_Out)
            then
               Send_String ("No time out detected." & ASCII.LF & ASCII.CR);
            end if;

            Send_String ("Server Address: "
              & Integer'Image (Integer (MBus_Get_Address (MBus_COM.Incoming_Msg.all)))
              & ASCII.LF & ASCII.CR);
            Send_String ("Function Code: "
              & Integer'Image (Integer (MBus_Get_Function_Code (MBus_COM.Incoming_Msg.all)))
              & ASCII.LF & ASCII.CR);
            Send_String ("Byte Count: "
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 3)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 4)))
              & ASCII.LF & ASCII.CR);
            Send_String ("Input Status: "
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 5)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 6)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 7)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 8)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 9)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 10)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 11)))
              & Integer'Image (Integer (MBus_Get_Data_At (MBus_COM.Incoming_Msg.all, 12)))
              & ASCII.LF & ASCII.CR);

            declare
               Chain : UInt8_Array (1 .. Get_Length (MBus_COM.Incoming_Msg.all));
            begin
               Read_Frame (Msg            => MBus_COM.Incoming_Msg.all,
                           Server_Address => Server_Address,
                           Function_Code  => Function_Code,
                           Data_Chain     => Chain);
            end;
         else
            if MBus_Has_Error (MBus_COM.Incoming_Msg.all, InterChar_Timed_Out) then
               Send_String ("InterChar timed out. ");
            end if;
            if MBus_Has_Error (MBus_COM.Incoming_Msg.all, InterFrame_Timed_Out) then
               Send_String ("InterFrame timed out. ");
            end if;
            if MBus_Has_Error (MBus_COM.Incoming_Msg.all, Response_Timed_Out) then
               Send_String ("Response timed out." & ASCII.LF & ASCII.CR);
            end if;
         end if;
         MBus_Clear_Errors (MBus_COM.Incoming_Msg.all);
         MBus_Clear_Errors (Term_COM.Incoming_Msg.all);
         Send_String ("Wait for a new cycle."
                      & ASCII.LF & ASCII.CR & ASCII.LF & ASCII.CR);
         --  Wait 3 seconds before receive the next frame.
         delay until Clock + Seconds (3);
      end if;
   end loop;

end Demo_MBus;
