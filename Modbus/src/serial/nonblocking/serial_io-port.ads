--  This package defines an abstract data type for a "serial port" providing
--  non-blocking input (Receive) and output (Send) procedures. The procedures
--  are considered non-blocking because they return to the caller (potentially)
--  before the entire message is received or sent.
--
--  The serial port abstraction is a wrapper around a USART peripheral,
--  described by a value of type Peripheral_Descriptor.
--
--  Interrupts are used to send and receive characters.
--
--  NB: clients must not send or receive messages until any prior sending or
--  receiving is completed.
with System;          use System;
with Ada.Interrupts;  use Ada.Interrupts;

with STM32.Timers;    use STM32.Timers;

with Message_Buffers; use Message_Buffers;

package Serial_IO.Port is

   type Serial_Port (Device : not null access Peripheral_Descriptor;
                     IRQ          : Interrupt_ID;
                     IRQ_Priority : Interrupt_Priority;
                     Outgoing_Msg : not null access Message;
                     Incoming_Msg : not null access Message;
                     Timer_Periph : not null access Timer) is
     limited private;

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

   --  This procedure was modified for MODBUS
   procedure Send (This : in out Serial_Port)
     with Inline,
          Pre => (Initialized (This) or else raise Serial_Port_Uninitialized);
   --  Sends Msg.Length characters of Msg via USART attached to This returning
   --  potentially prior to the completion of the message transmission.

   --  This procedure was modified for MODBUS
   procedure Receive (This : in out Serial_Port)
     with Inline,
          Pre  => (Initialized (This) or else raise Serial_Port_Uninitialized),
          Post => Get_Length (This.Incoming_Msg.all) <= This.Incoming_Msg.all.Physical_Size;
   --  Start receiving all characters ending when the specified Msg.Terminator
   --  character is received (it is not stored), or the physical capacity of Msg
   --  is reached.

private

   type Serial_Profile is record
      Initialized        : Boolean;
      Serial_Mode        : Serial_Modes;
   end record;

   protected type Serial_Port (Device : not null access Peripheral_Descriptor;
                               IRQ          : Interrupt_ID;
                               IRQ_Priority : Interrupt_Priority;
                               Outgoing_Msg : not null access Message;
                               Incoming_Msg : not null access Message;
                               Timer_Periph : not null access Timer)
   is
      pragma Interrupt_Priority (IRQ_Priority);

      procedure Start_Sending (Msg : not null access Message);

      procedure Start_Receiving (Msg : not null access Message);

      procedure Set_Initialized (Val : Boolean);
      function Get_Initialized return Boolean;
      procedure Set_Serial_Mode (Val : Serial_Modes);
      function Get_Serial_Mode return Serial_Modes;

   private
      Profile : Serial_Profile :=
        (Initialized        => False,
         Serial_Mode        => MBus_RTU);

      Next_Out : Positive;
      Out_Message : access Message;
      In_Message : access Message;

      procedure Handle_Transmission with Inline;
      procedure Reception_Complete with Inline;
      --  Disable Receive_Data_Not_Empty interrupt and signalize
      --  Reception_Complete in the incoming message.
      procedure Handle_Reception    with Inline;
      procedure Detect_Errors (Is_Xmit_IRQ : Boolean) with Inline;

      procedure IRQ_Handler with Attach_Handler => IRQ;

   end Serial_Port;

end Serial_IO.Port;
