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
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Outline_Commands;
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

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_outline_" & Name;
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Write_Text
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
   end Write_Text;

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
        "outline refresh participates in optional default keybindings");
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




   procedure Test_Clear_Versus_Feature_Panel_Clear
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
   end Test_Clear_Versus_Feature_Panel_Clear;



   procedure Test_Project_Summary_Exposes_Outline_Workflow
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
   end Test_Project_Summary_Exposes_Outline_Workflow;



   procedure Test_Refresh_Seam_Status_And_Unsupported_Sources
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
              "project extractor source remains unavailable in ");
      Assert (Result.Failure_Kind = Extractor_Not_Available,
              "future project extractor source reports extractor unavailable");
      Assert (Fingerprint (O) = Before_Finger,
              "unsupported project extractor source does not mutate outline");
   end Test_Refresh_Seam_Status_And_Unsupported_Sources;


   procedure Test_Availability_Does_Not_Refresh_Outline
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
   end Test_Availability_Does_Not_Refresh_Outline;



   procedure Test_Clear_And_Reset_Do_Not_Auto_Refresh
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
   end Test_Clear_And_Reset_Do_Not_Auto_Refresh;



   procedure Test_Outline_Parser_Runs_For_Extensionless_Buffer
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
   end Test_Outline_Parser_Runs_For_Extensionless_Buffer;


   procedure Test_Snapshot_Is_Immutable_And_Read_Only
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
   end Test_Snapshot_Is_Immutable_And_Read_Only;



   procedure Test_Result_Invariants_And_Fingerprints
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
   end Test_Result_Invariants_And_Fingerprints;


   procedure Test_Zero_Item_Refresh_Clears_Rows
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
   end Test_Zero_Item_Refresh_Clears_Rows;


   procedure Test_Dirty_Buffer_Refresh_Is_Read_Only
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
   end Test_Dirty_Buffer_Refresh_Is_Read_Only;


   procedure Test_No_Extraction_From_Availability
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
   end Test_No_Extraction_From_Availability;


   procedure Test_Projection_And_Targets_Are_Stable
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
   end Test_Projection_And_Targets_Are_Stable;


   procedure Test_Outline_Source_Classification
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
   end Test_Outline_Source_Classification;


   procedure Test_Stale_Result_Rejected_After_Buffer_Switch
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
   end Test_Stale_Result_Rejected_After_Buffer_Switch;


   procedure Test_Stale_Result_Rejected_After_Buffer_Edit
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
   end Test_Stale_Result_Rejected_After_Buffer_Edit;


   procedure Test_Clear_Invalidates_Pending_Result
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
   end Test_Clear_Invalidates_Pending_Result;


   procedure Test_Zero_Item_Result_Is_Diagnostic_State
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
   end Test_Zero_Item_Result_Is_Diagnostic_State;























   procedure Test_Refresh_Preserves_Selected_Item_By_Target
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
              "preserves selected outline item by stable target metadata");
      Assert (Item_Label (O, Selected_Index (O)) = "procedure Run",
              "preserved selection still names the selected symbol");
   end Test_Refresh_Preserves_Selected_Item_By_Target;

















   procedure Test_Command_Palette_Registers_Outline_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Open_Selected_Outline_Item),
              "open selected outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Select_Next_Outline_Item),
              "select next outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Select_Previous_Outline_Item),
              "select previous outline item is discoverable in the command palette");
      Assert (Editor.Commands.Is_Visible_In_Palette
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol),
              "reveal current outline symbol is discoverable in the command palette");
      Assert (Editor.Commands.Label
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol) =
              "Reveal Current Outline Symbol",
              "reveal current symbol has a concise palette label");
   end Test_Command_Palette_Registers_Outline_Navigation;


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
              "select-next executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "select-next should preserve feature-panel focus");
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
              "select-previous executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "select-previous should preserve feature-panel focus");
   end Test_Outline_Select_Previous_Preserves_Feature_Panel_Focus;

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
              "outline keybinding should resolve through registry");
      Assert (Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "outline keybinding should target the same command id as palette invocation");
      Assert (Editor.Commands.Is_Visible_In_Palette (Id),
              "keybound outline command should remain visible in the command palette");
   end Test_Outline_Command_Palette_And_Keybinding_Use_Same_Handler;












   procedure Test_Buffer_Close_Clears_Buffer_Owned_Outline_State
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
              "buffer close clears visible rows owned by the closed buffer");
      Assert (Selected_Index (O) = 0,
              "buffer close clears selected target for the closed buffer");
      Assert (not Has_Current_Symbol (O),
              "buffer close clears current symbol for the closed buffer");
      Assert (Remembered_Filter_Count (O) = 0,
              "buffer close removes remembered filter for the closed identity");
      Assert (not Snapshot_Is_Current (O, Snapshot),
              "buffer close invalidates pending extraction token for the closed buffer");
      Assert (Invariant_Holds (O),
              "buffer close leaves outline state consistent");
   end Test_Buffer_Close_Clears_Buffer_Owned_Outline_State;

   procedure Test_Project_And_Workspace_Close_Clear_Session_State
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
              "project close clears outline rows");
      Assert (Filter_History_Count (O) = 0,
              "project close clears session-local filter history");
      Assert (Remembered_Filter_Count (O) = 0,
              "project close clears remembered filters");
      Assert (not Filter_Input_Is_Active (O),
              "project close deactivates filter input");
      Assert (Invariant_Holds (O),
              "project close leaves outline state consistent");

      Replace_Items (O, Items);
      Apply_Filter (O, "compute");
      Commit_Filter_To_History (O);
      Remember_Filter_For_Buffer (O, 7);
      Reset_Outline_For_Workspace_Close (O);
      Assert (Item_Count (O) = 0 and then Filter_History_Count (O) = 0,
              "workspace close clears all outline feature session state");
      Assert (Remembered_Filter_Count (O) = 0,
              "workspace close clears remembered per-buffer filters");
   end Test_Project_And_Workspace_Close_Clear_Session_State;

   procedure Test_Unsupported_And_Failure_Clear_Interaction_State
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
              "unsupported content clears stale rows");
      Assert (Selected_Index (O) = 0 and then not Has_Current_Symbol (O),
              "unsupported content clears selection and current symbol");
      Assert (Filtered_Row_Count (O) = 0,
              "unsupported content clears filtered projection count");

      Replace_Items (O, Items);
      Select_Item (O, 1);
      Set_Current_Symbol_Index (O, 1);
      Reset_Outline_For_Extraction_Failure (O, "failed");
      Assert (Item_Count (O) = 0,
              "extraction failure clears stale rows");
      Assert (Current_Symbol_Label (O) = "",
              "extraction failure clears current-symbol label");
      Assert (Invariant_Holds (O),
              "failure leaves outline state consistent");
   end Test_Unsupported_And_Failure_Clear_Interaction_State;


   procedure Test_Repeated_Stale_Results_Do_Not_Change_State
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
                 "stale result must not replace accepted rows");
         Assert (Selected_Index (O) = 1 and then Current_Symbol_Index (O) = 1,
                 "stale result preserves accepted navigation state");
         Assert (Invariant_Holds (O),
                 "stale result leaves outline state consistent");
      end loop;
   end Test_Repeated_Stale_Results_Do_Not_Change_State;

   procedure Test_Command_Registry_Has_No_Duplicate_Outline_Commands
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
                 "outline command has descriptor metadata");
         Assert (Editor.Commands.Has_Stable_Name (Outline_Commands (I)),
                 "outline command has stable persisted name");
         Round_Trip := Editor.Commands.Command_Id_From_Stable_Name
           (Editor.Commands.Stable_Command_Name (Outline_Commands (I)), Found);
         Assert (Found and then Round_Trip = Outline_Commands (I),
                 "outline command stable name round-trips");

         for J in I + 1 .. Outline_Commands'Last loop
            Assert (Editor.Commands.Stable_Command_Name (Outline_Commands (I)) /=
                    Editor.Commands.Stable_Command_Name (Outline_Commands (J)),
                    "outline command stable names are unique");
         end loop;
      end loop;
   end Test_Command_Registry_Has_No_Duplicate_Outline_Commands;

   procedure Test_Projection_Invariant_Rejects_Stale_Panel
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
              "fresh projection satisfies invariant");

      Apply_Filter (O, "clear");
      Assert (not Projection_Invariant_Holds (O, P),
              "stale projection is rejected after filter generation change");
      Set_Rows_From_Outline (O, P);
      Assert (Projection_Invariant_Holds (O, P),
              "rebuilt projection satisfies invariant again");
   end Test_Projection_Invariant_Rejects_Stale_Panel;


   procedure Test_Outline_Projection_Generation_Unchanged_After_Helper_Move
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
         "moved feature-panel generation guard preserves row mapping");
      Assert
        (Validate_Outline_Row_For_Activation
           (O, P, 2, 7, Captured_Generation),
         "moved feature-panel generation guard preserves activation validation");

      Editor.Feature_Panel.Append_Row
        (P, Editor.Feature_Panel.Feature_Row_Item, "Stale UI Row");
      Assert
        (Map_Panel_Row_To_Outline_Row (O, P, 2, Captured_Generation) = 0,
         "stale captured panel generation is rejected after helper move");
      Assert
        (not Validate_Outline_Row_For_Activation
           (O, P, 2, 7, Captured_Generation),
         "stale activation path is rejected after helper move");
      Assert (Invariant_Holds (O),
              "helper movement leaves outline state invariant intact");
   end Test_Outline_Projection_Generation_Unchanged_After_Helper_Move;

   procedure Test_Outline_Command_Registration_Is_Idempotent
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
                 "outline command has a descriptor");
         Assert (Editor.Commands.Is_Bindable_Command (Outline_Commands (I)),
                 "public outline command remains bindable");
         for J in I + 1 .. Outline_Commands'Last loop
            Assert
              (Editor.Commands.Stable_Command_Name (Outline_Commands (I)) /=
               Editor.Commands.Stable_Command_Name (Outline_Commands (J)),
               "duplicate outline command id/stable name rejected by audit");
            Assert
              (Editor.Commands.Label (Outline_Commands (I)) /=
               Editor.Commands.Label (Outline_Commands (J)),
               "duplicate outline command-palette label rejected by audit");
         end loop;
      end loop;
   end Test_Outline_Command_Registration_Is_Idempotent;

   procedure Test_Outline_Keybinding_Registration_Is_Idempotent
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
              "first outline keybinding registration installs defaults");
      Assert (Second.Requested_Count = 6
              and then Second.Registered_Count = 0
              and then Second.Conflict_Count = 6,
              "second outline keybinding registration is deterministic and non-duplicating");
      Assert
        (Editor.Keybindings.Status (Validation) = Editor.Keybindings.Valid_Keybindings,
         "repeated outline keybinding registration leaves keybindings valid");
   end Test_Outline_Keybinding_Registration_Is_Idempotent;

   procedure Test_All_Outline_Commands_Are_Safe_Without_Active_Buffer
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
            "outline command must not fail without active buffer: " &
            Editor.Commands.Stable_Command_Name (Id));
         Assert (Invariant_Holds (S.Outline),
                 "no-active-buffer command keeps outline state consistent");
         Assert (Item_Count (S.Outline) = 0,
                 "no-active-buffer command must not create stale outline rows");
         Assert (not Filter_Input_Is_Active (S.Outline),
                 "no-active-buffer command must not leave filter input active");
      end loop;
   end Test_All_Outline_Commands_Are_Safe_Without_Active_Buffer;

   procedure Test_Closed_Project_Outline_Command_Sweep
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
                 "setup refresh produces extracted rows");
         Apply_Filter (S.Outline, "run");
         Commit_Filter_To_History (S.Outline);
         Activate_Filter_Input (S.Outline);

         Editor.State.Reset_Project_Scoped_State (S);
         Assert (Item_Count (S.Outline) = 0,
                 "project close clears accepted outline rows before sweep");
         Assert (Filter_History_Count (S.Outline) = 0,
                 "project close clears session-local filter history before sweep");
         Assert (not Filter_Input_Is_Active (S.Outline),
                 "project close deactivates filter input before sweep");

         Result := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert
           (Result.Status /= Editor.Executor.Command_Failed,
            "closed-project outline command must not fail: " &
            Editor.Commands.Stable_Command_Name (Id));
         Assert (Invariant_Holds (S.Outline),
                 "closed-project command keeps outline state consistent");
         Assert (Filter_History_Count (S.Outline) = 0,
                 "closed-project command must not resurrect filter history");
         if Id /= Editor.Commands.Command_Refresh_Outline then
            Assert (Item_Count (S.Outline) = 0,
                    "closed-project non-refresh command must not resurrect stale outline rows");
            Assert (not Filter_Input_Is_Active (S.Outline),
                    "closed-project non-refresh command must not activate stale filter input");
         end if;
      end loop;
   end Test_Closed_Project_Outline_Command_Sweep;






































   procedure Test_Outline_Contract_Review_Default_Passes
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
      Assert (Review.Active_Buffer_Only, "outline remains active-buffer scoped");
      Assert (Review.Refresh_Command_Owned, "outline refresh remains command-owned");
      Assert (Review.Projection_Side_Effect_Free, "outline projection remains pure");
      Assert (Review.Feature_Panel_Intact, "feature panel sentinel stays healthy");
      Assert (Review.Command_Surface_Intact, "command surface sentinel stays healthy");
      Assert (Review.Public_Build_Guardrail_Intact,
              "public-build manifest sentinel stays healthy");
      Assert (Review.Ada_Symbol_Navigation_Coherent,
              "symbol navigation sentinel stays healthy");
   end Test_Outline_Contract_Review_Default_Passes;

   procedure Test_Outline_Contract_Review_Is_Side_Effect_Free
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
   end Test_Outline_Contract_Review_Is_Side_Effect_Free;

   procedure Test_Outline_Contract_Review_Feedback_Is_Deterministic
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
   end Test_Outline_Contract_Review_Feedback_Is_Deterministic;





   procedure Test_Empty_States_Are_Display_Only
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
              "empty Ada outline refresh still succeeds");
      Assert (Item_Count (S.Outline) = 0,
              "zero extracted items leave no symbol rows");
      Assert (Outline_Empty_State_Label (S.Outline) = "No outline items found.",
              "empty extraction has a product-facing label");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "empty outline projects one display row");
      Assert (Editor.Feature_Panel.Row_Kind (S.Feature_Panel, 1) =
                Editor.Feature_Panel.Feature_Row_Empty_State,
              "empty projection uses an empty-state row");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "No outline items found.",
              "Feature Panel displays the empty-state label");
      Assert (not Editor.Feature_Panel.Row_Is_Selectable (S.Feature_Panel, 1),
              "empty-state rows are not selectable symbols");

      Before := S.Carets (0).Pos;
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status /= Editor.Executor.Command_Executed,
              "activating an empty-state row does not navigate");
      Assert (S.Carets (0).Pos = Before,
              "empty-state activation leaves the caret unchanged");
   end Test_Empty_States_Are_Display_Only;


   procedure Test_Outline_Display_States_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
   begin
      Assert (Outline_Header_Text (O) = "Outline: not refreshed",
              "default outline header says not refreshed");
      Assert (Outline_Empty_State_Label (O) = "Outline not refreshed.",
              "default empty label says not refreshed");

      Mark_Unsupported (O, Message_Outline_No_Symbols);
      Assert (Outline_Header_Text (O) = "Outline: no items",
              "zero-item header is distinct from unavailable");
      Assert (Outline_Empty_State_Label (O) = "No outline items found.",
              "zero-item label is distinct from unavailable");

      Mark_Unsupported (O, "Outline unavailable for this buffer");
      Assert (Outline_Header_Text (O) = "Outline: unavailable",
              "unsupported header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline unavailable for this buffer.",
              "unsupported label is explicit");

      Mark_Extraction_Failed (O);
      Assert (Outline_Header_Text (O) = "Outline: refresh failed",
              "failure header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline refresh failed.",
              "failure label is explicit");

      Clear (O);
      Mark_Stale_Result (O);
      Assert (Outline_Header_Text (O) = "Outline: may be stale",
              "stale header is explicit");
      Assert (Outline_Empty_State_Label (O) = "Outline may be stale.",
              "stale label is explicit");
   end Test_Outline_Display_States_Are_Clear;



   procedure Test_Show_Outline_No_Active_Buffer_State
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
              "show outline remains an explicit UI workflow with no active buffer");
      Assert (Outline_Empty_State_Label (S.Outline) = "No active buffer.",
              "no-active-buffer outline state is explicit");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "no-active-buffer state projects one display row");
      Assert (Editor.Feature_Panel.Row_Label (S.Feature_Panel, 1) = "No active buffer.",
              "no-active-buffer row uses the product-facing label");
      Assert (not Editor.Feature_Panel.Row_Is_Selectable (S.Feature_Panel, 1),
              "no-active-buffer row is display-only");
      Assert (not Editor.Feature_Panel.Row_Can_Open (S.Feature_Panel, 1),
              "no-active-buffer row has no navigation target");
   end Test_Show_Outline_No_Active_Buffer_State;










   procedure Test_Command_Surface_Registers_Navigation_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Label (Editor.Commands.Command_Next_Outline_Symbol) =
                "Next Outline Symbol",
              "next symbol command has a palette label");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Previous_Outline_Symbol) =
                "Previous Outline Symbol",
              "previous symbol command has a palette label");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Next_Outline_Symbol) =
                Editor.Commands.Navigation_Category,
              "next symbol is categorized as navigation");
      Assert (Editor.Commands.Category (Editor.Commands.Command_Previous_Outline_Symbol) =
                Editor.Commands.Navigation_Category,
              "previous symbol is categorized as navigation");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.next-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Next_Outline_Symbol,
              "next symbol stable name round trips without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.previous-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Previous_Outline_Symbol,
              "previous symbol stable name round trips without payload");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol) =
                "outline.reveal-current-symbol",
              "reveal-current command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Select_Current_Outline_Symbol) =
                "outline.select-current-symbol",
              "select-current command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Select_Next_Outline_Item) =
                "outline.select-next",
              "select-next command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Select_Previous_Outline_Item) =
                "outline.select-previous",
              "select-previous command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Focus_Outline_Filter) =
                "outline.filter.focus",
              "focus filter command has canonical no-payload stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Clear_Outline_Filter) =
                "outline.filter.clear",
              "clear filter command has canonical no-payload stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.reveal-current-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Reveal_Current_Outline_Symbol,
              "reveal-current stable alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.select-current-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Current_Outline_Symbol,
              "select-current stable alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("select-current-outline-symbol", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Current_Outline_Symbol,
              "legacy select-current alias remains loadable");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.select-next", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "select-next stable alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("select-next-outline-item", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "legacy select-next alias remains loadable");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.select-previous", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Previous_Outline_Item,
              "select-previous stable alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("select-previous-outline-item", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Previous_Outline_Item,
              "legacy select-previous alias remains loadable");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.next-match", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Next_Outline_Item,
              "filter next-match alias routes to existing filtered selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.previous-match", Found);
      Assert (Found and then Id = Editor.Commands.Command_Select_Previous_Outline_Item,
              "filter previous-match alias routes to existing filtered selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.focus", Found);
      Assert (Found and then Id = Editor.Commands.Command_Focus_Outline_Filter,
              "filter focus alias routes without payload");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline.filter.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Clear_Outline_Filter,
              "filter clear alias routes without payload");
   end Test_Command_Surface_Registers_Navigation_Commands;






























   function Contains_Lexical_State_Term (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "scanner") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "sanitized") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "token mask") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "lexical state") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "comment map") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "string map") /= 0;
   end Contains_Lexical_State_Term;





































   procedure Register_Tests (T : in out Outline_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Outline_Contract_Review_Default_Passes'Access,
         "outline contract review default passes");
      Register_Routine
        (T, Test_Outline_Contract_Review_Is_Side_Effect_Free'Access,
         "outline contract review is side-effect-free");
      Register_Routine
        (T, Test_Outline_Contract_Review_Feedback_Is_Deterministic'Access,
         "outline contract review feedback is deterministic");
      Register_Routine
        (T, Test_Empty_States_Are_Display_Only'Access,
         "outline empty states are display-only");
      Register_Routine
        (T, Test_Outline_Display_States_Are_Clear'Access,
         "outline display states are clear");
      Register_Routine
        (T, Test_Show_Outline_No_Active_Buffer_State'Access,
         "show outline projects no-active-buffer state");
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
      Register_Routine (T, Test_Clear_Feature_Panel_Does_Not_Clear_Outline'Access,
                        "generic clear feature panel does not clear outline");
      Register_Routine (T, Test_Availability_Is_Side_Effect_Free'Access,
                        "outline availability is side-effect-free");
      Register_Routine (T, Test_Separation_From_Project_Reset_Settings_And_Keybindings'Access,
                        "outline separates from settings/keybindings and resets with project scope");
      Register_Routine (T, Test_Clear_Versus_Feature_Panel_Clear'Access,
                        "clear outline differs from clear feature panel");
      Register_Routine (T, Test_Project_Summary_Exposes_Outline_Workflow'Access,
                        "summaries expose outline workflow state");
      Register_Routine (T, Test_Refresh_Seam_Status_And_Unsupported_Sources'Access,
                        "refresh seam reports status and rejects unsupported sources");
      Register_Routine (T, Test_Availability_Does_Not_Refresh_Outline'Access,
                        "outline availability does not refresh");
      Register_Routine
        (T, Test_Outline_Parser_Runs_For_Extensionless_Buffer'Access,
         "outline parser runs for extensionless buffers");
      Register_Routine (T, Test_Snapshot_Is_Immutable_And_Read_Only'Access,
                        "snapshot extraction is immutable and read-only");
      Register_Routine (T, Test_Result_Invariants_And_Fingerprints'Access,
                        "extraction result invariants and fingerprints");
      Register_Routine (T, Test_Zero_Item_Refresh_Clears_Rows'Access,
                        "zero-item refresh clears outline rows");
      Register_Routine (T, Test_Dirty_Buffer_Refresh_Is_Read_Only'Access,
                        "dirty-buffer refresh is read-only");
      Register_Routine (T, Test_No_Extraction_From_Availability'Access,
                        "availability never extracts");
      Register_Routine (T, Test_Projection_And_Targets_Are_Stable'Access,
                        "extracted projection and targets are stable");
      Register_Routine (T, Test_Clear_And_Reset_Do_Not_Auto_Refresh'Access,
                        "reset and show do not auto-refresh outline");
      Register_Routine (T, Test_Outline_Source_Classification'Access,
                        "outline source classification");
      Register_Routine (T, Test_Stale_Result_Rejected_After_Buffer_Switch'Access,
                        "stale result rejected after buffer switch");
      Register_Routine (T, Test_Stale_Result_Rejected_After_Buffer_Edit'Access,
                        "stale result rejected after buffer edit");
      Register_Routine (T, Test_Clear_Invalidates_Pending_Result'Access,
                        "clear invalidates pending extraction result");
      Register_Routine (T, Test_Zero_Item_Result_Is_Diagnostic_State'Access,
                        "zero-item extraction is diagnostic state");
      Register_Routine (T, Test_Refresh_Preserves_Selected_Item_By_Target'Access,
                        "refresh preserves selected item by target");
      Register_Routine
        (T, Test_Command_Palette_Registers_Outline_Navigation'Access,
         "command palette registers outline navigation");
      Register_Routine
        (T, Test_Outline_Select_Next_Preserves_Feature_Panel_Focus'Access,
         "select next preserves feature panel focus");
      Register_Routine
        (T, Test_Outline_Select_Previous_Preserves_Feature_Panel_Focus'Access,
         "select previous preserves feature panel focus");
      Register_Routine
        (T, Test_Outline_Command_Palette_And_Keybinding_Use_Same_Handler'Access,
         "command palette and keybinding use same handler");
      Register_Routine
        (T, Test_Buffer_Close_Clears_Buffer_Owned_Outline_State'Access,
         "buffer close clears buffer-owned outline state");
      Register_Routine
        (T, Test_Project_And_Workspace_Close_Clear_Session_State'Access,
         "project and workspace close clear outline session state");
      Register_Routine
        (T, Test_Unsupported_And_Failure_Clear_Interaction_State'Access,
         "unsupported and failure clear outline interaction state");
      Register_Routine
        (T, Test_Repeated_Stale_Results_Do_Not_Change_State'Access,
         "repeated stale results do not change state");
      Register_Routine
        (T, Test_Command_Registry_Has_No_Duplicate_Outline_Commands'Access,
         "outline command registry has no duplicate commands");
      Register_Routine
        (T, Test_Projection_Invariant_Rejects_Stale_Panel'Access,
         "projection invariant rejects stale panel");
      Register_Routine
        (T, Test_Outline_Projection_Generation_Unchanged_After_Helper_Move'Access,
         "outline projection generation unchanged after helper move");
      Register_Routine
        (T, Test_Outline_Command_Registration_Is_Idempotent'Access,
         "outline command registration is idempotent");
      Register_Routine
        (T, Test_Outline_Keybinding_Registration_Is_Idempotent'Access,
         "outline keybinding registration is idempotent");
      Register_Routine
        (T, Test_All_Outline_Commands_Are_Safe_Without_Active_Buffer'Access,
         "all outline commands safe without active buffer");
      Register_Routine
        (T, Test_Closed_Project_Outline_Command_Sweep'Access,
         "closed project outline command sweep");
      Register_Routine
        (T, Test_Command_Surface_Registers_Navigation_Commands'Access,
         "command surface registers symbol navigation commands");

   end Register_Tests;

end Editor.Outline.Tests;
