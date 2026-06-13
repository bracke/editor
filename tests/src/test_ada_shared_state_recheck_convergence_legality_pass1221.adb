with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Recheck_Application_Legality;
with Editor.Ada_Shared_State_Recheck_Convergence_Legality;
with Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
with Editor.Ada_Shared_State_Remediation_Worklist_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Recheck_Convergence_Legality_Pass1221 is
   package CUS renames Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
   use type CUS.Cross_Unit_Shared_State_Row_Id;
   use type CUS.Cross_Unit_Shared_State_Context_Kind;
   use type CUS.Cross_Unit_Shared_State_Dependency_State;
   use type CUS.Cross_Unit_Shared_State_Status;
   use type CUS.Cross_Unit_Shared_State_Context_Info;
   use type CUS.Cross_Unit_Shared_State_Info;
   use type CUS.Cross_Unit_Shared_State_Context_Model;
   use type CUS.Cross_Unit_Shared_State_Model;
   use type CUS.Cross_Unit_Shared_State_Set;
   package CU renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   use type CU.Cross_Unit_Final_Row_Id;
   use type CU.Cross_Unit_Final_Context_Kind;
   use type CU.Cross_Unit_Dependency_State;
   use type CU.Cross_Unit_Final_Status;
   use type CU.Cross_Unit_Final_Context_Info;
   use type CU.Cross_Unit_Final_Info;
   use type CU.Cross_Unit_Final_Context_Model;
   use type CU.Cross_Unit_Final_Set;
   use type CU.Cross_Unit_Final_Model;
   package States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   use type States.Abstract_State_Row_Id;
   use type States.Abstract_State_Context_Kind;
   use type States.Abstract_State_Status;
   use type States.Abstract_State_Context_Info;
   use type States.Abstract_State_Info;
   use type States.Abstract_State_Context_Model;
   use type States.Abstract_State_Model;
   use type States.Abstract_State_Set;
   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   use type Shared.Shared_State_Row_Id;
   use type Shared.Shared_State_Context_Kind;
   use type Shared.Shared_State_Status;
   use type Shared.Shared_State_Context_Info;
   use type Shared.Shared_State_Info;
   use type Shared.Shared_State_Context_Model;
   use type Shared.Shared_State_Model;
   use type Shared.Shared_State_Set;
   package O renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   use type O.Overload_Shared_State_Row_Id;
   use type O.Overload_Shared_State_Context_Kind;
   use type O.Overload_Shared_State_Status;
   use type O.Overload_Shared_State_Context_Info;
   use type O.Overload_Shared_State_Info;
   use type O.Overload_Shared_State_Context_Model;
   use type O.Overload_Shared_State_Model;
   use type O.Overload_Shared_State_Set;
   package Rep renames Editor.Ada_Representation_Shared_State_Final_Legality;
   use type Rep.Representation_Shared_State_Row_Id;
   use type Rep.Representation_Shared_State_Context_Kind;
   use type Rep.Representation_Shared_State_Status;
   use type Rep.Representation_Shared_State_Context_Info;
   use type Rep.Representation_Shared_State_Info;
   use type Rep.Representation_Shared_State_Context_Model;
   use type Rep.Representation_Shared_State_Model;
   use type Rep.Representation_Shared_State_Set;
   package Tasking renames Editor.Ada_Tasking_Shared_State_Final_Legality;
   use type Tasking.Tasking_Shared_State_Row_Id;
   use type Tasking.Tasking_Shared_State_Context_Kind;
   use type Tasking.Tasking_Shared_State_Status;
   use type Tasking.Tasking_Shared_State_Context_Info;
   use type Tasking.Tasking_Shared_State_Info;
   use type Tasking.Tasking_Shared_State_Context_Model;
   use type Tasking.Tasking_Shared_State_Model;
   use type Tasking.Tasking_Shared_State_Set;
   package Stable renames Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
   use type Stable.Shared_State_Stabilized_Diagnostic_Id;
   use type Stable.Shared_State_Stabilized_Family;
   use type Stable.Shared_State_Stabilized_Severity;
   use type Stable.Shared_State_Stabilized_Status;
   use type Stable.Shared_State_Stabilized_Row;
   use type Stable.Shared_State_Stabilized_Set;
   use type Stable.Shared_State_Stabilized_Model;
   package WL renames Editor.Ada_Shared_State_Remediation_Worklist_Legality;
   use type WL.Shared_State_Worklist_Id;
   use type WL.Shared_State_Worklist_Family;
   use type WL.Shared_State_Worklist_Diagnostic_Status;
   use type WL.Shared_State_Worklist_Action;
   use type WL.Shared_State_Worklist_Priority;
   use type WL.Shared_State_Worklist_Item;
   use type WL.Shared_State_Worklist_Model;
   use type WL.Shared_State_Worklist_Set;
   package Recheck renames Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
   use type Recheck.Shared_State_Recheck_Family;
   use type Recheck.Shared_State_Recheck_Work_Action;
   use type Recheck.Shared_State_Recheck_Work_Priority;
   use type Recheck.Shared_State_Recheck_Id;
   use type Recheck.Shared_State_Recheck_Status;
   use type Recheck.Shared_State_Recheck_Action;
   use type Recheck.Shared_State_Recheck_Row;
   use type Recheck.Shared_State_Recheck_Model;
   use type Recheck.Shared_State_Recheck_Set;
   package Apply renames Editor.Ada_Shared_State_Recheck_Application_Legality;
   use type Apply.Shared_State_Recheck_Eligibility_Status;
   use type Apply.Shared_State_Recheck_Eligibility_Action;
   use type Apply.Shared_State_Recheck_Blocker_Family;
   use type Apply.Shared_State_Recheck_Application_Id;
   use type Apply.Shared_State_Recheck_Application_Status;
   use type Apply.Shared_State_Recheck_Application_Action;
   use type Apply.Shared_State_Recheck_Application_Row;
   use type Apply.Shared_State_Recheck_Application_Model;
   use type Apply.Shared_State_Recheck_Application_Set;
   package Conv renames Editor.Ada_Shared_State_Recheck_Convergence_Legality;
   use type Conv.Shared_State_Recheck_Application_Status;
   use type Conv.Shared_State_Recheck_Application_Action;
   use type Conv.Shared_State_Recheck_Blocker_Family;
   use type Conv.Shared_State_Recheck_Convergence_Id;
   use type Conv.Shared_State_Recheck_Convergence_Status;
   use type Conv.Shared_State_Recheck_Convergence_Action;
   use type Conv.Shared_State_Recheck_Convergence_Row;
   use type Conv.Shared_State_Recheck_Convergence_Model;
   use type Conv.Shared_State_Recheck_Convergence_Set;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada shared-state recheck convergence legality pass1221");
   end Name;

   function Complete_Context
     (Id   : CUS.Cross_Unit_Shared_State_Row_Id;
      Kind : CUS.Cross_Unit_Shared_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return CUS.Cross_Unit_Shared_State_Context_Info is
      C : CUS.Cross_Unit_Shared_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Dependency := CUS.Shared_Dependency_With_Visible;
      C.Node := Node;
      C.Unit_Name := To_Unbounded_String ("Conv_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Conv_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Conv_State" & Natural'Image (Natural (Id)));
      C.Cross_Unit_Row := CU.Cross_Unit_Final_Row_Id (Id);
      C.Cross_Unit_Status := CU.Cross_Unit_Final_With_Use_Accepted;
      C.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      C.Abstract_State_Status := States.Abstract_State_Legal_Cross_Unit_View_Accepted;
      C.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      C.Shared_State_Status := Shared.Shared_State_Legal_Abstract_State_Effect_Accepted;
      C.Overload_State_Row := O.Overload_Shared_State_Row_Id (Id);
      C.Overload_State_Status := O.Overload_Shared_State_Legal_Abstract_State_Effect_Accepted;
      C.Representation_State_Row := Rep.Representation_Shared_State_Row_Id (Id);
      C.Representation_State_Status := Rep.Representation_Shared_State_Legal_Abstract_State_View_Accepted;
      C.Tasking_State_Row := Tasking.Tasking_Shared_State_Row_Id (Id);
      C.Tasking_State_Status := Tasking.Tasking_Shared_State_Legal_Abstract_State_Access_Accepted;
      C.Source_Fingerprint := Natural (Id) * 1221;
      C.Expected_Source_Fingerprint := Natural (Id) * 1221;
      return C;
   end Complete_Context;

   function Application_From
     (Contexts : CUS.Cross_Unit_Shared_State_Context_Model)
      return Apply.Shared_State_Recheck_Application_Model is
      Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      Diags   : constant Stable.Shared_State_Stabilized_Model := Stable.Build (Closure);
      Work    : constant WL.Shared_State_Worklist_Model := WL.Build (Diags);
      Elig    : constant Recheck.Shared_State_Recheck_Model := Recheck.Build (Work);
   begin
      return Apply.Build (Elig);
   end Application_From;

   procedure Current_And_Not_Required_Rows_Converge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Current : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (122101));
   begin
      Current.Dependency := CUS.Shared_Dependency_Local;
      Current.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, Current);

      declare
         Apps  : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
         Model : constant Conv.Shared_State_Recheck_Convergence_Model := Conv.Build (Apps);
         Row   : constant Conv.Shared_State_Recheck_Convergence_Row := Conv.Row_At (Model, 1);
      begin
         Assert (Conv.Count (Model) = 1, "one convergence row expected");
         Assert (Conv.Converged_Count (Model) = 1, "current shared-state evidence should converge");
         Assert (Conv.Current_Count (Model) = 1, "current evidence should remain current after convergence");
         Assert (Conv.Changed_Count (Model) = 0, "unchanged current evidence should not recheck again");
         Assert (Row.Status = Conv.Shared_State_Recheck_Converged_Current,
                 "current application rows should converge as current");
         Assert (Row.Action = Conv.Shared_State_Recheck_Convergence_Action_Accept_Current,
                 "converged current rows should be accepted at the convergence boundary");
      end;
   end Current_And_Not_Required_Rows_Converge;

   procedure Stable_Blockers_Remain_Withheld_Without_Churn
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (122121));
      Shared_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (122122));
      Rep_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (122123));
   begin
      Abstract_Blocker.Abstract_Constituent_Blocker := True;
      Shared_Blocker.Volatile_Atomic_Order_Blocker := True;
      Rep_Blocker.Requires_Representation_State := True;
      Rep_Blocker.Representation_Effect_Blocker := True;
      CUS.Add_Context (Contexts, Abstract_Blocker);
      CUS.Add_Context (Contexts, Shared_Blocker);
      CUS.Add_Context (Contexts, Rep_Blocker);

      declare
         Apps  : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
         Model : constant Conv.Shared_State_Recheck_Convergence_Model := Conv.Build (Apps);
      begin
         Assert (Conv.Count (Model) = 3, "three convergence rows expected");
         Assert (Conv.Converged_Count (Model) = 0, "blocked shared-state evidence must not converge as current");
         Assert (Conv.Stable_Withheld_Count (Model) = 3, "stable blockers should be retained without churn");
         Assert (Conv.Changed_Count (Model) = 0, "stable blockers should not be reported as changed");
         Assert
           (Conv.Count_By_Status (Model, Conv.Shared_State_Recheck_Stable_Withheld_Abstract_State) = 1,
            "abstract/refined-state blocker should remain stable and withheld");
         Assert
           (Conv.Count_By_Status (Model, Conv.Shared_State_Recheck_Stable_Withheld_Volatile_Atomic) = 1,
            "volatile/atomic blocker should remain stable and withheld");
         Assert
           (Conv.Count_By_Status (Model, Conv.Shared_State_Recheck_Stable_Withheld_Representation_Freezing) = 1,
            "representation/freezing blocker should remain stable and withheld");
      end;
   end Stable_Blockers_Remain_Withheld_Without_Churn;

   procedure Changed_Fingerprint_Forces_Recheck
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      C : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (122141));
   begin
      C.Dependency := CUS.Shared_Dependency_Local;
      C.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, C);

      declare
         Apps  : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
         Model : constant Conv.Shared_State_Recheck_Convergence_Model :=
           Conv.Build (Apps, Apply.Stable_Fingerprint (Apps) + 1);
         Row   : constant Conv.Shared_State_Recheck_Convergence_Row := Conv.Row_At (Model, 1);
      begin
         Assert (Conv.Count (Model) = 1, "one changed convergence row expected");
         Assert (Conv.Changed_Count (Model) = 1, "changed application fingerprint should force another recheck");
         Assert (Conv.Converged_Count (Model) = 0, "changed evidence must not be treated as converged");
         Assert (Row.Status = Conv.Shared_State_Recheck_Changed_Since_Previous,
                 "fingerprint mismatch should be classified as changed since previous");
         Assert (Row.Action = Conv.Shared_State_Recheck_Convergence_Action_Recheck_Again,
                 "changed shared-state evidence should request another bounded recheck");
      end;
   end Changed_Fingerprint_Forces_Recheck;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122161);
      C : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Private_Full_View, Node);
   begin
      C.Private_View_Barrier := True;
      CUS.Add_Context (Contexts, C);

      declare
         Apps  : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
         Model : constant Conv.Shared_State_Recheck_Convergence_Model := Conv.Build (Apps);
         Row   : constant Conv.Shared_State_Recheck_Convergence_Row := Conv.Row_At (Model, 1);
      begin
         Assert (Conv.Query_Count (Conv.Find_By_Node (Model, Node)) = 1,
                 "node lookup should preserve shared-state convergence evidence");
         Assert (Conv.Query_Count (Conv.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source fingerprint lookup should preserve convergence evidence");
         Assert (Conv.Count_By_Blocker_Family (Model, Row.Blocker_Family) = 1,
                 "blocker-family lookup should preserve the original family");
         Assert (Conv.Stable_Fingerprint (Model) /= 0,
                 "convergence model should have deterministic non-zero fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Current_And_Not_Required_Rows_Converge'Access,
         "current shared-state application rows converge");
      Register_Routine
        (T, Stable_Blockers_Remain_Withheld_Without_Churn'Access,
         "stable shared-state blockers remain withheld without churn");
      Register_Routine
        (T, Changed_Fingerprint_Forces_Recheck'Access,
         "changed shared-state application fingerprint forces recheck");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family'Access,
         "query surface preserves node, fingerprint, and blocker family");
   end Register_Tests;

end Test_Ada_Shared_State_Recheck_Convergence_Legality_Pass1221;
