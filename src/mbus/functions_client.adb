with Peripherals;           use Peripherals;
with MBus_Functions.Client; use MBus_Functions.Client;

package body Functions_Client is

   ---------------------------------
   -- MODBUS bit access functions --
   ---------------------------------

   -------------------------------
   -- MBus_Read_Discrete_Inputs --
   -------------------------------

   procedure MBus_Read_Discrete_Inputs
     (Address            : MBus_Server_Address;
      Starting_Address   : UInt16;
      Quantity_of_Inputs : UInt16)
   is
   begin
      MBus_Read_Discrete_Inputs
         (MBus_Port,
          Address            => Address,
          Starting_Address   => Starting_Address,
          Quantity_of_Inputs => Quantity_of_Inputs);
   end MBus_Read_Discrete_Inputs;

   ---------------------
   -- MBus_Read_Coils --
   ---------------------

   procedure MBus_Read_Coils
     (Address           : MBus_Server_Address;
      Starting_Address  : UInt16;
      Quantity_of_Coils : UInt16)
   is
   begin
      MBus_Read_Coils
         (MBus_Port,
          Address           => Address,
          Starting_Address  => Starting_Address,
          Quantity_of_Coils => Quantity_of_Coils);
   end MBus_Read_Coils;

   ----------------------------
   -- MBus_Write_Single_Coil --
   ----------------------------

   procedure MBus_Write_Single_Coil
     (Address        : MBus_Server_Address;
      Output_Address : UInt16;
      Output_Value   : UInt16)
   is
   begin
      MBus_Write_Single_Coil
         (MBus_Port,
          Address        => Address,
          Output_Address => Output_Address,
          Output_Value   => Output_Value);
   end MBus_Write_Single_Coil;

   -------------------------------
   -- MBus_Write_Multiple_Coils --
   -------------------------------

   procedure MBus_Write_Multiple_Coils
     (Address             : MBus_Server_Address;
      Starting_Address    : UInt16;
      Quantity_of_Outputs : UInt16;
      Byte_Count          : UInt8;
      Output_Value        : UInt8_Array)
   is
   begin
      MBus_Write_Multiple_Coils
         (MBus_Port,
          Address             => Address,
          Starting_Address    => Starting_Address,
          Quantity_of_Outputs => Quantity_of_Outputs,
          Byte_Count          => Byte_Count,
          Output_Value        => Output_Value);
   end MBus_Write_Multiple_Coils;

   -------------------------------------
   -- MODBUS 16 bits access functions --
   -------------------------------------

   ---------------------------------
   -- MBus_Read_Holding_Registers --
   ---------------------------------

   procedure MBus_Read_Holding_Registers
     (Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16)
   is
   begin
      MBus_Read_Holding_Registers
         (MBus_Port,
          Address               => Address,
          Starting_Address      => Starting_Address,
          Quantity_of_Registers => Quantity_of_Registers);
   end MBus_Read_Holding_Registers;

   -------------------------------
   -- MBus_Read_Input_Registers --
   -------------------------------

   procedure MBus_Read_Input_Registers
     (Address                     : MBus_Server_Address;
      Starting_Address            : UInt16;
      Quantity_of_Input_Registers : UInt16)
   is
   begin
      MBus_Read_Input_Registers
         (MBus_Port,
          Address                     => Address,
          Starting_Address            => Starting_Address,
          Quantity_of_Input_Registers => Quantity_of_Input_Registers);
   end MBus_Read_Input_Registers;

   --------------------------------
   -- MBus_Write_Single_Register --
   --------------------------------

   procedure MBus_Write_Single_Register
     (Address          : MBus_Server_Address;
      Register_Address : UInt16;
      Register_Value   : UInt16)
   is
   begin
      MBus_Write_Single_Register
         (MBus_Port,
          Address          => Address,
          Register_Address => Register_Address,
          Register_Value   => Register_Value);
   end MBus_Write_Single_Register;

   -----------------------------------
   -- MBus_Write_Multiple_Registers --
   -----------------------------------

   procedure MBus_Write_Multiple_Registers
     (Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16;
      Byte_Count            : UInt8;
      Registers_Value       : UInt16_Array)
   is
   begin
      MBus_Write_Multiple_Registers
         (MBus_Port,
          Address               => Address,
          Starting_Address      => Starting_Address,
          Quantity_of_Registers => Quantity_of_Registers,
          Byte_Count            => Byte_Count,
          Registers_Value       => Registers_Value);
   end MBus_Write_Multiple_Registers;

   ---------------------------------------
   -- MBus_ReadWrite_Multiple_Registers --
   ---------------------------------------

   procedure MBus_ReadWrite_Multiple_Registers
     (Address                : MBus_Server_Address;
      Read_Starting_Address  : UInt16;
      Quantity_to_Read       : UInt16;
      Write_Starting_Address : UInt16;
      Quantity_to_Write      : UInt16;
      Write_Byte_Count       : UInt8;
      Write_Registers_Value  : UInt16_Array)
   is
   begin
      MBus_ReadWrite_Multiple_Registers
         (MBus_Port,
          Address                => Address,
          Read_Starting_Address  => Read_Starting_Address,
          Quantity_to_Read       => Quantity_to_Read,
          Write_Starting_Address => Write_Starting_Address,
          Quantity_to_Write      => Quantity_to_Write,
          Write_Byte_Count       => Write_Byte_Count,
          Write_Registers_Value  => Write_Registers_Value);
   end MBus_ReadWrite_Multiple_Registers;

end Functions_Client;
