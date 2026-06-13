with Editor.Commands;
with Editor.Keybindings;

package Editor.Keybinding_Config is

   type Keybinding_Config_Status is
     (Keybinding_Config_Ok,
      Keybinding_Config_Not_Found,
      Keybinding_Config_Invalid_Format,
      Keybinding_Config_Unsupported_Version,
      Keybinding_Config_Read_Error,
      Keybinding_Config_Write_Error,
      Keybinding_Config_Partial_Load);

   type Keybinding_Config_Diagnostic_Kind is
     (Malformed_Line,
      Unknown_Section,
      Unknown_Command,
      Invalid_Command_Name,
      Invalid_Chord,
      Unsupported_Payload,
      Duplicate_Command,
      Duplicate_Chord,
      Unsupported_Version);

   type Keybinding_Config_Model is private;


   --  Return a stable user-readable status label for keybinding load/save/reset
   --  flows. The label is suitable for Executor messages and UI summaries and
   --  intentionally does not expose internal enum spelling.
   function Status_Label
     (Status : Keybinding_Config_Status) return String;

   --  Return a stable user-readable validation diagnostic label.
   function Diagnostic_Label
     (Kind : Keybinding_Config_Diagnostic_Kind) return String;

   --  Return the number of invalid/ignored records encountered by the most
   --  recent Load_From_File call. This is an observational diagnostic surface
   --  for keybinding management and audits; it is not persisted.
   function Last_Load_Ignored_Count return Natural;

   --  Return how many most-recently-loaded records were ignored for a
   --  specific diagnostic class. This lets the keybinding view surface
   --  unknown commands, non-bindable commands, malformed chords, duplicate
   --  chords/commands, and payload-bearing records without preserving the
   --  rejected records as executable state.
   function Last_Load_Diagnostic_Count
     (Kind : Keybinding_Config_Diagnostic_Kind) return Natural;

   --  Return True when a persisted keybinding value carries anything beyond
   --  the chord/unbind value allowed by the keybindings domain.  This is a
   --  display/audit helper only; it never parses or installs a binding.
   function Keybinding_Value_Has_Unsupported_Payload
     (Value : String) return Boolean;

   --  Restore Config to an empty versioned keybinding override model.
   --  @param Config keybinding configuration to clear
   procedure Clear
     (Config : in out Keybinding_Config_Model);

   --  Populate Config with the built-in default keybindings.
   --  @param Config keybinding configuration to populate
   procedure Set_Defaults
     (Config : in out Keybinding_Config_Model);

   --  Return the persisted keybinding file format version.
   --  @param Config keybinding configuration to inspect
   --  @return file format version
   function Version
     (Config : Keybinding_Config_Model) return Natural;

   --  Bind Command to Chord in the persisted model. Last valid chord wins.
   --  @param Config keybinding configuration to mutate
   --  @param Command stable concrete command id
   --  @param Chord key chord to persist
   procedure Bind
     (Config  : in out Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id;
      Chord   : Editor.Keybindings.Key_Chord);

   --  Explicitly unbind Command in the persisted model.
   --  @param Config keybinding configuration to mutate
   --  @param Command stable concrete command id
   procedure Unbind
     (Config  : in out Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id);

   --  Return the number of explicitly bound commands.
   --  @param Config keybinding configuration to inspect
   --  @return count of bound entries, excluding explicit unbinds
   function Binding_Count
     (Config : Keybinding_Config_Model) return Natural;

   --  Return the Index-th bound command in stable command-name order.
   --  @param Config keybinding configuration to inspect
   --  @param Index one-based binding index
   --  @return command id at Index
   function Command_At
     (Config : Keybinding_Config_Model;
      Index  : Positive) return Editor.Commands.Command_Id;

   --  Return the chord for Command, if Command is explicitly bound.
   --  @param Config keybinding configuration to inspect
   --  @param Command stable command id
   --  @param Found True when Command has a chord binding
   --  @return bound chord, or a harmless default when not Found
   function Chord_For
     (Config  : Keybinding_Config_Model;
      Command : Editor.Commands.Command_Id;
      Found   : out Boolean) return Editor.Keybindings.Key_Chord;

   --  Normalize duplicate/conflicting bindings into a deterministic table.
   --  @param Config keybinding configuration to normalize
   procedure Normalize
     (Config : in out Keybinding_Config_Model);

   --  Semantic equality over normalized persisted keybinding models.
   function Equivalent
     (Left  : Keybinding_Config_Model;
      Right : Keybinding_Config_Model) return Boolean;

   --  Build a persisted model from the active runtime keybinding table.
   --  Default commands that are absent from the active table are persisted as
   --  explicit unbinds so save/load preserves intentional unbinds and conflict
   --  displacement. The final active runtime table is not changed.
   --  @param Config resulting keybinding configuration
   procedure Build_From_Runtime
     (Config : out Keybinding_Config_Model);

   --  Apply Config to active runtime keybindings. This mutates only the
   --  process-wide keybinding resolver and does not execute commands.
   --  @param Config keybinding configuration to apply
   procedure Apply_To_Runtime
     (Config : Keybinding_Config_Model);

   --  Return the global editor keybindings path. EDITOR_KEYBINDINGS_PATH
   --  overrides the default for tests; otherwise $XDG_CONFIG_HOME/editor/keybindings
   --  or $HOME/.config/editor/keybindings is used.
   --  @return absolute or environment-provided keybindings path
   function Keybindings_File_Path return String;

   --  Save global keybinding overrides to Path using deterministic
   --  serialization and best-effort atomic temp-file replacement.
   --  @param Config keybinding configuration to save
   --  @param Path output file path
   --  @param Status save result
   procedure Save_To_File
     (Config : Keybinding_Config_Model;
      Path   : String;
      Status : out Keybinding_Config_Status);

   --  Load global keybinding overrides from Path. The loaded configuration
   --  targets stable command identifiers, not user-facing command labels.
   --  Missing files are reported separately so callers can fall back to
   --  built-in defaults without treating startup as failed.
   --  @param Path keybindings file path
   --  @param Config loaded keybinding configuration
   --  @param Status load result
   procedure Load_From_File
     (Path   : String;
      Config : out Keybinding_Config_Model;
      Status : out Keybinding_Config_Status);

private
   type Entry_State is (Entry_Absent, Entry_Bound, Entry_Unbound);

   type Keybinding_Entry is record
      State : Entry_State := Entry_Absent;
      Chord : Editor.Keybindings.Key_Chord :=
        (Key => Editor.Keybindings.Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
   end record;

   type Binding_Array is array (Editor.Commands.Command_Id) of Keybinding_Entry;

   type Keybinding_Config_Model is record
      Format_Version : Natural := 1;
      Entries        : Binding_Array;
   end record;

end Editor.Keybinding_Config;
