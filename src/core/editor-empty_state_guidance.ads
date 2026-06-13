with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Executor;
with Editor.State;

package Editor.Empty_State_Guidance is

   type Empty_State_Surface is
     (Main_Surface,
      File_Tree_Surface,
      Quick_Open_Surface,
      Project_Search_Surface,
      Outline_Surface,
      Diagnostics_Surface,
      Build_Surface,
      Recent_Projects_Surface,
      Configuration_Recovery_Surface);

   type Empty_State_Kind is
     (First_Run_State,
      Ready_State,
      No_Project_State,
      No_Active_Buffer_State,
      Unsupported_Buffer_State,
      Different_Buffer_State,
      No_Files_State,
      Not_Refreshed_State,
      Refresh_Required_State,
      No_Results_State,
      No_Candidates_State,
      No_Recent_Projects_State,
      No_Diagnostics_State,
      Filtered_None_State,
      Source_Less_Selected_State,
      No_Build_Diagnostics_State,
      No_Query_State,
      No_Matches_State,
      No_Symbols_State,
      Stale_State,
      Missing_Target_State,
      Missing_Root_State,
      Empty_Project_State,
      Limit_Reached_State,
      Replace_Preview_Empty_State,
      Consent_Required_State,
      No_Selected_Candidate_State,
      Request_Invalid_State,
      No_Result_State,
      No_Output_State,
      Diagnostics_Disabled_State,
      Selected_Unavailable_State,
      Only_Missing_Projects_State,
      Clean_State,
      Configuration_Warning_State,
      Safe_Defaults_State,
      Audit_Not_Run_State,
      Unavailable_State);

   type Empty_State_Severity is
     (Empty_Info,
      Empty_Warning,
      Empty_Error);

   type Suggested_Action_Activation_Mode is
     (Suggestion_Display_Only,
      Suggestion_Open_In_Command_Palette,
      Suggestion_Execute_Through_Executor);

   Max_Empty_State_Suggestions : constant Natural := 6;
   Max_Empty_State_Surfaces     : constant Natural := 9;

   type Empty_State_Suggested_Command is record
      Command                 : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Stable_Name             : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Title                   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Short_Explanation       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Surface_Source_Label    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Availability_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Activation_Mode         : Suggested_Action_Activation_Mode :=
        Suggestion_Execute_Through_Executor;
      Selected                : Boolean := False;
      Available               : Boolean := False;
      Unavailable_Reason      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Visible                 : Boolean := False;
      Carries_Payload         : Boolean := False;
   end record;

   type Empty_State_Suggestion_Array is
     array (Positive range 1 .. Max_Empty_State_Suggestions)
       of Empty_State_Suggested_Command;

   Empty_Command_Suggestion : constant Empty_State_Suggested_Command :=
     (others => <>);

   type Empty_State_Snapshot is record
      Surface               : Empty_State_Surface := Main_Surface;
      Kind                  : Empty_State_Kind := Ready_State;
      Primary_Message       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Secondary_Explanation : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Severity              : Empty_State_Severity := Empty_Info;
      Suggestion_Count      : Natural := 0;
      Suggestions           : Empty_State_Suggestion_Array :=
        (others => Empty_Command_Suggestion);
   end record;


   type Empty_State_Snapshot_Array is
     array (Positive range 1 .. Max_Empty_State_Surfaces)
       of Empty_State_Snapshot;

   function Build_All_Empty_State_Snapshots
     (S : Editor.State.State_Type) return Empty_State_Snapshot_Array;

   function Contains_Command_Suggestion
     (Snapshot : Empty_State_Snapshot;
      Command  : Editor.Commands.Command_Id) return Boolean;

   function Command_Suggestion_From_Descriptor
     (S       : Editor.State.State_Type;
      Command : Editor.Commands.Command_Id)
      return Empty_State_Suggested_Command;

   function Stable_Name_Is_Display_Only
     (Name : String) return Boolean;

   function Suggestion_Is_Descriptor_Consistent
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Suggestion_Is_Activation_Safe
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Suggested_Action_Availability_Label
     (Suggestion : Empty_State_Suggested_Command) return String;

   function Suggested_Action_Select_Next
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural;

   function Suggested_Action_Select_Previous
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural;

   function Suggested_Action_Selected_Index
     (Snapshot : Empty_State_Snapshot) return Natural;

   procedure Mark_Selected_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      Index    : Natural);

   function Open_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean;

   function Open_Selected_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Execute_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result;

   function Activate_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result;

   function Execute_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result;

   function Activate_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result;

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean;

   function Build_Main_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_File_Tree_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Quick_Open_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Project_Search_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Outline_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Diagnostics_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Build_UI_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Recent_Projects_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;

   function Build_Config_Recovery_Empty_State
     (S : Editor.State.State_Type) return Empty_State_Snapshot;


   function Empty_State_Surface_Count return Natural;

   function Empty_State_Surface_For_Slot
     (Index : Positive) return Empty_State_Surface;

   function Empty_State_Slot_For_Surface
     (Surface : Empty_State_Surface) return Positive;

   function Assert_Empty_State_Surface_Model_Is_Closed return Boolean;

   function Empty_State_Surface_Label
     (Surface : Empty_State_Surface) return String;

   function Empty_State_Kind_Label
     (Kind : Empty_State_Kind) return String;

   function Empty_State_Severity_Label
     (Severity : Empty_State_Severity) return String;

   function Empty_State_Should_Render
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Empty_State_Renderable_Count
     (Snapshots : Empty_State_Snapshot_Array) return Natural;

   function Empty_State_Snapshots_Equivalent
     (Left  : Empty_State_Snapshot;
      Right : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Severity_Is_Semantic
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Empty_State_Display_Line
     (Snapshot : Empty_State_Snapshot) return String;

   function Suggestion_Display_Line
     (Suggestion : Empty_State_Suggested_Command) return String;

   function Assert_Empty_State_Text_Is_Deterministic_And_Compact
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Display_Line_Is_Labelled
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Display_Line_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Array_Suggestion_Budget
     (Snapshots : Empty_State_Snapshot_Array) return Boolean;

   function Assert_Empty_State_Snapshot_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Is_Display_Only
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Array_Is_Display_Only
     (Snapshots : Empty_State_Snapshot_Array) return Boolean;

   function Assert_Empty_State_Suggestions_Have_No_Payloads
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Suggested_Actions_Store_Command_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Suggested_Action_Open_Palette_Carries_No_Payload
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean;

   function Assert_Suggested_Action_Activation_Mode_Is_Coherent
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Assert_Suggested_Action_Source_Label_Is_Surface_Owned
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean;

   function Assert_Suggested_Action_Metadata_Is_Current
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Assert_Suggested_Action_Is_Canonical_Surface_Projection
     (S          : Editor.State.State_Type;
      Surface    : Empty_State_Surface;
      Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections
     (S        : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Suggested_Action_Availability_Label_Is_Current
     (S          : Editor.State.State_Type;
      Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Selected_Suggested_Action_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Suggested_Action_Index_Is_Activatable
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean;

   function Assert_Empty_State_Suggestion_Tail_Is_Phase570_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Unavailable_Suggested_Action_Does_Not_Execute
     (Suggestion : Empty_State_Suggested_Command;
      Result     : Editor.Executor.Command_Execution_Result) return Boolean;

   function Assert_Keybindings_Have_No_Suggestion_Payloads return Boolean;

   function Assert_First_Run_Guidance_Fabricates_No_Project
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Render_Empty_State_Construction_Is_Observational
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Empty_State_Not_Persisted
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Empty_State_Suggestions_Are_Descriptor_Derived
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Suggestions_Are_Stable_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Suggestions_Resolve_From_Stable_Names
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Non_Ready_Empty_State_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_Ready_Empty_State_Is_Suppressed
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Assert_All_Empty_State_Surfaces_In_Canonical_Order
     (Snapshots : Empty_State_Snapshot_Array) return Boolean;

   function Assert_Empty_State_Array_Uses_Canonical_Slots
     (Snapshots : Empty_State_Snapshot_Array) return Boolean;

   function Assert_Empty_State_Activation_Uses_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Command : Editor.Commands.Command_Id) return Boolean;

   function Assert_Major_Empty_State_Surface_Coverage
     (S : Editor.State.State_Type) return Boolean;

   function Assert_All_Empty_State_Surfaces_Are_Present_Once
     (Snapshots : Empty_State_Snapshot_Array) return Boolean;

   function Assert_First_Use_Empty_State_Guidance_Coherent return Boolean;

end Editor.Empty_State_Guidance;
