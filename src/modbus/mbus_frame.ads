with HAL;             use HAL;

with Message_Buffers; use Message_Buffers;
with MBus;            use MBus;

package MBus_Frame is

   -----------------------------
   -- Procedures and function --
   -----------------------------

   function MBus_Get_Address (This : Message) return UInt8;
   --  Get the initial byte of the frame with modbus slave address value for RTU.
   --  Get the two chars with modbus slave address value for ASCII.

   procedure MBus_Set_Address (This : in out Message;  To : UInt8) with
     Post => MBus_Get_Address (This) = To;
   --  Put the initial byte of the frame with modbus slave address value for RTU.
   --  Put the start char ":" and the two chars with modbus slave address value for ASCII.

   function MBus_Get_Function_Code (This : Message) return UInt8;

   procedure MBus_Set_Function_Code (This : in out Message;  To : UInt8) with
     Post => MBus_Get_Function_Code (This) = To;
   --  Put the byte with modbus funtion code value for RTU.
   --  Put the two chars with modbus function code value for ASCII.

   function MBus_Get_Data_At (This : Message; Index : Positive) return UInt8;
   --  Takes a byte starting at 1st position of buffer for modbus RTU.
   --  Takes a pair of chars starting at 2nd position of buffer for modbus ASCII with
   --  high-order byte before low-order byte

   procedure MBus_Append_Data (This : in out Message;  To : UInt8) with
     Post => (if MBus_Get_Mode (This) = RTU then
                 MBus_Get_Data_At (This, Get_Length (This)) = To
              elsif MBus_Get_Mode (This) = ASC then
                 MBus_Get_Data_At (This, Get_Length (This) - 1) = To);
   --  Put the next byte with modbus data value for RTU.
   --  Put the next two chars with modbus data value for ASCII.

   function MBus_Get_Checking (This : Message) return UInt16;
   --  Get the two end frame bytes with CRC value for RTU.
   --  Get the two chars with LRC value for ASCII.

   procedure MBus_Set_Checking (This : in out Message;  To : UInt16) with
     Post => MBus_Get_Checking (This) = To;
   --  Put the two end frame bytes with CRC value for RTU.
   --  Put the two chars with LRC value and the two end frame chars CR and LF for ASCII.

end MBus_Frame;
