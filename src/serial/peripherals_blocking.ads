with STM32.Device;       use STM32.Device;

with Serial_IO.Blocking; use Serial_IO;

package Peripherals_Blocking is

   --  This specific USART is in the programming USB.
   --  It is used for monitoring the modbus communication.
   Term_Peripheral : aliased Peripheral_Descriptor :=
                  (Transceiver    => USART_3'Access,
                   Transceiver_AF => GPIO_AF_USART3_7,
                   Tx_Pin         => PD8,
                   Rx_Pin         => PD9);

   Term_COM : Blocking.Serial_Port (Term_Peripheral'Access);

   --  This USART is used for modbus protocol.
   MBus_Peripheral : aliased Peripheral_Descriptor :=
                  (Transceiver    => USART_6'Access,
                   Transceiver_AF => GPIO_AF_USART6_8,
                   Tx_Pin         => PG14,
                   Rx_Pin         => PG9);

   MBus_COM : Blocking.Serial_Port (MBus_Peripheral'Access);

end Peripherals_Blocking;
