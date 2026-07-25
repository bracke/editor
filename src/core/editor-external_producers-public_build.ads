with Ada.Strings.Unbounded;
with Editor.External_Producers.Public_Build_Command_Surface_Audits;
with Editor.External_Producers.Public_Build_Guardrail_Audits;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.State;

with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Public_Build_Types;

package Editor.External_Producers.Public_Build is

   subtype Consent_Model is Editor.External_Producers.Public_Build_Types.Public_Build_Consent_Model;
   subtype Consent_Validation_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Consent_Validation_Status;
   subtype Working_Context_Model is
     Editor.External_Producers.Public_Build_Types.Public_Build_Working_Context_Model;
   subtype Working_Context_Validation_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Working_Context_Validation_Status;
   subtype Command_Input is Editor.External_Producers.Public_Build_Types.Public_Build_Command_Input;
   subtype Input_Source is Editor.External_Producers.Public_Build_Types.Public_Build_Input_Source;
   subtype Input_Validation_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Input_Validation_Status;
   subtype Input_Safety is Editor.External_Producers.Public_Build_Types.Public_Build_Input_Safety;
   subtype Command_Surface_Entry is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Surface_Entry;
   subtype Command_Surface_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Surface_Status;
   subtype Command_Surface_Array is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Surface_Array;
   subtype Command_Promotion_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Promotion_Status;
   subtype UX_Dependency is Editor.External_Producers.Public_Build_Types.Public_Build_UX_Dependency;
   subtype UX_Dependency_Status is
     Editor.External_Producers.Public_Build_Types.Public_Build_UX_Dependency_Status;
   subtype UX_Dependency_Matrix is
     Editor.External_Producers.Public_Build_Types.Public_Build_UX_Dependency_Matrix;
   subtype UX_Dependency_Audit_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_UX_Dependency_Audit_Result;
   subtype Readiness_Audit_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Readiness_Audit_Result;
   subtype Blocker_Summary is
     Editor.External_Producers.Public_Build_Types.Public_Build_Blocker_Summary;
   subtype Hard_Freeze_Audit_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Command_Hard_Freeze_Audit_Result;
   subtype Hard_Freeze_Baseline is
     Editor.External_Producers.Public_Build_Types.Public_Build_Hard_Freeze_Baseline;
   subtype Hard_Freeze_Drift_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Hard_Freeze_Drift_Result;
   subtype Surface_Id_Scan_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Surface_Id_Scan_Result;
   subtype Guardrail_Result is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Result;
   subtype Guardrail_Health is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Health;
   subtype Guardrail_Audit_Matrix is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Audit_Matrix;
   subtype Guardrail_Audit_Trace is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Audit_Trace;
   subtype Guardrail_Contract_Mismatch is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Contract_Mismatch;
   subtype Guardrail_Failure_Detail is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Failure_Detail;
   subtype Guardrail_Failure_Detail_Vector is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Failure_Detail_Vector;
   subtype Guardrail_Regression_Manifest is
     Editor.External_Producers.Public_Build_Types.Public_Build_Guardrail_Regression_Manifest;
   subtype Command_Id_Vector is Editor.External_Producers.Public_Build_Types.Command_Id_Vector;
   subtype Argument_Vector is Editor.External_Producers.Build_Types.Process_Argument_Vector;
   subtype Working_Context is Editor.External_Producers.Build_Types.Build_Working_Context;
   subtype Execution_Consent is Editor.External_Producers.Build_Types.Build_Execution_Consent;
   subtype Build_Run_Request is Editor.External_Producers.Build_Types.Build_Run_Request;

   function Build_Public_Build_Command_Surface return Command_Surface_Array
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Command_Surface;

   function Validate_Public_Build_Command_Surface_Entry
     (Surface_Entry : Command_Surface_Entry) return Command_Surface_Status
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Validate_Public_Build_Command_Surface_Entry;

   procedure Assert_Public_Build_Command_Surface_Entry_Consistent
     (Surface_Entry : Command_Surface_Entry)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Command_Surface_Entry_Consistent;

   function Public_Build_Command_Surface_Ids return Command_Id_Vector
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Public_Build_Command_Surface_Ids;

   function Is_Public_Build_Surface_Id (Name : String) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Is_Public_Build_Surface_Id;

   procedure Assert_Public_Build_Surface_Ids_Not_Reused
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Surface_Ids_Not_Reused;

   procedure Assert_Public_Build_Blocker_Precedence
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Blocker_Precedence;

   function Build_Public_Build_UX_Dependency_Matrix
     return UX_Dependency_Matrix
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_UX_Dependency_Matrix;

   function Primary_Public_Build_UX_Dependency_Blocker
     (Matrix : UX_Dependency_Matrix) return UX_Dependency
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Primary_Public_Build_UX_Dependency_Blocker;

   function Validate_Public_Build_UX_Dependencies
     (Matrix : UX_Dependency_Matrix) return Command_Promotion_Status
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Validate_Public_Build_UX_Dependencies;

   function Validate_Public_Build_Command_Promotion
     (Surface_Entry : Command_Surface_Entry;
      Readiness     : Readiness_Audit_Result) return Command_Promotion_Status
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Validate_Public_Build_Command_Promotion;

   function Detect_Public_Build_Command_Exposure_Hard_Failure
     (Readiness : Readiness_Audit_Result) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Detect_Public_Build_Command_Exposure_Hard_Failure;

   function Audit_Public_Build_Command_Visibility return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Audit_Public_Build_Command_Visibility;

   procedure Assert_Public_Build_Command_Surface_Exposed
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Command_Surface_Exposed;

   function Audit_Public_Build_Command_UX_Dependencies
     return UX_Dependency_Audit_Result
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Audit_Public_Build_Command_UX_Dependencies;

   function Build_Public_Command_Not_Ready_Feedback
     (Audit : Readiness_Audit_Result) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Command_Not_Ready_Feedback;

   function Build_Public_Command_Promotion_Feedback
     (Status : Command_Promotion_Status) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Command_Promotion_Feedback;

   function Build_Public_Build_UX_Dependency_Feedback
     (Dependency : UX_Dependency) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_UX_Dependency_Feedback;

   function Build_Public_Build_Blocker_Summary return Blocker_Summary
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Blocker_Summary;

   function Build_Public_Build_Hard_Freeze_Baseline
     return Hard_Freeze_Baseline
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Hard_Freeze_Baseline;

   function Detect_Public_Build_Hard_Freeze_Drift
     (State    : Editor.State.State_Type;
      Baseline : Hard_Freeze_Baseline) return Hard_Freeze_Drift_Result
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Detect_Public_Build_Hard_Freeze_Drift;

   function Build_Public_Build_Drift_Feedback
     (Result : Hard_Freeze_Drift_Result) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Drift_Feedback;

   procedure Assert_No_Public_Build_Execution_Path
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_No_Public_Build_Execution_Path;

   procedure Assert_Public_Build_Hard_Freeze_Not_Persisted
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Hard_Freeze_Not_Persisted;

   function Build_Public_Build_Hard_Freeze_Feedback
     (Audit : Hard_Freeze_Audit_Result) return String
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Hard_Freeze_Feedback;

   function Public_Build_Surface_Ids_Not_Publicly_Projected
     (State : Editor.State.State_Type) return Boolean
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Public_Build_Surface_Ids_Not_Publicly_Projected;

   function Run_Public_Build_Command_Hard_Freeze_Audit
     (State : Editor.State.State_Type) return Hard_Freeze_Audit_Result
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Run_Public_Build_Command_Hard_Freeze_Audit;

   procedure Assert_Public_Build_Audits_Agree
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Command_Surface_Audits.Assert_Public_Build_Audits_Agree;

   function Validate_Public_Build_Consent
     (Consent : Consent_Model) return Consent_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Consent;

   function Classify_Public_Build_Consent_Safety
     (Consent : Consent_Model) return Input_Safety
     renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Consent_Safety;

   function Build_Execution_Consent_From_Public_Model
     (Consent : Consent_Model) return Execution_Consent
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Execution_Consent_From_Public_Model;

   function Build_Public_Build_Consent_Feedback
     (Status : Consent_Validation_Status) return String
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Consent_Feedback;

   function Validate_Public_Build_Working_Context
     (Context : Working_Context_Model) return Working_Context_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Working_Context;

   function Classify_Public_Build_Working_Context_Safety
     (Context : Working_Context_Model) return Input_Safety
     renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Working_Context_Safety;

   function Build_Working_Context_From_Public_Model
     (Context : Working_Context_Model) return Working_Context
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Working_Context_From_Public_Model;

   function Assert_Public_Build_Working_Context_Conversion_Consistent
     (Model   : Working_Context_Model;
      Context : Working_Context) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Assert_Public_Build_Working_Context_Conversion_Consistent;

   function Build_Public_Build_Working_Context_Feedback
     (Status : Working_Context_Validation_Status) return String
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Working_Context_Feedback;

   function Validate_Public_Build_Program_Label
     (Program_Label : Ada.Strings.Unbounded.Unbounded_String)
      return Input_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Program_Label;

   function Validate_Public_Build_Working_Context
     (Source  : Input_Source;
      Context : Working_Context) return Input_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Working_Context;

   function Validate_Public_Build_Arguments
     (Source    : Input_Source;
      Arguments : Argument_Vector) return Input_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Arguments;

   function Validate_Public_Build_Command_Input
     (Input : Command_Input) return Input_Validation_Status
     renames Editor.External_Producers.Public_Build_Input_Validation.Validate_Public_Build_Command_Input;

   function Classify_Public_Build_Input_Safety
     (Input : Command_Input) return Input_Safety
     renames Editor.External_Producers.Public_Build_Input_Validation.Classify_Public_Build_Input_Safety;

   function Build_User_Opt_In_Request_From_Public_Input
     (Input : Command_Input) return Build_Run_Request
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_User_Opt_In_Request_From_Public_Input;

   function Build_Public_Build_Request_From_UI_State
     (Input : Command_Input) return Build_Run_Request
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Request_From_UI_State;

   function Build_Public_Build_Input_Feedback
     (Status : Input_Validation_Status) return String
     renames Editor.External_Producers.Public_Build_Input_Validation.Build_Public_Build_Input_Feedback;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type) return Readiness_Audit_Result
     renames Editor.External_Producers.Public_Build_Input_Validation.Run_Public_Build_Command_Readiness_Audit;

   function Scan_Public_Build_Surface_Ids
     (Command_Id        : String := "";
      Display_Name     : String := "";
      Keybinding_Target : String := "";
      Runtime_Keybinding_Target : String := "";
      Palette_Row       : String := "";
      Executor_Route    : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "";
      Workspace_Name    : String := "")
      return Surface_Id_Scan_Result
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Scan_Public_Build_Surface_Ids;

   function Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Surface_Id_Scan_Result) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Surface_Id_Scan_Domains_Checked;

   procedure Assert_Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Surface_Id_Scan_Result)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Surface_Id_Scan_Domains_Checked;

   function Build_Public_Build_Guardrail_Audit_Trace
     return Guardrail_Audit_Trace
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Audit_Trace;

   function Public_Build_Guardrail_Audit_Trace_Complete
     (Trace : Guardrail_Audit_Trace) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Guardrail_Audit_Trace_Complete;

   procedure Assert_Public_Build_Guardrail_Trace_Complete
     (Trace : Guardrail_Audit_Trace)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Trace_Complete;

   function Compare_Public_Build_Guardrail_Snapshots
     (Before : Guardrail_Result;
      After  : Guardrail_Result) return Guardrail_Contract_Mismatch
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Compare_Public_Build_Guardrail_Snapshots;

   function Build_Public_Build_Internal_Test_Seam_Exposure_Detail
     (Palette_Row       : String := "";
      Keybinding_Target : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "")
      return Guardrail_Failure_Detail
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Internal_Test_Seam_Exposure_Detail;

   function Build_Public_Build_Guardrail_Health
     (State : Editor.State.State_Type) return Guardrail_Health
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Health;

   function Build_Public_Build_Guardrail_Health_Feedback
     (Health : Guardrail_Health) return String
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Health_Feedback;

   procedure Assert_Public_Build_Guardrail_Health_Default
     (Health : Guardrail_Health)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Health_Default;

   procedure Assert_Public_Build_Guardrail_Health_Not_Persisted
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Health_Not_Persisted;

   procedure Assert_Public_Build_Guardrail_Default_Health
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Default_Health;

   function Build_Public_Build_Guardrail_Audit_Matrix
     return Guardrail_Audit_Matrix
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Audit_Matrix;

   function Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Guardrail_Audit_Matrix) return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Guardrail_Audit_Matrix_Complete;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Guardrail_Audit_Matrix)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Audit_Matrix_Complete;

   function Build_Public_Build_Guardrail_Regression_Manifest
     (State : Editor.State.State_Type) return Guardrail_Regression_Manifest
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Regression_Manifest;

   function Build_Public_Build_Guardrail_Regression_Manifest_Feedback
     (Manifest : Guardrail_Regression_Manifest) return String
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Build_Public_Build_Guardrail_Regression_Manifest_Feedback;

   procedure Assert_Public_Build_Guardrail_Regression_Manifest_Default
     (Manifest : Guardrail_Regression_Manifest)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Regression_Manifest_Default;

   procedure Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (Manifest : Guardrail_Regression_Manifest)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;

   function Public_Build_Surface_Commands_Executable return Boolean
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Public_Build_Surface_Commands_Executable;

   function Run_Public_Build_Guardrail_Audit
     (State : Editor.State.State_Type) return Guardrail_Result
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Run_Public_Build_Guardrail_Audit;

   function Detect_Public_Build_Guardrail_Contract_Mismatch
     (Result : Guardrail_Result) return Guardrail_Contract_Mismatch
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Detect_Public_Build_Guardrail_Contract_Mismatch;

   procedure Assert_Public_Build_Guardrail_Default_Contract
     (Result : Guardrail_Result)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Default_Contract;

   procedure Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
     (State  : Editor.State.State_Type;
      Result : Guardrail_Result)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan;

   procedure Assert_Public_Build_Guardrail_State_Not_Persisted
     (State : Editor.State.State_Type)
     renames Editor.External_Producers.Public_Build_Guardrail_Audits.Assert_Public_Build_Guardrail_State_Not_Persisted;

end Editor.External_Producers.Public_Build;
