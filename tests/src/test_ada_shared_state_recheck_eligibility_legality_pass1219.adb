with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Remediation_Worklist_Legality;
with Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Recheck_Eligibility_Legality_Pass1219 is
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

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada shared-state recheck eligibility legality pass1219");
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
      C.Unit_Name := To_Unbounded_String ("Recheck_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Recheck_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Recheck_State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1219;
      C.Expected_Source_Fingerprint := Natural (Id) * 1219;
      return C;
   end Complete_Context;

   function Recheck_From
     (Contexts : CUS.Cross_Unit_Shared_State_Context_Model)
      return Recheck.Shared_State_Recheck_Model is
      Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      Diags   : constant Stable.Shared_State_Stabilized_Model := Stable.Build (Closure);
      Work    : constant WL.Shared_State_Worklist_Model := WL.Build (Diags);
   begin
      return Recheck.Build (Work);
   end Recheck_From;

   procedure Accepted_Current_Evidence_Is_Not_Rechecked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      A : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (121901));
   begin
      A.Dependency := CUS.Shared_Dependency_Local;
      A.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, A);

      declare
         Model : constant Recheck.Shared_State_Recheck_Model := Recheck_From (Contexts);
         Row   : constant Recheck.Shared_State_Recheck_Row := Recheck.Row_At (Model, 1);
      begin
         Assert (Recheck.Row_Count (Model) = 1, "one recheck row expected");
         Assert (Recheck.Current_Evidence_Count (Model) = 1, "accepted shared evidence remains current");
         Assert (Recheck.Eligible_Count (Model) = 0, "current evidence is not rechecked");
         Assert (Recheck.Blocked_Count (Model) = 0, "current evidence does not block downstream");
         Assert
           (Row.Status = Recheck.Shared_State_Recheck_Not_Required_Current,
            "accepted row should be not-required current evidence");
         Assert
           (Row.Action = Recheck.Shared_State_Recheck_Action_Keep_Current,
            "accepted row should keep current evidence");
      end;
   end Accepted_Current_Evidence_Is_Not_Rechecked;

   procedure Prerequisite_Blockers_Are_Preserved_As_Recheck_Blocks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121921));
      Shared_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (121922));
      Overload_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Overload_Type, Editor.Ada_Syntax_Tree.Node_Id (121923));
      Representation_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (121924));
      Tasking_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (5, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121925));
   begin
      Abstract_Blocker.Abstract_Constituent_Blocker := True;
      Shared_Blocker.Volatile_Atomic_Order_Blocker := True;
      Overload_Blocker.Requires_Overload_State := True;
      Overload_Blocker.Overload_State_Status := O.Overload_Shared_State_Volatile_Effect_Blocker;
      Representation_Blocker.Requires_Representation_State := True;
      Representation_Blocker.Representation_Effect_Blocker := True;
      Tasking_Blocker.Requires_Tasking_State := True;
      Tasking_Blocker.Tasking_Effect_Blocker := True;
      CUS.Add_Context (Contexts, Abstract_Blocker);
      CUS.Add_Context (Contexts, Shared_Blocker);
      CUS.Add_Context (Contexts, Overload_Blocker);
      CUS.Add_Context (Contexts, Representation_Blocker);
      CUS.Add_Context (Contexts, Tasking_Blocker);

      declare
         Model : constant Recheck.Shared_State_Recheck_Model := Recheck_From (Contexts);
      begin
         Assert (Recheck.Row_Count (Model) = 5, "five prerequisite rows expected");
         Assert (Recheck.Blocked_Count (Model) = 5, "all prerequisites should block recheck");
         Assert (Recheck.Abstract_State_Blocked_Count (Model) = 1, "abstract-state blocker should be preserved");
         Assert (Recheck.Volatile_Atomic_Blocked_Count (Model) = 1, "volatile/atomic blocker should be preserved");
         Assert (Recheck.Overload_Blocked_Count (Model) = 1, "overload/type blocker should be preserved");
         Assert (Recheck.Representation_Blocked_Count (Model) = 1, "representation blocker should be preserved");
         Assert (Recheck.Tasking_Blocked_Count (Model) = 1, "tasking blocker should be preserved");
      end;
   end Prerequisite_Blockers_Are_Preserved_As_Recheck_Blocks;

   procedure Dependency_View_Generic_State_And_Fingerprint_Remain_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Dep : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (121941));
      View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (121942));
      Gen : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Generic_Instance, Editor.Ada_Syntax_Tree.Node_Id (121943));
      State_Visibility : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121944));
      Fingerprint : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (5, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121945));
   begin
      Dep.Dependency := CUS.Shared_Dependency_Missing;
      View.Private_View_Barrier := True;
      Gen.Generic_Backmapping_Blocker := True;
      State_Visibility.State_Visibility_Blocker := True;
      Fingerprint.Expected_Source_Fingerprint := 1;
      CUS.Add_Context (Contexts, Dep);
      CUS.Add_Context (Contexts, View);
      CUS.Add_Context (Contexts, Gen);
      CUS.Add_Context (Contexts, State_Visibility);
      CUS.Add_Context (Contexts, Fingerprint);

      declare
         Model : constant Recheck.Shared_State_Recheck_Model := Recheck_From (Contexts);
      begin
         Assert (Recheck.Cross_Unit_Blocked_Count (Model) = 1, "dependency blocker should remain cross-unit");
         Assert (Recheck.View_Blocked_Count (Model) = 1, "view blocker should remain view-specific");
         Assert (Recheck.Generic_Blocked_Count (Model) = 1, "generic blocker should remain generic-specific");
         Assert (Recheck.State_Visibility_Blocked_Count (Model) = 1, "state visibility blocker should remain distinct");
         Assert (Recheck.Fingerprint_Blocked_Count (Model) = 1, "fingerprint mismatch should remain distinct");
         Assert
           (Recheck.Query_Count (Recheck.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121945))) = 1,
            "source-node query should find fingerprint blocker");
         Assert (Recheck.Fingerprint (Model) /= 0, "eligibility fingerprint should be stable");
      end;
   end Dependency_View_Generic_State_And_Fingerprint_Remain_Distinct;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Current_Evidence_Is_Not_Rechecked'Access,
         "accepted shared-state current evidence is not rechecked");
      Register_Routine
        (T, Prerequisite_Blockers_Are_Preserved_As_Recheck_Blocks'Access,
         "shared-state prerequisite blockers are preserved as recheck blockers");
      Register_Routine
        (T, Dependency_View_Generic_State_And_Fingerprint_Remain_Distinct'Access,
         "dependency, view, generic, state, and fingerprint blockers remain distinct");
   end Register_Tests;

end Test_Ada_Shared_State_Recheck_Eligibility_Legality_Pass1219;
