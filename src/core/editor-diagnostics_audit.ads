with Editor.State;

package Editor.Diagnostics_Audit is

   type Diagnostics_Contract_Review is record
      Session_Local                 : Boolean := False;
      Retention_Bounded             : Boolean := False;
      Projection_Side_Effect_Free   : Boolean := False;
      Filters_Compose               : Boolean := False;
      Severity_Source_Stable        : Boolean := False;
      Row_Identity_Stable           : Boolean := False;
      Targets_Validated             : Boolean := False;
      Actions_Routed                : Boolean := False;
      Editable_Actions_Visible      : Boolean := False;
      Lifecycle_Reset_Stable        : Boolean := False;
      Persistence_Clean             : Boolean := False;
      Feature_Panel_Intact          : Boolean := False;
      Command_Surface_Intact        : Boolean := False;
      Public_Build_Guardrail_Intact : Boolean := False;
      Review_Passed                 : Boolean := False;
   end record;

   --  Compact Phase 206 review of the session-local Diagnostics contract.
   --  The helper observes live editor state and exercises only local copies for
   --  retention, filtering, projection, row identity, row/Diagnostic_Id
   --  target validation, and lifecycle checks. It does not ingest diagnostics into live state, clear
   --  diagnostics, change live filters, switch the live Feature Panel feature,
   --  open files, move the caret, call Executor, call process runners, inspect
   --  project files, or persist audit results.
   function Review_Diagnostics_Contract
     (State : Editor.State.State_Type) return Diagnostics_Contract_Review;

   --  Deterministic audit/test feedback. The returned text contains no argv,
   --  shell syntax, environment, PATH lookup detail, filesystem paths, run ids,
   --  projection generations, serialized diagnostics, or process output dumps.
   function Build_Diagnostics_Contract_Review_Feedback
     (Review : Diagnostics_Contract_Review) return String;

end Editor.Diagnostics_Audit;
