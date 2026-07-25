with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.State;

with Editor.External_Producers.Public_Build_Types;
use Editor.External_Producers.Public_Build_Types;
package Editor.External_Producers.Public_Build_Input_Validation is

   subtype Build_Run_Request is
     Editor.External_Producers.Build_Types.Build_Run_Request;
   subtype Process_Argument_Vector is
     Editor.External_Producers.Build_Types.Process_Argument_Vector;
   subtype Build_Execution_Consent is
     Editor.External_Producers.Build_Types.Build_Execution_Consent;
   subtype Build_Working_Context is
     Editor.External_Producers.Build_Types.Build_Working_Context;

   function Contains_Control_Character (Value : String) return Boolean;

   function Contains_Shell_Syntax (Value : String) return Boolean;

   function Contains_Path_Separator (Value : String) return Boolean;

   function Looks_Project_Derived_Label (Value : String) return Boolean;

   function Looks_Path_Like_Label (Value : String) return Boolean;

   function Validate_Public_Build_Consent
     (Consent : Public_Build_Consent_Model)
      return Public_Build_Consent_Validation_Status;

   function Classify_Public_Build_Consent_Safety
     (Consent : Public_Build_Consent_Model) return Public_Build_Input_Safety;

   function Build_Execution_Consent_From_Public_Model
     (Consent : Public_Build_Consent_Model) return Build_Execution_Consent;

   function Build_Public_Build_Consent_Feedback
     (Status : Public_Build_Consent_Validation_Status) return String;

   function Audit_Public_Build_Consent_Readiness return Boolean;

   function Validate_Public_Build_Working_Context
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Working_Context_Validation_Status;

   function Classify_Public_Build_Working_Context_Safety
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Input_Safety;

   function Build_Working_Context_From_Public_Model
     (Context : Public_Build_Working_Context_Model) return Build_Working_Context;

   function Assert_Public_Build_Working_Context_Conversion_Consistent
     (Model   : Public_Build_Working_Context_Model;
      Context : Build_Working_Context) return Boolean;

   function Build_Public_Build_Working_Context_Feedback
     (Status : Public_Build_Working_Context_Validation_Status) return String;

   function Audit_Public_Build_Working_Context_Readiness return Boolean;

   function Validate_Public_Build_Program_Label
     (Program_Label : Unbounded_String)
      return Public_Build_Input_Validation_Status;

   function Validate_Public_Build_Working_Context
     (Source  : Public_Build_Input_Source;
      Context : Build_Working_Context)
      return Public_Build_Input_Validation_Status;

   function Validate_Public_Build_Arguments
     (Source    : Public_Build_Input_Source;
      Arguments : Process_Argument_Vector)
      return Public_Build_Input_Validation_Status;

   function Validate_Public_Build_Command_Input
     (Input : Public_Build_Command_Input)
      return Public_Build_Input_Validation_Status;

   function Classify_Public_Build_Input_Safety
     (Input : Public_Build_Command_Input) return Public_Build_Input_Safety;

   function Build_User_Opt_In_Request_From_Public_Input
     (Input : Public_Build_Command_Input) return Build_Run_Request;

   function Build_Public_Build_Request_From_UI_State
     (Input : Public_Build_Command_Input) return Build_Run_Request;

   function Build_Public_Build_Input_Feedback
     (Status : Public_Build_Input_Validation_Status) return String;

   function Audit_Public_Build_Input_Model_Readiness return Boolean;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result;

end Editor.External_Producers.Public_Build_Input_Validation;
