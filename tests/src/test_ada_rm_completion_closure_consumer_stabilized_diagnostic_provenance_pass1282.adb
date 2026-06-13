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
with Editor.Ada_Syntax_Tree;

package body Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance_Pass1282 is

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
      return AUnit.Format ("Ada RM-completion closure consumer stabilized diagnostic provenance pass1282");
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
        Complete_Context (1, Prior.Predicate_RM_Completion_Assignment, Editor.Ada_Syntax_Tree.Node_Id (128201));
      Cross_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Predicate_RM_Completion_Cross_Unit_State, Editor.Ada_Syntax_Tree.Node_Id (128202));
      Elaboration_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Predicate_RM_Completion_Object_Initialization, Editor.Ada_Syntax_Tree.Node_Id (128203));
      Accessibility_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Predicate_RM_Completion_Access_Escape, Editor.Ada_Syntax_Tree.Node_Id (128204));
      Exception_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Predicate_RM_Completion_Controlled_Finalization, Editor.Ada_Syntax_Tree.Node_Id (128205));
      Multiple_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Predicate_RM_Completion_Dispatching_Call, Editor.Ada_Syntax_Tree.Node_Id (128206));
      Fingerprint_Blocker : P.Predicate_RM_Closure_Consumer_Context :=
        Complete_Context (7, Prior.Predicate_RM_Completion_Conversion, Editor.Ada_Syntax_Tree.Node_Id (128207));
   begin
      Cross_Blocker.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      Elaboration_Blocker.Elaboration_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Closure_Elaboration;
      Accessibility_Blocker.Accessibility_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Closure_Accessibility;
      Exception_Blocker.Exception_Finalization_Consumer_Status := Exception_Finalization.Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization;
      Multiple_Blocker.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Closure_Overload_Type;
      Multiple_Blocker.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Closure_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      P.Add_Context (Contexts, Accepted);
      P.Add_Context (Contexts, Cross_Blocker);
      P.Add_Context (Contexts, Elaboration_Blocker);
      P.Add_Context (Contexts, Accessibility_Blocker);
      P.Add_Context (Contexts, Exception_Blocker);
      P.Add_Context (Contexts, Multiple_Blocker);
      P.Add_Context (Contexts, Fingerprint_Blocker);
      return A.Build (R.Build (W.Build (Diag.Build (P.Build (Contexts)))));
   end Build_Application;

   function Build_Diagnostics return D.RM_Closure_Consumer_Stabilized_Diagnostic_Model is
      Apps : constant A.RM_Closure_Consumer_Application_Model := Build_Application;
      Conv : constant C.RM_Closure_Consumer_Convergence_Model := C.Build (Apps, 0);
      Gates : constant G.RM_Closure_Consumer_Stabilization_Gate_Model := G.Build (Conv);
      Stable : constant S.RM_Closure_Consumer_Stabilized_Closure_Model := S.Build (Gates);
   begin
      return D.Build (Stable);
   end Build_Diagnostics;

   procedure Provenance_Preserves_End_To_End_Chain
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model := Build_Diagnostics;
      Model : constant Prov.RM_Closure_Consumer_Stabilized_Provenance_Model := Prov.Build (Diagnostics);
   begin
      Assert (Prov.Row_Count (Model) = D.Row_Count (Diagnostics),
              "provenance should preserve stabilized diagnostic row count");
      Assert (Prov.Full_Chain_Link_Count (Model) = Prov.Row_Count (Model),
              "every provenance row should link stabilized diagnostic to original diagnostic chain");
      Assert (Prov.Count_Stage (Model, Prov.RM_Closure_Consumer_Stabilized_Stage_Stabilized_Diagnostic) = Prov.Row_Count (Model),
              "latest provenance stage should be stabilized diagnostic");
      Assert (Prov.Fingerprint (Model) /= 0,
              "provenance fingerprint should be deterministic");
   end Provenance_Preserves_End_To_End_Chain;

   procedure Provenance_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Prov.RM_Closure_Consumer_Stabilized_Provenance_Model := Prov.Build (Build_Diagnostics);
   begin
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_None) = 1,
              "accepted current evidence should have no blocker");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Cross_Unit) = 1,
              "cross-unit blocker should be traceable");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Elaboration) = 1,
              "elaboration blocker should be traceable");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Accessibility) = 1,
              "accessibility blocker should be traceable");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Exception_Finalization) = 1,
              "exception/finalization blocker should be traceable");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Multiple) = 1,
              "multiple prerequisite blockers should be traceable");
      Assert (Prov.Count_Blocker (Model, Prov.RM_Closure_Consumer_Stabilized_Blocker_Stale_Or_Fingerprint) = 1,
              "fingerprint blocker should be traceable");
   end Provenance_Preserves_Blocker_Families;

   procedure Provenance_Classifies_Withheld_Emitted_And_Query_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Diagnostics : constant D.RM_Closure_Consumer_Stabilized_Diagnostic_Model := Build_Diagnostics;
      Model : constant Prov.RM_Closure_Consumer_Stabilized_Provenance_Model := Prov.Build (Diagnostics);
      Row : constant Prov.RM_Closure_Consumer_Stabilized_Provenance_Row := Prov.Row_At (Model, 2);
   begin
      Assert (Prov.Withheld_Count (Model) = D.Withheld_Current_Count (Diagnostics),
              "withheld current evidence count should match diagnostics");
      Assert (Prov.Emitted_Count (Model) = D.Emitted_Count (Diagnostics),
              "emitted provenance count should match diagnostics");
      Assert (Prov.Error_Count (Model) >= 5,
              "semantic blockers should remain error provenance");
      Assert (Prov.Warning_Count (Model) = D.Warning_Count (Diagnostics),
              "fingerprint warnings should remain warning provenance");
      Assert (Prov.Query_Count (Prov.Query_Node (Model, Row.Node)) = 1,
              "node query should find provenance row");
      Assert (Prov.Query_Count (Prov.Query_Status (Model, Row.Status)) >= 1,
              "status query should find provenance row");
      Assert (Prov.Query_Count (Prov.Query_Blocker (Model, Row.Blocker)) >= 1,
              "blocker query should find provenance row");
   end Provenance_Classifies_Withheld_Emitted_And_Query_Rows;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Provenance_Preserves_End_To_End_Chain'Access,
         "provenance preserves end-to-end chain");
      Register_Routine
        (T, Provenance_Preserves_Blocker_Families'Access,
         "provenance preserves blocker families");
      Register_Routine
        (T, Provenance_Classifies_Withheld_Emitted_And_Query_Rows'Access,
         "provenance classifies withheld/emitted rows and supports queries");
   end Register_Tests;

end Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance_Pass1282;
