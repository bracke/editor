with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Configuration_Audit;
with Editor.Configuration_Recovery;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Input_Bridge;
with Editor.Keybinding_Config;
with Editor.Keybinding_Management;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Render_Packet;
with Editor.Settings;
with Editor.Settings_Management;
with Editor.Startup_Readiness;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Configuration_Audit.Tests is

   use type Editor.Configuration_Audit.Configuration_Audit_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Settings.Settings_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Startup_Readiness.Startup_Domain_Status;
   use type Editor.Startup_Readiness.Startup_Readiness_Label;
   use type Editor.Configuration_Recovery.Configuration_Domain;

   function Temp_Path (Name : String) return String is
   begin
      return "/tmp/editor_phase108_" & Name;
   end Temp_Path;

   procedure Delete_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
      if Ada.Directories.Exists (Path & ".tmp") then
         Ada.Directories.Delete_File (Path & ".tmp");
      end if;
      if Ada.Directories.Exists (Path & ".bak") then
         Ada.Directories.Delete_File (Path & ".bak");
      end if;
   exception
      when others => null;
   end Delete_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Delete_If_Exists (Path);
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Text);
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         raise;
   end Write_File;

   function Read_All (Path : String) return String is
      F : Ada.Text_IO.File_Type;
      R : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Append (R, Ada.Text_IO.Get_Line (F));
         if not Ada.Text_IO.End_Of_File (F) then
            Append (R, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (F);
      return To_String (R);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         raise;
   end Read_All;

   function Chord
     (Key   : Editor.Keybindings.Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => False));
   end Chord;

   procedure Assert_Routes
     (C       : Editor.Keybindings.Key_Chord;
      Command : Editor.Commands.Command_Id;
      Context : String)
   is
      Actual : Editor.Commands.Command_Id;
   begin
      Assert
        (Editor.Keybindings.Resolve (C, Actual) = Editor.Keybindings.Bound_Command,
         Context & " must resolve");
      Assert (Actual = Command, Context & " must route to expected command");
   end Assert_Routes;

   procedure Reset_Global_Config_Test_State is
      Defaults : Editor.Settings.Settings_Model;
   begin
      Ada.Environment_Variables.Clear ("EDITOR_SETTINGS_PATH");
      Ada.Environment_Variables.Clear ("EDITOR_KEYBINDINGS_PATH");
      Editor.Settings_Management.Reset_Transient_State;
      Editor.Keybinding_Management.Reset_Transient_State;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Settings.Set_Defaults (Defaults);
      Editor.Settings.Apply (Defaults);
   end Reset_Global_Config_Test_State;

   procedure Install_Project
     (S    : in out Editor.State.State_Type;
      Root : String;
      Name : String)
   is
      Result : constant Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (Name),
         Error_Text   => Null_Unbounded_String);
   begin
      Editor.Project.Apply_Open_Result (S.Project, Result);
   end Install_Project;

   procedure Save_Custom_Settings
     (Path              : String;
      Theme             : String := "dark";
      Line_Numbers      : String := "relative";
      Show_Keybindings  : Boolean := True)
   is
      Model  : Editor.Settings.Settings_Model;
      Status : Editor.Settings.Settings_Status;
   begin
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Theme_Id (Model, Theme);
      Editor.Settings.Set_Line_Number_Mode_Name (Model, Line_Numbers);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (Model, Show_Keybindings);
      Editor.Settings.Save_To_File (Model, Path, Status);
      Assert (Status = Editor.Settings.Settings_Ok, "settings fixture must save");
   end Save_Custom_Settings;

   procedure Save_Save_File_Keybinding
     (Path : String;
      C    : Editor.Keybindings.Key_Chord)
   is
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
   begin
      Editor.Keybinding_Config.Set_Defaults (Config);
      Editor.Keybinding_Config.Bind (Config, Editor.Commands.Command_Save_File, C);
      Editor.Keybinding_Config.Save_To_File (Config, Path, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
              "keybinding fixture must save");
   end Save_Save_File_Keybinding;

   procedure Simulate_Startup_Config_Load
     (S                : in out Editor.State.State_Type;
      Settings_Path    : String;
      Keybindings_Path : String)
   is
      Settings        : Editor.Settings.Settings_Model;
      Settings_Status : Editor.Settings.Settings_Status;
      Config          : Editor.Keybinding_Config.Keybinding_Config_Model;
      Config_Status   : Editor.Keybinding_Config.Keybinding_Config_Status;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Settings.Load_From_File (Settings_Path, Settings, Settings_Status);
      if Settings_Status = Editor.Settings.Settings_Ok
        or else Settings_Status = Editor.Settings.Settings_Partial_Load
      then
         Editor.State.Apply_Settings (S, Settings);
      else
         Editor.Settings.Set_Defaults (Settings);
         Editor.State.Apply_Settings (S, Settings);
      end if;

      Editor.Keybinding_Config.Load_From_File
        (Keybindings_Path, Config, Config_Status);
      if Config_Status = Editor.Keybinding_Config.Keybinding_Config_Ok
        or else Config_Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load
      then
         Editor.Keybinding_Config.Apply_To_Runtime (Config);
      end if;
   end Simulate_Startup_Config_Load;

   function Name
     (T : Configuration_Audit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Configuration_Audit.Tests");
   end Name;

   overriding procedure Set_Up
     (T : in out Configuration_Audit_Test_Case)
   is
      pragma Unreferenced (T);
   begin
      Reset_Global_Config_Test_State;
   end Set_Up;

   overriding procedure Tear_Down
     (T : in out Configuration_Audit_Test_Case)
   is
      pragma Unreferenced (T);
   begin
      Reset_Global_Config_Test_State;
   end Tear_Down;

   procedure Test_Result_Collects_Domain_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Ok,
         "empty configuration audit must be ok");
      Assert
        (Editor.Configuration_Audit.Summary (Result) = "Configuration audit ok",
         "empty configuration audit summary must be canonical");

      Editor.Configuration_Audit.Add_Failure
        (Result, Editor.Configuration_Audit.Settings_Domain, "unexpected keybinding mutation");
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Failed,
         "failure must change configuration audit status");
      Assert (Editor.Configuration_Audit.Failure_Count (Result) = 1,
              "failure count must include domain failure");
      Assert
        (Editor.Configuration_Audit.Failure (Result, 1) =
           "settings: unexpected keybinding mutation",
         "failure text must be domain-qualified");
      Assert
        (Editor.Configuration_Audit.Summary (Result) =
           "Configuration audit failed: settings: unexpected keybinding mutation",
         "single failure summary must include domain-qualified text");

      Editor.Configuration_Audit.Clear (Result);
      Assert (Editor.Configuration_Audit.Failure_Count (Result) = 0,
              "clear must remove all configuration failures");
   end Test_Result_Collects_Domain_Failures;

   procedure Test_Summary_Reports_Combined_Configuration_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Model : Editor.Settings.Settings_Model;
      Summary : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Bind
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Theme_Id (Model, "light");
      Editor.Settings.Set_Line_Number_Mode_Name (Model, "relative");
      Editor.Settings.Set_Command_Palette_Show_Keybindings (Model, False);
      Editor.State.Apply_Settings (S, Model);
      Install_Project (S, "/tmp/editor-phase108-a", "editor-phase108-a");
      S.File_Info.Dirty := True;
      Editor.Recent_Projects.Clear (S.Recent_Projects);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/editor-phase108-a", "editor-phase108-a", 108);

      Summary := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (To_String (Summary.Theme_Id) = "light",
              "summary must expose active settings theme");
      Assert (To_String (Summary.Line_Number_Mode) = "relative",
              "summary must expose active line-number preference");
      Assert (not Summary.Command_Palette_Show_Keybindings,
              "summary must expose palette keybinding display preference");
      Assert (To_String (Summary.Save_File_Chord) = "Ctrl+Alt+S",
              "summary must expose active custom file.save binding");
      Assert (Summary.Has_Project and then Summary.Recent_Project_Count = 1,
              "summary must expose project/recent separation counters");
      Assert (Summary.Dirty_Buffer_Count = 1,
              "summary must expose dirty-buffer separation counter");
   end Test_Summary_Reports_Combined_Configuration_Surface;

   procedure Test_Clean_Startup_Baseline_Uses_Custom_Settings_And_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("startup_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("startup_keybindings.txt");
      S : Editor.State.State_Type;
      Summary : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Ada.Environment_Variables.Clear ("EDITOR_KEYBINDINGS_PATH");
      Ada.Environment_Variables.Clear ("EDITOR_SETTINGS_PATH");
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Settings.Reset;
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path, Theme => "dark", Line_Numbers => "relative", Show_Keybindings => True);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));

      Simulate_Startup_Config_Load (S, Settings_Path, Keybindings_Path);
      Summary := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (To_String (Summary.Theme_Id) = "dark",
              "startup must apply settings before first snapshot");
      Assert (To_String (Summary.Line_Number_Mode) = "relative",
              "startup must apply configured line-number mode");
      Assert (Summary.Command_Palette_Show_Keybindings,
              "startup must apply palette display preference");
      Assert (To_String (Summary.Save_File_Chord) = "Ctrl+Alt+S",
              "startup must apply active runtime keybinding override");
      Assert_Routes
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         "custom startup file.save chord");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Clean_Startup_Baseline_Uses_Custom_Settings_And_Keybindings;

   procedure Test_Display_Preference_Does_Not_Alter_Routing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("display_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("display_keybindings.txt");
      S : Editor.State.State_Type;
      Before : Editor.Configuration_Audit.Configuration_State_Summary;
      After  : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path, Show_Keybindings => True);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Simulate_Startup_Config_Load (S, Settings_Path, Keybindings_Path);
      Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Save_Custom_Settings (Settings_Path, Show_Keybindings => False);
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Settings_Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Settings);
      After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (Before.Active_Keybinding_Count = After.Active_Keybinding_Count,
              "settings reload must not alter active keybinding count");
      Assert (To_String (After.Save_File_Chord) = "Ctrl+Alt+S",
              "settings reload must not alter custom file.save route");
      Assert (not After.Command_Palette_Show_Keybindings,
              "settings reload may change palette display preference only");
      Assert_Routes
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         "custom route after display setting reload");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Display_Preference_Does_Not_Alter_Routing;

   procedure Test_Invalid_Keybindings_Preserve_Settings_And_Routing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("invalid_key_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("invalid_key_keybindings.txt");
      S : Editor.State.State_Type;
      Before : Editor.Configuration_Audit.Configuration_State_Summary;
      After  : Editor.Configuration_Audit.Configuration_State_Summary;
      Result : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path, Theme => "light", Line_Numbers => "relative", Show_Keybindings => True);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Simulate_Startup_Config_Load (S, Settings_Path, Keybindings_Path);
      Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Write_File (Keybindings_Path, "not-a-keybinding-file" & ASCII.LF);
      Ada.Environment_Variables.Set ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Keybindings);
      After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Result, Before, After, "invalid keybinding reload");
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Ok,
         Editor.Configuration_Audit.Summary (Result));
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "invalid keybinding reload must emit one domain-specific message");
      Assert_Routes
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         "routing after invalid keybinding reload");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Invalid_Keybindings_Preserve_Settings_And_Routing;

   procedure Test_Invalid_Settings_Do_Not_Affect_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("invalid_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("invalid_settings_keybindings.txt");
      S : Editor.State.State_Type;
      Before : Editor.Configuration_Audit.Configuration_State_Summary;
      After  : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path, Theme => "dark", Line_Numbers => "relative", Show_Keybindings => True);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Simulate_Startup_Config_Load (S, Settings_Path, Keybindings_Path);
      Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Write_File (Settings_Path, "not-a-settings-file" & ASCII.LF);
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Settings_Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Settings);
      After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (Before.Active_Keybinding_Count = After.Active_Keybinding_Count,
              "invalid settings reload must not alter keybinding count");
      Assert (To_String (After.Save_File_Chord) = "Ctrl+Alt+S",
              "invalid settings reload must not alter active save binding");
      Assert_Routes
        (Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True),
         Editor.Commands.Command_Save_File,
         "routing after invalid settings reload");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "invalid settings reload must emit one domain-specific message");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Invalid_Settings_Do_Not_Affect_Keybindings;

   procedure Test_Dirty_Pending_State_Survives_Configuration_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("dirty_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("dirty_keybindings.txt");
      S : Editor.State.State_Type;
      Before : Editor.Configuration_Audit.Configuration_State_Summary;
      After  : Editor.Configuration_Audit.Configuration_State_Summary;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/editor-phase108-b"),
         Display    => To_Unbounded_String ("editor-phase108-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Dirty : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));
      Ada.Environment_Variables.Set ("EDITOR_SETTINGS_PATH", Settings_Path);
      Ada.Environment_Variables.Set ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);
      Simulate_Startup_Config_Load (S, Settings_Path, Keybindings_Path);
      Install_Project (S, "/tmp/editor-phase108-a", "editor-phase108-a");
      Editor.State.Load_Text (S, "dirty phase 108 text");
      S.File_Info :=
        (Has_Path     => True,
         Path         => To_Unbounded_String ("/tmp/editor-phase108-a/main.adb"),
         Display_Name => To_Unbounded_String ("main.adb"),
         Dirty        => True,
         others       => <>);
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Dirty);

      Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Settings);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Keybindings);
      After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (Editor.State.Current_Text (S) = "dirty phase 108 text",
              "configuration reloads must not rewrite dirty text");
      Assert (After.Dirty_Buffer_Count = Before.Dirty_Buffer_Count,
              "configuration reloads must not clear dirty state");
      Assert (After.Has_Pending_Transition = Before.Has_Pending_Transition,
              "configuration reloads must not clear pending transition");
      Assert (To_String (After.Save_File_Chord) = "Ctrl+Alt+S",
              "configuration reloads must preserve active keybinding route");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Dirty_Pending_State_Survives_Configuration_Commands;

   procedure Test_Persistence_Exclusions_For_Settings_And_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("exclude_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("exclude_keybindings.txt");
      Settings_Text    : Unbounded_String;
      Keybindings_Text : Unbounded_String;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Save_Custom_Settings (Settings_Path, Theme => "dark", Line_Numbers => "relative", Show_Keybindings => True);
      Save_Save_File_Keybinding
        (Keybindings_Path, Chord (Editor.Keybindings.Key_S, Ctrl => True, Alt => True));

      Settings_Text := To_Unbounded_String (Read_All (Settings_Path));
      Keybindings_Text := To_Unbounded_String (Read_All (Keybindings_Path));

      Assert (Ada.Strings.Fixed.Index (To_String (Settings_Text), "Ctrl+Alt+S") = 0,
              "settings file must not contain keybinding chords");
      Assert (Ada.Strings.Fixed.Index (To_String (Settings_Text), "/tmp/editor-phase108") = 0,
              "settings file must not contain project paths");
      Assert (Ada.Strings.Fixed.Index (To_String (Keybindings_Text), "show-keybindings") = 0,
              "keybindings file must not contain settings keys");
      Assert (Ada.Strings.Fixed.Index (To_String (Keybindings_Text), "line-numbers") = 0,
              "keybindings file must not contain settings-owned keys");
      Assert (Ada.Strings.Fixed.Index (To_String (Keybindings_Text), "/tmp/editor-phase108") = 0,
              "keybindings file must not contain project paths");
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
   end Test_Persistence_Exclusions_For_Settings_And_Keybindings;

   procedure Test_Phase_567_Configuration_Recovery_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Configuration_Recovery_Coherent,
         "phase 567 configuration recovery contract must be coherent");
   end Test_Phase_567_Configuration_Recovery_Coherence;

   procedure Test_Phase_567_Recovery_Surface_Is_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
      Surface : Editor.Configuration_Recovery.Configuration_Recovery_Surface_Snapshot;
   begin
      Summary := (others => <>);
      Editor.Configuration_Recovery.Append
        (Summary,
         Editor.Configuration_Recovery.Status_From_Settings
           (Editor.Settings.Settings_Partial_Load));
      Editor.Configuration_Recovery.Append
        (Summary,
         Editor.Configuration_Recovery.Status_From_Keybindings
           (Editor.Keybinding_Config.Keybinding_Config_Partial_Load));
      Surface := Editor.Configuration_Recovery.Build_Surface_Snapshot (Summary, 2);

      Assert (Surface.Row_Count = 2, "recovery surface must expose domain rows");
      Assert (Surface.Bounded, "recovery surface must stay bounded");
      Assert (Surface.Warning_Count = 2, "recovery surface must count warnings");
      Assert (Surface.Rows (2).Selected, "selection is transient snapshot state only");
      Assert
        (To_String (Surface.Rows (1).Domain_Label) = "Settings",
         "settings recovery status must be displayed");
      Assert
        (To_String (Surface.Rows (2).Domain_Label) = "Keybindings",
         "keybindings recovery status must be displayed");
   end Test_Phase_567_Recovery_Surface_Is_Bounded;



   procedure Test_Phase_567_Recovery_Command_Catalog
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : constant Editor.Configuration_Recovery.Recovery_Command_Catalog :=
        Editor.Configuration_Recovery.Build_Recovery_Command_Catalog;
      Saw_Reset_All : Boolean := False;
      Saw_Save_Clean_Workspace : Boolean := False;
   begin
      Assert (Catalog.Row_Count = Editor.Configuration_Recovery.Max_Recovery_Command_Rows,
              "recovery command catalog must expose bounded recovery actions");
      Assert (Catalog.Payload_Command_Count = 0,
              "recovery commands must not carry command/keybinding payloads");
      Assert (Catalog.Reset_Count = 5,
              "recovery commands must expose four domain resets plus reset-all");
      Assert (Catalog.Save_Clean_Count = 4,
              "recovery commands must expose one save-clean action per persistence domain");
      Assert (Catalog.Confirmation_Count = 3,
              "reset-all must be represented as an explicit confirmation workflow");

      for I in 1 .. Catalog.Row_Count loop
         declare
            Name : constant String := To_String (Catalog.Rows (I).Stable_Name);
         begin
            if Name = "configuration.reset-all" then
               Saw_Reset_All := Catalog.Rows (I).Requires_Confirmation
                 and then Catalog.Rows (I).Reset_Action;
            elsif Name = "configuration.save-clean-workspace" then
               Saw_Save_Clean_Workspace := Catalog.Rows (I).Save_Clean_Action
                 and then Catalog.Rows (I).Domain = Editor.Configuration_Recovery.Workspace_Domain;
            end if;
         end;
      end loop;

      Assert (Saw_Reset_All, "reset-all recovery command must require confirmation");
      Assert (Saw_Save_Clean_Workspace, "workspace save-clean command must be domain-local");
   end Test_Phase_567_Recovery_Command_Catalog;


   procedure Test_Phase_567_Recovery_Commands_Are_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Commands.Command_Category;
      use type Editor.Commands.Command_Visibility;

      procedure Check
        (Id   : Editor.Commands.Command_Id;
         Name : String)
      is
         D     : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Found : Boolean := False;
         Roundtrip : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      begin
         Assert
           (Editor.Commands.Stable_Command_Name (Id) = Name,
            "configuration recovery command stable name must match catalog");
         Assert
           (Found and then Roundtrip = Id,
            "configuration recovery stable name must resolve back to the descriptor id");
         Assert
           (D.Visibility = Editor.Commands.Palette_Command,
            "configuration recovery commands must be discoverable through the palette");
         Assert
           (D.Configuration,
            "configuration recovery commands must be classified as configuration commands");
         Assert
           (not D.Requires_Explicit_Target and then not D.Target_Prompt_Capable,
            "configuration recovery commands must use stable command names without target payloads");
      end Check;
   begin
      Check
        (Editor.Commands.Command_Configuration_Recover_Show,
         "configuration.recover-show");
      Check
        (Editor.Commands.Command_Configuration_Audit,
         "configuration.audit");
      Check
        (Editor.Commands.Command_Configuration_Reset_Settings,
         "configuration.reset-settings");
      Check
        (Editor.Commands.Command_Configuration_Reset_Keybindings,
         "configuration.reset-keybindings");
      Check
        (Editor.Commands.Command_Configuration_Reset_Workspace,
         "configuration.reset-workspace");
      Check
        (Editor.Commands.Command_Configuration_Reset_Recent_Projects,
         "configuration.reset-recent-projects");
      Check
        (Editor.Commands.Command_Configuration_Reset_All,
         "configuration.reset-all");
      Check
        (Editor.Commands.Command_Configuration_Reset_All_Confirm,
         "configuration.reset-all.confirm");
      Check
        (Editor.Commands.Command_Configuration_Reset_All_Cancel,
         "configuration.reset-all.cancel");
      Check
        (Editor.Commands.Command_Configuration_Save_Clean_Settings,
         "configuration.save-clean-settings");
      Check
        (Editor.Commands.Command_Configuration_Save_Clean_Keybindings,
         "configuration.save-clean-keybindings");
      Check
        (Editor.Commands.Command_Configuration_Save_Clean_Workspace,
         "configuration.save-clean-workspace");
      Check
        (Editor.Commands.Command_Configuration_Save_Clean_Recent_Projects,
         "configuration.save-clean-recent-projects");
   end Test_Phase_567_Recovery_Commands_Are_Registered;

   procedure Test_Phase_567_Reset_All_Requires_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Reset_All_Requires_Confirmation,
         "reset-all recovery must do nothing until explicitly confirmed");
   end Test_Phase_567_Reset_All_Requires_Confirmation;


   procedure Test_Phase_567_Recovery_Availability_Is_Domain_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recovery_Command_Availability_Is_Domain_Local,
         "recovery command availability must be based on the affected domain only");
   end Test_Phase_567_Recovery_Availability_Is_Domain_Local;

   procedure Test_Phase_567_Recovery_Summary_Overflow_Is_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recovery_Summary_Overflow_Is_Bounded,
         "recovery summary overflow must be explicit and render rows must stay bounded");
   end Test_Phase_567_Recovery_Summary_Overflow_Is_Bounded;


   procedure Test_Phase_567_Settings_Recovery_Counts_Are_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Settings_Recovery_Counts_Are_Actionable,
         "settings partial recovery must expose defaulted/ignored counts for the recovery surface");
   end Test_Phase_567_Settings_Recovery_Counts_Are_Actionable;

   procedure Test_Phase_567_Recent_Projects_Partial_Load_Is_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recent_Projects_Partial_Load_Is_Preserved,
         "recent-projects partial recovery must preserve valid entries and report ignored entries");
   end Test_Phase_567_Recent_Projects_Partial_Load_Is_Preserved;


   procedure Test_Phase_567_Recorded_Recovery_Summary_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recorded_Recovery_Summary_Is_Transient,
         "recorded recovery summary must be transient and display-oriented only");
   end Test_Phase_567_Recorded_Recovery_Summary_Is_Transient;

   procedure Test_Phase_567_Recovery_Runtime_State_Clear_Is_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recovery_Runtime_State_Clear_Is_Local,
         "clearing recovery runtime state must clear only transient summary and confirmation state");
   end Test_Phase_567_Recovery_Runtime_State_Clear_Is_Local;

   procedure Test_Phase_567_Clean_Summary_Disables_Reset_And_Save_Clean
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Clean_Summary_Disables_Reset_And_Save_Clean,
         "clean recovery summaries must disable reset and save-clean recovery commands");
   end Test_Phase_567_Clean_Summary_Disables_Reset_And_Save_Clean;

   procedure Test_Phase_567_Domain_Local_Status_Record_Is_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Domain_Local_Status_Record_Is_Bounded,
         "domain-local command status recording must stay bounded and avoid fabricated audit rows");
   end Test_Phase_567_Domain_Local_Status_Record_Is_Bounded;


   procedure Test_Phase_567_Save_Clean_Failure_Status_Is_Exception_Contained
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Save_Clean_Failure_Status_Is_Exception_Contained,
         "save-clean failure status must stay exception-contained and domain-local");
   end Test_Phase_567_Save_Clean_Failure_Status_Is_Exception_Contained;

   procedure Test_Phase_567_Recovery_Messages_Are_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recovery_Messages_Are_Bounded,
         "recovery messages must be bounded before snapshot/recording");
   end Test_Phase_567_Recovery_Messages_Are_Bounded;

   procedure Test_Phase_567_Recovery_Availability_Blocks_Pending_Reset_All
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Recovery_Availability_Blocks_Domain_Mutation_While_Pending,
         "pending reset-all confirmation must block domain-local reset/save-clean mutations");
   end Test_Phase_567_Recovery_Availability_Blocks_Pending_Reset_All;

   procedure Test_Phase_567_Reset_All_Keybinding_Failure_Not_Fabricated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Configuration_Recovery.Assert_Reset_All_Keybinding_Failure_Status_Is_Not_Fabricated,
         "reset-all confirmation must not report keybindings defaults when keybinding reset fails");
   end Test_Phase_567_Reset_All_Keybinding_Failure_Not_Fabricated;


   procedure Test_Phase_577_Buffer_Boundary_Audit_Is_Configuration_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S,
         "workspace-format-version=1" & ASCII.LF
         & "open-file path=src/main.adb" & ASCII.LF);

      Assert (Summary.Buffer_Metadata_Coherent,
              "configuration audit must expose coherent buffer metadata projection");
      Assert (Summary.Active_Buffer_Valid,
              "configuration audit must expose active-buffer validity");
      Assert (Summary.Selected_Buffer_Valid,
              "configuration audit must expose selected-buffer validity");
      Assert (Summary.Workspace_Persistence_Safe,
              "configuration audit must expose workspace buffer persistence safety");
      Assert (Summary.Command_Keybinding_Payloads_Clear,
              "configuration audit must expose command/keybinding payload safety");
      Assert (Summary.Render_Boundary_Safe,
              "configuration audit must expose render boundary safety");
      Assert (Summary.Audit_Side_Effect_Free,
              "configuration audit must expose audit side-effect freedom");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S,
         "workspace-format-version=1" & ASCII.LF
         & "open-file path=src/main.adb" & ASCII.LF);
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Ok,
         Editor.Configuration_Audit.Summary (Result));
   end Test_Phase_577_Buffer_Boundary_Audit_Is_Configuration_Surface;

   procedure Test_Phase_577_Configuration_Audit_Fails_Forbidden_Buffer_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S,
         "runtime-buffer-id=42" & ASCII.LF
         & "active-runtime-buffer-id=42" & ASCII.LF
         & "selected-runtime-buffer-id=42" & ASCII.LF
         & "buffer-list-selection=42" & ASCII.LF
         & "dirty-text=modified contents" & ASCII.LF
         & "scratch-text=unsaved contents" & ASCII.LF
         & "conflict-token=opaque" & ASCII.LF
         & "close-prompt=discard" & ASCII.LF
         & "undo-stack=..." & ASCII.LF);

      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Failed,
         "configuration audit must fail when workspace text contains forbidden buffer runtime state");
      Assert
        (Editor.Configuration_Audit.Failure_Count (Result) >= 9,
         "forbidden runtime id, Buffer List, dirty/scratch text, conflict prompt, and undo state must produce audit rows");
      Assert
        (Ada.Strings.Fixed.Index
           (Editor.Configuration_Audit.Summary (Result),
            "Configuration audit failed") > 0,
         "failure summary must surface the Phase 577 buffer boundary audit");
   end Test_Phase_577_Configuration_Audit_Fails_Forbidden_Buffer_Persistence;

   procedure Test_Phase_577_Configuration_Audit_Inspects_Real_Buffer_List_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed  : Boolean := False;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/editor-phase577/selected.adb", "selected.adb", "procedure Selected is begin null; end;", Id);
      Editor.Buffers.Global_Set_Active_Buffer (Id);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For (S);
      Assert (Summary.Selected_Buffer_Valid
                and then Summary.Buffer_List_Selected_Row_Valid
                and then Summary.Buffer_List_Selected_Runtime_Id_Registered
                and then Summary.Buffer_List_Selection_Is_Transient,
              "Phase 577 configuration audit inspects valid real Buffer List selection state");

      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      Assert (Closed, "test setup closes selected global buffer without recomputing Buffer List rows");
      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For (S);
      Assert (not Summary.Selected_Buffer_Valid
                and then not Summary.Buffer_List_Selected_Row_Valid
                and then not Summary.Buffer_List_Selected_Runtime_Id_Registered,
              "Phase 577 configuration audit rejects stale selected Buffer List runtime ids");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries (Result, S);
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Failed,
              "Phase 577 configuration audit surfaces stale Buffer List selection as an audit failure");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase_577_Configuration_Audit_Inspects_Real_Buffer_List_Selection;



   function Phase577_Pending_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   end Phase577_Pending_Summary;

   procedure Test_Phase_577_Pending_Transition_Runtime_Id_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Target  : Editor.Pending_Transitions.Pending_Transition_Target := (others => <>);
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Target.Kind := Editor.Pending_Transitions.Pending_Close_Buffer;
      Target.Display := To_Unbounded_String ("dirty.adb");
      Target.Buffer_Id := 42;
      Target.Has_Buffer := True;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Phase577_Pending_Summary);

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S, "workspace-format-version=1" & ASCII.LF);
      Assert (Summary.Pending_Transition_Boundary_Safe,
              "pending transition runtime buffer ids must stay inside the transient boundary");
      Assert (Summary.Pending_Runtime_Buffer_Id_Transient,
              "pending transition runtime buffer ids must be classified as transient only");
      Assert (Summary.Pending_Buffer_Id_Not_Persisted,
              "pending transition runtime buffer ids must not cross the persistence boundary");
      Assert (Summary.Pending_Buffer_Id_Not_Command_Payload,
              "pending transition runtime buffer ids must not become command payloads");
      Assert (Summary.Pending_Buffer_Id_Not_Keybinding_Payload,
              "pending transition runtime buffer ids must not become keybinding payloads");
      Assert (Summary.Pending_Buffer_Id_Not_Render_Payload,
              "pending transition runtime buffer ids must not be rendered as structured payloads");
      Assert (Summary.Pending_Target_Revalidated_Before_Mutation,
              "pending transition runtime ids must have a revalidation key before mutation");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Ok,
              Editor.Configuration_Audit.Summary (Result));
   end Test_Phase_577_Pending_Transition_Runtime_Id_Is_Transient;

   procedure Test_Phase_577_Pending_Transition_File_Token_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Target  : Editor.Pending_Transitions.Pending_Transition_Target := (others => <>);
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Target.Kind := Editor.Pending_Transitions.Pending_Reload_Active_Buffer;
      Target.Display := To_Unbounded_String ("reload.adb");
      Target.Buffer_Id := 77;
      Target.Has_Buffer := True;
      Target.Path := To_Unbounded_String ("/tmp/editor-phase577/reload.adb");
      Target.Has_Path := True;
      Target.Observed_File_Status_Code := 2;
      Target.Has_Observed_File_Status := True;
      Target.Observed_File_Token_Label := To_Unbounded_String ("opaque-file-token-77");
      Target.Has_Observed_File_Token := True;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Phase577_Pending_Summary);

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S, "workspace-format-version=1" & ASCII.LF);
      Assert (Summary.Pending_Transition_Boundary_Safe,
              "pending file conflict tokens must stay inside the transient boundary");
      Assert (Summary.Pending_File_Conflict_Token_Transient,
              "pending file conflict tokens must be classified as transient only");
      Assert (Summary.Pending_File_Token_Not_Persisted,
              "pending file conflict tokens must not cross the persistence boundary");
      Assert (Summary.Pending_File_Token_Not_Rendered,
              "pending file conflict tokens must not be rendered to the user as opaque tokens");
      Assert (Summary.Pending_Target_Revalidated_Before_Mutation,
              "pending reload/revert tokens must have a revalidation key before mutation");
   end Test_Phase_577_Pending_Transition_File_Token_Is_Transient;

   procedure Test_Phase_577_Pending_Transition_Render_Payload_Leak_Fails_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target := (others => <>);
      Result : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Target.Kind := Editor.Pending_Transitions.Pending_Close_Buffer;
      Target.Display := To_Unbounded_String ("runtime_buffer_id=42");
      Target.Buffer_Id := 42;
      Target.Has_Buffer := True;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Phase577_Pending_Summary);

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Failed,
              "configuration audit must fail when pending prompt display exposes a structured runtime buffer payload");
   end Test_Phase_577_Pending_Transition_Render_Payload_Leak_Fails_Audit;


   procedure Test_Phase_577_File_Conflict_Prompt_Token_Is_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      S.File_Conflict_Prompt_Active := True;
      S.File_Conflict_Prompt_Buffer := 91;
      S.File_Conflict_Prompt_Path := To_Unbounded_String ("/tmp/editor-phase577/conflicted.adb");
      S.File_Conflict_Prompt_Display := To_Unbounded_String ("conflicted.adb");
      S.File_Conflict_Prompt_Kind := Editor.State.External_Modified_While_Dirty;
      S.File_Conflict_Prompt_Dirty := True;
      S.File_Conflict_Prompt_Buffer_Revision := 17;
      S.File_Conflict_Prompt_Token_Label := To_Unbounded_String ("opaque-conflict-token-91");

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S, "workspace-format-version=1" & ASCII.LF);
      Assert (Summary.File_Conflict_Prompt_Boundary_Safe,
              "file conflict prompt runtime state must stay inside the transient boundary");
      Assert (Summary.File_Conflict_Prompt_Transient,
              "file conflict prompt must be classified as transient only");
      Assert (Summary.File_Conflict_Prompt_Buffer_Id_Not_Persisted,
              "file conflict prompt buffer id must not cross persistence boundary");
      Assert (Summary.File_Conflict_Prompt_Buffer_Id_Not_Command_Payload,
              "file conflict prompt buffer id must not become a command payload");
      Assert (Summary.File_Conflict_Prompt_Buffer_Id_Not_Keybinding_Payload,
              "file conflict prompt buffer id must not become a keybinding payload");
      Assert (Summary.File_Conflict_Prompt_Buffer_Id_Not_Render_Payload,
              "file conflict prompt buffer id must not be rendered as a structured payload");
      Assert (Summary.File_Conflict_Prompt_Token_Not_Persisted,
              "file conflict prompt token must not cross persistence boundary");
      Assert (Summary.File_Conflict_Prompt_Token_Not_Rendered,
              "file conflict prompt token must not be rendered as an opaque token");
      Assert (Summary.File_Conflict_Prompt_Display_Hides_Runtime_Buffer_Id,
              "file conflict prompt display must hide runtime buffer id markers");
      Assert (Summary.File_Conflict_Prompt_Display_Hides_File_Token,
              "file conflict prompt display must hide file token labels");
      Assert (Summary.File_Conflict_Prompt_Revalidated_Before_Mutation,
              "file conflict prompt must carry enough transient state for confirmation-time revalidation");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Ok,
              Editor.Configuration_Audit.Summary (Result));
   end Test_Phase_577_File_Conflict_Prompt_Token_Is_Transient;

   procedure Test_Phase_577_File_Conflict_Prompt_Missing_Revalidation_Fails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      S.File_Conflict_Prompt_Active := True;
      S.File_Conflict_Prompt_Buffer := 0;
      S.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.File_Conflict_Prompt_Display := To_Unbounded_String ("conflicted.adb");
      S.File_Conflict_Prompt_Kind := Editor.State.External_Modified_While_Dirty;
      S.File_Conflict_Prompt_Dirty := True;
      S.File_Conflict_Prompt_Buffer_Revision := 17;
      S.File_Conflict_Prompt_Token_Label := To_Unbounded_String ("opaque-conflict-token-91");

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S, "workspace-format-version=1" & ASCII.LF);
      Assert (not Summary.File_Conflict_Prompt_Boundary_Safe,
              "file conflict prompt without buffer/path revalidation key must fail boundary audit");
      Assert (not Summary.File_Conflict_Prompt_Revalidated_Before_Mutation,
              "file conflict prompt without revalidation key must fail mutation-readiness audit");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Failed,
              "configuration audit must fail stale file conflict prompt state");
   end Test_Phase_577_File_Conflict_Prompt_Missing_Revalidation_Fails;


   procedure Test_Phase_577_Preservation_Audit_Does_Not_Mutate_Project_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Project : Editor.State.Project_Scoped_State_Summary;
      After_Project  : Editor.State.Project_Scoped_State_Summary;
      Before_Config  : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Config   : Editor.Configuration_Audit.Configuration_State_Summary;
      Summary        : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result         : Editor.Configuration_Audit.Configuration_Audit_Result;
      Serialized     : constant String :=
        "workspace-format-version=1" & ASCII.LF
        & "open-file path=/tmp/editor-phase577/runtime_buffer_id_notes.adb" & ASCII.LF
        & "active-file path=/tmp/editor-phase577/runtime_buffer_id_notes.adb" & ASCII.LF;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Project_Search.Set_Query (S.Project_Search, "phase577 preserve");
      Editor.Project_Search.Set_Status
        (S.Project_Search, Editor.Project_Search.Project_Search_Ok);

      Before_Project := Editor.State.Project_Scoped_State_Summary_For (S);
      Before_Config  := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For (S, Serialized);
      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, Serialized);

      After_Project := Editor.State.Project_Scoped_State_Summary_For (S);
      After_Config  := Editor.Configuration_Audit.Configuration_State_Summary_For (S);

      Assert (Summary.Workspace_Persistence_Safe,
              "Phase 577 preservation audit must structurally accept path values containing forbidden-looking words");
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Ok,
              Editor.Configuration_Audit.Summary (Result));
      Assert (After_Project.Feature_Panel_Row_Count = Before_Project.Feature_Panel_Row_Count,
              "Phase 577 preservation audit must not clear Feature Panel rows");
      Assert (After_Project.Feature_Panel_Selected_Row = Before_Project.Feature_Panel_Selected_Row,
              "Phase 577 preservation audit must not change Feature Panel selection");
      Assert (After_Project.Feature_Panel_Visible = Before_Project.Feature_Panel_Visible,
              "Phase 577 preservation audit must not hide Feature Panel");
      Assert (After_Project.Feature_Panel_Focused = Before_Project.Feature_Panel_Focused,
              "Phase 577 preservation audit must not move Feature Panel focus");
      Assert (After_Project.Has_Project_Search_Query = Before_Project.Has_Project_Search_Query,
              "Phase 577 preservation audit must not clear Project Search query state");
      Assert (After_Config.Theme_Id = Before_Config.Theme_Id
                and then After_Config.Line_Number_Mode = Before_Config.Line_Number_Mode
                and then After_Config.Cursor_Blink_Enabled = Before_Config.Cursor_Blink_Enabled,
              "Phase 577 preservation audit must not mutate settings state");
      Assert (After_Config.Active_Keybinding_Count = Before_Config.Active_Keybinding_Count
                and then After_Config.Save_File_Chord = Before_Config.Save_File_Chord
                and then After_Config.Command_Palette_Chord = Before_Config.Command_Palette_Chord,
              "Phase 577 preservation audit must not mutate keybinding state");
      Assert (After_Config.Dirty_Buffer_Count = Before_Config.Dirty_Buffer_Count
                and then After_Config.Has_Pending_Transition = Before_Config.Has_Pending_Transition,
              "Phase 577 preservation audit must not mutate dirty or pending lifecycle state");
   end Test_Phase_577_Preservation_Audit_Does_Not_Mutate_Project_Transient_State;

   procedure Test_Phase_577_Preservation_Workspace_Serialization_Does_Not_Persist_Runtime_UI_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Snapshot   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Serialized : Unbounded_String;
      Audit      : Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit;
      Result     : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/tmp/editor-phase577/preserved.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("preserved.adb");
      S.File_Info.Dirty := True;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Project_Search.Set_Query (S.Project_Search, "not persisted");
      S.Dirty_Close_Prompt_Active := True;
      S.Dirty_Close_Prompt_Buffer := 1234;
      S.Dirty_Close_Prompt_Buffer_Ids := To_Unbounded_String ("1234");

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Serialized := To_Unbounded_String
        (Editor.Workspace_Persistence.Serialized_Text (Snapshot));
      Audit := Editor.Workspace_Persistence.Audit_Serialized_Buffer_Persistence
        (To_String (Serialized));

      Assert (Audit.Safe,
              "Phase 577 preservation: workspace serializer must exclude runtime UI and close prompt state");
      Assert (not Audit.Runtime_Buffer_Id_Persisted
                and then not Audit.Selected_Buffer_Id_Persisted
                and then not Audit.Buffer_List_State_Persisted,
              "Phase 577 preservation: workspace serializer must exclude runtime buffer/list identities");
      Assert (not Audit.Dirty_Text_Persisted
                and then not Audit.Scratch_Text_Persisted
                and then not Audit.Close_Prompt_State_Persisted,
              "Phase 577 preservation: workspace serializer must exclude dirty text, scratch text, and close prompt state");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, To_String (Serialized));
      Assert (Editor.Configuration_Audit.Status (Result) =
                Editor.Configuration_Audit.Configuration_Audit_Ok,
              Editor.Configuration_Audit.Summary (Result));
   end Test_Phase_577_Preservation_Workspace_Serialization_Does_Not_Persist_Runtime_UI_State;

   procedure Test_Phase_577_Render_Boundary_Is_Deeply_Audited
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Render  : constant Editor.Render_Packet.Buffer_Metadata_Render_Boundary_Audit :=
        Editor.Render_Packet.Audit_Buffer_Metadata_Render_Boundary;
      Summary : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Assert (Render.Uses_Metadata_Snapshots_Only,
              "render must use precomputed buffer metadata snapshots only");
      Assert (Render.Does_Not_Switch_Buffers,
              "render must not switch buffers");
      Assert (Render.Does_Not_Close_Buffers,
              "render must not close buffers");
      Assert (Render.Does_Not_Save_Reload_Revert,
              "render must not save reload or revert buffers");
      Assert (Render.Does_Not_Probe_Filesystem,
              "render must not probe filesystem for buffer metadata");
      Assert (Render.Does_Not_Classify_By_Mutation,
              "render must not classify ownership or lifecycle by mutating state");
      Assert (Render.Does_Not_Expose_Runtime_Buffer_Ids,
              "render must not expose runtime buffer ids");
      Assert (Render.Buffer_List_Metadata_Projection_Only,
              "Buffer List render metadata must be snapshot-only");
      Assert (Render.Active_Buffer_Metadata_Projection_Only,
              "active-buffer render metadata must be snapshot-only");
      Assert (Editor.Render_Packet.Assert_Buffer_Metadata_Render_Boundary_Safe,
              "aggregate render boundary assertion must pass");

      Summary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S, "workspace-format-version=1" & ASCII.LF);

      Assert (Summary.Render_Boundary_Safe,
              "configuration audit must include aggregate render boundary safety");
      Assert (Summary.Render_Uses_Metadata_Snapshots_Only,
              "configuration audit must expose snapshot-only render metadata rule");
      Assert (Summary.Render_Does_Not_Switch_Buffers,
              "configuration audit must expose no render buffer switching rule");
      Assert (Summary.Render_Does_Not_Close_Buffers,
              "configuration audit must expose no render buffer close rule");
      Assert (Summary.Render_Does_Not_Save_Reload_Revert,
              "configuration audit must expose no render save/reload/revert rule");
      Assert (Summary.Render_Does_Not_Probe_Filesystem,
              "configuration audit must expose no render filesystem probe rule");
      Assert (Summary.Render_Does_Not_Classify_By_Mutation,
              "configuration audit must expose no render mutation-classification rule");
      Assert (Summary.Render_Does_Not_Expose_Runtime_Buffer_Ids,
              "configuration audit must expose no render runtime-id exposure rule");
      Assert (Summary.Render_Buffer_List_Metadata_Projection_Only,
              "configuration audit must expose Buffer List metadata projection rule");
      Assert (Summary.Render_Active_Buffer_Metadata_Projection_Only,
              "configuration audit must expose active-buffer metadata projection rule");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Ok,
         Editor.Configuration_Audit.Summary (Result));
   end Test_Phase_577_Render_Boundary_Is_Deeply_Audited;

   procedure Test_Phase_577_Completion_Assertion_Covers_All_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Configuration_Audit.Configuration_Audit_Result;
   begin
      Editor.State.Init (S);

      Assert
        (Editor.Configuration_Audit.Phase_577_Buffer_Metadata_Lifecycle_Complete
           (S, "workspace-format-version=1" & ASCII.LF),
         "Phase 577 completion assertion must pass for a clean safe boundary");

      Editor.Configuration_Audit.Audit_Buffer_Metadata_Lifecycle_Boundaries
        (Result, S, "workspace-format-version=1" & ASCII.LF);
      Assert
        (Editor.Configuration_Audit.Status (Result) =
           Editor.Configuration_Audit.Configuration_Audit_Ok,
         Editor.Configuration_Audit.Summary (Result));

      Assert
        (not Editor.Configuration_Audit.Phase_577_Buffer_Metadata_Lifecycle_Complete
           (S, "workspace-format-version=1" & ASCII.LF
             & "runtime-buffer-id=42" & ASCII.LF),
         "Phase 577 completion assertion must fail when a runtime buffer id is serialized");
   end Test_Phase_577_Completion_Assertion_Covers_All_Boundaries;

   procedure Test_Phase_578_Startup_Recovery_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Settings_Path    : constant String := Temp_Path ("phase578_missing_settings.txt");
      Keybindings_Path : constant String := Temp_Path ("phase578_malformed_keybindings.txt");
      Workspace_Path   : constant String := Temp_Path ("phase578_malformed_workspace.txt");
      Recent_Path      : constant String := Temp_Path ("phase578_missing_recent.txt");
      Settings         : Editor.Settings.Settings_Model;
      Keybindings      : Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace        : Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent           : Editor.Recent_Projects.Recent_Project_List;
      Startup          : Editor.Startup_Readiness.Startup_Summary;
      Recovery         : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
      Surface          : Editor.Configuration_Recovery.Configuration_Recovery_Surface_Snapshot;
      S                : Editor.State.State_Type;
      Before           : Editor.Configuration_Audit.Configuration_State_Summary;
      After            : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
      Write_File
        (Keybindings_Path,
         "this is not a supported keybinding file" & ASCII.LF &
         "payload=src/should-not-be-restored.adb" & ASCII.LF);
      Write_File
        (Workspace_Path,
         "this is not a supported workspace file" & ASCII.LF &
         "project-root=/tmp/phase578-fabricated-project" & ASCII.LF &
         "open-file=/tmp/phase578-fabricated-file.adb" & ASCII.LF &
         "diagnostic=transient" & ASCII.LF);

      Editor.Startup_Readiness.Clear_Startup_Summary;
      Editor.Configuration_Recovery.Clear_Recovery_Runtime_State;
      Editor.Startup_Readiness.Startup_Run
        (Settings_Path,
         Keybindings_Path,
         Workspace_Path,
         Recent_Path,
         (Restore_Workspace_On_Startup => True),
         Settings,
         Keybindings,
         Workspace,
         Recent,
         Startup);

      Assert (Startup.Bounded, "Phase 578 startup recovery summary must be bounded");
      Assert (Startup.Transient, "Phase 578 startup recovery summary must be transient");
      Assert (Startup.Row_Count = Editor.Startup_Readiness.Max_Startup_Domain_Rows,
              "Phase 578 startup recovery must describe all startup domains");
      Assert (Startup.Rows (1).Status =
                Editor.Startup_Readiness.Startup_Missing_Optional_File,
              "missing settings must be reported without failing startup");
      Assert (Startup.Rows (2).Status =
                Editor.Startup_Readiness.Startup_Defaulted,
              "malformed keybindings must fall back to defaults");
      Assert (Startup.Rows (3).Status =
                Editor.Startup_Readiness.Startup_Restore_Failed,
              "malformed workspace must not restore fabricated state");
      Assert (Startup.Rows (4).Status =
                Editor.Startup_Readiness.Startup_Missing_Optional_File,
              "missing recent-projects file must be optional");
      Assert (Startup.Safe_Default_Domain_Count >= 2,
              "missing/malformed startup domains must activate safe defaults");
      Assert (Startup.Warning_Count > 0,
              "startup recovery summary must expose recovery warnings");
      Assert (Editor.Startup_Readiness.Has_Recorded_Startup_Summary,
              "startup run must record a transient startup summary");

      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Workspace),
              "malformed workspace must not fabricate a project root");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Workspace) = 0,
              "malformed workspace must not fabricate open files");
      Assert (Editor.Recent_Projects.Count (Recent) = 0,
              "missing recent projects must leave an empty recent list");

      Editor.State.Init (S);
      Editor.State.Apply_Settings (S, Settings);
      Editor.Keybinding_Config.Apply_To_Runtime (Keybindings);
      Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (not Before.Has_Project,
              "safe startup must leave no active project when workspace recovery fails");
      Assert (not S.File_Info.Has_Path,
              "safe startup must leave no fabricated active file path");
      Assert (not S.File_Info.Dirty,
              "safe startup must not fabricate dirty buffer text");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "startup recovery must not restore pending confirmations");

      Recovery := Editor.Startup_Readiness.Configuration_Recovery_View (Startup);
      Surface := Editor.Configuration_Recovery.Build_Surface_Snapshot (Recovery, 1);
      Assert (Recovery.Bounded and then Surface.Bounded,
              "configuration recovery view must remain bounded");
      Assert (Recovery.Domain_Count <= Editor.Configuration_Recovery.Max_Recovery_Domains,
              "configuration recovery view must fit the recovery surface");
      Assert (Recovery.Rows (1).Domain =
                Editor.Configuration_Recovery.Settings_Domain,
              "recovery view must keep settings as a configuration domain");
      Assert (Recovery.Rows (2).Domain =
                Editor.Configuration_Recovery.Keybindings_Domain,
              "recovery view must keep keybindings as a configuration domain");
      Assert (Recovery.Rows (3).Domain =
                Editor.Configuration_Recovery.Workspace_Domain,
              "recovery view must keep workspace as a configuration domain");
      Assert (Surface.Row_Count = Recovery.Domain_Count,
              "recovery surface must project exactly the bounded recovery rows");
      Assert (To_String (Surface.Summary_Label)'Length > 0,
              "recovery surface must provide a bounded summary label");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Configuration_Recover_Show);
      After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (not After.Has_Project,
              "opening configuration recovery must not open a project");
      Assert (After.Recent_Project_Count = Before.Recent_Project_Count,
              "opening configuration recovery must not mutate recent projects");
      Assert (After.Dirty_Buffer_Count = Before.Dirty_Buffer_Count,
              "opening configuration recovery must not fabricate dirty buffers");
      Assert (After.Has_Pending_Transition = Before.Has_Pending_Transition,
              "opening configuration recovery must not restore pending transitions");
      Assert (Editor.Configuration_Recovery.Has_Recorded_Recovery_Summary,
              "configuration recovery show must record only a transient recovery summary");
      declare
         Recorded : constant Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
           Editor.Configuration_Recovery.Current_Recovery_Summary;
      begin
         Assert (Recorded.Bounded,
                 "recorded recovery summary must stay bounded");
      end;

      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
   end Test_Phase_578_Startup_Recovery_Dogfood_Scenario;

   overriding procedure Register_Tests
     (T : in out Configuration_Audit_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Result_Collects_Domain_Failures'Access,
         "result collects domain failures");
      Register_Routine
        (T, Test_Summary_Reports_Combined_Configuration_Surface'Access,
         "summary reports combined configuration surface");
      Register_Routine
        (T, Test_Clean_Startup_Baseline_Uses_Custom_Settings_And_Keybindings'Access,
         "clean startup baseline uses custom settings and keybindings");
      Register_Routine
        (T, Test_Display_Preference_Does_Not_Alter_Routing'Access,
         "display preference does not alter routing");
      Register_Routine
        (T, Test_Invalid_Keybindings_Preserve_Settings_And_Routing'Access,
         "invalid keybindings preserve settings and routing");
      Register_Routine
        (T, Test_Invalid_Settings_Do_Not_Affect_Keybindings'Access,
         "invalid settings do not affect keybindings");
      Register_Routine
        (T, Test_Dirty_Pending_State_Survives_Configuration_Commands'Access,
         "dirty pending state survives configuration commands");
      Register_Routine
        (T, Test_Persistence_Exclusions_For_Settings_And_Keybindings'Access,
         "persistence exclusions for settings and keybindings");
      Register_Routine
        (T, Test_Phase_567_Configuration_Recovery_Coherence'Access,
         "phase 567 configuration recovery coherence");
      Register_Routine
        (T, Test_Phase_567_Recovery_Surface_Is_Bounded'Access,
         "phase 567 recovery surface is bounded");
      Register_Routine
        (T, Test_Phase_567_Recovery_Command_Catalog'Access,
         "phase 567 recovery command catalog is bounded and payload-free");
      Register_Routine
        (T, Test_Phase_567_Recovery_Commands_Are_Registered'Access,
         "phase 567 recovery commands are registered descriptors");
      Register_Routine
        (T, Test_Phase_567_Reset_All_Requires_Confirmation'Access,
         "phase 567 reset all requires confirmation");
      Register_Routine
        (T, Test_Phase_567_Recovery_Availability_Is_Domain_Local'Access,
         "phase 567 recovery availability is domain-local");
      Register_Routine
        (T, Test_Phase_567_Recovery_Summary_Overflow_Is_Bounded'Access,
         "phase 567 recovery summary overflow is bounded");
      Register_Routine
        (T, Test_Phase_567_Settings_Recovery_Counts_Are_Actionable'Access,
         "phase 567 settings recovery counts are actionable");
      Register_Routine
        (T, Test_Phase_567_Recent_Projects_Partial_Load_Is_Preserved'Access,
         "phase 567 recent projects partial load is preserved");
      Register_Routine
        (T, Test_Phase_567_Recorded_Recovery_Summary_Is_Transient'Access,
         "phase 567 recorded recovery summary is transient");
      Register_Routine
        (T, Test_Phase_567_Recovery_Runtime_State_Clear_Is_Local'Access,
         "phase 567 recovery runtime state clear is local");
      Register_Routine
        (T, Test_Phase_567_Clean_Summary_Disables_Reset_And_Save_Clean'Access,
         "phase 567 clean summary disables reset and save clean");
      Register_Routine
        (T, Test_Phase_567_Domain_Local_Status_Record_Is_Bounded'Access,
         "phase 567 domain local status record is bounded");
      Register_Routine
        (T, Test_Phase_567_Save_Clean_Failure_Status_Is_Exception_Contained'Access,
         "phase 567 save clean failure status is exception contained");
      Register_Routine
        (T, Test_Phase_567_Recovery_Messages_Are_Bounded'Access,
         "phase 567 recovery messages are bounded");
      Register_Routine
        (T, Test_Phase_567_Recovery_Availability_Blocks_Pending_Reset_All'Access,
         "phase 567 recovery availability blocks pending reset all");
      Register_Routine
        (T, Test_Phase_567_Reset_All_Keybinding_Failure_Not_Fabricated'Access,
         "phase 567 reset all keybinding failure is not fabricated");
      Register_Routine
        (T, Test_Phase_577_Buffer_Boundary_Audit_Is_Configuration_Surface'Access,
         "phase 577 buffer boundary audit is exposed by configuration audit");
      Register_Routine
        (T, Test_Phase_577_Configuration_Audit_Inspects_Real_Buffer_List_Selection'Access,
         "phase 577 configuration audit inspects real Buffer List selection");
      Register_Routine
        (T, Test_Phase_577_Configuration_Audit_Fails_Forbidden_Buffer_Persistence'Access,
         "phase 577 configuration audit fails forbidden buffer persistence");
      Register_Routine
        (T, Test_Phase_577_Pending_Transition_Runtime_Id_Is_Transient'Access,
         "phase 577 pending transition runtime buffer id is transient");
      Register_Routine
        (T, Test_Phase_577_Pending_Transition_File_Token_Is_Transient'Access,
         "phase 577 pending transition file token is transient");
      Register_Routine
        (T, Test_Phase_577_Pending_Transition_Render_Payload_Leak_Fails_Audit'Access,
         "phase 577 pending transition render payload leak fails audit");
      Register_Routine
        (T, Test_Phase_577_File_Conflict_Prompt_Token_Is_Transient'Access,
         "phase 577 file conflict prompt token is transient");
      Register_Routine
        (T, Test_Phase_577_File_Conflict_Prompt_Missing_Revalidation_Fails'Access,
         "phase 577 file conflict prompt missing revalidation fails audit");
      Register_Routine
        (T, Test_Phase_577_Preservation_Audit_Does_Not_Mutate_Project_Transient_State'Access,
         "phase 577 preservation audit does not mutate project transient state");
      Register_Routine
        (T, Test_Phase_577_Preservation_Workspace_Serialization_Does_Not_Persist_Runtime_UI_State'Access,
         "phase 577 preservation workspace serialization excludes runtime UI state");
      Register_Routine
        (T, Test_Phase_577_Render_Boundary_Is_Deeply_Audited'Access,
         "phase 577 render boundary is deeply audited");
      Register_Routine
        (T, Test_Phase_577_Completion_Assertion_Covers_All_Boundaries'Access,
         "phase 577 completion assertion covers all boundaries");
      Register_Routine
        (T, Test_Phase_578_Startup_Recovery_Dogfood_Scenario'Access,
         "phase 578 startup recovery dogfood scenario");
   end Register_Tests;

end Editor.Configuration_Audit.Tests;
