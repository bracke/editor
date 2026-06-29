with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality is

   package P renames Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
   use type P.Predicate_RM_Closure_Consumer_Id;
   use type P.Predicate_RM_Kind;
   use type P.Predicate_RM_Closure_Consumer_Status;
   use type P.Predicate_RM_Closure_Consumer_Family;
   use type P.Predicate_RM_Closure_Consumer_Context;
   use type P.Predicate_RM_Closure_Consumer_Row;
   use type P.Predicate_RM_Closure_Consumer_Context_Model;
   use type P.Predicate_RM_Closure_Consumer_Model;
   use type P.Predicate_RM_Closure_Consumer_Set;
   package Diag renames Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
   use type Diag.RM_Closure_Consumer_Diagnostic_Id;
   use type Diag.RM_Closure_Consumer_Diagnostic_Family;
   use type Diag.RM_Closure_Consumer_Diagnostic_Severity;
   use type Diag.RM_Closure_Consumer_Diagnostic_Status;
   use type Diag.RM_Closure_Consumer_Diagnostic_Row;
   use type Diag.RM_Closure_Consumer_Diagnostic_Set;
   use type Diag.RM_Closure_Consumer_Diagnostic_Model;
   package W renames Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
   use type W.RM_Closure_Consumer_Worklist_Id;
   use type W.RM_Closure_Consumer_Worklist_Family;
   use type W.RM_Closure_Consumer_Worklist_Diagnostic_Status;
   use type W.RM_Closure_Consumer_Worklist_Action;
   use type W.RM_Closure_Consumer_Worklist_Priority;
   use type W.RM_Closure_Consumer_Worklist_Item;
   use type W.RM_Closure_Consumer_Worklist_Model;
   use type W.RM_Closure_Consumer_Worklist_Set;
   package R renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
   use type R.RM_Closure_Consumer_Recheck_Family;
   use type R.RM_Closure_Consumer_Recheck_Work_Action;
   use type R.RM_Closure_Consumer_Recheck_Work_Priority;
   use type R.RM_Closure_Consumer_Recheck_Id;
   use type R.RM_Closure_Consumer_Recheck_Status;
   use type R.RM_Closure_Consumer_Recheck_Action;
   use type R.RM_Closure_Consumer_Recheck_Row;
   use type R.RM_Closure_Consumer_Recheck_Model;
   use type R.RM_Closure_Consumer_Recheck_Set;
   package A renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
   use type A.RM_Closure_Consumer_Application_Family;
   use type A.RM_Closure_Consumer_Eligibility_Status;
   use type A.RM_Closure_Consumer_Eligibility_Action;
   use type A.RM_Closure_Consumer_Application_Id;
   use type A.RM_Closure_Consumer_Application_Status;
   use type A.RM_Closure_Consumer_Application_Action;
   use type A.RM_Closure_Consumer_Application_Row;
   use type A.RM_Closure_Consumer_Application_Model;
   use type A.RM_Closure_Consumer_Application_Set;
   package C renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
   use type C.RM_Closure_Consumer_Application_Status;
   use type C.RM_Closure_Consumer_Application_Action;
   use type C.RM_Closure_Consumer_Convergence_Family;
   use type C.RM_Closure_Consumer_Convergence_Id;
   use type C.RM_Closure_Consumer_Convergence_Status;
   use type C.RM_Closure_Consumer_Convergence_Action;
   use type C.RM_Closure_Consumer_Convergence_Row;
   use type C.RM_Closure_Consumer_Convergence_Model;
   use type C.RM_Closure_Consumer_Convergence_Set;
   package Prior renames P.Prior;
   package Closure renames P.Closure;
   package Cross_Unit renames P.Cross_Unit;
   package Elaboration renames P.Elaboration;
   package Accessibility renames P.Accessibility;
   package Exception_Finalization renames P.Exception_Finalization;
   package Overload renames P.Overload;
   package Representation renames P.Representation;
   package Tasking renames P.Tasking;
   package Dataflow renames P.Dataflow;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada RM-completion closure consumer recheck convergence");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : P.Predicate_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return P.Predicate_RM_Closure_Consumer_Context is
      Result : P.Predicate_RM_Closure_Consumer_Context;
   begin
      Result.Id := P.Predicate_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Predicate_RM_Row := Prior.Predicate_RM_Completion_Row_Id (Id);
      Result.Predicate_RM_Status := Prior.Predicate_RM_Completion_Legal_Assignment_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Current;
      Result.Cross_Unit_Consumer_Row := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Id (Id);
      Result.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Accepted;
      Result.Elaboration_Consumer_Row := Elaboration.Elaboration_RM_Closure_Consumer_Id (Id);
      Result.Elaboration_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Accepted;
      Result.Accessibility_Consumer_Row := Accessibility.Accessibility_RM_Closure_Consumer_Id (Id);
      Result.Accessibility_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Accepted;
      Result.Exception_Finalization_Consumer_Row := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Id (Id);
      Result.Exception_Finalization_Consumer_Status := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Accepted;
      Result.Overload_Consumer_Row := Overload.Overload_RM_Closure_Consumer_Id (Id);
      Result.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Accepted;
      Result.Representation_Consumer_Row := Representation.Representation_RM_Closure_Consumer_Id (Id);
      Result.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Accepted;
      Result.Tasking_Consumer_Row := Tasking.Tasking_RM_Closure_Consumer_Id (Id);
      Result.Tasking_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Accepted;
      Result.Dataflow_Consumer_Row := Dataflow.Dataflow_RM_Closure_Consumer_Id (Id);
      Result.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Accepted;
      Result.Source_Fingerprint := 1278 * Id;
      Result.Expected_Source_Fingerprint := 1278 * Id;
      Result.Substitution_Fingerprint := 8721 * Id;
      Result.Expected_Substitution_Fingerprint := 8721 * Id;
      return Result;
   end Complete_Context;

   function Build_Application return A.RM_Closure_Consumer_Application_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127801));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127802));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127803));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127804));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127805));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127806));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127807));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127808));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127809));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127810));
   begin
      Cross_Blocker.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      Elaboration_Blocker.Elaboration_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Closure_Elaboration;
      Accessibility_Blocker.Accessibility_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Closure_Accessibility;
      Exception_Blocker.Exception_Finalization_Consumer_Status := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization;
      Overload_Blocker.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Closure_Overload_Type;
      Representation_Blocker.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Closure_Representation;
      Tasking_Blocker.Tasking_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Closure_Tasking_Protected;
      Dataflow_Blocker.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Closure_Dataflow;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      P.Add_Context (Contexts, Accepted);
      P.Add_Context (Contexts, Cross_Blocker);
      P.Add_Context (Contexts, Elaboration_Blocker);
      P.Add_Context (Contexts, Accessibility_Blocker);
      P.Add_Context (Contexts, Exception_Blocker);
      P.Add_Context (Contexts, Overload_Blocker);
      P.Add_Context (Contexts, Representation_Blocker);
      P.Add_Context (Contexts, Tasking_Blocker);
      P.Add_Context (Contexts, Dataflow_Blocker);
      P.Add_Context (Contexts, Fingerprint_Blocker);
      return A.Build (R.Build (W.Build (Diag.Build (P.Build (Contexts)))));
   end Build_Application;

   function Build_Convergence
     (Previous : Natural := 0) return C.RM_Closure_Consumer_Convergence_Model is
      Apps : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
   begin
      return C.Build (Apps, Previous);
   end Build_Convergence;

   procedure Application_Rows_Converge_Or_Remain_Stable_Withheld
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Closure_Consumer_Convergence_Model := Build_Convergence;
      Row   : constant C.RM_Closure_Consumer_Convergence_Row := C.Row_At (Model, 1);
   begin
      Assert (C.Count (Model) = 10,
              "ten direct-consumer convergence rows expected");
      Assert (C.Converged_Count (Model) = 1,
              "current non-diagnostic direct-consumer evidence should converge as not required");
      Assert (C.Stable_Withheld_Count (Model) = 9,
              "blocked direct-consumer rows should remain stably withheld");
      Assert (C.Current_Count (Model) = 0,
              "fixture exposes no newly accepted current row");
      Assert (C.Changed_Count (Model) = 0,
              "fresh convergence should not be marked changed");
      Assert (Row.Status = C.RM_Closure_Consumer_Converged_Not_Required,
              "accepted diagnostic-free evidence should converge as not required");
      Assert (Row.Action = C.RM_Closure_Consumer_Convergence_Action_Skip_Not_Required,
              "converged non-diagnostic evidence should skip fresh recheck work");
   end Application_Rows_Converge_Or_Remain_Stable_Withheld;

   procedure Convergence_Preserves_Direct_Consumer_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Closure_Consumer_Convergence_Model := Build_Convergence;
   begin
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Cross_Unit) = 1,
              "cross-unit blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Elaboration) = 1,
              "elaboration blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Accessibility) = 1,
              "accessibility blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Exception_Finalization) = 1,
              "exception/finalization blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Overload_Type) = 1,
              "overload/type blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Representation) = 1,
              "representation blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Tasking_Protected) = 1,
              "tasking/protected blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Dataflow) = 1,
              "dataflow blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Stable_Withheld_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct through convergence");
   end Convergence_Preserves_Direct_Consumer_Blockers;

   procedure Convergence_Detects_Changed_Application_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Apps    : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
      Current : constant Natural := A.Stable_Fingerprint (Apps);
      Model   : constant C.RM_Closure_Consumer_Convergence_Model := C.Build (Apps, Current + 1);
   begin
      Assert (C.Count (Model) = 10,
              "changed convergence still mirrors application rows");
      Assert (C.Changed_Count (Model) = 10,
              "all rows should force recheck when the model fingerprint changes");
      Assert (C.Count_By_Status (Model, C.RM_Closure_Consumer_Changed_Since_Previous) = 10,
              "changed fingerprint should classify every row as changed since previous");
      Assert (C.Row_At (Model, 1).Action = C.RM_Closure_Consumer_Convergence_Action_Recheck_Again,
              "changed rows should request another recheck");
   end Convergence_Detects_Changed_Application_Fingerprint;

   procedure Convergence_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Closure_Consumer_Convergence_Model := Build_Convergence;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (127810);
   begin
      Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the fingerprint blocker convergence row");
      Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, 1278 * 10)) = 1,
              "source fingerprint lookup should find the fingerprint blocker convergence row");
      Assert (C.Query_Count (C.Find_By_Substitution_Fingerprint (Model, 8721 * 10)) = 1,
              "substitution fingerprint lookup should find the fingerprint blocker convergence row");
      Assert (C.Count_By_Family (Model, Diag.RM_Closure_Consumer_Diagnostic_Source_Fingerprint) = 1,
              "family query should preserve fingerprint blocker identity");
      Assert (C.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate convergence rows");
      Assert (C.Stable_Fingerprint (Model) /= 0,
              "convergence stable fingerprint should be non-zero");
   end Convergence_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Application_Rows_Converge_Or_Remain_Stable_Withheld'Access,
         "direct-consumer application rows converge or remain stably withheld");
      Register_Routine
        (T, Convergence_Preserves_Direct_Consumer_Blockers'Access,
         "direct-consumer convergence preserves blocker families");
      Register_Routine
        (T, Convergence_Detects_Changed_Application_Fingerprint'Access,
         "direct-consumer convergence detects changed fingerprints");
      Register_Routine
        (T, Convergence_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "direct-consumer convergence lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
