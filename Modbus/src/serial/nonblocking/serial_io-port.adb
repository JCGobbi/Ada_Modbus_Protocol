with HAL;  use HAL;

with Serial_Timer;

package body Serial_IO.Port is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (This : out Serial_Port) is
   begin
      Serial_IO.Initialize_Peripheral (This.Device);
      This.Set_Initialized (True);
   end Initialize;

   -----------------
   -- Initialized --
   -----------------

   function Initialized (This : Serial_Port) return Boolean is
   begin
      return This.Get_Initialized;
   end Initialized;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (This      : in out Serial_Port;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control)
   is
   begin
      Serial_IO.Configure (This.Device,
                           Baud_Rate,
                           Parity,
                           Data_Bits,
                           End_Bits,
                           Control);
   end Configure;

   ---------------------
   -- Get_Serial_Mode --
   ---------------------

   function Get_Serial_Mode (This : in out Serial_Port) return Serial_Modes is
   begin
      return This.Get_Serial_Mode;
   end Get_Serial_Mode;

   ---------------------
   -- Set_Serial_Mode --
   ---------------------

   procedure Set_Serial_Mode (This : in out Serial_Port; To : Serial_Modes) is
   begin
      This.Set_Serial_Mode (To);
   end Set_Serial_Mode;

   ----------
   -- Send --
   ----------

   procedure Send (This : in out Serial_Port)
   is
   begin
      This.Start_Sending (This.Outgoing_Msg);
   end Send;

   -------------
   -- Receive --
   -------------

   procedure Receive (This : in out Serial_Port)
   is
   begin
      This.Start_Receiving (This.Incoming_Msg);
   end Receive;

   -----------------
   -- Serial_Port --
   -----------------

   protected body Serial_Port is

      -------------------
      -- Start_Sending --
      -------------------

      procedure Start_Sending (Msg : not null access Message) is
      begin
         Out_Message := Msg;
         Next_Out := 1;

         Enable_Interrupts (Device.Transceiver.all, Parity_Error);
         Enable_Interrupts (Device.Transceiver.all, Error);
         Enable_Interrupts (Device.Transceiver.all, Transmission_Complete);
      end Start_Sending;

      ---------------------
      -- Start_Receiving --
      ---------------------

      procedure Start_Receiving (Msg : not null access Message) is
      begin
         In_Message := Msg;
         Clear (In_Message.all);

         Enable_Interrupts (Device.Transceiver.all, Parity_Error);
         Enable_Interrupts (Device.Transceiver.all, Error);
         Enable_Interrupts (Device.Transceiver.all, Received_Data_Not_Empty);
      end Start_Receiving;

      ---------------------
      -- Set_Initialized --
      ---------------------

      procedure Set_Initialized (Val : Boolean) is
      begin
         Profile.Initialized := Val;
      end Set_Initialized;

      ---------------------
      -- Get_Initialized --
      ---------------------

      function Get_Initialized return Boolean is
      begin
         return Profile.Initialized;
      end Get_Initialized;

      ---------------------
      -- Set_Serial_Mode --
      ---------------------

      procedure Set_Serial_Mode (Val : Serial_Modes) is
      begin
         Profile.Serial_Mode := Val;
      end Set_Serial_Mode;

      ---------------------
      -- Get_Serial_Mode --
      ---------------------

      function Get_Serial_Mode return Serial_Modes is
      begin
         return Profile.Serial_Mode;
      end Get_Serial_Mode;

      -------------------------
      -- Handle_Transmission --
      -------------------------

      procedure Handle_Transmission is
      begin
         Transmit (Device.Transceiver.all,
                   UInt9 (Out_Message.Get_Content_At (Next_Out)));
         Next_Out := Next_Out + 1;

         if Next_Out > Out_Message.Get_Length then
            Disable_Interrupts (Device.Transceiver.all,
                                Source => Transmission_Complete);
            Signal_Transmission_Complete (Out_Message.all); -- serial outgoing buffer
            Out_Message := null;
         end if;
      end Handle_Transmission;

      ------------------------
      -- Reception_Complete --
      ------------------------

      procedure Reception_Complete is
      begin
         loop
            --  Wait for device to clear the status
            exit when not Status (Device.Transceiver.all, Read_Data_Register_Not_Empty);
         end loop;
         Disable_Interrupts (Device.Transceiver.all, Source => Received_Data_Not_Empty);
         Signal_Reception_Complete (In_Message.all);
         In_Message := null;
      end Reception_Complete;

      ----------------------
      -- Handle_Reception --
      ----------------------

      procedure Handle_Reception is
         Raw : constant UInt8 := UInt8 (Current_Input (Device.Transceiver.all));
      begin
         case Get_Serial_Mode is
            when MBus_RTU =>
               In_Message.Append (Raw);
            when MBus_ASCII =>
               In_Message.Append (Raw);
               --  Test end-frame sequence CR + LF for modbus ASCII.
               if In_Message.Get_Length > 1 then
                  if In_Message.Get_Content_At
                       (In_Message.Get_Length) = 16#0A# and -- CR character
                    In_Message.Get_Content_At
                      (In_Message.Get_Length - 1) = 16#0D# -- LF character
                  then
                     Reception_Complete;
                  end if;
               end if;
            when Terminal =>
               In_Message.Append (Raw);
               --  Character CR is saved in the frame.
               if Raw = Character'Pos (In_Message.Get_Terminator) or
                 In_Message.Get_Length = In_Message.Physical_Size
               then
                  Reception_Complete;
               end if;
         end case;
      end Handle_Reception;

      -------------------
      -- Detect_Errors --
      -------------------

      procedure Detect_Errors (Is_Xmit_IRQ : Boolean) is
      begin
         if Status (Device.Transceiver.all, Parity_Error_Indicated) and
           Interrupt_Enabled (Device.Transceiver.all, Parity_Error)
         then
            Clear_Status (Device.Transceiver.all, Parity_Error_Indicated);
            if Is_Xmit_IRQ then
               Out_Message.Note_Error (Parity_Error_Detected);
            else
               In_Message.Note_Error (Parity_Error_Detected);
            end if;
         end if;

         if Status (Device.Transceiver.all, Framing_Error_Indicated) and
           Interrupt_Enabled (Device.Transceiver.all, Error)
         then
            Clear_Status (Device.Transceiver.all, Framing_Error_Indicated);
            if Is_Xmit_IRQ then
               Out_Message.Note_Error (Frame_Error_Detected);
            else
               In_Message.Note_Error (Frame_Error_Detected);
            end if;
         end if;

         if Status (Device.Transceiver.all, USART_Noise_Error_Indicated) and
           Interrupt_Enabled (Device.Transceiver.all, Error)
         then
            Clear_Status (Device.Transceiver.all, USART_Noise_Error_Indicated);
            if Is_Xmit_IRQ then
               Out_Message.Note_Error (Noise_Error_Detected);
            else
               In_Message.Note_Error (Noise_Error_Detected);
            end if;
         end if;

         if Status (Device.Transceiver.all, Overrun_Error_Indicated) and
           Interrupt_Enabled (Device.Transceiver.all, Error)
         then
            Clear_Status (Device.Transceiver.all, Overrun_Error_Indicated);
            if Is_Xmit_IRQ then
               Out_Message.Note_Error (Overrun_Error_Detected);
            else
               In_Message.Note_Error (Overrun_Error_Detected);
            end if;
         end if;
      end Detect_Errors;

      -----------------
      -- IRQ_Handler --
      -----------------

      procedure IRQ_Handler is
      begin
         --  check for transmission ready
         if Status (Device.Transceiver.all, Transmission_Complete_Indicated) and
           Interrupt_Enabled (Device.Transceiver.all, Transmission_Complete)
         then
            Clear_Status (Device.Transceiver.all, Transmission_Complete_Indicated);
            Detect_Errors (Is_Xmit_IRQ => True);
            Handle_Transmission;
         end if;

         --  check for data arrival
         if Status (Device.Transceiver.all, Read_Data_Register_Not_Empty) and
           Interrupt_Enabled (Device.Transceiver.all, Received_Data_Not_Empty)
         then
            --  Restart timeout timer for interchar, interframe and response
            --  timeouts.
            Serial_Timer.Start_Timeout (Timer_Periph.all, Mode => Get_Serial_Mode);

            Clear_Status (Device.Transceiver.all, Read_Data_Register_Not_Empty);
            Detect_Errors (Is_Xmit_IRQ => False);
            Handle_Reception;
         end if;

      end IRQ_Handler;

   end Serial_Port;

end Serial_IO.Port;
