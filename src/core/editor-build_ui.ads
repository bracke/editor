with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
use type Ada.Strings.Unbounded.Unbounded_String;
with Editor.Build_Working_Context;
with Editor.Build_Candidates;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;

package Editor.Build_UI is

   --  public build command UX foundation.  This package owns only
   --  transient input/consent state and pure validation helpers.  It does not
   --  execute processes, probe projects/filesystems, persist state, mutate
   --  Diagnostics, or infer build metadata.

   package Build_UI_Argument_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Build_UI_Argument_Vector is Build_UI_Argument_Vectors.Vector;

   type Build_UI_Request_Mode is
     (Build_UI_Request_Mode_Manual,
      Build_UI_Request_Mode_Candidate_Derived);

   type Build_UI_Build_Mode is
     (Build_UI_Build_Mode_Default,
      Build_UI_Build_Mode_Debug,
      Build_UI_Build_Mode_Release,
      Build_UI_Build_Mode_Validation);

   type Build_UI_Output_Capture_Limit is
     (Build_UI_Output_Capture_Small,
      Build_UI_Output_Capture_Normal,
      Build_UI_Output_Capture_Large);

   type Build_UI_Request_Option_Row is record
      Option_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Option_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Enabled : Boolean := False;
      Supported : Boolean := True;
      Disabled_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Build_UI_Request_Option_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Build_UI_Request_Option_Row);

   subtype Build_UI_Request_Option_Row_Vector is
     Build_UI_Request_Option_Row_Vectors.Vector;

   type Build_UI_Candidate_Row is record
      Candidate_Id : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Kind_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Tool_Kind_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Source_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected : Boolean := False;
      Stale : Boolean := False;
      Validation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Build_UI_Candidate_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Build_UI_Candidate_Row);

   subtype Build_UI_Candidate_Row_Vector is Build_UI_Candidate_Row_Vectors.Vector;

   type Build_UI_Action_Row is record
      Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Enabled : Boolean := False;
      Selected : Boolean := False;
      Diagnostic_Index : Natural := 0;
      Quick_Fix_Action_Index : Natural := 0;
      Disabled_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Build_UI_Action_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Build_UI_Action_Row);

   subtype Build_UI_Action_Row_Vector is Build_UI_Action_Row_Vectors.Vector;

   type Build_UI_Request_Preview is record
      Request_Mode : Build_UI_Request_Mode := Build_UI_Request_Mode_Manual;
      Request_Mode_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("manual");
      Tool_Kind_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Argv_Tokens : Build_UI_Argument_Vector :=
        Build_UI_Argument_Vectors.Empty_Vector;
      Working_Context_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected_Candidate_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Build_Mode_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("default");
      Diagnostics_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Output_Capture_Limit_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("normal bounded output capture (262144 bytes)");
      Request_Option_Rows : Build_UI_Request_Option_Row_Vector :=
        Build_UI_Request_Option_Row_Vectors.Empty_Vector;
      Request_Identity_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Consent_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Availability_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Build_UI_Working_Context_View is record
      Kind_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Validation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Build_UI_Diagnostics_View is record
      Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Count_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reveal_Available : Boolean := False;
      Reveal_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reveal_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Open_Source_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Open_Source_Available : Boolean := False;
      Open_Source_Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Suppress_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Suppress_Available : Boolean := False;
      Suppress_Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Suppressed_Count_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Show_Suppressed_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Show_Suppressed_Available : Boolean := False;
      Show_Suppressed_Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Restore_Suppressed_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Restore_Suppressed_Available : Boolean := False;
      Restore_Suppressed_Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Available : Boolean := False;
      Quick_Fix_Unavailable_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Action_Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Build_Diagnostics_Surface is record
      Latest_Result_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Diagnostics_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Diagnostics_Count_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reveal_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reveal_Available : Boolean := False;
      Result_Visible : Boolean := False;
   end record;

   type Build_UI_Render_Snapshot is record
      Visible : Boolean := False;
      Focused : Boolean := False;
      No_Project : Boolean := False;
      No_Candidates : Boolean := False;
      Candidate_Count : Natural := 0;
      Candidate_Count_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected_Candidate_Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Refresh_Action_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Refresh_Action_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Next_Action_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Actions : Build_UI_Action_Row_Vector :=
        Build_UI_Action_Row_Vectors.Empty_Vector;
      Candidates : Build_UI_Candidate_Row_Vector :=
        Build_UI_Candidate_Row_Vectors.Empty_Vector;
      Refresh_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Refresh_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Request_Preview : Build_UI_Request_Preview;
      Working_Context : Build_UI_Working_Context_View;
      Consent_Required : Boolean := False;
      Consent_Stale : Boolean := False;
      Consent_Acknowledged : Boolean := False;
      Request_Valid : Boolean := False;
      Run_Command_Available : Boolean := False;
      Run_Available : Boolean := False;
      Request_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Request_Action_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Run_Command_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Run_Action_Command_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Run_Availability_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Run_Recovery_Hint : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Result_Summary_Row_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Latest_Result : Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot;
      Output_Details : Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot;
      Diagnostics_View : Build_UI_Diagnostics_View;
   end record;

   type Public_Build_Tool_Selection is
     (Build_UI_No_Tool,
      Build_UI_GPRbuild,
      Build_UI_Alire,
      Build_UI_Custom_Disallowed_For_Now);

   type Build_Candidate_Refresh_Status is
     (Build_Candidate_Refresh_Not_Requested,
      Build_Candidate_Refresh_Succeeded,
      Build_Candidate_Refresh_No_Project_Context,
      Build_Candidate_Refresh_No_Candidates,
      Build_Candidate_Refresh_Failed);

   type Public_Build_UI_Validation_Status is
     (Build_UI_Valid,
      Build_UI_Rejected_Not_Visible,
      Build_UI_Rejected_No_Tool,
      Build_UI_Rejected_Custom_Tool,
      Build_UI_Rejected_No_Candidate_Selected,
      Build_UI_Rejected_Selected_Candidate_Stale,
      Build_UI_Rejected_Missing_Consent,
      Build_UI_Rejected_Unsafe_Arguments,
      Build_UI_Rejected_Unsupported_Request_Option,
      Build_UI_Rejected_Working_Context_Required,
      Build_UI_Rejected_Working_Context_Unavailable,
      Build_UI_Rejected_Unsafe_Working_Context,
      Build_UI_Rejected_Stale_Consent,
      Build_UI_Rejected_Execution_Backend_Disabled);

   type Public_Build_UI_State is record
      Build_UI_Visible : Boolean := False;
      Build_UI_Focused : Boolean := False;
      Selected_Build_Tool : Public_Build_Tool_Selection := Build_UI_No_Tool;
      Build_Target_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected_Working_Context : Editor.Build_Working_Context.Build_Working_Context_Record :=
        (Kind => Editor.Build_Working_Context.Build_Working_Context_None,
         Display_Label => Ada.Strings.Unbounded.Null_Unbounded_String,
         Canonical_Path_If_Available => Ada.Strings.Unbounded.Null_Unbounded_String,
         Source_Kind => Editor.Build_Working_Context.Working_Context_Source_None,
         Validation_Status => Editor.Build_Working_Context.Build_Working_Context_Rejected_None,
         Validation_Message => Ada.Strings.Unbounded.Null_Unbounded_String);
      Build_Working_Context_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Context_Status : Editor.Build_Working_Context.Build_Working_Context_Validation_Status :=
        Editor.Build_Working_Context.Build_Working_Context_Rejected_None;
      Working_Context_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Context_Canonical_Path_If_Available : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Structured_Arguments : Build_UI_Argument_Vector :=
        Build_UI_Argument_Vectors.Empty_Vector;
      Selected_Build_Mode : Build_UI_Build_Mode :=
        Build_UI_Build_Mode_Default;
      Show_Diagnostics_On_Result : Boolean := False;
      Output_Capture_Limit : Build_UI_Output_Capture_Limit :=
        Build_UI_Output_Capture_Normal;
      Option_Verbose_Output : Boolean := False;
      Option_Keep_Going : Boolean := False;
      Option_Warnings_As_Errors : Boolean := False;
      Option_Force_Rebuild : Boolean := False;
      Consent_Acknowledged : Boolean := False;
      Consent_Request_Identity : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Validation_Status : Public_Build_UI_Validation_Status :=
        Build_UI_Rejected_Not_Visible;
      Validation_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Pending_Public_Build_Request : Boolean := False;
      Build_Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Build_Candidate_Vectors.Empty_Vector;
      Selected_Build_Candidate_Id : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Selected_Build_Candidate_Status : Editor.Build_Candidates.Build_Candidate_Validation_Status :=
        Editor.Build_Candidates.Build_Candidate_Unavailable;
      Candidate_Applied_To_Request : Boolean := False;
      Candidate_Request_Preview : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Selection_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Discovery_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Refresh_Status : Build_Candidate_Refresh_Status :=
        Build_Candidate_Refresh_Not_Requested;
      Candidate_Refresh_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Last_Refresh_Candidate_Count : Natural := 0;
      Selected_Action_Row : Natural := 0;
      Action_Top_Row : Natural := 1;
      Selected_Candidate_Stale : Boolean := False;
      Selected_Candidate_Preserved_On_Refresh : Boolean := False;
      Selected_Candidate_Cleared_On_Refresh : Boolean := False;
   end record;

   function Empty_Arguments return Build_UI_Argument_Vector;

   procedure Append_Argument
     (Arguments : in out Build_UI_Argument_Vector;
      Value     : String);

   function Argument_Count (Arguments : Build_UI_Argument_Vector) return Natural;

   function Empty_State return Public_Build_UI_State;

   procedure Show (State : in out Public_Build_UI_State);
   procedure Focus (State : in out Public_Build_UI_State);
   procedure Hide (State : in out Public_Build_UI_State);

   procedure Select_Tool
     (State : in out Public_Build_UI_State;
      Tool  : Public_Build_Tool_Selection);

   procedure Set_Target_Label
     (State : in out Public_Build_UI_State;
      Label : String);

   procedure Select_Working_Context
     (State   : in out Public_Build_UI_State;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record);

   procedure Set_Working_Context_Label
     (State : in out Public_Build_UI_State;
      Label : String);

   procedure Set_Structured_Arguments
     (State     : in out Public_Build_UI_State;
      Arguments : Build_UI_Argument_Vector);

   procedure Set_Show_Diagnostics_On_Result
     (State : in out Public_Build_UI_State;
      Value : Boolean);

   procedure Set_Build_Candidates
     (State      : in out Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector;
      Message    : String := "");

   procedure Select_Build_Candidate
     (State        : in out Public_Build_UI_State;
      Candidate_Id : String);

   procedure Clear_Selected_Build_Candidate
     (State : in out Public_Build_UI_State);

   procedure Apply_Build_Candidate_To_UI_State
     (State     : in out Public_Build_UI_State;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record);

   function Build_Candidate_Request_Preview
     (State : Public_Build_UI_State) return String;

   function Candidate_Count
     (State : Public_Build_UI_State) return Natural;

   procedure Set_Build_Mode
     (State : in out Public_Build_UI_State;
      Mode  : Build_UI_Build_Mode);

   procedure Toggle_Diagnostics_Ingestion
     (State : in out Public_Build_UI_State);

   procedure Cycle_Output_Capture_Limit
     (State : in out Public_Build_UI_State);

   procedure Toggle_Verbose_Output
     (State : in out Public_Build_UI_State);

   procedure Toggle_Keep_Going
     (State : in out Public_Build_UI_State);

   procedure Toggle_Warnings_As_Errors
     (State : in out Public_Build_UI_State);

   procedure Toggle_Force_Rebuild
     (State : in out Public_Build_UI_State);

   procedure Select_Next_Action_Row
     (State : in out Public_Build_UI_State;
      Count : Natural);

   procedure Select_Previous_Action_Row
     (State : in out Public_Build_UI_State;
      Count : Natural);

   procedure Set_Selected_Action_Row
     (State : in out Public_Build_UI_State;
      Row   : Natural;
      Count : Natural);

   function Selected_Action_Row
     (State : Public_Build_UI_State;
      Count : Natural) return Natural;

   function Action_Top_Row
     (State         : Public_Build_UI_State;
      Count         : Natural;
      Visible_Count : Natural) return Natural;

   procedure Ensure_Selected_Action_Row_Visible
     (State         : in out Public_Build_UI_State;
      Count         : Natural;
      Visible_Count : Natural);

   procedure Scroll_Action_Rows
     (State         : in out Public_Build_UI_State;
      Count         : Natural;
      Visible_Count : Natural;
      Amount        : Integer);

   function Build_Mode_Label (Mode : Build_UI_Build_Mode) return String;
   function Output_Capture_Limit_Label
     (Limit : Build_UI_Output_Capture_Limit) return String;

   function Output_Capture_Limit_Bytes
     (Limit : Build_UI_Output_Capture_Limit) return Natural;

   procedure Acknowledge_Consent (State : in out Public_Build_UI_State);
   procedure Clear_Consent (State : in out Public_Build_UI_State);

   function Current_Request_Identity
     (State : Public_Build_UI_State) return String;

   function Validate_Build_UI_State
     (State : Public_Build_UI_State) return Public_Build_UI_Validation_Status;

   function Validation_Message
     (Status : Public_Build_UI_Validation_Status) return String;

   function Recovery_Message
     (Status : Public_Build_UI_Validation_Status) return String;

   function Has_Raw_Shell_Command_Field
     (State : Public_Build_UI_State) return Boolean;

   function Command_Palette_Can_Supply_Candidate
     (State : Public_Build_UI_State) return Boolean;

   function Keybinding_Can_Supply_Candidate
     (State : Public_Build_UI_State) return Boolean;

   function Has_Remembered_Consent_Field
     (State : Public_Build_UI_State) return Boolean;

   function Has_Candidate_Execution_Field
     (State : Public_Build_UI_State) return Boolean;

   function Tool_Label
     (Tool : Public_Build_Tool_Selection) return String;

   function Consent_Label
     (State : Public_Build_UI_State) return String;

   function Build_Render_Snapshot
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Build_UI_Render_Snapshot;

   function Build_Diagnostics_Surface_For
     (Snapshot : Build_UI_Render_Snapshot) return Build_Diagnostics_Surface;

   function Find_Action_Row
     (Snapshot                       : Build_UI_Render_Snapshot;
      Command_Name                   : String;
      Diagnostic_Index               : Natural := 0;
      Quick_Fix_Action_Index         : Natural := 0) return Natural;

   function Assert_Build_UI_Render_Snapshot_Is_Operable
     (Snapshot : Build_UI_Render_Snapshot) return Boolean;

   function Assert_Action_Row_Metadata
     (Row                             : Build_UI_Action_Row;
      Expected_Command_Name           : String;
      Expected_Enabled                : Boolean;
      Expected_Disabled_Reason        : String;
      Expected_Diagnostic_Index       : Natural;
      Expected_Quick_Fix_Action_Index : Natural;
      Expected_Selected               : Boolean := False) return Boolean;

   function Assert_Build_Diagnostics_Surface_Is_Renderable
     (Surface : Build_Diagnostics_Surface) return Boolean;

   function Assert_Build_UI_State_Is_Transient
     (State : Public_Build_UI_State) return Boolean;

   function Assert_Build_UI_Result_Output_Diagnostics_Useful
     (Snapshot : Build_UI_Render_Snapshot) return Boolean;

   function Assert_Public_Build_Result_Output_UI_Coherent
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean;

   function Assert_Build_Request_Is_Structured
     (State : Public_Build_UI_State) return Boolean;

   function Assert_Build_Request_Options_Are_Candidate_Specific
     (State : Public_Build_UI_State) return Boolean;

   function Assert_Build_Request_Preview_Matches_Tokens
     (Snapshot : Build_UI_Render_Snapshot) return Boolean;

   function Assert_Build_Consent_Tied_To_Request_Identity
     (State : Public_Build_UI_State) return Boolean;

   function Assert_Build_Request_State_Not_Persisted
     (State : Public_Build_UI_State) return Boolean;

   function Assert_Build_Request_Configuration_Coherent
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean;

end Editor.Build_UI;
