with Editor.State;
with Editor.Cursors;
with Ada.Containers; use Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.State; use Editor.State;
with Interfaces.C;
with Editor.Search;
with Editor.Wrap;
with Editor.Minimap;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Feature_Panel;
with Editor.Bookmarks;
with Editor.Input_Field;
with Editor.Build_UI;
with Editor.Terminal_Tasks;
with Editor.Syntax;
with Editor.Keybinding_Management;
with Editor.Settings_Management;
with Editor.Empty_State_Guidance;
with Editor.Guided_Prompts;
with Ada.Strings.Unbounded;

package Editor.Render_Model is

   use Editor.Cursors;

   Max_Render_Carets     : constant := 128;
   Max_Render_Selections : constant := 128;
   Max_Visible_Visual_Rows : constant := 4096;
   Max_Minimap_Samples      : constant := 4096;
   Max_Render_Diagnostics   : constant := 512;
   Max_Render_Active_Find_Matches : constant := 512;
   Max_Render_Syntax_Spans : constant := 4096;

   type Natural_Array is array (Positive range <>) of Natural;

   type Caret_Pos_Array is
     array (1 .. Max_Render_Carets) of Cursor_Index;

   type Selection_Pos_Array is
     array (1 .. Max_Render_Selections) of Cursor_Index;

   type Rectangular_Selection_Row_Span is record
      Row          : Natural := 0;
      Start_Column : Natural := 0;
      End_Column   : Natural := 0;
   end record;

   type Rectangular_Selection_Row_Span_Array is
     array (1 .. Max_Render_Selections) of Rectangular_Selection_Row_Span;

   type Diagnostic_Range_Array is
     array (1 .. Max_Render_Diagnostics) of Editor.Diagnostics.Diagnostic_Range;

   type Search_Match_Array is
     array (1 .. Max_Render_Active_Find_Matches) of Editor.Search.Search_Match;

   type Render_Syntax_Span is record
      Row         : Natural := 0;
      Start_Index : Natural := 0;
      End_Index   : Natural := 0;
      Kind        : Editor.Syntax.Token_Kind := Editor.Syntax.Plain_Text;
   end record;

   type Render_Syntax_Span_Array is
     array (1 .. Max_Render_Syntax_Spans) of Render_Syntax_Span;

   type Visual_Row_Info_Array is
     array (1 .. Max_Visible_Visual_Rows) of Editor.Wrap.Visual_Row_Info;

   type Render_Snapshot is record
      ---------------------------------------------------------------------
      -- Text
      ---------------------------------------------------------------------
      Length : Natural := 0;

      Text_Base_Index : Natural := 0;

      ---------------------------------------------------------------------
      -- Carets
      ---------------------------------------------------------------------
      Caret_Count : Natural := 0;
      Caret_Pos   : Caret_Pos_Array := (others => 0);
      Caret_Virtual_Column : Natural_Array (1 .. Max_Render_Carets);

      --  Viewport-local line starts.  Entries are absolute buffer indices,
      --  and Line_Start_Row_Base maps Line_Starts index 0 to a document row.
      --  The packet builder may include one sentinel row after the visible
      --  range to compute the final visible row end without consulting state.
      Line_Starts : Line_Start_Vectors.Vector;
      Line_Start_Row_Base : Natural := 0;
      Total_Line_Count : Natural := 1;
      Visible_Line_Count : Natural := 1;

      Visible_First_Row : Natural := 0;
      Visible_Last_Row  : Natural := 0;

      Wrap_Mode : Editor.Wrap.Wrap_Mode := Editor.Wrap.Wrap_None;
      Wrap_Col  : Positive := 1;
      Visible_Visual_Count : Natural := 0;
      Visible_Visual_Rows  : Visual_Row_Info_Array := (others => (Logical_Row => 0, Start_Col => 0, End_Col => 0));

      Primary_Caret_Row : Natural := 0;
      Primary_Caret_Col : Natural := 0;
      Primary_Caret_Logical_Row : Natural := 0;

      Minimap_Sample_Count : Natural := 0;
      Minimap_Samples      : Editor.Minimap.Minimap_Line_Info_Array
        (0 .. Max_Minimap_Samples - 1);

      ---------------------------------------------------------------------
      -- Selections
      --
      -- Current migration rule:
      --   multiple carets imply collapsed selections, but the render model
      --   is already structured to export multiple ranges when enabled.
      ---------------------------------------------------------------------
      Sel_Start_Virtual_Column : Natural_Array (1 .. Max_Render_Selections);
      Sel_End_Virtual_Column   : Natural_Array (1 .. Max_Render_Selections);
      Selection_Count : Natural := 0;
      Selected_Character_Count : Natural := 0;
      Selected_Line_Count      : Natural := 0;
      Sel_Start       : Selection_Pos_Array := (others => 0);
      Sel_End         : Selection_Pos_Array := (others => 0);

      Rectangular_Selection_Count : Natural := 0;
      Rectangular_Selections      : Rectangular_Selection_Row_Span_Array :=
        (others => (Row => 0, Start_Column => 0, End_Column => 0));

      Diagnostic_Count : Natural := 0;
      Diagnostics      : Diagnostic_Range_Array :=
        (others =>
           (Start_Index => 0,
            End_Index   => 0,
            Severity    => Editor.Diagnostics.Hint,
            Message     => Ada.Strings.Unbounded.Null_Unbounded_String,
            Quick_Fix_Label  => Ada.Strings.Unbounded.Null_Unbounded_String,
            Quick_Fix_Detail => Ada.Strings.Unbounded.Null_Unbounded_String,
            Has_Location => False,
            Start_Row    => 0,
            Start_Column => 0));

      Active_Find_Match_Count : Natural := 0;
      Active_Find_Matches     : Search_Match_Array := (others => Editor.Search.No_Match);
      Active_Find_Match : Editor.Search.Search_Match := Editor.Search.No_Match;

      Syntax_Span_Count : Natural := 0;
      Syntax_Spans      : Render_Syntax_Span_Array := (others => (others => <>));

      Folding : Editor.Folding.Folding_State;
      Gutter_Markers : Editor.Gutter_Markers.Gutter_Marker_State;
      Gutter_Marker_Hover : Editor.Gutter_Markers.Gutter_Marker_Hover_State;
      Semantic_Popup : Editor.State.Semantic_Popup_State;
      Messages : Editor.Messages.Message_State;
      Post_Restore_Feedback_Current : Boolean := False;

      File_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Is_Dirty  : Boolean := False;
      Total_Find_Match_Count : Natural := 0;
      Total_Diagnostic_Count   : Natural := 0;
      Has_Project             : Boolean := False;
      Project_Label           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;

      --  active-buffer metadata projection. These labels are
      --  copied from Editor.Buffers.Metadata_For for display only. Render
      --  must not derive, repair, switch, close, save, reload, or persist
      --  buffer state from them.
      Active_Buffer_Has_Metadata : Boolean := False;
      Active_Buffer_Ownership_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Buffer_Lifecycle_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Buffer_Workspace_Persistability_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Buffer_Stale_Backing_State : Boolean := False;
      Active_Buffer_Close_Eligibility_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;

      Panel_Focus_Target      : Editor.Panel_Focus.Focus_Target :=
        Editor.Panel_Focus.Editor_Text_Focus;
      Bottom_Focus_Content    : Editor.Panel_Focus.Bottom_Focus_Content :=
        Editor.Panel_Focus.No_Bottom_Focus;
      Active_Overlay          : Editor.Overlay_Focus.Overlay_Target :=
        Editor.Overlay_Focus.No_Overlay;
      Feature_Panel_Visible   : Boolean := False;
      Feature_Panel_Focused   : Boolean := False;
      Search_Query_Input_Active : Boolean := False;
      Outline_Filter_Input_Active : Boolean := False;
      Active_Feature          : Editor.Feature_Panel.Feature_Id :=
        Editor.Feature_Panel.Unknown_Feature;
      Bookmarks_Visible       : Boolean := False;
      Bookmark_Count          : Natural := 0;
      Bookmark_Selected_Index : Natural := 0;
      Bookmark_Selected_Key_File_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Bookmark_Selected_Key_Line_Number : Natural := 0;
      Bookmark_Selected_Key_Column : Natural := 0;
      Bookmark_Selected_Key_Has_Column : Boolean := False;
      Bookmark_Has_Selected_Key : Boolean := False;
      Bookmark_Rows           : Editor.Bookmarks.Bookmark_Row_Vectors.Vector;
      Bookmark_Empty_Message  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("No bookmarks");

      Goto_Line_Visible       : Boolean := False;
      Goto_Line_Query         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Goto_Line_Error_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Goto_Line_Field         : Editor.Input_Field.Field_Snapshot;

      Find_Visible           : Boolean := False;
      Find_Query             : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Find_Match_Count       : Natural := 0;
      Find_Case_Sensitive    : Boolean := False;
      Find_Whole_Word        : Boolean := False;
      Find_Matches_Stale     : Boolean := False;
      Find_Wrapped           : Boolean := False;
      Find_Matches_For_Active_Buffer : Boolean := False;
      Find_Selected_Match_Index : Natural := 0;
      Find_Selected_Match_Ordinal : Natural := 0;
      Find_Status_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Find_Error_Message     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Find_Field             : Editor.Input_Field.Field_Snapshot;
      Replace_Visible              : Boolean := False;
      Replace_Text                 : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Replace_Error_Message        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Target_Prompt_Visible : Boolean := False;
      File_Target_Prompt_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Target_Prompt_Field   : Editor.Input_Field.Field_Snapshot;

      --  dirty-buffer close review projection. These fields are
      --  derived from transient Executor-owned prompt state only; render must
      --  never use them to close, save, discard, or persist buffers.
      Dirty_Close_Prompt_Visible : Boolean := False;
      Dirty_Close_Scope          : Editor.State.Dirty_Close_Scope :=
        Editor.State.No_Dirty_Close_Scope;
      Dirty_Close_All_Buffers    : Boolean := False;
      Dirty_Close_Target_Buffer  : Natural := 0;
      Dirty_Close_Buffer_Count   : Natural := 0;
      Dirty_Close_Buffer_Fingerprint : Natural := 0;
      Dirty_Close_Dirty_Fingerprint : Natural := 0;
      --  render exposes the transient
      --  reviewed identity sets as inert snapshot text so UI/tests can
      --  show/debug the exact reviewed candidate set without owning close
      --  operations or persisting payloads.
      Dirty_Close_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Close_Dirty_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Close_Dirty_Count    : Natural := 0;
      Dirty_Close_File_Backed_Count : Natural := 0;
      Dirty_Close_Untitled_Count : Natural := 0;
      Dirty_Close_Conflicted_Count : Natural := 0;
      Dirty_Close_Unwritable_Count : Natural := 0;
      Dirty_Close_Missing_Count : Natural := 0;
      Dirty_Close_Save_Failure_Count : Natural := 0;
      --  render snapshots expose the
      --  prompt-owned action surface explicitly.  These booleans are
      --  observational only and mirror Executor availability policy; render
      --  must not interpret them as permission to mutate buffers itself.
      Dirty_Close_Save_Action_Available : Boolean := False;
      Dirty_Close_Discard_Action_Available : Boolean := False;
      Dirty_Close_Cancel_Action_Available : Boolean := False;
      Dirty_Close_Message        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;

      Build_UI : Editor.Build_UI.Build_UI_Render_Snapshot;
      Terminal_Tasks : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;

      --  keybinding-management projection.  This is a derived,
      --  render-facing snapshot only: it carries visibility, filter, capture,
      --  conflict/reset, selection, and load-diagnostic summary state.  It is
      --  never persisted and never used by rendering to assign/remove/reset
      --  keybindings.
      Keybindings_UI : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;

      --  settings/configuration management projection.  This is a
      --  bounded render-facing snapshot of supported global preferences and
      --  audit summaries only. It carries no keybinding maps, workspace
      --  session data, recent projects, command payloads, or persisted
      --  settings-editor query/filter/selection state.
      Settings_UI : Editor.Settings_Management.Settings_Surface_Snapshot;

      --  Bounded configuration-audit rows and settings command catalog.
      --  These snapshots are observational; they are derived from the current
      --  runtime settings and command descriptors and do not repair or persist
      --  configuration state.
      Configuration_Audit_UI :
        Editor.Settings_Management.Configuration_Audit_Surface_Snapshot;
      Settings_Command_Catalog_UI :
        Editor.Settings_Management.Settings_Command_Catalog_Snapshot;

      --  guided empty-state action projection.  This is a
      --  render-facing snapshot projection only: messages, availability labels,
      --  activation modes, selected markers, and command suggestions are
      --  derived from current runtime state and descriptors, carry no command
      --  payloads, execute nothing, refresh nothing, open no overlays, and are
      --  excluded from every persistence domain.
      Main_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      File_Tree_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Quick_Open_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Project_Search_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Outline_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Diagnostics_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Build_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Recent_Projects_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;
      Configuration_Recovery_Empty_State : Editor.Empty_State_Guidance.Empty_State_Snapshot;

      --  guided workflow prompt projection. This render-facing
      --  snapshot is observational only: it displays current prompt purpose,
      --  input/capture state, validation, and confirmation labels, and never
      --  starts, confirms, cancels, validates by side effect, or persists any
      --  prompt payload.
      Guided_Prompt : Editor.Guided_Prompts.Prompt_Snapshot;
   end record;

   subtype Editor_Snapshot is Render_Snapshot;

   function Build_Snapshot
     (S : Editor.State.State_Type) return Editor_Snapshot;

   procedure Build_Render_Snapshot
     (S : in out Editor.State.State_Type;
      O : out Render_Snapshot);

end Editor.Render_Model;
