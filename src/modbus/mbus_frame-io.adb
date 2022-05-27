package body MBus_Frame.IO is

   ----------------
   -- Send_Frame --
   ----------------

   procedure Send_Frame (This : in out Serial_Port;  Msg : in out Message) is
   begin
      Await_Reception_Complete (Msg); -- serial outgoing buffer

      if (Get_Length (Msg) /= 0) then -- The min length is 4 UInt8 bytes
         Send (This, Msg'Unchecked_Access);
         --  No need to wait for it here because the Put won't return until the
         --  message has been sent
      end if;

      Signal_Transmission_Complete (Msg); -- serial outgoing buffer

   end Send_Frame;

   -------------------
   -- Receive_Frame --
   -------------------

   procedure Receive_Frame (This : in out Serial_Port; Msg : in out Message) is
   begin
      Await_Transmission_Complete (Msg); -- incoming buffer
      --  Put frame from serial port to Incoming buffer
      Receive (This, Msg'Unchecked_Access);

      Signal_Reception_Complete (Msg); -- incoming buffer

   end Receive_Frame;

end MBus_Frame.IO;
