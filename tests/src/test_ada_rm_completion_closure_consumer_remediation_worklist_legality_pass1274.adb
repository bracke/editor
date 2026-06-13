with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality_Pass1274 is

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
      return AUnit.Format ("Ada RM-completion closure consumer remediation worklist pass1274");
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
      Result.Source_Fingerprint := 1274 * Id;
      Result.Expected_Source_Fingerprint := 1274 * Id;
      Result.Substitution_Fingerprint := 4721 * Id;
      Result.Expected_Substitution_Fingerprint := 4721 * Id;
      return Result;
   end Complete_Context;

   function Build_Worklist return W.RM_Closure_Consumer_Worklist_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127401));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127402));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127403));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127404));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127405));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127406));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127407));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127408));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127409));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127410));
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

   procedure Diagnostic_Blockers_Become_Work_Items
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Closure_Consumer_Worklist_Model := Build_Worklist;
   begin
      Assert (W.Count (Worklist) = 10,
              "ten direct-consumer remediation rows expected");
      Assert (W.Current_Evidence_Count (Worklist) = 1,
              "accepted diagnostic row should remain current semantic evidence");
      Assert (W.Ready_For_Recheck_Count (Worklist) = 9,
              "blocking rows should become recheck-ready remediation work");
      Assert (W.Blocked_Downstream_Count (Worklist) = 9,
              "blocking remediation rows should block downstream semantic trust");
   end Diagnostic_Blockers_Become_Work_Items;

   procedure Families_Map_To_Direct_Consumer_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Closure_Consumer_Worklist_Model := Build_Worklist;
   begin
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Cross_Unit) = 1,
              "cross-unit blocker should map to cross-unit action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Elaboration) = 1,
              "elaboration blocker should map to elaboration action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Accessibility) = 1,
              "accessibility blocker should map to accessibility action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Exception_Finalization) = 1,
              "exception/finalization blocker should map to exception action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Overload_Type) = 1,
              "overload/type blocker should map to overload action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Representation) = 1,
              "representation blocker should map to representation action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Tasking_Protected) = 1,
              "tasking/protected blocker should map to tasking action");
      Assert (W.Count_Action (Worklist, W.RM_Closure_Consumer_Worklist_Resolve_Dataflow) = 1,
              "dataflow blocker should map to dataflow action");
      Assert (W.Fingerprint_Mismatch_Count (Worklist) = 1,
              "source fingerprint mismatch should map to fingerprint recheck");
   end Families_Map_To_Direct_Consumer_Actions;

   procedure Priorities_Preserve_Prerequisite_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Closure_Consumer_Worklist_Model := Build_Worklist;
   begin
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Current_Evidence) = 1,
              "current evidence priority should be retained");
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Cross_Unit) = 1,
              "cross-unit priority should be retained");
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Elaboration) = 1,
              "elaboration priority should be retained");
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Accessibility) = 1,
              "accessibility priority should be retained");
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Exception_Finalization) = 1,
              "exception/finalization priority should be retained");
      Assert (W.Count_Priority (Worklist, W.RM_Closure_Consumer_Worklist_Priority_Stale_Or_Fingerprint) = 1,
              "fingerprint priority should be retained");
   end Priorities_Preserve_Prerequisite_Order;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Closure_Consumer_Worklist_Model := Build_Worklist;
      Row : constant W.RM_Closure_Consumer_Worklist_Item := W.Row_At (Worklist, 2);
   begin
      Assert (W.Query_Count (W.Query_Node (Worklist, Row.Node)) = 1,
              "node query should recover direct-consumer work item");
      Assert (W.Query_Count (W.Query_Source_Fingerprint (Worklist, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover direct-consumer work item");
      Assert (W.Count_Family (Worklist, Diag.RM_Closure_Consumer_Diagnostic_Cross_Unit) = 1,
              "family query should preserve direct-consumer blocker identity");
      Assert (W.Stable_Fingerprint (Worklist) /= 0,
              "direct-consumer worklist stable fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Diagnostic_Blockers_Become_Work_Items'Access,
         "diagnostic blockers become direct-consumer work items");
      Register_Routine
        (T, Families_Map_To_Direct_Consumer_Actions'Access,
         "families map to direct-consumer remediation actions");
      Register_Routine
        (T, Priorities_Preserve_Prerequisite_Order'Access,
         "priorities preserve prerequisite remediation order");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality_Pass1274;
