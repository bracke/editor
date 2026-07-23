with Ada.Calendar;
with Ada.Containers;
with Ada.Directories;
with Editor.State;
with Ada.Characters.Handling;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Editor.Build_Process_Control;
with Editor.Image_Helpers;

with Hostkit;
with Hostkit.Process;
with Editor.Build_Output_Details;
with Editor.Build_Runner_Policy;
with Editor.Buffers;
with Editor.Commands;
with Editor.Keybindings;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Targets;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Request_Policies;
with Editor.External_Producers.Diagnostic_Normalization;
with Editor.Producer_Contracts;
with Editor.Project;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Build_Runner_Audits;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Public_Build_Command_Surface_Audits;
with Editor.External_Producers.Public_Build_Guardrail_Audits;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Source_Metadata;
with GNAT.OS_Lib;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

use type Ada.Containers.Count_Type;

package body Editor.External_Producers is

   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;

   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Id;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;

   function Producer_Kind_Is_Valid
     (Kind : External_Producer_Kind) return Boolean
     renames Editor.External_Producers.Source_Metadata.Producer_Kind_Is_Valid;

   function Stable_Name
     (Kind : External_Producer_Kind) return String
     renames Editor.External_Producers.Source_Metadata.Stable_Name;

   function Display_Label
     (Kind : External_Producer_Kind) return String
     renames Editor.External_Producers.Source_Metadata.Display_Label;

   function Build_External_Producer_Source
     (Kind : External_Producer_Kind) return External_Producer_Source
     renames Editor.External_Producers.Source_Metadata.Build_External_Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return External_Producer_Source
     renames Editor.External_Producers.Source_Metadata.Build_Compiler_Diagnostics_Producer_Source;

   function Producer_Source_Is_Valid
     (Producer : External_Producer_Source) return Boolean
     renames Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : External_Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind
     renames Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Compiler_Diagnostic_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
     renames Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity;


   function Parse_Compiler_Diagnostic_Severity
     (Token : String) return Compiler_Diagnostic_Severity
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Severity;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "") return Diagnostic_Line_Parse_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Line;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Diagnostic_Text_Line_Array;
      Tool_Name : String := "") return Diagnostic_Line_Batch_Parse_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Lines;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Diagnostic_Line_Batch_Parse_Result) return Boolean
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Assert_Diagnostic_Line_Batch_Consistent;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Parsed   : Diagnostic_Line_Parse_Result) return External_Diagnostic_Record
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Normalize_Parsed_Compiler_Diagnostic;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Lines    : Diagnostic_Text_Line_Array) return Diagnostic_Line_Ingestion_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Compiler_Diagnostic_Lines;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Diagnostic_Line_Ingestion_Result) return Boolean
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Ingestion_Result_Is_Consistent;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Diagnostic_Line_Ingestion_Result)
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Assert_Diagnostic_Line_Ingestion_Result_Consistent;

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Diagnostic_Line_Ingestion_Result)
      return Diagnostic_Line_Command_Outcome
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Classify_Diagnostic_Line_Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Diagnostic_Line_Ingestion_Result) return String
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Build_Diagnostic_Line_Command_Feedback;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Diagnostic_Line_Ingestion_Result) return String
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Format_Diagnostic_Line_Ingestion_Result;

   function Empty_Diagnostic_Line_Command_Result
     return Diagnostic_Line_Command_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Empty_Diagnostic_Line_Command_Result;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Diagnostic_Lines_From_Command;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Diagnostic_Lines_From_Command_With_Tool_Label;

   function Diagnostic_Line_Parser_Audit_Passes return Boolean
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Parser_Audit_Passes;

   function Diagnostic_Line_Command_Surface_Audit_Passes return Boolean
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Command_Surface_Audit_Passes;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean
      renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Layering_Audit_Passes;

   function Build_Status_Label (Status : Build_Run_Status) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Status_Label;

   function Build_Default_Execution_Gate return Build_Execution_Gate
     renames Editor.External_Producers.Execution_Policy.Build_Default_Execution_Gate;

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

   function Validate_Build_Execution_Consent
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Validate_Build_Execution_Consent;

   function Validate_Build_Execution_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Validate_Build_Execution_Gate;

   function Assert_Build_Execution_Gate_Consistent
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Assert_Build_Execution_Gate_Consistent;

   function Select_Process_Runner_Mode
     (Gate   : Build_Execution_Gate;
      Policy : Process_Execution_Policy) return Process_Execution_Mode
     renames Editor.External_Producers.Execution_Policy.Select_Process_Runner_Mode;

   function Build_Cancellation_Unsupported_Process_Result
     return Process_Run_Result
     renames Editor.External_Producers.Execution_Policy.Build_Cancellation_Unsupported_Process_Result;

   function Current_Native_Process_Control_Backend
     return Native_Process_Control_Backend
     renames Editor.External_Producers.Execution_Policy.Current_Native_Process_Control_Backend;

   function Native_Process_Control_Backend_Label return String
     renames Editor.External_Producers.Execution_Policy.Native_Process_Control_Backend_Label;

   function Native_Process_Control_Is_POSIX return Boolean
     renames Editor.External_Producers.Execution_Policy.Native_Process_Control_Is_POSIX;

   function Native_Process_Control_Platform_Audit_Passes return Boolean
     renames Editor.External_Producers.Execution_Policy.Native_Process_Control_Platform_Audit_Passes;

   function Real_Process_Runner_Output_Capture_Mode
     return Process_Output_Capture_Mode
     renames Editor.External_Producers.Execution_Policy.Real_Process_Runner_Output_Capture_Mode;

   function Diagnostic_Stream_Preference
     (Result : Process_Run_Result) return Process_Diagnostic_Stream_Preference
     renames Editor.External_Producers.Execution_Policy.Diagnostic_Stream_Preference;

   function Process_Result_Output_Stream
     (Result : Process_Run_Result) return Process_Output_Stream
     renames Editor.External_Producers.Execution_Policy.Process_Result_Output_Stream;

   function Build_Result_Output_Stream
     (Result : Build_Run_Result) return Process_Output_Stream
     renames Editor.External_Producers.Execution_Policy.Build_Result_Output_Stream;

   function Build_Run_Diagnostic_Stream_Preference
     (Result : Build_Run_Result) return Process_Diagnostic_Stream_Preference
     renames Editor.External_Producers.Execution_Policy.Build_Run_Diagnostic_Stream_Preference;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Build_Unsupported_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Unsupported_Working_Context;

   function Build_Inherited_Test_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Inherited_Test_Working_Context;

   function Build_Explicit_Label_Working_Context
     (Label : String) return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Explicit_Label_Working_Context;

   function Contains_Control_Character (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Control_Character;

   function Contains_Shell_Syntax (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Shell_Syntax;

   function Contains_Path_Separator (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Path_Separator;

   function Looks_Project_Derived_Label (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Looks_Project_Derived_Label;

   function Looks_Path_Like_Label (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Looks_Path_Like_Label;


   function Validate_Public_Build_Consent
     (Consent : Public_Build_Consent_Model)
      return Public_Build_Consent_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Consent;

   function Classify_Public_Build_Consent_Safety
     (Consent : Public_Build_Consent_Model) return Public_Build_Input_Safety
      renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Consent_Safety;

   function Build_Execution_Consent_From_Public_Model
     (Consent : Public_Build_Consent_Model) return Build_Execution_Consent
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Execution_Consent_From_Public_Model;

   function Build_Public_Build_Consent_Feedback
     (Status : Public_Build_Consent_Validation_Status) return String
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Consent_Feedback;

   function Audit_Public_Build_Consent_Readiness return Boolean
      renames Editor.External_Producers.Public_Build_Input_Validation.Audit_Public_Build_Consent_Readiness;

   function Validate_Public_Build_Working_Context
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Working_Context_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Working_Context;

   function Classify_Public_Build_Working_Context_Safety
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Input_Safety
      renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Working_Context_Safety;

   function Build_Working_Context_From_Public_Model
     (Context : Public_Build_Working_Context_Model) return Build_Working_Context
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Working_Context_From_Public_Model;

   function Assert_Public_Build_Working_Context_Conversion_Consistent
     (Model   : Public_Build_Working_Context_Model;
      Context : Build_Working_Context) return Boolean
      renames Editor.External_Producers.Public_Build_Input_Validation.Assert_Public_Build_Working_Context_Conversion_Consistent;

   function Build_Public_Build_Working_Context_Feedback
     (Status : Public_Build_Working_Context_Validation_Status) return String
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Working_Context_Feedback;

   function Audit_Public_Build_Working_Context_Readiness return Boolean
      renames Editor.External_Producers.Public_Build_Input_Validation.Audit_Public_Build_Working_Context_Readiness;

   function Validate_Public_Build_Program_Label
     (Program_Label : Ada.Strings.Unbounded.Unbounded_String)
      return Public_Build_Input_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Program_Label;

   function Validate_Public_Build_Working_Context
     (Source  : Public_Build_Input_Source;
      Context : Build_Working_Context)
      return Public_Build_Input_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Working_Context;

   function Validate_Public_Build_Arguments
     (Source    : Public_Build_Input_Source;
      Arguments : Process_Argument_Vector)
      return Public_Build_Input_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Arguments;

   function Validate_Public_Build_Command_Input
     (Input : Public_Build_Command_Input)
      return Public_Build_Input_Validation_Status
      renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Command_Input;

   function Classify_Public_Build_Input_Safety
     (Input : Public_Build_Command_Input) return Public_Build_Input_Safety
      renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Input_Safety;

   function Build_User_Opt_In_Request_From_Public_Input
     (Input : Public_Build_Command_Input) return Build_Run_Request
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_User_Opt_In_Request_From_Public_Input;

   function Build_Public_Build_Request_From_UI_State
     (Input : Public_Build_Command_Input) return Build_Run_Request
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Request_From_UI_State;

   function Build_Public_Build_Input_Feedback
     (Status : Public_Build_Input_Validation_Status) return String
      renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Input_Feedback;

   function Audit_Public_Build_Input_Model_Readiness return Boolean
      renames Editor.External_Producers.Public_Build_Input_Validation.Audit_Public_Build_Input_Model_Readiness;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_One_Process_Argument;

   function Build_User_Opt_In_Request
     (Tool          : Build_Tool_Kind;
      Program_Label : String;
      Working_Label : String;
      Arguments     : Process_Argument_Vector) return Build_Run_Request
   is
   begin
      return
        (Tool                 => Tool,
         Provenance           => Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String (Working_Label),
         Command_Label        => To_Unbounded_String (Program_Label),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Arguments);
   end Build_User_Opt_In_Request;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Run_Request_Status;

   function Validate_Build_Run_Request
     (Request : Build_Run_Request) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Build_Run_Request;

   function Validate_User_Opt_In_Build_Request
     (Request : Build_Run_Request) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_User_Opt_In_Build_Request;

   function Build_Request_Rejection_Feedback
     (Status : Build_Request_Validation_Status) return String
     renames Editor.External_Producers.Request_Policies.Build_Request_Rejection_Feedback;

   function Validate_Build_Request_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Request_Provenance;

   function Validate_Build_Working_Context
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Working_Context;

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

   function Execute_Process_Request_Default
     (Request : Process_Run_Request) return Process_Run_Result
     renames Editor.External_Producers.Request_Policies.Execute_Process_Request_Default;

   function Empty_Process_Arguments return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

   procedure Append_Process_Argument
     (Arguments : in out Process_Argument_Vector;
      Value     : String)
     renames Editor.External_Producers.Request_Policies.Append_Process_Argument;

   function Process_Argument_Count
     (Arguments : Process_Argument_Vector) return Natural
     renames Editor.External_Producers.Request_Policies.Process_Argument_Count;

   function Build_Default_Timeout_Milliseconds return Natural
     renames Editor.External_Producers.Request_Policies.Build_Default_Timeout_Milliseconds;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Build_Timeout_Policy_Is_Bounded;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Process_Execution_Policy;

   function Looks_Absolute_Program (Program : String) return Boolean
     renames Editor.External_Producers.Request_Policies.Looks_Absolute_Program;

   function Validate_Process_Run_Request_For_Real_Execution_Status
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Process_Run_Request_For_Real_Execution_Status;

   function Validate_Process_Run_Request_For_Real_Execution
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Process_Run_Request_For_Real_Execution;

   function Process_Request_Rejection_Feedback
     (Status : Process_Request_Validation_Status) return String
     renames Editor.External_Producers.Request_Policies.Process_Request_Rejection_Feedback;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Build_Run_Request;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Real_Build_Tool_Request;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_User_Opt_In_Build_Request;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_User_Opt_In_Build_Feedback;

   function Empty_User_Opt_In_Build_Command_Context
      return User_Opt_In_Build_Command_Context
     renames Editor.External_Producers.Build_Command_Execution.Empty_User_Opt_In_Build_Command_Context;

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

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status
   is
      Request : constant Build_Run_Request := Context.Request;
      Gate    : constant Build_Execution_Gate := Context.Gate;
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      --  command-context validation is deliberately pure metadata
      --  classification. It does not execute, select a runner, inspect PATH,
      --  read project files, ingest Diagnostics, switch features, or retain any
      --  command request/gate/consent handle.
      if not Context.Has_Request then
         return User_Build_Context_Rejected_Missing_Context;
      end if;

      if Request.Provenance = Build_Request_Unknown
        and then Request.Tool = No_Build_Tool
        and then Clean_Command'Length = 0
        and then Request.Structured_Arguments.Is_Empty
      then
         return User_Build_Context_Rejected_Missing_Request;
      end if;

      if not Gate.Allow_Build_Run
        and then Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Gate.Process_Policy.Allow_Real_Execution
      then
         return User_Build_Context_Rejected_Missing_Gate;
      end if;

      if Gate.Consent = Build_Consent_Not_Provided then
         return User_Build_Context_Rejected_Missing_Consent;
      elsif Gate.Consent /= Build_Consent_User_Confirmed then
         return User_Build_Context_Rejected_Missing_Consent;
      end if;

      case Request.Provenance is
         when Build_Request_From_User_Opt_In =>
            null;
         when Build_Request_From_Implicit_Source =>
            return User_Build_Context_Rejected_Implicit_Source;
         when Build_Request_From_Test
            | Build_Request_From_Fixture
            | Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return User_Build_Context_Rejected_Provenance;
      end case;

      case Request.Tool is
         when No_Build_Tool | Custom_Build_Tool =>
            return User_Build_Context_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      if Length (Request.Arguments) > 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty or else Clean_Command'Length = 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return User_Build_Context_Rejected_Shell;
      end if;

      if Ada.Strings.Fixed.Trim
          (To_String (Request.Working_Label), Both)'Length > 0
      then
         return User_Build_Context_Rejected_Working_Context;
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Max_Output_Bytes = 0
        or else not Validate_Build_Execution_Gate (Gate)
      then
         return User_Build_Context_Rejected_Ambiguous_Execution_Path;
      end if;

      return User_Build_Context_Valid;
   end Validate_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
   begin
      case Status is
         when User_Build_Context_Valid =>
            case Result.Build_Result.Status is
               when Build_Run_Succeeded =>
                  if Ingested > 0 then
                     return "Build: succeeded, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: succeeded";
                  end if;
               when Build_Run_Failed =>
                  if Ingested > 0 then
                     return "Build: failed, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: failed";
                  end if;
               when Build_Run_Not_Available =>
                  return "Build: real execution unavailable";
               when Build_Run_Rejected =>
                  return "Build: rejected";
               when Build_Run_Execution_Error =>
                  return "Build: execution error";
               when Build_Run_Timed_Out =>
                  return "Build failed: timed out";
               when Build_Run_Cancelled =>
                  return "Build cancelled";
               when Build_Run_Cancellation_Unsupported =>
                  return "Build unavailable: cancellation unsupported";
               when Build_Run_Output_Truncated =>
                  return "Build: output truncated";
            end case;
         when User_Build_Context_Rejected_Missing_Context
            | User_Build_Context_Rejected_Missing_Request
            | User_Build_Context_Rejected_Provenance =>
            return "Build: user opt-in required";
         when User_Build_Context_Rejected_Missing_Gate =>
            return "Build: real build execution disabled";
         when User_Build_Context_Rejected_Missing_Consent =>
            return "Build: execution consent required";
         when User_Build_Context_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when User_Build_Context_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when User_Build_Context_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when User_Build_Context_Rejected_Shell =>
            return "Build: shell execution disabled";
         when User_Build_Context_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when User_Build_Context_Rejected_Ambiguous_Execution_Path =>
            return "Build: invalid build command context";
      end case;
   end Build_User_Opt_In_Command_Feedback;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean
   is
   begin
      return Context.Has_Request;
   end User_Opt_In_Build_Command_Context_Is_Available;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid
        or else Result.Process_Request_Status /= Process_Request_Valid
      then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Program_Label), Both)'Length > 0
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Arguments), Both)'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end User_Opt_In_Build_Preflight_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Preflight_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Preflight_Consistent;

   function User_Opt_In_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
   begin
      if Message'Length = 0 then
         return False;
      end if;

      if Result.Build_Result.Status in Build_Run_Rejected | Build_Run_Not_Available then
         return Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0;
      end if;

      return Gated_Build_Command_Result_Is_Consistent (Result);
   end User_Opt_In_Build_Command_Result_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Command_Result_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Command_Result_Consistent;

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean
   is
   begin
      case Fixture is
         when No_Real_Build_Tool_Fixture =>
            return False;
         when GPRbuild_Version_Fixture
            | Alire_Version_Fixture
            | Diagnostic_Output_Fixture =>
            return True;
      end case;
   end Real_Build_Tool_Fixture_Is_Approved;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate)
        and then Gate.Allow_Build_Run
        and then Gate.Allow_Real_Build_Tool_Fixture
        and then not Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
        and then Gate.Process_Policy.Allow_Real_Execution
        and then not Gate.Process_Policy.Allow_Shell
        and then Gate.Process_Policy.Max_Output_Bytes > 0;
   end Validate_Real_Build_Tool_Fixture_Gate;


   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Working_Status : Process_Request_Validation_Status;
      Clean_Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      --  fixture validation is a pure metadata check. It does not
      --  execute, inspect PATH, read project files, inspect workspace state,
      --  ingest diagnostics, mutate feature state, or infer fixture identity
      --  from command labels, program labels, argv, project-file inputs, settings,
      --  or command-palette visibility.
      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return Real_Build_Fixture_Rejected_Ambiguous_Gate;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return Real_Build_Fixture_Rejected_Shell;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Real_Build_Fixture_Rejected_Disabled;
      end if;

      if not Real_Build_Tool_Fixture_Is_Approved (Fixture) then
         return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end if;

      case Request.Provenance is
         when Build_Request_From_Implicit_Source =>
            return Real_Build_Fixture_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In
            | Build_Request_From_Test
            | Build_Request_From_Fixture =>
            null;
         when Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return Real_Build_Fixture_Rejected_Provenance;
      end case;

      if Build_Status = Build_Request_Rejected_Implicit_Source then
         return Real_Build_Fixture_Rejected_Implicit_Source;
      elsif Build_Status /= Build_Request_Valid then
         if Request.Tool = Custom_Build_Tool then
            return Real_Build_Fixture_Rejected_Custom_Tool;
         else
            return Real_Build_Fixture_Rejected_Provenance;
         end if;
      end if;

      if Request.Tool = Custom_Build_Tool then
         return Real_Build_Fixture_Rejected_Custom_Tool;
      end if;

      case Fixture is
         when GPRbuild_Version_Fixture =>
            if Request.Tool /= GPRbuild_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Alire_Version_Fixture =>
            if Request.Tool /= Alire_Build_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Diagnostic_Output_Fixture =>
            null;
         when No_Real_Build_Tool_Fixture =>
            return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end case;

      Working_Status := Validate_Build_Working_Context (Request, Gate);
      if Working_Status /= Process_Request_Valid then
         return Real_Build_Fixture_Rejected_Working_Context;
      end if;

      if Clean_Opaque'Length > 0 or else not Request.Structured_Arguments.Is_Empty then
         return Real_Build_Fixture_Rejected_Opaque_Arguments;
      end if;

      return Real_Build_Fixture_Valid;
   end Validate_Real_Build_Tool_Fixture_Request;

   function Real_Build_Tool_Fixture_Status_To_Build_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Build_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Build_Request_Valid;
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Real_Build_Fixture_Rejected_Custom_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when Real_Build_Fixture_Rejected_Provenance =>
            return Build_Request_Rejected_Provenance;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Shell
            | Real_Build_Fixture_Rejected_Opaque_Arguments
            | Real_Build_Fixture_Rejected_Working_Context
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Build_Request_Valid;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Build_Status;

   function Real_Build_Tool_Fixture_Status_To_Process_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Process_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Process_Request_Valid;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Real_Build_Fixture_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Real_Build_Fixture_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Real_Build_Fixture_Rejected_Working_Context =>
            return Process_Request_Rejected_Unsupported_Working_Directory;
         when Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Implicit_Source
            | Real_Build_Fixture_Rejected_Custom_Tool =>
            return Process_Request_Rejected_Execution_Disabled;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Process_Status;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return "Build: build fixture accepted";
         when Real_Build_Fixture_Rejected_Disabled =>
            return "Build: real build fixture disabled";
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when Real_Build_Fixture_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when Real_Build_Fixture_Rejected_Shell =>
            return "Build: shell execution disabled";
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Real_Build_Fixture_Not_Available =>
            return "Build: build fixture unavailable";
         when Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Custom_Tool
            | Real_Build_Fixture_Rejected_Ambiguous_Gate =>
            return "Build: build fixture rejected";
      end case;
   end Real_Build_Tool_Fixture_Rejection_Feedback;

   function Validate_Real_Build_Tool_Fixture_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            --  No internal-command gate exists. Keep internal commands
            --  rejected rather than inferring fixture opt-in from command labels.
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Real_Build_Tool_Fixture_Provenance;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request
   is
      pragma Unreferenced (Request);
   begin
      case Fixture is
         when GPRbuild_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Alire_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Diagnostic_Output_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("diagnostic-output-fixture"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument
                 ("--diagnostic-output-fixture"));
         when No_Real_Build_Tool_Fixture =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Real_Build_Tool_Fixture_Process_Request;

   function Validate_Real_Build_Tool_Fixture_Process_Request
     (Request : Process_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Process_Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Max_Output_Bytes = 0 then
         return Process_Request_Rejected_Invalid_Argument;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Opaque_Args'Length > 0 then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      for Arg of Request.Structured_Arguments loop
         declare
            Value : constant String := To_String (Arg);
         begin
            if Value'Length = 0 or else Contains_Control_Character (Value) then
               return Process_Request_Rejected_Invalid_Argument;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Real_Build_Tool_Fixture_Process_Request;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Build_Status : constant Build_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Build_Status (Validation);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Process_Status (Validation);
   begin
      if Validation /= Real_Build_Fixture_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Real_Build_Tool_Fixture_Process_Request
        (Request, Fixture);
      Process_Status := Validate_Real_Build_Tool_Fixture_Process_Request
        (Process_Request, Gate);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Fixture;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
   begin
      if Build_Result.Status = Build_Run_Not_Available then
         return "Build: build fixture unavailable";
      elsif Build_Result.Status = Build_Run_Rejected then
         return "Build: build fixture rejected";
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
        and then Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0
      then
         return Build_Status_Label (Build_Result.Status)
           & ", no diagnostics parsed";
      else
         return Build_Build_Command_Feedback (Build_Result, Diagnostic_Result);
      end if;
   end Build_Real_Build_Tool_Fixture_Feedback;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         return not Result.Has_Process_Request
           and then Result.Process_Request_Status /= Process_Request_Valid;
      end if;

      if Result.Process_Request_Status = Process_Request_Valid then
         return Result.Has_Process_Request;
      end if;

      return not Result.Has_Process_Request;
   end Build_Preflight_Result_Is_Consistent;


   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
      Program : constant String := To_String (Result.Process_Request.Program_Label);
      Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Result.Process_Request.Arguments), Both);
   begin
      if not Build_Preflight_Result_Is_Consistent (Result) then
         return False;
      end if;

      if Result.Build_Request_Status = Build_Request_Rejected_Implicit_Source
        and then Result.Has_Process_Request
      then
         return False;
      end if;

      if Result.Process_Request_Status /= Process_Request_Valid then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Program'Length > 0
        and then Opaque'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
   begin
      if Message'Length = 0 then
         return False;
      end if;

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

      if Result.Build_Result.Status = Build_Run_Not_Available
        and then Message = "Build: succeeded"
      then
         return False;
      end if;

      if Result.Build_Result.Status = Build_Run_Execution_Error
        and then Ingested > 0
      then
         return False;
      end if;

      if Ingested = 0 and then Parsed = 0 then
         return Message'Length > 0;
      end if;

      return True;
   end Real_Build_Tool_Fixture_Command_Result_Is_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Preflight_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Preflight_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Command_Result_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Command_Result_Consistent;

   function Enforce_Process_Output_Bounds
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Process_Run_Result
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      return Result;
   end Enforce_Process_Output_Bounds;

   function Process_Fixture_Result_Is_Consistent
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Boolean
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return False;
      end if;

      case Result.Status is
         when Process_Run_Succeeded | Process_Run_Failed =>
            return Result.Has_Exit_Code;
         when Process_Run_Not_Available | Process_Run_Rejected
            | Process_Run_Execution_Error
            | Process_Run_Cancellation_Unsupported =>
            return not Result.Has_Exit_Code
              and then Length (Result.Stdout_Text) = 0
              and then Length (Result.Stderr_Text) = 0;
         when Process_Run_Timed_Out | Process_Run_Cancelled
            | Process_Run_Output_Truncated =>
            return not Result.Has_Exit_Code;
      end case;
   end Process_Fixture_Result_Is_Consistent;

   procedure Assert_Process_Fixture_Result_Consistent
     (Result : Process_Run_Result)
   is
      Conservative_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Fixture_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   begin
      pragma Assert
        (Process_Fixture_Result_Is_Consistent (Result, Conservative_Policy));
   end Assert_Process_Fixture_Result_Consistent;

   function Execute_Test_Fed_Process_Request
     (Request         : Process_Run_Request;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Test_Fed_Process_Request;

   function Execute_Process_Request_Gated
     (Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Process_Request_Gated;

   function Execute_Process_Request_Real_Gated
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Process_Request_Real_Gated;

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_Process_Fixture_Request;

   function Validate_Process_Fixture_Request_Status
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_Process_Fixture_Request_Status;

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Process_Fixture_Request_Is_Valid;

   function Build_Process_Fixture_Request
     (Kind  : Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request
     renames Editor.External_Producers.Build_Command_Execution.Build_Process_Fixture_Request;

   procedure Append_With_Newline
     (Target : in out Unbounded_String;
      Value  : String)
     renames Editor.External_Producers.Build_Command_Execution.Append_With_Newline;

   procedure Append_Fixture_Output_Line
     (Target   : in out Unbounded_String;
      Has_Line : in out Boolean;
      Value    : String)
     renames Editor.External_Producers.Build_Command_Execution.Append_Fixture_Output_Line;

   function Execute_Process_Request_Real_Fixture
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Process_Request_Real_Fixture;

   function Build_Process_Fixture_Result
     (Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Build_Process_Fixture_Result;

   function Build_Result_From_Process_Result
     (Request : Build_Run_Request;
      Result  : Process_Run_Result) return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Build_Result_From_Process_Result;

   function Build_Build_Run_Result
     (Status           : Build_Run_Status;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : String := "";
      Stderr_Text      : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated;
      Diagnostic_Lines : Diagnostic_Text_Line_Array :=
        Diagnostic_Text_Line_Vectors.Empty_Vector) return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result;

   function Execute_Build_Request
     (Request : Build_Run_Request) return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Build_Request;

   function Execute_Test_Fed_Build_Request
     (Request         : Build_Run_Request;
      Supplied_Result : Build_Run_Result) return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Test_Fed_Build_Request;

   function Execute_Build_Request_With_Process_Policy
     (Request         : Build_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Build_Request_With_Process_Policy;

   procedure Append_Output_Text_Lines
     (Text  : String;
      Lines : in out Diagnostic_Text_Line_Array)
     renames Editor.External_Producers.Build_Command_Execution.Append_Output_Text_Lines;

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result) return Diagnostic_Text_Line_Array
     renames Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Ingest_Build_Run_Diagnostics;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_Build_Command_Feedback;

   function Run_Build_Command_Test_Seam
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Show_Diagnostics : Boolean := False) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_Test_Seam;

   function Run_Build_Command_Test_Seam_With_Runner
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Policy           : Process_Execution_Policy;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False);
      Show_Diagnostics : Boolean := False) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_Test_Seam_With_Runner;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_Gated_Build_Command_Feedback;

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String
     renames Editor.External_Producers.Build_Command_Execution.Process_Fixture_Rejection_Feedback;

   function Run_Build_Command_With_Gate
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
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

   function Run_Real_Build_Tool_Fixture_With_Gate
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Fixture          : Real_Build_Tool_Fixture_Kind;
      Gate             : Build_Execution_Gate;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Real_Build_Tool_Fixture_With_Gate;

   function Run_User_Opt_In_Build_Command_Test_Seam
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
     renames Editor.External_Producers.Build_Command_Execution.Run_User_Opt_In_Build_Command_Test_Seam;

   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : User_Opt_In_Build_Command_Context;
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
     renames Editor.External_Producers.Build_Command_Execution.Execute_User_Opt_In_Build_Command;

   function Build_Public_Build_Command_Surface
     return Public_Build_Command_Surface_Array renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_Command_Surface;

   function Validate_Public_Build_Command_Surface_Entry
     (Surface_Entry : Public_Build_Command_Surface_Entry)
      return Public_Build_Command_Surface_Status renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Validate_Public_Build_Command_Surface_Entry;

   procedure Assert_Public_Build_Command_Surface_Entry_Consistent
     (Surface_Entry : Public_Build_Command_Surface_Entry)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Assert_Public_Build_Command_Surface_Entry_Consistent;

   function Build_Public_Build_UX_Dependency_Matrix
     return Public_Build_UX_Dependency_Matrix
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_UX_Dependency_Matrix;

   function Primary_Public_Build_UX_Dependency_Blocker
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_UX_Dependency renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits.Primary_Public_Build_UX_Dependency_Blocker;

   function Validate_Public_Build_UX_Dependencies
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_Command_Promotion_Status
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Validate_Public_Build_UX_Dependencies;

   function Detect_Public_Build_Command_Exposure_Hard_Failure
     (Readiness : Public_Build_Command_Readiness_Audit_Result) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Detect_Public_Build_Command_Exposure_Hard_Failure;

   function Validate_Public_Build_Command_Promotion
     (Surface_Entry : Public_Build_Command_Surface_Entry;
      Readiness   : Public_Build_Command_Readiness_Audit_Result)
      return Public_Build_Command_Promotion_Status
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Validate_Public_Build_Command_Promotion;

   function Audit_Public_Build_Command_Visibility return Boolean renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Audit_Public_Build_Command_Visibility;

   procedure Assert_Public_Build_Command_Surface_Exposed renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Assert_Public_Build_Command_Surface_Exposed;

   function Audit_Public_Build_Command_UX_Dependencies return
     Public_Build_Command_UX_Dependency_Audit_Result renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Audit_Public_Build_Command_UX_Dependencies;

   function Build_Public_Command_Not_Ready_Feedback
     (Audit : Public_Build_Command_Readiness_Audit_Result) return String renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Command_Not_Ready_Feedback;


   function Build_Public_Command_Promotion_Feedback
     (Status : Public_Build_Command_Promotion_Status) return String renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Command_Promotion_Feedback;

   function Build_Public_Build_UX_Dependency_Feedback
     (Dependency : Public_Build_UX_Dependency) return String renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_UX_Dependency_Feedback;

   function Public_Build_Command_Surface_Ids return Command_Id_Vector
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Public_Build_Command_Surface_Ids;

   function Is_Public_Build_Surface_Id (Name : String) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Is_Public_Build_Surface_Id;

   function Public_Build_Public_Names_Not_Registered return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Public_Build_Public_Names_Not_Registered;

   function Build_Public_Build_Blocker_Summary
     return Public_Build_Blocker_Summary renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_Blocker_Summary;

   function Public_Build_Public_Name_Count return Natural renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Public_Build_Public_Name_Count;

   procedure Assert_Public_Build_Surface_Ids_Not_Reused renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Assert_Public_Build_Surface_Ids_Not_Reused;

   function Public_Build_Blocker_Precedence_Intact return Boolean renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Public_Build_Blocker_Precedence_Intact;

   procedure Assert_Public_Build_Blocker_Precedence renames
     Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Assert_Public_Build_Blocker_Precedence;

   function Run_Public_Build_Command_Hard_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Hard_Freeze_Audit_Result
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Run_Public_Build_Command_Hard_Freeze_Audit;

   function Build_Public_Build_Hard_Freeze_Baseline
     return Public_Build_Hard_Freeze_Baseline
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_Hard_Freeze_Baseline;

   function Detect_Public_Build_Hard_Freeze_Drift
     (State    : Editor.State.State_Type;
      Baseline : Public_Build_Hard_Freeze_Baseline)
      return Public_Build_Hard_Freeze_Drift_Result
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Detect_Public_Build_Hard_Freeze_Drift;

   function Build_Public_Build_Drift_Feedback
     (Result : Public_Build_Hard_Freeze_Drift_Result) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Build_Public_Build_Drift_Feedback;

   function Public_Build_Surface_Ids_Not_Publicly_Projected
     (State : Editor.State.State_Type) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Public_Build_Surface_Ids_Not_Publicly_Projected;

   procedure Assert_Public_Build_Audits_Agree
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits
       .Assert_Public_Build_Audits_Agree;

   function Run_Public_Build_Guardrail_Audit
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Result
   is
   begin
      return Editor.External_Producers.Public_Build_Guardrail_Audits
        .Run_Public_Build_Guardrail_Audit (State);
   end Run_Public_Build_Guardrail_Audit;

   function Detect_Public_Build_Guardrail_Contract_Mismatch
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
   is
   begin
      return Editor.External_Producers.Public_Build_Guardrail_Audits
        .Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   end Detect_Public_Build_Guardrail_Contract_Mismatch;

   procedure Assert_Public_Build_Guardrail_Default_Contract
     (Result : Public_Build_Guardrail_Result)
   is
   begin
      Editor.External_Producers.Public_Build_Guardrail_Audits
        .Assert_Public_Build_Guardrail_Default_Contract (Result);
   end Assert_Public_Build_Guardrail_Default_Contract;

   procedure Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
     (State  : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result)
   is
   begin
      Editor.External_Producers.Public_Build_Guardrail_Audits
        .Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
          (State, Result);
   end Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan;

   procedure Assert_Public_Build_Guardrail_State_Not_Persisted
     (State : Editor.State.State_Type)
   is
   begin
      Editor.External_Producers.Public_Build_Guardrail_Audits
        .Assert_Public_Build_Guardrail_State_Not_Persisted (State);
   end Assert_Public_Build_Guardrail_State_Not_Persisted;

   function Scan_Public_Build_Surface_Ids
     (Command_Id        : String := "";
      Display_Name     : String := "";
      Keybinding_Target : String := "";
      Runtime_Keybinding_Target : String := "";
      Palette_Row       : String := "";
      Executor_Route    : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "";
      Workspace_Name    : String := "")
      return Public_Build_Surface_Id_Scan_Result
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Scan_Public_Build_Surface_Ids;

   function Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Surface_Id_Scan_Domains_Checked;

   procedure Assert_Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Surface_Id_Scan_Domains_Checked;

   function Build_Public_Build_Guardrail_Audit_Trace
     return Public_Build_Guardrail_Audit_Trace
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Audit_Trace;

   function Public_Build_Guardrail_Audit_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Guardrail_Audit_Trace_Complete;

   procedure Assert_Public_Build_Guardrail_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Trace_Complete;

   function Compare_Public_Build_Guardrail_Snapshots
     (Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Compare_Public_Build_Guardrail_Snapshots;

   function Is_Internal_Public_Build_Test_Seam_Id (Name : String) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Is_Internal_Public_Build_Test_Seam_Id;

   function Build_Public_Build_Internal_Test_Seam_Exposure_Detail
     (Palette_Row       : String := "";
      Keybinding_Target : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "")
      return Public_Build_Guardrail_Failure_Detail
   is
   begin
      if Is_Internal_Public_Build_Test_Seam_Id (Palette_Row) then
         return
           (Kind       => Public_Build_Failure_Internal_Test_Seam_Exposure,
            Command_Id => To_Unbounded_String (Palette_Row),
            Domain     => To_Unbounded_String ("palette"));
      elsif Is_Internal_Public_Build_Test_Seam_Id (Keybinding_Target) then
         return
           (Kind       => Public_Build_Failure_Internal_Test_Seam_Exposure,
            Command_Id => To_Unbounded_String (Keybinding_Target),
            Domain     => To_Unbounded_String ("keybinding"));
      elsif Is_Internal_Public_Build_Test_Seam_Id (Invocation_Path) then
         return
           (Kind       => Public_Build_Failure_Internal_Test_Seam_Exposure,
            Command_Id => To_Unbounded_String (Invocation_Path),
            Domain     => To_Unbounded_String ("invocation"));
      elsif Is_Internal_Public_Build_Test_Seam_Id (Persisted_Name) then
         return
           (Kind       => Public_Build_Failure_Internal_Test_Seam_Exposure,
            Command_Id => To_Unbounded_String (Persisted_Name),
            Domain     => To_Unbounded_String ("persistence"));
      else
         return
           (Kind       => Public_Build_Failure_None,
            Command_Id => Null_Unbounded_String,
            Domain     => Null_Unbounded_String);
      end if;
   end Build_Public_Build_Internal_Test_Seam_Exposure_Detail;

   function Build_Public_Build_Guardrail_Health
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Health
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Health;

   function Build_Public_Build_Guardrail_Health_Feedback
     (Health : Public_Build_Guardrail_Health) return String
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Health_Feedback;

   procedure Assert_Public_Build_Guardrail_Health_Default
     (Health : Public_Build_Guardrail_Health)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Health_Default;

   procedure Assert_Public_Build_Guardrail_Health_Not_Persisted
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Health_Not_Persisted;

   procedure Assert_Public_Build_Guardrail_Default_Health
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Default_Health;



   function Build_Public_Build_Guardrail_Audit_Matrix
     return Public_Build_Guardrail_Audit_Matrix
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Audit_Matrix;

   function Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Guardrail_Audit_Matrix_Complete;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Audit_Matrix_Complete;

   function Public_Build_Surface_Commands_Executable return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Surface_Commands_Executable;

   function Build_Public_Build_Guardrail_Regression_Manifest
     (State : Editor.State.State_Type)
      return Public_Build_Guardrail_Regression_Manifest
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Regression_Manifest;

   function Build_Public_Build_Guardrail_Regression_Manifest_Feedback
     (Manifest : Public_Build_Guardrail_Regression_Manifest) return String
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Regression_Manifest_Feedback;

   procedure Assert_Public_Build_Guardrail_Regression_Manifest_Default
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Regression_Manifest_Default;

   function Public_Build_Guardrail_Audit_Matrix_Anchored
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
   is
   begin
      return Public_Build_Guardrail_Audit_Matrix_Complete (Matrix)
        and then Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
                   (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 = 31
        and then Matrix (Public_Build_Matrix_Normalized_Guardrail_Contract)
        and then Matrix (Public_Build_Matrix_Regression_Manifest)
        and then Matrix (Public_Build_Matrix_Audit_Trace_Completeness)
        and then Matrix (Public_Build_Matrix_Surface_Id_Domain_Coverage)
        and then Matrix (Public_Build_Matrix_Persistence_Exclusion_Scan)
        and then Matrix (Public_Build_Matrix_Lifecycle_Stability_Check)
        and then Matrix (Public_Build_Matrix_Side_Effect_Free_Audit_Check);
   end Public_Build_Guardrail_Audit_Matrix_Anchored;

   procedure Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
   is
      Result : constant Public_Build_Guardrail_Result :=
        Manifest.Health.Guardrail_Result;
      Contract_Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   begin
      --  every manifest field must be backed by raw/focused audit
      --  facts already present in the result, public-id scan, trace, mismatch,
      --  surface entry validation, or audit matrix.  No higher semantic helper is
      --  consulted here.
      if Manifest.Health.Healthy /=
        (Result.Status = Public_Build_Guardrail_Passed
         and then Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then Manifest.Health.Failure_Count = 0
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build guardrail health lacks direct backers";
      end if;

      if Manifest.Default_Contract_Matches /=
        (not Contract_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest default contract lacks direct backer";
      end if;

      if Manifest.Trace_Surface_Complete /=
        (Public_Build_Guardrail_Audit_Matrix_Complete
           (Build_Public_Build_Guardrail_Audit_Matrix)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Result.Audits_Consistent)
      then
         raise Program_Error with "public build manifest trace surface lacks direct backer";
      end if;

      if Manifest.Public_Command_Surface_Complete /=
        (Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan))
      then
         raise Program_Error with "public build manifest public domains lack direct backer";
      end if;

      if Manifest.Persistence_Exclusion_Clean /= Result.Persistence_Clean then
         raise Program_Error with "public build manifest persistence lacks direct backer";
      end if;

      if Manifest.Lifecycle_Stable /=
        (Manifest.Health.Failure_Count = 0
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest lifecycle lacks direct backer";
      end if;

      if Manifest.Public_Surface_Present /=
        (Result.No_Public_Command
         and then Result.No_Public_Keybinding
         and then Result.No_Public_Palette_Entry
         and then Result.No_Public_Bindable_Command)
      then
         raise Program_Error with "public build manifest public surface lacks direct backer";
      end if;

      if Manifest.Execution_Surface_Present /=
        (Result.No_Public_Executor_Route
         and then Result.No_Public_Invocation_Path
         and then Result.No_Public_Bindable_Command
         and then Result.Default_Execution_Disabled)
      then
         raise Program_Error with "public build manifest execution surface lacks direct backer";
      end if;

      if Manifest.Surface_Command_Executable /= Public_Build_Surface_Commands_Executable then
         raise Program_Error with "public build manifest surface entry state lacks direct backer";
      end if;

      if Manifest.Promotion_Blocked /= Result.Promotion_Blocked then
         raise Program_Error with "public build manifest promotion lacks direct backer";
      end if;

      if Manifest.Dependency_Blockers_Active /= Result.Dependency_Blockers_Active then
         raise Program_Error with "public build manifest dependency blockers lack direct backer";
      end if;

      if Manifest.Manifest_Healthy /=
        (Manifest.Health.Healthy
         and then Manifest.Default_Contract_Matches
         and then Manifest.Trace_Surface_Complete
         and then Manifest.Public_Command_Surface_Complete
         and then Manifest.Persistence_Exclusion_Clean
         and then Manifest.Lifecycle_Stable
         and then Manifest.Public_Surface_Present
         and then Manifest.Execution_Surface_Present
         and then Manifest.Surface_Command_Executable
         and then not Manifest.Promotion_Blocked
         and then not Manifest.Dependency_Blockers_Active)
      then
         raise Program_Error with "public build manifest health is not field-derived";
      end if;
   end Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
   is
   begin
      --  The regression manifest is the final semantic aggregation point.
      --  The only structure beside result/health/manifest that remains in this
      --  package is the coverage-only audit matrix, fixed at the       --  dimension set.
      if Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
           (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 /= 31
      then
         raise Program_Error with "public build guardrail audit matrix dimension drift";
      end if;
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete
        (Build_Public_Build_Guardrail_Audit_Matrix);
   end Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (State : Editor.State.State_Type)
   is
      Result   : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
      Health   : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
      Manifest : constant Public_Build_Guardrail_Regression_Manifest :=
        Build_Public_Build_Guardrail_Regression_Manifest (State);
   begin
      if Health.Guardrail_Result /= Result then
         raise Program_Error with "public build health does not reflect direct guardrail result";
      end if;
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
        (Manifest);
      if Manifest.Health /= Health then
         raise Program_Error with "public build manifest does not embed direct health";
      end if;
      if Result.Status /= Public_Build_Guardrail_Passed then
         raise Program_Error with "public build result status changed";
      end if;
   end Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only
   is
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
   begin
      if not Public_Build_Guardrail_Audit_Matrix_Complete (Matrix) then
         raise Program_Error with "public build guardrail audit matrix coverage incomplete";
      end if;
      if not Public_Build_Guardrail_Audit_Matrix_Anchored (Matrix) then
         raise Program_Error with "public build guardrail audit matrix lost coverage-only anchor";
      end if;
   end Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;

   procedure Assert_No_Public_Build_Execution_Path
     (State : Editor.State.State_Type)
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      Assert_Public_Build_Surface_Ids_Not_Reused;
      if not Audit.No_Public_Command_Registered
        or else not Audit.No_Public_Executor_Route
        or else not Audit.No_Public_Invocation_Path
        or else not Audit.No_Public_Default_Keybinding
        or else not Audit.No_Public_Command_Palette_Entry
        or else not Audit.No_Public_Bindable_Command
        or else not Audit.No_Default_Execution
      then
         raise Program_Error with "public build execution path exposed";
      end if;
   end Assert_No_Public_Build_Execution_Path;

   procedure Assert_Public_Build_Hard_Freeze_Not_Persisted
     (State : Editor.State.State_Type)
   is
      pragma Unreferenced (State);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      Assert_Public_Build_Surface_Ids_Not_Reused;
      if not Summary.Default_Execution_Disabled then
         raise Program_Error with "public build state persisted as command config";
      end if;
   end Assert_Public_Build_Hard_Freeze_Not_Persisted;

   function Build_Public_Build_Hard_Freeze_Feedback
     (Audit : Public_Build_Command_Hard_Freeze_Audit_Result) return String
   is
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      if Audit.Public_Exposure_Hard_Failure then
         return "Build: unsafe public command exposure detected";
      elsif not Audit.Passed then
         return "Build: public build hard-freeze failed";
      elsif Summary.Consent_UX_Missing then
         return "Build: consent UX not ready";
      elsif Summary.Working_Context_UX_Missing then
         return "Build: working directory UX not ready";
      elsif Summary.Implicit_Source_Unsupported then
         return "Build: explicit build request required";
      else
         return "Build: public command ready";
      end if;
   end Build_Public_Build_Hard_Freeze_Feedback;

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
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Test_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
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
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Result : Build_Execution_Consent_Audit_Result;
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Result.Has_Public_Build_Command :=
        Editor.Commands.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Run);
      Result.Has_Default_Build_Keybinding :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam).Has_Binding;
      Result.Internal_Command_Requires_Context :=
        D.Category = Editor.Commands.Internal_Category
        and then D.Visibility = Editor.Commands.Hidden_Command
        and then not D.Bindable
        and then Editor.Commands.Requires_Context
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam)
        and then not Editor.Commands.Visible_In_Command_Palette
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
        Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes;
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

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result
   is
   begin
      return Editor.External_Producers.Public_Build_Input_Validation
        .Run_Public_Build_Command_Readiness_Audit (State);
   end Run_Public_Build_Command_Readiness_Audit;

   function Audit_User_Opt_In_Build_Command_Surface return Boolean is
   begin
      return Editor.External_Producers.Build_Runner_Audits
        .Audit_User_Opt_In_Build_Command_Surface;
   end Audit_User_Opt_In_Build_Command_Surface;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean is
   begin
      return Editor.External_Producers.Build_Runner_Audits.Gated_Build_Command_Result_Is_Consistent
        (Result, Diagnostics_Ingestion_Allowed);
   end Gated_Build_Command_Result_Is_Consistent;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result) is
   begin
      Editor.External_Producers.Build_Runner_Audits.Assert_Gated_Build_Command_Result_Consistent
        (Result);
   end Assert_Gated_Build_Command_Result_Consistent;

   function Process_Runner_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Process_Runner_Audit_Passes;

   function Audit_Process_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Execution_Gates;

   function Audit_Build_Runner_Timeout_Cancellation_Safety return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Runner_Timeout_Cancellation_Safety;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Runner_Output_Stream_Capture;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Argv_And_Preflight_Gates;


   function Audit_Real_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Real_Build_Execution_Gates;

   function Audit_User_Opt_In_Build_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_User_Opt_In_Build_Gates;

   function Audit_Real_Build_Tool_Fixture_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Real_Build_Tool_Fixture_Gates;

   function Audit_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Execution_Gates;

   function Audit_Gated_Runner_Command_Path return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Gated_Runner_Command_Path;

   function Audit_Process_Fixture_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Fixture_Gates;

   function Build_Run_Test_Seam_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Run_Test_Seam_Audit_Passes;


   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  build/process runs are synchronous and retain no run id, pending
      --  result, late-delivery queue, output text, or build-owned feature state.
      null;
   end Reset_Build_Run_State_For_Project_Close;

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Workspace close has no build-run test seam state to clear in .
      null;
   end Reset_Build_Run_State_For_Workspace_Close;

   procedure Reset_Diagnostic_Line_Command_State_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Synchronous-only invariant: command-facing diagnostic-line ingestion
      --  stores no run id, no pending output, no retained lines, and no live
      --  buffer handles outside Diagnostics-owned rows.  Project close therefore
      --  has no command-ingestion state to clear.
      null;
   end Reset_Diagnostic_Line_Command_State_For_Project_Close;

   procedure Reset_Diagnostic_Line_Command_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Synchronous-only invariant: workspace close preserves pure parser and
      --  normalizer helpers and stable command descriptors; no transient
      --  diagnostic-line command state is retained here.
      null;
   end Reset_Diagnostic_Line_Command_State_For_Workspace_Close;

   function Is_Diagnostic_Path_Absolute
     (Path : String) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Is_Diagnostic_Path_Absolute;

   function Starts_With_Case_Insensitive
     (Text   : String;
      Prefix : String) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Starts_With_Case_Insensitive;

   function Diagnostic_Path_Has_Parent_Traversal
     (Path : String) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Diagnostic_Path_Has_Parent_Traversal;

   function Diagnostic_Label_Project_Bounded
     (S          : Editor.State.State_Type;
      File_Label : String) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Diagnostic_Label_Project_Bounded;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Buffer_Target_Resolution
     renames Editor.External_Producers.Diagnostic_Normalization.Resolve_Diagnostic_File_Target;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String
     renames Editor.External_Producers.Diagnostic_Normalization.Build_Normalized_Diagnostic_Source_Label;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Input    : Compiler_Diagnostic_Record)
      return External_Diagnostic_Record
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_Compiler_Diagnostic;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Inputs   : Compiler_Diagnostic_Record_Array)
      return Normalized_Diagnostic_Batch
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_Compiler_Diagnostic_Batch;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Inputs   : Compiler_Diagnostic_Record_Array)
      return Producer_Batch_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Compiler_Diagnostic_Batch;

   function Assert_Normalized_Batch_Consistent
     (Batch : Normalized_Diagnostic_Batch) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Assert_Normalized_Batch_Consistent;

   function Compiler_Diagnostic_Normalization_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Compiler_Diagnostic_Normalization_Audit_Passes;

   function Producer_Lifecycle_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Producer_Lifecycle_Audit_Passes;

   function Normalize_External_Diagnostic_Record
     (Item : External_Diagnostic_Record) return External_Diagnostic_Record
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_External_Diagnostic_Record;

   procedure Add_Normalized_Record
     (S           : in out Editor.State.State_Type;
      Producer    : External_Producer_Source;
      Item        : External_Diagnostic_Record;
      Target_Kept : out Boolean)
     renames Editor.External_Producers.Diagnostic_Normalization.Add_Normalized_Record;

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Item     : External_Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Diagnostic_Record;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Items    : External_Diagnostic_Record_Array)
      return Producer_Batch_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Diagnostic_Batch;

   function External_Producer_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.External_Producer_Audit_Passes;

end Editor.External_Producers;
