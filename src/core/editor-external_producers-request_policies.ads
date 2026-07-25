with Editor.Build_Working_Context;

package Editor.External_Producers.Request_Policies is

   function Build_User_Opt_In_Request
     (Tool          : Build_Tool_Kind;
      Program_Label : String;
      Working_Label : String;
      Arguments     : Process_Argument_Vector) return Build_Run_Request;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status;

   function Validate_Build_Run_Request
     (Request : Build_Run_Request) return Boolean;

   function Validate_User_Opt_In_Build_Request
     (Request : Build_Run_Request) return Build_Request_Validation_Status;

   function Build_Request_Rejection_Feedback
     (Status : Build_Request_Validation_Status) return String;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector;

   function Build_Unsupported_Working_Context return Build_Working_Context;

   function Build_Inherited_Test_Working_Context return Build_Working_Context;

   function Build_Explicit_Label_Working_Context
     (Label : String) return Build_Working_Context;

   function Validate_Build_Request_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status;

   function Validate_Build_Working_Context
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status;

   function Prepare_Process_Request
     (Request : Build_Run_Request) return Process_Run_Request;

   function Build_Process_Run_Result
     (Status        : Process_Run_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Text   : String := "";
      Stderr_Text   : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated) return Process_Run_Result;

   function Execute_Process_Request_Default
     (Request : Process_Run_Request) return Process_Run_Result;

   function Empty_Process_Arguments return Process_Argument_Vector;

   procedure Append_Process_Argument
     (Arguments : in out Process_Argument_Vector;
      Value     : String);

   function Process_Argument_Count
     (Arguments : Process_Argument_Vector) return Natural;

   function Build_Default_Timeout_Milliseconds return Natural;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean;

   function Looks_Absolute_Program (Program : String) return Boolean;

   function Validate_Process_Run_Request_For_Real_Execution_Status
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status;

   function Validate_Process_Run_Request_For_Real_Execution
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Boolean;

   function Process_Request_Rejection_Feedback
     (Status : Process_Request_Validation_Status) return String;

end Editor.External_Producers.Request_Policies;
