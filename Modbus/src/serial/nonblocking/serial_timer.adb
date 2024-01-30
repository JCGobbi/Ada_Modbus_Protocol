with Message_Buffers;
with MBus;            use MBus;

package body Serial_Timer is

   -------------------------------
   -- MODBUS RTU Implementation --
   -------------------------------

   --  The implementation of RTU reception driver may imply the management of a
   --  lot of interruptions due to the t1.5 and t3.5 timers. With high
   --  communication baud rates, this leads to a heavy CPU load. Consequently
   --  these two timers must be strictly respected when the baud rate is equal
   --  or lower than 19200 Bps.

   --  For baud rates greater than 19200 Bps, fixed values for the 2 timers
   --  should be used: it is recommended to use a value of 750 µs for the
   --  inter-character time-out (t1.5) and a value of 1,750 µs for inter-frame
   --  delay (t3.5). Both values are calculated at 22000 Bps.

   --  Standard baud rates in bps are: 300, 600, 1200, 2400, 4800, 9600, 14400,
   --  19200, 38400, 57600, 115200, 230400, 460800.

   --  RTU protocol demands 11 bits per character.

   --  Max inter-character time between character at 9600 Bps is:
   --  1.5 * 11 bits per character / 9600 Bps = 1,718.75 µs.

   --  Min inter-frame time between frames at 9600 Bps is:
   --  3.5 * 11 bits per character / 9600 Bps = 4,010.42 µs.

   ----------------
   -- Inter_Time --
   ----------------

   function Inter_Time (Bps        : Baud_Rates;
                        Inter_Char : UInt32) return UInt32
   is
   begin
      if Bps <= 19_200 then
         return 10**5 * Inter_Char * 11 / Bps;
      else
         --  With bps > 19200, fixed time of 750 us for inter-character with
         --  Inter_Char = 15, and fixed time of 1750 us for inter-frame with
         --  Inter_Char = 35.
         return 10**5 * Inter_Char * 11 / 22_000;
      end if;
   end Inter_Time;

   ----------------------------------
   -- Configure_Response_Timeout --
   ----------------------------------

   procedure Configure_Response_Timeout (This : in out Timer;
                                         uSec : UInt32)
   is
   begin
      Set_Compare_Value
        (This,
         Channel    => Channel_3,
         Word_Value => uSec - 1);
   end Configure_Response_Timeout;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer (This : in out Timer)
   is
   begin
      STM32.Device.Enable_Clock (This);
      STM32.Device.Reset (This);

      Configure
        (This,
         Prescaler     => Prescaler,
         Period        => UInt32'Last,  --  all the way up
         Clock_Divisor => Div1,
         Counter_Mode  => Up);

      Configure_Prescaler
        (This,
         Prescaler   => Prescaler,
         Reload_Mode => Immediate);

      --  Configure timer channels for interchar, interframe and response
      --  timeouts.
      for Next_Channel in Channel_1 .. Channel_4 loop
         Configure_Channel_Output
           (This,
            Channel  => Next_Channel,
            Mode     => Frozen,
            State    => Enable,
            Pulse    => Channel_Periods (Next_Channel),
            Polarity => High);

         Set_Output_Preload_Enable (This, Next_Channel, False);
      end loop;

      Enable (This);
      Initialized := True;
   end Initialize_Timer;

   --------------------
   -- Is_Initialized --
   --------------------

   function Is_Initialized
      return Boolean is (Initialized);

   -----------------------
   -- Configure_Timeout --
   -----------------------

   procedure Configure_Timeout (This   : in out Timer;
                                MB_Bps : Baud_Rates)
   is
   begin
      --  The actual serial interrupt period is between two consecutive
      --  Received_Data_Not_Empty, so it includes the time between characters
      --  plus the time of 1 character. This must be taken into account in the
      --  inter-char and inter-frame periods.
      --
      --  Set the timeout for maximum inter-character time for modbus RTU
      --  operation. It is 1.5 + 1 character time.
      Channel_1_Period := Inter_Time (Bps => MB_Bps, Inter_Char => 25) - 1;
      --  Set the timeout for minimum inter-frame time for modbus RTU operation.
      --  It is 3.5 + 1 character time.
      Channel_2_Period := Inter_Time (Bps => MB_Bps, Inter_Char => 45) - 1;
      --  Set the timeout for response time for modbus RTU and ASCII operation.
      Channel_3_Period := 2_000_000 - 1;
      Channel_4_Period := 1_000_000 - 1;

      Initialize_Timer (This);
   end Configure_Timeout;

   -------------------
   -- Start_Timeout --
   -------------------

   procedure Start_Timeout (This : in out Timer;
                            Mode : Serial_Modes)
   is
   begin
      --  Re-initialize the counter and prescaler, and update registers.
      Configure_Prescaler
        (This,
         Prescaler   => Prescaler,
         Reload_Mode => Immediate);

      case Mode is
         when MBus_RTU =>
            --  Enable the timer channel interrupts for interchar, interframe
            --  and response timeouts.
            Enable_Interrupt (This, Timer_CC1_Interrupt &
                              Timer_CC2_Interrupt & Timer_CC3_Interrupt);

         when MBus_ASCII =>
            --  Enable the timer channel interrupt for response timeout.
            Enable_Interrupt (This, Timer_CC3_Interrupt);
         when Terminal =>
            --  Enable the timer channel interrupt for response timeout.
            Enable_Interrupt (This, Timer_CC3_Interrupt);
      end case;
      Enable_Interrupt (This, Timer_CC4_Interrupt);
   end Start_Timeout;

   ------------------
   -- Stop_Timeout --
   ------------------

   procedure Stop_Timeout (This    : in out Timer;
                           Channel : Timer_Channel)
   is
   begin
      case Channel is
         when Channel_1 =>
            Disable_Interrupt (This, Timer_CC1_Interrupt);
         when Channel_2 =>
            Disable_Interrupt (This, Timer_CC2_Interrupt);
         when Channel_3 =>
            Disable_Interrupt (This, Timer_CC3_Interrupt);
         when Channel_4 =>
            Disable_Interrupt (This, Timer_CC4_Interrupt);
      end case;
   end Stop_Timeout;

   ----------------
   -- Timer_Port --
   ----------------

   protected body Timer_Port is

      -----------------
      -- ISR_Handler --
      -----------------

      procedure ISR_Handler is
         Current : UInt32;
      begin
         if Status (Device.all, Timer_CC1_Indicated) then
            if Interrupt_Enabled (Device.all, Timer_CC1_Interrupt) then
               Clear_Pending_Interrupt (Device.all, Timer_CC1_Interrupt);

               --  Signalize that inter-character time is greater then the maximum.
               Message_Buffers.MBus_Note_Error (Serial_Periph.Incoming_Msg.all,
                                                InterChar_Timed_Out);
               --  Disable CC1 interrupt
               Stop_Timeout (Device.all, Channel_1);
            end if;
         end if;
         if Status (Device.all, Timer_CC2_Indicated) then
            if Interrupt_Enabled (Device.all, Timer_CC2_Interrupt) then
               Clear_Pending_Interrupt (Device.all, Timer_CC2_Interrupt);

               --  Signalize that inter-frame time is greater then the minimum.
               Message_Buffers.MBus_Note_Error (Serial_Periph.Incoming_Msg.all,
                                                InterFrame_Timed_Out);
               --  Disable CC2 interrupt
               Stop_Timeout (Device.all, Channel_2);
               --  End MBus_RTU frame reception.
               Disable_Interrupts (Serial_Periph.Device.Transceiver.all,
                                   Source => Received_Data_Not_Empty);
               Message_Buffers.Signal_Reception_Complete (Serial_Periph.Incoming_Msg.all);
            end if;
         end if;
         if Status (Device.all, Timer_CC3_Indicated) then
            if Interrupt_Enabled (Device.all, Timer_CC3_Interrupt) then
               Clear_Pending_Interrupt (Device.all, Timer_CC3_Interrupt);

               --  Signalize that response time is greater then the maximum.
               Message_Buffers.MBus_Note_Error (Serial_Periph.Incoming_Msg.all,
                                                Response_Timed_Out);
               --  Disable CC3 interrupt
               Stop_Timeout (Device.all, Channel_3);

               if Port.Get_Serial_Mode (Serial_Periph.all) = MBus_ASCII then
                  --  End MBus_ASCII frame reception.
                  Disable_Interrupts (Serial_Periph.Device.Transceiver.all,
                                      Source => Received_Data_Not_Empty);
                  Message_Buffers.Signal_Reception_Complete (Serial_Periph.Incoming_Msg.all);
               end if;
            end if;
         end if;
         if Status (Device.all, Timer_CC4_Indicated) then
            if Interrupt_Enabled (Device.all, Timer_CC4_Interrupt) then
               Clear_Pending_Interrupt (Device.all, Timer_CC4_Interrupt);

               Current := Current_Capture_Value (Device.all, Channel_4);
               Set_Compare_Value (Device.all, Channel_4, Current + Channel_4_Period);
            end if;
         end if;
      end ISR_Handler;
   end Timer_Port;

end Serial_Timer;
