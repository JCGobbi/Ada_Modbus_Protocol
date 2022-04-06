with HAL;                          use HAL;
with Serial_IO;                    use Serial_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

with MBus;                         use MBus;

package Message_Buffers is
   pragma Elaborate_Body;

   type Message (Physical_Size : Positive) is tagged limited private;

   function Get_Content (This : Message) return UInt8_Array with Inline;

   function Get_Length (This : Message) return Natural with Inline;

   function Get_Content_At (This : Message;  Index : Positive) return UInt8 with
     Pre => Index <= Get_Length (This),
     Inline;

   procedure Clear (This : in out Message) with
     Post => Get_Length (This) = 0,-- and Content (This) = 0,
     Inline;

   procedure Append (This : in out Message;  Value : UInt8) with
     Pre  => Get_Length (This) < This.Physical_Size,
     Post => Get_Content_At (This, Get_Length (This)) = Value,
     Inline;

   procedure Set_Content (This : in out Message;  To : UInt8_Array) with
     Pre  => To'Length <= This.Physical_Size,
     Post => Get_Length (This) = To'Length and Get_Content (This) = To,
     Inline;

   procedure Set_Start (This : in out Message;  To : UInt8) with
     Post => Get_Length (This) = 1 and Get_Content_At (This, 1) = To,
     Inline;

   procedure Set_Terminator (This : in out Message;  To : Character) with
   Post => Get_Terminator (This) = To,
   Inline;
   --  Specify the character that signals the end of an incoming message
   --  from the sender's point of view, ie the "logical" end of a message,
   --  as opposed to the physical capacity.

   function Get_Terminator (This : Message) return Character with Inline;
   --  The logical end of message character (eg, CR). Either the value of a
   --  prior call to Set_Terminator, or the character Nul if no terminator has
   --  ever been set. The terminator character, if received, is not stored in
   --  the message into which characters are being received.

   procedure Await_Transmission_Complete (This : in out Message) with Inline;
   --  Used for non-blocking output, to wait until the last char has been sent.

   procedure Await_Reception_Complete (This : in out Message) with Inline;
   --  Used for non-blocking input, to wait until the last char has been
   --  received.

   procedure Signal_Transmission_Complete (This : in out Message) with Inline;

   procedure Signal_Reception_Complete (This : in out Message) with Inline;

   procedure Note_Error (This : in out Message; Condition : Error_Conditions)
     with Inline;

   function Errors_Detected (This : Message) return Error_Conditions with Inline;

   procedure Clear_Errors (This : in out Message) with Inline;

   function Has_Error (This : Message; Condition : Error_Conditions)
      return Boolean with Inline;

   function MBus_Get_Mode (This : Message) return MBus_Modes;

   procedure MBus_Set_Mode (This : in out Message;  To : MBus_Modes) with
     Post => MBus_Get_Mode (This) = To,
     Inline;
   -- Defines the way each frame is written into/read from the modbus outgoing/
   -- incoming buffers according to the mode:
   -- modbus RTU are treated as hexadecimal bytes,
   -- modbus ASCII are treated as Character'Pos of the two nibles of each byte.

   procedure MBus_Note_Error (This : in out Message; Condition : MBus_Error_Conditions)
     with Inline;

   function MBus_Errors_Detected (This : Message) return MBus_Error_Conditions with Inline;

   procedure MBus_Clear_Errors (This : in out Message) with Inline;

   function MBus_Has_Error (This : Message; Condition : MBus_Error_Conditions)
      return Boolean with Inline;

private

   type Message (Physical_Size : Positive) is tagged limited record
      Content               : UInt8_Array (1 .. Physical_Size);
      Length                : Natural := 0;
      Reception_Complete    : Suspension_Object;
      Transmission_Complete : Suspension_Object;
      Terminator            : Character := ASCII.NUL;
      Error_Status          : Error_Conditions := No_Error_Detected;
      MBus_Message_Mode     : MBus_Modes := RTU;
      MBus_Error_Status     : MBus_Error_Conditions := No_Error;
   end record;

end Message_Buffers;
