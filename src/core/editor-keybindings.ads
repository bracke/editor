with Ada.Strings.Unbounded;
with Editor.Commands;

package Editor.Keybindings is

   type Key_Code is
     (Key_Left,
      Key_Right,
      Key_Up,
      Key_Down,
      Key_Home,
      Key_End,
      Key_Page_Up,
      Key_Page_Down,
      Key_Backspace,
      Key_Delete,
      Key_Enter,
      Key_Escape,
      Key_A,
      Key_S,
      Key_C,
      Key_X,
      Key_V,
      Key_F,
      Key_G,
      Key_H,
      Key_P,
      Key_N,
      Key_W,
      Key_M,
      Key_L,
      Key_F1,
      Key_F2,
      Key_F3,
      Key_F12,
      Key_Tab,
      Key_Z,
      Key_Y);

   type Modifier_Set is record
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False;
      Meta  : Boolean := False;
   end record;

   type Key_Chord is record
      Key       : Key_Code;
      Modifiers : Modifier_Set;
   end record;

   type Binding_Result is
     (No_Binding,
      Bound_Command);

   type Command_Keybinding_Info is record
      Has_Binding : Boolean := False;
      Display     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Default_Keybinding_Registration_Result is record
      Requested_Count  : Natural := 0;
      Registered_Count : Natural := 0;
      Conflict_Count   : Natural := 0;
   end record;

   type Keybinding_Change_Status is
     (Keybinding_Change_Ok,
      Keybinding_Change_Invalid_Target,
      Keybinding_Change_Non_Bindable_Target,
      Keybinding_Change_Internal_Target,
      Keybinding_Change_Public_Build_Target,
      Keybinding_Change_Table_Full);

   procedure Reset_To_Defaults;

   procedure Clear;

   procedure Bind
     (Chord : Key_Chord;
      Id    : Editor.Commands.Command_Id);

   --  Assign Chord to Id for normal user-facing keybinding editing. This
   --  validates that Id is a concrete, bindable, non-internal, non-public-build
   --  command target before mutating. On success, the command's previous
   --  bindings are removed and any previous owner of Chord is displaced, so
   --  conflict handling is deterministic last-assignment-wins without partial
   --  mutation on rejection. Low-level Bind remains for built-in/default table
   --  construction and routing tests.
   procedure Assign
     (Chord  : Key_Chord;
      Id     : Editor.Commands.Command_Id;
      Status : out Keybinding_Change_Status);

   procedure Unbind
     (Chord : Key_Chord);

   procedure Unbind_Command
     (Id : Editor.Commands.Command_Id);

   --  Return whether a conservative default binding may be added without
   --  overwriting an existing user or default chord. This is deliberately
   --  chord-based: commands may already be available through the palette or a
   --  different user binding.
   function Can_Register_Default_Keybinding
     (Chord : Key_Chord) return Boolean;

   --  Register Phase 131 outline defaults without overwriting any existing
   --  chord. Conflicts are counted deterministically in candidate order;
   --  command-palette availability is independent of these optional keys.
   function Register_Outline_Keybindings
      return Default_Keybinding_Registration_Result;

   function Resolve
     (Chord : Key_Chord;
      Id    : out Editor.Commands.Command_Id) return Binding_Result;

   --  Return the primary keybinding display for Command. The primary binding
   --  is the first distinct chord for Command in registry insertion order.
   --  @param Command Command identifier.
   --  @return Binding display information, or Has_Binding = False.
   function Primary_Binding_For_Command
     (Command : Editor.Commands.Command_Id) return Command_Keybinding_Info;

   --  Return the number of distinct chords currently bound to Command.
   --  @param Command Command identifier.
   --  @return Number of bindings in deterministic registry order.
   function Binding_Count_For_Command
     (Command : Editor.Commands.Command_Id) return Natural;

   --  Return the Index-th distinct chord for Command in registry order.
   --  @param Command Command identifier.
   --  @param Index One-based binding index.
   --  @return Key chord at Index.
   function Binding_For_Command
     (Command : Editor.Commands.Command_Id;
      Index   : Positive) return Key_Chord;

   --  Return the number of commands that currently have at least one binding.
   --  The display list is command-based, sorted by stable command name, and
   --  excludes unbound bindable commands.
   function Bound_Command_Count return Natural;

   --  Return the Index-th currently bound command in stable command-name order.
   function Bound_Command_At
     (Index : Positive) return Editor.Commands.Command_Id;

   --  Return the number of normal user-facing assignable commands that are
   --  currently unbound. Internal build test seams and any future public build
   --  commands are excluded from this display-oriented set.
   function Unbound_Assignable_Command_Count return Natural;

   --  Return the Index-th unbound assignable command in stable command-name
   --  order for keybinding editor display surfaces.
   function Unbound_Assignable_Command_At
     (Index : Positive) return Editor.Commands.Command_Id;

   --  Return True when Id may be targeted by normal user-facing keybinding
   --  assignment UI. This is stricter than bindability and excludes internal
   --  build test seams and public build commands.
   function Is_Normal_Assignable_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   type Keybinding_Validation_Status is
     (Valid_Keybindings,
      Invalid_Keybindings);

   type Keybinding_Validation_Result is private;

   type Keybinding_Validation_Summary is record
      Bound_Command_Count : Natural := 0;
      Conflict_Count      : Natural := 0;
      Invalid_Count       : Natural := 0;
      Unbound_Count       : Natural := 0;
   end record;

   --  Validate the current deterministic keybinding table. Validation is
   --  intended for audits/tests and never mutates bindings. Runtime bindings
   --  are valid only when every target is concrete and bindable, no chord is
   --  duplicated, and every reverse lookup is consistent with forward lookup.
   --  @return Result containing a side-effect-free validation summary.
   function Validate return Keybinding_Validation_Result;

   --  @param Result Result returned by Validate.
   --  @return Overall validation status.
   function Status
     (Result : Keybinding_Validation_Result)
      return Keybinding_Validation_Status;

   --  @param Result Result returned by Validate.
   --  @return True when any used binding targets No_Command or a non-concrete id.
   function Has_Invalid_Command_Targets
     (Result : Keybinding_Validation_Result) return Boolean;

   --  @param Result Result returned by Validate.
   --  @return True when duplicate used chords are present in the table.
   function Has_Duplicate_Chords
     (Result : Keybinding_Validation_Result) return Boolean;

   --  @param Result Result returned by Validate.
   --  @return Deterministic validation counters for tests and diagnostics.
   function Summary
     (Result : Keybinding_Validation_Result)
      return Keybinding_Validation_Summary;

   --  Parse a key chord in the deterministic persisted/display format.
   --  @param Text Chord text such as Ctrl+Shift+S or F3.
   --  @param Found True when Text is a valid chord.
   --  @return Parsed chord, or a harmless default when not Found.
   function Parse_Chord
     (Text  : String;
      Found : out Boolean) return Key_Chord;

   --  Format a key chord using deterministic modifier order Ctrl, Alt, Shift, Meta.
   --  @param Chord Key chord to format.
   --  @return Stable user-facing display string such as Ctrl+Shift+F.
   function Format_Chord
     (Chord : Key_Chord) return String;

private

   type Keybinding_Validation_Result is record
      Validation_Status : Keybinding_Validation_Status := Valid_Keybindings;
      Invalid_Targets   : Boolean := False;
      Duplicate_Chords  : Boolean := False;
      Validation_Summary : Keybinding_Validation_Summary;
   end record;

end Editor.Keybindings;
