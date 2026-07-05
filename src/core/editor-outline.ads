with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
use type Ada.Strings.Unbounded.Unbounded_String;
with Editor.Feature_Panel;

package Editor.Outline is

   --  maintenance contract: the outline subsystem is frozen as an
   --  active-buffer, synchronous, validated snapshot feature. Future async,
   --  project-wide, or LSP-backed symbol work must enter through the
   --  extraction-result validation seam and must not mutate outline state
   --  directly.

   --  Outline interaction contract: selection, passive current-symbol
   --  tracking, reveal, and editor navigation are separate operations. Cursor
   --  movement may update current-symbol state only. Selection commands may
   --  reveal outline rows but must not move the editor cursor. Reveal commands
   --  must not navigate or select implicitly. Open-selected navigates only the
   --  validated selected row and returns focus to the editor only after
   --  successful navigation.

   type Outline_Item_Kind is
     (Outline_Header,
      Outline_Package,
      Outline_Package_Body,
      Outline_Type,
      Outline_Subprogram,
      Outline_Procedure,
      Outline_Function,
      Outline_Task,
      Outline_Protected,
      Outline_Field,
      Outline_Discriminant,
      Outline_Enum_Literal,
      Outline_Exception,
      Outline_Object,
      Outline_Generic_Formal,
      Outline_Section,
      Outline_Unknown);

   type Outline_Target_Kind is
     (No_Target,
      Buffer_Position_Target,
      Project_Path_Target);

   --  Provider-neutral refresh source classification.  Buffer extraction is
   --  owned by Executor through an explicit text snapshot; direct
   --  Outline.Refresh calls for extractor sources remain unavailable so render,
   --  availability, command-palette projection, and input routing cannot
   --  refresh content.  Deterministic synthetic outline rows live in test
   --  fixtures and enter through Replace_Items.
   type Outline_Refresh_Source is
     (Outline_Source_Buffer_Extractor,
      Outline_Source_Project_Extractor);

   type Outline_Refresh_Status is
     (Outline_Refresh_Ok,
      Outline_Refresh_Unavailable,
      Outline_Refresh_Failed,
      Outline_Refresh_Stale);

   type Outline_Source_Class is
     (No_Outline,
      Extracted_Outline,
      Stale_Extracted_Outline,
      Unsupported_Content,
      Extraction_Failed);

   type Outline_Freshness is
     (Outline_Unavailable,
      Outline_Current,
      Outline_Stale);

   type Outline_Snapshot_Identity is record
      Active_Buffer_Token  : Natural := 0;
      Buffer_Revision      : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      Text_Length          : Natural := 0;
      Request_Token        : Natural := 0;
   end record;

   type Outline_Refresh_Failure_Kind is
     (No_Failure,
      No_Active_Buffer,
      Unsupported_Buffer_Kind,
      Extractor_Not_Available,
      Extractor_Failed);

   type Outline_Refresh_Result is record
      Status       : Outline_Refresh_Status := Outline_Refresh_Unavailable;
      Failure_Kind : Outline_Refresh_Failure_Kind := Extractor_Not_Available;
      Item_Count   : Natural := 0;
      Source_Class : Outline_Source_Class := No_Outline;
   end record;

   type Outline_Item is record
      Kind        : Outline_Item_Kind := Outline_Unknown;
      Label       : Ada.Strings.Unbounded.Unbounded_String;
      Detail      : Ada.Strings.Unbounded.Unbounded_String;
      Depth       : Natural := 0;
      Target_Kind  : Outline_Target_Kind := No_Target;
      Buffer_Token : Natural := 0;
      Line         : Natural := 0;
      Column       : Natural := 0;
   end record;

   type Outline_Item_Array is array (Positive range <>) of Outline_Item;

   type Outline_State is private;

   type Outline_Summary is record
      Item_Count   : Natural := 0;
      Has_Items    : Boolean := False;
      Fingerprint  : Natural := 0;
      Source_Class : Outline_Source_Class := No_Outline;
   end record;

   --  Return whether the private outline state satisfies    --  structural invariants. This helper is side-effect-free and does not
   --  normalize, repair, project, parse, emit messages, or inspect editor
   --  buffers/project files.
   --  @param Outline Outline state to inspect.
   --  @return True when the outline item model is internally coherent.
   function Invariant_Holds
     (Outline : Outline_State) return Boolean;

   --  Return a compact deterministic diagnostic summary for tests and audits.
   --  The summary is side-effect-free and does not normalize or repair state.
   --  @param Outline Outline state to inspect.
   --  @return Human-readable outline state summary.
   function Debug_Summary
     (Outline : Outline_State) return String;

   --  Clear transient outline items.
   --  This operation mutates only outline state. It does not alter buffers,
   --  dirty state, project state, workspace persistence, settings, keybindings,
   --  recent projects, feature-panel visibility/focus/selection, or pending
   --  transitions.
   --  @param Outline Outline state to update.
   procedure Clear
     (Outline : in out Outline_State);

   --  Outline lifecycle ownership: accepted rows belong to the active
   --  accepted outline snapshot; filtered projections belong to the current
   --  accepted row set plus current filter text; selection and current-symbol
   --  indices are valid only for that row set; reveal and mouse mappings are
   --  valid only for the current feature-panel projection generation;
   --  remembered filters are session-local and keyed only by live buffer
   --  identity; filter history is session-local and non-persistent; extraction
   --  results may update state only after snapshot validation.

   procedure Reset_Outline_For_Buffer_Close
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);

   procedure Reset_Outline_For_Project_Close
     (Outline : in out Outline_State);

   procedure Reset_Outline_For_Workspace_Close
     (Outline : in out Outline_State);

   procedure Reset_Outline_For_Unsupported_Content
     (Outline : in out Outline_State);

   procedure Reset_Outline_For_Extraction_Failure
     (Outline : in out Outline_State;
      Message : String);

   --  Mark the visible Outline surface as unavailable because there is no
   --  active buffer. This keeps the state display-only: it clears rows,
   --  selection, current-symbol metadata, pending extraction, and never
   --  parses, refreshes, navigates, persists, or fabricates placeholder rows.
   procedure Mark_No_Active_Buffer
     (Outline : in out Outline_State);

   procedure Assert_Outline_State_Consistent
     (Outline : Outline_State);


   --  Begin a provider-owned extraction request.  The stored identity is used
   --  to reject late or out-of-order extraction results before they can replace
   --  visible rows.
   procedure Begin_Extraction
     (Outline  : in out Outline_State;
      Snapshot : Outline_Snapshot_Identity);

   --  Return the next deterministic request token to attach to an extraction
   --  snapshot.  The token is outline-local and has no global meaning.
   function Next_Request_Token
     (Outline : Outline_State) return Natural;

   --  Return whether Snapshot still matches the currently pending outline
   --  extraction request.
   function Snapshot_Is_Current
     (Outline  : Outline_State;
      Snapshot : Outline_Snapshot_Identity) return Boolean;

   --  Mark a late extraction result as stale and preserve current visible rows.
   procedure Mark_Stale_Result
     (Outline : in out Outline_State;
      Message : String := "Outline result discarded: stale buffer snapshot");

   --  Mark extraction as failed and clear visible rows.
   procedure Mark_Extraction_Failed
     (Outline : in out Outline_State;
      Message : String := "Outline extraction failed");

   --  Mark extraction as unsupported or empty and clear visible rows.
   procedure Mark_Unsupported
     (Outline : in out Outline_State;
      Message : String := "Outline unavailable for this buffer");

   --  Reset transient outline data when a project context closes or changes.
   --  @param Outline Outline state to update.
   procedure Reset_For_Project_Close
     (Outline : in out Outline_State);

   --  Reset active-buffer-scoped outline data when the active buffer changes.
   --  @param Outline Outline state to update.
   procedure Reset_For_Buffer_Change
     (Outline : in out Outline_State);

   --  Mark accepted outline rows stale after an edit to the active buffer.
   --  Rows are preserved for display, but activation/navigation must reject
   --  them until an explicit refresh accepts a matching snapshot.
   procedure Mark_For_Buffer_Change
     (Outline : in out Outline_State);

   --  Return whether the accepted outline snapshot still belongs to the
   --  supplied active-buffer identity and revision.
   function Is_Current_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean;

   function Is_Stale_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean;

   function Freshness_For_Active_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Outline_Freshness;

   function Source_Buffer_Token
     (Outline : Outline_State) return Natural;

   function Source_Buffer_Revision
     (Outline : Outline_State) return Natural;

   --  Refresh outline content from a provider-neutral source.  Extractor
   --  sources require explicit Executor-owned snapshots and return
   --  Outline_Refresh_Unavailable here without mutating state.
   --  @param Outline Outline state to update.
   --  @param Source Refresh source to request.
   --  @return Refresh status and resulting item count.
   function Refresh
     (Outline : in out Outline_State;
      Source  : Outline_Refresh_Source) return Outline_Refresh_Result;

   --  Replace outline state with provider-produced items.
   --  This operation mutates only Outline state. It does not inspect buffers,
   --  update Feature_Panel rows, emit messages, render, or touch lifecycle,
   --  dirty, settings, keybinding, workspace, recent-project, or pending state.
   --  @param Outline Outline state to replace.
   --  @param Items Provider-produced item array in display order.
   procedure Replace_Items
     (Outline : in out Outline_State;
      Items   : Outline_Item_Array);

   --  Remember the currently selected outline item index. Invalid or zero
   --  indices clear outline selection. This is outline-local selection state;
   --  feature-panel projection may mirror it but must not infer symbol targets
   --  from display rows alone.
   procedure Select_Item
     (Outline : in out Outline_State;
      Index   : Natural);

   function Selected_Index
     (Outline : Outline_State) return Natural;

   procedure Activate_Filter_Input
     (Outline : in out Outline_State);

   procedure Deactivate_Filter_Input
     (Outline : in out Outline_State);

   function Filter_Input_Is_Active
     (Outline : Outline_State) return Boolean;

   function Filter_Caret
     (Outline : Outline_State) return Natural;

   procedure Apply_Filter
     (Outline : in out Outline_State;
      Text    : String);

   procedure Insert_Filter_Character
     (Outline : in out Outline_State;
      Ch      : Character);

   procedure Insert_Filter_Text
     (Outline : in out Outline_State;
      Text    : String);

   procedure Delete_Filter_Character_Backward
     (Outline : in out Outline_State);

   procedure Delete_Filter_Character_Forward
     (Outline : in out Outline_State);

   procedure Move_Filter_Caret_Left
     (Outline : in out Outline_State);

   procedure Move_Filter_Caret_Right
     (Outline : in out Outline_State);

   procedure Move_Filter_Caret_Start
     (Outline : in out Outline_State);

   procedure Move_Filter_Caret_End
     (Outline : in out Outline_State);

   procedure Clear_Filter_Text
     (Outline : in out Outline_State);

   procedure Clear_Filter
     (Outline : in out Outline_State);

   procedure Reset_Filter_State_For_Lifecycle
     (Outline : in out Outline_State);

   procedure Commit_Filter_To_History
     (Outline : in out Outline_State);

   function Filter_History_Count
     (Outline : Outline_State) return Natural;

   function Filter_History_Entry
     (Outline : Outline_State;
      Index   : Positive) return String
      with Pre => Index <= Filter_History_Count (Outline);

   function Select_Previous_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean;

   function Select_Next_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean;

   procedure Clear_Filter_History
     (Outline : in out Outline_State);

   procedure Remember_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);

   function Restore_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural) return Boolean;

   procedure Forget_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);

   procedure Clear_All_Remembered_Filters
     (Outline : in out Outline_State);

   function Remembered_Filter_Count
     (Outline : Outline_State) return Natural;

   function Filter_Is_Active
     (Outline : Outline_State) return Boolean;

   function Filter_Text
     (Outline : Outline_State) return String;

   function Filtered_Row_Count
     (Outline : Outline_State) return Natural;

   function Rows_Generation
     (Outline : Outline_State) return Natural;

   function Filter_Generation
     (Outline : Outline_State) return Natural;

   function Projection_Generation
     (Outline : Outline_State) return Natural;

   function Visible_Row_For_Outline_Row
     (Outline           : Outline_State;
      Outline_Row_Index : Natural) return Natural;

   function Outline_Row_For_Visible_Row
     (Outline           : Outline_State;
      Visible_Row_Index : Natural) return Natural;

   function Has_Selected_Item
     (Outline : Outline_State) return Boolean;

   --  Current-symbol detection is positional and approximate. It uses the
   --  nearest validated outline item at or before the active cursor position;
   --  it is not semantic containment and does not imply that the cursor is
   --  inside the exact declaration range.
   procedure Clear_Current_Symbol
     (Outline : in out Outline_State);

   procedure Set_Current_Symbol_Index
     (Outline : in out Outline_State;
      Index   : Natural);

   function Current_Symbol_Index
     (Outline : Outline_State) return Natural;

   function Has_Current_Symbol
     (Outline : Outline_State) return Boolean;

   function Current_Symbol_Label
     (Outline : Outline_State) return String;

   function Current_Symbol_Line
     (Outline : Outline_State) return Natural;

   function Find_Current_Symbol_For_Cursor
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural;

   procedure Update_Current_Symbol_For_Cursor
     (Outline      : in out Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1);

   function Outline_Header_Text
     (Outline : Outline_State) return String;

   --  Return the user-facing display-only row label for the current empty,
   --  unavailable, stale, or failure Outline state. This helper is
   --  side-effect-free and does not inspect buffers, parse source text,
   --  refresh Outline, project rows, navigate, or persist state.
   function Outline_Empty_State_Label
     (Outline : Outline_State) return String;

   function Is_Current_Symbol_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
      with Pre => Index <= Item_Count (Outline);

   function Is_Selectable_Target_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
      with Pre => Index <= Item_Count (Outline);

   --  Return True when the current Outline projection contains at least one
   --  selectable target row after applying the transient Outline filter.  This
   --  is a side-effect-free availability helper for filter next/previous match
   --  commands; it does not reconcile selection or mutate filtered rows.
   function Has_Selectable_Filter_Match
     (Outline : Outline_State) return Boolean;

   --  Return the number of current navigable symbol rows. This helper counts
   --  real buffer-position Outline rows only; display/status/group rows are
   --  excluded. It is side-effect-free and does not parse, refresh, project,
   --  select, or mutate.
   function Navigable_Symbol_Count
     (Outline : Outline_State) return Natural;

   --  Return the number of current navigable symbol rows that remain visible
   --  after the transient Outline filter is applied. This is for    --  status/projection summaries and does not mutate filter or selection state.
   function Filtered_Navigable_Symbol_Count
     (Outline : Outline_State) return Natural;

   --  Validate that the current-symbol index still maps to a selectable,
   --  extracted outline row in the current feature-panel projection and active
   --  buffer.  This is the stale-row guard for explicit reveal/select commands.
   function Can_Reveal_Current_Symbol
     (Outline             : Outline_State;
      Panel               : Editor.Feature_Panel.Feature_Panel_State;
      Active_Buffer_Token : Natural) return Boolean;

   function Same_Outline_Target
     (Left, Right : Outline_Item) return Boolean;

   function Same_Outline_Symbol
     (Left, Right : Outline_Item) return Boolean;

   --  Return True only when the accepted Outline rows are current, not stale,
   --  and every navigable row belongs to the supplied active buffer token.
   --  This is the active-buffer identity guard for navigation,
   --  reveal, filtering, and transient filter restore.
   function Outline_Buffer_Identity_Matches
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean;

   --  Return True when the current accepted Outline contains at least one
   --  navigable symbol row for the supplied active buffer token.  This helper
   --  is observational and does not parse, refresh, project, select, or mutate.
   function Has_Navigable_Symbol_For_Buffer
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean;

   function Selection_Preservation_Score
     (Previous, Candidate : Outline_Item) return Natural;

   function Find_Nearest_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural;

   --  Return the next navigable symbol after the supplied caret position.
   --  This is derived only from accepted Outline rows and does not inspect,
   --  parse, refresh, or mutate source buffers. When Wrap is True, the first
   --  navigable symbol in the same buffer is returned after the last symbol.
   function Find_Next_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural;

   --  Return the previous navigable symbol before the supplied caret position.
   --  This is derived only from accepted Outline rows and does not inspect,
   --  parse, refresh, or mutate source buffers. When Wrap is True, the last
   --  navigable symbol in the same buffer is returned before the first symbol.
   function Find_Previous_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural;

   function Select_Next_Selectable
     (Outline : in out Outline_State) return Boolean;

   function Select_Previous_Selectable
     (Outline : in out Outline_State) return Boolean;

   --  Project outline items into generic feature-panel rows.
   --  The projection mutates only feature-panel rows and selection according to
   --  the documented projection policy. It does not mutate outline state, emit
   --  messages, parse source text, or change editor lifecycle/configuration state.
   --  @param Outline Outline state to read.
   --  @param Panel Feature panel state whose rows are replaced.
   procedure Set_Rows_From_Outline
     (Outline : Outline_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State);


   function Item_Count
     (Outline : Outline_State) return Natural;

   function Has_Items
     (Outline : Outline_State) return Boolean;

   function Source_Class
     (Outline : Outline_State) return Outline_Source_Class;

   function Last_Extraction_Source_Class
     (Outline : Outline_State) return Outline_Source_Class;

   function Last_Extraction_Message
     (Outline : Outline_State) return String;

   function Last_Extraction_Buffer_Label
     (Outline : Outline_State) return String;

   function Last_Extraction_Item_Count
     (Outline : Outline_State) return Natural;

   function Item_Label
     (Outline : Outline_State;
      Index   : Positive) return String
      with Pre => Index <= Item_Count (Outline);

   function Item_Detail
     (Outline : Outline_State;
      Index   : Positive) return String
      with Pre => Index <= Item_Count (Outline);

   function Item_Depth
     (Outline : Outline_State;
      Index   : Positive) return Natural
      with Pre => Index <= Item_Count (Outline);

   function Item_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Item_Kind
      with Pre => Index <= Item_Count (Outline);

   --  Return the target kind for an outline item.
   --  Buffer-position targets are produced only by validated extraction or
   --  trusted fixtures. Executor must revalidate the active-buffer snapshot,
   --  feature-panel row mapping, and one-based target position before any
   --  caret movement or file opening.
   --  @param Outline Outline state to inspect.
   --  @param Index One-based outline item index.
   --  @return Target classification for the item.
   function Item_Target_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Target_Kind
      with Pre => Index <= Item_Count (Outline);

   function Item_Buffer_Token
     (Outline : Outline_State;
      Index   : Positive) return Natural
      with Pre => Index <= Item_Count (Outline);

   function Item_Line
     (Outline : Outline_State;
      Index   : Positive) return Natural
      with Pre => Index <= Item_Count (Outline);

   function Item_Column
     (Outline : Outline_State;
      Index   : Positive) return Natural
      with Pre => Index <= Item_Count (Outline);

   --  Return whether a one-based feature-panel row is a current projection of
   --  a live outline item under the active projection mapping. Filtered
   --  projections may map visible row 1 to any source outline row, so callers
   --  must not infer source identity from display indices. This is the stale
   --  selection guard used by command availability and route-equivalence tests.
   --  It is side-effect-free: it does not repair rows, project outline items,
   --  inspect files, parse buffers, or emit messages.
   --  @param Outline Outline state to inspect.
   --  @param Panel Feature panel state to inspect.
   --  @param Row One-based feature-panel row index.
   --  @return True when Row maps to a live outline item projection.
   function Feature_Row_Maps_To_Item
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State;
      Row     : Positive) return Boolean;

   --  Validate a feature-panel row against the live outline projection and
   --  return the corresponding one-based outline item index. Expected
   --  generation zero disables generation checking for command paths that do
   --  not originate from a rendered mouse projection.
   function Map_Panel_Row_To_Outline_Row
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Natural;

   function Validate_Outline_Row_For_Selection
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean;

   function Validate_Outline_Row_For_Activation
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Active_Buffer_Token       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean;

   --  Return a side-effect-free outline summary for tests and audits.
   function Summary
     (Outline : Outline_State) return Outline_Summary;

   --  Return a deterministic fingerprint of outline content for regression tests.
   --  The fingerprint includes item metadata and excludes render state, time,
   --  focus, hover, cursor blink phase, and renderer atlas state.
   --  @param Outline Outline state to inspect.
   --  @return Deterministic outline content fingerprint.
   function Fingerprint
     (Outline : Outline_State) return Natural;

   function Message_Outline_Refreshed return String;
   function Message_Outline_Cleared return String;
   function Message_Outline_Shown return String;
   function Message_Outline_Focused return String;
   function Message_Outline_Item_Has_No_Target return String;
   function Message_Outline_Refresh_Failed return String;
   function Message_Outline_No_Current_Symbol return String;
   function Message_Outline_Current_Symbol_Revealed return String;
   function Message_Outline_No_Active_Buffer return String;
   function Message_Outline_Unsupported_Buffer return String;
   function Message_Outline_No_Symbols return String;
   function Message_Outline_No_Matching_Symbols return String;
   function Message_Outline_No_Selected_Symbol return String;
   function Message_Outline_Stale_Result_Discarded return String;

   --  Validate that Panel is a current projection of Outline.  This audit
   --  helper is side-effect-free and never repairs panel or outline state.
   --  @param Outline Outline state whose rows/filter are the source of truth.
   --  @param Panel Feature panel projection to inspect.
   --  @return True when every visible panel row maps to the current outline projection.
   function Projection_Invariant_Holds
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   procedure Assert_Outline_Projection_Consistent
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State);

   function Reason_No_Active_Buffer return String;
   function Reason_No_Outline_Items return String;
   function Reason_No_Outline_Item_Selected return String;
   function Reason_Outline_Belongs_To_Another_Buffer return String;
   function Reason_Feature_Panel_Hidden return String;
   function Reason_Feature_Panel_Already_Shown return String;
   function Reason_Feature_Panel_Already_Focused return String;

private
   package Outline_Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Outline_Item);

   package Filter_Text_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   type Remembered_Filter is record
      Buffer_Token : Natural := 0;
      Text         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
   end record;

   package Remembered_Filter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Remembered_Filter);

   type Outline_State is record
      Items                    : Outline_Item_Vectors.Vector;
      Source                   : Outline_Source_Class := No_Outline;
      Pending_Snapshot         : Outline_Snapshot_Identity;
      Last_Applied_Snapshot    : Outline_Snapshot_Identity;
      Next_Request             : Natural := 1;
      Last_Extraction_Source   : Outline_Source_Class := No_Outline;
      Last_Extraction_Message  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
      Last_Extraction_Buffer   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
      Last_Extraction_Count    : Natural := 0;
      Filter_Input_Active      : Boolean := False;
      Filter_Active            : Boolean := False;
      Filter_Text_Value        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
      Filter_Caret_Position    : Natural := 0;
      Filtered_Count           : Natural := 0;
      Rows_Generation          : Natural := 1;
      Filter_Generation        : Natural := 1;
      Projection_Generation    : Natural := 1;
      Recent_Filters           : Filter_Text_Vectors.Vector;
      Filter_History_Cursor    : Natural := 0;
      Remembered_Filters       : Remembered_Filter_Vectors.Vector;
      Selected                 : Natural := 0;
      Current_Symbol           : Natural := 0;
      Has_Current              : Boolean := False;
      Current_Label            : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
      Current_Line             : Natural := 0;
   end record;

end Editor.Outline;
