with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;

package Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits is

   function Audit_Public_Build_Consent_Readiness return Boolean;

   function Audit_Public_Build_Working_Context_Readiness return Boolean;

   function Audit_Public_Build_Input_Model_Readiness return Boolean;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result;

end Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits;
