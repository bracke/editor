with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Result_Summary;
with Editor.External_Producers;
with Editor.State;
with Editor.Build_Command;
with Editor.Commands;

package body Editor.Build_Result_Summary.Tests is

   use type Editor.Build_Result_Summary.Build_Result_Summary_Kind;
   use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.Build_Result_Summary.Build_Result_Request_Mode;
   use type Editor.Build_Result_Summary.Build_Result_Tool_Kind;
   use type Editor.External_Producers.Build_Run_Status;

   overriding function Name
     (T : Build_Result_Summary_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Result_Summary");
   end Name;

   function Request return Editor.External_Producers.Build_Run_Request is
   begin
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("current project root"),
         Command_Label => Null_Unbounded_String,
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   end Request;

   function Command_Result
     (Status : Editor.External_Producers.Build_Run_Status;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False)
      return Editor.External_Producers.Build_Command_Result
   is
   begin
      return
        (Build_Result =>
           Editor.External_Producers.Build_Build_Run_Result
             (Status,
              Exit_Code => Exit_Code,
              Has_Exit_Code => Has_Exit_Code,
              Stdout_Truncated => Stdout_Truncated,
              Stderr_Truncated => Stderr_Truncated),
         Diagnostic_Result =>
           Editor.External_Producers.Empty_Diagnostic_Line_Command_Result,
         Command_Message => To_Unbounded_String ("Build message"));
   end Command_Result;

   function Summary
     (Kind : Editor.Build_Result_Summary.Build_Result_Summary_Kind;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Timed_Out : Boolean := False;
      Cancelled : Boolean := False;
      Stdout_Truncated : Boolean := False)
      return Editor.Build_Result_Summary.Latest_Build_Result_Summary
   is
   begin
      return Editor.Build_Result_Summary.Build_Summary
        (Kind => Kind,
         Invocation_Label => "build.run",
         Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
         Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
         Working_Context_Label => "current project root",
         Runner_Status_Label => "test runner",
         Primary_Message => "Build message",
         Exit_Code => Exit_Code,
         Has_Exit_Code => Has_Exit_Code,
         Timed_Out => Timed_Out,
         Cancelled => Cancelled,
         Stdout_Truncated => Stdout_Truncated,
         Output_Partial => Timed_Out or else Cancelled);
   end Summary;

   procedure Test_Empty_Summary_Has_No_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Empty_Summary;
   begin
      Assert (not S.Has_Result, "summary starts empty before first build");
      Assert (S.Kind = Editor.Build_Result_Summary.Build_Result_Summary_None,
              "empty summary has none kind");
      Assert (Editor.Build_Result_Summary.Status_Label (S) = "No build result yet.",
              "empty summary has deterministic no-result label");
   end Test_Empty_Summary_Has_No_Result;

   procedure Test_Summary_Records_Success_And_Exit_Code
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True);
   begin
      Assert (S.Has_Result, "summary records latest build result");
      Assert (S.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
              "success maps to success summary kind");
      Assert (S.Has_Exit_Code and then S.Exit_Code_If_Available = 0,
              "summary carries available exit code");
      Assert (Editor.Build_Result_Summary.Tool_Label (S) = "gprbuild",
              "summary projects build tool label");
      Assert (Editor.Build_Result_Summary.Working_Context_Label (S) =
                "current project root",
              "summary projects working-context label as display-only state");
      declare
         Snapshot : constant Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot :=
           Editor.Build_Result_Summary.Render_Snapshot (S);
      begin
         Assert (Snapshot.Latest_Build_Result_Visible,
                 "render snapshot makes latest result visible");
         Assert (To_String (Snapshot.Latest_Build_Result_Status_Label) =
                   "Build succeeded",
                 "render snapshot carries status label only");
      end;
   end Test_Summary_Records_Success_And_Exit_Code;

   procedure Test_Summary_Records_Duration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Duration_Milliseconds => 4321,
           Has_Duration => True);
      Snapshot : constant Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot :=
        Editor.Build_Result_Summary.Render_Snapshot (S);
   begin
      Assert (S.Has_Duration and then S.Duration_Milliseconds = 4321,
              "summary carries elapsed build duration");
      Assert (Editor.Build_Result_Summary.Duration_Label (S) =
                "duration 4.3 s",
              "duration label is deterministic");
      Assert (To_String (Snapshot.Latest_Build_Result_Duration_Label) =
                "duration 4.3 s",
              "render snapshot exposes elapsed build duration");
   end Test_Summary_Records_Duration;

   procedure Test_Summary_Records_Timeout_Cancel_And_Truncation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Timeout : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Timed_Out => True);
      Cancel : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Cancelled,
           Cancelled => True);
      Truncated : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated,
           Stdout_Truncated => True);
   begin
      Assert (Timeout.Timed_Out, "timeout summary records timeout flag");
      Assert (Timeout.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
              "timeout maps to timeout kind");
      Assert (Cancel.Cancelled, "cancel summary records cancellation flag");
      Assert (Cancel.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Cancelled,
              "cancel maps to cancelled kind");
      Assert (Truncated.Stdout_Truncated and then not Truncated.Output_Partial,
              "truncation flags stay separate from partial-output state");
      Assert (Editor.Build_Result_Summary.Truncation_Label (Truncated) =
                "stdout truncated",
              "truncation label is deterministic");
   end Test_Summary_Records_Timeout_Cancel_And_Truncation;

   procedure Test_Summary_Does_Not_Own_Forbidden_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 1,
           Has_Exit_Code => True);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Summary_Is_Transient_Projection (S),
              "summary contains no process handle, token, rerun payload, diagnostics rows, or unbounded output field");
      Assert (not Editor.Build_Result_Summary.Has_Process_Handle_Field (S),
              "summary has no process handle field");
      Assert (not Editor.Build_Result_Summary.Has_Cancellation_Token_Field (S),
              "summary has no cancellation token field");
      Assert (not Editor.Build_Result_Summary.Has_Rerun_Request_Payload_Field (S),
              "summary has no rerun request payload field");
      Assert (not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field (S),
              "summary has no diagnostics rows field");
      Assert (not Editor.Build_Result_Summary.Has_Unbounded_Output_Field (S),
              "summary has no unbounded output field");
   end Test_Summary_Does_Not_Own_Forbidden_State;

   procedure Test_Executor_Build_Path_Updates_Unavailable_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "unavailable public build remains unavailable");
      Assert (S.Latest_Build_Result.Has_Result,
              "Executor/build path records unavailable latest summary");
      Assert (S.Latest_Build_Result.Kind =
                Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              "unavailable invocation maps to unavailable summary");
      Assert (To_String (S.Latest_Build_Result.Primary_Message)'Length > 0,
              "summary carries the primary message as display projection");
   end Test_Executor_Build_Path_Updates_Unavailable_Summary;



   procedure Test_Summary_Records_Failure_Spawn_And_Cancellation_Unsupported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Failed : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 2,
           Has_Exit_Code => True);
      Spawn_Failure : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "execution error",
           Primary_Message => "Build failed: execution error");
      Unsupported : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "cancellation unsupported",
           Primary_Message => "Build unavailable: cancellation unsupported",
           Cancellation_Unsupported => True);
   begin
      Assert (Failed.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Failed,
              "failed exit records failed summary kind");
      Assert (Failed.Has_Exit_Code and then Failed.Exit_Code_If_Available = 2,
              "failed exit preserves available exit code");
      Assert (To_String (Spawn_Failure.Runner_Status_Label) = "execution error",
              "spawn failure preserves runner status as display-only text");
      Assert (Unsupported.Cancellation_Unsupported,
              "cancellation unsupported records deterministic status flag");
      Assert (not Unsupported.Has_Exit_Code,
              "cancellation unsupported/unavailable summary has no exit code");
   end Test_Summary_Records_Failure_Spawn_And_Cancellation_Unsupported;

   procedure Test_Summary_Records_Diagnostics_Status_Count_And_Disabled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Ingested : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; diagnostics ingested",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 3,
           Has_Diagnostics_Count => True,
           Diagnostics_Error_Count => 1,
           Diagnostics_Warning_Count => 1,
           Diagnostics_Info_Count => 1,
           Has_Diagnostics_Severity_Counts => True);
      Disabled : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled);
   begin
      Assert (Ingested.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
              "summary records diagnostics ingestion succeeded status");
      Assert (Ingested.Has_Diagnostics_Count
              and then Ingested.Diagnostics_Count_If_Available = 3,
              "summary records diagnostics count only, not rows");
      Assert (Ingested.Has_Diagnostics_Severity_Counts
              and then Ingested.Diagnostics_Error_Count = 1
              and then Ingested.Diagnostics_Warning_Count = 1
              and then Ingested.Diagnostics_Info_Count = 1
              and then Ingested.Diagnostics_Note_Count = 0,
              "summary records scalar diagnostics severity counts without rows");
      Assert (Editor.Build_Result_Summary.Diagnostics_Label (Disabled) =
                "Diagnostics ingestion disabled.",
              "diagnostics-disabled build clears prior diagnostics status/count");
      Assert (not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field (Ingested),
              "summary does not own diagnostics rows");
   end Test_Summary_Records_Diagnostics_Status_Count_And_Disabled;

   procedure Test_Replacement_Is_Latest_Only_And_Clears_Previous_Flags
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived,
           Working_Context_Label => "candidate project root",
           Runner_Status_Label => "timed out",
           Primary_Message => "Build timed out",
           Timed_Out => True,
           Stdout_Truncated => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True);
      Next : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_Alire_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "manual project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Exit_Code => 0,
           Has_Exit_Code => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled);
      Replaced : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary (Previous, Next);
   begin
      Assert (Replaced.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
              "latest summary is replaced, not appended");
      Assert (not Replaced.Timed_Out and then not Replaced.Stdout_Truncated,
              "latest replacement clears prior timeout/truncation flags");
      Assert (Replaced.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled,
              "latest replacement clears prior diagnostics ingestion status");
      Assert (Replaced.Request_Mode =
                Editor.Build_Result_Summary.Build_Result_Request_Manual,
              "latest replacement clears prior candidate/manual provenance");
      Assert (not Editor.Build_Result_Summary.Has_Build_History_Field (Replaced),
              "summary package exposes no build history field");
   end Test_Replacement_Is_Latest_Only_And_Clears_Previous_Flags;

   procedure Test_Unavailable_Retention_Policy_And_Content_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Summary_From_Unavailable_Message
          ("Build unavailable: consent required.");
   begin
      Assert (Editor.Build_Result_Summary.Retain_Pre_Run_Unavailable_Summary,
              "explicitly retains pre-run unavailable summaries");
      Assert (S.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              "unavailable attempts map to unavailable summary");
      Assert (not S.Has_Exit_Code,
              "unavailable summary has no exit code");
      Assert (not S.Stdout_Truncated and then not S.Stderr_Truncated
              and then not S.Output_Partial,
              "unavailable summary has no runner output flags");
      Assert (S.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested,
              "unavailable summary has no diagnostics ingestion");
   end Test_Unavailable_Retention_Policy_And_Content_Bounds;

   procedure Test_Render_Snapshot_Is_Display_Only_And_Forbidden_State_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 9,
           Has_Exit_Code => True,
           Stdout_Truncated => True);
      Snapshot : constant Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot :=
        Editor.Build_Result_Summary.Render_Snapshot (S);
   begin
      Assert (Snapshot.Latest_Build_Result_Visible,
              "render consumes summary snapshot only");
      Assert (To_String (Snapshot.Latest_Build_Result_Exit_Code_Label) = " 9",
              "render snapshot receives precomputed exit-code label");
      Assert (To_String (Snapshot.Latest_Build_Result_Truncation_Label) =
                "stdout truncated",
              "render snapshot receives precomputed truncation label");
      Assert (Editor.Build_Result_Summary.Assert_Summary_Is_Transient_Projection (S),
              "rendered summary remains free of process/token/rerun/output/history ownership");
   end Test_Render_Snapshot_Is_Display_Only_And_Forbidden_State_Free;


   procedure Test_Canonicalizer_Clears_Stale_Display_Facts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Malformed : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_Alire_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded",
           Exit_Code => 77,
           Has_Exit_Code => False,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled,
           Diagnostics_Count => 9,
           Has_Diagnostics_Count => True);
      Canonical : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Canonicalize_Latest_Build_Result_Summary
          (Malformed);
   begin
      Assert (Canonical.Has_Result,
              "canonicalized summary remains a represented latest result");
      Assert (not Canonical.Has_Exit_Code
              and then Canonical.Exit_Code_If_Available = 0,
              "canonicalization clears stale unavailable exit code");
      Assert (not Canonical.Has_Diagnostics_Count
              and then Canonical.Diagnostics_Count_If_Available = 0,
              "canonicalization clears stale diagnostics count when disabled");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Shape_Canonical
                (Canonical),
              "canonicalized summary satisfies the shape contract");
   end Test_Canonicalizer_Clears_Stale_Display_Facts;

   procedure Test_Rerun_Diagnostics_Output_Process_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 4,
           Has_Exit_Code => True,
           Stdout_Truncated => True);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Rerun_State
                (S),
              "summary cannot be used as rerun payload or consent state");
      Assert (not Editor.Build_Result_Summary.Summary_Can_Be_Converted_To_Public_Build_Request
                (S),
              "summary is not convertible to a public build request");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
                (S),
              "summary stores diagnostics scalar facts only, not rows/tables");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Output_Log
                (S),
              "summary is not stdout/stderr output log ownership");
      Assert (not Editor.Build_Result_Summary.Has_Process_Handle_Field (S)
              and then not Editor.Build_Result_Summary.Has_Cancellation_Token_Field (S),
              "summary exposes no process-control state");
   end Test_Rerun_Diagnostics_Output_Process_Boundaries;

   procedure Test_Milestone_Canonical_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Timed_Out => True,
           Stdout_Truncated => True);
      Next : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 5,
           Has_Exit_Code => True);
      Replaced : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (Previous, Next);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Replace_Only
                (Previous, Next),
              "replacement helper is latest-only and non-historical");
      Assert (Replaced.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Failed
              and then not Replaced.Timed_Out
              and then not Replaced.Stdout_Truncated,
              "replacement does not retain timeout/truncation caches");
      Assert (Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Canonical_Coherent
                (Replaced),
              "public build result surface canonical coherence holds");
   end Test_Milestone_Canonical_Coherence;


   procedure Test_Final_Mapping_Freeze_For_All_Result_Kinds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Success : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True);
      Failed : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Exit_Code => 7,
           Has_Exit_Code => True);
      Unavailable : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Summary_From_Unavailable_Message
          ("Build unavailable: consent required.");
      Timeout : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Timed_Out => True,
           Stdout_Truncated => True);
      Cancelled : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Summary
          (Editor.Build_Result_Summary.Build_Result_Summary_Cancelled,
           Cancelled => True);
      Unsupported : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_No_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_None,
           Working_Context_Label => "",
           Runner_Status_Label => "cancellation unsupported",
           Primary_Message => "Build unavailable: cancellation unsupported",
           Cancellation_Unsupported => True);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Success),
              "freezes success summary mapping");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Failed),
              "freezes failed-exit summary mapping");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Unavailable),
              "freezes pre-run unavailable summary mapping");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Timeout),
              "freezes timeout summary mapping");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Cancelled),
              "freezes cancellation summary mapping");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Unsupported),
              "freezes cancellation-unsupported summary mapping");
      Assert (Unsupported.Cancellation_Unsupported
              and then not Unsupported.Has_Exit_Code,
              "cancellation unsupported remains display-only with no process state");
   end Test_Final_Mapping_Freeze_For_All_Result_Kinds;

   procedure Test_Final_Replace_Only_Clears_All_Prior_Facts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived,
           Working_Context_Label => "candidate project root",
           Runner_Status_Label => "timed out",
           Primary_Message => "Build timed out",
           Timed_Out => True,
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 6,
           Has_Diagnostics_Count => True);
      Next : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Summary_From_Unavailable_Message
          ("Build unavailable: execution backend disabled.");
      Replaced : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (Previous, Next);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Replace_Only_Frozen
                (Previous, Next),
              "freezes latest-only replacement semantics");
      Assert (Replaced.Kind = Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              "new represented result replaces previous status");
      Assert (not Replaced.Timed_Out
              and then not Replaced.Stdout_Truncated
              and then not Replaced.Stderr_Truncated
              and then not Replaced.Output_Partial,
              "unavailable replacement clears prior timeout/truncation facts");
      Assert (Replaced.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested
              and then not Replaced.Has_Diagnostics_Count,
              "Diagnostics summary is replaced, not accumulated");
      Assert (Replaced.Request_Mode =
                Editor.Build_Result_Summary.Build_Result_Request_None
              and then Replaced.Tool_Kind =
                Editor.Build_Result_Summary.Build_Result_No_Tool,
              "manual/candidate provenance is replaced, not cached");
   end Test_Final_Replace_Only_Clears_All_Prior_Facts;

   procedure Test_Final_Boundary_Coherence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_Alire_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; diagnostics ingested",
           Exit_Code => 0,
           Has_Exit_Code => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 2,
           Has_Diagnostics_Count => True);
   begin
      Assert (Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
                (S),
              "final result surface freeze helper is coherent");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State
                (S),
              "summary cannot be converted into a rerun request");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Process_Control
                (S),
              "summary has no process handle or cancellation token");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Output_Log
                (S),
              "summary is not an output log");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
                (S),
              "summary copies only Diagnostics scalar facts");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_No_History
                (S),
              "summary exposes no build history cache");
   end Test_Final_Boundary_Coherence_Freeze;

   procedure Test_Render_And_Availability_Do_Not_Update_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.State.State_Type;
      Before : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        State.Latest_Build_Result;
      Snapshot : Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot;
   begin
      Snapshot := Editor.Build_Result_Summary.Render_Snapshot
        (State.Latest_Build_Result);
      Assert (not Snapshot.Latest_Build_Result_Visible,
              "empty render snapshot is display-only");
      Assert (State.Latest_Build_Result.Has_Result = Before.Has_Result
              and then State.Latest_Build_Result.Kind = Before.Kind,
              "render does not mutate latest summary");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Render_Boundary
                (State.Latest_Build_Result),
              "render boundary remains side-effect-free");
      declare
         Availability : constant Editor.Commands.Command_Availability :=
           Editor.Build_Command.Build_Run_Availability (State);
         pragma Unreferenced (Availability);
      begin
         Assert (State.Latest_Build_Result.Has_Result = Before.Has_Result
                 and then State.Latest_Build_Result.Kind = Before.Kind,
                 "availability/frontdoor checks do not update latest summary");
      end;
   end Test_Render_And_Availability_Do_Not_Update_Summary;

   procedure Test_Executor_Path_Is_Only_Update_Path_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Assert (not State.Latest_Build_Result.Has_Result,
              "fresh runtime state has no restored latest result");
      Result := Editor.Build_Command.Execute_Public_Build_Run (State);
      Assert (Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Not_Available,
              "test exercises pre-run unavailable Executor/build outcome");
      Assert (State.Latest_Build_Result.Has_Result,
              "Executor/build outcome path creates latest summary");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Ownership_Frozen
                (State.Latest_Build_Result),
              "latest summary ownership is frozen to Executor/build outcome path");
      Assert (Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
                (State.Latest_Build_Result),
              "Executor-created unavailable summary satisfies final freeze contract");
   end Test_Executor_Path_Is_Only_Update_Path_Freeze;


   procedure Test_No_Diagnostics_Keeps_Explicit_Zero_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      No_Diagnostics : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; no diagnostics recognized",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => True);
      Canonical : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Canonicalize_Latest_Build_Result_Summary
          (No_Diagnostics);
   begin
      Assert (Canonical.Has_Diagnostics_Count
              and then Canonical.Diagnostics_Count_If_Available = 0,
              "keeps an explicit zero diagnostics count when ingestion ran");
      Assert (not Canonical.Has_Diagnostics_Severity_Counts
              and then Canonical.Diagnostics_Error_Count = 0
              and then Canonical.Diagnostics_Warning_Count = 0
              and then Canonical.Diagnostics_Info_Count = 0
              and then Canonical.Diagnostics_Note_Count = 0
              and then Canonical.Diagnostics_Unknown_Count = 0,
              "zero-diagnostics summary carries no stale severity counters");
      Assert (Editor.Build_Result_Summary.Diagnostics_Label (Canonical) =
                "No diagnostics.",
              "zero-diagnostics result summary uses the product Diagnostics empty state");
      Assert (Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
                (Canonical),
              "zero-count summary satisfies final mapping invariants");
   end Test_No_Diagnostics_Keeps_Explicit_Zero_Count;

   procedure Test_Diagnostics_Status_Canonicalization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Zero_Succeeded : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; no diagnostics recognized",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => True);
      Partial_Zero : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; diagnostics parsing failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => True);
      Partial_Unknown_Count : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; diagnostics parsing state incomplete",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 0,
           Has_Diagnostics_Count => False);
      Partial_With_Row : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Succeeded,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "succeeded",
           Primary_Message => "Build succeeded; diagnostics parsed partially",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial,
           Diagnostics_Count => 1,
           Has_Diagnostics_Count => True,
           Diagnostics_Error_Count => 1,
           Has_Diagnostics_Severity_Counts => True);
   begin
      Assert (Zero_Succeeded.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics
              and then Zero_Succeeded.Has_Diagnostics_Count
              and then Zero_Succeeded.Diagnostics_Count_If_Available = 0,
              "canonicalizes succeeded zero diagnostics to no-diagnostics status");
      Assert (Partial_Zero.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed
              and then not Partial_Zero.Has_Diagnostics_Count,
              "rejects parse-partial summaries without produced rows");
      Assert (Partial_Unknown_Count.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed
              and then not Partial_Unknown_Count.Has_Diagnostics_Count,
              "rejects parse-partial summaries with unknown produced-row count");
      Assert (Partial_With_Row.Diagnostics_Ingestion_Status =
                Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial
              and then Partial_With_Row.Has_Diagnostics_Count
              and then Partial_With_Row.Diagnostics_Count_If_Available = 1
              and then Partial_With_Row.Has_Diagnostics_Severity_Counts,
              "keeps parse-partial summaries only when rows were produced");
   end Test_Diagnostics_Status_Canonicalization;

   procedure Test_Render_Snapshot_Exposes_Panel_Summary_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : constant Editor.Build_Result_Summary.Latest_Build_Result_Summary :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True,
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded,
           Diagnostics_Count => 2,
           Has_Diagnostics_Count => True,
           Diagnostics_Error_Count => 1,
           Diagnostics_Warning_Count => 1,
           Has_Diagnostics_Severity_Counts => True,
           Duration_Milliseconds => 4_250,
           Has_Duration => True);
      Snapshot : constant Editor.Build_Result_Summary.Latest_Build_Result_Render_Snapshot :=
        Editor.Build_Result_Summary.Render_Snapshot (S);
      Row : constant String :=
        To_String (Snapshot.Latest_Build_Result_Summary_Row_Label);
   begin
      Assert (Ada.Strings.Fixed.Index (Row, "Build failed") > 0,
              "summary row must include result status");
      Assert (Ada.Strings.Fixed.Index (Row, "build.run") > 0,
              "summary row must include command label");
      Assert (Ada.Strings.Fixed.Index (Row, "exit 1") > 0,
              "summary row must include exit code");
      Assert (Ada.Strings.Fixed.Index (Row, "duration 4.3 s") > 0,
              "summary row must include rounded duration");
      Assert (Ada.Strings.Fixed.Index (Row, "diagnostics 2") > 0,
              "summary row must include diagnostics count");
   end Test_Render_Snapshot_Exposes_Panel_Summary_Row;


   overriding procedure Register_Tests
     (T : in out Build_Result_Summary_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Summary_Has_No_Result'Access,
         "latest build result summary starts empty");
      Register_Routine
        (T, Test_Summary_Records_Success_And_Exit_Code'Access,
         "latest build result summary records success and exit code");
      Register_Routine
        (T, Test_Summary_Records_Duration'Access,
         "latest build result summary records elapsed duration");
      Register_Routine
        (T, Test_Summary_Records_Timeout_Cancel_And_Truncation'Access,
         "latest build result summary records timeout cancel and truncation");
      Register_Routine
        (T, Test_Summary_Does_Not_Own_Forbidden_State'Access,
         "latest build result summary owns no forbidden state");
      Register_Routine
        (T, Test_Executor_Build_Path_Updates_Unavailable_Summary'Access,
         "Executor build path updates unavailable latest summary");

      Register_Routine
        (T, Test_Summary_Records_Failure_Spawn_And_Cancellation_Unsupported'Access,
         "latest build result summary records failure spawn and cancellation unsupported");
      Register_Routine
        (T, Test_Summary_Records_Diagnostics_Status_Count_And_Disabled'Access,
         "latest build result summary records diagnostics status count and disabled");
      Register_Routine
        (T, Test_Replacement_Is_Latest_Only_And_Clears_Previous_Flags'Access,
         "latest build result summary replaces prior outcome without history");
      Register_Routine
        (T, Test_Unavailable_Retention_Policy_And_Content_Bounds'Access,
         "latest build result summary unavailable retention policy is explicit");
      Register_Routine
        (T, Test_Render_Snapshot_Is_Display_Only_And_Forbidden_State_Free'Access,
         "latest build result render snapshot is display-only and forbidden-state free");
      Register_Routine
        (T, Test_Canonicalizer_Clears_Stale_Display_Facts'Access,
         "canonicalizer clears stale latest-result fields");
      Register_Routine
        (T, Test_Rerun_Diagnostics_Output_Process_Boundaries'Access,
         "latest summary boundary cleanup holds");
      Register_Routine
        (T, Test_Milestone_Canonical_Coherence'Access,
         "latest result surface canonical coherence holds");

      Register_Routine
        (T, Test_Final_Mapping_Freeze_For_All_Result_Kinds'Access,
         "final latest result mapping freeze holds");
      Register_Routine
        (T, Test_Final_Replace_Only_Clears_All_Prior_Facts'Access,
         "final latest result replacement freeze holds");
      Register_Routine
        (T, Test_Final_Boundary_Coherence_Freeze'Access,
         "final latest result boundary coherence holds");
      Register_Routine
        (T, Test_No_Diagnostics_Keeps_Explicit_Zero_Count'Access,
         "no-diagnostics summary keeps explicit zero count");
      Register_Routine
        (T, Test_Diagnostics_Status_Canonicalization'Access,
         "diagnostics status canonicalization is coherent");
      Register_Routine
        (T, Test_Render_Snapshot_Exposes_Panel_Summary_Row'Access,
         "latest build result render exposes a panel summary row");
      Register_Routine
        (T, Test_Render_And_Availability_Do_Not_Update_Summary'Access,
         "render/frontdoor non-ownership freeze holds");
      Register_Routine
        (T, Test_Executor_Path_Is_Only_Update_Path_Freeze'Access,
         "Executor-only update path freeze holds");

   end Register_Tests;

end Editor.Build_Result_Summary.Tests;
