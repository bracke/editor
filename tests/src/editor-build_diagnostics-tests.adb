with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Command;
with Editor.Build_Candidates;
with Editor.Build_Diagnostics;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.State;

use type Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Policy;
use type Editor.External_Producers.Build_Run_Status;
use type Editor.External_Producers.Diagnostic_Line_Command_Outcome;
use type Editor.External_Producers.Diagnostic_Line_Parse_Status;
use type Editor.Feature_Panel.Feature_Id;

package body Editor.Build_Diagnostics.Tests is

   overriding function Name
     (T : Build_Diagnostics_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Build_Diagnostics");
   end Name;

   function Request return Editor.External_Producers.Build_Run_Request
   is
   begin
      return
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   end Request;

   function Output_Result
     (Text : String) return Editor.External_Producers.Build_Run_Result
   is
   begin
      return Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Exit_Code     => 1,
         Has_Exit_Code => True,
         Stderr_Text   => Text);
   end Output_Result;

   procedure Prepare_Public_Build_UI
     (S                : in out Editor.State.State_Type;
      Show_Diagnostics : Boolean)
   is
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      GPR : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          ("current-project-root", "editor.gpr");
   begin
      Editor.Build_UI.Show (S.Build_UI);
      Candidates.Append (GPR);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, To_String (GPR.Candidate_Id));
      Editor.Build_UI.Set_Show_Diagnostics_On_Result
        (S.Build_UI, Show_Diagnostics);
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
   end Prepare_Public_Build_UI;

   procedure Test_Policy_Is_Explicit_And_Request_Controlled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (not Build_Diagnostics_Ingestion_Allowed
           (Build_Diagnostics_Ingestion_Disabled, True),
         "disabled policy rejects even an explicit request");
      Assert
        (Build_Diagnostics_Ingestion_Allowed
           (Build_Diagnostics_Ingestion_On_Request, True),
         "on-request policy honors the transient request option");
      Assert
        (not Build_Diagnostics_Ingestion_Allowed
           (Build_Diagnostics_Ingestion_On_Request, False),
         "on-request policy does not infer ingestion without request metadata");
      Assert
        (Build_Diagnostics_Ingestion_Allowed
           (Build_Diagnostics_Ingestion_Always_For_Build_Run, False),
         "always policy is explicit runtime policy, not remembered consent");
   end Test_Policy_Is_Explicit_And_Request_Controlled;

   procedure Test_Bounded_Output_Parsing_Uses_Captured_Result_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Lines  : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Build_Run_Result;
      Parsed : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
   begin
      for I in 1 .. Max_Build_Diagnostic_Input_Lines + 25 loop
         Lines.Append
           (To_Unbounded_String ("main.adb:1:1: warning: bounded"));
      end loop;

      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Diagnostic_Lines => Lines);
      Parsed := Parse_Build_Output_Diagnostics (Request, Result);

      Assert
        (Natural (Bounded_Build_Output_Diagnostic_Lines (Result).Length) =
           Max_Build_Diagnostic_Input_Lines,
         "build diagnostics parser receives only bounded captured lines");
      Assert
        (Parsed.Input_Count = Max_Build_Diagnostic_Input_Lines,
         "parser input count is bounded before ingestion");
      Assert
        (Parsed.Accepted_Count = Max_Build_Diagnostic_Input_Lines,
         "bounded diagnostic lines remain parseable");
   end Test_Bounded_Output_Parsing_Uses_Captured_Result_Only;

   procedure Test_Ingestion_Disabled_Produces_No_Diagnostics_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Command := Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Output_Result ("main.adb:1:1: error: disabled"),
         Build_Diagnostics_Ingestion_Disabled,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Ingestion.Parse_Input_Count = 0,
         "disabled policy does not parse build output");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
         "disabled policy does not mutate Diagnostics");
   end Test_Ingestion_Disabled_Produces_No_Diagnostics_Mutation;

   procedure Test_On_Request_Ingests_Through_Diagnostics_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Command := Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Output_Result ("main.adb:1:1: error: owned"),
         Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert
        (Command.Outcome =
           Editor.External_Producers.Diagnostic_Line_Command_Succeeded,
         "on-request policy parses build diagnostic output");
      Assert
        (Command.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "diagnostic is accepted through the Diagnostics ingestion result");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
         "Diagnostics owns the resulting row storage");
   end Test_On_Request_Ingests_Through_Diagnostics_Ownership;

   procedure Test_Build_Command_Routes_Output_Through_Diagnostic_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      S_Disabled : Editor.State.State_Type;
      Command_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           =>
           Editor.External_Producers.Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"));
      Captured_Output : constant Editor.External_Producers.Process_Run_Result :=
        Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code     => 1,
           Has_Exit_Code => True,
           Stderr_Text   =>
             "main.adb:1:1: error: command-owned" & ASCII.LF &
             "plain process noise");
      Command : Editor.External_Producers.Build_Command_Result;
      Disabled_Command : Editor.External_Producers.Build_Command_Result;
   begin
      Command := Editor.External_Producers.Run_Build_Command_With_Gate
        (S, Command_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate
           (Allow_Diagnostics_Ingestion => True,
            Show_Diagnostics            => False),
         Captured_Output);

      Assert
        (Command.Build_Result.Status =
           Editor.External_Producers.Build_Run_Failed,
         "build command returns the supplied runner status");
      Assert
        (Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 2,
         "build command parses captured output through Diagnostic_Result");
      Assert
        (Command.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 1,
         "build command accepts only parseable diagnostics");
      Assert
        (Command.Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1,
         "build command records non-diagnostic output as ignored parse input");
      Assert
        (Command.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1,
         "Diagnostic_Result owns the accepted diagnostics count");
      Assert
        (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
           Command.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count,
         "Diagnostics row storage matches the command Diagnostic_Result");
      Assert
        (not Command.Diagnostic_Result.Should_Show_Diagnostics,
         "show diagnostics remains gate metadata, not an output side effect");

      Disabled_Command := Editor.External_Producers.Run_Build_Command_With_Gate
        (S_Disabled, Command_Request,
         Editor.External_Producers.Build_Test_Fixture_Execution_Gate
           (Allow_Diagnostics_Ingestion => False,
            Show_Diagnostics            => True),
         Captured_Output);

      Assert
        (Disabled_Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 0,
         "disabled command diagnostics policy skips parsing captured output");
      Assert
        (Editor.Feature_Diagnostics.Row_Count
           (S_Disabled.Feature_Diagnostics) = 0,
         "disabled command diagnostics policy does not mutate Diagnostics");
   end Test_Build_Command_Routes_Output_Through_Diagnostic_Result;

   procedure Test_Show_Diagnostics_Remains_Request_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Assert
        (Editor.Feature_Panel_Controller.Show_Feature
           (S, Editor.Feature_Panel.Search_Results_Feature),
         "test can start on another feature");
      Command := Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Output_Result ("main.adb:1:1: warning: show"),
         Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Assert (Command.Should_Show_Diagnostics,
              "explicit request option can show Diagnostics");
      Assert
        (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
           Editor.Feature_Panel.Diagnostics_Feature,
         "show behavior remains owned by the existing Diagnostics feature");
   end Test_Show_Diagnostics_Remains_Request_Metadata;

   procedure Test_Public_Build_Gate_Uses_Request_Controlled_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Gate : Editor.External_Producers.Build_Execution_Gate;
   begin
      Prepare_Public_Build_UI (S, Show_Diagnostics => False);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert
        (not Gate.Allow_Diagnostics_Ingestion,
         "public build.run does not ingest diagnostics without request option");

      Prepare_Public_Build_UI (S, Show_Diagnostics => True);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert
        (Gate.Allow_Diagnostics_Ingestion,
         "public build.run enables ingestion from explicit request option");
      Assert
        (Gate.Show_Diagnostics,
         "public build.run forwards show request as transient metadata");
      Assert
        (Gate.Process_Policy.Max_Output_Bytes = 262_144,
         "normal output capture limit reaches the execution gate");

      Editor.Build_UI.Cycle_Output_Capture_Limit (S.Build_UI);
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      Gate := Editor.Build_Command.Build_Run_Execution_Gate (S);
      Assert
        (Gate.Process_Policy.Max_Output_Bytes = 1_048_576,
         "changed output capture limit changes the bounded runner policy");
   end Test_Public_Build_Gate_Uses_Request_Controlled_Policy;

   procedure Test_Foundation_Audit_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent,
         "diagnostics ingestion foundation audit passes");
   end Test_Foundation_Audit_Coherent;

   overriding procedure Register_Tests
     (T : in out Build_Diagnostics_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Policy_Is_Explicit_And_Request_Controlled'Access,
         "diagnostics ingestion policy is explicit and request-controlled");
      Register_Routine
        (T, Test_Bounded_Output_Parsing_Uses_Captured_Result_Only'Access,
         "bounded build output is parsed only from captured result");
      Register_Routine
        (T, Test_Ingestion_Disabled_Produces_No_Diagnostics_Mutation'Access,
         "disabled policy produces no Diagnostics mutation");
      Register_Routine
        (T, Test_On_Request_Ingests_Through_Diagnostics_Ownership'Access,
         "on-request ingestion uses Diagnostics ownership");
      Register_Routine
        (T, Test_Build_Command_Routes_Output_Through_Diagnostic_Result'Access,
         "build command routes output through Diagnostic_Result");
      Register_Routine
        (T, Test_Show_Diagnostics_Remains_Request_Metadata'Access,
         "show diagnostics remains transient request metadata");
      Register_Routine
        (T, Test_Public_Build_Gate_Uses_Request_Controlled_Policy'Access,
         "public build gate uses request-controlled diagnostics policy");
      Register_Routine
        (T, Test_Foundation_Audit_Coherent'Access,
         "foundation audit is coherent");
   end Register_Tests;

end Editor.Build_Diagnostics.Tests;
