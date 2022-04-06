with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with HAL;                   use HAL;
with STM32.USARTS;          use STM32.USARTS;

with Peripherals_Blocking;  use Peripherals_Blocking;
with Serial_IO.Blocking;    use Serial_IO.Blocking;
                            use Serial_IO;
with Message_Buffers;       use Message_Buffers;

with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO;

with MBus_Functions.Server; use MBus_Functions.Server;
                            use MBus_Functions;

procedure Demo_Term_Blocking is

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
      
      Await_Transmission_Complete (Outgoing); -- outgoing buffer
      Set_Content (Outgoing, To => CharPos);
      Signal_Reception_Complete (Outgoing); -- outgoing buffer
      Await_Reception_Complete (Outgoing); -- outgoing buffer
      Put (Term_COM, Outgoing'Unchecked_Access);
      -- No need to wait for it here because the Put won't return until the
      -- message has been sent.
      Signal_Transmission_Complete (Outgoing); -- outgoing buffer
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

   -- Start with outgoing buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Outgoing); -- outgoing buffer
   
   -- Start with incoming buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Incoming); -- incoming buffer
   
   Set_Terminator (Incoming, To => ASCII.CR);

   Send ("Test terminal monitoring and modbus comunication in the same"
         & " terminal serial channel." & ASCII.CR & ASCII.LF);
   -- This test emits a frame that needs the disabling of the command
   -- MBus_Set_Checking of the Write_Frame procedure in the MBus_Functions.adb
   -- file, called in the MBus_Read_Discrete_Inputs bellow. That command
   -- calculates the CRC or LRC checking of the frame, and produces unknown
   -- results that the terminal don't understand.
   Send ("The terminal will receive a modbus stream as responding to a"
         & " client request." & ASCII.CR & ASCII.LF);

   loop
      Set_Serial_Mode (Term_COM, Terminal);
      -- because MBus_Port = Term_COM
      Send ("Choose the number that corresponds to a modbus RTU or"
            & " ASCII test protocol." & ASCII.CR & ASCII.LF);
      Send ("1 - Modbus RTU." & ASCII.CR & ASCII.LF);
      Send ("2 - Modbus ASCII." & ASCII.CR & ASCII.LF);
      Signal_Transmission_Complete (Incoming); -- incoming buffer
   
      Receive_Frame (Term_COM, Incoming);
      Await_Reception_Complete (Incoming); -- incoming buffer

      if (Get_Content_At (Incoming, 1) = Character'Pos(Incoming.Get_Terminator))
          or ((Get_Content_At (Incoming, 1) /= Character'Pos('1'))
          and (Get_Content_At (Incoming, 1) /= Character'Pos('2')))
      then
         Send ("No valid option, please try again." & ASCII.CR & ASCII.LF);
      else
         if (Get_Content_At (Incoming, 1) = Character'Pos('1')) then
            Send ("Option 1. Send a response to a Read_Discrete_Inputs with:"
                   & ASCII.CR & ASCII.LF);
            Send ("Server_Address = 07, Function_Code = 0F, Byte_Count = BC"
                   & ASCII.CR & ASCII.LF);
            Send ("and Input_Status = (1F, 23, 47, 80)."
                   & ASCII.CR & ASCII.LF);

            MBus_Set_Mode (Outgoing, RTU);
            -- We are using terminal serial channel
            -- Set_Serial_Mode (Term_COM, Terminal);

            -- Send a response to a Read_Discrete_Inputs with
            -- Server_Address = 16#07#, Function_Code = 16#0F#,
            -- Byte_Count = 16#0B0C# and
            -- Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#).
            -- It is necessary to put the LF CR character to use
            -- Serial_Mode as Terminal.
            declare
               PosAddr  : constant UInt8 := Get_ASCII_Pos (16#07#); -- character 7
               PosCnt   : constant UInt16 := 16#4243#; -- characters B and C
               PosInput : constant UInt8_Array :=
                 (Get_ASCII_Pos (16#01#), Get_ASCII_Pos (16#0F#),
                  Get_ASCII_Pos (16#02#), Get_ASCII_Pos (16#03#),
                  Get_ASCII_Pos (16#04#), Get_ASCII_Pos (16#07#),
                  Get_ASCII_Pos (16#08#), Get_ASCII_Pos (16#00#),
                  16#0A#, 16#0D#); -- characters LF and CR
            begin
               MBus_Read_Discrete_Inputs (Address       => PosAddr,
                                          Byte_Count    => PosCnt,
                                          Input_Status  => PosInput);
            end;

         elsif (Get_Content_At (Incoming, 1) = Character'Pos('2')) then
            Send ("Option 2. Send a response to a Read_Discrete_Inputs with:"
                   & ASCII.CR & ASCII.LF);
            Send ("Server_Address = 07, Function_Code = 0F, Byte_Count = BC"
                   & ASCII.CR & ASCII.LF);
            Send ("and Input_Status = (1F, 23, 47, 80)."
                   & ASCII.CR & ASCII.LF);

            MBus_Set_Mode (Outgoing, ASC);
            -- We are using terminal serial channel
            Set_Serial_Mode (Term_COM, MBus_ASCII);

            -- Send a response to a Read_Discrete_Inputs with
            -- Server_Address = 16#07#, Function_Code = 16#0F#,
            -- Byte_Count = 16#0B0C# and
            -- Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#).
            -- It is necessary to put the LF CR characters to use
            -- Serial_Mode as Terminal.
            declare
               PosAddr  : constant UInt8 := 16#07#;
               PosByte  : constant UInt16 := 16#0B0C#; -- characters B and C
               PosInput : constant UInt8_Array := (16#1F#, 16#23#, 16#47#, 16#80#);
            begin
               MBus_Read_Discrete_Inputs (Address      => PosAddr,
                                          Byte_Count   => PosByte,
                                          Input_Status => PosInput);
            end;
         end if;
      end if;
   end loop;
      
end Demo_Term_Blocking;
