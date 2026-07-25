with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostics;
with Editor.State;

package Editor.External_Producers.Build_Command_Execution is

   subtype Diagnostic_Text_Line_Array is
     Editor.External_Producers.Build_Types.Diagnostic_Text_Line_Array;
   package Diagnostic_Text_Line_Vectors renames
     Editor.External_Producers.Build_Types.Diagnostic_Text_Line_Vectors;
   subtype Diagnostic_Line_Command_Result is
     Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;
   subtype Build_Run_Result is
     Editor.External_Producers.Build_Types.Build_Run_Result;
   subtype Build_Run_Status is
     Editor.External_Producers.Build_Types.Build_Run_Status;
   subtype Build_Run_Request is
     Editor.External_Producers.Build_Types.Build_Run_Request;
   subtype Build_Tool_Kind is
     Editor.External_Producers.Build_Types.Build_Tool_Kind;
   subtype Process_Execution_Policy is
     Editor.External_Producers.Build_Types.Process_Execution_Policy;
   subtype Process_Run_Result is
     Editor.External_Producers.Build_Types.Process_Run_Result;
   subtype Process_Run_Request is
     Editor.External_Producers.Build_Types.Process_Run_Request;
   subtype Process_Run_Status is
     Editor.External_Producers.Build_Types.Process_Run_Status;
   subtype Process_Output_Capture_Mode is
     Editor.External_Producers.Build_Types.Process_Output_Capture_Mode;
   subtype Build_Preflight_Result is
     Editor.External_Producers.Build_Types.Build_Preflight_Result;
   subtype Build_Execution_Gate is
     Editor.External_Producers.Build_Types.Build_Execution_Gate;
   subtype Build_Execution_Consent is
     Editor.External_Producers.Build_Types.Build_Execution_Consent;
   subtype Process_Argument_Vector is
     Editor.External_Producers.Build_Types.Process_Argument_Vector;
   subtype User_Opt_In_Build_Command_Context is
     Editor.External_Producers.Build_Types.User_Opt_In_Build_Command_Context;
   subtype User_Opt_In_Build_Command_Context_Status is
     Editor.External_Producers.Build_Types.User_Opt_In_Build_Command_Context_Status;
   subtype Real_Build_Tool_Fixture_Kind is
     Editor.External_Producers.Build_Types.Real_Build_Tool_Fixture_Kind;
   subtype Real_Build_Tool_Fixture_Validation_Status is
     Editor.External_Producers.Build_Types.Real_Build_Tool_Fixture_Validation_Status;
   subtype Build_Request_Validation_Status is
     Editor.External_Producers.Build_Types.Build_Request_Validation_Status;
   subtype Process_Request_Validation_Status is
     Editor.External_Producers.Build_Types.Process_Request_Validation_Status;
   subtype Process_Fixture_Validation_Status is
     Editor.External_Producers.Build_Types.Process_Fixture_Validation_Status;
   subtype Process_Fixture_Kind is
     Editor.External_Producers.Build_Types.Process_Fixture_Kind;
   subtype Process_Fixture_Request is
     Editor.External_Producers.Build_Types.Process_Fixture_Request;

   type Build_Command_Result is record
      Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result;
      Command_Message   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   procedure Append_Output_Text_Lines
     (Text  : String;
      Lines : in out Diagnostic_Text_Line_Array);

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result) return Diagnostic_Text_Line_Array;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String;

   function Run_Build_Command_Test_Seam
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Show_Diagnostics : Boolean := False) return Build_Command_Result;

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
      Show_Diagnostics : Boolean := False) return Build_Command_Result;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String;

   function Empty_User_Opt_In_Build_Command_Context
     return User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Context
     (Tool              : Build_Tool_Kind;
      Program_Label     : String;
      Working_Label     : String;
      Arguments         : Process_Argument_Vector;
      Consent           : Build_Execution_Consent;
      Allow_Diagnostics : Boolean;
      Show_Diagnostics  : Boolean)
      return User_Opt_In_Build_Command_Context;

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result);

   function User_Opt_In_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean;

   procedure Assert_User_Opt_In_Build_Command_Result_Consistent
     (Result : Build_Command_Result);

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean;

   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status;

   function Real_Build_Tool_Fixture_Status_To_Build_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Build_Request_Validation_Status;

   function Real_Build_Tool_Fixture_Status_To_Process_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Process_Request_Validation_Status;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String;

   function Validate_Real_Build_Tool_Fixture_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request;

   function Validate_Real_Build_Tool_Fixture_Process_Request
     (Request : Process_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result);

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result);

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String;

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
      return Build_Command_Result;

   function Run_Build_Command_With_Fixture_Gate
     (S       : in out Editor.State.State_Type;
      Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Gate    : Build_Execution_Gate) return Build_Command_Result;

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
      return Build_Command_Result;

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
      return Build_Command_Result;

   function Execute_Build_Request
     (Request : Build_Run_Request) return Build_Run_Result;

   function Execute_Test_Fed_Build_Request
     (Request         : Build_Run_Request;
      Supplied_Result : Build_Run_Result) return Build_Run_Result;

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
      return Build_Run_Result;

   function Enforce_Process_Output_Bounds
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Process_Run_Result;

   function Process_Fixture_Result_Is_Consistent
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Boolean;

   procedure Assert_Process_Fixture_Result_Consistent
     (Result : Process_Run_Result);

   function Execute_Test_Fed_Process_Request
     (Request         : Process_Run_Request;
      Supplied_Result : Process_Run_Result) return Process_Run_Result;

   function Execute_Process_Request_Gated
     (Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result;

   function Execute_Process_Request_Gated_With_State
     (S               : in out Editor.State.State_Type;
      Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result;

   function Execute_Process_Request_Real_Gated_With_State
     (S       : in out Editor.State.State_Type;
      Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

   function Execute_Process_Request_Real_Gated
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status;

   function Validate_Process_Fixture_Request_Status
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status;

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean;

   function Build_Process_Fixture_Request
     (Kind  : Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request;

   procedure Append_With_Newline
     (Target : in out Unbounded_String;
      Value  : String);

   procedure Append_Fixture_Output_Line
     (Target   : in out Unbounded_String;
      Has_Line : in out Boolean;
      Value    : String);

   function Execute_Process_Request_Real_Fixture
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

   function Build_Process_Fixture_Result
     (Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Build_Run_Result;

   function Build_Result_From_Process_Result
     (Request : Build_Run_Request;
      Result  : Process_Run_Result) return Build_Run_Result;

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
        Diagnostic_Text_Line_Vectors.Empty_Vector) return Build_Run_Result;

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
      return Build_Command_Result;

   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type);

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type);

end Editor.External_Producers.Build_Command_Execution;
