package body MBus is

   -------------------------------
   -- MODBUS RTU Implementation --
   -------------------------------

   -- The implementation of RTU reception driver may imply the management of a
   -- lot of interruptions due to the t1.5 and t3.5 timers. With high
   -- communication baud rates, this leads to a heavy CPU load. Consequently
   -- these two timers must be strictly respected when the baud rate is equal
   -- or lower than 19200 Bps.

   -- For baud rates greater than 19200 Bps, fixed values for the 2 timers
   -- should be used: it is recommended to use a value of 750µs for the
   -- inter-character time-out (t1.5) and a value of 1.750ms for inter-frame
   -- delay (t3.5). Both values are calculated at 22000 Bps.

   -- Standard baud rates in bps are: 300, 600, 1200, 2400, 4800, 9600, 14400,
   -- 19200, 38400, 57600, 115200, 230400, 460800.

   -- RTU protocol demands 11 bits per character.

   -- Max inter-character time between character at 9600 Bps is:
   -- 1.5 * 11 bits per character / 9600 Bps = 1.71875 ms.

   -- Min inter-frame time between frames at 9600 Bps is:
   -- 3.5 * 11 bits per character / 9600 Bps = 4.0104 ms.

   ----------------
   -- Inter_Time --
   ----------------

   -- Inter_Char is the number of characters in decimal parts.
   -- Maximum inter-character time is 1.5 char time, so Inter_Char is 15.
   -- Minimum inter-frame time is 3.5 char time, so Inter_Char is 35.
   function Inter_Time (Bps : Baud_Rates; Inter_Char : Natural) return Time_Span is
   begin
      if Bps <= 19_200 then
         return Microseconds((10**5 * Inter_Char * 11) / Integer(Bps)); -- time in microseconds
      else
         -- With bps > 19200, fixed time of 750 us for inter-character with Inter_Char = 15,
         -- and fixed time of 1750 us for inter-frame with Inter_Char = 35.
         return Microseconds((10**5 * Inter_Char * 11) / 22_000);
      end if;
   end Inter_Time;

   -------------------
   -- Get_High_Byte --
   -------------------

   function Get_High_Byte (Value : UInt16) return UInt8 is
      Val : constant UInt16 := Value;
   begin
      return UInt8(Shift_Right (Val, 8));
   end Get_High_Byte;

   ------------------
   -- Get_Low_Byte --
   ------------------

   function Get_Low_Byte (Value: UInt16) return UInt8 is
      Val : constant UInt16 := Value;
   begin
      return UInt8(Val and 16#00FF#);
   end Get_Low_Byte;

   --------------
   -- Get_Word --
   --------------

   function Get_Word (Hi : UInt8; Lo : UInt8) return UInt16 is
   begin
      return (Shift_Left (UInt16(Hi), 8) and UInt16(Lo));
   end Get_Word;

   -------------------
   -- Get_ASCII_Pos --
   -------------------

   function Get_ASCII_Pos (Val : UInt8) return UInt8 is
   begin
      case Val is
         when 16#00# =>
            return 16#30#; -- 0
         when 16#01# =>
            return 16#31#; -- 1
         when 16#02# =>
            return 16#32#; -- 2
         when 16#03# =>
            return 16#33#; -- 3
         when 16#04# =>
            return 16#34#; -- 4
         when 16#05# =>
            return 16#35#; -- 5
         when 16#06# =>
            return 16#36#; -- 6
         when 16#07# =>
            return 16#37#; -- 7
         when 16#08# =>
            return 16#38#; -- 8
         when 16#09# =>
            return 16#39#; -- 9
         when 16#0A# =>
            return 16#41#; -- A
         when 16#0B# =>
            return 16#42#; -- B
         when 16#0C# =>
            return 16#43#; -- C
         when 16#0D# =>
            return 16#44#; -- D
         when 16#0E# =>
            return 16#45#; -- E
         when 16#0F# =>
            return 16#46#; -- F
         when others =>
            return 16#00#; -- Null
      end case;
   end Get_ASCII_Pos;

   -------------------
   -- Get_ASCII_Val --
   -------------------

   function Get_ASCII_Val (Pos : UInt8) return UInt8 is
   begin
      case Pos is
         when 16#30# =>
            return 16#00#; -- 0
         when 16#31# =>
            return 16#01#; -- 1
         when 16#32# =>
            return 16#02#; -- 2
         when 16#33# =>
            return 16#03#; -- 3
         when 16#34# =>
            return 16#04#; -- 4
         when 16#35# =>
            return 16#05#; -- 5
         when 16#36# =>
            return 16#06#; -- 6
         when 16#37# =>
            return 16#07#; -- 7
         when 16#38# =>
            return 16#08#; -- 8
         when 16#39# =>
            return 16#09#; -- 9
         when 16#41# =>
            return 16#0A#; -- 10
         when 16#42# =>
            return 16#0B#; -- 11
         when 16#43# =>
            return 16#0C#; -- 12
         when 16#44# =>
            return 16#0D#; -- 13
         when 16#45# =>
            return 16#0E#; -- 14
         when 16#46# =>
            return 16#0F#; -- 15
         when others =>
            return 16#00#; -- 0
      end case;
   end Get_ASCII_Val;

   --------------------
   -- Get_ASCII_Char --
   --------------------

   function Get_ASCII_Char (Char : UInt8) return Character is
   begin
      case Char is
         when 16#00# =>
            return '0'; -- 0
         when 16#01# =>
            return '1'; -- 1
         when 16#02# =>
            return '2'; -- 2
         when 16#03# =>
            return '3'; -- 3
         when 16#04# =>
            return '4'; -- 4
         when 16#05# =>
            return '5'; -- 5
         when 16#06# =>
            return '6'; -- 6
         when 16#07# =>
            return '7'; -- 7
         when 16#08# =>
            return '8'; -- 8
         when 16#09# =>
            return '9'; -- 9
         when 16#0A# =>
            return 'A'; -- A
         when 16#0B# =>
            return 'B'; -- B
         when 16#0C# =>
            return 'C'; -- C
         when 16#0D# =>
            return 'D'; -- D
         when 16#0E# =>
            return 'E'; -- E
         when 16#0F# =>
            return 'F'; -- F
         when others =>
            return ' '; -- Null
      end case;
   end Get_ASCII_Char;

end MBus;
