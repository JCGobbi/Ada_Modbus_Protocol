with HAL;          use HAL;
with STM32.Device; use STM32.Device;

with MBus;         use MBus;

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
      Serial_IO.Configure (This.Device, Baud_Rate, Parity, Data_Bits, End_Bits, Control);
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

   procedure Set_InterChar_Timeout (This : in out Serial_Port; To : Time_Span) is
   begin
      This.InterChar_Timeout := To;
   end Set_InterChar_Timeout;

   ----------------------------
   -- Set_InterFrame_Timeout --
   ----------------------------

   procedure Set_InterFrame_Timeout (This : in out Serial_Port; To : Time_Span) is
   begin
      This.InterFrame_Timeout := To;
   end Set_InterFrame_Timeout;

   --------------------------
   -- Set_Response_Timeout --
   --------------------------

   procedure Set_Response_Timeout (This : in out Serial_Port;
                                   To : Time_Span := Time_Span_Last) is
   begin
      This.Response_Timeout := To;
   end Set_Response_Timeout;

   ---------
   -- Put --
   ---------

   procedure Put (This : in out Serial_Port;  Msg : not null access Message) is
   begin
      for Next in 1 .. Msg.Get_Length loop
         Await_Send_Ready (This.Device.Transceiver.all);
         Transmit (This.Device.Transceiver.all, UInt9(Msg.Get_Content_At (Next)));
      end loop;
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get (This : in out Serial_Port; Msg : not null access Message) is
      Raw : UInt9;
      Timed_Out : Boolean;
   begin
      Msg.Clear;
      Receiving : for K in 1 .. Msg.Physical_Size loop

         case This.Serial_Mode is
            when MBus_RTU =>
               -- Exit Await_Data_Available on Read_Data_Register_Not_Empty with
               -- time lesser than maximum inter-character time.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timeout   => This.InterChar_Timeout,
                                     Timed_Out => Timed_Out);
               if Timed_Out then -- Reached maximum inter-character time
              
                  -- Signalize that inter-character time is greater then the maximum.
                  Msg.MBus_Note_Error (InterChar_Timed_Out);

                  -- Exit Await_Data_Available on Read_Data_Register_Not_Empty or
                  -- minimum inter-frame time.
                  Await_Data_Available (This.Device.Transceiver.all,
                                        Timeout   => This.InterFrame_Timeout,
                                        Timed_Out => Timed_Out);
                  if Timed_Out then
                     -- Signalize that inter-frame time is greater then the minimum.
                     Msg.MBus_Note_Error (InterFrame_Timed_Out);

                     -- Exit Await_Data_Available on Read_Data_Register_Not_Empty or
                     -- maximum response time.
                     Await_Data_Available (This.Device.Transceiver.all,
                                           Timeout   => This.Response_Timeout,
                                           Timed_Out => Timed_Out);
                     if Timed_Out then
                        -- Signalize that response time is greater then the maximum.
                        Msg.MBus_Note_Error (Response_Timed_Out);
                     end if;
                     exit Receiving;
                  end if;
               end if;
            when MBus_ASCII =>
               -- Exit Await_Data_Available on Read_Data_Register_Not_Empty or
               -- maximum response time.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timeout   => This.Response_Timeout,
                                     Timed_Out => Timed_Out);
               if Timed_Out then
                  -- Signalize that response time is greater then the maximum.
                  Msg.MBus_Note_Error (Response_Timed_Out);
                  exit Receiving;
               end if;
            when Terminal =>
               -- Exit Await_Data_Available on Read_Data_Register_Not_Empty.
               Await_Data_Available (This.Device.Transceiver.all,
                                     Timed_Out => Timed_Out);
         end case;

         Receive (This.Device.Transceiver.all, Raw);

         case This.Serial_Mode is
            when MBus_RTU =>
               Msg.Append (UInt8(Raw));
            when MBus_ASCII =>
               Msg.Append (UInt8(Raw));
               -- Test end-frame sequence CR + LF for modbus ASCII.
               if (Msg.Get_Content_At (Msg.Get_Length - 1) = 16#0D# and -- CR character
                 Msg.Get_Content_At (Msg.Get_Length) = 16#0A#) then -- LF character
                  exit Receiving;
               end if;
            when Terminal =>
               -- Character CR is the last saved in the frame.
               Msg.Append (UInt8(Raw));
               exit Receiving when Raw = Character'Pos(Msg.Get_Terminator);
         end case;

      end loop Receiving;
   end Get;

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

   procedure Await_Data_Available (This    : USART;
                                  Timeout : Time_Span := Time_Span_Last;
                                  Timed_Out : out Boolean) is
   
      Deadline : constant Time := Clock + Timeout;
   begin
      Timed_Out := True;
      -- Await new characters until USART Read_Data_Register_Not_Empty but,
      -- if this doesn't happen, await until Clock = Timeout.
      while Clock < Deadline loop
         if Rx_Ready (This) then
            Timed_Out := False;
            exit;
         end if;
      end loop;
   end Await_Data_Available;

end Serial_IO.Blocking;
