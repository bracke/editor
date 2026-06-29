with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Editor.Missing_Stale_Recovery;

package body Editor.Missing_Stale_Recovery.Tests is

   use type Editor.Missing_Stale_Recovery.Target_Availability_State;
   use type Editor.Missing_Stale_Recovery.Target_Surface;
   use type Editor.Missing_Stale_Recovery.Workspace_Active_File_Fallback;
   use type Editor.Missing_Stale_Recovery.Recovery_Command_Kind;
   use type Editor.Missing_Stale_Recovery.Surface_Event_Effect;
   use type Editor.Missing_Stale_Recovery.Validation_Failure_Disposition;
   use type Editor.Missing_Stale_Recovery.Recovery_Attempt_Outcome;
   use type Editor.Missing_Stale_Recovery.Recovery_State_Disposition;
   use type Editor.Missing_Stale_Recovery.Target_Use_Kind;
   use type Editor.Missing_Stale_Recovery.Target_Reference_Context;
   use type Editor.Missing_Stale_Recovery.Target_Generation_State;
   use type Editor.Missing_Stale_Recovery.Recovery_Message_Content;
   use type Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Kind;
   use type Editor.Missing_Stale_Recovery.Recovery_Postcondition;
   use type Editor.Missing_Stale_Recovery.Stale_Surface_Lifecycle_Action;

   overriding function Name
     (T : Missing_Stale_Recovery_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Missing_Stale_Recovery");
   end Name;

   function Fixture_Root return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/phase561_missing_stale_fixture";
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

   procedure Test_User_Readable_Labels_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Label
                (Editor.Missing_Stale_Recovery.Target_Missing) = "target missing",
              "missing label is user-readable and not an enum name");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Outside_Project) =
                "Target is outside the current project.",
              "outside-project reason is distinct from missing");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Unreadable) =
                "File is not readable.",
              "unreadable reason is distinct");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Unwritable) =
                "File is not writable.",
              "unwritable reason is distinct");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason
                (Editor.Missing_Stale_Recovery.Target_Stale) =
                "Target is stale; refresh required.",
              "stale target reason uses the Phase 578 canonical wording");
      Assert (Editor.Missing_Stale_Recovery.Outcome_Label
                ((State   => Editor.Missing_Stale_Recovery.Target_Stale,
                  Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
                  Path    => Ada.Strings.Unbounded.To_Unbounded_String (""),
                  Line    => 0,
                  Column  => 0)) =
                "Project Search: Target is stale; refresh required.",
              "generic stale outcome cannot bypass canonical wording");
   end Test_User_Readable_Labels_Are_Stable;

   procedure Test_Workspace_And_Recent_Recovery_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Missing : constant String := Root & "/missing-project";
      Summary : constant Editor.Missing_Stale_Recovery.Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 2,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 1,
         Invalid_Caret_Targets  => 1,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_Workspace_Project_Target (Missing).State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "missing workspace project is unavailable");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Recovery_Message (Summary) =
                "Some workspace files could not be reopened; active file could not be restored.",
              "workspace load emits one primary missing-reference summary");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (1, 0) =
                "Recent project path no longer exists.",
              "recent project open failure is explicit");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (1, 1) =
                "Removed unavailable recent project.",
              "recent project removal message is explicit");
      Assert (Editor.Missing_Stale_Recovery.Recent_Project_Recovery_Message (0, 0) =
                "No unavailable recent projects.",
              "no-op recent missing removal is explicit");
      Assert (Editor.Missing_Stale_Recovery.Validate_Recent_Project_Target (Missing).Surface =
                Editor.Missing_Stale_Recovery.Recent_Project_Surface,
              "recent project missing marker is surface-specific");
   end Test_Workspace_And_Recent_Recovery_Messages;

   procedure Test_File_Lifecycle_Missing_Backing_File_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Missing : constant String := Root & "/src/deleted.adb";
      Missing_Parent : constant String := Root & "/gone/new.adb";
   begin
      Reset_Fixture;
      Ada.Directories.Delete_File (Source);
      Assert (Editor.Missing_Stale_Recovery.Validate_Buffer_Backing_File_Target
                (Source, Dirty => True).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "deleted dirty backing file is missing without clearing buffer text");
      Assert (Editor.Missing_Stale_Recovery.Dirty_Buffer_Text_Preserved_On
                (Editor.Missing_Stale_Recovery.Target_Missing),
              "dirty buffer text is preserved on missing backing file");
      Assert (Editor.Missing_Stale_Recovery.Validate_Save_Target (Missing).State =
                Editor.Missing_Stale_Recovery.Target_Available,
              "save to existing parent remains an explicit create/write operation");
      Assert (Editor.Missing_Stale_Recovery.Validate_Save_Target (Missing_Parent).State =
                Editor.Missing_Stale_Recovery.Target_Parent_Directory_Missing,
              "save target with missing parent reports the parent-directory recovery label");
      Assert (Editor.Missing_Stale_Recovery.Validate_Reveal_Target (Missing, Root).Surface =
                Editor.Missing_Stale_Recovery.File_Tree_Surface,
              "reveal validates through the File Tree surface");
   end Test_File_Lifecycle_Missing_Backing_File_Recovery;

   procedure Test_File_Project_And_Project_Boundary_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Existing : constant String := Root & "/src/main.adb";
      Missing  : constant String := Root & "/src/missing.adb";
      Outside  : constant String := "/tmp/editor-tests/phase561_outside.adb";
   begin
      Reset_Fixture;
      Write_File (Outside, "outside");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_Target (Root).State =
                Editor.Missing_Stale_Recovery.Target_Available,
              "existing project root is available");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_Target (Root & "/gone").State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "missing workspace project is reported as missing");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Existing).State = Editor.Missing_Stale_Recovery.Target_Available,
              "existing in-project file is available");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Missing).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "missing in-project file is missing, not fabricated");
      Assert (Editor.Missing_Stale_Recovery.Validate_Project_File_Target
                (Root, Outside).State = Editor.Missing_Stale_Recovery.Target_Outside_Project,
              "outside-project file is rejected before open/navigation");
      Ada.Directories.Delete_File (Outside);
   end Test_File_Project_And_Project_Boundary_Validation;

   procedure Test_Surface_Specific_Stale_Target_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Existing : constant String := Root & "/src/main.adb";
      Missing  : constant String := Root & "/src/gone.adb";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Node_Target
                (Missing, Root).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "stale File Tree node validates to missing");
      Assert (Editor.Missing_Stale_Recovery.Validate_Quick_Open_Result_Target
                (Missing, Root).State = Editor.Missing_Stale_Recovery.Target_Stale,
              "stale Quick Open match validates to stale");
      Assert (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                (Existing, 3, 1).State = Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range,
              "Project Search line out of range is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                (Existing, 1, 1, Stale => True).State = Editor.Missing_Stale_Recovery.Target_Stale,
              "stale Project Search row requires rerun before activation");
      Assert (Editor.Missing_Stale_Recovery.Validate_Replace_Preview_Target
                (Existing, 1, 1, Stale => True).State = Editor.Missing_Stale_Recovery.Target_Preview_Stale,
              "stale replace preview is rejected before apply");
   end Test_Surface_Specific_Stale_Target_Validation;

   procedure Test_Outline_Diagnostics_And_Build_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Candidate : constant String := Root & "/demo.gpr";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_Outline_Target
                (Active_Buffer_Matches => False,
                 Stale => False,
                 Line => 1,
                 Column => 1,
                 Last_Line => 1,
                 Last_Line_Column => 20).State =
                Editor.Missing_Stale_Recovery.Target_Stale,
              "Outline for another buffer is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Outline_Target
                (Active_Buffer_Matches => True,
                 Stale => True,
                 Line => 1,
                 Column => 1,
                 Last_Line => 1,
                 Last_Line_Column => 20).State =
                Editor.Missing_Stale_Recovery.Target_Refresh_Required,
              "stale Outline requires explicit refresh");
      Assert (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                (Source, False, 1, 1, 1, 20).State =
                Editor.Missing_Stale_Recovery.Target_Source_Less,
              "source-less diagnostic is non-navigable");
      Assert (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                (Source, True, 2, 1, 1, 20).State =
                Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range,
              "diagnostic line out of range is rejected");
      Assert (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                (Candidate, Root, Stale => True).State =
                Editor.Missing_Stale_Recovery.Target_Candidate_Stale,
              "stale build candidate blocks build.run preflight");
      Ada.Directories.Delete_File (Candidate);
      Assert (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                (Candidate, Root).State = Editor.Missing_Stale_Recovery.Target_Missing,
              "deleted build candidate blocks build.run preflight");
   end Test_Outline_Diagnostics_And_Build_Validation;

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




   procedure Test_File_Tree_Preflight_Workspace_Fallback_And_Replace_Report_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Missing : constant String := Root & "/src/gone.adb";
      Missing_Parent_Target : constant String := Root & "/gone/new.adb";
      Skipped : constant Editor.Missing_Stale_Recovery.Replace_Apply_Validation_Summary :=
        (Applied_Targets => 0,
         Missing_Targets => 1,
         Stale_Targets => 1,
         Out_Of_Range_Targets => 1);
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.File_Tree_Mutation_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.File_Tree_Rename_Node),
              "File Tree rename targets are validated at Executor mutation time");
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Mutation_Target
                (Editor.Missing_Stale_Recovery.File_Tree_Activate_Node, Missing, Root).State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "File Tree activation preflight rejects deleted selected nodes");
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Mutation_Target
                (Editor.Missing_Stale_Recovery.File_Tree_Delete_Node, Missing, Root).State =
                Editor.Missing_Stale_Recovery.Target_Missing,
              "File Tree delete preflight rejects already-missing selected nodes");
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Mutation_Target
                (Editor.Missing_Stale_Recovery.File_Tree_Rename_Node, Source, Root).State =
                Editor.Missing_Stale_Recovery.Target_Available,
              "File Tree rename preflight accepts existing in-project nodes");
      Assert (Editor.Missing_Stale_Recovery.Validate_File_Tree_Mutation_Target
                (Editor.Missing_Stale_Recovery.File_Tree_Create_File,
                 Missing_Parent_Target, Root, Root & "/gone").State =
                Editor.Missing_Stale_Recovery.Target_Parent_Directory_Missing,
              "File Tree create preflight reports missing parent instead of fabricating directories");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Active_File_Fallback_Policy
                (Active_File_Missing => False, Reopened_File_Count => 0) =
                Editor.Missing_Stale_Recovery.Workspace_Use_Restored_Active_File,
              "available workspace active file remains selected deterministically");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Active_File_Fallback_Policy
                (Active_File_Missing => True, Reopened_File_Count => 2) =
                Editor.Missing_Stale_Recovery.Workspace_Use_First_Reopened_File,
              "missing workspace active file falls back to first reopened file");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Active_File_Fallback_Label
                (Editor.Missing_Stale_Recovery.Workspace_No_Active_File) =
                "no active file restored",
              "workspace active-file fallback labels are user-readable");
      Assert (not Editor.Missing_Stale_Recovery.Replace_Apply_Skipped_Report_Allowed
                (Command_Reached_Validation => False, Summary => Skipped),
              "replace skipped-target summary is not emitted before apply validation runs");
      Assert (Editor.Missing_Stale_Recovery.Replace_Apply_Skipped_Report_Allowed
                (Command_Reached_Validation => True, Summary => Skipped),
              "replace skipped-target summary is allowed after validation reaches stale/missing targets");
      Assert (Editor.Missing_Stale_Recovery.Assert_File_Tree_Mutations_Preflight_At_Execution,
              "coherence helper covers File Tree mutation preflight");
      Assert (Editor.Missing_Stale_Recovery.Assert_Workspace_Active_File_Fallback_Is_Deterministic,
              "coherence helper covers deterministic workspace active-file fallback");
      Assert (Editor.Missing_Stale_Recovery.Assert_Replace_Skipped_Report_Requires_Validation,
              "coherence helper covers replace skipped-report boundary");
   end Test_File_Tree_Preflight_Workspace_Fallback_And_Replace_Report_Gates;


   procedure Test_Target_Use_Preflight_No_Auto_Refresh_And_Action_Hints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Target_Use_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.Use_Open_Target),
              "open target use validates at execution boundary");
      Assert (Editor.Missing_Stale_Recovery.Target_Use_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.Use_Apply_Replace_Target),
              "replace target use validates immediately before apply");
      Assert (Editor.Missing_Stale_Recovery.Target_Use_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.Use_Run_Build_Target),
              "build target use validates immediately before execution");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_May_Auto_Refresh
                (Editor.Missing_Stale_Recovery.Use_Navigate_Target),
              "navigation may not auto-refresh stale targets");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_May_Auto_Refresh
                (Editor.Missing_Stale_Recovery.Use_Apply_Replace_Target),
              "replace apply may not auto-rerun search");
      Assert (not Editor.Missing_Stale_Recovery.Missing_Target_May_Create_Implicit_File
                (Editor.Missing_Stale_Recovery.Buffer_Surface),
              "missing buffer targets cannot be silently recreated");
      Assert (not Editor.Missing_Stale_Recovery.Missing_Target_May_Create_Implicit_File
                (Editor.Missing_Stale_Recovery.File_Tree_Surface),
              "missing File Tree targets cannot fabricate nodes");
      Assert (Editor.Missing_Stale_Recovery.Failed_Target_Use_Preserves_User_Text
                (Editor.Missing_Stale_Recovery.Use_Save_Target,
                 Editor.Missing_Stale_Recovery.Target_Parent_Directory_Missing),
              "failed save to missing parent preserves dirty user text");
      Assert (Editor.Missing_Stale_Recovery.Failed_Target_Use_Preserves_User_Text
                (Editor.Missing_Stale_Recovery.Use_Reload_Target,
                 Editor.Missing_Stale_Recovery.Target_Unreadable),
              "failed reload from unreadable file preserves buffer text");
      Assert (Editor.Missing_Stale_Recovery.Stale_Target_User_Action_Hint
                (Editor.Missing_Stale_Recovery.Replace_Preview_Surface) =
                "rerun search before replace",
              "replace preview stale state points to explicit rerun recovery");
      Assert (Editor.Missing_Stale_Recovery.Stale_Target_User_Action_Hint
                (Editor.Missing_Stale_Recovery.Build_Surface) =
                "refresh build candidates",
              "stale build candidate points to explicit candidate refresh");
      Assert (Editor.Missing_Stale_Recovery.Project_Transition_Surface_Disposition
                (Editor.Missing_Stale_Recovery.Build_Surface) =
                "clear Build candidates, request, consent, result and output",
              "project transition disposition names all Build transient state");
      Assert (Editor.Missing_Stale_Recovery.Project_Transition_Surface_Disposition
                (Editor.Missing_Stale_Recovery.Buffer_Surface) =
                "preserve guarded dirty buffers",
              "project transition disposition keeps dirty buffers guarded");
      Assert (Editor.Missing_Stale_Recovery.Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh,
              "coherence helper covers target-use validation and no auto-refresh");
      Assert (Editor.Missing_Stale_Recovery.Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate,
              "coherence helper covers no fabrication and text preservation");
      Assert (Editor.Missing_Stale_Recovery.Assert_Stale_Targets_Expose_Explicit_User_Action_Hints,
              "coherence helper covers explicit recovery hints");
   end Test_Target_Use_Preflight_No_Auto_Refresh_And_Action_Hints;



   procedure Test_Recovery_Postconditions_Require_Revalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Missing_Stale_Recovery;
   begin
      Assert
        (Recovery_Command_Postcondition
           (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded) =
         Postcondition_Revalidate_Before_Use,
         "successful search rerun requires target revalidation before navigation/apply");
      Assert
        (Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
           (Recovery_Outline_Refresh, Outline_Surface, Recovery_Succeeded),
         "successful outline refresh does not authorize immediate stale target navigation");
      Assert
        (Recovery_Command_Postcondition
           (Recovery_Quick_Open_Clear_Query, Quick_Open_Surface, Recovery_Succeeded) =
         Postcondition_Surface_Cleared,
         "clear-query recovery clears the owning surface instead of selecting a target");
      Assert
        (Recovery_Command_Postcondition
           (Recovery_Project_Search_Run, Build_Surface, Recovery_Succeeded) =
         Postcondition_No_Target_Use,
         "cross-surface recovery attempts authorize no target use");
      Assert
        (not Recovery_Command_May_Immediately_Consume_Recovered_Target
           (Recovery_Build_Refresh_Candidates, Build_Surface, Recovery_Succeeded),
         "successful candidate refresh still requires build.run preflight");
      Assert
        (not Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
           (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Failed),
         "failed recovery preserves stale state for explicit retry rather than reusing target");
      Assert
        (Recovery_Postcondition_Label (Postcondition_Revalidate_Before_Use) =
         "Recovery completed; revalidate target before use.",
         "postcondition label is user-readable and payload-free");
      Assert
        (Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use,
         "milestone helper covers post-recovery revalidation policy");
   end Test_Recovery_Postconditions_Require_Revalidation;



   procedure Test_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Missing_Stale_Recovery;
   begin
      Assert
        (Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Mark_Stale),
         "stale Project Search results may be marked stale");
      Assert
        (Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Display_Marker),
         "stale markers may be displayed from snapshots");
      Assert
        (Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Block_Target_Use),
         "stale rows block target-consuming actions");
      Assert
        (Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Offer_Recovery_Hint),
         "stale rows may expose a payload-free recovery hint");
      Assert
        (Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Clear_By_Explicit_Recovery),
         "stale state may clear only through explicit recovery");
      Assert
        (not Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Persist_Marker),
         "stale markers are not persisted");
      Assert
        (not Stale_Surface_Lifecycle_Action_Allowed
           (Project_Search_Surface, Lifecycle_Auto_Refresh),
         "stale surfaces cannot auto-refresh");
      Assert
        (not Stale_Surface_Lifecycle_Action_Allowed
           (Replace_Preview_Surface, Lifecycle_Auto_Rerun),
         "stale replace previews cannot auto-rerun search");
      Assert
        (not Stale_Surface_Lifecycle_Action_Allowed
           (Quick_Open_Surface, Lifecycle_Open_Target),
         "stale Quick Open results cannot directly open targets");
      Assert
        (Stale_Surface_Lifecycle_Action_Is_Transient (Lifecycle_Display_Marker),
         "displayed stale markers are transient");
      Assert
        (not Stale_Surface_Lifecycle_Action_Is_Transient (Lifecycle_Persist_Marker),
         "persisting a stale marker is intentionally rejected by the lifecycle policy");
      Assert
        (not Stale_Surface_Lifecycle_Action_May_Use_Payload
           (Lifecycle_Offer_Recovery_Hint),
         "recovery hints cannot carry stale target payloads");
      Assert
        (Stale_Surface_Lifecycle_Requires_Executor_Recovery (Build_Surface),
         "stale Build state requires explicit Executor recovery");
      Assert
        (Stale_Surface_Lifecycle_Action_Label
           (Lifecycle_Clear_By_Explicit_Recovery) = "clear by explicit recovery",
         "lifecycle labels are user-readable");
      Assert
        (Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit,
         "milestone helper covers stale surface lifecycle policy");
   end Test_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;

   procedure Test_Milestone_Coherence_Helper
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Assert_Missing_Stale_Target_Recovery_Coherent,
              "Phase 561 coherence helper covers labels, stale validation, " &
              "command-boundary invariants, render boundary and persistence exclusion");
   end Test_Milestone_Coherence_Helper;



   procedure Test_Surface_Specific_Outcome_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Outside : constant String := "/tmp/editor-tests/phase561_outside_search.adb";
   begin
      Reset_Fixture;
      Write_File (Outside, "outside");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Quick_Open_Result_Target
                   (Root & "/src/gone.adb", Root)) = "Quick Open result is stale.",
              "Quick Open stale activation gets surface-specific wording");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                   (Root & "/src/gone.adb", 1, 1)) = "Search target no longer exists.",
              "missing Project Search target message names the Search surface");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                   (Source, 9, 1)) = "Search target line is unavailable.",
              "Project Search line-out-of-range message is distinct");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Outline_Target
                   (Active_Buffer_Matches => False,
                    Stale => False,
                    Line => 1,
                    Column => 1,
                    Last_Line => 1,
                    Last_Line_Column => 80)) = "Outline belongs to another buffer.",
              "Outline previous-buffer target gets explicit wording");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                   (Root & "/src/gone.adb", True, 1, 1, 1, 80)) =
                "Diagnostic target file is unavailable.",
              "missing Diagnostic source message is explicit");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                   (Root & "/gone.gpr", Root)) = "Build candidate file no longer exists.",
              "missing Build candidate message is explicit");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Build_Working_Context_Target
                   (Root & "/gone-root")) = "Build working directory is unavailable.",
              "missing Build working context message is explicit");
      Assert (Editor.Missing_Stale_Recovery.Validate_Search_Result_Target
                (Outside, 1, 1, Project_Root => Root).State =
                Editor.Missing_Stale_Recovery.Target_Outside_Project,
              "Project Search rejects stale previous-project targets before activation");
      Assert (Editor.Missing_Stale_Recovery.Validate_Replace_Preview_Target
                (Outside, 1, 1, Project_Root => Root).State =
                Editor.Missing_Stale_Recovery.Target_Outside_Project,
              "replace preview rejects stale previous-project targets before apply");
      Assert (Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
                (Outside, True, 1, 1, 1, 80, Project_Root => Root).State =
                Editor.Missing_Stale_Recovery.Target_Outside_Project,
              "Diagnostics rejects stale previous-project targets before navigation");
      Ada.Directories.Delete_File (Outside);
   end Test_Surface_Specific_Outcome_Messages;

   procedure Test_Render_Availability_And_Persistence_Exclusion_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.Missing_Stale_Recovery.Render_May_Repair_Targets,
              "render does not repair stale target state");
      Assert (not Editor.Missing_Stale_Recovery.Availability_May_Repair_Targets,
              "availability checks do not repair stale target state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Run_From_Render
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "recovery commands cannot be render-triggered");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Run_From_Availability
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run),
              "recovery commands cannot be availability-triggered");
      Assert (Editor.Missing_Stale_Recovery.Persistence_Field_Allowed
                (Editor.Missing_Stale_Recovery.Persist_Workspace_Structural_Reference),
              "workspace structural references remain persistable");
      Assert (Editor.Missing_Stale_Recovery.Persistence_Field_Allowed
                (Editor.Missing_Stale_Recovery.Persist_Keybinding_Command_Name),
              "keybindings may persist canonical command names only");
      Assert (not Editor.Missing_Stale_Recovery.Persistence_Field_Allowed
                (Editor.Missing_Stale_Recovery.Persist_Stale_Target_Payload),
              "stale target payloads are excluded from persistence");
      Assert (not Editor.Missing_Stale_Recovery.Persistence_Field_Allowed
                (Editor.Missing_Stale_Recovery.Persist_Recovery_Command_Payload),
              "recovery command payloads are excluded from persistence");
      Assert (not Editor.Missing_Stale_Recovery.Persistence_Field_Allowed
                (Editor.Missing_Stale_Recovery.Persist_Command_Outcome_Message),
              "command outcome messages remain transient");
   end Test_Render_Availability_And_Persistence_Exclusion_Depth;


   procedure Test_Access_Distinctions_And_Line_Only_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Result : Editor.Missing_Stale_Recovery.Target_Validation_Result;
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Validate_Buffer_Access_State
                ("readonly.adb", Target_Exists => True, Ordinary_File => True,
                 Readable => False, Writable => True, Require_Read => True).State =
                Editor.Missing_Stale_Recovery.Target_Unreadable,
              "explicit access validation distinguishes unreadable files");
      Assert (Editor.Missing_Stale_Recovery.Validate_Buffer_Access_State
                ("locked.adb", Target_Exists => True, Ordinary_File => True,
                 Readable => True, Writable => False, Require_Write => True).State =
                Editor.Missing_Stale_Recovery.Target_Unwritable,
              "explicit access validation distinguishes unwritable files");
      Assert (Editor.Missing_Stale_Recovery.Target_Outcome_Message
                (Editor.Missing_Stale_Recovery.Validate_Buffer_Access_State
                   ("locked.adb", Target_Exists => True, Ordinary_File => True,
                    Readable => True, Writable => False, Require_Write => True)) =
                "File is not writable.",
              "unwritable failure has a distinct command outcome message");
      Result := Editor.Missing_Stale_Recovery.Validate_Diagnostic_Target
        (Source, Has_Source => True, Line => 1, Column => 0,
         Last_Line => 1, Last_Line_Column => 80);
      Assert (Result.State = Editor.Missing_Stale_Recovery.Target_Available,
              "line-only diagnostic target is navigable under line-start policy");
      Assert (Result.Column = 1,
              "line-only diagnostic navigation resolves to line start");
   end Test_Access_Distinctions_And_Line_Only_Diagnostics;

   procedure Test_Search_Content_Replace_Summary_And_Stale_Boost_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Source : constant String := Root & "/src/main.adb";
      Outside : constant String := "/tmp/editor-tests/phase561_recent_outside.adb";
      Summary : constant Editor.Missing_Stale_Recovery.Replace_Apply_Validation_Summary :=
        (Applied_Targets => 2, Missing_Targets => 1, Stale_Targets => 1,
         Out_Of_Range_Targets => 1);
   begin
      Reset_Fixture;
      Write_File (Outside, "outside");
      Assert (Editor.Missing_Stale_Recovery.Search_Result_Content_State
                (Target_Exists => True, Line_Available => True,
                 Match_Still_Present => False, File_Touched_Since_Search => False) =
                Editor.Missing_Stale_Recovery.Target_Stale,
              "search row whose line no longer contains the match is stale");
      Assert (Editor.Missing_Stale_Recovery.Search_Result_Content_State
                (Target_Exists => True, Line_Available => True,
                 Match_Still_Present => True, File_Touched_Since_Search => True) =
                Editor.Missing_Stale_Recovery.Target_Stale,
              "search row from an edited file is stale until rerun");
      Assert (Editor.Missing_Stale_Recovery.Replace_Apply_Summary_Message (Summary) =
                "Replace applied to available targets; stale or missing targets were skipped.",
              "replace apply summary reports bounded stale/missing skips only after validation");
      Assert (Editor.Missing_Stale_Recovery.Quick_Open_Session_Recent_Boost_Allowed
                (Source, Root),
              "session-recent boost may use an available in-project file");
      Assert (not Editor.Missing_Stale_Recovery.Quick_Open_Session_Recent_Boost_Allowed
                (Outside, Root),
              "session-recent boost cannot inject an outside-project target");
      Assert (not Editor.Missing_Stale_Recovery.Quick_Open_Session_Recent_Boost_Allowed
                (Root & "/src/gone.adb", Root),
              "session-recent boost cannot inject a stale missing target");
      Ada.Directories.Delete_File (Outside);
   end Test_Search_Content_Replace_Summary_And_Stale_Boost_Gates;

   procedure Test_Build_Consent_File_Tree_Restore_And_No_Op_Outcomes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Fixture_Root;
      Candidate : constant String := Root & "/demo.gpr";
   begin
      Reset_Fixture;
      Assert (Editor.Missing_Stale_Recovery.Build_Request_Consent_Remains_Valid
                (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                   (Candidate, Root)),
              "build request consent remains valid only for the validated selected candidate");
      Assert (not Editor.Missing_Stale_Recovery.Build_Request_Consent_Remains_Valid
                (Editor.Missing_Stale_Recovery.Validate_Build_Candidate_Target
                   (Candidate, Root, Stale => True)),
              "stale selected candidate invalidates build request consent");
      Assert (Editor.Missing_Stale_Recovery.File_Tree_Expanded_Path_Restore_State
                (Root & "/src") = Editor.Missing_Stale_Recovery.Target_Available,
              "workspace File Tree expansion restore keeps existing directories");
      Assert (Editor.Missing_Stale_Recovery.File_Tree_Expanded_Path_Restore_State
                (Root & "/src/gone") = Editor.Missing_Stale_Recovery.Target_Missing,
              "workspace File Tree expansion restore ignores missing paths");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_No_Op_Message
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Clear_Results) =
                "No search results to clear.",
              "clear-results recovery has a clear no-op outcome");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_No_Op_Message
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Replace_Clear_Preview) =
                "No replace preview to clear.",
              "clear-preview recovery has a clear no-op outcome");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_No_Op_Message
                (Editor.Missing_Stale_Recovery.Recovery_Diagnostics_Clear) =
                "No diagnostics to clear.",
              "diagnostics.clear recovery has a clear no-op outcome");
   end Test_Build_Consent_File_Tree_Restore_And_No_Op_Outcomes;


   procedure Test_Selection_Marker_Fabrication_And_Reconsent_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Clean_Summary : constant Editor.Missing_Stale_Recovery.Replace_Apply_Validation_Summary :=
        (Applied_Targets => 3, Missing_Targets => 0, Stale_Targets => 0,
         Out_Of_Range_Targets => 0);
      Stale_Summary : constant Editor.Missing_Stale_Recovery.Replace_Apply_Validation_Summary :=
        (Applied_Targets => 2, Missing_Targets => 0, Stale_Targets => 1,
         Out_Of_Range_Targets => 0);
   begin
      Assert (Editor.Missing_Stale_Recovery.Surface_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.File_Tree_Surface),
              "File Tree stale nodes validate at execution boundaries");
      Assert (Editor.Missing_Stale_Recovery.Surface_Requires_Execution_Validation
                (Editor.Missing_Stale_Recovery.Build_Surface),
              "Build candidates validate at build.run preflight");
      Assert (Editor.Missing_Stale_Recovery.Selected_Stale_Target_Selection_Action
                (Editor.Missing_Stale_Recovery.File_Tree_Surface) =
                "clear or mark selected File Tree node stale",
              "stale File Tree selection is cleared or marked, not persisted as a payload");
      Assert (Editor.Missing_Stale_Recovery.Selected_Stale_Target_Selection_Action
                (Editor.Missing_Stale_Recovery.Build_Surface) =
                "invalidate selected build request consent",
              "stale Build candidate selection invalidates request consent");
      Assert (not Editor.Missing_Stale_Recovery.Failed_Recovery_Operation_May_Fabricate_State
                (Editor.Missing_Stale_Recovery.File_Tree_Surface),
              "failed File Tree recovery operations cannot fabricate nodes");
      Assert (not Editor.Missing_Stale_Recovery.Failed_Recovery_Operation_May_Fabricate_State
                (Editor.Missing_Stale_Recovery.Workspace_Surface),
              "failed workspace load cannot fabricate project or buffer state");
      Assert (Editor.Missing_Stale_Recovery.Recent_Missing_Marker_Is_Snapshot_Derived,
              "Recent Projects missing marker is snapshot-derived");
      Assert (not Editor.Missing_Stale_Recovery.Recent_Missing_Marker_May_Delete_Files,
              "Recent Projects missing marker never deletes files");
      Assert (not Editor.Missing_Stale_Recovery.Recent_Missing_Marker_May_Clear_Workspace,
              "Recent Projects missing marker never clears workspace state");
      Assert (Editor.Missing_Stale_Recovery.Buffer_Known_Missing_State_Allowed
                (Dirty => True, State => Editor.Missing_Stale_Recovery.Target_Missing),
              "dirty deleted backing file can be represented as known missing while preserving text");
      Assert (Editor.Missing_Stale_Recovery.Buffer_Known_Missing_State_Allowed
                (Dirty => False, State => Editor.Missing_Stale_Recovery.Target_Missing),
              "clean deleted backing file can be represented as known missing");
      Assert (Editor.Missing_Stale_Recovery.Replace_All_May_Apply (Clean_Summary),
              "replace all may apply only after every target validates");
      Assert (not Editor.Missing_Stale_Recovery.Replace_All_May_Apply (Stale_Summary),
              "replace all rejects a batch with any stale target");
      Assert (Editor.Missing_Stale_Recovery.Build_Candidate_Material_Identity_Matches
                ("demo.gpr", ".", "demo.gpr", "."),
              "same build candidate identity preserves request material identity");
      Assert (Editor.Missing_Stale_Recovery.Build_Candidate_Refresh_Requires_Reconsent
                ("demo.gpr", ".", "other.gpr", "."),
              "changed build candidate identity requires renewed consent");
   end Test_Selection_Marker_Fabrication_And_Reconsent_Gates;

   procedure Test_Recovery_Hints_Snapshot_And_Dirty_Preservation_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Stale,
         Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/main.adb"),
         Line    => 7,
         Column  => 1);
      Quick_Open_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Stale,
         Surface => Editor.Missing_Stale_Recovery.Quick_Open_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/main.adb"),
         Line    => 0,
         Column  => 0);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_For_Surface
                (Editor.Missing_Stale_Recovery.Project_Search_Surface) =
              Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
              "stale Search results point to explicit rerun command");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Can_Address_Result
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run, Search_Result),
              "explicit rerun command can address stale Search result only through Executor path");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Hint_Message (Search_Result) =
                "Search result is stale. Recovery: rerun search.",
              "stale Search outcome carries a user action hint without target payload");
      Assert (Editor.Missing_Stale_Recovery.Snapshot_Status_Is_Transient (Quick_Open_Result),
              "stale snapshot status is transient");
      Assert (not Editor.Missing_Stale_Recovery.Snapshot_Status_May_Be_Persisted
                (Quick_Open_Result),
              "stale snapshot status is excluded from persistence");
      Assert (not Editor.Missing_Stale_Recovery.Snapshot_Status_May_Probe_Filesystem,
              "snapshot projection cannot probe filesystem");
      Assert (not Editor.Missing_Stale_Recovery.Workspace_Load_May_Restore_Unsaved_Text,
              "workspace load never restores unsaved text from persistence");
      Assert (not Editor.Missing_Stale_Recovery.Project_Transition_May_Discard_Dirty_Buffer,
              "project transition cannot discard guarded dirty buffers");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Requires_Dirty_Guard
                (Editor.Missing_Stale_Recovery.Recovery_File_Reload_From_Disk),
              "reload recovery remains dirty-guarded");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Requires_Dirty_Guard
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "non-buffer refresh recovery does not require buffer dirty confirmation");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Hints_Map_To_Explicit_Commands,
              "milestone helper covers explicit command hints");
      Assert (Editor.Missing_Stale_Recovery.Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing,
              "milestone helper covers transient snapshot non-persistence");
      Assert (Editor.Missing_Stale_Recovery.Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text,
              "milestone helper covers dirty text preservation during recovery");
   end Test_Recovery_Hints_Snapshot_And_Dirty_Preservation_Depth;

   procedure Test_Event_Driven_Surface_Staleness_And_Clear_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_On_Surface
                (Editor.Missing_Stale_Recovery.Event_Buffer_Edited,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface) =
              Editor.Missing_Stale_Recovery.Surface_Marked_Stale,
              "buffer edit marks Project Search results stale");
      Assert (Editor.Missing_Stale_Recovery.Event_State_After
                (Editor.Missing_Stale_Recovery.Event_Buffer_Edited,
                 Editor.Missing_Stale_Recovery.Outline_Surface) =
              Editor.Missing_Stale_Recovery.Target_Refresh_Required,
              "buffer edit marks Outline refresh-required");
      Assert (Editor.Missing_Stale_Recovery.Event_State_After
                (Editor.Missing_Stale_Recovery.Event_Buffer_Reloaded,
                 Editor.Missing_Stale_Recovery.Replace_Preview_Surface) =
              Editor.Missing_Stale_Recovery.Target_Preview_Stale,
              "buffer reload marks replace preview stale");
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_On_Surface
                (Editor.Missing_Stale_Recovery.Event_Project_Switched,
                 Editor.Missing_Stale_Recovery.Quick_Open_Surface) =
              Editor.Missing_Stale_Recovery.Surface_Cleared,
              "project switch clears Quick Open results");
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_On_Surface
                (Editor.Missing_Stale_Recovery.Event_Project_Closed,
                 Editor.Missing_Stale_Recovery.Build_Surface) =
              Editor.Missing_Stale_Recovery.Surface_Cleared,
              "project close clears Build request/candidate state");
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_On_Surface
                (Editor.Missing_Stale_Recovery.Event_Project_Search_Rerun,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface) =
              Editor.Missing_Stale_Recovery.Surface_Replaced,
              "explicit search rerun replaces stale search results");
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_On_Surface
                (Editor.Missing_Stale_Recovery.Event_Project_Search_Rerun,
                 Editor.Missing_Stale_Recovery.Replace_Preview_Surface) =
              Editor.Missing_Stale_Recovery.Surface_Cleared,
              "search rerun clears old replace preview");
      Assert (Editor.Missing_Stale_Recovery.Event_Effect_Label
                (Editor.Missing_Stale_Recovery.Surface_Replaced) =
              "replaced by explicit refresh",
              "event effect label is user-readable");
      Assert (Editor.Missing_Stale_Recovery.Surface_Event_Effect_Is_Transient
                (Editor.Missing_Stale_Recovery.Surface_Marked_Stale),
              "stale event effects are transient");
      Assert (not Editor.Missing_Stale_Recovery.Surface_Event_Effect_Is_Transient
                (Editor.Missing_Stale_Recovery.Surface_Unchanged),
              "unchanged event effects are not persisted recovery state");
      Assert (not Editor.Missing_Stale_Recovery.Event_May_Create_Files
                (Editor.Missing_Stale_Recovery.Event_File_Tree_Refreshed),
              "explicit refresh events never fabricate files");
      Assert (not Editor.Missing_Stale_Recovery.Event_May_Bypass_Executor
                (Editor.Missing_Stale_Recovery.Event_Build_Candidates_Refreshed),
              "explicit recovery events do not bypass Executor routing");
      Assert (Editor.Missing_Stale_Recovery.Assert_Content_And_Project_Events_Update_Recovery_Surfaces,
              "milestone helper covers event-driven stale and clear policies");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor,
              "milestone helper covers event no-fabrication/no-bypass policy");
   end Test_Event_Driven_Surface_Staleness_And_Clear_Policies;

   procedure Test_Non_Executor_Triggers_And_No_Auto_Remap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Probe_Filesystem
                (Editor.Missing_Stale_Recovery.Trigger_User_Executor_Command),
              "explicit Executor recovery command may validate targets at execution");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Mutate_State
                (Editor.Missing_Stale_Recovery.Trigger_User_Executor_Command),
              "explicit Executor recovery command may replace stale surface state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Probe_Filesystem
                (Editor.Missing_Stale_Recovery.Trigger_Render_Snapshot),
              "render snapshot cannot probe stale targets");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Mutate_State
                (Editor.Missing_Stale_Recovery.Trigger_Availability_Check),
              "availability checks cannot repair stale targets");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Auto_Refresh
                (Editor.Missing_Stale_Recovery.Trigger_Background_Watcher),
              "Phase 561 has no filesystem watcher or background refresh recovery path");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Persist_Recovery_State
                (Editor.Missing_Stale_Recovery.Trigger_Workspace_Save),
              "workspace save cannot persist transient recovery state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Probe_Filesystem
                (Editor.Missing_Stale_Recovery.Trigger_Command_Palette_View),
              "Command Palette projection cannot validate payload targets");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Trigger_May_Mutate_State
                (Editor.Missing_Stale_Recovery.Trigger_Keybinding_Resolution),
              "keybinding resolution cannot mutate stale target state");
      Assert (Editor.Missing_Stale_Recovery.Target_Path_Identity_Matches
                ("src/main.adb", "src/main.adb"),
              "unchanged path identity matches");
      Assert (not Editor.Missing_Stale_Recovery.Target_Path_Identity_Matches
                ("src/main.adb", "src/moved.adb"),
              "moved path is not silently remapped");
      Assert (not Editor.Missing_Stale_Recovery.Missing_Target_May_Be_Auto_Remapped,
              "missing targets are not auto-remapped");
      Assert (Editor.Missing_Stale_Recovery.Assert_Non_Executor_Recovery_Triggers_Are_Observational,
              "milestone helper covers non-Executor observational trigger policy");
      Assert (Editor.Missing_Stale_Recovery.Assert_Missing_Targets_Are_Not_Remapped,
              "milestone helper covers no auto-remap policy");
   end Test_Non_Executor_Triggers_And_No_Auto_Remap;


   procedure Test_Staleness_Provenance_Project_Scope_And_Previous_Project_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Staleness_Provenance
          (Editor.Missing_Stale_Recovery.Project_Search_Surface,
           Editor.Missing_Stale_Recovery.Staleness_File_Content_Changed);
      Preview_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Staleness_Provenance
          (Editor.Missing_Stale_Recovery.Replace_Preview_Surface,
           Editor.Missing_Stale_Recovery.Staleness_Snapshot_Generation_Mismatch);
      Build_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Staleness_Provenance
          (Editor.Missing_Stale_Recovery.Build_Surface,
           Editor.Missing_Stale_Recovery.Staleness_Candidate_Identity_Changed);
   begin
      Assert (Editor.Missing_Stale_Recovery.Staleness_Reason_Label
                (Editor.Missing_Stale_Recovery.Staleness_Project_Identity_Mismatch) =
              "project identity changed",
              "staleness provenance label is user-readable");
      Assert (Search_Result.State = Editor.Missing_Stale_Recovery.Target_Stale,
              "edited file marks Project Search result stale by explicit provenance");
      Assert (Preview_Result.State = Editor.Missing_Stale_Recovery.Target_Preview_Stale,
              "snapshot mismatch marks replace preview stale");
      Assert (Build_Result.State = Editor.Missing_Stale_Recovery.Target_Candidate_Stale,
              "candidate identity changes mark Build request stale");
      Assert (not Editor.Missing_Stale_Recovery.Staleness_Reason_May_Be_Persisted
                (Editor.Missing_Stale_Recovery.Staleness_File_Content_Changed),
              "staleness provenance is transient and not persisted");
      Assert (Editor.Missing_Stale_Recovery.Staleness_Reason_Requires_Explicit_Recovery
                (Editor.Missing_Stale_Recovery.Staleness_Project_Identity_Mismatch),
              "project identity mismatch requires explicit recovery");
      Assert (Editor.Missing_Stale_Recovery.Project_Scope_Identity_Matches
                ("/tmp/editor-phase561", "/tmp/editor-phase561"),
              "matching project identity is accepted");
      Assert (not Editor.Missing_Stale_Recovery.Project_Scope_Identity_Matches
                ("/tmp/editor-phase561", "/tmp/other-phase561"),
              "previous-project identity cannot be reused for stale rows");
      Assert (not Editor.Missing_Stale_Recovery.Stale_Target_May_Be_Opened_From_Previous_Project,
              "stale previous-project target cannot be opened");
      Assert (Editor.Missing_Stale_Recovery.Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped,
              "milestone helper covers staleness provenance and project-scope identity");
   end Test_Staleness_Provenance_Project_Scope_And_Previous_Project_Gates;


   procedure Test_Workspace_Summary_And_Executor_Clear_Policy_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Stale_Workspace : constant Editor.Missing_Stale_Recovery.Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 2,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 1,
         Invalid_Caret_Targets  => 1,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
      Missing_Project : constant Editor.Missing_Stale_Recovery.Workspace_Recovery_Summary :=
        (Project_Missing        => True,
         Missing_Open_Files     => 7,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 4,
         Invalid_Caret_Targets  => 3,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
   begin
      Assert (Editor.Missing_Stale_Recovery.Workspace_Recovery_Primary_Outcome_Count
                (Stale_Workspace) = 1,
              "workspace missing-reference recovery emits one primary outcome");
      Assert (Editor.Missing_Stale_Recovery.Workspace_Recovery_Primary_Outcome_Count
                (Missing_Project) = 1,
              "missing workspace project still emits only one primary outcome");
      Assert (not Editor.Missing_Stale_Recovery.Workspace_Recovery_Summary_May_Be_Persisted
                (Stale_Workspace),
              "workspace recovery summary remains transient");
      Assert (not Editor.Missing_Stale_Recovery.Availability_Check_May_Write_Persistence,
              "availability cannot write recovery persistence");
      Assert (not Editor.Missing_Stale_Recovery.Availability_Check_May_Clear_Stale_State,
              "availability cannot clear stale state");
      Assert (not Editor.Missing_Stale_Recovery.Render_Snapshot_May_Clear_Stale_State,
              "render cannot clear stale state");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_May_Clear_Surface
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.File_Tree_Surface,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "Executor-routed File Tree refresh may clear File Tree stale state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Clear_Surface
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "File Tree refresh cannot repair Project Search stale state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Clear_Surface
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.File_Tree_Surface,
                 Editor.Missing_Stale_Recovery.Invocation_Availability),
              "availability cannot execute the stale-state clear");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
                (Editor.Missing_Stale_Recovery.Recovery_Workspace_Load),
              "failed workspace recovery preserves guarded dirty text");
      Assert (Editor.Missing_Stale_Recovery.Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome,
              "milestone helper covers workspace one-outcome transient summary");
      Assert (Editor.Missing_Stale_Recovery.Assert_Availability_And_Render_Cannot_Clear_Stale_State,
              "milestone helper covers observational availability/render boundaries");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor,
              "milestone helper covers scoped Executor-only stale-state clearing");
   end Test_Workspace_Summary_And_Executor_Clear_Policy_Depth;


   procedure Test_Command_Execution_Revalidation_And_Cached_Result_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Validation_Phase_May_Probe_Filesystem
                (Editor.Missing_Stale_Recovery.Validation_Command_Execution),
              "command execution validation may probe the target");
      Assert (Editor.Missing_Stale_Recovery.Validation_Phase_May_Mutate_State
                (Editor.Missing_Stale_Recovery.Validation_Command_Execution),
              "command execution validation may update owning recovery state");
      Assert (Editor.Missing_Stale_Recovery.Validation_Phase_May_Authorize_Target_Use
                (Editor.Missing_Stale_Recovery.Validation_Command_Execution),
              "only command execution validation authorizes target use");
      Assert (not Editor.Missing_Stale_Recovery.Validation_Phase_May_Probe_Filesystem
                (Editor.Missing_Stale_Recovery.Validation_Snapshot_Projection),
              "snapshot projection cannot probe files");
      Assert (not Editor.Missing_Stale_Recovery.Validation_Phase_May_Authorize_Target_Use
                (Editor.Missing_Stale_Recovery.Validation_Availability_Check),
              "availability validation cannot authorize target use");
      Assert (not Editor.Missing_Stale_Recovery.Validation_Phase_May_Mutate_State
                (Editor.Missing_Stale_Recovery.Validation_Persistence_Save),
              "persistence save cannot mutate recovery state");
      Assert (not Editor.Missing_Stale_Recovery.Validation_Phase_May_Reuse_Cached_Target_Result
                (Editor.Missing_Stale_Recovery.Validation_Command_Execution),
              "even command execution cannot treat cached target validation as authoritative");
      Assert (not Editor.Missing_Stale_Recovery.Cached_Target_Validation_May_Be_Applied
                (Editor.Missing_Stale_Recovery.Replace_Preview_Surface,
                 Editor.Missing_Stale_Recovery.Use_Apply_Replace_Target),
              "replace preview apply must revalidate instead of using cached validation");
      Assert (Editor.Missing_Stale_Recovery.Execution_Revalidation_Required
                (Editor.Missing_Stale_Recovery.Diagnostics_Surface,
                 Editor.Missing_Stale_Recovery.Use_Navigate_Target),
              "Diagnostics navigation requires execution-time revalidation");
      Assert (Editor.Missing_Stale_Recovery.Execution_Revalidation_Message
                (Editor.Missing_Stale_Recovery.Project_Search_Surface) =
              "Search result is revalidated before use.",
              "search recovery hint describes execution revalidation without payloads");
      Assert (Editor.Missing_Stale_Recovery.Assert_Target_Validation_Is_Command_Execution_Boundary,
              "milestone helper covers command-execution validation boundary");
      Assert (Editor.Missing_Stale_Recovery.Assert_Cached_Target_Validation_Is_Never_Authoritative,
              "milestone helper covers cached validation rejection");
   end Test_Command_Execution_Revalidation_And_Cached_Result_Boundaries;

   procedure Test_Confirmation_Forbidden_Mechanism_And_Transient_Field_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Pending : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Command_Availability_When_Confirmation_Pending
          (Editor.Missing_Stale_Recovery.Build_Surface);
   begin
      Assert (Pending.State = Editor.Missing_Stale_Recovery.Target_Command_Pending,
              "confirmation-pending commands are represented as unavailable");
      Assert (Editor.Missing_Stale_Recovery.Availability_Reason (Pending.State) =
              "Command unavailable while confirmation is pending.",
              "confirmation-pending availability message is user-readable");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Available_With_Confirmation_Pending
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates),
              "recovery command cannot run while confirmation is pending");
      Assert (not Editor.Missing_Stale_Recovery.Forbidden_Recovery_Mechanism_Allowed
                (Editor.Missing_Stale_Recovery.Forbidden_Filesystem_Watcher),
              "filesystem watcher recovery remains a non-goal");
      Assert (not Editor.Missing_Stale_Recovery.Forbidden_Recovery_Mechanism_Allowed
                (Editor.Missing_Stale_Recovery.Forbidden_Shell_Execution),
              "shell recovery remains a non-goal");
      Assert (not Editor.Missing_Stale_Recovery.Forbidden_Recovery_Mechanism_Allowed
                (Editor.Missing_Stale_Recovery.Forbidden_Command_Palette_Target_Payload),
              "Command Palette target payload recovery remains forbidden");
      Assert (not Editor.Missing_Stale_Recovery.Transient_Surface_Field_May_Be_Persisted
                (Editor.Missing_Stale_Recovery.Transient_Diagnostics_Filter),
              "Diagnostics transient filter/selection state is not persisted");
      Assert (not Editor.Missing_Stale_Recovery.Transient_Surface_Field_May_Be_Persisted
                (Editor.Missing_Stale_Recovery.Transient_Build_Output),
              "Build output remains transient for Phase 561 recovery");
      Assert (Editor.Missing_Stale_Recovery.Project_Transition_Clears_Build_Transient
                (Editor.Missing_Stale_Recovery.Transient_Build_Consent),
              "project transition clears stale Build consent");
      Assert (Editor.Missing_Stale_Recovery.Project_Transition_Clears_Build_Transient
                (Editor.Missing_Stale_Recovery.Transient_Build_Result),
              "project transition clears stale Build result state");
      Assert (not Editor.Missing_Stale_Recovery.Project_Transition_Clears_Build_Transient
                (Editor.Missing_Stale_Recovery.Transient_Outline_Rows),
              "Build-specific transient clear helper is scoped to Build state only");
      Assert (Editor.Missing_Stale_Recovery.Assert_Confirmation_Pending_Blocks_Recovery_Commands,
              "milestone helper covers confirmation-pending command blocking");
      Assert (Editor.Missing_Stale_Recovery.Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled,
              "milestone helper covers non-goal recovery mechanisms");
      Assert (Editor.Missing_Stale_Recovery.Assert_Transient_Surface_Fields_Are_Not_Persisted,
              "milestone helper covers transient field persistence exclusions");
      Assert (Editor.Missing_Stale_Recovery.Assert_Project_Transition_Clears_Build_Transient_State,
              "milestone helper covers Build transient clearing on project transition");
   end Test_Confirmation_Forbidden_Mechanism_And_Transient_Field_Policies;

   procedure Test_Failed_Validation_Disposition_And_Non_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Stale,
         Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/main.adb"),
         Line    => 4,
         Column  => 1);
      Missing_Buffer : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Missing,
         Surface => Editor.Missing_Stale_Recovery.Buffer_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/deleted.adb"),
         Line    => 0,
         Column  => 0);
   begin
      Assert (not Editor.Missing_Stale_Recovery.Target_Validation_Failure_May_Mutate_State
                (Search_Result),
              "stale target validation failure cannot mutate surface state");
      Assert (not Editor.Missing_Stale_Recovery.Target_Validation_Failure_May_Mutate_State
                (Missing_Buffer),
              "missing target validation failure cannot mutate buffer state");
      Assert (Editor.Missing_Stale_Recovery.Target_Validation_Failure_Disposition
                (Search_Result) = Editor.Missing_Stale_Recovery.Failure_Marks_Surface_Stale,
              "stale validation failures are marked stale without repair");
      Assert (Editor.Missing_Stale_Recovery.Target_Validation_Failure_Disposition
                (Missing_Buffer) = Editor.Missing_Stale_Recovery.Failure_Preserves_Surface_State,
              "missing buffer failures preserve existing buffer state");
      Assert (Editor.Missing_Stale_Recovery.Validation_Failure_Disposition_Label
                (Editor.Missing_Stale_Recovery.Failure_Marks_Surface_Stale) =
              "mark target stale and require explicit recovery",
              "failure disposition labels are user-readable");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_Failure_May_Discard_User_Text
                (Editor.Missing_Stale_Recovery.Use_Save_Target,
                 Editor.Missing_Stale_Recovery.Target_Missing),
              "failed save to missing target cannot discard user text");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Failed_Attempt_Clears_Stale_State
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run),
              "failed recovery command cannot clear stale Project Search state");
      Assert (Editor.Missing_Stale_Recovery.Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State,
              "milestone helper covers non-mutating failed validation");
   end Test_Failed_Validation_Disposition_And_Non_Mutation;


   procedure Test_Non_Destructive_Recovery_Action_And_Message_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Stale,
         Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/main.adb"),
         Line    => 7,
         Column  => 1);
      Recent_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Missing,
         Surface => Editor.Missing_Stale_Recovery.Recent_Project_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("/tmp/missing-project"),
         Line    => 0,
         Column  => 0);
      Pending_Result : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Command_Availability_When_Confirmation_Pending
          (Editor.Missing_Stale_Recovery.Project_Search_Surface);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Action_Is_Safe_For_State
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
                 Search_Result),
              "rerun search is the explicit safe recovery path for stale search results");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Action_Is_Safe_For_State
                (Editor.Missing_Stale_Recovery.Recovery_Recent_Projects_Remove_Missing,
                 Recent_Result),
              "remove-missing recent-project recovery is explicit and safe");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Action_Is_Safe_For_State
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
                 Pending_Result),
              "confirmation-pending state blocks otherwise valid recovery action");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Delete_User_File
                (Editor.Missing_Stale_Recovery.Recovery_Recent_Projects_Remove_Missing),
              "recent-project missing cleanup never deletes user files");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Fabricate_Project_State
                (Editor.Missing_Stale_Recovery.Recovery_Workspace_Load),
              "workspace recovery cannot fabricate project state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Message_May_Embed_Target_Payload
                (Search_Result),
              "recovery messages do not embed stale target payloads");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Message_Identifies_Surface_And_Category
                (Search_Result),
              "recovery messages identify surface and category without payloads");
      Assert (Editor.Missing_Stale_Recovery.Target_State_Has_Explicit_Recovery_Path
                (Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Target_Stale),
              "stale search state has an explicit recovery action");
      Assert (Editor.Missing_Stale_Recovery.Target_State_Has_Explicit_Recovery_Path
                (Editor.Missing_Stale_Recovery.Build_Surface,
                 Editor.Missing_Stale_Recovery.Target_Candidate_Stale),
              "stale build candidate state has an explicit recovery action");
      Assert (not Editor.Missing_Stale_Recovery.Target_State_Has_Explicit_Recovery_Path
                (Editor.Missing_Stale_Recovery.Quick_Open_Surface,
                 Editor.Missing_Stale_Recovery.Target_No_Result_Selected),
              "selectionless state does not invent recovery payloads");
      Assert (not Editor.Missing_Stale_Recovery.Target_State_Has_Explicit_Recovery_Path
                (Editor.Missing_Stale_Recovery.Diagnostics_Surface,
                 Editor.Missing_Stale_Recovery.Target_Source_Less),
              "source-less diagnostic remains non-navigable and has no fabricated recovery target");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless,
              "milestone helper covers safe non-destructive payload-free recovery actions");
   end Test_Non_Destructive_Recovery_Action_And_Message_Policies;


   procedure Test_Recovery_Attempt_Result_Disposition_And_Message_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Disposition
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Recovery_Succeeded) =
              Editor.Missing_Stale_Recovery.Recovery_State_Replaced,
              "successful project-search rerun replaces only the search surface");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Disposition
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Recovery_Failed) =
              Editor.Missing_Stale_Recovery.Recovery_State_Unchanged,
              "failed rerun preserves stale search state for explicit retry");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Disposition
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Recovery_Succeeded) =
              Editor.Missing_Stale_Recovery.Recovery_State_Unchanged,
              "File Tree refresh cannot clear Project Search stale state");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Disposition
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Clear_Results,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Recovery_Succeeded) =
              Editor.Missing_Stale_Recovery.Recovery_State_Cleared,
              "explicit clear-results command clears the owning search surface");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Attempt_May_Clear_State
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run,
                 Editor.Missing_Stale_Recovery.Project_Search_Surface,
                 Editor.Missing_Stale_Recovery.Recovery_Cancelled),
              "cancelled recovery attempts do not clear stale state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Attempt_Message_May_Embed_Path
                (Editor.Missing_Stale_Recovery.Recovery_Workspace_Load,
                 Editor.Missing_Stale_Recovery.Recovery_Failed),
              "recovery attempt messages never embed target paths");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Produces_One_Primary_Outcome
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates,
                 Editor.Missing_Stale_Recovery.Recovery_Succeeded),
              "successful recovery attempts still emit one primary outcome");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Preserves_Dirty_Text
                (Editor.Missing_Stale_Recovery.Recovery_File_Reload_From_Disk,
                 Editor.Missing_Stale_Recovery.Recovery_Failed),
              "failed reload recovery attempts preserve dirty text");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Attempt_Outcome_Label
                (Editor.Missing_Stale_Recovery.Recovery_Cancelled) =
              "Recovery cancelled; existing state preserved.",
              "cancelled recovery message is user-readable");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets,
              "milestone helper covers recovery attempt result disposition");
   end Test_Recovery_Attempt_Result_Disposition_And_Message_Boundaries;


   procedure Test_Multi_Target_Atomic_Preflight_And_Payload_Free_Summaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Bad_Replace : constant Editor.Missing_Stale_Recovery.Multi_Target_Validation_Summary :=
        (Valid_Targets        => 4,
         Missing_Targets      => 1,
         Stale_Targets        => 0,
         Outside_Project      => 1,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 0);
      Good_Workspace : constant Editor.Missing_Stale_Recovery.Multi_Target_Validation_Summary :=
        (Valid_Targets        => 2,
         Missing_Targets      => 0,
         Stale_Targets        => 0,
         Outside_Project      => 0,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 0);
   begin
      Assert (Editor.Missing_Stale_Recovery.Multi_Target_Command_Requires_Full_Preflight
                (Editor.Missing_Stale_Recovery.Multi_Project_Search_Replace_All),
              "replace-all validates every target before mutation");
      Assert (not Editor.Missing_Stale_Recovery.Multi_Target_Command_May_Mutate_Before_Preflight
                (Editor.Missing_Stale_Recovery.Multi_Project_Search_Replace_All),
              "replace-all cannot partially mutate before full target preflight");
      Assert (not Editor.Missing_Stale_Recovery.Multi_Target_Validation_Allows_Mutation
                (Bad_Replace),
              "any missing/outside/stale/out-of-range target blocks the batch mutation");
      Assert (Editor.Missing_Stale_Recovery.Multi_Target_Validation_Allows_Mutation
                (Good_Workspace),
              "all-valid multi-target recovery may proceed after preflight");
      Assert (Editor.Missing_Stale_Recovery.Multi_Target_Validation_Message (Bad_Replace) =
                "Some targets no longer exist; command not applied.",
              "batch failure summary is user-readable and count/category based");
      Assert (not Editor.Missing_Stale_Recovery.Multi_Target_Validation_Message_May_Embed_Paths
                (Bad_Replace),
              "batch validation messages do not embed stale target paths");
      Assert (Editor.Missing_Stale_Recovery.Multi_Target_Recovery_Preserves_Existing_State_On_Failure
                (Editor.Missing_Stale_Recovery.Multi_Project_Search_Replace_All,
                 Bad_Replace),
              "failed batch recovery preserves the existing surface state for explicit retry");
      Assert (Editor.Missing_Stale_Recovery.Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free,
              "milestone helper covers atomic multi-target preflight and payload-free summaries");
   end Test_Multi_Target_Atomic_Preflight_And_Payload_Free_Summaries;


   procedure Test_Target_Reference_Identity_And_Message_Payload_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous_Project : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Target_Reference_For_Execution
          (Editor.Missing_Stale_Recovery.Quick_Open_Surface,
           Editor.Missing_Stale_Recovery.Reference_Previous_Project,
           Editor.Missing_Stale_Recovery.Generation_Current);
      Stale_Search : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Target_Reference_For_Execution
          (Editor.Missing_Stale_Recovery.Project_Search_Surface,
           Editor.Missing_Stale_Recovery.Reference_Current_Project,
           Editor.Missing_Stale_Recovery.Generation_Stale);
      Stale_Replace : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Validate_Target_Reference_For_Execution
          (Editor.Missing_Stale_Recovery.Replace_Preview_Surface,
           Editor.Missing_Stale_Recovery.Reference_Current_Project,
           Editor.Missing_Stale_Recovery.Generation_Stale);
   begin
      Assert
        (Editor.Missing_Stale_Recovery.Target_Reference_Context_May_Be_Consumed
           (Editor.Missing_Stale_Recovery.Reference_Current_Project),
         "current-project references may be consumed after execution validation");
      Assert
        (not Editor.Missing_Stale_Recovery.Target_Reference_Context_May_Be_Consumed
           (Editor.Missing_Stale_Recovery.Reference_Previous_Project),
         "previous-project references cannot be consumed after project switch");
      Assert
        (not Editor.Missing_Stale_Recovery.Target_Reference_Context_May_Be_Consumed
           (Editor.Missing_Stale_Recovery.Reference_Project_Closed),
         "closed-project references cannot be consumed");
      Assert
        (Editor.Missing_Stale_Recovery.Target_Generation_State_Allows_Target_Use
           (Editor.Missing_Stale_Recovery.Generation_Current),
         "current generation may be used at execution boundary");
      Assert
        (not Editor.Missing_Stale_Recovery.Target_Generation_State_Allows_Target_Use
           (Editor.Missing_Stale_Recovery.Generation_Stale),
         "stale generation must be refreshed or rerun before use");
      Assert
        (Previous_Project.State = Editor.Missing_Stale_Recovery.Target_Outside_Project,
         "previous-project quick-open row is rejected as outside the current project");
      Assert
        (Stale_Search.State = Editor.Missing_Stale_Recovery.Target_Stale,
         "stale search generation validates as stale");
      Assert
        (Stale_Replace.State = Editor.Missing_Stale_Recovery.Target_Preview_Stale,
         "stale replace generation validates as preview stale");
      Assert
        (Editor.Missing_Stale_Recovery.Recovery_Message_Content_Allowed
           (Editor.Missing_Stale_Recovery.Recovery_Message_Surface_Category),
         "surface/category recovery messages are allowed");
      Assert
        (Editor.Missing_Stale_Recovery.Recovery_Message_Content_Allowed
           (Editor.Missing_Stale_Recovery.Recovery_Message_Counts_Only),
         "bounded count-only recovery summaries are allowed");
      Assert
        (not Editor.Missing_Stale_Recovery.Recovery_Message_Content_Allowed
           (Editor.Missing_Stale_Recovery.Recovery_Message_Target_Path),
         "recovery messages cannot embed stale target paths");
      Assert
        (not Editor.Missing_Stale_Recovery.Recovery_Message_Content_Allowed
           (Editor.Missing_Stale_Recovery.Recovery_Message_Target_Line),
         "recovery messages cannot embed stale target line payloads");
      Assert
        (not Editor.Missing_Stale_Recovery.Recovery_Message_Content_Allowed
           (Editor.Missing_Stale_Recovery.Recovery_Message_Internal_Enum),
         "recovery messages cannot expose internal enum names");
      Assert
        (Editor.Missing_Stale_Recovery.Target_Result_Message_Is_Payload_Free
           (Previous_Project),
         "previous-project rejection message is payload-free");
      Assert
        (Editor.Missing_Stale_Recovery.Target_Result_Message_Is_Payload_Free
           (Stale_Search),
         "stale search message is payload-free");
      Assert
        (Editor.Missing_Stale_Recovery.Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit,
         "milestone helper covers reference identity and message payload policies");
   end Test_Target_Reference_Identity_And_Message_Payload_Policies;

   procedure Test_Target_Use_Blocking_Matrix_And_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing_Search : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Missing,
         Surface => Editor.Missing_Stale_Recovery.Project_Search_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("src/deleted.adb"),
         Line    => 4,
         Column  => 1);
      Available_Build : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        (State   => Editor.Missing_Stale_Recovery.Target_Available,
         Surface => Editor.Missing_Stale_Recovery.Build_Surface,
         Path    => Ada.Strings.Unbounded.To_Unbounded_String ("demo.gpr"),
         Line    => 0,
         Column  => 0);
      Pending_Build : constant Editor.Missing_Stale_Recovery.Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.Command_Availability_When_Confirmation_Pending
          (Editor.Missing_Stale_Recovery.Build_Surface);
   begin
      Assert (Editor.Missing_Stale_Recovery.Target_State_Blocks_Use
                (Editor.Missing_Stale_Recovery.Target_Missing,
                 Editor.Missing_Stale_Recovery.Use_Open_Target),
              "missing targets block open before command use");
      Assert (Editor.Missing_Stale_Recovery.Target_State_Blocks_Use
                (Editor.Missing_Stale_Recovery.Target_Unwritable,
                 Editor.Missing_Stale_Recovery.Use_Save_Target),
              "unwritable targets block save distinctly");
      Assert (Editor.Missing_Stale_Recovery.Target_State_Blocks_Use
                (Editor.Missing_Stale_Recovery.Target_Line_Out_Of_Range,
                 Editor.Missing_Stale_Recovery.Use_Navigate_Target),
              "out-of-range targets block navigation");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_May_Proceed
                (Missing_Search, Editor.Missing_Stale_Recovery.Use_Navigate_Target),
              "missing search target cannot navigate");
      Assert (Editor.Missing_Stale_Recovery.Target_Use_May_Proceed
                (Available_Build, Editor.Missing_Stale_Recovery.Use_Run_Build_Target),
              "available build target may run only after execution validation");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_May_Proceed
                (Available_Build, Editor.Missing_Stale_Recovery.Use_Apply_Replace_Target),
              "available target on wrong surface cannot be applied as replace preview");
      Assert (Editor.Missing_Stale_Recovery.Target_Use_Blocking_Message
                (Pending_Build, Editor.Missing_Stale_Recovery.Use_Run_Build_Target) =
                "Build: Command unavailable while confirmation is pending.",
              "confirmation-pending build block is user-readable");
      Assert (Editor.Missing_Stale_Recovery.Target_Use_Failure_Requires_Recovery_Command
                (Editor.Missing_Stale_Recovery.Target_Preview_Stale,
                 Editor.Missing_Stale_Recovery.Use_Apply_Replace_Target),
              "stale replace failures require explicit recovery");
      Assert (not Editor.Missing_Stale_Recovery.Target_Use_Failure_Requires_Recovery_Command
                (Editor.Missing_Stale_Recovery.Target_Source_Less,
                 Editor.Missing_Stale_Recovery.Use_Navigate_Target),
              "source-less diagnostics do not fabricate a recovery path");
      Assert (Editor.Missing_Stale_Recovery.Assert_Target_Use_Blocking_Matrix_Is_Explicit,
              "milestone helper covers target use blocking matrix");
   end Test_Target_Use_Blocking_Matrix_And_Messages;




   procedure Test_Recovery_Command_Effect_Matrix_And_Non_Goal_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Effect_Probe_Filesystem,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "explicit Executor recovery command may probe only for its recovery action");
      Assert (Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Effect_Mutate_Owning_Surface,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "explicit Executor recovery command may update its owning surface");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Effect_Probe_Filesystem,
                 Editor.Missing_Stale_Recovery.Invocation_Render),
              "render cannot gain filesystem probing through recovery command effect policy");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh,
                 Editor.Missing_Stale_Recovery.Effect_Mutate_Owning_Surface,
                 Editor.Missing_Stale_Recovery.Invocation_Availability),
              "availability cannot mutate through recovery command effect policy");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_Build_Refresh_Candidates,
                 Editor.Missing_Stale_Recovery.Effect_Run_Build,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "build candidate refresh cannot run a build");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_Recent_Projects_Remove_Missing,
                 Editor.Missing_Stale_Recovery.Effect_Delete_User_File,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "recent-project cleanup cannot delete user files");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_Effect_Allowed
                (Editor.Missing_Stale_Recovery.Recovery_Workspace_Load,
                 Editor.Missing_Stale_Recovery.Effect_Create_Project_Context,
                 Editor.Missing_Stale_Recovery.Invocation_Executor),
              "workspace recovery cannot fabricate project context");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Write_Persistence
                (Editor.Missing_Stale_Recovery.Recovery_Project_Search_Run),
              "search rerun recovery does not persist recovery state");
      Assert (not Editor.Missing_Stale_Recovery.Recovery_Command_May_Clear_Other_Surface
                (Editor.Missing_Stale_Recovery.Recovery_File_Tree_Refresh),
              "File Tree refresh cannot clear unrelated stale surfaces");
      Assert (Editor.Missing_Stale_Recovery.Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe,
              "milestone helper covers explicit recovery command effect matrix");
   end Test_Recovery_Command_Effect_Matrix_And_Non_Goal_Gates;

   overriding procedure Register_Tests
     (T : in out Missing_Stale_Recovery_Test_Case)
   is
   begin
      Register_Routine
        (T, Test_User_Readable_Labels_Are_Stable'Access,
         "Phase 561 missing/stale labels are user-readable and distinct");
      Register_Routine
        (T, Test_Workspace_And_Recent_Recovery_Messages'Access,
         "Phase 561 reports workspace and recent-project missing references");
      Register_Routine
        (T, Test_File_Project_And_Project_Boundary_Validation'Access,
         "Phase 561 validates missing workspace/file targets and project boundary");
      Register_Routine
        (T, Test_File_Lifecycle_Missing_Backing_File_Recovery'Access,
         "Phase 561 preserves dirty buffers and validates save/reveal recovery");
      Register_Routine
        (T, Test_Surface_Specific_Stale_Target_Validation'Access,
         "Phase 561 validates stale File Tree/Quick Open/Search/replace targets");
      Register_Routine
        (T, Test_Outline_Diagnostics_And_Build_Validation'Access,
         "Phase 561 validates stale Outline/Diagnostics/Build targets");
      Register_Routine
        (T, Test_Render_Persistence_And_Command_Payload_Boundaries'Access,
         "Phase 561 preserves render, persistence and no-payload boundaries");
      Register_Routine
        (T, Test_Project_Transition_And_Explicit_Recovery_Boundaries'Access,
         "Phase 561 clears project-scoped stale surfaces and bounds recovery commands");
      Register_Routine
        (T, Test_Stale_Targets_Block_Actions_Until_Recovery'Access,
         "Phase 561 stale targets block navigation, replace apply and build run");
      Register_Routine
        (T, Test_Surface_Specific_Outcome_Messages'Access,
         "Phase 561 emits surface-specific stale/missing target messages");
      Register_Routine
        (T, Test_Render_Availability_And_Persistence_Exclusion_Depth'Access,
         "Phase 561 excludes automatic repair and transient recovery persistence");
      Register_Routine
        (T, Test_Workspace_Action_Caret_And_Selection_Policies'Access,
         "Phase 561 makes workspace fallback, caret and no-selection policies explicit");
      Register_Routine
        (T, Test_Dirty_Guards_And_Parent_Directory_Messages'Access,
         "Phase 561 preserves dirty guards and distinguishes missing parent directories");

      Register_Routine
        (T, Test_Access_Distinctions_And_Line_Only_Diagnostics'Access,
         "Phase 561 distinguishes unreadable/unwritable and line-only diagnostics");
      Register_Routine
        (T, Test_Search_Content_Replace_Summary_And_Stale_Boost_Gates'Access,
         "Phase 561 gates search content staleness, replace summary and Quick Open boosts");
      Register_Routine
        (T, Test_Build_Consent_File_Tree_Restore_And_No_Op_Outcomes'Access,
         "Phase 561 invalidates stale build consent and reports recovery no-ops");

      Register_Routine
        (T, Test_Selection_Marker_Fabrication_And_Reconsent_Gates'Access,
         "Phase 561 gates stale selections, snapshot markers, replace-all and build reconsent");
      Register_Routine
        (T, Test_Command_Route_Payload_Outcome_And_Snapshot_Label_Gates'Access,
         "Phase 561 enforces Executor routing, payload-free invocations and one outcome");

      Register_Routine
        (T, Test_File_Tree_Preflight_Workspace_Fallback_And_Replace_Report_Gates'Access,
         "File Tree preflight, workspace fallback and replace-report gates");

      Register_Routine
        (T, Test_Target_Use_Preflight_No_Auto_Refresh_And_Action_Hints'Access,
         "Target uses validate, do not auto-refresh, and expose explicit recovery hints");
      Register_Routine
        (T, Test_Recovery_Hints_Snapshot_And_Dirty_Preservation_Depth'Access,
         "Recovery hints map to explicit commands and transient snapshots stay non-persisted");
      Register_Routine
        (T, Test_Event_Driven_Surface_Staleness_And_Clear_Policies'Access,
         "Event-driven stale, clear and refresh effects are explicit and transient");
      Register_Routine
        (T, Test_Non_Executor_Triggers_And_No_Auto_Remap'Access,
         "Non-Executor recovery triggers are observational and missing paths are not remapped");
      Register_Routine
        (T, Test_Staleness_Provenance_Project_Scope_And_Previous_Project_Gates'Access,
         "Staleness provenance is explicit, transient and project-scoped");
      Register_Routine
        (T, Test_Workspace_Summary_And_Executor_Clear_Policy_Depth'Access,
         "Workspace recovery summary and stale-state clearing are Executor-scoped");
      Register_Routine
        (T, Test_Command_Execution_Revalidation_And_Cached_Result_Boundaries'Access,
         "Target validation is execution-boundary-only and cached results are not authoritative");
      Register_Routine
        (T, Test_Confirmation_Forbidden_Mechanism_And_Transient_Field_Policies'Access,
         "Confirmation pending, forbidden mechanisms and transient fields stay bounded");
      Register_Routine
        (T, Test_Failed_Validation_Disposition_And_Non_Mutation'Access,
         "Failed validation preserves state and cannot silently clear stale surfaces");

      Register_Routine
        (T, Test_Non_Destructive_Recovery_Action_And_Message_Policies'Access,
         "Recovery actions are non-destructive, payload-free and explicitly scoped");
      Register_Routine
        (T, Test_Recovery_Attempt_Result_Disposition_And_Message_Boundaries'Access,
         "Recovery attempts clear stale state only on successful owning-surface recovery");
      Register_Routine
        (T, Test_Multi_Target_Atomic_Preflight_And_Payload_Free_Summaries'Access,
         "Multi-target recovery commands preflight atomically and use payload-free summaries");
      Register_Routine
        (T, Test_Target_Reference_Identity_And_Message_Payload_Policies'Access,
         "Target references are current-project/current-generation and messages remain payload-free");
      Register_Routine
        (T, Test_Target_Use_Blocking_Matrix_And_Messages'Access,
         "Target use blocking matrix is explicit and user-readable");
      Register_Routine
        (T, Test_Recovery_Command_Effect_Matrix_And_Non_Goal_Gates'Access,
         "Recovery command effects are explicit and non-goal-safe");
      Register_Routine
        (T, Test_Recovery_Postconditions_Require_Revalidation'Access,
         "Successful recovery still requires target revalidation before target use");
      Register_Routine
        (T, Test_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit'Access,
         "Stale surface lifecycle is bounded, transient and explicit");
      Register_Routine
        (T, Test_Milestone_Coherence_Helper'Access,
         "Phase 561 milestone coherence helper is satisfied");
   end Register_Tests;

end Editor.Missing_Stale_Recovery.Tests;
