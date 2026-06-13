with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Editor.Feature_Panel is

   --  Stable identifiers for feature-panel-backed features.  Unknown_Feature is
   --  an explicit rejection sentinel and is never a valid active feature.
   type Feature_Id is
     (Unknown_Feature,
      Outline_Feature,
      Messages_Feature,
      Search_Results_Feature,
      Diagnostics_Feature);

   type Feature_Descriptor is record
      Id            : Feature_Id := Unknown_Feature;
      Stable_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String;
      Supports_Rows : Boolean := True;
      Can_Clear     : Boolean := False;
   end record;

   type Feature_Row_Actions is record
      Can_Select : Boolean := False;
      Can_Open   : Boolean := False;
      Can_Copy   : Boolean := False;
      Can_Clear  : Boolean := False;
      Can_Reveal : Boolean := False;
   end record;

   type Feature_Projection_Token is record
      Feature    : Feature_Id := Unknown_Feature;
      Generation : Natural := 0;
   end record;

   --  Phase 203 generic Feature Panel contract:
   --
   --  Feature-panel infrastructure owns only generic transient UI mechanics:
   --  visibility, focus, active feature identity, descriptors, projection
   --  tokens, visible row mapping, reveal requests, mouse hit-testing,
   --  selection movement, render snapshots, and generic dispatch shape.
   --
   --  Each feature owns its source rows, source-specific state, filters or
   --  query state, row action affordances, target validation, command behavior,
   --  refresh lifecycle, and feature lifecycle cleanup. Feature-specific
   --  packages must project rows into this shell and must validate any opaque
   --  target payload before acting on it.
   --
   --  Generic feature-panel code must not parse files, refresh Outline, run
   --  Search, ingest Diagnostics, post Messages, open files directly, move the
   --  caret directly, read project metadata, inspect project/build files, call
   --  process runners, inspect PATH, or persist transient panel state. It must
   --  not know about Ada outline declaration kinds, Search query semantics,
   --  Diagnostics source/filter semantics, Messages categories, process output,
   --  public-build input/consent/working-context models, or build-tool state.
   --
   --  The finalized built-in feature scopes remain:
   --    Outline: active-buffer outline extraction/navigation/filtering.
   --    Messages: session-local editor-originated messages.
   --    Search Results: active-buffer synchronous literal search.
   --    Diagnostics: session-local diagnostic-like rows posted through a
   --    producer API.

   type Feature_Panel_Row_Kind is
     (Feature_Row_Header,
      Feature_Row_Item,
      Feature_Row_Empty_State);

   type Feature_Action_Id is new Natural;
   No_Feature_Action : constant Feature_Action_Id := 0;

   type Feature_Row_Severity is
     (Feature_Row_No_Severity,
      Feature_Row_Info_Severity,
      Feature_Row_Warning_Severity,
      Feature_Row_Error_Severity);

   type Feature_Panel_Row is record
      Kind              : Feature_Panel_Row_Kind := Feature_Row_Item;
      Label             : Ada.Strings.Unbounded.Unbounded_String;
      Detail            : Ada.Strings.Unbounded.Unbounded_String;
      Is_Current_Symbol : Boolean := False;
      Selectable        : Boolean := True;
      Activatable       : Boolean := False;
      Has_Target        : Boolean := False;
      --  Generic emphasis marker retained for renderer/test support.
      --  It is display metadata only; generic code must
      --  not infer Diagnostics ownership or diagnostic source semantics from it.
      Is_Diagnostic     : Boolean := False;
      Can_Open          : Boolean := False;
      Can_Copy          : Boolean := False;
      Can_Clear         : Boolean := False;
      Can_Reveal        : Boolean := False;
      Is_Selected       : Boolean := False;
      Action_Id         : Feature_Action_Id := No_Feature_Action;
      Source_Index      : Natural := 0;
      Severity          : Feature_Row_Severity := Feature_Row_No_Severity;
   end record;

   type Feature_Panel_Render_Row is record
      Kind              : Feature_Panel_Row_Kind := Feature_Row_Item;
      Label             : Ada.Strings.Unbounded.Unbounded_String;
      Detail            : Ada.Strings.Unbounded.Unbounded_String;
      Selected          : Boolean := False;
      Is_Current_Symbol : Boolean := False;
      Selectable        : Boolean := True;
      Activatable       : Boolean := False;
      Has_Target        : Boolean := False;
      Is_Diagnostic     : Boolean := False;
      Can_Open          : Boolean := False;
      Can_Copy          : Boolean := False;
      Can_Clear         : Boolean := False;
      Can_Reveal        : Boolean := False;
      Action_Id         : Feature_Action_Id := No_Feature_Action;
      Source_Index      : Natural := 0;
      Severity          : Feature_Row_Severity := Feature_Row_No_Severity;
   end record;

   type Feature_Panel_State is private;
   type Feature_Panel_Render_Snapshot is private;

   type Feature_Panel_Summary is record
      Visible           : Boolean := False;
      Focused           : Boolean := False;
      Row_Count         : Natural := 0;
      Has_Selection     : Boolean := False;
      Selected_Row      : Natural := 0;
      First_Visible_Row : Natural := 1;
      Visible_Row_Count : Natural := 10;
   end record;

   type Feature_Panel_Fingerprint is record
      Visible          : Boolean := False;
      Focused          : Boolean := False;
      Row_Count        : Natural := 0;
      Has_Selection    : Boolean := False;
      Selected_Row     : Natural := 0;
      Row_Labels_Hash  : Natural := 0;
      Row_Details_Hash : Natural := 0;
   end record;

   function Is_Known_Feature (Feature : Feature_Id) return Boolean;

   function Feature_Descriptor_Count return Natural;

   function Descriptor_Id (Index : Positive) return Feature_Id;

   function Feature_Stable_Name (Feature : Feature_Id) return String;

   function Feature_Display_Label (Feature : Feature_Id) return String;

   function Feature_Supports_Rows (Feature : Feature_Id) return Boolean;

   function Feature_Can_Clear (Feature : Feature_Id) return Boolean;

   function Active_Feature (Panel : Feature_Panel_State) return Feature_Id;


   --  Capture the currently projected feature view's transient selection and
   --  scroll state. This stores only feature-panel UI state, not rows, row
   --  hints, source-buffer metadata, diagnostics, messages, search results,
   --  outline content, or any persistent domain.
   procedure Save_Active_Feature_View_State
     (Panel : in out Feature_Panel_State);

   --  Restore the active feature's previously captured transient selection and
   --  scroll state after that feature has been projected again. Invalid or
   --  empty row sets are clamped safely without selecting rows from another
   --  feature.
   procedure Restore_Active_Feature_View_State
     (Panel : in out Feature_Panel_State);

   --  Forget saved transient selection/scroll state for a feature whose source
   --  rows were explicitly cleared, replaced, trimmed, or regenerated. This
   --  does not mutate visible rows and does not affect other features.
   procedure Forget_Feature_View_State
     (Panel   : in out Feature_Panel_State;
      Feature : Feature_Id);

   procedure Forget_Active_Feature_View_State
     (Panel : in out Feature_Panel_State);

   --  Clear the active feature's visible selection before rebuilding a
   --  projection from a different feature. This prevents feature-specific
   --  projectors from interpreting another feature's row Source_Index as their
   --  own row identity.
   procedure Clear_Visible_Selection_For_Feature_Switch
     (Panel : in out Feature_Panel_State);
   function Set_Active_Feature
     (Panel   : in out Feature_Panel_State;
      Feature : Feature_Id) return Boolean;

   function Build_Feature_Projection_Token
     (Panel : Feature_Panel_State) return Feature_Projection_Token;

   function Validate_Feature_Projection_Token
     (Panel : Feature_Panel_State;
      Token : Feature_Projection_Token) return Boolean;

   --  Return whether the internal feature-panel invariants hold.
   --  The helper is side-effect-free and does not repair state.
   --  @param Panel Feature panel state to inspect.
   --  @return True when visibility, focus, row, and selection invariants hold.
   function Invariant_Holds
     (Panel : Feature_Panel_State) return Boolean;

   --  Return a side-effect-free structured state summary for tests and audits.
   --  @param Panel Feature panel state to inspect.
   --  @return Stable feature-panel state summary.
   function Summary
     (Panel : Feature_Panel_State) return Feature_Panel_Summary;

   --  Return a deterministic test/debug fingerprint including row-content hashes.
   --  The fingerprint excludes render/backend state, theme colours, glyph atlas
   --  state, messages, settings, keybindings, dirty state, and project state.
   --  @param Panel Feature panel state to inspect.
   --  @return Stable fingerprint for side-effect tests.
   function Fingerprint
     (Panel : Feature_Panel_State) return Feature_Panel_Fingerprint;

   --  Return whether a one-based row index is the current selected row.
   --  Invalid indices return False and never repair selection.
   --  @param Panel Feature panel state to inspect.
   --  @param Index One-based row index.
   --  @return True when Index is the selected live row.
   function Is_Selected_Row
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   --  Return a compact diagnostic summary of feature-panel runtime state.
   --  The summary is side-effect-free and does not normalize state.
   --  @param Panel Feature panel state to inspect.
   --  @return Human-readable debug summary.
   function Debug_Summary
     (Panel : Feature_Panel_State) return String;

   --  Clear all transient feature-panel state.
   --  @param Panel Feature panel state to update.
   procedure Clear
     (Panel : in out Feature_Panel_State);

   --  Clear project-scoped feature panel content.
   --  This operation removes transient rows and selection only. It does not
   --  save, discard, or reload project files, and it does not mutate global
   --  settings, keybindings, workspace sessions, recent projects, dirty state,
   --  buffers, or pending transitions.
   --  @param Panel Feature panel state to update.
   procedure Reset_For_Project_Close
     (Panel : in out Feature_Panel_State);

   --  Set whether the feature panel should be rendered.
   --  Hiding the panel also clears feature-panel focus.
   --  @param Panel Feature panel state to update.
   --  @param Visible True when the panel should be visible.
   procedure Set_Visible
     (Panel   : in out Feature_Panel_State;
      Visible : Boolean);

   --  Return whether the feature panel is currently visible.
   --  This query is side-effect-free and is safe for availability checks and
   --  render snapshot construction.
   --  @param Panel Feature panel state to inspect.
   --  @return True when the panel should be rendered.
   function Is_Visible
     (Panel : Feature_Panel_State) return Boolean;

   --  Set whether the feature panel owns panel focus.
   --  Focus is accepted only while the panel is visible.
   --  @param Panel Feature panel state to update.
   --  @param Focused True when feature-panel local input may be handled.
   procedure Set_Focused
     (Panel   : in out Feature_Panel_State;
      Focused : Boolean);

   --  Return whether the feature panel owns panel focus.
   --  @param Panel Feature panel state to inspect.
   --  @return True when feature-panel local input may be handled.
   function Is_Focused
     (Panel : Feature_Panel_State) return Boolean;

   --  Remove transient rows and clear selection.
   --  This operation does not alter files, buffers, dirty state, project state,
   --  workspace persistence, settings, keybindings, recent projects, or pending
   --  transitions.
   --  @param Panel Feature panel state to update.
   procedure Clear_Rows
     (Panel : in out Feature_Panel_State);

   procedure Set_Header_Text
     (Panel : in out Feature_Panel_State;
      Text  : String);

   function Header_Text
     (Panel : Feature_Panel_State) return String;

   --  Append a generic display row. This helper intentionally knows nothing
   --  about outline, parsers, language servers, or feature semantics.
   --  @param Panel Feature panel state to update.
   --  @param Kind Generic feature-panel row kind.
   --  @param Label Row label.
   --  @param Detail Row detail text.
   procedure Append_Row
     (Panel             : in out Feature_Panel_State;
      Kind              : Feature_Panel_Row_Kind;
      Label             : String;
      Detail            : String := "";
      Is_Current_Symbol : Boolean := False;
      Selectable        : Boolean := True;
      Activatable       : Boolean := False;
      Has_Target        : Boolean := False;
      Is_Diagnostic     : Boolean := False;
      Can_Open          : Boolean := False;
      Can_Copy          : Boolean := False;
      Can_Clear         : Boolean := False;
      Can_Reveal        : Boolean := False;
      Action_Id         : Feature_Action_Id := No_Feature_Action;
      Source_Index      : Natural := 0;
      Severity          : Feature_Row_Severity := Feature_Row_No_Severity);

   --  Return the current row-projection generation. Callers that derive a
   --  mouse hit from rendered rows should retain this value and pass it back
   --  to stale-projection guards before selecting or activating rows.
   function Projection_Generation
     (Panel : Feature_Panel_State) return Natural;

   --  Return whether Expected denotes the current feature-panel projection.
   --  Expected = 0 is treated as an intentionally unchecked command path;
   --  nonzero values must match Projection_Generation exactly. This helper is
   --  feature-panel generic and intentionally knows nothing about outline rows,
   --  parsers, language servers, extraction snapshots, or command semantics.
   --  @param Panel Feature panel state to inspect.
   --  @param Expected Expected projection generation, or zero to skip checking.
   --  @return True when the generation is acceptable for a row action.
   function Projection_Generation_Matches
     (Panel    : Feature_Panel_State;
      Expected : Natural) return Boolean;

   function Projection_Token_Matches
     (Panel : Feature_Panel_State;
      Token : Feature_Projection_Token) return Boolean;

   --  Return whether Row is a live one-based feature-panel row index. Zero and
   --  out-of-range values are rejected without repairing panel state. This is
   --  the generic row-index guard used by feature-specific projection mappers.
   --  @param Panel Feature panel state to inspect.
   --  @param Row One-based row index to validate.
   --  @return True when Row identifies an existing rendered/action row.
   function Projection_Row_Index_Is_Valid
     (Panel : Feature_Panel_State;
      Row   : Natural) return Boolean;

   --  Return whether a pending reveal row still names a live panel row.
   --  Feature-specific callers must perform their own semantic/source-target
   --  validation before requesting a reveal.
   --  @param Panel Feature panel state to inspect.
   --  @param Row One-based row index to validate.
   --  @return True when Row may be consumed by Reveal_Row.
   function Reveal_Row_Index_Is_Valid
     (Panel : Feature_Panel_State;
      Row   : Natural) return Boolean;

   function Row_Is_Selectable
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Has_Selectable_Row
     (Panel : Feature_Panel_State) return Boolean;

   function Row_Is_Activatable
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Has_Target
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Is_Diagnostic
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Can_Open
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Can_Copy
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Can_Clear
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   --  Return whether the current projection contains at least one row that may
   --  be cleared by an active-feature clear command. Empty-state and header
   --  rows are not clearable even though they are visible projection rows.
   function Has_Clearable_Row
     (Panel : Feature_Panel_State) return Boolean;

   function Row_Can_Reveal
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   function Row_Actions
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Row_Actions;

   function Row_Source_Index
     (Panel : Feature_Panel_State;
      Index : Positive) return Natural;

   function Row_Severity
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Row_Severity;

   --  Return the number of transient feature-panel rows.
   --  @param Panel Feature panel state to inspect.
   --  @return Row count.
   function Row_Count
     (Panel : Feature_Panel_State) return Natural;

   --  Return the one-based selected row index, or zero when nothing is selected.
   --  @param Panel Feature panel state to inspect.
   --  @return Selected row index.
   function Selected_Row
     (Panel : Feature_Panel_State) return Natural;

   --  Select the first row when rows exist. Empty panels retain no selection.
   --  The operation mutates only feature-panel selection and emits no messages.
   --  @param Panel Feature panel state to update.
   procedure Select_First
     (Panel : in out Feature_Panel_State);

   --  Select a specific one-based row. Invalid or zero indices clear selection.
   --  The operation mutates only feature-panel selection and emits no messages.
   --  @param Panel Feature panel state to update.
   --  @param Index One-based row index, or zero to clear selection.
   procedure Select_Row
     (Panel : in out Feature_Panel_State;
      Index : Natural);

   --  Move selection to the next row, clamping at the final row.
   --  The operation mutates only feature-panel selection and emits no messages.
   --  @param Panel Feature panel state to update.
   procedure Select_Next
     (Panel : in out Feature_Panel_State);

   --  Move selection to the previous row, clamping at the first row.
   --  The operation mutates only feature-panel selection and emits no messages.
   --  @param Panel Feature panel state to update.
   procedure Select_Previous
     (Panel : in out Feature_Panel_State);

   --  Return whether a live row is selected.
   --  @param Panel Feature panel state to inspect.
   --  @return True when Selected_Row denotes an existing row.
   function Has_Selection
     (Panel : Feature_Panel_State) return Boolean;

   --  Return the deterministic empty-state text for visible empty panels.
   --  @param Panel Feature panel state to inspect.
   --  @return Empty-state message.
   function Empty_Message
     (Panel : Feature_Panel_State) return String;

   --  Return the kind of a one-based row. Invalid indices return Empty_State.
   --  @param Panel Feature panel state to inspect.
   --  @param Index One-based row index.
   --  @return Row kind.
   function Row_Kind
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Panel_Row_Kind;

   --  Return the label of a one-based row, or the empty string for invalid indices.
   --  @param Panel Feature panel state to inspect.
   --  @param Index One-based row index.
   --  @return Row label.
   function Row_Label
     (Panel : Feature_Panel_State;
      Index : Positive) return String;

   --  Return the detail text of a one-based row, or the empty string for invalid indices.
   --  @param Panel Feature panel state to inspect.
   --  @param Index One-based row index.
   --  @return Row detail.
   function Row_Detail
     (Panel : Feature_Panel_State;
      Index : Positive) return String;

   --  Return whether a one-based row is marked as the passive current symbol.
   --  Selection remains the primary interaction state; this marker is only
   --  presentational and never acts as a navigation target by itself.
   function Row_Is_Current_Symbol
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean;

   --  Request that the feature panel reveal a one-based row.  This records a
   --  validated UI synchronization request only; it does not change selection,
   --  focus, visibility, row content, or any editor cursor.
   procedure Request_Reveal_Row
     (Panel : in out Feature_Panel_State;
      Index : Natural);

   procedure Request_Reveal_Row
     (Panel : in out Feature_Panel_State;
      Token : Feature_Projection_Token;
      Index : Natural);

   --  Return the currently requested reveal row, or zero when no valid reveal
   --  request is pending.
   function Requested_Reveal_Row
     (Panel : Feature_Panel_State) return Natural;

   --  Clear any pending reveal request without touching selection or rows.
   procedure Clear_Reveal_Request
     (Panel : in out Feature_Panel_State);

   --  Set the deterministic feature-panel viewport capacity used by reveal
   --  tests and simple render integration. Zero is normalized to one.
   procedure Set_Visible_Row_Count
     (Panel : in out Feature_Panel_State;
      Count : Natural);

   function Visible_Row_Count
     (Panel : Feature_Panel_State) return Natural;

   function First_Visible_Row
     (Panel : Feature_Panel_State) return Natural;

   --  Translate a one-based viewport row to the current feature row using the
   --  active scroll offset. Invalid viewport rows and hidden/out-of-range rows
   --  return zero without mutating panel state.
   function Visible_Row_To_Row_Index
     (Panel       : Feature_Panel_State;
      Visible_Row : Natural) return Natural;

   --  Scroll the simple feature-panel viewport just enough to make Row
   --  visible. Invalid rows are ignored safely and clear the pending reveal
   --  request. Rows already inside the visible range leave the scroll offset
   --  unchanged.
   procedure Reveal_Row
     (Panel : in out Feature_Panel_State;
      Row   : Natural);

   --  Clamp the transient row viewport after row count or layout changes.
   --  This mutates only feature-panel viewport state.
   procedure Clamp_Viewport
     (Panel : in out Feature_Panel_State);

   --  Scroll the feature-panel viewport by a signed row delta without changing
   --  selection, focus, rows, feature identity, or source feature state.
   procedure Scroll_By
     (Panel : in out Feature_Panel_State;
      Step_Delta : Integer);

   --  Apply the current validated reveal request to the simple scroll state
   --  and clear the request. Invalid/stale requests are cleared safely.
   procedure Apply_Pending_Reveal
     (Panel : in out Feature_Panel_State);

   --  Build a side-effect-free render snapshot.
   --  Snapshot construction does not clamp, repair, emit messages, or allocate
   --  renderer/backend resources.
   --  @param Panel Feature panel state to inspect.
   --  @return Immutable render snapshot copy.
   function Build_Render_Snapshot
     (Panel : Feature_Panel_State) return Feature_Panel_Render_Snapshot;

   --  Return whether the render snapshot is visible.
   function Snapshot_Is_Visible
     (Snapshot : Feature_Panel_Render_Snapshot) return Boolean;

   --  Return whether the render snapshot is focused.
   function Snapshot_Is_Focused
     (Snapshot : Feature_Panel_Render_Snapshot) return Boolean;

   function Snapshot_Header_Text
     (Snapshot : Feature_Panel_Render_Snapshot) return String;

   function Snapshot_Projection_Generation
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural;

   function Snapshot_First_Visible_Row
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural;

   function Snapshot_Visible_Row_Count
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural;

   --  Return the render snapshot row count.
   function Snapshot_Row_Count
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural;

   --  Return the render snapshot empty-state text.
   function Snapshot_Empty_Message
     (Snapshot : Feature_Panel_Render_Snapshot) return String;

   --  Return render row selected state for a one-based row index.
   function Snapshot_Row_Selected
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   function Snapshot_Row_Is_Current_Symbol
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   --  Return render row label for a one-based row index.
   function Snapshot_Row_Label
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return String;

   --  Return render row detail for a one-based row index.
   function Snapshot_Row_Detail
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return String;

   function Snapshot_Row_Severity
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Feature_Row_Severity;

   function Snapshot_Row_Can_Open
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   function Snapshot_Row_Can_Copy
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   function Snapshot_Row_Can_Clear
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   function Snapshot_Row_Can_Reveal
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean;

   --  Canonical Phase 118 feature-panel command outcome messages.
   --  These helpers centralize user-facing strings for Executor, palette,
   --  keybinding, route, and documentation alignment tests.
   function Message_Feature_Panel_Shown return String;
   function Message_Feature_Panel_Hidden return String;
   function Message_Feature_Panel_Focused return String;
   function Message_Feature_Panel_Cleared return String;
   function Message_Feature_Panel_Row_Has_No_Target return String;

   --  Canonical Phase 118 disabled reasons. Availability checks may return
   --  these strings, but must never emit them as messages themselves.
   function Reason_Feature_Panel_Hidden return String;
   function Reason_Feature_Panel_Already_Shown return String;
   function Reason_Feature_Panel_Already_Focused return String;
   function Reason_No_Feature_Panel_Rows return String;
   function Reason_No_Feature_Panel_Row_Selected return String;

private
   type Saved_Feature_View_State is record
      Has_State         : Boolean := False;
      Selected_Row      : Natural := 0;
      First_Visible_Row : Natural := 1;
   end record;

   type Saved_Feature_View_State_Table is array (Feature_Id) of Saved_Feature_View_State;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Feature_Panel_Row);

   package Render_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Feature_Panel_Render_Row);

   type Feature_Panel_State is record
      Visible  : Boolean := False;
      Focused  : Boolean := False;
      Rows              : Row_Vectors.Vector;
      Selected          : Natural := 0;
      Reveal_Row        : Natural := 0;
      First_Visible_Row : Natural := 1;
      Visible_Row_Count : Natural := 10;
      Header            : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("Feature");
      Projection_Generation : Natural := 1;
      Active_Feature_Id     : Feature_Id := Outline_Feature;
      Saved_View_State     : Saved_Feature_View_State_Table;
   end record;

   type Feature_Panel_Render_Snapshot is record
      Visible       : Boolean := False;
      Focused       : Boolean := False;
      Empty_Message : Ada.Strings.Unbounded.Unbounded_String;
      Header        : Ada.Strings.Unbounded.Unbounded_String;
      Projection_Generation : Natural := 0;
      Projection_Feature    : Feature_Id := Unknown_Feature;
      First_Visible_Row     : Natural := 1;
      Visible_Row_Count     : Natural := 10;
      Rows          : Render_Row_Vectors.Vector;
   end record;

end Editor.Feature_Panel;
