package MBus_Frame.Errors is

   -----------------------------
   -- Procedures and function --
   -----------------------------

   procedure Process_Error_Status (This : in out Message;
                                   Server_Address : MBus_Server_Address;
                                   Function_Code  : UInt8);
   -- Test if received MODBUS frame in the modbus incoming buffer has errors and set
   -- Error_Status into its buffer.

   procedure Process_Received_Errors (This : in out Message);
   -- Process errors of the received MODBUS frame in the Error_Status of the modbus
   -- incoming buffer.

end MBus_Frame.Errors;
