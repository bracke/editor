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
with Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
with Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
with Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration_Pass1292 is

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
      return AUnit.Format ("Ada remaining RM edge stabilized closure diagnostic integration pass1292");
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


   package EL renames Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
   use type EL.Remaining_RM_Edge_Recheck_Diagnostic_Status;
   use type EL.Remaining_RM_Edge_Recheck_Diagnostic_Family;
   use type EL.Remaining_RM_Edge_Recheck_Work_Action;
   use type EL.Remaining_RM_Edge_Recheck_Work_Priority;
   use type EL.Remaining_RM_Edge_Kind;
   use type EL.Remaining_RM_Edge_Blocker_Family;
   use type EL.Remaining_RM_Edge_Recheck_Id;
   use type EL.Remaining_RM_Edge_Recheck_Status;
   use type EL.Remaining_RM_Edge_Recheck_Action;
   use type EL.Remaining_RM_Edge_Recheck_Row;
   use type EL.Remaining_RM_Edge_Recheck_Model;
   use type EL.Remaining_RM_Edge_Recheck_Set;
   package AP renames Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
   use type AP.Remaining_RM_Edge_Application_Diagnostic_Status;
   use type AP.Remaining_RM_Edge_Application_Diagnostic_Family;
   use type AP.Remaining_RM_Edge_Application_Eligibility_Status;
   use type AP.Remaining_RM_Edge_Application_Eligibility_Action;
   use type AP.Remaining_RM_Edge_Kind;
   use type AP.Remaining_RM_Edge_Blocker_Family;
   use type AP.Remaining_RM_Edge_Application_Id;
   use type AP.Remaining_RM_Edge_Application_Status;
   use type AP.Remaining_RM_Edge_Application_Action;
   use type AP.Remaining_RM_Edge_Application_Row;
   use type AP.Remaining_RM_Edge_Application_Model;
   use type AP.Remaining_RM_Edge_Application_Set;
   package CV renames Editor.Ada_Remaining_RM_Edge_Recheck_Convergence_Legality;
   use type CV.Remaining_RM_Edge_Convergence_Application_Status;
   use type CV.Remaining_RM_Edge_Convergence_Application_Action;
   use type CV.Remaining_RM_Edge_Convergence_Family;
   use type CV.Remaining_RM_Edge_Kind;
   use type CV.Remaining_RM_Edge_Blocker_Family;
   use type CV.Remaining_RM_Edge_Convergence_Id;
   use type CV.Remaining_RM_Edge_Convergence_Status;
   use type CV.Remaining_RM_Edge_Convergence_Action;
   use type CV.Remaining_RM_Edge_Convergence_Row;
   use type CV.Remaining_RM_Edge_Convergence_Model;
   use type CV.Remaining_RM_Edge_Convergence_Set;

   function Build_Rechecks return EL.Remaining_RM_Edge_Recheck_Model is
   begin
      return EL.Build (Build_Worklist);
   end Build_Rechecks;

   function Build_Applications return AP.Remaining_RM_Edge_Application_Model is
   begin
      return AP.Build (Build_Rechecks);
   end Build_Applications;

   function Build_Convergence
     (Previous : Natural := 0) return CV.Remaining_RM_Edge_Convergence_Model is
   begin
      return CV.Build (Build_Applications, Previous);
   end Build_Convergence;


   package SG renames Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
   use type SG.Remaining_RM_Edge_Stabilization_Convergence_Status;
   use type SG.Remaining_RM_Edge_Stabilization_Convergence_Action;
   use type SG.Remaining_RM_Edge_Stabilization_Family;
   use type SG.Remaining_RM_Edge_Kind;
   use type SG.Remaining_RM_Edge_Blocker_Family;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Id;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Status;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Action;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Row;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Model;
   use type SG.Remaining_RM_Edge_Stabilization_Gate_Set;

   function Build_Gates
     (Previous : Natural := 0) return SG.Remaining_RM_Edge_Stabilization_Gate_Model is
      Convergence : constant CV.Remaining_RM_Edge_Convergence_Model := Build_Convergence (Previous);
   begin
      return SG.Build (Convergence);
   end Build_Gates;


   package SC renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Stabilization_Status;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Stabilization_Action;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Family;
   use type SC.Remaining_RM_Edge_Kind;
   use type SC.Remaining_RM_Edge_Blocker_Family;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Id;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Status;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Action;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Row;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Model;
   use type SC.Remaining_RM_Edge_Stabilized_Closure_Set;

   function Build_Stabilized_Closure
     (Previous : Natural := 0) return SC.Remaining_RM_Edge_Stabilized_Closure_Model is
      Gates : constant SG.Remaining_RM_Edge_Stabilization_Gate_Model := Build_Gates (Previous);
   begin
      return SC.Build (Gates);
   end Build_Stabilized_Closure;

   package CD renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Id;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Status;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Action;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Family;
   use type CD.Remaining_RM_Edge_Kind;
   use type CD.Remaining_RM_Edge_Blocker_Family;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
   use type CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;

   function Build_Closure_Diagnostics
     (Previous : Natural := 0) return CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model is
      Closure : constant SC.Remaining_RM_Edge_Stabilized_Closure_Model := Build_Stabilized_Closure (Previous);
   begin
      return CD.Build (Closure);
   end Build_Closure_Diagnostics;

   procedure Stabilized_Closure_Blockers_Emit_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Closure : constant SC.Remaining_RM_Edge_Stabilized_Closure_Model := Build_Stabilized_Closure;
      Diagnostics : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model := CD.Build (Closure);
   begin
      Assert (CD.Row_Count (Diagnostics) = SC.Row_Count (Closure),
              "closure diagnostic integration should preserve stabilized remaining-edge closure row count");
      Assert (CD.Withheld_Current_Count (Diagnostics) = SC.Accepted_Count (Closure),
              "accepted closure evidence should be withheld as current non-diagnostic evidence");
      Assert (CD.Emitted_Count (Diagnostics) = SC.Blocked_Count (Closure),
              "stable remaining-edge closure blockers should be emitted");
      Assert (CD.Fingerprint (Diagnostics) /= 0,
              "closure diagnostic integration should have deterministic fingerprint");
   end Stabilized_Closure_Blockers_Emit_Diagnostics;

   procedure Preserves_Remaining_Edge_And_Closure_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model := Build_Closure_Diagnostics;
   begin
      Assert (CD.Count_Status (Diagnostics, CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required) = 1,
              "accepted not-required closure evidence should not become a diagnostic");
      Assert (CD.Count_Status (Diagnostics, CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge_Blocker) = 1,
              "remaining-edge blockers should remain distinct diagnostics");
      Assert (CD.Count_Status (Diagnostics, CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure_Blocker) = 2,
              "stabilized direct-consumer closure blockers should remain distinct diagnostics");
      Assert (CD.Count_Status (Diagnostics, CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint blockers should remain explicit diagnostics");
   end Preserves_Remaining_Edge_And_Closure_Blocker_Families;

   procedure Recheck_Required_Rows_Are_Warnings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Apps : constant AP.Remaining_RM_Edge_Application_Model := Build_Applications;
      Prior_Fingerprint : constant Natural := AP.Stable_Fingerprint (Apps) + 1;
      Diagnostics : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model := Build_Closure_Diagnostics (Prior_Fingerprint);
   begin
      Assert (CD.Recheck_Required_Count (Diagnostics) = CD.Row_Count (Diagnostics),
              "changed remaining-edge evidence should produce recheck-required diagnostics");
      Assert (CD.Error_Count (Diagnostics) = 0,
              "recheck-required rows should not be reported as confident Ada errors");
   end Recheck_Required_Rows_Are_Warnings;

   procedure Feed_Consumes_Stabilized_Closure_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Diagnostics : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model := Build_Closure_Diagnostics;
      Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Remaining_RM_Edge_Stabilized_Closure_Diagnostics
          (Guarded, Diagnostics);
      Stale_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Remaining_RM_Edge_Stabilized_Closure_Diagnostics
          (Guarded, Diagnostics, False, 7);
   begin
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Feed) = CD.Emitted_Count (Diagnostics),
              "feed should expose only emitted stabilized closure diagnostics");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Current (Feed),
              "current stabilized closure diagnostics should keep feed current");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Stale_Feed),
              "stale stabilized closure diagnostics should reject feed");
      Assert (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Stale_Feed) = 7,
              "stale rejection count should be preserved");
   end Feed_Consumes_Stabilized_Closure_Diagnostics;

   procedure Query_Surface_Finds_Diagnostic_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model := Build_Closure_Diagnostics;
      Row : constant CD.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row := CD.Row_At (Diagnostics, 3);
   begin
      Assert (CD.Query_Count (CD.Query_Node (Diagnostics, Row.Node)) >= 1,
              "node query should find stabilized closure diagnostic rows");
      Assert (CD.Query_Count (CD.Query_Source_Fingerprint (Diagnostics, Row.Source_Fingerprint)) >= 1,
              "source fingerprint query should find stabilized closure diagnostic rows");
      Assert (Row.Blocks_Downstream,
              "emitted stabilized closure diagnostics should block downstream trust");
   end Query_Surface_Finds_Diagnostic_Rows;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Stabilized_Closure_Blockers_Emit_Diagnostics'Access,
         "stabilized closure blockers emit diagnostics");
      Register_Routine
        (T, Preserves_Remaining_Edge_And_Closure_Blocker_Families'Access,
         "preserves remaining-edge and closure blocker families");
      Register_Routine
        (T, Recheck_Required_Rows_Are_Warnings'Access,
         "recheck-required rows are warnings");
      Register_Routine
        (T, Feed_Consumes_Stabilized_Closure_Diagnostics'Access,
         "feed consumes stabilized closure diagnostics");
      Register_Routine
        (T, Query_Surface_Finds_Diagnostic_Rows'Access,
         "query surface finds diagnostic rows");
   end Register_Tests;

end Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration_Pass1292;
