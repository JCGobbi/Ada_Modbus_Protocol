with Peripherals;
with MBus_Frame.IO;
--  with Message_Buffers;

package body MBus_Task is

   ------------------------------
   -- Receive_Frame_Controller --
   ------------------------------

   task body Receive_Frame_Controller is
   begin
      --  The synchronization for this task is done inside the Receive_Frame
      --  bellow because it "Await_Transmission_Complete (Incoming_Msg);".
      loop
         MBus_Frame.IO.Receive_Frame (Peripherals.MBus_Port);
      end loop;
   end Receive_Frame_Controller;

begin
   --  Initialization code that will be executed before the tasks are run.
   null;
end MBus_Task;
