with Serial_IO.Port; use Serial_IO.Port;

package MBus_Functions.Server is

   ---------------------------------
   -- MODBUS bit access functions --
   ---------------------------------

   procedure MBus_Read_Discrete_Inputs
     (This         : in out Serial_Port;
      Address      : MBus_Server_Address;
      Byte_Count   : UInt16;
      Input_Status : UInt8_Array);

   procedure MBus_Read_Coils
     (This        : in out Serial_Port;
      Address     : MBus_Server_Address;
      Byte_Count  : UInt8;
      Coil_Status : UInt8_Array);

   procedure MBus_Write_Single_Coil
     (This           : in out Serial_Port;
      Address        : MBus_Server_Address;
      Output_Address : UInt16;
      Output_Value   : UInt16);

   procedure MBus_Write_Multiple_Coils
     (This                : in out Serial_Port;
      Address             : MBus_Server_Address;
      Starting_Address    : UInt16;
      Quantity_of_Outputs : UInt16);

   -------------------------------------
   -- MODBUS 16 bits access functions --
   -------------------------------------

   procedure MBus_Read_Holding_Registers
     (This           : in out Serial_Port;
      Address        : MBus_Server_Address;
      Byte_Count     : UInt8;
      Register_Value : UInt16_Array);

   procedure MBus_Read_Input_Registers
     (This            : in out Serial_Port;
      Address         : MBus_Server_Address;
      Byte_Count      : UInt8;
      Input_Registers : UInt16_Array);

   procedure MBus_Write_Single_Register
     (This             : in out Serial_Port;
      Address          : MBus_Server_Address;
      Register_Address : UInt16;
      Register_Value   : UInt16);

   procedure MBus_Write_Multiple_Registers
     (This                  : in out Serial_Port;
      Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16);

   procedure MBus_ReadWrite_Multiple_Registers
     (This                 : in out Serial_Port;
      Address              : MBus_Server_Address;
      Byte_Count           : UInt8;
      Read_Registers_Value : UInt16_Array);

   --------------------------------
   -- MODBUS data exception code --
   --------------------------------

   procedure MBus_Exception_Response
     (This                : in out Serial_Port;
      Address             : MBus_Server_Address;
      Normal_Function     : MBus_Normal_Function_Code;
      Data_Exception_Code : UInt8);

end MBus_Functions.Server;
