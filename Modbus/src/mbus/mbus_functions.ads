with HAL;              use HAL;

with Message_Buffers;  use Message_Buffers;
with MBus;             use MBus;

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

   ------------------------------
   -- Procedures and functions --
   ------------------------------

   procedure Write_Frame (Msg            : in out Message;
                          Server_Address : MBus_Server_Address;
                          Function_Code  : UInt8;
                          Data_Chain     : UInt8_Array);
   --  Write the complete RTU or ASCII modbus frame with head and tail in the
   --  outgoing message buffer, including the calculation of CRC for RTU or LRC
   --  for ASCII.

   procedure Read_Frame (Msg            : in out Message;
                         Server_Address : MBus_Server_Address;
                         Function_Code  : UInt8;
                         Data_Chain     : in out UInt8_Array);
   --  Read from the incoming message buffer the complete RTU or ASCII modbus
   --  frame with head and tail to a byte array.

end MBus_Functions;
