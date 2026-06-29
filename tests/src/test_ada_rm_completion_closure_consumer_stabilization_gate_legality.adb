with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality is

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
   package G renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
   use type G.RM_Closure_Consumer_Convergence_Status;
   use type G.RM_Closure_Consumer_Convergence_Action;
   use type G.RM_Closure_Consumer_Stabilization_Family;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Id;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Status;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Action;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Row;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Model;
   use type G.RM_Closure_Consumer_Stabilization_Gate_Set;
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
      return AUnit.Format ("Ada RM-completion closure consumer stabilization gate");
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
      Result.Source_Fingerprint := 1279 * Id;
      Result.Expected_Source_Fingerprint := 1279 * Id;
      Result.Substitution_Fingerprint := 9721 * Id;
      Result.Expected_Substitution_Fingerprint := 9721 * Id;
      return Result;
   end Complete_Context;

   function Build_Application return A.RM_Closure_Consumer_Application_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127901));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127902));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127903));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127904));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127905));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127906));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127907));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127908));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127909));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127910));
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



   function Build_Gate
     (Previous : Natural := 0) return G.RM_Closure_Consumer_Stabilization_Gate_Model is
      Conv : constant C.RM_Closure_Consumer_Convergence_Model := Build_Convergence (Previous);
   begin
      return G.Build (Conv);
   end Build_Gate;

   procedure Stable_Convergence_Promotes_Or_Withholds_At_Gate
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant G.RM_Closure_Consumer_Stabilization_Gate_Model := Build_Gate;
      Row   : constant G.RM_Closure_Consumer_Stabilization_Gate_Row := G.Row_At (Model, 1);
   begin
      Assert (G.Count (Model) = 10,
              "ten stabilization gate rows expected");
      Assert (G.Promoted_Count (Model) = 1,
              "converged not-required evidence should be promoted across the stable boundary");
      Assert (G.Withheld_Count (Model) = 9,
              "stable blockers should remain withheld at the gate");
      Assert (G.Current_Count (Model) = 0,
              "fixture exposes no newly current diagnostic row");
      Assert (G.Recheck_Required_Count (Model) = 0,
              "fresh stable convergence should not require another recheck");
      Assert (Row.Status = G.RM_Closure_Consumer_Stabilization_Gate_Promoted_Not_Required,
              "accepted non-diagnostic evidence should be promoted as not-required");
      Assert (Row.Action = G.RM_Closure_Consumer_Stabilization_Gate_Action_Promote_Not_Required,
              "promoted non-diagnostic evidence should cross the stable gate without diagnostics");
   end Stable_Convergence_Promotes_Or_Withholds_At_Gate;

   procedure Gate_Preserves_Direct_Consumer_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant G.RM_Closure_Consumer_Stabilization_Gate_Model := Build_Gate;
   begin
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Cross_Unit) = 1,
              "cross-unit blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Elaboration) = 1,
              "elaboration blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Accessibility) = 1,
              "accessibility blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Exception_Finalization) = 1,
              "exception/finalization blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Overload_Type) = 1,
              "overload/type blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Representation) = 1,
              "representation blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Tasking_Protected) = 1,
              "tasking/protected blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Dataflow) = 1,
              "dataflow blocker should remain distinct at stabilization gate");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Withheld_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct at stabilization gate");
   end Gate_Preserves_Direct_Consumer_Blocker_Families;

   procedure Changed_Convergence_Is_Not_Promoted
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Apps    : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
      Current : constant Natural := A.Stable_Fingerprint (Apps);
      Conv    : constant C.RM_Closure_Consumer_Convergence_Model := C.Build (Apps, Current + 1);
      Model   : constant G.RM_Closure_Consumer_Stabilization_Gate_Model := G.Build (Conv);
   begin
      Assert (G.Count (Model) = 10,
              "changed convergence should still mirror input rows");
      Assert (G.Recheck_Required_Count (Model) = 10,
              "changed convergence rows should require another bounded recheck");
      Assert (G.Promoted_Count (Model) = 0,
              "changed convergence rows must not be promoted");
      Assert (G.Count_By_Status (Model, G.RM_Closure_Consumer_Stabilization_Gate_Recheck_Required) = 10,
              "changed fingerprints should be gated as recheck required");
      Assert (G.Row_At (Model, 1).Action = G.RM_Closure_Consumer_Stabilization_Gate_Action_Recheck,
              "changed rows should request recheck at the stabilization gate");
   end Changed_Convergence_Is_Not_Promoted;

   procedure Gate_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant G.RM_Closure_Consumer_Stabilization_Gate_Model := Build_Gate;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (127910);
   begin
      Assert (G.Query_Count (G.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the fingerprint blocker gate row");
      Assert (G.Query_Count (G.Find_By_Source_Fingerprint (Model, 1279 * 10)) = 1,
              "source fingerprint lookup should find the fingerprint blocker gate row");
      Assert (G.Query_Count (G.Find_By_Substitution_Fingerprint (Model, 9721 * 10)) = 1,
              "substitution fingerprint lookup should find the fingerprint blocker gate row");
      Assert (G.Count_By_Family (Model, Diag.RM_Closure_Consumer_Diagnostic_Source_Fingerprint) = 1,
              "family query should preserve fingerprint blocker identity");
      Assert (G.Indeterminate_Count (Model) = 0,
              "fixture should not produce degraded indeterminate gate rows");
      Assert (G.Stable_Fingerprint (Model) /= 0,
              "stabilization gate fingerprint should be non-zero");
   end Gate_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Stable_Convergence_Promotes_Or_Withholds_At_Gate'Access,
         "stable convergence promotes or withholds at stabilization gate");
      Register_Routine
        (T, Gate_Preserves_Direct_Consumer_Blocker_Families'Access,
         "stabilization gate preserves direct-consumer blocker families");
      Register_Routine
        (T, Changed_Convergence_Is_Not_Promoted'Access,
         "changed convergence is not promoted");
      Register_Routine
        (T, Gate_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "stabilization gate lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
