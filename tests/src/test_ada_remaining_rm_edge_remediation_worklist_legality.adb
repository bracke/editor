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
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;
with Editor.Ada_Remaining_RM_Edge_Precision_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
with Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Remaining_RM_Edge_Remediation_Worklist_Legality is

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
   package Rch renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
   use type Rch.RM_Closure_Consumer_Recheck_Family;
   use type Rch.RM_Closure_Consumer_Recheck_Work_Action;
   use type Rch.RM_Closure_Consumer_Recheck_Work_Priority;
   use type Rch.RM_Closure_Consumer_Recheck_Id;
   use type Rch.RM_Closure_Consumer_Recheck_Status;
   use type Rch.RM_Closure_Consumer_Recheck_Action;
   use type Rch.RM_Closure_Consumer_Recheck_Row;
   use type Rch.RM_Closure_Consumer_Recheck_Model;
   use type Rch.RM_Closure_Consumer_Recheck_Set;
   package App renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
   use type App.RM_Closure_Consumer_Application_Family;
   use type App.RM_Closure_Consumer_Eligibility_Status;
   use type App.RM_Closure_Consumer_Eligibility_Action;
   use type App.RM_Closure_Consumer_Application_Id;
   use type App.RM_Closure_Consumer_Application_Status;
   use type App.RM_Closure_Consumer_Application_Action;
   use type App.RM_Closure_Consumer_Application_Row;
   use type App.RM_Closure_Consumer_Application_Model;
   use type App.RM_Closure_Consumer_Application_Set;
   package Conv renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
   use type Conv.RM_Closure_Consumer_Application_Status;
   use type Conv.RM_Closure_Consumer_Application_Action;
   use type Conv.RM_Closure_Consumer_Convergence_Family;
   use type Conv.RM_Closure_Consumer_Convergence_Id;
   use type Conv.RM_Closure_Consumer_Convergence_Status;
   use type Conv.RM_Closure_Consumer_Convergence_Action;
   use type Conv.RM_Closure_Consumer_Convergence_Row;
   use type Conv.RM_Closure_Consumer_Convergence_Model;
   use type Conv.RM_Closure_Consumer_Convergence_Set;
   package Gate renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
   use type Gate.RM_Closure_Consumer_Convergence_Status;
   use type Gate.RM_Closure_Consumer_Convergence_Action;
   use type Gate.RM_Closure_Consumer_Stabilization_Family;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Id;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Status;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Action;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Row;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Model;
   use type Gate.RM_Closure_Consumer_Stabilization_Gate_Set;
   package Stable renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
   use type Stable.RM_Closure_Consumer_Stabilization_Status;
   use type Stable.RM_Closure_Consumer_Stabilization_Action;
   use type Stable.RM_Closure_Consumer_Closure_Family;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Action;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Row;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Model;
   use type Stable.RM_Closure_Consumer_Stabilized_Closure_Set;
   package Stable_Diag renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Closure_Action;
   use type Stable_Diag.RM_Closure_Consumer_Closure_Family;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Id;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Severity;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   use type Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Model;
   package Prov renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Id;
   use type Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Id;
   use type Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type Prov.RM_Closure_Consumer_Closure_Family;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Status;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Stage;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Blocker;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Row;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Model;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Set;
   package Search renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;
   use type Search.RM_Closure_Consumer_Stabilized_Provenance_Id;
   use type Search.RM_Closure_Consumer_Stabilized_Provenance_Status;
   use type Search.RM_Closure_Consumer_Stabilized_Provenance_Stage;
   use type Search.RM_Closure_Consumer_Stabilized_Provenance_Blocker;
   use type Search.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type Search.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type Search.RM_Closure_Consumer_Closure_Family;
   use type Search.RM_Closure_Consumer_Stabilized_Search_Index_Id;
   use type Search.RM_Closure_Consumer_Stabilized_Search_Entry;
   use type Search.RM_Closure_Consumer_Stabilized_Search_Result;
   use type Search.RM_Closure_Consumer_Stabilized_Search_Result_Set;
   use type Search.RM_Closure_Consumer_Stabilized_Search_Index_Model;
   package Edge renames Editor.Ada_Remaining_RM_Edge_Precision_Legality;
   use type Edge.Remaining_RM_Edge_Precision_Id;
   use type Edge.Remaining_RM_Edge_Kind;
   use type Edge.Remaining_RM_Edge_Blocker_Family;
   use type Edge.Remaining_RM_Edge_Status;
   use type Edge.Remaining_RM_Edge_Context;
   use type Edge.Remaining_RM_Edge_Row;
   use type Edge.Remaining_RM_Edge_Context_Model;
   use type Edge.Remaining_RM_Edge_Model;
   use type Edge.Remaining_RM_Edge_Set;
   package Consumer renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Id;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Status;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Blocker;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Row;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Model;
   use type Consumer.Remaining_RM_Edge_Stabilized_Consumer_Set;
   package D renames Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
   use type D.Remaining_RM_Edge_Stabilized_Consumer_Id;
   use type D.Remaining_RM_Edge_Stabilized_Consumer_Status;
   use type D.Remaining_RM_Edge_Stabilized_Consumer_Blocker;
   use type D.Remaining_RM_Edge_Kind;
   use type D.Remaining_RM_Edge_Blocker_Family;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Id;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Family;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Severity;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Status;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Row;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Set;
   use type D.Remaining_RM_Edge_Stabilized_Diagnostic_Model;
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
      return AUnit.Format ("Ada remaining RM edge remediation worklist legality");
   end Name;

   function Complete_Predicate_Context
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
   end Complete_Predicate_Context;

   function Build_Application return App.RM_Closure_Consumer_Application_Model is
      Contexts : P.Predicate_RM_Closure_Consumer_Context_Model;
      Accepted : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Predicate_Context (1, Prior.Predicate_RM_Completion_Assignment, Editor.Ada_Syntax_Tree.Node_Id (128501));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Predicate_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State, Editor.Ada_Syntax_Tree.Node_Id (128502));
   begin
      Cross_Blocker.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      P.Add_Context (Contexts, Accepted);
      P.Add_Context (Contexts, Cross_Blocker);
      return App.Build (Rch.Build (W.Build (Diag.Build (P.Build (Contexts)))));
   end Build_Application;

   function Build_Stable return Stable.RM_Closure_Consumer_Stabilized_Closure_Model is
      Apps : constant App.RM_Closure_Consumer_Application_Model := Build_Application;
      Convergence : constant Conv.RM_Closure_Consumer_Convergence_Model := Conv.Build (Apps, 0);
      Gates : constant Gate.RM_Closure_Consumer_Stabilization_Gate_Model := Gate.Build (Convergence);
   begin
      return Stable.Build (Gates);
   end Build_Stable;

   function Build_Search return Search.RM_Closure_Consumer_Stabilized_Search_Index_Model is
      Stable_Model : constant Stable.RM_Closure_Consumer_Stabilized_Closure_Model := Build_Stable;
      Diagnostics : constant Stable_Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Model := Stable_Diag.Build (Stable_Model);
      Provenance : constant Prov.RM_Closure_Consumer_Stabilized_Provenance_Model := Prov.Build (Diagnostics);
   begin
      return Search.Build (Provenance);
   end Build_Search;

   function Complete_Edge
     (Id : Natural;
      Kind : Edge.Remaining_RM_Edge_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id;
      Application : Natural) return Edge.Remaining_RM_Edge_Context is
      Result : Edge.Remaining_RM_Edge_Context;
   begin
      Result.Id := Edge.Remaining_RM_Edge_Precision_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Application_Row := Edge.Application.RM_Closure_Consumer_Application_Id (Application);
      Result.Application_Status := Edge.Application.RM_Closure_Consumer_Application_Current_Accepted;
      Result.Source_Fingerprint := 1280 * Application;
      Result.Expected_Source_Fingerprint := 1280 * Application;
      Result.Substitution_Fingerprint := 10_280 * Application;
      Result.Expected_Substitution_Fingerprint := 10_280 * Application;
      return Result;
   end Complete_Edge;

   function Build_Edges return Edge.Remaining_RM_Edge_Model is
      Contexts : Edge.Remaining_RM_Edge_Context_Model;
      Accepted : Edge.Remaining_RM_Edge_Context :=
        Complete_Edge (1, Edge.Remaining_RM_Edge_Dispatching_Abstract_State_Effect, Editor.Ada_Syntax_Tree.Node_Id (128501), 1);
      Closure_Blocker : Edge.Remaining_RM_Edge_Context :=
        Complete_Edge (2, Edge.Remaining_RM_Edge_Renamed_Primitive, Editor.Ada_Syntax_Tree.Node_Id (128502), 2);
      Edge_Blocker : Edge.Remaining_RM_Edge_Context :=
        Complete_Edge (3, Edge.Remaining_RM_Edge_Protected_Action_Reentrancy, Editor.Ada_Syntax_Tree.Node_Id (128501), 1);
      Missing_Closure : Edge.Remaining_RM_Edge_Context :=
        Complete_Edge (4, Edge.Remaining_RM_Edge_Access_Subprogram_Effect_Profile, Editor.Ada_Syntax_Tree.Node_Id (128599), 99);
      Source_Mismatch : Edge.Remaining_RM_Edge_Context :=
        Complete_Edge (5, Edge.Remaining_RM_Edge_Volatile_Atomic_Representation_Clause, Editor.Ada_Syntax_Tree.Node_Id (128501), 1);
   begin
      Edge_Blocker.Protected_Reentrancy_Mismatch := True;
      Source_Mismatch.Source_Fingerprint := 77_777;
      Source_Mismatch.Expected_Source_Fingerprint := 77_777;

      Edge.Add_Context (Contexts, Accepted);
      Edge.Add_Context (Contexts, Closure_Blocker);
      Edge.Add_Context (Contexts, Edge_Blocker);
      Edge.Add_Context (Contexts, Missing_Closure);
      Edge.Add_Context (Contexts, Source_Mismatch);
      return Edge.Build (Contexts);
   end Build_Edges;

   function Build_Consumers return Consumer.Remaining_RM_Edge_Stabilized_Consumer_Model is
   begin
      return Consumer.Build (Build_Edges, Build_Stable, Build_Search);
   end Build_Consumers;


   package WL renames Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
   use type WL.Remaining_RM_Edge_Worklist_Diagnostic_Status;
   use type WL.Remaining_RM_Edge_Worklist_Diagnostic_Family;
   use type WL.Remaining_RM_Edge_Kind;
   use type WL.Remaining_RM_Edge_Blocker_Family;
   use type WL.Remaining_RM_Edge_Worklist_Id;
   use type WL.Remaining_RM_Edge_Worklist_Action;
   use type WL.Remaining_RM_Edge_Worklist_Priority;
   use type WL.Remaining_RM_Edge_Worklist_Item;
   use type WL.Remaining_RM_Edge_Worklist_Model;
   use type WL.Remaining_RM_Edge_Worklist_Set;

   function Build_Diagnostics return D.Remaining_RM_Edge_Stabilized_Diagnostic_Model is
   begin
      return D.Build (Build_Consumers);
   end Build_Diagnostics;

   function Build_Worklist return WL.Remaining_RM_Edge_Worklist_Model is
   begin
      return WL.Build (Build_Diagnostics);
   end Build_Worklist;

   procedure Diagnostics_Are_Converted_To_Deterministic_Work_Items
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.Remaining_RM_Edge_Stabilized_Diagnostic_Model := Build_Diagnostics;
      Worklist : constant WL.Remaining_RM_Edge_Worklist_Model := WL.Build (Diagnostics);
   begin
      Assert (WL.Count (Worklist) = D.Row_Count (Diagnostics),
              "worklist should preserve remaining-edge diagnostic row count");
      Assert (WL.Current_Evidence_Count (Worklist) = D.Withheld_Current_Count (Diagnostics),
              "accepted remaining-edge diagnostics should remain current evidence");
      Assert (WL.Ready_For_Recheck_Count (Worklist) = D.Emitted_Count (Diagnostics),
              "emitted remaining-edge blockers should become recheck work");
      Assert (WL.Blocked_Downstream_Count (Worklist) = D.Emitted_Count (Diagnostics),
              "emitted blockers should block downstream remaining-edge consumers");
   end Diagnostics_Are_Converted_To_Deterministic_Work_Items;

   procedure Orders_Remaining_Edge_And_Closure_Prerequisites
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant WL.Remaining_RM_Edge_Worklist_Model := Build_Worklist;
   begin
      Assert (WL.Count_Action (Worklist, WL.Remaining_RM_Edge_Worklist_Keep_Current_Evidence) = 1,
              "accepted remaining-edge rows should be kept as current evidence");
      Assert (WL.Count_Action (Worklist, WL.Remaining_RM_Edge_Worklist_Resolve_Remaining_Edge) = 1,
              "remaining RM edge blockers should be routed to remaining-edge repair");
      Assert (WL.Count_Action (Worklist, WL.Remaining_RM_Edge_Worklist_Resolve_Stabilized_Closure) = 2,
              "missing or blocked stabilized closure evidence should be resolved before edge recheck");
      Assert (WL.Count_Priority (Worklist, WL.Remaining_RM_Edge_Worklist_Priority_Remaining_Edge) = 1,
              "remaining-edge work should keep its own remediation priority");
      Assert (WL.Count_Priority (Worklist, WL.Remaining_RM_Edge_Worklist_Priority_Stabilized_Closure) = 2,
              "stabilized-closure blockers should keep closure priority");
   end Orders_Remaining_Edge_And_Closure_Prerequisites;

   procedure Preserves_Fingerprint_And_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant WL.Remaining_RM_Edge_Worklist_Model := Build_Worklist;
   begin
      Assert (WL.Count_Family (Worklist, D.Remaining_RM_Edge_Stabilized_Diagnostic_Remaining_Edge) = 1,
              "remaining-edge diagnostic family should be preserved");
      Assert (WL.Count_Family (Worklist, D.Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure) = 2,
              "stabilized-closure diagnostic family should be preserved");
      Assert (WL.Fingerprint_Mismatch_Count (Worklist) = 1,
              "source or substitution fingerprint blockers should be counted separately");
      Assert (WL.Query_Count (WL.Query_Edge_Blocker (Worklist, Edge.Remaining_RM_Edge_Blocker_Protected_Reentrancy)) = 1,
              "protected reentrancy edge blocker should remain queryable");
      Assert (WL.Stable_Fingerprint (Worklist) /= 0,
              "worklist fingerprint should be deterministic");
   end Preserves_Fingerprint_And_Blocker_Families;

   procedure Query_Surface_Finds_Node_And_Source_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant WL.Remaining_RM_Edge_Worklist_Model := Build_Worklist;
      Row : constant WL.Remaining_RM_Edge_Worklist_Item := WL.Row_At (Worklist, 3);
   begin
      Assert (WL.Query_Count (WL.Query_Node (Worklist, Row.Node)) >= 1,
              "node query should find remaining-edge worklist rows");
      Assert (WL.Query_Count (WL.Query_Source_Fingerprint (Worklist, Row.Source_Fingerprint)) >= 1,
              "source fingerprint query should find remaining-edge worklist rows");
      Assert (WL.Is_Ready_For_Recheck (Row),
              "blocked row should be ready for bounded recheck");
      Assert (WL.Blocks_Downstream (Row),
              "blocked row should block downstream remaining-edge consumers");
   end Query_Surface_Finds_Node_And_Source_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Diagnostics_Are_Converted_To_Deterministic_Work_Items'Access,
         "diagnostics are converted to deterministic work items");
      Register_Routine
        (T, Orders_Remaining_Edge_And_Closure_Prerequisites'Access,
         "orders remaining-edge and closure prerequisites");
      Register_Routine
        (T, Preserves_Fingerprint_And_Blocker_Families'Access,
         "preserves fingerprint and blocker families");
      Register_Routine
        (T, Query_Surface_Finds_Node_And_Source_Fingerprint'Access,
         "query surface finds node and source fingerprint");
   end Register_Tests;

end Test_Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
