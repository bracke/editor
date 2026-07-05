with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Keybindings;

package Editor.Keybinding_Management is

   type Keybinding_Filter is
     (Filter_All,
      Filter_Bound,
      Filter_Unbound,
      Filter_Conflicts,
      Filter_Non_Bindable);

   type Keybinding_Capture_State is
     (Capture_Inactive,
      Capture_Active,
      Capture_Conflict_Pending);

   type Keybinding_Action_Status is
     (Keybinding_Action_Ok,
      Keybinding_Action_No_Command_Selected,
      Keybinding_Action_Command_Not_Bindable,
      Keybinding_Action_Invalid_Shortcut,
      Keybinding_Action_Shortcut_Already_Assigned,
      Keybinding_Action_No_Keybinding_Selected,
      Keybinding_Action_Reset_Confirmation_Pending,
      Keybinding_Action_Confirmation_Pending,
      Keybinding_Action_Cancelled,
      Keybinding_Action_IO_Failed);

   type Keybinding_Row_Snapshot is record
      Command             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Command_Title       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stable_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Category_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Description         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Active_Chord    : Boolean := False;
      Active_Chord        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Chord_Count  : Natural := 0;
      Active_Chords       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Default_Chord   : Boolean := False;
      Default_Chord       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Bindable            : Boolean := False;
      Non_Bindable        : Boolean := False;
      Conflicting         : Boolean := False;
      Selected            : Boolean := False;
      Source_Label        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Keybinding_Chord_Row_Snapshot is record
      Chord_Label         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Command_Title       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stable_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Category_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Default_Chord       : Boolean := False;
      User_Override       : Boolean := False;
      Conflicting         : Boolean := False;
      Selected            : Boolean := False;
   end record;

   --  Bounded render-facing row projection. Render packets consume these rows
   --  from the immutable Render_Model snapshot instead of calling back into
   --  keybinding management while emitting. This keeps rendering observational
   --  even if the live keybinding editor state changes after snapshot capture.
   Max_Surface_Rows : constant Natural := 40;

   type Keybinding_Surface_Row_Array is array (Positive range 1 .. Max_Surface_Rows)
     of Keybinding_Row_Snapshot;

   type Keybinding_Surface_Chord_Row_Array is array
     (Positive range 1 .. Max_Surface_Rows) of Keybinding_Chord_Row_Snapshot;

   Empty_Keybinding_Row : constant Keybinding_Row_Snapshot := (others => <>);
   Empty_Keybinding_Chord_Row : constant Keybinding_Chord_Row_Snapshot :=
     (others => <>);

   type Keybinding_List_Summary is record
      Row_Count                  : Natural := 0;
      Chord_Row_Count            : Natural := 0;
      Bound_Command_Count        : Natural := 0;
      Unbound_Bindable_Count     : Natural := 0;
      Non_Bindable_Command_Count : Natural := 0;
      Conflict_Count             : Natural := 0;
      Runtime_Validation_Conflicts : Natural := 0;
      Runtime_Validation_Invalids  : Natural := 0;
      Last_Load_Ignored_Count      : Natural := 0;
      Last_Load_Unknown_Commands   : Natural := 0;
      Last_Load_Non_Bindable       : Natural := 0;
      Last_Load_Invalid_Chords     : Natural := 0;
      Last_Load_Payloads           : Natural := 0;
      Last_Load_Duplicate_Chords   : Natural := 0;
      Capture                    : Keybinding_Capture_State := Capture_Inactive;
      Has_Pending_Conflict       : Boolean := False;
      Pending_Conflict_Command   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Pending_Conflict_Chord     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Pending_Reset          : Boolean := False;
   end record;

   type Keybinding_Surface_Snapshot is record
      Visible              : Boolean := False;
      Focused              : Boolean := False;
      Query_Present        : Boolean := False;
      Filter               : Keybinding_Filter := Filter_All;
      Selected_Command     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Has_Selected_Chord   : Boolean := False;
      Selected_Chord_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Row_Count            : Natural := 0;
      Chord_Row_Count      : Natural := 0;
      Display_Row_Count    : Natural := 0;
      Display_Rows         : Keybinding_Surface_Row_Array :=
        (others => Empty_Keybinding_Row);
      Display_Chord_Row_Count : Natural := 0;
      Display_Chord_Rows      : Keybinding_Surface_Chord_Row_Array :=
        (others => Empty_Keybinding_Chord_Row);
      Capture              : Keybinding_Capture_State := Capture_Inactive;
      Has_Pending_Conflict : Boolean := False;
      Has_Pending_Reset    : Boolean := False;
      Last_Load_Ignored_Count : Natural := 0;
      Last_Load_Diagnostic_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Message       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   procedure Show;
   procedure Focus;
   procedure Hide;
   procedure Reset_Transient_State;
   function Is_Visible return Boolean;
   function Is_Focused return Boolean;

   procedure Set_Query (Query : String);
   procedure Clear_Query;
   function Query return String;

   procedure Set_Filter (Filter : Keybinding_Filter);
   procedure Clear_Filter;
   function Current_Filter return Keybinding_Filter;

   procedure Select_Command (Command : Editor.Commands.Command_Id);
   procedure Select_Next_Row;
   procedure Select_Previous_Row;
   procedure Clear_Selection;
   function Selected_Command return Editor.Commands.Command_Id;

   function Row_Count return Natural;
   function Row_At (Index : Positive) return Keybinding_Row_Snapshot;
   function Chord_Row_Count return Natural;
   function Chord_Row_At (Index : Positive) return Keybinding_Chord_Row_Snapshot;
   procedure Select_Chord
     (Text   : String;
      Status : out Keybinding_Action_Status);
   procedure Clear_Chord_Selection;
   function Has_Selected_Chord return Boolean;
   function Selected_Chord_Label return String;
   function Summary return Keybinding_List_Summary;
   function Current_Capture_State return Keybinding_Capture_State;
   function Build_Surface_Snapshot return Keybinding_Surface_Snapshot;

   procedure Begin_Assign_Selected (Status : out Keybinding_Action_Status);
   procedure Cancel_Capture (Status : out Keybinding_Action_Status);

   function Has_Pending_Conflict return Boolean;
   function Pending_Conflict_Command return Editor.Commands.Command_Id;
   function Pending_Conflict_Chord return String;

   procedure Confirm_Pending_Assignment
     (Status : out Keybinding_Action_Status);

   procedure Capture_Assignment
     (Text             : String;
      Confirm_Conflict : Boolean;
      Status           : out Keybinding_Action_Status);

   procedure Assign_Selected
     (Chord            : Editor.Keybindings.Key_Chord;
      Confirm_Conflict : Boolean;
      Status           : out Keybinding_Action_Status);

   procedure Remove_Selected (Status : out Keybinding_Action_Status);
   procedure Request_Reset_To_Defaults (Status : out Keybinding_Action_Status);
   procedure Confirm_Reset_To_Defaults (Status : out Keybinding_Action_Status);
   procedure Cancel_Reset_To_Defaults (Status : out Keybinding_Action_Status);
   function Has_Pending_Reset return Boolean;
   procedure Reset_To_Defaults (Status : out Keybinding_Action_Status);
   procedure Save (Path : String; Status : out Keybinding_Action_Status);
   procedure Load (Path : String; Status : out Keybinding_Action_Status);

   function Action_Status_Label (Status : Keybinding_Action_Status) return String;
   function Last_Load_Diagnostics_Label return String;
   function Latest_Message return String;

   --  render/persistence guards. These helpers are observational and
   --  verify that the management surface snapshot contains only transient UI
   --  state plus derived rows, never command payloads or persistence-domain data.
   function Assert_Keybinding_Surface_Render_Is_Observational return Boolean;
   function Assert_Keybinding_Editor_State_Not_Persisted return Boolean;

   --  coherence guard. This helper is observational except for a
   --  local save/load model round-trip and never executes commands.
   function Assert_Keybinding_Management_Coherent return Boolean;

end Editor.Keybinding_Management;
