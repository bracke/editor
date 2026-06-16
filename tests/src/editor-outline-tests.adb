with Ada.Characters.Handling;
with Editor.Test_Helper;
with Editor.Pending_Transitions;
with Editor.Buffers;
with Ada.Text_IO;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Ada_Syntax_Core;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Outline_Extractor;
with Editor.Outline_Audit;
with Editor.Panel_Focus;
with Editor.State;
with Editor.Render_Model;
with Editor.Workspace_Persistence;

package body Editor.Outline.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Failure_Kind;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline_Extractor.Extraction_Status;
   use type Editor.Outline_Extractor.Extraction_Failure_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Fingerprint;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Active_Message_Text;

   function Name (T : Outline_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Tests");
   end Name;

   procedure Populate_Synthetic_Outline
     (O : in out Outline_State)
   is
      Result : constant Outline_Refresh_Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
   begin
      pragma Assert (Result.Status = Outline_Refresh_Ok,
                     "synthetic outline fixture refresh succeeds");
   end Populate_Synthetic_Outline;

   function First_Label_Index
     (O     : Outline_State;
      Label : String) return Natural
   is
   begin
      for I in 1 .. Item_Count (O) loop
         if Item_Label (O, I) = Label then
            return I;
         end if;
      end loop;

      return 0;
   end First_Label_Index;

   function Has_Label
     (O     : Outline_State;
      Label : String) return Boolean
   is
   begin
      return First_Label_Index (O, Label) /= 0;
   end Has_Label;

   procedure Assert_Has_Label
     (O       : Outline_State;
      Label   : String;
      Message : String)
   is
   begin
      Assert (Has_Label (O, Label), Message);
   end Assert_Has_Label;

   function Phase579_Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_phase579_outline_" & Name;
   end Phase579_Temp_Path;

   procedure Phase579_Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Phase579_Remove_If_Exists;

   procedure Phase579_Write_Text
     (Path : String;
      Text : String)
   is
      package Stream_IO renames Ada.Streams.Stream_IO;
      File  : Stream_IO.File_Type;
      Bytes : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      for I in Text'Range loop
         Bytes (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;

      Stream_IO.Create (File, Stream_IO.Out_File, Path);
      if Text'Length > 0 then
         Stream_IO.Write (File, Bytes);
      end if;
      Stream_IO.Close (File);
   exception
      when others =>
         if Stream_IO.Is_Open (File) then
            Stream_IO.Close (File);
         end if;
         raise;
   end Phase579_Write_Text;

   procedure Test_Synthetic_Items_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O  : Outline_State;
      F1 : Natural;
      F2 : Natural;
   begin
      Assert (Item_Count (O) = 0, "outline starts empty");
      Populate_Synthetic_Outline (O);
      F1 := Fingerprint (O);
      Assert (Item_Count (O) = 5, "synthetic outline has five rows");
      Assert (Invariant_Holds (O), "synthetic outline satisfies invariants");
      Assert (Item_Kind (O, 1) = Outline_Header, "first row is header");
      Assert (Item_Label (O, 1) = "Outline", "header label is deterministic");
      Assert (Item_Depth (O, 1) = 0, "header depth is deterministic");
      Assert (Item_Depth (O, 5) = 2, "field depth is deterministic");
      Assert (Item_Label (O, 4) = "Synthetic_Procedure", "synthetic subprogram label");
      Assert (Item_Target_Kind (O, 4) = No_Target, "synthetic rows have no navigation target");
      Assert (Item_Line (O, 4) = 0 and then Item_Column (O, 4) = 0,
              "synthetic rows do not assign source positions");
      Populate_Synthetic_Outline (O);
      F2 := Fingerprint (O);
      Assert (F1 = F2, "synthetic outline fingerprint is stable");
      Clear (O);
      Assert (not Has_Items (O), "clear removes outline items");
   end Test_Synthetic_Items_Are_Deterministic;

   procedure Test_Projection_To_Feature_Panel
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Populate_Synthetic_Outline (O);
      Editor.Feature_Panel.Set_Visible (P, True);
      Set_Rows_From_Outline (O, P);
      Assert (Editor.Feature_Panel.Is_Visible (P), "projection preserves panel visibility");
      Assert (Editor.Feature_Panel.Row_Count (P) = Item_Count (O), "projection row count matches outline");
      Assert (Editor.Feature_Panel.Row_Kind (P, 1) = Editor.Feature_Panel.Feature_Row_Header,
              "outline header maps to feature header");
      Assert (Editor.Feature_Panel.Row_Kind (P, 2) = Editor.Feature_Panel.Feature_Row_Item,
              "outline items map to feature rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 4) = "Synthetic_Procedure",
              "projection preserves labels");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 0,
              "projection does not select implicitly");
   end Test_Projection_To_Feature_Panel;

   procedure Test_Summary_Debug_And_Clear_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      S : Outline_Summary;
   begin
      Assert (Invariant_Holds (O), "empty outline satisfies invariants");
      Assert (Debug_Summary (O)'Length > 0, "debug summary is non-empty");
      S := Summary (O);
      Assert (S.Item_Count = 0 and then not S.Has_Items,
              "empty summary reports no items");
      Populate_Synthetic_Outline (O);
      S := Summary (O);
      Assert (S.Item_Count = 5 and then S.Has_Items,
              "placeholder summary reports items");
      Reset_For_Buffer_Change (O);
      Assert (Item_Count (O) = 0 and then Invariant_Holds (O),
              "buffer-change reset clears outline only");
      Populate_Synthetic_Outline (O);
      Reset_For_Project_Close (O);
      Assert (Item_Count (O) = 0 and then Invariant_Holds (O),
              "project-close reset clears outline only");
   end Test_Summary_Debug_And_Clear_Invariants;

   procedure Test_Command_Metadata_And_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Category (Editor.Commands.Command_Refresh_Outline) =
                Editor.Commands.Panel_Category,
              "refresh outline is a panel command");
      Assert (Editor.Commands.Is_Visible_In_Palette (Editor.Commands.Command_Refresh_Outline),
              "refresh outline appears in command palette");
      Assert (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Refresh_Outline) =
                "outline.refresh",
              "refresh outline stable name is canonical dot form");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("outline.open-selected", Found);
      Assert (Found and then Id = Editor.Commands.Command_Open_Selected_Outline_Item,
              "open selected outline canonical stable name round trips");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("refresh-outline", Found);
      Assert (not Found, "old refresh-outline spelling is not a stable command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("clear-outline", Found);
      Assert (not Found, "old clear-outline spelling is not a stable command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("show-outline", Found);
      Assert (not Found, "old show-outline spelling is not a stable command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("focus-outline", Found);
      Assert (not Found, "old focus-outline spelling is not a stable command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("open-selected-outline-item", Found);
      Assert (not Found, "old open-selected-outline-item spelling is not a stable command");
      Assert (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Show_Outline),
              "show outline is bindable without a default chord");
   end Test_Command_Metadata_And_Stable_Names;

   procedure Test_Command_Execution_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Refresh_Outline)),
        "refresh outline unavailable without active buffer");
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "refresh outline executes through executor");
      Assert (Item_Count (S.Outline) = 2, "refresh extracts marker outline state");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "refresh outline shows feature panel");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 2) = "procedure Run",
              "refresh projects extracted outline rows");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "refresh projection leaves no selected row");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_Refreshed,
              "refresh emits canonical outline message");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "clear outline executes through executor");
      Assert (Item_Count (S.Outline) = 0, "clear removes outline state");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "clear removes outline feature rows");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "clear outline clears feature-panel selection");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_Cleared,
              "clear emits canonical outline message");
   end Test_Command_Execution_And_Availability;

   procedure Test_Show_And_Focus_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Assert (Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Show_Outline)),
        "show outline is available while feature panel is hidden");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "show outline executes once");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Show_Outline)),
        "show outline is unavailable after the panel is visible");
      Assert (Editor.Commands.Unavailable_Reason
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Show_Outline)) =
          Editor.Outline.Reason_Feature_Panel_Already_Shown,
        "show outline disabled reason is canonical");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "focus outline executes while visible and not focused");
      Assert (not Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Focus_Outline)),
        "focus outline is unavailable after focus");
      Assert (Editor.Commands.Unavailable_Reason
        (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Focus_Outline)) =
          Editor.Outline.Reason_Feature_Panel_Already_Focused,
        "focus outline disabled reason is canonical");
   end Test_Show_And_Focus_Availability;

   procedure Test_Open_Selected_Navigates_To_Buffer_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "intro" & ASCII.LF & "@outline procedure Demo" & ASCII.LF &
            "procedure Demo is begin null; end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "refresh setup executes");
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open selected outline item navigates to its buffer target");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 0,
              "open selected moves the primary caret to the captured line/column");
      Assert (Editor.State.Current_Text (S) =
                "intro" & ASCII.LF & "@outline procedure Demo" & ASCII.LF &
                "procedure Demo is begin null; end Demo;",
              "open selected outline does not alter buffer text");
   end Test_Open_Selected_Navigates_To_Buffer_Target;

   procedure Test_Open_Selected_Requires_Live_Outline_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Outline.Clear (S.Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale feature-panel selection cannot open without outline item");
      Assert (Active_Message_Text (S) = Editor.Outline.Reason_No_Outline_Item_Selected,
              "stale selection emits unavailable selected-item reason");
   end Test_Open_Selected_Requires_Live_Outline_Row;

   procedure Test_Clear_Feature_Panel_Does_Not_Clear_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      F : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      F := Fingerprint (S.Outline);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Fingerprint (S.Outline) = F,
              "generic clear feature panel does not clear outline source state");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "generic clear feature panel clears displayed rows");
   end Test_Clear_Feature_Panel_Does_Not_Clear_Outline;

   procedure Test_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_Before : Natural;
      Panel_Before   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Messages_Before : Natural;
      A             : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (not Editor.Commands.Is_Available (A),
              "open selected is unavailable until selection exists");
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "availability preserves outline fingerprint");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "availability preserves feature-panel fingerprint");
      Assert (Editor.Messages.Count (S.Messages) = Messages_Before,
              "availability emits no messages");
   end Test_Availability_Is_Side_Effect_Free;

   procedure Test_Separation_From_Project_Reset_Settings_And_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Chord  : Editor.Keybindings.Key_Chord;
      Found  : Boolean := False;
      Id     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.State.Apply_Settings (S, S.Settings);
      Assert (Item_Count (S.Outline) = 1, "settings application does not clear extracted outline");
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Refresh_Outline).Has_Binding,
        "phase 131 outline refresh participates in optional default keybindings");
      Editor.Keybinding_Config.Clear (Config);
      Chord := Editor.Keybindings.Parse_Chord ("Ctrl+Alt+F1", Found);
      Assert (Found, "outline custom chord parses");
      Editor.Keybinding_Config.Bind (Config, Editor.Commands.Command_Refresh_Outline, Chord);
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      Assert (Editor.Keybindings.Resolve (Chord, Id) = Editor.Keybindings.Bound_Command
        and then Id = Editor.Commands.Command_Refresh_Outline,
        "custom outline chord resolves to command id");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Item_Count (S.Outline) = 0, "project-scoped reset clears outline");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "project-scoped reset clears outline rows");
   end Test_Separation_From_Project_Reset_Settings_And_Keybindings;



   procedure Test_Phase121_Refresh_Replaces_And_Clears_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_First : Natural := 0;
      Panel_First   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result        : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "first buffer text must not affect outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 121 refresh executes with active buffer");
      Outline_First := Fingerprint (S.Outline);
      Panel_First := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "display-only empty outline row is not selectable before replacement refresh");
      Editor.State.Load_Text (S, "different active text still must not affect outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 121 replacement refresh executes");
      Assert (Fingerprint (S.Outline) = Outline_First,
              "refresh twice produces identical outline fingerprint");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Labels_Hash =
                Panel_First.Row_Labels_Hash,
              "refresh twice produces identical feature-panel row label fingerprint");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Details_Hash =
                Panel_First.Row_Details_Hash,
              "refresh twice produces identical feature-panel row detail fingerprint");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "refresh clears feature-panel selection");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "refresh shows the feature panel");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "refresh does not focus the feature panel");
   end Test_Phase121_Refresh_Replaces_And_Clears_Selection;


   procedure Test_Phase121_Clear_Versus_Feature_Panel_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Outline_Before : Natural := 0;
      Result         : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Outline_Before := Fingerprint (S.Outline);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clear_Feature_Panel);
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "clear feature panel preserves outline content owner state");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "clear feature panel clears display rows");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "clear feature panel clears selection");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "clear outline remains available while outline state exists");
      Assert (Item_Count (S.Outline) = 0,
              "clear outline clears preserved outline state");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "clear outline leaves rows cleared");
   end Test_Phase121_Clear_Versus_Feature_Panel_Clear;


   procedure Test_Phase121_Selection_Mapping_Rejects_Stale_Generic_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);

      Assert (not Editor.Outline.Feature_Row_Maps_To_Item
                (S.Outline, S.Feature_Panel,
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel)),
              "generic feature-panel rows are not current outline projections");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "open selected outline rejects stale or non-outline selected rows");
      Assert (Active_Message_Text (S) = Editor.Outline.Reason_No_Outline_Item_Selected,
              "stale or non-outline row reports selected-item unavailable reason");
   end Test_Phase121_Selection_Mapping_Rejects_Stale_Generic_Row;


   procedure Test_Phase121_Project_Summary_Exposes_Outline_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.State.Project_Scoped_State_Summary;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Summary := Editor.State.Project_Scoped_State_Summary_For (S);

      Assert (Summary.Outline_Item_Count = Item_Count (S.Outline),
              "project summary exposes outline item count");
      Assert (Summary.Outline_Fingerprint = Fingerprint (S.Outline),
              "project summary exposes outline fingerprint");
      Assert (Summary.Feature_Panel_Row_Count =
                Editor.Feature_Panel.Row_Count (S.Feature_Panel),
              "project summary exposes feature-panel row count");
      Assert (Summary.Feature_Panel_Has_Selection,
              "project summary exposes feature-panel selection state");
      Assert (Summary.Feature_Panel_Selected_Row = 1,
              "project summary exposes selected feature-panel row");
      Assert (Summary.Feature_Panel_Fingerprint =
                Editor.Feature_Panel.Fingerprint (S.Feature_Panel),
              "project summary exposes feature-panel fingerprint");
   end Test_Phase121_Project_Summary_Exposes_Outline_Workflow;



   procedure Test_Phase122_Refresh_Seam_Status_And_Unsupported_Sources
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O             : Outline_State;
      P             : Editor.Feature_Panel.Feature_Panel_State;
      Result        : Outline_Refresh_Result;
      Before_Finger : Natural := 0;
   begin
      Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
      Assert (Result.Status = Outline_Refresh_Ok,
              "outline refresh reports ok");
      Assert (Result.Failure_Kind = No_Failure,
              "outline refresh reports no failure kind");
      Assert (Result.Item_Count = 5 and then Item_Count (O) = 5,
              "outline refresh reports deterministic item count");
      Assert (Editor.Feature_Panel.Row_Count (P) = 0,
              "outline refresh does not mutate feature-panel rows");

      Before_Finger := Fingerprint (O);
      Result := Refresh (O, Outline_Source_Buffer_Extractor);
      Assert (Result.Status = Outline_Refresh_Unavailable,
              "buffer extractor source requires explicit Executor snapshot");
      Assert (Result.Failure_Kind = Extractor_Not_Available,
              "direct outline refresh reports extractor unavailable");
      Assert (Fingerprint (O) = Before_Finger,
              "direct buffer extractor source does not mutate outline");

      Result := Refresh (O, Outline_Source_Project_Extractor);
      Assert (Result.Status = Outline_Refresh_Unavailable,
              "project extractor source remains unavailable in Phase 123");
      Assert (Result.Failure_Kind = Extractor_Not_Available,
              "future project extractor source reports extractor unavailable");
      Assert (Fingerprint (O) = Before_Finger,
              "unsupported project extractor source does not mutate outline");
   end Test_Phase122_Refresh_Seam_Status_And_Unsupported_Sources;


   procedure Test_Phase122_Availability_Does_Not_Refresh_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Outline_Before  : Natural;
      Panel_Before    : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Messages_Before : Natural;
      A               : Editor.Commands.Command_Availability;
      Outline_Commands : constant array (Positive range <>) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Focus_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "availability must not populate outline");
      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      for Id of Outline_Commands loop
         A := Editor.Executor.Command_Availability (S, Id);
         Assert (Fingerprint (S.Outline) = Outline_Before,
                 "outline availability preserves outline fingerprint");
         Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
                 "outline availability preserves feature-panel fingerprint");
         Assert (Editor.Messages.Count (S.Messages) = Messages_Before,
                 "outline availability emits no messages");
         Assert (Item_Count (S.Outline) = 0,
                 "outline availability does not refresh placeholder items");
      end loop;
   end Test_Phase122_Availability_Does_Not_Refresh_Outline;


   procedure Test_Phase123_Command_Refresh_Uses_Buffer_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_First : Natural := 0;
      Panel_First   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result        : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package One" & ASCII.LF & "package One is end One;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first refresh executes through executor");
      Outline_First := Fingerprint (S.Outline);
      Panel_First := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Editor.State.Load_Text
        (S, "@outline procedure Totally_Different" & ASCII.LF &
            "procedure Totally_Different is begin null; end Totally_Different;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second refresh executes through executor");
      Assert (Fingerprint (S.Outline) /= Outline_First,
              "buffer extractor refresh inspects explicit active-buffer snapshot");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Labels_Hash /=
                Panel_First.Row_Labels_Hash,
              "buffer extractor projection labels follow markers");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_Refreshed,
              "executor maps refresh ok to one canonical message");
   end Test_Phase123_Command_Refresh_Uses_Buffer_Markers;


   procedure Test_Phase122_Clear_And_Reset_Do_Not_Auto_Refresh
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 1,
              "fixture has refreshed extracted outline items");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Item_Count (S.Outline) = 0,
              "project-scoped reset clears outline items");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "project-scoped reset clears feature-panel rows");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Show_Outline);
      Assert (Item_Count (S.Outline) = 0,
              "show outline after reset does not auto-refresh extracted items");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "show outline after reset does not auto-project rows");
   end Test_Phase122_Clear_And_Reset_Do_Not_Auto_Refresh;


   procedure Test_Phase123_Extractor_Marker_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("ignored" & ASCII.LF &
           "   @outline package Demo" & ASCII.LF &
           "@outline type State" & ASCII.LF &
           "not an outline row");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "marker extraction succeeds for ordinary text");
      Assert (Editor.Outline_Extractor.Failure (Result) =
                Editor.Outline_Extractor.No_Failure,
              "successful marker extraction has no failure kind");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "only @outline marker rows become outline items");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2, "apply replaces outline with extracted items");
      Assert (Item_Label (O, 1) = "package Demo",
              "marker label removes @outline prefix");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package marker derives package kind");
      Assert (Item_Line (O, 1) = 2 and then Item_Column (O, 1) = 4,
              "extracted target stores one-based line and first non-space column");
      Assert (Item_Target_Kind (O, 1) = Buffer_Position_Target,
              "extracted target metadata is stored but remains inert");
   end Test_Phase123_Extractor_Marker_Grammar;

   procedure Test_Phase579_Outline_Marker_Fallback_Is_Marker_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("not a declaration" & ASCII.LF &
           "   @outline procedure Manual_Run" & ASCII.LF &
           "still not a declaration" & ASCII.LF,
           "manual.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "marker-only fallback extraction succeeds for Ada-like labels");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 1,
              "parser-empty fallback keeps only explicit @outline rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Manual_Run",
              "manual marker label is preserved without Ada fallback scanning");
      Assert (Item_Line (O, 1) = 2 and then Item_Column (O, 1) = 4,
              "manual marker target remains snapshot-owned");
   end Test_Phase579_Outline_Marker_Fallback_Is_Marker_Only;


   procedure Test_Phase579_Outline_Parser_Runs_For_Extensionless_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Extensionless is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Extensionless;",
           "scratch");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "parser-owned extraction succeeds without Ada file extension");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "extensionless source is parsed by Ada_Declaration_Parser before marker fallback");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Extensionless",
              "extensionless package row comes from the language model");
      Assert (Item_Label (O, 2) = "procedure Run",
              "extensionless procedure row comes from the language model");
   end Test_Phase579_Outline_Parser_Runs_For_Extensionless_Buffer;


   procedure Test_Phase124_Snapshot_Is_Immutable_And_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result   : Editor.Outline_Extractor.Extraction_Result;
      O        : Outline_State;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Snapshot_A" & ASCII.LF & "body");
      Snapshot := Editor.Outline_Extractor.Make_Snapshot (Editor.State.Current_Text (S));

      Editor.State.Load_Text (S, "@outline package Snapshot_B" & ASCII.LF & "body");
      Result := Editor.Outline_Extractor.Extract (Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Editor.Outline_Extractor.Is_Success (Result),
              "snapshot extraction remains successful after buffer mutation");
      Assert (Item_Count (O) = 1, "snapshot A produces one item");
      Assert (Item_Label (O, 1) = "package Snapshot_A",
              "extraction reads the immutable snapshot, not later buffer text");
      Assert (Editor.State.Current_Text (S) = "@outline package Snapshot_B" & ASCII.LF & "body",
              "snapshot extraction does not repair or mutate current buffer text");
   end Test_Phase124_Snapshot_Is_Immutable_And_Read_Only;


   procedure Test_Phase124_Marker_Grammar_Freeze_And_Edge_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("@outline" & ASCII.LF &
           "@outline    " & ASCII.LF &
           "   @outline section Setup   " & ASCII.CR & ASCII.LF &
           "@outline field Value" & ASCII.LF &
           "@Outline package Wrong_Case" & ASCII.LF &
           "@outline frobnicate Future" & ASCII.LF &
           "@outline procedure No_Final_Newline");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "edge-case marker extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "empty labels and wrong-case markers are ignored");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Item_Label (O, 1) = "section Setup",
              "excess marker and label whitespace is trimmed");
      Assert (Item_Kind (O, 1) = Outline_Section,
              "section marker derives section kind");
      Assert (Item_Line (O, 1) = 3 and then Item_Column (O, 1) = 4,
              "CRLF line and leading whitespace column are deterministic");
      Assert (Item_Kind (O, 2) = Outline_Field,
              "field marker derives field kind");
      Assert (Item_Kind (O, 3) = Outline_Unknown,
              "unknown marker kinds are accepted as unknown outline items");
      Assert (Item_Label (O, 4) = "procedure No_Final_Newline",
              "final line without newline is extracted normally");
   end Test_Phase124_Marker_Grammar_Freeze_And_Edge_Cases;


   procedure Test_Phase124_Result_Invariants_And_Fingerprints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot (""));
      A : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("noise" & ASCII.LF & "@outline type State"));
      B : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("other" & ASCII.LF & "@outline type State"));
      C : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("@outline type State"));
      Default_Result : Editor.Outline_Extractor.Extraction_Result;
      O : Outline_State;
      Before : Natural;
   begin
      Assert (Editor.Outline_Extractor.Is_Success (Empty_Result),
              "empty buffer is a successful zero-item extraction");
      Assert (Editor.Outline_Extractor.Failure (Empty_Result) =
                Editor.Outline_Extractor.No_Failure,
              "successful zero-item extraction has no failure");
      Assert (Editor.Outline_Extractor.Item_Count (Empty_Result) = 0,
              "empty buffer produces no items");

      Assert (Editor.Outline_Extractor.Fingerprint (A) =
                Editor.Outline_Extractor.Fingerprint (B),
              "same marker at same line has same extraction fingerprint");
      Assert (Editor.Outline_Extractor.Fingerprint (A) /=
                Editor.Outline_Extractor.Fingerprint (C),
              "line-number changes are reflected in extraction fingerprint");

      Populate_Synthetic_Outline (O);
      Before := Fingerprint (O);
      Editor.Outline_Extractor.Apply_To_Outline (Default_Result, O);
      Assert (Fingerprint (O) = Before,
              "non-ok extraction result does not replace outline state");
   end Test_Phase124_Result_Invariants_And_Fingerprints;


   procedure Test_Phase124_Zero_Item_Refresh_Clears_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      A      : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Old" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 1,
              "fixture starts with extracted outline item");

      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.State.Load_Text (S, "ordinary text without markers");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "zero-item refresh is successful, not failed");
      Assert (Item_Count (S.Outline) = 0,
              "zero-item refresh clears previous outline items");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1
                and then Editor.Feature_Panel.Row_Kind (S.Feature_Panel, 1) =
                  Editor.Feature_Panel.Feature_Row_Empty_State,
              "zero-item refresh projects a display-only empty-state row");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "zero-item refresh clears stale feature-panel selection");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "successful zero-item refresh still shows the feature panel");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_Refreshed,
              "zero-item refresh emits the canonical success message");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Outline);
      Assert (not Editor.Commands.Is_Available (A),
              "clear outline is unavailable after zero-item refresh");
   end Test_Phase124_Zero_Item_Refresh_Clears_Rows;


   procedure Test_Phase124_Dirty_Buffer_Refresh_Is_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Caret_Count_Before : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Dirty_Run" & ASCII.LF & "body");
      Editor.State.Set_Dirty (S, True);
      Caret_Count_Before := Natural (S.Carets.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Editor.State.Is_Dirty (S),
              "refresh outline does not clear dirty state");
      Assert (Editor.State.Current_Text (S) =
                "@outline procedure Dirty_Run" & ASCII.LF & "body",
              "refresh outline does not save or mutate buffer text");
      Assert (Natural (S.Carets.Length) = Caret_Count_Before,
              "refresh outline does not alter caret count");
      Assert (Item_Count (S.Outline) = 1,
              "dirty buffer extraction reads current in-memory text");
   end Test_Phase124_Dirty_Buffer_Refresh_Is_Read_Only;


   procedure Test_Phase124_No_Extraction_From_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Outline_Before  : Natural;
      Panel_Before    : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Messages_Before : Natural;
      A               : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Initial" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      Editor.State.Load_Text
        (S, "@outline package Changed_But_Not_Refreshed" & ASCII.LF & "x");
      Messages_Before := Editor.Messages.Count (S.Messages);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Editor.Commands.Is_Available (A),
              "refresh outline remains available with an active buffer");
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "availability does not extract changed buffer text");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "availability does not project changed buffer text");
      Assert (Editor.Messages.Count (S.Messages) = Messages_Before,
              "availability emits no extraction messages");
   end Test_Phase124_No_Extraction_From_Availability;


   procedure Test_Phase124_Projection_And_Targets_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Active_Before : Boolean;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline section Setup" & ASCII.LF &
            "@outline procedure Run" & ASCII.LF & "body");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);

      Assert (Editor.Feature_Panel.Row_Kind (S.Feature_Panel, 1) =
                Editor.Feature_Panel.Feature_Row_Header,
              "outline section projects to a feature-panel header row");
      Assert (Editor.Feature_Panel.Row_Kind (S.Feature_Panel, 2) =
                Editor.Feature_Panel.Feature_Row_Item,
              "outline subprogram projects to a feature-panel item row");
      Assert (Item_Target_Kind (S.Outline, 2) = Buffer_Position_Target,
              "extracted item stores buffer-position target metadata");
      Assert (Item_Line (S.Outline, 2) = 2 and then Item_Column (S.Outline, 2) = 1,
              "extracted item stores one-based line and column");

      Active_Before := Editor.State.Has_Active_Buffer (S);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Feature_Panel.Select_Next (S.Feature_Panel);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);

      Assert (Editor.State.Current_Text (S) =
                "@outline section Setup" & ASCII.LF &
                "@outline procedure Run" & ASCII.LF & "body",
              "open selected extracted item does not mutate buffer text");
      Assert (Editor.State.Has_Active_Buffer (S) = Active_Before,
              "open selected extracted item does not change active-buffer presence");
      declare
         Row : Natural := 0;
         Col : Natural := 0;
      begin
         Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
         Assert (Row = 1 and then Col = 0,
                 "open selected extracted item navigates to target line");
      end;
   end Test_Phase124_Projection_And_Targets_Are_Stable;


   procedure Test_Phase125_Outline_Source_Classification
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O      : Outline_State;
      Result : Outline_Refresh_Result;
   begin
      Assert (Source_Class (O) = No_Outline,
              "new outline state starts classified as no outline");
      Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
      Assert (Result.Source_Class = Extracted_Outline,
              "synthetic fixture rows use extracted-outline classification after Replace_Items");
      Assert (Source_Class (O) = Extracted_Outline,
              "synthetic rows enter through Replace_Items and use extracted-outline classification");

      declare
         Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
           Editor.Outline_Extractor.Make_Snapshot
             ("@outline package Demo" & ASCII.LF,
              Active_Buffer_Token  => 1,
              Buffer_Revision      => 1,
              Lifecycle_Generation => 1,
              Request_Token        => Next_Request_Token (O));
         Extracted : Editor.Outline_Extractor.Extraction_Result;
      begin
         Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
         Extracted := Editor.Outline_Extractor.Extract (Snapshot);
         Editor.Outline_Extractor.Apply_To_Outline (Extracted, O);
      end;

      Assert (Source_Class (O) = Extracted_Outline,
              "successful extraction classifies visible rows as extracted");
      Assert (Last_Extraction_Source_Class (O) = Extracted_Outline,
              "diagnostics remember latest extracted source class");
      Assert (Last_Extraction_Item_Count (O) = 1,
              "diagnostics remember latest extracted item count");

      Clear (O);
      Assert (Source_Class (O) = No_Outline,
              "clear returns outline state to no-outline classification");
   end Test_Phase125_Outline_Source_Classification;


   procedure Test_Phase125_Stale_Result_Rejected_After_Buffer_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      A : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      B : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      A_Result : Editor.Outline_Extractor.Extraction_Result;
   begin
      A := Editor.Outline_Extractor.Make_Snapshot
        ("@outline package Buffer_A" & ASCII.LF,
         Active_Buffer_Token  => 10,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (A));
      A_Result := Editor.Outline_Extractor.Extract (A);

      B := Editor.Outline_Extractor.Make_Snapshot
        ("@outline package Buffer_B" & ASCII.LF,
         Active_Buffer_Token  => 11,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (B));

      Editor.Outline_Extractor.Apply_To_Outline (A_Result, O);
      Assert (Item_Count (O) = 0,
              "late result from previous active buffer does not create rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "late result from previous active buffer is classified stale");
   end Test_Phase125_Stale_Result_Rejected_After_Buffer_Switch;


   procedure Test_Phase125_Stale_Result_Rejected_After_Buffer_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Rev_1 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Rev_2 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Old_Result : Editor.Outline_Extractor.Extraction_Result;
   begin
      Rev_1 := Editor.Outline_Extractor.Make_Snapshot
        ("@outline package Revision_One" & ASCII.LF,
         Active_Buffer_Token  => 10,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Rev_1));
      Old_Result := Editor.Outline_Extractor.Extract (Rev_1);

      Rev_2 := Editor.Outline_Extractor.Make_Snapshot
        ("@outline package Revision_Two" & ASCII.LF,
         Active_Buffer_Token  => 10,
         Buffer_Revision      => 2,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Rev_2));

      Editor.Outline_Extractor.Apply_To_Outline (Old_Result, O);
      Assert (Item_Count (O) = 0,
              "old revision result does not replace current revision outline");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "old revision result is classified stale");
   end Test_Phase125_Stale_Result_Rejected_After_Buffer_Edit;


   procedure Test_Phase125_Clear_Invalidates_Pending_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("@outline procedure Late" & ASCII.LF,
         Active_Buffer_Token  => 7,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Result := Editor.Outline_Extractor.Extract (Snapshot);
      Clear (O);

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 0,
              "manual clear prevents a late result from resurrecting rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "late result after manual clear is classified stale");
   end Test_Phase125_Clear_Invalidates_Pending_Result;


   procedure Test_Phase125_Zero_Item_Result_Is_Diagnostic_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Populate_Synthetic_Outline (O);
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("ordinary text without outline markers",
         Active_Buffer_Token  => 3,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Result := Editor.Outline_Extractor.Extract (Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Item_Count (O) = 0,
              "zero-item extraction clears previous placeholder rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "zero-item extraction is represented as unsupported diagnostic state");
      Assert (Last_Extraction_Message (O)'Length > 0,
              "zero-item extraction records a deterministic diagnostic message");
   end Test_Phase125_Zero_Item_Result_Is_Diagnostic_State;




   procedure Test_Phase126_Ada_Outline_Extracts_Common_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Editor.Outline is" & ASCII.LF &
           "package body Editor.Outline is" & ASCII.LF &
           "procedure Refresh;" & ASCII.LF &
           "function Item_Count return Natural;" & ASCII.LF &
           "type Outline_Source_Class is" & ASCII.LF &
           "task Worker;" & ASCII.LF &
           "protected Guard is");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada lexical extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "Ada lexical extraction recognizes common declarations");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Source_Class (O) = Extracted_Outline,
              "Ada declarations apply as extracted outline rows");
      Assert (Item_Label (O, 1) = "package Editor.Outline",
              "package spec label is stable");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package spec kind is stable");
      Assert (Item_Label (O, 2) = "package body Editor.Outline",
              "package body label is stable");
      Assert (Item_Kind (O, 2) = Outline_Package_Body,
              "package body kind is stable");
      Assert (Item_Label (O, 3) = "procedure Refresh",
              "procedure label is stable");
      Assert (Item_Kind (O, 3) = Outline_Procedure,
              "procedure kind is stable");
      Assert (Item_Label (O, 4) = "function Item_Count",
              "function label is stable");
      Assert (Item_Kind (O, 4) = Outline_Function,
              "function kind is stable");
      Assert (Item_Label (O, 5) = "type Outline_Source_Class",
              "type label is stable");
      Assert (Item_Kind (O, 5) = Outline_Type,
              "type kind is stable");
      Assert (Item_Kind (O, 6) = Outline_Task,
              "task kind is stable");
      Assert (Item_Kind (O, 7) = Outline_Protected,
              "protected kind is stable");
   end Test_Phase126_Ada_Outline_Extracts_Common_Declarations;


   procedure Test_Phase126_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Commented is" & ASCII.LF &
           "   -- procedure Hidden;" & ASCII.LF &
           "PACKAGE Demo IS -- procedure Hidden_Trailing;" & ASCII.LF &
           "PrOcEdUrE Run; -- function Not_Seen return Boolean;" & ASCII.LF &
           "function Visible return Natural;");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "Ada scanner ignores full-line and trailing comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "Ada keyword matching is case-insensitive for packages");
      Assert (Item_Label (O, 2) = "procedure Run",
              "Ada keyword matching is case-insensitive for procedures");
      Assert (Item_Label (O, 3) = "function Visible",
              "trailing comments do not poison following declarations");
   end Test_Phase126_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive;


   procedure Test_Phase126_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Empty_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot (""));
      Non_Ada_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("# heading" & ASCII.LF & "plain text without declarations"));
      Non_Ada_Extension_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract
          (Editor.Outline_Extractor.Make_Snapshot
             ("function Visible return Natural;", "demo.js"));
   begin
      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Empty_Result, O);
      Assert (Item_Count (O) = 0,
              "empty extraction clears previous placeholder rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "empty extraction is a deterministic unsupported state");

      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Non_Ada_Result, O);
      Assert (Item_Count (O) = 0,
              "non-Ada text does not retain stale Ada or placeholder rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "non-Ada text is classified as unsupported content");

      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Non_Ada_Extension_Result, O);
      Assert (Item_Count (O) = 0,
              "non-Ada file extensions disable Ada content sniffing");
      Assert (Source_Class (O) = Unsupported_Content,
              "non-Ada file extensions are classified as unsupported content");
   end Test_Phase126_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported;


   procedure Test_Phase126_Ada_Outline_Rows_Open_To_Target_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Ada outline refresh executes through the command path");
      Assert (Item_Count (S.Outline) = 2,
              "Ada command refresh extracts package and procedure rows");

      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Feature_Panel.Select_Next (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "opening an Ada outline row executes");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 3,
              "opening an Ada outline row navigates to captured line/column");
   end Test_Phase126_Ada_Outline_Rows_Open_To_Target_Line;


   procedure Test_Phase126_Ada_Outline_Result_Still_Rejected_When_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Old_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      New_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Old_Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Old_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Old_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 1,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Old_Snapshot));
      Old_Result := Editor.Outline_Extractor.Extract (Old_Snapshot);

      New_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package New_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 2,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (New_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Old_Result, O);
      Assert (Item_Count (O) = 0,
              "stale Ada extraction result does not create rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "stale Ada extraction result keeps stale classification");
   end Test_Phase126_Ada_Outline_Result_Still_Rejected_When_Stale;


   procedure Test_Phase127_Ada_Outline_Extracts_Multiline_Procedure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure Refresh" & ASCII.LF &
           "     (State : in out Outline_State;" & ASCII.LF &
           "      Force : Boolean := False);" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "multi-line procedure extraction emits package and procedure only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Refresh",
              "multi-line procedure label excludes profile");
      Assert (Item_Depth (O, 2) = 1,
              "multi-line procedure inside package receives member depth");
   end Test_Phase127_Ada_Outline_Extracts_Multiline_Procedure;


   procedure Test_Phase127_Ada_Outline_Extracts_Multiline_Function
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   function Item_Count" & ASCII.LF &
           "     (State : Outline_State)" & ASCII.LF &
           "      return Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "multi-line function extraction emits package and function only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "function Item_Count",
              "multi-line function label excludes profile and return type");
      Assert (Item_Kind (O, 2) = Outline_Function,
              "multi-line function preserves function kind");
   end Test_Phase127_Ada_Outline_Extracts_Multiline_Function;


   procedure Test_Phase127_Ada_Outline_Does_Not_Duplicate_Continuation_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Refresh" & ASCII.LF &
           "  (Procedure_Name : String;" & ASCII.LF &
           "   Function_Name  : String);" & ASCII.LF &
           "function Done return Boolean;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "continuation lines do not become duplicate outline symbols");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Refresh",
              "first row is the multi-line procedure declaration");
      Assert (Item_Label (O, 2) = "function Done",
              "scanner resumes after the multi-line declaration boundary");
   end Test_Phase127_Ada_Outline_Does_Not_Duplicate_Continuation_Lines;


   procedure Test_Phase127_Ada_Outline_Extracts_Generic_Package
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "package Generic_Map is" & ASCII.LF &
           "end Generic_Map;",
           "generic_map.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 1,
              "generic package extraction emits one outline row");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "generic package Generic_Map",
              "generic package label is compact and stable");
      Assert (Item_Kind (O, 1) = Outline_Package,
              "generic package uses package outline kind without enum churn");
   end Test_Phase127_Ada_Outline_Extracts_Generic_Package;


   procedure Test_Phase127_Ada_Outline_Extracts_Generic_Procedure_And_Function
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element_Type is private;" & ASCII.LF &
           "procedure Swap" & ASCII.LF &
           "  (Left  : in out Element_Type;" & ASCII.LF &
           "   Right : in out Element_Type);" & ASCII.LF &
           "generic" & ASCII.LF &
           "   with function ""<""" & ASCII.LF &
           "     (Left, Right : Key_Type) return Boolean;" & ASCII.LF &
           "function Minimum" & ASCII.LF &
           "  (Left, Right : Key_Type)" & ASCII.LF &
           "   return Key_Type;",
           "generic_ops.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "generic formal declarations and generic units are extracted");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element_Type",
              "generic formal type row is extracted");
      Assert (Item_Label (O, 2) = "generic procedure Swap",
              "generic procedure label is compact");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "generic formal operator function row is extracted");
      Assert (Item_Label (O, 4) = "generic function Minimum",
              "generic function label is compact");
   end Test_Phase127_Ada_Outline_Extracts_Generic_Procedure_And_Function;


   procedure Test_Phase127_Ada_Outline_Clears_Pending_Generic_After_Use
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element_Type is private;" & ASCII.LF &
           "procedure Swap" & ASCII.LF &
           "  (Left, Right : in out Element_Type);" & ASCII.LF &
           "procedure Plain;",
           "generic_ops.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "generic marker applies to the following declaration after formals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element_Type",
              "generic formal type row is extracted");
      Assert (Item_Label (O, 2) = "generic procedure Swap",
              "generic marker applies to the generic procedure");
      Assert (Item_Label (O, 3) = "procedure Plain",
              "generic marker does not leak into later declarations");
   end Test_Phase127_Ada_Outline_Clears_Pending_Generic_After_Use;


   procedure Test_Phase127_Ada_Outline_Label_Excludes_Profile_And_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Editor.Outline is -- package Hidden is" & ASCII.LF &
           "procedure Refresh (Force : Boolean); -- function Hidden return Boolean" & ASCII.LF &
           "function Item_Count return Natural; -- trailing comment",
           "editor-outline.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "labels ignore profiles and trailing comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Editor.Outline",
              "package body label excludes trailing is and comment");
      Assert (Item_Label (O, 2) = "procedure Refresh",
              "procedure label excludes profile and comment");
      Assert (Item_Label (O, 3) = "function Item_Count",
              "function label excludes return type and comment");
   end Test_Phase127_Ada_Outline_Label_Excludes_Profile_And_Comment;


   procedure Test_Phase127_Ada_Outline_Assigns_Depth_For_Package_Members
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Top is" & ASCII.LF &
           "      procedure Nested;" & ASCII.LF &
           "   end Top;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "depth test extracts package body, member, and nested declaration");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Depth (O, 1) = 0,
              "package body starts at top-level depth");
      Assert (Item_Depth (O, 2) = 1,
              "subprogram body inside package body has member depth");
      Assert (Item_Depth (O, 3) = 2,
              "nested declaration inside subprogram has nested depth");
   end Test_Phase127_Ada_Outline_Assigns_Depth_For_Package_Members;


   procedure Test_Phase127_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("end Stray;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "unmatched end line does not prevent later extraction");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Depth (O, 1) = 0,
              "unmatched end does not underflow depth");
      Assert (Item_Depth (O, 2) = 1,
              "member depth remains stable after unmatched end");
   end Test_Phase127_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End;


   procedure Test_Phase127_Ada_Outline_String_Comment_Marker_Is_Not_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   Message : constant String := ""not -- a comment"";" & ASCII.LF &
           "   procedure Run; -- real comment" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "string literals containing comment markers do not break scanning");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "constant Message",
              "package constant row remains visible");
      Assert (Item_Label (O, 3) = "procedure Run",
              "real trailing comment is still ignored after string-literal line");
   end Test_Phase127_Ada_Outline_String_Comment_Marker_Is_Not_Comment;


   procedure Test_Phase127_Ada_Outline_Distinguishes_Package_Spec_And_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Editor.Outline is" & ASCII.LF &
           "end Editor.Outline;" & ASCII.LF &
           "package body Editor.Outline is" & ASCII.LF &
           "end Editor.Outline;",
           "editor-outline.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "package spec/body distinction extracts two package rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Kind (O, 1) = Outline_Package,
              "package spec keeps package kind");
      Assert (Item_Kind (O, 2) = Outline_Package_Body,
              "package body keeps package-body kind");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "spec") /= 0,
              "package spec detail records spec classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "body") /= 0,
              "package body detail records body classification");
   end Test_Phase127_Ada_Outline_Distinguishes_Package_Spec_And_Body;


   procedure Test_Phase127_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Declared;" & ASCII.LF &
           "   procedure Implemented is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Implemented;" & ASCII.LF &
           "   procedure Multiline" & ASCII.LF &
           "     (Flag : Boolean)" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Multiline;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "procedure declaration/body distinction keeps all rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "declaration") /= 0,
              "procedure declaration detail records declaration classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "body") /= 0,
              "single-line procedure body header records body classification");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "body") /= 0,
              "multi-line procedure body header is upgraded after accumulated is line");
   end Test_Phase127_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body;


   procedure Test_Phase127_Ada_Outline_Still_Rejects_Stale_Multiline_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Old_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      New_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Old_Result   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Old_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Old_Buffer is" & ASCII.LF &
         "   procedure Refresh" & ASCII.LF &
         "     (Force : Boolean);" & ASCII.LF &
         "end Old_Buffer;",
         Active_Buffer_Token  => 1,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Old_Snapshot));
      Old_Result := Editor.Outline_Extractor.Extract (Old_Snapshot);

      New_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package New_Buffer is" & ASCII.LF,
         Active_Buffer_Token  => 2,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (New_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Old_Result, O);
      Assert (Item_Count (O) = 0,
              "stale multi-line Ada extraction result does not create rows");
      Assert (Source_Class (O) = Stale_Extracted_Outline,
              "stale multi-line Ada extraction result keeps stale classification");
   end Test_Phase127_Ada_Outline_Still_Rejects_Stale_Multiline_Result;


   procedure Test_Phase127_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Visible;", "demo.js");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Populate_Synthetic_Outline (O);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 0,
              "unsupported buffer clears previous rows instead of keeping stale Ada rows");
      Assert (Source_Class (O) = Unsupported_Content,
              "unsupported buffer receives deterministic unsupported classification");
   end Test_Phase127_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows;


   procedure Test_Phase128_Refresh_Preserves_Selected_Item_By_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot_1 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Snapshot_2 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result_1   : Editor.Outline_Extractor.Extraction_Result;
      Result_2   : Editor.Outline_Extractor.Extraction_Result;
   begin
      Snapshot_1 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 128,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_1));
      Result_1 := Editor.Outline_Extractor.Extract (Snapshot_1);
      Editor.Outline_Extractor.Apply_To_Outline (Result_1, O);

      Select_Item (O, 2);
      Assert (Selected_Index (O) = 2, "fixture selects extracted procedure row");

      Snapshot_2 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Stop;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 128,
         Buffer_Revision      => 2,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_2));
      Result_2 := Editor.Outline_Extractor.Extract (Snapshot_2);
      Editor.Outline_Extractor.Apply_To_Outline (Result_2, O);

      Assert (Selected_Index (O) = 2,
              "phase 128 preserves selected outline item by stable target metadata");
      Assert (Item_Label (O, Selected_Index (O)) = "procedure Run",
              "phase 128 preserved selection still names the selected symbol");
   end Test_Phase128_Refresh_Preserves_Selected_Item_By_Target;


   procedure Test_Phase128_Refresh_Does_Not_Preserve_Selection_Across_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot_1 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Snapshot_2 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot_1 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 201,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_1));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot_1), O);
      Select_Item (O, 2);

      Snapshot_2 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 202,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_2));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot_2), O);

      Assert (Selected_Index (O) = 0,
              "phase 128 does not preserve outline selection across buffer tokens");
   end Test_Phase128_Refresh_Does_Not_Preserve_Selection_Across_Buffers;


   procedure Test_Phase128_Select_Current_Symbol_Chooses_Preceding_Item
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result   : Editor.Outline_Extractor.Extraction_Result;
      Index    : Natural;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 300,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Result := Editor.Outline_Extractor.Extract (Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Index := Find_Nearest_Item_For_Position (O, 300, 3, 1);
      Assert (Index /= 0, "phase 128 nearest-symbol lookup finds a preceding row");
      Assert (Item_Label (O, Index) = "procedure First",
              "phase 128 nearest-symbol lookup chooses greatest line at or before cursor");
   end Test_Phase128_Select_Current_Symbol_Chooses_Preceding_Item;


   procedure Test_Phase128_Select_Next_Previous_Skip_Non_Selectable_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("@outline section Navigation" & ASCII.LF &
         "@outline procedure First" & ASCII.LF &
         "@outline section More" & ASCII.LF &
         "@outline procedure Second",
         Active_Buffer_Token  => 400,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Select_Next_Selectable (O),
              "phase 128 select-next finds first selectable row");
      Assert (Selected_Index (O) = 2,
              "phase 128 select-next skips non-selectable section row");
      Assert (Select_Next_Selectable (O),
              "phase 128 select-next finds following selectable row");
      Assert (Selected_Index (O) = 4,
              "phase 128 select-next skips intermediate non-selectable section row");
      Assert (Select_Previous_Selectable (O),
              "phase 128 select-previous finds previous selectable row");
      Assert (Selected_Index (O) = 2,
              "phase 128 select-previous skips non-selectable rows");
   end Test_Phase128_Select_Next_Previous_Skip_Non_Selectable_Rows;


   procedure Test_Phase129_Current_Symbol_Updates_On_Cursor_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 501,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 501, 3, 1);
      Assert (Has_Current_Symbol (O),
              "phase 129 cursor update records a current outline symbol");
      Assert (Current_Symbol_Label (O) = "procedure Second",
              "phase 129 current symbol uses the nearest preceding extracted row");
      Assert (Current_Symbol_Line (O) = 3,
              "phase 129 current symbol records the target source line");
   end Test_Phase129_Current_Symbol_Updates_On_Cursor_Line;


   procedure Test_Phase129_Current_Symbol_Clears_Before_First_Item
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("" & ASCII.LF &
         "package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 502,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 502, 1, 1);
      Assert (not Has_Current_Symbol (O),
              "phase 129 cursor before first symbol clears current-symbol state");
      Assert (Current_Symbol_Index (O) = 0,
              "phase 129 cleared current symbol exposes zero index");
   end Test_Phase129_Current_Symbol_Clears_Before_First_Item;


   procedure Test_Phase129_Current_Symbol_Does_Not_Change_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 503,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Select_Item (O, 2);

      Update_Current_Symbol_For_Cursor (O, 503, 3, 1);
      Assert (Selected_Index (O) = 2,
              "phase 129 cursor current-symbol update does not move outline selection");
      Assert (Current_Symbol_Index (O) = 3,
              "phase 129 current-symbol index remains independent from selection");
   end Test_Phase129_Current_Symbol_Does_Not_Change_Selection;


   procedure Test_Phase129_Current_Symbol_Clears_For_Unsupported_And_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF & "   procedure Run;" & ASCII.LF & "end Demo;",
         Active_Buffer_Token  => 504,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 504, 2, 1);
      Assert (Has_Current_Symbol (O), "phase 129 fixture has current symbol");

      Mark_Unsupported (O);
      Assert (not Has_Current_Symbol (O),
              "phase 129 unsupported outline state clears current symbol");
      Assert (Outline_Header_Text (O) = "Outline: unavailable",
              "phase 129 unsupported outline state has compact header text");

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 504, 2, 1);
      Mark_Extraction_Failed (O);
      Assert (not Has_Current_Symbol (O),
              "phase 129 extraction failure clears current symbol");
      Assert (Outline_Header_Text (O) = "Outline: refresh failed",
              "phase 129 extraction failure has compact header text");
   end Test_Phase129_Current_Symbol_Clears_For_Unsupported_And_Failure;


   procedure Test_Phase129_Header_And_Row_Projection_Mark_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Render : Editor.Feature_Panel.Feature_Panel_Render_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 505,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 505, 3, 1);
      Select_Item (O, 2);

      Set_Rows_From_Outline (O, P);
      Assert (Outline_Header_Text (O) = "Outline: procedure Second",
              "phase 129 header prefers the current symbol label");
      Assert (Editor.Feature_Panel.Header_Text (P) = "Outline: procedure Second",
              "phase 129 projection exposes compact outline header text");
      Assert (not Editor.Feature_Panel.Row_Is_Current_Symbol (P, 2),
              "phase 129 selected-only outline row is not marked current");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (P, 3),
              "phase 129 projection marks the current-symbol row");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 2,
              "phase 129 projection keeps selected row independent from current symbol");

      Render := Editor.Feature_Panel.Build_Render_Snapshot (P);
      Assert (Editor.Feature_Panel.Snapshot_Row_Selected (Render, 2),
              "phase 129 selected row remains primary in render snapshot");
      Assert (Editor.Feature_Panel.Snapshot_Row_Is_Current_Symbol (Render, 3),
              "phase 129 render snapshot carries current-symbol marker");

      Select_Item (O, 3);
      Set_Rows_From_Outline (O, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 3,
              "phase 129 selected current-symbol row keeps selected state primary");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (P, 3),
              "phase 129 selected current-symbol row keeps passive marker metadata");
   end Test_Phase129_Header_And_Row_Projection_Mark_Current_Symbol;


   procedure Test_Phase129_Clear_Removes_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF & "   procedure Run;" & ASCII.LF & "end Demo;",
         Active_Buffer_Token  => 506,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 506, 2, 1);
      Clear (O);

      Assert (not Has_Current_Symbol (O),
              "phase 129 clear removes current-symbol state");
      Assert (Outline_Header_Text (O) = "Outline: not refreshed",
              "phase 129 clear reports no-symbol header state");
   end Test_Phase129_Clear_Removes_Current_Symbol;


   procedure Test_Phase129_Stale_Result_Preserves_Accepted_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Accepted_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Accepted_Result   : Editor.Outline_Extractor.Extraction_Result;
      Pending_Snapshot  : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Accepted_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 507,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Accepted_Snapshot));
      Accepted_Result := Editor.Outline_Extractor.Extract (Accepted_Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Accepted_Result, O);
      Update_Current_Symbol_For_Cursor (O, 507, 2, 1);

      Pending_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Newer is" & ASCII.LF,
         Active_Buffer_Token  => 507,
         Buffer_Revision      => 2,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Pending_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Accepted_Result, O);
      Assert (Source_Class (O) = Extracted_Outline,
              "phase 129 stale result preserves accepted outline classification when rows exist");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "phase 129 stale result is still recorded in diagnostics");
      Assert (Current_Symbol_Label (O) = "procedure Run",
              "phase 129 stale result does not clear accepted current-symbol label");
      Assert (Current_Symbol_Index (O) = 2,
              "phase 129 stale result does not replace current-symbol index from rejected rows");
   end Test_Phase129_Stale_Result_Preserves_Accepted_Current_Symbol;


   procedure Test_Phase129_Cursor_Move_Command_Updates_Current_Symbol_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 129 cursor movement fixture refreshes outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 129 first cursor move executes");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 129 second cursor move executes");

      Assert (Current_Symbol_Label (S.Outline) = "procedure Later",
              "phase 129 cursor movement updates passive current-symbol state");
      Assert (Editor.Feature_Panel.Header_Text (S.Feature_Panel) =
                "Outline: procedure Later",
              "phase 129 cursor movement refreshes compact outline header projection");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (S.Feature_Panel, 2),
              "phase 129 cursor movement marks the current-symbol row projection");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "phase 129 cursor movement does not steal outline selection");
   end Test_Phase129_Cursor_Move_Command_Updates_Current_Symbol_Projection;


   procedure Test_Phase130_Reveal_Current_Symbol_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 130 reveal fixture refreshes extracted outline");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "phase 130 fixture tracks second outline row as current symbol");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 130 reveal current symbol command executes");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "phase 130 reveal current symbol shows the outline panel");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 2,
              "phase 130 reveal current symbol requests reveal of the current-symbol row");
      Assert (Selected_Index (S.Outline) = 2,
              "phase 550 reveal current symbol selects the matching outline row");
      Assert (Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              and then Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "phase 550 reveal current symbol mirrors feature-panel selection");
   end Test_Phase130_Reveal_Current_Symbol_Requests_Reveal;


   procedure Test_Phase130_Reveal_Current_Symbol_Noops_When_No_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "intro" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 130 no-current fixture refreshes extracted outline");
      Assert (not Has_Current_Symbol (S.Outline),
              "phase 130 cursor before first symbol has no current symbol");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "phase 130 reveal current symbol is unavailable without a current symbol");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 0,
              "phase 130 no-current reveal leaves no reveal request");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_No_Current_Symbol,
              "phase 130 no-current reveal emits deterministic feedback");
   end Test_Phase130_Reveal_Current_Symbol_Noops_When_No_Current_Symbol;


   procedure Test_Phase130_Select_Current_Symbol_Changes_Selection_And_Reveals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 130 select current symbol executes");
      Assert (Selected_Index (S.Outline) = 2,
              "phase 130 select current symbol intentionally changes outline selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "phase 130 select current symbol mirrors feature-panel selection");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 2,
              "phase 130 select current symbol also requests reveal of selected row");
   end Test_Phase130_Select_Current_Symbol_Changes_Selection_And_Reveals;


   procedure Test_Phase130_Open_Selected_Does_Not_Use_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "phase 130 fixture current symbol is row two before open-selected");

      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 130 open selected executes against selected row");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0,
              "phase 130 open-selected navigates to selected row, not current symbol");
   end Test_Phase130_Open_Selected_Does_Not_Use_Current_Symbol;


   procedure Test_Phase130_Command_Palette_Registers_Outline_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Open_Selected_Outline_Item),
              "phase 130 open selected outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Select_Next_Outline_Item),
              "phase 130 select next outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Select_Previous_Outline_Item),
              "phase 130 select previous outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol),
              "phase 130 reveal current outline symbol is discoverable in the command palette");
      Assert (Editor.Commands.Label
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol) =
              "Reveal Current Outline Symbol",
              "phase 130 reveal current symbol has a concise palette label");
   end Test_Phase130_Command_Palette_Registers_Outline_Navigation;


   procedure Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 focus-return fixture refreshes outline");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 fixture focuses feature panel");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 open-selected succeeds for a live selected outline target");
      Assert (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
              "phase 131 successful outline open-selected should return focus to editor text");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 131 successful outline open-selected should clear feature-panel focus");
   end Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success;

   procedure Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 0);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "phase 131 open-selected without a selected target should be unavailable");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 131 failed open-selected should not steal feature-panel focus");
   end Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target;

   procedure Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "phase 131 fixture has current symbol on row two");
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 open-selected should navigate the selected row");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0 and then Col = 0,
              "phase 131 open-selected must not navigate to passive current-symbol row");
   end Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol;

   procedure Test_Outline_Select_Next_Preserves_Feature_Panel_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 select-next executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 131 select-next should preserve feature-panel focus");
   end Test_Outline_Select_Next_Preserves_Feature_Panel_Focus;

   procedure Test_Outline_Select_Previous_Preserves_Feature_Panel_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Select_Item (S.Outline, 2);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Previous_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 select-previous executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 131 select-previous should preserve feature-panel focus");
   end Test_Outline_Select_Previous_Preserves_Feature_Panel_Focus;

   procedure Test_Outline_Select_Current_Symbol_Preserves_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 select-current-symbol executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 131 select-current-symbol should preserve feature-panel focus");
   end Test_Outline_Select_Current_Symbol_Preserves_Focus;

   procedure Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 reveal-current-symbol executes");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "phase 131 reveal-current-symbol must not move the editor cursor");
   end Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor;

   procedure Test_Outline_Select_Next_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 select-next reveal fixture executes");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) =
                Editor.Outline.Selected_Index (S.Outline),
              "phase 131 select-next should request reveal for the new selected row");
   end Test_Outline_Select_Next_Requests_Reveal;

   procedure Test_Outline_Select_Previous_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Select_Item (S.Outline, 2);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Previous_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 131 select-previous reveal fixture executes");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) =
                Editor.Outline.Selected_Index (S.Outline),
              "phase 131 select-previous should request reveal for the new selected row");
   end Test_Outline_Select_Previous_Requests_Reveal;

   procedure Test_Outline_Command_Palette_And_Keybinding_Use_Same_Handler
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Id : Editor.Commands.Command_Id;
      Chord : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_F3,
         Modifiers =>
           (Ctrl => False, Shift => False, Alt => True, Meta => False));
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Editor.Keybindings.Resolve (Chord, Id) = Editor.Keybindings.Bound_Command,
              "phase 131 outline keybinding should resolve through registry");
      Assert (Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "phase 131 outline keybinding should target the same command id as palette invocation");
      Assert (Editor.Commands.Is_Visible_In_Palette (Id),
              "phase 131 keybound outline command should remain visible in the command palette");
   end Test_Outline_Command_Palette_And_Keybinding_Use_Same_Handler;



   procedure Test_Outline_Mouse_Click_Selects_Row_Without_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Outline_Row_Click (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 132 mouse click should select a live outline row");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 2,
              "phase 132 mouse click updates outline selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "phase 132 mouse click mirrors feature-panel selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "phase 132 mouse click must not navigate the editor cursor");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 132 mouse click preserves feature-panel focus");
   end Test_Outline_Mouse_Click_Selects_Row_Without_Navigation;


   procedure Test_Outline_Mouse_Double_Click_Opens_Selected_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);

      Result := Editor.Executor.Execute_Outline_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 132 mouse activation should dispatch through open-selected");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 2,
              "phase 132 mouse activation selects the activated row first");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2,
              "phase 132 mouse activation navigates to the selected row target");
      Assert (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
              "phase 132 successful mouse activation returns focus to editor text");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 132 successful mouse activation clears feature-panel focus");
   end Test_Outline_Mouse_Double_Click_Opens_Selected_Row;


   procedure Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Populate_Synthetic_Outline (S.Outline);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Outline_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "phase 132 placeholder/diagnostic row activation should be rejected");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "phase 132 rejected diagnostic activation must not move the cursor");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "phase 132 rejected diagnostic activation must not return focus to editor text");
   end Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate;


   procedure Test_Outline_Mouse_Click_Rejects_Stale_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Gen    : Natural := 0;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Gen := Editor.Feature_Panel.Projection_Generation (S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Outline);

      Result := Editor.Executor.Execute_Outline_Row_Click (S, 1, Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "phase 132 stale mouse projection should be rejected");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "phase 132 stale mouse projection must not recreate selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "phase 132 stale mouse projection must not navigate");
   end Test_Outline_Mouse_Click_Rejects_Stale_Projection;


   procedure Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Current_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Current_Before := Editor.Outline.Current_Symbol_Index (S.Outline);
      Assert (Current_Before = 2,
              "phase 132 fixture has passive current symbol on second row");

      Result := Editor.Executor.Execute_Outline_Row_Click (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 132 mouse selection should execute for row one");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 1,
              "phase 132 mouse selection changes selection intentionally");
      Assert (Editor.Outline.Current_Symbol_Index (S.Outline) = Current_Before,
              "phase 132 mouse selection must not overwrite current-symbol state");
   end Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol;


   procedure Test_Phase133_Outline_Filter_Matches_Label_Case_Insensitive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         3 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Select_Item (O, 3);
      Apply_Filter (O, "REFRESH");
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Is_Active (O), "filter is active after non-empty query");
      Assert (Filtered_Row_Count (O) = 1, "filter keeps exactly the matching row");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "filtered projection exposes only matching rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Refresh_Model",
              "case-insensitive label filter projects matching symbol");
      Assert (Selected_Index (O) = 2,
              "hidden selection is reconciled to first visible selectable row");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "panel selection uses visible filtered row index");
      Assert (Map_Panel_Row_To_Outline_Row (O, P, 1) = 2,
              "filtered visible row maps back to underlying outline row");
   end Test_Phase133_Outline_Filter_Matches_Label_Case_Insensitive;

   procedure Test_Phase133_Outline_Clear_Filter_Restores_All_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "procedure");
      Set_Rows_From_Outline (O, P);
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "kind-text filter keeps procedure row");

      Clear_Filter (O);
      Set_Rows_From_Outline (O, P);
      Assert (not Filter_Is_Active (O), "clear-filter deactivates filter");
      Assert (Filtered_Row_Count (O) = 2, "clear-filter restores full count");
      Assert (Editor.Feature_Panel.Row_Count (P) = 2,
              "clear-filter restores all projected rows");
      Assert (Map_Panel_Row_To_Outline_Row (O, P, 2) = 2,
              "unfiltered row mapping remains direct after clear");
   end Test_Phase133_Outline_Clear_Filter_Restores_All_Rows;


   procedure Test_Phase134_Outline_Focus_Filter_Activates_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "ref");
      Activate_Filter_Input (O);

      Assert (Filter_Input_Is_Active (O),
              "phase 134 focus-filter activates outline filter input mode");
      Assert (Filter_Text (O) = "ref",
              "phase 134 focus-filter preserves existing filter text");
      Assert (Filter_Caret (O) = 3,
              "phase 134 focus-filter places the caret at the end of the filter");
   end Test_Phase134_Outline_Focus_Filter_Activates_Input;

   procedure Test_Phase134_Filter_Input_Text_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Character (O, 'c');
      Insert_Filter_Character (O, 'l');
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Input_Is_Active (O),
              "phase 134 typing keeps outline filter input active");
      Assert (Filter_Text (O) = "cl",
              "phase 134 printable keys update filter text");
      Assert (Filtered_Row_Count (O) = 1,
              "phase 134 filter text edit rebuilds filtered projection count");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "phase 134 filter text edit projects only matching rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "phase 134 filter text edit exposes the matching visible row");
   end Test_Phase134_Filter_Input_Text_Rebuilds_Projection;

   procedure Test_Phase134_Filter_Input_Backspace_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "clex");
      Delete_Filter_Character_Backward (O);
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Text (O) = "cle",
              "phase 134 Backspace removes the previous filter character");
      Assert (Filtered_Row_Count (O) = 1,
              "phase 134 Backspace rebuilds filtered row count");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "phase 134 Backspace rebuilds visible projection");
   end Test_Phase134_Filter_Input_Backspace_Rebuilds_Projection;

   procedure Test_Phase134_Filter_Input_Escape_Rule
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");
      Clear_Filter_Text (O);

      Assert (Filter_Input_Is_Active (O),
              "phase 134 Escape with non-empty filter clears text but keeps input active");
      Assert (not Filter_Is_Active (O),
              "phase 134 Escape clear restores unfiltered projection state");
      Assert (Filter_Text (O) = "",
              "phase 134 Escape clear removes filter text");

      Deactivate_Filter_Input (O);
      Assert (not Filter_Input_Is_Active (O),
              "phase 134 Escape with empty filter deactivates input mode");
   end Test_Phase134_Filter_Input_Escape_Rule;

   procedure Test_Phase134_Filter_Edit_Selection_Reconciliation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Select_Item (O, 2);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "clear");
      Assert (Selected_Index (O) = 2,
              "phase 134 live filter preserves selected underlying row when still visible");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "refresh");
      Assert (Selected_Index (O) = 1,
              "phase 134 live filter selects first visible match when previous selection is hidden");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "xyz");
      Assert (Selected_Index (O) = 0,
              "phase 134 live filter clears selection when no selectable rows match");
   end Test_Phase134_Filter_Edit_Selection_Reconciliation;

   procedure Test_Phase134_Filter_Cleared_On_Outline_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");
      Clear (O);

      Assert (Item_Count (O) = 0, "phase 134 clear removes outline rows");
      Assert (not Filter_Input_Is_Active (O),
              "phase 134 clear deactivates filter input");
      Assert (not Filter_Is_Active (O),
              "phase 134 clear deactivates filter projection");
      Assert (Filter_Text (O) = "",
              "phase 134 clear removes filter text");
   end Test_Phase134_Filter_Cleared_On_Outline_Clear;

   procedure Test_Phase134_Filter_Header_Shows_Text_And_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");

      Assert (Outline_Header_Text (O) = "Outline: filter ""ref"" -- 1 of 2 symbols",
              "phase 134 header shows filter text and match count");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "xyz");
      Assert (Outline_Header_Text (O) = "Outline: filter ""xyz"" -- no matches",
              "phase 134 header shows filter text and no-match state");
   end Test_Phase134_Filter_Header_Shows_Text_And_Count;

   procedure Test_Phase134_Filter_Command_Palette_Registers_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Label (Editor.Commands.Command_Focus_Outline_Filter) =
                "Focus Outline Filter",
              "phase 134 focus filter has concise palette label");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Clear_Outline_Filter) =
                "Clear Outline Filter",
              "phase 134 clear filter has concise palette label");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("focus-outline-filter", Found);
      Assert (Found and then Id = Editor.Commands.Command_Focus_Outline_Filter,
              "phase 134 focus filter stable command name round trips");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("toggle-outline-filter", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Outline_Filter,
              "phase 134 toggle filter stable command name round trips");
      Assert (Editor.Commands.Label
                (Editor.Commands.Command_Outline_Filter_History_Previous) =
                "Outline: Previous Filter",
              "phase 135 previous filter history command has concise palette label");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline-filter-history-previous", Found);
      Assert
        (Found and then
           Id = Editor.Commands.Command_Outline_Filter_History_Previous,
         "phase 135 previous filter history stable command name round trips");
   end Test_Phase134_Filter_Command_Palette_Registers_Commands;



   procedure Test_Phase135_Filter_History_Adds_Deduplicates_And_Trims
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "Refresh");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "");
      Commit_Filter_To_History (O);
      Assert (Filter_History_Count (O) = 1,
              "phase 135 history stores non-empty committed filter only");
      Assert (Filter_History_Entry (O, 1) = "refresh",
              "phase 135 history normalizes committed filter text");

      Apply_Filter (O, "clear");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Assert (Filter_History_Count (O) = 2,
              "phase 135 duplicate history entry is moved instead of duplicated");
      Assert (Filter_History_Entry (O, 1) = "refresh",
              "phase 135 duplicate history entry moves to most recent slot");

      for I in 1 .. 12 loop
         Apply_Filter (O, "filter" & Natural'Image (I));
         Commit_Filter_To_History (O);
      end loop;
      Assert (Filter_History_Count (O) = 10,
              "phase 135 history enforces the fixed maximum size");
   end Test_Phase135_Filter_History_Adds_Deduplicates_And_Trims;

   procedure Test_Phase135_Filter_History_Navigation_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "clear");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Clear_Filter_Text (O);

      Assert (not Select_Previous_Filter_History_Entry (O),
              "phase 135 history navigation no-ops while input is inactive");
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "phase 135 previous history replaces active filter text");
      Set_Rows_From_Outline (O, P);
      Assert (Filter_Text (O) = "refresh",
              "phase 135 previous history selects newest filter first");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "phase 135 previous history rebuilds filtered projection");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Refresh_Model",
              "phase 135 previous history projection exposes matching row");

      Assert (Select_Previous_Filter_History_Entry (O),
              "phase 135 second previous history selects older entry");
      Assert (Filter_Text (O) = "clear",
              "phase 135 second previous history replaces filter with older entry");
      Assert (Select_Next_Filter_History_Entry (O),
              "phase 135 next history moves toward newer entry");
      Assert (Filter_Text (O) = "refresh",
              "phase 135 next history restores newer entry");
   end Test_Phase135_Filter_History_Navigation_Rebuilds_Projection;

   procedure Test_Phase135_Clear_Filter_History_Removes_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
   begin
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Clear_Filter_History (O);
      Activate_Filter_Input (O);
      Assert (Filter_History_Count (O) = 0,
              "phase 135 clear history removes all filter entries");
      Assert (not Select_Previous_Filter_History_Entry (O),
              "phase 135 cleared history cannot be navigated");
   end Test_Phase135_Clear_Filter_History_Removes_Entries;

   procedure Test_Phase135_Filter_Remembered_Per_Buffer_And_Restored
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Apply_Filter (O, "clear");
      Remember_Filter_For_Buffer (O, 7);
      Clear_Filter (O);

      Assert (Restore_Filter_For_Buffer (O, 7),
              "phase 135 remembered filter restores for matching live buffer identity");
      Set_Rows_From_Outline (O, P);
      Assert (Filter_Text (O) = "clear",
              "phase 135 restored filter text is preserved per buffer");
      Assert (not Filter_Input_Is_Active (O),
              "phase 135 restored filter does not automatically activate input focus");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "phase 135 restored filter rebuilds projection from accepted rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "phase 135 restored filter projection is reconciled");
   end Test_Phase135_Filter_Remembered_Per_Buffer_And_Restored;

   procedure Test_Phase135_Filter_Not_Restored_For_Closed_Or_Reused_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items_A : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("main.adb"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
      Items_B : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("main.adb"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 8,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items_A);
      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Forget_Filter_For_Buffer (O, 7);
      Assert (Remembered_Filter_Count (O) = 0,
              "phase 135 closing a buffer forgets its remembered filter");
      Assert (not Restore_Filter_For_Buffer (O, 7),
              "phase 135 closed buffer filter cannot be restored");

      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Replace_Items (O, Items_B);
      Clear_Filter (O);
      Assert (not Restore_Filter_For_Buffer (O, 8),
              "phase 135 same display label with different buffer identity does not inherit stale filter");
      Assert (Filter_Text (O) = "",
              "phase 135 label-only reuse leaves filter text empty");
   end Test_Phase135_Filter_Not_Restored_For_Closed_Or_Reused_Label;

   procedure Test_Phase135_Filter_Reset_Clears_Transient_Cursor_And_Project_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "phase 135 setup selects a history cursor entry");
      Reset_Filter_State_For_Lifecycle (O);
      Assert (Filter_Text (O) = "",
              "phase 135 lifecycle reset clears filter text");
      Assert (not Filter_Input_Is_Active (O),
              "phase 135 lifecycle reset deactivates filter input");
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "phase 135 lifecycle reset clears history cursor without deleting history");

      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Reset_For_Project_Close (O);
      Assert (Filter_History_Count (O) = 0,
              "phase 135 project close clears session-local filter history");
      Assert (Remembered_Filter_Count (O) = 0,
              "phase 135 project close clears remembered per-buffer filters");
   end Test_Phase135_Filter_Reset_Clears_Transient_Cursor_And_Project_State;


   procedure Test_Phase136_Buffer_Close_Clears_Buffer_Owned_Outline_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 3,
            Column       => 1));
      Snapshot : constant Outline_Snapshot_Identity :=
        (Active_Buffer_Token  => 7,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Text_Length          => 12,
         Request_Token        => 44);
   begin
      Replace_Items (O, Items);
      Select_Item (O, 1);
      Set_Current_Symbol_Index (O, 1);
      Apply_Filter (O, "run");
      Remember_Filter_For_Buffer (O, 7);
      Begin_Extraction (O, Snapshot);

      Reset_Outline_For_Buffer_Close (O, 7);

      Assert (Item_Count (O) = 0,
              "phase 136 buffer close clears visible rows owned by the closed buffer");
      Assert (Selected_Index (O) = 0,
              "phase 136 buffer close clears selected target for the closed buffer");
      Assert (not Has_Current_Symbol (O),
              "phase 136 buffer close clears current symbol for the closed buffer");
      Assert (Remembered_Filter_Count (O) = 0,
              "phase 136 buffer close removes remembered filter for the closed identity");
      Assert (not Snapshot_Is_Current (O, Snapshot),
              "phase 136 buffer close invalidates pending extraction token for the closed buffer");
      Assert (Invariant_Holds (O),
              "phase 136 buffer close leaves outline state consistent");
   end Test_Phase136_Buffer_Close_Clears_Buffer_Owned_Outline_State;

   procedure Test_Phase136_Project_And_Workspace_Close_Clear_Session_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Compute"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 8,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "compute");
      Commit_Filter_To_History (O);
      Remember_Filter_For_Buffer (O, 7);
      Activate_Filter_Input (O);

      Reset_Outline_For_Project_Close (O);
      Assert (Item_Count (O) = 0,
              "phase 136 project close clears outline rows");
      Assert (Filter_History_Count (O) = 0,
              "phase 136 project close clears session-local filter history");
      Assert (Remembered_Filter_Count (O) = 0,
              "phase 136 project close clears remembered filters");
      Assert (not Filter_Input_Is_Active (O),
              "phase 136 project close deactivates filter input");
      Assert (Invariant_Holds (O),
              "phase 136 project close leaves outline state consistent");

      Replace_Items (O, Items);
      Apply_Filter (O, "compute");
      Commit_Filter_To_History (O);
      Remember_Filter_For_Buffer (O, 7);
      Reset_Outline_For_Workspace_Close (O);
      Assert (Item_Count (O) = 0 and then Filter_History_Count (O) = 0,
              "phase 136 workspace close clears all outline feature session state");
      Assert (Remembered_Filter_Count (O) = 0,
              "phase 136 workspace close clears remembered per-buffer filters");
   end Test_Phase136_Project_And_Workspace_Close_Clear_Session_State;

   procedure Test_Phase136_Unsupported_And_Failure_Clear_Interaction_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 2,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Select_Item (O, 1);
      Set_Current_Symbol_Index (O, 1);
      Apply_Filter (O, "run");
      Reset_Outline_For_Unsupported_Content (O);
      Assert (Item_Count (O) = 0,
              "phase 136 unsupported content clears stale rows");
      Assert (Selected_Index (O) = 0 and then not Has_Current_Symbol (O),
              "phase 136 unsupported content clears selection and current symbol");
      Assert (Filtered_Row_Count (O) = 0,
              "phase 136 unsupported content clears filtered projection count");

      Replace_Items (O, Items);
      Select_Item (O, 1);
      Set_Current_Symbol_Index (O, 1);
      Reset_Outline_For_Extraction_Failure (O, "failed");
      Assert (Item_Count (O) = 0,
              "phase 136 extraction failure clears stale rows");
      Assert (Current_Symbol_Label (O) = "",
              "phase 136 extraction failure clears current-symbol label");
      Assert (Invariant_Holds (O),
              "phase 136 failure leaves outline state consistent");
   end Test_Phase136_Unsupported_And_Failure_Clear_Interaction_State;

   procedure Test_Phase136_Projection_Generation_Changes_On_Filter_And_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Rows_Before   : Natural;
      Filter_Before : Natural;
      Proj_Before   : Natural;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 2,
            Column       => 1));
   begin
      Rows_Before := Rows_Generation (O);
      Proj_Before := Projection_Generation (O);
      Replace_Items (O, Items);
      Assert (Rows_Generation (O) /= Rows_Before,
              "phase 136 accepted refresh changes row generation");
      Assert (Projection_Generation (O) /= Proj_Before,
              "phase 136 accepted refresh invalidates projection generation");

      Filter_Before := Filter_Generation (O);
      Proj_Before := Projection_Generation (O);
      Apply_Filter (O, "run");
      Assert (Filter_Generation (O) /= Filter_Before,
              "phase 136 filter edit changes filter generation");
      Assert (Projection_Generation (O) /= Proj_Before,
              "phase 136 filter edit invalidates projection generation");
   end Test_Phase136_Projection_Generation_Changes_On_Filter_And_Rows;

   procedure Test_Phase136_Mouse_And_Reveal_Reject_Old_Panel_Generation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Old_Gen : Natural;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 1),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Set_Rows_From_Outline (O, P);
      Old_Gen := Editor.Feature_Panel.Projection_Generation (P);
      Apply_Filter (O, "clear");
      Set_Rows_From_Outline (O, P);

      Assert (Map_Panel_Row_To_Outline_Row (O, P, 1, Old_Gen) = 0,
              "phase 136 stale mouse mapping generation is rejected");
      Assert (not Validate_Outline_Row_For_Selection (O, P, 1, Old_Gen),
              "phase 136 stale selection generation is rejected");
      Assert (not Validate_Outline_Row_For_Activation (O, P, 1, 7, Old_Gen),
              "phase 136 stale reveal/activation generation is rejected");
      Assert (Validate_Outline_Row_For_Activation
                (O, P, 1, 7, Editor.Feature_Panel.Projection_Generation (P)),
              "phase 136 current projection generation remains activatable");
   end Test_Phase136_Mouse_And_Reveal_Reject_Old_Panel_Generation;


   procedure Test_Phase137_Repeated_Filter_Clear_Restores_Stable_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Base_Fingerprint : Natural := 0;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 1),
         3 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Base_Fingerprint := Fingerprint (O);

      for I in 1 .. 20 loop
         Apply_Filter (O, (if I mod 2 = 0 then "refresh" else "clear"));
         Set_Rows_From_Outline (O, P);
         Assert (Editor.Feature_Panel.Row_Count (P) = 1,
                 "phase 137 repeated filter edit keeps projection bounded");
         Assert (Projection_Invariant_Holds (O, P),
                 "phase 137 filtered projection invariant holds during repetition");

         Clear_Filter (O);
         Set_Rows_From_Outline (O, P);
         Assert (Editor.Feature_Panel.Row_Count (P) = 3,
                 "phase 137 repeated clear-filter restores every row");
         Assert (Fingerprint (O) = Base_Fingerprint,
                 "phase 137 filter-only operations do not mutate accepted rows");
      end loop;
   end Test_Phase137_Repeated_Filter_Clear_Restores_Stable_Rows;

   procedure Test_Phase137_Filtered_Mouse_Activation_Uses_Current_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline procedure Refresh" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Clear" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 137 refresh setup executes");

      Apply_Filter (S.Outline, "clear");
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "phase 137 fixture has one filtered visible row");
      Assert (Map_Panel_Row_To_Outline_Row (S.Outline, S.Feature_Panel, 1) = 2,
              "phase 137 filtered visible row maps to second outline row");

      Result := Editor.Executor.Execute_Outline_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 137 mouse activation uses visible row through shared open handler");
      Assert (Selected_Index (S.Outline) = 2,
              "phase 137 mouse activation stores the mapped outline row as selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "phase 137 mouse activation keeps the visible panel row selected");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "phase 137 activation navigates to the filtered symbol target");
   end Test_Phase137_Filtered_Mouse_Activation_Uses_Current_Projection;

   procedure Test_Phase137_Repeated_Stale_Results_Do_Not_Change_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Outline_Snapshot_Identity :=
        (Active_Buffer_Token  => 7,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Text_Length          => 42,
         Request_Token        => 1);
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 2,
            Column       => 1));
      Baseline : Natural := 0;
   begin
      Replace_Items (O, Items);
      Select_Item (O, 1);
      Set_Current_Symbol_Index (O, 1);
      Begin_Extraction (O, Snapshot);
      Baseline := Fingerprint (O);

      for I in 1 .. 8 loop
         Mark_Stale_Result (O, Message_Outline_Stale_Result_Discarded);
         Assert (Fingerprint (O) = Baseline,
                 "phase 137 stale result must not replace accepted rows");
         Assert (Selected_Index (O) = 1 and then Current_Symbol_Index (O) = 1,
                 "phase 137 stale result preserves accepted navigation state");
         Assert (Invariant_Holds (O),
                 "phase 137 stale result leaves outline state consistent");
      end loop;
   end Test_Phase137_Repeated_Stale_Results_Do_Not_Change_State;

   procedure Test_Phase137_Command_Registry_Has_No_Duplicate_Outline_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Id_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Outline_Commands : constant Command_Id_Array :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Focus_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         Editor.Commands.Command_Select_Next_Outline_Item,
         Editor.Commands.Command_Select_Previous_Outline_Item,
         Editor.Commands.Command_Focus_Outline_Filter,
         Editor.Commands.Command_Filter_Outline,
         Editor.Commands.Command_Clear_Outline_Filter,
         Editor.Commands.Command_Toggle_Outline_Filter,
         Editor.Commands.Command_Outline_Filter_History_Previous,
         Editor.Commands.Command_Outline_Filter_History_Next,
         Editor.Commands.Command_Clear_Outline_Filter_History);
      Found : Boolean := False;
      Round_Trip : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      for I in Outline_Commands'Range loop
         Assert (Editor.Commands.Has_Descriptor (Outline_Commands (I)),
                 "phase 137 outline command has descriptor metadata");
         Assert (Editor.Commands.Has_Stable_Name (Outline_Commands (I)),
                 "phase 137 outline command has stable persisted name");
         Round_Trip := Editor.Commands.Command_Id_From_Stable_Name
           (Editor.Commands.Stable_Command_Name (Outline_Commands (I)), Found);
         Assert (Found and then Round_Trip = Outline_Commands (I),
                 "phase 137 outline command stable name round-trips");

         for J in I + 1 .. Outline_Commands'Last loop
            Assert (Editor.Commands.Stable_Command_Name (Outline_Commands (I)) /=
                    Editor.Commands.Stable_Command_Name (Outline_Commands (J)),
                    "phase 137 outline command stable names are unique");
         end loop;
      end loop;
   end Test_Phase137_Command_Registry_Has_No_Duplicate_Outline_Commands;

   procedure Test_Phase137_Projection_Invariant_Rejects_Stale_Panel
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 3,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Set_Rows_From_Outline (O, P);
      Assert (Projection_Invariant_Holds (O, P),
              "phase 137 fresh projection satisfies invariant");

      Apply_Filter (O, "clear");
      Assert (not Projection_Invariant_Holds (O, P),
              "phase 137 stale projection is rejected after filter generation change");
      Set_Rows_From_Outline (O, P);
      Assert (Projection_Invariant_Holds (O, P),
              "phase 137 rebuilt projection satisfies invariant again");
   end Test_Phase137_Projection_Invariant_Rejects_Stale_Panel;


   procedure Test_Phase138_Outline_Projection_Generation_Unchanged_After_Helper_Move
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 2,
            Column       => 1),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Compute"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 4,
            Column       => 1));
      Captured_Generation : Natural := 0;
   begin
      Replace_Items (O, Items);
      Set_Rows_From_Outline (O, P);
      Captured_Generation := Editor.Feature_Panel.Projection_Generation (P);

      Assert
        (Map_Panel_Row_To_Outline_Row (O, P, 2, Captured_Generation) = 2,
         "phase 138 moved feature-panel generation guard preserves row mapping");
      Assert
        (Validate_Outline_Row_For_Activation
           (O, P, 2, 7, Captured_Generation),
         "phase 138 moved feature-panel generation guard preserves activation validation");

      Editor.Feature_Panel.Append_Row
        (P, Editor.Feature_Panel.Feature_Row_Item, "Stale UI Row");
      Assert
        (Map_Panel_Row_To_Outline_Row (O, P, 2, Captured_Generation) = 0,
         "phase 138 stale captured panel generation is rejected after helper move");
      Assert
        (not Validate_Outline_Row_For_Activation
           (O, P, 2, 7, Captured_Generation),
         "phase 138 stale activation path is rejected after helper move");
      Assert (Invariant_Holds (O),
              "phase 138 helper movement leaves outline state invariant intact");
   end Test_Phase138_Outline_Projection_Generation_Unchanged_After_Helper_Move;

   procedure Test_Phase138_Outline_Command_Registration_Is_Idempotent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Id_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Outline_Commands : constant Command_Id_Array :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Focus_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         Editor.Commands.Command_Select_Next_Outline_Item,
         Editor.Commands.Command_Select_Previous_Outline_Item,
         Editor.Commands.Command_Focus_Outline_Filter,
         Editor.Commands.Command_Filter_Outline,
         Editor.Commands.Command_Clear_Outline_Filter,
         Editor.Commands.Command_Toggle_Outline_Filter,
         Editor.Commands.Command_Outline_Filter_History_Previous,
         Editor.Commands.Command_Outline_Filter_History_Next,
         Editor.Commands.Command_Clear_Outline_Filter_History);
   begin
      for I in Outline_Commands'Range loop
         Assert (Editor.Commands.Has_Descriptor (Outline_Commands (I)),
                 "phase 138 outline command has a descriptor");
         Assert (Editor.Commands.Is_Bindable_Command (Outline_Commands (I)),
                 "phase 138 public outline command remains bindable");
         for J in I + 1 .. Outline_Commands'Last loop
            Assert
              (Editor.Commands.Stable_Command_Name (Outline_Commands (I)) /=
               Editor.Commands.Stable_Command_Name (Outline_Commands (J)),
               "phase 138 duplicate outline command id/stable name rejected by audit");
            Assert
              (Editor.Commands.Label (Outline_Commands (I)) /=
               Editor.Commands.Label (Outline_Commands (J)),
               "phase 138 duplicate outline command-palette label rejected by audit");
         end loop;
      end loop;
   end Test_Phase138_Outline_Command_Registration_Is_Idempotent;

   procedure Test_Phase138_Outline_Keybinding_Registration_Is_Idempotent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      First  : Editor.Keybindings.Default_Keybinding_Registration_Result;
      Second : Editor.Keybindings.Default_Keybinding_Registration_Result;
      Validation : Editor.Keybindings.Keybinding_Validation_Result;
   begin
      Editor.Keybindings.Clear;
      First := Editor.Keybindings.Register_Outline_Keybindings;
      Second := Editor.Keybindings.Register_Outline_Keybindings;
      Validation := Editor.Keybindings.Validate;

      Assert (First.Requested_Count = 6 and then First.Registered_Count = 6,
              "phase 138 first outline keybinding registration installs defaults");
      Assert (Second.Requested_Count = 6
              and then Second.Registered_Count = 0
              and then Second.Conflict_Count = 6,
              "phase 138 second outline keybinding registration is deterministic and non-duplicating");
      Assert
        (Editor.Keybindings.Status (Validation) = Editor.Keybindings.Valid_Keybindings,
         "phase 138 repeated outline keybinding registration leaves keybindings valid");
   end Test_Phase138_Outline_Keybinding_Registration_Is_Idempotent;

   procedure Test_Phase138_All_Outline_Commands_Are_Safe_Without_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Id_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Outline_Commands : constant Command_Id_Array :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Select_Next_Outline_Item,
         Editor.Commands.Command_Select_Previous_Outline_Item,
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         Editor.Commands.Command_Focus_Outline_Filter,
         Editor.Commands.Command_Filter_Outline,
         Editor.Commands.Command_Clear_Outline_Filter,
         Editor.Commands.Command_Outline_Filter_History_Previous,
         Editor.Commands.Command_Outline_Filter_History_Next,
         Editor.Commands.Command_Clear_Outline_Filter_History);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);

      for Id of Outline_Commands loop
         Result := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert
           (Result.Status /= Editor.Executor.Command_Failed,
            "phase 138 outline command must not fail without active buffer: " &
            Editor.Commands.Stable_Command_Name (Id));
         Assert (Invariant_Holds (S.Outline),
                 "phase 138 no-active-buffer command keeps outline state consistent");
         Assert (Item_Count (S.Outline) = 0,
                 "phase 138 no-active-buffer command must not create stale outline rows");
         Assert (not Filter_Input_Is_Active (S.Outline),
                 "phase 138 no-active-buffer command must not leave filter input active");
      end loop;
   end Test_Phase138_All_Outline_Commands_Are_Safe_Without_Active_Buffer;

   procedure Test_Phase138_Closed_Project_Outline_Command_Sweep
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Id_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Outline_Commands : constant Command_Id_Array :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Select_Next_Outline_Item,
         Editor.Commands.Command_Select_Previous_Outline_Item,
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         Editor.Commands.Command_Focus_Outline_Filter,
         Editor.Commands.Command_Filter_Outline,
         Editor.Commands.Command_Clear_Outline_Filter,
         Editor.Commands.Command_Outline_Filter_History_Previous,
         Editor.Commands.Command_Outline_Filter_History_Next,
         Editor.Commands.Command_Clear_Outline_Filter_History);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      for Id of Outline_Commands loop
         Editor.State.Init (S);
         Editor.State.Load_Text
           (S, "@outline package Demo" & ASCII.LF &
               "@outline procedure Run" & ASCII.LF &
               "end Demo;");
         Result := Editor.Executor.Execute_Command_With_Result
           (S, Editor.Commands.Command_Refresh_Outline);
         Assert (Result.Status = Editor.Executor.Command_Executed,
                 "phase 138 setup refresh produces extracted rows");
         Apply_Filter (S.Outline, "run");
         Commit_Filter_To_History (S.Outline);
         Activate_Filter_Input (S.Outline);

         Editor.State.Reset_Project_Scoped_State (S);
         Assert (Item_Count (S.Outline) = 0,
                 "phase 138 project close clears accepted outline rows before sweep");
         Assert (Filter_History_Count (S.Outline) = 0,
                 "phase 138 project close clears session-local filter history before sweep");
         Assert (not Filter_Input_Is_Active (S.Outline),
                 "phase 138 project close deactivates filter input before sweep");

         Result := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert
           (Result.Status /= Editor.Executor.Command_Failed,
            "phase 138 closed-project outline command must not fail: " &
            Editor.Commands.Stable_Command_Name (Id));
         Assert (Invariant_Holds (S.Outline),
                 "phase 138 closed-project command keeps outline state consistent");
         Assert (Filter_History_Count (S.Outline) = 0,
                 "phase 138 closed-project command must not resurrect filter history");
         if Id /= Editor.Commands.Command_Refresh_Outline then
            Assert (Item_Count (S.Outline) = 0,
                    "phase 138 closed-project non-refresh command must not resurrect stale outline rows");
            Assert (not Filter_Input_Is_Active (S.Outline),
                    "phase 138 closed-project non-refresh command must not activate stale filter input");
         end if;
      end loop;
   end Test_Phase138_Closed_Project_Outline_Command_Sweep;


   procedure Test_Phase549_Ada_Outline_Extracts_Renames_And_Expression_Functions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo renames Root.Demo;" & ASCII.LF &
           "procedure Run renames Other_Run;" & ASCII.LF &
           "function Compute return Integer renames Other_Compute;" & ASCII.LF &
           "function Ready return Boolean is (True);",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 extracts package, procedure, function renames and expression functions");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo renames",
              "package rename label is explicit");
      Assert (Item_Label (O, 2) = "procedure Run renames",
              "procedure rename label is explicit");
      Assert (Item_Label (O, 3) = "function Compute renames",
              "function rename label is explicit");
      Assert (Item_Label (O, 4) = "expression function Ready",
              "expression function label is explicit when the pattern is clear");
      Assert (Item_Line (O, 3) = 3 and then Item_Column (O, 3) = 1,
              "rename target stays on the renaming declaration line");
   end Test_Phase549_Ada_Outline_Extracts_Renames_And_Expression_Functions;


   procedure Test_Phase549_Ada_Outline_Extracts_Type_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type State is private;" & ASCII.LF &
           "   type Cursor is limited private;" & ASCII.LF &
           "   type Node is record" & ASCII.LF &
           "      Value : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   type Mode is (Insert, Normal);" & ASCII.LF &
           "   subtype Index is Natural range 1 .. 10;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 9,
              "phase 549 extracts common type and subtype forms with parser-owned child rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type State",
              "private type label is kind-aware");
      Assert (Item_Label (O, 3) = "private type Cursor",
              "limited private type remains compact");
      Assert (Item_Label (O, 4) = "record type Node",
              "record type label is kind-aware");
      Assert (Item_Label (O, 6) = "enum type Mode",
              "enumeration type label is kind-aware");
      Assert (Item_Label (O, 9) = "subtype Index",
              "subtype label includes subtype name");
      Assert (Item_Depth (O, 6) = 1,
              "record type scanning does not corrupt following package-member depth");
   end Test_Phase549_Ada_Outline_Extracts_Type_Forms;


   procedure Test_Phase549_Ada_Outline_Extracts_Task_And_Protected_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   task type Job is" & ASCII.LF &
           "   end Job;" & ASCII.LF &
           "   task body Worker is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "   protected Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "   protected type Gate is" & ASCII.LF &
           "   end Gate;" & ASCII.LF &
           "   protected body Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "phase 549 extracts task/protected declarations, types, and bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "task Worker",
              "task declaration label is stable");
      Assert (Item_Label (O, 3) = "task type Job",
              "task type label is stable");
      Assert (Item_Label (O, 4) = "task body Worker",
              "task body label is stable");
      Assert (Item_Label (O, 5) = "protected Lock",
              "protected declaration label is stable");
      Assert (Item_Label (O, 6) = "protected type Gate",
              "protected type label is stable");
      Assert (Item_Label (O, 7) = "protected body Lock",
              "protected body label is stable");
      Assert (Item_Kind (O, 7) = Outline_Protected,
              "protected body uses protected outline kind without enum churn");
   end Test_Phase549_Ada_Outline_Extracts_Task_And_Protected_Forms;


   procedure Test_Phase549_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "   with procedure Visit (Value : Element);" & ASCII.LF &
           "package Containers is" & ASCII.LF &
           "   procedure Plain;" & ASCII.LF &
           "end Containers;" & ASCII.LF &
           "procedure Later;",
           "containers.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 549 keeps generic formals and the marker for the unit");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "generic formal type is visible as parser-owned metadata");
      Assert (Item_Label (O, 2) = "formal procedure Visit",
              "generic formal procedure is visible as parser-owned metadata");
      Assert (Item_Label (O, 3) = "generic package Containers",
              "generic marker applies to the following package declaration");
      Assert (Item_Label (O, 4) = "procedure Plain",
              "generic marker does not leak into package members");
      Assert (Item_Label (O, 5) = "procedure Later",
              "generic marker does not leak beyond the generic unit");
   end Test_Phase549_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals;


   procedure Test_Phase549_Ada_Outline_Handles_Multiline_Renames_And_Operators
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     renames Other_Run;" & ASCII.LF &
           "   function Compute return Integer" & ASCII.LF &
           "     renames Other_Compute;" & ASCII.LF &
           "   function ""+"" (Left, Right : Integer) return Integer;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 extracts package, multi-line renames, and operator functions");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Run renames",
              "multi-line procedure rename upgrades the original declaration row");
      Assert (Item_Label (O, 3) = "function Compute renames",
              "multi-line function rename upgrades the original declaration row");
      Assert (Item_Label (O, 4) = "function ""+""",
              "operator-symbol function name is preserved compactly");
      Assert (Item_Line (O, 2) = 2 and then Item_Column (O, 2) = 4,
              "multi-line rename target remains the first declaration line");
   end Test_Phase549_Ada_Outline_Handles_Multiline_Renames_And_Operators;


   procedure Test_Phase549_Ada_Outline_Coverage_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type State is record" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Value : Index);" & ASCII.LF &
           "   function Ready return Boolean is (True);" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   protected Lock is" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 7,
              "phase 549 coherent coverage extracts common Ada outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "generic package Demo",
              "coherent coverage keeps generic package label");
      Assert_Has_Label (O, "record type State",
              "coherent coverage includes record type label");
      Assert_Has_Label (O, "subtype Index",
              "coherent coverage includes subtype label");
      Assert_Has_Label (O, "procedure Run",
              "coherent coverage keeps multi-line procedure label compact");
      Assert_Has_Label (O, "expression function Ready",
              "coherent coverage includes clear expression function label");
      Assert (Item_Kind (O, First_Label_Index (O, "task Worker")) = Outline_Task,
              "coherent coverage includes task kind");
      Assert (Item_Kind (O, First_Label_Index (O, "protected Lock")) = Outline_Protected,
              "coherent coverage includes protected kind");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 7,
              "coherent coverage preserves first-line target for multi-line procedure");
   end Test_Phase549_Ada_Outline_Coverage_Coherent;



   procedure Test_Phase549_Completeness_Multiline_Type_And_Expression_Functions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type State is" & ASCII.LF &
           "      record" & ASCII.LF &
           "         Value : Integer;" & ASCII.LF &
           "      end record;" & ASCII.LF &
           "   subtype After_Record is Natural;" & ASCII.LF &
           "   function Ready return Boolean is" & ASCII.LF &
           "      (True);" & ASCII.LF &
           "   function Split return Boolean" & ASCII.LF &
           "      is" & ASCII.LF &
           "      (False);" & ASCII.LF &
           "   function Build return Integer" & ASCII.LF &
           "      is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return 1;" & ASCII.LF &
           "   end Build;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "phase 549 completeness extracts multiline record type, following subtype, and split function forms");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "record type State",
              "record type split across the is/record lines is still classified as a record type");
      Assert (Item_Line (O, 2) = 2 and then Item_Column (O, 2) = 4,
              "multiline record target remains on the type declaration start");
      Assert (Item_Label (O, 4) = "subtype After_Record",
              "split record pending state ends at end record and preserves following declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype remains at the package-member depth after split record completion");
      Assert (Item_Label (O, 5) = "expression function Ready",
              "expression function split after is is classified conservatively when the next line is the expression");
      Assert (Item_Label (O, 6) = "expression function Split",
              "expression function with is on a separate line remains classified as expression");
      Assert (Item_Label (O, 7) = "function body Build",
              "ordinary function body split after is is not mistaken for an expression function");
      Assert (Item_Line (O, 5) = 7
                and then Item_Line (O, 6) = 9
                and then Item_Line (O, 7) = 12,
              "multiline function targets remain on their first declaration lines");
   end Test_Phase549_Completeness_Multiline_Type_And_Expression_Functions;


   procedure Test_Phase549_Completeness_Split_Generic_Formals_Keep_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is" & ASCII.LF &
           "      private;" & ASCII.LF &
           "   type Cursor is" & ASCII.LF &
           "      range <>;" & ASCII.LF &
           "   with function ""<""" & ASCII.LF &
           "     (Left, Right : Element) return Boolean is <>;" & ASCII.LF &
           "package Ordered_Sets is" & ASCII.LF &
           "   function Empty return Boolean;" & ASCII.LF &
           "end Ordered_Sets;",
           "ordered_sets.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 549 completeness keeps generic marker through split formal declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "split generic formal type is visible without opening depth");
      Assert (Item_Label (O, 2) = "formal type Cursor",
              "second split generic formal type is visible without opening depth");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "split generic formal function is visible");
      Assert (Item_Label (O, 4) = "generic package Ordered_Sets",
              "split generic formal type declarations do not clear the generic marker");
      Assert (Item_Label (O, 5) = "function Empty",
              "generic marker still clears after the associated package declaration");
   end Test_Phase549_Completeness_Split_Generic_Formals_Keep_Marker;


   procedure Test_Phase549_Completeness_Split_Generic_Package_Formal_Keep_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with package Formal is" & ASCII.LF &
           "      new Ada.Containers.Vectors (Positive, Element);" & ASCII.LF &
           "   Default_Count : Natural :=" & ASCII.LF &
           "      0;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   procedure Use_Formal;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness keeps marker through split generic package and object formals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal package Formal",
              "split formal package is visible");
      Assert (Item_Label (O, 2) = "formal object Default_Count",
              "split formal object is visible without a duplicate object row");
      Assert (Item_Label (O, 3) = "generic package Demo",
              "split formal package continuation does not clear or consume the generic marker");
      Assert (Item_Line (O, 3) = 6,
              "generic package target remains on the real declaration, not the formal package");
      Assert (Item_Label (O, 4) = "procedure Use_Formal",
              "generic marker clears after the associated package declaration");
   end Test_Phase549_Completeness_Split_Generic_Package_Formal_Keep_Marker;


   procedure Test_Phase549_Completeness_Comments_Strings_And_Generic_Task_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   Text : constant String := ""procedure Fake; -- not a comment"";" & ASCII.LF &
           "   -- function Hidden return Boolean;" & ASCII.LF &
           "   procedure Visible; -- function Also_Hidden return Boolean;" & ASCII.LF &
           "   generic" & ASCII.LF &
           "      type Element is private;" & ASCII.LF &
           "   task Worker;" & ASCII.LF &
           "   function Later return Boolean;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "phase 549 completeness ignores obvious comments/strings and clears unsupported generic marker targets");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package still extracts near strings and comments");
      Assert (Item_Label (O, 3) = "procedure Visible",
              "inline comment content after a declaration does not fabricate a second row");
      Assert (Item_Label (O, 5) = "task Worker",
              "generic marker does not attach to unsupported task declarations");
      Assert (Item_Label (O, 6) = "function Later",
              "generic marker cleared before the following supported function");
   end Test_Phase549_Completeness_Comments_Strings_And_Generic_Task_Boundary;



   procedure Test_Phase549_Completeness_Split_Package_Forms_Do_Not_Open_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo" & ASCII.LF &
           "is" & ASCII.LF &
           "   package Int_Vectors is new Ada.Containers.Vectors" & ASCII.LF &
           "     (Positive, Integer);" & ASCII.LF &
           "   package Renamed" & ASCII.LF &
           "     renames Ada.Text_IO;" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness handles split package spec, instantiation, and rename forms");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "split package spec keeps compact package label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "spec") /= 0,
              "split package spec is not misclassified as a body");
      Assert (Item_Label (O, 2) = "package Int_Vectors",
              "split package instantiation keeps the instantiated package target row");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split package instantiation is classified without opening lexical depth");
      Assert (Item_Label (O, 3) = "package Renamed renames",
              "split package rename updates the original declaration row");
      Assert (Item_Label (O, 4) = "subtype After_Instantiation",
              "following declaration is not nested under a split instantiation");
      Assert (Item_Depth (O, 2) = 1 and then Item_Depth (O, 4) = 1,
              "split instantiation does not corrupt package-member depth");
      Assert (Item_Line (O, 2) = 3 and then Item_Line (O, 3) = 5,
              "split package forms keep targets on their first declaration lines");
   end Test_Phase549_Completeness_Split_Package_Forms_Do_Not_Open_Depth;


   procedure Test_Phase549_Completeness_Null_And_Separate_Subprogram_Bodies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Reset is null;" & ASCII.LF &
           "   procedure Deferred" & ASCII.LF &
           "      is separate;" & ASCII.LF &
           "   function External return Integer is separate;" & ASCII.LF &
           "   function Abstract_Value return Integer is abstract;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 549 completeness extracts null/separate subprogram bodies without opening depth");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure body Reset",
              "null procedure is classified as a body-like outline target");
      Assert (Item_Label (O, 3) = "procedure body Deferred",
              "split separate procedure is classified as a body-like outline target");
      Assert (Item_Label (O, 4) = "function body External",
              "separate function is classified as a body-like outline target");
      Assert (Item_Label (O, 5) = "function Abstract_Value",
              "abstract function remains a declaration, not a function body");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 3
                and then Item_Line (O, 4) = 5,
              "null/separate subprogram targets stay on their declaration starts");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "null/separate/abstract forms do not corrupt following package-member depth");
   end Test_Phase549_Completeness_Null_And_Separate_Subprogram_Bodies;


   procedure Test_Phase549_Completeness_Record_Named_Types_Are_Not_Records
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type Record_Node is private;" & ASCII.LF &
           "   type Node_Access is access Record_Node;" & ASCII.LF &
           "   type Split_Access is" & ASCII.LF &
           "      access Record_Node;" & ASCII.LF &
           "   type Record_Table is array" & ASCII.LF &
           "      (Positive range <>) of Record_Node;" & ASCII.LF &
           "   subtype After_Types is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "phase 549 completeness keeps record-named access/array types as plain types");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type Record_Node",
              "actual private type remains private even when its name contains Record");
      Assert (Item_Label (O, 3) = "access type Node_Access",
              "access type to Record_Node is not mislabeled as a record type");
      Assert (Item_Label (O, 4) = "type Split_Access",
              "split access type to Record_Node does not wait for end record");
      Assert (Item_Label (O, 5) = "array type Record_Table",
              "array type mentioning Record_Node is not mislabeled as a record type");
      Assert (Item_Label (O, 6) = "subtype After_Types",
              "following subtype is still extracted after split record-named types");
      Assert (Item_Line (O, 4) = 4 and then Item_Line (O, 5) = 6,
              "split access/array targets stay on their first declaration lines");
      Assert (Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1
                and then Item_Depth (O, 6) = 1,
              "record-named type references do not corrupt package-member depth");
   end Test_Phase549_Completeness_Record_Named_Types_Are_Not_Records;


   procedure Test_Phase549_Completeness_Private_Named_Types_Are_Not_Private
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   type Private_Data is private;" & ASCII.LF &
           "   type Data_Access is access Private_Data;" & ASCII.LF &
           "   type Split_Access is" & ASCII.LF &
           "      access Private_Data;" & ASCII.LF &
           "   type Data_Table is array" & ASCII.LF &
           "      (Positive range <>) of Private_Data;" & ASCII.LF &
           "   package Data_Maps is new Ada.Containers.Vectors" & ASCII.LF &
           "      (Positive, Private_Data);" & ASCII.LF &
           "   subtype After_Types is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "phase 549 completeness keeps private-named access/array/instantiation forms precise");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "private type Private_Data",
              "actual private type remains classified as private");
      Assert (Item_Label (O, 3) = "access type Data_Access",
              "access type to Private_Data is not mislabeled as a private type");
      Assert (Item_Label (O, 4) = "type Split_Access",
              "split access type to Private_Data remains a plain type");
      Assert (Item_Label (O, 5) = "array type Data_Table",
              "array type mentioning Private_Data remains a plain type");
      Assert (Item_Label (O, 6) = "package Data_Maps",
              "split package instantiation remains a package row");
      Assert (Item_Label (O, 7) = "subtype After_Types",
              "following subtype is still extracted after private-named forms");
      Assert (Item_Line (O, 4) = 4
                and then Item_Line (O, 5) = 6
                and then Item_Line (O, 6) = 8,
              "split private-named forms keep first-line source targets");
      Assert (Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1
                and then Item_Depth (O, 6) = 1
                and then Item_Depth (O, 7) = 1,
              "private-named references do not corrupt package-member depth");
   end Test_Phase549_Completeness_Private_Named_Types_Are_Not_Private;


   procedure Test_Phase549_Completeness_Is_Followed_By_Uses_Code_Tokens
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo with Annotation => ""is new"" is" & ASCII.LF &
           "   procedure Logged with Note => ""is null"";" & ASCII.LF &
           "   function Remote return Boolean with Note => ""is separate"";" & ASCII.LF &
           "   procedure Actual_Null is null;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness keeps is-followed-by tests outside string literals");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package aspect string containing is new is not treated as an instantiation");
      Assert (Item_Label (O, 2) = "procedure Logged",
              "procedure aspect string containing is null is not treated as a null body");
      Assert (Item_Label (O, 3) = "function Remote",
              "function aspect string containing is separate is not treated as a separate body");
      Assert (Item_Label (O, 4) = "procedure body Actual_Null",
              "real null procedure body remains body-classified");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "string-literal token suppression does not corrupt package-member depth");
   end Test_Phase549_Completeness_Is_Followed_By_Uses_Code_Tokens;


   procedure Test_Phase549_Completeness_Code_Tokens_Ignore_Strings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure Quoted_Rename with Note => ""renames"";" & ASCII.LF &
           "   function Quoted_Is return Boolean with Note => ""is"";" & ASCII.LF &
           "   type Access_Record_Name is access String with Note => ""record"";" & ASCII.LF &
           "   type Access_Private_Name is access String with Note => ""private"";" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 549 completeness ignores declaration keywords inside strings");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package remains a package spec");
      Assert (Item_Label (O, 2) = "procedure Quoted_Rename",
              "renames inside string literal does not change procedure label");
      Assert (Item_Label (O, 3) = "function Quoted_Is",
              "is inside string literal does not make function a body");
      Assert (Item_Label (O, 4) = "access type Access_Record_Name",
              "record inside string literal does not make access type a record type");
      Assert (Item_Label (O, 5) = "access type Access_Private_Name",
              "private inside string literal does not make access type a private type");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "string keyword suppression preserves package-member depth");
   end Test_Phase549_Completeness_Code_Tokens_Ignore_Strings;


   procedure Test_Phase549_Completeness_Expression_Function_Is_Open_Paren
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   function Compact return Boolean is(True);" & ASCII.LF &
           "   function Spaced return Boolean is (True);" & ASCII.LF &
           "   function Quoted return Boolean with Note => ""is("";" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness handles expression functions without requiring space before open paren");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item");
      Assert (Item_Label (O, 2) = "expression function Compact",
              "is immediately followed by open paren is classified as expression function");
      Assert (Item_Label (O, 3) = "expression function Spaced",
              "spaced expression function remains classified as expression function");
      Assert (Item_Label (O, 4) = "function Quoted",
              "quoted is-open-paren text does not classify declaration as expression function");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "expression-function punctuation handling preserves package-member depth");
   end Test_Phase549_Completeness_Expression_Function_Is_Open_Paren;


   procedure Test_Phase549_Completeness_Overriding_Subprograms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   overriding procedure Adjust (Object : in out Controlled);" & ASCII.LF &
           "   not overriding function Create" & ASCII.LF &
           "      return Controlled" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return Result : Controlled;" & ASCII.LF &
           "   end Create;" & ASCII.LF &
           "   overriding function Ready return Boolean is (True);" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts overriding/not overriding subprogram declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body still extracts before overriding subprograms");
      Assert (Item_Label (O, 2) = "procedure Adjust",
              "overriding procedure keeps compact procedure label");
      Assert (Item_Label (O, 3) = "function body Create",
              "not overriding multi-line function body is classified after prefix stripping");
      Assert (Item_Label (O, 4) = "expression function Ready",
              "overriding expression function remains expression-classified");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 3
                and then Item_Line (O, 4) = 9,
              "overriding subprogram targets stay on the prefixed declaration line");
      Assert (Item_Column (O, 2) = 15
                and then Item_Column (O, 3) = 19
                and then Item_Column (O, 4) = 15,
              "overriding subprogram target columns point to declaration keywords");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "overriding prefix handling does not corrupt package-member depth");
   end Test_Phase549_Completeness_Overriding_Subprograms;


   procedure Test_Phase549_Completeness_Separate_Subunit_Bodies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("separate (Demo)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "separate (Demo) function Ready return Boolean is (True);" & ASCII.LF &
           "separate (Demo) overriding function Flag return Boolean is (True);" & ASCII.LF &
           "separate (Demo)" & ASCII.LF &
           "package body Child is" & ASCII.LF &
           "end Child;",
           "demo-worker.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts same-line and split separate subunit bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure body Worker",
              "split separate procedure subunit is classified as a procedure body");
      Assert (Item_Label (O, 2) = "expression function Ready",
              "same-line separate expression function keeps expression classification");
      Assert (Item_Label (O, 3) = "expression function Flag",
              "same-line separate overriding expression function strips both prefixes");
      Assert (Item_Label (O, 4) = "package body Child",
              "split separate package body is extracted after separate prefix line");
      Assert (Item_Line (O, 1) = 2
                and then Item_Line (O, 2) = 6
                and then Item_Line (O, 3) = 7
                and then Item_Line (O, 4) = 9,
              "separate subunit targets stay on the real declaration/body line");
      Assert (Item_Column (O, 2) = 17
                and then Item_Column (O, 3) = 28,
              "same-line separate subunit target columns point to function keywords");
      Assert (Item_Depth (O, 1) = 0
                and then Item_Depth (O, 2) = 0
                and then Item_Depth (O, 3) = 0
                and then Item_Depth (O, 4) = 0,
              "separate subunits do not inherit fabricated package nesting depth");
   end Test_Phase549_Completeness_Separate_Subunit_Bodies;


   procedure Test_Phase549_Completeness_End_Name_Keyword_Prefixes_Close_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Record_Type is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Record_Type;" & ASCII.LF &
           "   function If_State return Boolean is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return True;" & ASCII.LF &
           "   end If_State;" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts declarations around end-name keyword prefixes");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item");
      Assert (Item_Label (O, 2) = "procedure body Record_Type",
              "procedure whose name begins with record is classified as a body");
      Assert (Item_Label (O, 3) = "function body If_State",
              "function whose name begins with if is classified as a body");
      Assert (Item_Label (O, 4) = "subtype Index",
              "following subtype is still extracted");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "end name prefixes such as end Record_Type and end If_State close block depth");
   end Test_Phase549_Completeness_End_Name_Keyword_Prefixes_Close_Depth;


   procedure Test_Phase549_Completeness_Subprogram_Instantiations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is new Generic_Run;" & ASCII.LF &
           "   function Make is new Generic_Make" & ASCII.LF &
           "     (Integer);" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts subprogram instantiations without depth drift");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item before subprogram instantiations");
      Assert (Item_Label (O, 2) = "procedure Run",
              "procedure instantiation keeps compact procedure label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "same-line procedure instantiation is classified as an instantiation");
      Assert (Item_Label (O, 3) = "function Make",
              "split function instantiation keeps compact function label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "instantiation") /= 0,
              "split function instantiation waits for the terminating semicolon");
      Assert (Item_Label (O, 4) = "subtype After_Instantiation",
              "following subtype still extracts after subprogram instantiations");
      Assert (Item_Line (O, 2) = 2 and then Item_Line (O, 3) = 3,
              "subprogram instantiation targets stay on first declaration lines");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1,
              "subprogram instantiations do not open package-member depth");
   end Test_Phase549_Completeness_Subprogram_Instantiations;




   procedure Test_Phase549_Completeness_Split_Is_New_Instantiations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   package Int_Vectors is" & ASCII.LF &
           "      new Ada.Containers.Vectors" & ASCII.LF &
           "        (Positive, Integer);" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      new Generic_Run;" & ASCII.LF &
           "   function Make is" & ASCII.LF &
           "      new Generic_Make" & ASCII.LF &
           "        (Integer);" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 549 completeness extracts split is/new instantiations without extra rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo",
              "package body remains first item before split instantiations");
      Assert (Item_Label (O, 2) = "package Int_Vectors",
              "split package instantiation keeps compact package label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split package instantiation is classified as instantiation");
      Assert (Item_Label (O, 3) = "procedure Run",
              "split procedure instantiation removes provisional body label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "instantiation") /= 0,
              "split procedure instantiation is classified as instantiation");
      Assert (Item_Label (O, 4) = "function Make",
              "split function instantiation keeps compact function label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "instantiation") /= 0,
              "split function instantiation is classified as instantiation");
      Assert (Item_Label (O, 5) = "subtype After_Instantiation",
              "following subtype still extracts after split is/new instantiations");
      Assert (Item_Line (O, 2) = 2
                and then Item_Line (O, 3) = 5
                and then Item_Line (O, 4) = 7,
              "split is/new instantiation targets stay on first declaration lines");
      Assert (Item_Depth (O, 2) = 1
                and then Item_Depth (O, 3) = 1
                and then Item_Depth (O, 4) = 1
                and then Item_Depth (O, 5) = 1,
              "split is/new instantiations do not open package-member depth");
   end Test_Phase549_Completeness_Split_Is_New_Instantiations;

   procedure Test_Phase549_Completeness_Completed_Split_Instantiation_Clears_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   function Make is" & ASCII.LF &
           "      new Generic_Make;" & ASCII.LF &
           "   new Unexpected;" & ASCII.LF &
           "   subtype After_Instantiation is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 549 completeness ignores malformed new line after completed split instantiation");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "function Make",
              "split function instantiation keeps compact function label after completion");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "instantiation") /= 0,
              "split function instantiation finalizes through pending declaration state");
      Assert (Item_Label (O, 3) = "subtype After_Instantiation",
              "following subtype still extracts after malformed new continuation");
      Assert (Item_Depth (O, 2) = 1 and then Item_Depth (O, 3) = 1,
              "completed split instantiation clears candidate state before later new-prefixed text");
   end Test_Phase549_Completeness_Completed_Split_Instantiation_Clears_Candidate;


   procedure Test_Phase549_Completeness_Private_Child_Package_Specs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("private package Demo.Hidden is" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo.Hidden;" & ASCII.LF &
           "package body Demo.Hidden is" & ASCII.LF &
           "end Demo.Hidden;",
           "demo-hidden.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 549 completeness extracts private child package specs and bodies");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo.Hidden",
              "private child package spec uses compact package label");
      Assert (Item_Line (O, 1) = 1 and then Item_Column (O, 1) = 9,
              "private child package target points to package keyword, not private prefix");
      Assert (Item_Label (O, 2) = "subtype Index",
              "private child package contents still extract in source order");
      Assert (Item_Depth (O, 2) = 1,
              "private child package spec opens package-member depth");
      Assert (Item_Label (O, 3) = "package body Demo.Hidden",
              "ordinary package body after private spec remains recognized");
      Assert (Item_Depth (O, 3) = 0,
              "private child package close restores top-level depth before body");
   end Test_Phase549_Completeness_Private_Child_Package_Specs;


   procedure Test_Phase549_Completeness_Generic_Private_Child_Package_Specs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "private package Demo.Hidden is" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Demo.Hidden;" & ASCII.LF &
           "package body Demo.Hidden is" & ASCII.LF &
           "end Demo.Hidden;",
           "demo-hidden.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts generic private child package specs");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "generic private child package formal type is visible");
      Assert (Item_Label (O, 2) = "generic package Demo.Hidden",
              "generic marker applies to private child package spec, not to formal private type");
      Assert (Item_Line (O, 2) = 3 and then Item_Column (O, 2) = 9,
              "generic private child package target points to package keyword");
      Assert (Item_Label (O, 3) = "subtype Index",
              "generic private child package contents still extract");
      Assert (Item_Depth (O, 3) = 1,
              "generic private child package opens package-member depth");
      Assert (Item_Label (O, 4) = "package body Demo.Hidden",
              "following package body does not inherit the generic marker");
      Assert (Item_Depth (O, 4) = 0,
              "generic private child package close restores top-level depth");
   end Test_Phase549_Completeness_Generic_Private_Child_Package_Specs;


   procedure Test_Phase549_Completeness_Split_Is_Separate_Body_Stubs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo.Child is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "function Make return Integer is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "subtype After_Stub is Natural;",
           "demo-child.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness extracts split is/separate body stubs without stale depth");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Demo.Child",
              "split package body stub remains a package body row");
      Assert (Item_Depth (O, 1) = 0,
              "split package body stub stays at top-level depth");
      Assert (Item_Label (O, 2) = "procedure body Worker",
              "split procedure body stub remains a body row");
      Assert (Item_Depth (O, 2) = 0,
              "split procedure body stub does not keep depth open");
      Assert (Item_Label (O, 3) = "function body Make",
              "split function body stub remains a body row");
      Assert (Item_Depth (O, 3) = 0,
              "split function body stub does not keep depth open");
      Assert (Item_Label (O, 4) = "subtype After_Stub",
              "following subtype remains visible after split body stubs");
      Assert (Item_Depth (O, 4) = 0,
              "following subtype is not nested under a split body stub");
   end Test_Phase549_Completeness_Split_Is_Separate_Body_Stubs;


   procedure Test_Phase549_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure With_Aspect" & ASCII.LF &
           "     with Note => ""not; done""" & ASCII.LF &
           "     is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end With_Aspect;" & ASCII.LF &
           "   function Expr return Boolean" & ASCII.LF &
           "     with Note => ""not; an end""" & ASCII.LF &
           "     is" & ASCII.LF &
           "     (True);" & ASCII.LF &
           "   subtype After_String_Semicolon is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 549 completeness ignores semicolons inside strings while ending declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package row remains first with string-semicolon declarations");
      Assert (Item_Label (O, 2) = "procedure body With_Aspect",
              "string semicolon in aspect does not prematurely finalize procedure declaration");
      Assert (Item_Depth (O, 2) = 1,
              "procedure body remains a package member");
      Assert (Item_Label (O, 3) = "expression function Expr",
              "string semicolon in aspect does not hide split expression function classification");
      Assert (Item_Depth (O, 3) = 1,
              "expression function remains a package member");
      Assert (Item_Label (O, 4) = "subtype After_String_Semicolon",
              "following subtype remains visible after string semicolon declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype remains at package-member depth");
   end Test_Phase549_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations;




   procedure Test_Phase549_Completeness_Protected_Type_Label_Branch_Compiles
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   protected type Lock is" & ASCII.LF &
           "      procedure Enter;" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "   protected body Lock is" & ASCII.LF &
           "      procedure Enter is null;" & ASCII.LF &
           "   end Lock;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 4,
              "phase 549 completeness extracts protected type/body rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "package remains first around protected declarations");
      Assert (Item_Label (O, 2) = "protected type Lock",
              "protected type label branch is present and deterministic");
      Assert (Item_Label (O, 3) = "procedure Enter",
              "protected type operation remains nested under protected type");
      Assert (Item_Depth (O, 3) = 2,
              "protected type operation keeps deterministic lexical depth");
      Assert (Item_Label (O, 4) = "protected body Lock",
              "protected body label branch remains deterministic");
   end Test_Phase549_Completeness_Protected_Type_Label_Branch_Compiles;


   procedure Test_Phase549_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   procedure With_Aspect" & ASCII.LF &
           "     with Note => ';'" & ASCII.LF &
           "     is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end With_Aspect;" & ASCII.LF &
           "   function Ready return Boolean" & ASCII.LF &
           "     with Note => ';'" & ASCII.LF &
           "     is" & ASCII.LF &
           "     (True);" & ASCII.LF &
           "   subtype After_Character_Aspect is Natural;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) >= 4,
              "phase 549 completeness keeps declarations open across character-literal semicolons");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure body With_Aspect",
              "semicolon character literal does not finalize split procedure as declaration");
      Assert (Item_Label (O, 3) = "expression function Ready",
              "semicolon character literal does not hide split expression function");
      Assert (Item_Label (O, 4) = "subtype After_Character_Aspect",
              "following subtype remains visible after character-literal aspect declarations");
      Assert (Item_Depth (O, 4) = 1,
              "following subtype keeps package-member depth after character-literal aspects");
   end Test_Phase549_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations;




   procedure Test_Phase204_Outline_Contract_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Review : Editor.Outline_Audit.Outline_Contract_Review;
   begin
      Editor.State.Init (S);
      Review := Editor.Outline_Audit.Review_Outline_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review));
      Assert (Review.Active_Buffer_Only, "phase 204 outline remains active-buffer scoped");
      Assert (Review.Refresh_Command_Owned, "phase 204 outline refresh remains command-owned");
      Assert (Review.Projection_Side_Effect_Free, "phase 204 outline projection remains pure");
      Assert (Review.Feature_Panel_Intact, "phase 204 feature panel sentinel stays healthy");
      Assert (Review.Command_Surface_Intact, "phase 204 command surface sentinel stays healthy");
      Assert (Review.Public_Build_Guardrail_Intact,
              "phase 204 public-build manifest sentinel stays healthy");
      Assert (Review.Ada_Symbol_Navigation_Coherent,
              "phase 550 symbol navigation sentinel stays healthy");
   end Test_Phase204_Outline_Contract_Review_Default_Passes;

   procedure Test_Phase204_Outline_Contract_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_FP     : Natural;
      Before_Rows   : Natural;
      Before_Select : Natural;
      Before_Current : Natural;
      Before_Filter : Ada.Strings.Unbounded.Unbounded_String;
      Review        : Editor.Outline_Audit.Outline_Contract_Review;
   begin
      Editor.State.Init (S);
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Package,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 1,
             Column       => 1),
          2 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 2"),
             Depth       => 1,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 2,
             Column       => 4)));
      Select_Item (S.Outline, 2);
      Apply_Filter (S.Outline, "run");
      Update_Current_Symbol_For_Cursor (S.Outline, S.Registry_Token, 2, 4);

      Before_FP := Fingerprint (S.Outline);
      Before_Rows := Item_Count (S.Outline);
      Before_Select := Selected_Index (S.Outline);
      Before_Current := Current_Symbol_Index (S.Outline);
      Before_Filter := Ada.Strings.Unbounded.To_Unbounded_String (Filter_Text (S.Outline));

      Review := Editor.Outline_Audit.Review_Outline_Contract (S);
      Assert (Review.Review_Passed,
              Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review));
      Assert (Fingerprint (S.Outline) = Before_FP, "review does not mutate outline content");
      Assert (Item_Count (S.Outline) = Before_Rows, "review does not replace rows");
      Assert (Selected_Index (S.Outline) = Before_Select, "review does not change selection");
      Assert (Current_Symbol_Index (S.Outline) = Before_Current,
              "review does not change current symbol");
      Assert (Filter_Text (S.Outline) = Ada.Strings.Unbounded.To_String (Before_Filter),
              "review does not change filter text");
   end Test_Phase204_Outline_Contract_Review_Is_Side_Effect_Free;

   procedure Test_Phase204_Outline_Contract_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Editor.Outline_Audit.Outline_Contract_Review;
   begin
      Review := (others => True);
      Assert (Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review) =
                "Outline: contract healthy",
              "healthy outline feedback is deterministic");
      Review.Review_Passed := False;
      Review.Active_Buffer_Only := False;
      Assert (Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review) =
                "Outline: active-buffer scope failed",
              "active-buffer failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Targets_Validated := False;
      Assert (Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review) =
                "Outline: target validation failed",
              "target validation failure feedback is deterministic");
      Review := (others => True);
      Review.Review_Passed := False;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Editor.Outline_Audit.Build_Outline_Contract_Review_Feedback (Review) =
                "Outline: public build guardrail failed",
              "public-build sentinel feedback is deterministic");
   end Test_Phase204_Outline_Contract_Review_Feedback_Is_Deterministic;

   procedure Test_Phase204_Open_Selected_Rejects_Out_Of_Range_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "null;" & ASCII.LF &
            "end Demo;");
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 99"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 99,
             Column       => 1)));
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "out-of-range outline target is rejected before execution");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "failed out-of-range activation does not move caret");
   end Test_Phase204_Open_Selected_Rejects_Out_Of_Range_Target;


   procedure Test_Phase579_Declaration_Navigation_Availability_Rejects_Stale_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Open_Availability : Editor.Commands.Command_Availability;
      Declaration_Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "null;" & ASCII.LF &
            "end Demo;");
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 99"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 99,
             Column       => 1)));
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Open_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Declaration_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Declaration);

      Assert (not Editor.Commands.Is_Available (Open_Availability),
              "open-selected availability rejects out-of-range outline target");
      Assert (not Editor.Commands.Is_Available (Declaration_Availability),
              "goto-declaration availability rejects out-of-range outline target");
   end Test_Phase579_Declaration_Navigation_Availability_Rejects_Stale_Target;



   procedure Test_Phase531_Ada_Outline_Extracts_Subtype_And_Navigates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   subtype Count is Natural;" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 531 Ada outline refresh remains command-owned");
      Assert (Item_Count (S.Outline) = 3,
              "phase 531 Ada outline extracts package, subtype, and procedure rows");
      Assert (Item_Label (S.Outline, 2) = "subtype Count",
              "phase 531 subtype row has a compact Ada symbol label");
      Assert (Item_Kind (S.Outline, 2) = Outline_Type,
              "phase 531 subtype reuses the existing type outline kind");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 2) = "subtype Count",
              "phase 531 Feature Panel projection displays the subtype row");

      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 531 activating a real Ada outline row navigates");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 3,
              "phase 531 outline navigation uses the stored target line and column");
   end Test_Phase531_Ada_Outline_Extracts_Subtype_And_Navigates;


   procedure Test_Phase531_Empty_States_Are_Display_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "ordinary text without Ada outline declarations" & ASCII.LF &
            "still just display-only content");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 531 empty Ada outline refresh still succeeds");
      Assert (Item_Count (S.Outline) = 0,
              "phase 531 zero extracted items leave no symbol rows");
      Assert (Outline_Empty_State_Label (S.Outline) = "No outline items found.",
              "phase 531 empty extraction has a product-facing label");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "phase 531 empty outline projects one display row");
      Assert (Editor.Feature_Panel.Row_Kind (S.Feature_Panel, 1) =
                Editor.Feature_Panel.Feature_Row_Empty_State,
              "phase 531 empty projection uses an empty-state row");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "No outline items found.",
              "phase 531 Feature Panel displays the empty-state label");
      Assert (not Editor.Feature_Panel.Row_Is_Selectable (S.Feature_Panel, 1),
              "phase 531 empty-state rows are not selectable symbols");

      Before := S.Carets (0).Pos;
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status /= Editor.Executor.Command_Executed,
              "phase 531 activating an empty-state row does not navigate");
      Assert (S.Carets (0).Pos = Before,
              "phase 531 empty-state activation leaves the caret unchanged");
   end Test_Phase531_Empty_States_Are_Display_Only;


   procedure Test_Phase531_Outline_Display_States_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
   begin
      Assert (Outline_Header_Text (O) = "Outline: not refreshed",
              "phase 531 default outline header says not refreshed");
      Assert (Outline_Empty_State_Label (O) = "Outline not refreshed.",
              "phase 531 default empty label says not refreshed");

      Mark_Unsupported (O, Message_Outline_No_Symbols);
      Assert (Outline_Header_Text (O) = "Outline: no items",
              "phase 531 zero-item header is distinct from unavailable");
      Assert (Outline_Empty_State_Label (O) = "No outline items found.",
              "phase 531 zero-item label is distinct from unavailable");

      Mark_Unsupported (O, "Outline unavailable for this buffer");
      Assert (Outline_Header_Text (O) = "Outline: unavailable",
              "phase 531 unsupported header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline unavailable for this buffer.",
              "phase 531 unsupported label is explicit");

      Mark_Extraction_Failed (O);
      Assert (Outline_Header_Text (O) = "Outline: refresh failed",
              "phase 531 failure header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline refresh failed.",
              "phase 531 failure label is explicit");

      Clear (O);
      Mark_Stale_Result (O);
      Assert (Outline_Header_Text (O) = "Outline: may be stale",
              "phase 531 stale header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline may be stale.",
              "phase 531 stale label is explicit");
   end Test_Phase531_Outline_Display_States_Are_Clear;



   procedure Test_Phase531_Show_Outline_No_Active_Buffer_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 531 show outline remains an explicit UI workflow with no active buffer");
      Assert (Outline_Empty_State_Label (S.Outline) = "No active buffer.",
              "phase 531 no-active-buffer outline state is explicit");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "phase 531 no-active-buffer state projects one display row");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "No active buffer.",
              "phase 531 no-active-buffer row uses the product-facing label");
      Assert (not Editor.Feature_Panel.Row_Is_Selectable (S.Feature_Panel, 1),
              "phase 531 no-active-buffer row is display-only");
      Assert (not Editor.Feature_Panel.Row_Can_Open (S.Feature_Panel, 1),
              "phase 531 no-active-buffer row has no navigation target");
   end Test_Phase531_Show_Outline_No_Active_Buffer_State;



   procedure Test_Phase550_Next_Previous_Symbol_Use_Source_Order_And_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Next     : Natural;
      Previous : Natural;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 550,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Next := Find_Next_Symbol_For_Position (O, 550, 1, 1, True);
      Assert (Next /= 0, "phase 550 next symbol finds a navigable row");
      Assert (Item_Label (O, Next) = "procedure Alpha",
              "phase 550 next symbol chooses the first symbol after the caret");

      Next := Find_Next_Symbol_For_Position (O, 550, 3, 4, True);
      Assert (Next /= 0 and then Item_Label (O, Next) = "package Demo",
              "phase 550 next symbol wraps to the first active-buffer symbol");

      Previous := Find_Previous_Symbol_For_Position (O, 550, 3, 4, True);
      Assert (Previous /= 0 and then Item_Label (O, Previous) = "procedure Alpha",
              "phase 550 previous symbol chooses the closest preceding symbol");

      Previous := Find_Previous_Symbol_For_Position (O, 550, 1, 1, True);
      Assert (Previous /= 0 and then Item_Label (O, Previous) = "procedure Beta",
              "phase 550 previous symbol wraps to the last active-buffer symbol");
   end Test_Phase550_Next_Previous_Symbol_Use_Source_Order_And_Wrap;


   procedure Test_Phase550_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 551,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Find_Next_Symbol_For_Position (O, 552, 1, 1, True) = 0,
              "phase 550 next symbol rejects a different active buffer token");
      Assert (Find_Previous_Symbol_For_Position (O, 552, 1, 1, True) = 0,
              "phase 550 previous symbol rejects a different active buffer token");

      Mark_Stale_Result (O);
      Clear (O);
      Mark_Stale_Result (O);
      Assert (Find_Next_Symbol_For_Position (O, 551, 1, 1, True) = 0,
              "phase 550 next symbol rejects stale/non-extracted outline state");
   end Test_Phase550_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline;


   procedure Test_Phase550_Symbol_Navigation_Rejects_Retained_Stale_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 553,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Source_Class (O) = Extracted_Outline,
              "phase 550 retained stale-row fixture starts from accepted extracted rows");
      Mark_Stale_Result (O);
      Assert (Source_Class (O) = Extracted_Outline,
              "phase 550 stale diagnostic may retain accepted rows for display");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "phase 550 stale diagnostic is still visible to navigation guards");
      Assert (Find_Next_Symbol_For_Position (O, 553, 1, 1, True) = 0,
              "phase 550 next symbol rejects retained stale rows");
      Assert (Find_Previous_Symbol_For_Position (O, 553, 3, 1, True) = 0,
              "phase 550 previous symbol rejects retained stale rows");
      Assert (Find_Current_Symbol_For_Cursor (O, 553, 2, 4) = 0,
              "phase 550 current symbol rejects retained stale rows");
   end Test_Phase550_Symbol_Navigation_Rejects_Retained_Stale_Rows;


   procedure Test_Phase550_Symbol_Navigation_Rejects_Mixed_Buffer_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O     : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("package Demo"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
            Depth       => 0,
            Target_Kind => Buffer_Position_Target,
            Buffer_Token => 5501,
            Line        => 1,
            Column      => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("procedure Other"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 3"),
            Depth       => 1,
            Target_Kind => Buffer_Position_Target,
            Buffer_Token => 5502,
            Line        => 3,
            Column      => 4));
   begin
      Replace_Items (O, Items);

      Assert (Source_Class (O) = Extracted_Outline,
              "phase 550 mixed-buffer fixture starts as extracted rows");
      Assert (not Outline_Buffer_Identity_Matches (O, 5501),
              "phase 550 buffer identity rejects mixed active-buffer rows");
      Assert (not Has_Navigable_Symbol_For_Buffer (O, 5501),
              "phase 550 navigable helper rejects mixed-buffer outline rows");
      Assert (Find_Next_Symbol_For_Position (O, 5501, 1, 1, True) = 0,
              "phase 550 next symbol refuses partial navigation into mixed-buffer rows");
      Assert (Find_Previous_Symbol_For_Position (O, 5501, 4, 1, True) = 0,
              "phase 550 previous symbol refuses partial navigation into mixed-buffer rows");
      Assert (Find_Current_Symbol_For_Cursor (O, 5501, 2, 1) = 0,
              "phase 550 current symbol refuses partial derivation from mixed-buffer rows");
   end Test_Phase550_Symbol_Navigation_Rejects_Mixed_Buffer_Rows;


   procedure Test_Phase550_Status_Counts_Only_Navigable_Symbol_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O     : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Section,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Navigation"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("section"),
            Depth       => 0,
            Target_Kind  => No_Target,
            Buffer_Token => 0,
            Line         => 0,
            Column       => 0),
         2 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("package Demo"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 5503,
            Line         => 1,
            Column       => 1),
         3 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("procedure Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 2"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 5503,
            Line         => 2,
            Column       => 4));
   begin
      Replace_Items (O, Items);

      Assert (Navigable_Symbol_Count (O) = 2,
              "phase 550 status counts real navigable symbols, not group/status rows");
      Assert (Filtered_Navigable_Symbol_Count (O) = 2,
              "phase 550 unfiltered visible symbol count excludes display rows");
      Assert (Outline_Header_Text (O) = "Outline: 2 symbols",
              "phase 550 outline header counts navigable symbols only");

      Apply_Filter (O, "run");
      Assert (Filtered_Navigable_Symbol_Count (O) = 1,
              "phase 550 filtered status count reports only matching symbols");
      Assert (Filtered_Row_Count (O) = 1,
              "phase 550 fixture filter also leaves one visible projection row");
      Assert (Outline_Header_Text (O) = "Outline: filter ""run"" -- 1 of 2 symbols",
              "phase 550 filtered header counts navigable symbols only");

      Mark_Stale_Result (O);
      Assert (Outline_Header_Text (O) = "Outline: stale",
              "phase 550 retained stale rows override current/filter header text");
      Assert (Navigable_Symbol_Count (O) = 0,
              "phase 550 status symbol count rejects retained stale rows");
      Assert (Filtered_Navigable_Symbol_Count (O) = 0,
              "phase 550 filtered status count rejects retained stale rows");
   end Test_Phase550_Status_Counts_Only_Navigable_Symbol_Rows;


   procedure Test_Phase550_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 555,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Outline_Buffer_Identity_Matches (O, 555),
              "phase 550 buffer identity helper accepts current extracted rows");
      Assert (Has_Navigable_Symbol_For_Buffer (O, 555),
              "phase 550 navigable-symbol helper sees accepted active-buffer rows");
      Assert (not Outline_Buffer_Identity_Matches (O, 556),
              "phase 550 buffer identity helper rejects another active buffer token");

      Apply_Filter (O, "run");
      Remember_Filter_For_Buffer (O, 555);
      Clear_Filter (O);
      Assert (Restore_Filter_For_Buffer (O, 555),
              "phase 550 transient filter restore accepts live matching rows");

      Mark_Stale_Result (O);
      Clear_Filter (O);
      Assert (not Outline_Buffer_Identity_Matches (O, 555),
              "phase 550 buffer identity helper rejects retained stale rows");
      Assert (not Has_Navigable_Symbol_For_Buffer (O, 555),
              "phase 550 navigable-symbol helper rejects retained stale rows");
      Assert (not Restore_Filter_For_Buffer (O, 555),
              "phase 550 filter restore rejects retained stale rows");
   end Test_Phase550_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows;


   procedure Test_Phase550_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 554,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 554, 2, 4);
      Set_Rows_From_Outline (O, Panel);
      Assert (Can_Reveal_Current_Symbol (O, Panel, 554),
              "phase 550 reveal helper accepts a live current symbol row");

      Mark_Stale_Result (O);
      Assert (not Can_Reveal_Current_Symbol (O, Panel, 554),
              "phase 550 reveal helper rejects retained stale current-symbol rows");
   end Test_Phase550_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol;


   procedure Test_Phase550_Command_Surface_Registers_Navigation_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Label (Editor.Commands.Command_Next_Outline_Symbol) =
                "Next Outline Symbol",
              "phase 550 next symbol command has a palette label");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Previous_Outline_Symbol) =
                "Previous Outline Symbol",
              "phase 550 previous symbol command has a palette label");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Next_Outline_Symbol) =
                Editor.Commands.Navigation_Category,
              "phase 550 next symbol is categorized as navigation");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Previous_Outline_Symbol) =
                Editor.Commands.Navigation_Category,
              "phase 550 previous symbol is categorized as navigation");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.next-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Next_Outline_Symbol,
              "phase 550 next symbol stable name round trips without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.previous-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Previous_Outline_Symbol,
              "phase 550 previous symbol stable name round trips without payload");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol) =
                "outline.reveal-current-symbol",
              "phase 550 reveal-current command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Focus_Outline_Filter) =
                "outline.filter.focus",
              "phase 550 focus filter command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Clear_Outline_Filter) =
                "outline.filter.clear",
              "phase 550 clear filter command has canonical no-payload stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.reveal-current-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Reveal_Current_Outline_Symbol,
              "phase 550 reveal-current stable alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.next-match", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "phase 550 filter next-match alias routes to existing filtered selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.previous-match", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Previous_Outline_Item,
              "phase 550 filter previous-match alias routes to existing filtered selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.focus", Found);
      Assert (Found and then Id = Editor.Commands.Command_Focus_Outline_Filter,
              "phase 550 filter focus alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Clear_Outline_Filter,
              "phase 550 filter clear alias routes without payload");
   end Test_Phase550_Command_Surface_Registers_Navigation_Commands;



   procedure Test_Phase550_Filter_Match_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Before_Selected : Natural := 0;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 550,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Apply_Filter (O, "beta");
      Select_Item (O, 0);
      Before_Selected := Selected_Index (O);

      Assert (Has_Selectable_Filter_Match (O),
              "phase 550 filter availability sees matching selectable symbols");
      Assert (Selected_Index (O) = Before_Selected,
              "phase 550 filter availability helper does not reconcile or mutate selection");

      Apply_Filter (O, "line 2");
      Assert (Has_Selectable_Filter_Match (O),
              "phase 550 filter availability matches deterministic row detail text");

      Apply_Filter (O, "not-present");
      Assert (not Has_Selectable_Filter_Match (O),
              "phase 550 filter availability rejects no-match filters");

      Clear_Filter (O);
      Mark_Stale_Result (O);
      Assert (not Has_Selectable_Filter_Match (O),
              "phase 550 filter availability rejects retained stale rows");
   end Test_Phase550_Filter_Match_Availability_Is_Side_Effect_Free;


   procedure Test_Phase550_Ada_Symbol_Navigation_Audit_Is_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_FP      : Natural;
      Before_Select  : Natural;
      Before_Current : Natural;
      Before_Filter  : Ada.Strings.Unbounded.Unbounded_String;
      Review         : Editor.Outline_Audit.Outline_Contract_Review;
   begin
      Editor.State.Init (S);
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Package,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 1,
             Column       => 1),
          2 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 2"),
             Depth       => 1,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 2,
             Column       => 4),
          3 =>
            (Kind        => Outline_Function,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Compute"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 3"),
             Depth       => 1,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 3,
             Column       => 4)));
      Apply_Filter (S.Outline, "run");
      Update_Current_Symbol_For_Cursor (S.Outline, S.Registry_Token, 2, 4);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);

      Before_FP := Fingerprint (S.Outline);
      Before_Select := Selected_Index (S.Outline);
      Before_Current := Current_Symbol_Index (S.Outline);
      Before_Filter := Ada.Strings.Unbounded.To_Unbounded_String (Filter_Text (S.Outline));

      Assert (Editor.Outline_Audit.Assert_Ada_Symbol_Navigation_Coherent (S),
              "phase 550 milestone helper accepts coherent symbol navigation state");
      Review := Editor.Outline_Audit.Review_Outline_Contract (S);
      Assert (Review.Ada_Symbol_Navigation_Coherent,
              "phase 550 contract review includes symbol navigation coherence");
      Assert (Editor.Outline_Audit.Assert_Ada_Lexical_Safety_Coherent (S),
              "phase 552 milestone helper accepts coherent lexical safety state");
      Assert (Review.Ada_Lexical_Safety_Coherent,
              "phase 552 contract review includes lexical safety coherence");
      Assert (Fingerprint (S.Outline) = Before_FP,
              "phase 550 symbol navigation audit does not mutate outline content");
      Assert (Selected_Index (S.Outline) = Before_Select,
              "phase 550 symbol navigation audit does not change selection");
      Assert (Current_Symbol_Index (S.Outline) = Before_Current,
              "phase 550 symbol navigation audit does not change current symbol");
      Assert (Filter_Text (S.Outline) = Ada.Strings.Unbounded.To_String (Before_Filter),
              "phase 550 symbol navigation audit does not change filter text");
   end Test_Phase550_Ada_Symbol_Navigation_Audit_Is_Coherent;


   procedure Test_Phase551_Ada_Structure_Ranges_Annotate_Outline_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           77,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "phase 551 structure extraction succeeds");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Assert (Item_Count (O) = 2,
              "phase 551 keeps ordinary Ada outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "phase 551 package body row is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "phase 551 package body detail carries best-effort line range");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "phase 551 procedure body row is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-5 body",
              "phase 551 procedure body detail carries best-effort line range");
   end Test_Phase551_Ada_Structure_Ranges_Annotate_Outline_Details;


   procedure Test_Phase551_Current_Symbol_Uses_Smallest_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      if True then" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end if;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           88,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 current-symbol fixture has package/procedure rows");
      Assert (Item_Detail (O, 1) = "lines 1-8 body",
              "phase 551 package range includes nested procedure");
      Assert (Item_Detail (O, 2) = "lines 2-7 body",
              "phase 551 procedure range includes nested if block");

      Assert (Find_Current_Symbol_For_Cursor (O, 88, 5, 10) = 2,
              "phase 551 current symbol uses smallest enclosing procedure range");
      Update_Current_Symbol_For_Cursor (O, 88, 5, 10);
      Assert (Current_Symbol_Label (O) = "procedure body Run",
              "phase 551 passive current label reflects range-derived symbol");
      Assert (Find_Current_Symbol_For_Cursor (O, 88, 1, 1) = 1,
              "phase 551 package line resolves to package body range");
   end Test_Phase551_Current_Symbol_Uses_Smallest_Enclosing_Range;


   procedure Test_Phase551_Structure_Ranges_Ignore_Comments_And_String_Keywords
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   -- procedure Fake is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      Text : constant String := ""end Run;"";" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null; -- end Demo;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb",
           99,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 comment/string safety does not fabricate outline rows");
      Assert (Item_Detail (O, 1) = "lines 1-8 body",
              "phase 551 package range ignores commented end text");
      Assert (Item_Detail (O, 2) = "lines 3-7 body",
              "phase 551 procedure range ignores string literal end text");
   end Test_Phase551_Structure_Ranges_Ignore_Comments_And_String_Keywords;


   procedure Test_Phase551_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Inner;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "nested_begin.adb",
           101,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 nested begin/end fixture keeps outer and inner rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 outer procedure label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "phase 551 outer procedure range ignores nested anonymous block end");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "phase 551 inner procedure label is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-5 body",
              "phase 551 inner procedure range closes at its own end");
      Assert (Find_Current_Symbol_For_Cursor (O, 101, 8, 7) = 1,
              "phase 551 nested anonymous block still resolves to enclosing outer procedure");
   end Test_Phase551_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body;


   procedure Test_Phase551_Record_Task_And_Protected_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("type Item is record" & ASCII.LF &
           "   Value : Integer;" & ASCII.LF &
           "end record;" & ASCII.LF &
           "task body Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "protected body Guard is" & ASCII.LF &
           "   procedure Touch is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Touch;" & ASCII.LF &
           "end Guard;" & ASCII.LF,
           "structures.adb",
           102,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 5,
              "phase 551 record/task/protected fixture keeps expected outline rows");
      Assert (Item_Label (O, 1) = "record type Item",
              "phase 551 record type label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-3 record",
              "phase 551 record type receives a closed range");
      Assert (Item_Label (O, 2) = "field Value",
              "phase 579 record component row is visible inside the record");
      Assert (Item_Label (O, 3) = "task body Worker",
              "phase 551 task body label is preserved");
      Assert (Item_Detail (O, 3) = "lines 4-7 body",
              "phase 551 task body receives a closed range");
      Assert (Item_Label (O, 4) = "protected body Guard",
              "phase 551 protected body label is preserved");
      Assert (Item_Detail (O, 4) = "lines 8-13 body",
              "phase 551 protected body receives a closed range over nested procedure");
      Assert (Item_Label (O, 5) = "procedure body Touch",
              "phase 551 nested protected procedure label is preserved");
      Assert (Item_Detail (O, 5) = "lines 9-12 body",
              "phase 551 nested protected procedure receives a closed range");
      Assert (Find_Current_Symbol_For_Cursor (O, 102, 11, 7) = 5,
              "phase 551 current symbol prefers nested protected operation range");
   end Test_Phase551_Record_Task_And_Protected_Ranges;


   procedure Test_Phase551_Task_And_Protected_Type_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("task type Worker is" & ASCII.LF &
           "   entry Start;" & ASCII.LF &
           "end Worker;" & ASCII.LF &
           "protected type Guard is" & ASCII.LF &
           "   procedure Touch;" & ASCII.LF &
           "private" & ASCII.LF &
           "   Flag : Boolean := False;" & ASCII.LF &
           "end Guard;" & ASCII.LF,
           "task_protected_types.ads",
           106,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 5,
              "phase 579 task/protected type fixture includes entry declaration row");
      Assert (Item_Label (O, 1) = "task type Worker",
              "phase 551 task type label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-3 type",
              "phase 551 task type receives a closed lexical range");
      Assert (Item_Label (O, 2) = "entry Start",
              "phase 579 task entry declaration is exposed as a navigable outline row");
      Assert (Item_Detail (O, 2) = "line 2 declaration",
              "phase 579 task entry declaration keeps declaration detail");
      Assert (Item_Depth (O, 2) = 1,
              "phase 579 task entry declaration is nested under the task type");
      Assert (Item_Label (O, 3) = "protected type Guard",
              "phase 551 protected type label is preserved");
      Assert (Item_Detail (O, 3) = "lines 4-8 type",
              "phase 551 protected type receives a closed lexical range");
      Assert (Item_Label (O, 4) = "procedure Touch",
              "phase 579 protected operation declaration is visible");
      Assert (Item_Label (O, 5) = "object Flag",
              "phase 579 private protected object row is visible");
      Assert (Find_Current_Symbol_For_Cursor (O, 106, 7, 4) = 5,
              "phase 579 current symbol prefers the private protected object row");
   end Test_Phase551_Task_And_Protected_Type_Ranges;


   procedure Test_Phase551_Named_End_Mismatch_Does_Not_Close_Root_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Wrong;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_end.adb",
           103,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 mismatched named end fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 mismatched root end keeps outer row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 mismatched named end does not fabricate a closed root range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "phase 551 later procedure label is preserved after mismatch");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "phase 551 later procedure range is not corrupted by earlier mismatch");
   end Test_Phase551_Named_End_Mismatch_Does_Not_Close_Root_Range;


   procedure Test_Phase551_Keyword_End_Forms_Close_Matching_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF &
           "procedure Run is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end procedure;" & ASCII.LF,
           "keyword_end_forms.adb",
           104,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 keyword end fixture keeps package and procedure rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "phase 551 keyword package end keeps package row label");
      Assert (Item_Detail (O, 1) = "lines 1-4 body",
              "phase 551 end package closes package body range");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "phase 551 keyword procedure end keeps procedure row label");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "phase 551 end procedure closes procedure body range");
   end Test_Phase551_Keyword_End_Forms_Close_Matching_Constructs;


   procedure Test_Phase551_Keyword_End_Mismatch_Does_Not_Close_Root_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF &
           "package body Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end package;" & ASCII.LF,
           "keyword_end_mismatch.adb",
           105,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 keyword mismatch fixture keeps both rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 keyword mismatch keeps procedure row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 end package does not close procedure body range");
      Assert (Item_Label (O, 2) = "package body Later",
              "phase 551 later package row is preserved after mismatch");
      Assert (Item_Detail (O, 2) = "lines 5-8 body",
              "phase 551 matching keyword end still closes later package range");
   end Test_Phase551_Keyword_End_Mismatch_Does_Not_Close_Root_Range;


   procedure Test_Phase551_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   if Ready then null; end if;" & ASCII.LF &
           "   for I in 1 .. 2 loop null; end loop;" & ASCII.LF &
           "   procedure Local is begin null; end Local;" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "inline_balanced_blocks.adb",
           107,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 inline-balanced fixture keeps outer and local rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 inline-balanced outer procedure label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-7 body",
              "phase 551 one-line if/loop/subprogram do not truncate outer range");
      Assert (Item_Label (O, 2) = "procedure body Local",
              "phase 551 inline local procedure row is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 5 body") /= 0,
              "phase 551 single-line local procedure remains start-only");
      Assert (Find_Current_Symbol_For_Cursor (O, 107, 6, 4) = 1,
              "phase 551 current symbol still resolves inside outer after inline blocks");
   end Test_Phase551_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges;


   procedure Test_Phase551_Multiline_Subprogram_Body_Header_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer" & ASCII.LF &
           "  (Value : Integer)" & ASCII.LF &
           "is" & ASCII.LF &
           "   procedure Local" & ASCII.LF &
           "     (Flag : Boolean)" & ASCII.LF &
           "   is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Local;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Local (True);" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "multiline_body_header.adb",
           108,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 multiline body fixture keeps outer and local rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 multiline body outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-12 body",
              "phase 551 multiline body header receives closed range");
      Assert (Item_Label (O, 2) = "procedure body Local",
              "phase 551 multiline nested body label is preserved");
      Assert (Item_Detail (O, 2) = "lines 4-9 body",
              "phase 551 multiline nested body receives closed range");
      Assert (Find_Current_Symbol_For_Cursor (O, 108, 8, 7) = 2,
              "phase 551 current symbol uses nested multiline body range");
      Assert (Find_Current_Symbol_For_Cursor (O, 108, 11, 4) = 1,
              "phase 551 current symbol returns outer after nested multiline body");
   end Test_Phase551_Multiline_Subprogram_Body_Header_Range;


   procedure Test_Phase551_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Decl" & ASCII.LF &
           "     (Value : Integer);" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "split_subprogram_spec.adb",
           109,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 split spec fixture keeps outer and declaration rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 split spec outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "phase 551 split spec does not consume outer body range");
      Assert (Item_Label (O, 2) = "procedure Decl",
              "phase 551 split spec declaration row is preserved");
      Assert (Item_Detail (O, 2) = "line 2 declaration",
              "phase 551 split spec does not fabricate a body range");
   end Test_Phase551_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range;




   procedure Test_Phase551_Separate_Body_Stubs_Do_Not_Get_Local_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo.Child is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "   separate;" & ASCII.LF &
           "function Make return Integer is separate;" & ASCII.LF &
           "procedure Real is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end;" & ASCII.LF,
           "separate_body_stubs.adb",
           110,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 4,
              "phase 551 separate stub fixture keeps all body-like rows");
      Assert (Item_Label (O, 1) = "package body Demo.Child",
              "phase 551 split separate package stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 split separate package stub has no local range");
      Assert (Item_Label (O, 2) = "procedure body Worker",
              "phase 551 split separate procedure stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 3 body") /= 0,
              "phase 551 split separate procedure stub has no local range");
      Assert (Item_Label (O, 3) = "function body Make",
              "phase 551 same-line separate function stub label is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "line 5 body") /= 0,
              "phase 551 same-line separate function stub has no local range");
      Assert (Item_Label (O, 4) = "procedure body Real",
              "phase 551 following real body label is preserved");
      Assert (Item_Detail (O, 4) = "lines 6-9 body",
              "phase 551 later real body still receives a closed local range");
   end Test_Phase551_Separate_Body_Stubs_Do_Not_Get_Local_Ranges;


   procedure Test_Phase551_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Local" & ASCII.LF &
           "     (Message : String := ""is"");" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "split_spec_string_tokens.adb",
           111,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 split spec string-token fixture keeps outer and declaration rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 split spec string-token outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "phase 551 string literal is token does not corrupt outer body range");
      Assert (Item_Label (O, 2) = "procedure Local",
              "phase 551 split spec with string default keeps declaration row");
      Assert (Item_Detail (O, 2) = "line 2 declaration",
              "phase 551 split spec string default does not fabricate body range");
   end Test_Phase551_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges;

   procedure Test_Phase551_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   overriding procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      begin" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end;" & ASCII.LF &
           "   end Inner;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "prefixed_nested_body.adb",
           112,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 prefixed nested-body fixture keeps outer and inner rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 prefixed nested-body outer label is preserved");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "phase 551 prefixed nested body participates in enclosing range stack");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "phase 551 prefixed nested-body inner label is preserved");
      Assert (Item_Detail (O, 2) = "lines 2-7 body",
              "phase 551 prefixed nested body receives its own range");
   end Test_Phase551_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack;


   procedure Test_Phase551_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Bad is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   case Value is" & ASCII.LF &
           "      when others => null;" & ASCII.LF &
           "   end if;" & ASCII.LF &
           "end Bad;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_nested_block.adb",
           113,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 mismatched nested-block fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Bad",
              "phase 551 malformed block keeps bad procedure row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 mismatched end if does not close a case block and fabricate a range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "phase 551 later procedure label is preserved after malformed block");
      Assert (Item_Detail (O, 2) = "lines 7-10 body",
              "phase 551 later procedure range survives earlier malformed block");
   end Test_Phase551_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range;


   procedure Test_Phase551_Mismatched_Nested_Named_End_Does_Not_Close_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "   procedure Inner is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Wrong;" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Outer;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_nested_named_end.adb",
           114,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "phase 551 mismatched nested named-end fixture keeps all procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 mismatched nested named-end keeps outer row label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 end Wrong does not close nested Inner and fabricate outer range");
      Assert (Item_Label (O, 2) = "procedure body Inner",
              "phase 551 malformed nested body row is preserved");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "line 2 body") /= 0,
              "phase 551 mismatched nested named end does not fabricate inner range");
      Assert (Item_Label (O, 3) = "procedure body Later",
              "phase 551 later procedure label survives nested named mismatch");
      Assert (Item_Detail (O, 3) = "lines 9-12 body",
              "phase 551 later range survives nested named mismatch");
   end Test_Phase551_Mismatched_Nested_Named_End_Does_Not_Close_Body;


   procedure Test_Phase551_Labeled_Blocks_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Demo : begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Demo;" & ASCII.LF &
           "end Demo;" & ASCII.LF &
           "procedure Run is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Run : declare" & ASCII.LF &
           "      Value : Integer := 0;" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Run;" & ASCII.LF,
           "labeled_blocks.adb",
           115,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 labeled-block fixture keeps package and procedure rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "phase 551 labeled block keeps package body label");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "phase 551 labeled begin block does not close same-named package body");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "phase 551 labeled declare block keeps procedure body label");
      Assert (Item_Detail (O, 2) = "lines 7-14 body",
              "phase 551 labeled declare block does not close same-named procedure body");
   end Test_Phase551_Labeled_Blocks_Do_Not_Close_Enclosing_Range;


   procedure Test_Phase551_Mismatched_Labeled_Loop_End_Does_Not_Close_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("procedure Outer is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   Loop_Label : loop" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end loop Wrong_Label;" & ASCII.LF &
           "end Outer;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "mismatched_labeled_loop.adb",
           116,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 mismatched labeled loop fixture keeps both procedure rows");
      Assert (Item_Label (O, 1) = "procedure body Outer",
              "phase 551 mismatched labeled loop keeps outer procedure label");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "line 1 body") /= 0,
              "phase 551 end loop Wrong_Label does not fabricate outer range");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "phase 551 later procedure survives labeled loop mismatch");
      Assert (Item_Detail (O, 2) = "lines 7-10 body",
              "phase 551 later range survives labeled loop mismatch");
   end Test_Phase551_Mismatched_Labeled_Loop_End_Does_Not_Close_Range;


   procedure Test_Phase551_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("protected body Device is" & ASCII.LF &
           "   entry Device when Ready is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Device;" & ASCII.LF &
           "end Device;" & ASCII.LF &
           "task body Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   accept Worker do" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "entry_accept_bodies.adb",
           117,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "phase 579 entry/accept body fixture keeps enclosing rows and entry declaration");
      Assert (Item_Label (O, 1) = "protected body Device",
              "phase 551 protected body label is preserved across same-named entry body");
      Assert (Item_Detail (O, 1) = "lines 1-6 body",
              "phase 551 same-named entry end does not close protected body early");
      Assert (Item_Label (O, 2) = "entry Device",
              "phase 579 protected entry declaration remains navigable");
      Assert (Item_Label (O, 3) = "task body Worker",
              "phase 551 task body label is preserved across same-named accept body");
      Assert (Item_Detail (O, 3) = "lines 7-12 body",
              "phase 551 same-named accept end does not close task body early");
   end Test_Phase551_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range;


   procedure Test_Phase551_Select_Blocks_Do_Not_Close_Enclosing_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("task body Coordinator is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   select" & ASCII.LF &
           "      accept Start do" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end Start;" & ASCII.LF &
           "   or" & ASCII.LF &
           "      delay 1.0;" & ASCII.LF &
           "   end select;" & ASCII.LF &
           "end Coordinator;" & ASCII.LF &
           "procedure Later is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Later;" & ASCII.LF,
           "select_blocks.adb",
           118,
           1,
           1,
           0);
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 551 select block fixture keeps enclosing task and later procedure rows");
      Assert (Item_Label (O, 1) = "task body Coordinator",
              "phase 551 select block keeps task body label");
      Assert (Item_Detail (O, 1) = "lines 1-10 body",
              "phase 551 end select closes select frame without closing task body early");
      Assert (Item_Label (O, 2) = "procedure body Later",
              "phase 551 later procedure survives select block matching");
      Assert (Item_Detail (O, 2) = "lines 11-14 body",
              "phase 551 later procedure range survives select block matching");
   end Test_Phase551_Select_Blocks_Do_Not_Close_Enclosing_Range;


   procedure Test_Phase552_Ada_Lexical_Sanitizer_Preserves_Columns
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "X : String := ""-- procedure Fake""; C := 'P'; Y := Integer'Image (Value); -- end;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure");
      Comment_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "-- end");
      Char_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'P'");
      Attr_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'Image");
      Unmatched_Line : constant String :=
        "Y := Integer'Image (Value); Z := Value + 1;";
      Z_Column       : constant Natural := Ada.Strings.Fixed.Index (Unmatched_Line, "Z :=");
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 sanitized Ada line preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure") = 0,
              "phase 552 sanitized Ada line masks string declarations");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "--") = 0,
              "phase 552 sanitized Ada line masks comments");
      Assert (Sanitized (Line'First) = 'X',
              "phase 552 sanitized Ada line preserves code columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Column)),
              "phase 552 string text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Column)),
              "phase 552 comment text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Char_Column)),
              "phase 552 simple character literal is non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attr_Column)),
              "phase 552 Ada attribute apostrophe remains code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Unmatched_Line, Positive (Z_Column)),
              "phase 552 unmatched apostrophe in attribute-like text does not suppress later code");
   end Test_Phase552_Ada_Lexical_Sanitizer_Preserves_Columns;

   procedure Test_Phase552_Ada_Outline_Ignores_Comments_Strings_And_Characters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "-- procedure Hidden;" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   S1 : constant String := ""procedure Fake is"";" & ASCII.LF &
           "   S2 : constant String := ""quoted """" package Hidden is """" text"";" & ASCII.LF &
           "   C  : Character := 'P';" & ASCII.LF &
           "   Img : String := Integer'Image (42);" & ASCII.LF &
           "   procedure Run; -- function Fake return Integer;" & ASCII.LF &
           "end Real;",
           "real.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "phase 552 outline ignores fake declarations in comments and strings while keeping real objects");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 real package near comments extracts");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 real procedure with inline comment extracts");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 8,
              "phase 552 original source target line is preserved");
   end Test_Phase552_Ada_Outline_Ignores_Comments_Strings_And_Characters;

   procedure Test_Phase552_Ada_Structure_Ranges_Use_Code_Only_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      Put_Line (""end Run; begin package Fake is"" );" & ASCII.LF &
           "      C := 'E';" & ASCII.LF &
           "      -- begin" & ASCII.LF &
           "      -- end Run;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "real.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "phase 552 structure input still extracts real package body and procedure");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "lines 1-9") /= 0,
              "phase 552 package body range ignores begin/end in strings and comments");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-8") /= 0,
              "phase 552 procedure body range ignores non-code close tokens");
   end Test_Phase552_Ada_Structure_Ranges_Use_Code_Only_Text;

   procedure Test_Phase552_Ada_Record_Range_Ignores_End_Record_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   type State is record" & ASCII.LF &
           "      Text : String := ""end record;"";" & ASCII.LF &
           "      -- end record;" & ASCII.LF &
           "      Value : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Real;",
           "record_strings.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 552 record fixture extracts package, record type, and real fields only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, First_Label_Index (O, "record type State")) = "record type State",
              "phase 552 record label is based on real type declaration");
      Assert (Ada.Strings.Fixed.Index
                (Item_Detail (O, First_Label_Index (O, "record type State")), "lines 2-6") /= 0,
              "phase 552 record range ignores end record inside strings and comments");
   end Test_Phase552_Ada_Record_Range_Ignores_End_Record_In_Non_Code;

   procedure Test_Phase552_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      if Ready then" & ASCII.LF &
           "         Put_Line (""end if; end Run;"");" & ASCII.LF &
           "         -- end if;" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end if;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "nested_if_strings.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "phase 552 nested-block fixture extracts package body and procedure only");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "lines 1-10") /= 0,
              "phase 552 package range ignores end text inside nested string/comment lines");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-9") /= 0,
              "phase 552 procedure range ignores end if/end procedure text inside strings/comments");
   end Test_Phase552_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code;

   procedure Test_Phase552_Ada_Unterminated_String_Is_Line_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   Broken : constant String := ""procedure Fake is" & ASCII.LF &
           "   procedure After_Broken;" & ASCII.LF &
           "end Real;",
           "real.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 unterminated string masks only its physical line while keeping real constants");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "procedure After_Broken",
              "phase 552 valid declaration after unterminated string line extracts");
   end Test_Phase552_Ada_Unterminated_String_Is_Line_Local;


   procedure Test_Phase552_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "S := ""quoted """" package Fake is -- end """" text""; X := 1;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Package_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "package");
      Marker_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "-- end");
      X_Column       : constant Natural := Ada.Strings.Fixed.Index (Line, "X := 1");
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 doubled-quote sanitizer preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package") = 0,
              "phase 552 doubled quotes do not expose fake package text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "--") = 0,
              "phase 552 comment marker inside a string is masked as string text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Package_Column)),
              "phase 552 package token inside doubled-quote string is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Marker_Column)),
              "phase 552 comment marker inside doubled-quote string is non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (X_Column)),
              "phase 552 code after a closed doubled-quote string remains code");
   end Test_Phase552_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code;

   procedure Test_Phase552_Ada_Generic_Prelude_Ignores_Comment_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- generic" & ASCII.LF &
           "-- package Fake is" & ASCII.LF &
           "procedure Plain;" & ASCII.LF &
           "generic" & ASCII.LF &
           "procedure Real_Generic;",
           "generic_comments.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "phase 552 generic prelude comments do not add fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "procedure Plain",
              "phase 552 generic text inside comments does not mark next declaration generic");
      Assert (Item_Label (O, 2) = "generic procedure Real_Generic",
              "phase 552 real generic prelude still applies to the following declaration");
   end Test_Phase552_Ada_Generic_Prelude_Ignores_Comment_Text;

   procedure Test_Phase552_Ada_Current_Symbol_And_Reveal_Skip_Fakes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "-- procedure Fake_Comment;" & ASCII.LF &
            "package Real is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   procedure Run; -- procedure Fake_Inline;" & ASCII.LF &
            "end Real;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 552 current-symbol fixture refreshes through executor");
      Assert (Item_Count (S.Outline) = 3,
              "phase 552 current-symbol fixture has real package, object, and procedure rows");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Label (S.Outline) = "procedure Run",
              "phase 552 current symbol ignores fake comment and string declarations");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "phase 552 reveal current executes after lexical-safe refresh");
      Assert (Selected_Index (S.Outline) = 3,
              "phase 552 reveal current selects only the real procedure row");
      Assert (Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              and then Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 3,
              "phase 552 reveal current mirrors the real row into feature-panel selection");
   end Test_Phase552_Ada_Current_Symbol_And_Reveal_Skip_Fakes;


   procedure Test_Phase552_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Ada.Strings.Unbounded;
      Big       : Unbounded_String := To_Unbounded_String ("package Real is ");
      Sanitized : Unbounded_String;
      Repeat    : Unbounded_String;
   begin
      for I in 1 .. 200 loop
         Append (Big, Character'Val (34) & "procedure Fake_" & Natural'Image (I) & " is" & Character'Val (34) & " ");
         Append (Big, "-- begin end package procedure function type");
      end loop;

      Sanitized := To_Unbounded_String
        (Editor.Ada_Syntax_Core.Sanitize_Line (To_String (Big)));
      Repeat := To_Unbounded_String
        (Editor.Ada_Syntax_Core.Sanitize_Line (To_String (Big)));

      Assert (Length (Sanitized) = Length (Big),
              "phase 552 large lexical sanitization preserves line length");
      Assert (Sanitized = Repeat,
              "phase 552 large lexical sanitization is deterministic for the same snapshot line");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "procedure Fake_") = 0,
              "phase 552 large string/comment-heavy line masks declaration-like text");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "--") = 0,
              "phase 552 large string/comment-heavy line masks comment markers");
      Assert (Ada.Strings.Fixed.Index (To_String (Sanitized), "package Real is") /= 0,
              "phase 552 large string/comment-heavy line preserves leading code");
   end Test_Phase552_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic;


   function Contains_Phase552_Lexical_State_Term (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "scanner") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "sanitized") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "token mask") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "lexical state") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "comment map") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "string map") /= 0;
   end Contains_Phase552_Lexical_State_Term;

   procedure Test_Phase552_Ada_Character_Quote_Literal_And_Spaces_Are_Masked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quote      : constant Character := Character'Val (16#27#);
      Line       : constant String :=
        "A : Character := " & Quote & " " & Quote &
        "; Q : Character := " & Quote & Quote & Quote & Quote &
        "; procedure Real;";
      Sanitized  : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Space_Lit  : constant Natural := Ada.Strings.Fixed.Index (Line, Quote & " " & Quote);
      Quote_Lit  : constant Natural := Ada.Strings.Fixed.Index (Line, Quote & Quote & Quote & Quote);
      Proc_Col   : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure Real");
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 quote/space character literal masking preserves columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Space_Lit)),
              "phase 552 space character literal starts as non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Quote_Lit)),
              "phase 552 quote character literal starts as non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Proc_Col)),
              "phase 552 code after quote character literal remains code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") /= 0,
              "phase 552 declaration after character literals remains visible");
   end Test_Phase552_Ada_Character_Quote_Literal_And_Spaces_Are_Masked;

   procedure Test_Phase552_Ada_Valid_Declarations_After_Closed_Non_Code_Spans
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   S : constant String := ""function Fake return Integer"";" & ASCII.LF &
           "   procedure After_String;" & ASCII.LF &
           "   C : Character := 'P';" & ASCII.LF &
           "   function After_Char return Integer;" & ASCII.LF &
           "   I : String := Integer'Image (42);" & ASCII.LF &
           "   subtype Index is Natural;" & ASCII.LF &
           "end Real;",
           "after_non_code.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "phase 552 inline declarations after closed strings/chars/attributes extract");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 package remains first real row");
      Assert_Has_Label (O, "procedure After_String",
              "phase 552 declaration after closed string line extracts");
      Assert_Has_Label (O, "function After_Char",
              "phase 552 declaration after simple character literal line extracts");
      Assert_Has_Label (O, "subtype Index",
              "phase 552 declaration after attribute apostrophe line extracts");
   end Test_Phase552_Ada_Valid_Declarations_After_Closed_Non_Code_Spans;


   procedure Test_Phase552_Ada_Comment_Starts_After_Closed_String_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "S := ""-- not a comment inside string""; I := Integer'Image (42); -- procedure Fake; end Real;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Inner_Marker : constant Natural := Ada.Strings.Fixed.Index (Line, "-- not");
      Attr_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "'Image");
      Comment_Col  : constant Natural := Ada.Strings.Fixed.Index (Line, "-- procedure");
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 post-string comment sanitizer preserves line length");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Inner_Marker)),
              "phase 552 -- inside a closed string remains string text, not a comment boundary");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attr_Column)),
              "phase 552 attribute apostrophe between string and comment remains code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Col)),
              "phase 552 -- after a closed string starts the actual line comment");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 fake declaration after post-string comment marker is masked");
   end Test_Phase552_Ada_Comment_Starts_After_Closed_String_Only;

   procedure Test_Phase552_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Name : String := ""procedure Fake; end Real;""; -- function Hidden return Integer" & ASCII.LF &
           "      Value : Integer);" & ASCII.LF &
           "   function After return Integer;" & ASCII.LF &
           "end Real;",
           "multiline_sanitized.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 multi-line declaration windows ignore fake text in strings/comments");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 package row survives multi-line declaration fixture");
      Assert (Item_Label (O, 2) = "procedure Run",
              "phase 552 split procedure row survives inline comment/string text");
      Assert (Item_Label (O, 3) = "function After",
              "phase 552 following declaration proves pending window closed on code semicolon");
   end Test_Phase552_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text;

   procedure Test_Phase552_Ada_Generic_Prelude_Ignores_String_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   Marker : constant String := ""generic"";" & ASCII.LF &
           "   procedure Plain;" & ASCII.LF &
           "   Text : constant String := ""generic package Hidden is"";" & ASCII.LF &
           "   function Still_Plain return Integer;" & ASCII.LF &
           "end Real;",
           "generic_string.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 552 generic prelude text in strings does not create or decorate rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "procedure Plain",
              "phase 552 string generic marker does not mark procedure generic");
      Assert_Has_Label (O, "function Still_Plain",
              "phase 552 string generic package text does not affect later function");
   end Test_Phase552_Ada_Generic_Prelude_Ignores_String_Text;

   procedure Test_Phase552_Ada_Sanitized_View_Is_Transient_And_Derived
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line_A : constant String := "procedure Real; -- procedure Fake;";
      Line_B : constant String := "procedure Real;";
      A1 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_A);
      A2 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_A);
      B1 : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line_B);
   begin
      Assert (A1 = A2,
              "phase 552 sanitized view is derived deterministically from the supplied line");
      Assert (A1'Length = Line_A'Length and then B1'Length = Line_B'Length,
              "phase 552 sanitized views preserve each source line shape independently");
      Assert (Ada.Strings.Fixed.Index (A1, "Fake") = 0,
              "phase 552 sanitized view masks comment-only fake text");
      Assert (Ada.Strings.Fixed.Index (B1, "Real") /= 0,
              "phase 552 separate derived view has no retained mask from previous line");
      Assert (Line_A /= A1,
              "phase 552 sanitizer returns a transient code view and never rewrites caller text");
   end Test_Phase552_Ada_Sanitized_View_Is_Transient_And_Derived;

   procedure Test_Phase552_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Ada.Strings.Unbounded;
      Covered : constant array (Positive range 1 .. 5) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Next_Outline_Symbol,
         Editor.Commands.Command_Previous_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      D    : Editor.Commands.Command_Descriptor;
      Bind : Editor.Keybindings.Command_Keybinding_Info;
      Name : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Keybindings.Reset_To_Defaults;

      for Id of Covered loop
         D := Editor.Commands.Descriptor (Id);
         Name := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
         Assert (D.Id = Id,
                 "phase 552 descriptor keeps canonical outline command id");
         Assert (Editor.Commands.Is_Visible_In_Palette (Id),
                 "phase 552 outline command remains palette-visible without scanner payload");
         Assert (Editor.Commands.Is_Bindable_Command (Id),
                 "phase 552 outline command remains keybinding-addressable by command id only");
         Assert (not Contains_Phase552_Lexical_State_Term (To_String (Name)),
                 "phase 552 stable command name carries no lexical scanner payload");
         Assert (not Contains_Phase552_Lexical_State_Term (To_String (D.Name)),
                 "phase 552 command label carries no lexical scanner payload");
         Assert (not Contains_Phase552_Lexical_State_Term (To_String (D.Description)),
                 "phase 552 command description carries no lexical scanner payload");
         Assert (not Contains_Phase552_Lexical_State_Term (To_String (D.Target_Prompt_Label)),
                 "phase 552 command target prompt carries no lexical scanner payload");

         Bind := Editor.Keybindings.Primary_Binding_For_Command (Id);
         if Bind.Has_Binding then
            Assert (not Contains_Phase552_Lexical_State_Term (To_String (Bind.Display)),
                    "phase 552 keybinding display carries chord text only, not scanner state");
         end if;
      end loop;
   end Test_Phase552_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State;

   procedure Test_Phase552_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Snap            : Editor.Render_Model.Render_Snapshot;
      A               : Editor.Commands.Command_Availability;
      Outline_Before  : Natural;
      Panel_Before    : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Messages_Before : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Real is" & ASCII.LF &
            "   procedure Old;" & ASCII.LF &
            "end Real;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 2,
              "phase 552 boundary fixture starts from an explicit lexical-safe refresh");

      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      Editor.State.Load_Text
        (S, "-- procedure Fake_Comment;" & ASCII.LF &
            "package Changed is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   procedure New_Real;" & ASCII.LF &
            "end Changed;");

      Outline_Before := Fingerprint (S.Outline);
      Panel_Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Messages_Before := Editor.Messages.Count (S.Messages);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Commands.Is_Available (A),
              "phase 552 refresh availability remains available with an active buffer");
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "phase 552 availability does not scan changed Ada text");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "phase 552 availability does not reproject lexical-safe rows");
      Assert (Editor.Messages.Count (S.Messages) = Messages_Before,
              "phase 552 availability emits no lexical scan feedback");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Fingerprint (S.Outline) = Outline_Before,
              "phase 552 render snapshot does not run lexical scanning or refresh outline");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel) = Panel_Before,
              "phase 552 render snapshot observes existing feature-panel rows only");
      Assert (Snap.Length = Editor.State.Current_Text (S)'Length,
              "phase 552 render snapshot still reflects current buffer text without sanitizer output");
   end Test_Phase552_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan;

   procedure Test_Phase552_Ada_Workspace_Snapshot_Excludes_Lexical_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Real is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   -- package Fake_Comment is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Real;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) = 3,
              "phase 552 persistence fixture has lexical-safe outline rows before snapshot");

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "lexical") = 0,
              "phase 552 workspace debug summary excludes lexical scanner state");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "sanitized") = 0,
              "phase 552 workspace debug summary excludes sanitized source text");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "token") = 0,
              "phase 552 workspace debug summary excludes token masks");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "Fake_String") = 0,
              "phase 552 workspace snapshot does not persist source or string-literal scanner text");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "Fake_Comment") = 0,
              "phase 552 workspace snapshot does not persist comment scanner text");
   end Test_Phase552_Ada_Workspace_Snapshot_Excludes_Lexical_State;



   procedure Test_Phase552_Ada_Detection_Ignores_Non_Code_Only_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Fake_Only : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "Banner : constant String := ""procedure Hidden is"";" & ASCII.LF &
           "Text   : constant String := ""begin end package Fake;"";" & ASCII.LF &
           "-- function Hidden return Integer;",
           "scratch");
      Real_Ada : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & ASCII.LF &
           "Banner : constant String := ""procedure Hidden is"";" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "scratch");
      Fake_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Fake_Only);
      Real_Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Real_Ada);
      O : Outline_State;
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Fake_Result) = 0,
              "phase 552 extensionless Ada detection ignores comment/string-only fake declarations");
      Assert (Editor.Outline_Extractor.Item_Count (Real_Result) = 3,
              "phase 552 extensionless Ada detection still enables real declarations after non-code fakes");
      Editor.Outline_Extractor.Apply_To_Outline (Real_Result, O);
      Assert_Has_Label (O, "package Real",
              "phase 552 real extensionless package survives sanitized Ada detection");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 real extensionless procedure survives sanitized Ada detection");
   end Test_Phase552_Ada_Detection_Ignores_Non_Code_Only_Buffer;

   procedure Test_Phase552_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.CR & ASCII.LF &
           "   S : constant String := ""end Real; procedure Fake is"";" & ASCII.CR & ASCII.LF &
           "   -- package Hidden is" & ASCII.CR & ASCII.LF &
           "   procedure Run; -- function Hidden return Integer;" & ASCII.CR & ASCII.LF &
           "end Real;" & ASCII.CR,
           "crlf.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 CRLF Ada input masks strings/comments without leaking fake declarations");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 CRLF package row remains real source only");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 CRLF inline comment fake function is ignored");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Run")) = 4,
              "phase 552 CRLF source line mapping remains original and stable");
   end Test_Phase552_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code;

   procedure Test_Phase552_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      Outer : loop" & ASCII.LF &
           "         Put_Line (""end loop Outer; end Run;"");" & ASCII.LF &
           "         -- end loop Outer;" & ASCII.LF &
           "         exit;" & ASCII.LF &
           "      end loop Outer;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "labelled_loop.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 2,
              "phase 552 labelled-loop fixture extracts only real package/procedure rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "lines 2-9") /= 0,
              "phase 552 labelled loop closes from real code, not string/comment label text");
   end Test_Phase552_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code;


   procedure Test_Phase552_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String := ASCII.HT & "Package Real is -- PrOcEdUrE Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (ASCII.HT & "-- PaCkAgE Hidden is" & ASCII.LF &
           ASCII.HT & "Package Real is" & ASCII.LF &
           ASCII.HT & "   Text : constant String := ""FuNcTiOn Hidden return Integer;"";" & ASCII.LF &
           ASCII.HT & "   PrOcEdUrE Run; -- TyPe Hidden is null record;" & ASCII.LF &
           ASCII.HT & "end Real;",
           "mixed_case.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 tabbed mixed-case line preserves original length");
      Assert (Sanitized (Line'First) = ASCII.HT,
              "phase 552 leading tab in code remains code, not sanitizer output");
      Assert (Ada.Strings.Fixed.Index
                (Ada.Characters.Handling.To_Lower (Sanitized), "procedure fake") = 0,
              "phase 552 mixed-case fake declaration after comment is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 mixed-case real Ada declarations extract while non-code fakes are ignored");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 mixed-case package label normalizes from real code only");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 mixed-case procedure label normalizes from real code only");
   end Test_Phase552_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe;

   procedure Test_Phase552_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String := "C : Character := '-'; -- procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Dash_Column : constant Positive := Positive (Ada.Strings.Fixed.Index (Line, "'-'"));
      Comment_Column : constant Positive := Positive (Ada.Strings.Fixed.Index (Line, "--"));
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 dash character/comment line preserves columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Dash_Column),
              "phase 552 dash character literal is masked as non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Comment_Column),
              "phase 552 comment after dash character literal starts a real comment");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 fake declaration after character-literal comment marker is masked");
   end Test_Phase552_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment;

   procedure Test_Phase552_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           "   procedure Run" & ASCII.LF &
           "     (Name : String := ""; procedure Fake;"";" & ASCII.LF &
           "      Value : Integer);" & ASCII.LF &
           "   procedure After_Run;" & ASCII.LF &
           "end Real;",
           "string_semicolon.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 semicolon inside string does not close multi-line declaration or create fake row");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Run",
              "phase 552 split procedure remains one real row despite string semicolon text");
      Assert (Item_Line (O, 2) = 2,
              "phase 552 split procedure target remains original declaration line");
      Assert (Item_Label (O, 3) = "procedure After_Run",
              "phase 552 declaration after string-semicolon window still extracts");
   end Test_Phase552_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration;


   procedure Test_Phase552_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Operators is" & ASCII.LF &
           "   Text : constant String := ""function """"+"""" return Integer;"";" & ASCII.LF &
           "   -- function ""-"" return Integer;" & ASCII.LF &
           "   function ""+"" (Left, Right : Integer) return Integer;" & ASCII.LF &
           "   function ""and"" (Left, Right : Boolean) return Boolean; -- function Fake return Boolean;" & ASCII.LF &
           "end Operators;",
           "operators.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 552 quoted operator fakes in comments/strings do not produce rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Operators",
              "phase 552 operator fixture keeps real package body row");
      Assert_Has_Label (O, "function ""+""",
              "phase 552 real quoted operator function remains code despite string masking elsewhere");
      Assert_Has_Label (O, "function ""and""",
              "phase 552 alphabetic quoted operator function remains code");
      Assert (Item_Line (O, First_Label_Index (O, "function ""+""")) = 4,
              "phase 552 operator target line maps to original real declaration");
   end Test_Phase552_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked;

   procedure Test_Phase552_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Nul : constant Character := Character'Val (0);
      Line : constant String :=
        "Name : constant String := ""procedure" & Nul & "Fake is""; -- package Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "control.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 control-character string/comment line preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure") = 0,
              "phase 552 declaration text before embedded control character inside string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Hidden") = 0,
              "phase 552 declaration text after comment marker on control line is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 embedded control characters in non-code spans do not create fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 control-character fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 control-character fixture keeps later real procedure row");
   end Test_Phase552_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan;


   procedure Test_Phase552_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line_Empty : constant String :=
        "   Empty : constant String := """"; -- procedure Hidden;";
      Line_Adjacent : constant String :=
        "   Joined : constant String := ""package Hidden is"" & ""end Hidden;""; -- function Hidden return Integer;";
      Sanitized_Empty : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line_Empty);
      Sanitized_Adjacent : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line_Adjacent);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line_Empty & ASCII.LF &
           Line_Adjacent & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "adjacent_strings.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized_Empty'Length = Line_Empty'Length,
              "phase 552 empty-string/comment line preserves columns");
      Assert (Sanitized_Adjacent'Length = Line_Adjacent'Length,
              "phase 552 adjacent-string/comment line preserves columns");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Empty, "procedure Hidden") = 0,
              "phase 552 declaration after comment following empty string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "package Hidden") = 0,
              "phase 552 declaration text inside first adjacent string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "end Hidden") = 0,
              "phase 552 end text inside second adjacent string is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized_Adjacent, "function Hidden") = 0,
              "phase 552 declaration after adjacent-string comment is masked");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "phase 552 adjacent and empty strings do not leak fake outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 adjacent-string fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 adjacent-string fixture keeps later real procedure row");
   end Test_Phase552_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments;

   procedure Test_Phase552_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   Name : constant String := ""package Fake is; procedure Hidden;"";" & ASCII.LF &
           "   -- function Hidden return Integer;" & ASCII.LF &
           "package Real is" & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;" & ASCII.LF &
           "package body Real is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      for I in 1 .. 2 loop" & ASCII.LF &
           "         case I is" & ASCII.LF &
           "            when 1 => Put_Line (""end case; end loop; end Run;"");" & ASCII.LF &
           "            when others => null; -- end case; end loop;" & ASCII.LF &
           "         end case;" & ASCII.LF &
           "      end loop;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Real;",
           "generic_case_loop.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 5,
              "phase 552 generic formals and case/loop strings do not create fake rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert_Has_Label (O, "generic package Real",
              "phase 552 real generic package survives sanitized formal defaults");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 package-spec procedure survives sanitized generic formal lines");
      Assert_Has_Label (O, "package body Real",
              "phase 552 real package body is not confused by prior string/comment fakes");
      Assert_Has_Label (O, "procedure body Run",
              "phase 552 real procedure body is extracted after generic spec");
      Assert (Ada.Strings.Fixed.Index
                (Item_Detail (O, First_Label_Index (O, "procedure body Run")), "lines 8-16") /= 0,
              "phase 552 case/loop end tokens inside strings/comments do not truncate procedure range");
   end Test_Phase552_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text;


   procedure Test_Phase552_Ada_Double_Quote_Character_Literal_Does_Not_Start_String
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Quote_Char : constant Character := Character'Val (16#22#);
      Quote_Literal : constant String := "'" & Quote_Char & "'";
      Line : constant String :=
        "   Quote : Character := " & Quote_Literal &
        "; -- procedure Hidden; package Also_Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Real is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Run;" & ASCII.LF &
           "end Real;",
           "quote_character.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 double-quote character literal preserves columns");
      Assert (Ada.Strings.Fixed.Index (Sanitized, Quote_Literal) = 0,
              "phase 552 double-quote character literal span is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Hidden") = 0,
              "phase 552 comment after double-quote character literal masks fake procedure");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Also_Hidden") = 0,
              "phase 552 comment after double-quote character literal masks fake package");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Ada.Strings.Fixed.Index (Line, "Quote")),
              "phase 552 code before double-quote character literal remains code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Ada.Strings.Fixed.Index (Line, "procedure Hidden")),
              "phase 552 fake declaration after character-literal comment is non-code");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 double-quote character literal does not leak fake outline rows");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Real",
              "phase 552 double-quote character fixture keeps real package row");
      Assert_Has_Label (O, "procedure Run",
              "phase 552 double-quote character fixture keeps later real procedure row");
   end Test_Phase552_Ada_Double_Quote_Character_Literal_Does_Not_Start_String;


   procedure Test_Phase552_Ada_Token_Helpers_Use_Unified_Sanitized_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           "   function Semi" & ASCII.LF &
           "     return Character is (';'" & ASCII.LF &
           "     ); -- function Fake return Integer is (0);" & ASCII.LF &
           "   function Later return Integer;" & ASCII.LF &
           "end Demo;",
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "phase 552 unified token helpers ignore semicolon inside character literal and fake comment expression");
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Demo",
              "phase 552 package remains the real root row");
      Assert (Item_Label (O, 2) = "expression function Semi",
              "phase 552 character-literal semicolon does not end the split expression function early");
      Assert (Item_Label (O, 3) = "function Later",
              "phase 552 scanner resumes after the real code semicolon on the continuation line");
      Assert (Item_Line (O, 2) = 2,
              "phase 552 split expression-function target remains the declaration line");
   end Test_Phase552_Ada_Token_Helpers_Use_Unified_Sanitized_View;


   procedure Test_Phase552_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Gap : String := ""a b"";   procedure Real; -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Word_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "a b");
      String_Space_Column : constant Natural := String_Word_Column + 1;
      Code_Space_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, ";   procedure") + 1;
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Real");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Fake");
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 shared lexical mask preserves sanitized line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "a b") = 0,
              "phase 552 shared lexical mask hides string payload text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "phase 552 shared lexical mask hides trailing comment text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "phase 552 shared lexical mask preserves real code columns");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Word_Column)),
              "phase 552 code-column helper agrees that string letters are non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Space_Column)),
              "phase 552 code-column helper agrees that string spaces are non-code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Code_Space_Column)),
              "phase 552 code-column helper keeps ordinary code whitespace as code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Real_Column)),
              "phase 552 code-column helper keeps real declaration text as code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "phase 552 code-column helper masks fake declaration text in comments");
   end Test_Phase552_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer;


   procedure Test_Phase552_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Whole : constant String :=
        "prefix procedure Real; -- procedure Fake;";
      Line : constant String := Whole (8 .. Whole'Last);
      Empty : constant String := "";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Fake_Index : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Fake_Column : constant Positive :=
        Positive (Fake_Index - Line'First + 1);
   begin
      Assert (Sanitized'First = Line'First
                and then Sanitized'Last = Line'Last,
              "phase 552 sanitizer preserves non-1-based slice bounds");
      Assert (Sanitized'Length = Line'Length,
              "phase 552 sanitizer preserves non-1-based slice length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Line'First,
              "phase 552 non-1-based sanitized slice keeps real code at original index");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 non-1-based sanitized slice masks comment fake declaration");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column (Line, 1),
              "phase 552 code-column helper treats column one of a slice as source column one");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Fake_Column),
              "phase 552 code-column helper masks fake declaration in non-1-based slices");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column (Empty, 1),
              "phase 552 code-column helper returns false for empty lines");
      Assert (Editor.Ada_Syntax_Core.Sanitize_Line (Empty)'Length = 0,
              "phase 552 sanitizer accepts empty lines without stored state");
   end Test_Phase552_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines;



   procedure Test_Phase552_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Image : constant String := Integer'Image (Value) & Character'Val (16#2D#); -- procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Attribute_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Integer'Image");
      Qualified_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Character'Val");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (Line & ASCII.LF &
           "procedure Real;" & ASCII.LF &
           "package Also_Real is end Also_Real;");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Integer'Image") = Attribute_Column,
              "phase 552 attribute apostrophe remains code in sanitized text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Character'Val") = Qualified_Column,
              "phase 552 qualified-name apostrophe remains code in sanitized text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 fake declaration after attribute/qualified expression comment is masked");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Attribute_Column)),
              "phase 552 code-column helper keeps attribute prefix as code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Qualified_Column)),
              "phase 552 code-column helper keeps qualified literal helper as code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "phase 552 code-column helper masks comment text after qualified expression");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "phase 552 attribute/qualified expression comments do not create fake outline rows");
      Assert_Has_Label (O, "procedure Real",
              "phase 552 real declaration after attribute/qualified expression still extracts");
      Assert_Has_Label (O, "package Also_Real",
              "phase 552 following real package still extracts after apostrophe-heavy line");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 2,
              "phase 552 real declaration target line remains mapped after apostrophe-heavy line");
   end Test_Phase552_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code;


   procedure Test_Phase552_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : constant String :=
        "   Pair : String := 'A' & 'B' & Character'Val (16#2D#); -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      First_Char_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "'A'");
      Second_Char_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "'B'");
      Join_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "& 'B'");
      Qualified_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "Character'Val");
      Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          (Line & ASCII.LF &
           "procedure Real;" & ASCII.LF &
           "package Later is end Later;",
           "adjacent_character_literals.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
      O : Outline_State;
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 adjacent character literals preserve line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "'A'") = 0,
              "phase 552 first adjacent character literal is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "'B'") = 0,
              "phase 552 second adjacent character literal is masked independently");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Character'Val") = Qualified_Column,
              "phase 552 qualified attribute-like call remains code after character literals");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "phase 552 trailing comment after adjacent character literals is masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (First_Char_Column)),
              "phase 552 first character literal is non-code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Second_Char_Column)),
              "phase 552 second character literal is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Join_Column)),
              "phase 552 code between adjacent character literals remains code");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Qualified_Column)),
              "phase 552 qualified-name apostrophe remains code after adjacent literals");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "phase 552 fake declaration in trailing comment remains non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 3,
              "phase 552 adjacent character literals and trailing comments do not create fake outline rows");
      Assert_Has_Label (O, "procedure Real",
              "phase 552 real procedure after adjacent character literals still extracts");
      Assert_Has_Label (O, "package Later",
              "phase 552 following package after adjacent character literals still extracts");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 2,
              "phase 552 target mapping survives adjacent character literal line");
   end Test_Phase552_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code;

   procedure Test_Phase552_Ada_Character_String_Comment_Sequence_Uses_One_Line_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Quote_Char : constant Character := Character'Val (16#22#);
      Quote_Literal : constant String := "'" & Quote_Char & "'";
      Line : constant String :=
        "   Q : Character := " & Quote_Literal &
        "; S : constant String := ""procedure Fake is""; -- package Hidden is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Character_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, Quote_Literal);
      String_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Comment_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "package Hidden");
      Second_Object_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Line, "S : constant");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Demo is" & ASCII.LF &
           Line & ASCII.LF &
           "   procedure Real;" & ASCII.LF &
           "end Demo;",
           "character_string_comment_sequence.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 character/string/comment sequence preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, Quote_Literal) = 0,
              "phase 552 double-quote character literal is masked before later string");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 later string payload is masked after character literal");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Hidden") = 0,
              "phase 552 trailing comment is masked after character and string spans");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "S : constant") = Second_Object_Column,
              "phase 552 scanner resumes code between character literal and string literal");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Character_Column)),
              "phase 552 character literal remains non-code in mixed sequence");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Column)),
              "phase 552 string payload remains non-code in mixed sequence");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Column)),
              "phase 552 trailing comment remains non-code in mixed sequence");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Second_Object_Column)),
              "phase 552 object code between masked spans remains code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 4,
              "phase 552 mixed character/string/comment line does not create fake outline rows");
      Assert (Item_Label (O, 1) = "package Demo",
              "phase 552 mixed sequence keeps real package row");
      Assert_Has_Label (O, "procedure Real",
              "phase 552 mixed sequence keeps later real procedure row");
      Assert (Item_Line (O, First_Label_Index (O, "procedure Real")) = 3,
              "phase 552 mixed sequence preserves later target line mapping");
   end Test_Phase552_Ada_Character_String_Comment_Sequence_Uses_One_Line_State;


   procedure Test_Phase552_Ada_Comment_Quotes_And_Chars_Are_Line_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line : constant String :=
        "      Flag := True; -- ""end Run;"" 'P' procedure Fake;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Flag_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Flag");
      Quote_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "end Run");
      Char_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "'P'");
      Fake_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure Fake");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           Line & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;",
           "comment_quote_character_line_local.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 comment with quotes/chars preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Flag") = Flag_Column,
              "phase 552 code before comment remains visible before quoted comment text");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "end Run") = 0,
              "phase 552 quoted close text inside comments remains non-code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 declaration-like text after quoted comment text remains masked");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Flag_Column)),
              "phase 552 code-column helper preserves code before comment quote text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Quote_Column)),
              "phase 552 quote-delimited text inside a comment is not string-state code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Char_Column)),
              "phase 552 character-looking text inside a comment remains comment text");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Fake_Column)),
              "phase 552 fake declaration after comment quote/char text remains non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 552 quoted/comment character text does not create fake outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "phase 552 package body remains the first real row");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "phase 552 procedure body remains the only nested real row");
      Assert (Item_Detail (O, 2) = "lines 2-6 body",
              "phase 552 commented quoted end text does not close the procedure range early");
   end Test_Phase552_Ada_Comment_Quotes_And_Chars_Are_Line_Local;


   procedure Test_Phase552_Ada_Structure_Normalization_Reapplies_Code_Only_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Line : constant String :=
        "      Text : constant String := ""Inner: begin""; -- Hidden: loop";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Label_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Inner: begin");
      Comment_Label_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "Hidden: loop");
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "   begin" & ASCII.LF &
           Line & ASCII.LF &
           "      Inner : declare" & ASCII.LF &
           "      begin" & ASCII.LF &
           "         null;" & ASCII.LF &
           "      end Inner;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Demo;",
           "structure_normalization_code_only.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Sanitized'Length = Line'Length,
              "phase 552 structure-normalization fixture preserves line length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Inner: begin") = 0,
              "phase 552 label-like begin text inside strings is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "Hidden: loop") = 0,
              "phase 552 label-like loop text inside comments is masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (String_Label_Column)),
              "phase 552 string label-like structure text is non-code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Comment_Label_Column)),
              "phase 552 comment label-like structure text is non-code");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Count (O) = 2,
              "phase 552 label-like non-code structure text creates no fake outline rows");
      Assert (Item_Label (O, 1) = "package body Demo",
              "phase 552 structure-normalization fixture keeps package body row");
      Assert (Item_Label (O, 2) = "procedure body Run",
              "phase 552 structure-normalization fixture keeps procedure body row");
      Assert (Item_Detail (O, 2) = "lines 2-9 body",
              "phase 552 normalized structure scan ignores label-like string/comment text");
   end Test_Phase552_Ada_Structure_Normalization_Reapplies_Code_Only_View;


   procedure Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "S : constant String := ""procedure Fake" & ASCII.LF &
        "procedure Real; -- function Fake return Integer;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      String_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Fake");
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "phase 552 multi-line public sanitizer preserves length");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 unterminated string text before embedded line break is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "phase 552 public sanitizer resets string state after embedded line break");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Fake") = 0,
              "phase 552 trailing comment after embedded line break remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (String_Fake_Column)),
              "phase 552 string text before embedded line break is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "phase 552 code after embedded line break is code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "phase 552 comment text after embedded line break is non-code by column helper");
   end Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break;


   procedure Test_Phase552_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "S : constant String := ""procedure Fake" & ASCII.CR & ASCII.LF &
        "procedure Real; -- function Fake return Integer;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      CR_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, String'(1 => ASCII.CR));
      LF_Column : constant Natural := CR_Column + 1;
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "phase 552 CRLF public sanitizer preserves length");
      Assert (CR_Column > 0 and then LF_Column <= Multi_Line'Length,
              "phase 552 CRLF fixture contains adjacent CRLF boundary");
      Assert (Sanitized (Sanitized'First + CR_Column - 1) = ' ',
              "phase 552 CR in direct helper input is non-code");
      Assert (Sanitized (Sanitized'First + LF_Column - 1) = ' ',
              "phase 552 LF in direct helper input is non-code");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 pre-CRLF unterminated string text is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "phase 552 scanning resumes after CRLF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Fake") = 0,
              "phase 552 trailing comment after CRLF remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (CR_Column)),
              "phase 552 CR boundary is non-code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (LF_Column)),
              "phase 552 LF boundary is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "phase 552 code after CRLF boundary is code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "phase 552 comment after CRLF boundary is non-code by column helper");
   end Test_Phase552_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary;




   procedure Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Multi_Line : constant String :=
        "procedure Real; -- procedure Fake;" & ASCII.LF &
        "function Later return Integer; -- package Fake is";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Multi_Line);
      LF_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, String'(1 => ASCII.LF));
      Real_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Real");
      Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "procedure Fake");
      Later_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "function Later");
      Later_Comment_Fake_Column : constant Natural :=
        Ada.Strings.Fixed.Index (Multi_Line, "package Fake");
   begin
      Assert (Sanitized'Length = Multi_Line'Length,
              "phase 552 multi-line comment public sanitizer preserves length");
      Assert (LF_Column > 0,
              "phase 552 comment-state fixture contains embedded LF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Real") = Real_Column,
              "phase 552 code before first comment remains visible");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "procedure Fake") = 0,
              "phase 552 comment before embedded line break is masked");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "function Later") = Later_Column,
              "phase 552 scanning resumes after comment-line LF boundary");
      Assert (Ada.Strings.Fixed.Index (Sanitized, "package Fake") = 0,
              "phase 552 second-line trailing comment remains masked");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (LF_Column)),
              "phase 552 LF after comment line is non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Real_Column)),
              "phase 552 first-line real declaration remains code by column helper");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Comment_Fake_Column)),
              "phase 552 first-line comment declaration remains non-code by column helper");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Later_Column)),
              "phase 552 second-line code is visible after comment reset");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Multi_Line, Positive (Later_Comment_Fake_Column)),
              "phase 552 second-line comment declaration remains non-code by column helper");
   end Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break;


   procedure Test_Phase579_Ada_Record_Component_Fields_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Point is record" & ASCII.LF &
           "      X : Integer;" & ASCII.LF &
           "      Y, Z : Integer := 0;" & ASCII.LF &
           "      case Has_Label is" & ASCII.LF &
           "         when True =>" & ASCII.LF &
           "            Label : Natural;" & ASCII.LF &
           "         when False =>" & ASCII.LF &
           "            null;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "record field extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "package, variant record type, and component rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package Model", "package row remains first");
      Assert (Item_Label (O, 2) = "variant record type Point", "variant record type row is preserved");
      Assert (Item_Label (O, 3) = "field X", "single component row extracted");
      Assert (Item_Label (O, 4) = "field Y", "first multi-name component row extracted");
      Assert (Item_Label (O, 5) = "field Z", "second multi-name component row extracted");
      Assert (Item_Label (O, 6) = "field Label", "variant component row extracted");
      Assert (Item_Kind (O, 3) = Outline_Field, "component uses field kind");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "component depth is nested under record type");
      Assert (Item_Detail (O, 3) = "line 3 component",
              "component detail identifies record component form");
      Assert (Item_Target_Kind (O, 3) = Buffer_Position_Target,
              "component row navigates to source position");
   end Test_Phase579_Ada_Record_Component_Fields_Are_Extracted;

   procedure Test_Phase579_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Choice is record" & ASCII.LF &
           "      -- Fake : Integer;" & ASCII.LF &
           "      Text : String := ""not : a field;"";" & ASCII.LF &
           "      when_flag : Boolean;" & ASCII.LF &
           "      case Kind is" & ASCII.LF &
           "         when others =>" & ASCII.LF &
           "            null;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "record field extraction with non-code fakes succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "only package, record type, and real component rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 3) = "field Text",
              "field with string-literal punctuation is extracted once");
      Assert (Item_Label (O, 4) = "field when_flag",
              "identifier containing keyword text is still a component");
   end Test_Phase579_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines;


   procedure Test_Phase579_Ada_Enumeration_Literals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type Color is (Red, Green, Blue);" & ASCII.LF &
           "   type Mode is" & ASCII.LF &
           "     (Fast," & ASCII.LF &
           "      Slow);" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "enumeration literal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 8,
              "package, enum types, and literal rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "enum type Color",
              "single-line enumeration type label is explicit");
      Assert (Item_Label (O, 3) = "literal Red",
              "first literal row is extracted");
      Assert (Item_Label (O, 5) = "literal Blue",
              "last single-line literal row is extracted");
      Assert (Item_Label (O, 6) = "enum type Mode",
              "split enumeration type label is explicit");
      Assert (Item_Label (O, 7) = "literal Fast",
              "split first literal row is extracted");
      Assert (Item_Label (O, 8) = "literal Slow",
              "split final literal row is extracted");
      Assert (Item_Kind (O, 3) = Outline_Enum_Literal,
              "literal row uses enum literal kind");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "literal depth is nested under enumeration type");
      Assert (Item_Detail (O, 3) = "line 2 enumeration",
              "literal detail identifies enumeration form");
   end Test_Phase579_Ada_Enumeration_Literals_Are_Extracted;

   procedure Test_Phase579_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   Limit : constant Natural := 10;" & ASCII.LF &
           "   Parse_Error, Read_Error : exception;" & ASCII.LF &
           "   type Point is record" & ASCII.LF &
           "      X : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "package exception and constant extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "package, constant, split exceptions, record, and field rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "constant Limit",
              "package constant row is extracted");
      Assert (Item_Label (O, 3) = "exception Parse_Error",
              "first exception declaration row is extracted");
      Assert (Item_Label (O, 4) = "exception Read_Error",
              "second exception declaration row is extracted");
      Assert (Item_Kind (O, 2) = Outline_Object,
              "constant row uses object kind");
      Assert (Item_Kind (O, 3) = Outline_Exception,
              "exception row uses exception kind");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "constant") /= 0,
              "constant detail identifies declaration form");
      Assert (Item_Detail (O, 3) = "line 3 exception",
              "exception detail identifies declaration form");
   end Test_Phase579_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted;



   procedure Test_Phase579_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   Count : Natural := 0;" & ASCII.LF &
           "   Alias : Natural renames Count;" & ASCII.LF &
           "   type Kind is (Small, Medium);" & ASCII.LF &
           "   type Item (K : Kind; Size : Natural := 0) is record" & ASCII.LF &
           "      Name : Natural;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   type Token is ('A', 'Z');" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "object/discriminant/character-literal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 13,
              "package, objects, enum literals, discriminants, field, and char literals are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "object Count",
              "package-level variable object row is extracted");
      Assert (Item_Label (O, 3) = "object Alias renames",
              "package-level object renaming row is extracted");
      Assert (Item_Detail (O, 2) = "line 2 object default-expression",
              "ordinary object detail identifies object form");
      Assert (Item_Detail (O, 3) = "line 3 renames",
              "object renaming detail identifies renames form");
      Assert (Item_Label (O, 7) = "record type Item",
              "discriminated record type row is preserved");
      Assert (Item_Label (O, 8) = "discriminant K",
              "first discriminant row is extracted");
      Assert (Item_Label (O, 9) = "discriminant Size",
              "second discriminant row is extracted");
      Assert (Item_Label (O, 10) = "field Name",
              "record component after discriminants is still extracted");
      Assert (Item_Kind (O, 8) = Outline_Discriminant,
              "discriminant row uses discriminant kind");
      Assert (Item_Depth (O, 8) = Item_Depth (O, 7) + 1,
              "discriminant depth is nested under record type");
      Assert (Item_Detail (O, 8) = "line 5 discriminant",
              "discriminant detail identifies declaration form");
      Assert (Item_Label (O, 11) = "enum type Token",
              "character literal enumeration type is extracted");
      Assert (Item_Label (O, 12) = "literal 'A'",
              "first character literal enumeration row is extracted");
      Assert (Item_Label (O, 13) = "literal 'Z'",
              "second character literal enumeration row is extracted");
   end Test_Phase579_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted;

   procedure Test_Phase579_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Model is" & ASCII.LF &
           "   Public_State : Natural;" & ASCII.LF &
           "   for Public_State'Address use System'To_Address (0);" & ASCII.LF &
           "   procedure Run is" & ASCII.LF &
           "      Local_State : Natural := 0;" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "object scanner with local and representation lines succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "only package body, package-level object, and procedure body rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package body Model",
              "package body row remains first");
      Assert (Item_Label (O, 2) = "object Public_State",
              "package-body declarative object row is extracted");
      Assert (Item_Label (O, 3) = "procedure body Run",
              "procedure body row remains extracted");
   end Test_Phase579_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines;


   procedure Test_Phase579_Ada_Representation_Clauses_Are_Detail_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package Model is" & ASCII.LF &
           "   type R is record" & ASCII.LF &
           "      A : Integer;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   for R use record" & ASCII.LF &
           "      A at 0 range 0 .. 31;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   State : Integer;" & ASCII.LF &
           "   for State'Address use System'To_Address (0);" & ASCII.LF &
           "end Model;" & ASCII.LF,
           "model.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "representation metadata extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 4,
              "representation clauses do not create standalone outline rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "record type R",
              "record type row remains parser-owned");
      Assert (Item_Detail (O, 2) = "lines 2-4 record",
              "record type detail carries its source range");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "representation") /= 0,
              "record component detail carries representation metadata");
      Assert (Item_Label (O, 4) = "object State",
              "object row remains extracted after representation record");
      Assert (Item_Detail (O, 4) = "line 8 object representation",
              "object detail carries address representation metadata");
   end Test_Phase579_Ada_Representation_Clauses_Are_Detail_Metadata;


   procedure Test_Phase579_Ada_Generic_Formals_Are_Extracted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "   Capacity : Positive := 10;" & ASCII.LF &
           "   with function ""<"" (Left, Right : Element) return Boolean;" & ASCII.LF &
           "   with procedure Visit (Item : Element);" & ASCII.LF &
           "   with package IO is new Ada.Text_IO.Integer_IO (Integer);" & ASCII.LF &
           "package Model.Generic_Box is" & ASCII.LF &
           "end Model.Generic_Box;" & ASCII.LF,
           "model-generic.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "generic formal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 6,
              "formal type/object/subprogram/package rows and generic package row are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "formal type row is extracted");
      Assert (Item_Label (O, 2) = "formal object Capacity",
              "formal object row is extracted");
      Assert (Item_Label (O, 3) = "formal function ""<""",
              "formal operator function row is extracted");
      Assert (Item_Label (O, 4) = "formal procedure Visit",
              "formal procedure row is extracted");
      Assert (Item_Label (O, 5) = "formal package IO",
              "formal package row is extracted");
      Assert (Item_Label (O, 6) = "generic package Model.Generic_Box",
              "generic package row still follows formals");
      Assert (Item_Kind (O, 1) = Outline_Generic_Formal,
              "formal rows use generic formal kind");
      Assert (Item_Detail (O, 1) = "line 2 generic formal type",
              "formal type detail identifies generic-formal type");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "generic formal function") /= 0,
              "formal function detail identifies generic-formal function");
   end Test_Phase579_Ada_Generic_Formals_Are_Extracted;

   procedure Test_Phase579_Ada_Generic_Formal_Continuations_Are_Not_Duplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is" & ASCII.LF &
           "      private;" & ASCII.LF &
           "   with function Render" & ASCII.LF &
           "     (Item : Element) return String;" & ASCII.LF &
           "package Model.Box is" & ASCII.LF &
           "end Model.Box;" & ASCII.LF,
           "box.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "split generic formal extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 3,
              "only first formal lines and the generic package row are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal type Element",
              "split formal type is represented by its leading line");
      Assert (Item_Label (O, 2) = "formal function Render",
              "split formal function is represented by its leading line");
      Assert (Item_Label (O, 3) = "generic package Model.Box",
              "generic package row is preserved after split formals");
   end Test_Phase579_Ada_Generic_Formal_Continuations_Are_Not_Duplicated;





   procedure Test_Phase579_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("package body Demo is" & ASCII.LF &
           "   abstract procedure Hook;" & ASCII.LF &
           "   overriding procedure Run;" & ASCII.LF &
           "   not overriding function Make return Natural;" & ASCII.LF &
           "   procedure Stop is null;" & ASCII.LF &
           "   function ""+"" (Left, Right : Natural) return Natural;" & ASCII.LF &
           "   separate (Demo) procedure Worker is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.adb");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada abstract/null/operator/subunit extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "package body, abstract/overriding/null/operator/subunit rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 2) = "procedure Hook",
              "abstract procedure prefix does not hide the procedure row");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 2), "abstract") /= 0,
              "abstract procedure metadata is retained in outline details");
      Assert (Item_Label (O, 3) = "procedure Run",
              "overriding procedure prefix is stripped from the outline label");
      Assert (Item_Label (O, 4) = "function Make",
              "not-overriding function prefix is stripped from the outline label");
      Assert (Item_Label (O, 5) = "procedure body Stop",
              "null procedure declaration is retained as a body-like procedure row");
      Assert (Item_Label (O, 6) = "function ""+""",
              "operator function names are retained as quoted operator labels");
      Assert (Item_Label (O, 7) = "procedure body Worker",
              "same-line separate subprogram body is extracted as a body row");
      Assert (Item_Kind (O, 6) = Outline_Function,
              "operator function row uses function kind");
      Assert (Item_Detail (O, 7) = "lines 7-10 body",
              "separate subprogram body receives a closed body range");
   end Test_Phase579_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators;

   procedure Test_Phase579_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("private package A.B.C is" & ASCII.LF &
           "   task type Worker is" & ASCII.LF &
           "      entry Start;" & ASCII.LF &
           "   end Worker;" & ASCII.LF &
           "   protected type Guard is" & ASCII.LF &
           "      entry Lock;" & ASCII.LF &
           "   end Guard;" & ASCII.LF &
           "   package Numbers is new Ada.Text_IO.Integer_IO (Integer);" & ASCII.LF &
           "   procedure Visit is new Generic_Visit;" & ASCII.LF &
           "end A.B.C;" & ASCII.LF,
           "a-b-c.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada child package/task/protected/instantiation extraction succeeds");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "child package, task/protected entries, and instantiation rows are extracted");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "package A.B.C",
              "private child package declaration keeps its qualified package name");
      Assert (Item_Label (O, 2) = "task type Worker",
              "task type row is extracted");
      Assert (Item_Label (O, 3) = "entry Start",
              "task entry declaration row is extracted");
      Assert (Item_Label (O, 4) = "protected type Guard",
              "protected type row is extracted");
      Assert (Item_Label (O, 5) = "entry Lock",
              "protected entry declaration row is extracted");
      Assert (Item_Label (O, 6) = "package Numbers",
              "generic package instantiation row is extracted");
      Assert (Item_Label (O, 7) = "procedure Visit",
              "generic procedure instantiation row is extracted");
      Assert (Item_Detail (O, 6) = "line 8 instantiation generic-actuals",
              "package instantiation detail is explicit");
      Assert (Item_Detail (O, 7) = "line 9 instantiation is new Generic_Visit",
              "procedure instantiation detail is explicit");
      Assert (Item_Depth (O, 3) = Item_Depth (O, 2) + 1,
              "task entry is nested under the task type");
      Assert (Item_Depth (O, 5) = Item_Depth (O, 4) + 1,
              "protected entry is nested under the protected type");
   end Test_Phase579_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages;



   procedure Test_Phase707_Ada_Outline_Precision_For_Expanded_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with package Formal is new Generic_Formal (<>);" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type Shape (Kind : Natural) is record" & ASCII.LF &
           "      case Kind is" & ASCII.LF &
           "         when 0 => null;" & ASCII.LF &
           "         when others => Value : Integer;" & ASCII.LF &
           "      end case;" & ASCII.LF &
           "   end record;" & ASCII.LF &
           "   protected type Gate is" & ASCII.LF &
           "      entry Slot (Positive range <>) when Ready;" & ASCII.LF &
           "   end Gate;" & ASCII.LF &
           "   Local_Error : exception;" & ASCII.LF &
           "end Demo;" & ASCII.LF &
           "package body Demo is separate;" & ASCII.LF,
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "pass 707 outline extraction succeeds for expanded Ada constructs");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 9,
              "pass 707 outline keeps formal package, variant record, variant field, entry family, exception, and stub rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal package Formal",
              "formal package rows remain first-class generic formal outline rows");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 1), "generic formal package") /= 0,
              "formal package detail is specific rather than a generic formal blob");
      Assert (Item_Label (O, 3) = "variant record type Shape",
              "variant record type label exposes variant-record metadata");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 3), "variant-record") /= 0,
              "variant record detail retains structural metadata");
      Assert (Item_Label (O, 7) = "entry family Slot",
              "entry-family declarations are distinct from ordinary entries in Outline");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 7), "entry-family") /= 0,
              "entry-family detail is retained for filtering and inspection");
      Assert (Item_Label (O, 8) = "exception Local_Error",
              "exception declarations remain visible outline rows");
      Assert (Item_Label (O, 9) = "package body Demo",
              "body stubs keep the package-body label instead of degrading to unknown");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 9), "body-stub") /= 0,
              "body-stub detail is visible to Outline without semantic compilation");
   end Test_Phase707_Ada_Outline_Precision_For_Expanded_Constructs;




   procedure Test_Phase721_Ada_Outline_Type_Family_Label_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   with type Formal_Vector is array (Positive range <>) of Integer;" & ASCII.LF &
           "   with type Formal_Callback is access function return Integer;" & ASCII.LF &
           "package Demo is" & ASCII.LF &
           "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
           "   type Link is access all Integer;" & ASCII.LF &
           "   type Callback is access function return Integer;" & ASCII.LF &
           "   type Child is new Parent with private;" & ASCII.LF &
           "end Demo;" & ASCII.LF,
           "demo.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Assert (Editor.Outline_Extractor.Status (Result) =
                Editor.Outline_Extractor.Extraction_Ok,
              "pass 721 outline extraction succeeds for expanded type families");
      Assert (Editor.Outline_Extractor.Item_Count (Result) = 7,
              "pass 721 outline keeps formal type rows and package type rows");

      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Assert (Item_Label (O, 1) = "formal array type Formal_Vector",
              "formal array type label exposes array metadata");
      Assert (Item_Label (O, 2) = "formal access subprogram type Formal_Callback",
              "formal access-to-subprogram type label exposes callable access metadata");
      Assert (Item_Label (O, 4) = "array type Vector",
              "array type label exposes array metadata");
      Assert (Item_Label (O, 5) = "access type Link",
              "access object type label exposes access metadata");
      Assert (Item_Label (O, 6) = "access subprogram type Callback",
              "access-to-subprogram type label exposes callable access metadata");
      Assert (Item_Label (O, 7) = "private extension type Child",
              "private extension type label exposes derived private-extension metadata");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 4), "array") /= 0,
              "array metadata remains in detail for filtering");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 6), "access-subprogram") /= 0,
              "access-subprogram metadata remains in detail for filtering");
      Assert (Ada.Strings.Fixed.Index (Item_Detail (O, 7), "private-extension") /= 0,
              "private-extension metadata remains in detail for filtering");
   end Test_Phase721_Ada_Outline_Type_Family_Label_Precision;


   procedure Test_Phase579_Outline_Freshness_Is_Queryable_After_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 579,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Source_Buffer_Token (O) = 579,
              "accepted outline records source buffer token");
      Assert (Source_Buffer_Revision (O) = 1,
              "accepted outline records source buffer revision");
      Assert (Is_Current_For_Buffer (O, 579, 1),
              "accepted outline is current for matching buffer identity");

      Mark_For_Buffer_Change (O);

      Assert (Item_Count (O) > 0,
              "edit freshness marking preserves rows for display");
      Assert (not Is_Current_For_Buffer (O, 579, 1),
              "stale outline is not current even for old revision");
      Assert (Is_Stale_For_Buffer (O, 579, 2),
              "stale outline is queryable against the edited revision");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "edit freshness marking records stale outline status");
   end Test_Phase579_Outline_Freshness_Is_Queryable_After_Edit;

   procedure Test_Phase579_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 901,
         Buffer_Revision      => 7,
         Lifecycle_Generation => 3,
         Request_Token        => Next_Request_Token (O));

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Freshness_For_Active_Buffer (O, 901, 7) = Outline_Current,
              "matching active buffer and revision is current");
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Stale,
              "same active buffer with newer revision is stale");
      Assert (Freshness_For_Active_Buffer (O, 902, 7) = Outline_Unavailable,
              "different active buffer is not falsely current");

      Mark_For_Buffer_Change (O);
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Stale,
              "edited source remains stale until refresh");

      Reset_Outline_For_Buffer_Close (O, 901);
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Unavailable,
              "closed source buffer makes outline unavailable");
   end Test_Phase579_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer;

   procedure Test_Phase579_Outline_Reload_And_Revert_Clear_Freshness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Phase579_Temp_Path ("reload_revert.adb");
      Disk_Text : constant String :=
        "package Demo is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "end Demo;";
      Disk_Replacement : constant String :=
        "package Demo is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "   procedure Stop;" & ASCII.LF &
        "end Demo;";
   begin
      Phase579_Remove_If_Exists (Path);
      Phase579_Write_Text (Path, Disk_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) > 0,
              "phase 579 reload setup refreshes a real Ada outline");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "phase 579 reload setup outline is current before file replacement");

      Phase579_Write_Text (Path, Disk_Replacement);
      Editor.Executor.Execute_Reload_Active_Buffer (S);
      Assert (Editor.State.Current_Text (S) = Disk_Replacement,
              "phase 579 reload replaces text from disk");
      Assert (Item_Count (S.Outline) = 0,
              "phase 579 reload clears previously accepted outline rows");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "phase 579 reload makes outline unavailable until explicit refresh");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "phase 579 outline can be refreshed current again after reload");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "phase 579 dirty-buffer outline can be current before revert");

      Editor.Executor.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "phase 579 revert creates an explicit destructive confirmation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (Editor.State.Current_Text (S) = Disk_Replacement,
              "phase 579 revert restores disk text after confirmation");
      Assert (Item_Count (S.Outline) = 0,
              "phase 579 revert clears previously accepted outline rows");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "phase 579 revert makes outline unavailable until explicit refresh");

      Phase579_Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Phase579_Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase579_Outline_Reload_And_Revert_Clear_Freshness;

   procedure Test_Phase579_Close_Buffer_Blocks_Selected_Row_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) > 0,
              "phase 579 close-buffer setup has outline rows");
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Reset_Outline_For_Buffer_Close (S.Outline, S.Active_Buffer_Token);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable
                or else Result.Status = Editor.Executor.Command_No_Op,
              "phase 579 closed-buffer outline navigation is blocked");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "phase 579 closed-buffer outline navigation does not move caret");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "phase 579 closed-buffer outline is unavailable");
   end Test_Phase579_Close_Buffer_Blocks_Selected_Row_Navigation;

   procedure Test_Phase579_Next_Previous_Boundaries_Can_Report_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 57918,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Find_Next_Symbol_For_Position (O, 57918, 4, 1, Wrap => False) = 0,
              "phase 579 next symbol can report unavailable after the last row");
      Assert (Find_Previous_Symbol_For_Position (O, 57918, 1, 1, Wrap => False) = 0,
              "phase 579 previous symbol can report unavailable before the first row");
      Assert (Find_Next_Symbol_For_Position (O, 57918, 4, 1, Wrap => True) /= 0,
              "phase 579 next symbol still supports explicit wrap semantics");
      Assert (Find_Previous_Symbol_For_Position (O, 57918, 1, 1, Wrap => True) /= 0,
              "phase 579 previous symbol still supports explicit wrap semantics");
   end Test_Phase579_Next_Previous_Boundaries_Can_Report_Unavailable;

   procedure Test_Phase579_Filtered_Selection_Clamps_At_Visible_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Alpha;" & ASCII.LF &
            "   procedure Beta;" & ASCII.LF &
            "   procedure Gamma;" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Apply_Filter (S.Outline, "Beta");
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "phase 579 filter reduces outline projection to one visible row");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "phase 579 filtered outline selects the only visible row");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "phase 579 select-next clamps at filtered end");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Previous_Outline_Item);
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "phase 579 select-previous clamps at filtered beginning");

      Clear_Filter (S.Outline);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) >= 4,
              "phase 579 clear filter restores full outline projection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) /= 0,
              "phase 579 clear filter leaves a deterministic selection");
   end Test_Phase579_Filtered_Selection_Clamps_At_Visible_Bounds;

   procedure Register_Tests (T : in out Outline_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Phase204_Outline_Contract_Review_Default_Passes'Access,
         "phase 204 outline contract review default passes");
      Register_Routine
        (T, Test_Phase204_Outline_Contract_Review_Is_Side_Effect_Free'Access,
         "phase 204 outline contract review is side-effect-free");
      Register_Routine
        (T, Test_Phase204_Outline_Contract_Review_Feedback_Is_Deterministic'Access,
         "phase 204 outline contract review feedback is deterministic");
      Register_Routine
        (T, Test_Phase204_Open_Selected_Rejects_Out_Of_Range_Target'Access,
         "phase 204 outline open selected rejects out-of-range target");
      Register_Routine
        (T, Test_Phase531_Ada_Outline_Extracts_Subtype_And_Navigates'Access,
         "phase 531 Ada outline extracts subtype and navigates");
      Register_Routine
        (T, Test_Phase531_Empty_States_Are_Display_Only'Access,
         "phase 531 outline empty states are display-only");
      Register_Routine
        (T, Test_Phase531_Outline_Display_States_Are_Clear'Access,
         "phase 531 outline display states are clear");
      Register_Routine
        (T, Test_Phase531_Show_Outline_No_Active_Buffer_State'Access,
         "phase 531 show outline projects no-active-buffer state");
      Register_Routine (T, Test_Synthetic_Items_Are_Deterministic'Access,
                        "synthetic outline fixture items are deterministic");
      Register_Routine (T, Test_Projection_To_Feature_Panel'Access,
                        "outline projects to feature-panel rows");
      Register_Routine (T, Test_Summary_Debug_And_Clear_Invariants'Access,
                        "outline summaries, debug text, and reset invariants");
      Register_Routine (T, Test_Command_Metadata_And_Stable_Names'Access,
                        "outline command metadata and stable names");
      Register_Routine (T, Test_Command_Execution_And_Availability'Access,
                        "outline command execution and availability");
      Register_Routine (T, Test_Show_And_Focus_Availability'Access,
                        "outline show/focus availability is canonical");
      Register_Routine (T, Test_Open_Selected_Navigates_To_Buffer_Target'Access,
                        "open selected outline item navigates to buffer target");
      Register_Routine (T, Test_Open_Selected_Requires_Live_Outline_Row'Access,
                        "open selected outline requires a live outline row");
      Register_Routine (T, Test_Clear_Feature_Panel_Does_Not_Clear_Outline'Access,
                        "generic clear feature panel does not clear outline");
      Register_Routine (T, Test_Availability_Is_Side_Effect_Free'Access,
                        "outline availability is side-effect-free");
      Register_Routine (T, Test_Separation_From_Project_Reset_Settings_And_Keybindings'Access,
                        "outline separates from settings/keybindings and resets with project scope");
      Register_Routine (T, Test_Phase121_Refresh_Replaces_And_Clears_Selection'Access,
                        "phase 121 refresh replaces placeholders and clears selection");
      Register_Routine (T, Test_Phase121_Clear_Versus_Feature_Panel_Clear'Access,
                        "phase 121 clear outline differs from clear feature panel");
      Register_Routine (T, Test_Phase121_Selection_Mapping_Rejects_Stale_Generic_Row'Access,
                        "phase 121 selection mapping rejects stale generic rows");
      Register_Routine (T, Test_Phase121_Project_Summary_Exposes_Outline_Workflow'Access,
                        "phase 121 summaries expose outline workflow state");
      Register_Routine (T, Test_Phase122_Refresh_Seam_Status_And_Unsupported_Sources'Access,
                        "phase 122 refresh seam reports status and rejects unsupported sources");
      Register_Routine (T, Test_Phase122_Availability_Does_Not_Refresh_Outline'Access,
                        "phase 122 outline availability does not refresh");
      Register_Routine (T, Test_Phase123_Command_Refresh_Uses_Buffer_Markers'Access,
                        "phase 123 command refresh uses buffer marker extraction");
      Register_Routine (T, Test_Phase123_Extractor_Marker_Grammar'Access,
                        "phase 123 extractor marker grammar is deterministic");
      Register_Routine
        (T, Test_Phase579_Outline_Marker_Fallback_Is_Marker_Only'Access,
         "phase 579 outline fallback is marker-only");
      Register_Routine
        (T, Test_Phase579_Outline_Parser_Runs_For_Extensionless_Buffer'Access,
         "phase 579 outline parser runs for extensionless buffers");
      Register_Routine (T, Test_Phase124_Snapshot_Is_Immutable_And_Read_Only'Access,
                        "phase 124 snapshot extraction is immutable and read-only");
      Register_Routine (T, Test_Phase124_Marker_Grammar_Freeze_And_Edge_Cases'Access,
                        "phase 124 marker grammar and edge cases are frozen");
      Register_Routine (T, Test_Phase124_Result_Invariants_And_Fingerprints'Access,
                        "phase 124 extraction result invariants and fingerprints");
      Register_Routine (T, Test_Phase124_Zero_Item_Refresh_Clears_Rows'Access,
                        "phase 124 zero-item refresh clears outline rows");
      Register_Routine (T, Test_Phase124_Dirty_Buffer_Refresh_Is_Read_Only'Access,
                        "phase 124 dirty-buffer refresh is read-only");
      Register_Routine (T, Test_Phase124_No_Extraction_From_Availability'Access,
                        "phase 124 availability never extracts");
      Register_Routine (T, Test_Phase124_Projection_And_Targets_Are_Stable'Access,
                        "phase 124 extracted projection and targets are stable");
      Register_Routine (T, Test_Phase122_Clear_And_Reset_Do_Not_Auto_Refresh'Access,
                        "phase 122 reset and show do not auto-refresh outline");
      Register_Routine (T, Test_Phase125_Outline_Source_Classification'Access,
                        "phase 125 outline source classification");
      Register_Routine (T, Test_Phase125_Stale_Result_Rejected_After_Buffer_Switch'Access,
                        "phase 125 stale result rejected after buffer switch");
      Register_Routine (T, Test_Phase125_Stale_Result_Rejected_After_Buffer_Edit'Access,
                        "phase 125 stale result rejected after buffer edit");
      Register_Routine (T, Test_Phase125_Clear_Invalidates_Pending_Result'Access,
                        "phase 125 clear invalidates pending extraction result");
      Register_Routine (T, Test_Phase125_Zero_Item_Result_Is_Diagnostic_State'Access,
                        "phase 125 zero-item extraction is diagnostic state");
      Register_Routine (T, Test_Phase126_Ada_Outline_Extracts_Common_Declarations'Access,
                        "phase 126 Ada outline extracts common declarations");
      Register_Routine (T, Test_Phase126_Ada_Outline_Ignores_Comments_And_Is_Case_Insensitive'Access,
                        "phase 126 Ada outline ignores comments and is case-insensitive");
      Register_Routine (T, Test_Phase126_Ada_Outline_Empty_And_Non_Ada_Are_Unsupported'Access,
                        "phase 126 Ada outline empty and non-Ada are unsupported");
      Register_Routine (T, Test_Phase126_Ada_Outline_Rows_Open_To_Target_Line'Access,
                        "phase 126 Ada outline rows open to target line");
      Register_Routine (T, Test_Phase126_Ada_Outline_Result_Still_Rejected_When_Stale'Access,
                        "phase 126 Ada outline stale result rejection");
      Register_Routine (T, Test_Phase127_Ada_Outline_Extracts_Multiline_Procedure'Access,
                        "phase 127 Ada outline extracts multi-line procedure");
      Register_Routine (T, Test_Phase127_Ada_Outline_Extracts_Multiline_Function'Access,
                        "phase 127 Ada outline extracts multi-line function");
      Register_Routine (T, Test_Phase127_Ada_Outline_Does_Not_Duplicate_Continuation_Lines'Access,
                        "phase 127 Ada outline avoids continuation duplicates");
      Register_Routine (T, Test_Phase127_Ada_Outline_Extracts_Generic_Package'Access,
                        "phase 127 Ada outline extracts generic package");
      Register_Routine (T, Test_Phase127_Ada_Outline_Extracts_Generic_Procedure_And_Function'Access,
                        "phase 127 Ada outline extracts generic subprograms");
      Register_Routine (T, Test_Phase127_Ada_Outline_Clears_Pending_Generic_After_Use'Access,
                        "phase 127 Ada outline clears pending generic marker");
      Register_Routine (T, Test_Phase127_Ada_Outline_Label_Excludes_Profile_And_Comment'Access,
                        "phase 127 Ada outline labels exclude profile and comment");
      Register_Routine (T, Test_Phase127_Ada_Outline_Assigns_Depth_For_Package_Members'Access,
                        "phase 127 Ada outline assigns depth for package members");
      Register_Routine (T, Test_Phase127_Ada_Outline_Depth_Remains_Stable_On_Unmatched_End'Access,
                        "phase 127 Ada outline depth remains stable on unmatched end");
      Register_Routine (T, Test_Phase127_Ada_Outline_String_Comment_Marker_Is_Not_Comment'Access,
                        "phase 127 Ada outline ignores comment marker inside strings");
      Register_Routine (T, Test_Phase127_Ada_Outline_Distinguishes_Package_Spec_And_Body'Access,
                        "phase 127 Ada outline distinguishes package spec and body");
      Register_Routine (T, Test_Phase127_Ada_Outline_Distinguishes_Procedure_Declaration_And_Body'Access,
                        "phase 127 Ada outline distinguishes procedure declaration and body");
      Register_Routine (T, Test_Phase127_Ada_Outline_Still_Rejects_Stale_Multiline_Result'Access,
                        "phase 127 Ada outline rejects stale multi-line result");
      Register_Routine (T, Test_Phase127_Ada_Outline_Unsupported_Buffer_Clears_Previous_Rows'Access,
                        "phase 127 unsupported buffer clears previous rows");
      Register_Routine (T, Test_Phase128_Refresh_Preserves_Selected_Item_By_Target'Access,
                        "phase 128 refresh preserves selected item by target");
      Register_Routine (T, Test_Phase128_Refresh_Does_Not_Preserve_Selection_Across_Buffers'Access,
                        "phase 128 refresh does not preserve selection across buffers");
      Register_Routine (T, Test_Phase128_Select_Current_Symbol_Chooses_Preceding_Item'Access,
                        "phase 128 current-symbol lookup chooses preceding item");
      Register_Routine (T, Test_Phase128_Select_Next_Previous_Skip_Non_Selectable_Rows'Access,
                        "phase 128 previous/next selection skips non-selectable rows");
      Register_Routine (T, Test_Phase129_Current_Symbol_Updates_On_Cursor_Line'Access,
                        "phase 129 current symbol updates on cursor line");
      Register_Routine (T, Test_Phase129_Current_Symbol_Clears_Before_First_Item'Access,
                        "phase 129 current symbol clears before first item");
      Register_Routine (T, Test_Phase129_Current_Symbol_Does_Not_Change_Selection'Access,
                        "phase 129 current symbol does not change selection");
      Register_Routine (T, Test_Phase129_Current_Symbol_Clears_For_Unsupported_And_Failure'Access,
                        "phase 129 unsupported and failure clear current symbol");
      Register_Routine (T, Test_Phase129_Header_And_Row_Projection_Mark_Current_Symbol'Access,
                        "phase 129 header and projection mark current symbol");
      Register_Routine (T, Test_Phase129_Clear_Removes_Current_Symbol'Access,
                        "phase 129 clear removes current symbol");
      Register_Routine
        (T, Test_Phase129_Stale_Result_Preserves_Accepted_Current_Symbol'Access,
         "phase 129 stale result preserves accepted current symbol");
      Register_Routine
        (T, Test_Phase129_Cursor_Move_Command_Updates_Current_Symbol_Projection'Access,
         "phase 129 cursor move command updates current symbol projection");
      Register_Routine
        (T, Test_Phase130_Reveal_Current_Symbol_Requests_Reveal'Access,
         "phase 130 reveal current symbol requests reveal");
      Register_Routine
        (T, Test_Phase130_Reveal_Current_Symbol_Noops_When_No_Current_Symbol'Access,
         "phase 130 reveal current symbol noops without current symbol");
      Register_Routine
        (T, Test_Phase130_Select_Current_Symbol_Changes_Selection_And_Reveals'Access,
         "phase 130 select current symbol changes selection and reveals");
      Register_Routine
        (T, Test_Phase130_Open_Selected_Does_Not_Use_Current_Symbol'Access,
         "phase 130 open selected does not use current symbol");
      Register_Routine
        (T, Test_Phase130_Command_Palette_Registers_Outline_Navigation'Access,
         "phase 130 command palette registers outline navigation");
      Register_Routine
        (T, Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success'Access,
         "phase 131 open selected returns focus to editor on success");
      Register_Routine
        (T, Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target'Access,
         "phase 131 open selected does not return focus on no target");
      Register_Routine
        (T, Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol'Access,
         "phase 131 open selected does not use current symbol");
      Register_Routine
        (T, Test_Outline_Select_Next_Preserves_Feature_Panel_Focus'Access,
         "phase 131 select next preserves feature panel focus");
      Register_Routine
        (T, Test_Outline_Select_Previous_Preserves_Feature_Panel_Focus'Access,
         "phase 131 select previous preserves feature panel focus");
      Register_Routine
        (T, Test_Outline_Select_Current_Symbol_Preserves_Focus'Access,
         "phase 131 select current symbol preserves focus");
      Register_Routine
        (T, Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor'Access,
         "phase 131 reveal current symbol does not move editor cursor");
      Register_Routine
        (T, Test_Outline_Select_Next_Requests_Reveal'Access,
         "phase 131 select next requests reveal");
      Register_Routine
        (T, Test_Outline_Select_Previous_Requests_Reveal'Access,
         "phase 131 select previous requests reveal");
      Register_Routine
        (T, Test_Outline_Command_Palette_And_Keybinding_Use_Same_Handler'Access,
         "phase 131 command palette and keybinding use same handler");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Selects_Row_Without_Navigation'Access,
         "phase 132 mouse click selects row without navigation");
      Register_Routine
        (T, Test_Outline_Mouse_Double_Click_Opens_Selected_Row'Access,
         "phase 132 mouse activation opens selected row");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate'Access,
         "phase 132 mouse diagnostic row does not navigate");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Rejects_Stale_Projection'Access,
         "phase 132 mouse stale projection is rejected");
      Register_Routine
        (T, Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol'Access,
         "phase 132 mouse selection does not change current symbol");
      Register_Routine
        (T, Test_Phase133_Outline_Filter_Matches_Label_Case_Insensitive'Access,
         "phase 133 outline filter matches label case-insensitively");
      Register_Routine
        (T, Test_Phase133_Outline_Clear_Filter_Restores_All_Rows'Access,
         "phase 133 outline clear filter restores all rows");
      Register_Routine
        (T, Test_Phase134_Outline_Focus_Filter_Activates_Input'Access,
         "phase 134 outline focus filter activates input");
      Register_Routine
        (T, Test_Phase134_Filter_Input_Text_Rebuilds_Projection'Access,
         "phase 134 outline filter input text rebuilds projection");
      Register_Routine
        (T, Test_Phase134_Filter_Input_Backspace_Rebuilds_Projection'Access,
         "phase 134 outline filter input backspace rebuilds projection");
      Register_Routine
        (T, Test_Phase134_Filter_Input_Escape_Rule'Access,
         "phase 134 outline filter input escape rule");
      Register_Routine
        (T, Test_Phase134_Filter_Edit_Selection_Reconciliation'Access,
         "phase 134 outline filter edit reconciles selection");
      Register_Routine
        (T, Test_Phase134_Filter_Cleared_On_Outline_Clear'Access,
         "phase 134 outline clear removes filter state");
      Register_Routine
        (T, Test_Phase134_Filter_Header_Shows_Text_And_Count'Access,
         "phase 134 outline filter header shows text and count");
      Register_Routine
        (T, Test_Phase134_Filter_Command_Palette_Registers_Commands'Access,
         "phase 134 outline filter commands are registered");
      Register_Routine
        (T, Test_Phase135_Filter_History_Adds_Deduplicates_And_Trims'Access,
         "phase 135 outline filter history adds, deduplicates, and trims");
      Register_Routine
        (T, Test_Phase135_Filter_History_Navigation_Rebuilds_Projection'Access,
         "phase 135 outline filter history navigation rebuilds projection");
      Register_Routine
        (T, Test_Phase135_Clear_Filter_History_Removes_Entries'Access,
         "phase 135 outline clear filter history removes entries");
      Register_Routine
        (T, Test_Phase135_Filter_Remembered_Per_Buffer_And_Restored'Access,
         "phase 135 outline filter remembered per buffer and restored");
      Register_Routine
        (T, Test_Phase135_Filter_Not_Restored_For_Closed_Or_Reused_Label'Access,
         "phase 135 outline filter rejects closed and label-reused buffers");
      Register_Routine
        (T, Test_Phase135_Filter_Reset_Clears_Transient_Cursor_And_Project_State'Access,
         "phase 135 outline filter lifecycle reset clears transient state");
      Register_Routine
        (T, Test_Phase136_Buffer_Close_Clears_Buffer_Owned_Outline_State'Access,
         "phase 136 buffer close clears buffer-owned outline state");
      Register_Routine
        (T, Test_Phase136_Project_And_Workspace_Close_Clear_Session_State'Access,
         "phase 136 project and workspace close clear outline session state");
      Register_Routine
        (T, Test_Phase136_Unsupported_And_Failure_Clear_Interaction_State'Access,
         "phase 136 unsupported and failure clear outline interaction state");
      Register_Routine
        (T, Test_Phase136_Projection_Generation_Changes_On_Filter_And_Rows'Access,
         "phase 136 projection generation changes on filter and row edits");
      Register_Routine
        (T, Test_Phase136_Mouse_And_Reveal_Reject_Old_Panel_Generation'Access,
         "phase 136 mouse and reveal reject old projection generation");
      Register_Routine
        (T, Test_Phase137_Repeated_Filter_Clear_Restores_Stable_Rows'Access,
         "phase 137 repeated filter clear restores stable rows");
      Register_Routine
        (T, Test_Phase137_Filtered_Mouse_Activation_Uses_Current_Projection'Access,
         "phase 137 filtered mouse activation uses current projection");
      Register_Routine
        (T, Test_Phase137_Repeated_Stale_Results_Do_Not_Change_State'Access,
         "phase 137 repeated stale results do not change state");
      Register_Routine
        (T, Test_Phase137_Command_Registry_Has_No_Duplicate_Outline_Commands'Access,
         "phase 137 outline command registry has no duplicate commands");
      Register_Routine
        (T, Test_Phase137_Projection_Invariant_Rejects_Stale_Panel'Access,
         "phase 137 projection invariant rejects stale panel");
      Register_Routine
        (T, Test_Phase138_Outline_Projection_Generation_Unchanged_After_Helper_Move'Access,
         "phase 138 outline projection generation unchanged after helper move");
      Register_Routine
        (T, Test_Phase138_Outline_Command_Registration_Is_Idempotent'Access,
         "phase 138 outline command registration is idempotent");
      Register_Routine
        (T, Test_Phase138_Outline_Keybinding_Registration_Is_Idempotent'Access,
         "phase 138 outline keybinding registration is idempotent");
      Register_Routine
        (T, Test_Phase138_All_Outline_Commands_Are_Safe_Without_Active_Buffer'Access,
         "phase 138 all outline commands safe without active buffer");
      Register_Routine
        (T, Test_Phase138_Closed_Project_Outline_Command_Sweep'Access,
         "phase 138 closed project outline command sweep");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Extracts_Renames_And_Expression_Functions'Access,
         "phase 549 Ada outline extracts renames and expression functions");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Extracts_Type_Forms'Access,
         "phase 549 Ada outline extracts type forms");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Extracts_Task_And_Protected_Forms'Access,
         "phase 549 Ada outline extracts task and protected forms");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Generic_Marker_Is_Bounded_Across_Formals'Access,
         "phase 549 Ada outline generic marker is bounded across formals");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Handles_Multiline_Renames_And_Operators'Access,
         "phase 549 Ada outline handles multiline renames and operator functions");
      Register_Routine
        (T, Test_Phase549_Ada_Outline_Coverage_Coherent'Access,
         "phase 549 Ada outline coverage coherent");
      Register_Routine
        (T, Test_Phase549_Completeness_Multiline_Type_And_Expression_Functions'Access,
         "phase 549 completeness handles multiline type and expression functions");
      Register_Routine
        (T, Test_Phase549_Completeness_Split_Generic_Formals_Keep_Marker'Access,
         "phase 549 completeness keeps marker through split generic formals");
      Register_Routine
        (T, Test_Phase549_Completeness_Split_Generic_Package_Formal_Keep_Marker'Access,
         "phase 549 completeness keeps marker through split generic package formals");
      Register_Routine
        (T, Test_Phase549_Completeness_Comments_Strings_And_Generic_Task_Boundary'Access,
         "phase 549 completeness preserves comment/string and generic boundaries");
      Register_Routine
        (T, Test_Phase549_Completeness_Split_Package_Forms_Do_Not_Open_Depth'Access,
         "phase 549 completeness handles split package instantiation/rename depth");
      Register_Routine
        (T, Test_Phase549_Completeness_Null_And_Separate_Subprogram_Bodies'Access,
         "phase 549 completeness handles null/separate subprogram bodies");
      Register_Routine
        (T, Test_Phase549_Completeness_Record_Named_Types_Are_Not_Records'Access,
         "phase 549 completeness keeps record-named access/array types as plain types");
      Register_Routine
        (T, Test_Phase549_Completeness_Private_Named_Types_Are_Not_Private'Access,
         "phase 549 completeness keeps private-named references as plain types");
      Register_Routine
        (T, Test_Phase549_Completeness_Is_Followed_By_Uses_Code_Tokens'Access,
         "phase 549 completeness keeps is-followed-by checks outside strings");
      Register_Routine
        (T, Test_Phase549_Completeness_Code_Tokens_Ignore_Strings'Access,
         "phase 549 completeness keeps code-token checks outside strings");
      Register_Routine
        (T, Test_Phase549_Completeness_Expression_Function_Is_Open_Paren'Access,
         "phase 549 completeness handles expression functions with is followed by open paren");
      Register_Routine
        (T, Test_Phase549_Completeness_Overriding_Subprograms'Access,
         "phase 549 completeness handles overriding subprogram declarations");
      Register_Routine
        (T, Test_Phase549_Completeness_Separate_Subunit_Bodies'Access,
         "phase 549 completeness handles separate subunit bodies");
      Register_Routine
        (T, Test_Phase549_Completeness_End_Name_Keyword_Prefixes_Close_Depth'Access,
         "phase 549 completeness closes depth for end names that prefix Ada keywords");
      Register_Routine
        (T, Test_Phase549_Completeness_Subprogram_Instantiations'Access,
         "phase 549 completeness handles subprogram instantiations");
      Register_Routine
        (T, Test_Phase549_Completeness_Split_Is_New_Instantiations'Access,
         "phase 549 completeness handles split is/new instantiations");
      Register_Routine
        (T, Test_Phase549_Completeness_Completed_Split_Instantiation_Clears_Candidate'Access,
         "phase 549 completeness clears completed split instantiation candidates");
      Register_Routine
        (T, Test_Phase549_Completeness_Private_Child_Package_Specs'Access,
         "phase 549 completeness handles private child package specs");
      Register_Routine
        (T, Test_Phase549_Completeness_Generic_Private_Child_Package_Specs'Access,
         "phase 549 completeness handles generic private child package specs");
      Register_Routine
        (T, Test_Phase549_Completeness_Split_Is_Separate_Body_Stubs'Access,
         "phase 549 completeness handles split is/separate body stubs");
      Register_Routine
        (T, Test_Phase549_Completeness_Semicolons_In_Strings_Do_Not_End_Declarations'Access,
         "phase 549 completeness ignores string semicolons in declaration windows");
      Register_Routine
        (T, Test_Phase549_Completeness_Protected_Type_Label_Branch_Compiles'Access,
         "phase 549 completeness keeps protected type label branch compile-clean");
      Register_Routine
        (T, Test_Phase549_Completeness_Character_Literal_Semicolons_Do_Not_End_Declarations'Access,
         "phase 549 completeness ignores character literal semicolons in declaration windows");
      Register_Routine
        (T, Test_Phase550_Next_Previous_Symbol_Use_Source_Order_And_Wrap'Access,
         "phase 550 next/previous symbol use source order and wrap");
      Register_Routine
        (T, Test_Phase550_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline'Access,
         "phase 550 symbol navigation rejects other-buffer and stale outline state");
      Register_Routine
        (T, Test_Phase550_Symbol_Navigation_Rejects_Retained_Stale_Rows'Access,
         "phase 550 symbol navigation rejects retained stale rows");
      Register_Routine
        (T, Test_Phase550_Symbol_Navigation_Rejects_Mixed_Buffer_Rows'Access,
         "phase 550 symbol navigation rejects mixed-buffer rows");
      Register_Routine
        (T, Test_Phase550_Status_Counts_Only_Navigable_Symbol_Rows'Access,
         "phase 550 status counts only navigable symbol rows");
      Register_Routine
        (T, Test_Phase550_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows'Access,
         "phase 550 buffer identity helper and filter restore reject stale rows");
      Register_Routine
        (T, Test_Phase550_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol'Access,
         "phase 550 reveal helper rejects retained stale current symbol rows");
      Register_Routine
        (T, Test_Phase550_Command_Surface_Registers_Navigation_Commands'Access,
         "phase 550 command surface registers symbol navigation commands");
      Register_Routine
        (T, Test_Phase550_Filter_Match_Availability_Is_Side_Effect_Free'Access,
         "phase 550 filter match availability is side-effect-free");
      Register_Routine
        (T, Test_Phase551_Ada_Structure_Ranges_Annotate_Outline_Details'Access,
         "phase 551 Ada structure ranges annotate outline details");
      Register_Routine
        (T, Test_Phase551_Current_Symbol_Uses_Smallest_Enclosing_Range'Access,
         "phase 551 current symbol uses smallest enclosing range");
      Register_Routine
        (T, Test_Phase551_Structure_Ranges_Ignore_Comments_And_String_Keywords'Access,
         "phase 551 structure ranges ignore comments and string keywords");
      Register_Routine
        (T, Test_Phase551_Begin_End_Blocks_Do_Not_Truncate_Enclosing_Body'Access,
         "phase 551 begin/end blocks do not truncate enclosing body");
      Register_Routine
        (T, Test_Phase551_Record_Task_And_Protected_Ranges'Access,
         "phase 551 record task and protected ranges");
      Register_Routine
        (T, Test_Phase551_Task_And_Protected_Type_Ranges'Access,
         "phase 551 task and protected type ranges");
      Register_Routine
        (T, Test_Phase551_Named_End_Mismatch_Does_Not_Close_Root_Range'Access,
         "phase 551 mismatched named end does not close root range");
      Register_Routine
        (T, Test_Phase551_Keyword_End_Forms_Close_Matching_Constructs'Access,
         "phase 551 keyword end forms close matching constructs");
      Register_Routine
        (T, Test_Phase551_Keyword_End_Mismatch_Does_Not_Close_Root_Range'Access,
         "phase 551 keyword end mismatch does not close root range");
      Register_Routine
        (T, Test_Phase551_Inline_Balanced_Blocks_Do_Not_Truncate_Ranges'Access,
         "phase 551 inline balanced blocks do not truncate ranges");
      Register_Routine
        (T, Test_Phase551_Multiline_Subprogram_Body_Header_Range'Access,
         "phase 551 multiline subprogram body header range");
      Register_Routine
        (T, Test_Phase551_Split_Subprogram_Spec_Does_Not_Corrupt_Outer_Range'Access,
         "phase 551 split subprogram spec does not corrupt outer range");
      Register_Routine
        (T, Test_Phase551_Separate_Body_Stubs_Do_Not_Get_Local_Ranges'Access,
         "phase 551 separate body stubs do not get local ranges");
      Register_Routine
        (T, Test_Phase551_String_Tokens_In_Split_Spec_Do_Not_Corrupt_Ranges'Access,
         "phase 551 string tokens in split spec do not corrupt ranges");
      Register_Routine
        (T, Test_Phase551_Prefixed_Nested_Body_Does_Not_Hide_From_Range_Stack'Access,
         "phase 551 prefixed nested body does not hide from range stack");
      Register_Routine
        (T, Test_Phase551_Mismatched_Nested_Block_End_Does_Not_Fabricate_Range'Access,
         "phase 551 mismatched nested block end does not fabricate range");
      Register_Routine
        (T, Test_Phase551_Mismatched_Nested_Named_End_Does_Not_Close_Body'Access,
         "phase 551 mismatched nested named end does not fabricate range");
      Register_Routine
        (T, Test_Phase551_Labeled_Blocks_Do_Not_Close_Enclosing_Range'Access,
         "phase 551 labeled blocks do not close enclosing range");
      Register_Routine
        (T, Test_Phase551_Mismatched_Labeled_Loop_End_Does_Not_Close_Range'Access,
         "phase 551 mismatched labeled loop end does not fabricate range");
      Register_Routine
        (T, Test_Phase551_Entry_And_Accept_Bodies_Do_Not_Close_Enclosing_Range'Access,
         "phase 551 entry and accept bodies do not close enclosing range");
      Register_Routine
        (T, Test_Phase551_Select_Blocks_Do_Not_Close_Enclosing_Range'Access,
         "phase 551 select blocks do not close enclosing range");
      Register_Routine
        (T, Test_Phase552_Ada_Lexical_Sanitizer_Preserves_Columns'Access,
         "phase 552 Ada lexical sanitizer preserves columns");
      Register_Routine
        (T, Test_Phase552_Ada_Outline_Ignores_Comments_Strings_And_Characters'Access,
         "phase 552 Ada outline ignores comments strings and characters");
      Register_Routine
        (T, Test_Phase552_Ada_Structure_Ranges_Use_Code_Only_Text'Access,
         "phase 552 Ada structure ranges use code-only text");
      Register_Routine
        (T, Test_Phase552_Ada_Record_Range_Ignores_End_Record_In_Non_Code'Access,
         "phase 552 Ada record range ignores end record in non-code text");
      Register_Routine
        (T, Test_Phase552_Ada_Nested_Block_Range_Ignores_End_If_In_Non_Code'Access,
         "phase 552 Ada nested block range ignores end if in non-code text");
      Register_Routine
        (T, Test_Phase552_Ada_Unterminated_String_Is_Line_Local'Access,
         "phase 552 Ada unterminated string is line-local");
      Register_Routine
        (T, Test_Phase552_Ada_Doubled_Quotes_And_Comment_Markers_Are_Non_Code'Access,
         "phase 552 Ada doubled quotes and comment markers are non-code");
      Register_Routine
        (T, Test_Phase552_Ada_Generic_Prelude_Ignores_Comment_Text'Access,
         "phase 552 Ada generic prelude ignores comment text");
      Register_Routine
        (T, Test_Phase552_Ada_Current_Symbol_And_Reveal_Skip_Fakes'Access,
         "phase 552 Ada current symbol and reveal skip fakes");
      Register_Routine
        (T, Test_Phase552_Ada_Lexical_Scanner_Is_Bounded_And_Deterministic'Access,
         "phase 552 Ada lexical scanner is bounded and deterministic");
      Register_Routine
        (T, Test_Phase552_Ada_Character_Quote_Literal_And_Spaces_Are_Masked'Access,
         "phase 552 Ada quote and space character literals are masked");
      Register_Routine
        (T, Test_Phase552_Ada_Valid_Declarations_After_Closed_Non_Code_Spans'Access,
         "phase 552 Ada valid declarations after closed non-code spans extract");
      Register_Routine
        (T, Test_Phase552_Ada_Comment_Starts_After_Closed_String_Only'Access,
         "phase 552 Ada comment starts only after closed string");
      Register_Routine
        (T, Test_Phase552_Ada_Multiline_Declaration_Window_Uses_Sanitized_Text'Access,
         "phase 552 Ada multi-line declaration windows use sanitized text");
      Register_Routine
        (T, Test_Phase552_Ada_Generic_Prelude_Ignores_String_Text'Access,
         "phase 552 Ada generic prelude ignores string text");
      Register_Routine
        (T, Test_Phase552_Ada_Sanitized_View_Is_Transient_And_Derived'Access,
         "phase 552 Ada sanitized view is transient and derived");
      Register_Routine
        (T, Test_Phase552_Ada_Command_Metadata_And_Keybindings_Carry_No_Lexical_State'Access,
         "phase 552 Ada command metadata and keybindings carry no lexical state");
      Register_Routine
        (T, Test_Phase552_Ada_Availability_And_Render_Do_Not_Run_Lexical_Scan'Access,
         "phase 552 Ada availability and render do not run lexical scan");
      Register_Routine
        (T, Test_Phase552_Ada_Workspace_Snapshot_Excludes_Lexical_State'Access,
         "phase 552 Ada workspace snapshot excludes lexical state");
      Register_Routine
        (T, Test_Phase552_Ada_Detection_Ignores_Non_Code_Only_Buffer'Access,
         "phase 552 Ada detection ignores non-code only buffer");
      Register_Routine
        (T, Test_Phase552_Ada_CRLF_And_Trailing_CR_Do_Not_Leak_Non_Code'Access,
         "phase 552 Ada CRLF and trailing CR do not leak non-code");
      Register_Routine
        (T, Test_Phase552_Ada_Labelled_Loops_Ignore_Labels_In_Non_Code'Access,
         "phase 552 Ada labelled loops ignore labels in non-code");
      Register_Routine
        (T, Test_Phase552_Ada_Tabs_And_Mixed_Case_Keywords_Remain_Lexically_Safe'Access,
         "phase 552 Ada tabs and mixed-case keywords remain lexically safe");
      Register_Routine
        (T, Test_Phase552_Ada_Comment_After_Dash_Character_Literal_Is_Real_Comment'Access,
         "phase 552 Ada comment after dash character literal is real comment");
      Register_Routine
        (T, Test_Phase552_Ada_String_Semicolon_Does_Not_Close_Multiline_Declaration'Access,
         "phase 552 Ada string semicolon does not close multi-line declaration");
      Register_Routine
        (T, Test_Phase552_Ada_Operator_Functions_Remain_Code_While_Quoted_Fakes_Are_Masked'Access,
         "phase 552 Ada operator functions remain code while quoted fakes are masked");
      Register_Routine
        (T, Test_Phase552_Ada_Null_And_Control_Characters_Do_Not_Break_Line_Scan'Access,
         "phase 552 Ada null and control characters do not break line scan");
      Register_Routine
        (T, Test_Phase552_Ada_Adjacent_And_Empty_Strings_Do_Not_Leak_Comments'Access,
         "phase 552 Ada adjacent and empty strings do not leak comments");
      Register_Routine
        (T, Test_Phase552_Ada_Generic_Formals_And_Case_Loop_Use_Code_Only_Text'Access,
         "phase 552 Ada generic formals and case loop use code-only text");
      Register_Routine
        (T, Test_Phase552_Ada_Double_Quote_Character_Literal_Does_Not_Start_String'Access,
         "phase 552 Ada double-quote character literal does not start string");
      Register_Routine
        (T, Test_Phase552_Ada_Token_Helpers_Use_Unified_Sanitized_View'Access,
         "phase 552 Ada token helpers use unified sanitized view");

      Register_Routine
        (T, Test_Phase552_Ada_Code_Column_Uses_Same_Mask_As_Sanitizer'Access,
         "phase 552 Ada code-column helper uses the same mask as sanitizer");
      Register_Routine
        (T, Test_Phase552_Ada_Lexical_Public_Helpers_Handle_Slices_And_Empty_Lines'Access,
         "phase 552 Ada lexical helpers handle slices and empty lines");
      Register_Routine
        (T, Test_Phase552_Ada_Attribute_And_Qualified_Literal_Apostrophes_Remain_Code'Access,
         "phase 552 Ada attribute and qualified literal apostrophes remain code");
      Register_Routine
        (T, Test_Phase552_Ada_Adjacent_Character_Literals_Do_Not_Suppress_Code'Access,
         "phase 552 Ada adjacent character literals do not suppress code");
      Register_Routine
        (T, Test_Phase552_Ada_Character_String_Comment_Sequence_Uses_One_Line_State'Access,
         "phase 552 Ada character string comment sequence uses one-line state");
      Register_Routine
        (T, Test_Phase552_Ada_Comment_Quotes_And_Chars_Are_Line_Local'Access,
         "phase 552 Ada comment quotes and chars are line-local");
      Register_Routine
        (T, Test_Phase552_Ada_Structure_Normalization_Reapplies_Code_Only_View'Access,
         "phase 552 Ada structure normalization reapplies code-only view");
      Register_Routine
        (T, Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_String_State_Across_Line_Break'Access,
         "phase 552 Ada public sanitizer resets string state across line breaks");
      Register_Routine
        (T, Test_Phase552_Ada_Public_Sanitizer_Treats_CRLF_As_Non_Code_Boundary'Access,
         "phase 552 Ada public sanitizer treats CRLF as non-code boundary");
      Register_Routine
        (T, Test_Phase552_Ada_Public_Sanitizer_Does_Not_Carry_Comment_State_Across_Line_Break'Access,
         "phase 552 Ada public sanitizer resets comment state across line breaks");
      Register_Routine
        (T, Test_Phase579_Ada_Record_Component_Fields_Are_Extracted'Access,
         "phase 579 Ada record component fields are extracted");
      Register_Routine
        (T, Test_Phase579_Ada_Record_Field_Scanner_Ignores_Non_Component_Lines'Access,
         "phase 579 Ada record field scanner ignores non-component lines");
      Register_Routine
        (T, Test_Phase579_Ada_Enumeration_Literals_Are_Extracted'Access,
         "phase 579 Ada enumeration literals are extracted");
      Register_Routine
        (T, Test_Phase579_Ada_Package_Exception_And_Constant_Declarations_Are_Extracted'Access,
         "phase 579 Ada package exception and constant declarations are extracted");
      Register_Routine
        (T, Test_Phase579_Ada_Objects_Discriminants_And_Character_Literals_Are_Extracted'Access,
         "phase 579 Ada objects discriminants and character literals are extracted");
      Register_Routine
        (T, Test_Phase579_Ada_Object_Scanner_Ignores_Local_And_Non_Object_Lines'Access,
         "phase 579 Ada object scanner ignores local and non-object lines");
      Register_Routine
        (T, Test_Phase579_Ada_Representation_Clauses_Are_Detail_Metadata'Access,
         "phase 579 Ada representation clauses are outline detail metadata");
      Register_Routine
        (T, Test_Phase579_Ada_Generic_Formals_Are_Extracted'Access,
         "phase 579 Ada generic formals are extracted");
      Register_Routine
        (T, Test_Phase579_Ada_Generic_Formal_Continuations_Are_Not_Duplicated'Access,
         "phase 579 Ada generic formal continuations are not duplicated");
      Register_Routine
        (T, Test_Phase579_Ada_Outline_Extracts_Subunits_Abstract_Null_And_Operators'Access,
         "phase 579 Ada outline extracts subunits abstract null and operators");
      Register_Routine
        (T, Test_Phase579_Ada_Outline_Extracts_Entries_Instantiations_And_Child_Packages'Access,
         "phase 579 Ada outline extracts entries instantiations and child packages");
      Register_Routine
        (T, Test_Phase707_Ada_Outline_Precision_For_Expanded_Constructs'Access,
         "pass 707 Ada outline precision for expanded constructs");
      Register_Routine
        (T, Test_Phase721_Ada_Outline_Type_Family_Label_Precision'Access,
         "pass 721 Ada outline type family label precision");
      Register_Routine
        (T, Test_Phase579_Outline_Freshness_Is_Queryable_After_Edit'Access,
         "phase 579 outline freshness is queryable after edit");
      Register_Routine
        (T, Test_Phase579_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer'Access,
         "phase 579 outline freshness classifies current stale and wrong buffer");
      Register_Routine
        (T, Test_Phase579_Outline_Reload_And_Revert_Clear_Freshness'Access,
         "phase 579 outline reload and revert clear freshness");
      Register_Routine
        (T, Test_Phase579_Close_Buffer_Blocks_Selected_Row_Navigation'Access,
         "phase 579 close buffer blocks selected outline navigation");
      Register_Routine
        (T, Test_Phase579_Declaration_Navigation_Availability_Rejects_Stale_Target'Access,
         "phase 579 declaration navigation availability rejects stale targets");
      Register_Routine
        (T, Test_Phase579_Next_Previous_Boundaries_Can_Report_Unavailable'Access,
         "phase 579 next previous boundaries can report unavailable");
      Register_Routine
        (T, Test_Phase579_Filtered_Selection_Clamps_At_Visible_Bounds'Access,
         "phase 579 filtered selection clamps at visible bounds");
      Register_Routine
        (T, Test_Phase550_Ada_Symbol_Navigation_Audit_Is_Coherent'Access,
         "phase 550 Ada symbol navigation audit is coherent");
   end Register_Tests;

end Editor.Outline.Tests;
