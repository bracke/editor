with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Real_Process is

   function Execute_Process_Request_Real_Gated_With_State
     (S       : in out Editor.State.State_Type;
      Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

   function Execute_Process_Request_Real_Gated
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

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

   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type);

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type);


end Editor.External_Producers.Build_Command_Execution.Real_Process;
