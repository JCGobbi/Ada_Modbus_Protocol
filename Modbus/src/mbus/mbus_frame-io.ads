with Serial_IO.Port; use Serial_IO.Port;

package MBus_Frame.IO is

   procedure Send_Frame (This : in out Serial_Port)
     with Pre => Get_Length (This.Outgoing_Msg.all) /= 0;
   --  Send the frame in the outgoing buffer to the serial port.

   procedure Receive_Frame (This : in out Serial_Port);
   --  Receive the frame in the the serial port to the incoming buffer.

end MBus_Frame.IO;
