with MBus_Frame.IO;   use MBus_Frame.IO;

package body MBus_Functions.Server is

   ---------------------------------
   -- MODBUS bit access functions --
   ---------------------------------

   -------------------------------
   -- MBus_Read_Discrete_Inputs --
   -------------------------------

   procedure MBus_Read_Discrete_Inputs
     (Address       : MBus_Server_Address;
      Byte_Count    : UInt16;
      Input_Status  : Block_8)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Read_Discrete_Inputs;
      DBuffer : Block_8 (1 .. Input_Status'Length + 2);
   begin
      DBuffer(1) := Get_High_Byte (Byte_Count);
      DBuffer(2) := Get_Low_Byte (Byte_Count);
      for i in 1 .. Input_Status'Length loop
         DBuffer(i + 2) := Input_Status(i);
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Discrete_Inputs;

   ---------------------
   -- MBus_Read_Coils --
   ---------------------

   procedure MBus_Read_Coils
     (Address       : MBus_Server_Address;
      Byte_Count    : UInt8;
      Coil_Status   : Block_8)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Read_Coils;
      DBuffer : Block_8 (1 .. Coil_Status'Length + 1);
   begin
      DBuffer(1) := Byte_Count;
      for i in 1 .. Coil_Status'Length loop
         DBuffer(i + 1) := Coil_Status(i);
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
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
      Normal_Function : constant MBus_Normal_Function_Code := Write_Single_Coil;
      DBuffer : Block_8 (1 .. 4);
   begin
      DBuffer(1) := Get_High_Byte (Output_Address);
      DBuffer(2) := Get_Low_Byte (Output_Address);
      DBuffer(3) := Get_High_Byte (Output_Value);
      DBuffer(4) := Get_Low_Byte (Output_Value);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Write_Single_Coil;

   -------------------------------
   -- MBus_Write_Multiple_Coils --
   -------------------------------

   procedure MBus_Write_Multiple_Coils
     (Address             : MBus_Server_Address;
      Starting_Address    : UInt16;
      Quantity_of_Outputs : UInt16)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Write_Multiple_Coils;
      DBuffer : Block_8 (1 .. 4);
   begin
      DBuffer(1) := Get_High_Byte (Starting_Address);
      DBuffer(2) := Get_Low_Byte (Starting_Address);
      DBuffer(3) := Get_High_Byte (Quantity_of_Outputs);
      DBuffer(4) := Get_Low_Byte (Quantity_of_Outputs);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Register_Value : Block_16)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Read_Holding_Registers;
      DBuffer : Block_8 (1 .. (Register_Value'Length * 2) + 1);
   begin
      DBuffer(1) := Byte_Count;
      for i in 1 .. Register_Value'Length loop
         DBuffer(i * 2) := Get_High_Byte(Register_Value(i));
         DBuffer(i * 2 + 1) := Get_Low_Byte(Register_Value(i));
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Read_Holding_Registers;

   -------------------------------
   -- MBus_Read_Input_Registers --
   -------------------------------
   
   procedure MBus_Read_Input_Registers
     (Address         : MBus_Server_Address;
      Byte_Count      : UInt8;
      Input_Registers : Block_16)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Read_Input_Registers;
      DBuffer : Block_8 (1 .. (Input_Registers'Length * 2) + 1);
   begin
      DBuffer(1) := Byte_Count;
      for i in 1 .. Input_Registers'Length loop
         DBuffer (i * 2) := Get_High_Byte(Input_Registers(i));
         DBuffer (i * 2 + 1) := Get_Low_Byte(Input_Registers(i));
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
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
      Normal_Function : constant MBus_Normal_Function_Code := Write_Single_Register;
      DBuffer : Block_8 (1 .. 4);
   begin
      DBuffer(1) := Get_High_Byte (Register_Address);
      DBuffer(2) := Get_Low_Byte (Register_Address);
      DBuffer(3) := Get_High_Byte (Register_Value);
      DBuffer(4) := Get_Low_Byte (Register_Value);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Write_Single_Register;

   -----------------------------------
   -- MBus_Write_Multiple_Registers --
   -----------------------------------

   procedure MBus_Write_Multiple_Registers
     (Address               : MBus_Server_Address;
      Starting_Address      : UInt16;
      Quantity_of_Registers : UInt16)
   is
      Normal_Function : constant MBus_Normal_Function_Code := Write_Multiple_Registers;
      DBuffer : Block_8 (1 .. 4);
   begin
      DBuffer(1) := Get_High_Byte (Starting_Address);
      DBuffer(2) := Get_Low_Byte (Starting_Address);
      DBuffer(3) := Get_High_Byte (Quantity_of_Registers);
      DBuffer(4) := Get_Low_Byte (Quantity_of_Registers);
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Write_Multiple_Registers;

   ---------------------------------------
   -- MBus_ReadWrite_Multiple_Registers --
   ---------------------------------------
   
   procedure MBus_ReadWrite_Multiple_Registers
     (Address              : MBus_Server_Address;
      Byte_Count           : UInt8;
      Read_Registers_Value : Block_16)
   is
      Normal_Function : constant MBus_Normal_Function_Code := ReadWrite_Multiple_Registers;
      DBuffer : Block_8 (1 .. (Read_Registers_Value'Length * 2) + 1);
   begin
      DBuffer(1) := Byte_Count;
      for i in 1 .. Read_Registers_Value'Length loop
         DBuffer (i * 2) := Get_High_Byte(Read_Registers_Value(i));
         DBuffer (i * 2 + 1) := Get_Low_Byte(Read_Registers_Value(i));
      end loop;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Normal_Function,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
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
      Exception_Function_Code : constant MBus_Exception_Function_Code
                              := Normal_Function + MBus_Exception_Code;
      DBuffer : Block_8 (1 .. 1);
   begin
      DBuffer(1) := Data_Exception_Code;
      Write_Frame (Msg            => Outgoing,
                   Server_Address => Address,
                   Function_Code  => Exception_Function_Code,
                   Data_Chain     => DBuffer);
      -- Send the frame from the Outgoing buffer to the serial channel.
      Send_Frame (This => MBus_Port, Msg => Outgoing);
   end MBus_Exception_Response;

end MBus_Functions.Server;
