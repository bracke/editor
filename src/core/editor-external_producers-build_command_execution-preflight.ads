with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Preflight is

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result;

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

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result);

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;


end Editor.External_Producers.Build_Command_Execution.Preflight;
