with HAL;       use HAL;
with STM32.CRC; use STM32.CRC;

package Checking is

   procedure Update_CRC (Input : UInt8; CRC : in out UInt16);
   --  Updates the 16-bit CRC value from the 8-bit Input values and any
   --  previously-calculated CRC value. Output is the resulting CRC-16 value.

   procedure Update_CRC (Input : Block_8;
                         CRC   : in out UInt16);
   --  Updates the 16-bit CRC value from the 8-bit array Input values and any
   --  previously-calculated CRC value. Output is the resulting CRC-16 value.

   procedure Update_CRC (Input : Block_8;
                         CRC   : in out UInt16;
                         Start : Natural;
                         Final : Natural) with
     Pre => ((Start >= Input'First and Final <= Input'Last and Start < Final)
             or else raise Invalid_Request with "CRC interval out of bounds");
   --  Updates the 16-bit CRC value from the 8-bit array Input values and any
   --  previously-calculated CRC value. Output is the resulting CRC-16 value.

   procedure Reset_CRC (CRC : in out UInt16) with
     Post => CRC = 16#FFFF#;
   --  Reset the unit's calculator value to 16#FFFF#. All previous
   --  calculations due to calls to Update_CRC are lost. Does not affect
   --  the contents of the unit's independent data.

   function Calculate_LRC (Input : Block_8) return UInt8;
   --  Calculates the 8-bit LRC value from the 8-bit array Input values.
   --  Output is the resulting LRC 8 bit value.

   function Calculate_LRC (Input : Block_8;
                           Start : Natural;
                           Final : Natural) return UInt8 with
     Pre => ((Start >= Input'First and Final <= Input'Last and Start < Final)
             or else raise Invalid_Request with "LRC interval out of bounds");
   --  Calculates the 8-bit LRC value from the 8-bit array Input values.
   --  Output is the resulting LRC 8 bit value.

   procedure Reset_LRC (LRC : in out UInt8) with
     Post => LRC = 16#00#;
   --  Reset the unit's calculator value to 16#00#. All previous
   --  calculations due to calls to Calculate_LRC are lost.

   Invalid_Request : exception;
   --  Raised when the requested CRC or LRC interval is out of bounds.

end Checking;
