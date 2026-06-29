with Text_Buffer;
with Editor.Cursors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Ada.Calendar;
with Editor.Search;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Dirty_Lines;
with Editor.Input_Field;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
with Editor.Go_To_Line;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Search_Results;
with Editor.Problems;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Workspace_Persistence;
with Editor.Recent_Projects;
with Editor.Pending_Transitions;
with Editor.Settings;
with Editor.Feature_Panel;
with Editor.Feature_Messages;
with Editor.Feature_Search_Results;
with Editor.Feature_Diagnostics;
with Editor.Producer_Contracts;
with Editor.Outline;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.Bookmarks;
with Editor.Commands;
with Editor.Build_UI;
with Editor.Terminal_Tasks;
with Editor.Build_Runner_Policy;
with Editor.Build_Process_Control;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Guided_Prompts;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.Ada_Project_Index;
with Editor.Ada_Language_Service;
with Editor.Ada_Language_Model;

package Editor.State is

   package Line_Start_Vectors is new Ada.Containers.Vectors
      (Index_Type   => Natural,
      Element_Type => Natural);

   type Active_Diagnostic_State is record
      Has_Active : Boolean := False;
      Index      : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   end record;

   type File_Conflict_Kind is
     (No_File_Conflict,
      External_Modified_While_Clean,
      External_Modified_While_Dirty,
      Backing_File_Deleted_While_Clean,
      Backing_File_Deleted_While_Dirty,
      Backing_File_Unreadable,
      Backing_File_Unwritable,
      Backing_File_Replaced,
      Save_Target_Parent_Missing);

   type File_Conflict_Action is
     (No_File_Conflict_Action,
      File_Conflict_Keep_Buffer,
      File_Conflict_Reload_From_Disk,
      File_Conflict_Overwrite_Disk,
      File_Conflict_Cancel);

   type Dirty_Close_Scope is
     (No_Dirty_Close_Scope,
      Active_Buffer_Close_Scope,
      Selected_Buffer_Close_Scope,
      All_Buffers_Close_Scope,
      Transition_Buffer_Close_Scope);

   type File_State is record
      Has_Path     : Boolean := False;
      Path         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("Untitled");
      Dirty        : Boolean := False;
      Baseline_Valid   : Boolean := False;
      Saved_Generation : Natural := 0;
      Last_Save_Failed   : Boolean := False;
      Last_Reload_Failed : Boolean := False;
      Last_Revert_Failed : Boolean := False;
      Missing_Target_Surfaced    : Boolean := False;
      Unreadable_Target_Surfaced : Boolean := False;
      Unwritable_Target_Surfaced : Boolean := False;
      External_Change_Surfaced   : Boolean := False;
      Blocked_Close_Surfaced     : Boolean := False;
      File_Token_Known : Boolean := False;
      File_Token_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   Max_Reopen_Candidates : constant Natural := 16;
   subtype Reopen_Candidate_Index is Positive range 1 .. Max_Reopen_Candidates;
   type Reopen_Candidate_Array is
     array (Reopen_Candidate_Index) of Ada.Strings.Unbounded.Unbounded_String;

   Max_Semantic_Completion_Items : constant Natural := 12;
   subtype Semantic_Completion_Item_Index is
     Positive range 1 .. Max_Semantic_Completion_Items;

   type Semantic_Completion_Item is record
      Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Semantic_Completion_Item_Array is
     array (Semantic_Completion_Item_Index) of Semantic_Completion_Item;

   type Semantic_Popup_Kind is
     (No_Semantic_Popup,
      Semantic_Hover_Popup,
      Semantic_Completion_Popup);

   type Semantic_Popup_State is record
      Active : Boolean := False;
      Kind   : Semantic_Popup_Kind := No_Semantic_Popup;
      Anchor_Row : Natural := 0;
      Anchor_Column : Natural := 0;
      Title  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Item_Count : Natural := 0;
      Selected_Item : Natural := 0;
      Items : Semantic_Completion_Item_Array := (others => (others => <>));
   end record;

   type State_Type is record
      Buffer             : Text_Buffer.Buffer_Type;
      Carets             : Editor.Cursors.Cursors_Vector.Vector;
      --  Cached public line-start projection for callers that need direct
      --  row/index snapshots. Text_Buffer remains the authoritative text store;
      --  mutation paths must refresh this projection through the helpers below.
      Line_Starts        : Line_Start_Vectors.Vector;
      Preferred_Column   : Natural := 0;
      Rect_Select_Active : Boolean := False;
      Rect_Anchor_Row    : Natural := 0;
      Rect_Anchor_Col    : Natural := 0;
      --  Phase 354 active-buffer Find state.  Active Find is transient,
      --  in-memory, and never persisted.
      Active_Find_Query   : Ada.Strings.Unbounded.Unbounded_String;
      Active_Find_Matches : Editor.Search.Search_Match_Vectors.Vector;
      Active_Find_Match   : Editor.Search.Search_Match := Editor.Search.No_Match;
      Active_Find_Stale   : Boolean := False;
      Active_Find_Wrapped : Boolean := False;
      Active_Find_Case_Sensitive : Boolean := False;
      Active_Find_Whole_Word : Boolean := False;
      Active_Find_Source_Buffer_Token : Natural := 0;
      --  Phase 365 active-buffer Replace state. Replace is a transient
      --  extension of canonical Find and is never persisted.
      Active_Replace_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Replace_Error_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Replace_Prompt : Boolean := False;
      Diagnostics       : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Active_Diagnostic : Active_Diagnostic_State;
      Gutter_Markers    : Editor.Gutter_Markers.Gutter_Marker_State;
      Dirty_Lines       : Editor.Dirty_Lines.Dirty_Line_State;
      Project           : Editor.Project.Project_State;
      Recent_Projects   : Editor.Recent_Projects.Recent_Project_List;
      --  Phase 559 transient Recent Projects list selection.  This is never
      --  written to Recent Projects or workspace persistence.
      Recent_Project_Selected_Index : Natural := 0;
      --  Phase 562 transient Recent Projects focus marker.  This is UI-only
      --  focus state, not part of recent-project or workspace persistence.
      Recent_Projects_Focused : Boolean := False;
      Settings          : Editor.Settings.Settings_Model;
      Pending_Transitions : Editor.Pending_Transitions.Pending_Transition_State;
      Feature_Panel    : Editor.Feature_Panel.Feature_Panel_State;
      Outline          : Editor.Outline.Outline_State;
      Feature_Messages : Editor.Feature_Messages.Message_Feature_State;
      Feature_Search_Results : Editor.Feature_Search_Results.Search_Results_Feature_State;
      Feature_Diagnostics : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      --  Passive outline cursor synchronization cache.  Cursor movement may
      --  update the current-symbol marker from the latest accepted outline,
      --  but it must not trigger extraction, selection changes, or navigation.
      Outline_Cursor_Key_Valid : Boolean := False;
      Outline_Cursor_Buffer_Token : Natural := 0;
      Outline_Cursor_Line : Natural := 0;
      Outline_Cursor_Column : Natural := 0;
      File_Tree         : Editor.File_Tree.File_Tree_State;
      File_Tree_View    : Editor.File_Tree_View.File_Tree_View_State;
      Panels            : Editor.Panels.Panel_Set;
      Messages          : Editor.Messages.Message_State;
      Active_Find_Input  : Editor.Input_Field.Input_Field_State;
      Active_Find_Prompt : Boolean := False;
      Quick_Open        : Editor.Quick_Open.Quick_Open_State;
      Buffer_Switcher   : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Go_To_Line       : Editor.Go_To_Line.Go_To_Line_State;
      Navigation_History : Editor.Navigation_History.Navigation_History_State;
      Recent_Buffers    : Editor.Recent_Buffers.Recent_Buffer_State;
      Project_Search    : Editor.Project_Search.Project_Search_State;
      Bookmarks         : Editor.Bookmarks.Bookmark_State;
      Project_Search_Bar : Editor.Project_Search_Bar.Project_Search_Bar_State;
      Search_Results_View : Editor.Search_Results.Search_Results_View_State;
      Problems_View      : Editor.Problems.Problems_View_State;
      Panel_Focus      : Editor.Panel_Focus.Panel_Focus_State;
      Overlay_Focus    : Editor.Overlay_Focus.Overlay_Focus_State;
      Gutter_Marker_Hover : Editor.Gutter_Markers.Gutter_Marker_Hover_State;
      Semantic_Popup   : Semantic_Popup_State;
      Folding           : Editor.Folding.Folding_State;
      File_Info         : File_State;
      --  Phase 542 transient path-only reopen stack.  This is runtime
      --  state only: no closed-buffer text, edit history, caret/selection,
      --  Find/Replace, Clipboard, Navigation History, render cache, or
      --  persistence data is stored here.  The single-candidate mirror fields
      --  mirror the top stack entry for test support and
      --  projections; persistence must still exclude all of these fields.
      Reopen_Candidate_Count : Natural := 0;
      Reopen_Candidate_Paths : Reopen_Candidate_Array :=
        (others => Ada.Strings.Unbounded.Null_Unbounded_String);
      Reopen_Candidate_Labels : Reopen_Candidate_Array :=
        (others => Ada.Strings.Unbounded.Null_Unbounded_String);
      Has_Reopen_Candidate : Boolean := False;
      Reopen_Candidate_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reopen_Candidate_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Registry_Token    : Natural := 0;
      Active_Buffer_Token : Natural := 0;
      Buffer_Revision   : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      --  Transient per-buffer syntax state. This is intentionally runtime-only:
      --  it is invalidated by text changes/reload/revert, consumed by render
      --  snapshots, and never serialized to workspace/session files.
      Syntax_Cache      : Editor.Syntax_Cache.Syntax_Cache;
      Syntax_Symbols    : Editor.Syntax_Semantics.Semantic_Map;
      --  Parser-owned analysis retained for render-time scope-aware semantic
      --  lookup.  This is stamped with the same buffer/revision as
      --  Syntax_Symbols and is never persisted.
      Syntax_Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      --  Transient in-process Ada project language index.  This is runtime-only
      --  and is cleared or invalidated by explicit language-index commands and
      --  project/buffer lifecycle paths; it is never persisted.
      Language_Index    : Editor.Ada_Project_Index.Index_State;
      --  Transient language-service facade state.  It mirrors the project
      --  language index for model-backed navigation and retains compiler-backed
      --  diagnostic output from explicit build runs for IDE language consumers.
      --  It is never persisted.
      Language_Service  : Editor.Ada_Language_Service.Service_State;
      Syntax_Source_Revision : Natural := Natural'Last;
      Syntax_Source_Buffer_Token : Natural := 0;
      Syntax_Symbols_Revision : Natural := Natural'Last;
      Syntax_Symbols_Buffer_Token : Natural := 0;
      --  Transient UI-only marker: the latest visible restore feedback may
      --  be projected as current command feedback only until the next
      --  ordinary interaction replaces restore context with normal state.
      Post_Restore_Feedback_Current : Boolean := False;
      --  Phase 468 transient file-lifecycle target prompt. This is UI/input
      --  state only and is never persisted, used for save-as/rename/copy/move
      --  parameter acquisition before canonical Executor execution.
      File_Target_Prompt_Active : Boolean := False;
      File_Target_Prompt_Command : Editor.Commands.Command_Id :=
        Editor.Commands.No_Command;
      File_Target_Prompt_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Target_Prompt_Input : Editor.Input_Field.Input_Field_State;
      --  Phase 574 transient file-conflict prompt state.  It contains only
      --  buffer/path identity and visible action state, never buffer text,
      --  never persisted tokens, and never keybinding/palette payloads.
      File_Conflict_Prompt_Active : Boolean := False;
      File_Conflict_Prompt_Buffer : Natural := 0;
      File_Conflict_Prompt_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Conflict_Prompt_Display : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Conflict_Prompt_Kind : File_Conflict_Kind := No_File_Conflict;
      File_Conflict_Prompt_Dirty : Boolean := False;
      --  Buffer revision captured when the prompt was opened.  This lets
      --  confirmation reject stale prompts if buffer text changed through any
      --  route while the prompt was visible, without storing buffer text.
      File_Conflict_Prompt_Buffer_Revision : Natural := 0;
      File_Conflict_Prompt_Token_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      --  Phase 575/574 interaction: when save-and-close discovers an
      --  external conflict, the file-conflict prompt owns the overwrite
      --  decision.  These transient fields remember only the buffer identity
      --  needed to close after an explicit overwrite succeeds; no text, path
      --  payload, keybinding payload, or persisted close request is stored.
      File_Conflict_Close_After_Overwrite : Boolean := False;
      File_Conflict_Close_After_Overwrite_Buffer : Natural := 0;
      File_Conflict_Close_After_Overwrite_Selected : Boolean := False;
      File_Conflict_Close_After_Overwrite_All_Buffers : Boolean := False;
      --  Phase 575 transient dirty-buffer close review.  It stores only
      --  buffer identities and counts while a close prompt is active; never
      --  buffer text, persisted payloads, keybinding payloads, or workspace
      --  state.
      Dirty_Close_Prompt_Active : Boolean := False;
      Dirty_Close_Prompt_Scope : Dirty_Close_Scope := No_Dirty_Close_Scope;
      Dirty_Close_Prompt_All_Buffers : Boolean := False;
      Dirty_Close_Prompt_Buffer : Natural := 0;
      --  Number of open buffers when an all-buffers close review was opened.
      --  Used only for transient confirmation-time staleness checks; it is
      --  never persisted and never carries text or command payloads.
      Dirty_Close_Prompt_Buffer_Count : Natural := 0;
      --  Transient fingerprint of open buffer identities for all-buffer
      --  close review staleness detection.  This prevents a same-count
      --  buffer replacement from inheriting a prior discard/save prompt.
      Dirty_Close_Prompt_Buffer_Fingerprint : Natural := 0;
      --  Transient serialized identity set of all open buffers when an
      --  all-buffers close review was opened.  The fingerprint above is a
      --  fast diagnostic/snapshot value; this exact id list is the authority
      --  for confirmation-time stale-review checks and prevents arithmetic
      --  fingerprint collisions from authorizing a changed buffer set.
      Dirty_Close_Prompt_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      --  Transient fingerprint of dirty buffer identities for all-buffer
      --  close review staleness detection.  This prevents newly dirtied
      --  buffers from inheriting a prior discard/save prompt that did not
      --  explicitly review them.
      Dirty_Close_Prompt_Dirty_Fingerprint : Natural := 0;
      --  Transient serialized identity set of buffers that were dirty when
      --  an all-buffers close review was opened.  This lets confirmation
      --  accept reviewed dirty buffers becoming clean while still rejecting
      --  newly dirtied buffers that were not reviewed.  It stores only buffer
      --  identities, never text or persisted payloads.
      Dirty_Close_Prompt_Dirty_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Close_Prompt_Dirty_Count : Natural := 0;
      Dirty_Close_Prompt_File_Backed_Count : Natural := 0;
      Dirty_Close_Prompt_Untitled_Count : Natural := 0;
      Dirty_Close_Prompt_Conflicted_Count : Natural := 0;
      Dirty_Close_Prompt_Unwritable_Count : Natural := 0;
      Dirty_Close_Prompt_Missing_Count : Natural := 0;
      Dirty_Close_Prompt_Save_Failure_Count : Natural := 0;
      --  Phase 501 transient public build UX input/consent state. This is not
      --  workspace, settings, recent-project, keybinding, Diagnostics, or
      --  persistence state.
      Build_UI : Editor.Build_UI.Public_Build_UI_State;
      --  Transient integrated terminal/task state.  It owns visible task rows,
      --  selected task, bounded output, and rerun metadata only; it is not
      --  persisted into workspace/settings files.
      Terminal_Tasks : Editor.Terminal_Tasks.Terminal_Task_State;
      --  Phase 510 transient latest build.run result summary. It is a
      --  snapshot projection only: no history, rerun payload, process handle,
      --  cancellation token, Diagnostics rows, or persistence state.
      Latest_Build_Result :
        Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      --  Phase 562 transient focus marker for the latest build result
      --  summary surface.  The summary data remains display-only and this
      --  flag is never persisted.
      Latest_Build_Result_Focused : Boolean := False;
      --  Phase 514 transient latest build.run bounded output details. It is a
      --  snapshot projection over bounded stdout/stderr captures and active
      --  stream excerpts: no history, terminal emulation, rerun payload,
      --  process handle, Diagnostics rows, or persistence state.
      Latest_Build_Output_Details :
        Editor.Build_Output_Details.Latest_Build_Output_Details;
      --  Phase 504 transient runtime execution policy for public build.run.
      --  It is deliberately outside workspace/settings/recent/keybinding
      --  persistence and is not supplied by palette/keybinding/UI payloads.
      Public_Build_Execution_Policy :
        Editor.Build_Runner_Policy.Build_Execution_Policy :=
          Editor.Build_Runner_Policy.Build_Execution_Disabled;
      --  Transient active build job model for build.cancel.  It records only
      --  the current live process-control handle and cancellation state while
      --  the build is active; it is never persisted, never exposed through
      --  keybinding payloads, and never stores rerun argv or full output logs.
      Public_Build_Job_Active : Boolean := False;
      Public_Build_Job_Id : Natural := 0;
      Public_Build_Job_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Public_Build_Job_Cancellation :
        Editor.Build_Runner_Policy.Build_Cancellation_State :=
          Editor.Build_Runner_Policy.No_Cancellation_Requested;
      Public_Build_Process_Handle :
        Editor.Build_Process_Control.Build_Process_Handle :=
          Editor.Build_Process_Control.No_Process_Handle;
      --  Transient asynchronous public build job markers.  State_Type owns
      --  the observable job lifecycle, stable async slot id, and cancellation
      --  state.  The build command runner transfers copied request/gate/result
      --  payloads through a bounded protected build-job service keyed by
      --  Public_Build_Async_Slot_Id and Public_Build_Job_Id; it must not keep
      --  one unnamed package-level job payload or worker singleton.
      Public_Build_Async_Slot_Id : Natural := 0;
      Public_Build_Async_Job_Queued : Boolean := False;
      Public_Build_Async_Job_Result_Pending : Boolean := False;
      --  Transient incremental build output stream for the active public build
      --  job.  It stores bounded display excerpts only; no process handle,
      --  rerun payload, full terminal log, or persistence state is stored here.
      Public_Build_Output_Stream :
        Editor.Build_Output_Details.Build_Output_Stream_State;
      --  Phase 571 transient guided workflow prompt state. This state owns
      --  modal/scoped prompt input, validation, captured chords, and pending
      --  confirmation summaries only while a multi-step workflow is active.
      --  It is deliberately excluded from workspace, settings, keybindings,
      --  recent-projects, and every persistence domain.
      Guided_Prompt : Editor.Guided_Prompts.Prompt_State;
   end record;

   type Project_Scoped_State_Summary is record
      Has_Project_Root            : Boolean := False;
      File_Tree_Node_Count        : Natural := 0;
      File_Tree_Expansion_Count   : Natural := 0;
      Quick_Open_Result_Count     : Natural := 0;
      Project_Search_Result_Count : Natural := 0;
      Bookmark_Count               : Natural := 0;
      Bookmarks_Visible            : Boolean := False;
      Search_Results_Row_Count    : Natural := 0;
      Has_Project_Search_Query    : Boolean := False;
      Feature_Panel_Row_Count     : Natural := 0;
      Feature_Panel_Selected_Row  : Natural := 0;
      Feature_Panel_Has_Selection : Boolean := False;
      Feature_Panel_Visible       : Boolean := False;
      Feature_Panel_Focused       : Boolean := False;
      Feature_Panel_Fingerprint   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Outline_Item_Count          : Natural := 0;
      Outline_Has_Items           : Boolean := False;
      Outline_Fingerprint         : Natural := 0;
      Feature_Message_Row_Count   : Natural := 0;
      Feature_Search_Result_Count : Natural := 0;
      Feature_Diagnostic_Row_Count : Natural := 0;
      Has_Pending_Project_Target  : Boolean := False;
   end record;

   type Buffer_Change is record
      Start_Index : Natural;
      Old_Length  : Natural;
      New_Length  : Natural;
   end record;


   --  Phase 51 active-buffer projection helpers.  During the active-buffer
   --  migration State_Type remains the active document projection while
   --  Editor.Buffers owns the registry used by executor buffer operations.
   function Has_Active_Buffer (S : State_Type) return Boolean;

   function Active_Buffer (S : State_Type) return State_Type;

   function Current_File (S : State_Type) return File_State;

   procedure Set_Current_File
     (S    : in out State_Type;
      File : File_State);

   function Is_Dirty (S : State_Type) return Boolean;

   procedure Set_Dirty
     (S     : in out State_Type;
      Dirty : Boolean);

   procedure Initialize (S : out State_Type);

   --  Clear the canonical transient file-lifecycle target prompt state.
   --  This helper owns lifecycle cleanup for pending command, label, and
   --  editable target input; it performs no command execution and writes no
   --  persistence state.
   procedure Clear_File_Target_Prompt (S : in out State_Type);

   --  Apply validated global editor settings to stable subsystem boundaries.
   --  This does not open files, mutate project roots, touch dirty state, or
   --  restore workspace/recent-project state.
   procedure Apply_Settings
     (S        : in out State_Type;
      Settings : Editor.Settings.Settings_Model);

   procedure Apply_Settings
     (S        : in out State_Type;
      Settings : Editor.Settings.Settings_Model;
      Summary  : out Editor.Settings.Settings_Apply_Summary);

   procedure Mutate_Buffer
     (S : in out State_Type;
      Op : access procedure (B : in out Text_Buffer.Buffer_Type));

   procedure Rebuild_Line_Index (S : in out State_Type);

   procedure Load_Text
     (S    : in out State_Type;
      Text : String);

   procedure Replace_Document
     (S    : in out State_Type;
      Text : String);

   --  Replace only the editable buffer contents and reset buffer-local
   --  caret/selection/search/diagnostic/folding/marker state. File identity
   --  and lifecycle metadata are preserved; callers that need a fresh untitled
   --  buffer should use Load_Text.
   --  @param S editor state to mutate
   --  @param Contents complete replacement document text
   procedure Replace_Buffer_Contents
     (S        : in out State_Type;
      Contents : String);

   --  Serialize the current editable buffer contents using the editor's
   --  internal newline convention.
   --  @param S editor state whose buffer is serialized
   --  @return complete current buffer text
   function Current_Text
     (S : State_Type) return String;

   function Current_Buffer_Revision
     (S : State_Type) return Natural;

   function Current_Lifecycle_Generation
     (S : State_Type) return Natural;

   --  Recompute line-level dirty classification for the current active-buffer
   --  projection without changing the saved/opened baseline.
   --  @param S editor state whose dirty-line state is refreshed
   procedure Refresh_Dirty_Lines
     (S : in out State_Type);

   --  Replace the line-level baseline with the current active-buffer text and
   --  clear all dirty rows.  Call only after successful open/new/save/save-as
   --  baseline-establishing operations.
   --  @param S editor state whose current text becomes the clean baseline
   procedure Reset_Dirty_Line_Baseline
     (S : in out State_Type);

   function Line_Count (S : State_Type) return Natural;

   function Row_For_Index
     (S     : State_Type;
      Index : Editor.Cursors.Cursor_Index) return Natural;

   procedure Row_Col_For_Index
     (S     : State_Type;
      Index : Editor.Cursors.Cursor_Index;
      Row   : out Natural;
      Col   : out Natural);

   function Line_Start
     (S   : State_Type;
      Row : Natural) return Editor.Cursors.Cursor_Index;

   function Line_End
     (S   : State_Type;
      Row : Natural) return Editor.Cursors.Cursor_Index;

   --  Prepare the active buffer's runtime syntax cache for a visible row range.
   --  This is a render-model preparation step, not a packet-builder side effect.
   procedure Prepare_Syntax_For_Visible_Range
     (S          : in out State_Type;
      First_Row  : Natural;
      Last_Row   : Natural;
      Use_Semantic_Colouring : Boolean := True);

   procedure Rebuild_After_Buffer_Change
    (S : in out State_Type);

   procedure Rebuild_After_Buffer_Change
   (S      : in out State_Type;
    Change : Buffer_Change);

   --  Initialize editor state using the global configuration startup order:
   --  defaults and command metadata, default runtime keybindings, global
   --  settings load/apply, global keybindings load/apply, recent projects,
   --  then project/workspace lifecycle setup by higher-level startup code.
   --  This does not initialize rendering/font/runtime services.
   procedure Init (S : out State_Type);
   procedure Normalize_Carets (S : in out State_Type);

   procedure Add_Diagnostic
     (S           : in out State_Type;
      Start_Index : Editor.Cursors.Cursor_Index;
      End_Index   : Editor.Cursors.Cursor_Index;
      Severity    : Editor.Diagnostics.Diagnostic_Severity;
      Message     : String := "");

   procedure Clear_Diagnostics
     (S : in out State_Type);

   function Normalize_Diagnostic_Source
     (Source : String) return String;

   function Post_Diagnostic_With_Result
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String := "") return Editor.Producer_Contracts.Producer_Result;

   procedure Post_Diagnostic
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String := "");

   function Post_Targeted_Diagnostic_With_Result
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural) return Editor.Producer_Contracts.Producer_Result;

   procedure Post_Targeted_Diagnostic
     (S        : in out State_Type;
      Severity : Editor.Feature_Diagnostics.Diagnostic_Severity;
      Message  : String;
      Source   : String;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural);

   procedure Toggle_Bookmark
     (S   : in out State_Type;
      Row : Natural);

   procedure Clear_Gutter_Marker_Hover
     (S : in out State_Type);

   procedure Set_Gutter_Marker_Hover
     (S    : in out State_Type;
      Row  : Natural;
      Kind : Editor.Gutter_Markers.Gutter_Marker_Kind);

   procedure Check_Line_Index (S : State_Type);

   --  Return a compact audit snapshot of state derived from the active project.
   --  The summary intentionally excludes global state such as theme, recent
   --  projects, workspace session files, clipboard, messages, and buffer text.
   --  @param S editor state to inspect
   --  @return project-scoped state counters and booleans
   function Project_Scoped_State_Summary_For
     (S : State_Type) return Project_Scoped_State_Summary;

   --  Reset only project-scoped state for a guarded project close/clear/open transition.
   --  This helper does not save buffers, discard edits, mutate recent projects,
   --  delete workspace session files, or reset global editor preferences.
   --  @param S editor state to mutate
   procedure Reset_Project_Scoped_State
     (S : in out State_Type);

   --  Build a conservative, serializable workspace/session snapshot.
   --  Volatile editor data such as unsaved text, undo/redo, clipboard,
   --  overlays, diagnostics, search results, and render caches are excluded.
   function Build_Workspace_Snapshot
     (S : State_Type) return Editor.Workspace_Persistence.Workspace_Snapshot;

end Editor.State;
