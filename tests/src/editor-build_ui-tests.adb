with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Public_Request;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_Candidates;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Build_Working_Context;
with Editor.External_Producers;
with Editor.Commands;
with Editor.State;
with Editor.Executor;
with Editor.Command_Execution;
with Editor.Render_Model;

use type Editor.Build_UI.Public_Build_UI_Validation_Status;
use type Editor.Build_UI.Public_Build_Tool_Selection;
use type Editor.Build_Working_Context.Build_Working_Context_Kind;
use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;
use type Editor.Build_Working_Context.Working_Context_Source_Kind;
use type Editor.External_Producers.Build_Request_Provenance;
use type Editor.External_Producers.Build_Tool_Kind;
use type Editor.Commands.Command_Id;
use type Editor.Command_Execution.Command_Execution_Status;
use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
use type Editor.Build_UI.Build_UI_Build_Mode;
use type Editor.Build_UI.Build_UI_Output_Capture_Limit;

package body Editor.Build_UI.Tests is

   overriding function Name
     (T : Build_UI_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_UI");
   end Name;

   function Ready_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Ready_UI;


   function Ready_Alire_UI return Editor.Build_UI.Public_Build_UI_State
   is
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result (S, True);
      Editor.Build_UI.Acknowledge_Consent (S);
      return S;
   end Ready_Alire_UI;

   procedure Test_Build_UI_State_Is_Transient_And_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (S.Build_UI_Visible, "public build UI is explicitly visible");
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_GPRbuild,
              "build tool selection is explicit and bounded");
      Assert (Editor.Build_UI.Argument_Count (S.Structured_Arguments) > 0,
              "arguments are structured tokens");
      Assert (S.Show_Diagnostics_On_Result,
              "diagnostics display preference is explicit and transient");
      Assert (Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S),
              "build UI state carries no raw shell or remembered-consent field");
   end Test_Build_UI_State_Is_Transient_And_Explicit;

   procedure Test_Request_Changes_Invalidate_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      Assert (S.Consent_Acknowledged, "setup starts consented");
      Editor.Build_UI.Select_Tool (S, Editor.Build_UI.Build_UI_Alire);
      Assert (not S.Consent_Acknowledged, "tool change invalidates consent");

      S := Ready_UI;
      Editor.Build_UI.Append_Argument (Args, "build");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Assert (not S.Consent_Acknowledged, "argument change invalidates consent");

      S := Ready_UI;
      Editor.Build_UI.Set_Working_Context_Label (S, "active-workspace-root");
      Assert (not S.Consent_Acknowledged, "working context change invalidates consent");
   end Test_Request_Changes_Invalidate_Consent;

   procedure Test_Structured_Request_Conversion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      C : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
   begin
      Assert (C.Status = Editor.Build_UI.Build_UI_Valid,
              "complete consented UI validates");
      Assert (C.Request.Provenance =
                Editor.External_Producers.Build_Request_From_User_Opt_In,
              "conversion preserves user-opt-in provenance");
      Assert (C.Request.Tool = Editor.External_Producers.GPRbuild_Tool,
              "conversion preserves bounded tool selection");
      Assert (To_String (C.Request.Arguments)'Length = 0,
              "conversion does not create opaque shell arguments");
      Assert (Editor.External_Producers.Process_Argument_Count
                (C.Request.Structured_Arguments) > 0,
              "conversion preserves structured argv");
   end Test_Structured_Request_Conversion;

   procedure Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      Args : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      Editor.Build_UI.Clear_Consent (S);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "missing consent prevents public build request");

      S := Ready_UI;
      Editor.Build_UI.Append_Argument (Args, "-q; rm -rf tmp");
      Editor.Build_UI.Set_Structured_Arguments (S, Args);
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsafe_Arguments,
              "shell-like argument form is rejected before conversion");
   end Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected;


   procedure Test_Working_Context_Model_Is_Explicit_Structured_And_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Current_Project_Root ("current-project-root");
      Missing_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.None;
      Unavailable_Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unavailable ("No canonical project/workspace context");
   begin
      Assert (Project_Context.Kind =
                Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
              "project root context is an explicit bounded kind");
      Assert (Project_Context.Source_Kind =
                Editor.Build_Working_Context.Working_Context_Source_Canonical_Project,
              "project root context comes only from canonical project state");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Project_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Valid,
              "canonical project context validates without filesystem probing");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Missing_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Rejected_None,
              "missing context has deterministic unavailable status");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context
                (Unavailable_Context) =
              Editor.Build_Working_Context.Build_Working_Context_Rejected_Unavailable,
              "unavailable context remains explicit and non-probing");
      Assert (Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
                (Project_Context),
              "working context is transient metadata");
      Assert (Editor.Build_Working_Context.Assert_Build_Working_Context_Does_Not_Probe_Filesystem
                (Project_Context),
              "working context model does not use filesystem discovery");
   end Test_Working_Context_Model_Is_Explicit_Structured_And_Transient;

   procedure Test_Working_Context_Rejects_Forbidden_Sources
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Raw : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           "/tmp/build", Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
           "/tmp/build");
      Shell : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           "cd /tmp && alr build",
           Editor.Build_Working_Context.Working_Context_Source_Shell_Derived,
           "/tmp");
      Metadata : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
           "project:alire.toml",
           Editor.Build_Working_Context.Working_Context_Source_Project_Metadata_Derived,
           "project:alire.toml");
      Persisted : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
           "remembered-cwd",
           Editor.Build_Working_Context.Working_Context_Source_Persisted,
           "remembered-cwd");
   begin
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Raw) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Raw_Text,
              "raw cwd text is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Shell) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Shell_Derived,
              "shell-derived cwd is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Metadata) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Project_Metadata_Derived,
              "project metadata-derived cwd is rejected");
      Assert (Editor.Build_Working_Context.Validate_Build_Working_Context (Persisted) =
                Editor.Build_Working_Context.Build_Working_Context_Rejected_Persisted,
              "persisted working context is rejected");
   end Test_Working_Context_Rejects_Forbidden_Sources;

   procedure Test_Request_Conversion_Requires_Valid_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
      C : Editor.Build_Public_Request.Public_Build_Request_Conversion_Result;
   begin
      S.Selected_Working_Context := Editor.Build_Working_Context.None;
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Working_Context_Required,
              "missing working context blocks conversion");

      S := Ready_UI;
      S.Selected_Working_Context :=
        Editor.Build_Working_Context.Unavailable
          ("No canonical project/workspace context");
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Working_Context_Unavailable,
              "unavailable working context blocks conversion");

      S := Ready_UI;
      S.Selected_Working_Context :=
        Editor.Build_Working_Context.Unsafe_Context
          (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
           "/tmp/build",
           Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
           "/tmp/build");
      Editor.Build_UI.Acknowledge_Consent (S);
      C := Editor.Build_Public_Request.Build_Public_Request_From_UI_State (S);
      Assert (C.Status = Editor.Build_UI.Build_UI_Rejected_Unsafe_Working_Context,
              "raw directory text blocks conversion");
   end Test_Request_Conversion_Requires_Valid_Working_Context;

   procedure Test_Working_Context_Consent_Binds_Request_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (S.Consent_Acknowledged, "setup is consented");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid,
              "ready state validates before request identity changes");

      S.Working_Context_Canonical_Path_If_Available := To_Unbounded_String ("tampered");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid,
              "render snapshot fields do not participate as mutable authority");

      S.Selected_Working_Context := Editor.Build_Working_Context.Current_Project_Root
        ("different-canonical-token");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Stale_Consent,
              "changing request working context after consent requires renewed consent");
   end Test_Working_Context_Consent_Binds_Request_Identity;

   procedure Test_Public_Build_Working_Context_Foundation_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_UI.Public_Build_UI_State := Ready_UI;
   begin
      Assert (Editor.Build_Public_Request.Assert_Public_Build_Working_Context_Foundation_Coherent
                (S),
              "Phase 502 working-context foundation is coherent");
   end Test_Public_Build_Working_Context_Foundation_Coherent;

   procedure Test_Build_Run_Command_Is_Public_But_Non_Executing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      S.Build_UI := Ready_UI;
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run has a stable public command name");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Run),
              "build.run is classified as the public build command");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);
      Assert (Result.Status = Editor.Command_Execution.Command_Unavailable,
              "build.run remains unavailable while execution backend is disabled");
   end Test_Build_Run_Command_Is_Public_But_Non_Executing;


   procedure Test_Build_UI_Operability_Actions_And_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Assert (S.Build_UI.Build_UI_Visible, "Build UI can be shown");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "showing Build UI does not acknowledge consent");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "showing Build UI does not auto-select or discover candidates");

      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI_Actions.Build_UI_Select_Candidate
        (S, To_String (Candidate.Candidate_Id));
      Assert (S.Build_UI.Candidate_Applied_To_Request,
              "candidate selection applies candidate-derived request mode");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "candidate selection invalidates prior consent and does not auto-consent");

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Visible, "snapshot exposes visible Build UI");
      Assert (Snapshot.Candidate_Count = 1,
              "snapshot exposes candidate list from transient state");
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "candidate-derived",
              "snapshot exposes request mode");
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "alire",
              "snapshot exposes structured tool kind");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 1,
              "snapshot exposes structured argv tokens");
      Assert (Snapshot.Consent_Required,
              "snapshot exposes consent-required state");
      Assert (To_String (Snapshot.Run_Availability_Label)'Length > 0,
              "snapshot exposes build.run availability reason");

      Editor.Build_UI_Actions.Build_UI_Acknowledge_Consent (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Consent_Acknowledged,
              "explicit Build UI consent acknowledgement is visible");
      Editor.Build_UI_Actions.Build_UI_Clear_Consent (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Consent_Required,
              "explicit Build UI consent clearing is visible");
   end Test_Build_UI_Operability_Actions_And_Snapshot;

   procedure Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Result : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Run_Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Refresh_Candidates
        (S, Editor.Build_Working_Context.Unavailable
              ("No canonical project/workspace context"));
      Assert (Result.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_No_Project_Context,
              "Build UI refresh calls canonical refresh path and reports no project");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
                (Before.Build_UI, S.Build_UI, Result),
              "Build UI refresh does not auto-select");
      Assert (Editor.Build_Candidate_Refresh.Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
                (Before.Build_UI, S.Build_UI),
              "Build UI refresh does not auto-consent");

      Before := S;
      Run_Result := Editor.Build_UI_Actions.Build_UI_Run_Build (S);
      Assert (Run_Result.Status = Editor.Command_Execution.Command_Unavailable,
              "Build UI Run respects Executor availability");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Run_Routes_Through_Executor
                (Before, S, Run_Result),
              "Build UI Run dispatches canonical build.run through Executor");
   end Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries;

   procedure Test_Build_UI_Result_And_Output_Snapshot_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Summary_From_Unavailable_Message
          ("execution backend disabled");
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("stdout excerpt"),
           To_Unbounded_String ("stderr excerpt"),
           Stdout_Truncated => True,
           Stderr_Truncated => False,
           Output_Partial => True);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Latest_Result.Latest_Build_Result_Visible,
              "Build UI snapshot projects latest result summary");
      Assert (Snapshot.Output_Details.Output_Details_Available,
              "Build UI snapshot projects bounded output details");
      Assert (To_String (Snapshot.Output_Details.Stdout_Excerpt) =
                "stdout excerpt",
              "Build UI snapshot exposes bounded stdout excerpt");
      Assert (To_String (Snapshot.Output_Details.Stderr_Excerpt) =
                "stderr excerpt",
              "Build UI snapshot exposes bounded stderr excerpt");
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Does_Not_Persist_Transient_State
                (S),
              "Build UI projection preserves persistence exclusions");
   end Test_Build_UI_Result_And_Output_Snapshot_Projection;


   procedure Test_Render_Model_Projects_Build_UI_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Editor.Build_UI.Select_Tool (S.Build_UI, Editor.Build_UI.Build_UI_GPRbuild);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Build_UI.Visible,
              "render model consumes Build UI snapshot");
      Assert (To_String (Snap.Build_UI.Request_Preview.Tool_Kind_Label) =
                "gprbuild",
              "render model projects Build UI request preview without mutation");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "render snapshot does not acknowledge consent");
   end Test_Render_Model_Projects_Build_UI_Snapshot;

   procedure Test_Build_UI_Commands_Are_Public_And_Executor_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.ui.show", Found);
      Assert (Found and then Id = Editor.Commands.Command_Build_UI_Show,
              "build.ui.show has a stable command id");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Show);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI show is routed through Executor");
      Assert (S.Build_UI.Build_UI_Visible,
              "Build UI show command makes the Build UI visible");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "Build UI show command does not acknowledge consent");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "Build UI show command does not discover or auto-select candidates");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI focus is routed through Executor");
      Assert (S.Build_UI.Build_UI_Visible and then S.Build_UI.Build_UI_Focused,
              "Build UI focus command shows and focuses the panel");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_UI_Hide);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "Build UI hide is routed through Executor");
      Assert (not S.Build_UI.Build_UI_Visible,
              "Build UI hide command hides the panel");
   end Test_Build_UI_Commands_Are_Public_And_Executor_Routed;


   procedure Test_Phase527_Result_Output_Diagnostics_UI_Usability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True,
           Stdout_Truncated => True,
           Output_Partial => False,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 2,
           Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("bounded stdout"),
           To_Unbounded_String ("bounded stderr"),
           Stdout_Truncated => True);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Status_Label) =
                "Build failed",
              "Phase 527 Build UI shows understandable latest result status");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Runner_Status_Label) =
                "failed",
              "Phase 527 Build UI shows runner status");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Diagnostics_Label) =
                "Diagnostics produced: 2",
              "Phase 527 Build UI shows Diagnostics scalar count");
      Assert (To_String (Snapshot.Output_Details.Stdout_Excerpt) =
                "bounded stdout"
              and then To_String (Snapshot.Output_Details.Stderr_Excerpt) =
                "bounded stderr",
              "Phase 527 Build UI exposes bounded stdout/stderr excerpts");
      Assert (To_String (Snapshot.Output_Details.Stdout_Truncation_Label) =
                "stdout truncated",
              "Phase 527 Build UI distinguishes stdout truncation");
      Assert (Snapshot.Diagnostics_View.Reveal_Available
              and then To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                "diagnostics-show",
              "Phase 527 Build UI reveal uses existing Diagnostics command name only");
      Assert (Editor.Build_UI_Actions.Assert_Public_Build_Result_Output_UI_Coherent
                (S),
              "Phase 527 result/output/diagnostics UI remains coherent and transient");
   end Test_Phase527_Result_Output_Diagnostics_UI_Usability;

   procedure Test_Phase527_No_Output_And_Partial_Output_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_Alire_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "timed out",
           Primary_Message => "Build timed out",
           Timed_Out => True,
           Output_Partial => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_No_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out);

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (To_String (Snapshot.Output_Details.No_Output_Label) =
                "No build output captured.",
              "Phase 527 Build UI shows no-output state explicitly");
      Assert (To_String (Snapshot.Output_Details.Stdout_No_Output_Label) =
                "No stdout captured."
              and then To_String (Snapshot.Output_Details.Stderr_No_Output_Label) =
                "No stderr captured.",
              "Phase 527 Build UI does not reuse stale stream text");
      Assert (To_String (Snapshot.Output_Details.Partial_Output_Label) =
                "build timed out; output may be incomplete",
              "Phase 527 Build UI distinguishes partial timeout output from truncation");
      Assert (To_String (Snapshot.Latest_Result.Latest_Build_Result_Truncation_Label) =
                "output not truncated",
              "Phase 527 timeout partial output is not reported as truncation");
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "Phase 527 no diagnostics does not create a build-local diagnostics route");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => True);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "Phase 527 zero produced Diagnostics does not expose reveal action");
   end Test_Phase527_No_Output_And_Partial_Output_Are_Clear;

   procedure Test_Phase527_Reveal_Diagnostics_Routes_Through_Existing_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           To_Unbounded_String ("out"),
           To_Unbounded_String ("err"));
      Before := S;
      Result := Editor.Build_UI_Actions.Build_UI_Reveal_Diagnostics (S);
      Assert (Editor.Build_UI_Actions.Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
                (Before, S, Result),
              "Phase 527 reveal diagnostics invokes existing Diagnostics command without build payload");
   end Test_Phase527_Reveal_Diagnostics_Routes_Through_Existing_Command;



   procedure Test_Phase554_Candidate_Specific_Request_Configuration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Alire : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Alire_Candidate ("current-project-root");
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (Alire);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 2 candidates");

      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (Alire.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "candidate-derived",
              "Phase 554 selected candidate produces candidate-derived request mode");
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "alire",
              "Phase 554 Alire candidate exposes alire tool label");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 1,
              "Phase 554 Alire request preview exposes structured argv tokens");
      Assert (To_String (Snapshot.Request_Preview.Build_Mode_Label) = "default",
              "Phase 554 default mode is visible");
      Assert (To_String (Snapshot.Request_Preview.Diagnostics_Label) =
                "Diagnostics not requested after build",
              "Phase 554 diagnostics ingestion state is visible");
      Assert (To_String (Snapshot.Request_Preview.Output_Capture_Limit_Label) =
                "normal bounded output capture (262144 bytes)",
              "Phase 554 bounded output capture policy is visible");
      Assert (Natural (Snapshot.Request_Preview.Request_Option_Rows.Length) >= 5,
              "Phase 554 request option rows are projected into the Build UI snapshot");
      Assert (not S.Option_Verbose_Output and then not S.Option_Keep_Going,
              "Phase 554 Alire candidate starts with GPR-only flags disabled");
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Assert (not S.Option_Verbose_Output,
              "Phase 554 unsupported Alire verbose flag is not applied");

      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (Snapshot.Request_Preview.Tool_Kind_Label) = "gprbuild",
              "Phase 554 GPR candidate exposes gprbuild tool label");
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 2,
              "Phase 554 GPR request preview exposes -P and selected project token");
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Editor.Build_UI.Toggle_Keep_Going (S);
      Assert (S.Option_Verbose_Output and then S.Option_Keep_Going,
              "Phase 554 supported GPR fixed flag toggles are structured state");
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Editor.Build_UI.Argument_Count
                (Snapshot.Request_Preview.Argv_Tokens) = 4,
              "Phase 554 GPR fixed flag toggles append fixed argv tokens only");
      Assert (Editor.Build_UI.Assert_Build_Request_Options_Are_Candidate_Specific (S),
              "Phase 554 candidate-specific option assertion holds for GPR request");

      S.Option_Warnings_As_Errors := True;
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option,
              "Phase 554 rejects unimplemented hidden warnings-as-errors flag even for GPR candidates");
      Assert (Ada.Strings.Fixed.Index
                (To_String (S.Candidate_Request_Preview), "warnings-as-errors") = 0,
              "Phase 554 preview omits unimplemented hidden warnings-as-errors option");
      Assert (not Editor.Build_UI.Assert_Build_Request_Options_Are_Candidate_Specific (S),
              "Phase 554 coherence rejects hidden flags without fixed argv mappings");
      S.Option_Warnings_As_Errors := False;
      S.Option_Force_Rebuild := True;
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option,
              "Phase 554 rejects unimplemented hidden force-rebuild flag even for GPR candidates");
   end Test_Phase554_Candidate_Specific_Request_Configuration;

   procedure Test_Phase554_Material_Changes_Invalidate_Exact_Request_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Original_Id : Unbounded_String;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "Phase 554 valid candidate request can be consented");
      Original_Id := S.Consent_Request_Identity;

      Editor.Build_UI.Toggle_Diagnostics_Ingestion (S);
      Assert (not S.Consent_Acknowledged,
              "Phase 554 diagnostics toggle invalidates request consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "Phase 554 diagnostics toggle changes material request identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "Phase 554 changed diagnostics request can be re-consented");
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Cycle_Output_Capture_Limit (S);
      Assert (not S.Consent_Acknowledged,
              "Phase 554 output capture limit change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "Phase 554 output capture limit changes material identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Toggle_Verbose_Output (S);
      Assert (not S.Consent_Acknowledged,
              "Phase 554 fixed flag change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "Phase 554 fixed flag change changes material identity");

      Editor.Build_UI.Acknowledge_Consent (S);
      Original_Id := S.Consent_Request_Identity;
      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (not S.Consent_Acknowledged,
              "build mode change invalidates consent");
      Assert (To_String (Original_Id) /= Editor.Build_UI.Current_Request_Identity (S),
              "build mode change changes material identity");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Valid
              or else Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "GPR debug mode remains a supported request once consent is refreshed");
      Editor.Build_UI.Acknowledge_Consent (S);
      Assert (S.Consent_Acknowledged,
              "GPR debug request can be consented after review");
   end Test_Phase554_Material_Changes_Invalidate_Exact_Request_Consent;


   procedure Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_UI;

      function Has_Arg (Token : String) return Boolean is
      begin
         for Arg of S.Structured_Arguments loop
            if To_String (Arg) = Token then
               return True;
            end if;
         end loop;
         return False;
      end Has_Arg;
   begin
      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (Has_Arg ("-g"), "debug profile adds -g");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "debug profile is supported and only requires renewed consent");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Release);
      Assert (not Has_Arg ("-g"), "release profile removes debug flag");
      Assert (Has_Arg ("-O2"), "release profile adds -O2");
      Assert (Has_Arg ("-gnatp"), "release profile adds -gnatp");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Validation);
      Assert (not Has_Arg ("-O2"), "validation profile removes release optimization flag");
      Assert (not Has_Arg ("-gnatp"), "validation profile removes release assertion policy flag");
      Assert (Has_Arg ("-gnata"), "validation profile adds assertion checking flag");
      Assert (Has_Arg ("-gnatwa"), "validation profile adds warning profile flag");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Default);
      Assert (not Has_Arg ("-gnata") and then not Has_Arg ("-gnatwa"),
              "default profile removes validation flags");
   end Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments;


   procedure Test_Build_UI_Alire_Modes_Apply_Profile_Switches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State := Ready_Alire_UI;

      function Has_Arg (Token : String) return Boolean is
      begin
         for Arg of S.Structured_Arguments loop
            if To_String (Arg) = Token then
               return True;
            end if;
         end loop;
         return False;
      end Has_Arg;
   begin
      Assert (S.Selected_Build_Tool = Editor.Build_UI.Build_UI_Alire,
              "Alire profile test starts from an Alire candidate");
      Assert (not Has_Arg ("--development")
              and then not Has_Arg ("--release")
              and then not Has_Arg ("--validation"),
              "default Alire profile leaves alr build unqualified");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Debug);
      Assert (Has_Arg ("--development"),
              "debug build mode maps to Alire development profile");
      Assert (not Has_Arg ("--release") and then not Has_Arg ("--validation"),
              "Alire development profile is exclusive");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
              "Alire development profile is supported and only requires renewed consent");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Release);
      Assert (not Has_Arg ("--development"),
              "Alire release profile strips development switch");
      Assert (Has_Arg ("--release"),
              "release build mode maps to Alire release profile");
      Assert (not Has_Arg ("--validation"),
              "Alire release profile is exclusive");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Validation);
      Assert (not Has_Arg ("--release"),
              "Alire validation profile strips release switch");
      Assert (Has_Arg ("--validation"),
              "validation build mode maps to Alire validation profile");
      Assert (not Has_Arg ("-gnata") and then not Has_Arg ("-gnatwa"),
              "Alire profiles use alr profile switches rather than GPR compiler flags");

      Editor.Build_UI.Set_Build_Mode
        (S, Editor.Build_UI.Build_UI_Build_Mode_Default);
      Assert (not Has_Arg ("--development")
              and then not Has_Arg ("--release")
              and then not Has_Arg ("--validation"),
              "default build mode removes explicit Alire profile switches");
   end Test_Build_UI_Alire_Modes_Apply_Profile_Switches;


   procedure Test_Phase554_Request_Preview_Validation_And_Persistence_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Build_UI.Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S, To_String (GPR.Candidate_Id));
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Snapshot.Consent_Required,
              "Phase 554 valid unconsented request reports consent required");
      Assert (not Snapshot.Run_Available,
              "Phase 554 build.run is unavailable before exact consent");
      Assert (To_String (Snapshot.Request_Preview.Selected_Candidate_Label)'Length > 0,
              "Phase 554 preview shows selected candidate label");
      Assert (To_String (Snapshot.Request_Preview.Working_Context_Label)'Length > 0,
              "Phase 554 preview shows working context label");
      Assert (To_String (Snapshot.Request_Preview.Request_Identity_Label)'Length > 0,
              "Phase 554 preview shows material request identity");
      Assert (Editor.Build_UI.Assert_Build_Request_Preview_Matches_Tokens (Snapshot),
              "Phase 554 preview is derived from structured argv tokens");

      Editor.Build_UI.Acknowledge_Consent (S);
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (Snapshot.Consent_Acknowledged,
              "Phase 554 exact request consent is visible in snapshot");
      Assert (Snapshot.Run_Available,
              "Phase 554 valid consented request makes build.run UI-available");
      Assert (Editor.Build_UI.Assert_Build_Consent_Tied_To_Request_Identity (S),
              "Phase 554 consent is tied to exact request identity");
      Assert (Editor.Build_UI.Assert_Build_Request_State_Not_Persisted (S),
              "Phase 554 request configuration remains persistence-excluded transient state");
      Assert (Editor.Build_UI.Assert_Build_Request_Configuration_Coherent
                (S, Editor.Build_Result_Summary.Empty_Summary,
                 Editor.Build_Output_Details.Empty_Output_Details),
              "Phase 554 request configuration coherence assertion passes");

      Editor.Build_UI.Set_Build_Candidates
        (S, Editor.Build_Candidates.Empty_Candidates,
         "refresh succeeded: no candidates");
      Snapshot := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (not S.Consent_Acknowledged,
              "Phase 554 candidate refresh clearing selection invalidates consent");
      Assert (To_String (S.Selected_Build_Candidate_Id)'Length = 0,
              "Phase 554 candidate refresh clears selected candidate identity from transient state");
      Assert (Editor.Build_UI.Validate_Build_UI_State (S) =
                Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected,
              "Phase 554 no selected candidate makes the configured build request invalid");
      Assert (To_String (Snapshot.Request_Preview.Request_Mode_Label) =
                "no selected candidate",
              "Phase 554 preview does not present removed manual request as runnable");
   end Test_Phase554_Request_Preview_Validation_And_Persistence_Exclusion;


   procedure Test_Phase536_Build_UI_Dogfood_Labels_Are_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.Build_UI.Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details;
      View    : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.Build_UI.Show (S);
      View := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (View.Run_Availability_Label) =
              "Build run unavailable: no build candidate selected",
              "Build run availability explains the missing selected candidate");
      Assert (To_String (View.Refresh_Status_Label) =
              "Build candidates not refreshed yet",
              "Build candidate refresh status is user-facing");

      S := Ready_UI;
      Editor.Build_UI.Clear_Consent (S);
      View := Editor.Build_UI.Build_Render_Snapshot
        (S, Editor.Build_Result_Summary.Empty_Summary,
         Editor.Build_Output_Details.Empty_Output_Details);
      Assert (To_String (View.Run_Availability_Label) =
              "Build run unavailable: review the request and acknowledge consent first",
              "Build run labels missing consent with a next action");
      Assert (To_String (View.Request_Preview.Consent_Label) =
              "Consent missing: review and acknowledge the build request",
              "Build request preview distinguishes missing consent");

      Summary := Editor.Build_Result_Summary.Build_Summary
        (Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
         "build.run",
         Editor.Build_Result_Summary.Build_Result_No_Tool,
         Editor.Build_Result_Summary.Build_Result_Request_None,
         "",
         "not available",
         "Build run unavailable: execution backend is disabled",
         Diagnostics_Ingestion_Status =>
           Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested);
      Details := Editor.Build_Output_Details.Build_Output_Details_No_Output_State
        (Editor.Build_Output_Details.Build_Output_Runner_Not_Available);
      View := Editor.Build_UI.Build_Render_Snapshot (S, Summary, Details);
      Assert (To_String
                (View.Latest_Result.Latest_Build_Result_Status_Label) =
              "Build unavailable: check the Build panel run availability reason.",
              "latest build result unavailable label points back to run availability");
      Assert (To_String (View.Output_Details.No_Output_Label) =
              "No build output captured.",
              "output details no-output state is clear");
      Assert (To_String (View.Diagnostics_View.Count_Label) =
              "Diagnostics not requested",
              "diagnostics count label distinguishes not-requested state");
   end Test_Phase536_Build_UI_Dogfood_Labels_Are_Clear;

   procedure Test_Phase556_Reveal_Diagnostics_Requires_Produced_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Build_UI_Actions.Show_Build_UI (S);

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => False);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (not Snapshot.Diagnostics_View.Reveal_Available,
              "Phase 556 partial diagnostics without produced count cannot reveal rows");
      Assert (To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) = "",
              "Phase 556 Build UI does not fabricate a reveal command without rows");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Assert (Snapshot.Diagnostics_View.Reveal_Available
              and then To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                "diagnostics-show",
              "Phase 556 Build UI exposes reveal only when Diagnostics-owned rows exist");
   end Test_Phase556_Reveal_Diagnostics_Requires_Produced_Count;

   overriding procedure Register_Tests
     (T : in out Build_UI_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Build_UI_State_Is_Transient_And_Explicit'Access,
         "build UI state is transient and explicit");
      Register_Routine
        (T, Test_Request_Changes_Invalidate_Consent'Access,
         "request changes invalidate build consent");
      Register_Routine
        (T, Test_Structured_Request_Conversion'Access,
         "build UI converts to structured public request");
      Register_Routine
        (T, Test_Unsafe_Arguments_And_Missing_Consent_Are_Rejected'Access,
         "unsafe arguments and missing consent are rejected");
      Register_Routine
        (T, Test_Build_Run_Command_Is_Public_But_Non_Executing'Access,
         "build.run is public and non-executing while backend disabled");
      Register_Routine
        (T, Test_Working_Context_Model_Is_Explicit_Structured_And_Transient'Access,
         "working context model is explicit structured and transient");
      Register_Routine
        (T, Test_Working_Context_Rejects_Forbidden_Sources'Access,
         "working context rejects forbidden sources");
      Register_Routine
        (T, Test_Request_Conversion_Requires_Valid_Working_Context'Access,
         "request conversion requires valid working context");
      Register_Routine
        (T, Test_Working_Context_Consent_Binds_Request_Identity'Access,
         "working context consent binds request identity");
      Register_Routine
        (T, Test_Public_Build_Working_Context_Foundation_Coherent'Access,
         "public build working-context foundation coherent");
      Register_Routine
        (T, Test_Build_UI_Operability_Actions_And_Snapshot'Access,
         "build UI operability actions and snapshot");
      Register_Routine
        (T, Test_Build_UI_Refresh_And_Run_Use_Canonical_Boundaries'Access,
         "build UI refresh and run use canonical boundaries");
      Register_Routine
        (T, Test_Build_UI_Result_And_Output_Snapshot_Projection'Access,
         "build UI result and output snapshot projection");
      Register_Routine
        (T, Test_Render_Model_Projects_Build_UI_Snapshot'Access,
         "render model projects Build UI snapshot");
      Register_Routine
        (T, Test_Build_UI_Commands_Are_Public_And_Executor_Routed'Access,
         "build UI commands are public and Executor routed");
      Register_Routine
        (T, Test_Phase527_Result_Output_Diagnostics_UI_Usability'Access,
         "Phase 527 result output diagnostics UI usability");
      Register_Routine
        (T, Test_Phase527_No_Output_And_Partial_Output_Are_Clear'Access,
         "Phase 527 no-output and partial-output states are clear");
      Register_Routine
        (T, Test_Phase527_Reveal_Diagnostics_Routes_Through_Existing_Command'Access,
         "Phase 527 reveal diagnostics routes through existing command");
      Register_Routine
        (T, Test_Phase554_Candidate_Specific_Request_Configuration'Access,
         "Phase 554 candidate-specific request configuration");
      Register_Routine
        (T, Test_Phase554_Material_Changes_Invalidate_Exact_Request_Consent'Access,
         "Phase 554 material changes invalidate exact request consent");
      Register_Routine
        (T, Test_Build_UI_GPR_Modes_Apply_Fixed_Arguments'Access,
         "Build UI GPR modes apply fixed structured arguments");
      Register_Routine
        (T, Test_Build_UI_Alire_Modes_Apply_Profile_Switches'Access,
         "Build UI Alire modes apply structured profile switches");
      Register_Routine
        (T, Test_Phase554_Request_Preview_Validation_And_Persistence_Exclusion'Access,
         "Phase 554 request preview validation and persistence exclusion");
      Register_Routine
        (T, Test_Phase536_Build_UI_Dogfood_Labels_Are_Clear'Access,
         "Phase 536 Build UI dogfood labels are clear");
      Register_Routine
        (T, Test_Phase556_Reveal_Diagnostics_Requires_Produced_Count'Access,
         "Phase 556 reveal diagnostics requires produced count");

   end Register_Tests;

end Editor.Build_UI.Tests;
