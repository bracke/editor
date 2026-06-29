with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration is

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
   package S renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
   use type S.RM_Closure_Consumer_Stabilization_Status;
   use type S.RM_Closure_Consumer_Stabilization_Action;
   use type S.RM_Closure_Consumer_Closure_Family;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Action;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Row;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Model;
   use type S.RM_Closure_Consumer_Stabilized_Closure_Set;
   package D renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
   use type D.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type D.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type D.RM_Closure_Consumer_Stabilized_Closure_Action;
   use type D.RM_Closure_Consumer_Closure_Family;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Id;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Severity;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Row;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   use type D.RM_Closure_Consumer_Stabilized_Diagnostic_Model;
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
      return AUnit.Format ("Ada RM-completion closure consumer stabilized diagnostic integration");
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
      Result.Source_Fingerprint := 1280 * Id;
      Result.Expected_Source_Fingerprint := 1280 * Id;
      Result.Substitution_Fingerprint := 10_280 * Id;
      Result.Expected_Substitution_Fingerprint := 10_280 * Id;
      return Result;
   end Complete_Context;

   function Build_Application return A.RM_Closure_Consumer_Application_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (128001));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (128002));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (128003));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (128004));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (128005));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (128006));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (128007));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (128008));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (128009));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (128010));
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

   function Build_Gate
     (Previous : Natural := 0) return G.RM_Closure_Consumer_Stabilization_Gate_Model is
      Apps : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
      Conv : constant C.RM_Closure_Consumer_Convergence_Model := C.Build (Apps, Previous);
   begin
      return G.Build (Conv);
   end Build_Gate;

   function Build_Closure
     (Previous : Natural := 0) return S.RM_Closure_Consumer_Stabilized_Closure_Model is
   begin
      return S.Build (Build_Gate (Previous));
   end Build_Closure;



   procedure Accepted_Stabilized_Rows_Are_Withheld_As_Current_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure_Model : constant S.RM_Closure_Consumer_Stabilized_Closure_Model := Build_Closure;
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model :=
        D.Build (Closure_Model);
   begin
      Assert (D.Row_Count (Diagnostics) = S.Row_Count (Closure_Model),
              "diagnostic integration should preserve stabilized closure row count");
      Assert (D.Withheld_Current_Count (Diagnostics) = S.Accepted_Count (Closure_Model),
              "accepted stabilized closure rows should be withheld as current evidence");
      Assert (D.Emitted_Count (Diagnostics) = S.Blocked_Count (Closure_Model),
              "stable blockers should be emitted, accepted evidence withheld");
      Assert
        (D.Count_Status (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required) = 1,
         "accepted-not-required stabilized closure status should be preserved");
      Assert (D.Info_Count (Diagnostics) = 1,
              "accepted evidence should remain informational and non-diagnostic");
   end Accepted_Stabilized_Rows_Are_Withheld_As_Current_Evidence;

   procedure Stabilized_Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model :=
        D.Build (Build_Closure);
   begin
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit) = 1,
              "cross-unit stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration) = 1,
              "elaboration stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility) = 1,
              "accessibility stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization) = 1,
              "exception/finalization stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type) = 1,
              "overload/type stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Representation) = 1,
              "representation stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected) = 1,
              "tasking/protected stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow) = 1,
              "dataflow stabilized blocker family should be preserved");
      Assert (D.Count_Family (Diagnostics, D.RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint) = 1,
              "source fingerprint stabilized blocker should be preserved");
      Assert (D.Error_Count (Diagnostics) = 8,
              "semantic prerequisite blockers should enter diagnostics as errors");
      Assert (D.Warning_Count (Diagnostics) = 1,
              "fingerprint blocker should remain warning severity");
   end Stabilized_Blocker_Families_Are_Preserved;

   procedure Query_Surface_Preserves_Closure_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model :=
        D.Build (Build_Closure);
      Row : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Row := D.Row_At (Diagnostics, 10);
   begin
      Assert (D.Query_Count (D.Query_Node (Diagnostics, Row.Node)) = 1,
              "node query should find stabilized direct-consumer diagnostic row");
      Assert (D.Query_Count (D.Query_Source_Fingerprint (Diagnostics, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should find stabilized direct-consumer diagnostic row");
      Assert (D.Query_Count (D.Query_Closure_Family (Diagnostics, Row.Closure_Family)) >= 1,
              "closure-family query should preserve original prerequisite family");
      Assert (D.Fingerprint (Diagnostics) /= 0,
              "stabilized diagnostic fingerprint should be deterministic");
   end Query_Surface_Preserves_Closure_Identity;

   procedure Feed_Integration_Emits_Stable_Blockers_And_Rejects_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model := D.Build (Build_Closure);
      Current_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_RM_Completion_Closure_Consumer_Stabilized_Diagnostics
          (Guarded, Diagnostics, True, 0);
      Stale_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_RM_Completion_Closure_Consumer_Stabilized_Diagnostics
          (Guarded, Diagnostics, False, 17);
   begin
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Current (Current_Feed),
              "current feed should remain current");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Current_Feed) = D.Emitted_Count (Diagnostics),
              "feed should emit exactly stabilized direct-consumer blockers");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Current_Feed) = 8,
              "semantic stabilized blockers should enter feed as errors");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Warning_Count (Current_Feed) = 1,
              "fingerprint stabilized blocker should enter feed as warning");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Stale_Feed),
              "stale stabilized direct-consumer diagnostics should reject the feed");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Stale_Feed) = 17,
              "stale rejection count should be preserved");
   end Feed_Integration_Emits_Stable_Blockers_And_Rejects_Stale;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Stabilized_Rows_Are_Withheld_As_Current_Evidence'Access,
         "accepted stabilized rows are withheld as current evidence");
      Register_Routine
        (T, Stabilized_Blocker_Families_Are_Preserved'Access,
         "stabilized blocker families are preserved");
      Register_Routine
        (T, Query_Surface_Preserves_Closure_Identity'Access,
         "query surface preserves closure identity");
      Register_Routine
        (T, Feed_Integration_Emits_Stable_Blockers_And_Rejects_Stale'Access,
         "feed integration emits stable blockers and rejects stale input");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
