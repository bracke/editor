with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with AUnit.Assertions; use AUnit.Assertions;
with Editor.Missing_Stale_Recovery;
with Editor.Test_Temp;

package body Editor.Missing_Stale_Recovery.Boundary_Tests is

   use type Editor.Missing_Stale_Recovery.Target_Availability_State;
   use type Editor.Missing_Stale_Recovery.Target_Surface;
   use type Editor.Missing_Stale_Recovery.Workspace_Active_File_Fallback;

   function Fixture_Root return String is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Path ("editor-tests"));
      return Editor.Test_Temp.Path ("editor-tests/missing_stale_fixture");
   end Fixture_Root;

   procedure Write_File (Path : String; Text : String := "demo") is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (F, Text);
      Ada.Text_IO.Close (F);
   end Write_File;

   procedure Reset_Fixture is
      Root : constant String := Fixture_Root;
   begin
      if Ada.Directories.Exists (Root) then
         Ada.Directories.Delete_Tree (Root);
      end if;
      Ada.Directories.Create_Path (Root);
      Ada.Directories.Create_Path (Root & "/src");
      Write_File (Root & "/src/main.adb", "procedure Main is begin null; end Main;");
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
   end Reset_Fixture;

   procedure Test_Render_Persistence_And_Command_Payload_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.Missing_Stale_Recovery.Render_May_Probe_Targets,
              "render remains observational and may not probe filesystem targets");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_State_Is_Persistable
                (Editor.Missing_Stale_Recovery.Target_Stale),
              "stale target state is transient and excluded from persistence");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_State_Is_Persistable
                (Editor.Missing_Stale_Recovery.Target_Preview_Stale),
              "replace preview stale state is excluded from persistence");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Is_Payload_Free
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "file-tree.refresh carries no file/tree-node payload");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Is_Payload_Free
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run),
              "project-search.run carries no stale result payload");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Name
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates) =
                "build.refresh-candidates",
              "build recovery command uses canonical command name only");
   end Test_Render_Persistence_And_Command_Payload_Boundaries;

   procedure Test_Project_Transition_And_Explicit_Recovery_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Candidate : constant String := Root & "/demo.gpr";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Surface_Cleared_On_Project_Transition
                (Editor.Missing_Stale_Recovery.Quick_Open_Surface),
              "project switch/close clears Quick Open results");
      Assert (Editor.Missing_Stale_Recovery.Surface_Cleared_On_Project_Transition
                (Editor.Missing_Stale_Recovery.Project_Search_Surface),
              "project switch/close clears Project Search results");
      Assert (Editor.Missing_Stale_Recovery.Surface_Cleared_On_Project_Transition
                (Editor.Missing_Stale_Recovery.Replace_Preview_Surface),
              "project switch/close clears replace preview state");
      Assert (Editor.Missing_Stale_Recovery.Surface_Cleared_On_Project_Transition
                (Editor.Missing_Stale_Recovery.Build_Surface),
              "project switch/close clears Build candidates/request/result/output");
      Assert (not Editor.Missing_Stale_Recovery.Surface_Cleared_On_Project_Transition
                (Editor.Missing_Stale_Recovery.Recent_Project_Surface),
              "project switch does not delete Recent Projects state");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Is_Explicit
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "file-tree.refresh is an explicit recovery action");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Replaces_Stale_Surface
                (Editor.Missing_Stale_Recovery.Recovery_Outline_Refresh,
                 Editor.Missing_Stale_Recovery.Outline_Surface),
              "outline.refresh is bounded to Outline stale recovery");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Replaces_Stale_Surface
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface),
              "build.refresh-candidates cannot repair Project Search stale rows");
      Assert (Editor.Missing_Stale_Recovery.Build_Run_Allowed
                (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                   (Candidate, Root)),
              "available build candidate passes build.run preflight");
   end Test_Project_Transition_And_Explicit_Recovery_Boundaries;

   procedure Test_Stale_Targets_Block_Actions_Until_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Candidate : constant String := Root & "/demo.gpr";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Stale_State_After_Content_Change
                (Editor.Missing_Stale_Recovery.Outline_Surface) =
                Editor.Missing_Stale_Recovery.Target_Refresh_Required,
              "buffer edit/reload marks Outline refresh-required");
      Assert (Editor.Missing_Stale_Recovery.Stale_State_After_Content_Change
                (Editor.Missing_Stale_Recovery.Replace_Preview_Surface) =
                Editor.Missing_Stale_Recovery.Target_Preview_Stale,
              "edit/delete marks replace preview stale");
      Assert (not Editor.Missing_Stale_Recovery.Navigation_Allowed
                (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                   (Source, 1, 1, Stale => True)),
              "stale Project Search result cannot navigate");
      Assert (not Editor.Missing_Stale_Recovery.Replace_Apply_Allowed
                (Editor.Missing_Stale_Recovery.Validate_Replace_Preview_Target
                   (Source, 1, 1, Stale => True)),
              "stale replace preview cannot apply");
      Assert (not Editor.Missing_Stale_Recovery.Build_Run_Allowed
                (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                   (Candidate, Root, Stale => True)),
              "stale build candidate cannot run");
      Assert (Editor.Missing_Stale_Recovery.Navigation_Allowed
                (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                   (Source, True, 1, 1, 1, 80)),
              "available diagnostic target may navigate after validation");
   end Test_Stale_Targets_Block_Actions_Until_Recovery;

   procedure Test_Workspace_Action_Caret_And_Selection_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Workspace_Restore_Action_Is_Safe
                (Editor.Missing_Stale_Recovery.Workspace_Skip_Missing_File),
              "workspace restore may skip missing open files without fabricating buffers");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Restore_Action_Is_Safe
                (Editor.Missing_Stale_Recovery.Workspace_Fallback_To_First_Available_File),
              "workspace restore may deterministically fall back from missing active file");
      Assert (not Editor.Missing_Stale_Recovery.Workspace_Restore_Action_Is_Safe
                (Editor.Missing_Stale_Recovery.Workspace_Reject_Fabricated_Project),
              "workspace restore rejects fabricated project state");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Restore_Action_Fabricates_State
                (Editor.Missing_Stale_Recovery.Workspace_Reject_Fabricated_Buffer),
              "fabricated buffer recovery is explicitly unsafe");
      Assert (Editor.Missing_Stale_Recovery.Caret_Target_Policy
                (Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range, False) =
                "ignore caret target",
              "invalid workspace caret targets are ignored unless clamp policy is explicit");
      Assert (Editor.Missing_Stale_Recovery.Caret_Target_Policy
                (Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range, True) =
                "clamp caret target",
              "caret clamping is represented only under explicit policy");
      Assert (Editor.Missing_Stale_Recovery.Command_Availability_When_No_Selection
                (Editor.Missing_Stale_Recovery.Quick_Open_Surface).State =
                Editor.Missing_Stale_Recovery.Target_No_Result_Selected,
              "Quick Open activation without selection is unavailable without a payload");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Command_Availability_When_No_Selection
                   (Editor.Missing_Stale_Recovery.Quick_Open_Surface)) =
                "No Quick Open result selected.",
              "Quick Open no-selection message is user-readable");
      Assert (Editor.Missing_Stale_Recovery.Command_Availability_When_No_Selection
                (Editor.Missing_Stale_Recovery.Diagnostics_Surface).State =
                Editor.Missing_Stale_Recovery.Target_No_Diagnostic_Selected,
              "Diagnostics navigation without selection is unavailable without a payload");
      Assert (Editor.Missing_Stale_Recovery.Command_Availability_When_No_Selection
                (Editor.Missing_Stale_Recovery.Build_Surface).State =
                Editor.Missing_Stale_Recovery.Target_No_Build_Candidate_Selected,
              "Build run without selected candidate is unavailable without a payload");
   end Test_Workspace_Action_Caret_And_Selection_Policies;

   procedure Test_Dirty_Guards_And_Parent_Directory_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Missing_Parent : constant String := Root & "/gone/new.adb";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Save_Target (Missing_Parent)) =
                "Parent directory is unavailable.",
              "save failure distinguishes missing parent directory from missing backing file");
      Assert (Editor.Missing_Stale_Recovery.Dirty_State_Preserved_On
                (Editor.Missing_Stale_Recovery.Target_Parent_Directory_Missing),
              "dirty state remains set when save target parent is missing");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Bypass_Dirty_Guards
                (Editor.Missing_Stale_Recovery.Recovery_File_Reload_From_Disk),
              "reload recovery cannot bypass dirty-buffer guards");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Bypass_Dirty_Guards
                (Editor.Missing_Stale_Recovery.Recovery_File_Revert_Buffer),
              "revert recovery cannot bypass dirty-buffer guards");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Bypass_Dirty_Guards
                (Editor.Missing_Stale_Recovery.Recovery_Workspace_Load),
              "workspace load recovery cannot bypass dirty-buffer guards");
   end Test_Dirty_Guards_And_Parent_Directory_Messages;

   procedure Test_Command_Route_Payload_Outcome_And_Snapshot_Label_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Stale_Quick_Open : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Quick_Open_Result_Target ("missing.adb");
      Missing_Build : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Missing,
         Surface => Editor.Missing_Stale_Recovery.Build_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("missing.gpr"),
         Line    => 0,
         Column  => 0);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Routes_Through_Executor
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "recovery commands are Executor-routed commands, not local widget actions");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Routes_Through_Executor
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates),
              "build.refresh-candidates routes through Executor");
      Assert (not Editor.Missing_Stale_Recovery.Invocation_Source_May_Carry_Target_Payload
                (Editor.Missing_Stale_Recovery.Invocation_Command_Palette),
              "Command Palette may invoke only canonical command names without stale target payloads");
      Assert (not Editor.Missing_Stale_Recovery.Invocation_Source_May_Carry_Target_Payload
                (Editor.Missing_Stale_Recovery.Invocation_Keybinding),
              "keybindings may invoke only canonical command names without target payloads");
      Assert (not Editor.Missing_Stale_Recovery.Invocation_Source_May_Execute_Recovery_Command
                (Editor.Missing_Stale_Recovery.Invocation_Render),
              "render cannot execute recovery commands");
      Assert (not Editor.Missing_Stale_Recovery.Invocation_Source_May_Execute_Recovery_Command
                (Editor.Missing_Stale_Recovery.Invocation_Availability),
              "availability cannot execute recovery commands");
      Assert (Editor.Missing_Stale_Recovery.Invocation_Source_May_Execute_Recovery_Command
                (Editor.Missing_Stale_Recovery.Invocation_Executor),
              "Executor is the single recovery command mutation boundary");
      Assert (Editor.Missing_Stale_Recovery.Command_Outcome_Count_For_Validation
                (Stale_Quick_Open) = 1,
              "stale target validation produces one primary command outcome");
      Assert (Editor.Missing_Stale_Recovery.Command_Outcome_Is_User_Readable
                (Stale_Quick_Open),
              "Quick Open stale outcome exposes no enum names");
      Assert (Editor.Missing_Stale_Recovery.Command_Outcome_Is_User_Readable
                (Missing_Build),
              "Build missing-candidate outcome exposes no enum names");
      Assert (Editor.Missing_Stale_Recovery.Surface_Recovery_Label
                (Editor.Missing_Stale_Recovery.Quick_Open_Surface,
                 Editor.Missing_Stale_Recovery.Target_Stale) =
                "Quick Open target stale",
              "snapshot marker combines surface and stale label without probing filesystem");
      Assert (Editor.Missing_Stale_Recovery.Surface_Recovery_Label
                (Editor.Missing_Stale_Recovery.Outline_Surface,
                 Editor.Missing_Stale_Recovery.Target_Available) = "",
              "available targets do not render stale markers");
   end Test_Command_Route_Payload_Outcome_And_Snapshot_Label_Gates;

end Editor.Missing_Stale_Recovery.Boundary_Tests;
