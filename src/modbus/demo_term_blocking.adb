
--  This test emits a frame that needs the disabling of the command
--  MBus_Set_Checking of the Write_Frame procedure in the MBus_Functions.adb
--  file, called in the MBus_Read_Discrete_Inputs bellow. That command
--  calculates the CRC or LRC checking of the frame, and produces unknown
--  results that the terminal don't understand.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with HAL;                   use HAL;
with STM32.USARTs;          use STM32.USARTs;

with Peripherals_Blocking;  use Peripherals_Blocking;
with Serial_IO.Blocking;    use Serial_IO.Blocking, Serial_IO;
with Message_Buffers;       use Message_Buffers;

with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO;

with MBus_Functions.Server; use MBus_Functions.Server, MBus_Functions;

procedure Demo_Term_Blocking is

   ------------------------------------------------
   -- The serial channel for MODBUS comunication --
   ------------------------------------------------

   --  For testing purposes, we may use the modbus protocol with each one
   --  of the two serial channels MBus_COM or Term_COM. This program uses the
   --  Term_COM terminal to get the messages in the host terminal console, so we
   --  must change the MBus_Port to "MBus_Port : Serial_Port renames Term_COM;"
   --  at MBus_Functions.ads because the MODBUS functions use the MBus_Port;

   Term_Bps : constant Baud_Rates := 115_200;
   --  MBus_Bps : constant Baud_Rates := 9_600;
   --  Defines the address of the server.
   Server_Address : constant MBus_Server_Address := 16#07#;

   ------------------------------
   -- Procedures and functions --
   ------------------------------

   procedure Send_String (This : String);
   --  Translate a string into a sequence of ASCII addresses and send the frame.

   procedure Send_String (This : String) is
      Pos : UInt8;
      CharPos : UInt8_Array (1 .. This'Length);
   begin
      for i in This'Range loop
         Pos := Character'Pos (This (i));
         CharPos (i) := Pos;
      end loop;

      Await_Transmission_Complete (Outgoing); -- outgoing buffer
      Set_Content (Outgoing, To => CharPos);
      Signal_Reception_Complete (Outgoing); -- outgoing buffer
      Await_Reception_Complete (Outgoing); -- outgoing buffer
      Send (Term_COM, Outgoing'Unchecked_Access);
      --  No need to wait for it here because the Put won't return until the
      --  message has been sent.
      Signal_Transmission_Complete (Outgoing); -- outgoing buffer
   end Send_String;

begin
   --  The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
   --  serial channel are defined at Serial_IO.ads. This mode only affects the
   --  reception of data choosing the end of frame mode in the Get procedure at
   --  Serial_IO.Blocking.

   --  Configuration for Terminal console
   Initialize (Term_COM);
   Configure (Term_COM, Baud_Rate => Term_Bps, Parity => No_Parity);
   Set_Serial_Mode (Term_COM, Terminal);

   --  Configuration for modbus
   --  Initialize (MBus_COM);
   --  Configure (MBus_COM, Baud_Rate => MBus_Bps, Parity => Even_Parity);
   --  Set_Serial_Mode (MBus_COM, MBus_RTU);

   --  Start with outgoing buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Outgoing); -- outgoing buffer

   --  Start with incoming buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Incoming); -- incoming buffer

   Set_Terminator (Incoming, To => ASCII.CR);

   Send_String (ASCII.FF & "Test terminal monitoring and modbus comunication in"
         & " the same terminal serial channel. The terminal will receive a"
         & " modbus stream as responding to a client request." & ASCII.CR & ASCII.LF);

   loop
      Set_Serial_Mode (Term_COM, Terminal);
      --  because MBus_Port = Term_COM
      Send_String ("Choose the number that corresponds to a modbus RTU or"
            & " ASCII test protocol." & ASCII.CR & ASCII.LF);
      Send_String ("1 - Modbus RTU." & ASCII.CR & ASCII.LF);
      Send_String ("2 - Modbus ASCII." & ASCII.CR & ASCII.LF);
      Signal_Transmission_Complete (Incoming); -- incoming buffer

      Receive_Frame (Term_COM, Incoming);
      Await_Reception_Complete (Incoming); -- incoming buffer

      if (Get_Content_At (Incoming, 1) = Character'Pos (Incoming.Get_Terminator))
          or ((Get_Content_At (Incoming, 1) /= Character'Pos ('1'))
          and (Get_Content_At (Incoming, 1) /= Character'Pos ('2')))
      then
         Send_String ("No valid option, please try again." & ASCII.CR & ASCII.LF);
      else
         if (Get_Content_At (Incoming, 1) = Character'Pos ('1')) then
            Send_String ("Option 1. Send a response to a Read_Discrete_Inputs with:"
                   & ASCII.CR & ASCII.LF);
            Send_String ("Server_Address = 07, Function_Code = 02, Byte_Count = BC"
                   & ASCII.CR & ASCII.LF);
            Send_String ("and Input_Status = (16#9F#, 16#63#, 16#47#, 16#81#, 16#CB#)."
                   & ASCII.CR & ASCII.LF);

            MBus_Set_Mode (Outgoing, RTU);

            --  Send a response to a Read_Discrete_Inputs with
            --  Server_Address = 16#07#, Function_Code = 16#0F#,
            --  Byte_Count = 16#0B0C# and
            --  Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#).
            --  It is necessary to put the LF CR character to use
            --  Serial_Mode as Terminal.
            declare
               PosAddr  : constant UInt8 := Get_ASCII_Pos (Server_Address); -- character 7
               PosCnt   : constant UInt16 := 16#4243#; -- characters B and C
               PosInput : constant UInt8_Array (1 .. 10) :=
                 (Get_ASCII_Pos (16#09#), Get_ASCII_Pos (16#0F#),
                  Get_ASCII_Pos (16#06#), Get_ASCII_Pos (16#03#),
                  Get_ASCII_Pos (16#04#), Get_ASCII_Pos (16#07#),
                  Get_ASCII_Pos (16#08#), Get_ASCII_Pos (16#01#),
                  Get_ASCII_Pos (16#0C#), Get_ASCII_Pos (16#0B#));
            begin
               MBus_Read_Discrete_Inputs (Address       => PosAddr,
                                          Byte_Count    => PosCnt,
                                          Input_Status  => PosInput);
            end;
            Send_String ("" & ASCII.CR & ASCII.LF);

         elsif (Get_Content_At (Incoming, 1) = Character'Pos ('2')) then
            Send_String ("Option 2. Send a response to a Read_Discrete_Inputs with:"
                   & ASCII.CR & ASCII.LF);
            Send_String ("Server_Address = 07, Function_Code = 02, Byte_Count = BC"
                   & ASCII.CR & ASCII.LF);
            Send_String ("and Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#, 16#6C#)."
                   & ASCII.CR & ASCII.LF);

            MBus_Set_Mode (Outgoing, ASC);

            --  Send a response to a Read_Discrete_Inputs with
            --  Server_Address = 16#07#, Function_Code = 16#0F#,
            --  Byte_Count = 16#0B0C# and
            --  Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#, 16#6C#).
            --  It is necessary to put the LF CR characters to use
            --  Serial_Mode as Terminal.
            declare
               PosByte  : constant UInt16 := 16#0B0C#; -- characters B and C
               PosInput : constant UInt8_Array (1 .. 5) :=
                 (16#1F#, 16#23#, 16#47#, 16#80#, 16#6C#);
            begin
               MBus_Read_Discrete_Inputs (Address      => Server_Address,
                                          Byte_Count   => PosByte,
                                          Input_Status => PosInput);
            end;
         end if;
      end if;
      Send_String ("" & ASCII.CR & ASCII.LF);
   end loop;

end Demo_Term_Blocking;
