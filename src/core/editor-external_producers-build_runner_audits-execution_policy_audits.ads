with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Build_Types;

package Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits is

   subtype Build_Command_Result is
     Editor.External_Producers.Build_Command_Execution.Build_Command_Result;
   subtype Build_Run_Result is
     Editor.External_Producers.Build_Types.Build_Run_Result;
   subtype Diagnostic_Text_Line_Array is
     Editor.External_Producers.Build_Types.Diagnostic_Text_Line_Array;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result);

   function Process_Runner_Audit_Passes return Boolean;

   function Audit_Process_Execution_Gates return Boolean;

   function Audit_Build_Runner_Timeout_Cancellation_Safety return Boolean;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean;

end Editor.External_Producers.Build_Runner_Audits.Execution_Policy_Audits;
