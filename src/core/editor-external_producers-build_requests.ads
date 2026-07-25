with Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;
with Editor.State;

with Editor.External_Producers.Public_Build_Types;
package Editor.External_Producers.Build_Requests is

   subtype Argument_Vector is Editor.External_Producers.Build_Types.Process_Argument_Vector;
   subtype Process_Argument_Vector is
     Editor.External_Producers.Build_Types.Process_Argument_Vector;
   subtype Build_Tool_Kind is Editor.External_Producers.Build_Types.Build_Tool_Kind;
   subtype Build_Request_Provenance is
     Editor.External_Producers.Build_Types.Build_Request_Provenance;
   subtype Build_Run_Request is Editor.External_Producers.Build_Types.Build_Run_Request;
   subtype User_Build_Command_Request is
     Editor.External_Producers.Build_Types.User_Build_Command_Request;
   subtype Build_Request_Validation_Status is
     Editor.External_Producers.Build_Types.Build_Request_Validation_Status;
   subtype Build_Run_Status is Editor.External_Producers.Build_Types.Build_Run_Status;
   subtype Build_Working_Context is
     Editor.External_Producers.Build_Types.Build_Working_Context;
   subtype Build_Execution_Consent is
     Editor.External_Producers.Build_Types.Build_Execution_Consent;
   subtype Public_Build_Command_Input is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Input;
   subtype Public_Build_Input_Validation_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Input_Validation_Status;
   subtype Public_Build_Input_Safety is
     Editor.External_Producers.Public_Build_Types.Public_Build_Input_Safety;
   subtype Build_Preflight_Result is
     Editor.External_Producers.Build_Types.Build_Preflight_Result;
   subtype Diagnostic_Text_Line_Array is
     Editor.External_Producers.Build_Types.Diagnostic_Text_Line_Array;
   package Diagnostic_Text_Line_Vectors renames
     Editor.External_Producers.Build_Types.Diagnostic_Text_Line_Vectors;
   subtype Diagnostic_Line_Command_Result is
     Editor.External_Producers.Build_Command_Execution.Diagnostic_Line_Command_Result;
   subtype Build_Run_Result is
     Editor.External_Producers.Build_Types.Build_Run_Result;
   subtype Build_Command_Result is
     Editor.External_Producers.Build_Command_Execution.Build_Command_Result;
   subtype Process_Run_Request is
     Editor.External_Producers.Build_Types.Process_Run_Request;
   subtype Process_Run_Result is
     Editor.External_Producers.Build_Types.Process_Run_Result;
   subtype Process_Request_Validation_Status is
     Editor.External_Producers.Build_Types.Process_Request_Validation_Status;
   subtype Process_Execution_Policy is
     Editor.External_Producers.Build_Types.Process_Execution_Policy;
   subtype Build_Execution_Gate is
     Editor.External_Producers.Build_Types.Build_Execution_Gate;
   subtype Process_Fixture_Request is
     Editor.External_Producers.Build_Types.Process_Fixture_Request;
   subtype Process_Fixture_Validation_Status is
     Editor.External_Producers.Build_Types.Process_Fixture_Validation_Status;
   subtype Real_Build_Tool_Fixture_Kind is
     Editor.External_Producers.Build_Types.Real_Build_Tool_Fixture_Kind;
   subtype Real_Build_Tool_Fixture_Validation_Status is
     Editor.External_Producers.Build_Types.Real_Build_Tool_Fixture_Validation_Status;
   subtype User_Opt_In_Build_Command_Context is
     Editor.External_Producers.Build_Types.User_Opt_In_Build_Command_Context;
   subtype User_Opt_In_Build_Command_Context_Status is
     Editor.External_Producers.Build_Types.User_Opt_In_Build_Command_Context_Status;

   package Argument_Vectors renames
     Editor.External_Producers.Build_Types.Process_Argument_Vectors;

   function Build_User_Opt_In_Request
     (Tool          : Build_Tool_Kind;
      Program_Label : String;
      Working_Label : String;
      Arguments     : Argument_Vector) return Build_Run_Request
     renames Editor.External_Producers.Request_Policies.Build_User_Opt_In_Request;

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

   function Empty_Process_Arguments return Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

   procedure Append_Process_Argument
     (Arguments : in out Argument_Vector;
      Value     : String)
     renames Editor.External_Producers.Request_Policies.Append_Process_Argument;

   function Process_Argument_Count
     (Arguments : Argument_Vector) return Natural
     renames Editor.External_Producers.Request_Policies.Process_Argument_Count;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Build_Unsupported_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Unsupported_Working_Context;

   function Build_Inherited_Test_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Inherited_Test_Working_Context;

   function Build_Explicit_Label_Working_Context
     (Label : String) return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Explicit_Label_Working_Context;

   function Validate_Build_Request_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Request_Provenance;

   function Validate_Build_Working_Context
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Editor.External_Producers.Build_Types.Process_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Working_Context;

   function Prepare_Process_Request
     (Request : Build_Run_Request) return Process_Run_Request
     renames Editor.External_Producers.Request_Policies.Prepare_Process_Request;

   function Build_Process_Run_Result
     (Status        : Editor.External_Producers.Build_Types.Process_Run_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Text   : String := "";
      Stderr_Text   : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Capture_Mode : Editor.External_Producers.Build_Types.Process_Output_Capture_Mode :=
        Editor.External_Producers.Build_Types.Process_Output_Capture_Separated)
      return Process_Run_Result
     renames Editor.External_Producers.Request_Policies.Build_Process_Run_Result;

   function Build_Build_Run_Result
     (Status           : Editor.External_Producers.Build_Types.Build_Run_Status;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : String := "";
      Stderr_Text      : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Output_Capture_Mode : Editor.External_Producers.Build_Types.Process_Output_Capture_Mode :=
        Editor.External_Producers.Build_Types.Process_Output_Capture_Separated;
      Diagnostic_Lines : Diagnostic_Text_Line_Array :=
        Diagnostic_Text_Line_Vectors.Empty_Vector)
      return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Build_Build_Run_Result;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result)
      return String
     renames Editor.External_Producers.Build_Command_Execution.Build_Build_Command_Feedback;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                    : Build_Run_Result;
      Diagnostic_Result               : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used      : Boolean;
      Diagnostics_Ingestion_Allowed   : Boolean) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_Gated_Build_Command_Feedback;

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result)
      return Diagnostic_Text_Line_Array
     renames Editor.External_Producers.Build_Command_Execution.Extract_Diagnostic_Lines_From_Build_Result;

   function Validate_Process_Run_Request_For_Real_Execution_Status
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Process_Run_Request_For_Real_Execution_Status;

   function Validate_Process_Run_Request_For_Real_Execution
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Process_Run_Request_For_Real_Execution;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Request_Policies.Validate_Process_Execution_Policy;

   function Execute_Process_Request_Default
     (Request : Process_Run_Request) return Process_Run_Result
     renames Editor.External_Producers.Request_Policies.Execute_Process_Request_Default;

   function Process_Request_Rejection_Feedback
     (Status : Process_Request_Validation_Status) return String
     renames Editor.External_Producers.Request_Policies.Process_Request_Rejection_Feedback;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Build_Run_Request;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_User_Opt_In_Build_Request;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
     renames Editor.External_Producers.Build_Command_Execution.Preflight_Real_Build_Tool_Fixture;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False)
      return Diagnostic_Line_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Ingest_Build_Run_Diagnostics;

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
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_Build_Request_With_Process_Policy;

   function Enforce_Process_Output_Bounds
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Process_Run_Result
     renames Editor.External_Producers.Build_Command_Execution.Enforce_Process_Output_Bounds;

   function Process_Fixture_Result_Is_Consistent
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Process_Fixture_Result_Is_Consistent;

   procedure Assert_Process_Fixture_Result_Consistent
     (Result : Process_Run_Result)
     renames Editor.External_Producers.Build_Command_Execution.Assert_Process_Fixture_Result_Consistent;

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

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Process_Fixture_Request_Is_Valid;

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

   function Run_Build_Command_With_Gate
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_With_Gate;

   function Run_Build_Command_Test_Seam_With_Runner
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Policy           : Process_Execution_Policy;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False);
      Show_Diagnostics : Boolean := False) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_Test_Seam_With_Runner;

   function Run_Build_Command_Test_Seam
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Show_Diagnostics : Boolean := False) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_Test_Seam;

   function Run_Build_Command_With_Fixture_Gate
     (S       : in out Editor.State.State_Type;
      Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Gate    : Build_Execution_Gate) return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Build_Command_With_Fixture_Gate;

   function Run_User_Opt_In_Build_Command_Test_Seam
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_User_Opt_In_Build_Command_Test_Seam;

   function Run_Real_Build_Tool_Fixture_With_Gate
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Fixture          : Real_Build_Tool_Fixture_Kind;
      Gate             : Build_Execution_Gate;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Run_Real_Build_Tool_Fixture_With_Gate;

   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : User_Opt_In_Build_Command_Context;
      Supplied_Result : Process_Run_Result :=
        (Status        => Editor.External_Producers.Build_Types.Process_Run_Not_Available,
         Output_Capture_Mode => Editor.External_Producers.Build_Types.Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
     renames Editor.External_Producers.Build_Command_Execution.Execute_User_Opt_In_Build_Command;

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
     renames Editor.External_Producers.Build_Command_Execution.Validate_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_User_Opt_In_Command_Feedback;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.User_Opt_In_Build_Command_Context_Is_Available;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.User_Opt_In_Build_Preflight_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result)
     renames Editor.External_Producers.Build_Command_Execution.Assert_User_Opt_In_Build_Preflight_Consistent;

   function User_Opt_In_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.User_Opt_In_Build_Command_Result_Is_Consistent;

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Real_Build_Tool_Fixture_Is_Approved;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request
     renames Editor.External_Producers.Build_Command_Execution.Prepare_Real_Build_Tool_Fixture_Process_Request;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
     renames Editor.External_Producers.Build_Command_Execution.Build_Real_Build_Tool_Fixture_Feedback;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Build_Preflight_Result_Is_Consistent;

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Real_Build_Tool_Fixture_Command_Result_Is_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result)
     renames Editor.External_Producers.Build_Command_Execution.Assert_Real_Build_Tool_Fixture_Preflight_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result)
     renames Editor.External_Producers.Build_Command_Execution.Assert_Real_Build_Tool_Fixture_Command_Result_Consistent;

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

   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
     renames Editor.External_Producers.Build_Command_Execution.Validate_Real_Build_Tool_Fixture_Request;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Build_Command_Execution.Validate_Real_Build_Tool_Fixture_Gate;

   function Build_Process_Fixture_Request
     (Kind  : Editor.External_Producers.Build_Types.Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request
     renames Editor.External_Producers.Build_Command_Execution.Build_Process_Fixture_Request;

   function Validate_Build_Execution_Gate
     (Gate : Build_Execution_Gate) return Boolean
     renames Editor.External_Producers.Execution_Policy.Validate_Build_Execution_Gate;

   procedure Assert_User_Opt_In_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
     renames Editor.External_Producers.Build_Command_Execution.Assert_User_Opt_In_Build_Command_Result_Consistent;

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

   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type)
     renames Editor.External_Producers.Build_Command_Execution.Reset_Build_Run_State_For_Project_Close;

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
     renames Editor.External_Producers.Build_Command_Execution.Reset_Build_Run_State_For_Workspace_Close;

end Editor.External_Producers.Build_Requests;
