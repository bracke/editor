with Ada.Directories;
with Ada.Text_IO;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_Diagnostics;
with Editor.Build_Execution_Workflow;
with Editor.Build_Output_Details;
with Editor.Build_Public_Request;
with Editor.Build_Result_Summary;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.External_Producers;
with Editor.Messages;
with Editor.Project;
with Editor.State;

package body Editor.Build_Execution_Workflow.Tests is

   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.External_Producers.Build_Run_Status;
use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.External_Producers.Process_Run_Status;
   use type Editor.External_Producers.Build_Execution_Consent;
   use type Editor.External_Producers.Native_Process_Control_Backend;
   use type Editor.Build_Result_Summary.Build_Result_Summary_Kind;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;

   overriding function Name
     (T : Build_Execution_Workflow_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Execution_Workflow");
   end Name;

   function Fixture_Root return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/phase555_execution_fixture";
   end Fixture_Root;

   procedure Write_File (Path : String; Text : String := "") is
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
      Write_File (Root & "/demo.gpr", "project Demo is end Demo;");
   end Reset_Fixture;

   function Request return Editor.External_Producers.Build_Run_Request
   is
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "-P");
      Editor.External_Producers.Append_Process_Argument (Args, "demo.gpr");
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("current-project-root"),
         Command_Label => To_Unbounded_String ("gprbuild demo.gpr"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
   end Request;

   function Ready_State return Editor.State.State_Type
   is
      Root : constant String := Fixture_Root;
      S : Editor.State.State_Type;
      Project_Result : Editor.Project.Project_Open_Result;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Reset_Fixture;
      Project_Result :=
        (Status => Editor.Project.Project_Open_Ok,
         Root_Path => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase555_execution_fixture"),
         Error_Text => Null_Unbounded_String);
      Candidate := Editor.Build_Candidates.Gprbuild_Candidate
        (Root, "demo.gpr");
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Editor.Project.Apply_Open_Result (S.Project, Project_Result);
      Editor.Build_UI.Show (S.Build_UI);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S.Build_UI, True);
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      return S;
   end Ready_State;

   function Latest_Message_Text (S : Editor.State.State_Type) return String
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Latest_Message_Text;

   procedure Test_Preflight_Rejects_Unconsented_Or_Invalid_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
   begin
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Ready,
              "valid configured request is ready before consent is cleared");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Requires_Valid_Consented_Request
                (S),
              "Phase 555 pre-run validation requires matching current consent");
      Editor.Build_UI.Clear_Consent (S.Build_UI);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Consent_Required,
              "clearing consent makes build.run unavailable before runner invocation");
      declare
         Result : constant Editor.External_Producers.Build_Command_Result :=
           Editor.Build_Command.Execute_Public_Build_Run (S);
      begin
         Assert (Result.Build_Result.Status =
                   Editor.External_Producers.Build_Run_Not_Available,
                 "unconsented request does not invoke the runner");
      end;

      S := Ready_State;
      S.Build_UI.Consent_Request_Identity := To_Unbounded_String ("stale-request-identity");
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Consent_Stale,
              "stale consent identity is rejected immediately before execution");
   end Test_Preflight_Rejects_Unconsented_Or_Invalid_Request;

   procedure Test_Structured_Gated_Run_Produces_Latest_Result_And_Output
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Process_Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True,
           Stdout_Text => "build ok",
           Stderr_Text => "");
      Command_Result : Editor.External_Producers.Build_Command_Result;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
   begin
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Uses_Structured_Tokens
                (Request),
              "Phase 555 runner request uses argv tokens rather than raw shell text");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Does_Not_Use_Shell_Text
                (Request),
              "Phase 555 request has no shell pipeline/redirection language");

      Command_Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Request, Gate, Process_Result);
      Assert (Command_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Succeeded,
              "gated structured request maps successful runner exit to build success");
      Assert (Command_Result.Build_Result.Has_Exit_Code
              and then Command_Result.Build_Result.Exit_Code = 0,
              "exit code remains represented as runner result metadata");
      Assert (To_String (Command_Result.Build_Result.Stdout_Text) = "build ok",
              "bounded stdout is captured from runner result");

      Summary := Editor.Build_Result_Summary.Build_Summary
        (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
         Working_Context_Label => "current-project-root",
         Runner_Status_Label => "succeeded",
         Primary_Message => To_String (Command_Result.Command_Message),
         Exit_Code => Command_Result.Build_Result.Exit_Code,
         Has_Exit_Code => Command_Result.Build_Result.Has_Exit_Code);
      Details := Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
        (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
         Stdout_Text => Command_Result.Build_Result.Stdout_Text,
         Stderr_Text => Command_Result.Build_Result.Stderr_Text,
         Stdout_Truncated => Command_Result.Build_Result.Stdout_Truncated,
         Stderr_Truncated => Command_Result.Build_Result.Stderr_Truncated,
         Output_Partial => Command_Result.Build_Result.Output_Partial,
         Exit_Code => Command_Result.Build_Result.Exit_Code,
         Has_Exit_Code => Command_Result.Build_Result.Has_Exit_Code);

      Assert (Editor.Build_Execution_Workflow.Assert_Build_Result_Summary_Reflects_Runner_Status
                (Summary),
              "latest result summary is a compact projection of runner status");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Output_Is_Bounded
                (Details),
              "output details expose bounded captured output only");
   end Test_Structured_Gated_Run_Produces_Latest_Result_And_Output;

   procedure Test_Diagnostics_Ingestion_Is_Request_Controlled_And_Owned
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Gate_Disabled : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Gate_Enabled : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => True,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Process_Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code => 1,
           Has_Exit_Code => True,
           Stderr_Text => "demo.adb:1:1:error: broken");
      Disabled_Result : Editor.External_Producers.Build_Command_Result;
      Enabled_Result : Editor.External_Producers.Build_Command_Result;
   begin
      Disabled_Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Request, Gate_Disabled, Process_Result);
      Assert (Disabled_Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
              "disabled diagnostics ingestion produces no Diagnostics-owned rows");

      Enabled_Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Request, Gate_Enabled, Process_Result);
      Assert (Enabled_Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count > 0,
              "enabled diagnostics ingestion sends parsed output through Diagnostics ingestion seam");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Diagnostics_Owned_By_Diagnostics
                (S),
              "Build surfaces keep only scalar diagnostics facts and do not own rows");
      Assert (Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted,
              "diagnostics integration does not add build-local persistence");
   end Test_Diagnostics_Ingestion_Is_Request_Controlled_And_Owned;

   procedure Test_Render_Command_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S.Build_UI);
   begin
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Render_Does_Not_Run_Or_Parse
                (S),
              "rendering the Build snapshot does not execute, cancel, or parse output");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Result_Output_Not_Persisted
                (S),
              "request/result/output/consent remain excluded from persistence domains");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Keybindings_Have_No_Run_Payloads,
              "keybindings carry only the canonical build.run command name");
      Assert (Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (S),
              "Command Palette has no request/result payload channel for build.run");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Uses_Structured_Tokens
                (Conversion.Request),
              "UI conversion retains structured argv tokens for the execution boundary");
   end Test_Render_Command_And_Persistence_Boundaries;

   procedure Test_Unavailable_Preflight_Updates_Transient_Result_And_Output
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (S.Build_UI);
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);

      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "pre-run unavailable result is represented as a build command outcome");
      Assert (S.Latest_Build_Result.Has_Result
              and then S.Latest_Build_Result.Kind =
                Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              "pre-run failure updates only the transient latest result summary");
      Assert (To_String (S.Latest_Build_Result.Primary_Message) =
                "No build candidate selected.",
              "latest summary preserves the exact pre-run primary outcome");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details
              and then S.Latest_Build_Output_Details.Kind =
                Editor.Build_Output_Details.Build_Output_Details_Unavailable,
              "pre-run failure updates only transient output details, not runner output");
      Assert (not S.Latest_Build_Output_Details.Stdout_Available
              and then not S.Latest_Build_Output_Details.Stderr_Available,
              "pre-run failure does not invent captured stdout or stderr");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Result_Output_Not_Persisted
                (S),
              "pre-run result/output surfaces remain excluded from persistence");
   end Test_Unavailable_Preflight_Updates_Transient_Result_And_Output;

   procedure Test_Build_UI_Projects_Result_Output_And_Diagnostics_As_Display_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      S.Latest_Build_Result := Editor.Build_Result_Summary.Build_Summary
        (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Candidate_Derived,
         Working_Context_Label => "current-project-root",
         Runner_Status_Label => "failed",
         Primary_Message => "Build failed: exit code 1.",
         Exit_Code => 1,
         Has_Exit_Code => True,
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
         Diagnostics_Count => 2,
         Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => To_Unbounded_String ("compile stdout"),
           Stderr_Text => To_Unbounded_String ("demo.adb:1:1:error: broken"),
           Stdout_Truncated => False,
           Stderr_Truncated => False,
           Output_Partial => False,
           Exit_Code => 1,
           Has_Exit_Code => True);

      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details);

      Assert (Editor.Build_UI.Assert_Public_Build_Result_Output_UI_Coherent
                (S.Build_UI, S.Latest_Build_Result,
                 S.Latest_Build_Output_Details),
              "Build UI renders result output and diagnostics as display-only projections");
      Assert (Snapshot.Output_Details.Output_Details_Available
              and then Snapshot.Diagnostics_View.Reveal_Available,
              "Build UI exposes output availability and scalar diagnostics reveal state");
      Assert (To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                "diagnostics.show",
              "Build UI diagnostics reveal remains a command name, not owned rows");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Render_Does_Not_Run_Or_Parse
                (S),
              "rendering populated execution surfaces still does not run or parse builds");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Diagnostics_Owned_By_Diagnostics
                (S),
              "Build UI keeps diagnostics status/count scalar and Diagnostics-owned");
   end Test_Build_UI_Projects_Result_Output_And_Diagnostics_As_Display_Only;


   procedure Test_Preflight_Rejects_No_Project_Before_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.Project.Clear (S.Project);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_No_Project_Open,
              "build.run is unavailable when no project is open");
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "no-project preflight does not invoke the runner");
      Assert (To_String (Result.Command_Message) = "No project open.",
              "no-project preflight emits a clear primary outcome");
   end Test_Preflight_Rejects_No_Project_Before_Runner;


   procedure Test_Preflight_Rejects_No_Candidate_And_Stale_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      No_Candidate_State : Editor.State.State_Type := Ready_State;
      Stale_State : Editor.State.State_Type := Ready_State;
      No_Candidate_Result : Editor.External_Producers.Build_Command_Result;
      Stale_Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate
        (No_Candidate_State.Build_UI);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation
                (No_Candidate_State) =
              Editor.Build_Command.Build_Run_Readiness_No_Candidate_Selected,
              "pre-run validation distinguishes missing candidate from generic invalid request");
      No_Candidate_Result := Editor.Build_Command.Execute_Public_Build_Run
        (No_Candidate_State);
      Assert (No_Candidate_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "missing candidate does not invoke the runner");
      Assert (To_String (No_Candidate_Result.Command_Message) =
                "No build candidate selected.",
              "missing candidate uses the clear Phase 555 failure message");

      Stale_State.Build_UI.Selected_Candidate_Stale := True;
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation
                (Stale_State) =
              Editor.Build_Command.Build_Run_Readiness_Selected_Candidate_Stale,
              "pre-run validation distinguishes stale selected candidate");
      Stale_Result := Editor.Build_Command.Execute_Public_Build_Run
        (Stale_State);
      Assert (Stale_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "stale selected candidate does not invoke the runner");
      Assert (To_String (Stale_Result.Command_Message) =
                "Selected build candidate is stale.",
              "stale candidate uses the clear Phase 555 failure message");
   end Test_Preflight_Rejects_No_Candidate_And_Stale_Candidate;

   procedure Test_Preflight_Rejects_Missing_Candidate_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Ada.Directories.Delete_File (Fixture_Root & "/demo.gpr");
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Candidate_File_Missing,
              "pre-run validation rechecks selected candidate source availability");
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "missing candidate source rejects before runner invocation");
      Assert (To_String (Result.Command_Message) =
                "Build candidate file no longer exists.",
              "missing candidate source uses a clear Phase 555 failure message");
   end Test_Preflight_Rejects_Missing_Candidate_File;


   procedure Test_Preflight_Rejects_Working_Context_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing_Context_State : Editor.State.State_Type := Ready_State;
      Unavailable_Context_State : Editor.State.State_Type := Ready_State;
      Missing_Result : Editor.External_Producers.Build_Command_Result;
      Unavailable_Result : Editor.External_Producers.Build_Command_Result;
   begin
      Missing_Context_State.Build_UI.Selected_Working_Context :=
        Editor.Build_Working_Context.None;
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation
                (Missing_Context_State) =
              Editor.Build_Command.Build_Run_Readiness_Working_Context_Required,
              "pre-run validation rejects missing working context before runner invocation");
      Missing_Result := Editor.Build_Command.Execute_Public_Build_Run
        (Missing_Context_State);
      Assert (Missing_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "missing working context does not invoke the runner");
      Assert (To_String (Missing_Result.Command_Message) =
                "Build working directory is required.",
              "missing working context has a direct user-facing outcome");

      Unavailable_Context_State.Build_UI.Selected_Working_Context :=
        Editor.Build_Working_Context.Unavailable ("working directory removed");
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation
                (Unavailable_Context_State) =
              Editor.Build_Command.Build_Run_Readiness_Working_Context_Unavailable,
              "pre-run validation rejects unavailable working context before runner invocation");
      Unavailable_Result := Editor.Build_Command.Execute_Public_Build_Run
        (Unavailable_Context_State);
      Assert (Unavailable_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "unavailable working context does not invoke the runner");
      Assert (To_String (Unavailable_Result.Command_Message) =
                "Build working directory is unavailable.",
              "unavailable working context has a direct user-facing outcome");
   end Test_Preflight_Rejects_Working_Context_Failures;

   procedure Test_Execution_Gate_Carries_Output_And_Diagnostics_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Gate : Editor.External_Producers.Build_Execution_Gate;
   begin
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Gate.Allow_Build_Run
              and then Gate.Allow_Real_Build_Tool_Execution
              and then Gate.Consent = Editor.External_Producers.Build_Consent_User_Confirmed,
              "ready consented build.run opens only the gated structured execution path");
      Assert (Gate.Allow_Diagnostics_Ingestion
              and then Gate.Show_Diagnostics,
              "diagnostics ingestion/show flags are carried from explicit request configuration");
      Assert (Gate.Process_Policy.Max_Output_Bytes =
                Editor.Build_UI.Output_Capture_Limit_Bytes
                  (S.Build_UI.Output_Capture_Limit),
              "execution gate receives the configured bounded output capture limit");

      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S.Build_UI, False);
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (not Gate.Allow_Diagnostics_Ingestion
              and then not Gate.Show_Diagnostics,
              "disabled diagnostics request disables ingestion before runner/result integration");
   end Test_Execution_Gate_Carries_Output_And_Diagnostics_Policies;

   procedure Test_Output_Details_No_Output_State_Is_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Stdout_Text => Null_Unbounded_String,
           Stderr_Text => Null_Unbounded_String);
      Snapshot : constant Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot :=
        Editor.Build_Output_Details.Render_Snapshot (Details);
   begin
      Assert (Details.Has_Output_Details,
              "latest output details still represent a completed build with no output");
      Assert (not Details.Stdout_Available and then not Details.Stderr_Available,
              "no-output builds do not invent stdout or stderr text");
      Assert (Editor.Build_Output_Details.Status_Label (Details) =
                "No build output captured.",
              "no-output status is explicit");
      Assert (To_String (Snapshot.No_Output_Label) =
                "No build output captured.",
              "render snapshot exposes a clear no-output label");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Output_Is_Bounded
                (Details),
              "no-output state remains bounded and transient");
   end Test_Output_Details_No_Output_State_Is_Clear;

   procedure Test_Runner_Failure_Statuses_Are_Represented
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Failed : constant Editor.External_Producers.Build_Command_Result :=
        Editor.External_Producers.Run_Build_Command_With_Gate
          (S, Request, Gate,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Failed,
              Exit_Code => 1,
              Has_Exit_Code => True,
              Stderr_Text => "build failed"));
      Timeout : constant Editor.External_Producers.Build_Command_Result :=
        Editor.External_Producers.Run_Build_Command_With_Gate
          (S, Request, Gate,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Timed_Out,
              Stdout_Text => "partial stdout"));
      Cancelled : constant Editor.External_Producers.Build_Command_Result :=
        Editor.External_Producers.Run_Build_Command_With_Gate
          (S, Request, Gate,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Cancelled,
              Stderr_Text => "cancelled stderr"));
      Spawn_Failure : constant Editor.External_Producers.Build_Command_Result :=
        Editor.External_Producers.Run_Build_Command_With_Gate
          (S, Request, Gate,
           Editor.External_Producers.Build_Process_Run_Result
             (Editor.External_Producers.Process_Run_Execution_Error));
   begin
      Assert (Failed.Build_Result.Status = Editor.External_Producers.Build_Run_Failed
              and then Failed.Build_Result.Has_Exit_Code
              and then Failed.Build_Result.Exit_Code = 1,
              "nonzero runner exit is represented as failed-exit with exit code");
      Assert (Timeout.Build_Result.Status = Editor.External_Producers.Build_Run_Timed_Out
              and then Timeout.Build_Result.Output_Partial,
              "timeout is represented clearly and preserves partial-output policy");
      Assert (Cancelled.Build_Result.Status = Editor.External_Producers.Build_Run_Cancelled
              and then Cancelled.Build_Result.Output_Partial,
              "cancelled runner status is represented without clearing request state");
      Assert (Spawn_Failure.Build_Result.Status =
                Editor.External_Producers.Build_Run_Execution_Error,
              "spawn/output execution failure is represented separately from compiler failure");
   end Test_Runner_Failure_Statuses_Are_Represented;

   procedure Test_Output_Truncation_And_Latest_Result_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      First_Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded.");
      Next_Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "output truncated",
           Primary_Message => "Build output truncated.",
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Output_Partial => True);
      Replaced_Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (First_Summary, Next_Summary);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Output_Truncated,
           Stdout_Text => To_Unbounded_String ("stdout excerpt"),
           Stderr_Text => To_Unbounded_String ("stderr excerpt"),
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Output_Partial => True);
   begin
      Assert (Replaced_Summary.Kind =
                Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated,
              "latest result is replaced by the newest attempt rather than appended as history");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Replace_Only
                (First_Summary, Replaced_Summary),
              "latest result summary remains replace-only and not build history");
      Assert (Details.Stdout_Truncated and then Details.Stderr_Truncated
              and then Details.Output_Partial,
              "stdout/stderr truncation markers are represented in output details");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Output_Is_Bounded (Details),
              "truncated output details remain bounded and display-only");
   end Test_Output_Truncation_And_Latest_Result_Replacement;

   procedure Test_Shell_Payloads_Are_Rejected_By_Coherence_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
      Shell_Request : Editor.External_Producers.Build_Run_Request;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "demo.gpr; rm -rf tmp");
      Shell_Request :=
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("current-project-root"),
         Command_Label => To_Unbounded_String ("gprbuild demo.gpr; rm -rf tmp"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
      Assert (not Editor.Build_Execution_Workflow.Assert_Build_Run_Does_Not_Use_Shell_Text
                (Shell_Request),
              "shell metacharacters are not accepted as a structured build request");
   end Test_Shell_Payloads_Are_Rejected_By_Coherence_Guards;


   procedure Test_Executor_Route_Rejects_Build_Run_Before_Runner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Before_Count : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (S.Build_UI);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);

      Assert (Result.Status = Editor.Command_Execution.Command_Unavailable
              and then Result.Command = Editor.Commands.Command_Build_Run,
              "Executor route returns unavailable for pre-run build.run rejection");
      Assert (Editor.Messages.Count (S.Messages) = Before_Count + 1,
              "Executor route emits exactly one primary command outcome message");
      Assert (Latest_Message_Text (S) = "No build candidate selected.",
              "Executor route surfaces the pre-run validation reason, not runner text");
      Assert (S.Latest_Build_Result.Has_Result
              and then S.Latest_Build_Output_Details.Has_Output_Details,
              "Executor route updates only transient result/output surfaces for rejection");
      Assert (not S.Latest_Build_Output_Details.Stdout_Available
              and then not S.Latest_Build_Output_Details.Stderr_Available,
              "Executor pre-run rejection has no captured runner output");
   end Test_Executor_Route_Rejects_Build_Run_Before_Runner;

   procedure Test_Gated_Runner_Rejects_Shell_Shaped_Tokens_Without_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
      Shell_Request : Editor.External_Producers.Build_Run_Request;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Real_Execution_Gate
          (Allow_Diagnostics_Ingestion => True,
           Consent => Editor.External_Producers.Build_Consent_User_Confirmed);
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "demo.gpr; rm -rf tmp");
      Shell_Request :=
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("current-project-root"),
         Command_Label => To_Unbounded_String ("gprbuild demo.gpr; rm -rf tmp"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);

      Result := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Shell_Request, Gate);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Rejected,
              "gated runner rejects shell-shaped structured tokens before execution");
      Assert (Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0,
              "rejected shell-shaped requests do not create Diagnostics-owned rows");
      Assert (To_String (Result.Build_Result.Stdout_Text) = ""
              and then To_String (Result.Build_Result.Stderr_Text) = "",
              "rejected shell-shaped requests do not synthesize captured output");
   end Test_Gated_Runner_Rejects_Shell_Shaped_Tokens_Without_Diagnostics;

   procedure Test_Result_And_Output_Surfaces_Carry_No_Rerun_Or_Process_Control
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "timed out",
           Primary_Message => "Build timed out.",
           Timed_Out => True,
           Output_Partial => True);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Timed_Out,
           Stdout_Text => To_Unbounded_String ("partial stdout"),
           Stderr_Text => Null_Unbounded_String,
           Output_Partial => True);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Rerun_State
                (Summary),
              "latest result summary carries no rerun request payload");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Output_Log
                (Summary),
              "latest result summary carries no unbounded output log");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Rerun_State
                (Details),
              "output details carry no rerun request payload");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Process_Control
                (Details),
              "output details carry no process handle or cancellation token");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Output_Log
                (Details),
              "output details stay bounded excerpts, not a terminal log");
   end Test_Result_And_Output_Surfaces_Carry_No_Rerun_Or_Process_Control;


   procedure Test_Request_Mutation_Invalidates_Consent_And_Blocks_Run
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Before : Editor.State.State_Type;
      Old_Identity : constant String := Editor.Build_UI.Current_Request_Identity (S.Build_UI);
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Ready,
              "initial consented request is ready");
      Editor.Build_UI.Toggle_Verbose_Output (S.Build_UI);
      Assert (Editor.Build_UI.Current_Request_Identity (S.Build_UI) /= Old_Identity,
              "changing a structured request option changes the consent identity");
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Consent_Required,
              "request mutation clears consent and blocks build.run before execution");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "execution gate does not carry user-confirmed consent after request mutation");

      Before := S;
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Preflight_Failure_Is_Non_Destructive
                (Before, S, Result),
              "mutated unconsented request fails preflight without runner output or buffer mutation");
   end Test_Request_Mutation_Invalidates_Consent_And_Blocks_Run;

   procedure Test_Execution_Gate_Consent_Follows_Preflight_Readiness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Gate : Editor.External_Producers.Build_Execution_Gate;
   begin
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Ready,
              "ready state validates before gate consent check");
      Assert (Gate.Consent = Editor.External_Producers.Build_Consent_User_Confirmed,
              "ready state carries request-specific confirmed consent into the execution gate");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper accepts consented ready request");

      Editor.Build_UI.Clear_Consent (S.Build_UI);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Consent_Required,
              "missing consent is caught by preflight");
      Assert (Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed,
              "missing consent is not promoted by the execution gate");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper rejects confirmed gate consent for unavailable request");

      S := Ready_State;
      S.Build_UI.Consent_Request_Identity := To_Unbounded_String ("manually-stale-consent");
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Consent_Stale,
              "stale consent identity is caught by preflight even if the acknowledge flag remains set");
      Assert (Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed,
              "stale consent identity is not promoted into a confirmed execution gate");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper rejects confirmed gate consent for stale consent identity");

      S := Ready_State;
      Editor.Project.Clear (S.Project);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_No_Project_Open,
              "no-project state is caught before execution even with a consented request surface");
      Assert (Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed,
              "execution gate does not promote consent when project preflight fails");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper rejects confirmed gate consent for no-project preflight failure");

      S := Ready_State;
      S.Build_UI.Selected_Candidate_Stale := True;
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Selected_Candidate_Stale,
              "stale selected candidate is caught before execution even with matching consent");
      Assert (Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed,
              "execution gate does not promote consent when selected candidate preflight fails");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper rejects confirmed gate consent for stale candidate preflight failure");

      S := Ready_State;
      Ada.Directories.Delete_File (Fixture_Root & "/demo.gpr");
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
                Editor.Build_Command.Build_Run_Readiness_Candidate_File_Missing,
              "missing selected candidate source is caught before execution even with matching consent");
      Assert (Gate.Consent /= Editor.External_Producers.Build_Consent_User_Confirmed,
              "execution gate does not promote consent when candidate file preflight fails");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Gate_Consent_Matches_Preflight
                (S),
              "coherence helper rejects confirmed gate consent for missing candidate file preflight failure");
   end Test_Execution_Gate_Consent_Follows_Preflight_Readiness;


   procedure Test_Preflight_Failure_Preserves_Request_Configuration_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Before : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      S.Build_UI.Selected_Candidate_Stale := True;
      Before := S;
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);

      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "stale-candidate preflight remains a non-runner unavailable result");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Preflight_Preserves_Request_Surface
                (Before, S),
              "preflight failure does not refresh candidates clear selection auto-consent or rewrite request options");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Preflight_Failure_Is_Non_Destructive
                (Before, S, Result),
              "preflight failure remains non-destructive while exposing only transient result/output state");
   end Test_Preflight_Failure_Preserves_Request_Configuration_Surface;

   procedure Test_Build_Cancel_Command_Uses_Active_Job_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.State.Initialize (S);
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.cancel", Found);
      Assert (Found and then Id = Editor.Commands.Command_Build_Cancel,
              "build.cancel is advertised once the active build-job model exists");
      Assert (not Editor.Commands.Is_Available
                (Editor.Build_Command.Build_Cancel_Availability (S)),
              "build.cancel is unavailable without an active build job");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Cancel_Advertised_With_Active_Job_Model (S),
              "workflow coherence accepts build.cancel only with active job state");
      Editor.Build_Command.Begin_Public_Build_Job (S, "test build");
      Editor.Build_Command.Register_Public_Build_Test_Process (S);
      Assert (Editor.Commands.Is_Available
                (Editor.Build_Command.Build_Cancel_Availability (S)),
              "build.cancel becomes available while a cancellable public build job is active");
      Result := Editor.Build_Command.Request_Public_Build_Cancel (S);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Cancelled,
              "build.cancel requests cancellation through the active process handle");
      Assert (S.Public_Build_Job_Cancellation =
                Editor.Build_Runner_Policy.Cancellation_Requested,
              "active public build job records requested cancellation after signalling the handle");

      Editor.Build_Command.Complete_Public_Build_Job (S);
      Editor.Build_Command.Begin_Public_Build_Job (S, "non-cancellable build");
      Result := Editor.Build_Command.Request_Public_Build_Cancel (S);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Cancellation_Unsupported,
              "build.cancel still reports unsupported cancellation when no process handle is registered");
   end Test_Build_Cancel_Command_Uses_Active_Job_Model;


   procedure Test_Active_Build_Job_Streams_Output_Before_Final_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);
      Editor.Build_Command.Begin_Public_Build_Job (S, "streaming build");
      Editor.Build_Command.Append_Public_Build_Output_Chunk
        (S, Editor.Build_Output_Details.Build_Output_Stream_Stdout, "compile A\n");
      Editor.Build_Command.Append_Public_Build_Output_Chunk
        (S, Editor.Build_Output_Details.Build_Output_Stream_Stderr,
         "src/main.adb:1:1: error: failed\n");

      Assert (S.Public_Build_Output_Stream.Active
              and then S.Public_Build_Output_Stream.Chunk_Count = 2,
              "active public build job owns an incremental bounded output stream");
      Assert (S.Latest_Build_Output_Details.Output_Partial
              and then S.Latest_Build_Output_Details.Stdout_Available
              and then S.Latest_Build_Output_Details.Stderr_Available,
              "stream chunks update latest output details before the final result");

      Editor.Build_Command.Complete_Public_Build_Output_Stream
        (S, Editor.Build_Output_Details.Build_Output_Runner_Failed,
         Exit_Code => 1, Has_Exit_Code => True);
      Editor.Build_Command.Complete_Public_Build_Job (S);
      Assert (not S.Public_Build_Output_Stream.Active
              and then not S.Latest_Build_Output_Details.Output_Partial,
              "final streamed build output is closed and no longer marked active partial output");
   end Test_Active_Build_Job_Streams_Output_Before_Final_Result;

   procedure Test_Output_Capture_Over_Limit_Is_Clear_Failure_Not_Unbounded_Log
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Policy : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Test_Fixture,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 4,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Raw_Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True,
           Stdout_Text => "12345",
           Stderr_Text => "");
      Bounded : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Enforce_Process_Output_Bounds
          (Raw_Result, Policy);
      Build_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Result_From_Process_Result
          (Request, Bounded);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Execution_Error,
           Stdout_Text => Build_Result.Stdout_Text,
           Stderr_Text => Build_Result.Stderr_Text,
           Stdout_Truncated => Build_Result.Stdout_Truncated,
           Stderr_Truncated => Build_Result.Stderr_Truncated,
           Output_Partial => Build_Result.Output_Partial);
   begin
      Assert (Bounded.Status = Editor.External_Producers.Process_Run_Execution_Error,
              "output capture over the configured limit becomes a clear execution/output failure");
      Assert (Build_Result.Status = Editor.External_Producers.Build_Run_Execution_Error,
              "bounded process-output failure maps to build execution failure, not success with an unbounded log");
      Assert (not Details.Stdout_Available
              and then not Details.Stderr_Available
              and then Editor.Build_Execution_Workflow.Assert_Build_Output_Is_Bounded (Details),
              "output capture failure exposes no unbounded stdout or stderr details");
   end Test_Output_Capture_Over_Limit_Is_Clear_Failure_Not_Unbounded_Log;

   procedure Test_Diagnostics_Ingestion_Failure_Is_Scalar_And_Does_Not_Hide_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed: exit code 1.",
           Exit_Code => 1,
           Has_Exit_Code => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => False);
      Snapshot : constant Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot :=
        Editor.Build_Result_Summary.Render_Snapshot (Summary);
   begin
      Assert (Summary.Has_Result
              and then Summary.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Failed
              and then Summary.Has_Exit_Code
              and then Summary.Exit_Code_If_Available = 1,
              "diagnostics ingestion failure does not hide the runner build result");
      Assert (Editor.Build_Result_Summary.Diagnostics_Label (Summary) =
                "Diagnostics ingestion failed; review output for details.",
              "diagnostics ingestion failure is represented as a scalar summary label");
      Assert (Length (Snapshot.Latest_Build_Result_Diagnostics_Label) > 0,
              "render snapshot carries scalar diagnostics status only");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Result_Summary_Reflects_Runner_Status
                (Summary),
              "summary with ingestion failure remains a transient non-owning result projection");
   end Test_Diagnostics_Ingestion_Failure_Is_Scalar_And_Does_Not_Hide_Result;

   procedure Test_Availability_Is_Side_Effect_Free_With_Populated_Execution_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Before_Result : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Candidate_Derived,
           Working_Context_Label => "current-project-root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed: exit code 1.",
           Exit_Code => 1,
           Has_Exit_Code => True);
      Before_Output : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => To_Unbounded_String ("out"),
           Stderr_Text => To_Unbounded_String ("err"),
           Exit_Code => 1,
           Has_Exit_Code => True);
      First_Availability : Editor.Commands.Command_Availability;
      Second_Availability : Editor.Commands.Command_Availability;
   begin
      S.Latest_Build_Result := Before_Result;
      S.Latest_Build_Output_Details := Before_Output;

      First_Availability := Editor.Build_Command.Build_Run_Availability (S);
      Second_Availability := Editor.Build_Command.Build_Run_Availability (S);

      Assert (Editor.Commands.Is_Available (First_Availability) =
                Editor.Commands.Is_Available (Second_Availability),
              "build.run availability is stable across repeated checks");
      Assert (S.Latest_Build_Result.Has_Result
              and then To_String (S.Latest_Build_Result.Primary_Message) =
                "Build failed: exit code 1.",
              "availability checks do not rewrite latest result summary");
      Assert (S.Latest_Build_Output_Details.Stdout_Available
              and then To_String (S.Latest_Build_Output_Details.Stdout_Excerpt) = "out"
              and then To_String (S.Latest_Build_Output_Details.Stderr_Excerpt) = "err",
              "availability checks do not rewrite bounded output details");
      Assert (Editor.Build_Command.Assert_Build_Run_Availability_Side_Effect_Free (S),
              "command availability remains side-effect-free with populated execution state");
   end Test_Availability_Is_Side_Effect_Free_With_Populated_Execution_State;

   procedure Test_Command_Surface_Has_No_Execution_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Run_Descriptor : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
   begin
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Command_Surface_Has_No_Execution_Payloads,
              "build.run descriptor exposes only a canonical command, not request/candidate/result payloads");
      Assert (not Run_Descriptor.Bindable,
              "build.run remains unavailable to payload-free keybindings until a safe default exists");
      Assert (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Build_Run) = "build.run",
              "Command Palette route uses the canonical stable command name only");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Keybindings_Have_No_Run_Payloads,
              "keybinding surface carries no Build request or result identifiers");
   end Test_Command_Surface_Has_No_Execution_Payloads;

   procedure Test_Populated_Execution_State_Is_Still_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
   begin
      S.Latest_Build_Result := Editor.Build_Result_Summary.Build_Summary
        (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Candidate_Derived,
         Working_Context_Label => "current-project-root",
         Runner_Status_Label => "output truncated",
         Primary_Message => "Build output truncated.",
         Stdout_Truncated => True,
         Stderr_Truncated => True,
         Output_Partial => True,
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
         Diagnostics_Count => 3,
         Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Output_Truncated,
           Stdout_Text => To_Unbounded_String ("bounded stdout"),
           Stderr_Text => To_Unbounded_String ("bounded stderr"),
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Output_Partial => True);

      Assert (S.Build_UI.Consent_Acknowledged,
              "fixture starts from a user-consented request surface");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Execution_No_Transient_Persistence_Fields (S),
              "candidate selection request config consent latest result output and diagnostics scalar state remain non-persisted");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Execution_Workflow_Coherent (S),
              "Phase 555 coherence holds even with populated transient execution surfaces");
   end Test_Populated_Execution_State_Is_Still_Not_Persisted;

   procedure Test_Disabled_Diagnostics_Result_Cannot_Request_Diagnostics_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Gate_Disabled : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Process_Result : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code => 1,
           Has_Exit_Code => True,
           Stderr_Text => "demo.adb:1:1:error: broken");
      Result : constant Editor.External_Producers.Build_Command_Result :=
        Editor.External_Producers.Run_Build_Command_With_Gate
          (S, Request, Gate_Disabled, Process_Result);
   begin
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Failed,
              "runner failure remains visible even when diagnostics ingestion is disabled");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Diagnostics_Disabled_Does_Not_Ingest (Result),
              "disabled diagnostics ingestion produces no rows and no reveal request");
      Assert (Result.Diagnostic_Result.Ingestion.Parse_Input_Count = 0,
              "disabled diagnostics ingestion does not parse captured output opportunistically");
   end Test_Disabled_Diagnostics_Result_Cannot_Request_Diagnostics_Reveal;


   procedure Test_Unavailable_Reasons_Are_Complete_And_Direct
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Run_Unavailable_Reasons_Complete,
              "every build.run preflight status has a direct non-empty user-facing reason");
      Assert (Editor.Build_Command.Build_Run_Unavailable_Reason
                (Editor.Build_Command.Build_Run_Readiness_Request_Incomplete) =
              "Build request is not ready.",
              "generic invalid request remains explicit but non-runner-owned");
      Assert (Editor.Build_Command.Build_Run_Unavailable_Reason
                (Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled) =
              "Build execution backend is disabled.",
              "disabled backend has an explicit pre-run outcome");
   end Test_Unavailable_Reasons_Are_Complete_And_Direct;

   procedure Test_Repeated_Preflight_Failures_Replace_Latest_Result_Not_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      First_Exec : Editor.Command_Execution.Command_Execution_Result;
      Second_Exec : Editor.Command_Execution.Command_Execution_Result;
      First_Result : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      First_Message_Count : Natural;
      Before_Count : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (S.Build_UI);
      First_Exec := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);
      First_Result := S.Latest_Build_Result;
      First_Message_Count := Editor.Messages.Count (S.Messages);

      Assert (First_Exec.Status = Editor.Command_Execution.Command_Unavailable,
              "first preflight rejection returns through Executor as unavailable");
      Assert (To_String (First_Result.Primary_Message) = "No build candidate selected.",
              "first preflight rejection becomes the latest result message");
      Assert (First_Message_Count = Before_Count + 1,
              "first preflight rejection emits exactly one command outcome");

      Editor.Project.Clear (S.Project);
      Second_Exec := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);

      Assert (Second_Exec.Status = Editor.Command_Execution.Command_Unavailable,
              "second preflight rejection also returns through Executor as unavailable");
      Assert (Editor.Messages.Count (S.Messages) = First_Message_Count + 1,
              "second preflight rejection emits exactly one additional command outcome");
      Assert (Latest_Message_Text (S) = "No project open.",
              "latest visible command outcome is replaced by the newest preflight reason");
      Assert (To_String (S.Latest_Build_Result.Primary_Message) = "No project open.",
              "latest result summary is replaced by newest preflight failure, not appended history");
      Assert (Editor.Build_Execution_Workflow.Assert_Build_Latest_Result_Replaces_Attempt
                (First_Result, S.Latest_Build_Result),
              "latest-result surface remains replace-only across repeated preflight failures");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details
              and then not S.Latest_Build_Output_Details.Stdout_Available
              and then not S.Latest_Build_Output_Details.Stderr_Available,
              "repeated preflight failures still do not synthesize runner output");
   end Test_Repeated_Preflight_Failures_Replace_Latest_Result_Not_History;

   procedure Test_Preflight_Rejections_Do_Not_Run_Diagnostics_Ingestion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type := Ready_State;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (S.Build_UI);
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);

      Assert (Editor.Build_Execution_Workflow.Assert_Build_Preflight_Result_Has_No_Diagnostics
                (Result),
              "preflight rejections do not parse output or create diagnostics rows");
      Assert (S.Latest_Build_Result.Has_Result
              and then S.Latest_Build_Result.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested,
              "preflight latest result carries scalar not-requested diagnostics status only");
   end Test_Preflight_Rejections_Do_Not_Run_Diagnostics_Ingestion;


   procedure Test_Async_Build_Cancel_Handoff_State_Machine
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Build_Command.Assert_Async_Build_Cancel_Handoff_Behavior,
              "async build handoff supports running -> cancel -> cancelled finalization behavior");
   end Test_Async_Build_Cancel_Handoff_State_Machine;

   procedure Test_Async_Build_Output_Snapshot_Handoff_State_Machine
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Build_Command.Assert_Async_Build_Output_Snapshot_Handoff_Behavior,
              "async build handoff publishes stdout/stderr stream snapshots before final completion");
   end Test_Async_Build_Output_Snapshot_Handoff_State_Machine;

   procedure Test_Async_Build_Partial_Stdout_Stderr_Before_Completion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion,
         "async build publishes partial stdout and stderr before final completion");
   end Test_Async_Build_Partial_Stdout_Stderr_Before_Completion;

   procedure Test_Async_Build_State_Slots_Are_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_State_Slots_Are_Isolated,
         "async build slots must keep separate editor-state handoff payloads");
   end Test_Async_Build_State_Slots_Are_Isolated;

   procedure Test_Async_Build_Slot_Id_Is_Stable_Per_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Slot_Id_Is_Stable_Per_State,
         "async build slot id must be stable per editor state across jobs");
   end Test_Async_Build_Slot_Id_Is_Stable_Per_State;

   procedure Test_Async_Build_Slot_Pool_Exhaustion_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Slot_Pool_Exhaustion_Is_Rejected,
         "async build slot pool must reject the ninth simultaneous occupied slot");
   end Test_Async_Build_Slot_Pool_Exhaustion_Is_Rejected;

   procedure Test_Async_Build_Lifecycle_Shutdown_Handoff
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior,
         "project/open/close lifecycle requests async build cancellation before transition");
   end Test_Async_Build_Lifecycle_Shutdown_Handoff;

   procedure Test_Async_Build_Worker_Shutdown_Drain
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Worker_Shutdown_Drain_Behavior,
         "async build worker shutdown drains active job and clears process state");
   end Test_Async_Build_Worker_Shutdown_Drain;

   procedure Test_Async_Build_Real_Process_Cancel_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Real_Process_Cancel_Integration,
         "async build can cancel a live real process and finalize cancelled");
   end Test_Async_Build_Real_Process_Cancel_Integration;



   procedure Test_Async_Build_Worker_Stop_Terminates_Pool
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Build_Command.Assert_Async_Build_Worker_Stop_Terminates_Pool_Behavior,
         "async build worker stop terminates the application-exit worker pool");
   end Test_Async_Build_Worker_Stop_Terminates_Pool;

   procedure Test_Native_Process_Control_Backend_Is_Explicitly_POSIX
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.External_Producers.Current_Native_Process_Control_Backend =
         Editor.External_Producers.Native_Process_Control_POSIX,
         "native process-control backend is explicitly POSIX");
      Assert
        (Editor.External_Producers.Native_Process_Control_Is_POSIX,
         "native process-control backend reports POSIX support");
      Assert
        (Editor.External_Producers.Native_Process_Control_Backend_Label =
         "POSIX/fork-exec-waitpid-kill",
         "native process-control backend label names the POSIX primitives");
      Assert
        (Editor.External_Producers.Native_Process_Control_Platform_Audit_Passes,
         "native process-control platform audit passes");
   end Test_Native_Process_Control_Backend_Is_Explicitly_POSIX;

   overriding procedure Register_Tests
     (T : in out Build_Execution_Workflow_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Unavailable_Reasons_Are_Complete_And_Direct'Access,
         "Phase 555 unavailable reasons are complete and direct");
      Register_Routine
        (T, Test_Repeated_Preflight_Failures_Replace_Latest_Result_Not_History'Access,
         "Phase 555 repeated preflight failures replace latest result, not history");
      Register_Routine
        (T, Test_Preflight_Rejections_Do_Not_Run_Diagnostics_Ingestion'Access,
         "Phase 555 preflight rejections do not run diagnostics ingestion");
      Register_Routine
        (T, Test_Preflight_Rejects_No_Project_Before_Runner'Access,
         "Phase 555 pre-run validation rejects no-project state before runner");
      Register_Routine
        (T, Test_Preflight_Rejects_Unconsented_Or_Invalid_Request'Access,
         "Phase 555 pre-run validation rejects missing/stale consent before runner");
      Register_Routine
        (T, Test_Preflight_Rejects_No_Candidate_And_Stale_Candidate'Access,
         "Phase 555 pre-run validation rejects missing and stale candidates before runner");
      Register_Routine
        (T, Test_Preflight_Rejects_Missing_Candidate_File'Access,
         "Phase 555 pre-run validation rejects missing candidate source files before runner");
      Register_Routine
        (T, Test_Structured_Gated_Run_Produces_Latest_Result_And_Output'Access,
         "Phase 555 structured gated build run produces result and bounded output");
      Register_Routine
        (T, Test_Preflight_Rejects_Working_Context_Failures'Access,
         "Phase 555 pre-run validation rejects missing and unavailable working contexts before runner");
      Register_Routine
        (T, Test_Execution_Gate_Carries_Output_And_Diagnostics_Policies'Access,
         "Phase 555 execution gate carries consent output and diagnostics request policies");
      Register_Routine
        (T, Test_Execution_Gate_Consent_Follows_Preflight_Readiness'Access,
         "Phase 555 execution gate consent follows preflight readiness");
      Register_Routine
        (T, Test_Request_Mutation_Invalidates_Consent_And_Blocks_Run'Access,
         "Phase 555 request mutation invalidates consent and blocks build.run");
      Register_Routine
        (T, Test_Preflight_Failure_Preserves_Request_Configuration_Surface'Access,
         "Phase 555 preflight failures preserve request configuration and selection surface");
      Register_Routine
        (T, Test_Build_Cancel_Command_Uses_Active_Job_Model'Access,
         "Build cancel is advertised through the active build-job cancellation/unsupported model");
      Register_Routine
        (T, Test_Active_Build_Job_Streams_Output_Before_Final_Result'Access,
         "active build job streams bounded output before the final result");
      Register_Routine
        (T, Test_Async_Build_Cancel_Handoff_State_Machine'Access,
         "async build handoff cancels a running job and finalizes cancelled");
      Register_Routine
        (T, Test_Async_Build_Output_Snapshot_Handoff_State_Machine'Access,
         "async build handoff publishes running stdout/stderr snapshots");
      Register_Routine
        (T, Test_Async_Build_Partial_Stdout_Stderr_Before_Completion'Access,
         "async build exposes partial stdout/stderr before final completion");
      Register_Routine
        (T, Test_Async_Build_State_Slots_Are_Isolated'Access,
         "async build state slots isolate handoff payloads");
      Register_Routine
        (T, Test_Async_Build_Slot_Id_Is_Stable_Per_State'Access,
         "async build slot id remains stable per editor state across jobs");
      Register_Routine
        (T, Test_Async_Build_Slot_Pool_Exhaustion_Is_Rejected'Access,
         "async build slot pool rejects simultaneous over-capacity state slots");
      Register_Routine
        (T, Test_Async_Build_Lifecycle_Shutdown_Handoff'Access,
         "async build lifecycle shutdown requests cancellation before project transitions");
      Register_Routine
        (T, Test_Async_Build_Worker_Shutdown_Drain'Access,
         "async build worker shutdown drains active job and clears process state");
      Register_Routine
        (T, Test_Async_Build_Real_Process_Cancel_Integration'Access,
         "async build cancels a live real process and finalizes cancelled");
      Register_Routine
        (T, Test_Native_Process_Control_Backend_Is_Explicitly_POSIX'Access,
         "native build process-control backend is explicitly POSIX-scoped");
      Register_Routine
        (T, Test_Runner_Failure_Statuses_Are_Represented'Access,
         "Phase 555 runner failure statuses are represented clearly");
      Register_Routine
        (T, Test_Output_Truncation_And_Latest_Result_Replacement'Access,
         "Phase 555 output truncation and latest-result replacement remain bounded");
      Register_Routine
        (T, Test_Output_Capture_Over_Limit_Is_Clear_Failure_Not_Unbounded_Log'Access,
         "Phase 555 output capture over limit is a clear failure, not an unbounded log");
      Register_Routine
        (T, Test_Output_Details_No_Output_State_Is_Clear'Access,
         "Phase 555 output details represent no-output builds clearly");
      Register_Routine
        (T, Test_Diagnostics_Ingestion_Is_Request_Controlled_And_Owned'Access,
         "Phase 555 diagnostics ingestion is request controlled and Diagnostics-owned");
      Register_Routine
        (T, Test_Diagnostics_Ingestion_Failure_Is_Scalar_And_Does_Not_Hide_Result'Access,
         "Phase 555 diagnostics ingestion failure is scalar and does not hide build result");
      Register_Routine
        (T, Test_Shell_Payloads_Are_Rejected_By_Coherence_Guards'Access,
         "Phase 555 shell payloads are rejected by execution coherence guards");
      Register_Routine
        (T, Test_Gated_Runner_Rejects_Shell_Shaped_Tokens_Without_Diagnostics'Access,
         "Phase 555 gated runner rejects shell-shaped tokens without diagnostics");
      Register_Routine
        (T, Test_Executor_Route_Rejects_Build_Run_Before_Runner'Access,
         "Phase 555 Executor route rejects build.run before runner and emits one outcome");
      Register_Routine
        (T, Test_Result_And_Output_Surfaces_Carry_No_Rerun_Or_Process_Control'Access,
         "Phase 555 result and output surfaces carry no rerun or process control state");
      Register_Routine
        (T, Test_Unavailable_Preflight_Updates_Transient_Result_And_Output'Access,
         "Phase 555 pre-run failures update only transient result and output surfaces");
      Register_Routine
        (T, Test_Build_UI_Projects_Result_Output_And_Diagnostics_As_Display_Only'Access,
         "Phase 555 Build UI projects result output and diagnostics as display-only state");

      Register_Routine
        (T, Test_Availability_Is_Side_Effect_Free_With_Populated_Execution_State'Access,
         "Phase 555 availability remains side-effect-free with populated execution state");
      Register_Routine
        (T, Test_Command_Surface_Has_No_Execution_Payloads'Access,
         "Phase 555 command surface carries no execution payloads");
      Register_Routine
        (T, Test_Populated_Execution_State_Is_Still_Not_Persisted'Access,
         "Phase 555 populated execution state remains excluded from persistence");
      Register_Routine
        (T, Test_Disabled_Diagnostics_Result_Cannot_Request_Diagnostics_Reveal'Access,
         "Phase 555 disabled diagnostics ingestion cannot request reveal or rows");
      Register_Routine
        (T, Test_Render_Command_And_Persistence_Boundaries'Access,
         "Phase 555 render command routing and persistence boundaries remain closed");
      Register_Routine
        (T, Test_Async_Build_Worker_Stop_Terminates_Pool'Access,
         "async build worker stop terminates the application-exit worker pool");
   end Register_Tests;

end Editor.Build_Execution_Workflow.Tests;
