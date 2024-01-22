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
with HAL;                  use HAL;
with STM32.USARTs;         use STM32.USARTs;

with Peripherals_Blocking; use Peripherals_Blocking;
with MBus_Frame.IO;        use MBus_Frame.IO;
with Serial_IO.Blocking;   use Serial_IO.Blocking, Serial_IO;
with Message_Buffers;      use Message_Buffers;

procedure Demo_String_Blocking is

   -------------
   -- Buffers --
   -------------

   Incoming : aliased Message (Physical_Size => 1024);  -- arbitrary size
   Outgoing : aliased Message (Physical_Size => 1024);  -- arbitrary size

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

      Await_Transmission_Complete (Outgoing);
      Set_Content (Outgoing, To => CharPos);
      Signal_Reception_Complete (Outgoing);
      Send_Frame (Term_COM, Outgoing);
   end Send_String;

begin
   --  The three modes of operation MBus_RTU, MBus_ASCII and Terminal for the
   --  serial channel are defined at Serial_IO.ads. This mode only affects the
   --  reception of data choosing the end of frame mode in the Receive procedure
   --  at Serial_IO.Blocking.

   --  Configuration for Terminal console
   Initialize (Term_COM);
   Configure (Term_COM, Baud_Rate => Term_Bps);
   Set_Serial_Mode (Term_COM, Terminal);
   --  We don't need to configure timeouts for Terminal serial port.

   --  Start with buffers empty, so there is no need to wait.
   Signal_Transmission_Complete (Outgoing);
   Signal_Transmission_Complete (Incoming);

   Set_Terminator (Incoming, To => ASCII.CR);

   Send_String (ASCII.FF & "Enter text, terminated by CR <Enter>."
                & ASCII.CR & ASCII.LF);

   loop
      Receive_Frame (Term_COM, Incoming);
      Send_String ("Received : ");

      Await_Reception_Complete (Incoming);
      if (Get_Content_At (Incoming, 1) = Character'Pos (Incoming.Get_Terminator))
      then
         Send_String ("no characters." & ASCII.CR & ASCII.LF);
      else
         declare
            --  The IntPos array has dynamic length, so we need to declare its
            --  size inside the loop.
            IntPos : UInt8_Array (1 .. Get_Length (Incoming));
         begin
            --  Loop back the received characters from the host.
            IntPos := Get_Content (Incoming);
            Await_Transmission_Complete (Outgoing);
            Set_Content (Outgoing, To => IntPos);
         end;
         Signal_Reception_Complete (Outgoing);
         Send_Frame (Term_COM, Outgoing);
         Send_String ("" & ASCII.LF); -- The frame already has CR
      end if;
      Signal_Transmission_Complete (Incoming);

   end loop;

end Demo_String_Blocking;
