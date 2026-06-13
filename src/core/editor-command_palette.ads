with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Input_Field;

package Editor.Command_Palette is

   Max_Visible_Items : constant Natural := 8;

   type Palette_State is record
      Open                    : Boolean := False;
      Query                   : Ada.Strings.Unbounded.Unbounded_String;
      Selected_Item            : Natural := 0;
      Selected_Candidate_Index : Natural := 0;
      Selected_Command_Id      : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Top_Row                  : Natural := 1;
   end record;

   type Command_Palette_Config is record
      Max_Visible_Rows             : Natural := 12;
      Overlay_Width_In_Columns     : Natural := 72;
      Show_Unavailable_Commands    : Boolean := True;
      Group_Empty_Query_By_Category : Boolean := True;
      Show_Selected_Reason         : Boolean := True;
      Show_Selected_Description    : Boolean := True;
      Show_Keybindings             : Boolean := True;
      Show_Help_Row                : Boolean := False;
   end record;

   type Command_Palette_Availability_Filter is
     (Palette_All_Commands,
      Palette_Available_Only,
      Palette_Unavailable_Only);

   type Command_Palette_Keybinding_Filter is
     (Palette_All_Keybinding_States,
      Palette_Bound_Commands_Only,
      Palette_Unbound_Bindable_Commands_Only);

   Max_Related_Command_Help_Items : constant Natural := 4;

   type Command_Palette_Row_Kind is
     (Command_Palette_Header_Row,
      Command_Palette_Command_Row,
      Command_Palette_Detail_Row,
      Command_Palette_Help_Row,
      Command_Palette_Empty_Row);

   type Related_Command_Help_Item is record
      Command     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Stable_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Title       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Visible     : Boolean := False;
      Carries_Payload : Boolean := False;
   end record;

   type Related_Command_Help_Array is
     array (Positive range 1 .. Max_Related_Command_Help_Items)
       of Related_Command_Help_Item;

   Empty_Related_Command_Help_Item : constant Related_Command_Help_Item :=
     (others => <>);

   type Command_Help_Snapshot is record
      Title                 : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stable_Name           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Category_Label        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Description           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Keybinding_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Active_Keybinding : Boolean := False;
      Active_Keybinding_Count : Natural := 0;
      Unbound_Bindable     : Boolean := False;
      Non_Bindable_Command : Boolean := False;
      Bindability_Label     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Visibility_Label      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Classification_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Availability_Label    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Unavailable_Reason    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Surface_Relevance_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Guard_Label           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Related_Command_Count : Natural := 0;
      Related_Commands      : Related_Command_Help_Array :=
        (others => Empty_Related_Command_Help_Item);
   end record;

   type Command_Palette_Row is record
      Kind                   : Command_Palette_Row_Kind := Command_Palette_Empty_Row;
      Candidate_Index        : Natural := 0;
      Category               : Editor.Commands.Command_Category :=
        Editor.Commands.Internal_Category;
      Primary_Text           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Secondary_Text         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Keybinding_Text        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Keybinding         : Boolean := False;
      Is_Selected            : Boolean := False;
      Is_Available           : Boolean := True;
      Is_Detail_For_Selected : Boolean := False;
   end record;

   type Command_Palette_Row_Layout is record
      --  Concatenated visible label and secondary detail for renderers.
      Visible_Text                 : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Show_Keybinding           : Boolean := False;
      Keybinding_Text           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Keybinding_Column         : Natural := 0;
      Label_Start_Column        : Natural := 0;
      Label_Columns             : Natural := 0;
      Secondary_Start_Column    : Natural := 0;
      Secondary_Columns         : Natural := 0;
      Keybinding_Start_Column   : Natural := 0;
      Keybinding_Columns        : Natural := 0;
      Show_Secondary            : Boolean := False;
   end record;

   type Command_Palette_Snapshot is private;

   function Current return Palette_State;

   --  Return the global command-palette display preferences.
   function Current_Config return Command_Palette_Config;

   --  Replace global command-palette display preferences.
   procedure Set_Current_Config (Config : Command_Palette_Config);

   procedure Set_Show_Unavailable_Commands (Enabled : Boolean);
   procedure Set_Show_Keybindings (Enabled : Boolean);
   procedure Set_Show_Help_Row (Enabled : Boolean);
   procedure Toggle_Show_Help_Row;

   --  Transient palette filters. They affect only command discovery
   --  projection and are cleared by Reset; no filter state is persisted.
   procedure Clear_Transient_Filters;
   --  Return True when query, selection, help/details visibility, and all
   --  transient filters are at their closed-palette baseline. This is a
   --  side-effect-free persistence/audit helper for Phase 564; it does not
   --  inspect or mutate settings/keybindings/workspace state.
   function Transient_State_Clear return Boolean;
   procedure Set_Availability_Filter
     (Filter : Command_Palette_Availability_Filter);
   function Current_Availability_Filter
      return Command_Palette_Availability_Filter;
   procedure Set_Category_Filter_Label (Label : String);
   procedure Clear_Category_Filter;
   function Has_Category_Filter return Boolean;
   function Current_Category_Filter_Label return String;
   procedure Set_Destructive_Filter (Enabled : Boolean);
   function Destructive_Filter_Enabled return Boolean;
   procedure Set_Keybinding_Filter
     (Filter : Command_Palette_Keybinding_Filter);
   function Current_Keybinding_Filter return Command_Palette_Keybinding_Filter;

   procedure Reset;
   procedure Open;

   --  Open the palette with a descriptor-backed command selected. This is a
   --  transient guided-action entry point: it carries only a stable command
   --  id, suppresses hidden/internal commands, and persists no palette state.
   procedure Open_With_Command
     (Command : Editor.Commands.Command_Id);

   procedure Close;
   procedure Toggle;

   function Is_Open return Boolean;

   procedure Append_Character
     (Ch : Character);

   procedure Insert_Text
     (Text : String);

   procedure Move_Cursor_Left;
   procedure Move_Cursor_Right;
   procedure Move_Cursor_Start;
   procedure Move_Cursor_End;
   procedure Select_All;

   procedure Set_Cursor_From_Visible_Column
     (Visible_Column  : Natural;
      Visible_Columns : Natural);

   function Query_Cursor return Natural;

   procedure Backspace;
   procedure Delete_Forward;

   function Query_Snapshot
     (Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

   procedure Move_Selection_Up;
   procedure Move_Selection_Down;
   procedure Move_Selection_By (Amount : Integer);

   --  Move selection over the same visible candidate sequence that the
   --  Executor/render path projects. Use this for Command Palette overlay
   --  input so availability filters and Show_Unavailable_Commands cannot
   --  cause keyboard navigation to target a non-rendered command.
   procedure Move_Selection_By_Candidates
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Amount     : Integer);
   procedure Select_First;
   procedure Select_Last;

   procedure Filtered_Commands
     (Result : out Editor.Commands.Command_Descriptor_Vectors.Vector);

   function Selected_Command return Editor.Commands.Command_Id;

   function Has_Selected_Command return Boolean;

   function Match_Score
     (Label          : String;
      Category_Label : String;
      Description    : String;
      Query          : String) return Natural;

   --  Return True when a candidate passes the current transient palette
   --  filters. This is display-only filtering over already-projected metadata
   --  and does not compute availability, mutate keybindings, or execute work.
   function Candidate_Passes_Transient_Filters
     (Candidate : Editor.Commands.Command_Palette_Candidate) return Boolean;

   --  Return True when a candidate is visible under the current transient
   --  filters and command-palette display preferences. This additionally
   --  honors Show_Unavailable_Commands so selection/execution cannot target a
   --  row hidden from the normal palette projection.
   function Candidate_Is_Currently_Visible
     (Candidate : Editor.Commands.Command_Palette_Candidate) return Boolean;

   --  Project candidates to the currently visible command-palette rows. This
   --  is used by input/execution paths so Enter operates on the same filtered
   --  candidate sequence that render displays, without carrying payloads.
   procedure Visible_Candidates
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Result     : out Editor.Commands.Command_Palette_Candidate_Vectors.Vector);

   --  Descriptor-only counterpart used by selection/filter projection helpers.
   --  Availability filters are intentionally ignored here because availability
   --  is Executor-owned and context-dependent.
   function Descriptor_Passes_Transient_Metadata_Filters
     (Descriptor : Editor.Commands.Command_Descriptor) return Boolean;

   --  Rank a command by the full discoverability surface: title/label,
   --  stable command name, refined category label, description, and active
   --  keybinding display text. This helper is pure projection logic and does
   --  not compute availability or mutate palette state.
   function Metadata_Match_Score
     (Label          : String;
      Stable_Name    : String;
      Category_Label : String;
      Description    : String;
      Keybinding     : String;
      Query          : String) return Natural;

   --  Build display-only help for a command candidate. Help is derived from
   --  descriptor metadata, active keybinding projection already carried by
   --  the candidate, and the candidate availability snapshot.
   function Build_Command_Help
     (Candidate : Editor.Commands.Command_Palette_Candidate)
      return Command_Help_Snapshot;

   function Related_Command_Is_Activation_Safe
     (Item : Related_Command_Help_Item) return Boolean;

   function Related_Command_Is_Canonical_Descriptor_Projection
     (Item : Related_Command_Help_Item) return Boolean;

   function Assert_Related_Command_Help_Is_Phase570_Coherent
     (Help : Command_Help_Snapshot) return Boolean;

   function Descriptor_Registry_Order
     (Id : Editor.Commands.Command_Id) return Natural;

   procedure Sort_Candidates
     (Candidates : in out Editor.Commands.Command_Palette_Candidate_Vectors.Vector);

   procedure Reconcile_Selection
     (Candidates             : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Preferred_Command      : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Prefer_First_Available : Boolean := True);

   function Build_Snapshot
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : Command_Palette_Config) return Command_Palette_Snapshot;

   --  Truncate text to Max_Columns using the editor's monospaced column model.
   --  Max_Columns = 0 returns an empty string. Very narrow truncation is
   --  deterministic and uses the same ASCII ellipsis marker as existing
   --  editor truncation helpers.
   --  @param Text Text to fit.
   --  @param Max_Columns Available monospaced columns.
   --  @return Text clipped to Max_Columns columns.
   function Truncate_With_Ellipsis
     (Text        : String;
      Max_Columns : Natural) return String;

   --  Compute deterministic column ranges for a command palette row. The
   --  layout gives priority to label text, selected unavailable reasons or
   --  selected descriptions, and then a right-aligned keybinding if it can fit
   --  without overlap. A too-wide keybinding is omitted deterministically.
   --  @param Row_Width_Columns Available row width in monospaced columns.
   --  @param Label_Length Command label length in columns.
   --  @param Secondary_Length Selected-row description or reason length.
   --  @param Keybinding_Length Formatted keybinding length.
   --  @param Is_Selected Whether selected-row secondary text may be shown.
   --  @param Is_Available Whether the command can run in the current context.
   --  @return Column layout for label, secondary text, and keybinding text.
   function Layout_Command_Row
     (Row_Width_Columns : Natural;
      Label_Length      : Natural;
      Secondary_Length  : Natural;
      Keybinding_Length : Natural;
      Is_Selected       : Boolean;
      Is_Available      : Boolean) return Command_Palette_Row_Layout;

   --  Project a command candidate into deterministic one-row display text.
   --  The returned layout reserves right-side columns for the keybinding when
   --  it fits; command label and selected secondary text are truncated before
   --  the keybinding column. Selected unavailable commands show their reason
   --  in preference to descriptions.
   --  @param Candidate Command palette candidate to display.
   --  @param Is_Selected Whether selected-row secondary text may be shown.
   --  @param Row_Columns Available text columns inside the palette row.
   --  @return Text and right-aligned keybinding placement for render/tests.
   function Project_Command_Row_Layout
     (Candidate   : Editor.Commands.Command_Palette_Candidate;
      Is_Selected : Boolean;
      Row_Columns : Natural) return Command_Palette_Row_Layout;

   function Row_Count
     (Snapshot : Command_Palette_Snapshot) return Natural;

   function Row
     (Snapshot : Command_Palette_Snapshot;
      Index    : Positive) return Command_Palette_Row;

   function Candidate_Count
     (Snapshot : Command_Palette_Snapshot) return Natural;

   function Candidate
     (Snapshot : Command_Palette_Snapshot;
      Index    : Natural) return Editor.Commands.Command_Palette_Candidate;

   function Candidate_For_Row
     (Snapshot  : Command_Palette_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean) return Natural;

   function Row_For_Candidate
     (Snapshot        : Command_Palette_Snapshot;
      Candidate_Index : Natural;
      Found           : out Boolean) return Natural;

   procedure Ensure_Selected_Row_Visible
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural);

   procedure Clamp_Viewport
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural);

   procedure Scroll_By
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer);

private

   package Command_Palette_Row_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Palette_Row);

   type Command_Palette_Snapshot is record
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Rows       : Command_Palette_Row_Vectors.Vector;
   end record;

end Editor.Command_Palette;
