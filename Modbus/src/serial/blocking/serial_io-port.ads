--  This package defines an abstract data type for a "serial port" providing
--  blocking input (Get) and output (Put) procedures. The procedures are
--  considered blocking in that they do not return to the caller until the
--  entire message is received or sent.
--
--  The serial port abstraction is a wrapper around a USART peripheral,
--  described by a value of type Peripheral_Descriptor.
--
--  Polling is used within the procedures to determine when characters are sent
--  and received.

with Ada.Real_Time;   use Ada.Real_Time;

with Message_Buffers; use Message_Buffers;

package Serial_IO.Port is
   pragma Elaborate_Body;

   type Serial_Port (Device       : not null access Peripheral_Descriptor;
                     Outgoing_Msg : not null access Message;
                     Incoming_Msg : not null access Message) is
     tagged limited private;

   procedure Initialize (This : out Serial_Port)
     with Post => (Initialized (This));

   function Initialized (This : Serial_Port) return Boolean with Inline;

   Serial_Port_Uninitialized : exception;

   procedure Configure
     (This      : in out Serial_Port;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control)
     with
       Pre => (Initialized (This) or else raise Serial_Port_Uninitialized);

   --  This procedure was created for MODBUS
   function Get_Serial_Mode (This : in out Serial_Port) return Serial_Modes
     with Inline;

   --  This procedure was created for MODBUS
   procedure Set_Serial_Mode (This : in out Serial_Port; To : Serial_Modes)
     with Post => Get_Serial_Mode (This) = To,
          Inline;
   --  Defines the end of frame according to the mode:
   --  Modbus RTU by inter-frame timeout, modbus ASCII by CR LF characters,
   --  Terminal by CR or other end character saved at the Terminator variable in
   --  the terminal buffer.

   --  This procedure was created for MODBUS
   procedure Set_InterChar_Timeout (This : in out Serial_Port; To : Time_Span)
     with Inline;

   --  This procedure was created for MODBUS
   procedure Set_InterFrame_Timeout (This : in out Serial_Port; To : Time_Span)
     with Inline;

   --  This procedure was created for MODBUS
   procedure Set_Response_Timeout
     (This : in out Serial_Port;
      To : Time_Span := Time_Span_Last)
     with Inline;

   procedure Configure_Timeout (This   : in out Serial_Port;
                                MB_Bps : Baud_Rates);
   --  Configure the timeouts for interchar, interframe and response.

   --  This procedure was modified for MODBUS
   procedure Send (This : in out Serial_Port)
     with Pre => (Initialized (This) or else raise Serial_Port_Uninitialized);
   --  Sends Msg.Length characters of Msg via USART attached to This. Callers
   --  wait until all characters are sent.

   --  This procedure was modified for MODBUS
   procedure Receive (This : in out Serial_Port)
     with Pre  => (Initialized (This) or else raise Serial_Port_Uninitialized),
          Post => Get_Length (This.Incoming_Msg.all) <= This.Incoming_Msg.all.Physical_Size;
   --  Callers wait until all characters are received.

private

   function Inter_Time (Bps : Baud_Rates; Inter_Char : Natural) return Time_Span;
   --  Inter_Char is the number of characters in x10 parts.
   --  Maximum inter-character time is 1.5 char time, so Inter_Char is 15.
   --  Minimum inter-frame time is 3.5 char time, so Inter_Char is 35.

   type Serial_Port (Device       : not null access Peripheral_Descriptor;
                     Outgoing_Msg : not null access Message;
                     Incoming_Msg : not null access Message) is
      tagged limited record
         Initialized        : Boolean := False;
         Serial_Mode        : Serial_Modes := MBus_RTU;
         InterChar_Timeout  : Time_Span := Microseconds (750); -- default 9600 bps
         InterFrame_Timeout : Time_Span := Microseconds (1_750); -- default 9600 bps
         Response_Timeout   : Time_Span := Time_Span_Last;
      end record;

   procedure Await_Send_Ready (This : USART) with Inline;
   procedure Await_Data_Available
     (This      : USART;
      Timeout   : Time_Span := Time_Span_Last;
      Timed_Out : out Boolean)
     with Inline;

end Serial_IO.Port;
