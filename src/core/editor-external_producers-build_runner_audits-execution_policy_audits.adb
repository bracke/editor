with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Request_Policies;
with Editor.State;

package body Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits is

   use type Ada.Containers.Count_Type;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Layering_Audit_Passes;

   function Native_Process_Control_Platform_Audit_Passes return Boolean
     renames Editor.External_Producers.Execution_Policy.Native_Process_Control_Platform_Audit_Passes;

   function Build_Test_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate;

   function Build_Cancellation_Unsupported_Process_Result
     return Process_Run_Result
     renames Editor.External_Producers.Execution_Policy.Build_Cancellation_Unsupported_Process_Result;

   function Real_Process_Runner_Output_Capture_Mode
     return Process_Output_Capture_Mode
     renames Editor.External_Producers.Execution_Policy.Real_Process_Runner_Output_Capture_Mode;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Build_Preflight_Result_Is_Consistent;

   function Diagnostic_Stream_Preference
     (Result : Process_Run_Result) return Process_Diagnostic_Stream_Preference
     renames Editor.External_Producers.Execution_Policy.Diagnostic_Stream_Preference;

   function Build_Run_Diagnostic_Stream_Preference
     (Result : Build_Run_Result) return Process_Diagnostic_Stream_Preference
     renames Editor.External_Producers.Execution_Policy.Build_Run_Diagnostic_Stream_Preference;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Prepare_Process_Request
     (Request : Build_Run_Request) return Process_Run_Request
     renames Editor.External_Producers.Request_Policies.Prepare_Process_Request;

   function Build_Process_Run_Result
     (Status        : Process_Run_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Text   : String := "";
      Stderr_Text   : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated) return Process_Run_Result
     renames Editor.External_Producers.Request_Policies.Build_Process_Run_Result;

   function Empty_Process_Arguments return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

   procedure Append_Process_Argument
     (Arguments : in out Process_Argument_Vector;
      Value     : String)
     renames Editor.External_Producers.Request_Policies.Append_Process_Argument;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Run_Request_Status;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Process_Execution_Policy;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Build_Run_Request;

   function Run_Build_Command_With_Gate
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_With_Gate;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean
   is
      Max_Build_Timeout_Milliseconds : constant Natural := 600_000;
   begin
      if Policy.Mode = Process_Execution_Disabled then
         return Policy.Timeout_Milliseconds = 0;
      end if;

      return Policy.Timeout_Milliseconds <= Max_Build_Timeout_Milliseconds;
   end Build_Timeout_Policy_Is_Bounded;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
      Message : constant String := To_String (Result.Command_Message);
   begin
      case Result.Build_Result.Status is
         when Build_Run_Succeeded | Build_Run_Failed =>
            if not Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
         when Build_Run_Not_Available | Build_Run_Rejected
            | Build_Run_Execution_Error | Build_Run_Timed_Out
            | Build_Run_Cancelled | Build_Run_Cancellation_Unsupported
            | Build_Run_Output_Truncated =>
            if Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
      end case;

      if not Diagnostics_Ingestion_Allowed then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      if Result.Build_Result.Status = Build_Run_Not_Available then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      return Message'Length > 0;
   end Gated_Build_Command_Result_Is_Consistent;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Gated_Build_Command_Result_Is_Consistent (Result));
   end Assert_Gated_Build_Command_Result_Consistent;

   function Process_Runner_Audit_Passes return Boolean
   is
      GPR_Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        (Tool                 => Alire_Build_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("alr build"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Custom_Request : constant Build_Run_Request :=
        (Tool                 => Custom_Build_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("custom"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      GPR_Process : constant Process_Run_Request :=
        Prepare_Process_Request (GPR_Request);
      Alire_Process : constant Process_Run_Request :=
        Prepare_Process_Request (Alire_Request);
      Default_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Process_Request_Default (GPR_Process);
      Supplied_Process : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed, Exit_Code => 7, Has_Exit_Code => True,
           Stdout_Text => "src/stdout.adb:3:4: warning: out",
           Stderr_Text => "src/stderr.adb:1:2: error: err");
      Test_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Test_Fed_Process_Request (GPR_Process, Supplied_Process);
      Empty_Process : constant Process_Run_Request :=
        (Program_Label => Null_Unbounded_String,
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Rejected_Test : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Test_Fed_Process_Request
          (Empty_Process, Build_Process_Run_Result (Process_Run_Succeeded));
      Build_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Requests.Build_Result_From_Process_Result (GPR_Request, Test_Result);
      Lines : constant Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Build_Result);
   begin
      return Validate_Build_Run_Request_Status (GPR_Request) = Build_Request_Valid
        and then Validate_Build_Run_Request_Status (Custom_Request) =
          Build_Request_Rejected_Unsupported_Tool
        and then To_String (GPR_Process.Program_Label) = "gprbuild"
        and then To_String (GPR_Process.Arguments) = "-q"
        and then To_String (Alire_Process.Program_Label) = "alr"
        and then Length (Alire_Process.Arguments) = 0
        and then Alire_Process.Structured_Arguments.Length = 1
        and then To_String (Alire_Process.Structured_Arguments.First_Element) = "build"
        and then Default_Result.Status = Process_Run_Not_Available
        and then Length (Default_Result.Stdout_Text) = 0
        and then Length (Default_Result.Stderr_Text) = 0
        and then Test_Result.Status = Process_Run_Failed
        and then Test_Result.Has_Exit_Code
        and then Test_Result.Exit_Code = 7
        and then Rejected_Test.Status = Process_Run_Rejected
        and then Build_Result.Status = Build_Run_Failed
        and then Build_Result.Has_Exit_Code
        and then Build_Result.Exit_Code = 7
        and then Lines.Length = 2
        and then To_String (Lines.First_Element) =
          "src/stderr.adb:1:2: error: err"
        and then To_String (Lines.Last_Element) =
          "src/stdout.adb:3:4: warning: out"
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Audit_Process_Execution_Gates
        and then Audit_Process_Argv_And_Preflight_Gates
        and then Audit_Build_Runner_Output_Stream_Capture
        and then Audit_Build_Runner_Timeout_Cancellation_Safety;
   end Process_Runner_Audit_Passes;

   function Audit_Process_Execution_Gates return Boolean
   is
      Default_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Shell_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => True,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Real_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 8,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Timeout_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 1);
      Empty_Request : constant Process_Run_Request :=
        (Program_Label => Null_Unbounded_String,
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Opaque_Request : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Empty_Process_Arguments);
      No_Arg_Request : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Valid_Process : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Disabled_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Not_Available);
      Shell_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Rejected);
      Opaque_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Rejected);
      Empty_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Rejected);
      Timeout_Result : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Succeeded);
      Oversize : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Execution_Error);
      Args : constant Process_Argument_Vector :=
        Build_Process_Argument_Vector ("one", "", "three");
      Bad_Build : constant Build_Run_Result :=
        Editor.External_Producers.Build_Command_Execution.Execute_Build_Request_With_Process_Policy
          ((Tool                 => No_Build_Tool,
            Provenance           => Build_Request_From_Internal_Command,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
           Real_Policy,
           Build_Process_Run_Result (Process_Run_Succeeded));
   begin
      return Validate_Process_Execution_Policy (Default_Policy)
        and then not Validate_Process_Execution_Policy (Shell_Policy)
        and then Validate_Process_Execution_Policy (Timeout_Policy)
        and then not Editor.External_Producers.Build_Requests.Validate_Process_Run_Request_For_Real_Execution
          (Opaque_Request, Real_Policy)
        and then not Editor.External_Producers.Build_Requests.Validate_Process_Run_Request_For_Real_Execution
          (No_Arg_Request, Real_Policy)
        and then Editor.External_Producers.Build_Requests.Validate_Process_Run_Request_For_Real_Execution
          (Valid_Process, Real_Policy)
        and then Disabled_Result.Status = Build_Run_Not_Available
        and then Shell_Result.Status = Build_Run_Rejected
        and then Opaque_Result.Status = Build_Run_Rejected
        and then Empty_Result.Status = Build_Run_Rejected
        and then Timeout_Result.Status = Build_Run_Succeeded
        and then Oversize.Status = Build_Run_Execution_Error
        and then Args.Length = 3
        and then To_String (Args.First_Element) = "one"
        and then To_String (Args.Element (1)) = ""
        and then To_String (Args.Last_Element) = "three"
        and then Bad_Build.Status = Build_Run_Rejected
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Native_Process_Control_Platform_Audit_Passes;
   end Audit_Process_Execution_Gates;

   function Audit_Build_Runner_Timeout_Cancellation_Safety return Boolean
   is
      S : Editor.State.State_Type;
      Timeout_Gate : constant Build_Execution_Gate :=
        Build_Test_Fixture_Execution_Gate;
      Timeout_Process : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Timed_Out,
           Stderr_Text => "main.adb:1:1: error: bounded timeout partial");
      Cancel_Process : constant Process_Run_Result :=
        Build_Process_Run_Result (Process_Run_Cancelled);
      Unsupported_Process : constant Process_Run_Result :=
        Build_Cancellation_Unsupported_Process_Result;
      Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Timeout_Result : Build_Command_Result;
      Cancel_Result : Build_Command_Result;
      Unsupported_Result : Build_Command_Result;
      Invalid_Timeout_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 900_000);
   begin
      Editor.State.Init (S);
      Timeout_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Timeout_Process);
      Cancel_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Cancel_Process);
      Unsupported_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Unsupported_Process);

      return Build_Timeout_Policy_Is_Bounded (Timeout_Gate.Process_Policy)
        and then not Build_Timeout_Policy_Is_Bounded (Invalid_Timeout_Policy)
        and then Timeout_Result.Build_Result.Status = Build_Run_Timed_Out
        and then To_String (Timeout_Result.Command_Message) =
          "Build failed: timed out"
        and then Cancel_Result.Build_Result.Status = Build_Run_Cancelled
        and then To_String (Cancel_Result.Command_Message) = "Build cancelled"
        and then Unsupported_Result.Build_Result.Status =
          Build_Run_Cancellation_Unsupported
        and then To_String (Unsupported_Result.Command_Message) =
          "Build unavailable: cancellation unsupported"
        and then Timeout_Result.Diagnostic_Result.Ingestion.Parse_Input_Count <= 512;
   end Audit_Build_Runner_Timeout_Cancellation_Safety;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean
   is
      Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Separated : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed,
           Stdout_Text => "main.adb:3:1: warning: stdout",
           Stderr_Text => "main.adb:1:1: error: stderr");
      Merged : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed,
           Stdout_Text => "main.adb:1:1: error: merged stderr/stdout",
           Output_Capture_Mode => Process_Output_Capture_Merged_Stdout_Stderr);
      Separated_Build : constant Build_Run_Result :=
        Editor.External_Producers.Build_Requests.Build_Result_From_Process_Result (Request, Separated);
      Merged_Build : constant Build_Run_Result :=
        Editor.External_Producers.Build_Requests.Build_Result_From_Process_Result (Request, Merged);
      Separated_Lines : constant Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Separated_Build);
      Merged_Lines : constant Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Merged_Build);
   begin
      return Real_Process_Runner_Output_Capture_Mode =
          Process_Output_Capture_Separated
        and then Diagnostic_Stream_Preference (Separated) =
          Process_Diagnostics_Prefer_Stderr
        and then Diagnostic_Stream_Preference (Merged) =
          Process_Diagnostics_Merged_Output_Fallback
        and then Build_Run_Diagnostic_Stream_Preference (Separated_Build) =
          Process_Diagnostics_Prefer_Stderr
        and then Build_Run_Diagnostic_Stream_Preference (Merged_Build) =
          Process_Diagnostics_Merged_Output_Fallback
        and then Separated_Lines.Length = 2
        and then To_String (Separated_Lines.First_Element) =
          "main.adb:1:1: error: stderr"
        and then Merged_Lines.Length = 1
        and then To_String (Merged_Lines.First_Element) =
          "main.adb:1:1: error: merged stderr/stdout";
   end Audit_Build_Runner_Output_Stream_Capture;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean
   is
      Real_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Disabled_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      GPR_Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => To_Unbounded_String ("-q --not-split"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        (Tool                 => Alire_Build_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("alr build"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Invalid_Request : constant Build_Run_Request :=
        (Tool                 => No_Build_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => Null_Unbounded_String,
         Command_Label        => Null_Unbounded_String,
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      GPR_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (GPR_Request, Real_Policy);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Opaque_Request, Real_Policy);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (GPR_Request, Disabled_Policy);
      Invalid_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Invalid_Request, Real_Policy);
      Alire_Process : constant Process_Run_Request :=
        Prepare_Process_Request (Alire_Request);
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, "two words");
      Append_Process_Argument (Args, """quoted""");
      Append_Process_Argument (Args, ";rm -rf ignored");

      return Build_Preflight_Result_Is_Consistent (GPR_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Opaque_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Disabled_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Invalid_Preflight)
        and then GPR_Preflight.Process_Request_Status = Process_Request_Valid
        and then GPR_Preflight.Has_Process_Request
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then not Opaque_Preflight.Has_Process_Request
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Invalid_Preflight.Build_Request_Status =
          Build_Request_Rejected_No_Tool
        and then not Invalid_Preflight.Has_Process_Request
        and then Alire_Process.Structured_Arguments.Length = 1
        and then To_String (Alire_Process.Structured_Arguments.First_Element) =
          "build"
        and then Args.Length = 3
        and then To_String (Args.First_Element) = "two words"
        and then To_String (Args.Element (1)) = """quoted"""
        and then To_String (Args.Last_Element) = ";rm -rf ignored";
   end Audit_Process_Argv_And_Preflight_Gates;

end Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits;
