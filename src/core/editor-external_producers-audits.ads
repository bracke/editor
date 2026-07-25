with Editor.External_Producers.Build_Runner_Audits;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Diagnostic_Normalization;
with Editor.State;

package Editor.External_Producers.Audits is

   subtype Build_Command_Result is Editor.External_Producers.Build_Requests.Build_Command_Result;
   subtype Build_Execution_Consent_Audit_Result is
     Editor.External_Producers.Build_Execution_Consent_Audit_Result;

   function Compiler_Diagnostic_Normalization_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Compiler_Diagnostic_Normalization_Audit_Passes;

   function Producer_Lifecycle_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Producer_Lifecycle_Audit_Passes;

   function External_Producer_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.External_Producer_Audit_Passes;

   function Diagnostic_Line_Parser_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Parser_Audit_Passes;

   function Diagnostic_Line_Command_Surface_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Command_Surface_Audit_Passes;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Layering_Audit_Passes;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Gated_Build_Command_Result_Is_Consistent;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
     renames Editor.External_Producers.Build_Runner_Audits.Assert_Gated_Build_Command_Result_Consistent;

   function Process_Runner_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Process_Runner_Audit_Passes;

   function Audit_Process_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Execution_Gates;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Runner_Output_Stream_Capture;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Argv_And_Preflight_Gates;

   function Audit_Real_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Real_Build_Execution_Gates;

   function Audit_Real_Build_Tool_Fixture_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Real_Build_Tool_Fixture_Gates;

   function Audit_User_Opt_In_Build_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_User_Opt_In_Build_Gates;

   function Audit_User_Opt_In_Build_Command_Surface return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_User_Opt_In_Build_Command_Surface;

   function Audit_Build_Execution_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Execution_Gates;

   function Audit_Gated_Runner_Command_Path return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Gated_Runner_Command_Path;

   function Audit_Process_Fixture_Gates return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Process_Fixture_Gates;

   function Build_Run_Test_Seam_Audit_Passes return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Build_Run_Test_Seam_Audit_Passes;

   function Run_Build_Execution_Consent_Audit
     (State : Editor.State.State_Type)
      return Build_Execution_Consent_Audit_Result
     renames Editor.External_Producers.Build_Runner_Audits.Run_Build_Execution_Consent_Audit;

   function Audit_Build_Command_Rejection_Matrix return Boolean
     renames Editor.External_Producers.Build_Runner_Audits.Audit_Build_Command_Rejection_Matrix;

end Editor.External_Producers.Audits;
