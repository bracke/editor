with Ada.Strings.Unbounded;
with Editor.Buffer_Switcher;
with Editor.Command_Palette;
with Editor.Commands;

package Editor.Command_Route_Audit is

   type Route_Source is
     (Route_From_Keybinding,
      Route_From_Command_Palette,
      Route_From_Pending_Bar,
      Route_From_Recent_Project_Picker,
      Route_From_File_Tree,
      Route_From_Search_Results,
      Route_From_Problems,
      Route_From_Tab_Bar,
      Route_From_Gutter,
      Route_From_Feature_Panel,
      Route_From_Feature_Render_Projection,
      Route_From_Menu_Equivalent,
      Route_From_Suggested_Action,
      Route_From_Test);

   type Route_Audit_Failure_Kind is
     (Route_Dispatched_Wrong_Command,
      Route_Dispatched_More_Than_Once,
      Route_Bypassed_Executor,
      Route_Emitted_Duplicate_Messages,
      Route_Bypassed_Availability,
      Route_Bypassed_Dirty_Guard,
      Route_Used_Stale_Keybinding_Table,
      Route_Targeted_Non_Concrete_Command,
      Route_Carried_Command_Payload,
      Route_Selected_By_Display_Label,
      Route_Custom_Failure);

   type Route_Audit_Result is private;

   --  Clear all recorded route-audit observations.
   --  @param Result audit object to reset
   procedure Clear
     (Result : in out Route_Audit_Result);

   --  Record one command-like UI route. This helper is side-effect-free except
   --  for mutating the supplied local audit object; it never executes commands
   --  and never mutates editor state or configuration.
   --  @param Result audit object to update
   --  @param Source command-like route source
   --  @param Command stable command id routed by the source
   procedure Record_Route
     (Result  : in out Route_Audit_Result;
      Source  : Route_Source;
      Command : Editor.Commands.Command_Id);

   --  command-palette route assertion: palette execution must route
   --  by stable command id, through the Executor, and with no selected-row
   --  payload. This only records observations on the local audit object.
   procedure Record_Command_Palette_Route
     (Result                   : in out Route_Audit_Result;
      Command                  : Editor.Commands.Command_Id;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Carried_Payload          : Boolean);

   --  keybinding-management route assertion: assign/remove/reset
   --  actions must route by selected stable command id through Executor-owned
   --  command handling and must not carry chord, row, path, result, diagnostic,
   --  or build-candidate payloads as command-route data.
   procedure Record_Keybinding_Management_Route
     (Result                   : in out Route_Audit_Result;
      Command                  : Editor.Commands.Command_Id;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Carried_Payload          : Boolean);

   --  suggested-action route assertion: guided actions must route by
   --  stable command id through the Executor or the command-palette entry point,
   --  after availability has been observed, and without target/payload data.
   procedure Record_Suggested_Action_Route
     (Result                               : in out Route_Audit_Result;
      Command                              : Editor.Commands.Command_Id;
      Routed_Through_Executor              : Boolean;
      Used_Stable_Command_Name             : Boolean;
      Availability_Checked                 : Boolean;
      Carried_Payload                      : Boolean;
      Routed_Through_Command_Palette_Entry : Boolean := False);

   --  buffer workflow route assertion: buffer switch/close/list
   --  activation routes must use stable command identity through Executor,
   --  observe availability, and must not carry runtime buffer ids as command,
   --  keybinding, palette, or render payloads.
   procedure Record_Buffer_Workflow_Route
     (Result                  : in out Route_Audit_Result;
      Source                  : Route_Source;
      Command                 : Editor.Commands.Command_Id;
      Routed_Through_Executor : Boolean;
      Availability_Checked    : Boolean;
      Carried_Buffer_Payload  : Boolean);

   --  generic command-like UI route assertion: panel, list, pending,
   --  picker, and row-action activations must dispatch one stable command id
   --  through Executor after availability is observed, without row/path/result
   --  payloads in the command route.
   procedure Record_Command_UI_Route
     (Result                   : in out Route_Audit_Result;
      Source                   : Route_Source;
      Command                  : Editor.Commands.Command_Id;
      Dispatch_Count           : Natural;
      Routed_Through_Executor  : Boolean;
      Used_Stable_Command_Name : Boolean;
      Availability_Checked     : Boolean;
      Carried_Payload          : Boolean);


   --  route-surface inspector: return True when text contains
   --  explicit runtime buffer identity/payload field names that are forbidden
   --  in command, keybinding, palette, workspace, or render route data.
   function Text_Contains_Runtime_Buffer_Payload
     (Text : String) return Boolean;

   --  Inspect a command descriptor as a route target.  This validates stable
   --  command identity and rejects explicit runtime-buffer payload markers in
   --  descriptor-owned persistence/route fields.
   procedure Inspect_Command_Descriptor_No_Buffer_Payload
     (Result     : in out Route_Audit_Result;
      Source     : Route_Source;
      Descriptor : Editor.Commands.Command_Descriptor);

   --  Inspect a command-palette row/candidate snapshot directly rather than
   --  trusting a caller-provided payload boolean.
   procedure Inspect_Command_Palette_Row_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Row    : Editor.Command_Palette.Command_Palette_Row);

   procedure Inspect_Command_Palette_Snapshot_No_Buffer_Payload
     (Result   : in out Route_Audit_Result;
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot);

   --  Inspect current keybinding records directly.  Keybindings are valid only
   --  when they target stable command ids and their display/persistence
   --  projection carries no runtime buffer id.
   procedure Inspect_Keybinding_Table_No_Buffer_Payload
     (Result : in out Route_Audit_Result);

   --  Inspect Buffer List route metadata.  Runtime row ids may exist inside the
   --  transient switcher state, but visible route/persisted text must not carry
   --  them as payload fields.
   procedure Inspect_Buffer_Switcher_Row_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row);

   procedure Inspect_Buffer_Switcher_State_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      State  : Editor.Buffer_Switcher.Buffer_Switcher_State);

   --  Inspect serialized route/persistence text for forbidden runtime buffer
   --  identity fields.  This is intended for workspace/keybinding/palette
   --  serialized audit paths.
   procedure Inspect_Serialized_Route_Text_No_Buffer_Payload
     (Result : in out Route_Audit_Result;
      Source : Route_Source;
      Text   : String);

   --  Aggregate route-surface inspection over descriptors, current
   --  keybindings, Buffer List state, and serialized workspace text.
   procedure Inspect_Buffer_Route_Surfaces_No_Buffer_Payload
     (Result               : in out Route_Audit_Result;
      Buffer_Switcher_State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Serialized_Workspace : String := "");

   --  Record an explicit route-audit failure without executing anything.
   --  @param Result audit object to update
   --  @param Source command-like route source
   --  @param Message failure description
   procedure Record_Failure
     (Result  : in out Route_Audit_Result;
      Source  : Route_Source;
      Message : String);

   --  Record a typed, actionable route-audit failure. This remains
   --  test-oriented and never executes commands or mutates editor state.
   --  @param Result audit object to update.
   --  @param Source command-like route source.
   --  @param Kind failure classification.
   --  @param Expected expected command id for dispatch failures.
   --  @param Actual actual command id observed by the route.
   --  @param Message additional failure detail.
   procedure Record_Route_Failure
     (Result   : in out Route_Audit_Result;
      Source   : Route_Source;
      Kind     : Route_Audit_Failure_Kind;
      Expected : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Actual   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Message  : String := "");

   --  Return the latest typed/actionable failure message, if any.
   --  @param Result audit object to inspect.
   --  @return Failure text suitable for assertion messages.
   function Last_Failure_Message
     (Result : Route_Audit_Result) return String;

   --  Return the number of route-audit failures.
   --  @param Result audit object to inspect
   --  @return failure count
   function Failure_Count
     (Result : Route_Audit_Result) return Natural;

   --  Return a deterministic human-readable route-audit summary.
   --  @param Result audit object to inspect
   --  @return summary suitable for regression-test assertion messages
   function Summary
     (Result : Route_Audit_Result) return String;

private
   use Ada.Strings.Unbounded;

   type Route_Audit_Result is record
      Routes       : Natural := 0;
      Failures     : Natural := 0;
      Last_Source  : Route_Source := Route_From_Test;
      Last_Kind    : Route_Audit_Failure_Kind := Route_Custom_Failure;
      Last_Expected : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Last_Actual   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Last_Message  : Unbounded_String := Null_Unbounded_String;
      Failure_Log   : Unbounded_String := Null_Unbounded_String;
   end record;

end Editor.Command_Route_Audit;
