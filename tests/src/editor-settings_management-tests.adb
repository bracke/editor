with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Settings;
with Editor.Commands;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Settings_Management;
with Editor.State;
with Editor.Render_Model;

package body Editor.Settings_Management.Tests is

   use type Editor.Settings_Management.Setting_Update_Status;
   use type Editor.Settings_Management.Setting_Category;
   use type Editor.Settings_Management.Setting_Value_Kind;
   use type Editor.Settings_Management.Settings_Command_Action;
   use type Editor.Commands.Command_Id;
   use type Editor.Settings.Settings_Status;

   function Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key => Code,
         Modifiers =>
           (Ctrl => False, Alt => False, Shift => False, Meta => False));
   end Key;

   function Name
     (T : Settings_Management_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Settings_Management.Tests");
   end Name;

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_" & Name;
   end Temp_Path;

   procedure Delete_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others => null;
   end Delete_If_Exists;

   procedure Write_Text (Path : String; Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Write_Text;

   procedure Test_Rows_Expose_Metadata

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      Seen_Command_Palette : Boolean := False;
      Seen_Boolean         : Boolean := False;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Assert (Editor.Settings_Management.Setting_Count >= 9,
              "settings list should expose all supported persisted preferences");

      for I in 1 .. Editor.Settings_Management.Setting_Count loop
         declare
            Row : constant Editor.Settings_Management.Setting_Row :=
              Editor.Settings_Management.Row_At (Settings, I);
         begin
            Assert (To_String (Row.Key)'Length > 0, "setting key must be stable and non-empty");
            Assert (To_String (Row.Display_Name)'Length > 0, "setting display name must be present");
            Assert (To_String (Row.Default_Value)'Length > 0, "setting default value must be visible");
            Assert (To_String (Row.Current_Value)'Length > 0, "setting current value must be visible");
            Assert (To_String (Row.Description)'Length > 0, "setting description must be visible");
            Assert (To_String (Row.Source_Label)'Length > 0, "setting source label must be visible");
            Assert (Row.Valid, "default settings row must validate");
            if Row.Category = Editor.Settings_Management.Command_Palette_Setting then
               Seen_Command_Palette := True;
            end if;
            if Row.Kind = Editor.Settings_Management.Setting_Boolean then
               Seen_Boolean := True;
               Assert (Row.Toggleable, "boolean settings should be toggleable");
            end if;
         end;
      end loop;

      Assert (Seen_Command_Palette, "command palette display preferences should be listed");
      Assert (Seen_Boolean, "boolean preferences should be represented");
   end Test_Rows_Expose_Metadata;

   procedure Test_Search_And_Filter_Are_Transient_Projections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      Found_Key : Boolean := False;
      Found_Modified : Boolean := False;
      Status : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      for I in 1 .. Editor.Settings_Management.Setting_Count loop
         declare
            Row : constant Editor.Settings_Management.Setting_Row :=
              Editor.Settings_Management.Row_At (Settings, I);
         begin
            if Editor.Settings_Management.Matches_Search (Row, "show-keybindings") then
               Found_Key := True;
            end if;
         end;
      end loop;
      Assert (Found_Key, "search should match stable setting keys");

      Editor.Settings_Management.Toggle_Setting
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok, "toggle should update model");
      for I in 1 .. Editor.Settings_Management.Setting_Count loop
         declare
            Row : constant Editor.Settings_Management.Setting_Row :=
              Editor.Settings_Management.Row_At (Settings, I);
         begin
            if Editor.Settings_Management.Matches_Filter
                 (Row, Editor.Settings_Management.Filter_Modified_Settings)
            then
               Found_Modified := True;
            end if;
         end;
      end loop;
      Assert (Found_Modified, "modified filter should match changed settings");
   end Test_Search_And_Filter_Are_Transient_Projections;

   procedure Test_Typed_Edit_Reset_And_Validation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      Status   : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);

      Editor.Settings_Management.Toggle_Setting
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok, "boolean toggle should succeed");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "toggle should change only selected boolean setting");

      Editor.Settings_Management.Toggle_Setting
        (Settings, Editor.Settings.Setting_Name_Line_Numbers, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Not_Toggleable,
              "non-boolean setting cannot be toggled");

      Editor.Settings_Management.Set_Setting_Value
        (Settings, Editor.Settings.Setting_Name_Line_Numbers, "hybrid", Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok, "allowed enum value should be accepted");
      Assert (Editor.Settings.Line_Number_Mode_Name (Settings) = "hybrid",
              "enum setting should change to accepted value");

      Editor.Settings_Management.Set_Setting_Value
        (Settings, Editor.Settings.Setting_Name_Line_Numbers, "sideways", Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Invalid_Value,
              "invalid enum value should be rejected");
      Assert (Editor.Settings.Line_Number_Mode_Name (Settings) = "hybrid",
              "invalid enum value must not overwrite current value");

      Editor.Settings_Management.Reset_Setting
        (Settings, Editor.Settings.Setting_Name_Line_Numbers, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok, "reset selected should restore default");
      Assert (Editor.Settings.Line_Number_Mode_Name (Settings) = "absolute",
              "reset selected should restore default line-number mode");
   end Test_Typed_Edit_Reset_And_Validation;

   procedure Test_Save_Load_Audit_Reports_Unknown_Invalid_Forbidden

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("settings_audit.txt");
      Audit  : Editor.Settings_Management.Settings_File_Audit;
   begin
      Delete_If_Exists (Path);
      Write_Text
        (Path,
         "editor-settings-version=1" & ASCII.LF &
         "[editor]" & ASCII.LF &
         "line-numbers=sideways" & ASCII.LF &
         "cursor-style=bar" & ASCII.LF &
         "workspace-open-file=src/main.adb" & ASCII.LF &
         "[command-palette]" & ASCII.LF &
         "show-keybindings=false" & ASCII.LF &
         "[keybindings]" & ASCII.LF &
         "save=Ctrl+S" & ASCII.LF);

      Editor.Settings_Management.Audit_Settings_File (Path, Audit);
      Assert (Audit.Load_Status = Editor.Settings.Settings_Partial_Load,
              "invalid and unknown fields should produce partial load status");
      Assert (Audit.Supported_Field_Count >= 2, "audit should count supported fields");
      Assert (Audit.Unknown_Field_Count >= 2, "audit should report unknown fields");
      Assert (Audit.Invalid_Value_Count = 1, "audit should report malformed setting values");
      Assert (Audit.Forbidden_Domain_Count >= 2,
              "audit should flag keybinding/workspace contamination in settings file");
      Delete_If_Exists (Path);
   end Test_Save_Load_Audit_Reports_Unknown_Invalid_Forbidden;

   procedure Test_Domain_Audit_Recognizes_Separation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Settings_Management.Domain_Separation_Audit;
   begin
      Editor.Settings_Management.Audit_Domain_Separation_Text
        ("theme=dark" & ASCII.LF & "show-keybindings=true", Result);
      Assert (Result.Forbidden_Field_Count = 0,
              "display preference show-keybindings must not be treated as a keybinding map");

      Editor.Settings_Management.Audit_Domain_Separation_Text
        ("keybinding.save=Ctrl+S" & ASCII.LF &
         "workspace-open-file=main.adb" & ASCII.LF &
         "recent-project=/tmp/demo" & ASCII.LF &
         "build-result=failed", Result);
      Assert (Result.Settings_Contains_Keybindings, "audit should detect keybinding contamination");
      Assert (Result.Settings_Contains_Workspace, "audit should detect workspace contamination");
      Assert (Result.Settings_Contains_Recent, "audit should detect recent-project contamination");
      Assert (Result.Settings_Contains_Runtime, "audit should detect runtime-state contamination");
      Assert (Result.Forbidden_Field_Count = 4, "audit should count forbidden domain groups");
   end Test_Domain_Audit_Recognizes_Separation;


   procedure Test_Transient_Settings_Editor_Selection_Filter_And_Selected_Actions


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      UI       : Editor.Settings_Management.Settings_Editor_State;
      Snapshot : Editor.Settings_Management.Settings_Surface_Snapshot;
      Status   : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Assert (Editor.Settings_Management.Selected_Key (UI) = "",
              "settings editor starts without persisted selection");

      Editor.Settings_Management.Focus_Settings (UI);
      Assert (UI.Visible and then UI.Focused,
              "focusing settings should show the transient settings surface");
      Assert (Editor.Settings_Management.Selected_Key (UI) = Editor.Settings.Setting_Name_Theme,
              "focus should establish a deterministic transient selection");

      Editor.Settings_Management.Set_Search_Query (UI, "show-keybindings");
      Snapshot := Editor.Settings_Management.Build_Surface_Snapshot (Settings, UI);
      Assert (Snapshot.Display_Row_Count = 1,
              "settings query should filter render rows without mutating settings");
      Assert (To_String (Snapshot.Display_Rows (1).Key) =
                Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
              "settings query should match stable keys");

      Editor.Settings_Management.Clear_Search_Query (UI);
      UI.Selected_Index := Editor.Settings_Management.Index_For_Key
        (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings);
      Editor.Settings_Management.Toggle_Selected_Setting (Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "selected boolean setting should toggle through typed helper");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "selected toggle must update only the selected settings model value");

      Snapshot := Editor.Settings_Management.Build_Surface_Snapshot (Settings, UI);
      Assert (Snapshot.Modified_Count = 1,
              "selected action should be visible as a modified setting");
      Assert (Snapshot.Display_Rows (UI.Selected_Index).Selected,
              "settings render row should mark the transient selection");

      Editor.Settings_Management.Reset_Selected_Setting (Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "selected reset should restore the selected setting default");
      Assert (Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "selected reset must restore the selected setting default only");
   end Test_Transient_Settings_Editor_Selection_Filter_And_Selected_Actions;


   procedure Test_Surface_Snapshot_Is_Render_Facing_And_Observational


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      Snapshot : Editor.Settings_Management.Settings_Surface_Snapshot;
      Before   : Editor.Settings_Management.Settings_Surface_Snapshot;
      Status   : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Before := Editor.Settings_Management.Build_Surface_Snapshot (Settings);
      Snapshot := Editor.Settings_Management.Build_Surface_Snapshot (Settings);
      Assert (Snapshot.Visible, "settings surface snapshot should be render-visible when requested");
      Assert (Snapshot.Row_Count = Editor.Settings_Management.Setting_Count,
              "settings surface row count should reflect supported settings only");
      Assert (Snapshot.Display_Row_Count = Editor.Settings_Management.Setting_Count,
              "settings surface should expose bounded display rows for all supported settings");
      Assert (Snapshot.Modified_Count = 0, "default settings should not be marked modified");
      Assert (Snapshot.Invalid_Count = 0, "default settings should not be invalid");
      Assert (To_String (Snapshot.Audit_Summary)'Length > 0,
              "settings surface snapshot should carry bounded audit summary text");
      Assert (To_String (Snapshot.Domain_Summary) = "Settings domain separation ok.",
              "settings surface snapshot should carry domain separation summary");
      Assert (To_String (Snapshot.Display_Rows (1).Key) = To_String (Before.Display_Rows (1).Key),
              "settings render rows should be stable across observational snapshot builds");

      Editor.Settings_Management.Toggle_Setting
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "fixture setting toggle should succeed");
      Snapshot := Editor.Settings_Management.Build_Surface_Snapshot (Settings);
      Assert (Snapshot.Modified_Count = 1,
              "settings surface should mark runtime preference changes without saving");
      Assert (Editor.Settings_Management.Assert_Settings_Surface_Render_Is_Observational,
              "settings surface snapshot helper should remain observational");
   end Test_Surface_Snapshot_Is_Render_Facing_And_Observational;

   procedure Test_Render_Model_Includes_Settings_Surface

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Settings_UI.Row_Count = Editor.Settings_Management.Setting_Count,
              "render snapshot must include settings surface rows");
      Assert (Snap.Settings_UI.Display_Row_Count > 0,
              "render snapshot must expose bounded settings display rows");
      Assert (To_String (Snap.Settings_UI.Display_Rows (1).Key)'Length > 0,
              "rendered settings rows must carry stable setting keys");
      Assert (Snap.Settings_UI.Modified_Count = 0,
              "render snapshot must not mutate settings while projecting rows");
      Assert (Snap.Configuration_Audit_UI.Display_Count > 0,
              "render snapshot must expose bounded configuration audit rows");
      Assert (Snap.Settings_Command_Catalog_UI.Display_Count > 0,
              "render snapshot must expose bounded settings command catalog rows");
      Assert (Snap.Settings_Command_Catalog_UI.Payload_Command_Count = 0,
              "rendered settings command catalog must remain payload-free");
   end Test_Render_Model_Includes_Settings_Surface;

   procedure Test_Current_Settings_Surface_State_Feeds_Render_Snapshot

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Snap   : Editor.Render_Model.Render_Snapshot;
      UI     : Editor.Settings_Management.Settings_Editor_State;
      Status : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.State.Init (S);
      Editor.Settings_Management.Reset_Transient_State;

      UI := Editor.Settings_Management.Current_Settings_Editor_State;
      Editor.Settings_Management.Focus_Settings (UI);
      Editor.Settings_Management.Set_Search_Query (UI, "theme");
      Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Settings_UI.Visible,
              "current transient settings surface visibility should feed render snapshot");
      Assert (Snap.Settings_UI.Focused,
              "current transient settings surface focus should feed render snapshot");
      Assert (Snap.Settings_UI.Display_Row_Count >= 1,
              "current transient settings query should still project matching rows");

      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Reset_All,
         S.Settings, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Confirmation_Required,
              "global settings surface command should request reset-all confirmation");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Settings_UI.Pending_Reset_All,
              "pending reset-all confirmation should be visible in render snapshot");
      Assert (To_String (Snap.Settings_UI.Confirmation_Message)'Length > 0,
              "pending reset-all confirmation should carry render-facing message");

      Editor.Settings_Management.Reset_Transient_State;
   end Test_Current_Settings_Surface_State_Feeds_Render_Snapshot;

   procedure Test_Settings_Editor_Transient_State_Is_Not_Persisted

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path  : constant String := Temp_Path ("settings_editor_transient.txt");
      Audit : Editor.Settings_Management.Settings_File_Audit;
   begin
      Delete_If_Exists (Path);
      Write_Text
        (Path,
         "editor-settings-version=1" & ASCII.LF &
         "[appearance]" & ASCII.LF &
         "theme=dark" & ASCII.LF &
         "[settings-editor]" & ASCII.LF &
         "query=theme" & ASCII.LF &
         "selection=theme" & ASCII.LF &
         "filter=modified" & ASCII.LF &
         "[configuration-audit]" & ASCII.LF &
         "last-result=ok" & ASCII.LF);
      Editor.Settings_Management.Audit_Settings_File (Path, Audit);
      Assert (Audit.Supported_Field_Count = 1,
              "settings audit should count only supported global settings fields");
      Assert (Audit.Unknown_Field_Count >= 4,
              "settings editor/audit transient state should be unsupported in settings persistence");
      Assert (Audit.Forbidden_Domain_Count >= 1,
              "settings editor/audit transients should be reported as forbidden runtime persistence");
      Assert (Editor.Settings_Management.Assert_Settings_Editor_State_Not_Persisted,
              "settings editor transient-state guard should pass");
      Delete_If_Exists (Path);
   end Test_Settings_Editor_Transient_State_Is_Not_Persisted;



   procedure Test_Save_Load_Wrappers_Report_Bounded_Summaries



     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("settings_persistence_summary.txt");
      Settings : Editor.Settings.Settings_Model;
      Loaded   : Editor.Settings.Settings_Model;
      Summary  : Editor.Settings_Management.Settings_Persistence_Summary;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Delete_If_Exists (Path);
      Editor.Settings.Set_Defaults (Settings);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (Settings, False);

      Editor.Settings_Management.Save_User_Config (Settings, Path, Summary);
      Assert (Summary.Status = Editor.Settings.Settings_Ok,
              "settings save wrapper should report a clean settings-only save");
      Assert (Summary.Supported_Field_Count = Editor.Settings_Management.Setting_Count,
              "settings save wrapper should audit the serialized supported fields");
      Assert (Summary.Unknown_Field_Count = 0
                and then Summary.Invalid_Value_Count = 0
                and then Summary.Forbidden_Field_Count = 0,
              "settings save wrapper must not write other persistence domains");
      Message := To_Unbounded_String
        (Editor.Settings_Management.Persistence_Summary_Message ("save", Summary));
      Assert (To_String (Message) = "Settings saved.",
              "clean settings save should emit a bounded primary summary");

      Editor.Settings_Management.Load_User_Config (Path, Loaded, Summary);
      Assert (Summary.Status = Editor.Settings.Settings_Ok,
              "settings load wrapper should report a clean settings-only load");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Loaded),
              "settings load should apply supported display preference values only");
      Delete_If_Exists (Path);
   end Test_Save_Load_Wrappers_Report_Bounded_Summaries;

   procedure Test_Load_Wrapper_Reports_Forbidden_Domain_Contamination

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("settings_load_forbidden.txt");
      Loaded   : Editor.Settings.Settings_Model;
      Summary  : Editor.Settings_Management.Settings_Persistence_Summary;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Delete_If_Exists (Path);
      Write_Text
        (Path,
         "editor-settings-version=1" & ASCII.LF &
         "[command-palette]" & ASCII.LF &
         "show-keybindings=false" & ASCII.LF &
         "[workspace]" & ASCII.LF &
         "open-file=src/main.adb" & ASCII.LF &
         "[keybindings]" & ASCII.LF &
         "chord=Ctrl+S" & ASCII.LF);

      Editor.Settings_Management.Load_User_Config (Path, Loaded, Summary);
      Assert (Summary.Status = Editor.Settings.Settings_Partial_Load,
              "cross-domain settings files should load supported settings but report partial load");
      Assert (Summary.Forbidden_Field_Count >= 2,
              "load wrapper should report workspace/keybinding contamination");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Loaded),
              "supported display preference should still load when unsupported fields are ignored");
      Message := To_Unbounded_String
        (Editor.Settings_Management.Persistence_Summary_Message ("load", Summary));
      Assert (To_String (Message)'Length > 0,
              "partial settings load should have a bounded summary message");
      Assert (Editor.Settings_Management.Assert_Settings_Save_Writes_Global_Preferences_Only,
              "settings save assertion should verify supported global preference persistence only");
      Assert (Editor.Settings_Management.Assert_Settings_Load_Does_Not_Cross_Domains,
              "settings load assertion should verify ignored forbidden domains do not become settings");
      Delete_If_Exists (Path);
   end Test_Load_Wrapper_Reports_Forbidden_Domain_Contamination;



   procedure Test_Settings_Command_Surface_Is_Configuration_And_Payload_Free



     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Audit : Editor.Settings_Management.Settings_Command_Surface_Audit;
   begin
      Editor.Settings_Management.Audit_Settings_Command_Surface (Audit);
      Assert (Audit.Settings_Command_Count = 3,
              "settings command surface should include save load and reset-all commands");
      Assert (Audit.Missing_Descriptor_Count = 0,
              "settings commands should have complete descriptors");
      Assert (Audit.Wrong_Category_Count = 0,
              "settings commands should be categorized as Settings");
      Assert (Audit.Non_Configuration_Count = 0,
              "settings commands should be marked configuration commands");
      Assert (Audit.Payload_Capable_Count = 0,
              "settings commands should not expose target prompts or key/value payloads");
      Assert (Audit.Hidden_Command_Count = 0,
              "settings commands should be visible in command discovery");
      Assert (Editor.Settings_Management.Assert_Settings_Command_Surface_Coherent,
              "settings command surface helper should pass");
      Assert (Editor.Settings_Management.Assert_Settings_Keybindings_And_Palette_Carry_No_Payloads,
              "settings command palette/keybinding route must remain payload-free");
      Assert (Editor.Settings_Management.Command_Surface_Audit_Summary (Audit)'Length > 0,
              "settings command audit should expose a bounded summary");
   end Test_Settings_Command_Surface_Is_Configuration_And_Payload_Free;



   procedure Test_Settings_Command_Availability_And_Surface_Execution_Are_Typed



     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      UI       : Editor.Settings_Management.Settings_Editor_State;
      Avail    : Editor.Settings_Management.Settings_Command_Availability;
      Status   : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);

      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Toggle_Selected, Settings, UI);
      Assert (not Avail.Available, "toggle selected should be unavailable without selection");
      Assert (Editor.Settings_Management.Availability_Message (Avail) = "No setting selected.",
              "availability should expose a stable no-selection reason");

      Editor.Settings_Management.Focus_Settings (UI);
      UI.Selected_Index := Editor.Settings_Management.Index_For_Key
        (Editor.Settings.Setting_Name_Theme);
      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Toggle_Selected, Settings, UI);
      Assert (not Avail.Available,
              "non-boolean selected setting should not be toggleable through command surface");
      Assert (Editor.Settings_Management.Availability_Message (Avail) =
                "Selected setting is not toggleable.",
              "toggle availability should report non-toggleable settings clearly");

      UI.Selected_Index := Editor.Settings_Management.Index_For_Key
        (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings);
      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Toggle_Selected, Settings, UI);
      Assert (Avail.Available,
              "boolean selected setting should be command-available without payload");

      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Toggle_Selected,
         Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "surface command bridge should execute selected toggle through typed helper");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "surface command bridge should mutate only the selected setting value");

      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Reset_Selected, Settings, UI);
      Assert (Avail.Available,
              "modified selected setting should allow reset-selected");
      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Reset_Selected,
         Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "reset-selected command bridge should restore default");
      Assert (Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "reset-selected command bridge must not touch keybindings/workspace/recent domains");
      Assert (Editor.Settings_Management.Assert_Settings_Command_Availability_Is_Side_Effect_Free,
              "settings command availability must be side-effect-free");
   end Test_Settings_Command_Availability_And_Surface_Execution_Are_Typed;

   procedure Test_Reset_All_Settings_Is_Domain_Local

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      UI       : Editor.Settings_Management.Settings_Editor_State;
      Status   : Editor.Settings_Management.Setting_Update_Status;
      Avail    : Editor.Settings_Management.Settings_Command_Availability;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Reset_All, Settings, UI);
      Assert (not Avail.Available,
              "reset all should be unavailable when every setting is already default");

      Editor.Settings_Management.Set_Setting_Value
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         "false", Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "fixture setting update should succeed");
      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Reset_All, Settings, UI);
      Assert (Avail.Available,
              "reset all should become available when settings differ from defaults");
      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Reset_All,
         Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Confirmation_Required,
              "reset all command bridge should require explicit confirmation");
      Assert (Editor.Settings_Management.Has_Pending_Reset_All (UI),
              "reset all request should create only transient confirmation state");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "reset all request must not mutate settings before confirmation");
      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Confirm_Reset_All,
         Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "confirmed reset all command bridge should execute explicitly");
      Assert (not Editor.Settings_Management.Has_Pending_Reset_All (UI),
              "confirmed reset all should clear transient confirmation state");
      Assert (Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "confirmed reset all settings should restore only settings defaults");
      Assert (Editor.Settings_Management.Assert_Reset_All_Settings_Does_Not_Cross_Domains,
              "reset all settings must not reset keybindings workspace or recent projects");
      Assert (Editor.Settings_Management.Assert_Reset_All_Settings_Command_Requires_Confirmation,
              "reset all settings command must require confirmation before mutation");
   end Test_Reset_All_Settings_Is_Domain_Local;


   procedure Test_Pending_Reset_All_Blocks_Conflicting_Settings_Commands


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings : Editor.Settings.Settings_Model;
      UI       : Editor.Settings_Management.Settings_Editor_State;
      Avail    : Editor.Settings_Management.Settings_Command_Availability;
      Status   : Editor.Settings_Management.Setting_Update_Status;
   begin
      Editor.Settings.Set_Defaults (Settings);
      Editor.Settings_Management.Focus_Settings (UI);
      UI.Selected_Index := Editor.Settings_Management.Index_For_Key
        (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings);
      Editor.Settings_Management.Set_Setting_Value
        (Settings, Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings,
         "false", Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Ok,
              "fixture setting update should succeed before confirmation request");

      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Reset_All, Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Confirmation_Required,
              "reset all should enter transient confirmation state");
      Assert (Editor.Settings_Management.Has_Pending_Reset_All (UI),
              "pending reset confirmation should be visible to availability checks");

      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Toggle_Selected, Settings, UI);
      Assert (not Avail.Available,
              "pending reset confirmation should block conflicting settings edits");
      Assert (Editor.Settings_Management.Availability_Message (Avail) =
                "Command unavailable while confirmation is pending.",
              "blocked command should expose the canonical pending-confirmation reason");

      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Toggle_Selected, Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Blocked_By_Confirmation,
              "conflicting edit command should not execute while confirmation is pending");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "blocked edit must not mutate settings before reset-all confirmation");

      Avail := Editor.Settings_Management.Availability_For
        (Editor.Settings_Management.Settings_Action_Confirm_Reset_All, Settings, UI);
      Assert (Avail.Available,
              "confirm reset all should remain available while confirmation is pending");
      Editor.Settings_Management.Execute_Settings_Surface_Command
        (Editor.Settings_Management.Settings_Action_Cancel_Reset_All, Settings, UI, Status);
      Assert (Status = Editor.Settings_Management.Setting_Update_Confirmation_Cancelled,
              "cancel reset all should clear the transient pending confirmation");
      Assert (not Editor.Settings_Management.Has_Pending_Reset_All (UI),
              "cancel reset all must clear only transient confirmation state");
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (Settings),
              "cancel reset all must not reset or otherwise mutate settings");
   end Test_Pending_Reset_All_Blocks_Conflicting_Settings_Commands;



   procedure Test_Configuration_Audit_Surface_Is_Bounded_Transient_And_Separated



     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      File_Audit    : Editor.Settings_Management.Settings_File_Audit;
      Domain_Audit  : Editor.Settings_Management.Domain_Separation_Audit;
      Command_Audit : Editor.Settings_Management.Settings_Command_Surface_Audit;
      Surface       : Editor.Settings_Management.Configuration_Audit_Surface_Snapshot;
   begin
      File_Audit :=
        (Load_Status            => Editor.Settings.Settings_Ok,
         Supported_Field_Count  => Editor.Settings_Management.Setting_Count,
         Unknown_Field_Count    => 0,
         Invalid_Value_Count    => 0,
         Forbidden_Domain_Count => 0,
         Malformed_Line_Count   => 0);
      Editor.Settings_Management.Audit_Domain_Separation_Text
        ("theme=dark" & ASCII.LF &
         "show-keybindings=true",
         Domain_Audit);
      Editor.Settings_Management.Audit_Settings_Command_Surface (Command_Audit);
      Surface := Editor.Settings_Management.Build_Configuration_Audit_Surface
        (File_Audit, Domain_Audit, Command_Audit);
      Assert (Surface.Row_Count >= 7,
              "configuration audit surface should expose schema/domain/command rows");
      Assert (Surface.Display_Count = Surface.Row_Count,
              "small audit surface should expose every bounded row");
      Assert (Surface.Warning_Count = 0,
              "clean fixture should have no audit warnings");
      Assert (To_String (Surface.Summary) =
                "Configuration audit ok: settings, keybindings, workspace, recent projects, commands, and transient state are separated.",
              "clean audit surface should expose a user-readable ok summary");

      File_Audit.Unknown_Field_Count := 1;
      Editor.Settings_Management.Audit_Domain_Separation_Text
        ("[settings-editor]" & ASCII.LF &
         "settings-query=theme" & ASCII.LF &
         "configuration-audit-result=old" & ASCII.LF &
         "pending-settings-reset-confirmation=true",
         Domain_Audit);
      Surface := Editor.Settings_Management.Build_Configuration_Audit_Surface
        (File_Audit, Domain_Audit, Command_Audit);
      Assert (Surface.Warning_Count >= 2,
              "contaminated audit fixture should expose warnings without repairing state");
      Assert (Surface.Display_Count <= Editor.Settings_Management.Max_Configuration_Audit_Rows,
              "audit surface must remain bounded for render consumption");
      Assert (Editor.Settings_Management.Assert_Configuration_Audit_Surface_Is_Bounded_And_Transient,
              "audit surface helper should verify bounded transient projection");
   end Test_Configuration_Audit_Surface_Is_Bounded_Transient_And_Separated;


   procedure Test_Settings_Command_Catalog_Covers_Surface_Actions_And_No_Payloads


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : constant Editor.Settings_Management.Settings_Command_Catalog_Snapshot :=
        Editor.Settings_Management.Build_Settings_Command_Catalog;
      Seen_Toggle_Selected : Boolean := False;
      Seen_Set_Value       : Boolean := False;
      Seen_Show_Audit      : Boolean := False;
      Seen_Executor_Reset  : Boolean := False;
   begin
      Assert (Catalog.Row_Count = 12,
              "settings command catalog should include executor and typed surface commands");
      Assert (Catalog.Display_Count <= Editor.Settings_Management.Max_Settings_Command_Catalog_Rows,
              "settings command catalog must be bounded for display");
      Assert (Catalog.Executor_Command_Count = 3,
              "save load reset-all should remain canonical executor commands");
      Assert (Catalog.Surface_Command_Count = 9,
              "selected-setting and audit commands should be typed surface actions");
      Assert (Catalog.Payload_Command_Count = 0,
              "settings catalog must not expose key/value payload commands");

      for I in 1 .. Catalog.Display_Count loop
         declare
            Row : constant Editor.Settings_Management.Settings_Command_Catalog_Row :=
              Catalog.Rows (I);
         begin
            Assert (To_String (Row.Stable_Name)'Length > 0,
                    "catalog rows should have stable command names");
            Assert (To_String (Row.Display_Name)'Length > 0,
                    "catalog rows should have display names");
            Assert (To_String (Row.Availability_Hint)'Length > 0,
                    "catalog rows should expose availability hints");
            Assert (Row.No_Payload,
                    "catalog rows should be no-payload by construction");
            Assert (Row.Configuration,
                    "settings catalog rows should be configuration scoped");

            if Row.Action = Editor.Settings_Management.Settings_Action_Toggle_Selected then
               Seen_Toggle_Selected := Row.Requires_Selection and then Row.Surface_Only;
            elsif Row.Action = Editor.Settings_Management.Settings_Action_Set_Selected_Value then
               Seen_Set_Value := Row.Requires_Selection
                 and then Row.Requires_Value
                 and then Row.Surface_Only
                 and then Row.No_Payload;
            elsif Row.Action = Editor.Settings_Management.Settings_Action_Show_Audit then
               Seen_Show_Audit := Row.Surface_Only and then not Row.Requires_Value;
            elsif Row.Action = Editor.Settings_Management.Settings_Action_Reset_All then
               Seen_Executor_Reset := Row.Has_Executor_Command
                 and then Row.Requires_Confirmation;
            end if;
         end;
      end loop;

      Assert (Seen_Toggle_Selected,
              "catalog should expose typed toggle-selected action");
      Assert (Seen_Set_Value,
              "catalog should expose set-selected-value as typed surface input only");
      Assert (Seen_Show_Audit,
              "catalog should expose configuration audit display action");
      Assert (Seen_Executor_Reset,
              "catalog should mark reset-all as executor-backed and confirmation-required");
      Assert (Editor.Settings_Management.Assert_Settings_Command_Catalog_Is_Bounded_And_Payload_Free,
              "catalog coherence helper should pass");
   end Test_Settings_Command_Catalog_Covers_Surface_Actions_And_No_Payloads;




   procedure Test_Settings_Command_Routes_Are_Explicit_And_No_Payload




     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Routes : constant Editor.Settings_Management.Settings_Command_Route_Snapshot :=
        Editor.Settings_Management.Build_Settings_Command_Routes;
      Seen_Save : Boolean := False;
      Seen_Set_Value : Boolean := False;
      Seen_Audit : Boolean := False;
   begin
      Assert (Routes.Row_Count = 12,
              "settings command route table should cover every settings command catalog row");
      Assert (Routes.Executor_Route_Count = 3,
              "save/load/reset-all should be canonical executor routes");
      Assert (Routes.Typed_Surface_Count = 9,
              "selected-setting/audit helpers should remain typed surface routes");
      Assert (Routes.Palette_Route_Count = 3,
              "only executor-backed settings commands should be palette-addressable commands");
      Assert (Routes.Keybinding_Route_Count = 3,
              "only executor-backed settings commands should be keybinding-addressable");
      Assert (Routes.Payload_Route_Count = 0,
              "settings routes must expose no key/value payload route");

      for I in 1 .. Routes.Row_Count loop
         declare
            Row : constant Editor.Settings_Management.Settings_Command_Route_Row :=
              Routes.Rows (I);
         begin
            Assert (To_String (Row.Stable_Name)'Length > 0,
                    "settings route rows should have stable route names");
            Assert (Row.No_Payload,
                    "settings route rows should be payload-free");
            Assert (Row.Executor_Backend /= Row.Typed_Surface,
                    "each settings route should be either executor-backed or typed surface-only");

            if Row.Executor_Backend then
               Assert (Row.Executor_Command /= Editor.Commands.No_Command,
                       "executor-backed route should carry a concrete command id");
               Assert (Row.Palette_Addressable,
                       "executor-backed route should remain command-palette addressable");
               Assert (Row.Keybinding_Addressable,
                       "executor-backed route should remain keybinding addressable by stable name only");
            else
               Assert (Row.Executor_Command = Editor.Commands.No_Command,
                       "typed surface route must not fabricate an executor command id");
               Assert (not Row.Palette_Addressable,
                       "typed surface route must not be command-palette payload-addressable");
               Assert (not Row.Keybinding_Addressable,
                       "typed surface route must not be keybinding payload-addressable");
            end if;

            if Row.Action = Editor.Settings_Management.Settings_Action_Save then
               Seen_Save := Row.Executor_Backend;
            elsif Row.Action = Editor.Settings_Management.Settings_Action_Set_Selected_Value then
               Seen_Set_Value := Row.Typed_Surface and then Row.Requires_Value;
            elsif Row.Action = Editor.Settings_Management.Settings_Action_Show_Audit then
               Seen_Audit := Row.Typed_Surface and then not Row.Requires_Value;
            end if;
         end;
      end loop;

      Assert (Seen_Save, "route table should include executor-backed settings save");
      Assert (Seen_Set_Value, "route table should include typed set-selected-value route");
      Assert (Seen_Audit, "route table should include typed configuration audit route");
      Assert (Editor.Settings_Management.Assert_Settings_Command_Routes_Are_Executor_Or_Typed_Surface_Only,
              "settings route coherence helper should pass");
   end Test_Settings_Command_Routes_Are_Explicit_And_No_Payload;

   procedure Test_Milestone_Helper

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   pragma Unreferenced (T);
   begin
      Assert (Editor.Settings_Management.Assert_Settings_Configuration_Management_Coherent,
              "milestone helper should pass for default settings model");
   end Test_Milestone_Helper;

   procedure Test_Focused_Settings_Keyboard_Routes_Through_Input_Bridge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      UI : Editor.Settings_Management.Settings_Editor_State;
      After : Editor.State.State_Type;
      Selected : constant Natural :=
        Editor.Settings_Management.Index_For_Key
          (Editor.Settings.Setting_Name_Command_Palette_Show_Keybindings);
   begin
      Editor.State.Init (S);
      Editor.Settings_Management.Reset_Transient_State;
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);

      Editor.Settings_Management.Focus_Settings (UI);
      UI.Selected_Index := Selected;
      Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Down));
      UI := Editor.Settings_Management.Current_Settings_Editor_State;
      Assert (UI.Selected_Index /= Selected,
              "Down is consumed by focused settings selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Up));
      UI := Editor.Settings_Management.Current_Settings_Editor_State;
      Assert (UI.Selected_Index = Selected,
              "Up returns focused settings selection");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not Editor.Settings.Command_Palette_Show_Keybindings (After.Settings),
              "Enter toggles the focused selected setting through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Settings.Command_Palette_Show_Keybindings (After.Settings),
              "Delete resets the focused selected setting through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Escape));
      UI := Editor.Settings_Management.Current_Settings_Editor_State;
      Assert (not UI.Visible and then not UI.Focused,
              "Escape hides the focused settings surface");
   end Test_Focused_Settings_Keyboard_Routes_Through_Input_Bridge;

   overriding procedure Register_Tests
     (T : in out Settings_Management_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rows_Expose_Metadata'Access,
         "settings rows expose stable keys, defaults, descriptions, sources and validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_And_Filter_Are_Transient_Projections'Access,
         "settings search/filter are deterministic transient projections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Typed_Edit_Reset_And_Validation'Access,
         "typed setting edit/reset validates values and toggleability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Load_Audit_Reports_Unknown_Invalid_Forbidden'Access,
         "settings file audit reports unknown invalid and forbidden-domain fields");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Domain_Audit_Recognizes_Separation'Access,
         "settings domain audit distinguishes display preferences from forbidden domains");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Transient_Settings_Editor_Selection_Filter_And_Selected_Actions'Access,
         "settings editor selection filter and selected actions are transient and typed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Surface_Snapshot_Is_Render_Facing_And_Observational'Access,
         "settings surface snapshot is bounded render-facing and observational");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Model_Includes_Settings_Surface'Access,
         "render model includes settings surface snapshot");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Current_Settings_Surface_State_Feeds_Render_Snapshot'Access,
         "current transient settings surface state feeds render snapshots without persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Editor_Transient_State_Is_Not_Persisted'Access,
         "settings editor and audit transient state is not settings persistence");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Load_Wrappers_Report_Bounded_Summaries'Access,
         "settings save/load wrappers report bounded summaries and settings-only persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Wrapper_Reports_Forbidden_Domain_Contamination'Access,
         "settings load wrapper reports forbidden domain contamination without applying it");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Command_Surface_Is_Configuration_And_Payload_Free'Access,
         "settings command surface is discoverable configuration-classified and payload-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Command_Availability_And_Surface_Execution_Are_Typed'Access,
         "settings command availability and surface execution are typed and side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_All_Settings_Is_Domain_Local'Access,
         "reset all settings is explicit and domain-local");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Reset_All_Blocks_Conflicting_Settings_Commands'Access,
         "pending reset all confirmation blocks conflicting settings commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Configuration_Audit_Surface_Is_Bounded_Transient_And_Separated'Access,
         "configuration audit surface is bounded transient and domain-separated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Command_Catalog_Covers_Surface_Actions_And_No_Payloads'Access,
         "settings command catalog covers typed surface actions without payloads");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Settings_Command_Routes_Are_Explicit_And_No_Payload'Access,
         "settings command routes are executor-backed or typed surface-only without payloads");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Focused_Settings_Keyboard_Routes_Through_Input_Bridge'Access,
         "focused settings keyboard routes through Input_Bridge");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Milestone_Helper'Access,
         "settings configuration management milestone helper remains coherent");
   end Register_Tests;

end Editor.Settings_Management.Tests;
