with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Editor.External_Producers.Public_Build_Command_Surface_Audits is

   function Build_Status_Label (Status : Build_Run_Status) return String;

   function Build_Public_Build_Command_Surface
     return Public_Build_Command_Surface_Array;

   function Validate_Public_Build_Command_Surface_Entry
     (Surface_Entry : Public_Build_Command_Surface_Entry)
      return Public_Build_Command_Surface_Status;

   procedure Assert_Public_Build_Command_Surface_Entry_Consistent
     (Surface_Entry : Public_Build_Command_Surface_Entry);

   function Public_Build_Command_Surface_Ids return Command_Id_Vector;

   function Is_Public_Build_Surface_Id (Name : String) return Boolean;

   function Public_Build_Public_Names_Not_Registered return Boolean;

   function Public_Build_Public_Name_Count return Natural;

   procedure Assert_Public_Build_Surface_Ids_Not_Reused;

   function Public_Build_Blocker_Precedence_Intact return Boolean;

   procedure Assert_Public_Build_Blocker_Precedence;

   function Build_Public_Build_UX_Dependency_Matrix
     return Public_Build_UX_Dependency_Matrix;

   function Primary_Public_Build_UX_Dependency_Blocker
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_UX_Dependency;

   function Validate_Public_Build_UX_Dependencies
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_Command_Promotion_Status;

   function Detect_Public_Build_Command_Exposure_Hard_Failure
     (Readiness : Public_Build_Command_Readiness_Audit_Result) return Boolean;

   function Audit_Public_Build_Command_Visibility return Boolean;

   procedure Assert_Public_Build_Command_Surface_Exposed;

   function Audit_Public_Build_Command_UX_Dependencies
     return Public_Build_Command_UX_Dependency_Audit_Result;

   function Build_Public_Command_Not_Ready_Feedback
     (Audit : Public_Build_Command_Readiness_Audit_Result) return String;

   function Build_Public_Command_Promotion_Feedback
     (Status : Public_Build_Command_Promotion_Status) return String;

   function Build_Public_Build_UX_Dependency_Feedback
     (Dependency : Public_Build_UX_Dependency) return String;

   function Validate_Public_Build_Command_Promotion
     (Surface_Entry : Public_Build_Command_Surface_Entry;
      Readiness   : Public_Build_Command_Readiness_Audit_Result)
      return Public_Build_Command_Promotion_Status;

   function Build_Public_Build_Blocker_Summary
     return Public_Build_Blocker_Summary;

   function Build_Public_Build_Hard_Freeze_Baseline
     return Public_Build_Hard_Freeze_Baseline;

   function Detect_Public_Build_Hard_Freeze_Drift
     (State    : Editor.State.State_Type;
      Baseline : Public_Build_Hard_Freeze_Baseline)
      return Public_Build_Hard_Freeze_Drift_Result;

   function Build_Public_Build_Drift_Feedback
     (Result : Public_Build_Hard_Freeze_Drift_Result) return String;

   function Public_Build_Surface_Ids_Not_Publicly_Projected
     (State : Editor.State.State_Type) return Boolean;

   function Run_Public_Build_Command_Hard_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Hard_Freeze_Audit_Result;

   procedure Assert_No_Public_Build_Execution_Path
     (State : Editor.State.State_Type);

   procedure Assert_Public_Build_Hard_Freeze_Not_Persisted
     (State : Editor.State.State_Type);

   function Build_Public_Build_Hard_Freeze_Feedback
     (Audit : Public_Build_Command_Hard_Freeze_Audit_Result) return String;

   procedure Assert_Public_Build_Audits_Agree
     (State : Editor.State.State_Type);

end Editor.External_Producers.Public_Build_Command_Surface_Audits;
