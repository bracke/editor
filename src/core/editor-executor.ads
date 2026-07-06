with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;
with Editor.Commands;
with Text_Buffer; use Text_Buffer;
with Editor.Cursors; use Editor.Cursors;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Diagnostics;
with Editor.Navigation;
with Editor.Selection;
with Editor.Project_Search;
with Editor.Overlay_Focus;
with Editor.Workspace_Persistence;
with Editor.Dirty_Guards;
with Editor.Command_Execution;
with Editor.Executor_Edit_Status;
with Editor.External_Producers;
with Editor.Navigation_History;
with Editor.Pending_Transitions;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;

package Editor.Executor is


   subtype Command_Execution_Status is
     Editor.Command_Execution.Command_Execution_Status;
   subtype Command_Execution_Result is
     Editor.Command_Execution.Command_Execution_Result;

   Command_Executed : constant Command_Execution_Status :=
     Editor.Command_Execution.Command_Executed;
   Command_Unavailable : constant Command_Execution_Status :=
     Editor.Command_Execution.Command_Unavailable;
   Command_Failed : constant Command_Execution_Status :=
     Editor.Command_Execution.Command_Failed;
   Command_Cancelled : constant Command_Execution_Status :=
     Editor.Command_Execution.Command_Cancelled;
   Command_No_Op : constant Command_Execution_Status :=
     Editor.Command_Execution.Command_No_Op;


   function Is_Focus_Target_Still_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target) return Boolean;

   procedure Restore_Previous_Overlay_Focus
     (S      : in out Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target);

   procedure Activate_Overlay
     (S       : in out Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target);

   procedure Dismiss_Active_Overlay
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason);

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Deactivate_Active_Overlay_Only
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason);

   procedure Execute_No_Log
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_No_Log_With_Status
     (S           : in out Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Line_Status : out Editor.Executor_Edit_Status.Line_Edit_Status);

   --  Return advisory availability for a stable command id. Execution still
   --  validates concrete state before mutation; this predicate exists so
   --  user-invoked unavailable commands can report deterministic feedback.
   --  @param S editor state to inspect.
   --  @param Id stable command identifier.
   --  @return availability flag and concise reason when unavailable.
   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Diagnostic_Quick_Fix_Action_Availability
     (S                : Editor.State.State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural)
      return Editor.Commands.Command_Availability;

   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String;

   --  Execute a stable user-command id through the guarded command boundary.
   --  Availability is checked first and unavailable commands report exactly
   --  one user-visible message without dispatching the mutation handler.
   --  Hidden command ids may still execute through keybinding/context routes.
   --  @param S editor state to inspect and mutate.
   --  @param Id stable command identifier to execute.
   --  @param Shift optional route modifier used by selection/navigation commands.
   procedure Execute_Command
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False);


   --  Execute a stable user-command id and return a compact result for
   --  regression tests. Messages remain the sole user-facing feedback path.
   --  @param S editor state to inspect and mutate.
   --  @param Id stable command identifier to execute.
   --  @param Shift optional route modifier used by selection/navigation commands.
   --  @return Command execution status and command id.
   function Execute_Command_With_Result
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False) return Command_Execution_Result;

   --  Execute the internal/test-only user-opt-in build test-seam command with
   --  structured context supplied by tests or an internal caller.  The normal
   --  public command route has no free-form payload path for this command.
   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : Editor.External_Producers.User_Opt_In_Build_Command_Context;
      Supplied_Result : Editor.External_Producers.Process_Run_Result :=
        (Status        => Editor.External_Producers.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Editor.External_Producers.Build_Command_Result;

   function File_Tree_Status_Message
     (Result : Editor.File_Tree.File_Tree_Scan_Result) return String;

   --  Apply project-open workspace persistence policy after a project was
   --  opened.  This procedure may report available/invalid/restored session
   --  state, but must not make project opening fail solely because session
   --  restore fails.
   --  @param S editor state after project open.
   --  @param Config static lifecycle policy configuration.
   procedure Apply_Project_Open_Workspace_Policy
     (S      : in out Editor.State.State_Type;
      Config : Editor.Workspace_Persistence.Workspace_Lifecycle_Config :=
        Editor.Workspace_Persistence.Default_Workspace_Lifecycle_Config);

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status);

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : out Editor.Workspace_Persistence.Workspace_Restore_Summary);

   function Restore_Summary_Message
     (Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Partial : Boolean) return String;

   procedure Report_Workspace_Load_Status
     (S      : in out Editor.State.State_Type;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status);

   procedure Mark_Restore_Summary_Current
     (S       : in out Editor.State.State_Type;
      Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary);

   procedure Report_Restore_Success
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Report_Restore_Warning
     (S    : in out Editor.State.State_Type;
      Text : String);

   function Extract_Text
     (Buffer : Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Count  : Natural) return Unbounded_String;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Editor.Cursors.Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String);

   procedure Insert_Text_At
     (Buffer : in out Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Text   : Unbounded_String);

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index;

   function Safe_Anchor
     (S : Editor.State.State_Type) return Cursor_Index;

   procedure Set_Primary_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index);

   function Active_Buffer_Known_Project_File
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural;

   function Is_Ada_Source_Path
     (Path : String) return Boolean;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural);

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural);

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type);

   function Has_Selected_Outline_Activation_Target
     (S : Editor.State.State_Type) return Boolean;

   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean;

   function Diagnostic_Availability_Reason
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String;

   function Focus_Feature_Target_Buffer
     (S             : in out Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean;

   --  Internal support surface for executor child command packages.  These
   --  preserve the public executor entry points while allowing command-family
   --  implementations to move out of the parent body.
   function Visible_Restore_Message_In_History
     (S : Editor.State.State_Type) return Boolean;

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type);

   function File_Lifecycle_Confirmation_Pending
     (S : Editor.State.State_Type) return Boolean;

   procedure Clear_Restore_Feedback_Current
     (S : in out Editor.State.State_Type);

   procedure Clear_Reopen_Candidate
     (S : in out Editor.State.State_Type);

   function Trimmed_Command_Text (Text : String) return String;

   function Valid_Buffer_Label_Text (Text : String) return Boolean;

   procedure Start_Dirty_Close_Prompt
     (S           : in out Editor.State.State_Type;
      Scope       : Editor.State.Dirty_Close_Scope;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary);

   procedure Finalize_Cleanup_Buffer_Close
     (S          : in out Editor.State.State_Type;
      Id         : Editor.Buffers.Buffer_Id;
      Was_Active : Boolean);

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type);

   procedure Populate_Project_Known_Files_From_File_Tree
     (S : in out Editor.State.State_Type);

   function File_Tree_Visible_Row_Count_For_View return Natural;

   procedure Validate_File_Tree_View
     (S : in out Editor.State.State_Type);

   function Selected_File_Tree_Node
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Id;

   procedure Select_File_Tree_Node
     (S    : in out Editor.State.State_Type;
      Node : Editor.File_Tree.File_Tree_Node_Id);

   function Current_Navigation_Location
     (S      : Editor.State.State_Type;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location;

   procedure Record_Navigation_If_Target_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location;
      Target   : Editor.Navigation_History.Navigation_Location);

   procedure Record_Navigation_If_Current_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location);

   type Navigation_Apply_Status is
     (Navigation_Applied,
      Navigation_Target_Missing,
      Navigation_Target_Invalid_Location);

   function Apply_Navigation_Location
     (S        : in out Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location;
      Status   : out Navigation_Apply_Status) return Boolean;

   function Same_Navigation_Place
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean;

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location;

   procedure Apply_Feature_Target_Handoff
     (S             : in out Editor.State.State_Type;
      Target_Row    : Natural;
      Target_Column : Natural);

   procedure Sync_Current_Outline_Symbol_From_Caret
     (S : in out Editor.State.State_Type);

   function Search_Results_Visible_Row_Count return Natural;

   function Problems_Visible_Row_Count return Natural;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type);

end Editor.Executor;
