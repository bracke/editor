with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_Diagnostics;
with Editor.Build_Milestone_Freeze;
with Editor.Build_Public_Request;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Commands;
with Editor.External_Producers;
with Editor.Project;
with Editor.Feature_Diagnostics;
with Editor.State;

package body Editor.Build_Milestone_Freeze.Tests is

   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Build_UI.Public_Build_Tool_Selection;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Editor.External_Producers.Process_Run_Status;
   use type Editor.External_Producers.Process_Request_Validation_Status;
   use type Editor.External_Producers.Build_Request_Provenance;

   overriding function Name
     (T : Build_Milestone_Freeze_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Milestone_Freeze");
   end Name;

   function Manual_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "demo.gpr");
   begin
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Focus (S);
      Editor.Build_Candidates.Append_Unique_Candidate (Candidates, Candidate);
      Editor.Build_UI.Set_Build_Candidates (S, Candidates);
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Manual_UI;

   function Candidate_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
   begin
      Editor.Build_UI.Show (S);
      Editor.Build_UI.Focus (S);
      Editor.Build_Candidates.Append_Unique_Candidate (Candidates, Candidate);
      Editor.Build_UI.Set_Build_Candidates (S, Candidates);
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      return S;
   end Candidate_UI;

   procedure Test_Manual_Request_Workflow_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_UI.Public_Build_UI_State := Manual_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
   begin
      Assert (S.Build_UI_Visible and then S.Build_UI_Focused,
              "manual workflow starts from visible focused build UI");
      Assert (S.Candidate_Applied_To_Request,
              "Phase 554 configured workflow depends on an explicitly selected candidate");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild,
              "manual workflow freezes explicit tool selection");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) = 2,
              "configured workflow freezes structured argv tokens");
      Assert (S.Consent_Acknowledged,
              "manual workflow requires explicit request-specific consent");
      Assert (C.Status = Editor.Build_UI.Build_UI_Valid,
              "manual workflow converts only after validation");
      Assert (C.Request.Tool = Editor.External_Producers.GPRbuild_Tool,
              "manual workflow preserves bounded tool kind");
      Assert (To_String (C.Request.Arguments)'Length = 0,
              "manual workflow does not create opaque shell text");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Manual_Request_Frozen,
              "manual request freeze helper passes");
   end Test_Manual_Request_Workflow_Freeze;

   procedure Test_Candidate_Derived_Request_Workflow_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Candidate_UI;
      C : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      Assert (S.Candidate_Applied_To_Request,
              "candidate selection explicitly populates the transient request");
      Assert (not S.Consent_Acknowledged,
              "candidate selection does not imply consent");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "candidate-derived request requires renewed consent");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_Alire,
              "candidate-derived request uses candidate tool kind");
      Assert (not Editor.Build_UI.Command_Palette_Can_Supply_Candidate (S),
              "Command Palette cannot supply candidate id");
      Assert (not Editor.Build_UI.Keybinding_Can_Supply_Candidate (S),
              "keybinding cannot supply candidate id");
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Valid,
              "candidate-derived request converts after renewed consent");
      Assert (C.Request.Tool = Editor.External_Producers.Alire_Build_Tool,
              "candidate-derived request preserves alire tool kind");
      Assert (To_String (C.Request.Command_Label) = "alr",
              "candidate-derived request preserves executable token");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Candidate_Request_Frozen,
              "candidate-derived request freeze helper passes");
   end Test_Candidate_Derived_Request_Workflow_Freeze;

   procedure Test_Request_Identity_And_Consent_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Manual_UI;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
      Stable : constant String := Editor.Build_UI.Current_Request_Identity (S);
   begin
      Assert (To_String (S.Consent_Request_Identity) = Stable,
              "consent binds to the exact current request identity");
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      Assert (not S.Consent_Acknowledged,
              "tool change invalidates consent");
      S := Manual_UI;
      Editor.Build_UI.Append_Argument (Args, "--target");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Assert (not S.Consent_Acknowledged,
              "argv change invalidates consent");
      S := Manual_UI;
      Editor.Build_UI.Select_Working_Context
        (S, Editor.Build_Working_Context.Current_Workspace_Root
              ("active-workspace-root"));
      Assert (not S.Consent_Acknowledged,
              "working context change invalidates consent");
      S := Candidate_UI;
      Editor.Build_UI.Acknowledge_Consent (S);
      Editor.Build_UI.Clear_Selected_Build_Candidate (S);
      Assert (not S.Consent_Acknowledged,
              "clearing candidate invalidates consent");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Request_Identity_Frozen,
              "request identity freeze helper passes");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Consent_Frozen,
              "consent freeze helper passes");
   end Test_Request_Identity_And_Consent_Freeze;

   procedure Test_Build_Run_Route_And_Frontdoors_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Project_Result : constant Editor.Project.Project_Open_Result :=
        (Status => Editor.Project.Project_Open_Ok,
         Root_Path => To_Unbounded_String ("current-project-root"),
         Display_Name => To_Unbounded_String ("current-project-root"),
         Error_Text => Null_Unbounded_String);
   begin
      S.Build_UI := Manual_UI;
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Disabled;
      Editor.Project.Apply_Open_Result (S.Project, Project_Result);
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run stable command name is frozen");
      Assert (Editor.Build_Command.Build_Run_Readiness (S) =
                Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled,
              "Executor route revalidates execution policy before runner");
      Assert (Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (S),
              "Command Palette boundary remains descriptor/Executor-only");
      Assert (Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary,
              "keybinding boundary stores no request payload or consent");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Frontdoor_Boundaries_Frozen (S),
              "frontdoor boundary freeze helper passes");
   end Test_Build_Run_Route_And_Frontdoors_Freeze;

   procedure Test_Runner_Boundary_And_Result_Mapping_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (Manual_UI);
      Gate : Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Default_Execution_Gate;
      Supplied : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code => 2,
           Has_Exit_Code => True,
           Stdout_Text => "",
           Stderr_Text => "main.adb:1:1: error: failed");
      Preflight : Editor.External_Producers.Build_Preflight_Result;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Gate.Process_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Test_Fixture,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Gate.Allow_Build_Run := True;
      Gate.Consent := Editor.External_Producers.Build_Consent_Test_Only;
      Gate.Allow_Diagnostics_Ingestion := False;
      Gate.Show_Diagnostics := False;
      Preflight := Editor.External_Producers.Preflight_Build_Run_Request
        (C.Request, Gate.Process_Policy);
      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, C.Request, Gate, Supplied);
      Assert (Preflight.Process_Request_Status =
                Editor.External_Producers.Process_Request_Valid,
              "runner receives a valid structured process request");
      Assert (To_String (Preflight.Process_Request.Program_Label) = "gprbuild",
              "runner receives executable token only");
      Assert (To_String (Preflight.Process_Request.Arguments)'Length = 0,
              "runner receives no shell command string");
      Assert (not Gate.Process_Policy.Allow_Shell,
              "runner policy forbids shell execution");
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "process failure maps deterministically to build failure");
      Assert (Result.Build_Result.Exit_Code = 2,
              "runner exit code is preserved in bounded result");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Runner_Boundary_Frozen,
              "runner boundary freeze helper passes");
   end Test_Runner_Boundary_And_Result_Mapping_Freeze;

   procedure Test_Diagnostics_Ownership_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (Manual_UI);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Build_Result : Editor.External_Producers.Build_Run_Result;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Lines.Append (To_Unbounded_String ("main.adb:1:1: warning: owned"));
      Build_Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Diagnostic_Lines => Lines);
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, C.Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Assert (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
              "diagnostics ingestion uses the Diagnostics API result");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "Diagnostics owns resulting row storage");
      Assert (Editor.Build_Milestone_Freeze.Assert_Public_Build_Diagnostics_Boundary_Frozen,
              "diagnostics boundary freeze helper passes");
   end Test_Diagnostics_Ownership_Freeze;

   procedure Test_Milestone_Coherence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Build_Milestone_Freeze.Public_Build_Command_Milestone_Freeze;
   begin
      S.Build_UI := Manual_UI;
      R := Editor.Build_Milestone_Freeze.Run_Public_Build_Command_Milestone_Freeze_Audit
        (S);
      Assert (R.Manual_Request_Frozen, "manual request path is frozen");
      Assert (R.Candidate_Request_Frozen, "candidate request path is frozen");
      Assert (R.Request_Identity_And_Consent_Frozen,
              "request identity and consent behavior is frozen");
      Assert (R.Runner_Boundary_Frozen, "runner boundary is frozen");
      Assert (R.Diagnostics_Boundary_Frozen,
              "Diagnostics-owned ingestion boundary is frozen");
      Assert (R.Persistence_Exclusion_Frozen,
              "public build transient state remains excluded from persistence");
      Assert (R.Coherent, "Phase 508 public build milestone is coherent");
   end Test_Milestone_Coherence_Freeze;

   overriding procedure Register_Tests
     (T : in out Build_Milestone_Freeze_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Manual_Request_Workflow_Freeze'Access,
         "Phase 508 manual request workflow freeze");
      Register_Routine
        (T, Test_Candidate_Derived_Request_Workflow_Freeze'Access,
         "Phase 508 candidate-derived request workflow freeze");
      Register_Routine
        (T, Test_Request_Identity_And_Consent_Freeze'Access,
         "Phase 508 request identity and consent freeze");
      Register_Routine
        (T, Test_Build_Run_Route_And_Frontdoors_Freeze'Access,
         "Phase 508 build.run route and frontdoor boundaries freeze");
      Register_Routine
        (T, Test_Runner_Boundary_And_Result_Mapping_Freeze'Access,
         "Phase 508 runner boundary and result mapping freeze");
      Register_Routine
        (T, Test_Diagnostics_Ownership_Freeze'Access,
         "Phase 508 Diagnostics ownership freeze");
      Register_Routine
        (T, Test_Milestone_Coherence_Freeze'Access,
         "Phase 508 public build milestone coherence freeze");
   end Register_Tests;

end Editor.Build_Milestone_Freeze.Tests;
