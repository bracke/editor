with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Request_Policies;
with Editor.State;

package body Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits is

   use type Ada.Containers.Count_Type;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Empty_Process_Arguments return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

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

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Run_Request_Status;

   function Validate_Build_Execution_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Validate_Build_Execution_Gate;

   function Build_Default_Execution_Gate return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Default_Execution_Gate;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Real_Build_Tool_Request;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_User_Opt_In_Build_Feedback;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.User_Opt_In_Build_Preflight_Is_Consistent;

   function Build_Test_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate;

   function Build_Real_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Real_Fixture_Execution_Gate;

   function Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Require_Absolute_Program    : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Not_Provided) return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Real_Execution_Gate;

   function Build_Default_Timeout_Milliseconds return Natural
     renames Editor.External_Producers.Execution_Policy.Build_Default_Timeout_Milliseconds;

   function Select_Process_Runner_Mode
     (Gate   : Build_Execution_Gate;
      Policy : Process_Execution_Policy) return Process_Execution_Mode
     renames Editor.External_Producers.Execution_Policy.Select_Process_Runner_Mode;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_User_Opt_In_Build_Request;

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_Process_Fixture_Request;

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

   function Run_Build_Command_With_Fixture_Gate
     (S       : in out Editor.State.State_Type;
      Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Gate    : Build_Execution_Gate) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_With_Fixture_Gate;

   function Audit_Real_Build_Execution_Gates return Boolean
   is
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed);
      Missing_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Test_Only_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_Test_Only);
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      User_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Fixture_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_Fixture,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Project_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_Implicit_Source,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Working_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("project-root"),
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      User_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Real_Gate);
      Missing_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Missing_Consent_Gate);
      Test_Only_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Test_Only_Consent_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Unknown_Request, Real_Gate);
      Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Fixture_Request, Real_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Project_Request, Real_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Working_Request, Real_Gate);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Opaque_Request, Real_Gate);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Default_Gate);
      Fixture_Gate_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Fixture_Gate);
   begin
      return Real_Gate.Allow_Real_Build_Tool_Execution
        and then not Fixture_Gate.Allow_Real_Build_Tool_Execution
        and then User_Preflight.Build_Request_Status = Build_Request_Valid
        and then User_Preflight.Process_Request_Status = Process_Request_Valid
        and then User_Preflight.Has_Process_Request
        and then Missing_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Missing_Consent_Preflight.Has_Process_Request
        and then Test_Only_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Test_Only_Consent_Preflight.Has_Process_Request
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unknown_Provenance
        and then not Unknown_Preflight.Has_Process_Request
        and then Fixture_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Implicit_Source
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Fixture_Gate_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance;
   end Audit_Real_Build_Execution_Gates;

   function Audit_User_Opt_In_Build_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed);
      Missing_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Test_Only_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_Test_Only);
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Shell_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_User_Confirmed,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      User_Request : constant Build_Run_Request :=
        Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request
          (GPRbuild_Tool, "gprbuild", "",
           Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request
          (Alire_Build_Tool, "alr", "",
           Build_Process_Argument_Vector ("build"));
      Project_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Implicit_Source,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Fixture_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Fixture,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Custom_Request : constant Build_Run_Request :=
        Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request
          (Custom_Build_Tool, "custom", "",
           Build_Process_Argument_Vector ("build"));
      No_Tool_Request : constant Build_Run_Request :=
        Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request
          (No_Build_Tool, "", "", Empty_Process_Arguments);
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Working_Request : constant Build_Run_Request :=
        Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request
          (GPRbuild_Tool, "gprbuild", "project-root",
           Build_Process_Argument_Vector ("-q"));
      User_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Real_Gate);
      Missing_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Missing_Consent_Gate);
      Test_Only_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Test_Only_Consent_Gate);
      Alire_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Alire_Request, Real_Gate);
      Default_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Default_Gate);
      Fixture_Gate_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Fixture_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Project_Request, Real_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Unknown_Request, Real_Gate);
      Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Fixture_Request, Real_Gate);
      Custom_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Custom_Request, Real_Gate);
      No_Tool_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (No_Tool_Request, Real_Gate);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Opaque_Request, Real_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Working_Request, Real_Gate);
      Shell_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Shell_Gate);
   begin
      return Validate_Build_Execution_Gate (Default_Gate)
        and then not Default_Gate.Allow_Build_Run
        and then User_Preflight.Build_Request_Status = Build_Request_Valid
        and then User_Preflight.Process_Request_Status = Process_Request_Valid
        and then User_Preflight.Has_Process_Request
        and then Missing_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Missing_Consent_Preflight.Has_Process_Request
        and then Test_Only_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Test_Only_Consent_Preflight.Has_Process_Request
        and then Build_User_Opt_In_Build_Feedback (Missing_Consent_Preflight) =
          "Build: execution consent required"
        and then To_String (User_Preflight.Process_Request.Program_Label) = "gprbuild"
        and then Alire_Preflight.Process_Request_Status = Process_Request_Valid
        and then To_String (Alire_Preflight.Process_Request.Program_Label) = "alr"
        and then Default_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then Default_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Fixture_Gate_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Implicit_Source
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unknown_Provenance
        and then Fixture_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance
        and then Custom_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unsupported_Tool
        and then No_Tool_Preflight.Build_Request_Status =
          Build_Request_Rejected_No_Tool
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Shell_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Build_User_Opt_In_Build_Feedback (Project_Preflight) =
          "Build: explicit build request required"
        and then Build_User_Opt_In_Build_Feedback (Unknown_Preflight) =
          "Build: user opt-in required"
        and then Build_User_Opt_In_Build_Feedback (Custom_Preflight) =
          "Build: custom build tool not supported"
        and then Build_User_Opt_In_Build_Feedback (Opaque_Preflight) =
          "Build: structured arguments required"
        and then User_Opt_In_Build_Preflight_Is_Consistent (User_Preflight)
        and then User_Opt_In_Build_Preflight_Is_Consistent (Project_Preflight)
        and then Audit_User_Opt_In_Build_Command_Surface;
   end Audit_User_Opt_In_Build_Gates;

   function Audit_Build_Execution_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate :=
        Build_Default_Execution_Gate;
      Test_Gate : constant Build_Execution_Gate :=
        Build_Test_Fixture_Execution_Gate;
      Real_Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Ambiguous_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Test_Fixture,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      Shell_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   begin
      return Validate_Build_Execution_Gate (Default_Gate)
        and then Default_Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Default_Gate.Allow_Build_Run
        and then Select_Process_Runner_Mode
          (Default_Gate, Default_Gate.Process_Policy) = Process_Execution_Disabled
        and then Validate_Build_Execution_Gate (Test_Gate)
        and then Select_Process_Runner_Mode
          (Test_Gate, Test_Gate.Process_Policy) = Process_Execution_Test_Fixture
        and then Validate_Build_Execution_Gate (Real_Fixture_Gate)
        and then Select_Process_Runner_Mode
          (Real_Fixture_Gate, Real_Fixture_Gate.Process_Policy) =
          Process_Execution_Real_Fixture_Allowed
        and then Validate_Build_Execution_Gate (Real_Gate)
        and then Select_Process_Runner_Mode
          (Real_Gate, Real_Gate.Process_Policy) = Process_Execution_Real_Allowed
        and then Select_Process_Runner_Mode
          (Real_Gate, Test_Gate.Process_Policy) = Process_Execution_Disabled
        and then not Validate_Build_Execution_Gate (Ambiguous_Gate)
        and then not Validate_Build_Execution_Gate (Shell_Gate);
   end Audit_Build_Execution_Gates;

   function Audit_Gated_Runner_Command_Path return Boolean
   is
      S : Editor.State.State_Type;
      Valid_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Invalid_Request : constant Build_Run_Request :=
        (Tool          => No_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Supplied_Success : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Succeeded,
           Stderr_Text => "main.adb:1:1: error: should-not-ingest");
      Disabled_Command : Build_Command_Result;
      Invalid_Command : Build_Command_Result;
      Test_Command : Build_Command_Result;
      Real_Command : Build_Command_Result;
      Opaque_Command : Build_Command_Result;
   begin
      Editor.State.Init (S);

      Disabled_Command := Run_Build_Command_With_Gate
        (S, Valid_Request, Build_Default_Execution_Gate, Supplied_Success);
      Invalid_Command := Run_Build_Command_With_Gate
        (S, Invalid_Request, Build_Test_Fixture_Execution_Gate, Supplied_Success);
      Test_Command := Run_Build_Command_With_Gate
        (S, Valid_Request,
         Build_Test_Fixture_Execution_Gate
           (Allow_Diagnostics_Ingestion => False),
         Supplied_Success);
      Real_Command := Run_Build_Command_With_Gate
        (S,
         (Tool          => GPRbuild_Tool,
          Provenance    => Build_Request_From_User_Opt_In,
          Working_Label => Null_Unbounded_String,
          Command_Label => To_Unbounded_String ("gprbuild --version"),
          Arguments     => Null_Unbounded_String,
          Structured_Arguments => Build_Process_Argument_Vector ("--version")),
         Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed), Supplied_Success);
      Opaque_Command := Run_Build_Command_With_Gate
        (S,
         (Tool          => GPRbuild_Tool,
          Provenance    => Build_Request_From_User_Opt_In,
          Working_Label => Null_Unbounded_String,
          Command_Label => To_Unbounded_String ("gprbuild"),
          Arguments     => To_Unbounded_String ("-q"),
          Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed), Supplied_Success);

      return Disabled_Command.Build_Result.Status = Build_Run_Not_Available
        and then To_String (Disabled_Command.Command_Message) =
          "Build: execution disabled"
        and then Invalid_Command.Build_Result.Status = Build_Run_Rejected
        and then Test_Command.Build_Result.Status = Build_Run_Succeeded
        and then Test_Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 0
        and then To_String (Test_Command.Command_Message) =
          "Build: succeeded, diagnostics ingestion disabled"
        and then Real_Command.Build_Result.Status = Build_Run_Succeeded
        and then Real_Command.Build_Result.Has_Exit_Code
        and then Real_Command.Build_Result.Exit_Code = 0
        and then Ada.Strings.Fixed.Index
          (To_String (Real_Command.Command_Message), "Build: succeeded") = 1
        and then Opaque_Command.Build_Result.Status = Build_Run_Rejected
        and then To_String (Opaque_Command.Command_Message) =
          "Build: structured arguments required";
   end Audit_Gated_Runner_Command_Path;

   function Audit_Process_Fixture_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Disabled_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x.adb:1:1: error: fixture", "")),
           Default_Gate.Process_Policy);
      Unknown_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Process_Request_Real_Fixture
          ((Kind => No_Process_Fixture, Arguments => Empty_Process_Arguments),
           Fixture_Gate.Process_Policy);
      Echo_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector
              ("stdout", "two words", ";not interpreted")),
           Fixture_Gate.Process_Policy);
      Oversize_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate (Max_Output_Bytes => 3);
      Oversize_Result : constant Process_Run_Result :=
        Editor.External_Producers.Build_Requests.Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "1234", "")),
           Oversize_Gate.Process_Policy);
      Disabled_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x", "")),
           Default_Gate.Process_Policy);
      Unknown_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => No_Process_Fixture, Arguments => Empty_Process_Arguments),
           Fixture_Gate.Process_Policy);
      Shell_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x", "")),
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0));
      S : Editor.State.State_Type;
      Command : Build_Command_Result;
   begin
      Editor.State.Init (S);
      Command := Run_Build_Command_With_Fixture_Gate
        (S,
         (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Internal_Command,
          Working_Label => To_Unbounded_String ("unit-test"),
          Command_Label => To_Unbounded_String ("gprbuild"),
          Arguments     => Null_Unbounded_String,
          Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         (Kind => Echo_Diagnostic_Fixture,
          Arguments => Build_Process_Argument_Vector
            ("stderr", "main.adb:1:1: error: fixture", "noise")),
         Fixture_Gate);

      return Disabled_Status = Fixture_Request_Rejected_Disabled
        and then Unknown_Status = Fixture_Request_Rejected_Unknown_Fixture
        and then Shell_Status = Fixture_Request_Rejected_Shell
        and then Disabled_Result.Status = Process_Run_Not_Available
        and then Unknown_Result.Status = Process_Run_Rejected
        and then Echo_Result.Status = Process_Run_Succeeded
        and then Editor.External_Producers.Build_Requests.Process_Fixture_Result_Is_Consistent
          (Echo_Result, Fixture_Gate.Process_Policy)
        and then To_String (Echo_Result.Stdout_Text) =
          "two words" & ASCII.LF & ";not interpreted"
        and then Oversize_Result.Status = Process_Run_Execution_Error
        and then Editor.External_Producers.Build_Requests.Process_Fixture_Result_Is_Consistent
          (Oversize_Result, Oversize_Gate.Process_Policy)
        and then Command.Build_Result.Status = Build_Run_Succeeded
        and then Gated_Build_Command_Result_Is_Consistent (Command)
        and then Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 2
        and then Command.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 1
        and then Command.Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1
        and then Command.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1;
   end Audit_Process_Fixture_Gates;

   function Build_Run_Test_Seam_Audit_Passes return Boolean
   is
      Valid_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      No_Tool_Request : constant Build_Run_Request :=
        (Tool          => No_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Empty_Command_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Lines : Diagnostic_Text_Line_Array;
      Result_With_Lines : Build_Run_Result;
      Error_With_Output : Build_Run_Result;
      Split_Output : Build_Run_Result;
      Test_Fed_Result : Build_Run_Result;
      Invalid_Test_Fed_Result : Build_Run_Result;
      Extracted : Diagnostic_Text_Line_Array;
      Error_Extracted : Diagnostic_Text_Line_Array;
      Split_Extracted : Diagnostic_Text_Line_Array;
      Default_Result : Build_Run_Result;
      Empty_Diag : constant
        Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Pipeline.
          Empty_Diagnostic_Line_Command_Result;
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:1:1: error: build"));
      Result_With_Lines := Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result
        (Build_Run_Failed, Exit_Code => 1, Has_Exit_Code => True,
         Stderr_Text => "src/other.adb:2:3: warning: split",
         Diagnostic_Lines => Lines);
      Error_With_Output := Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result
        (Build_Run_Execution_Error,
         Stderr_Text => "src/ignored.adb:2:3: error: ignored");
      Split_Output := Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result
        (Build_Run_Failed,
         Stdout_Text => "src/stdout.adb:4:5: warning: stdout",
         Stderr_Text => "src/stderr.adb:2:3: error: stderr");
      Test_Fed_Result := Editor.External_Producers.Build_Command_Execution.Execute_Test_Fed_Build_Request
        (Valid_Request,
         Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Failed, Exit_Code => 1,
           Has_Exit_Code => True));
      Invalid_Test_Fed_Result := Editor.External_Producers.Build_Command_Execution.Execute_Test_Fed_Build_Request
        (No_Tool_Request, Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Succeeded));
      Extracted := Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Result_With_Lines);
      Error_Extracted := Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Error_With_Output);
      Split_Extracted := Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result (Split_Output);
      Default_Result := Editor.External_Producers.Build_Command_Execution.Execute_Build_Request (Valid_Request);

      return Validate_Build_Run_Request_Status (Valid_Request) = Build_Request_Valid
        and then Validate_Build_Run_Request_Status (No_Tool_Request) =
          Build_Request_Rejected_No_Tool
        and then Validate_Build_Run_Request_Status (Empty_Command_Request) =
          Build_Request_Rejected_Empty_Command
        and then Default_Result.Status = Build_Run_Not_Available
        and then Default_Result.Diagnostic_Lines.Length = 0
        and then Test_Fed_Result.Status = Build_Run_Failed
        and then Invalid_Test_Fed_Result.Status = Build_Run_Rejected
        and then Extracted.Length = 1
        and then To_String (Extracted.First_Element) =
          "src/main.adb:1:1: error: build"
        and then Error_Extracted.Length = 1
        and then To_String (Error_Extracted.First_Element) =
          "src/ignored.adb:2:3: error: ignored"
        and then Split_Extracted.Length = 2
        and then To_String (Split_Extracted.First_Element) =
          "src/stderr.adb:2:3: error: stderr"
        and then To_String (Split_Extracted.Last_Element) =
          "src/stdout.adb:4:5: warning: stdout"
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.
          Diagnostic_Line_Layering_Audit_Passes
        and then Process_Runner_Audit_Passes
        and then Audit_Build_Execution_Gates
        and then Audit_Real_Build_Execution_Gates
        and then Audit_Real_Build_Tool_Fixture_Gates
        and then Audit_User_Opt_In_Build_Gates
        and then Audit_Gated_Runner_Command_Path
        and then Audit_Process_Fixture_Gates
        and then Editor.External_Producers.Build_Command_Execution.Build_Build_Command_Feedback
          (Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Succeeded),
           Empty_Diag) =
          "Build: succeeded";
   end Build_Run_Test_Seam_Audit_Passes;

end Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits;
