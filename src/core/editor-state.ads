with Editor.Command_Ids; use Editor.Command_Ids;
with Text_Buffer;
with Editor.Cursors;
with Ada.Strings.Unbounded;
with Ada.Calendar;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Dirty_Lines;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
with Editor.Go_To_Line;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Workspace_Persistence;
with Editor.Pending_Transitions;
with Editor.Settings;
with Editor.Feature_Diagnostics;
with Editor.Producer_Contracts;
with Editor.Outline;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.Bookmarks;
with Editor.Guided_Prompts;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.Ada_Project_Index;
with Editor.Ada_Language_Service;
with Editor.Ada_Language_Model;
with Editor.State_Buffer;
with Editor.State_Search;
with Editor.State_Project;
with Editor.State_Panel;
with Editor.State_Semantic;
with Editor.State_Build;
with Editor.State_Caret;
with Editor.State_Outline;
with Editor.State_Surface;

package Editor.State is

   package Line_Start_Vectors renames
     Editor.State_Buffer.Line_Start_Vectors;

   subtype Active_Diagnostic_State is
     Editor.State_Panel.Active_Diagnostic_State;

   subtype File_Conflict_Kind is
     Editor.State_Buffer.File_Conflict_Kind;
   No_File_Conflict : constant File_Conflict_Kind :=
     Editor.State_Buffer.No_File_Conflict;
   External_Modified_While_Clean : constant File_Conflict_Kind :=
     Editor.State_Buffer.External_Modified_While_Clean;
   External_Modified_While_Dirty : constant File_Conflict_Kind :=
     Editor.State_Buffer.External_Modified_While_Dirty;
   Backing_File_Deleted_While_Clean : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Deleted_While_Clean;
   Backing_File_Deleted_While_Dirty : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Deleted_While_Dirty;
   Backing_File_Unreadable : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Unreadable;
   Backing_File_Unwritable : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Unwritable;
   Backing_File_Replaced : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Replaced;
   Save_Target_Parent_Missing : constant File_Conflict_Kind :=
     Editor.State_Buffer.Save_Target_Parent_Missing;

   subtype File_Conflict_Action is
     Editor.State_Buffer.File_Conflict_Action;
   No_File_Conflict_Action : constant File_Conflict_Action :=
     Editor.State_Buffer.No_File_Conflict_Action;
   File_Conflict_Keep_Buffer : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Keep_Buffer;
   File_Conflict_Reload_From_Disk : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Reload_From_Disk;
   File_Conflict_Overwrite_Disk : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Overwrite_Disk;
   File_Conflict_Cancel : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Cancel;

   subtype Dirty_Close_Scope is
     Editor.State_Buffer.Dirty_Close_Scope;
   No_Dirty_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.No_Dirty_Close_Scope;
   Active_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Active_Buffer_Close_Scope;
   Selected_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Selected_Buffer_Close_Scope;
   All_Buffers_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.All_Buffers_Close_Scope;
   Transition_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Transition_Buffer_Close_Scope;

   subtype File_State is Editor.State_Buffer.File_State;
   Max_Reopen_Candidates : constant Natural :=
     Editor.State_Buffer.Max_Reopen_Candidates;
   subtype Reopen_Candidate_Index is
     Editor.State_Buffer.Reopen_Candidate_Index;
   subtype Reopen_Candidate_Array is
     Editor.State_Buffer.Reopen_Candidate_Array;

   Max_Semantic_Completion_Items : constant Natural :=
     Editor.State_Semantic.Max_Semantic_Completion_Items;
   subtype Semantic_Completion_Item_Index is
     Editor.State_Semantic.Semantic_Completion_Item_Index;
   subtype Semantic_Completion_Item is
     Editor.State_Semantic.Semantic_Completion_Item;
   subtype Semantic_Completion_Item_Array is
     Editor.State_Semantic.Semantic_Completion_Item_Array;
   subtype Semantic_Popup_Kind is
     Editor.State_Semantic.Semantic_Popup_Kind;
   No_Semantic_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.No_Semantic_Popup;
   Semantic_Hover_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.Semantic_Hover_Popup;
   Semantic_Completion_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.Semantic_Completion_Popup;
   subtype Semantic_Popup_State is
     Editor.State_Semantic.Semantic_Popup_State;
   subtype Quick_Fix_Workflow_State is
     Editor.State_Semantic.Quick_Fix_Workflow_State;

   type State_Type is record
      Buffer             : Text_Buffer.Buffer_Type;
      Caret            : Editor.State_Caret.Caret_Runtime_State;
      --  Cached public line-start projection for callers that need direct
      --  row/index snapshots. Text_Buffer remains the authoritative text store;
      --  mutation paths must refresh this projection through the helpers below.
      Line_Starts        : Line_Start_Vectors.Vector;
      Search           : Editor.State_Search.Search_Runtime_State;
      Panel            : Editor.State_Panel.Panel_Runtime_State;
      Gutter_Markers    : Editor.Gutter_Markers.Gutter_Marker_State;
      Dirty_Lines       : Editor.Dirty_Lines.Dirty_Line_State;
      Project_Runtime   : Editor.State_Project.Project_Runtime_State;
      Settings          : Editor.Settings.Settings_Model;
      Pending_Transitions : Editor.Pending_Transitions.Pending_Transition_State;
      Outline          : Editor.Outline.Outline_State;
      --  Passive outline cursor synchronization cache.  Cursor movement may
      --  update the current-symbol marker from the latest accepted outline,
      --  but it must not trigger extraction, selection changes, or navigation.
      Outline_Cursor  : Editor.State_Outline.Outline_Cursor_Sync_State;
      Surface         : Editor.State_Surface.Surface_Runtime_State;
      Panels            : Editor.Panels.Panel_Set;
      Navigation_History : Editor.Navigation_History.Navigation_History_State;
      Recent_Buffers    : Editor.Recent_Buffers.Recent_Buffer_State;
      Bookmarks         : Editor.Bookmarks.Bookmark_State;
      Gutter_Marker_Hover : Editor.Gutter_Markers.Gutter_Marker_Hover_State;
      Semantic         : Editor.State_Semantic.Semantic_Runtime_State;
      Folding           : Editor.Folding.Folding_State;
      --  Buffer lifecycle owns file identity, reopen candidates, active
      --  buffer tokens/revisions, file-target prompts, file-conflict prompts,
      --  and dirty-close review state. It is runtime/editor state only; no
      --  workspace persistence data or command payloads are stored here.
      Buffer_Lifecycle : Editor.State_Buffer.Buffer_Lifecycle_State;
      --  Transient per-buffer syntax state. This is intentionally runtime-only:
      --  it is invalidated by text changes/reload/revert, consumed by render
      --  snapshots, and never serialized to workspace/session files.
      Syntax_Cache      : Editor.Syntax_Cache.Syntax_Cache;
      Syntax_Symbols    : Editor.Syntax_Semantics.Semantic_Map;
      --  Parser-owned analysis retained for render-time scope-aware semantic
      --  lookup.  This is stamped with the same buffer/revision as
      --  Syntax_Symbols and is never persisted.
      Syntax_Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Build            : Editor.State_Build.Build_Runtime_State;
      --  transient guided workflow prompt state. This state owns
      --  modal/scoped prompt input, validation, captured chords, and pending
      --  confirmation summaries only while a multi-step workflow is active.
      --  It is deliberately excluded from workspace, settings, keybindings,
      --  recent-projects, and every persistence domain.
      Guided_Prompt : Editor.Guided_Prompts.Prompt_State;
   end record;

   subtype Project_Scoped_State_Summary is
     Editor.State_Project.Project_Scoped_State_Summary;

   type Buffer_Change is record
      Start_Index : Natural;
      Old_Length  : Natural;
      New_Length  : Natural;
   end record;


   --  active-buffer projection helpers.  During the active-buffer
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

   procedure Start_Quick_Fix_Workflow
     (S                : in out State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural := 0);

   procedure Clear_Quick_Fix_Workflow
     (S : in out State_Type);

   function Has_Pending_Quick_Fix_Workflow
     (S : State_Type) return Boolean;

   function Pending_Quick_Fix_Diagnostic_Index
     (S : State_Type) return Natural;

   function Pending_Quick_Fix_Action_Index
     (S : State_Type) return Natural;

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
