package body MBus_Frame is

   ----------------------
   -- MBus_Get_Address --
   ----------------------

   -- Get the initial byte of the frame with modbus server address value for RTU.
   -- Get the two chars with modbus server address value for ASCII.
   function MBus_Get_Address (This : Message) return UInt8 is
      Box : UInt8;
   begin
      case MBus_Get_Mode (This) is
         when RTU =>
            return Get_Content_At (This, 1);
         when ASC =>
            -- Low-order byte before high-order byte
            Box := Get_ASCII_Val (Get_Content_At (This, 2));
            Box := Box or Shift_Left(Get_ASCII_Val (Get_Content_At (This, 3)), 4);
            return Box;
         when TCP =>
            return 0;
      end case;
   end MBus_Get_Address;

   ----------------------
   -- MBus_Set_Address --
   ----------------------

   -- Put the initial byte of the frame with modbus server address value for RTU.
   -- Put the start char ":" and the two chars with modbus server address value for ASCII.
   procedure MBus_Set_Address (This : in out Message;  To : UInt8) is
   begin
      case MBus_Get_Mode (This) is
         when RTU =>
            Set_Start (This, To);
         when ASC =>
            Set_Start (This, Character'Pos(':')); -- Start character
            -- Low-order byte before high-order byte
            Append (This, Get_ASCII_Pos (To and 16#0F#));
            Append (This, Get_ASCII_Pos (Shift_Right(To, 4)));
         when TCP =>
            null;
      end case;
   end MBus_Set_Address;

   ----------------------------
   -- MBus_Get_Function_Code --
   ----------------------------

   function MBus_Get_Function_Code (This : Message) return UInt8 is
      Box : UInt8;
   begin
      case MBus_Get_Mode (This) is
         when RTU =>
            return Get_Content_At (This, 2);
         when ASC => -- Low-order byte before high-order byte
            Box := Get_ASCII_Val (Get_Content_At (This, 4));
            Box := Box or Shift_Left(Get_ASCII_Val (Get_Content_At (This, 5)), 4);
            return Box;
         when TCP =>
            return 0;
      end case;
   end MBus_Get_Function_Code;

   ----------------------------
   -- MBus_Set_Function_Code --
   ----------------------------

   -- Put the byte with modbus funtion code value for RTU.
   -- Put the two chars with modbus function code value for ASCII.
   procedure MBus_Set_Function_Code (This : in out Message;  To : UInt8) is
   begin
      case MBus_Get_Mode (This) is
         when RTU =>
            Append (This, To);
         when ASC => -- Low-order byte before high-order byte
            Append (This, Get_ASCII_Pos (To and 16#0F#));
            Append (This, Get_ASCII_Pos (Shift_Right(To, 4)));
         when TCP =>
            null;
      end case;
   end MBus_Set_Function_Code;

   ----------------------
   -- MBus_Get_Data_At --
   ----------------------

   function MBus_Get_Data_At (This : Message; Index : Positive) return UInt8 is
      Box : UInt8;
   begin
      case MBus_Get_Mode (This) is
         when RTU => -- Takes a byte starting at 1st position of buffer
            return Get_Content_At (This, Index);
         when ASC =>
            -- Takes a pair of chars starting at 2nd position of buffer
            -- High-order byte before low-order byte
            Box := Shift_Left(Get_ASCII_Val (Get_Content_At (This, Index * 2)), 4);
            Box := Box or Get_ASCII_Val (Get_Content_At (This, (Index * 2) + 1));
            return Box;
         when TCP =>
            return 0;
      end case;
   end MBus_Get_Data_At;

   ----------------------
   -- MBus_Append_Data --
   ----------------------

   -- Put the next byte with modbus data value for RTU.
   -- Put the next two chars with modbus data value for ASCII.
   procedure MBus_Append_Data (This : in out Message;  To : UInt8) is
   begin
      case MBus_Get_Mode (This) is
         when RTU =>
            Append (This, To);
         when ASC => -- High-order byte before low-order byte
            Append (This, Get_ASCII_Pos (Shift_Right(To, 4)));
            Append (This, Get_ASCII_Pos (To and 16#0F#));
         when TCP =>
            null;
      end case;
   end MBus_Append_Data;

   -----------------------
   -- MBus_Get_Checking --
   -----------------------

   -- Get the two end frame bytes with CRC value for RTU.
   -- Get the two chars with LRC value for ASCII.
   function MBus_Get_Checking (This : Message) return UInt16 is
      Check : UInt16;
   begin
      case MBus_Get_Mode (This) is
         when RTU => -- Low-order byte before high-order byte
            Check := Shift_Left (UInt16(Get_Content_At (This, Get_Length (This))), 8);
            Check := Check or UInt16(Get_Content_At (This, Get_Length (This) - 1));
            return Check;
         when ASC => -- High-order char before low-order char
            Check := Shift_Left (UInt16(Get_ASCII_Val (Get_Content_At (This, Get_Length (This) - 3))), 4);
            Check := Check or UInt16(Get_ASCII_Val(Get_Content_At (This, Get_Length (This) - 2)));
            return Check;
         when TCP =>
            return 0;
      end case;
   end MBus_Get_Checking;

   -----------------------
   -- MBus_Set_Checking --
   -----------------------

   -- Put the two end frame bytes with CRC value for RTU.
   -- Put the two chars with LRC value and the two end frame chars CR and LF for ASCII.
   procedure MBus_Set_Checking (This : in out Message;  To : UInt16) is
   begin
      case MBus_Get_Mode (This) is
         when RTU => -- Low-order byte before high-order byte
            Append (This, Get_Low_Byte(To));
            Append (This, Get_High_Byte(To));
         when ASC => -- High-order char before low-order char
            Append (This, Get_ASCII_Pos (UInt8(Shift_Right(To and 16#00F0#, 4))));
            Append (This, Get_ASCII_Pos (UInt8(To and 16#000F#)));
            Append (This, 16#0D#); -- CR character
            Append (This, 16#0A#); -- LF character
         when TCP =>
            null;
      end case;
   end MBus_Set_Checking;

end Mbus_Frame;
