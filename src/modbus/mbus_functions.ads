with HAL;                  use HAL;

with Peripherals_Blocking; use Peripherals_Blocking;
with Serial_IO.Blocking;   use Serial_IO.Blocking;
with Message_Buffers;      use Message_Buffers;
with MBus;                 use MBus;

package MBus_Functions is

   --------------------------------------
   -- Input and output modes of MODBUS --
   --------------------------------------

   --  The input and output operating modes RTU, ASCII and TCP are already set up
   --  at message_buffers.ads with default mode RTU.
   --  The input and output operating modes MBus_RTU, MBus_ASCII and Terminal for
   --  the modbus serial port are already set up at serial_io-blocking.ads with
   --  default mode MBus_RTU.
   --  Both configurations can be changed at any time with the sets bellow:

   --  MBus_Set_Mode change Message.MBus_Message_Mode at message_buffers.ads
   --  Set_Serial_Mode change Serial_Port.Serial_Mode at serial_io-blocking.ads

   --  MBus routines use internally a defined serial port to send and receive
   --  messages, so it is necessary to define a common serial port for all of
   --  them.
   MBus_Port : Serial_Port renames MBus_COM;

   -----------------------------------------
   -- Input and output buffers for MODBUS --
   -----------------------------------------

   --  These buffers may be configured here or inside the declarative part of
   --  the procedures WriteSend_Frame and ReadReceive_Frame defined bellow. If
   --  we define them here, these buffers will exist after each procedure close.
   --  If we define them inside each procedure, these buffers will not exist
   --  after the closing of the procedures.

   --  Inside the procedures, the WriteSend_Frame will need only the Outgoing
   --  buffers and the ReadReceive_Frame will only need the Incoming buffers.

   --  Both methods will correctly give the same result.

   Incoming : aliased Message (Physical_Size => 513);  -- max ASCII modbus size
   Outgoing : aliased Message (Physical_Size => 513);  -- max ASCII modbus size

   ------------------------------
   -- Procedures and functions --
   ------------------------------

   procedure Write_Frame (Msg            : in out Message;
                          Server_Address : MBus_Server_Address;
                          Function_Code  : UInt8;
                          Data_Chain     : UInt8_Array);

   procedure Read_Frame (Msg           : in out Message;
                         Server_Address : MBus_Server_Address;
                         Function_Code : UInt8;
                         Data_Chain    : in out UInt8_Array);

end MBus_Functions;
