package body Checking is

   -- Hardware Checking with STM32F4 hardware CRC calculator

   -- Enable_Clock (CRC_Unit);
   -- Update_CRC (CRC_Unit, Input => Section1, Output => Checksum_CPU);
   -- Reset_Calculator (CRC_Unit);

   -- Software Checking
   -----------------
   -- Update_CRC ---
   -----------------

   procedure Update_CRC (Input : UInt8;
                         CRC: in out UInt16)
   is
      -- Polynomial for calculating CRC 16
      Poly : constant UInt16 := 16#A001#; -- 2#1010_0000_0000_0001#
   begin
      CRC := CRC xor UInt16(Input);

      for i in UInt8 range 1 .. 8 loop
         if UInt8(CRC and 16#0001#) = 1 then
            CRC := Shift_Right (CRC, 1) xor Poly;
         else
            CRC := Shift_Right (CRC, 1);
         end if;
      end loop;

   end Update_CRC;

   -----------------
   -- Update_CRC ---
   -----------------

   procedure Update_CRC (Input : Block_8;
                         CRC   : in out UInt16)
   is
   begin
      for i in Input'Range loop
         Update_CRC (Input(i), CRC);
      end loop;

   end Update_CRC;

   -----------------
   -- Update_CRC ---
   -----------------

   procedure Update_CRC (Input : Block_8;
                         CRC   : in out UInt16;
                         Start : Natural;
                         Final : Natural)
   is
   begin
      for i in Start .. Final loop
         Update_CRC (Input(i), CRC);
      end loop;

   end Update_CRC;

   ---------------
   -- Reset_CRC --
   ---------------

   procedure Reset_CRC (CRC : in out UInt16) is
   begin
      CRC := 16#FFFF#;
   end Reset_CRC;

   --------------------
   -- Calculate_LRC ---
   --------------------

   function Calculate_LRC (Input : Block_8) return UInt8
   is
      LRC : UInt16 := 16#0000#;
   begin
      for i in Input'Range loop
         LRC :=  LRC + UInt16(Input(i));
      end loop;
      return (16#FF# - UInt8(LRC and 16#00FF#)) - 1;
   end Calculate_LRC;

   --------------------
   -- Calculate_LRC ---
   --------------------

   function Calculate_LRC (Input : Block_8;
                           Start : Natural;
                           Final : Natural) return UInt8
   is
      LRC : UInt16 := 16#0000#;
   begin
      for i in Start .. Final loop
         LRC :=  LRC + UInt16(Input(i));
      end loop;
      return (16#FF# - UInt8(LRC and 16#00FF#)) - 1;
   end Calculate_LRC;

   ---------------
   -- Reset_LRC --
   ---------------

   procedure Reset_LRC (LRC : in out UInt8) is
   begin
      LRC := 16#00#;
   end Reset_LRC;

end Checking;
