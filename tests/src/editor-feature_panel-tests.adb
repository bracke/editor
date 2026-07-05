with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Workspace_Persistence;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Ada.Text_IO;
with Ada.Directories;
with Editor.Commands;
with Editor.Cursors;
with Editor.Clipboard;
with Editor.Executor;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Messages;
with Editor.Feature_Messages.Fixtures;
with Editor.Feature_Search_Results;
with Editor.Search_Results_Audit;
with Editor.Diagnostics_Audit;
with Editor.Feature_Diagnostics;
with Editor.Message_Producers;
with Editor.Outline;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.State;
with Editor.Buffers;
with Editor.View;
with Editor.Layout;
with Text_Buffer;

package body Editor.Feature_Panel.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Feature_Messages.Message_Id;
   use type Editor.Feature_Messages.Message_Source_Kind;
   use type Editor.Feature_Messages.Message_Severity;
   use type Editor.Feature_Diagnostics.Diagnostic_Id;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   use type Editor.Feature_Panel.Feature_Row_Severity;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
   use type Editor.Feature_Panel.Feature_Id;

   function Name (T : Feature_Panel_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Feature_Panel.Tests");
   end Name;

   procedure Test_Model_Defaults_And_Placeholders
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Assert (not Is_Visible (Panel), "feature panel defaults hidden");
      Assert (not Is_Focused (Panel), "feature panel defaults unfocused");
      Assert (Row_Count (Panel) = 0, "feature panel defaults empty");
      Assert (Selected_Row (Panel) = 0, "empty feature panel has no selection");
      Assert (Empty_Message (Panel) = "No feature rows", "empty message is deterministic");

      Set_Placeholder_Rows (Panel);
      Assert (Row_Count (Panel) = 3, "placeholder rows are deterministic");
      Assert (Selected_Row (Panel) = 0, "placeholder population does not select implicitly");
      Select_First (Panel);
      Assert (Selected_Row (Panel) = 2, "Select_First skips the non-selectable header row");
      Assert (Row_Label (Panel, 1) = "Feature Panel", "header placeholder label");
      Assert (Row_Label (Panel, 2) = "Placeholder Item", "first placeholder item label");
      Assert (Row_Label (Panel, 3) = "Another Placeholder Item", "second placeholder item label");

      Select_Next (Panel);
      Select_Next (Panel);
      Select_Next (Panel);
      Assert (Selected_Row (Panel) = 3, "next selection clamps at final row");
      Select_Previous (Panel);
      Assert (Selected_Row (Panel) = 2, "previous selection moves upward");
      Clear_Rows (Panel);
      Assert (Row_Count (Panel) = 0 and then Selected_Row (Panel) = 0,
              "clearing rows also clears selection");
   end Test_Model_Defaults_And_Placeholders;

   procedure Test_Command_Metadata_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Category (Editor.Commands.Command_Toggle_Feature_Panel) =
                Editor.Commands.Panel_Category,
              "toggle feature panel must be in Panels category");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Toggle_Feature_Panel),
              "toggle feature panel is command-palette visible");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Toggle_Feature_Panel) =
                "toggle-feature-panel",
              "feature stable name is lowercase kebab-case");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("toggle-feature-panel", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Feature_Panel,
              "feature stable name round trips");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("populate-feature-panel-placeholder", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "removed placeholder population command is removed");
   end Test_Command_Metadata_Stable_Names;

   procedure Test_Command_Availability_And_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Assert (not Is_Visible (S.Feature_Panel), "feature panel starts hidden");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Hide_Feature_Panel)),
        "hide is unavailable when feature panel hidden");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Toggle_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "toggle feature panel executes");
      Assert (Is_Visible (S.Feature_Panel), "toggle shows feature panel");

      Assert (Row_Count (S.Feature_Panel) = 0,
              "normal feature panel commands do not populate placeholder rows");
      Set_Placeholder_Rows (S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 3,
              "explicit fixture helper populates placeholder rows");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "clear feature panel executes");
      Assert (Row_Count (S.Feature_Panel) = 0, "clear removes rows");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Clear_Feature_Panel)),
        "clear is unavailable after rows are cleared");
   end Test_Command_Availability_And_Execution;

   procedure Test_Project_Reset_And_Settings_Separation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Set_Visible (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Editor.State.Apply_Settings (S, S.Settings);
      Assert (Row_Count (S.Feature_Panel) = 3,
              "settings application must not clear transient feature rows");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Is_Visible (S.Feature_Panel),
              "project reset preserves non-persisted visibility policy");
      Assert (Row_Count (S.Feature_Panel) = 0,
              "project reset clears project-scoped feature rows");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "project reset clears feature selection");
   end Test_Project_Reset_And_Settings_Separation;

   procedure Test_Keybinding_Config_Accepts_Bindable_Feature_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Chord  : Editor.Keybindings.Key_Chord;
      Found  : Boolean := False;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Config.Clear (Config);
      Chord := Editor.Keybindings.Parse_Chord ("Ctrl+Alt+O", Found);
      Assert (Found, "test chord parses");
      Editor.Keybinding_Config.Bind
        (Config, Editor.Commands.Command_Toggle_Feature_Panel, Chord);
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert (Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Toggle_Feature_Panel).Has_Binding,
        "runtime keybinding reverse lookup sees feature command binding");
      Assert (Ada.Strings.Unbounded.To_String
        (Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Toggle_Feature_Panel).Display) = "Ctrl+Alt+O",
        "runtime keybinding display uses custom feature chord");
      declare
         Removed_Found : Boolean := True;
         Removed_Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Removed_Id := Editor.Commands.Command_Id_From_Stable_Name
           ("populate-feature-panel-placeholder", Removed_Found);
         Assert (not Removed_Found and then Removed_Id = Editor.Commands.No_Command,
                 "removed placeholder command cannot be keybound because it is removed");
      end;
   end Test_Keybinding_Config_Accepts_Bindable_Feature_Command;



   procedure Test_Invariants_Focus_And_Render_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel    : Feature_Panel_State;
      Snapshot : Feature_Panel_Render_Snapshot;
   begin
      Assert (Invariant_Holds (Panel), "default feature panel invariant holds");
      Set_Focused (Panel, True);
      Assert (not Is_Focused (Panel), "hidden panel cannot become focused");
      Assert (Invariant_Holds (Panel), "hidden focus rejection preserves invariant");

      Set_Visible (Panel, True);
      Set_Focused (Panel, True);
      Assert (Is_Focused (Panel), "visible feature panel can be focused");
      Set_Visible (Panel, False);
      Assert (not Is_Focused (Panel), "hiding feature panel clears focus");
      Assert (Invariant_Holds (Panel), "hide clears focus invariant");

      Set_Visible (Panel, True);
      Set_Placeholder_Rows (Panel);
      Select_First (Panel);
      Select_Next (Panel);
      Snapshot := Build_Render_Snapshot (Panel);
      Assert (Snapshot_Is_Visible (Snapshot), "render snapshot preserves visibility");
      Assert (Snapshot_Row_Count (Snapshot) = 3, "render snapshot copies rows");
      Assert (Snapshot_Row_Selected (Snapshot, 3), "render snapshot marks selected row");
      Assert (Snapshot_Row_Label (Snapshot, 2) = "Placeholder Item",
              "render snapshot preserves deterministic row label");
      Assert (Row_Count (Panel) = 3 and then Selected_Row (Panel) = 3,
              "snapshot construction is side-effect-free");
   end Test_Invariants_Focus_And_Render_Snapshot;

   procedure Test_Empty_Selection_And_Command_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      S     : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Messages : Natural;
   begin
      Select_First (Panel);
      Assert (not Has_Selection (Panel), "Select_First on empty panel leaves no selection");
      Select_Next (Panel);
      Assert (Selected_Row (Panel) = 0, "Select_Next on empty panel leaves no selection");
      Select_Previous (Panel);
      Assert (Selected_Row (Panel) = 0, "Select_Previous on empty panel leaves no selection");
      Assert (Invariant_Holds (Panel), "empty selection movement preserves invariant");

      Editor.State.Init (S);
      Set_Visible (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Select_Next);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selection command executes when visible with rows");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "selection command emits no message");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "placeholder open is unavailable because the selected row has no target");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages + 1,
              "placeholder open emits one primary message");
   end Test_Empty_Selection_And_Command_Messages;

   procedure Test_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Rows     : Natural;
      Before_Selected : Natural;
      Before_Visible  : Boolean;
      Before_Focused  : Boolean;
      Before_Messages : Natural;
      Availability    : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Set_Visible (S.Feature_Panel, True);
      Set_Focused (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Select_Next (S.Feature_Panel);
      Before_Rows := Row_Count (S.Feature_Panel);
      Before_Selected := Selected_Row (S.Feature_Panel);
      Before_Visible := Is_Visible (S.Feature_Panel);
      Before_Focused := Is_Focused (S.Feature_Panel);
      Before_Messages := Editor.Messages.Count (S.Messages);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Editor.Commands.Is_Available (Availability),
              "clear feature panel availability sees clearable rows");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (not Editor.Commands.Is_Available (Availability),
              "open selected availability rejects selected row without target");

      Assert (Row_Count (S.Feature_Panel) = Before_Rows,
              "availability does not mutate row count");
      Assert (Selected_Row (S.Feature_Panel) = Before_Selected,
              "availability does not mutate selection");
      Assert (Is_Visible (S.Feature_Panel) = Before_Visible,
              "availability does not mutate visibility");
      Assert (Is_Focused (S.Feature_Panel) = Before_Focused,
              "availability does not mutate focus");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "availability emits no messages");
   end Test_Availability_Is_Side_Effect_Free;


   procedure Test_Summary_Fingerprint_And_Row_Access
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      S1    : Feature_Panel_Summary;
      F1    : Feature_Panel_Fingerprint;
      F2    : Feature_Panel_Fingerprint;
   begin
      Set_Visible (Panel, True);
      Set_Focused (Panel, True);
      Set_Placeholder_Rows (Panel);
      S1 := Summary (Panel);
      Assert (S1.Visible and then S1.Focused, "summary records visibility and focus");
      Assert (S1.Row_Count = 3, "summary records row count");
      Assert (not S1.Has_Selection and then S1.Selected_Row = 0,
              "summary records explicit no-selection placeholder policy");
      Assert (not Is_Selected_Row (Panel, 1), "no implicit selected row");
      Select_First (Panel);
      Assert (Is_Selected_Row (Panel, 2), "Is_Selected_Row uses explicit selectable-row selection");
      Assert (Row_Kind (Panel, 100) = Feature_Row_Empty_State,
              "invalid row kind returns deterministic empty state");
      Assert (Row_Label (Panel, 100) = "", "invalid row label returns empty string");
      Assert (Row_Detail (Panel, 100) = "", "invalid row detail returns empty string");
      F1 := Fingerprint (Panel);
      F2 := Fingerprint (Panel);
      Assert (F1.Row_Labels_Hash = F2.Row_Labels_Hash
              and then F1.Row_Details_Hash = F2.Row_Details_Hash,
              "fingerprints are deterministic and side-effect-free");
   end Test_Summary_Fingerprint_And_Row_Access;

   procedure Test_Explicit_Unavailable_Command_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Feature_Panel_Fingerprint;
   begin
      Editor.State.Init (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "hide hidden feature panel is explicitly unavailable");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "show hidden feature panel executes");
      Before := Fingerprint (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "show visible feature panel is explicitly unavailable");
      Assert (Fingerprint (S.Feature_Panel) = Before,
              "unavailable show does not mutate feature-panel state");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "focus visible feature panel executes");
      Before := Fingerprint (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "focus already focused feature panel is unavailable");
      Assert (Fingerprint (S.Feature_Panel) = Before,
              "unavailable focus does not mutate feature-panel state");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "clear empty feature panel is unavailable");
   end Test_Explicit_Unavailable_Command_Policy;

   procedure Test_Fixture_Builders
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Hidden   : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Feature_Panel_Hidden;
      Visible  : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Feature_Panel_Visible;
      Focused  : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Feature_Panel_Focused;
      Rows     : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Feature_Panel_Rows;
      Selected : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Feature_Panel_Selected_Row;
      Project_Rows : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Project_And_Feature_Panel_Rows;
      Dirty_Rows : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Dirty_Buffer_And_Feature_Panel_Rows;
      Pending_Rows : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Pending_Transition_And_Feature_Panel_Rows;
      Palette_Rows : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Command_Palette_And_Feature_Panel_Rows;
      Custom_Keybinding_Rows : Editor.State.State_Type :=
        Editor.Feature_Panel.Fixtures.State_With_Custom_Keybindings_For_Feature_Panel;
   begin
      Assert (not Is_Visible (Hidden.Feature_Panel), "hidden fixture is hidden");
      Assert (Is_Visible (Visible.Feature_Panel), "visible fixture is visible");
      Assert (Is_Focused (Focused.Feature_Panel), "focused fixture is focused");
      Assert (Row_Count (Rows.Feature_Panel) = 3
              and then not Has_Selection (Rows.Feature_Panel),
              "rows fixture has deterministic rows without selection");
      Assert (Has_Selection (Selected.Feature_Panel),
              "selected fixture explicitly selects a row");
      Assert (Row_Count (Project_Rows.Feature_Panel) = 3,
              "project + rows fixture is available");
      Assert (Editor.State.Is_Dirty (Dirty_Rows),
              "dirty-buffer + rows fixture is available");
      Assert (Editor.Pending_Transitions.Has_Pending
                (Pending_Rows.Pending_Transitions),
              "pending-transition + rows fixture is available");
      Assert (Row_Count (Palette_Rows.Feature_Panel) = 3,
              "command-palette + rows fixture is available");
      Assert (Row_Count (Custom_Keybinding_Rows.Feature_Panel) = 3
              and then Editor.Keybindings.Primary_Binding_For_Command
                (Editor.Commands.Command_Toggle_Feature_Panel).Has_Binding,
              "custom-keybindings + rows fixture is available");
   end Test_Fixture_Builders;



   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "" & Name);
   end Temp_Path;

   function Read_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Strings.Unbounded.Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            Ada.Strings.Unbounded.Append (Result, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return Ada.Strings.Unbounded.To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Read_Text;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Assert_Invariant_After_Representative_Sequence
     (S       : Editor.State.State_Type;
      Context : String)
   is
   begin
      Assert (Invariant_Holds (S.Feature_Panel),
              Context & ": feature-panel invariant must hold");
      Assert ((not Is_Focused (S.Feature_Panel)) or else Is_Visible (S.Feature_Panel),
              Context & ": focused feature panel must be visible");
      Assert ((Row_Count (S.Feature_Panel) /= 0) or else
                Selected_Row (S.Feature_Panel) = 0,
              Context & ": empty feature panel must have no selection");
      Assert (Selected_Row (S.Feature_Panel) <= Row_Count (S.Feature_Panel),
              Context & ": selected row must be in range");
   end Assert_Invariant_After_Representative_Sequence;

   procedure Test_Consolidated_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Assert_Invariant_After_Representative_Sequence (S, "initial state");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "show executes from hidden state");
      Assert_Invariant_After_Representative_Sequence (S, "after show");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "focus executes when visible");
      Assert_Invariant_After_Representative_Sequence (S, "after focus");

      Assert (Row_Count (S.Feature_Panel) = 0,
              "show/focus command sequence leaves placeholder rows absent");
      Set_Placeholder_Rows (S.Feature_Panel);
      Assert_Invariant_After_Representative_Sequence (S, "after explicit fixture populate");

      Select_First (S.Feature_Panel);
      Editor.Feature_Panel.Select_Next (S.Feature_Panel);
      Editor.Feature_Panel.Select_Previous (S.Feature_Panel);
      Assert_Invariant_After_Representative_Sequence (S, "after local selection");

      declare
         Before : constant Feature_Panel_Fingerprint := Fingerprint (S.Feature_Panel);
         Snap   : constant Feature_Panel_Render_Snapshot :=
           Build_Render_Snapshot (S.Feature_Panel);
         Avail  : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      begin
         Assert (Snapshot_Row_Count (Snap) = Row_Count (S.Feature_Panel),
                 "render snapshot sees rows");
         Assert (not Editor.Commands.Is_Available (Avail),
                 "open-selected availability rejects explicit row without target");
         Assert (Fingerprint (S.Feature_Panel) = Before,
                 "render snapshot and availability must be side-effect-free");
      end;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "clear executes with rows");
      Assert_Invariant_After_Representative_Sequence (S, "after clear");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "hide executes when visible");
      Assert_Invariant_After_Representative_Sequence (S, "after hide");
   end Test_Consolidated_Invariants;

   procedure Test_Command_Set_Frozen
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Feature_Commands : constant array (Positive range <>) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Toggle_Feature_Panel,
         Editor.Commands.Command_Show_Feature_Panel,
         Editor.Commands.Command_Hide_Feature_Panel,
         Editor.Commands.Command_Focus_Feature_Panel,
         Editor.Commands.Command_Clear_Feature_Panel,
         Editor.Commands.Command_Feature_Panel_Select_Next,
         Editor.Commands.Command_Feature_Panel_Select_Previous,
         Editor.Commands.Command_Feature_Panel_Open_Selected);
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id;
      D     : Editor.Commands.Command_Descriptor;
   begin
      for Id of Feature_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (D.Id = Id, "feature-panel descriptor id must match");
         Assert (D.Category = Editor.Commands.Panel_Category,
                 "feature-panel command category policy is frozen");
         Assert (Editor.Commands.Has_Availability_Handler (Id),
                 "feature-panel command must have availability handler");
         Assert (Editor.Commands.Stable_Command_Name (Id)'Length > 0,
                 "feature-panel stable name must exist");
         Round := Editor.Commands.Command_Id_From_Stable_Name
           (Editor.Commands.Stable_Command_Name (Id), Found);
         Assert (Found and then Round = Id,
                 "feature-panel stable name must round-trip");
      end loop;

      declare
         Removed_Found : Boolean := True;
         Removed_Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Removed_Id := Editor.Commands.Command_Id_From_Stable_Name
           ("populate-feature-panel-placeholder", Removed_Found);
         Assert (not Removed_Found and then Removed_Id = Editor.Commands.No_Command,
                 "removed placeholder population command is removed");
      end;
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Toggle_Feature_Panel),
              "toggle feature panel remains explicitly bindable");
      Editor.Keybindings.Reset_To_Defaults;
      Assert (not Editor.Keybindings.Primary_Binding_For_Command
                (Editor.Commands.Command_Toggle_Feature_Panel).Has_Binding,
              "keeps no default feature-panel keybinding");
   end Test_Command_Set_Frozen;

   procedure Test_Canonical_Reasons_And_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Msg    : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Editor.State.Init (S);
      Assert (Editor.Feature_Panel.Message_Feature_Panel_Shown = "Feature panel shown",
              "shown message is canonical");
      Assert (Editor.Feature_Panel.Message_Feature_Panel_Hidden = "Feature panel hidden",
              "hidden message is canonical");
      Assert (Editor.Feature_Panel.Message_Feature_Panel_Focused = "Feature panel focused",
              "focused message is canonical");
      Assert (Editor.Feature_Panel.Message_Feature_Panel_Cleared = "Feature panel: active feature cleared",
              "cleared message is canonical");
      Assert (Editor.Feature_Panel.Message_Feature_Panel_Row_Has_No_Target =
              "Feature panel: target unavailable",
              "no-target message is canonical");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "hide hidden is unavailable");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
                Editor.Feature_Panel.Reason_Feature_Panel_Hidden,
              "unavailable execution reports canonical disabled reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "show hidden executes");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "show visible is unavailable");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
                Editor.Feature_Panel.Reason_Feature_Panel_Already_Shown,
              "show disabled reason is canonical");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "focus visible executes");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "focus already-focused is unavailable");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
                Editor.Feature_Panel.Reason_Feature_Panel_Already_Focused,
              "focus disabled reason is canonical");
   end Test_Canonical_Reasons_And_Messages;

   procedure Test_Lifecycle_Reset_Is_Success_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Before  : Feature_Panel_Fingerprint;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
      Target  : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => Ada.Strings.Unbounded.To_Unbounded_String ("/tmp/project-b"),
         Display    => Ada.Strings.Unbounded.To_Unbounded_String ("project-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
   begin
      Editor.State.Init (S);
      Set_Visible (S.Feature_Panel, True);
      Set_Focused (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Before := Fingerprint (S.Feature_Panel);

      Editor.Pending_Transitions.Set_Pending (S.Pending_Transitions, Target, Summary);
      Assert (Fingerprint (S.Feature_Panel) = Before,
              "blocked transition setup preserves feature-panel state");
      Editor.Pending_Transitions.Clear (S.Pending_Transitions);
      Assert (Fingerprint (S.Feature_Panel) = Before,
              "cancel pending transition preserves feature-panel state");

      Editor.State.Apply_Settings (S, S.Settings);
      Assert (Fingerprint (S.Feature_Panel) = Before,
              "settings application does not reset feature-panel rows");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Is_Visible (S.Feature_Panel),
              "successful project reset preserves visibility policy");
      Assert (not Is_Focused (S.Feature_Panel),
              "successful project reset clears feature-panel focus");
      Assert (Row_Count (S.Feature_Panel) = 0 and then
                Selected_Row (S.Feature_Panel) = 0,
              "successful project reset clears rows and selection");
   end Test_Lifecycle_Reset_Is_Success_Only;

   procedure Test_Workspace_Persistence_Excludes_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Path     : constant String := Temp_Path ("feature_panel_workspace.txt");
      Text     : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Set_Visible (S.Feature_Panel, True);
      Set_Focused (S.Feature_Panel, True);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace snapshot should save for persistence probe");
      Text := Ada.Strings.Unbounded.To_Unbounded_String (Read_Text (Path));
      Assert (not Contains (Ada.Strings.Unbounded.To_String (Text), "Feature panel"),
              "workspace must not persist feature-panel title");
      Assert (not Contains (Ada.Strings.Unbounded.To_String (Text), "Placeholder Item"),
              "workspace must not persist placeholder rows");
      Assert (Contains (Ada.Strings.Unbounded.To_String (Text), "active-feature-panel="),
              "workspace must persist active feature-panel selection structurally");
      Assert (not Contains (Ada.Strings.Unbounded.To_String (Text), "selected-feature-panel-row"),
              "workspace must not persist feature-panel row selection state");
      Assert (not Contains (Ada.Strings.Unbounded.To_String (Text), "feature-panel-filter"),
              "workspace must not persist feature-panel runtime filters");
      Assert (not Contains (Ada.Strings.Unbounded.To_String (Text), "feature_panel"),
              "workspace must not persist feature_panel runtime keys");
      Remove_If_Exists (Path);
   end Test_Workspace_Persistence_Excludes_Runtime_State;

   procedure Test_Command_Palette_Post_Command_Refresh
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Hide_Feature_Panel)),
        "hide is disabled before show");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Focus_Feature_Panel)),
        "focus is disabled while hidden");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Show_Feature_Panel)),
        "show becomes disabled after show");
      Assert (Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Hide_Feature_Panel)),
        "hide becomes available after show");
      declare
         Focus_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Focus_Feature_Panel);
      begin
         Assert (Editor.Commands.Is_Available (Focus_Availability),
                 "focus becomes available after show: " &
                 Editor.Commands.Unavailable_Reason (Focus_Availability));
      end;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_Feature_Panel);
      Set_Placeholder_Rows (S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Clear_Feature_Panel)),
        "clear disabled after clear");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Feature_Panel_Open_Selected)),
        "open selected disabled after clear");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Feature_Panel_Select_Next)),
        "select next disabled after clear");
   end Test_Command_Palette_Post_Command_Refresh;


   procedure Test_Outline_Reveal_Row_Scrolls_Above_Visible_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Placeholder_Rows (Panel);
      Set_Visible_Row_Count (Panel, 2);
      Reveal_Row (Panel, 3);
      Assert (First_Visible_Row (Panel) = 2,
              "setup reveal should place row three at bottom of a two-row viewport");
      Reveal_Row (Panel, 1);
      Assert (First_Visible_Row (Panel) = 1,
              "revealing a row above the visible range should scroll upward to that row");
   end Test_Outline_Reveal_Row_Scrolls_Above_Visible_Range;

   procedure Test_Outline_Reveal_Row_Scrolls_Below_Visible_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Placeholder_Rows (Panel);
      Set_Visible_Row_Count (Panel, 2);
      Reveal_Row (Panel, 3);
      Assert (First_Visible_Row (Panel) = 2,
              "revealing row below the visible range should scroll just enough to show it");
   end Test_Outline_Reveal_Row_Scrolls_Below_Visible_Range;

   procedure Test_Outline_Reveal_Row_Leaves_Visible_Row_Unchanged
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Placeholder_Rows (Panel);
      Set_Visible_Row_Count (Panel, 2);
      Reveal_Row (Panel, 2);
      Assert (First_Visible_Row (Panel) = 1,
              "revealing an already visible row should not change the scroll offset");
   end Test_Outline_Reveal_Row_Leaves_Visible_Row_Unchanged;

   procedure Test_Outline_Reveal_Row_Rejects_Invalid_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Placeholder_Rows (Panel);
      Set_Visible_Row_Count (Panel, 2);
      Request_Reveal_Row (Panel, 2);
      Reveal_Row (Panel, 99);
      Assert (Requested_Reveal_Row (Panel) = 0,
              "invalid reveal row should clear stale pending reveal request");
      Assert (First_Visible_Row (Panel) = 1,
              "invalid reveal row should not move a valid scroll offset");
   end Test_Outline_Reveal_Row_Rejects_Invalid_Index;


   procedure Test_Generic_Projection_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Panel      : Feature_Panel_State;
      Generation : Natural := 0;
   begin
      Assert (Projection_Generation_Matches (Panel, 0),
              "unchecked generation zero is accepted for command paths");
      Generation := Projection_Generation (Panel);
      Assert (Projection_Generation_Matches (Panel, Generation),
              "current projection generation validates");
      Assert (not Projection_Row_Index_Is_Valid (Panel, 1),
              "empty panel rejects row one");
      Assert (not Reveal_Row_Index_Is_Valid (Panel, 1),
              "empty panel rejects reveal row one");

      Set_Placeholder_Rows (Panel);
      Generation := Projection_Generation (Panel);
      Assert (Projection_Row_Index_Is_Valid (Panel, 1),
              "live projection row one validates");
      Assert (Projection_Row_Index_Is_Valid (Panel, Row_Count (Panel)),
              "final live projection row validates");
      Assert (not Projection_Row_Index_Is_Valid (Panel, 0),
              "row zero is never a live projection row");
      Assert (not Projection_Row_Index_Is_Valid (Panel, Row_Count (Panel) + 1),
              "out-of-range projection row is rejected");
      Assert (Reveal_Row_Index_Is_Valid (Panel, 2),
              "reveal uses the same generic live-row guard");
      Assert (Projection_Generation_Matches (Panel, Generation),
              "unchanged rows preserve captured generation");
      Append_Row (Panel, Feature_Row_Item, "Later");
      Assert (not Projection_Generation_Matches (Panel, Generation),
              "row mutation invalidates captured generation");
   end Test_Generic_Projection_Guards;


   procedure Test_Feature_Panel_Can_Show_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show executes through the normal executor path");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "messages.show makes the generic feature panel visible");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 2,
              "messages.show projects a header plus deterministic empty row");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "Messages",
              "messages projection uses its own header label");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "messages.show does not inject synthetic source rows");
   end Test_Feature_Panel_Can_Show_Messages;

   procedure Test_Switch_Outline_To_Messages_Preserves_Outline_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Outline_Fingerprint : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before messages switch");
      Outline_Fingerprint := Editor.Outline.Fingerprint (S.Outline);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show executes after outline projection");
      Assert (Editor.Outline.Fingerprint (S.Outline) = Outline_Fingerprint,
              "switching to messages preserves accepted outline state");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "Messages",
              "active projection is rebuilt for messages");

      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) /= "Messages",
              "switching back to outline rebuilds through the outline projection path");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "switching back to outline preserves the empty messages source state");
   end Test_Switch_Outline_To_Messages_Preserves_Outline_State;

   procedure Test_Clear_Messages_Does_Not_Clear_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Outline_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before messages clear isolation test");
      Outline_Count := Editor.Outline.Item_Count (S.Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "Project opened");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show projects existing message state before clear");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.clear executes through the normal executor path");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "messages.clear removes only messages source rows");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "messages.clear does not clear accepted outline rows");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "Messages",
              "messages.clear leaves the panel showing the messages empty projection");
   end Test_Clear_Messages_Does_Not_Clear_Outline;

   procedure Test_Clear_Outline_Does_Not_Clear_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before outline clear isolation test");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "Project opened");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show projects messages state before outline clear");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline clear executes while messages state exists");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "outline.clear does not clear messages source rows");
      Assert (Editor.Outline.Item_Count (S.Outline) = 0,
              "outline.clear still clears outline source rows");
   end Test_Clear_Outline_Does_Not_Clear_Messages;

   procedure Test_Messages_Reject_Stale_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
      Generation : Natural;
   begin
      Editor.Feature_Messages.Fixtures.Set_Test_Rows (Messages, 42);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Generation := Projection_Generation (Panel);
      Assert (Editor.Feature_Messages.Validate_Row_Action
        (Messages, Panel, 2, Generation),
        "current messages projection generation accepts selectable row action");
      Clear_Rows (Panel);
      Append_Row (Panel, Feature_Row_Header, "Other", Selectable => False);
      Assert (not Editor.Feature_Messages.Validate_Row_Action
        (Messages, Panel, 2, Generation),
        "stale messages projection generation is rejected outside outline");
   end Test_Messages_Reject_Stale_Projection;

   procedure Test_Messages_Add_Projects_Severity_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "Project opened");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "File changed on disk");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "Save failed");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);

      Assert (Editor.Feature_Messages.Row_Count (Messages) = 3,
              "three messages are stored as deterministic source rows");
      Assert (Row_Label (Panel, 2) = "info: Project opened",
              "info message projects severity as row label");
      Assert (Row_Severity (Panel, 2) = Feature_Row_Info_Severity,
              "info message projects severity as row data");
      Assert (Row_Label (Panel, 3) = "warning: File changed on disk",
              "warning message projects severity as row label");
      Assert (Row_Severity (Panel, 3) = Feature_Row_Warning_Severity,
              "warning message projects severity as row data");
      Assert (Row_Label (Panel, 4) = "error: Save failed",
              "error message projects severity as row label");
      Assert (Row_Severity (Panel, 4) = Feature_Row_Error_Severity,
              "error message projects severity as row data");
      Assert (Header_Text (Panel) = "Messages: 1 error, 1 warning, 1 info",
              "messages header summarizes all severities deterministically");
   end Test_Messages_Add_Projects_Severity_Rows;

   procedure Test_Messages_Clear_Clears_Selection_And_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
      Before_Generation : Natural;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "Project opened");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Select_Row (Panel, 2);
      Before_Generation := Projection_Generation (Panel);

      Editor.Feature_Messages.Clear_Messages (Messages);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);

      Assert (Editor.Feature_Messages.Row_Count (Messages) = 0,
              "messages.clear removes all message source rows");
      Assert (Selected_Row (Panel) = 0,
              "messages.clear projection clears feature-panel selection");
      Assert (Row_Label (Panel, 2) = "No messages",
              "messages.clear rebuilds deterministic empty state");
      Assert (not Projection_Generation_Matches (Panel, Before_Generation),
              "messages.clear invalidates the previous projection generation");
   end Test_Messages_Clear_Clears_Selection_And_Projection;

   procedure Test_Messages_Click_Selects_Without_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural;
      Col    : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "main.adb", True, S.Registry_Token, 2, 2);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Click (S, 2);
      Editor.State.Row_Col_For_Index (S, S.Carets.Element (S.Carets.First_Index).Pos, Row, Col);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "message row click selects through generic row validation");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "message row click selects the clicked row");
      Assert (Row = 0 and then Col = 0,
              "message row click does not navigate the editor cursor");
   end Test_Messages_Click_Selects_Without_Navigation;

   procedure Test_Messages_Activation_With_Target_Navigates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural;
      Col    : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "main.adb", True, S.Registry_Token, 2, 2);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Activation (S, 2);
      Editor.State.Row_Col_For_Index (S, S.Carets.Element (S.Carets.First_Index).Pos, Row, Col);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "message activation with a live target executes");
      Assert (Row = 1 and then Col = 1,
              "message activation navigates to the one-based target line and column");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "successful message activation returns focus to editor text");
   end Test_Messages_Activation_With_Target_Navigates;

   procedure Test_Messages_Activation_Without_Target_Noops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "Project opened");
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "message activation without a target is a deterministic no-op");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 0,
              "no-target activation does not select or navigate implicitly");
   end Test_Messages_Activation_Without_Target_Noops;

   procedure Test_Messages_Activation_Rejects_Closed_Buffer_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "old.adb", True, S.Registry_Token + 10, 1, 1);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "message activation rejects a target that is not the live active buffer token");
   end Test_Messages_Activation_Rejects_Closed_Buffer_Target;

   procedure Test_Messages_Buffer_Close_Removes_Targeted_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "Project opened");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "main.adb", True, 42, 1, 1);
      Editor.Feature_Messages.Reset_For_Buffer_Close (Messages, 42);

      Assert (Editor.Feature_Messages.Row_Count (Messages) = 1,
              "buffer close removes messages targeting the closed buffer only");
      Assert (Editor.Feature_Messages.Item_Text (Messages, 1) = "Project opened",
              "untargeted session message survives targeted buffer close cleanup");
   end Test_Messages_Buffer_Close_Removes_Targeted_Messages;

   procedure Test_Feature_Panel_Switch_Outline_Messages_Preserves_Both_States
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Outline_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before mixed feature switch test");
      Outline_Count := Editor.Outline.Item_Count (S.Outline);

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message,
         "File changed on disk");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show executes during mixed feature switch test");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "messages source rows survive switching to messages projection");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "outline source rows survive switching to messages projection");

      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "messages source rows survive switching back to outline projection");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "outline source rows survive switching back from messages projection");
   end Test_Feature_Panel_Switch_Outline_Messages_Preserves_Both_States;

   procedure Test_Messages_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Show_Messages) = "show-messages",
        "messages.show stable command id remains kebab-case");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Show_Messages),
        "messages.show is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Clear_Messages),
        "messages.clear is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Toggle_Message_Info),
        "messages.toggle-info is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Toggle_Message_Warnings),
        "messages.toggle-warnings is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Toggle_Message_Errors),
        "messages.toggle-errors is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Show_All_Messages),
        "messages.show-all is command-palette visible");
      Assert (Editor.Commands.Is_Visible_In_Palette
        (Editor.Commands.Command_Clear_Message_Filter),
        "messages.clear-filter is command-palette visible");
      Editor.Keybindings.Reset_To_Defaults;
      Assert (not Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Show_Messages).Has_Binding,
        "messages.show has no default keybinding in the scaffold phase");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("clear-messages", Found);
      Assert (Found and then Id = Editor.Commands.Command_Clear_Messages,
              "messages.clear stable name round trips through command registry");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("toggle-message-info", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Message_Info,
              "messages.toggle-info stable name round trips through command registry");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("show-all-messages", Found);
      Assert (Found and then Id = Editor.Commands.Command_Show_All_Messages,
              "messages.show-all stable name round trips through command registry");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("clear-message-filter", Found);
      Assert (Found and then Id = Editor.Commands.Command_Clear_Message_Filter,
              "messages.clear-filter stable name round trips through command registry");
   end Test_Messages_Command_Metadata;


   procedure Test_Messages_Filter_Matches_Text_And_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message,
         "Project opened", "main.adb");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "disk");

      Editor.Feature_Messages.Set_Filter_Text (Messages, "SAVE");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 1,
              "messages text filter is case-insensitive and projection-only");
      Assert (Row_Count (Panel) = 2,
              "filtered messages projection contains header plus one visible row");
      Assert (Row_Source_Index (Panel, 2) = 2,
              "text filter maps visible row to original source row");

      Editor.Feature_Messages.Set_Filter_Text (Messages, "main");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (Row_Source_Index (Panel, 2) = 1,
              "messages text filter matches source labels");
      Assert (Editor.Feature_Messages.Row_Count (Messages) = 2,
              "messages filtering does not mutate source rows");
   end Test_Messages_Filter_Matches_Text_And_Source;

   procedure Test_Messages_Filter_Matches_Severity_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "Alpha");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "Beta");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "Gamma");
      Editor.Feature_Messages.Set_Filter_Text (Messages, "warning");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);

      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 1,
              "messages filter matches severity display text");
      Assert (Row_Source_Index (Panel, 2) = 2,
              "severity text match preserves source-row mapping");
   end Test_Messages_Filter_Matches_Severity_Text;

   procedure Test_Messages_Severity_Toggles_Compose_With_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "save complete");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "save warning");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "save failed");
      Editor.Feature_Messages.Toggle_Warnings (Messages);
      Editor.Feature_Messages.Set_Filter_Text (Messages, "save");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);

      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 2,
              "messages text and severity filters compose with AND semantics");
      Assert (Row_Source_Index (Panel, 2) = 1 and then Row_Source_Index (Panel, 3) = 3,
              "severity-filtered projection preserves insertion order of visible rows");
      Assert (Row_Severity (Panel, 2) = Feature_Row_Info_Severity,
              "projected info row carries generic severity data");
      Assert (Row_Severity (Panel, 3) = Feature_Row_Error_Severity,
              "projected error row carries generic severity data");
   end Test_Messages_Severity_Toggles_Compose_With_Text;

   procedure Test_Messages_Filter_Reconciles_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "first");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "second");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "third");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Select_Row (Panel, 3);

      Editor.Feature_Messages.Toggle_Info (Messages);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (Selected_Row (Panel) = 2 and then Row_Source_Index (Panel, 2) = 2,
              "filtering preserves selected message id when it remains visible");

      Editor.Feature_Messages.Toggle_Warnings (Messages);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (Selected_Row (Panel) = 2 and then Row_Source_Index (Panel, 2) = 3,
              "filtering selects first visible row when previous selection is hidden");

      Editor.Feature_Messages.Toggle_Errors (Messages);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (Selected_Row (Panel) = 0,
              "filtering with no visible rows clears visible selection");
   end Test_Messages_Filter_Reconciles_Selection;

   procedure Test_Messages_Clear_Filter_And_Workspace_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "info");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "error");
      Editor.Feature_Messages.Toggle_Info (Messages);
      Editor.Feature_Messages.Set_Filter_Text (Messages, "error");
      Assert (Editor.Feature_Messages.Filter_Is_Active (Messages),
              "messages filter reports active text/severity state");
      Editor.Feature_Messages.Clear_Filter (Messages);
      Assert (not Editor.Feature_Messages.Filter_Is_Active (Messages),
              "messages.clear-filter restores all severities and clears text");
      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 2,
              "messages.clear-filter restores all rows to the visible projection model");

      Editor.Feature_Messages.Toggle_Info (Messages);
      Editor.Feature_Messages.Reset_For_Workspace_Close (Messages);
      Assert (Editor.Feature_Messages.Row_Count (Messages) = 0,
              "workspace close clears messages source rows");
      Assert (not Editor.Feature_Messages.Filter_Is_Active (Messages),
              "workspace close clears messages filter state");
   end Test_Messages_Clear_Filter_And_Workspace_Close;

   procedure Test_Messages_Filtered_Activation_Rejects_Stale_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages   : Editor.Feature_Messages.Message_Feature_State;
      Panel      : Feature_Panel_State;
      Generation : Natural;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "visible",
         "main.adb", True, 42, 1, 1);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Generation := Projection_Generation (Panel);
      Editor.Feature_Messages.Toggle_Info (Messages);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Assert (not Editor.Feature_Messages.Validate_Row_Action
        (Messages, Panel, 2, Generation),
        "filtered messages activation rejects stale projection generations");
   end Test_Messages_Filtered_Activation_Rejects_Stale_Projection;

   procedure Test_Messages_Filter_Commands_Do_Not_Affect_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Outline_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before messages filter isolation test");
      Outline_Count := Editor.Outline.Item_Count (S.Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message, "Project opened");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Toggle_Message_Info);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages severity toggle executes through command registry");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "messages filter commands do not mutate outline source rows");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_All_Messages);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "messages.show-all executes through command registry");
      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "messages.show-all does not mutate outline state");
   end Test_Messages_Filter_Commands_Do_Not_Affect_Outline;


   procedure Test_Messages_Source_Kind_And_Target_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages    => Messages,
         Severity    => Editor.Feature_Messages.Warning_Message,
         Text        => "File changed on disk — main.adb",
         Source      => "main.adb",
         Has_Target  => True,
         Buffer      => 42,
         Line        => 5,
         Column      => 3,
         Source_Kind => Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Add_Message
        (Messages    => Messages,
         Severity    => Editor.Feature_Messages.Error_Message,
         Text        => "Save failed — bad.adb",
         Source      => "bad.adb",
         Has_Target  => True,
         Buffer      => 42,
         Line        => 0,
         Column      => 3,
         Source_Kind => Editor.Feature_Messages.File_Source);

      Assert (Editor.Feature_Messages.Item_Source_Kind (Messages, 1) =
              Editor.Feature_Messages.File_Source,
              "message source kind is stored as data, not only free-form text");
      Assert (Editor.Feature_Messages.Item_Has_Target (Messages, 1),
              "valid targeted message keeps target metadata");
      Assert (not Editor.Feature_Messages.Item_Has_Target (Messages, 2),
              "invalid one-based target line is stored as non-activatable message row");
   end Test_Messages_Source_Kind_And_Target_Validation;

   procedure Test_Messages_Max_Retention_Evicts_Oldest_And_Keeps_Ids
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Limit    : constant Natural := Editor.Feature_Messages.Max_Retained_Messages;
   begin
      for I in 1 .. Limit + 1 loop
         Editor.Feature_Messages.Add_Message
           (Messages,
            Editor.Feature_Messages.Info_Message,
            "message " & Natural'Image (I),
            Source_Kind => Editor.Feature_Messages.Editor_Source);
      end loop;

      Assert (Editor.Feature_Messages.Row_Count (Messages) = Limit,
              "bounded retention keeps only the configured session-local maximum");
      Assert (Editor.Feature_Messages.Item_Id (Messages, 1) =
              Editor.Feature_Messages.Message_Id (2),
              "retention evicts the oldest row instead of reusing or rewriting ids");
      Assert (Editor.Feature_Messages.Item_Id (Messages, Limit) =
              Editor.Feature_Messages.Message_Id (Limit + 1),
              "new rows keep monotonically increasing ids after eviction");
   end Test_Messages_Max_Retention_Evicts_Oldest_And_Keeps_Ids;

   procedure Test_Messages_Deduplicates_Adjacent_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message,
         "Save failed — main.adb", "main.adb",
         Source_Kind => Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message,
         "Save failed — main.adb", "main.adb",
         Source_Kind => Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message,
         "Project closed", "project",
         Source_Kind => Editor.Feature_Messages.Project_Source);
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message,
         "Save failed — main.adb", "main.adb",
         Source_Kind => Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Project_Rows (Messages, Panel);

      Assert (Editor.Feature_Messages.Row_Count (Messages) = 3,
              "adjacent identical messages deduplicate without scanning unrelated history");
      Assert (Editor.Feature_Messages.Item_Repeat_Count (Messages, 1) = 2,
              "adjacent duplicate increments repeat count on the retained row");
      Assert (Editor.Feature_Messages.Item_Repeat_Count (Messages, 3) = 1,
              "nonadjacent repeated message is not merged with old history");
      Assert (Row_Label (Panel, 2) = "error: Save failed — main.adb (x2)",
              "projection displays repeat count only for repeated adjacent messages");
   end Test_Messages_Deduplicates_Adjacent_Only;

   procedure Test_Post_Message_Preserves_Filter_And_Reprojects_When_Active
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Set_Filter_Text (S.Feature_Messages, "save");
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Editor.Message_Producers.Post_Message
        (S,
         Editor.Feature_Messages.Error_Message,
         "Save failed — main.adb",
         "main.adb",
         Editor.Feature_Messages.File_Source);

      Assert (Editor.Feature_Messages.Filter_Is_Active (S.Feature_Messages),
              "posting a message preserves current Messages filter state");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 2) =
              "error: Save failed — main.adb",
              "producer reprojects the Messages panel when it is already active");
      Assert (Editor.Feature_Messages.Visible_Row_Count (S.Feature_Messages) = 1,
              "posted message participates in the current filtered projection");
   end Test_Post_Message_Preserves_Filter_And_Reprojects_When_Active;


   procedure Test_Save_As_Does_Not_Post_Secondary_Feature_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Path   : constant String := Temp_Path ("save_as.txt");
   begin
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello");
      Cmd.Kind := Editor.Commands.Save_File_As;
      Cmd.Path := Ada.Strings.Unbounded.To_Unbounded_String (Path);

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "Save As success must not post a secondary feature-message row");
      Remove_If_Exists (Path);
   end Test_Save_As_Does_Not_Post_Secondary_Feature_Message;

   procedure Test_Message_Producer_Does_Not_Affect_Outline_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Result        : Editor.Executor.Command_Execution_Result;
      Outline_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "outline refresh executes before producer isolation test");
      Outline_Count := Editor.Outline.Item_Count (S.Outline);

      Editor.Message_Producers.Post_Message
        (S,
         Editor.Feature_Messages.Info_Message,
         "Project closed",
         "project",
         Editor.Feature_Messages.Project_Source);

      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "Messages producer does not mutate accepted outline rows");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "Messages producer appends only Messages source rows");
   end Test_Message_Producer_Does_Not_Affect_Outline_State;


   procedure Test_Messages_Clear_Selected_Reconciles_To_Next
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message, "first", "a.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message, "second", "b.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message, "third", "c.adb");
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 3);

      Assert
        (Editor.Feature_Messages.Clear_Selected_Message
           (S.Feature_Messages, S.Feature_Panel),
         "clear-selected must remove a live selected message");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 2,
              "clear-selected removes exactly one source row");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 3,
              "clear-selected prefers the next visible row after deletion");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 3) = "error: third",
              "selection must land on the former next message row");
   end Test_Messages_Clear_Selected_Reconciles_To_Next;

   procedure Test_Messages_Clear_Selected_Reconciles_To_Previous
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message, "first", "a.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message, "second", "b.adb");
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 3);

      Assert
        (Editor.Feature_Messages.Clear_Selected_Message
           (S.Feature_Messages, S.Feature_Panel),
         "clear-selected must remove the selected final row");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "clear-selected falls back to previous visible row when no next row exists");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 2) = "info: first",
              "previous fallback must select the remaining message row");
   end Test_Messages_Clear_Selected_Reconciles_To_Previous;

   procedure Test_Messages_Clear_By_Severity_Preserves_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Removed : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message, "saved", "main.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message, "changed", "main.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message, "failed", "main.adb");
      Editor.Feature_Messages.Set_Filter_Text (S.Feature_Messages, "main");
      Editor.Feature_Messages.Toggle_Info (S.Feature_Messages);

      Removed := Editor.Feature_Messages.Clear_Messages_By_Severity
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message);

      Assert (Removed = 1, "clear-warnings helper removes warning rows only");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 2,
              "clear-warnings preserves non-warning source rows");
      Assert (not Editor.Feature_Messages.Severity_Is_Visible
                (S.Feature_Messages, Editor.Feature_Messages.Info_Message),
              "clear-warnings preserves severity visibility filters");
      Assert (Editor.Feature_Messages.Filter_Is_Active (S.Feature_Messages),
              "clear-warnings preserves active text/severity filter state");
   end Test_Messages_Clear_By_Severity_Preserves_Filter;

   procedure Test_Messages_Copy_Text_And_Action_Flags
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message,
         "File changed on disk", "main.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Warning_Message,
         "File changed on disk", "main.adb");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "main.adb", True, S.Registry_Token, 1, 1,
         Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Assert (Editor.Feature_Panel.Row_Can_Copy (S.Feature_Panel, 2),
              "normal Messages row declares copy affordance");
      Assert (Editor.Feature_Panel.Row_Can_Clear (S.Feature_Panel, 2),
              "normal Messages row declares clear affordance");
      Assert (not Editor.Feature_Panel.Row_Can_Open (S.Feature_Panel, 2),
              "untargeted Messages row cannot open");
      Assert (Editor.Feature_Panel.Row_Can_Open (S.Feature_Panel, 3),
              "targeted Messages row declares open affordance");

      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Assert
        (Editor.Feature_Messages.Selected_Message_Text
           (S.Feature_Messages, S.Feature_Panel) =
         "warning: File changed on disk — main.adb (x2)",
         "selected message copy text includes severity, source, and repeat count");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Copy_Selected_Message_Text);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "copy-selected command executes for selected Messages row");
      Assert (Editor.Clipboard.Get_Text =
                Ada.Strings.Unbounded.To_Unbounded_String ("warning: File changed on disk — main.adb (x2)"),
              "copy-selected command writes deterministic plain text to clipboard");
   end Test_Messages_Copy_Text_And_Action_Flags;

   procedure Test_Messages_Action_Commands_Do_Not_Affect_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure Main is" & ASCII.LF & "begin" & ASCII.LF & "   null;" & ASCII.LF & "end Main;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Outline_Count := Editor.Outline.Item_Count (S.Outline);

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message, "failed", "main.adb");
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Selected_Message);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Error_Messages);

      Assert (Editor.Outline.Item_Count (S.Outline) = Outline_Count,
              "Messages action commands must not mutate outline source rows");
   end Test_Messages_Action_Commands_Do_Not_Affect_Outline;



   procedure Test_Messages_Filter_Delete_Post_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Info_Message, "open", "editor");
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "save failed", "main.adb");
      Editor.Feature_Messages.Set_Filter_Text (Messages, "save");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Select_Row (Panel, 2);

      Assert (Editor.Feature_Messages.Clear_Selected_Message (Messages, Panel),
              "clear-selected removes the filtered visible message");
      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 0,
              "deleting the only matching row leaves no visible matches");
      Assert (Selected_Row (Panel) = 0,
              "deletion reconciles filtered selection to empty");

      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "save retry queued", "main.adb");
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change (Messages, Panel);
      Assert (Editor.Feature_Messages.Visible_Row_Count (Messages) = 1,
              "posted rows compose with the existing text filter");
      Assert (Row_Label (Panel, 2) = "warning: save retry queued",
              "projection rebuilds from current source rows after post");
      Editor.Feature_Messages.Assert_Messages_State_Consistent (Messages);
      Editor.Feature_Messages.Assert_Messages_Projection_Consistent (Messages, Panel);
   end Test_Messages_Filter_Delete_Post_Rebuilds_Projection;

   procedure Test_Messages_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Error_Message, "save failed", "main.adb",
         True, 42, 2, 1, Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Add_Message
        (Messages, Editor.Feature_Messages.Warning_Message, "save warning", "other.adb",
         True, 77, 1, 1, Editor.Feature_Messages.File_Source);
      Editor.Feature_Messages.Set_Filter_Text (Messages, "save");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Select_Row (Panel, 2);

      Editor.Feature_Messages.Reset_For_Buffer_Close (Messages, 42);
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change (Messages, Panel);
      Assert (Editor.Feature_Messages.Row_Count (Messages) = 1,
              "buffer close removes only targeted rows for the closing buffer");
      Assert (Editor.Feature_Messages.Item_Target_Buffer (Messages, 1) = 77,
              "unrelated targeted message survives buffer close");
      Assert (Row_Source_Index (Panel, 2) = 1,
              "projection is rebuilt against surviving source rows");
      Editor.Feature_Messages.Assert_Messages_Projection_Consistent (Messages, Panel);
   end Test_Messages_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows;

   procedure Test_Feature_Panel_Reveal_Rejects_Cross_Feature_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Row_Count (S.Feature_Panel) >= 2,
              "outline projection exists before cross-feature validation");
      Assert (Row_Label (S.Feature_Panel, 1) /= "Messages",
              "active projection is Outline, not Messages");
      Assert (not Editor.Feature_Messages.Validate_Row_Action
        (S.Feature_Messages, S.Feature_Panel, 2, 0),
        "Messages validation rejects rows from an Outline projection");
   end Test_Feature_Panel_Reveal_Rejects_Cross_Feature_Token;

   procedure Test_Messages_Workspace_Close_After_Many_Operations_Clears_All_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Messages : Editor.Feature_Messages.Message_Feature_State;
      Panel    : Feature_Panel_State;
      Limit    : constant Natural := Editor.Feature_Messages.Max_Retained_Messages;
   begin
      for I in 1 .. Limit + 5 loop
         Editor.Feature_Messages.Add_Message
           (Messages, Editor.Feature_Messages.Info_Message,
            "message" & Natural'Image (I), Source_Kind => Editor.Feature_Messages.Editor_Source);
      end loop;
      Editor.Feature_Messages.Toggle_Info (Messages);
      Editor.Feature_Messages.Set_Filter_Text (Messages, "message");
      Editor.Feature_Messages.Project_Rows (Messages, Panel);
      Editor.Feature_Messages.Reset_For_Workspace_Close (Messages);
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change (Messages, Panel);

      Assert (Editor.Feature_Messages.Row_Count (Messages) = 0,
              "workspace close clears all retained message rows");
      Assert (not Editor.Feature_Messages.Filter_Is_Active (Messages),
              "workspace close clears text and severity filters");
      Assert (Selected_Row (Panel) = 0,
              "workspace close clears projected selection");
      Assert (Row_Label (Panel, 2) = "No messages",
              "workspace close rebuilds deterministic empty projection");
   end Test_Messages_Workspace_Close_After_Many_Operations_Clears_All_State;


   procedure Test_Feature_Descriptor_Table_Has_Deterministic_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Feature_Descriptor_Count = 4,
              "descriptor table contains Outline, Messages, Search Results, and Diagnostics");
      Assert (Descriptor_Id (1) = Outline_Feature,
              "descriptor order starts with Outline");
      Assert (Descriptor_Id (2) = Messages_Feature,
              "descriptor order then lists Messages");
      Assert (Descriptor_Id (3) = Search_Results_Feature,
              "descriptor order appends Search Results without reordering existing features");
      Assert (Feature_Stable_Name (Outline_Feature) = "outline",
              "outline stable feature name is deterministic");
      Assert (Feature_Display_Label (Messages_Feature) = "Messages",
              "messages display label is deterministic");
      Assert (Feature_Stable_Name (Search_Results_Feature) = "search-results",
              "search results stable feature name is deterministic");
      Assert (Feature_Display_Label (Search_Results_Feature) = "Search Results",
              "search results display label is deterministic");
   end Test_Feature_Descriptor_Table_Has_Deterministic_Order;

   procedure Test_Feature_Descriptor_Table_Rejects_Unknown_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Assert (not Is_Known_Feature (Unknown_Feature),
              "unknown feature sentinel is not a known feature");
      Assert (not Set_Active_Feature (Panel, Unknown_Feature),
              "active feature rejects unknown feature id");
      Assert (Active_Feature (Panel) = Outline_Feature,
              "failed switch preserves known default active feature");
   end Test_Feature_Descriptor_Table_Rejects_Unknown_Feature;

   procedure Test_Feature_Switch_To_Outline_Uses_Outline_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Outline_Feature),
        "show outline succeeds through centralized feature switch");
      Assert (Active_Feature (S.Feature_Panel) = Outline_Feature,
              "active feature is Outline after switch");
      Assert (Row_Count (S.Feature_Panel) >= 2,
              "outline provider rebuilt projected rows");
      Assert (Row_Label (S.Feature_Panel, 1) /= "Messages",
              "outline projection does not use Messages header");
   end Test_Feature_Switch_To_Outline_Uses_Outline_Projection;

   procedure Test_Feature_Switch_To_Messages_Uses_Messages_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "hello", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
        (S, Messages_Feature),
        "show messages succeeds through centralized feature switch");
      Assert (Active_Feature (S.Feature_Panel) = Messages_Feature,
              "active feature is Messages after switch");
      Assert (Row_Label (S.Feature_Panel, 1) = "Messages",
              "messages provider rebuilt projected rows");
   end Test_Feature_Switch_To_Messages_Uses_Messages_Projection;

   procedure Test_Feature_Switch_Invalidates_Previous_Feature_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Outline_Token : Feature_Projection_Token;
   begin
      Editor.State.Init (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "initial outline switch succeeds");
      Outline_Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "switch to messages succeeds");
      Assert (not Validate_Feature_Projection_Token (S.Feature_Panel, Outline_Token),
              "switching features invalidates previous feature token");
   end Test_Feature_Switch_Invalidates_Previous_Feature_Token;

   procedure Test_Feature_Projection_Token_Includes_Feature_Id
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Token : Feature_Projection_Token;
   begin
      Assert (Set_Active_Feature (Panel, Messages_Feature),
              "can set messages active feature");
      Token := Build_Feature_Projection_Token (Panel);
      Assert (Token.Feature = Messages_Feature,
              "projection token carries active feature id");
      Assert (Token.Generation = Projection_Generation (Panel),
              "projection token carries projection generation");
   end Test_Feature_Projection_Token_Includes_Feature_Id;

   procedure Test_Feature_Reveal_Rejects_Cross_Feature_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Token : Feature_Projection_Token;
   begin
      Assert (Set_Active_Feature (Panel, Outline_Feature),
              "can set outline active feature");
      Append_Row (Panel, Feature_Row_Item, "row");
      Token := Build_Feature_Projection_Token (Panel);
      Assert (Set_Active_Feature (Panel, Messages_Feature),
              "can switch to messages active feature");
      Request_Reveal_Row (Panel, Token, 1);
      Assert (Requested_Reveal_Row (Panel) = 0,
              "reveal rejects token from another feature");
   end Test_Feature_Reveal_Rejects_Cross_Feature_Token;

   procedure Test_Feature_Action_Rejects_Cross_Feature_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Token : Feature_Projection_Token;
   begin
      Assert (Set_Active_Feature (Panel, Outline_Feature),
              "can set outline active feature");
      Token := Build_Feature_Projection_Token (Panel);
      Assert (Set_Active_Feature (Panel, Messages_Feature),
              "can switch to messages active feature");
      Assert (not Projection_Token_Matches (Panel, Token),
              "action validation rejects cross-feature token");
   end Test_Feature_Action_Rejects_Cross_Feature_Token;

   procedure Test_Feature_Lifecycle_Project_Close_Dispatches_To_All_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "hello", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "demo", True, S.Registry_Token, 1, 1);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);
      Assert (not Editor.Outline.Has_Items (S.Outline),
              "project close lifecycle dispatcher resets Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "project close lifecycle dispatcher resets Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "project close lifecycle dispatcher resets Search Results");
      Assert (Row_Count (S.Feature_Panel) = 0,
              "project close invalidates projected rows");
   end Test_Feature_Lifecycle_Project_Close_Dispatches_To_All_Features;

   procedure Test_Feature_Command_Clear_Active_Delegates_To_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "hello", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "can show messages before clear-active");
      Assert (Editor.Feature_Panel_Controller.Dispatch_Active_Feature_Clear (S),
              "generic clear dispatches to active feature");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "clear-active-feature clears Messages source state");
      Assert (Row_Label (S.Feature_Panel, 1) = "Messages",
              "clear-active-feature rebuilds active feature projection");
   end Test_Feature_Command_Clear_Active_Delegates_To_Active_Feature;


   procedure Test_Search_Results_Show_And_Clear_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit one", "demo", True, S.Registry_Token, 1, 1);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit two", "demo", False);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Show_Search_Results_Feature);
      Assert (Active_Feature (S.Feature_Panel) = Search_Results_Feature,
              "search results show switches active feature");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "search results projection contains only search rows");
      Assert (Row_Label (S.Feature_Panel, 1) = "hit one"
        and then Row_Label (S.Feature_Panel, 2) = "hit two",
              "search results projection preserves insertion order");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "showing search results does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "showing search results does not mutate Messages");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Clear_Search_Results_Feature);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "search results clear removes source rows");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "clearing search results does not clear Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "clearing search results does not clear Messages");
   end Test_Search_Results_Show_And_Clear_Isolated;

   procedure Test_Search_Results_Projection_Token_And_Activation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Token : Feature_Projection_Token;
      Stale_Generation : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "live", "buffer", True, S.Registry_Token, 2, 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
              "can show Search Results through centralized switch");
      Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Assert (Token.Feature = Search_Results_Feature,
              "search results projection token carries search feature id");
      Stale_Generation := Projection_Generation (S.Feature_Panel);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "second", "buffer", False);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Assert (Editor.Feature_Search_Results.Map_Search_Result_Row_To_Item
        (S.Feature_Search_Results, S.Feature_Panel, 1, Stale_Generation) = 0,
              "search results reject stale projection generation");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "targeted search result activation navigates through shared editor path");
      Assert (not Is_Focused (S.Feature_Panel),
              "successful search result activation returns focus to editor");
   end Test_Search_Results_Projection_Token_And_Activation;

   procedure Test_Search_Results_Rejects_Cross_Feature_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Search_Token : Feature_Projection_Token;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "demo", False);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
              "show search results succeeds");
      Search_Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "switch to messages succeeds");
      Request_Reveal_Row (S.Feature_Panel, Search_Token, 1);
      Assert (Requested_Reveal_Row (S.Feature_Panel) = 0,
              "reveal rejects search token while messages is active");
      Assert (not Projection_Token_Matches (S.Feature_Panel, Search_Token),
              "action validation rejects search token while messages is active");
   end Test_Search_Results_Rejects_Cross_Feature_Token;

   procedure Test_Clear_Active_Delegates_To_Search_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "demo", False);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
              "can show search results before clear-active");
      Assert (Editor.Feature_Panel_Controller.Dispatch_Active_Feature_Clear (S),
              "generic clear dispatches to Search Results");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "clear-active-feature clears Search Results source state");
      Assert (Row_Label (S.Feature_Panel, 1) = "No search results.",
              "clear-active-feature rebuilds search empty projection");
   end Test_Clear_Active_Delegates_To_Search_Results;

   procedure Test_Search_Active_Buffer_Finds_Ordered_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Refresh refresh" & ASCII.LF & "no hit" & ASCII.LF & "REFRESH" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "refresh");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);

      Assert (Active_Feature (S.Feature_Panel) = Search_Results_Feature,
              "active-buffer search switches to Search Results feature");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 3,
              "active-buffer search finds every case-insensitive match");
      Assert (Editor.Feature_Search_Results.Item_Match_Line (S.Feature_Search_Results, 1) = 1
        and then Editor.Feature_Search_Results.Item_Match_Column (S.Feature_Search_Results, 1) = 1
        and then Editor.Feature_Search_Results.Item_Match_Line (S.Feature_Search_Results, 2) = 1
        and then Editor.Feature_Search_Results.Item_Match_Column (S.Feature_Search_Results, 2) = 9
        and then Editor.Feature_Search_Results.Item_Match_Line (S.Feature_Search_Results, 3) = 3
        and then Editor.Feature_Search_Results.Item_Match_Column (S.Feature_Search_Results, 3) = 1,
              "active-buffer search preserves line/column order and multiple matches per line");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "active-buffer search selects first result");
   end Test_Search_Active_Buffer_Finds_Ordered_Matches;

   procedure Test_Search_Active_Buffer_Zero_Matches_Replaces_Previous
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "setup found initial result");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "missing");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "zero-match search replaces and clears previous rows");
      Assert (Editor.Feature_Search_Results.Has_Query (S.Feature_Search_Results),
              "zero-match state retains producing query");
      Assert (Header_Text (S.Feature_Panel) = "Search Results: no matches for ""missing""",
              "zero-match projection has deterministic header");
   end Test_Search_Active_Buffer_Zero_Matches_Replaces_Previous;

   procedure Test_Search_Activation_And_Stale_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "target here" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "target");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "search result activation navigates to live target");
      Assert (not Is_Focused (S.Feature_Panel),
              "search result activation returns focus to editor");

      Editor.State.Replace_Buffer_Contents
        (S, "one" & ASCII.LF & "changed target here" & ASCII.LF);
      Editor.Feature_Search_Results.Mark_Stale_For_Buffer_Change
        (S.Feature_Search_Results, S.Registry_Token, Editor.State.Current_Buffer_Revision (S));
      Assert (Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "searched-buffer edit marks active-buffer results stale");
   end Test_Search_Activation_And_Stale_State;

   procedure Test_Search_Results_Do_Not_Mutate_Outline_Or_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "refresh" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "refresh");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);

      Assert (Editor.Outline.Has_Items (S.Outline),
              "active-buffer search does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "active-buffer search does not mutate Messages");
   end Test_Search_Results_Do_Not_Mutate_Outline_Or_Messages;



   procedure Test_Search_Query_Input_And_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Results : Editor.Feature_Search_Results.Search_Results_Feature_State;
   begin
      Editor.Feature_Search_Results.Activate_Search_Query_Input (Results);
      Assert (Editor.Feature_Search_Results.Search_Input_Is_Active (Results),
              "search query input activates explicitly");
      Editor.Feature_Search_Results.Insert_Search_Input_Character (Results, 'n');
      Editor.Feature_Search_Results.Insert_Search_Input_Character (Results, 'e');
      Editor.Feature_Search_Results.Insert_Search_Input_Character (Results, 'e');
      Editor.Feature_Search_Results.Insert_Search_Input_Character (Results, 'd');
      Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward (Results);
      Assert (Editor.Feature_Search_Results.Search_Input_Text (Results) = "nee",
              "backspace edits query input rather than editor buffer text");
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (Results, "alpha");
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (Results, "beta");
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (Results, "alpha");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count (Results) = 2,
              "query history deduplicates executed queries");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Item (Results, 2) = "alpha",
              "duplicate query moves to most recent history slot");
      Editor.Feature_Search_Results.Select_Previous_Search_Query (Results);
      Assert (Editor.Feature_Search_Results.Search_Input_Text (Results) = "alpha",
              "history previous loads the most recent query into input text");
   end Test_Search_Query_Input_And_History;

   procedure Test_Search_Query_Input_Does_Not_Edit_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "buffer text" & ASCII.LF);
      Before := To_Unbounded_String (Editor.State.Current_Text (S));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Focus_Query);
      Editor.Feature_Search_Results.Insert_Search_Input_Character
        (S.Feature_Search_Results, 'x');
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Assert (Editor.State.Current_Text (S) = To_String (Before),
              "direct query input editing must not mutate active buffer contents");
      Assert (Editor.Feature_Search_Results.Search_Input_Text (S.Feature_Search_Results) = "x",
              "query input owns printable text while active");
   end Test_Search_Query_Input_Does_Not_Edit_Buffer;

   procedure Test_Repeat_Uses_Last_Query_And_Clears_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package alpha" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF &
         "beta" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "repeat setup found one result");
      Editor.State.Replace_Buffer_Contents (S, "alpha" & ASCII.LF & "alpha" & ASCII.LF);
      Assert (Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "buffer edits mark previous active-buffer search results stale");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Repeat_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "repeat reruns last query against current active buffer");
      Assert (not Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "repeat replaces stale rows and clears stale state");
   end Test_Repeat_Uses_Last_Query_And_Clears_Stale;

   procedure Test_Repeat_Preserves_Selection_When_Possible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hit" & ASCII.LF & "hit" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "hit");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Repeat_Active_Buffer);
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "repeat preserves the same selected match when it still exists");
   end Test_Repeat_Preserves_Selection_When_Possible;

   procedure Test_Case_Sensitive_Mode_Is_Optional_And_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Results : Editor.Feature_Search_Results.Search_Results_Feature_State;
   begin
      Editor.Feature_Search_Results.Toggle_Case_Sensitive (Results);
      Assert (Editor.Feature_Search_Results.Case_Sensitive (Results),
              "case-sensitive toggle flips only Search Results state");
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (Results, "Refresh", "Refresh" & ASCII.LF & "refresh" & ASCII.LF,
         "buffer", 1, 1, Editor.Feature_Search_Results.Case_Sensitive (Results));
      Assert (Editor.Feature_Search_Results.Row_Count (Results) = 1,
              "case-sensitive search does not widen matching scope");
      Assert (Editor.Feature_Search_Results.Header_Text (Results) =
              "Search Results: case-sensitive - 1 match for ""Refresh""",
              "header exposes case-sensitive mode without internal ids");
   end Test_Case_Sensitive_Mode_Is_Optional_And_Visible;


   procedure Test_Search_Result_Context_Truncation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Near_Start : constant String :=
        Editor.Feature_Search_Results.Truncate_Search_Result_Context
          ("   Refresh (State); followed by a deliberately long suffix for testing",
           4, 7, 32);
      Near_Middle : constant String :=
        Editor.Feature_Search_Results.Truncate_Search_Result_Context
          ("prefix prefix prefix prefix Refresh (State) suffix suffix suffix suffix",
           29, 7, 32);
      Near_End : constant String :=
        Editor.Feature_Search_Results.Truncate_Search_Result_Context
          ("prefix prefix prefix prefix suffix suffix suffix Refresh",
           49, 7, 32);
   begin
      Assert (Editor.Feature_Search_Results.Build_Search_Result_Context
        ("   procedure Refresh   ", 14, 7) = "procedure Refresh",
              "short search context trims surrounding whitespace");
      Assert (Near_Start (Near_Start'Last - 2 .. Near_Start'Last) = "...",
              "long context near start keeps prefix and adds trailing ellipsis");
      Assert (Near_Middle (Near_Middle'First .. Near_Middle'First + 2) = "..."
        and then Near_Middle (Near_Middle'Last - 2 .. Near_Middle'Last) = "...",
              "long context near middle has leading and trailing ellipses");
      Assert (Near_End (Near_End'First .. Near_End'First + 2) = "...",
              "long context near end keeps suffix with leading ellipsis");
   end Test_Search_Result_Context_Truncation;

   procedure Test_Search_Projection_Uses_Bounded_Context_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "removed label",
         Source_Label  => "main.adb",
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 42,
         Target_Column => 11,
         Query         => "Refresh",
         Line_Text     => "   procedure Refresh (State : in out Model);   ",
         Match_Line    => 42,
         Match_Column  => 14,
         Match_Length  => 7);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Assert (Row_Label (S.Feature_Panel, 1) =
        "main.adb:42: procedure Refresh (State : in out Model);",
              "projection derives compact context label without mutating source metadata");
      Assert (Editor.Feature_Search_Results.Item_Target_Column
        (S.Feature_Search_Results, 1) = 11,
              "projected context must not alter target column metadata");
      Assert (Editor.Feature_Search_Results.Format_Search_Result_For_Copy
        (S.Feature_Search_Results, 1) = Row_Label (S.Feature_Panel, 1),
              "copy formatter uses the same stable search-result context label");
   end Test_Search_Projection_Uses_Bounded_Context_Label;

   procedure Test_Search_Rerun_Same_Query_Preserves_Selected_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hit" & ASCII.LF & "hit" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "hit");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Selected_Row (S.Feature_Panel) = 2,
              "explicit rerun of same active-buffer query preserves selected match identity");
   end Test_Search_Rerun_Same_Query_Preserves_Selected_Match;

   procedure Test_Search_Rerun_Different_Query_Selects_First
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "beta" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "beta");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "different query selects the first new result by default");
   end Test_Search_Rerun_Different_Query_Selects_First;

   procedure Test_Search_Activation_Rejects_Invalid_Stale_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "missing", "buffer", True,
         S.Registry_Token, 99, 1, "one", "one", 99, 1, 3);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale search activation rejects targets whose line no longer exists");
   end Test_Search_Activation_Rejects_Invalid_Stale_Target;


   procedure Test_Search_Workspace_Close_Clears_Query_Input_And_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Activate_Search_Query_Input (S.Feature_Search_Results);
      Editor.Feature_Search_Results.Set_Search_Input_Text (S.Feature_Search_Results, "needle");
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (S.Feature_Search_Results, "alpha");
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (S.Feature_Search_Results, "beta");
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "buffer", True, 1, 1, 1);

      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);

      Assert (not Editor.Feature_Search_Results.Search_Input_Is_Active (S.Feature_Search_Results),
              "workspace close deactivates Search Results query input");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count (S.Feature_Search_Results) = 0,
              "workspace close clears session-local Search Results query history");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "workspace close clears Search Results rows");
      Assert (not Editor.Feature_Search_Results.Has_Query (S.Feature_Search_Results),
              "workspace close clears Search Results query state");
   end Test_Search_Workspace_Close_Clears_Query_Input_And_History;

   procedure Test_Search_Project_Close_Preserves_Bounded_History_But_Clears_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (S.Feature_Search_Results, "alpha");
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "buffer", True, 1, 1, 1);
      Editor.Feature_Search_Results.Activate_Search_Query_Input (S.Feature_Search_Results);

      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);

      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "project close clears Search Results rows");
      Assert (not Editor.Feature_Search_Results.Search_Input_Is_Active (S.Feature_Search_Results),
              "project close clears Search Results query input");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count (S.Feature_Search_Results) = 1,
              "project close preserves bounded session query history by policy");
   end Test_Search_Project_Close_Preserves_Bounded_History_But_Clears_Rows;

   procedure Test_Search_Buffer_Close_With_Selected_Result_Clears_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Closed_Buffer : Natural := 42;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, "hit", "hit" & ASCII.LF, "buffer", Closed_Buffer, 1);
      Editor.Feature_Search_Results.Project_Rows (S.Feature_Search_Results, S.Feature_Panel);
      Select_Row (S.Feature_Panel, 1);

      Editor.Feature_Search_Results.Reset_Search_Results_For_Buffer_Close
        (S.Feature_Search_Results, Closed_Buffer);
      Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
        (S.Feature_Search_Results, S.Feature_Panel);

      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "closing the searched buffer clears Search Results rows");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "closing the selected search target clears feature-panel selection");
      Assert (not Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "buffer-close reset leaves no stale Search Results state");
   end Test_Search_Buffer_Close_With_Selected_Result_Clears_Target;

   procedure Test_Search_Result_Replacement_Invalidates_Old_Reveal_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Old_Token : Feature_Projection_Token;
   begin
      Editor.State.Init (S);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "old", "buffer", True, 1, 1, 1);
      Editor.Feature_Search_Results.Project_Rows (S.Feature_Search_Results, S.Feature_Panel);
      Old_Token := Build_Feature_Projection_Token (S.Feature_Panel);

      Editor.Feature_Search_Results.Clear (S.Feature_Search_Results);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "new", "buffer", True, 1, 1, 1);
      Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
        (S.Feature_Search_Results, S.Feature_Panel, Select_First_When_Available => True);

      Request_Reveal_Row (S.Feature_Panel, Old_Token, 1);
      Assert (Requested_Reveal_Row (S.Feature_Panel) = 0,
              "stale search projection token cannot reveal after result replacement");
      Assert (not Projection_Token_Matches (S.Feature_Panel, Old_Token),
              "result replacement invalidates old Search Results projection generation");
   end Test_Search_Result_Replacement_Invalidates_Old_Reveal_Token;

   procedure Test_Feature_Panel_Repeated_Outline_Messages_Search_Switch_Preserves_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Search_Count : Natural;
      Message_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "needle" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, "needle", Editor.State.Current_Text (S),
         "buffer", S.Registry_Token, Editor.State.Current_Buffer_Revision (S));
      Search_Count := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Message_Count := Editor.Feature_Messages.Row_Count (S.Feature_Messages);

      for I in 1 .. 5 loop
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
                 "can repeatedly switch to Outline");
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
                 "can repeatedly switch to Messages");
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
                 "can repeatedly switch to Search Results");
      end loop;

      Assert (Editor.Outline.Has_Items (S.Outline),
              "repeated feature switching preserves Outline state");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Message_Count,
              "repeated feature switching preserves Messages state");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Search_Count,
              "repeated feature switching preserves Search Results state");
   end Test_Feature_Panel_Repeated_Outline_Messages_Search_Switch_Preserves_Isolation;

   procedure Test_Search_Long_Session_Query_History_Remains_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Results : Editor.Feature_Search_Results.Search_Results_Feature_State;
   begin
      for I in 1 .. 35 loop
         Editor.Feature_Search_Results.Commit_Search_Query_To_History
           (Results, "query-" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both));
      end loop;
      Editor.Feature_Search_Results.Commit_Search_Query_To_History (Results, "query-30");

      Assert (Editor.Feature_Search_Results.Search_Query_History_Count (Results) = 20,
              "Search Results query history remains bounded");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Item (Results, 20) = "query-30",
              "repeated history entries move to the newest position without duplicates");
      Editor.Feature_Search_Results.Assert_Search_Results_State_Consistent (Results);
   end Test_Search_Long_Session_Query_History_Remains_Bounded;


   procedure Test_Feature_Descriptor_Table_Covers_All_Feature_Ids
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Seen_Outline : Boolean := False;
      Seen_Messages : Boolean := False;
      Seen_Search : Boolean := False;
      Seen_Diagnostics : Boolean := False;
      Feature : Feature_Id;
   begin
      for I in 1 .. Feature_Descriptor_Count loop
         Feature := Descriptor_Id (I);
         Assert (Is_Known_Feature (Feature),
                 "descriptor table exposes only known features");
         Assert (Feature_Supports_Rows (Feature),
                 "every registered feature declares row support");
         Assert (Feature_Can_Clear (Feature),
                 "every current registered feature declares clear support");
         Assert (Feature_Display_Label (Feature)'Length > 0,
                 "every registered feature has a static display label");
         Assert (Feature_Stable_Name (Feature)'Length > 0,
                 "every registered feature has a stable name");

         case Feature is
            when Outline_Feature =>
               Seen_Outline := True;
            when Messages_Feature =>
               Seen_Messages := True;
            when Search_Results_Feature =>
               Seen_Search := True;
            when Diagnostics_Feature =>
               Seen_Diagnostics := True;
            when Unknown_Feature =>
               Assert (False, "unknown feature is not registered");
         end case;
      end loop;

      Assert (Seen_Outline and then Seen_Messages and then Seen_Search and then Seen_Diagnostics,
              "descriptor table covers Outline, Messages, Search Results, and Diagnostics");
      Assert (Descriptor_Id (Feature_Descriptor_Count + 1) = Unknown_Feature,
              "out-of-range descriptor lookup rejects safely");
      Assert (not Feature_Supports_Rows (Unknown_Feature),
              "unknown feature has no generic row capability");
      Assert (not Feature_Can_Clear (Unknown_Feature),
              "unknown feature has no clear capability");
   end Test_Feature_Descriptor_Table_Covers_All_Feature_Ids;

   procedure Test_Feature_Dispatch_Covers_All_Feature_Ids
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Feature_Panel_Controller.Feature_Dispatch_Covers_All_Features,
              "projection, clear, and lifecycle dispatch covers every descriptor feature");
   end Test_Feature_Dispatch_Covers_All_Feature_Ids;

   procedure Test_Feature_Stale_Token_Rejected_After_Repeated_Switching
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Outline_Token : Feature_Projection_Token;
   begin
      Editor.State.Init (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "can show Outline before token capture");
      Append_Row (S.Feature_Panel, Feature_Row_Item, "outline row", Can_Reveal => True);
      Outline_Token := Build_Feature_Projection_Token (S.Feature_Panel);

      for I in 1 .. 3 loop
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
                 "repeated switch to Messages succeeds");
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
                 "repeated switch to Search Results succeeds");
         Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
                 "repeated switch back to Outline succeeds");
      end loop;

      Request_Reveal_Row (S.Feature_Panel, Outline_Token, 1);
      Assert (Requested_Reveal_Row (S.Feature_Panel) = 0,
              "stale feature projection token is rejected after repeated switching");
      Assert (not Projection_Token_Matches (S.Feature_Panel, Outline_Token),
              "stale feature projection token no longer matches active projection");
   end Test_Feature_Stale_Token_Rejected_After_Repeated_Switching;

   procedure Test_Feature_Clear_Active_Only_Clears_Active_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "needle" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, "needle", Editor.State.Current_Text (S),
         "buffer", S.Registry_Token, Editor.State.Current_Buffer_Revision (S));

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "can activate Messages before generic clear");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Feature_Panel);

      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "clear-active clears active Messages state");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "clear-active leaves inactive Outline state intact");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) > 0,
              "clear-active leaves inactive Search Results state intact");
   end Test_Feature_Clear_Active_Only_Clears_Active_Feature;

   procedure Test_Feature_Workspace_Close_Preserves_Command_Registrations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      D : Editor.Commands.Command_Descriptor;
   begin
      Editor.State.Init (S);
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);

      D := Editor.Commands.Descriptor (Editor.Commands.Command_Show_Outline);
      Assert (D.Id = Editor.Commands.Command_Show_Outline,
              "workspace close preserves Outline command registration");
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Show_Messages);
      Assert (D.Id = Editor.Commands.Command_Show_Messages,
              "workspace close preserves Messages command registration");
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Show_Search_Results_Feature);
      Assert (D.Id = Editor.Commands.Command_Show_Search_Results_Feature,
              "workspace close preserves Search Results command registration");
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Diagnostics_Show);
      Assert (D.Id = Editor.Commands.Command_Diagnostics_Show,
              "workspace close preserves Diagnostics command registration");
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (D.Id = Editor.Commands.Command_Feature_Panel_Open_Selected,
              "workspace close preserves generic feature-panel command registration");
   end Test_Feature_Workspace_Close_Preserves_Command_Registrations;


   procedure Test_Diagnostics_Show_And_Clear_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package Demo" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF &
         "beta" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "buffer", True, S.Registry_Token, 1, 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning,
         "diagnostic one", "buffer",
         Has_Target => True, Target_Buffer => S.Registry_Token,
         Target_Line => 1, Target_Column => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Info,
         "diagnostic two", "scaffold", Has_Target => False);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Show);
      Assert (Active_Feature (S.Feature_Panel) = Diagnostics_Feature,
              "diagnostics.show switches active feature");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "Diagnostics projection contains only diagnostics rows");
      Assert (Row_Label (S.Feature_Panel, 1) =
                "warning: diagnostic one — buffer:1:1 [Unknown]"
        and then Row_Label (S.Feature_Panel, 2) =
                "info: diagnostic two — scaffold — Target file missing or unavailable [Unknown]",
              "Diagnostics projection preserves source-grouped review order");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "diagnostics.show does not mutate Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "diagnostics.show does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "diagnostics.show does not mutate Search Results");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Clear);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "diagnostics.clear removes Diagnostics rows");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "diagnostics.clear does not clear Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "diagnostics.clear does not clear Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "diagnostics.clear does not clear Search Results");
   end Test_Diagnostics_Show_And_Clear_Isolated;

   procedure Test_Diagnostics_Token_Activation_And_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Token : Feature_Projection_Token;
      Stale_Generation : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error,
         "live target", "buffer",
         Has_Target => True, Target_Buffer => S.Registry_Token,
         Target_Line => 2, Target_Column => 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "can show Diagnostics through centralized switch");
      Token := Build_Feature_Projection_Token (S.Feature_Panel);
      Assert (Token.Feature = Diagnostics_Feature,
              "Diagnostics projection token carries Diagnostics feature id");
      Stale_Generation := Projection_Generation (S.Feature_Panel);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Info,
         "second", "scaffold", Has_Target => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
        (S.Feature_Diagnostics, S.Feature_Panel, 1, Stale_Generation) = 0,
              "Diagnostics rejects stale projection generation");

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation
        (S, 1, Projection_Generation (S.Feature_Panel));
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "targeted Diagnostics row activates through validated navigation");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "can switch away before cross-feature token rejection");
      Editor.Feature_Panel.Request_Reveal_Row (S.Feature_Panel, Token, 1);
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 0,
              "cross-feature Diagnostics reveal token is rejected");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "can return to Diagnostics before buffer-close reset");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
        (S, S.Registry_Token);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "buffer close removes only targeted Diagnostics rows");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "project close clears Diagnostics rows");
   end Test_Diagnostics_Token_Activation_And_Lifecycle;


   procedure Test_Diagnostics_Posting_And_Header
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);

      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "Style note", "editor");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "Unused declaration", "parser.adb");
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "Missing semicolon",
         "main.adb", S.Registry_Token, 2, 1);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 3,
              "posting appends Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 1) = 1
        and then Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 2) = 2
        and then Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 3) = 3,
              "posting assigns stable insertion ids");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 1) =
              Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
              "untargeted producer rows carry editor source kind");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind (S.Feature_Diagnostics, 3) =
              Editor.Feature_Diagnostics.File_Diagnostic_Source,
              "targeted producer rows carry file source kind");
      Assert (Editor.Feature_Diagnostics.Header_Text (S.Feature_Diagnostics) =
              "Diagnostics: Errors: 1 | Warnings: 1 | Info: 1 | Notes: 0 | Unknown: 0 | Total: 3",
              "header uses source row severity counts");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics can be shown after posting");
      Assert (Header_Text (S.Feature_Panel) =
              "Diagnostics: Errors: 1 | Warnings: 1 | Info: 1 | Notes: 0 | Unknown: 0 | Total: 3",
              "projected header uses Diagnostics status text");
      Assert (Row_Label (S.Feature_Panel, 2) =
              "error: Missing semicolon — main.adb:2:1 [File]",
              "targeted labels are deterministic and compact");
      Assert (Row_Severity (S.Feature_Panel, 2) = Feature_Row_Error_Severity,
              "diagnostic severity maps into generic row severity");
   end Test_Diagnostics_Posting_And_Header;


   procedure Test_Diagnostics_Invalid_Target_And_Retention
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      First_Id_After_Eviction : Editor.Feature_Diagnostics.Diagnostic_Id;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF);

      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "bad",
         "main.adb", S.Registry_Token, 99, 1);
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "invalid target is retained as non-activatable row");

      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics loop
         Editor.State.Post_Diagnostic
           (S, Editor.Feature_Diagnostics.Diagnostic_Info, "row" & Natural'Image (I), "test");
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
              Editor.Feature_Diagnostics.Max_Diagnostics,
              "retention evicts oldest diagnostics at the cap");
      First_Id_After_Eviction := Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 1);
      Assert (First_Id_After_Eviction = 2,
              "retention removes the oldest diagnostic first");
      Assert (Editor.Feature_Diagnostics.Next_Diagnostic_Id (S.Feature_Diagnostics) =
              Editor.Feature_Diagnostics.Diagnostic_Id (Editor.Feature_Diagnostics.Max_Diagnostics + 2),
              "retained diagnostics do not reuse ids");
   end Test_Diagnostics_Invalid_Target_And_Retention;


   procedure Test_Diagnostics_Active_Reprojection_After_Post
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Natural;
   begin
      Editor.State.Init (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "empty Diagnostics can be shown");
      Before := Projection_Generation (S.Feature_Panel);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "late", "editor");
      Assert (Row_Count (S.Feature_Panel) = 1,
              "posting while active refreshes projection rows");
      Assert (Projection_Generation (S.Feature_Panel) /= Before,
              "posting while active invalidates projection generation");
      Assert (Header_Text (S.Feature_Panel) =
              "Diagnostics: Errors: 0 | Warnings: 1 | Info: 0 | Notes: 0 | Unknown: 0 | Total: 1",
              "posting while active refreshes header text");
   end Test_Diagnostics_Active_Reprojection_After_Post;

   procedure Test_Diagnostics_Text_Filter_Composes_And_Preserves_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "Style note", "editor");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "Unused declaration", "parser.adb");
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "Missing semicolon",
         "main.adb", S.Registry_Token, 2, 1);

      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "MAIN");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 1,
              "text filter matches target/source labels case-insensitively");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics can project a filtered row set");
      Assert (Row_Count (S.Feature_Panel) = 1,
              "filtered projection includes only matching diagnostics");
      Assert (Row_Source_Index (S.Feature_Panel, 1) = 3,
              "filtered rows keep stable Diagnostic_Id mapping");
      Assert (Header_Text (S.Feature_Panel) =
              "Diagnostics: 1 of 3 visible | Visible Errors: 1 | Visible Warnings: 0 | Visible Info: 0 | Visible Notes: 0 | Visible Unknown: 0 | Visible Total: 1 | Errors: 1 | Warnings: 1 | Info: 1 | Notes: 0 | Unknown: 0 | Total: 3",
              "filtered header shows visible and source counts");

      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "unused");
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) = 2,
              "text filter matches diagnostic messages without reordering rows");
   end Test_Diagnostics_Text_Filter_Composes_And_Preserves_Order;


   procedure Test_Diagnostics_Severity_Toggles_Reconcile_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "info row", "editor");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "warning row", "parser.adb");
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "error row",
         "main.adb", S.Registry_Token, 2, 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection is visible before severity toggles");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 3);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Toggle_Warnings);
      Assert (Row_Count (S.Feature_Panel) = 2,
              "warning toggle hides warning rows only from projection");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 3,
              "severity filtering does not mutate source diagnostic rows");
      Assert (Selected_Row (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) = 1,
              "selection falls back to first visible diagnostic when hidden");
      Assert (Header_Text (S.Feature_Panel) =
              "Diagnostics: 2 of 3 visible | Visible Errors: 1 | Visible Warnings: 0 | Visible Info: 1 | Visible Notes: 0 | Visible Unknown: 0 | Visible Total: 2 | Errors: 1 | Warnings: 1 | Info: 1 | Notes: 0 | Unknown: 0 | Total: 3",
              "severity-filtered header shows visible and source counts");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Show_All);
      Assert (Row_Count (S.Feature_Panel) = 3,
              "diagnostics.show-all restores all severities and sources");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics),
              "diagnostics.show-all clears active filter state");
   end Test_Diagnostics_Severity_Toggles_Reconcile_Selection;


   procedure Test_Diagnostics_Filtered_Activation_Rejects_Stale_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Stale_Generation : Natural;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "error row",
         "main.adb", S.Registry_Token, 2, 1);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "info row", "editor");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection is visible before filtered activation");
      Stale_Generation := Projection_Generation (S.Feature_Panel);
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "error");
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation
        (S, 1, Stale_Generation);
      Assert (Result.Status /= Editor.Executor.Command_Executed,
              "filtered activation rejects stale projection generations");
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation
        (S, 1, Projection_Generation (S.Feature_Panel));
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "filtered activation navigates the visible targeted diagnostic");
   end Test_Diagnostics_Filtered_Activation_Rejects_Stale_Projection;


   procedure Test_Diagnostics_Clear_Selected_Reconciles_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "first", "editor");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "second", "parser.adb");
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "third",
         "main.adb", S.Registry_Token, 2, 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection is visible before clear-selected");
      Select_Row (S.Feature_Panel, 3);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Selected);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "clear-selected removes one source diagnostic row");
      Assert (Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 1) = 1
        and then Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 2) = 3,
              "clear-selected removes by Diagnostic_Id, not display label");
      Assert (Selected_Row (S.Feature_Panel) = 2
        and then Row_Source_Index (S.Feature_Panel, 2) = 3,
              "clear-selected reconciles selection to the same visible slot when possible");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Selected);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "second clear-selected removes selected next diagnostic");
      Assert (Selected_Row (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) = 1,
              "deleting the last visible row reconciles to previous diagnostic");
   end Test_Diagnostics_Clear_Selected_Reconciles_Selection;


   procedure Test_Diagnostics_Clear_By_Severity_And_Source_Preserve_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      D2 : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Removed : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Info, "style", "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Warning, "unused", "parser.adb",
         Source_Kind => Editor.Feature_Diagnostics.File_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "broken", "build",
         Source_Kind => Editor.Feature_Diagnostics.Project_Diagnostic_Source);
      Editor.Feature_Diagnostics.Set_Filter_Text (D, "e");
      Editor.Feature_Diagnostics.Toggle_Info_Visible (D);
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (D, Editor.Feature_Diagnostics.Project_Diagnostic_Source);

      Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Severity
        (D, Editor.Feature_Diagnostics.Diagnostic_Warning);
      Assert (Removed = 1, "clear warnings removes warning diagnostics only");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 2,
              "severity subset clear preserves non-matching diagnostics");
      Assert (Editor.Feature_Diagnostics.Filter_Text (D) = "e"
        and then not Editor.Feature_Diagnostics.Severity_Is_Visible
          (D, Editor.Feature_Diagnostics.Diagnostic_Info)
        and then not Editor.Feature_Diagnostics.Source_Is_Visible
          (D, Editor.Feature_Diagnostics.Project_Diagnostic_Source),
              "severity subset clear preserves text, severity, and source filters");

      Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source
        (D, Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Assert (Removed = 1, "clear by source removes only that source kind");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 1
        and then Editor.Feature_Diagnostics.Item_Source_Kind (D, 1) =
          Editor.Feature_Diagnostics.Project_Diagnostic_Source,
              "source subset clear preserves other source kinds");
      Assert (Editor.Feature_Diagnostics.Filter_Text (D) = "e"
        and then not Editor.Feature_Diagnostics.Severity_Is_Visible
          (D, Editor.Feature_Diagnostics.Diagnostic_Info)
        and then not Editor.Feature_Diagnostics.Source_Is_Visible
          (D, Editor.Feature_Diagnostics.Project_Diagnostic_Source),
              "source subset clear preserves active filter state");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (D2, Editor.Feature_Diagnostics.Diagnostic_Error, "first semantic", "src/a.adb",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D2, Editor.Feature_Diagnostics.Diagnostic_Error, "second semantic", "src/b.adb",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D2, Editor.Feature_Diagnostics.Diagnostic_Error, "external same path", "src/a.adb",
         Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source_And_Label
        (D2, Editor.Feature_Diagnostics.Editor_Diagnostic_Source, "src/a.adb");
      Assert (Removed = 1,
              "clear by source and label removes only exact producer rows");
      Assert (Editor.Feature_Diagnostics.Row_Count (D2) = 2
              and then Editor.Feature_Diagnostics.Item_Source_Label (D2, 1) = "src/b.adb"
              and then Editor.Feature_Diagnostics.Item_Source_Kind (D2, 2) =
                Editor.Feature_Diagnostics.External_Diagnostic_Source,
              "clear by source and label preserves other labels and source kinds");
   end Test_Diagnostics_Clear_By_Severity_And_Source_Preserve_Filters;


   procedure Test_Diagnostics_Copy_Format_And_Action_Flags
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package alpha" & ASCII.LF &
         "@outline procedure beta" & ASCII.LF);
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "Missing semicolon",
         "main.adb", S.Registry_Token, 2, 1);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning,
         "Unused declaration", "parser.adb");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection is visible before action flag checks");

      Assert (Row_Can_Open (S.Feature_Panel, 1)
        and then Row_Can_Copy (S.Feature_Panel, 1)
        and then Row_Can_Clear (S.Feature_Panel, 1)
        and then Row_Severity (S.Feature_Panel, 1) = Feature_Row_Error_Severity,
              "targeted diagnostic can open, copy, clear, and carries severity");
      Assert ((not Row_Can_Open (S.Feature_Panel, 2))
        and then Row_Can_Copy (S.Feature_Panel, 2)
        and then Row_Can_Clear (S.Feature_Panel, 2)
        and then Row_Severity (S.Feature_Panel, 2) = Feature_Row_Warning_Severity,
              "untargeted diagnostic cannot open but can copy and clear");
      Assert (Editor.Feature_Diagnostics.Format_Diagnostic_For_Copy
        (S.Feature_Diagnostics, 1) = "error: Missing semicolon — main.adb:2:1 [File]",
              "copy formatter is deterministic and compact");
      Select_Row (S.Feature_Panel, 2);
      Assert (Editor.Feature_Diagnostics.Selected_Diagnostic_Text
        (S.Feature_Diagnostics, S.Feature_Panel) =
        "warning: Unused declaration — parser.adb — Target file missing or unavailable [Manual/Test Fixture]",
              "selected diagnostic copy text uses selected Diagnostic_Id mapping");
   end Test_Diagnostics_Copy_Format_And_Action_Flags;


   procedure Test_Diagnostics_Action_Commands_Do_Not_Affect_Other_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package alpha" & ASCII.LF &
         "@outline procedure beta" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "hit", "buffer", True, S.Registry_Token, 1, 1);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "diagnostic", "main.adb");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection is visible before isolation checks");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Copy_Selected_Text);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Errors);
      Assert (Editor.Outline.Has_Items (S.Outline),
              "diagnostics action commands do not affect Outline");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "diagnostics action commands do not affect Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "diagnostics action commands do not affect Search Results");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "diagnostics action command clears only Diagnostics rows");
   end Test_Diagnostics_Action_Commands_Do_Not_Affect_Other_Features;


   procedure Test_Diagnostics_Command_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "info row", "editor");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics feedback test shows diagnostics panel");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Toggle_Info);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
              Editor.Feature_Diagnostics.Message_Info_Hidden,
              "hiding info emits the compact deterministic feedback string");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Toggle_Info);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
              Editor.Feature_Diagnostics.Message_Info_Shown,
              "showing info emits the compact deterministic feedback string");
   end Test_Diagnostics_Command_Feedback_Is_Deterministic;


   procedure Test_Diagnostics_Filter_Delete_Post_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, "alpha row", "editor");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "beta row", "editor");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection visible before filter/delete/post");

      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "beta");
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) = 2,
              "text filter exposes only the matching diagnostic before delete");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Selected);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "clear-selected removes the filtered selected source row");
      Assert (Row_Count (S.Feature_Panel) = 1
        and then not Row_Is_Selectable (S.Feature_Panel, 1),
              "filtered projection becomes deterministic empty state after delete");

      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "beta replacement", "editor");
      Assert (Row_Count (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) = 3,
              "posting after filtered deletion rebuilds projection from current rows");
   end Test_Diagnostics_Filter_Delete_Post_Rebuilds_Projection;


   procedure Test_Diagnostics_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "buffer row",
         "main.adb", S.Registry_Token, 2, 1);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "session row", "editor");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection visible before buffer close reset");
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "row");
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
        (S.Feature_Diagnostics, S.Feature_Panel);

      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
        (S, S.Registry_Token);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "buffer close removes only targeted diagnostics for the closed buffer");
      Assert (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, 1) = "session row",
              "buffer close preserves untargeted session diagnostic rows");
      Assert (Row_Count (S.Feature_Panel) = 1
        and then Row_Source_Index (S.Feature_Panel, 1) =
          Natural (Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 1)),
              "buffer close rebuilds active filtered diagnostics projection");
   end Test_Diagnostics_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows;


   procedure Test_Diagnostics_Workspace_Close_After_Many_Operations_Clears_All_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      for I in 1 .. 20 loop
         Editor.State.Post_Diagnostic
           (S, Editor.Feature_Diagnostics.Diagnostic_Info,
            "diag" & Natural'Image (I), "editor");
      end loop;
      Editor.Feature_Diagnostics.Set_Filter_Text (S.Feature_Diagnostics, "diag");
      Editor.Feature_Diagnostics.Toggle_Info_Visible (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection visible before workspace close reset");

      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "workspace close clears diagnostics source rows");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics),
              "workspace close clears diagnostics filter state");
      Assert (Editor.Feature_Diagnostics.Next_Diagnostic_Id (S.Feature_Diagnostics) = 1,
              "workspace close resets session-local diagnostic producer ids");
      Assert (Editor.Feature_Diagnostics.Severity_Is_Visible
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Info)
        and then Editor.Feature_Diagnostics.Source_Is_Visible
          (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Editor_Diagnostic_Source),
              "workspace close restores diagnostics visibility defaults");
   end Test_Diagnostics_Workspace_Close_After_Many_Operations_Clears_All_State;


   procedure Test_Feature_Panel_Cross_Feature_Diagnostics_Tokens_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Generation : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "diagnostic", "editor");
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "diagnostics projection visible before cross-feature token check");
      Generation := Projection_Generation (S.Feature_Panel);

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "switched to Messages before validating stale diagnostics row token");

      Assert (Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
        (S.Feature_Diagnostics, S.Feature_Panel, 1, Generation) = 0,
              "diagnostics row mapping rejects cross-feature stale tokens");
      Assert (not Editor.Feature_Diagnostics.Validate_Row_Action
        (S.Feature_Diagnostics, S.Feature_Panel, 1, Generation),
              "diagnostics row action rejects cross-feature stale tokens");
   end Test_Feature_Panel_Cross_Feature_Diagnostics_Tokens_Rejected;


   procedure Test_Diagnostics_Repeated_Posting_Respects_Retention
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 25 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (D, Editor.Feature_Diagnostics.Diagnostic_Warning,
            "diag" & Natural'Image (I), "producer",
            Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      end loop;

      Editor.Feature_Diagnostics.Assert_Diagnostics_State_Consistent (D);
      Assert (Editor.Feature_Diagnostics.Row_Count (D) =
              Editor.Feature_Diagnostics.Max_Diagnostics,
              "repeated posting keeps diagnostics bounded by retention limit");
      Assert (Editor.Feature_Diagnostics.Item_Id (D, 1) = 26,
              "retention evicts oldest diagnostics without reusing ids");
      Assert (Editor.Feature_Diagnostics.Next_Diagnostic_Id (D) =
              Editor.Feature_Diagnostics.Diagnostic_Id
                (Editor.Feature_Diagnostics.Max_Diagnostics + 26),
              "repeated posting advances producer id monotonically");
   end Test_Diagnostics_Repeated_Posting_Respects_Retention;



   procedure Test_Diagnostics_Contract_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Editor.Diagnostics_Audit.Diagnostics_Contract_Review;
   begin
      Editor.State.Init (S);
      Review := Editor.Diagnostics_Audit.Review_Diagnostics_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review));
      Assert (Review.Session_Local,
              "Diagnostics remain session-local");
      Assert (Review.Retention_Bounded,
              "Diagnostics retention remains bounded");
      Assert (Review.Projection_Side_Effect_Free,
              "Diagnostics projection remains side-effect-free");
      Assert (Review.Filters_Compose,
              "Diagnostics filters compose deterministically");
      Assert (Review.Targets_Validated,
              "Diagnostics targets remain validated");
      Assert (Review.Actions_Routed,
              "Diagnostics action commands remain routed");
      Assert (Review.Editable_Actions_Visible,
              "Diagnostics editable actions remain visible");
      Assert (Review.Feature_Panel_Intact,
              "Feature Panel sentinel stays healthy");
      Assert (Review.Command_Surface_Intact,
              "command surface sentinel stays healthy");
      Assert (Review.Public_Build_Guardrail_Intact,
              "public-build manifest sentinel stays healthy");
   end Test_Diagnostics_Contract_Review_Default_Passes;

   procedure Test_Diagnostics_Contract_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Before_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Before_Rows     : Natural;
      Before_Visible  : Natural;
      Before_Next_Id  : Editor.Feature_Diagnostics.Diagnostic_Id;
      Before_Selected : Natural;
      Before_Feature  : Editor.Feature_Panel.Feature_Id;
      Before_Filter   : Boolean;
      Review          : Editor.Diagnostics_Audit.Diagnostics_Contract_Review;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "line one" & ASCII.LF & "line two" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "demo error",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Before_Text := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.State.Current_Text (S));
      Before_Rows := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Before_Visible := Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics);
      Before_Next_Id := Editor.Feature_Diagnostics.Next_Diagnostic_Id (S.Feature_Diagnostics);
      Before_Selected := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Before_Feature := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Before_Filter := Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics);

      Review := Editor.Diagnostics_Audit.Review_Diagnostics_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review));
      Assert (Editor.State.Current_Text (S) = Ada.Strings.Unbounded.To_String (Before_Text),
              "Diagnostics review does not mutate active-buffer text");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = Before_Rows,
              "Diagnostics review does not mutate diagnostic rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = Before_Visible,
              "Diagnostics review does not mutate visible Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Next_Diagnostic_Id (S.Feature_Diagnostics) = Before_Next_Id,
              "Diagnostics review does not allocate Diagnostic_Id values");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = Before_Selected,
              "Diagnostics review does not change Feature Panel selection");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) = Before_Feature,
              "Diagnostics review does not switch Feature Panel feature");
      Assert (Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics) = Before_Filter,
              "Diagnostics review does not mutate live filters");
   end Test_Diagnostics_Contract_Review_Is_Side_Effect_Free;

   procedure Test_Diagnostics_Contract_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Editor.Diagnostics_Audit.Diagnostics_Contract_Review;
   begin
      Review := (others => True);
      Assert (Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review) =
                "Diagnostics: contract healthy",
              "healthy Diagnostics feedback is deterministic");
      Review.Review_Passed := False;
      Review.Session_Local := False;
      Assert (Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review) =
                "Diagnostics: session-local scope failed",
              "session-local failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Targets_Validated := False;
      Assert (Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review) =
                "Diagnostics: target validation failed",
              "target-validation failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Editable_Actions_Visible := False;
      Assert (Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review) =
                "Diagnostics: editable action projection missing",
              "editable-action projection failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Editor.Diagnostics_Audit.Build_Diagnostics_Contract_Review_Feedback (Review) =
                "Diagnostics: public build guardrail failed",
              "public-build sentinel failure feedback is deterministic");
   end Test_Diagnostics_Contract_Review_Feedback_Is_Deterministic;

   procedure Test_Diagnostics_Retention_Filter_And_Target_Robustness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D     : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Gen   : Natural;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 3 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (D,
            (if I mod 2 = 0 then Editor.Feature_Diagnostics.Diagnostic_Error
             else Editor.Feature_Diagnostics.Diagnostic_Warning),
            "retained" & Natural'Image (I),
            "external",
            Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target    => True,
            Target_Buffer => 7,
            Target_Line   => 1,
            Target_Column => 1);
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (D) =
              Editor.Feature_Diagnostics.Max_Diagnostics,
              "Diagnostics retention remains bounded after overflow");
      Assert (Editor.Feature_Diagnostics.Item_Id (D, 1) = 4,
              "Diagnostics retention trims oldest rows first");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) =
              Editor.Feature_Diagnostics.Max_Diagnostics,
              "Diagnostics projection sees all retained rows before filtering");

      Editor.Feature_Diagnostics.Toggle_Errors_Visible (D);
      Assert (Editor.Feature_Diagnostics.Row_Count (D) =
              Editor.Feature_Diagnostics.Max_Diagnostics,
              "Diagnostics severity filtering does not mutate retained rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) <
              Editor.Feature_Diagnostics.Row_Count (D),
              "Diagnostics severity filtering hides rows projection-only");
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (D, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 0,
              "Diagnostics source filtering composes with severity filtering");
      Editor.Feature_Diagnostics.Show_All (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) =
              Editor.Feature_Diagnostics.Row_Count (D),
              "Diagnostics clearing filters restores retained rows");

      Editor.Feature_Diagnostics.Project_Rows (D, Panel);
      Gen := Editor.Feature_Panel.Projection_Generation (Panel);
      Assert (Editor.Feature_Diagnostics.Validate_Row_Action (D, Panel, 1, Gen),
              "Diagnostics valid projected row action passes generation validation");
      Editor.Feature_Diagnostics.Project_Rows (D, Panel);
      Assert (not Editor.Feature_Diagnostics.Validate_Row_Action (D, Panel, 1, Gen),
              "Diagnostics stale projection generation is rejected");
      Assert (not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
                (D, 1, Editor.Feature_Diagnostics.No_Buffer),
              "Diagnostics target validation rejects absent active buffer token");
      Assert (Editor.Feature_Diagnostics.Validate_Diagnostic_Target (D, 1, 7),
              "Diagnostics target validation accepts matching active buffer token");
      Assert (not Editor.Feature_Diagnostics.Clear_Diagnostic_By_Id (D, 1),
              "Diagnostics action by trimmed Diagnostic_Id fails safely");
   end Test_Diagnostics_Retention_Filter_And_Target_Robustness;


   procedure Test_Diagnostics_Activation_Rejects_Out_Of_Range_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "column outside active buffer line",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 99);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Diagnostics activation rejects out-of-range column");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "rejected Diagnostics activation does not move caret");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "rejected Diagnostics activation does not mutate diagnostic rows");
   end Test_Diagnostics_Activation_Rejects_Out_Of_Range_Column;

   procedure Test_Diagnostics_Clear_Lifecycle_And_Sibling_Features_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Info_Message,
         "message kept", Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "search row",
         Source_Label  => "buffer",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1,
         Query         => "abc",
         Line_Text     => "abc",
         Match_Line    => 1,
         Match_Column  => 1,
         Match_Length  => 3);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "diagnostic cleared",
         "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);

      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "clear Diagnostics removes diagnostic rows");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 0,
              "clear Diagnostics clears stale Diagnostics selection");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "clear Diagnostics does not affect Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "clear Diagnostics does not affect Search Results");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "workspace-close diagnostic",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Reset_Diagnostics_For_Workspace_Close
        (S.Feature_Diagnostics);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "workspace close clears session-local Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Next_Diagnostic_Id (S.Feature_Diagnostics) = 1,
              "workspace close resets transient Diagnostic_Id allocation");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "Diagnostics workspace reset does not alter Messages state");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "Diagnostics workspace reset does not alter Search Results state");
   end Test_Diagnostics_Clear_Lifecycle_And_Sibling_Features_Isolated;



   procedure Test_Diagnostics_Projection_Empty_State_And_Row_Metadata_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D              : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Panel          : Editor.Feature_Panel.Feature_Panel_State;
      First_Label    : Ada.Strings.Unbounded.Unbounded_String;
      First_Detail   : Ada.Strings.Unbounded.Unbounded_String;
      First_Source   : Natural := 0;
      First_Severity : Editor.Feature_Panel.Feature_Row_Severity;
   begin
      Editor.Feature_Diagnostics.Project_Rows (D, Panel);
      Assert (Editor.Feature_Panel.Active_Feature (Panel) =
              Editor.Feature_Panel.Diagnostics_Feature,
              "Diagnostics projection selects only the Diagnostics feature shell");
      Assert (Editor.Feature_Panel.Row_Count (Panel) = 1,
              "empty Diagnostics projection emits one deterministic empty row");
      Assert (Editor.Feature_Panel.Row_Kind (Panel, 1) =
              Editor.Feature_Panel.Feature_Row_Empty_State,
              "empty Diagnostics row is explicitly an empty-state row");
      Assert (Editor.Feature_Panel.Row_Label (Panel, 1) = "No diagnostics.",
              "empty Diagnostics label is deterministic");
      Assert (Editor.Feature_Panel.Row_Detail (Panel, 1) =
              "Diagnostics appear here; nothing to navigate.",
              "empty Diagnostics detail is deterministic");
      Assert (not Editor.Feature_Panel.Row_Is_Selectable (Panel, 1),
              "empty Diagnostics row is not selectable");
      Assert (Editor.Feature_Panel.Selected_Row (Panel) = 0,
              "empty Diagnostics projection has no selection");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "syntax error",
         "compiler",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 11,
         Target_Line   => 3,
         Target_Column => 5);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "style warning",
         "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);

      Editor.Feature_Diagnostics.Project_Rows (D, Panel);
      Assert (Editor.Feature_Panel.Row_Count (Panel) = 2,
              "Diagnostics projection emits exactly visible diagnostic rows");
      Assert (Editor.Feature_Panel.Selected_Row (Panel) = 1,
              "Diagnostics projection selects the first visible diagnostic row");
      Assert (Editor.Feature_Panel.Row_Label (Panel, 1) =
              "error: syntax error — compiler:3:5 [External Producer]",
              "Diagnostics target row label is deterministic");
      Assert (Editor.Feature_Panel.Row_Detail (Panel, 1) =
              "state: openable | compiler:3:5 | producer: External Producer",
              "Diagnostics target row detail is deterministic");
      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 1) = "openable",
              "targeted Diagnostics row exposes openable state");
      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 2) = "unavailable",
              "source-labelled untargeted Diagnostics row exposes unavailable state");
      Assert (Editor.Feature_Panel.Row_Severity (Panel, 1) =
              Editor.Feature_Panel.Feature_Row_Error_Severity,
              "Diagnostics error severity projects to generic row severity");
      Assert (Editor.Feature_Panel.Row_Is_Diagnostic (Panel, 1),
              "Diagnostics projected rows remain marked as diagnostic rows");
      Assert (Editor.Feature_Panel.Row_Is_Activatable (Panel, 1),
              "Diagnostics target row is activatable only with target metadata");
      Assert (Editor.Feature_Panel.Row_Can_Open (Panel, 1),
              "Diagnostics target row exposes open action metadata");
      Assert (Editor.Feature_Panel.Row_Can_Copy (Panel, 1),
              "Diagnostics target row exposes copy action metadata");
      Assert (Editor.Feature_Panel.Row_Can_Clear (Panel, 1),
              "Diagnostics target row exposes clear action metadata");
      Assert (Editor.Feature_Panel.Row_Source_Index (Panel, 1) = 1,
              "Diagnostics row source index carries stable Diagnostic_Id");

      First_Label := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Feature_Panel.Row_Label (Panel, 1));
      First_Detail := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Feature_Panel.Row_Detail (Panel, 1));
      First_Source := Editor.Feature_Panel.Row_Source_Index (Panel, 1);
      First_Severity := Editor.Feature_Panel.Row_Severity (Panel, 1);
      Editor.Feature_Diagnostics.Project_Rows (D, Panel);
      Assert (Editor.Feature_Panel.Row_Label (Panel, 1) =
              Ada.Strings.Unbounded.To_String (First_Label),
              "repeated Diagnostics projection preserves row labels");
      Assert (Editor.Feature_Panel.Row_Detail (Panel, 1) =
              Ada.Strings.Unbounded.To_String (First_Detail),
              "repeated Diagnostics projection preserves row details");
      Assert (Editor.Feature_Panel.Row_Source_Index (Panel, 1) = First_Source,
              "repeated Diagnostics projection preserves Diagnostic_Id source index");
      Assert (Editor.Feature_Panel.Row_Severity (Panel, 1) = First_Severity,
              "repeated Diagnostics projection preserves severity metadata");
   end Test_Diagnostics_Projection_Empty_State_And_Row_Metadata_Deterministic;

   procedure Test_Diagnostics_Row_State_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "openable", "main.adb",
         Has_Target => True, Target_Buffer => 10, Target_Line => 4,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "missing line", "main.adb",
         Has_Target => True, Target_Buffer => 10, Target_Line => 0);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "missing file", "main.adb",
         Has_Target => True, Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line => 4);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "no source", "",
         Has_Target => False);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale (D, 10);

      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 1) = "stale",
              "stale Diagnostics row state wins over target availability");
      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 2) = "stale",
              "stale missing-line rows are labelled stale");
      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 3) = "missing file",
              "missing-file Diagnostics row state is explicit");
      Assert (Editor.Feature_Diagnostics.Item_Row_State_Label (D, 4) = "no source",
              "source-less Diagnostics row state is explicit");
   end Test_Diagnostics_Row_State_Labels;

   procedure Test_Diagnostics_Activation_Rejects_No_Target_Stale_And_Trimmed_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
      Gen    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "untargeted diagnostic",
         "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Diagnostics activation rejects diagnostics with no target");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "no-target Diagnostics activation leaves caret unchanged");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "valid target before stale projection",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Gen := Editor.Feature_Panel.Projection_Generation (S.Feature_Panel);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation (S, 1, Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Diagnostics activation rejects stale projection generation");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "stale Diagnostics activation leaves caret unchanged");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "trimmed target",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 1 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Editor.Feature_Diagnostics.Diagnostic_Info,
            "newer diagnostic" & Natural'Image (I),
            "external",
            Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target    => True,
            Target_Buffer => S.Registry_Token,
            Target_Line   => 1,
            Target_Column => 1);
      end loop;
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Diagnostics activation rejects trimmed Diagnostic_Id rows");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "trimmed Diagnostics activation leaves caret unchanged");
   end Test_Diagnostics_Activation_Rejects_No_Target_Stale_And_Trimmed_Rows;

   procedure Test_Diagnostics_Filter_Text_Composes_And_Preserves_Source_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D          : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      First_Id   : Editor.Feature_Diagnostics.Diagnostic_Id;
      Second_Id  : Editor.Feature_Diagnostics.Diagnostic_Id;
      Before_Rows : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "alpha parser error", "compiler",
         Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Warning, "beta style warning", "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      First_Id := Editor.Feature_Diagnostics.Item_Id (D, 1);
      Second_Id := Editor.Feature_Diagnostics.Item_Id (D, 2);
      Before_Rows := Editor.Feature_Diagnostics.Row_Count (D);

      Editor.Feature_Diagnostics.Set_Filter_Text (D, " ALPHA ");
      Assert (Editor.Feature_Diagnostics.Filter_Active (D),
              "Diagnostics text filter becomes active after normalization");
      Assert (Editor.Feature_Diagnostics.Filter_Text (D) = "alpha",
              "Diagnostics text filter is normalized deterministically");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "Diagnostics text filter hides nonmatching rows");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = Before_Rows,
              "Diagnostics text filter does not mutate source rows");
      Assert (Editor.Feature_Diagnostics.Item_Id (D, 1) = First_Id
              and then Editor.Feature_Diagnostics.Item_Id (D, 2) = Second_Id,
              "Diagnostics text filter preserves Diagnostic_Id identity");

      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (D, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 0,
              "Diagnostics text and source filters compose deterministically");
      Editor.Feature_Diagnostics.Show_All (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = Before_Rows,
              "Diagnostics Show_All restores all source rows to projection");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = Before_Rows,
              "Diagnostics filter clearing remains projection-only");
   end Test_Diagnostics_Filter_Text_Composes_And_Preserves_Source_Rows;

   procedure Test_Diagnostics_Explicit_Id_Activation_Validates_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Result         : Editor.Executor.Command_Execution_Result;
      Valid_Id       : Editor.Feature_Diagnostics.Diagnostic_Id;
      Wrong_Buffer_Id : Editor.Feature_Diagnostics.Diagnostic_Id;
      Removed        : Boolean := False;
      Before         : Editor.Cursors.Cursor_Index;
      After_Valid    : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "explicit id target",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 2,
         Target_Column => 2);
      Valid_Id := Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 1);

      Assert (Editor.Feature_Diagnostics.Map_Diagnostic_Id_To_Item
                (S.Feature_Diagnostics, Valid_Id) = 1,
              "explicit Diagnostic_Id maps to its live source row");
      Assert (Editor.Feature_Diagnostics.Diagnostic_Id_Is_Live
                (S.Feature_Diagnostics, Valid_Id),
              "explicit Diagnostic_Id reports live identity before activation");
      Assert (Editor.Feature_Diagnostics.Validate_Diagnostic_Id_Target
                (S.Feature_Diagnostics, Valid_Id, S.Registry_Token),
              "explicit Diagnostic_Id target validates against active buffer token");

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Id_Activation (S, Valid_Id);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "explicit Diagnostic_Id activation succeeds for valid active-buffer target");
      Assert (S.Carets (S.Carets.First_Index).Pos /= Before,
              "explicit Diagnostic_Id activation moves caret only after validation");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "explicit Diagnostic_Id activation does not mutate diagnostic rows");
      After_Valid := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Id_Activation
        (S, Editor.Feature_Diagnostics.No_Diagnostic);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "explicit Diagnostic_Id activation rejects No_Diagnostic");
      Assert (S.Carets (S.Carets.First_Index).Pos = After_Valid,
              "rejected No_Diagnostic activation leaves caret unchanged");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "wrong buffer target",
         "external",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token + 1,
         Target_Line   => 1,
         Target_Column => 1);
      Wrong_Buffer_Id := Editor.Feature_Diagnostics.Item_Id (S.Feature_Diagnostics, 2);
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Id_Activation
        (S, Wrong_Buffer_Id);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "explicit Diagnostic_Id activation rejects inactive-buffer targets");
      Assert (S.Carets (S.Carets.First_Index).Pos = After_Valid,
              "rejected inactive-buffer Diagnostic_Id leaves caret unchanged");

      Removed := Editor.Feature_Diagnostics.Clear_Diagnostic_By_Id
        (S.Feature_Diagnostics, Valid_Id);
      Assert (Removed,
              "explicit Diagnostic_Id cleanup removes the live diagnostic");
      Assert (not Editor.Feature_Diagnostics.Diagnostic_Id_Is_Live
                (S.Feature_Diagnostics, Valid_Id),
              "cleared Diagnostic_Id is no longer live");
      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Id_Activation (S, Valid_Id);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "explicit Diagnostic_Id activation rejects trimmed or cleared ids");
      Assert (S.Carets (S.Carets.First_Index).Pos = After_Valid,
              "rejected cleared Diagnostic_Id leaves caret unchanged");
   end Test_Diagnostics_Explicit_Id_Activation_Validates_Target;

   procedure Test_Diagnostics_Navigation_No_Visible_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Select_Next);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "Diagnostics next with no rows is explicitly unavailable");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) /=
              Editor.Feature_Panel.Diagnostics_Feature,
              "Diagnostics next with no rows does not show an empty shell");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 0,
              "Diagnostics next with no rows leaves selection absent");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Info,
         "hidden info",
         "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Toggle_Info_Visible (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Select_Previous);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "Diagnostics previous with all rows filtered is explicitly unavailable");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "Diagnostics filtered navigation no-op does not mutate source rows");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 0,
              "Diagnostics filtered navigation no-op leaves selection absent");
   end Test_Diagnostics_Navigation_No_Visible_Is_No_Op;

   procedure Test_Search_Results_Contract_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Editor.Search_Results_Audit.Search_Results_Contract_Review;
   begin
      Editor.State.Init (S);
      Review := Editor.Search_Results_Audit.Review_Search_Results_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review));
      Assert (Review.Active_Buffer_Only,
              "Search Results remain active-buffer scoped");
      Assert (Review.Search_Command_Owned,
              "Search Results remain command-owned");
      Assert (Review.Matching_Deterministic,
              "Search Results matching remains deterministic");
      Assert (Review.Query_Input_Non_Mutating,
              "Search Results query input cannot edit the buffer");
      Assert (Review.Feature_Panel_Intact,
              "Feature Panel sentinel stays healthy");
      Assert (Review.Command_Surface_Intact,
              "command surface sentinel stays healthy");
      Assert (Review.Public_Build_Guardrail_Intact,
              "public-build manifest sentinel stays healthy");
   end Test_Search_Results_Contract_Review_Default_Passes;

   procedure Test_Search_Results_Contract_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S                : Editor.State.State_Type;
      Before_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Before_Query     : Ada.Strings.Unbounded.Unbounded_String;
      Before_Rows      : Natural;
      Before_History   : Natural;
      Before_Selected  : Natural;
      Before_Feature   : Editor.Feature_Panel.Feature_Id;
      Review           : Editor.Search_Results_Audit.Search_Results_Contract_Review;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "alpha" & ASCII.LF);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, "alpha", Editor.State.Current_Text (S),
         "buffer", S.Registry_Token, Editor.State.Current_Buffer_Revision (S));
      Editor.Feature_Search_Results.Commit_Search_Query_To_History
        (S.Feature_Search_Results, "alpha");
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);

      Before_Text := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.State.Current_Text (S));
      Before_Query := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results));
      Before_Rows := Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results);
      Before_History := Editor.Feature_Search_Results.Search_Query_History_Count
        (S.Feature_Search_Results);
      Before_Selected := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Before_Feature := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);

      Review := Editor.Search_Results_Audit.Review_Search_Results_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review));
      Assert (Editor.State.Current_Text (S) = Ada.Strings.Unbounded.To_String (Before_Text),
              "review does not mutate active-buffer text");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
                Ada.Strings.Unbounded.To_String (Before_Query),
              "review does not mutate Search Results query text");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = Before_Rows,
              "review does not replace Search Results rows");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count
                (S.Feature_Search_Results) = Before_History,
              "review does not mutate query history");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = Before_Selected,
              "review does not change Feature Panel selection");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) = Before_Feature,
              "review does not switch Feature Panel feature");
   end Test_Search_Results_Contract_Review_Is_Side_Effect_Free;

   procedure Test_Search_Results_Contract_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Editor.Search_Results_Audit.Search_Results_Contract_Review;
   begin
      Review := (others => True);
      Assert (Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review) =
                "Search: contract healthy",
              "healthy Search Results feedback is deterministic");
      Review.Review_Passed := False;
      Review.Active_Buffer_Only := False;
      Assert (Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review) =
                "Search: active-buffer scope failed",
              "active-buffer failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Targets_Validated := False;
      Assert (Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review) =
                "Search: target validation failed",
              "target-validation failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Editor.Search_Results_Audit.Build_Search_Results_Contract_Review_Feedback (Review) =
                "Search: public build guardrail failed",
              "public-build sentinel feedback is deterministic");
   end Test_Search_Results_Contract_Review_Feedback_Is_Deterministic;

   procedure Test_Search_Results_Active_Buffer_Only_And_Targets_Validated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Editor.Search_Results_Audit.Search_Results_Contract_Review;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "needle" & ASCII.LF);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results, "needle", Editor.State.Current_Text (S),
         "buffer", S.Registry_Token, Editor.State.Current_Buffer_Revision (S));
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);

      Review := Editor.Search_Results_Audit.Review_Search_Results_Contract (S);
      Assert (Review.Active_Buffer_Only,
              "review accepts only active-buffer Search Results targets");
      Assert (Review.Targets_Validated,
              "review confirms Search Results target validation");
      Assert (not Editor.Feature_Search_Results.Validate_Search_Result_Target
        (S.Feature_Search_Results, 1, Editor.Feature_Search_Results.No_Buffer),
              "target validation rejects absent active buffer token");
      Assert (Editor.Feature_Search_Results.Validate_Search_Result_Target
        (S.Feature_Search_Results, 1, S.Registry_Token),
              "target validation accepts matching active buffer token");
   end Test_Search_Results_Active_Buffer_Only_And_Targets_Validated;

   procedure Test_Search_Results_Query_History_Bounded_And_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Editor.Search_Results_Audit.Search_Results_Contract_Review;
   begin
      Editor.State.Init (S);
      for I in 1 .. 25 loop
         Editor.Feature_Search_Results.Commit_Search_Query_To_History
           (S.Feature_Search_Results, "query-" & Natural'Image (I));
      end loop;

      Review := Editor.Search_Results_Audit.Review_Search_Results_Contract (S);
      Assert (Review.Query_History_Bounded,
              "query history remains bounded by the Search Results model");
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count
                (S.Feature_Search_Results) = 20,
              "query history keeps only the bounded session-local tail");

      Editor.Feature_Search_Results.Reset_Search_Results_For_Workspace_Close
        (S.Feature_Search_Results);
      Assert (Editor.Feature_Search_Results.Search_Query_History_Count
                (S.Feature_Search_Results) = 0,
              "workspace close proves query history is not persisted");
   end Test_Search_Results_Query_History_Bounded_And_Not_Persisted;

   procedure Test_Search_Results_Open_Selected_Rejects_Stale_And_Out_Of_Range_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "stale",
         Source_Label  => "buffer",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 99,
         Target_Column => 1,
         Query         => "two",
         Line_Text     => "two",
         Match_Line    => 99,
         Match_Column  => 1,
         Match_Length  => 3);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "out-of-range Search Results target is rejected");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "failed Search Results activation does not move caret");
   end Test_Search_Results_Open_Selected_Rejects_Stale_And_Out_Of_Range_Targets;


   procedure Test_Search_Results_Activation_Rejects_Out_Of_Range_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "bad column",
         Source_Label  => "buffer",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 99,
         Query         => "abc",
         Line_Text     => "abc",
         Match_Line    => 1,
         Match_Column  => 99,
         Match_Length  => 3);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Search Results activation rejects out-of-range column");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "rejected Search Results activation does not move caret");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "rejected Search Results activation does not mutate rows");
   end Test_Search_Results_Activation_Rejects_Out_Of_Range_Column;

   procedure Test_Messages_Row_Display_Empty_And_Long_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Editor.Feature_Messages.Message_Feature_State;
      P : Feature_Panel_State;
      Long_Text : constant String :=
        "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz" &
        "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz" &
        "abcdefghijklmnopqrstuvwxyz";
   begin
      Editor.Feature_Messages.Add_Message
        (M, Editor.Feature_Messages.Info_Message, "");
      Editor.Feature_Messages.Add_Message
        (M, Editor.Feature_Messages.Warning_Message, Long_Text,
         Source_Kind => Editor.Feature_Messages.Command_Source);
      Editor.Feature_Messages.Add_Message
        (M, Editor.Feature_Messages.Error_Message, "failed", "compiler");
      Editor.Feature_Messages.Project_Rows (M, P);

      Assert (Row_Label (P, 2) = "info: (empty message)",
              "empty message text uses deterministic fallback label");
      Assert (Ada.Strings.Fixed.Index (Row_Label (P, 3), "warning: ") = 1,
              "warning severity remains visible in row label");
      Assert (Ada.Strings.Fixed.Index (Row_Label (P, 3), "...") /= 0,
              "long message labels are deterministically trimmed");
      Assert (Row_Detail (P, 3) = "command",
              "source kind is displayed when no source label exists");
      Assert (Row_Detail (P, 4) = "compiler",
              "source label is displayed deterministically");
      Assert (Row_Severity (P, 4) = Feature_Row_Error_Severity,
              "error severity remains projected as row metadata");
   end Test_Messages_Row_Display_Empty_And_Long_Text;


   procedure Test_Messages_Empty_State_Is_Not_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Editor.Feature_Messages.Message_Feature_State;
      P : Feature_Panel_State;
   begin
      Editor.Feature_Messages.Project_Rows (M, P);

      Assert (Row_Count (P) = 2,
              "Messages projection keeps header plus deterministic empty state");
      Assert (Row_Label (P, 2) = "No messages",
              "empty Messages row has deterministic label");
      Assert (Row_Detail (P, 2) = "Command feedback appears here; nothing to clear.",
              "empty Messages row has useful deterministic detail");
      Assert (not Row_Is_Selectable (P, 2),
              "empty Messages row is not selectable");
      Assert (not Row_Is_Activatable (P, 2),
              "empty Messages row is not activatable");
      Assert (Editor.Feature_Messages.Map_Message_Row_To_Item (M, P, 2) = 0,
              "empty Messages row is not mapped to a source message");
   end Test_Messages_Empty_State_Is_Not_Actionable;


   procedure Test_Messages_Activation_Rejects_Out_Of_Range_Position
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural;
      Col    : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "bad target", "main.adb", True, S.Registry_Token, 2, 99);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);
      Editor.State.Row_Col_For_Index
        (S, S.Carets.Element (S.Carets.First_Index).Pos, Row, Col);

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "Messages activation rejects out-of-range columns");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 0,
              "failed Messages activation does not select stale target rows");
      declare
         After_Row : Natural;
         After_Col : Natural;
      begin
         Editor.State.Row_Col_For_Index
           (S, S.Carets.Element (S.Carets.First_Index).Pos, After_Row, After_Col);
         Assert (After_Row = Row and then After_Col = Col,
                 "failed Messages activation does not move the caret");
      end;
   end Test_Messages_Activation_Rejects_Out_Of_Range_Position;


   procedure Test_Messages_Retention_Trims_Oldest_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Editor.Feature_Messages.Message_Feature_State;
      P : Feature_Panel_State;
   begin
      for I in 1 .. Editor.Feature_Messages.Max_Retained_Messages + 1 loop
         Editor.Feature_Messages.Add_Message
           (M, Editor.Feature_Messages.Info_Message,
            "message" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both));
      end loop;
      Editor.Feature_Messages.Project_Rows (M, P);

      Assert (Editor.Feature_Messages.Row_Count (M) =
              Editor.Feature_Messages.Max_Retained_Messages,
              "Messages retention remains bounded");
      Assert (Editor.Feature_Messages.Item_Text (M, 1) = "message2",
              "Messages retention trims the oldest source row first");
      Assert (Editor.Feature_Messages.Map_Message_Row_To_Item (M, P, 2) = 1,
              "retained first visible row maps to the first retained source item");
   end Test_Messages_Retention_Trims_Oldest_Deterministically;



   procedure Test_Clear_Empty_Rows_Does_Not_Bump_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Before : Natural := 0;
   begin
      Before := Editor.Feature_Panel.Projection_Generation (Panel);
      Editor.Feature_Panel.Clear_Rows (Panel);
      Assert
        (Editor.Feature_Panel.Projection_Generation (Panel) = Before,
         "clearing already-empty feature rows must not churn projection generation");

      Editor.Feature_Panel.Append_Row
        (Panel, Editor.Feature_Panel.Feature_Row_Item, "one");
      Before := Editor.Feature_Panel.Projection_Generation (Panel);
      Editor.Feature_Panel.Clear_Rows (Panel);
      Assert
        (Editor.Feature_Panel.Projection_Generation (Panel) /= Before,
         "clearing non-empty feature rows must still change projection generation");
   end Test_Clear_Empty_Rows_Does_Not_Bump_Projection;

   procedure Test_Unchanged_Header_Does_Not_Churn_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Before : constant Editor.Feature_Panel.Feature_Panel_Fingerprint :=
        Editor.Feature_Panel.Fingerprint (Panel);
   begin
      Editor.Feature_Panel.Set_Header_Text
        (Panel, Editor.Feature_Panel.Header_Text (Panel));
      declare
         After : constant Editor.Feature_Panel.Feature_Panel_Fingerprint :=
           Editor.Feature_Panel.Fingerprint (Panel);
      begin
         Assert
           (After.Visible = Before.Visible
            and then After.Focused = Before.Focused
            and then After.Row_Count = Before.Row_Count
            and then After.Has_Selection = Before.Has_Selection
            and then After.Selected_Row = Before.Selected_Row
            and then After.Row_Labels_Hash = Before.Row_Labels_Hash
            and then After.Row_Details_Hash = Before.Row_Details_Hash,
            "setting the same feature-panel header must leave state fingerprint stable");
      end;
   end Test_Unchanged_Header_Does_Not_Churn_State;


   procedure Test_Feature_Panel_Scroll_Clamps_And_Preserves_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 12 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "Row" & Natural'Image (I), Selectable => True);
      end loop;
      Select_Row (Panel, 2);

      Scroll_By (Panel, 4);
      Assert (First_Visible_Row (Panel) = 5,
              "feature panel wheel scroll advances only viewport");
      Assert (Selected_Row (Panel) = 2,
              "feature panel wheel scroll does not mutate selection");

      Scroll_By (Panel, 100);
      Assert (First_Visible_Row (Panel) = 10,
              "feature panel scroll clamps at final legal top row");

      Scroll_By (Panel, -100);
      Assert (First_Visible_Row (Panel) = 1,
              "feature panel scroll clamps at first row");

      Clear_Rows (Panel);
      Assert (First_Visible_Row (Panel) = 1 and then Selected_Row (Panel) = 0,
              "clearing feature rows resets viewport and selection safely");
   end Test_Feature_Panel_Scroll_Clamps_And_Preserves_Selection;


   procedure Test_Search_Result_Activation_Focuses_Source_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "needle in A" & ASCII.LF & "tail");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "buffer B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);

      Assert
        (Editor.Feature_Search_Results.Item_Target_Buffer
           (S.Feature_Search_Results, 1) = Natural (A_Id),
         "search result rows remember the producing buffer");

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert
        (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
         "switching buffers does not clear Search Results rows");
      Assert
        (Editor.Feature_Search_Results.Item_Target_Buffer
           (S.Feature_Search_Results, 1) = Natural (A_Id),
         "switching buffers does not retarget Search Results rows");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);

      Assert
        (Editor.Buffers.Global_Active_Buffer = A_Id,
         "activating an inactive-buffer Search Result focuses its source buffer");
      Assert
        (Editor.Executor.Safe_Caret (S) = 0,
         "activation moves the caret only after source-buffer validation");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Search_Result_Activation_Focuses_Source_Buffer;

   procedure Test_Diagnostic_Activation_Failure_Leaves_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "bad line", "A",
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True, Target_Buffer => Natural (A_Id),
         Target_Line => 99, Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      declare
         Ignored : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Diagnostics_Feature);
         pragma Unreferenced (Ignored);
      begin
         null;
      end;

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);

      Assert
        (Editor.Buffers.Global_Active_Buffer = B_Id,
         "failed cross-buffer Diagnostic activation preserves the active buffer");
      Assert
        (Editor.Executor.Safe_Caret (S) = 0,
         "failed cross-buffer Diagnostic activation preserves the cursor");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostic_Activation_Failure_Leaves_Active_Buffer;



   procedure Test_Feature_Switch_Preserves_Per_Feature_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package Demo" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF &
         "body" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "can show Outline rows");
      Assert (Row_Count (S.Feature_Panel) >= 2,
              "Outline projection has selectable rows");
      Select_Row (S.Feature_Panel, 2);

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages,
         Editor.Feature_Messages.Info_Message,
         "message",
         Source_Kind => Editor.Feature_Messages.Editor_Source);

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "can switch to Messages");
      Assert (Active_Feature (S.Feature_Panel) = Messages_Feature,
              "Messages becomes active feature");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "Outline selection is not reused as a Messages selection");
      Assert (Row_Count (S.Feature_Panel) >= 2,
              "Messages projection contains header and message row");
      Select_Row (S.Feature_Panel, 2);

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "can switch back to Outline");
      Assert (Active_Feature (S.Feature_Panel) = Outline_Feature,
              "Outline becomes active feature again");
      Assert (Selected_Row (S.Feature_Panel) = 2,
              "Outline selection survives active-feature switching");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "can switch back to Messages");
      Assert (Selected_Row (S.Feature_Panel) = 2,
              "Messages selection survives active-feature switching");
   end Test_Feature_Switch_Preserves_Per_Feature_Selection;

   procedure Test_Feature_Switch_Preserves_Per_Feature_Scroll_And_Clamps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
      Switched : Boolean;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 12 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "Outline" & Natural'Image (I), Selectable => True);
      end loop;
      Select_Row (Panel, 4);
      Scroll_By (Panel, 5);
      Assert (First_Visible_Row (Panel) = 7,
              "setup records Outline scroll offset");

      Switched := Set_Active_Feature (Panel, Search_Results_Feature);
      Assert (Switched, "can switch generic panel to Search Results");
      Clear_Rows (Panel);
      Append_Row (Panel, Feature_Row_Item, "Search 1", Selectable => True);
      Append_Row (Panel, Feature_Row_Item, "Search 2", Selectable => True);
      Restore_Active_Feature_View_State (Panel);
      Assert (Selected_Row (Panel) = 0,
              "unsaved Search selection starts empty, not inherited");
      Select_Row (Panel, 2);

      Switched := Set_Active_Feature (Panel, Outline_Feature);
      Assert (Switched, "can switch generic panel back to Outline");
      Clear_Rows (Panel);
      for I in 1 .. 12 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "Outline" & Natural'Image (I), Selectable => True);
      end loop;
      Restore_Active_Feature_View_State (Panel);
      Assert (Selected_Row (Panel) = 4,
              "Outline selection is restored from its own view state");
      Assert (First_Visible_Row (Panel) = 7,
              "Outline scroll offset is restored from its own view state");

      Switched := Set_Active_Feature (Panel, Search_Results_Feature);
      Assert (Switched, "can switch generic panel back to Search Results");
      Clear_Rows (Panel);
      Append_Row (Panel, Feature_Row_Item, "Search 1", Selectable => True);
      Restore_Active_Feature_View_State (Panel);
      Assert (Selected_Row (Panel) = 0,
              "stale saved Search selection clears when row count shrinks");
      Assert (First_Visible_Row (Panel) = 1,
              "stale saved Search scroll clamps after row count shrinks");
   end Test_Feature_Switch_Preserves_Per_Feature_Scroll_And_Clamps;



   procedure Test_Empty_State_Rows_Are_Not_Selected_Or_Openable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Outline_Feature),
              "can show empty Outline feature");
      Assert (Row_Count (S.Feature_Panel) = 1,
              "empty Outline projects a deterministic empty-state row");
      Assert (Row_Kind (S.Feature_Panel, 1) = Feature_Row_Empty_State,
              "empty Outline row is explicitly an empty state");
      Assert (not Row_Is_Selectable (S.Feature_Panel, 1),
              "empty-state row is not selectable");
      Assert (not Row_Can_Open (S.Feature_Panel, 1),
              "empty-state row is not openable");

      Select_First (S.Feature_Panel);
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "selecting an empty state leaves no selected row");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (not Editor.Commands.Is_Available (Availability),
              "open-selected is unavailable with no selected feature row");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (not Editor.Commands.Is_Available (Availability),
              "clear is unavailable when only an empty-state row is visible");
   end Test_Empty_State_Rows_Are_Not_Selected_Or_Openable;

   procedure Test_Row_Replacement_Clears_Invalid_Selection_And_Clamps_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 10 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "old" & Natural'Image (I), Selectable => True, Can_Open => True);
      end loop;
      Select_Row (Panel, 8);
      Scroll_By (Panel, 7);
      Assert (Selected_Row (Panel) = 8 and then First_Visible_Row (Panel) = 8,
              "setup has deep selection and scroll state");

      Clear_Rows (Panel);
      Append_Row
        (Panel, Feature_Row_Empty_State, "No search results.",
         Selectable => False, Activatable => False, Can_Open => False);
      Restore_Active_Feature_View_State (Panel);

      Assert (Selected_Row (Panel) = 0,
              "replacement with empty state clears stale selection");
      Assert (First_Visible_Row (Panel) = 1,
              "replacement with empty state clamps scroll offset");
      Assert (not Has_Clearable_Row (Panel),
              "empty replacement does not expose clearable rows");
   end Test_Row_Replacement_Clears_Invalid_Selection_And_Clamps_Scroll;

   procedure Test_Clear_Active_Feature_Does_Not_Clear_Sibling_Feature
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package Demo" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF &
         "needle" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Outline.Item_Count (S.Outline) >= 2,
              "setup has Outline rows");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "setup has Search Results rows");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
              "active feature can be Search Results");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "clear active Search Results executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "clear removes active Search Results rows");
      Assert (Editor.Outline.Item_Count (S.Outline) >= 2,
              "clear does not mutate sibling Outline rows");
   end Test_Clear_Active_Feature_Does_Not_Clear_Sibling_Feature;


   procedure Test_Forget_View_State_Blocks_Stale_Selection_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel   : Feature_Panel_State;
      Switched : Boolean;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 8 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "outline old" & Natural'Image (I), Selectable => True,
            Activatable => True, Has_Target => True, Can_Open => True);
      end loop;
      Select_Row (Panel, 7);
      Scroll_By (Panel, 5);

      Switched := Set_Active_Feature (Panel, Search_Results_Feature);
      Assert (Switched, "setup saves old Outline view state");
      Forget_Feature_View_State (Panel, Outline_Feature);

      Switched := Set_Active_Feature (Panel, Outline_Feature);
      Assert (Switched, "can return to Outline after forgetting stale state");
      Clear_Rows (Panel);
      Append_Row
        (Panel, Feature_Row_Item, "outline fresh 1", Selectable => True,
         Activatable => True, Has_Target => True, Can_Open => True);
      Append_Row
        (Panel, Feature_Row_Item, "outline fresh 2", Selectable => True,
         Activatable => True, Has_Target => True, Can_Open => True);
      Restore_Active_Feature_View_State (Panel);

      Assert (Selected_Row (Panel) = 0,
              "forgotten stale Outline selection is not restored onto fresh rows");
      Assert (First_Visible_Row (Panel) = 1,
              "forgotten stale Outline scroll is not restored onto fresh rows");
      Assert (Row_Count (Panel) = 2,
              "fresh recovered rows remain visible after stale view-state cleanup");
   end Test_Forget_View_State_Blocks_Stale_Selection_Restore;

   procedure Test_Search_Rerun_After_Clear_Recovers_Fresh_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Result       : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "needle one" & ASCII.LF &
         "middle" & ASCII.LF &
         "needle two" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial Search execution succeeds");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "setup has initial Search rows");

      Select_Row (S.Feature_Panel, 2);
      Scroll_By (S.Feature_Panel, 20);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Search_Results_Feature);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Search clear executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "Search clear removes old rows");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Search rerun after clear executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "Search rerun repopulates fresh rows");
      Assert (Active_Feature (S.Feature_Panel) = Search_Results_Feature,
              "Search recovery projects the Search Results feature");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "Search recovery selects the first fresh row by policy");
      Assert (First_Visible_Row (S.Feature_Panel) = 1,
              "Search recovery resets stale scroll offset");
      Assert
        (Editor.Feature_Search_Results.Item_Target_Buffer
           (S.Feature_Search_Results, 1) /= Editor.Feature_Search_Results.No_Buffer,
         "recovered Search row has fresh buffer-aware target metadata");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Assert (Editor.Commands.Is_Available (Availability),
              "open-selected is available after fresh Search recovery");
   end Test_Search_Rerun_After_Clear_Recovers_Fresh_Rows;

   procedure Test_Inactive_Diagnostics_Recovery_Does_Not_Steal_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "needle" & ASCII.LF & "body" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Active_Feature (S.Feature_Panel) = Search_Results_Feature,
              "setup has Search Results active");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "can show Diagnostics before recovery");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "old diagnostic", "old source",
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True, Target_Buffer => 1,
         Target_Line => 1, Target_Column => 1);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Select_First (S.Feature_Panel);
      Assert (Selected_Row (S.Feature_Panel) /= 0,
              "setup records a Diagnostics selection");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Search_Results_Feature),
              "can return to Search Results before inactive recovery");
      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "fresh diagnostic", "fresh source",
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True, Target_Buffer => 1,
         Target_Line => 1, Target_Column => 1);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);

      Assert (Active_Feature (S.Feature_Panel) = Search_Results_Feature,
              "inactive Diagnostics recovery does not steal the active Search view");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "inactive Diagnostics recovery preserves Search rows");

      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "switching to recovered Diagnostics succeeds");
      Assert (Row_Count (S.Feature_Panel) = 1,
              "recovered Diagnostics projects only the fresh row");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "recovered Diagnostics starts from a valid fresh selection");
      Assert (Row_Label (S.Feature_Panel, 1) /= "old diagnostic",
              "old invalid Diagnostic row is not projected after recovery");
   end Test_Inactive_Diagnostics_Recovery_Does_Not_Steal_View;


   procedure Test_Repeated_Outline_Refresh_Invalidates_Old_Row_Handle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Result     : Editor.Executor.Command_Execution_Result;
      Old_Gen    : Natural;
      Fresh_Gen  : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "@outline package First" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial Outline refresh executes");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "initial Outline refresh projects two rows");
      Old_Gen := Projection_Generation (S.Feature_Panel);

      Editor.State.Load_Text
        (S,
         "@outline package Second" & ASCII.LF &
         "@outline function Compute" & ASCII.LF);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second Outline refresh executes");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "second Outline refresh replaces rows without duplicates");
      Fresh_Gen := Projection_Generation (S.Feature_Panel);
      Assert (Fresh_Gen /= Old_Gen,
              "repeated Outline refresh advances the projection handle generation");
      Assert (Contains (Row_Label (S.Feature_Panel, 1), "Second"),
              "second Outline refresh shows fresh labels");

      Result := Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation
        (S, 1, Expected_Panel_Generation => Old_Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "old Outline row handle is rejected after replacement");
      Assert (Selected_Row (S.Feature_Panel) <= Row_Count (S.Feature_Panel),
              "stale Outline activation leaves selection in range");
   end Test_Repeated_Outline_Refresh_Invalidates_Old_Row_Handle;

   procedure Test_Repeated_Search_Rerun_Replaces_And_Handles_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Result    : Editor.Executor.Command_Execution_Result;
      Old_Gen   : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "needle one" & ASCII.LF &
         "middle" & ASCII.LF &
         "needle two" & ASCII.LF);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial Search rerun executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "initial Search has two source results");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "initial Search projection has two rows");
      Old_Gen := Projection_Generation (S.Feature_Panel);

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "absent");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Search rows-to-no-results rerun executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "no-results rerun clears source results");
      Assert (Row_Count (S.Feature_Panel) = 1
              and then Row_Kind (S.Feature_Panel, 1) = Feature_Row_Empty_State,
              "no-results rerun projects a deterministic empty-state row");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "rows-to-no-results rerun clears selection");
      Assert (First_Visible_Row (S.Feature_Panel) = 1,
              "rows-to-no-results rerun clamps scroll");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation
        (S, 1, Expected_Panel_Generation => Old_Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "old Search row handle is rejected after no-results replacement");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "needle");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Search no-results-to-rows rerun executes");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "Search no-results-to-rows rerun restores two fresh source results");
      Assert (Row_Count (S.Feature_Panel) = 2,
              "Search no-results-to-rows rerun replaces empty state without duplicates");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "Search no-results-to-rows rerun selects the first fresh result");
   end Test_Repeated_Search_Rerun_Replaces_And_Handles_Empty;

   procedure Test_Repeated_Diagnostics_Clear_Regenerate_Rejects_Old_Handle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Result  : Editor.Executor.Command_Execution_Result;
      Old_Gen : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Diagnostics_Feature),
              "can show Diagnostics feature");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "old diagnostic", "",
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True, Target_Buffer => 1,
         Target_Line => 1, Target_Column => 1);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 1,
              "Diagnostics projects initial row");
      Old_Gen := Projection_Generation (S.Feature_Panel);

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 1
              and then Row_Kind (S.Feature_Panel, 1) = Feature_Row_Empty_State,
              "Diagnostics clear leaves deterministic empty state");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "Diagnostics clear resets selection");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "fresh diagnostic", "",
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target => True, Target_Buffer => 1,
         Target_Line => 2, Target_Column => 1);
      Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
        (S.Feature_Diagnostics, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 1,
              "Diagnostics regenerate creates one fresh row");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "Diagnostics regenerate selects a valid fresh row");
      Assert (Row_Label (S.Feature_Panel, 1) /= "old diagnostic",
              "Diagnostics regenerate does not project old diagnostic row");

      Result := Editor.Executor.Diagnostics_Commands.Execute_Diagnostic_Row_Activation
        (S, 1, Expected_Panel_Generation => Old_Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "old Diagnostic row handle is rejected after clear/regenerate");
   end Test_Repeated_Diagnostics_Clear_Regenerate_Rejects_Old_Handle;

   procedure Test_Repeated_Messages_Clear_Regenerate_Rejects_Old_Handle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Result  : Editor.Executor.Command_Execution_Result;
      Old_Gen : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Assert (Editor.Feature_Panel_Controller.Show_Feature (S, Messages_Feature),
              "can show Messages feature");
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages,
         Editor.Feature_Messages.Info_Message,
         "old message", "",
         Has_Target => True, Buffer => 1, Line => 1, Column => 1,
         Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
        (S.Feature_Messages, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 2,
              "Messages projects header and initial message row");
      Old_Gen := Projection_Generation (S.Feature_Panel);

      Editor.Feature_Messages.Clear (S.Feature_Messages);
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
        (S.Feature_Messages, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 2
              and then Row_Kind (S.Feature_Panel, 2) = Feature_Row_Empty_State,
              "Messages clear leaves header plus deterministic empty state");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "Messages clear resets selection");

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages,
         Editor.Feature_Messages.Warning_Message,
         "fresh message", "",
         Has_Target => True, Buffer => 1, Line => 2, Column => 1,
         Source_Kind => Editor.Feature_Messages.Editor_Source);
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
        (S.Feature_Messages, S.Feature_Panel);
      Assert (Row_Count (S.Feature_Panel) = 2,
              "Messages regenerate creates header and one fresh row");
      Assert (Selected_Row (S.Feature_Panel) = 0,
              "Messages regenerate does not restore a stale old selection");
      Select_Row (S.Feature_Panel, 2);
      Assert (Contains (Row_Label (S.Feature_Panel, 2), "fresh message"),
              "Messages regenerate projects fresh row text");

      Result := Editor.Executor.Message_Commands.Execute_Message_Row_Activation
        (S, 2, Expected_Panel_Generation => Old_Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "old Message row handle is rejected after clear/regenerate");
   end Test_Repeated_Messages_Clear_Regenerate_Rejects_Old_Handle;


   procedure Test_Keyboard_Selection_Reveals_And_Clamps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 8 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "row" & Natural'Image (I),
            Selectable => True, Activatable => True, Has_Target => True);
      end loop;

      Select_First (Panel);
      Assert (Selected_Row (Panel) = 1,
              "initial keyboard selection starts at first row");
      Assert (First_Visible_Row (Panel) = 1,
              "first selected row is initially visible");

      for I in 1 .. 12 loop
         Select_Next (Panel);
      end loop;
      Assert (Selected_Row (Panel) = 8,
              "repeated Down clamps at last selectable row");
      Assert (First_Visible_Row (Panel) = 6,
              "repeated Down reveals the selected last row");
      Assert (Visible_Row_To_Row_Index (Panel, 3) = 8,
              "viewport mapping points at the revealed last row");

      for I in 1 .. 12 loop
         Select_Previous (Panel);
      end loop;
      Assert (Selected_Row (Panel) = 1,
              "repeated Up clamps at first selectable row");
      Assert (First_Visible_Row (Panel) = 1,
              "repeated Up reveals the selected first row");
   end Test_Keyboard_Selection_Reveals_And_Clamps;

   procedure Test_Mouse_Row_Mapping_Respects_Scroll
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 3);
      for I in 1 .. 8 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "row" & Natural'Image (I),
            Selectable => True, Activatable => True, Has_Target => True);
      end loop;

      Scroll_By (Panel, 4);
      Assert (First_Visible_Row (Panel) = 5,
              "setup scrolls to a later visible window");
      Assert (Visible_Row_To_Row_Index (Panel, 1) = 5,
              "first clicked visible row maps through scroll offset");
      Assert (Visible_Row_To_Row_Index (Panel, 2) = 6,
              "middle clicked visible row maps through scroll offset");
      Assert (Visible_Row_To_Row_Index (Panel, 3) = 7,
              "last clicked visible row maps through scroll offset");
      Assert (Visible_Row_To_Row_Index (Panel, 4) = 0,
              "pointer row beyond viewport cannot activate hidden rows");

      Select_Row (Panel, Visible_Row_To_Row_Index (Panel, 2));
      Assert (Selected_Row (Panel) = 6,
              "mouse-style selection selects the live scrolled row");
      Assert (First_Visible_Row (Panel) = 5,
              "selecting an already visible mouse row preserves scroll calmness");
   end Test_Mouse_Row_Mapping_Respects_Scroll;

   procedure Test_Clear_And_Empty_Navigation_Reset_View_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panel : Feature_Panel_State;
   begin
      Set_Visible (Panel, True);
      Set_Visible_Row_Count (Panel, 2);
      for I in 1 .. 5 loop
         Append_Row
           (Panel, Feature_Row_Item,
            "row" & Natural'Image (I),
            Selectable => True);
      end loop;

      Select_Row (Panel, 5);
      Assert (Selected_Row (Panel) = 5 and then First_Visible_Row (Panel) = 4,
              "setup has a selected row at the end of a scrolled view");

      Clear_Rows (Panel);
      Assert (Row_Count (Panel) = 0,
              "clear removes rows");
      Assert (Selected_Row (Panel) = 0,
              "clear removes selection");
      Assert (First_Visible_Row (Panel) = 1,
              "clear resets scroll to deterministic empty view");
      Assert (Visible_Row_To_Row_Index (Panel, 1) = 0,
              "empty view maps no visible row to a feature target");

      Select_Next (Panel);
      Select_Previous (Panel);
      Assert (Selected_Row (Panel) = 0 and then First_Visible_Row (Panel) = 1,
              "empty keyboard navigation remains deterministic");
   end Test_Clear_And_Empty_Navigation_Reset_View_State;



   procedure Test_Search_Activation_Reveals_Target_And_Returns_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Text   : Ada.Strings.Unbounded.Unbounded_String;
      Result : Editor.Executor.Command_Execution_Result;
      Row           : Natural := 0;
      Col           : Natural := 0;
      Viewport_Rows : Natural := 1;
      Expected_Y    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Editor.Layout.Cell_W * 40, Editor.Layout.Cell_H * 5);

      for I in 1 .. 20 loop
         Ada.Strings.Unbounded.Append
           (Text, "line" & Natural'Image (I) & ASCII.LF);
      end loop;
      Editor.State.Load_Text (S, Ada.Strings.Unbounded.To_String (Text));
      Editor.View.Set_Scroll (0, 0);

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "target",
         Source_Label  => "buffer",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 15,
         Target_Column => 1,
         Query         => "line",
         Line_Text     => "line 15",
         Match_Line    => 15,
         Match_Column  => 1,
         Match_Length  => 4);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Editor.State.Row_Col_For_Index
        (S, S.Carets.Element (S.Carets.First_Index).Pos, Row, Col);
      Viewport_Rows := Natural'Max
        (1, Editor.Layout.Visible_Row_Count
          (Editor.Layout.Current, Editor.View.Viewport_Height));
      if 14 > Viewport_Rows / 2 then
         Expected_Y := 14 - Viewport_Rows / 2;
      else
         Expected_Y := 0;
      end if;

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "successful Search activation executes after validation");
      Assert (Row = 14 and then Col = 0,
              "successful Search activation moves caret to target");
      Assert (Editor.View.Scroll_Y = Expected_Y,
              "successful Search activation reveals the target row predictably");
      Assert (not Is_Focused (S.Feature_Panel),
              "successful Search activation returns focus to editor text");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "successful Search activation preserves selected feature row");

      Editor.View.Set_Viewport (800, 600);
      Editor.View.Reset_Scroll;
   end Test_Search_Activation_Reveals_Target_And_Returns_Focus;

   procedure Test_Failed_Search_Activation_Preserves_Editor_And_Panel_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Result        : Editor.Executor.Command_Execution_Result;
      Before_Caret  : Editor.Cursors.Cursor_Index;
      Before_Scroll : Natural;
   begin
      Editor.State.Init (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Editor.Layout.Cell_W * 40, Editor.Layout.Cell_H * 5);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Editor.View.Set_Scroll (0, 3);
      Before_Scroll := Editor.View.Scroll_Y;
      Before_Caret := S.Carets.Element (S.Carets.First_Index).Pos;

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "bad target",
         Source_Label  => "buffer",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 99,
         Target_Column => 1,
         Query         => "two",
         Line_Text     => "two",
         Match_Line    => 99,
         Match_Column  => 1,
         Match_Length  => 3);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "failed Search activation no-ops before handoff");
      Assert (S.Carets.Element (S.Carets.First_Index).Pos = Before_Caret,
              "failed Search activation preserves editor caret");
      Assert (Editor.View.Scroll_Y = Before_Scroll,
              "failed Search activation preserves editor viewport");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "failed Search activation preserves feature selection");
      Assert (Is_Focused (S.Feature_Panel),
              "failed Search activation preserves Feature Panel focus");

      Editor.View.Set_Viewport (800, 600);
      Editor.View.Reset_Scroll;
   end Test_Failed_Search_Activation_Preserves_Editor_And_Panel_State;

   procedure Test_Outline_Refresh_Preserves_Editor_Viewport
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Result        : Editor.Executor.Command_Execution_Result;
      Before_Caret  : Editor.Cursors.Cursor_Index;
      Before_Scroll : Natural;
   begin
      Editor.State.Init (S);
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Editor.Layout.Cell_W * 40, Editor.Layout.Cell_H * 5);
      Editor.State.Load_Text
        (S,
         "@outline package Demo" & ASCII.LF &
         "one" & ASCII.LF &
         "two" & ASCII.LF &
         "@outline procedure Run" & ASCII.LF);
      Editor.View.Set_Scroll (0, 2);
      Before_Scroll := Editor.View.Scroll_Y;
      Before_Caret := S.Carets.Element (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Outline refresh executes normally");
      Assert (S.Carets.Element (S.Carets.First_Index).Pos = Before_Caret,
              "Outline refresh preserves editor caret");
      Assert (Editor.View.Scroll_Y = Before_Scroll,
              "Outline refresh preserves editor viewport");
      Assert (Active_Feature (S.Feature_Panel) = Outline_Feature,
              "Outline refresh updates the Feature Panel view only for Outline");

      Editor.View.Set_Viewport (800, 600);
      Editor.View.Reset_Scroll;
   end Test_Outline_Refresh_Preserves_Editor_Viewport;


   function Paste_Command (Text : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := Ada.Strings.Unbounded.To_Unbounded_String (Text);
      return Cmd;
   end Paste_Command;

   function Insert_Command (Ch : Character) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := Ch;
      Cmd.Text := To_Unbounded_String (String'(1 => Ch));
      Cmd.Code := Wide_Wide_Character'Val (0);
      return Cmd;
   end Insert_Command;

   function Simple_Command
     (Kind : Editor.Commands.Command_Kind) return Editor.Commands.Command
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Kind;
      return Cmd;
   end Simple_Command;

   function Registry_Buffer_Text
     (Id : Editor.Buffers.Buffer_Id) return String
   is
      Snapshot : constant Editor.State.State_Type :=
        Editor.Buffers.Buffer (Editor.Buffers.Global_Registry_For_UI, Id);
   begin
      return Text_Buffer.UTF8_Text (Snapshot.Buffer);
   end Registry_Buffer_Text;

   procedure Test_Repeated_Search_Activations_Edit_Latest_Target_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "A target",
         Source_Label  => "A",
         Has_Target    => True,
         Target_Buffer => Natural (A_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "A",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "B target",
         Source_Label  => "B",
         Has_Target    => True,
         Target_Buffer => Natural (B_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "B",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "can show repeated Search activation rows");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first Search activation executes");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id
                and then S.Active_Buffer_Token = Natural (A_Id),
              "first Search activation makes A the editor target");
      Editor.Executor.Execute_No_Log (S, Paste_Command ("-after-A"));

      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second Search activation executes");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id
                and then S.Active_Buffer_Token = Natural (B_Id),
              "second Search activation makes B the editor target");
      Editor.Executor.Execute_No_Log (S, Paste_Command ("-after-B"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Assert (Registry_Buffer_Text (A_Id) = "A-after-A" & ASCII.LF,
              "edit after first activation stays in A");
      Assert (Registry_Buffer_Text (B_Id) = "B-after-B" & ASCII.LF,
              "edit after second activation stays in B");
      Assert (Selected_Row (S.Feature_Panel) = 2,
              "repeated activation preserves latest valid feature selection");
      Assert (not Is_Focused (S.Feature_Panel),
              "repeated activation leaves editor focus active");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Repeated_Search_Activations_Edit_Latest_Target_Buffer;

   procedure Test_Failed_Activation_Preserves_Previous_Target_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "live B",
         Source_Label  => "B",
         Has_Target    => True,
         Target_Buffer => Natural (B_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "B",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "stale A",
         Source_Label  => "A",
         Has_Target    => True,
         Target_Buffer => Natural (A_Id),
         Target_Line   => 99,
         Target_Column => 1,
         Query         => "target",
         Line_Text     => "A",
         Match_Line    => 99,
         Match_Column  => 1,
         Match_Length  => 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "can show failed-activation rows");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "live setup activation executes");
      Assert (S.Active_Buffer_Token = Natural (B_Id),
              "setup leaves B as active editor target");

      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale second activation no-ops");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id
                and then S.Active_Buffer_Token = Natural (B_Id),
              "failed activation preserves previous active buffer");
      Assert (Is_Focused (S.Feature_Panel),
              "failed activation preserves Feature Panel focus");
      Assert (Selected_Row (S.Feature_Panel) = 2,
              "failed activation preserves selected stale row for feedback/retry");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Failed_Activation_Preserves_Previous_Target_Buffer;

   procedure Test_Typing_After_Repeated_Round_Trips_Is_Ordinary_Active_Buffer_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Panel : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After_Panel  : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "A target",
         Source_Label  => "A",
         Has_Target    => True,
         Target_Buffer => Natural (A_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "A",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "B target",
         Source_Label  => "B",
         Has_Target    => True,
         Target_Buffer => Natural (B_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "B",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "setup can show Search rows");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first activation executes");
      Editor.Executor.Execute_No_Log (S, Paste_Command ("-typed-A"));

      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second activation executes");

      Before_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Editor.Executor.Execute_No_Log (S, Paste_Command ("-typed-B"));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      After_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Assert (Registry_Buffer_Text (A_Id) = "A-typed-A" & ASCII.LF,
              "typing after first round trip stays in A");
      Assert (Registry_Buffer_Text (B_Id) = "B-typed-B" & ASCII.LF,
              "typing after repeated round trips edits active B only");
      Assert (After_Panel.Row_Count = Before_Panel.Row_Count
                and then After_Panel.Selected_Row = Before_Panel.Selected_Row
                and then After_Panel.Row_Labels_Hash = Before_Panel.Row_Labels_Hash
                and then After_Panel.Row_Details_Hash = Before_Panel.Row_Details_Hash,
              "ordinary typing does not mutate visible Feature Panel rows");
      Assert (not Is_Focused (S.Feature_Panel),
              "ordinary typing keeps editor focus after activation");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Typing_After_Repeated_Round_Trips_Is_Ordinary_Active_Buffer_Edit;

   procedure Test_Stale_Search_Row_After_Edit_Cannot_Retarget_Editor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Panel : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After_Panel  : Editor.Feature_Panel.Feature_Panel_Fingerprint;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "setup creates one live Search result");

      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "setup activation reaches A");
      Editor.Executor.Execute_No_Log (S, Insert_Command ('Z'));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "edit marks old Search row source stale");

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "beta" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "setup switches ordinary editing target to B");

      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      After_Panel := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale Search row activation is rejected");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id
                and then S.Active_Buffer_Token = Natural (B_Id),
              "stale Search row cannot retarget editor away from B");
      Assert (Registry_Buffer_Text (A_Id) = "Zalpha" & ASCII.LF,
              "stale activation does not mutate edited source buffer");
      Assert (Registry_Buffer_Text (B_Id) = "beta" & ASCII.LF,
              "stale activation preserves current active buffer content");
      Assert (After_Panel.Row_Count = Before_Panel.Row_Count
                and then After_Panel.Selected_Row = Before_Panel.Selected_Row
                and then After_Panel.Row_Labels_Hash = Before_Panel.Row_Labels_Hash,
              "stale activation preserves visible Feature Panel rows");
      Assert (Is_Focused (S.Feature_Panel),
              "failed stale activation preserves Feature Panel focus");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Stale_Search_Row_After_Edit_Cannot_Retarget_Editor;

   procedure Test_Undo_Redo_And_Cursor_After_Round_Trip_Remain_Buffer_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "B" & ASCII.LF);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results,
         Label         => "B target",
         Source_Label  => "B",
         Has_Target    => True,
         Target_Buffer => Natural (B_Id),
         Target_Line   => 1,
         Target_Column => 2,
         Query         => "target",
         Line_Text     => "B",
         Match_Line    => 1,
         Match_Column  => 2,
         Match_Length  => 1);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Search_Results_Feature),
              "setup can show B target");
      Result := Editor.Executor.Search_Results_Commands.Execute_Search_Result_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "activation establishes B as edit target");

      Editor.Executor.Execute_No_Log (S, Paste_Command ("-edit"));
      Editor.Executor.Execute_No_Log (S, Simple_Command (Editor.Commands.Move_Left));
      Editor.State.Row_Col_For_Index
        (S, S.Carets.Element (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0 and then Col = 5,
              "cursor movement after round trip starts from active B cursor");

      Editor.Executor.Execute_No_Log (S, Simple_Command (Editor.Commands.Undo));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Registry_Buffer_Text (B_Id) = "B" & ASCII.LF,
              "undo after round trip affects active B only");
      Assert (Registry_Buffer_Text (A_Id) = "A" & ASCII.LF,
              "undo after round trip preserves unrelated A");

      Editor.Executor.Execute_No_Log (S, Simple_Command (Editor.Commands.Redo));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Registry_Buffer_Text (B_Id) = "B-edit" & ASCII.LF,
              "redo after round trip affects active B only");
      Assert (Selected_Row (S.Feature_Panel) = 1,
              "undo/redo do not reactivate or change Feature Panel selection");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Undo_Redo_And_Cursor_After_Round_Trip_Remain_Buffer_Local;

   procedure Register_Tests (T : in out Feature_Panel_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Clear_Empty_Rows_Does_Not_Bump_Projection'Access,
         "empty feature clear avoids projection churn");
      Register_Routine
        (T, Test_Unchanged_Header_Does_Not_Churn_State'Access,
         "unchanged feature header avoids state churn");
      Register_Routine (T, Test_Model_Defaults_And_Placeholders'Access,
                        "feature panel model defaults and placeholder rows");
      Register_Routine (T, Test_Command_Metadata_Stable_Names'Access,
                        "feature panel command metadata and stable names");
      Register_Routine (T, Test_Command_Availability_And_Execution'Access,
                        "feature panel availability and executor route");
      Register_Routine (T, Test_Project_Reset_And_Settings_Separation'Access,
                        "feature panel project reset and settings separation");
      Register_Routine (T, Test_Keybinding_Config_Accepts_Bindable_Feature_Command'Access,
                        "feature panel keybinding integration");
      Register_Routine (T, Test_Invariants_Focus_And_Render_Snapshot'Access,
                        "feature panel invariants focus and render snapshot");
      Register_Routine (T, Test_Empty_Selection_And_Command_Messages'Access,
                        "feature panel empty selection and command messages");
      Register_Routine (T, Test_Availability_Is_Side_Effect_Free'Access,
                        "feature panel availability side-effect freedom");
      Register_Routine (T, Test_Summary_Fingerprint_And_Row_Access'Access,
                        "feature panel summary fingerprint and row access");
      Register_Routine (T, Test_Explicit_Unavailable_Command_Policy'Access,
                        "feature panel explicit unavailable command policy");
      Register_Routine (T, Test_Fixture_Builders'Access,
                        "feature panel fixture builders");

      Register_Routine (T, Test_Consolidated_Invariants'Access,
                        "consolidated feature-panel invariants");
      Register_Routine (T, Test_Command_Set_Frozen'Access,
                        "feature-panel command set frozen");
      Register_Routine (T, Test_Canonical_Reasons_And_Messages'Access,
                        "canonical feature-panel reasons and messages");
      Register_Routine (T, Test_Lifecycle_Reset_Is_Success_Only'Access,
                        "feature-panel lifecycle reset is success-only");
      Register_Routine (T, Test_Workspace_Persistence_Excludes_Runtime_State'Access,
                        "feature-panel persistence exclusion");
      Register_Routine (T, Test_Command_Palette_Post_Command_Refresh'Access,
                        "feature-panel command-palette post-command refresh");
      Register_Routine (T, Test_Outline_Reveal_Row_Scrolls_Above_Visible_Range'Access,
                        "reveal row scrolls above visible range");
      Register_Routine (T, Test_Outline_Reveal_Row_Scrolls_Below_Visible_Range'Access,
                        "reveal row scrolls below visible range");
      Register_Routine (T, Test_Outline_Reveal_Row_Leaves_Visible_Row_Unchanged'Access,
                        "reveal row leaves visible row unchanged");
      Register_Routine (T, Test_Outline_Reveal_Row_Rejects_Invalid_Index'Access,
                        "reveal row rejects invalid index");
      Register_Routine (T, Test_Generic_Projection_Guards'Access,
                        "generic projection guards");
      Register_Routine (T, Test_Feature_Panel_Can_Show_Messages'Access,
                        "feature panel can show messages");
      Register_Routine (T, Test_Switch_Outline_To_Messages_Preserves_Outline_State'Access,
                        "switching outline to messages preserves outline state");
      Register_Routine (T, Test_Clear_Messages_Does_Not_Clear_Outline'Access,
                        "clearing messages does not clear outline");
      Register_Routine (T, Test_Clear_Outline_Does_Not_Clear_Messages'Access,
                        "clearing outline does not clear messages");
      Register_Routine (T, Test_Messages_Reject_Stale_Projection'Access,
                        "messages reject stale projection generation");
      Register_Routine (T, Test_Messages_Command_Metadata'Access,
                        "messages command metadata");

      Register_Routine (T, Test_Messages_Add_Projects_Severity_Rows'Access,
                        "messages add projects severity rows");
      Register_Routine (T, Test_Messages_Clear_Clears_Selection_And_Projection'Access,
                        "messages clear clears selection and projection");
      Register_Routine (T, Test_Messages_Click_Selects_Without_Navigation'Access,
                        "messages click selects without navigation");
      Register_Routine (T, Test_Messages_Activation_With_Target_Navigates'Access,
                        "messages activation with target navigates");
      Register_Routine (T, Test_Messages_Activation_Without_Target_Noops'Access,
                        "messages activation without target noops");
      Register_Routine (T, Test_Messages_Activation_Rejects_Closed_Buffer_Target'Access,
                        "messages activation rejects closed buffer target");
      Register_Routine (T, Test_Messages_Buffer_Close_Removes_Targeted_Messages'Access,
                        "messages buffer close removes targeted messages");
      Register_Routine (T, Test_Feature_Panel_Switch_Outline_Messages_Preserves_Both_States'Access,
                        "feature panel switch outline/messages preserves both states");

      Register_Routine (T, Test_Messages_Filter_Matches_Text_And_Source'Access,
                        "messages filter matches text and source");
      Register_Routine (T, Test_Messages_Filter_Matches_Severity_Text'Access,
                        "messages filter matches severity text");
      Register_Routine (T, Test_Messages_Severity_Toggles_Compose_With_Text'Access,
                        "messages severity toggles compose with text filter");
      Register_Routine (T, Test_Messages_Filter_Reconciles_Selection'Access,
                        "messages filter reconciles selection");
      Register_Routine (T, Test_Messages_Clear_Filter_And_Workspace_Close'Access,
                        "messages clear filter and workspace close");
      Register_Routine (T, Test_Messages_Filtered_Activation_Rejects_Stale_Projection'Access,
                        "messages filtered activation rejects stale projection");
      Register_Routine (T, Test_Messages_Filter_Commands_Do_Not_Affect_Outline'Access,
                        "messages filter commands do not affect outline");

      Register_Routine (T, Test_Messages_Source_Kind_And_Target_Validation'Access,
                        "messages source kind and target validation");
      Register_Routine (T, Test_Messages_Max_Retention_Evicts_Oldest_And_Keeps_Ids'Access,
                        "messages retention evicts oldest and keeps ids");
      Register_Routine (T, Test_Messages_Deduplicates_Adjacent_Only'Access,
                        "messages deduplicate adjacent only");
      Register_Routine (T, Test_Post_Message_Preserves_Filter_And_Reprojects_When_Active'Access,
                        "message producer preserves filter and reprojects");
      Register_Routine (T, Test_Save_As_Does_Not_Post_Secondary_Feature_Message'Access,
                        "Save As Does Not Post Secondary Feature Message");
      Register_Routine (T, Test_Message_Producer_Does_Not_Affect_Outline_State'Access,
                        "message producer does not affect outline state");

      Register_Routine (T, Test_Messages_Clear_Selected_Reconciles_To_Next'Access,
                        "messages clear-selected reconciles to next row");
      Register_Routine (T, Test_Messages_Clear_Selected_Reconciles_To_Previous'Access,
                        "messages clear-selected reconciles to previous row");
      Register_Routine (T, Test_Messages_Clear_By_Severity_Preserves_Filter'Access,
                        "messages clear-by-severity preserves filters");
      Register_Routine (T, Test_Messages_Copy_Text_And_Action_Flags'Access,
                        "messages copy formatting and action flags");
      Register_Routine (T, Test_Messages_Action_Commands_Do_Not_Affect_Outline'Access,
                        "messages actions do not affect outline");

      Register_Routine (T, Test_Messages_Filter_Delete_Post_Rebuilds_Projection'Access,
                        "messages filter delete post rebuilds projection");
      Register_Routine (T, Test_Messages_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows'Access,
                        "messages buffer close with active filter removes targeted rows");
      Register_Routine (T, Test_Feature_Panel_Reveal_Rejects_Cross_Feature_Token'Access,
                        "feature panel rejects cross-feature token");
      Register_Routine (T, Test_Messages_Workspace_Close_After_Many_Operations_Clears_All_State'Access,
                        "messages workspace close after many operations clears all state");

      Register_Routine (T, Test_Feature_Descriptor_Table_Has_Deterministic_Order'Access,
                        "feature descriptor table deterministic order");
      Register_Routine (T, Test_Feature_Descriptor_Table_Rejects_Unknown_Feature'Access,
                        "feature descriptor table rejects unknown feature");
      Register_Routine (T, Test_Feature_Switch_To_Outline_Uses_Outline_Projection'Access,
                        "switch to outline uses outline projection");
      Register_Routine (T, Test_Feature_Switch_To_Messages_Uses_Messages_Projection'Access,
                        "switch to messages uses messages projection");
      Register_Routine (T, Test_Feature_Switch_Invalidates_Previous_Feature_Token'Access,
                        "switching invalidates previous feature token");
      Register_Routine (T, Test_Feature_Projection_Token_Includes_Feature_Id'Access,
                        "projection token includes feature id");
      Register_Routine (T, Test_Feature_Reveal_Rejects_Cross_Feature_Token'Access,
                        "reveal rejects cross-feature token");
      Register_Routine (T, Test_Feature_Action_Rejects_Cross_Feature_Token'Access,
                        "action rejects cross-feature token");
      Register_Routine (T, Test_Feature_Lifecycle_Project_Close_Dispatches_To_All_Features'Access,
                        "project close lifecycle dispatches to all features");
      Register_Routine (T, Test_Feature_Command_Clear_Active_Delegates_To_Active_Feature'Access,
                        "clear-active delegates to active feature");
      Register_Routine (T, Test_Search_Results_Show_And_Clear_Isolated'Access,
                        "search results show and clear are isolated");
      Register_Routine (T, Test_Search_Results_Projection_Token_And_Activation'Access,
                        "search results projection token and activation");
      Register_Routine (T, Test_Search_Results_Rejects_Cross_Feature_Token'Access,
                        "search results rejects cross-feature token");
      Register_Routine (T, Test_Clear_Active_Delegates_To_Search_Results'Access,
                        "clear-active delegates to search results");
      Register_Routine (T, Test_Search_Active_Buffer_Finds_Ordered_Matches'Access,
                        "active-buffer search finds ordered matches");
      Register_Routine (T, Test_Search_Active_Buffer_Zero_Matches_Replaces_Previous'Access,
                        "active-buffer search zero matches replaces previous");
      Register_Routine (T, Test_Search_Activation_And_Stale_State'Access,
                        "search result activation and stale state");
      Register_Routine (T, Test_Search_Results_Do_Not_Mutate_Outline_Or_Messages'Access,
                        "search results isolate Outline and Messages");
      Register_Routine (T, Test_Search_Query_Input_And_History'Access,
                        "search query input and history");
      Register_Routine (T, Test_Search_Query_Input_Does_Not_Edit_Buffer'Access,
                        "search query input does not edit buffer");
      Register_Routine (T, Test_Repeat_Uses_Last_Query_And_Clears_Stale'Access,
                        "repeat search uses last query and clears stale");
      Register_Routine (T, Test_Repeat_Preserves_Selection_When_Possible'Access,
                        "repeat search preserves selection");
      Register_Routine (T, Test_Case_Sensitive_Mode_Is_Optional_And_Visible'Access,
                        "case-sensitive mode is visible");
      Register_Routine (T, Test_Search_Result_Context_Truncation'Access,
                        "search result context truncation");
      Register_Routine (T, Test_Search_Projection_Uses_Bounded_Context_Label'Access,
                        "search projection uses bounded context labels");
      Register_Routine (T, Test_Search_Rerun_Same_Query_Preserves_Selected_Match'Access,
                        "rerun same query preserves selected match");
      Register_Routine (T, Test_Search_Rerun_Different_Query_Selects_First'Access,
                        "different query selects first result");
      Register_Routine (T, Test_Search_Activation_Rejects_Invalid_Stale_Target'Access,
                        "activation rejects invalid stale target");

      Register_Routine (T, Test_Search_Workspace_Close_Clears_Query_Input_And_History'Access,
                        "search workspace close clears query input and history");
      Register_Routine (T, Test_Search_Project_Close_Preserves_Bounded_History_But_Clears_Rows'Access,
                        "search project close preserves bounded history but clears rows");
      Register_Routine (T, Test_Search_Buffer_Close_With_Selected_Result_Clears_Target'Access,
                        "search buffer close with selected result clears target");
      Register_Routine (T, Test_Search_Result_Replacement_Invalidates_Old_Reveal_Token'Access,
                        "search result replacement invalidates old reveal token");
      Register_Routine (T, Test_Feature_Panel_Repeated_Outline_Messages_Search_Switch_Preserves_Isolation'Access,
                        "repeated Outline/Messages/Search switch preserves isolation");
      Register_Routine (T, Test_Search_Long_Session_Query_History_Remains_Bounded'Access,
                        "long session search query history remains bounded");
      Register_Routine
        (T, Test_Feature_Panel_Scroll_Clamps_And_Preserves_Selection'Access,
         "Feature Panel Scroll Clamps And Preserves Selection");

      Register_Routine
        (T, Test_Messages_Row_Display_Empty_And_Long_Text'Access,
         "Messages row display empty and long text");
      Register_Routine
        (T, Test_Messages_Empty_State_Is_Not_Actionable'Access,
         "Messages empty state is not actionable");
      Register_Routine
        (T, Test_Messages_Activation_Rejects_Out_Of_Range_Position'Access,
         "Messages activation rejects out-of-range position");
      Register_Routine
        (T, Test_Messages_Retention_Trims_Oldest_Deterministically'Access,
         "Messages retention trims oldest deterministically");

      Register_Routine
        (T, Test_Diagnostics_Contract_Review_Default_Passes'Access,
         "Diagnostics contract review default passes");
      Register_Routine
        (T, Test_Diagnostics_Contract_Review_Is_Side_Effect_Free'Access,
         "Diagnostics contract review is side-effect-free");
      Register_Routine
        (T, Test_Diagnostics_Contract_Review_Feedback_Is_Deterministic'Access,
         "Diagnostics contract review feedback is deterministic");
      Register_Routine
        (T, Test_Diagnostics_Retention_Filter_And_Target_Robustness'Access,
         "Diagnostics retention filter and target robustness");

      Register_Routine
        (T, Test_Diagnostics_Activation_Rejects_Out_Of_Range_Column'Access,
         "Diagnostics activation rejects out-of-range column");
      Register_Routine
        (T, Test_Diagnostics_Clear_Lifecycle_And_Sibling_Features_Isolated'Access,
         "Diagnostics clear lifecycle and sibling feature isolation");


      Register_Routine
        (T, Test_Diagnostics_Projection_Empty_State_And_Row_Metadata_Deterministic'Access,
         "Diagnostics projection empty state and row metadata deterministic");
      Register_Routine
        (T, Test_Diagnostics_Row_State_Labels'Access,
         "Diagnostics row state labels are explicit");
      Register_Routine
        (T, Test_Diagnostics_Activation_Rejects_No_Target_Stale_And_Trimmed_Rows'Access,
         "Diagnostics activation rejects no-target stale and trimmed rows");
      Register_Routine
        (T, Test_Diagnostics_Filter_Text_Composes_And_Preserves_Source_Rows'Access,
         "Diagnostics filter text composes and preserves source rows");

      Register_Routine
        (T, Test_Diagnostics_Explicit_Id_Activation_Validates_Target'Access,
         "Diagnostics explicit Diagnostic_Id activation validates targets");

      Register_Routine
        (T, Test_Diagnostics_Navigation_No_Visible_Is_No_Op'Access,
         "Diagnostics navigation with no visible rows is no-op");

      Register_Routine
        (T, Test_Search_Results_Contract_Review_Default_Passes'Access,
         "Search Results contract review default passes");
      Register_Routine
        (T, Test_Search_Results_Contract_Review_Is_Side_Effect_Free'Access,
         "Search Results contract review is side-effect-free");
      Register_Routine
        (T, Test_Search_Results_Contract_Review_Feedback_Is_Deterministic'Access,
         "Search Results contract review feedback is deterministic");
      Register_Routine
        (T, Test_Search_Results_Active_Buffer_Only_And_Targets_Validated'Access,
         "Search Results active-buffer scope and target validation");
      Register_Routine
        (T, Test_Search_Results_Query_History_Bounded_And_Not_Persisted'Access,
         "Search Results query history bounded and non-persistent");
      Register_Routine
        (T, Test_Search_Results_Open_Selected_Rejects_Stale_And_Out_Of_Range_Targets'Access,
         "Search Results open selected rejects stale out-of-range targets");
      Register_Routine
        (T, Test_Search_Results_Activation_Rejects_Out_Of_Range_Column'Access,
         "Search Results activation rejects out-of-range column");
      Register_Routine (T, Test_Feature_Descriptor_Table_Covers_All_Feature_Ids'Access,
                        "feature descriptor table covers all feature ids");
      Register_Routine (T, Test_Feature_Dispatch_Covers_All_Feature_Ids'Access,
                        "feature dispatch covers all feature ids");
      Register_Routine (T, Test_Feature_Stale_Token_Rejected_After_Repeated_Switching'Access,
                        "stale token rejected after repeated switching");
      Register_Routine (T, Test_Feature_Clear_Active_Only_Clears_Active_Feature'Access,
                        "clear active only clears active feature");
      Register_Routine (T, Test_Feature_Workspace_Close_Preserves_Command_Registrations'Access,
                        "workspace close preserves command registrations");
      Register_Routine (T, Test_Diagnostics_Show_And_Clear_Isolated'Access,
                        "diagnostics show and clear are isolated");
      Register_Routine (T, Test_Diagnostics_Token_Activation_And_Lifecycle'Access,
                        "diagnostics token activation and lifecycle");
      Register_Routine (T, Test_Diagnostics_Posting_And_Header'Access,
                        "diagnostics posting, source kind, header, and projection");
      Register_Routine (T, Test_Diagnostics_Invalid_Target_And_Retention'Access,
                        "diagnostics invalid target retention and id stability");
      Register_Routine (T, Test_Diagnostics_Active_Reprojection_After_Post'Access,
                        "diagnostics active projection refresh after posting");
      Register_Routine
        (T, Test_Diagnostics_Text_Filter_Composes_And_Preserves_Order'Access,
         "Diagnostics text filter projection and ordering");
      Register_Routine
        (T, Test_Diagnostics_Severity_Toggles_Reconcile_Selection'Access,
         "Diagnostics severity toggles and selection reconciliation");
      Register_Routine
        (T, Test_Diagnostics_Filtered_Activation_Rejects_Stale_Projection'Access,
         "Diagnostics filtered activation rejects stale generation");
      Register_Routine
        (T, Test_Diagnostics_Clear_Selected_Reconciles_Selection'Access,
         "Diagnostics clear-selected reconciles selection");
      Register_Routine
        (T, Test_Diagnostics_Clear_By_Severity_And_Source_Preserve_Filters'Access,
         "Diagnostics subset clearing preserves filters");
      Register_Routine
        (T, Test_Diagnostics_Copy_Format_And_Action_Flags'Access,
         "Diagnostics copy formatting and action flags");
      Register_Routine
        (T, Test_Diagnostics_Action_Commands_Do_Not_Affect_Other_Features'Access,
         "Diagnostics action commands preserve feature isolation");
      Register_Routine
        (T, Test_Diagnostics_Command_Feedback_Is_Deterministic'Access,
         "Diagnostics command feedback is deterministic");
      Register_Routine
        (T, Test_Diagnostics_Filter_Delete_Post_Rebuilds_Projection'Access,
         "Diagnostics filter delete post rebuilds projection");
      Register_Routine
        (T, Test_Diagnostics_Buffer_Close_With_Filter_Active_Removes_Targeted_Rows'Access,
         "Diagnostics buffer close with active filter removes targeted rows");
      Register_Routine
        (T, Test_Diagnostics_Workspace_Close_After_Many_Operations_Clears_All_State'Access,
         "Diagnostics workspace close after many operations clears all state");
      Register_Routine
        (T, Test_Feature_Panel_Cross_Feature_Diagnostics_Tokens_Rejected'Access,
         "cross-feature Diagnostics tokens are rejected");
      Register_Routine
        (T, Test_Diagnostics_Repeated_Posting_Respects_Retention'Access,
         "repeated Diagnostics posting respects retention");

      Register_Routine
        (T, Test_Search_Result_Activation_Focuses_Source_Buffer'Access,
         "Search Result activation focuses source buffer");
      Register_Routine
        (T, Test_Diagnostic_Activation_Failure_Leaves_Active_Buffer'Access,
         "failed Diagnostic activation preserves active buffer");
      Register_Routine
        (T, Test_Feature_Switch_Preserves_Per_Feature_Selection'Access,
         "feature switch preserves per-feature selection");
      Register_Routine
        (T, Test_Feature_Switch_Preserves_Per_Feature_Scroll_And_Clamps'Access,
         "feature switch preserves per-feature scroll and clamps stale offsets");
      Register_Routine
        (T, Test_Empty_State_Rows_Are_Not_Selected_Or_Openable'Access,
         "empty-state rows are not selected or openable");
      Register_Routine
        (T, Test_Row_Replacement_Clears_Invalid_Selection_And_Clamps_Scroll'Access,
         "row replacement clears invalid selection and clamps scroll");
      Register_Routine
        (T, Test_Clear_Active_Feature_Does_Not_Clear_Sibling_Feature'Access,
         "clear active feature does not clear sibling feature");
      Register_Routine
        (T, Test_Forget_View_State_Blocks_Stale_Selection_Restore'Access,
         "forgotten stale view state is not restored after recovery");
      Register_Routine
        (T, Test_Search_Rerun_After_Clear_Recovers_Fresh_Rows'Access,
         "Search rerun after clear recovers fresh rows");
      Register_Routine
        (T, Test_Inactive_Diagnostics_Recovery_Does_Not_Steal_View'Access,
         "inactive Diagnostics recovery does not steal active view");
      Register_Routine
        (T, Test_Repeated_Outline_Refresh_Invalidates_Old_Row_Handle'Access,
         "repeated Outline refresh invalidates old row handles");
      Register_Routine
        (T, Test_Repeated_Search_Rerun_Replaces_And_Handles_Empty'Access,
         "repeated Search rerun replaces rows and handles empty state");
      Register_Routine
        (T, Test_Repeated_Diagnostics_Clear_Regenerate_Rejects_Old_Handle'Access,
         "repeated Diagnostics clear/regenerate rejects old handles");
      Register_Routine
        (T, Test_Repeated_Messages_Clear_Regenerate_Rejects_Old_Handle'Access,
         "repeated Messages clear/regenerate rejects old handles");
      Register_Routine
        (T, Test_Keyboard_Selection_Reveals_And_Clamps'Access,
         "keyboard selection reveals and clamps during long sessions");
      Register_Routine
        (T, Test_Mouse_Row_Mapping_Respects_Scroll'Access,
         "mouse row mapping respects Feature Panel scroll");
      Register_Routine
        (T, Test_Clear_And_Empty_Navigation_Reset_View_State'Access,
         "clear and empty navigation reset view state");
      Register_Routine
        (T, Test_Search_Activation_Reveals_Target_And_Returns_Focus'Access,
         "Search activation reveals target and returns focus");
      Register_Routine
        (T, Test_Failed_Search_Activation_Preserves_Editor_And_Panel_State'Access,
         "failed Search activation preserves editor and panel state");
      Register_Routine
        (T, Test_Outline_Refresh_Preserves_Editor_Viewport'Access,
         "Outline refresh preserves editor viewport");
      Register_Routine
        (T, Test_Repeated_Search_Activations_Edit_Latest_Target_Buffer'Access,
         "repeated Search activations edit latest target buffer");
      Register_Routine
        (T, Test_Failed_Activation_Preserves_Previous_Target_Buffer'Access,
         "failed activation preserves previous target buffer");
      Register_Routine
        (T, Test_Typing_After_Repeated_Round_Trips_Is_Ordinary_Active_Buffer_Edit'Access,
         "typing after repeated round trips is ordinary active-buffer edit");
      Register_Routine
        (T, Test_Stale_Search_Row_After_Edit_Cannot_Retarget_Editor'Access,
         "stale Search row after edit cannot retarget editor");
      Register_Routine
        (T, Test_Undo_Redo_And_Cursor_After_Round_Trip_Remain_Buffer_Local'Access,
         "undo redo and cursor after round trip remain buffer-local");

   end Register_Tests;

end Editor.Feature_Panel.Tests;
