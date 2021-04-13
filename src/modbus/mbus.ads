with Ada.Real_Time; use Ada.Real_Time;
with HAL;           use HAL;
with STM32.USARTS;  use STM32.USARTS;

package MBus is

   ------------------------------------
   -- Types, variables and constants --
   ------------------------------------

   -- Default mode for MODBUS protocol
   type MBus_Modes is (RTU, ASC, TCP);

   subtype MBus_Server_Address is UInt8 range 0 .. 247;
   -- Valid Modbus server addresses in unicast mode: 1 .. 247
   -- Valid Modbus server address in broadcast mode: 0

   Server_Address : MBus_Server_Address := 1;
   -- Variable used for server address

   subtype MBus_RTU_Data_Size is Natural range 0 .. 252;
   -- Max Data size for RTU Message Frame

   subtype MBus_ASCII_Data_Size is Natural range 0 .. 504;
   -- Max Data size for ASCII Message Frame

   subtype MBus_Normal_Function_Code is UInt8 range 1 .. 127;
   -- Valid Modbus function codes: 1 .. 127
   -- Invalid function code: 0

   Normal_Function_Code : MBus_Normal_Function_Code;
   -- Variable used for normal function code response

   subtype MBus_Exception_Function_Code is UInt8 range 128 .. 255;
   -- Valid Modbus exception function code: 128 .. 255

   MBus_Exception_Code  : constant UInt8 := 16#80#;
   -- On exception function code errors response: normal function code + 0x80

   subtype MBus_Discrete_Inputs_Quantity is UInt16 range 1 .. 2000; -- 16#0001# .. 16#07D0#
   subtype MBus_Coils_Quantity is UInt16 range 1 .. 2000; -- 16#0001# .. 16#07D0#
   subtype MBus_Holding_Registers_Quantity is UInt16 range 1 .. 125; -- 16#0001# .. 16#007D#
   subtype MBus_Input_Registers_Quantity is UInt16 range 1 .. 125; -- 16#0001# .. 16#007D#

   -------------------------------------
   --  MODBUS buffer error conditions --
   -------------------------------------
   type MBus_Error_Conditions is mod 256;

   No_Error               : constant MBus_Error_Conditions := 2#0000_0000#;
   Invalid_Address        : constant MBus_Error_Conditions := 2#0000_0001#;
   Invalid_Function_Code  : constant MBus_Error_Conditions := 2#0000_0010#;
   Invalid_Checking       : constant MBus_Error_Conditions := 2#0000_0100#;
   Invalid_Parity         : constant MBus_Error_Conditions := 2#0000_1000#;
   InterChar_Timed_Out    : constant MBus_Error_Conditions := 2#0001_0000#;
   InterFrame_Timed_Out   : constant MBus_Error_Conditions := 2#0010_0000#;
   Response_Timed_Out     : constant MBus_Error_Conditions := 2#0100_0000#;
   Invalid_Frame          : constant MBus_Error_Conditions := 2#1000_0000#;

   ----------------------------------------------------------
   -- Constants and variables related with MODBUS protocol --
   ----------------------------------------------------------

   -- MODBUS Public Function Code Definition
   -- Modbus bit access codes
   Read_Discrete_Inputs : constant UInt8 := 16#02#; -- Physical discrete Inputs
   Read_Coils           : constant UInt8 := 16#01#; -- Internal bits or physical coils
   Write_Single_Coil    : constant UInt8 := 16#05#; -- Internal bits or physical coils
   Write_Multiple_Coils : constant UInt8 := 16#0F#; -- Internal bits or physical coils

    -- Modbus 16 bit access codes
   Read_Input_Registers         : constant UInt8 := 16#04#; -- Physical input registers
   Read_Holding_Registers       : constant UInt8 := 16#03#; -- Physical input registers
   Write_Single_Register        : constant UInt8 := 16#06#; -- Internal Registers or physical output registers
   Write_Multiple_Registers     : constant UInt8 := 16#10#; -- Internal Registers or physical output registers
   ReadWrite_Multiple_Registers : constant UInt8 := 16#17#; -- Internal Registers or physical output registers
   Mask_Write_Register          : constant UInt8 := 16#16#; -- Internal Registers or physical output registers
   Read_FIFO_Queue              : constant UInt8 := 16#18#; -- Internal Registers or physical output registers

   -- Modbus file record access codes
   Read_File_Record  : constant UInt8 := 16#14#;
   Write_File_Record : constant UInt8 := 16#15#;

   -- Modbus diagnostics codes
   Read_Exception_Status      : constant UInt8 := 16#07#;
   Diagnostic                 : constant UInt8 := 16#08#; -- With subtypes 00-18, 20
   Get_Com_Event_Counter      : constant UInt8 := 16#0B#;
   Get_Com_Event_Log          : constant UInt8 := 16#0C#;
   Report_Server_ID           : constant UInt8 := 16#11#;
   Read_Device_Identification : constant UInt8 := 16#2B#; -- With subtype 14

   -- Modbus other codes
   Encapsulation_Interface_Transport : constant UInt8 := 16#2B#; -- With subtypes 13, 14
   CANopen_General_Reference         : constant UInt8 := 16#2B#; -- With subtype 13

   -- Modbus data exception codes
   Illegal_Function         : constant UInt8 := 16#01#;
   Illegal_Data_Address     : constant UInt8 := 16#02#;
   Illegal_Data_Value       : constant UInt8 := 16#03#;
   Server_Device_Failure    : constant UInt8 := 16#04#;
   Acknowledge              : constant UInt8 := 16#05#;
   Server_Device_Busy       : constant UInt8 := 16#06#;
   Memory_Parity_Error      : constant UInt8 := 16#08#;
   Gateway_Path_Unavailable : constant UInt8 := 16#0A#;
   GTD_Failed_to_Respond    : constant UInt8 := 16#0B#; -- Gateway Target Device Failed to Respond

   -----------------------------
   -- Procedures and function --
   -----------------------------

   function Inter_Time (Bps : Baud_Rates; Inter_Char : Natural) return Time_Span;
   -- Inter_Char is the number of characters in decimal parts.
   -- Maximum inter-character time is 1.5 char time, so Inter_Char is 15.
   -- Minimum inter-frame time is 3.5 char time, so Inter_Char is 35.

   function Get_High_Byte (Value : UInt16) return UInt8;
   function Get_Low_Byte (Value : UInt16) return UInt8;
   function Get_Word (Hi : UInt8; Lo : UInt8) return UInt16;
   function Get_ASCII_Pos (Val : UInt8) return UInt8;
   function Get_ASCII_Val (Pos : UInt8) return UInt8;
   function Get_ASCII_Char (Char : UInt8) return Character;

end MBus;
