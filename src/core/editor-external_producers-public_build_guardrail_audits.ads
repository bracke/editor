package Editor.External_Producers.Public_Build_Guardrail_Audits is

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
      return Public_Build_Surface_Id_Scan_Result;

   function Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result) return Boolean;

   procedure Assert_Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result);

   function Build_Public_Build_Guardrail_Audit_Trace
     return Public_Build_Guardrail_Audit_Trace;

   function Public_Build_Guardrail_Audit_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace) return Boolean;

   procedure Assert_Public_Build_Guardrail_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace);

   function Compare_Public_Build_Guardrail_Snapshots
     (Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch;

   function Is_Internal_Public_Build_Test_Seam_Id (Name : String) return Boolean;

   function First_Public_Build_Guardrail_Failure
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail;

   function Collect_Public_Build_Guardrail_Failures
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail_Vector;

   function Build_Public_Build_Guardrail_Health
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Health;

   function Build_Public_Build_Guardrail_Health_Feedback
     (Health : Public_Build_Guardrail_Health) return String;

   procedure Assert_Public_Build_Guardrail_Health_Default
     (Health : Public_Build_Guardrail_Health);

   procedure Assert_Public_Build_Guardrail_Health_Not_Persisted
     (State : Editor.State.State_Type);

   procedure Assert_Public_Build_Guardrail_Default_Health
     (State : Editor.State.State_Type);

   function Build_Public_Build_Guardrail_Audit_Matrix
     return Public_Build_Guardrail_Audit_Matrix;

   function Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix);

   function Build_Public_Build_Guardrail_Regression_Manifest
     (State : Editor.State.State_Type)
      return Public_Build_Guardrail_Regression_Manifest;

   function Build_Public_Build_Guardrail_Regression_Manifest_Feedback
     (Manifest : Public_Build_Guardrail_Regression_Manifest) return String;

   procedure Assert_Public_Build_Guardrail_Regression_Manifest_Default
     (Manifest : Public_Build_Guardrail_Regression_Manifest);

   function Public_Build_Surface_Commands_Executable return Boolean;

   function Run_Public_Build_Guardrail_Audit
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Result;

   function Detect_Public_Build_Guardrail_Contract_Mismatch
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch;

   procedure Assert_Public_Build_Guardrail_Default_Contract
     (Result : Public_Build_Guardrail_Result);

   procedure Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
     (State  : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result);

   procedure Assert_Public_Build_Guardrail_State_Not_Persisted
     (State : Editor.State.State_Type);

end Editor.External_Producers.Public_Build_Guardrail_Audits;
