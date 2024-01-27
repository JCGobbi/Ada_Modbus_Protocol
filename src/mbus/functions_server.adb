with Peripherals;           use Peripherals;
with MBus_Functions.Server; use MBus_Functions.Server;

package body Functions_Server is

   ---------------------------------
   -- MODBUS bit access functions --
   ---------------------------------

   -------------------------------
   -- MBus_Read_Discrete_Inputs --
   -------------------------------

   procedure MBus_Read_Discrete_Inputs
     (Address      : MBus_Server_Address;
      Byte_Count   : UInt16;
      Input_Status : UInt8_Array)
   is
   begin
      MBus_Read_Discrete_Inputs
         (MBus_Port,
          Address      => Address,
          Byte_Count   => Byte_Count,
          Input_Status => Input_Status);
   end MBus_Read_Discrete_Inputs;

   ---------------------
   -- MBus_Read_Coils --
   ---------------------

   procedure MBus_Read_Coils
     (Address     : MBus_Server_Address;
      Byte_Count  : UInt8;
      Coil_Status : UInt8_Array)
   is
   begin
      MBus_Read_Coils
         (MBus_Port,
          Address     => Address,
          Byte_Count  => Byte_Count,
          Coil_Status => Coil_Status);
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
      Quantity_of_Outputs : UInt16)
   is
   begin
      MBus_Write_Multiple_Coils
         (MBus_Port,
          Address             => Address,
          Starting_Address    => Starting_Address,
          Quantity_of_Outputs => Quantity_of_Outputs);
   end MBus_Write_Multiple_Coils;

   -------------------------------------
   -- MODBUS 16 bits access functions --
   -------------------------------------

   ---------------------------------
   -- MBus_Read_Holding_Registers --
   ---------------------------------

   procedure MBus_Read_Holding_Registers
     (Address        : MBus_Server_Address;
      Byte_Count     : UInt8;
      Register_Value : UInt16_Array)
   is
   begin
      MBus_Read_Holding_Registers
         (MBus_Port,
          Address        => Address,
          Byte_Count     => Byte_Count,
          Register_Value => Register_Value);
   end MBus_Read_Holding_Registers;

   -------------------------------
   -- MBus_Read_Input_Registers --
   -------------------------------

   procedure MBus_Read_Input_Registers
     (Address         : MBus_Server_Address;
      Byte_Count      : UInt8;
      Input_Registers : UInt16_Array)
   is
   begin
      MBus_Read_Input_Registers
         (MBus_Port,
          Address         => Address,
          Byte_Count      => Byte_Count,
          Input_Registers => Input_Registers);
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
      Quantity_of_Registers : UInt16)
   is
   begin
      MBus_Write_Multiple_Registers
         (MBus_Port,
          Address               => Address,
          Starting_Address      => Starting_Address,
          Quantity_of_Registers => Quantity_of_Registers);
   end MBus_Write_Multiple_Registers;

   ---------------------------------------
   -- MBus_ReadWrite_Multiple_Registers --
   ---------------------------------------

   procedure MBus_ReadWrite_Multiple_Registers
     (Address              : MBus_Server_Address;
      Byte_Count           : UInt8;
      Read_Registers_Value : UInt16_Array)
   is
   begin
      MBus_ReadWrite_Multiple_Registers
         (MBus_Port,
          Address              => Address,
          Byte_Count           => Byte_Count,
          Read_Registers_Value => Read_Registers_Value);
   end MBus_ReadWrite_Multiple_Registers;

   --------------------------------
   -- MODBUS data exception code --
   --------------------------------

   -----------------------------
   -- MBus_Exception_Response --
   -----------------------------

   procedure MBus_Exception_Response
     (Address             : MBus_Server_Address;
      Normal_Function     : MBus_Normal_Function_Code;
      Data_Exception_Code : UInt8)
   is
   begin
      MBus_Exception_Response
         (MBus_Port,
          Address             => Address,
          Normal_Function     => Normal_Function,
          Data_Exception_Code => Data_Exception_Code);
   end MBus_Exception_Response;

end Functions_Server;
