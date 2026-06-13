with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Editor.Messages is

   type Message_Severity is
     (Info_Message,
      Success_Message,
      Warning_Message,
      Error_Message);

   type Message_Id is new Natural;
   No_Message : constant Message_Id := 0;

   type Message_Config is record
      Default_Lifetime_Ms   : Natural := 3_000;
      Error_Lifetime_Ms     : Natural := 5_000;
      Max_Visible_Messages  : Natural := 3;
      Max_Text_Columns      : Natural := 96;
      Replace_Same_Category : Boolean := True;
   end record;

   type Message_Record is record
      Id            : Message_Id := No_Message;
      Severity      : Message_Severity := Info_Message;
      Text          : Ada.Strings.Unbounded.Unbounded_String;
      Created_At_Ms : Natural := 0;
      Expires_At_Ms : Natural := 0;
   end record;
   subtype Editor_Message is Message_Record;
   type Message_State is private;

   type Message_Layout is record
      Origin_X     : Natural := 0;
      Origin_Y     : Natural := 0;
      Cell_W       : Positive := 8;
      Cell_H       : Positive := 16;
      Status_Bar_Y : Integer := 0;
   end record;

   type Message_Rect is record
      Visible : Boolean := False;
      X       : Natural := 0;
      Y       : Natural := 0;
      W       : Natural := 0;
      H       : Natural := 0;
   end record;

   procedure Clear
     (State : in out Message_State);

   function Has_Messages
     (State : Message_State) return Boolean;

   function Is_Empty
     (State : Message_State) return Boolean;

   procedure Push
     (State    : in out Message_State;
      Severity : Message_Severity;
      Text     : String;
      Now_Ms   : Natural;
      Config   : Message_Config);

   procedure Push_Info
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config);

   procedure Push_Success
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config);

   procedure Push_Warning
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config);

   procedure Push_Error
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config);

   --  Convenience overloads.  Deterministic callers should pass editor time and Message_Config explicitly.
   procedure Push
     (State    : in out Message_State;
      Severity : Message_Severity;
      Text     : String;
      Ticks    : Natural := 180;
      Sticky   : Boolean := False);

   procedure Push_Info
     (State : in out Message_State;
      Text  : String);

   procedure Push_Success
     (State : in out Message_State;
      Text  : String);

   procedure Push_Warning
     (State : in out Message_State;
      Text  : String);

   procedure Push_Error
     (State : in out Message_State;
      Text  : String);

   procedure Tick
     (State  : in out Message_State;
      Now_Ms : Natural);

   procedure Tick
     (State : in out Message_State);

   procedure Dismiss_Latest
     (State : in out Message_State);

   procedure Dismiss_All
     (State : in out Message_State);

   function Visible_Count
     (State  : Message_State;
      Now_Ms : Natural;
      Config : Message_Config) return Natural;

   function Visible_Message
     (State  : Message_State;
      Index  : Positive;
      Now_Ms : Natural;
      Config : Message_Config) return Message_Record;

   function Id
     (Message : Message_Record) return Message_Id;

   function Text
     (Message : Message_Record) return String;

   function Severity
     (Message : Message_Record) return Message_Severity;

   function Active_Message
     (State : Message_State;
      Found : out Boolean) return Editor_Message;

   function Count
     (State : Message_State) return Natural;

   function Normalize_Text
     (Text        : String;
      Max_Columns : Natural) return String;

   function Display_Text
     (Message : Editor_Message;
      Columns : Natural) return String;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State) return Message_Rect;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      Index           : Positive;
      Now_Ms          : Natural;
      Config          : Message_Config) return Message_Rect;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      Index           : Positive;
      Config          : Message_Config) return Message_Rect;

   function Is_In_Overlay
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      X               : Integer;
      Y               : Integer) return Boolean;

private
   package Message_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Message_Record);

   type Message_State is record
      Queue        : Message_Vectors.Vector;
      Next_Id      : Message_Id := 1;
      Current_Time_Ms : Natural := 0;
   end record;

end Editor.Messages;
