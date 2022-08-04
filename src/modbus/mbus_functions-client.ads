package MBus_Functions.Client is

   ---------------------------------
   -- MODBUS bit access functions --
   ---------------------------------

   procedure MBus_Read_Discrete_Inputs
     (Address            : MBus_Server_Address;
      Starting_Address   : UInt16;
      Quantity_of_Inputs : UInt16);

   procedure MBus_Read_Coils
     (Address           : MBus_Server_Address;
      Starting_Address  : UInt16;
      Quantity_of_Coils : UInt16);

   procedure MBus_Write_Single_Coil
     (Address        : MBus_Server_Address;
      Output_Address : UInt16;
      Output_Value   : UInt16);

   procedure MBus_Write_Multiple_Coils
     (Address             : MBus_Server_Address;
      Starting_Address    : UInt16;
      Quantity_of_Outputs : UInt16;
      Byte_Count          : UInt8;
      Output_Value        : UInt8_Array);

   -------------------------------------
   -- MODBUS 16 bits access functions --
   -------------------------------------

   procedure MBus_Read_Holding_Registers
     (Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16);

   procedure MBus_Read_Input_Registers
     (Address                     : MBus_Server_Address;
      Starting_Address            : UInt16;
      Quantity_of_Input_Registers : UInt16);

   procedure MBus_Write_Single_Register
     (Address          : MBus_Server_Address;
      Register_Address : UInt16;
      Register_Value   : UInt16);

   procedure MBus_Write_Multiple_Registers
     (Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16;
      Byte_Count            : UInt8;
      Registers_Value       : UInt16_Array);

   procedure MBus_ReadWrite_Multiple_Registers
     (Address                : MBus_Server_Address;
      Read_Starting_Address  : UInt16;
      Quantity_to_Read       : UInt16;
      Write_Starting_Address : UInt16;
      Quantity_to_Write      : UInt16;
      Write_Byte_Count       : UInt8;
      Write_Registers_Value  : UInt16_Array);

end MBus_Functions.Client;
