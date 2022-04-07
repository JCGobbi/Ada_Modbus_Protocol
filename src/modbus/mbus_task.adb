with Peripherals_Blocking; use Peripherals_Blocking;
with MBus_Frame.IO;        use MBus_Frame.IO;
with MBus_Functions;       use MBus_Functions;

package body MBus_Task is

   ------------------------------
   -- Receive_Frame_Controller --
   ------------------------------

   task body Receive_Frame_Controller is

   begin
      --  The synchronization for this task is done inside
      --  the Receive_Frame (MBus_COM, Incoming) because it
      --  Await_Transmission_Complete (Incoming); -- incoming buffer
      loop
         Receive_Frame (MBus_COM, Incoming);
      end loop;
   end Receive_Frame_Controller;

begin
   --  Initialization code that will be executed before the tasks are run.

   null;

end MBus_Task;
