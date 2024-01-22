with HAL;  use HAL;

with MBus; use MBus;

package body Serial_IO.Blocking is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (This : out Serial_Port) is
   begin
      Serial_IO.Initialize_Peripheral (This.Device);
      This.Initialized := True;
   end Initialize;

   -----------------
   -- Initialized --
   -----------------

   function Initialized (This : Serial_Port) return Boolean is
     (This.Initialized);

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
      return This.Serial_Mode;
   end Get_Serial_Mode;

   ---------------------
   -- Set_Serial_Mode --
   ---------------------

   procedure Set_Serial_Mode (This : in out Serial_Port; To : Serial_Modes) is
   begin
      This.Serial_Mode := To;
   end Set_Serial_Mode;

   ---------------------------
   -- Set_InterChar_Timeout --
   ---------------------------

   procedure Set_InterChar_Timeout (This : in out Serial_Port;
                                    To   : Time_Span)
   is
   begin
      This.InterChar_Timeout := To;
   end Set_InterChar_Timeout;

   ----------------------------
   -- Set_InterFrame_Timeout --
   ----------------------------

   procedure Set_InterFrame_Timeout (This : in out Serial_Port;
                                     To   : Time_Span)
   is
   begin
      This.InterFrame_Timeout := To;
   end Set_InterFrame_Timeout;

   --------------------------
   -- Set_Response_Timeout --
   --------------------------

   procedure Set_Response_Timeout (This : in out Serial_Port;
                                   To   : Time_Span := Time_Span_Last)
   is
   begin
      This.Response_Timeout := To;
   end Set_Response_Timeout;

   -------------------------------
   -- MODBUS RTU Implementation --
   -------------------------------

   --  The implementation of RTU reception driver may imply the management of a
   --  lot of interruptions due to the t1.5 and t3.5 timers. With high
   --  communication baud rates, this leads to a heavy CPU load. Consequently
   --  these two timers must be strictly respected when the baud rate is equal
   --  or lower than 19200 Bps.

   --  For baud rates greater than 19200 Bps, fixed values for the 2 timers
   --  should be used: it is recommended to use a value of 750µs for the
   --  inter-character time-out (t1.5) and a value of 1.750ms for inter-frame
   --  delay (t3.5). Both values are calculated at 22000 Bps.

   --  Standard baud rates in bps are: 300, 600, 1200, 2400, 4800, 9600, 14400,
   --  19200, 38400, 57600, 115200, 230400, 460800.

   --  RTU protocol demands 11 bits per character.

   --  Max inter-character time between character at 9600 Bps is:
   --  1.5 * 11 bits per character / 9600 Bps = 1.71875 ms.

   --  Min inter-frame time between frames at 9600 Bps is:
   --  3.5 * 11 bits per character / 9600 Bps = 4.0104 ms.

   ----------------
   -- Inter_Time --
   ----------------

   function Inter_Time (Bps        : Baud_Rates;
                        Inter_Char : Natural) return Time_Span
   is
   begin
      if Bps <= 19_200 then
         return Microseconds ((10**5 * Inter_Char * 11) / Integer (Bps));
      else
         --  With bps > 19200, fixed time of 750 us for inter-character with
         --  Inter_Char = 15, and fixed time of 1750 us for inter-frame with
         --  Inter_Char = 35.
         return Microseconds ((10**5 * Inter_Char * 11) / 22_000);
      end if;
   end Inter_Time;

   -----------------------
   -- Configure_Timeout --
   -----------------------

   procedure Configure_Timeout (This   : in out Serial_Port;
                                MB_Bps : Baud_Rates)
   is
      Timeout  : Time_Span;
   begin
      --  Set the timeout for maximum inter-character time for modbus RTU operation.
      Timeout := Inter_Time (Bps => MB_Bps, Inter_Char => 15);
      Set_InterChar_Timeout (This, Timeout);

      --  Set the timeout for minimum inter-frame time for modbus RTU operation.
      --  This time must consider the inter-character elapsed time above.
      Timeout := Inter_Time (Bps => MB_Bps, Inter_Char => 20);
      Set_InterFrame_Timeout (This, Timeout);

      --  Set the timeout for response time for modbus RTU and ASCII operation.
      Timeout := Milliseconds (2_000);
      Set_Response_Timeout (This, Timeout);

   end Configure_Timeout;

   ----------
   -- Send --
   ----------

   procedure Send (This : in out Serial_Port;
                   Msg  : not null access Message)
   is
   begin
      for Next in 1 .. Msg.Get_Length loop
         Await_Send_Ready (This.Device.Transceiver.all);
         Transmit (This.Device.Transceiver.all, UInt9 (Msg.Get_Content_At (Next)));
      end loop;
   end Send;

   -------------
   -- Receive --
   -------------

   procedure Receive (This : in out Serial_Port;
                      Msg  : not null access Message)
   is
      Raw : UInt9;
      Timed_Out : Boolean;
   begin
      Msg.Clear;
      Receiving : for K in 1 .. Msg.Physical_Size loop

         case This.Serial_Mode is
            when MBus_RTU =>
               --  Exit Await_Data_Available on Read_Data_Register_Not_Empty with
               --  time lesser than maximum inter-character time.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timeout   => This.InterChar_Timeout,
                                     Timed_Out => Timed_Out);
               if Timed_Out then -- Reached maximum inter-character time

                  --  Signalize that inter-character time is greater then the maximum.
                  Msg.MBus_Note_Error (InterChar_Timed_Out);

                  --  Exit Await_Data_Available on Read_Data_Register_Not_Empty or
                  --  minimum inter-frame time.
                  Await_Data_Available (This.Device.Transceiver.all,
                                        Timeout   => This.InterFrame_Timeout,
                                        Timed_Out => Timed_Out);
                  if Timed_Out then --  Reached maximum inter-frame time
                     --  Signalize that inter-frame time is greater then the minimum.
                     Msg.MBus_Note_Error (InterFrame_Timed_Out);

                     --  Exit Await_Data_Available on Read_Data_Register_Not_Empty or
                     --  maximum response time.
                     Await_Data_Available (This.Device.Transceiver.all,
                                           Timeout   => This.Response_Timeout,
                                           Timed_Out => Timed_Out);
                     if Timed_Out then --  Reached maximum response time
                        --  Signalize that response time is greater then the maximum.
                        Msg.MBus_Note_Error (Response_Timed_Out);
                     end if;
                     exit Receiving;
                  end if;
               end if;
            when MBus_ASCII =>
               --  Exit Await_Data_Available on Read_Data_Register_Not_Empty or
               --  maximum response time.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timeout   => This.Response_Timeout,
                                     Timed_Out => Timed_Out);
               if Timed_Out then --  Reached maximum response time
                  --  Signalize that response time is greater then the maximum.
                  Msg.MBus_Note_Error (Response_Timed_Out);
                  exit Receiving;
               end if;
            when Terminal =>
               --  Exit Await_Data_Available on Read_Data_Register_Not_Empty.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timed_Out => Timed_Out);
               if Timed_Out then -- Reached maximum response time
                  --  Signalize that response time is greater then the maximum.
                  Msg.MBus_Note_Error (Response_Timed_Out);
               end if;
         end case;

         if Rx_Ready (This.Device.Transceiver.all) then
            Receive (This.Device.Transceiver.all, Raw);

            case This.Serial_Mode is
               when MBus_RTU =>
                  Msg.Append (UInt8 (Raw));
               when MBus_ASCII =>
                  Msg.Append (UInt8 (Raw));
                  --  Test end-frame sequence CR + LF for modbus ASCII.
                  if Msg.Get_Length > 1 then
                     if Msg.Get_Content_At (Msg.Get_Length) = 16#0A# and -- LF character
                        Msg.Get_Content_At (Msg.Get_Length - 1) = 16#0D# -- CR character
                     then
                        exit Receiving;
                     end if;
                  end if;
               when Terminal =>
                  --  Character CR is the last saved in the frame.
                  Msg.Append (UInt8 (Raw));
                  exit Receiving when UInt8 (Raw) = Character'Pos (Msg.Get_Terminator);
            end case;
            Clear_Status (This.Device.Transceiver.all, Read_Data_Register_Not_Empty);
         end if;

      end loop Receiving;
   end Receive;

   ----------------------
   -- Await_Send_Ready --
   ----------------------

   procedure Await_Send_Ready (This : USART) is
   begin
      loop
         exit when Tx_Ready (This);
      end loop;
   end Await_Send_Ready;

   --------------------------
   -- Await_Data_Available --
   --------------------------

   procedure Await_Data_Available
     (This    : USART;
      Timeout : Time_Span := Time_Span_Last;
      Timed_Out : out Boolean)
   is
      Deadline : constant Time := Clock + Timeout;
   begin
      Timed_Out := True;
      --  Await new characters until USART Read_Data_Register_Not_Empty but,
      --  if this doesn't happen, await until Clock = Timeout.
      while Clock < Deadline loop
         if Rx_Ready (This) then
            Timed_Out := False;
            exit;
         end if;
      end loop;
   end Await_Data_Available;

end Serial_IO.Blocking;
