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
with Editor.External_Producers;
with Editor.Feature_Diagnostics;

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

   procedure Deactivate_Active_Overlay_Only
     (S      : in out Editor.State.State_Type;
      Reason : Editor.Overlay_Focus.Overlay_Dismissal_Reason);

   procedure Execute_No_Log
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

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

   function Check_Dirty_Transition
     (State : Editor.State.State_Type;
      Kind  : Editor.Dirty_Guards.Dirty_Transition_Kind)
      return Editor.Dirty_Guards.Dirty_Transition_Result;

   --  Return whether the currently stored pending transition still points at
   --  live editor/project/workspace state.  This is side-effect-free.
   function Pending_Transition_Is_Still_Valid
     (State : Editor.State.State_Type) return Boolean;

   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String;

   --  Clear stale pending-transition state without reporting.  User-visible
   --  retry/action paths report their own single outcome message.
   procedure Invalidate_Pending_Transition_If_Stale
     (State : in out Editor.State.State_Type);

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

   --  Build the current command-palette candidate snapshot, including
   --  context-aware availability and unavailable reasons.
   --  @param S editor state to inspect.
   --  @param Result filtered command candidates in deterministic display order.
   procedure Command_Palette_Candidates
     (S      : Editor.State.State_Type;
      Result : out Editor.Commands.Command_Palette_Candidate_Vectors.Vector);



   --  Descriptor-owned minimal prompt metadata consumers.  These do not own
   --  prompt truth tables; Editor.Commands is the canonical static source.
   function Command_Requires_File_Target_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Descriptor-owned explicit-target query mirrored for executor callers.
   function Command_Requires_Explicit_Target
     (Id : Editor.Commands.Command_Id) return Boolean;

   function File_Target_Prompt_Is_Active
     (S : Editor.State.State_Type) return Boolean;

   function File_Target_Prompt_Input_Text
     (S : Editor.State.State_Type) return String;

   function File_Target_Prompt_Label
     (S : Editor.State.State_Type) return String;

   procedure Open_File_Target_Prompt
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id);

   procedure Cancel_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Confirm_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Insert_File_Target_Prompt_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Select_All_File_Target_Prompt_Text
     (S : in out Editor.State.State_Type);

   procedure Backspace_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Delete_Forward_File_Target_Prompt
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_Start
     (S : in out Editor.State.State_Type);

   procedure Move_File_Target_Prompt_Cursor_End
     (S : in out Editor.State.State_Type);


   --  Execute one canonical file lifecycle command that carries an explicit
   --  target path.  This is the single dispatch seam used by transient
   --  target-prompt confirmation and structured explicit-target command
   --  execution; it performs no prompt-specific validation.
   procedure Execute_File_Target_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Target : String);

   procedure Execute_Open_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   --  Open a project/folder root without changing buffers or file identity.
   --  @param S editor state whose global project state receives the result
   --  @param Path host filesystem directory path to open as the project root
   procedure Execute_Open_Project
     (S                        : in out Editor.State.State_Type;
      Path                     : String;
      Refresh_Build_Candidates : Boolean := True;
      Apply_Workspace_Policy   : Boolean := True;
      Recent_Project_Open      : Boolean := False;
      Explicit_Switch          : Boolean := False);

   --  Refresh the editor-global file tree from the active project root.
   --  @param S editor state whose file tree and messages are updated
   procedure Execute_Refresh_File_Tree
     (S : in out Editor.State.State_Type);

   procedure Execute_Refresh_Project_Files
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Files_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Selected_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Selected_Recent_Project
     (S : in out Editor.State.State_Type);

   procedure Execute_Remove_Missing_Recent_Projects
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Node_Action
     (S      : in out Editor.State.State_Type;
      Node   : Editor.File_Tree.File_Tree_Node_Id;
      Action : Editor.File_Tree_View.File_Tree_Action);

   procedure Execute_File_Tree_Action
     (S   : in out Editor.State.State_Type;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result);

   procedure Execute_Save
     (S : in out Editor.State.State_Type);

   --  Explicitly reload the active clean associated buffer from disk.
   --  Dirty buffers are blocked; reload never saves, discards, closes,
   --  reopens, watches, or persists disk text.
   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type);

   --  Explicitly discard active dirty associated buffer changes by
   --  rereading the associated file from disk after successful validation.
   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type);

   --  Explicitly rename the active clean associated buffer's backing file to
   --  an explicit target path. The association updates only after filesystem
   --  rename success; text and saved baseline text are preserved.
   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   --  Explicitly delete the active clean associated buffer's backing file.
   --  The buffer remains open as unsaved in-memory text after filesystem
   --  delete success; dirty buffers are blocked.
   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type);

   --  Explicitly copy the active clean associated buffer's backing file to
   --  an explicit target path. The active buffer association, text, saved
   --  baseline, and dirty state are preserved.
   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   --  Explicitly move the active clean associated buffer's backing file to
   --  an explicit target path. The active association updates only after
   --  filesystem success; text, saved baseline, and dirty state are preserved.
   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Save_Workspace_State
     (S : in out Editor.State.State_Type);

   procedure Execute_Restore_Workspace_State
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Workspace_State
     (S : in out Editor.State.State_Type);

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

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_All_Clean_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Reopen_Closed_Buffer
     (S : in out Editor.State.State_Type);


   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String);


   procedure Execute_New_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Switch_Buffer
     (S                : in out Editor.State.State_Type;
      Id               : Editor.Buffers.Buffer_Id;
      Recent_Traversal : Boolean := False;
      Emit_Feedback    : Boolean := True);

   procedure Execute_Previous_Recent_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Next_Recent_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id);

   procedure Execute_Next_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Problems_Panel
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Editor_Text
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Problems
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_File_Tree
     (S : in out Editor.State.State_Type);


   --  Select a live outline row from a mouse/projection hit without moving
   --  the editor cursor or changing current-symbol state. Expected generation
   --  zero disables stale-projection checking for non-rendered tests.
   function Execute_Outline_Row_Click
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;

   --  Activate a live outline row by first selecting it through the same row
   --  validation path and then dispatching outline.open-selected.
   function Execute_Outline_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;


   --  Select a live Messages row without moving the editor cursor.
   function Execute_Message_Row_Click
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;

   --  Activate a live Messages row with a validated target.
   function Execute_Message_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;

   --  Activate a live Search Results scaffold row with a validated target.
   function Execute_Search_Result_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;

   --  Activate a live Diagnostics row with a validated target.
   function Execute_Diagnostic_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Command_Execution_Result;

   --  Activate a live Diagnostics item by explicit Diagnostic_Id without
   --  relying on a projected row. The id must still be live, targeted at the
   --  active buffer token, and in active-buffer range. This helper does not
   --  open files, start producers, or repair stale projections.
   function Execute_Diagnostic_Id_Activation
     (S  : in out Editor.State.State_Type;
      Id : Editor.Feature_Diagnostics.Diagnostic_Id)
      return Command_Execution_Result;


   procedure Execute_File_Tree_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Collapse_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Expand_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Toggle_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Bottom_Panel_Focus
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Focus_Editor
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String);

   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural);

   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Scope_Selected_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Scope_Set
     (S     : in out Editor.State.State_Type;
      Scope : String);

   procedure Execute_Project_Search_Scope_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Case_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Case_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Whole_Word_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Whole_Word_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Regex_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Regex_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Include_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String);

   procedure Execute_Project_Search_Exclude_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String);

   procedure Execute_Project_Search_Include_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Exclude_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Jump_To_Diagnostic
     (S     : in out Editor.State.State_Type;
      Index : Editor.Diagnostics.Diagnostic_Index);

   procedure Execute_Next_Diagnostic
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Diagnostic
     (S : in out Editor.State.State_Type);

   procedure Execute_Jump_To_Diagnostic_On_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Toggle_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Bookmark_At_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Next_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Bookmark
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Bookmarks
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_All_Bookmarks
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Toggle_Current_Location
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Clear_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Goto_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Goto_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Reveal_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Remove_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Bookmark_Toggle_Surface
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Line_At
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Extend_Selection_By_Line
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction);

   procedure Execute_Extend_Selection_To_Line
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Select_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_All_Selection_Command
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Selection_Command
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Current_Word_Command
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Word_At
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural);

   procedure Execute_Extend_Selection_By_Word
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction);

   --  Start rectangular-selection mode at the primary caret. This command only
   --  changes selection state; it must not mutate text, dirty-line state, or
   --  undo history.
   procedure Execute_Start_Rectangular_Selection
     (S : in out Editor.State.State_Type);

   --  Store a normalized grid-cell rectangle on the active buffer projection.
   --  Rows are inclusive and columns are half-open. Secondary carets are
   --  cleared by the Phase 68 single-rectangle policy.
   procedure Execute_Set_Rectangular_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Editor.Selection.Text_Position;
      Cursor : Editor.Selection.Text_Position);

   --  Clear rectangular-selection mode and collapse to the current primary
   --  cursor. Ordinary linear selections are left to the existing selection
   --  commands.
   procedure Execute_Clear_Rectangular_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Find_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_From_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_From_Active_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_First
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Last
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Reveal_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Prefill_Goto_Line_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Next_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Previous_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Reveal_Active
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Active_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Priority_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Priority_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Next_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Previous_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Buffer_Switcher_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Pinned
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Group
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Filter_Label
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Filter_Noted
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Sort
     (S    : in out Editor.State.State_Type;
      Mode : Editor.Buffer_Switcher.Switcher_Sort_Mode);

   procedure Execute_Buffer_Switcher_Sort_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Sort_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Close
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Pin
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Unpin
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Toggle_Pin
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Group_Assign
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Selected_Group_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Label_Set
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Selected_Label_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Selected_Note_Set
     (S    : in out Editor.State.State_Type;
      Note : String);

   procedure Execute_Buffer_Switcher_Selected_Note_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Next_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Previous_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Preview_Center_Cursor
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Set
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Clear_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Invert_Visible
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Visible
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Clear_Visible
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Pinned
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Group
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Mark_Label
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Mark_Noted
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Close_Marked
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Confirm
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Pin_Marked
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Unpin_Marked
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Clear_Metadata
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Group_Assign
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Mark_Group_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Label_Set
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Mark_Label_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Note_Set
     (S    : in out Editor.State.State_Type;
      Note : String);

   procedure Execute_Buffer_Switcher_Mark_Note_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Review_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Review_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Review_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Pending_Mark_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Active_Find_Input_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Start
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_End
     (S : in out Editor.State.State_Type);


   --  Preserve the rectangular anchor and update the rectangular cursor to the
   --  given document row/grid column. If rectangular mode is not active yet,
   --  the primary caret becomes the anchor.
   procedure Execute_Select_Rectangle_To
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural);


   function Extract_Text
     (Buffer : Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Count  : Natural) return Unbounded_String;

   procedure Insert_Text_At
     (Buffer : in out Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Text   : Unbounded_String);

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index;

end Editor.Executor;
