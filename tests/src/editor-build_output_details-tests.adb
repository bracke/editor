with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.External_Producers;
with Editor.State;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Build_Runner_Policy;
with Editor.Build_Command;
with Editor.Build_Candidates;
with Editor.Build_Output_Details_Audit;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Input_Bridge;
with Editor.Keybindings;

package body Editor.Build_Output_Details.Tests is

   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Build_Output_Details.Build_Output_Stream_Selection;
   use type Editor.Commands.Command_Id;
   use type Editor.Build_Result_Summary.Build_Result_Summary_Kind;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.Build_Runner_Policy.Build_Execution_Policy;
   use type Editor.Command_Execution.Command_Execution_Status;

   overriding function Name
     (T : Build_Output_Details_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Output_Details");
   end Name;

   function Repeat (C : Character; Count : Natural) return String is
      Result : String (1 .. Count);
   begin
      for I in Result'Range loop
         Result (I) := C;
      end loop;
      return Result;
   end Repeat;

   function Details_From_Output
     (Status : Editor.Build_Output_Details.Build_Output_Runner_Status;
      Stdout_Text : String := "";
      Stderr_Text : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial : Boolean := False;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False)
      return Editor.Build_Output_Details.Latest_Build_Output_Details
   is
   begin
      return Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
        (Runner_Status => Status,
         Stdout_Text => To_Unbounded_String (Stdout_Text),
         Stderr_Text => To_Unbounded_String (Stderr_Text),
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated,
         Output_Partial => Output_Partial,
         Exit_Code => Exit_Code,
         Has_Exit_Code => Has_Exit_Code);
   end Details_From_Output;

   function Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key => Code,
         Modifiers =>
           (Ctrl => False, Alt => False, Shift => False, Meta => False));
   end Key;

   function Ready_State return Editor.State.State_Type is
      S : Editor.State.State_Type;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
   begin
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Editor.Build_UI.Show (S.Build_UI);
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, To_String (Candidate.Candidate_Id));
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      return S;
   end Ready_State;

   procedure Test_Output_Details_Absent_Before_First_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Empty_Output_Details;
   begin
      Assert (not Details.Has_Output_Details,
              "output details start absent before a represented build outcome");
      Assert (Details.Kind = Editor.Build_Output_Details.Build_Output_Details_None,
              "empty details use none kind");
      Assert (Editor.Build_Output_Details.Status_Label (Details) =
                "No build output captured.",
              "empty details label is deterministic");
   end Test_Output_Details_Absent_Before_First_Result;

   procedure Test_Success_And_Failure_Create_Bounded_Output_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Success : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Stdout_Text => "ok", Exit_Code => 0, Has_Exit_Code => True);
      Failure : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stderr_Text => "src/main.adb:1:1: error: failed",
              Exit_Code => 1, Has_Exit_Code => True);
   begin
      Assert (Success.Has_Output_Details and then Success.Stdout_Available,
              "successful build creates latest stdout details when captured");
      Assert (To_String (Success.Stdout_Excerpt) = "ok",
              "stdout excerpt comes from bounded runner capture");
      Assert (Failure.Has_Output_Details and then Failure.Stderr_Available,
              "failed build creates latest stderr details when captured");
      Assert (To_String (Failure.Stderr_Excerpt) =
                "src/main.adb:1:1: error: failed",
              "stderr excerpt comes from bounded runner capture");
      Assert (Editor.Build_Output_Details.Assert_Build_Output_Details_Bounded
                (Failure),
              "captured output details remain bounded");
   end Test_Success_And_Failure_Create_Bounded_Output_Details;

   procedure Test_Timeout_And_Cancelled_Output_Are_Marked_Partial
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Timeout : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out,
              Stdout_Text => "partial stdout");
      Cancelled : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
              Stderr_Text => "partial stderr");
   begin
      Assert (Timeout.Kind = Editor.Build_Output_Details.Build_Output_Details_Partial
              and then Timeout.Timed_Out and then Timeout.Output_Partial,
              "timeout captured output is marked partial");
      Assert (Editor.Build_Output_Details.Partial_Output_Label (Timeout) =
                "partial output: build timed out",
              "timeout details have timeout partial marker");
      Assert (Cancelled.Kind = Editor.Build_Output_Details.Build_Output_Details_Partial
              and then Cancelled.Cancelled and then Cancelled.Output_Partial,
              "cancelled captured output is marked partial");
      Assert (Editor.Build_Output_Details.Partial_Output_Label (Cancelled) =
                "partial output: build cancelled",
              "cancelled details have cancellation partial marker");
   end Test_Timeout_And_Cancelled_Output_Are_Marked_Partial;

   procedure Test_Truncation_And_Display_Bounds_Are_Marked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Long_Output : constant String :=
        Repeat ('x', Editor.Build_Output_Details.Max_Build_Output_Detail_Excerpt_Bytes + 16);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stdout_Text => Long_Output,
              Stderr_Text => "err",
              Stdout_Truncated => True,
              Exit_Code => 1,
              Has_Exit_Code => True);
   begin
      Assert (Details.Kind = Editor.Build_Output_Details.Build_Output_Details_Truncated,
              "runner/display truncation maps to truncated details kind");
      Assert (Length (Details.Stdout_Excerpt) =
                Editor.Build_Output_Details.Max_Build_Output_Detail_Excerpt_Bytes,
              "stdout excerpt is secondarily bounded for display");
      Assert (Details.Stdout_Truncated and then Details.Stdout_Display_Truncated,
              "stdout truncation markers preserve runner and display bounds");
      Assert (Editor.Build_Output_Details.Stdout_Truncation_Label (Details) =
                "stdout runner/display truncated",
              "stdout truncation label is deterministic");
   end Test_Truncation_And_Display_Bounds_Are_Marked;

   procedure Test_Replacement_Is_Latest_Only_And_Clears_Prior_Output
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stderr_Text => "old stderr", Stderr_Truncated => True);
      Next : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Stdout_Text => "new stdout", Exit_Code => 0, Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Previous, Next);
   begin
      Assert (Replaced.Stdout_Available and then not Replaced.Stderr_Available,
              "latest output details are replaced, not appended");
      Assert (To_String (Replaced.Stdout_Excerpt) = "new stdout",
              "new stdout replaces prior stderr output");
      Assert (not Replaced.Stderr_Truncated,
              "prior stderr truncation flag is cleared by replacement");
      Assert (Editor.Build_Output_Details.Assert_Build_Output_Details_Replace_Only
                (Previous, Next),
              "replace-only helper rejects history semantics");
   end Test_Replacement_Is_Latest_Only_And_Clears_Prior_Output;

   procedure Test_Details_Do_Not_Own_Forbidden_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stderr_Text => "error");
   begin
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Foundation_Coherent
                (Details),
              "details contain no process handle, token, rerun payload, diagnostics rows, history, or persistence field");
      Assert (not Editor.Build_Output_Details.Has_Process_Handle_Field (Details),
              "details have no process handle");
      Assert (not Editor.Build_Output_Details.Has_Cancellation_Token_Field (Details),
              "details have no cancellation token");
      Assert (not Editor.Build_Output_Details.Has_Rerun_Request_Payload_Field (Details),
              "details have no rerun payload");
      Assert (not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field (Details),
              "details do not own Diagnostics rows");
      Assert (not Editor.Build_Output_Details.Has_Persistence_Field (Details),
              "details have no persistence field");
   end Test_Details_Do_Not_Own_Forbidden_State;

   procedure Test_Render_Snapshot_Consumes_Details_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stdout_Text => "out", Stderr_Text => "err");
   begin
      Editor.Build_Output_Details.Show_Output_Details (Details);
      Editor.Build_Output_Details.Select_Output_Stream
        (Details, Editor.Build_Output_Details.Build_Output_Stream_Stdout);
      declare
         Snapshot : constant Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot :=
           Editor.Build_Output_Details.Render_Snapshot (Details);
      begin
         Assert (Snapshot.Output_Details_Visible,
                 "render snapshot follows transient visibility flag");
         Assert (Snapshot.Output_Details_Available,
                 "render snapshot exposes availability only from details snapshot");
         Assert (To_String (Snapshot.Stdout_Excerpt) = "out",
                 "render snapshot carries bounded stdout excerpt");
         Assert (To_String (Snapshot.Stderr_Excerpt) = "err",
                 "render snapshot carries bounded stderr excerpt");
         Assert (Snapshot.Selected_Output_Stream =
                   Editor.Build_Output_Details.Build_Output_Stream_Stdout,
                 "stream selection is transient display state");
      end;
   end Test_Render_Snapshot_Consumes_Details_Only;

   procedure Test_Executor_Updates_Output_Details_And_Keeps_Summary_Compact
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "incomplete public command remains unavailable before runner execution");
      Assert (S.Latest_Build_Result.Has_Result,
              "Executor updates latest compact summary");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details,
              "Executor also replaces latest output details");
      Assert (S.Latest_Build_Result.Kind =
                Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              "summary remains a compact status projection");
      Assert (not Editor.Build_Result_Summary.Has_Full_Stdout_Field
                (S.Latest_Build_Result),
              "summary still does not store full stdout");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Foundation_Coherent
                (S.Latest_Build_Output_Details),
              "output details remain bounded/transient after Executor update");
   end Test_Executor_Updates_Output_Details_And_Keeps_Summary_Compact;

   procedure Test_Output_Details_Visibility_Does_Not_Mutate_Output
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stdout_Text => "out", Stderr_Text => "err");
   begin
      Editor.Build_Output_Details.Focus_Output_Details (Details);
      Editor.Build_Output_Details.Hide_Output_Details (Details);
      Editor.Build_Output_Details.Select_Output_Stream
        (Details, Editor.Build_Output_Details.Build_Output_Stream_Stderr);
      Assert (To_String (Details.Stdout_Excerpt) = "out"
              and then To_String (Details.Stderr_Excerpt) = "err",
              "visibility/focus/stream changes never mutate captured output");
      Assert (not Details.Build_Output_Details_Visible
              and then not Details.Build_Output_Details_Focused,
              "hide clears transient output-details focus only");
   end Test_Output_Details_Visibility_Does_Not_Mutate_Output;

   procedure Test_Output_Details_Commands_And_Focused_Keyboard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Result_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Unavailable,
              "build result focus is unavailable before a result exists");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Output_Details_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Unavailable,
              "output details focus is unavailable before output exists");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "gprbuild editor.gpr",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "project",
           Runner_Status_Label => "failed",
           Primary_Message => "build failed",
           Diagnostics_Ingestion_Status =>
             Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded);
      S.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "stdout",
           Stderr_Text => "stderr");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("build.output-details.select-stdout", Found);
      Assert (Found
              and then Id =
                Editor.Commands.Command_Build_Output_Details_Select_Stdout,
              "output details stdout command has a stable id");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Result_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "build result focus routes through Executor");
      Assert (S.Latest_Build_Result_Focused,
              "build result focus command focuses the result surface");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Output_Details_Focus);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "output details focus routes through Executor");
      Assert (S.Latest_Build_Output_Details.Build_Output_Details_Focused,
              "output details focus command focuses the details surface");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Output_Details_Select_Stdout);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed
              and then S.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Stdout,
              "stdout selection command updates the selected output stream");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Output_Details_Select_Stderr);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed
              and then S.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Stderr,
              "stderr selection command updates the selected output stream");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Output_Details_Select_Merged);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed
              and then S.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Merged,
              "merged selection command updates the selected output stream");

      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := False;
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Latest_Build_Output_Details.Build_Output_Details_Focused
              and then not After.Latest_Build_Result_Focused,
              "Enter on focused result moves focus to output details");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Left));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Stdout,
              "Left selects stdout while output details are focused");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Right));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Stderr,
              "Right selects stderr while output details are focused");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Latest_Build_Output_Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Merged,
              "Down selects merged output while output details are focused");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not After.Latest_Build_Result_Focused
              and then not
                After.Latest_Build_Output_Details.Build_Output_Details_Focused,
              "Escape returns build result/details focus to editor text");
   end Test_Output_Details_Commands_And_Focused_Keyboard;

   procedure Test_Unavailable_Details_Are_Not_History_Or_Output_Log
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Unavailable_Output_Details
          ("Build unavailable: execution backend disabled.");
   begin
      Assert (Details.Has_Output_Details,
              "unavailable represented build gets a replace-only unavailable details marker");
      Assert (Details.Kind = Editor.Build_Output_Details.Build_Output_Details_Unavailable,
              "unavailable marker does not imply captured output");
      Assert (not Details.Stdout_Available and then not Details.Stderr_Available,
              "unavailable details carry no output excerpts");
      Assert (not Editor.Build_Output_Details.Has_Build_History_Field (Details),
              "unavailable details do not create history");
      Assert (not Editor.Build_Output_Details.Has_Unbounded_Output_Field (Details),
              "unavailable details do not create an output log");
   end Test_Unavailable_Details_Are_Not_History_Or_Output_Log;

   procedure Test_Output_Details_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Audit : Editor.Build_Output_Details_Audit.Build_Output_Details_Audit_Result;
   begin
      S.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
              Stdout_Text => "out", Stderr_Text => "err",
              Exit_Code => 1, Has_Exit_Code => True);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True);
      Audit := Editor.Build_Output_Details_Audit.Run_Build_Output_Details_Audit (S);
      Assert (Audit.Coherent,
              "output-details audit confirms transient bounded non-owner boundaries");
      Assert (Audit.Summary_Remains_Compact,
              "audit also confirms compact summary remains intact");
   end Test_Output_Details_Audit_Coherent;


   procedure Test_No_Output_State_Is_Deterministic_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_No_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True);
   begin
      Assert (Details.Has_Output_Details,
              "no-output represented build still has deterministic details record");
      Assert (Details.Kind = Editor.Build_Output_Details.Build_Output_Details_Unavailable,
              "no-output details use unavailable/no-output state");
      Assert (not Details.Stdout_Available and then not Details.Stderr_Available,
              "no-output details fabricate neither stdout nor stderr");
      Assert (Length (Details.Stdout_Excerpt) = 0
              and then Length (Details.Stderr_Excerpt) = 0,
              "no-output details have empty stream excerpts");
      Assert (not Details.Stdout_Truncated and then not Details.Stderr_Truncated,
              "no-output details clear truncation flags");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Reliability_Coherent
                (Details),
              "no-output details remain reliable and bounded");
   end Test_No_Output_State_Is_Deterministic_And_Bounded;

   procedure Test_Stale_Stream_Fields_Clear_Across_Replacement_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Stdout_Only : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Stdout_Text => "stdout one", Stdout_Truncated => True);
      Stderr_Only : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stderr_Text => "stderr two", Stderr_Truncated => True,
           Exit_Code => 1, Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details_Reliably
          (Stdout_Only, Stderr_Only);
   begin
      Assert (not Replaced.Stdout_Available
              and then Length (Replaced.Stdout_Excerpt) = 0,
              "stdout-only build followed by stderr-only build clears stdout");
      Assert (Replaced.Stderr_Available
              and then To_String (Replaced.Stderr_Excerpt) = "stderr two",
              "latest stderr-only output is retained");
      Assert (not Replaced.Stdout_Truncated
              and then not Replaced.Stdout_Display_Truncated,
              "prior stdout truncation markers are cleared");
      Assert (Replaced.Stderr_Truncated,
              "latest stderr truncation marker is retained");
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Stale_Fields_Cleared
                (Stdout_Only, Stderr_Only),
              "stale-field assertion covers stream replacement");
   end Test_Stale_Stream_Fields_Clear_Across_Replacement_Families;

   procedure Test_Truncated_And_Partial_Markers_Clear_On_Later_Complete_Output
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Timeout : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_Partial_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out,
           To_Unbounded_String ("partial"),
           To_Unbounded_String (""),
           Stdout_Truncated => True);
      Complete : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Stdout_Text => "complete", Exit_Code => 0, Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Timeout, Complete);
   begin
      Assert (not Replaced.Output_Partial
              and then not Replaced.Timed_Out
              and then not Replaced.Cancelled,
              "normal success clears prior timeout/cancel partial state");
      Assert (not Replaced.Stdout_Truncated
              and then not Replaced.Stderr_Truncated,
              "normal success clears prior truncation flags");
      Assert (Replaced.Kind = Editor.Build_Output_Details.Build_Output_Details_Available,
              "complete later output is available, not partial/truncated");
   end Test_Truncated_And_Partial_Markers_Clear_On_Later_Complete_Output;

   procedure Test_Pre_Run_Unavailable_Replaces_Output_With_Empty_Unavailable_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "old out", Stderr_Text => "old err",
           Exit_Code => 1, Has_Exit_Code => True);
      Unavailable : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Unavailable_Output_Details
          ("Build unavailable: consent required.");
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Previous, Unavailable);
   begin
      Assert (Replaced.Has_Output_Details,
              "pre-run unavailable has an explicit retained empty details marker");
      Assert (Replaced.Kind = Editor.Build_Output_Details.Build_Output_Details_Unavailable,
              "pre-run unavailable replaces prior output with unavailable/no-output details");
      Assert (not Replaced.Stdout_Available
              and then not Replaced.Stderr_Available,
              "pre-run unavailable fabricates no captured streams");
      Assert (Length (Replaced.Stdout_Excerpt) = 0
              and then Length (Replaced.Stderr_Excerpt) = 0,
              "pre-run unavailable clears prior stdout/stderr excerpts");
   end Test_Pre_Run_Unavailable_Replaces_Output_With_Empty_Unavailable_State;

   procedure Test_Reliability_Helper_Reasserts_All_Output_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
           Stdout_Text => "partial out", Stderr_Text => "partial err",
           Output_Partial => True);
   begin
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Not_History (Details),
              "details are not build history");
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Not_Rerun_State (Details),
              "details are not rerun state");
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Not_Process_Control (Details),
              "details are not process control");
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Not_Diagnostics_Owner (Details),
              "details are not Diagnostics ownership");
      Assert (Editor.Build_Output_Details.Assert_Output_Details_Persistence_Excluded (Details),
              "details remain excluded from persistence");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Reliability_Coherent
                (Details),
              "milestone reliability helper is coherent");
   end Test_Reliability_Helper_Reasserts_All_Output_Boundaries;



   procedure Test_Canonical_Shape_Removes_Log_Rerun_Process_Diagnostics_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "bounded stdout",
           Stderr_Text => "bounded stderr",
           Exit_Code => 1,
           Has_Exit_Code => True);
   begin
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Shape_Canonical
                (Details),
              "output details shape is bounded display-only state");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Rerun_State
                (Details),
              "output details contain no request/consent/working-context rerun payload");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner
                (Details),
              "output details contain no Diagnostics row copy");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Output_Log
                (Details),
              "output details are not full logs, histories, or saved paths");
      Assert (not Editor.Build_Output_Details.Has_Process_Handle_Field (Details)
              and then not Editor.Build_Output_Details.Has_Cancellation_Token_Field (Details),
              "output details expose no process-control handles");
   end Test_Canonical_Shape_Removes_Log_Rerun_Process_Diagnostics_State;

   procedure Test_Canonical_Replacement_Drops_All_Previous_Stream_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out,
           Stdout_Text => "old partial stdout",
           Stderr_Text => "old partial stderr",
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Output_Partial => True);
      Next : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_No_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Previous, Next);
   begin
      Assert (Replaced.Has_Output_Details,
              "no-output replacement keeps one latest represented record");
      Assert (not Replaced.Stdout_Available
              and then not Replaced.Stderr_Available,
              "no-output replacement has no stream availability");
      Assert (Length (Replaced.Stdout_Excerpt) = 0
              and then Length (Replaced.Stderr_Excerpt) = 0,
              "no-output replacement clears both prior excerpts");
      Assert (not Replaced.Stdout_Truncated
              and then not Replaced.Stderr_Truncated
              and then not Replaced.Output_Partial,
              "no-output replacement clears prior truncation and partial flags");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Replace_Only
                (Previous, Next),
              "replacement is deterministic and non-historical");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_No_Output_Canonical
                (Replaced),
              "no-output state is explicit and canonical");
   end Test_Canonical_Replacement_Drops_All_Previous_Stream_State;

   procedure Test_Render_And_Audit_Do_Not_Own_Runtime_Output_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot;
      Before_Identity : Unbounded_String;
      Audit : Editor.Build_Output_Details_Audit.Build_Output_Details_Audit_Result;
   begin
      S.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "render stdout",
           Stderr_Text => "render stderr",
           Exit_Code => 1,
           Has_Exit_Code => True);
      Before_Identity := S.Latest_Build_Output_Details.Associated_Result_Identity;
      Snapshot := Editor.Build_Output_Details.Render_Snapshot
        (S.Latest_Build_Output_Details);
      Assert (To_String (Snapshot.Stdout_Excerpt) = "render stdout"
              and then To_String (Snapshot.Stderr_Excerpt) = "render stderr",
              "render snapshot consumes bounded fields already present");
      Assert (To_String (S.Latest_Build_Output_Details.Associated_Result_Identity) =
                To_String (Before_Identity),
              "render snapshot does not mutate output details identity");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Render_Cleanup
                (S.Latest_Build_Output_Details),
              "render cleanup assertion confirms snapshot-only behavior");

      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True);
      Audit := Editor.Build_Output_Details_Audit.Run_Build_Output_Details_Audit (S);
      Assert (Audit.Output_Details_Canonical_Coherent,
              "audit observes canonical output boundaries without owning runtime details");
      Assert (Audit.Coherent,
              "audit remains side-effect-free and coherent");
   end Test_Render_And_Audit_Do_Not_Own_Runtime_Output_Details;

   procedure Test_Executor_Path_Is_Only_State_Update_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "pre-run unavailable outcome is still represented through Executor path");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details,
              "Executor path replaces latest output details even for unavailable outcome");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Canonical_Coherent
                (S.Latest_Build_Output_Details),
              "Executor-updated output details are canonical and display-only");
      Assert (not S.Latest_Build_Output_Details.Stdout_Available
              and then not S.Latest_Build_Output_Details.Stderr_Available,
              "unavailable outcome fabricates no stdout/stderr from command messages");
   end Test_Executor_Path_Is_Only_State_Update_Surface;


   procedure Test_Final_Freeze_Shape_And_Mapping_All_Outcomes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Success : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Stdout_Text => "ok", Exit_Code => 0, Has_Exit_Code => True);
      Failure : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stderr_Text => "failed", Exit_Code => 1, Has_Exit_Code => True);
      Spawn_Failure : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Execution_Error,
           Stderr_Text => "spawn failed", Exit_Code => 0, Has_Exit_Code => False);
      Timeout : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Timed_Out,
           Stdout_Text => "partial", Output_Partial => True);
      Cancelled : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
           Stderr_Text => "cancel partial", Output_Partial => True);
      Cancellation_Unsupported : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported);
   begin
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Success),
              "final freeze accepts successful bounded stdout details");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Failure),
              "final freeze accepts failed bounded stderr details");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Spawn_Failure),
              "final freeze accepts retained bounded spawn-error details");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Timeout)
              and then Timeout.Output_Partial and then Timeout.Timed_Out,
              "timeout details are partial without process-control state");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Cancelled)
              and then Cancelled.Output_Partial and then Cancelled.Cancelled,
              "cancellation details are partial without cancellation token state");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (Cancellation_Unsupported)
              and then not Cancellation_Unsupported.Stdout_Available
              and then not Cancellation_Unsupported.Stderr_Available,
              "cancellation-unsupported details retain no process-control state");
   end Test_Final_Freeze_Shape_And_Mapping_All_Outcomes;

   procedure Test_Final_Freeze_No_Output_Clears_And_Fabricates_Nothing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "old stdout",
           Stderr_Text => "old stderr",
           Stdout_Truncated => True,
           Stderr_Truncated => True,
           Output_Partial => True,
           Exit_Code => 1,
           Has_Exit_Code => True);
      No_Output : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_No_Output_State
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Previous, No_Output);
   begin
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_No_Output_Frozen
                (Replaced),
              "no-output state is explicitly frozen");
      Assert (Length (Replaced.Stdout_Excerpt) = 0
              and then Length (Replaced.Stderr_Excerpt) = 0,
              "no-output state clears prior stdout/stderr excerpts");
      Assert (not Replaced.Stdout_Truncated
              and then not Replaced.Stderr_Truncated
              and then not Replaced.Output_Partial,
              "no-output state clears prior truncation/partial flags");
      Assert (To_String (Replaced.Stdout_Excerpt) /= "Build succeeded"
              and then To_String (Replaced.Stderr_Excerpt) /= "Build succeeded",
              "no-output state does not fabricate command-message output");
      Assert (not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field (Replaced),
              "no-output state does not copy Diagnostics rows");
   end Test_Final_Freeze_No_Output_Clears_And_Fabricates_Nothing;

   procedure Test_Final_Freeze_Replace_Only_No_History_Rerun_Log_Process
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Previous : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stderr_Text => "old failure", Exit_Code => 1, Has_Exit_Code => True);
      Next : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
           Stdout_Text => "new success", Exit_Code => 0, Has_Exit_Code => True);
      Replaced : constant Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (Previous, Next);
   begin
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Replace_Only_Frozen
                (Previous, Next),
              "replacement is final-frozen as latest-only");
      Assert (To_String (Replaced.Stdout_Excerpt) = "new success"
              and then Length (Replaced.Stderr_Excerpt) = 0,
              "replacement carries only latest represented output");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_No_History
                (Replaced),
              "details are not build or output history");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Rerun_State
                (Replaced),
              "details cannot be converted into rerun state");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Process_Control
                (Replaced),
              "details expose no process handle or cancellation token");
      Assert (Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Output_Log
                (Replaced),
              "details are bounded excerpts, not output logs");
   end Test_Final_Freeze_Replace_Only_No_History_Rerun_Log_Process;

   procedure Test_Final_Freeze_Summary_Frontdoor_And_Executor_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Assert (Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (S),
              "Command Palette boundary remains descriptor/Executor-only");
      Assert (Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary,
              "keybinding boundary remains command-name-only");
      Result := Editor.Build_Command.Execute_Public_Build_Run (S);
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Not_Available,
              "pre-run unavailable result is represented through Executor");
      Assert (Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
                (S.Latest_Build_Output_Details),
              "Executor-updated output details satisfy final freeze");
      Assert (Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
                (S.Latest_Build_Result),
              "preserves compact result-summary final freeze");
      Assert (not Editor.Build_Result_Summary.Has_Full_Stdout_Field
                (S.Latest_Build_Result)
              and then not Editor.Build_Result_Summary.Has_Full_Stderr_Field
                (S.Latest_Build_Result),
              "summary still does not store stdout/stderr excerpts");
   end Test_Final_Freeze_Summary_Frontdoor_And_Executor_Ownership;

   procedure Test_Final_Freeze_Render_Audit_Lifecycle_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Unbounded_String;
      Snapshot : Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot;
      Audit : Editor.Build_Output_Details_Audit.Build_Output_Details_Audit_Result;
      Restarted : Editor.State.State_Type;
   begin
      S.Latest_Build_Output_Details :=
        Details_From_Output
          (Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => "bounded out",
           Stderr_Text => "bounded err",
           Exit_Code => 1,
           Has_Exit_Code => True);
      S.Latest_Build_Result :=
        Editor.Build_Result_Summary.Build_Summary
          (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Failed,
           Invocation_Label => "build.run",
           Tool_Kind => Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool,
           Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Manual,
           Working_Context_Label => "current project root",
           Runner_Status_Label => "failed",
           Primary_Message => "Build failed",
           Exit_Code => 1,
           Has_Exit_Code => True);
      Before := S.Latest_Build_Output_Details.Associated_Result_Identity;
      Snapshot := Editor.Build_Output_Details.Render_Snapshot
        (S.Latest_Build_Output_Details);
      Assert (To_String (Snapshot.Stdout_Excerpt) = "bounded out"
              and then To_String (Snapshot.Stderr_Excerpt) = "bounded err",
              "render consumes already-built output-details snapshot");
      Assert (To_String (S.Latest_Build_Output_Details.Associated_Result_Identity) =
                To_String (Before),
              "render does not mutate latest output details");
      Audit := Editor.Build_Output_Details_Audit.Run_Build_Output_Details_Audit (S);
      Assert (Audit.Output_Details_Final_Freeze_Coherent
              and then Audit.Coherent,
              "audit observes final boundaries without mutating runtime state");
      Assert (Editor.Build_Command.Assert_Build_Run_Persistence_Excluded (S),
              "build command persistence exclusion remains intact");
      Assert (not Restarted.Latest_Build_Output_Details.Has_Output_Details,
              "fresh session/reload restores no output details");
   end Test_Final_Freeze_Render_Audit_Lifecycle_And_Persistence;



   procedure Test_Incremental_Build_Output_Stream_Produces_Bounded_Partial_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Stream : Editor.Build_Output_Details.Build_Output_Stream_State :=
        Editor.Build_Output_Details.Empty_Build_Output_Stream;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details;
   begin
      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (Stream, Job_Id => 7, Limit_Bytes => 8);
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream, Editor.Build_Output_Details.Build_Output_Stream_Stdout, "hello");
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream, Editor.Build_Output_Details.Build_Output_Stream_Stderr,
         "src/main.adb:1:1: error");

      Assert (Stream.Active and then Stream.Chunk_Count = 2,
              "stream records active incremental chunks");
      Assert (Editor.Build_Output_Details.Assert_Build_Output_Stream_Bounded (Stream),
              "stream stores only bounded excerpts while build is active");
      Assert (Stream.Stderr_Truncated,
              "over-limit stderr chunk marks stream truncation explicitly");

      Details := Editor.Build_Output_Details.Build_Output_Details_From_Stream
        (Stream,
         Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
         Output_Partial => True);
      Assert (Details.Kind = Editor.Build_Output_Details.Build_Output_Details_Partial
              and then Details.Output_Partial,
              "active stream projects as partial latest output details");
      Assert (To_String (Details.Stdout_Excerpt) = "hello"
              and then To_String (Details.Stderr_Excerpt) = "src/main",
              "partial output details expose bounded stdout/stderr excerpts");

      Editor.Build_Output_Details.Finish_Build_Output_Stream (Stream);
      Details := Editor.Build_Output_Details.Build_Output_Details_From_Stream
        (Stream,
         Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
         Output_Partial => False,
         Exit_Code => 1,
         Has_Exit_Code => True);
      Assert (not Details.Output_Partial
              and then Details.Kind = Editor.Build_Output_Details.Build_Output_Details_Truncated,
              "finished stream becomes final bounded output, not an active partial stream");
   end Test_Incremental_Build_Output_Stream_Produces_Bounded_Partial_Details;


   procedure Test_Merged_Output_Provenance_Is_Rendered_As_Merged
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Failed,
           Stdout_Text => To_Unbounded_String ("merged compiler output"),
           Stderr_Text => Null_Unbounded_String,
           Output_Stream => Editor.Build_Output_Details.Build_Output_Stream_Merged);
      Snapshot : Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot;
   begin
      Editor.Build_Output_Details.Show_Output_Details (Details);
      Snapshot := Editor.Build_Output_Details.Render_Snapshot (Details);

      Assert (Details.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Merged,
              "merged output details preserve stream provenance");
      Assert (Snapshot.Selected_Output_Stream =
                Editor.Build_Output_Details.Build_Output_Stream_Merged,
              "render snapshot labels merged fallback output as merged");
      Assert (To_String (Snapshot.Stdout_Excerpt) = "merged compiler output",
              "merged fallback remains visible in the output panel");
   end Test_Merged_Output_Provenance_Is_Rendered_As_Merged;

   overriding procedure Register_Tests
     (T : in out Build_Output_Details_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Output_Details_Absent_Before_First_Result'Access,
         "output details are absent before first represented build");
      Register_Routine
        (T, Test_Success_And_Failure_Create_Bounded_Output_Details'Access,
         "success/failure create bounded stdout/stderr details");
      Register_Routine
        (T, Test_Timeout_And_Cancelled_Output_Are_Marked_Partial'Access,
         "timeout/cancel output details are marked partial");
      Register_Routine
        (T, Test_Truncation_And_Display_Bounds_Are_Marked'Access,
         "runner/display truncation markers are preserved");
      Register_Routine
        (T, Test_No_Output_State_Is_Deterministic_And_Bounded'Access,
         "no-output state is deterministic and bounded");
      Register_Routine
        (T, Test_Replacement_Is_Latest_Only_And_Clears_Prior_Output'Access,
         "output details replacement is latest-only");
      Register_Routine
        (T, Test_Stale_Stream_Fields_Clear_Across_Replacement_Families'Access,
         "stale stream fields clear across replacement families");
      Register_Routine
        (T, Test_Truncated_And_Partial_Markers_Clear_On_Later_Complete_Output'Access,
         "truncated and partial markers clear on later complete output");
      Register_Routine
        (T, Test_Details_Do_Not_Own_Forbidden_State'Access,
         "output details do not own forbidden state");
      Register_Routine
        (T, Test_Render_Snapshot_Consumes_Details_Only'Access,
         "render consumes output details snapshot only");
      Register_Routine
        (T, Test_Executor_Updates_Output_Details_And_Keeps_Summary_Compact'Access,
         "Executor updates details without weakening compact summary");
      Register_Routine
        (T, Test_Output_Details_Visibility_Does_Not_Mutate_Output'Access,
         "visibility and selected stream do not mutate output");
      Register_Routine
        (T, Test_Output_Details_Commands_And_Focused_Keyboard'Access,
         "output details commands and focused keyboard route through Executor");
      Register_Routine
        (T, Test_Unavailable_Details_Are_Not_History_Or_Output_Log'Access,
         "unavailable details are not history or output log");
      Register_Routine
        (T, Test_Pre_Run_Unavailable_Replaces_Output_With_Empty_Unavailable_State'Access,
         "pre-run unavailable replaces output with empty unavailable state");
      Register_Routine
        (T, Test_Reliability_Helper_Reasserts_All_Output_Boundaries'Access,
         "reliability helper reasserts output boundaries");
      Register_Routine
        (T, Test_Canonical_Shape_Removes_Log_Rerun_Process_Diagnostics_State'Access,
         "canonical shape removes log/rerun/process/Diagnostics state");
      Register_Routine
        (T, Test_Canonical_Replacement_Drops_All_Previous_Stream_State'Access,
         "canonical replacement drops previous stream state");
      Register_Routine
        (T, Test_Render_And_Audit_Do_Not_Own_Runtime_Output_Details'Access,
         "render and audit do not own runtime output details");
      Register_Routine
        (T, Test_Executor_Path_Is_Only_State_Update_Surface'Access,
         "Executor path is only state update surface");
      Register_Routine
        (T, Test_Final_Freeze_Shape_And_Mapping_All_Outcomes'Access,
         "final freeze shape and mapping all outcomes");
      Register_Routine
        (T, Test_Final_Freeze_No_Output_Clears_And_Fabricates_Nothing'Access,
         "no-output final freeze clears and fabricates nothing");
      Register_Routine
        (T, Test_Final_Freeze_Replace_Only_No_History_Rerun_Log_Process'Access,
         "replace-only/no-history/no-rerun/no-log/no-process freeze");
      Register_Routine
        (T, Test_Final_Freeze_Summary_Frontdoor_And_Executor_Ownership'Access,
         "summary/frontdoor/Executor ownership freeze");
      Register_Routine
        (T, Test_Final_Freeze_Render_Audit_Lifecycle_And_Persistence'Access,
         "render/audit/lifecycle/persistence final freeze");
      Register_Routine
        (T, Test_Incremental_Build_Output_Stream_Produces_Bounded_Partial_Details'Access,
         "incremental build output stream produces bounded partial details");
      Register_Routine
        (T, Test_Merged_Output_Provenance_Is_Rendered_As_Merged'Access,
         "merged fallback output preserves stream provenance");
      Register_Routine
        (T, Test_Output_Details_Audit_Coherent'Access,
         "output details audit is coherent");
   end Register_Tests;

end Editor.Build_Output_Details.Tests;
