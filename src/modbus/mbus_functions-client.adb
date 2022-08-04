with MBus_Frame.IO;   use MBus_Frame.IO;

package body MBus_Functions.Client is

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
      Function_Code : constant MBus_Normal_Function_Code := Read_Discrete_Inputs;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Inputs);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Inputs);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Discrete_Inputs;

   ---------------------
   -- MBus_Read_Coils --
   ---------------------

   procedure MBus_Read_Coils
     (Address           : MBus_Server_Address;
      Starting_Address  : UInt16;
      Quantity_of_Coils : UInt16)
   is
      Function_Code : constant MBus_Normal_Function_Code := Read_Coils;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Coils);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Coils);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Coils;

   ----------------------------
   -- MBus_Write_Single_Coil --
   ----------------------------

   procedure MBus_Write_Single_Coil
     (Address        : MBus_Server_Address;
      Output_Address : UInt16;
      Output_Value   : UInt16)
   is
      Function_Code : constant MBus_Normal_Function_Code := Write_Single_Coil;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Output_Address);
      DBuffer (2) := Get_Low_Byte (Output_Address);
      DBuffer (3) := Get_High_Byte (Output_Value);
      DBuffer (4) := Get_Low_Byte (Output_Value);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Function_Code : constant MBus_Normal_Function_Code := Write_Multiple_Coils;
      DBuffer : UInt8_Array (1 .. Output_Value'Length + 5);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Outputs);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Outputs);
      DBuffer (5) := Byte_Count;
      for i in 1 .. Output_Value'Length loop
         DBuffer (i + 5) := Output_Value (i);
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Function_Code : constant MBus_Normal_Function_Code := Read_Holding_Registers;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Registers);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Registers);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Holding_Registers;

   -------------------------------
   -- MBus_Read_Input_Registers --
   -------------------------------

   procedure MBus_Read_Input_Registers
     (Address                     : MBus_Server_Address;
      Starting_Address            : UInt16;
      Quantity_of_Input_Registers : UInt16)
   is
      Function_Code : constant MBus_Normal_Function_Code := Read_Input_Registers;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Input_Registers);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Input_Registers);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Input_Registers;

   --------------------------------
   -- MBus_Write_Single_Register --
   --------------------------------

   procedure MBus_Write_Single_Register
     (Address          : MBus_Server_Address;
      Register_Address : UInt16;
      Register_Value   : UInt16)
   is
      Function_Code : constant MBus_Normal_Function_Code := Write_Single_Register;
      DBuffer : UInt8_Array (1 .. 4);
   begin
      DBuffer (1) := Get_High_Byte (Register_Address);
      DBuffer (2) := Get_Low_Byte (Register_Address);
      DBuffer (3) := Get_High_Byte (Register_Value);
      DBuffer (4) := Get_Low_Byte (Register_Value);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Function_Code : constant MBus_Normal_Function_Code := Write_Multiple_Registers;
      DBuffer : UInt8_Array (1 .. Registers_Value'Length * 2 + 5);
   begin
      DBuffer (1) := Get_High_Byte (Starting_Address);
      DBuffer (2) := Get_Low_Byte (Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_of_Registers);
      DBuffer (4) := Get_Low_Byte (Quantity_of_Registers);
      DBuffer (5) := Byte_Count;
      for i in 1 .. (Registers_Value'Length) loop
         DBuffer (i * 2 + 4) := Get_High_Byte (Registers_Value (i));
         DBuffer (i * 2 + 5) := Get_Low_Byte (Registers_Value (i));
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Function_Code : constant MBus_Normal_Function_Code := ReadWrite_Multiple_Registers;
      DBuffer : UInt8_Array (1 .. Write_Registers_Value'Length * 2 + 9);
   begin
      DBuffer (1) := Get_High_Byte (Read_Starting_Address);
      DBuffer (2) := Get_Low_Byte (Read_Starting_Address);
      DBuffer (3) := Get_High_Byte (Quantity_to_Read);
      DBuffer (4) := Get_Low_Byte (Quantity_to_Read);
      DBuffer (5) := Get_High_Byte (Write_Starting_Address);
      DBuffer (6) := Get_Low_Byte (Write_Starting_Address);
      DBuffer (7) := Get_High_Byte (Quantity_to_Write);
      DBuffer (8) := Get_Low_Byte (Quantity_to_Write);
      DBuffer (9) := Write_Byte_Count;
      for i in 1 .. Write_Registers_Value'Length loop
         DBuffer (i * 2 + 8) := Get_High_Byte (Write_Registers_Value (i));
         DBuffer (i * 2 + 9) := Get_Low_Byte (Write_Registers_Value (i));
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Function_Code,
                   Data_Chain     => DBuffer);
      --  Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_ReadWrite_Multiple_Registers;

end MBus_Functions.Client;
