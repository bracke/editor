with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality is

   package D renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
   use type D.Dataflow_RM_Completion_Row_Id;
   use type D.Dataflow_RM_Completion_Kind;
   use type D.Dataflow_RM_Completion_Blocker_Family;
   use type D.Dataflow_RM_Completion_Status;
   use type D.Dataflow_RM_Completion_Context;
   use type D.Dataflow_RM_Completion_Row;
   use type D.Dataflow_RM_Completion_Context_Model;
   use type D.Dataflow_RM_Completion_Model;
   use type D.Query_Result;
   package Diag renames Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
   use type Diag.RM_Completion_Diagnostic_Id;
   use type Diag.RM_Completion_Diagnostic_Family;
   use type Diag.RM_Completion_Diagnostic_Severity;
   use type Diag.RM_Completion_Diagnostic_Status;
   use type Diag.RM_Completion_Diagnostic_Row;
   use type Diag.RM_Completion_Diagnostic_Set;
   use type Diag.RM_Completion_Diagnostic_Model;
   package W renames Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
   use type W.RM_Completion_Worklist_Id;
   use type W.RM_Completion_Worklist_Family;
   use type W.RM_Completion_Worklist_Diagnostic_Status;
   use type W.RM_Completion_Worklist_Action;
   use type W.RM_Completion_Worklist_Priority;
   use type W.RM_Completion_Worklist_Item;
   use type W.RM_Completion_Worklist_Model;
   use type W.RM_Completion_Worklist_Set;
   package R renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
   use type R.RM_Completion_Recheck_Family;
   use type R.RM_Completion_Recheck_Work_Action;
   use type R.RM_Completion_Recheck_Work_Priority;
   use type R.RM_Completion_Recheck_Id;
   use type R.RM_Completion_Recheck_Status;
   use type R.RM_Completion_Recheck_Action;
   use type R.RM_Completion_Recheck_Row;
   use type R.RM_Completion_Recheck_Model;
   use type R.RM_Completion_Recheck_Set;
   package A renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
   use type A.RM_Completion_Application_Family;
   use type A.RM_Completion_Eligibility_Status;
   use type A.RM_Completion_Eligibility_Action;
   use type A.RM_Completion_Application_Id;
   use type A.RM_Completion_Application_Status;
   use type A.RM_Completion_Application_Action;
   use type A.RM_Completion_Application_Row;
   use type A.RM_Completion_Application_Model;
   use type A.RM_Completion_Application_Set;
   package Prior renames D.Prior_Dataflow;
   package Cross_RM renames D.Cross_RM;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state RM completion recheck application");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : D.Dataflow_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return D.Dataflow_RM_Completion_Context is
      Result : D.Dataflow_RM_Completion_Context;
   begin
      Result.Id := D.Dataflow_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Prior_Dataflow_Row := Prior.Dataflow_Generic_Final_Row_Id (Id);
      Result.Prior_Dataflow_Status := Prior.Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Source_Fingerprint := 1260 * Id;
      Result.Expected_Source_Fingerprint := 1260 * Id;
      Result.Substitution_Fingerprint := 6210 * Id;
      Result.Expected_Substitution_Fingerprint := 6210 * Id;
      return Result;
   end Complete_Context;

   function Build_Application return A.RM_Completion_Application_Model is
      Contexts : D.Dataflow_RM_Completion_Context_Model;
      Accepted : D.Dataflow_RM_Completion_Context :=
        Complete_Context (1, D.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (126001));
      Cross_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (2, D.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (126002));
      Representation_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (3, D.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (126003));
      Dataflow_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (4, D.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (126004));
      Fingerprint_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (5, D.Dataflow_RM_Completion_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (126005));
   begin
      Cross_Blocker.Cross_RM_Row := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Representation_Blocker.Requires_Representation_RM := True;
      Dataflow_Blocker.Read_Before_Write_Blocker := True;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Cross_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Dataflow_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      return A.Build (R.Build (W.Build (Diag.Build (D.Build (Contexts)))));
   end Build_Application;

   procedure Eligibility_Is_Applied_To_Current_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.RM_Completion_Application_Model := Build_Application;
   begin
      Assert (A.Row_Count (Model) = 5,
              "five RM-completion application rows expected");
      Assert (A.Current_Count (Model) = 1,
              "current RM-completion evidence should remain current");
      Assert (A.Accepted_Count (Model) = 0,
              "blocked prerequisites should prevent accepted current exposure");
      Assert (A.Withheld_Count (Model) = 4,
              "four prerequisite blockers should be withheld");
   end Eligibility_Is_Applied_To_Current_Boundary;

   procedure Blocker_Families_Are_Withheld_Without_Flattening
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.RM_Completion_Application_Model := Build_Application;
   begin
      Assert (A.Count_By_Status (Model, A.RM_Completion_Application_Current_Non_Diagnostic_Evidence) = 1,
              "accepted evidence should remain non-diagnostic current evidence");
      Assert (A.Count_By_Status (Model, A.RM_Completion_Application_Withheld_Cross_Unit) = 1,
              "cross-unit blocker should remain cross-unit");
      Assert (A.Count_By_Status (Model, A.RM_Completion_Application_Withheld_Representation) = 1,
              "representation blocker should remain representation/freezing");
      Assert (A.Count_By_Status (Model, A.RM_Completion_Application_Withheld_Dataflow) = 1,
              "dataflow blocker should remain dataflow");
      Assert (A.Count_By_Status (Model, A.RM_Completion_Application_Withheld_Stale_Or_Fingerprint) = 1,
              "fingerprint blocker should remain stale/fingerprint");
   end Blocker_Families_Are_Withheld_Without_Flattening;

   procedure Actions_Preserve_Application_Boundary_Decisions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.RM_Completion_Application_Model := Build_Application;
   begin
      Assert (A.Query_Count (A.Query_Action (Model, A.RM_Completion_Application_Action_Keep_Non_Diagnostic_Evidence)) = 1,
              "current evidence should be kept as non-diagnostic evidence");
      Assert (A.Query_Count (A.Query_Action (Model, A.RM_Completion_Application_Action_Withhold_For_Cross_Unit)) = 1,
              "cross-unit blocker should withhold for cross-unit closure");
      Assert (A.Query_Count (A.Query_Action (Model, A.RM_Completion_Application_Action_Withhold_For_Representation)) = 1,
              "representation blocker should withhold for representation evidence");
      Assert (A.Query_Count (A.Query_Action (Model, A.RM_Completion_Application_Action_Withhold_For_Dataflow)) = 1,
              "dataflow blocker should withhold for dataflow evidence");
      Assert (A.Query_Count (A.Query_Action (Model, A.RM_Completion_Application_Action_Withhold_For_Fingerprint)) = 1,
              "fingerprint blocker should withhold for refreshed fingerprints");
   end Actions_Preserve_Application_Boundary_Decisions;

   procedure Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant A.RM_Completion_Application_Model := Build_Application;
      Row : constant A.RM_Completion_Application_Row := A.Row_At (Model, 2);
   begin
      Assert (A.Query_Count (A.Find_By_Node (Model, Row.Node)) = 1,
              "node lookup should recover the application row");
      Assert (A.Query_Count (A.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
              "source fingerprint lookup should recover the application row");
      Assert (A.Query_Count (A.Find_By_Substitution_Fingerprint (Model, Row.Substitution_Fingerprint)) = 1,
              "substitution fingerprint lookup should recover the application row");
      Assert (A.Count_By_Family (Model, Diag.RM_Completion_Diagnostic_Cross_Unit_RM_Completion) = 1,
              "family lookup should preserve cross-unit RM-completion identity");
      Assert (A.Stable_Fingerprint (Model) /= 0,
              "application model fingerprint should be non-zero");
   end Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Eligibility_Is_Applied_To_Current_Boundary'Access,
         "eligibility is applied to current RM-completion boundary");
      Register_Routine
        (T, Blocker_Families_Are_Withheld_Without_Flattening'Access,
         "blocker families are withheld without flattening");
      Register_Routine
        (T, Actions_Preserve_Application_Boundary_Decisions'Access,
         "actions preserve application boundary decisions");
      Register_Routine
        (T, Lookups_And_Fingerprints_Are_Deterministic'Access,
         "lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
