with HAL;                  use HAL;
with STM32.USARTs;         use STM32.USARTs;

with Peripherals_Blocking; use Peripherals_Blocking;
with Serial_IO.Blocking;   use Serial_IO.Blocking;
with Message_Buffers;      use Message_Buffers;
with MBus;                 use MBus;

package MBus_Functions is

   --------------------------------------
   -- Input and output modes of MODBUS --
   --------------------------------------

   --  The input and output operating modes RTU, ASCII and TCP are already set up
   --  at MBus.ads with default mode RTU.
   --  The input and output operating modes MBus_RTU, MBus_ASCII and Terminal for
   --  the modbus serial port are already set up at Serial_IO.ads with default
   --  mode MBus_RTU.
   --  Both configurations can be changed at any time with the sets bellow:

   --  MBus_Mode   : RTU; -- for MBus_Set_Mode at mbus.ads
   --  Serial_Mode : MBus_RTU; -- for Set_Serial_Mode at serial_io.ads

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

   procedure MBus_Initialize (MB_Mode    : MBus_Modes;
                              MB_Address : MBus_Server_Address;
                              MB_Port    : in out Serial_Port;
                              MB_Bps     : Baud_Rates;
                              MB_Parity  : Parities);

   procedure Write_Frame (Msg            : in out Message;
                          Server_Address : MBus_Server_Address;
                          Function_Code  : UInt8;
                          Data_Chain     : UInt8_Array);

   procedure WriteSend_Frame (Msg            : in out Message;
                              Server_Address : MBus_Server_Address;
                              Function_Code  : UInt8;
                              Data_Chain     : UInt8_Array);

   procedure Read_Frame (Msg           : in out Message;
                         Server_Address : MBus_Server_Address;
                         Function_Code : UInt8;
                         Data_Chain    : in out UInt8_Array);

   procedure ReadReceive_Frame (Msg            : in out Message;
                                Server_Address : MBus_Server_Address;
                                Function_Code  : UInt8;
                                Data_Chain     : in out UInt8_Array);

end MBus_Functions;
