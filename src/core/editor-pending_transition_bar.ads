with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Pending_Transitions;

package Editor.Pending_Transition_Bar is

   type Pending_Bar_Action is
     (No_Pending_Bar_Action,
      Save_All_Action,
      Close_All_Clean_Buffers_Action,
      Retry_Pending_Transition_Action,
      Discard_Pending_Transition_Action,
      Cancel_Pending_Transition_Action);

   type Pending_Bar_Operation is
     (No_Pending_Bar_Operation,
      Pending_Bar_Close_Buffer_Operation,
      Pending_Bar_Close_All_Buffers_Operation,
      Pending_Bar_Close_Other_Buffers_Operation,
      Pending_Bar_Reload_Buffer_Operation,
      Pending_Bar_Revert_Buffer_Operation,
      Pending_Bar_Close_Project_Operation,
      Pending_Bar_Clear_Project_Operation,
      Pending_Bar_Project_Switch_Operation,
      Pending_Bar_Restore_Workspace_Operation,
      Pending_Bar_Clear_Workspace_State_Operation);

   type Pending_Bar_Action_Info is record
      Action         : Pending_Bar_Action := No_Pending_Bar_Action;
      Command        : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Label          : Ada.Strings.Unbounded.Unbounded_String;
      Available      : Boolean := True;
      Is_Destructive : Boolean := False;
   end record;

   type Pending_Bar_Config is record
      Max_Actions          : Natural := 6;
      Height_Rows          : Natural := 1;
      Show_Close_Clean     : Boolean := True;
      Show_Retry           : Boolean := True;
      Show_Cancel          : Boolean := True;
      Minimum_Text_Columns : Natural := 24;
   end record;

   type Pending_Bar_Snapshot is private;

   function Build_Snapshot
     (Pending : Editor.Pending_Transitions.Pending_Transition_State;
      Config  : Pending_Bar_Config) return Pending_Bar_Snapshot;

   function Is_Visible
     (Snapshot : Pending_Bar_Snapshot) return Boolean;

   function Summary_Text
     (Snapshot : Pending_Bar_Snapshot) return String;

   function Guidance_Text
     (Snapshot : Pending_Bar_Snapshot) return String;

   function Display_Text
     (Snapshot : Pending_Bar_Snapshot) return String;

   function Action_Count
     (Snapshot : Pending_Bar_Snapshot) return Natural;

   function Operation
     (Snapshot : Pending_Bar_Snapshot) return Pending_Bar_Operation;

   function Requires_Destructive_Confirmation
     (Snapshot : Pending_Bar_Snapshot) return Boolean;

   function Assert_Action_Routes_Are_Command_Backed
     (Snapshot : Pending_Bar_Snapshot) return Boolean;

   function Assert_Destructive_Actions_Are_Confirmed
     (Snapshot : Pending_Bar_Snapshot) return Boolean;

   function Assert_Pending_Bar_Route_Audit_Passes
     (Snapshot : Pending_Bar_Snapshot) return Boolean;

   function Action
     (Snapshot : Pending_Bar_Snapshot;
      Index    : Positive) return Pending_Bar_Action_Info;

   procedure Set_Action_Availability
     (Snapshot  : in out Pending_Bar_Snapshot;
      Action    : Pending_Bar_Action;
      Available : Boolean);

   function Command_For_Action
     (Action : Pending_Bar_Action) return Editor.Commands.Command_Id;

   type Pending_Bar_Action_Rect is record
      Action : Pending_Bar_Action := No_Pending_Bar_Action;
      X      : Integer := 0;
      Y      : Integer := 0;
      W      : Integer := 0;
      H      : Integer := 0;
   end record;

   type Pending_Bar_Layout is private;

   function Layout
     (Snapshot : Pending_Bar_Snapshot;
      Bounds_X : Integer;
      Bounds_Y : Integer;
      Bounds_W : Integer;
      Cell_W   : Natural;
      Cell_H   : Natural) return Pending_Bar_Layout;

   function Action_Rect_Count
     (Layout : Pending_Bar_Layout) return Natural;

   function Action_Rect
     (Layout : Pending_Bar_Layout;
      Index  : Positive) return Pending_Bar_Action_Rect;

   function Bar_X (Layout : Pending_Bar_Layout) return Integer;
   function Bar_Y (Layout : Pending_Bar_Layout) return Integer;
   function Bar_W (Layout : Pending_Bar_Layout) return Integer;
   function Bar_H (Layout : Pending_Bar_Layout) return Integer;

   type Pending_Bar_Hit_Zone is
     (Outside_Pending_Bar,
      Pending_Bar_Background,
      Pending_Bar_Action_Zone);

   type Pending_Bar_Hit_Result is record
      Zone   : Pending_Bar_Hit_Zone := Outside_Pending_Bar;
      Action : Pending_Bar_Action := No_Pending_Bar_Action;
   end record;

   function Hit_Test
     (Snapshot : Pending_Bar_Snapshot;
      Layout   : Pending_Bar_Layout;
      X        : Integer;
      Y        : Integer) return Pending_Bar_Hit_Result;

private
   Max_Pending_Bar_Actions : constant Positive := 6;

   type Pending_Bar_Action_Array is array (Positive range 1 .. Max_Pending_Bar_Actions)
     of Pending_Bar_Action_Info;

   type Pending_Bar_Action_Rect_Array is array (Positive range 1 .. Max_Pending_Bar_Actions)
     of Pending_Bar_Action_Rect;

   type Pending_Bar_Snapshot is record
      Visible     : Boolean := False;
      Summary     : Ada.Strings.Unbounded.Unbounded_String;
      Guidance    : Ada.Strings.Unbounded.Unbounded_String;
      Height_Rows          : Natural := 1;
      Minimum_Text_Columns : Natural := 24;
      Operation            : Pending_Bar_Operation := No_Pending_Bar_Operation;
      Destructive          : Boolean := False;
      Count                : Natural := 0;
      Actions              : Pending_Bar_Action_Array;
   end record;

   type Pending_Bar_Layout is record
      Visible    : Boolean := False;
      X          : Integer := 0;
      Y          : Integer := 0;
      W          : Integer := 0;
      H          : Integer := 0;
      Rect_Count : Natural := 0;
      Rects      : Pending_Bar_Action_Rect_Array;
   end record;

end Editor.Pending_Transition_Bar;
