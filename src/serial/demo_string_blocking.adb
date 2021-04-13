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
with STM32.CRC;            use STM32.CRC;
with STM32.USARTs;         use STM32.USARTs;

with Peripherals_Blocking; use Peripherals_Blocking;
with Serial_IO.Blocking;   use Serial_IO.Blocking;
                           use Serial_IO;
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

   procedure Send (This : String);
     
   procedure Send (This : String) is
      Pos : UInt8;
      CharPos : Block_8 (1 .. This'Length);
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
   Configure (Term_COM, Baud_Rate => 115_200);
   Set_Serial_Mode (Term_COM, Terminal);
   
   -- Start with outgoing buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Outgoing); -- outgoing buffer
   
   -- Start with incoming buffer empty, so there is no need to wait.
   Signal_Transmission_Complete (Incoming); -- incoming buffer
   
   Send ("Enter text, terminated by CR." & ASCII.CR & ASCII.LF);
      
   Set_Terminator (Incoming, To => ASCII.CR);
   loop
      Await_Transmission_Complete (Incoming); -- incoming buffer
      Get (Term_COM, Incoming'Unchecked_Access);
      Signal_Reception_Complete (Incoming); -- incoming buffer
      Send ("Received : ");

      Await_Reception_Complete (Incoming); -- incoming buffer
      if (Get_Content_At (Incoming, 1) = Character'Pos(Incoming.Get_Terminator))  then
         Send ("no characters." & ASCII.CR & ASCII.LF);
      else
         declare
            IntPos : Block_8 (1 .. Get_Length (Incoming));
            -- The IntPos array has dynamic length, so we need to declare its size
            -- inside the loop.
         begin
            IntPos := Get_Content (Incoming);
            Await_Transmission_Complete (Outgoing); -- outgoing buffer
            Set_Content (Outgoing, To => IntPos);         
         end;
         Signal_Reception_Complete (Outgoing); -- outgoing buffer
         Await_Reception_Complete (Outgoing); -- outgoing buffer
         Put (Term_COM, Outgoing'Unchecked_Access);
         Signal_Transmission_Complete (Outgoing); -- outgoing buffer
         Send ("" & ASCII.LF); -- The frame already has CR
      end if;
      Signal_Transmission_Complete (Incoming);

   end loop;
   
end Demo_String_Blocking;
