with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Fixture_Gates is

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

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result);

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result);

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


end Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
