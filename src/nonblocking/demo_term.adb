--  Test terminal and modbus comunications in the same terminal serial channel.
--  The terminal will receive a modbus stream as responding to a client request.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with HAL;                   use HAL;
with STM32.USARTs;          use STM32.USARTs;

with Peripherals;           use Peripherals;
with Serial_IO.Port;        use Serial_IO.Port, Serial_IO;
with Message_Buffers;       use Message_Buffers;
with MBus;                  use MBus;
with MBus_Frame.IO;         use MBus_Frame.IO;
with MBus_Functions.Server; use MBus_Functions;

procedure Demo_Term is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   Term_Bps : constant Baud_Rates := 115_200;

   ------------------------------------------------
   -- The serial channel for MODBUS comunication --
   ------------------------------------------------

   --  For testing purposes, we may use the modbus protocol functions with each
   --  one of the two serial channels MBus_COM or Term_COM, setting it up inside
   --  Peripherals.ads: "MBus_Port : Serial_Port renames Term_COM;".
   --  Or we may use the MODBUS library functions that need the serial port as
   --  argument.
   --  Because the MODBUS functions use the internal Outcoming_Msg and
   --  Incoming_Msg defined at MBus_Functions.ads, the messages sent/received
   --  to/from the terminal port must use these same buffers.

   --  Defines the address of the server.
   Server_Address : constant MBus_Server_Address := 16#07#;

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
   --  The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
   --  serial channel are defined at Serial_IO.ads. This mode only affects the
   --  reception of data choosing the end of frame mode in the Receive procedure
   --  at Serial_IO.Port.

   --  Configuration for Terminal console
   Initialize (Term_COM);
   Configure (Term_COM, Baud_Rate => Term_Bps, Parity => No_Parity);
   Set_Serial_Mode (Term_COM, Terminal);
   --  We don't need to configure timeouts for Terminal serial port.

   --  Start with buffers empty, so there is no need to wait.
   Signal_Transmission_Complete (Term_COM.Outgoing_Msg.all);
   Signal_Transmission_Complete (Term_COM.Incoming_Msg.all);

   Set_Terminator (Term_COM.Incoming_Msg.all, To => ASCII.CR);

   Send_String (ASCII.FF & "Test terminal and modbus comunications in the same"
     & " terminal serial channel. The terminal will receive a modbus stream as"
     & " responding to a client request." & ASCII.LF & ASCII.CR);

   loop
      Send_String ("Choose the number that corresponds to a modbus RTU or"
        & " ASCII test protocol." & ASCII.LF & ASCII.CR);
      Send_String ("1 - Modbus RTU." & ASCII.LF & ASCII.CR);
      Send_String ("2 - Modbus ASCII." & ASCII.LF & ASCII.CR & ASCII.LF & ASCII.CR);

      Receive_Frame (Term_COM);
      Await_Reception_Complete (Term_COM.Incoming_Msg.all);

      if (Get_Content_At (Term_COM.Incoming_Msg.all, 1) =
          Character'Pos (Get_Terminator (Term_COM.Incoming_Msg.all)))
          or ((Get_Content_At (Term_COM.Incoming_Msg.all, 1) /= Character'Pos ('1'))
          and (Get_Content_At (Term_COM.Incoming_Msg.all, 1) /= Character'Pos ('2')))
      then
         Send_String ("Invalid option, please try again."
                      & ASCII.LF & ASCII.CR & ASCII.LF & ASCII.CR);
      else
         if (Get_Content_At (Term_COM.Incoming_Msg.all, 1) = Character'Pos ('1')) then
            Send_String ("Option 1. Send a response to a Read_Discrete_Inputs with:"
              & ASCII.LF & ASCII.CR);
            Send_String ("Server_Address = 07, Function_Code = 02, Byte_Count = BC"
              & ASCII.LF & ASCII.CR);
            Send_String ("and Input_Status = (9F, 63, 47, 81, CB)."
              & ASCII.LF & ASCII.CR);

            MBus_Set_Mode (Term_COM.Outgoing_Msg.all, RTU);
            --  We are using terminal serial channel in mode Terminal instead of
            --  MBus_RTU, so the data includes characters LF and CR at the end
            --  of frame.
            --  Set_Serial_Mode (Term_COM, MBus_RTU);

            --  Send a response to a Read_Discrete_Inputs with
            --  Server_Address = 16#07#, Function_Code = 16#02#,
            --  Byte_Count = 16#0B0C# and
            --  Input_Status = (16#9F#, 16#63#, 16#47#, 16#81#, 16#CB#).
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
               --  Use library MODBUS functions to send directly to terminal
               --  serial port.
               Server.MBus_Read_Discrete_Inputs
                        (Term_COM,
                         Address      => PosAddr,
                         Byte_Count   => PosCnt,
                         Input_Status => PosInput);
            end;
            Send_String (ASCII.LF & ASCII.CR); --  next line
            Send_String (ASCII.LF & ASCII.CR); --  blank line

         elsif (Get_Content_At (Term_COM.Incoming_Msg.all, 1) = Character'Pos ('2')) then
            Send_String ("Option 2. Send a response to a Read_Discrete_Inputs with:"
              & ASCII.LF & ASCII.CR);
            Send_String ("Server_Address = 07, Function_Code = 02, Byte_Count = BC"
              & ASCII.LF & ASCII.CR);
            Send_String ("and Input_Status = (1F, 23, 47, 80, 6C)."
              & ASCII.LF & ASCII.CR);

            MBus_Set_Mode (Term_COM.Outgoing_Msg.all, ASC);
            --  We are using terminal serial channel in mode Terminal instead of
            --  MBus_ASCII, so the data includes characters LF and CR at the end
            --  of frame.
            --  Set_Serial_Mode (Term_COM, MBus_ASCII);

            --  Send a response to a Read_Discrete_Inputs with
            --  Server_Address = 16#07#, Function_Code = 16#02#,
            --  Byte_Count = 16#0B0C# and
            --  Input_Status = (16#1F#, 16#23#, 16#47#, 16#80#, 16#6C#).
            declare
               PosByte  : constant UInt16 := 16#0B0C#; -- characters B and C
               PosInput : constant UInt8_Array (1 .. 5) :=
                 (16#1F#, 16#23#, 16#47#, 16#80#, 16#6C#);
            begin
               --  Use library MODBUS functions to send directly to terminal
               --  serial port.
               Server.MBus_Read_Discrete_Inputs
                        (Term_COM,
                         Address      => Server_Address,
                         Byte_Count   => PosByte,
                         Input_Status => PosInput);
            end;
            Send_String (ASCII.LF & ASCII.CR); --  blank line
         end if;
      end if;
      Signal_Transmission_Complete (Term_COM.Incoming_Msg.all);
   end loop;

end Demo_Term;
