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
with Editor.Ada_Shared_State_Stabilization_Gate_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Stabilized_Closure_Legality is
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
   package Gate renames Editor.Ada_Shared_State_Stabilization_Gate_Legality;
   use type Gate.Shared_State_Recheck_Convergence_Status;
   use type Gate.Shared_State_Recheck_Convergence_Action;
   use type Gate.Shared_State_Recheck_Blocker_Family;
   use type Gate.Shared_State_Stabilization_Gate_Id;
   use type Gate.Shared_State_Stabilization_Gate_Status;
   use type Gate.Shared_State_Stabilization_Gate_Action;
   use type Gate.Shared_State_Stabilization_Gate_Row;
   use type Gate.Shared_State_Stabilization_Gate_Model;
   use type Gate.Shared_State_Stabilization_Gate_Set;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   use type Closure.Shared_State_Recheck_Blocker_Family;
   use type Closure.Shared_State_Stabilization_Gate_Status;
   use type Closure.Shared_State_Stabilization_Gate_Action;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Closure.Shared_State_Stabilized_Closure_Action;
   use type Closure.Shared_State_Stabilized_Closure_Row;
   use type Closure.Shared_State_Stabilized_Closure_Model;
   use type Closure.Shared_State_Stabilized_Closure_Set;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada shared-state stabilized closure legality");
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
      C.Unit_Name := To_Unbounded_String ("Gate_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Gate_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Gate_State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1223;
      C.Expected_Source_Fingerprint := Natural (Id) * 1223;
      return C;
   end Complete_Context;

   function Convergence_From
     (Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Previous : Natural := 0) return Conv.Shared_State_Recheck_Convergence_Model is
      Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      Diags   : constant Stable.Shared_State_Stabilized_Model := Stable.Build (Closure);
      Work    : constant WL.Shared_State_Worklist_Model := WL.Build (Diags);
      Elig    : constant Recheck.Shared_State_Recheck_Model := Recheck.Build (Work);
      Apps    : constant Apply.Shared_State_Recheck_Application_Model := Apply.Build (Elig);
   begin
      return Conv.Build (Apps, Previous);
   end Convergence_From;

   procedure Stable_Current_Rows_Are_Promoted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Current : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (122201));
   begin
      Current.Dependency := CUS.Shared_Dependency_Local;
      Current.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, Current);

      declare
         Conv_Model : constant Conv.Shared_State_Recheck_Convergence_Model := Convergence_From (Contexts);
         Model      : constant Closure.Shared_State_Stabilized_Closure_Model := Closure.Build (Gate.Build (Conv_Model));
         Row        : constant Closure.Shared_State_Stabilized_Closure_Row := Closure.Row_At (Model, 1);
      begin
         Assert (Closure.Count (Model) = 1, "one stabilized-closure row expected");
         Assert (Closure.Accepted_Count (Model) = 1, "stable current evidence should be promoted");
         Assert (Closure.Current_Count (Model) = 1, "promoted current row should remain current");
         Assert (Closure.Blocked_Count (Model) = 0, "promoted current row should not be withheld");
         Assert (Row.Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current,
                 "current convergence rows should cross the stabilized closure");
         Assert (Row.Action = Closure.Shared_State_Stabilized_Closure_Action_Accept,
                 "current stabilization rows should promote current evidence");
      end;
   end Stable_Current_Rows_Are_Promoted;

   procedure Stable_Blockers_Remain_Withheld
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (122221));
      Task_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (122222));
      View_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (122223));
   begin
      Abstract_Blocker.Abstract_Constituent_Blocker := True;
      Task_Blocker.Requires_Tasking_State := True;
      Task_Blocker.Tasking_Effect_Blocker := True;
      View_Blocker.Private_View_Barrier := True;
      CUS.Add_Context (Contexts, Abstract_Blocker);
      CUS.Add_Context (Contexts, Task_Blocker);
      CUS.Add_Context (Contexts, View_Blocker);

      declare
         Model : constant Closure.Shared_State_Stabilized_Closure_Model := Closure.Build (Gate.Build (Convergence_From (Contexts)));
      begin
         Assert (Closure.Count (Model) = 3, "three stabilized-closure rows expected");
         Assert (Closure.Accepted_Count (Model) = 0, "blocked evidence must not be promoted");
         Assert (Closure.Blocked_Count (Model) = 3, "stable blockers should remain withheld");
         Assert (Closure.Recheck_Required_Count (Model) = 0, "stable blockers should not request recheck");
         Assert
           (Closure.Count_By_Status (Model, Closure.Shared_State_Stabilized_Closure_Blocker_Abstract_State) = 1,
            "abstract/refined-state blocker should remain explicit at stabilized closure");
         Assert
           (Closure.Count_By_Status (Model, Closure.Shared_State_Stabilized_Closure_Blocker_Tasking_Protected) = 1,
            "tasking/protected blocker should remain explicit at stabilized closure");
         Assert
           (Closure.Count_By_Status (Model, Closure.Shared_State_Stabilized_Closure_Blocker_View_Barrier) = 1,
            "view-barrier blocker should remain explicit at stabilized closure");
      end;
   end Stable_Blockers_Remain_Withheld;

   procedure Changed_Convergence_Forces_Recheck
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      C : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (122241));
   begin
      C.Dependency := CUS.Shared_Dependency_Local;
      C.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, C);

      declare
         Changed : constant Conv.Shared_State_Recheck_Convergence_Model := Convergence_From (Contexts, 42);
         Model   : constant Closure.Shared_State_Stabilized_Closure_Model := Closure.Build (Gate.Build (Changed));
         Row     : constant Closure.Shared_State_Stabilized_Closure_Row := Closure.Row_At (Model, 1);
      begin
         Assert (Closure.Count (Model) = 1, "one changed stabilized-closure row expected");
         Assert (Closure.Accepted_Count (Model) = 0, "changed evidence must not be promoted");
         Assert (Closure.Recheck_Required_Count (Model) = 1, "changed convergence evidence should force recheck");
         Assert (Row.Status = Closure.Shared_State_Stabilized_Closure_Recheck_Required,
                 "changed convergence rows should be held for another bounded recheck");
         Assert (Row.Action = Closure.Shared_State_Stabilized_Closure_Action_Recheck,
                 "changed stabilization rows should request recheck");
      end;
   end Changed_Convergence_Forces_Recheck;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122261);
      C : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Representation, Node);
   begin
      C.Requires_Representation_State := True;
      C.Representation_Effect_Blocker := True;
      CUS.Add_Context (Contexts, C);

      declare
         Model : constant Closure.Shared_State_Stabilized_Closure_Model := Closure.Build (Gate.Build (Convergence_From (Contexts)));
         Row   : constant Closure.Shared_State_Stabilized_Closure_Row := Closure.Row_At (Model, 1);
      begin
         Assert (Closure.Query_Count (Closure.Find_By_Node (Model, Node)) = 1,
                 "node lookup should preserve shared-state stabilization evidence");
         Assert (Closure.Query_Count (Closure.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source fingerprint lookup should preserve stabilization evidence");
         Assert (Closure.Count_By_Blocker_Family (Model, Row.Blocker_Family) = 1,
                 "blocker-family lookup should preserve the original family");
         Assert (Closure.Stable_Fingerprint (Model) /= 0,
                 "stabilized-closure model should have deterministic non-zero fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Stable_Current_Rows_Are_Promoted'Access,
         "stable current shared-state rows are promoted");
      Register_Routine
        (T, Stable_Blockers_Remain_Withheld'Access,
         "stable shared-state blockers remain withheld at stabilized closure");
      Register_Routine
        (T, Changed_Convergence_Forces_Recheck'Access,
         "changed convergence evidence forces another recheck");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Blocker_Family'Access,
         "query surface preserves node, fingerprint, and blocker family");
   end Register_Tests;

end Test_Ada_Shared_State_Stabilized_Closure_Legality;
