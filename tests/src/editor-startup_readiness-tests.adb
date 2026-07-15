with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Text_IO;
with Editor.Commands;
with Editor.Configuration_Recovery;
with Editor.Executor;
with Editor.State;
with Editor.Keybinding_Config;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.Status_Bar;
with Editor.Workspace_Persistence;

package body Editor.Startup_Readiness.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Configuration_Recovery.Configuration_Domain;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

   overriding function Name
     (T : Startup_Readiness_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Startup_Readiness");
   end Name;

   procedure Delete_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others => null;
   end Delete_If_Exists;

   procedure Ensure_Directory (Path : String) is
   begin
      if not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Path (Path);
      end if;
   exception
      when others => null;
   end Ensure_Directory;

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

   procedure Test_Startup_Readiness_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Startup_Readiness.Assert_Startup_Readiness_Coherent,
         "startup readiness must be coherent");
   end Test_Startup_Readiness_Coherent;

   procedure Test_First_Run_Is_Calm_Defaulted_And_Unfabricated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_First_Run_Summary;
   begin
      Assert (Summary.First_Run, "missing optional domains must classify as first run");
      Assert (Summary.Readiness = Startup_First_Run_Ready,
              "first run must be ready, not error state");
      Assert (Summary.Safe_Default_Domain_Count = 2,
              "settings and keybindings defaults must be marked active");
      Assert (Summary.Rows (5).Status = Startup_Not_Requested,
              "project restore must not fabricate project state");
      Assert (Summary.Rows (6).Status = Startup_Not_Requested,
              "file restore must not fabricate open buffers");
      Assert (Summary.Rows (7).Status = Startup_Not_Requested,
              "panel/layout restore must not fabricate transient feature state");
      Assert (First_Run_Empty_State_Label (Summary) =
              "Ready. Default settings active. Default keybindings active. No workspace restored. No recent projects. Open a project to begin.",
              "first-run surface must be explicit and calm");
   end Test_First_Run_Is_Calm_Defaulted_And_Unfabricated;

   procedure Test_Partial_Workspace_Restore_Is_Count_Based
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 3),
         Project_Restored => True,
         Files_Restored => 2,
         Files_Missing => 5,
         Active_Buffer_Restored => True);
   begin
      Assert (Summary.Readiness = Startup_Workspace_Partial_Restore,
              "missing workspace files must surface as partial restore");
      Assert (Summary.Restored_File_Count = 2,
              "restored files must be counted");
      Assert (Summary.Missing_File_Count = 5,
              "missing files must be skipped and counted");
      Assert (Summary.Safe_Focus = Startup_Focus_Editor,
              "restored active buffer must select safe editor focus");
      Assert (Status_Bar_Label (Summary) = "Workspace partial restore",
              "status bar label must expose partial startup restore");
   end Test_Partial_Workspace_Restore_Is_Count_Based;

   procedure Test_Project_Unavailable_Does_Not_Fabricate_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Missing => True);
   begin
      Assert (Summary.Readiness = Startup_Project_Unavailable,
              "missing project must be reported without project fabrication");
      Assert (Summary.Safe_Focus = Startup_Focus_None,
              "missing project must not focus a fabricated target");
      Assert (Summary.Missing_File_Count = 1,
              "missing project reference must be counted");
      Assert (Status_Bar_Label (Summary) = "Project unavailable",
              "status must expose project-unavailable startup state");
   end Test_Project_Unavailable_Does_Not_Fabricate_Context;

   procedure Test_Status_Bar_Startup_Segment_Is_Observational
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Status_Bar.Status_Bar_Snapshot;
   begin
      Snapshot.Startup_Status_Label := To_Unbounded_String ("Ready with warnings");
      Assert
        (Editor.Status_Bar.Status_Startup_Segment (Snapshot) =
         "Ready with warnings",
         "status bar startup segment must be a scalar projection");
      Assert
        (Index (Editor.Status_Bar.Format_Right (Snapshot), "Ready with warnings") > 0,
         "formatted status must include startup readiness when present");
   end Test_Status_Bar_Startup_Segment_Is_Observational;

   procedure Test_Startup_Run_Loads_Domains_Independently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base : constant String := Editor.Test_Temp.Base & "/editor_startup_";
      Settings_Path : constant String := Base & "settings";
      Keybindings_Path : constant String := Base & "keybindings";
      Workspace_Path : constant String := Base & "workspace";
      Recent_Path : constant String := Base & "recent";
      Settings : Editor.Settings.Settings_Model;
      Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent : Editor.Recent_Projects.Recent_Project_List;
      Summary : Startup_Summary;
   begin
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
      Write_File (Keybindings_Path, "not a keybinding config");

      Startup_Run
        (Settings_Path, Keybindings_Path, Workspace_Path, Recent_Path,
         (Restore_Workspace_On_Startup => True),
         Settings, Keybindings, Workspace, Recent, Summary);

      Assert (Summary.Row_Count = 7,
              "startup summary must contain bounded domain/project/file/panel rows");
      Assert (Summary.Rows (1).Status = Startup_Missing_Optional_File,
              "missing settings are optional defaults");
      Assert (Summary.Rows (2).Status in Startup_Defaulted | Startup_Loaded_With_Warnings,
              "malformed keybindings must not block other domains");
      Assert (Summary.Rows (3).Status = Startup_Missing_Optional_File,
              "missing workspace is optional on startup");
      Assert (Summary.Rows (4).Status = Startup_Missing_Optional_File,
              "missing recent projects are optional");
      Assert (Summary.Safe_Default_Domain_Count >= 1,
              "safe defaults must be active where needed");

      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
   end Test_Startup_Run_Loads_Domains_Independently;


   procedure Test_Restore_Routing_And_Surface_Cleanup_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Ok),
         Domain_Row ("Workspace", Startup_Ok),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 0,
         Active_Buffer_Restored => True);
   begin
      Assert (Summary.Project_Restore_Uses_Lifecycle,
              "startup project restore summary must preserve lifecycle routing invariant");
      Assert (Summary.File_Restore_Uses_Lifecycle,
              "startup file restore summary must preserve file lifecycle routing invariant");
      Assert (Summary.Project_Surfaces_Initialized,
              "startup must initialize project surfaces cleanly");
      Assert (Summary.Rows (7).Status = Startup_Not_Requested,
              "startup must not restore transient panel/layout rows unless explicitly structural");
      Assert (Assert_Startup_Routes_Restore_Through_Lifecycle,
              "restore routing assertion must pass");
      Assert (Assert_Startup_Project_Surfaces_Initialized_Cleanly,
              "surface cleanup assertion must pass");
   end Test_Restore_Routing_And_Surface_Cleanup_Invariants;

   procedure Test_Startup_Restores_No_Pending_Recovery_UI
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted, Warning_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore, Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 1),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 1,
         Active_Buffer_Restored => True);
   begin
      Assert (not Summary.Pending_Confirmation_Restored,
              "startup must not restore pending confirmations");
      Assert (not Summary.Recovery_View_Auto_Repairs,
              "startup recovery view integration must not auto-repair");
      Assert (Summary.Transient,
              "startup recovery UI state must remain transient");
      Assert (Assert_Startup_Restores_No_Pending_Confirmation,
              "pending confirmation assertion must pass");
   end Test_Startup_Restores_No_Pending_Recovery_UI;


   procedure Test_Startup_Run_Resolves_Relative_Files_And_Panels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base : constant String := Editor.Test_Temp.Base & "/editor_relative_workspace";
      Project_Root : constant String := Base & "/project";
      Source_Dir   : constant String := Project_Root & "/src";
      Source_File  : constant String := Source_Dir & "/main.adb";
      Settings_Path : constant String := Base & "/settings.conf";
      Keybindings_Path : constant String := Base & "/keybindings.conf";
      Workspace_Path : constant String := Base & "/workspace.conf";
      Recent_Path : constant String := Base & "/recent.conf";
      Saved_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Settings : Editor.Settings.Settings_Model;
      Keybindings : Editor.Keybinding_Config.Keybinding_Config_Model;
      Loaded_Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Recent : Editor.Recent_Projects.Recent_Project_List;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Source_Dir);
      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
      Write_File (Source_File, "procedure Main is begin null; end Main;");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Project_Root);
      Item.Path := To_Unbounded_String ("src/main.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", Is_Project_Relative => True);
      Editor.Workspace_Persistence.Set_File_Tree_Panel
        (Snapshot, Visible => True, Width => 32);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Workspace_Path, Saved_Status);
      Assert (Saved_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "test workspace fixture must save cleanly");

      Startup_Run
        (Settings_Path, Keybindings_Path, Workspace_Path, Recent_Path,
         (Restore_Workspace_On_Startup => True),
         Settings, Keybindings, Loaded_Workspace, Recent, Summary);

      Assert (Summary.Rows (3).Status = Startup_Ok,
              "workspace fixture must load as structural workspace state");
      Assert (Summary.Rows (5).Status = Startup_Ok,
              "existing project root must be reported through project restore status");
      Assert (Summary.Rows (6).Status = Startup_Ok,
              "project-relative open file must resolve against project root");
      Assert (Summary.Rows (6).Restored_File_Count = 1,
              "relative file restore count must use resolved workspace path");
      Assert (Summary.Rows (7).Status = Startup_Ok,
              "structural panel/layout restore must be reported when workspace restore succeeds");
      Assert (Summary.Safe_Focus = Startup_Focus_Editor,
              "resolved active buffer restore must select editor focus");

      Delete_If_Exists (Settings_Path);
      Delete_If_Exists (Keybindings_Path);
      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Recent_Path);
      Delete_If_Exists (Source_File);
   end Test_Startup_Run_Resolves_Relative_Files_And_Panels;





   procedure Test_Active_File_Must_Be_Restored_For_Editor_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Root : constant String := Editor.Test_Temp.Base & "/editor_active_focus_project";
      Source_Dir   : constant String := Project_Root & "/src";
      Existing_File : constant String := Source_Dir & "/main.adb";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Source_Dir);
      Write_File (Existing_File, "procedure Main is begin null; end Main;" & ASCII.LF);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Project_Root);
      Item.Path := To_Unbounded_String ("src/main.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/missing.adb", Is_Project_Relative => True);

      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (5).Status = Startup_Ok,
              "existing project root must still restore through project status");
      Assert (Summary.Rows (6).Status = Startup_Ok,
              "non-active open file restore must still be counted");
      Assert (Summary.Rows (6).Restored_File_Count = 1,
              "restored non-active file must be reported");
      Assert (Summary.Safe_Focus = Startup_Focus_File_Tree,
              "editor focus requires the saved active file itself to restore");

      Delete_If_Exists (Existing_File);
   end Test_Active_File_Must_Be_Restored_For_Editor_Focus;


   procedure Test_Active_File_Must_Belong_To_Open_Files_For_Editor_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Root : constant String := Editor.Test_Temp.Base & "/editor_active_membership_project";
      Source_Dir   : constant String := Project_Root & "/src";
      Open_File    : constant String := Source_Dir & "/open.adb";
      Active_File  : constant String := Source_Dir & "/active.adb";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Source_Dir);
      Write_File (Open_File, "procedure Open_File is begin null; end Open_File;" & ASCII.LF);
      Write_File (Active_File, "procedure Active_File is begin null; end Active_File;" & ASCII.LF);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Project_Root);
      Item.Path := To_Unbounded_String ("src/open.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/active.adb", Is_Project_Relative => True);

      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (6).Status = Startup_Ok,
              "open-file restore must still report the restored file");
      Assert (Summary.Rows (6).Restored_File_Count = 1,
              "only files from the workspace open-file list are restored buffers");
      Assert (Summary.Safe_Focus = Startup_Focus_File_Tree,
              "existing active-file path outside open files must not fabricate editor focus");

      Delete_If_Exists (Open_File);
      Delete_If_Exists (Active_File);
   end Test_Active_File_Must_Belong_To_Open_Files_For_Editor_Focus;


   procedure Test_Startup_Summary_Availability_Is_Observational
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Summary : constant Startup_Summary := Build_First_Run_Summary;
   begin
      Clear_Startup_Summary;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Startup_Show_Summary);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "startup summary command must be unavailable before startup records a summary");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
              "No startup summary available.",
              "startup summary availability must give deterministic reason");

      Record_Startup_Summary (Summary);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Startup_Show_Summary);
      Assert (Availability.Status = Editor.Commands.Command_Available,
              "startup summary command must become available after transient summary record");
      Assert (Has_Recorded_Startup_Summary,
              "availability check must not clear or mutate recorded startup summary");
      Clear_Startup_Summary;
   end Test_Startup_Summary_Availability_Is_Observational;

   procedure Test_Startup_Display_Command_Is_No_Payload_And_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name ("startup.show-summary", Found);
      Descriptor : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Startup_Show_Summary);
      Command : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Editor.Commands.Command_Startup_Show_Summary);
   begin
      Assert (Found and then Id = Editor.Commands.Command_Startup_Show_Summary,
              "startup.show-summary must resolve to the startup summary command");
      Assert (Descriptor.Visibility = Editor.Commands.Palette_Command,
              "startup summary command must be discoverable through the command palette");
      Assert (Descriptor.Configuration,
              "startup summary command must remain in the configuration/recovery command family");
      Assert (not Descriptor.Requires_Explicit_Target
              and then not Descriptor.Target_Prompt_Capable,
              "startup summary command must not carry a payload");
      Assert (Command.Kind = Editor.Commands.Startup_Show_Summary,
              "startup summary command must route through the executor command kind");
      Assert (Length (Command.Text) = 0
              and then Length (Command.Path) = 0
              and then Length (Command.Query) = 0,
              "startup summary command payload fields must be empty");
      Assert (Assert_Startup_Display_Commands_Route_Through_Executor,
              "startup display command route assertion must pass");
   end Test_Startup_Display_Command_Is_No_Payload_And_Routed;


   procedure Test_Startup_Recovery_View_Is_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted, Warning_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore, Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 1),
         Project_Missing => True,
         Files_Restored => 1,
         Files_Missing => 2,
         Panel_Layout_Warnings => 1);
      Recovery : constant Editor.Configuration_Recovery.Configuration_Recovery_Summary :=
        Configuration_Recovery_View (Summary);
   begin
      Assert (Recovery.Bounded,
              "startup recovery projection must fit the recovery domain array");
      Assert (Recovery.Domain_Count = 5,
              "startup restore rows must be folded into one runtime recovery row");
      Assert (Recovery.Rows (5).Domain =
              Editor.Configuration_Recovery.Runtime_Defaults_Domain,
              "folded startup restore details must use the runtime defaults domain");
      Assert (Recovery.Rows (5).Warning_Count >= 3,
              "runtime recovery row must preserve startup restore warning counts");
      Assert (Assert_Startup_Recovery_View_Is_Bounded,
              "startup recovery view bounded assertion must pass");
   end Test_Startup_Recovery_View_Is_Bounded;


   procedure Test_Recovery_Show_Projects_Startup_Warnings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 2,
         Active_Buffer_Restored => True,
         Panel_Layout_Warnings => 1);
      Recovery : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
   begin
      Editor.Configuration_Recovery.Clear_Recorded_Recovery_Summary;
      Clear_Startup_Summary;
      Record_Startup_Summary (Summary);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Configuration_Recover_Show);

      Assert (Editor.Configuration_Recovery.Has_Recorded_Recovery_Summary,
              "recovery show must project recorded startup warnings into the recovery view");
      Recovery := Editor.Configuration_Recovery.Current_Recovery_Summary;
      Assert (Recovery.Domain_Count = 5,
              "startup restore rows must remain bounded when shown through recovery view");
      Assert (Recovery.Rows (5).Domain =
              Editor.Configuration_Recovery.Runtime_Defaults_Domain,
              "startup project/file/panel restore warnings must fold into runtime row");
      Assert (Recovery.Rows (5).Warning_Count >= 3,
              "runtime recovery row must preserve startup missing-file and panel warnings");
      Assert (Has_Recorded_Startup_Summary,
              "recovery display must not clear the transient startup summary");

      Editor.Configuration_Recovery.Clear_Recorded_Recovery_Summary;
      Clear_Startup_Summary;
   end Test_Recovery_Show_Projects_Startup_Warnings;


   procedure Test_Observed_Summary_Uses_Loaded_Workspace_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base : constant String := Editor.Test_Temp.Base & "/editor_observed_workspace";
      Missing_Project : constant String := Base & "/missing-project";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Startup_Summary;
   begin
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Missing_Project);
      Item.Path := To_Unbounded_String ("missing.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);

      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (5).Status = Startup_Unavailable,
              "observed startup summary must report missing project root");
      Assert (Summary.Rows (6).Status = Startup_Not_Requested,
              "project-relative restore must not cascade under a missing project root");
      Assert (Summary.Missing_File_Count = 1,
              "observed startup summary must count only the missing project target");
      Assert (Summary.Safe_Focus = Startup_Focus_None,
              "missing project/file restore must not choose an unsafe focus target");
   end Test_Observed_Summary_Uses_Loaded_Workspace_Diagnostics;


   procedure Test_Disabled_Workspace_Restore_Is_Not_Reported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Dir : constant String := Editor.Test_Temp.Base & "/editor_restore_disabled_project";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Project_Dir);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Project_Dir);
      Item.Path := To_Unbounded_String ("missing_when_disabled.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);

      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => False);

      Assert (Summary.Rows (3).Status = Startup_Not_Requested,
              "disabled startup workspace restore must report workspace not requested");
      Assert (Summary.Rows (5).Status = Startup_Not_Requested,
              "disabled startup workspace restore must not report project restore");
      Assert (Summary.Rows (6).Status = Startup_Not_Requested,
              "disabled startup workspace restore must not report open-file restore");
      Assert (Summary.Rows (7).Status = Startup_Not_Requested,
              "disabled startup workspace restore must not report panel/layout restore");
      Assert (Summary.Missing_File_Count = 0,
              "disabled startup workspace restore must not count skipped workspace files");
      Assert (Summary.Safe_Focus = Startup_Focus_None,
              "disabled startup workspace restore must not choose a restored-buffer focus");
   end Test_Disabled_Workspace_Restore_Is_Not_Reported;


   procedure Test_Workspace_Diagnostics_Are_Not_All_Invalid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Dir : constant String := Editor.Test_Temp.Base & "/editor_workspace_diag_project";
      Source_Dir  : constant String := Project_Dir & "/src";
      Source_File : constant String := Source_Dir & "/main.adb";
      Workspace_Path : constant String := Editor.Test_Temp.Base & "/editor_workspace_diag.session";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Source_Dir);
      Write_File (Source_File, "procedure Main is begin null; end Main;" & ASCII.LF);
      Write_File
        (Workspace_Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & Project_Dir & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-width=0" & ASCII.LF &
         "bottom-height=0" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File
        (Workspace_Path, Snapshot, Status);
      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Status,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (3).Warning_Count = 0,
              "panel-only diagnostics must not be duplicated as workspace startup warnings");
      Assert (Summary.Rows (3).Invalid_Entry_Count = 0,
              "panel-only workspace diagnostics must not be counted as invalid entries");
      Assert (Summary.Rows (7).Status = Startup_Loaded_With_Warnings,
              "panel/layout diagnostics must be folded into the panel/layout restore row");
      Assert (Summary.Rows (7).Warning_Count >= 1,
              "panel/layout restore row must count structural panel warnings");

      Delete_If_Exists (Workspace_Path);
      Delete_If_Exists (Source_File);
   end Test_Workspace_Diagnostics_Are_Not_All_Invalid;


   procedure Test_Missing_Open_File_Is_Not_Double_Counted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Dir : constant String := Editor.Test_Temp.Base & "/editor_missing_count_project";
      Workspace_Path : constant String := Editor.Test_Temp.Base & "/editor_missing_count.session";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary : Startup_Summary;
   begin
      Ensure_Directory (Project_Dir);
      Write_File
        (Workspace_Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & Project_Dir & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "missing.adb|relative=true|row=0|col=0|view=0" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File
        (Workspace_Path, Snapshot, Status);
      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Status,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (3).Warning_Count = 0,
              "workspace row must not duplicate missing-target restore warnings");
      Assert (Summary.Rows (3).Missing_File_Count = 0,
              "workspace diagnostics must not own missing-target aggregate counts");
      Assert (Summary.Rows (6).Missing_File_Count = 1,
              "open-file restore row must own skipped missing-file count");
      Assert (Summary.Rows (6).Warning_Count = 1,
              "open-file restore row must own skipped missing-file warning");
      Assert (Summary.Missing_File_Count = 1,
              "one missing open file must not be double-counted");
      Assert (Summary.Warning_Count = 1,
              "one missing open file must not double-count aggregate warnings");

      Delete_If_Exists (Workspace_Path);
   end Test_Missing_Open_File_Is_Not_Double_Counted;


   procedure Test_Recovery_View_Does_Not_Double_Count_Missing_Target_Warnings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Dir : constant String := Editor.Test_Temp.Base & "/editor_recovery_missing_project";
      Workspace_Path : constant String := Editor.Test_Temp.Base & "/editor_recovery_missing.session";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary : Startup_Summary;
      Recovery : Editor.Configuration_Recovery.Configuration_Recovery_Summary;
   begin
      Ensure_Directory (Project_Dir);
      Write_File
        (Workspace_Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & Project_Dir & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "missing.adb|relative=true|row=0|col=0|view=0" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File
        (Workspace_Path, Snapshot, Status);
      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Status,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);
      Recovery := Configuration_Recovery_View (Summary);

      Assert (Summary.Warning_Count = 1,
              "startup summary should own one warning for one skipped missing open file");
      Assert (Recovery.Warning_Count = 1,
              "recovery projection must not add missing-file counts to restore warnings");

      Delete_If_Exists (Workspace_Path);
   end Test_Recovery_View_Does_Not_Double_Count_Missing_Target_Warnings;


   procedure Test_Missing_Project_Does_Not_Cascade_Open_File_Missing_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing_Project_Dir : constant String := Editor.Test_Temp.Base & "/editor_missing_project_root_absent";
      Workspace_Path : constant String := Editor.Test_Temp.Base & "/editor_missing_project_cascade.session";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary : Startup_Summary;
   begin
      if Ada.Directories.Exists (Missing_Project_Dir) then
         null;
      end if;
      Write_File
        (Workspace_Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & Missing_Project_Dir & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/missing.adb|relative=true|row=0|col=0|view=0" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File
        (Workspace_Path, Snapshot, Status);
      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Status,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (5).Status = Startup_Unavailable,
              "missing project root must be owned by the project restore row");
      Assert (Summary.Rows (5).Missing_File_Count = 1,
              "missing project root must count as the single unavailable startup target");
      Assert (Summary.Rows (6).Status = Startup_Not_Requested,
              "open-file restore must not cascade when the project context is unavailable");
      Assert (Summary.Rows (6).Missing_File_Count = 0,
              "project-relative open files must not be independently counted under missing project");
      Assert (Summary.Missing_File_Count = 1,
              "missing project plus relative files must not cascade missing-file totals");
      Assert (Summary.Readiness = Startup_Project_Unavailable,
              "project unavailable must remain the primary startup readiness label");

      Delete_If_Exists (Workspace_Path);
   end Test_Missing_Project_Does_Not_Cascade_Open_File_Missing_Counts;


   procedure Test_Missing_Project_Rejects_Absolute_Open_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing_Project_Dir : constant String :=
        Editor.Test_Temp.Base & "/editor_abs_restore_missing_project_root";
      Absolute_File : constant String :=
        Editor.Test_Temp.Base & "/editor_absolute_workspace_file.adb";
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Startup_Summary;
   begin
      Write_File
        (Absolute_File,
         "procedure Absolute_Workspace_File is begin null; end Absolute_Workspace_File;"
         & ASCII.LF);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Missing_Project_Dir);
      Item.Path := To_Unbounded_String (Absolute_File);
      Item.Is_Project_Relative := False;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      --  The strict workspace schema rejects absolute open-file entries before
      --  startup restore. Project-relative entries then cannot be attempted
      --  while the saved project root is unavailable.
      Item.Path := To_Unbounded_String ("src/missing_under_missing_project.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, Absolute_File, Is_Project_Relative => False);

      Summary := Build_Observed_Startup_Summary
        (Editor.Settings.Settings_Ok,
         Editor.Keybinding_Config.Keybinding_Config_Ok,
         Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         Editor.Recent_Projects.Recent_Project_Ok,
         Snapshot,
         Restore_Requested => True);

      Assert (Summary.Rows (5).Status = Startup_Unavailable,
              "missing project root must remain the primary project restore status");
      Assert (Summary.Rows (6).Status = Startup_Not_Requested,
              "open-file restore must not run without retained project-relative entries");
      Assert (Summary.Rows (6).Warning_Count = 0,
              "suppressed project-relative open files must not add cascaded warnings");
      Assert (Summary.Rows (6).Restored_File_Count = 0,
              "absolute open-file entries must not be counted under strict workspace schema");
      Assert (Summary.Rows (6).Missing_File_Count = 0,
              "suppressed project-relative entries must not add missing-file target counts");
      Assert (Summary.Missing_File_Count = 1,
              "strict workspace restore must not add cascaded open-file counts");
      Assert (Summary.Warning_Count = 1,
              "missing project should own the only startup warning");
      Assert (Summary.Safe_Focus = Startup_Focus_None,
              "rejected absolute active file must not receive editor focus");
      Assert (Summary.Readiness = Startup_Project_Unavailable,
              "project unavailable remains the readiness label without restored buffers");
      Assert (Status_Bar_Label (Summary) = "Project unavailable",
              "status must expose project unavailable without fabricated restored files");
      Assert (Index (Startup_Command_Message (Summary), "Restored files:") = 0,
              "startup command summary must not include rejected absolute file counts");

      Delete_If_Exists (Absolute_File);
   end Test_Missing_Project_Rejects_Absolute_Open_Files;


   procedure Test_State_Init_Records_Startup_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Clear_Startup_Summary;
      Editor.State.Init (S);
      Assert (Has_Recorded_Startup_Summary,
              "state initialization must record a transient startup summary");
      Assert (Current_Startup_Summary.Row_Count = 7,
              "recorded startup summary must use the bounded row model");
      Assert (Editor.Executor.Command_Availability
                (S, Editor.Commands.Command_Startup_Show_Summary).Status =
              Editor.Commands.Command_Available,
              "startup summary command must be available after state initialization");
      Clear_Startup_Summary;
   end Test_State_Init_Records_Startup_Summary;

   procedure Test_Startup_Command_Message_Is_Bounded_And_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Ok),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Rejected_Entry_Count => 2),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1),
         Domain_Row ("Recent Projects", Startup_Ok),
         Project_Restored => True,
         Files_Restored => 1,
         Files_Missing => 3,
         Active_Buffer_Restored => True);
      Message : constant String := Startup_Command_Message (Summary);
   begin
      Assert (Index (Message, "Workspace restored with missing files skipped.") > 0,
              "startup summary command message must include the readiness message");
      Assert (Index (Message, "Warnings: 5.") > 0,
              "startup summary command message must include aggregate warnings");
      Assert (Index (Message, "Rejected entries: 2.") > 0,
              "startup summary command message must include rejected-entry count");
      Assert (Index (Message, "Missing files: 3.") > 0,
              "startup summary command message must include missing-file count");
      Assert (Index (Message, "Open configuration recovery for details.") > 0,
              "startup summary command message must include the action suggestion");
      Assert (Message'Length <= Max_Startup_Label_Length,
              "startup summary command message must remain bounded");
   end Test_Startup_Command_Message_Is_Bounded_And_Actionable;

   procedure Test_Aggregate_Counts_Match_Bounded_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : Startup_Summary := Build_Startup_Summary
        (Domain_Row ("Settings", Startup_Defaulted,
                     Warning_Count => 1,
                     Safe_Defaults_Active => True),
         Domain_Row ("Keybindings", Startup_Loaded_With_Warnings,
                     Warning_Count => 2, Rejected_Entry_Count => 2,
                     Safe_Defaults_Active => True),
         Domain_Row ("Workspace", Startup_Partial_Restore,
                     Warning_Count => 1, Missing_File_Count => 3),
         Domain_Row ("Recent Projects", Startup_Loaded_With_Warnings,
                     Warning_Count => 1, Invalid_Entry_Count => 4),
         Project_Restored => True,
         Files_Restored => 2,
         Files_Missing => 1,
         Active_Buffer_Restored => True,
         Panel_Layout_Warnings => 1);
   begin
      Assert (Summary.Warning_Count = 7,
              "startup warning aggregate must equal bounded row warnings");
      Assert (Summary.Invalid_Entry_Count = 4,
              "startup invalid-entry aggregate must equal bounded row invalid counts");
      Assert (Summary.Rejected_Entry_Count = 2,
              "startup rejected-entry aggregate must equal bounded row rejected counts");
      Assert (Summary.Missing_File_Count = 4,
              "startup missing-file aggregate must equal bounded row missing counts");
      Assert (Summary.Restored_File_Count = 2,
              "startup restored-file aggregate must equal bounded row restored counts");

      Summary.Warning_Count := 99;
      Record_Startup_Summary (Summary);
      Assert (Current_Startup_Summary.Warning_Count = 7,
              "recorded startup summaries must normalize aggregate warning counts");
      Clear_Startup_Summary;
      Assert (Assert_Startup_Aggregate_Counts_Match_Rows,
              "aggregate consistency assertion must pass");
   end Test_Aggregate_Counts_Match_Bounded_Rows;



   overriding procedure Register_Tests
     (T : in out Startup_Readiness_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Startup_Readiness_Coherent'Access,
         "startup readiness coherent");
      Register_Routine
        (T, Test_First_Run_Is_Calm_Defaulted_And_Unfabricated'Access,
         "first run is calm defaulted and unfabricated");
      Register_Routine
        (T, Test_Partial_Workspace_Restore_Is_Count_Based'Access,
         "partial workspace restore is count based");
      Register_Routine
        (T, Test_Project_Unavailable_Does_Not_Fabricate_Context'Access,
         "project unavailable does not fabricate context");
      Register_Routine
        (T, Test_Status_Bar_Startup_Segment_Is_Observational'Access,
         "status bar startup segment is observational");
      Register_Routine
        (T, Test_Startup_Run_Loads_Domains_Independently'Access,
         "startup run loads domains independently");
      Register_Routine
        (T, Test_Restore_Routing_And_Surface_Cleanup_Invariants'Access,
         "restore routing and surface cleanup invariants");
      Register_Routine
        (T, Test_Startup_Restores_No_Pending_Recovery_UI'Access,
         "startup restores no pending recovery ui");
      Register_Routine
        (T, Test_Startup_Run_Resolves_Relative_Files_And_Panels'Access,
         "startup run resolves relative files and panels");
      Register_Routine
        (T, Test_Active_File_Must_Be_Restored_For_Editor_Focus'Access,
         "active file must be restored for editor focus");
      Register_Routine
        (T, Test_Active_File_Must_Belong_To_Open_Files_For_Editor_Focus'Access,
         "active file must belong to open files for editor focus");
      Register_Routine
        (T, Test_Startup_Summary_Availability_Is_Observational'Access,
         "startup summary availability is observational");
      Register_Routine
        (T, Test_Startup_Display_Command_Is_No_Payload_And_Routed'Access,
         "startup display command is no payload and routed");
      Register_Routine
        (T, Test_Startup_Recovery_View_Is_Bounded'Access,
         "startup recovery view is bounded");
      Register_Routine
        (T, Test_Recovery_Show_Projects_Startup_Warnings'Access,
         "recovery show projects startup warnings");
      Register_Routine
        (T, Test_Observed_Summary_Uses_Loaded_Workspace_Diagnostics'Access,
         "observed startup summary uses loaded workspace diagnostics");
      Register_Routine
        (T, Test_Disabled_Workspace_Restore_Is_Not_Reported'Access,
         "disabled workspace restore is not reported");
      Register_Routine
        (T, Test_Workspace_Diagnostics_Are_Not_All_Invalid'Access,
         "workspace diagnostics are not all invalid");
      Register_Routine
        (T, Test_Missing_Open_File_Is_Not_Double_Counted'Access,
         "missing open file is not double counted");
      Register_Routine
        (T, Test_Recovery_View_Does_Not_Double_Count_Missing_Target_Warnings'Access,
         "recovery view does not double count missing target warnings");
      Register_Routine
        (T, Test_Missing_Project_Does_Not_Cascade_Open_File_Missing_Counts'Access,
         "missing project does not cascade open-file missing counts");
      Register_Routine
        (T, Test_Missing_Project_Rejects_Absolute_Open_Files'Access,
         "missing project rejects absolute open files");
      Register_Routine
        (T, Test_State_Init_Records_Startup_Summary'Access,
         "state init records startup summary");
      Register_Routine
        (T, Test_Startup_Command_Message_Is_Bounded_And_Actionable'Access,
         "startup command message is bounded and actionable");
      Register_Routine
        (T, Test_Aggregate_Counts_Match_Bounded_Rows'Access,
         "aggregate counts match bounded rows");
   end Register_Tests;

end Editor.Startup_Readiness.Tests;
