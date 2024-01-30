with System;         use System;
with Ada.Interrupts; use Ada.Interrupts;
with HAL;            use HAL;

with STM32.Device;
with STM32.Timers;   use STM32.Timers;
with STM32.USARTs;   use STM32.USARTs;

with Serial_IO.Port;    use Serial_IO;

package Serial_Timer is

   type Timer_Port (Device        : not null access Timer;
                    IRQ           : Interrupt_ID;
                    IRQ_Priority  : Interrupt_Priority;
                    Serial_Periph : not null access Port.Serial_Port) is
     limited private;

   procedure Configure_Response_Timeout (This : in out Timer;
                                         uSec : UInt32);
   --  Configure response channel timeout in microseconds.

   procedure Configure_Timeout (This   : in out Timer;
                                MB_Bps : Baud_Rates);
   --  Initialize timeout timer and configure timeouts for inter-character,
   --  inter-frame and response.

   procedure Start_Timeout (This : in out Timer;
                            Mode : Serial_Modes);
   --  Reset the timer counters, enable interrupts and start the timeout
   --  counters.

   procedure Stop_Timeout (This    : in out Timer;
                           Channel : Timer_Channel);
   --  Disable timeout interrupts.

   function Is_Initialized return Boolean;
   --  Returns True if the board specifics are initialized.

private

   Initialized : Boolean := False;

   Serial_Timer_Clock : constant UInt32 :=
     STM32.Device.System_Clock_Frequencies.TIMCLK1;

   Prescaler : constant UInt16 := UInt16 (Serial_Timer_Clock / 1_000_000 - 1);
   --  With 84 MHz into the timer and 1 MHz into Counter we get a prescaler
   --  value of 84.

   --  STM32F429 operates at 168 MHz with 84 MHz into timer prescaler.
   --  With prescaler = (84 - 1) we have 1 MHz into Counter, so period has
   --  a 1 us unit time.
   --  With 300 bps minimum and 11 bits per frame, the maximum inter-frame
   --  period T3.5 will be 11*3.5/300 = 0.1283 s = 128333.3 us. The value to
   --  save into the counter will be 128333, so we use a timer with 32 bits
   --  counter. The programmed value into the counter will be the value in us.
   --  The response timeout may be any value lower then 2**32, that corresponds
   --  to 4.295E3 s.
   --  With bps > 19200 it is assumed a maximum 22000 bps, and with 11 bits per
   --  frame the minimum inter-char period T1.5 will be 11*1.5/22000 = 750 us,
   --  so the counter will have a value of 750.

   Channel_1_Period : UInt32 := 750 - 1; --  11*1.5/22000, 750 us
   --  Used for inter-character timeout when serial mode is MBus_RTU.
   Channel_2_Period : UInt32 := 1750 - 1; --  11*3.5/22000, 1750 us
   --  Used for inter-frame timeout when serial mode is MBus_RTU.
   Channel_3_Period : UInt32 := 2_000_000 - 1; --  2000 ms
   --  Used for response timeout. Timer 2 has a 32 bits counter.
   Channel_4_Period : UInt32 := 1_000_000 - 1; --  1 sec LED flashing test

   --  A convenience array for the sake of using a loop to configure the timer
   --  channels
   Channel_Periods : constant array (Channel_1 .. Channel_4) of UInt32 :=
     (Channel_1_Period,
      Channel_2_Period,
      Channel_3_Period,
      Channel_4_Period);

   function Inter_Time (Bps        : Baud_Rates;
                        Inter_Char : UInt32) return UInt32;
   --  Inter_Char is the number of characters in x10 parts.
   --  Maximum inter-character time is 1.5 char time, so Inter_Char is 15.
   --  Minimum inter-frame time is 3.5 char time, so Inter_Char is 35.

   procedure Initialize_Timer (This : in out Timer);
   --  Enable timer clock, configure prescaler and counter mode and the counter
   --  for each timer channel.

   protected type Timer_Port (Device        : not null access Timer;
                              IRQ           : Interrupt_ID;
                              IRQ_Priority  : Interrupt_Priority;
                              Serial_Periph : not null access Port.Serial_Port)
   is
      pragma Interrupt_Priority (IRQ_Priority);
   private
      procedure ISR_Handler with
        Attach_Handler => IRQ;
   end Timer_Port;

end Serial_Timer;
