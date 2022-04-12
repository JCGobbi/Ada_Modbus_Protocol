with STM32.Device;

package body Serial_IO is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize_Peripheral (Periph : access Peripheral_Descriptor) is
      Configuration : GPIO_Port_Configuration;
      Periph_Pins   : constant GPIO_Points := Periph.Rx_Pin & Periph.Tx_Pin;
   begin
      STM32.Device.Enable_Clock (Periph_Pins);
      STM32.Device.Enable_Clock (Periph.Transceiver.all);

      Configuration := (Mode           => Mode_AF,
                        AF             => Periph.Transceiver_AF,
                        AF_Speed       => Speed_50MHz,
                        AF_Output_Type => Push_Pull,
                        Resistors      => Pull_Up);

      Configure_IO (Periph_Pins, Configuration);
   end Initialize_Peripheral;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Periph    : access Peripheral_Descriptor;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control)
   is
   begin
      Disable (Periph.Transceiver.all);

      Set_Baud_Rate    (Periph.Transceiver.all, Baud_Rate);
      Set_Mode         (Periph.Transceiver.all, Tx_Rx_Mode);
      Set_Stop_Bits    (Periph.Transceiver.all, End_Bits);
      Set_Word_Length  (Periph.Transceiver.all, Data_Bits);
      Set_Parity       (Periph.Transceiver.all, Parity);
      Set_Flow_Control (Periph.Transceiver.all, Control);

      Enable (Periph.Transceiver.all);
   end Configure;

end Serial_IO;
