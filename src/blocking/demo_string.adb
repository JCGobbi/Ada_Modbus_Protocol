--  A demonstration of a higher-level USART interface, using blocking I/O.
--  The file declares the main procedure for the demonstration.

--  This demo tests the transmitting/receiving of bytes by the serial buffers
--  to/from a terminal connected with the serial channel of a computer using
--  a string instead of an ADU modbus frame. This shows that the same serial
--  buffer may be used by the modbus protocol and string terminal.

--  Initially the board sends a message to the serial channel of the computer,
--  that receives it with a terminal emulator like PuTTY. The response with CR
--  <Enter> is received by the board and echoed back to the terminal.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.
with HAL;             use HAL;
with STM32.USARTs;    use STM32.USARTs;

with Peripherals;     use Peripherals;
with MBus_Frame.IO;   use MBus_Frame.IO;
with Serial_IO.Port;  use Serial_IO.Port, Serial_IO;
with Message_Buffers; use Message_Buffers;

procedure Demo_String is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   Term_Bps : constant Baud_Rates := 115_200;

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
   Configure (Term_COM, Baud_Rate => Term_Bps);
   Set_Serial_Mode (Term_COM, Terminal);
   --  We don't need to configure timeouts for Terminal serial port.

   Set_Terminator (Term_COM.Incoming_Msg.all, To => ASCII.CR);

   --  Start with buffers empty, so there is no need to wait.
   Signal_Transmission_Complete (Term_COM.Outgoing_Msg.all);
   Send_String (ASCII.FF & "");

   loop
      Send_String ("Enter text, terminated by CR <Enter>."
                & ASCII.CR & ASCII.LF);
      --  Receive characters from host terminal.
      Signal_Transmission_Complete (Term_COM.Incoming_Msg.all);
      Receive_Frame (Term_COM);
      --  Wait until the end of received characters from host terminal.
      Await_Reception_Complete (Term_COM.Incoming_Msg.all);

      Send_String ("Received : ");

      if (Get_Content_At (Term_COM.Incoming_Msg.all, 1) =
          Character'Pos (Get_Terminator (Term_COM.Incoming_Msg.all)))
      then
         Send_String ("no characters." & ASCII.LF & ASCII.CR);
      else
         declare
            --  The IntPos array has dynamic length, so we need to declare its
            --  size inside the loop.
            IntPos : UInt8_Array (1 .. Get_Length (Term_COM.Incoming_Msg.all));
         begin
            --  Loop back the received characters from the host.
            IntPos := Get_Content (Term_COM.Incoming_Msg.all);
            Await_Transmission_Complete (Term_COM.Outgoing_Msg.all);
            Set_Content (Term_COM.Outgoing_Msg.all, To => IntPos);
         end;
         Signal_Reception_Complete (Term_COM.Outgoing_Msg.all);
         Send_Frame (Term_COM);
         Send_String ("" & ASCII.LF); -- The frame already has CR
      end if;
      Send_String ("" & ASCII.CR & ASCII.LF);
   end loop;

end Demo_String;
