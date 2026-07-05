with Ada.Strings.Unbounded;

package Editor.Status_Bar is

   --  User-visible status bar configuration.
   --
   --  The status bar is deliberately non-interactive.  This
   --  configuration only controls whether layout reserves the bottom row and
   --  whether render packet construction emits status bar visuals.
   type Status_Bar_Config is record
      Enabled : Boolean := True;
   end record;

   --  Logical fields that may be displayed by the status bar formatter.
   --
   --  This enumeration documents the initial field set.  Formatting remains
   --  centralized in this package; the data itself is owned by editor state,
   --  file, search, diagnostics, line-number, and view subsystems.
   type Status_Bar_Field is
     (File_Name_Field,
      Dirty_State_Field,
      Cursor_Position_Field,
      Selection_Count_Field,
      Caret_Count_Field,
      Line_Number_Mode_Field,
      Active_Find_Match_Count_Field,
      Diagnostic_Count_Field,
      Project_State_Field,
      Focus_State_Field,
      Command_Feedback_Field,
      File_State_Field,
      Buffer_Kind_Field,
      Pending_Confirmation_Field,
      Outline_Status_Field,
      Diagnostics_Status_Field,
      Build_Status_Field,
      Search_Status_Field,
      Quick_Open_Status_Field,
      File_Tree_Status_Field,
      Workspace_Status_Field,
      Recent_Projects_Status_Field,
      Startup_Status_Field,
      Undo_Redo_Status_Field);

   type Status_Message_Kind is
     (Status_Message_Other,
      Status_Message_Quick_Open_No_Project,
      Status_Message_Quick_Open_No_Matches,
      Status_Message_Outline_Not_Refreshed,
      Status_Message_Find_No_Query,
      Status_Message_Find_No_Matches,
      Status_Message_Build_Failed,
      Status_Message_Build_Ready,
      Status_Message_Diagnostics_Target_Stale,
      Status_Message_Search_Target_Stale,
      Status_Message_File_Tree_No_Project,
      Status_Message_Workspace_Restored,
      Status_Message_Workspace_Partial_Restore,
      Status_Message_Workspace_No_Restore,
      Status_Message_Workspace_Unsaved_Confirmation,
      Status_Message_Recent_Projects_None);

   --  Immutable status data projected from the current editor state.
   --
   --  Cursor_Row and Cursor_Column are stored using the editor's internal
   --  zero-based coordinates.  Format_Right presents them as one-based values.
   type Status_Bar_Snapshot is record
      File_Name          : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Label         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Buffer_Kind_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_State_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Active_Buffer  : Boolean := True;
      Is_Dirty           : Boolean := False;
      Dirty_State_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Cursor_Row         : Natural := 0;
      Cursor_Column      : Natural := 0;
      Selection_Count    : Natural := 0;
      Selected_Character_Count : Natural := 0;
      Selected_Line_Count      : Natural := 0;
      Rectangular_Selection_Active : Boolean := False;
      Undo_Redo_Label    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Caret_Count        : Natural := 1;
      Line_Number_Mode   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Find_Active_Match : Natural := 0;
      Active_Find_Match_Count  : Natural := 0;
      Find_Input_Open     : Boolean := False;
      Find_Query_Present  : Boolean := False;
      Find_Wrapped        : Boolean := False;
      Diagnostic_Count    : Natural := 0;
      Has_Project         : Boolean := False;
      Project_Label       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_State_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Focus_Label         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Panel_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Input_Mode_Label    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Overlay_Query_Active : Boolean := False;
      Active_Feature_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Focus_Hint         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Lifecycle_Hint     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Pending_Confirmation_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Outline_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Outline_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Diagnostics_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Diagnostics_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Build_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Build_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Search_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Search_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Quick_Open_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Open_Status_Kind : Status_Message_Kind := Status_Message_Other;
      File_Tree_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Tree_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Workspace_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Workspace_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Recent_Projects_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Recent_Projects_Status_Kind : Status_Message_Kind := Status_Message_Other;
      Startup_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Command_Feedback : Boolean := False;
      Command_Feedback    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command_Feedback_Severity : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Workspace_Status_Surface is record
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Restore_Details : Boolean := False;
      Restore_Details_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Save_State_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("workspace.save");
      Restore_State_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("workspace.restore");
      Clear_State_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("workspace.clear");
   end record;

   type Quick_Open_Context_Surface is record
      Active : Boolean := False;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Open_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("quick_open.open");
      Clear_Scope_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("quick_open.scope.clear");
      Clear_Filter_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("quick_open.kind.clear");
   end record;

   type Outline_Status_Surface is record
      Active : Boolean := False;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Refresh_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("outline.refresh");
      Open_Selected_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("outline.open-selected");
      Reveal_Current_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("outline.reveal-current-symbol");
   end record;

   type Search_Replace_Status_Surface is record
      Active : Boolean := False;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Run_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("project.search.run");
      Open_Selected_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("project.search.open-selected");
      Clear_Query_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("project.search.query.clear");
   end record;

   type File_Tree_Status_Surface is record
      Active : Boolean := False;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Refresh_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("file-tree.refresh");
      Open_Selected_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("file-tree.open-selected");
      Reveal_Active_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("file-tree.reveal-active-file");
   end record;

   type Recent_Projects_Status_Surface is record
      Active : Boolean := False;
      Summary_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Show_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("recent-projects.show");
      Open_Selected_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("recent-projects.open-selected");
      Remove_Missing_Command : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("recent-projects.remove-missing");
   end record;

   function Workspace_Surface_Action_Label
     (Surface : Workspace_Status_Surface) return String;

   function Quick_Open_Context_Action_Label
     (Surface : Quick_Open_Context_Surface) return String;

   function Outline_Surface_Action_Label
     (Surface : Outline_Status_Surface) return String;

   function Search_Replace_Surface_Action_Label
     (Surface : Search_Replace_Status_Surface) return String;

   function File_Tree_Surface_Action_Label
     (Surface : File_Tree_Status_Surface) return String;

   function Recent_Projects_Surface_Action_Label
     (Surface : Recent_Projects_Status_Surface) return String;

   function Workspace_Surface_Action_Count
     (Surface : Workspace_Status_Surface) return Natural;

   function Quick_Open_Context_Action_Count
     (Surface : Quick_Open_Context_Surface) return Natural;

   function Outline_Surface_Action_Count
     (Surface : Outline_Status_Surface) return Natural;

   function Search_Replace_Surface_Action_Count
     (Surface : Search_Replace_Status_Surface) return Natural;

   function File_Tree_Surface_Action_Count
     (Surface : File_Tree_Status_Surface) return Natural;

   function Recent_Projects_Surface_Action_Count
     (Surface : Recent_Projects_Status_Surface) return Natural;

   --  Return whether the status bar is enabled.
   --
   --  @param Config Status bar configuration to query.
   --  @return True when the status bar should reserve layout space and render.
   function Enabled
     (Config : Status_Bar_Config) return Boolean;

   --  Return the number of grid rows consumed by the status bar.
   --
   --  @param Config Status bar configuration to query.
   --  @return One row when enabled, otherwise zero rows.
   function Height_In_Rows
     (Config : Status_Bar_Config) return Natural;

   --  Format the left status bar text.
   --
   --  @param Snapshot Current status data projected from editor state.
   --  @return File-name text plus the dirty marker when applicable.
   function Format_Left
     (Snapshot : Status_Bar_Snapshot) return String;

   --  Format the right status bar text.
   --
   --  @param Snapshot Current status data projected from editor state.
   --  @return Cursor, caret, selection, line-number, search, and diagnostic text.
   function Format_Right
     (Snapshot : Status_Bar_Snapshot) return String;


   --  Individual scalar status-segment builders.  These helpers expose the
   --  same observational formatting policy used by Format_Right so tests can
   --  verify coverage without depending on row/output payloads.
   function Status_Project_File_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Dirty_File_State_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Project_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Focus_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Caret_Selection_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Command_Outcome_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   --  Return the public user-facing outcome class used in status text.
   --  This deliberately hides internal message-severity spellings such as
   --  ``error`` or ``warn`` behind the classes.
   function Status_Command_Outcome_Class
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Build_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Diagnostics_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Search_Replace_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Quick_Open_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Message_Kind_For
     (Label : Ada.Strings.Unbounded.Unbounded_String) return Status_Message_Kind;

   function Status_Build_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Diagnostics_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Search_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Quick_Open_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_File_Tree_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Workspace_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Outline_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Recent_Projects_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Outline_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_File_Tree_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Workspace_Recent_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Workspace_Surface
     (Snapshot : Status_Bar_Snapshot) return Workspace_Status_Surface;

   function Quick_Open_Context_Surface_For
     (Snapshot : Status_Bar_Snapshot) return Quick_Open_Context_Surface;

   function Outline_Surface
     (Snapshot : Status_Bar_Snapshot) return Outline_Status_Surface;

   function Search_Replace_Surface
     (Snapshot : Status_Bar_Snapshot) return Search_Replace_Status_Surface;

   function File_Tree_Surface
     (Snapshot : Status_Bar_Snapshot) return File_Tree_Status_Surface;

   function Recent_Projects_Surface
     (Snapshot : Status_Bar_Snapshot) return Recent_Projects_Status_Surface;

   function Status_Startup_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   --  Truncate a status segment deterministically.  This helper is pure
   --  formatting policy: it never inspects editor state and never mutates
   --  subsystem data.
   function Status_Truncate_Label
     (Text        : String;
      Max_Columns : Natural := 64) return String;

   --  Build a bounded single-line projection of the complete status surface.
   --  Render may still place left/right segments separately, but this helper
   --  gives tests and narrow viewports one deterministic compact policy over
   --  the same immutable snapshot.
   function Status_Layout_Compact
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return String;

   --  Return True when render should use the priority-ordered compact status
   --  projection instead of the two-column left/right split.  This is a pure
   --  layout decision over scalar snapshot data.
   function Status_Layout_Should_Use_Compact
     (Snapshot          : Status_Bar_Snapshot;
      Available_Columns : Natural) return Boolean;

   --  milestone assertion for the broadened main-context status
   --  line.  The predicate is intentionally phrased over an immutable
   --  snapshot so tests can prove status remains observational and bounded.
   function Assert_Status_Line_Context_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Summarizes_Main_Context
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_File_State_Markers
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Copy_Rows_Or_Output
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Duplicate_Priority_Segments
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Command_Outcome_Uses_Public_Classes
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Layout_Is_Bounded
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return Boolean;

   function Assert_Status_Layout_Preserves_Priority
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Segment_Builders_Are_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Is_Single_Line
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   --  Status configuration is display-only: it may reserve/hide the status
   --  row, but it never stores current project/file/focus/build/search values.
   function Assert_Status_Config_Is_Display_Only
     (Config : Status_Bar_Config) return Boolean;

   --  Status is a render snapshot, not a command payload carrier.
   function Assert_Status_Carries_No_Command_Payloads
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   --  status/feedback coherence helpers.  These are
   --  side-effect-free predicates over the immutable snapshot; they do not
   --  inspect editor state, mutate status data, or copy feature rows.
   function Assert_Status_Snapshot_Is_Observational
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Active_Buffer_And_Dirty_State
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Caret_And_Selection
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Command_Outcome
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Copy_Feature_Rows
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Feature_Summaries
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_State_Not_Persisted
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Editing_Status_And_Feedback_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

end Editor.Status_Bar;
