package body Message_Buffers is

   -----------------
   -- Get_Content --
   -----------------

   function Get_Content (This : Message) return UInt8_Array is
   begin
      return This.Content (1 .. This.Length);
   end Get_Content;

   --------------------
   -- Get_Content_At --
   --------------------

   function Get_Content_At (This : Message;  Index : Positive) return UInt8 is
   begin
      return This.Content (Index);
   end Get_Content_At;

   ----------------
   -- Get_Length --
   ----------------

   function Get_Length (This : Message) return Natural is
   begin
      return This.Length;
   end Get_Length;

   -----------
   -- Clear --
   -----------

   procedure Clear (This : in out Message) is
   begin
      This.Length := 0;
   end Clear;

   ------------
   -- Append --
   ------------

   procedure Append (This : in out Message;  Value : UInt8) is
   begin
      This.Length := This.Length + 1;
      This.Content (This.Length) := Value;
   end Append;

   -----------------
   -- Set_Content --
   -----------------

   procedure Set_Content (This : in out Message;  To : UInt8_Array) is
   begin
      This.Content (1 .. To'Length) := To;
      This.Length := To'Length;
   end Set_Content;

   ---------------
   -- Set_Start --
   ---------------

   procedure Set_Start (This : in out Message;  To : UInt8) is
   begin
      This.Content (1) := To;
      This.Length := 1;
   end Set_Start;

   --------------------
   -- Set_Terminator --
   --------------------

   procedure Set_Terminator (This : in out Message;  To : Character) is
   begin
      This.Terminator := To;
   end Set_Terminator;

   ----------------
   -- Get_Terminator --
   ----------------

   function Get_Terminator (This : Message) return Character is
   begin
      return This.Terminator;
   end Get_Terminator;

   ---------------------------------
   -- Await_Transmission_Complete --
   ---------------------------------

   procedure Await_Transmission_Complete (This : in out Message) is
   begin
      Suspend_Until_True (This.Transmission_Complete);
   end Await_Transmission_Complete;

   ------------------------------
   -- Await_Reception_Complete --
   ------------------------------

   procedure Await_Reception_Complete (This : in out Message) is
   begin
      Suspend_Until_True (This.Reception_Complete);
   end Await_Reception_Complete;

   ----------------------------------
   -- Signal_Transmission_Complete --
   ----------------------------------

   procedure Signal_Transmission_Complete (This : in out Message) is
   begin
      Set_True (This.Transmission_Complete);
   end Signal_Transmission_Complete;

   -------------------------------
   -- Signal_Reception_Complete --
   -------------------------------

   procedure Signal_Reception_Complete (This : in out Message) is
   begin
      Set_True (This.Reception_Complete);
   end Signal_Reception_Complete;

   ----------------
   -- Note_Error --
   ----------------

   procedure Note_Error (This : in out Message; Condition : Error_Conditions) is
   begin
      This.Error_Status := This.Error_Status or Condition;
   end Note_Error;

   ---------------------
   -- Errors_Detected --
   ---------------------

   function Errors_Detected (This : Message) return Error_Conditions is
   begin
      return This.Error_Status;
   end Errors_Detected;

   ------------------
   -- Clear_Errors --
   ------------------

   procedure Clear_Errors (This : in out Message) is
   begin
      This.Error_Status := No_Error_Detected;
   end Clear_Errors;

   ---------------
   -- Has_Error --
   ---------------

   function Has_Error (This : Message; Condition : Error_Conditions) return Boolean is
   begin
      return (This.Error_Status and Condition) /= 0;
   end Has_Error;

   -------------------
   -- MBus_Get_Mode --
   -------------------

   function MBus_Get_Mode (This : Message) return MBus_Modes is
   begin
      return This.MBus_Message_Mode;
   end MBus_Get_Mode;

   -------------------
   -- MBus_Set_Mode --
   -------------------

   procedure MBus_Set_Mode (This : in out Message;  To : MBus_Modes) is
   begin
      This.MBus_Message_Mode := To;
   end MBus_Set_Mode;

   ---------------------
   -- MBus_Note_Error --
   ---------------------

   procedure MBus_Note_Error (This : in out Message; Condition : MBus_Error_Conditions) is
   begin
      This.MBus_Error_Status := This.MBus_Error_Status or Condition;
   end MBus_Note_Error;

   --------------------------
   -- MBus_Errors_Detected --
   --------------------------

   function MBus_Errors_Detected (This : Message) return MBus_Error_Conditions is
   begin
      return This.MBus_Error_Status;
   end MBus_Errors_Detected;

   -----------------------
   -- MBus_Clear_Errors --
   -----------------------

   procedure MBus_Clear_Errors (This : in out Message) is
   begin
      This.MBus_Error_Status := No_Error;
   end MBus_Clear_Errors;

   --------------------
   -- MBus_Has_Error --
   --------------------

   function MBus_Has_Error (This : Message; Condition : MBus_Error_Conditions) return Boolean is
   begin
      return (This.MBus_Error_Status and Condition) /= 0;
   end MBus_Has_Error;

end Message_Buffers;
