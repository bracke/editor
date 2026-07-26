with Editor.Commands.Classification;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Commands.Build_Terminal_Ids;
with Editor.Keybindings;
with Editor.State;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits;
with Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Request_Policies;


with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;

package body Editor.External_Producers.Build_Runner_Audits is

   use type Ada.Containers.Count_Type;
   use type Editor.Commands.Descriptors.Command_Category;
   use type Editor.Commands.Descriptors.Command_Visibility;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Empty_Process_Arguments return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

   function Validate_Build_Execution_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Validate_Build_Execution_Gate;

   function Build_Default_Execution_Gate return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Default_Execution_Gate;

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

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Real_Build_Tool_Fixture;

   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_Real_Build_Tool_Fixture_Request;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Validate_Real_Build_Tool_Fixture_Gate;

   function Build_User_Opt_In_Command_Context
     (Tool              : Build_Tool_Kind;
      Program_Label     : String;
      Working_Label     : String;
      Arguments         : Process_Argument_Vector;
      Consent           : Build_Execution_Consent;
      Allow_Diagnostics : Boolean;
      Show_Diagnostics  : Boolean)
      return User_Opt_In_Build_Command_Context
     renames Editor.External_Producers.Build_Command_Execution.Build_User_Opt_In_Command_Context;

   function Empty_User_Opt_In_Build_Command_Context
     return User_Opt_In_Build_Command_Context
     renames Editor.External_Producers.Build_Command_Execution.Empty_User_Opt_In_Build_Command_Context;

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_User_Opt_In_Command_Feedback;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Build_Preflight_Result_Is_Consistent;

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Gated_Build_Command_Result_Is_Consistent;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Assert_Gated_Build_Command_Result_Consistent;

   function Process_Runner_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Process_Runner_Audit_Passes;

   function Audit_Process_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Audit_Process_Execution_Gates;

   function Audit_Build_Runner_Timeout_Cancellation_Safety return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Audit_Build_Runner_Timeout_Cancellation_Safety;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Audit_Build_Runner_Output_Stream_Capture;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits.Audit_Process_Argv_And_Preflight_Gates;

   function Audit_User_Opt_In_Build_Command_Surface return Boolean
   is
      Valid_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Missing_Context : constant User_Opt_In_Build_Command_Context :=
        Empty_User_Opt_In_Build_Command_Context;
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Test_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Test_Only));
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Implicit_Source,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Internal_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Internal_Command,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid_Context.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run               => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                      => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion  => True,
            Show_Diagnostics             => False));
      Working_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => To_Unbounded_String ("project-root"),
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Ambiguous_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy => Valid_Context.Gate.Process_Policy,
            Allow_Build_Run               => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => True,
            Consent                      => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion  => True,
            Show_Diagnostics             => False));
      Empty_Command_Result : constant Build_Command_Result :=
        (Build_Result      => Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result (Build_Run_Rejected),
         Diagnostic_Result =>
           Editor.External_Producers.Diagnostic_Line_Parsing.
             Empty_Diagnostic_Line_Command_Result,
         Command_Message   => Null_Unbounded_String);
   begin
      return Validate_User_Opt_In_Build_Command_Context (Valid_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Test_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Project_Context) =
          User_Build_Context_Rejected_Implicit_Source
        and then Validate_User_Opt_In_Build_Command_Context (Internal_Context) =
          User_Build_Context_Rejected_Provenance
        and then Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
          User_Build_Context_Rejected_Custom_Tool
        and then Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
          User_Build_Context_Rejected_Opaque_Arguments
        and then Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
          User_Build_Context_Rejected_Shell
        and then Validate_User_Opt_In_Build_Command_Context (Working_Context) =
          User_Build_Context_Rejected_Working_Context
        and then Validate_User_Opt_In_Build_Command_Context (Ambiguous_Context) =
          User_Build_Context_Rejected_Ambiguous_Execution_Path
        and then Build_User_Opt_In_Command_Feedback
          (User_Build_Context_Rejected_Implicit_Source, Empty_Command_Result) =
          "Build: explicit build request required"
        and then Build_User_Opt_In_Command_Feedback
          (User_Build_Context_Rejected_Shell, Empty_Command_Result) =
          "Build: shell execution disabled";
   end Audit_User_Opt_In_Build_Command_Surface;

   function Audit_Real_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Audit_Real_Build_Execution_Gates;

   function Audit_User_Opt_In_Build_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Audit_User_Opt_In_Build_Gates;

   function Audit_Real_Build_Tool_Fixture_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Fixture_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => True,
         Consent                     => Build_Consent_Test_Only,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      Real_Gate : constant Build_Execution_Gate := Build_Real_Execution_Gate;
      Ambiguous_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => True,
         Consent                     => Build_Consent_User_Confirmed,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      GPR_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Alire_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Project_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Implicit_Source,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Custom_Request : constant Build_Run_Request :=
        (Tool          => Custom_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Working_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("project-root"),
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => To_Unbounded_String ("--version"),
         Structured_Arguments => Empty_Process_Arguments);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, GPRbuild_Version_Fixture, Default_Gate);
      Accepted_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Unknown_Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, No_Real_Build_Tool_Fixture, Fixture_Gate);
      Alire_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Alire_Request, Alire_Version_Fixture, Fixture_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Project_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Unknown_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Custom_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Custom_Request, Diagnostic_Output_Fixture, Fixture_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Working_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Disabled_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Default_Gate);
      Accepted_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Ambiguous_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Ambiguous_Gate);
      Project_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Project_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Custom_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Custom_Request, Diagnostic_Output_Fixture, Fixture_Gate);
      Working_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Working_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Opaque_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Opaque_Request, GPRbuild_Version_Fixture, Fixture_Gate);
   begin
      return not Default_Gate.Allow_Real_Build_Tool_Fixture
        and then Validate_Real_Build_Tool_Fixture_Gate (Fixture_Gate)
        and then not Validate_Real_Build_Tool_Fixture_Gate (Real_Gate)
        and then not Validate_Build_Execution_Gate (Ambiguous_Gate)
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Accepted_Preflight.Build_Request_Status = Build_Request_Valid
        and then Accepted_Preflight.Process_Request_Status = Process_Request_Valid
        and then Accepted_Preflight.Has_Process_Request
        and then To_String (Accepted_Preflight.Process_Request.Program_Label) =
          "gprbuild"
        and then Accepted_Preflight.Process_Request.Structured_Arguments.Length = 1
        and then To_String
          (Accepted_Preflight.Process_Request.Structured_Arguments.First_Element) =
          "--version"
        and then Alire_Preflight.Process_Request_Status = Process_Request_Valid
        and then To_String (Alire_Preflight.Process_Request.Program_Label) = "alr"
        and then Unknown_Fixture_Preflight.Process_Request_Status =
          Process_Request_Rejected_Empty_Program
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Implicit_Source
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance
        and then Custom_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unsupported_Tool
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Build_Preflight_Result_Is_Consistent (Accepted_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Disabled_Preflight)
        and then Disabled_Validation = Real_Build_Fixture_Rejected_Disabled
        and then Accepted_Validation = Real_Build_Fixture_Valid
        and then Ambiguous_Validation = Real_Build_Fixture_Rejected_Ambiguous_Gate
        and then Project_Validation = Real_Build_Fixture_Rejected_Implicit_Source
        and then Custom_Validation = Real_Build_Fixture_Rejected_Custom_Tool
        and then Working_Validation = Real_Build_Fixture_Rejected_Working_Context
        and then Opaque_Validation = Real_Build_Fixture_Rejected_Opaque_Arguments
        and then Real_Build_Tool_Fixture_Preflight_Is_Consistent (Accepted_Preflight)
        and then Real_Build_Tool_Fixture_Preflight_Is_Consistent (Disabled_Preflight);
   end Audit_Real_Build_Tool_Fixture_Gates;

   function Audit_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Audit_Build_Execution_Gates;

   function Audit_Gated_Runner_Command_Path return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Audit_Gated_Runner_Command_Path;

   function Audit_Process_Fixture_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Audit_Process_Fixture_Gates;

   function Build_Run_Test_Seam_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits.Build_Run_Test_Seam_Audit_Passes;

   function Audit_Build_Command_Rejection_Matrix return Boolean
   is
      Valid : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Missing_Request : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Missing_Gate : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Build_Default_Execution_Gate);
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           Build_Real_Execution_Gate
             (Consent => Build_Consent_Not_Provided));
      Test_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           Build_Real_Execution_Gate
             (Consent => Build_Consent_Test_Only));
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Implicit_Source,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Fixture_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Fixture,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
      Working_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => To_Unbounded_String ("project-root"),
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      No_Diagnostics_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => False,
           Show_Diagnostics  => False);
      Show_Diagnostics_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => True);
      Ambiguous_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           (Process_Policy => Valid.Gate.Process_Policy,
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => True,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
   begin
      return Validate_User_Opt_In_Build_Command_Context
          (Empty_User_Opt_In_Build_Command_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Request) =
          User_Build_Context_Rejected_Missing_Request
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Gate) =
          User_Build_Context_Rejected_Missing_Gate
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Test_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Project_Context) =
          User_Build_Context_Rejected_Implicit_Source
        and then Validate_User_Opt_In_Build_Command_Context (Fixture_Context) =
          User_Build_Context_Rejected_Provenance
        and then Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
          User_Build_Context_Rejected_Custom_Tool
        and then Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
          User_Build_Context_Rejected_Opaque_Arguments
        and then Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
          User_Build_Context_Rejected_Shell
        and then Validate_User_Opt_In_Build_Command_Context (Working_Context) =
          User_Build_Context_Rejected_Working_Context
        and then Validate_User_Opt_In_Build_Command_Context (No_Diagnostics_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Show_Diagnostics_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Ambiguous_Context) =
          User_Build_Context_Rejected_Ambiguous_Execution_Path;
   end Audit_Build_Command_Rejection_Matrix;

   function Run_Build_Execution_Consent_Audit
     (State : Editor.State.State_Type)
      return Build_Execution_Consent_Audit_Result
   is
      pragma Unreferenced (State);
      Valid_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Implicit_Source,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid_Context.Gate);
      Missing_Gate : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Default_Execution_Gate);
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           Build_Real_Execution_Gate
             (Consent => Build_Consent_Not_Provided));
      Result : Build_Execution_Consent_Audit_Result;
      D : constant Editor.Commands.Descriptors.Command_Descriptor :=
        Editor.Commands.Descriptors.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Result.Has_Public_Build_Command :=
        Editor.Commands.Build_Terminal_Ids.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Run);
      Result.Has_Default_Build_Keybinding :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam).Has_Binding;
      Result.Internal_Command_Requires_Context :=
        D.Category = Editor.Commands.Descriptors.Internal_Category
        and then D.Visibility = Editor.Commands.Descriptors.Hidden_Command
        and then not D.Bindable
        and then Editor.Commands.Availability_Metadata.Requires_Context
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam)
        and then not Editor.Commands.Classification.Visible_In_Command_Palette
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Result.Internal_Command_Requires_Provenance :=
        Validate_User_Opt_In_Build_Command_Context
          (Empty_User_Opt_In_Build_Command_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context
          ((Has_Request => True,
            Request     =>
              (Tool                 => GPRbuild_Tool,
               Provenance           => Build_Request_From_Internal_Command,
               Working_Label        => Null_Unbounded_String,
               Command_Label        => To_Unbounded_String ("gprbuild"),
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_Process_Argument_Vector ("-q")),
            Gate        => Valid_Context.Gate)) =
          User_Build_Context_Rejected_Provenance;
      Result.Internal_Command_Requires_Gate :=
        Validate_User_Opt_In_Build_Command_Context (Missing_Gate) =
        User_Build_Context_Rejected_Missing_Gate;
      Result.Internal_Command_Requires_Consent :=
        Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
        User_Build_Context_Rejected_Missing_Consent;
      Result.Rejects_Implicit_Source :=
        Validate_User_Opt_In_Build_Command_Context (Project_Context) =
        User_Build_Context_Rejected_Implicit_Source;
      Result.Rejects_Custom_Tool :=
        Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
        User_Build_Context_Rejected_Custom_Tool;
      Result.Rejects_Shell :=
        Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
        User_Build_Context_Rejected_Shell;
      Result.Rejects_Opaque_Arguments :=
        Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
        User_Build_Context_Rejected_Opaque_Arguments;
      Result.Routes_Diagnostics_Through_Pipeline :=
        Editor.External_Producers.Diagnostic_Line_Pipeline.
          Diagnostic_Line_Command_Surface_Audit_Passes
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.
          Diagnostic_Line_Layering_Audit_Passes;
      Result.Passed :=
        Result.Has_Public_Build_Command
        and then not Result.Has_Default_Build_Keybinding
        and then Result.Internal_Command_Requires_Context
        and then Result.Internal_Command_Requires_Provenance
        and then Result.Internal_Command_Requires_Gate
        and then Result.Internal_Command_Requires_Consent
        and then Result.Rejects_Implicit_Source
        and then Result.Rejects_Custom_Tool
        and then Result.Rejects_Shell
        and then Result.Rejects_Opaque_Arguments
        and then Result.Routes_Diagnostics_Through_Pipeline
        and then Audit_Build_Command_Rejection_Matrix;
      return Result;
   end Run_Build_Execution_Consent_Audit;

end Editor.External_Producers.Build_Runner_Audits;
