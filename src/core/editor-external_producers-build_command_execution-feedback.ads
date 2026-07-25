with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Feedback is

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String;

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String;


end Editor.External_Producers.Build_Command_Execution.Feedback;
