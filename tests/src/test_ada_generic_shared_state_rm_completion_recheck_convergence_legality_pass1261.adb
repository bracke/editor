with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality_Pass1261 is

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
   package C renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality;
   use type C.RM_Completion_Application_Status;
   use type C.RM_Completion_Application_Action;
   use type C.RM_Completion_Convergence_Family;
   use type C.RM_Completion_Convergence_Id;
   use type C.RM_Completion_Convergence_Status;
   use type C.RM_Completion_Convergence_Action;
   use type C.RM_Completion_Convergence_Row;
   use type C.RM_Completion_Convergence_Model;
   use type C.RM_Completion_Convergence_Set;
   package Prior renames D.Prior_Dataflow;
   package Cross_RM renames D.Cross_RM;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state RM completion recheck convergence pass1261");
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
      Result.Source_Fingerprint := 1261 * Id;
      Result.Expected_Source_Fingerprint := 1261 * Id;
      Result.Substitution_Fingerprint := 6211 * Id;
      Result.Expected_Substitution_Fingerprint := 6211 * Id;
      return Result;
   end Complete_Context;

   function Build_Application return A.RM_Completion_Application_Model is
      Contexts : D.Dataflow_RM_Completion_Context_Model;
      Accepted : D.Dataflow_RM_Completion_Context :=
        Complete_Context (1, D.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (126101));
      Cross_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (2, D.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (126102));
      Representation_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (3, D.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (126103));
      Dataflow_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (4, D.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (126104));
      Fingerprint_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (5, D.Dataflow_RM_Completion_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (126105));
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

   function Build_Convergence
     (Previous : Natural := 0) return C.RM_Completion_Convergence_Model is
      Apps : constant A.RM_Completion_Application_Model := Build_Application;
   begin
      return C.Build (Apps, Previous);
   end Build_Convergence;

   procedure Application_Rows_Converge_Or_Remain_Stable_Withheld
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Completion_Convergence_Model := Build_Convergence;
      Row   : constant C.RM_Completion_Convergence_Row := C.Row_At (Model, 1);
   begin
      Assert (C.Count (Model) = 5, "five RM-completion convergence rows expected");
      Assert (C.Converged_Count (Model) = 1, "current non-diagnostic evidence should converge as not required");
      Assert (C.Stable_Withheld_Count (Model) = 4, "blocked rows should remain stably withheld");
      Assert (C.Current_Count (Model) = 0, "fixture exposes no newly accepted current row");
      Assert (C.Changed_Count (Model) = 0, "fresh convergence should not be marked changed");
      Assert (Row.Status = C.RM_Completion_Converged_Not_Required,
              "accepted diagnostic-free RM-completion evidence should converge as not required");
      Assert (Row.Action = C.RM_Completion_Convergence_Action_Skip_Not_Required,
              "converged non-diagnostic evidence should skip fresh recheck work");
   end Application_Rows_Converge_Or_Remain_Stable_Withheld;

   procedure Convergence_Preserves_RM_Completion_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Completion_Convergence_Model := Build_Convergence;
   begin
      Assert (C.Count_By_Status (Model, C.RM_Completion_Stable_Withheld_Cross_Unit) = 1,
              "cross-unit RM blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Completion_Stable_Withheld_Representation) = 1,
              "representation blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Completion_Stable_Withheld_Dataflow) = 1,
              "dataflow blocker should remain distinct through convergence");
      Assert (C.Count_By_Status (Model, C.RM_Completion_Stable_Withheld_Stale_Or_Fingerprint) = 1,
              "fingerprint blocker should remain distinct through convergence");
   end Convergence_Preserves_RM_Completion_Blocker_Families;

   procedure Convergence_Detects_Changed_Application_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Apps    : constant A.RM_Completion_Application_Model := Build_Application;
      Current : constant Natural := A.Stable_Fingerprint (Apps);
      Model   : constant C.RM_Completion_Convergence_Model := C.Build (Apps, Current + 1);
   begin
      Assert (C.Count (Model) = 5, "changed convergence still mirrors application rows");
      Assert (C.Changed_Count (Model) = 5, "all rows should force recheck when the model fingerprint changes");
      Assert (C.Count_By_Status (Model, C.RM_Completion_Changed_Since_Previous) = 5,
              "changed fingerprint should classify every row as changed since previous");
      Assert (C.Row_At (Model, 1).Action = C.RM_Completion_Convergence_Action_Recheck_Again,
              "changed rows should request another recheck");
   end Convergence_Detects_Changed_Application_Fingerprint;

   procedure Convergence_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant C.RM_Completion_Convergence_Model := Build_Convergence;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126105);
   begin
      Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the fingerprint blocker convergence row");
      Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, 1261 * 5)) = 1,
              "source fingerprint lookup should find the fingerprint blocker convergence row");
      Assert (C.Query_Count (C.Find_By_Substitution_Fingerprint (Model, 6211 * 5)) = 1,
              "substitution fingerprint lookup should find the fingerprint blocker convergence row");
      Assert (C.Count_By_Family (Model, Diag.RM_Completion_Diagnostic_Source_Fingerprint) = 1,
              "family query should preserve fingerprint blocker identity");
      Assert (C.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate convergence rows");
      Assert (C.Stable_Fingerprint (Model) /= 0, "convergence stable fingerprint should be non-zero");
   end Convergence_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Application_Rows_Converge_Or_Remain_Stable_Withheld'Access,
         "RM-completion application rows converge or remain stably withheld");
      Register_Routine
        (T, Convergence_Preserves_RM_Completion_Blocker_Families'Access,
         "RM-completion convergence preserves blocker families");
      Register_Routine
        (T, Convergence_Detects_Changed_Application_Fingerprint'Access,
         "RM-completion convergence detects changed fingerprints");
      Register_Routine
        (T, Convergence_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "RM-completion convergence lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality_Pass1261;
