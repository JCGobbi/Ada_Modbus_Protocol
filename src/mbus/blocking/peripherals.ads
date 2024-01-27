with STM32.Device;    use STM32.Device;

with Message_Buffers; use Message_Buffers;
with Serial_IO.Port;  use Serial_IO;

package Peripherals is

   ------------------------------------------------------
   -- Input and output buffers for MODBUS and Terminal --
   ------------------------------------------------------

   --  These buffers are used only for the terminal serial port.
   Term_Outgoing : aliased Message (Physical_Size => 1024);
   Term_Incoming : aliased Message (Physical_Size => 1024);

   --  These buffers are used for the MODBUS serial port. The size of these
   --  buffers are the max ASCII modbus size.
   MBus_Outgoing : aliased Message (Physical_Size => 513);
   MBus_Incoming : aliased Message (Physical_Size => 513);

   --  This specific USART is in the programming USB.
   --  It is used for monitoring the modbus communication.
   Term_Peripheral : aliased Peripheral_Descriptor :=
                               (Transceiver    => USART_3'Access,
                                Transceiver_AF => GPIO_AF_USART3_7,
                                Tx_Pin         => PD8,
                                Rx_Pin         => PD9);

   Term_COM : Port.Serial_Port (Device       => Term_Peripheral'Access,
                                Outgoing_Msg => Term_Outgoing'Access,
                                Incoming_Msg => Term_Incoming'Access);

   --  This USART is used for modbus protocol.
   MBus_Peripheral : aliased Peripheral_Descriptor :=
                               (Transceiver    => USART_6'Access,
                                Transceiver_AF => GPIO_AF_USART6_8,
                                Tx_Pin         => PG14,
                                Rx_Pin         => PG9);

   MBus_COM : Port.Serial_Port (Device       => MBus_Peripheral'Access,
                                Outgoing_Msg => MBus_Outgoing'Access,
                                Incoming_Msg => MBus_Incoming'Access);

   --  MBus routines use internally a defined serial port to send and receive
   --  messages, so it is necessary to define a common serial port for all of
   --  them.
   MBus_Port : Port.Serial_Port renames MBus_COM;

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

end Peripherals;
