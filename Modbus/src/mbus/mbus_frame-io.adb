package body MBus_Frame.IO is

   ----------------
   -- Send_Frame --
   ----------------

   procedure Send_Frame (This : in out Serial_Port) is
   begin
      Await_Reception_Complete (This.Outgoing_Msg.all);

      Send (This);
      --  At the end of frame transmission, Send will set the flag
      --  "Signal_Transmission_Complete (This.Outgoing_Msg.all);" on the
      --  outgoing buffer.
   end Send_Frame;

   -------------------
   -- Receive_Frame --
   -------------------

   procedure Receive_Frame (This : in out Serial_Port) is
   begin
      Await_Transmission_Complete (This.Incoming_Msg.all); -- incoming buffer
      --  Put frame from serial port to Incoming buffer
      Receive (This);
      --  At the end of frame reception, Receive will set the flag
      --  "Signal_Reception_Complete (This.Incoming_Msg.all);" on the incoming
      --  buffer.
   end Receive_Frame;

end MBus_Frame.IO;
