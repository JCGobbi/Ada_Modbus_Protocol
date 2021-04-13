with Serial_IO.Blocking; use Serial_IO.Blocking;

package MBus_Frame.IO is

   procedure Send_Frame (This : in out Serial_Port; Msg : in out Message);
   -- Send the frame in the outgoing buffer to the serial port.

   procedure Receive_Frame (This : in out Serial_Port; Msg : in out Message);
   -- Receive the frame in the the serial port to the incoming buffer.

end MBus_Frame.IO;
