with HAL;           use HAL;
with STM32;         use STM32;
with STM32.GPIO;    use STM32.GPIO;
with STM32.USARTs;  use STM32.USARTs;

package Serial_IO is

   ------------------------------------------------
   -- Baud rates for MODBUS and terminal console --
   ------------------------------------------------

   MBus_Bps : Baud_Rates := 9_600;
   Term_Bps : Baud_Rates := 115_200;

   -- Mode selection for the serial channel: modbus RTU, modbus ASCII and Terminal
   type Serial_Modes is (MBus_RTU, MBus_ASCII, Terminal);

   type Peripheral_Descriptor is record
      Transceiver    : not null access USART;
      Transceiver_AF : GPIO_Alternate_Function;
      Tx_Pin         : GPIO_Point;
      Rx_Pin         : GPIO_Point;
   end record;

   procedure Initialize_Peripheral (Device : access Peripheral_Descriptor);

   procedure Configure
     (Device    : access Peripheral_Descriptor;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control);

   type Error_Conditions is mod 256;

   No_Error_Detected      : constant Error_Conditions := 2#0000_0000#;
   Parity_Error_Detected  : constant Error_Conditions := 2#0000_0001#;
   Noise_Error_Detected   : constant Error_Conditions := 2#0000_0010#;
   Frame_Error_Detected   : constant Error_Conditions := 2#0000_0100#;
   Overrun_Error_Detected : constant Error_Conditions := 2#0000_1000#;
   DMA_Error_Detected     : constant Error_Conditions := 2#0001_0000#;

end Serial_IO;
