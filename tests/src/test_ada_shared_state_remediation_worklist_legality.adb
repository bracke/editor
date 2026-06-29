with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Remediation_Worklist_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Remediation_Worklist_Legality is

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

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada shared-state remediation worklist legality");
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
      C.Unit_Name := To_Unbounded_String ("Worklist_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Worklist_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Worklist_State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1218;
      C.Expected_Source_Fingerprint := Natural (Id) * 1218;
      return C;
   end Complete_Context;

   function Worklist_From
     (Contexts : CUS.Cross_Unit_Shared_State_Context_Model)
      return WL.Shared_State_Worklist_Model is
      Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      Diags   : constant Stable.Shared_State_Stabilized_Model := Stable.Build (Closure);
   begin
      return WL.Build (Diags);
   end Worklist_From;

   procedure Accepted_Evidence_Does_Not_Block_Recheck
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      A : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (121801));
   begin
      A.Dependency := CUS.Shared_Dependency_Local;
      A.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, A);

      declare
         Model : constant WL.Shared_State_Worklist_Model := Worklist_From (Contexts);
         Row   : constant WL.Shared_State_Worklist_Item := WL.Row_At (Model, 1);
      begin
         Assert (WL.Row_Count (Model) = 1, "one worklist item expected");
         Assert (WL.Current_Evidence_Count (Model) = 1, "accepted row should remain current evidence");
         Assert (WL.Ready_For_Recheck_Count (Model) = 0, "accepted evidence should not be rechecked");
         Assert (not WL.Blocks_Downstream (Row), "accepted evidence should not block downstream consumers");
         Assert
           (Row.Action = WL.Shared_State_Worklist_Keep_Current_Evidence,
            "accepted evidence should be kept, not repaired");
      end;
   end Accepted_Evidence_Does_Not_Block_Recheck;

   procedure Shared_State_Blockers_Produce_Ordered_Work
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121821));
      Shared_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (121822));
      Representation_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (121823));
      Tasking_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121824));
   begin
      Abstract_Blocker.Abstract_Constituent_Blocker := True;
      Shared_Blocker.Volatile_Atomic_Order_Blocker := True;
      Representation_Blocker.Representation_Effect_Blocker := True;
      Tasking_Blocker.Tasking_Effect_Blocker := True;
      CUS.Add_Context (Contexts, Abstract_Blocker);
      CUS.Add_Context (Contexts, Shared_Blocker);
      CUS.Add_Context (Contexts, Representation_Blocker);
      CUS.Add_Context (Contexts, Tasking_Blocker);

      declare
         Model : constant WL.Shared_State_Worklist_Model := Worklist_From (Contexts);
      begin
         Assert (WL.Row_Count (Model) = 4, "four blocker work items expected");
         Assert (WL.Ready_For_Recheck_Count (Model) = 4, "all blockers should be recheck work");
         Assert (WL.Blocked_Downstream_Count (Model) = 4, "all blockers should block downstream consumers");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Resolve_Abstract_State) = 1,
            "abstract-state remediation action should be preserved");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Resolve_Volatile_Atomic) = 1,
            "volatile/atomic remediation action should be preserved");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Resolve_Representation) = 1,
            "representation remediation action should be preserved");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Resolve_Tasking_Protected) = 1,
            "tasking remediation action should be preserved");
      end;
   end Shared_State_Blockers_Produce_Ordered_Work;

   procedure Dependency_View_Generic_And_Fingerprint_Actions_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Dep : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (121841));
      View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (121842));
      Gen : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Generic_Instance, Editor.Ada_Syntax_Tree.Node_Id (121843));
      Fingerprint : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121844));
   begin
      Dep.Dependency := CUS.Shared_Dependency_Missing;
      View.Private_View_Barrier := True;
      Gen.Generic_Backmapping_Blocker := True;
      Fingerprint.Expected_Source_Fingerprint := 1;
      CUS.Add_Context (Contexts, Dep);
      CUS.Add_Context (Contexts, View);
      CUS.Add_Context (Contexts, Gen);
      CUS.Add_Context (Contexts, Fingerprint);

      declare
         Model : constant WL.Shared_State_Worklist_Model := Worklist_From (Contexts);
      begin
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Close_Cross_Unit_Dependency) = 1,
            "dependency blocker should close cross-unit dependency first");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Resolve_View_Barrier) = 1,
            "view blocker should be a view remediation action");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Repair_Generic_Backmapping) = 1,
            "generic blocker should repair backmapping");
         Assert
           (WL.Count_Action (Model, WL.Shared_State_Worklist_Recheck_Source_Fingerprint) = 1,
            "fingerprint mismatch should refresh source evidence");
         Assert
           (WL.Query_Count (WL.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121844))) = 1,
            "query by source node should find fingerprint work item");
         Assert (WL.Fingerprint (Model) /= 0, "worklist fingerprint should be stable");
      end;
   end Dependency_View_Generic_And_Fingerprint_Actions_Are_Distinct;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Evidence_Does_Not_Block_Recheck'Access,
         "accepted shared-state evidence does not block recheck");
      Register_Routine
        (T, Shared_State_Blockers_Produce_Ordered_Work'Access,
         "shared-state blockers produce ordered semantic work");
      Register_Routine
        (T, Dependency_View_Generic_And_Fingerprint_Actions_Are_Distinct'Access,
         "dependency, view, generic, and fingerprint actions stay distinct");
   end Register_Tests;

end Test_Ada_Shared_State_Remediation_Worklist_Legality;
