with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Dirty_Guards;
with Editor.Lifecycle_Audit;
with Editor.Pending_Transitions;
with Editor.Settings;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Lifecycle_Audit.Tests is

   use type Editor.Lifecycle_Audit.Lifecycle_Audit_Status;

   function Name
     (T : Lifecycle_Audit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Lifecycle_Audit.Tests");
   end Name;

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

   procedure Test_Result_Collects_Deterministic_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Editor.Lifecycle_Audit.Lifecycle_Audit_Result;
   begin
      Assert
        (Editor.Lifecycle_Audit.Status (Result) =
           Editor.Lifecycle_Audit.Lifecycle_Audit_Ok,
         "empty lifecycle audit must be ok");
      Assert
        (Editor.Lifecycle_Audit.Summary (Result) = "Lifecycle audit ok",
         "empty lifecycle audit summary must be canonical");

      Editor.Lifecycle_Audit.Add_Failure (Result, "project changed");
      Assert
        (Editor.Lifecycle_Audit.Status (Result) =
           Editor.Lifecycle_Audit.Lifecycle_Audit_Failed,
         "failure must change lifecycle audit status");
      Assert
        (Editor.Lifecycle_Audit.Failure_Count (Result) = 1,
         "failure count must include appended failure");
      Assert
        (Editor.Lifecycle_Audit.Failure (Result, 1) = "project changed",
         "failure lookup must be one-based and deterministic");
      Assert
        (Editor.Lifecycle_Audit.Summary (Result) =
           "Lifecycle audit failed: project changed",
         "single-failure summary must include the failure message");

      Editor.Lifecycle_Audit.Clear (Result);
      Assert
        (Editor.Lifecycle_Audit.Failure_Count (Result) = 0,
         "clear must remove all lifecycle audit failures");
   end Test_Result_Collects_Deterministic_Failures;

   procedure Test_State_Summary_Reports_Lifecycle_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/editor-phase100-b"),
         Display    => To_Unbounded_String ("editor-phase100-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Dirty : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
      Summary : Editor.Lifecycle_Audit.Lifecycle_State_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Install_Project (S, "/tmp/editor-phase100-a", "editor-phase100-a");
      S.File_Info :=
        (Has_Path     => True,
         Path         => To_Unbounded_String ("/tmp/editor-phase100-a/main.adb"),
         Display_Name => To_Unbounded_String ("main.adb"),
         Dirty        => True,
         others       => <>);
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Dirty);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/editor-phase100-a", "editor-phase100-a", 100);

      Summary := Editor.Lifecycle_Audit.State_Summary (S);

      Assert (Summary.Has_Project,
              "lifecycle summary must report active project");
      Assert (To_String (Summary.Project_Display) = "editor-phase100-a",
              "lifecycle summary must expose project display name");
      Assert (Summary.Buffer_Count = 1,
              "lifecycle summary must include active buffer projection");
      Assert (Summary.Dirty_Buffer_Count = 1,
              "lifecycle summary must include dirty active buffer");
      Assert (Summary.Dirty_File_Backed_Count = 1,
              "lifecycle summary must classify dirty file-backed buffers");
      Assert (Summary.Recent_Project_Count = 1,
              "lifecycle summary must count global recent projects");
      Assert (Summary.Has_Pending_Transition,
              "lifecycle summary must report pending transition");
      Assert (To_String (Summary.Pending_Kind_Name) = "open-project",
              "lifecycle summary must expose stable pending kind name");
   end Test_State_Summary_Reports_Lifecycle_Surface;

   procedure Test_Read_Only_Summary_Does_Not_Mutate_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Lifecycle_Audit.Lifecycle_State_Summary;
      After  : Editor.Lifecycle_Audit.Lifecycle_State_Summary;
      Result : Editor.Lifecycle_Audit.Lifecycle_Audit_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Install_Project (S, "/tmp/editor-phase100-a", "editor-phase100-a");
      S.File_Info.Dirty := True;

      Before := Editor.Lifecycle_Audit.State_Summary (S);
      After := Editor.Lifecycle_Audit.State_Summary (S);
      Editor.Lifecycle_Audit.Expect_No_Core_Lifecycle_Mutation
        (Result, Before, After, "summary");

      Assert
        (Editor.Lifecycle_Audit.Status (Result) =
           Editor.Lifecycle_Audit.Lifecycle_Audit_Ok,
         "lifecycle summary construction must be side-effect-free");
   end Test_Read_Only_Summary_Does_Not_Mutate_State;

   procedure Test_Workspace_Snapshot_Excludes_Transient_Lifecycle_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Project,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("close project"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => False,
         others     => <>);
      Dirty : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 1, File_Backed_Count => 0);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Install_Project (S, "/tmp/editor-phase100-a", "editor-phase100-a");
      S.File_Info.Dirty := True;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Dirty);

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);

      Assert
        (Editor.Workspace_Persistence.Has_Project_Root (Snapshot),
         "workspace snapshot should retain structural project root");
      Assert
        (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 0,
         "workspace snapshot must not serialize untitled dirty buffer text");
      Assert
        (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
         "workspace snapshot must not serialize pending-transition target state");
      Assert
        (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
         "building workspace snapshot must not clear pending transition");
      Assert (S.File_Info.Dirty,
              "building workspace snapshot must not save dirty text");
   end Test_Workspace_Snapshot_Excludes_Transient_Lifecycle_State;


   procedure Test_Settings_Lifecycle_Summary_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Model : Editor.Settings.Settings_Model;
      Before : Editor.Lifecycle_Audit.Settings_Lifecycle_Summary;
      After  : Editor.Lifecycle_Audit.Settings_Lifecycle_Summary;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/editor-phase104-b"),
         Display    => To_Unbounded_String ("editor-phase104-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Dirty : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Settings.Set_Defaults (Model);
      Editor.Settings.Set_Theme_Id (Model, "dark");
      Editor.Settings.Set_Line_Number_Mode_Name (Model, "relative");
      Editor.Settings.Set_Cursor_Blink (Model, False);
      Editor.Settings.Set_Minimap_Visible (Model, False);
      Editor.State.Apply_Settings (S, Model);
      Install_Project (S, "/tmp/editor-phase104-a", "editor-phase104-a");
      S.File_Info.Dirty := True;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Dirty);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/editor-phase104-a", "editor-phase104-a", 104);

      Before := Editor.Lifecycle_Audit.Settings_Lifecycle_Summary_For (S);
      After := Editor.Lifecycle_Audit.Settings_Lifecycle_Summary_For (S);

      Assert (To_String (Before.Theme_Id) = "dark",
              "settings lifecycle summary must expose normalized theme id");
      Assert (To_String (Before.Line_Number_Mode) = "relative",
              "settings lifecycle summary must expose line-number mode");
      Assert (not Before.Cursor_Blink_Enabled,
              "settings lifecycle summary must expose cursor blink preference");
      Assert (not Before.Minimap_Visible,
              "settings lifecycle summary must expose minimap visibility");
      Assert (Before.Has_Project and then Before.Dirty_Buffer_Count = 1,
              "settings lifecycle summary must include lifecycle separation counters");
      Assert (Before.Has_Pending_Transition and then Before.Recent_Project_Count = 1,
              "settings lifecycle summary must report pending and recent-project separation counters");
      Assert (To_String (Before.Theme_Id) = To_String (After.Theme_Id)
              and then To_String (Before.Line_Number_Mode) = To_String (After.Line_Number_Mode)
              and then Before.Dirty_Buffer_Count = After.Dirty_Buffer_Count,
              "settings lifecycle summary must be side-effect-free and stable");
   end Test_Settings_Lifecycle_Summary_Is_Side_Effect_Free;

   overriding procedure Register_Tests
     (T : in out Lifecycle_Audit_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Result_Collects_Deterministic_Failures'Access,
         "result collects deterministic failures");
      Register_Routine
        (T, Test_State_Summary_Reports_Lifecycle_Surface'Access,
         "state summary reports lifecycle surface");
      Register_Routine
        (T, Test_Read_Only_Summary_Does_Not_Mutate_State'Access,
         "read-only summary does not mutate state");
      Register_Routine
        (T, Test_Workspace_Snapshot_Excludes_Transient_Lifecycle_State'Access,
         "workspace snapshot excludes transient lifecycle state");
      Register_Routine
        (T, Test_Settings_Lifecycle_Summary_Is_Side_Effect_Free'Access,
         "settings lifecycle summary is side-effect-free");
   end Register_Tests;

end Editor.Lifecycle_Audit.Tests;
