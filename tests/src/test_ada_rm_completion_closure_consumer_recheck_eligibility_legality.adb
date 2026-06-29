with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality is

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
      return AUnit.Format ("Ada RM-completion closure consumer recheck eligibility");
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
      Result.Source_Fingerprint := 1275 * Id;
      Result.Expected_Source_Fingerprint := 1275 * Id;
      Result.Substitution_Fingerprint := 5721 * Id;
      Result.Expected_Substitution_Fingerprint := 5721 * Id;
      return Result;
   end Complete_Context;

   function Build_Worklist return W.RM_Closure_Consumer_Worklist_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127501));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127502));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127503));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127504));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127505));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127506));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127507));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127508));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127509));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127510));
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
      return W.Build (Diag.Build (P.Build (Contexts)));
   end Build_Worklist;



   function Build_Recheck return R.RM_Closure_Consumer_Recheck_Model is
   begin
      return R.Build (Build_Worklist);
   end Build_Recheck;

   procedure Worklist_Becomes_Bounded_Recheck_Eligibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Recheck : constant R.RM_Closure_Consumer_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Row_Count (Recheck) = 10,
              "ten direct-consumer recheck eligibility rows expected");
      Assert (R.Current_Evidence_Count (Recheck) = 1,
              "accepted consumer diagnostic should remain current evidence");
      Assert (R.Eligible_Count (Recheck) = 0,
              "unresolved prerequisite blockers should not be eligible yet");
      Assert (R.Blocked_Count (Recheck) = 9,
              "blocking work items should remain bounded prerequisite blockers");
   end Worklist_Becomes_Bounded_Recheck_Eligibility;

   procedure Direct_Consumer_Blockers_Preserve_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Recheck : constant R.RM_Closure_Consumer_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Cross_Unit_Blocked_Count (Recheck) = 1,
              "cross-unit prerequisite should block direct-consumer recheck");
      Assert (R.Elaboration_Blocked_Count (Recheck) = 1,
              "elaboration prerequisite should block direct-consumer recheck");
      Assert (R.Accessibility_Blocked_Count (Recheck) = 1,
              "accessibility prerequisite should block direct-consumer recheck");
      Assert (R.Exception_Blocked_Count (Recheck) = 1,
              "exception/finalization prerequisite should block direct-consumer recheck");
      Assert (R.Overload_Blocked_Count (Recheck) = 1,
              "overload/type prerequisite should block direct-consumer recheck");
      Assert (R.Representation_Blocked_Count (Recheck) = 1,
              "representation prerequisite should block direct-consumer recheck");
      Assert (R.Tasking_Blocked_Count (Recheck) = 1,
              "tasking/protected prerequisite should block direct-consumer recheck");
      Assert (R.Dataflow_Blocked_Count (Recheck) = 1,
              "dataflow prerequisite should block direct-consumer recheck");
      Assert (R.Fingerprint_Blocked_Count (Recheck) = 1,
              "fingerprint mismatch should remain a fingerprint blocker");
   end Direct_Consumer_Blockers_Preserve_Status;

   procedure Actions_Preserve_Prerequisite_Waits
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Recheck : constant R.RM_Closure_Consumer_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Keep_Current) = 1,
              "current evidence should keep current action");
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Wait_For_Cross_Unit) = 1,
              "cross-unit blocker should wait for cross-unit evidence");
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Wait_For_Elaboration) = 1,
              "elaboration blocker should wait for elaboration evidence");
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Wait_For_Accessibility) = 1,
              "accessibility blocker should wait for accessibility evidence");
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Wait_For_Exception_Finalization) = 1,
              "exception blocker should wait for exception/finalization evidence");
      Assert (R.Count_Action (Recheck, R.RM_Closure_Consumer_Recheck_Action_Wait_For_Source_Fingerprint) = 1,
              "source fingerprint mismatch should wait for source fingerprint refresh");
   end Actions_Preserve_Prerequisite_Waits;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Recheck : constant R.RM_Closure_Consumer_Recheck_Model := Build_Recheck;
      Row : constant R.RM_Closure_Consumer_Recheck_Row := R.Row_At (Recheck, 2);
   begin
      Assert (R.Query_Count (R.Query_Node (Recheck, Row.Node)) = 1,
              "node query should recover direct-consumer recheck row");
      Assert (R.Query_Count (R.Query_Source_Fingerprint (Recheck, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover direct-consumer recheck row");
      Assert (R.Count_Family (Recheck, Diag.RM_Closure_Consumer_Diagnostic_Cross_Unit) = 1,
              "family query should preserve direct-consumer blocker identity");
      Assert (R.Stable_Fingerprint (Recheck) /= 0,
              "direct-consumer recheck eligibility stable fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Worklist_Becomes_Bounded_Recheck_Eligibility'Access,
         "worklist becomes bounded recheck eligibility");
      Register_Routine
        (T, Direct_Consumer_Blockers_Preserve_Status'Access,
         "direct-consumer blockers preserve recheck status");
      Register_Routine
        (T, Actions_Preserve_Prerequisite_Waits'Access,
         "actions preserve prerequisite waits");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
