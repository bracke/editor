with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality is

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
      return AUnit.Format ("Ada RM-completion closure consumer recheck application");
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
      Result.Source_Fingerprint := 1276 * Id;
      Result.Expected_Source_Fingerprint := 1276 * Id;
      Result.Substitution_Fingerprint := 6721 * Id;
      Result.Expected_Substitution_Fingerprint := 6721 * Id;
      return Result;
   end Complete_Context;

   function Build_Eligibility return R.RM_Closure_Consumer_Recheck_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (127601));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127602));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization,
                          Editor.Ada_Syntax_Tree.Node_Id (127603));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (127604));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (127605));
      Overload_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127606));
      Representation_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127607));
      Tasking_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (8, Prior.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (127608));
      Dataflow_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (9, Prior.Predicate_RM_Completion_Return,
                          Editor.Ada_Syntax_Tree.Node_Id (127609));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (10, Prior.Predicate_RM_Completion_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (127610));
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
      return R.Build (W.Build (Diag.Build (P.Build (Contexts))));
   end Build_Eligibility;

   function Build_Application return A.RM_Closure_Consumer_Application_Model is
   begin
      return A.Build (Build_Eligibility);
   end Build_Application;

   procedure Eligibility_Is_Applied_To_Current_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      App : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
   begin
      Assert (A.Row_Count (App) = 10,
              "ten direct-consumer recheck application rows expected");
      Assert (A.Current_Count (App) = 1,
              "accepted current evidence should remain current");
      Assert (A.Accepted_Count (App) = 0,
              "no blocked prerequisite should be exposed as accepted current");
      Assert (A.Withheld_Count (App) = 9,
              "blocking prerequisites should remain withheld at application boundary");
   end Eligibility_Is_Applied_To_Current_Boundary;

   procedure Withheld_Blockers_Preserve_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      App : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
   begin
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Cross_Unit) = 1,
              "cross-unit prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Elaboration) = 1,
              "elaboration prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Accessibility) = 1,
              "accessibility prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Exception_Finalization) = 1,
              "exception/finalization prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Overload_Type) = 1,
              "overload/type prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Representation) = 1,
              "representation prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Tasking_Protected) = 1,
              "tasking/protected prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Dataflow) = 1,
              "dataflow prerequisite should be withheld");
      Assert (A.Count_Status (App, A.RM_Closure_Consumer_Application_Withheld_Source_Fingerprint) = 1,
              "source fingerprint mismatch should be withheld");
   end Withheld_Blockers_Preserve_Status;

   procedure Actions_Preserve_Application_Waits
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      App : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
   begin
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Keep_Non_Diagnostic_Evidence) = 1,
              "current evidence should be kept as non-diagnostic evidence");
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Withhold_For_Cross_Unit) = 1,
              "cross-unit blocker should withhold for cross-unit evidence");
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Withhold_For_Elaboration) = 1,
              "elaboration blocker should withhold for elaboration evidence");
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Withhold_For_Accessibility) = 1,
              "accessibility blocker should withhold for accessibility evidence");
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Withhold_For_Exception_Finalization) = 1,
              "exception blocker should withhold for exception/finalization evidence");
      Assert (A.Count_Action (App, A.RM_Closure_Consumer_Application_Action_Withhold_For_Source_Fingerprint) = 1,
              "source fingerprint mismatch should withhold for source fingerprint refresh");
   end Actions_Preserve_Application_Waits;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      App : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
      Row : constant A.RM_Closure_Consumer_Application_Row := A.Row_At (App, 2);
   begin
      Assert (A.Query_Count (A.Query_Node (App, Row.Node)) = 1,
              "node query should recover direct-consumer application row");
      Assert (A.Query_Count (A.Query_Source_Fingerprint (App, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover direct-consumer application row");
      Assert (A.Query_Count (A.Query_Substitution_Fingerprint (App, Row.Substitution_Fingerprint)) = 1,
              "substitution fingerprint query should recover direct-consumer application row");
      Assert (A.Count_Family (App, Diag.RM_Closure_Consumer_Diagnostic_Cross_Unit) = 1,
              "family query should preserve direct-consumer blocker identity");
      Assert (A.Stable_Fingerprint (App) /= 0,
              "direct-consumer recheck application stable fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Eligibility_Is_Applied_To_Current_Boundary'Access,
         "eligibility is applied to current boundary");
      Register_Routine
        (T, Withheld_Blockers_Preserve_Status'Access,
         "withheld blockers preserve status");
      Register_Routine
        (T, Actions_Preserve_Application_Waits'Access,
         "actions preserve application waits");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
