with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Recheck_Application_Legality;
with Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
with Editor.Ada_Shared_State_Remediation_Worklist_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Recheck_Application_Legality is
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

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada shared-state recheck application legality");
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
      C.Unit_Name := To_Unbounded_String ("Apply_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Apply_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Apply_State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1220;
      C.Expected_Source_Fingerprint := Natural (Id) * 1220;
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

   procedure Current_Evidence_Is_Applied_As_Non_Diagnostic_Current
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      A : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (122001));
   begin
      A.Dependency := CUS.Shared_Dependency_Local;
      A.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      CUS.Add_Context (Contexts, A);

      declare
         Model : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
         Row   : constant Apply.Shared_State_Recheck_Application_Row := Apply.Row_At (Model, 1);
      begin
         Assert (Apply.Count (Model) = 1, "one application row expected");
         Assert (Apply.Current_Count (Model) = 1, "current evidence should remain current");
         Assert (Apply.Accepted_Count (Model) = 0, "current non-diagnostic evidence is not a fresh accepted recheck");
         Assert (Apply.Withheld_Count (Model) = 0, "current evidence should not be withheld");
         Assert
           (Row.Status = Apply.Shared_State_Recheck_Application_Current_Non_Diagnostic_Evidence,
            "accepted stabilized evidence should be kept as current non-diagnostic evidence");
         Assert
           (Row.Action = Apply.Shared_State_Recheck_Application_Action_Keep_Non_Diagnostic_Evidence,
            "application should keep the shared-state evidence without emitting a diagnostic");
      end;
   end Current_Evidence_Is_Applied_As_Non_Diagnostic_Current;

   procedure Shared_State_Prerequisites_Withhold_Downstream_Currentness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (122021));
      Shared_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (122022));
      Overload_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Overload_Type, Editor.Ada_Syntax_Tree.Node_Id (122023));
      Representation_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (122024));
      Tasking_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (5, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (122025));
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
         Model : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
      begin
         Assert (Apply.Count (Model) = 5, "five application rows expected");
         Assert (Apply.Current_Count (Model) = 0, "blocked prerequisites must not become current");
         Assert (Apply.Withheld_Count (Model) = 5, "all shared-state blockers should withhold downstream currentness");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Abstract_State) = 1,
            "abstract/refined-state blocker should withhold application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Volatile_Atomic) = 1,
            "volatile/atomic/shared-variable blocker should withhold application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Overload_Shared_State) = 1,
            "overload shared-state blocker should withhold application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Representation_Freezing) = 1,
            "representation/freezing blocker should withhold application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Tasking_Protected) = 1,
            "tasking/protected blocker should withhold application");
      end;
   end Shared_State_Prerequisites_Withhold_Downstream_Currentness;

   procedure Dependency_View_Generic_State_And_Fingerprint_Are_Findable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Dep : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (122041));
      View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (122042));
      Gen : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Generic_Instance, Editor.Ada_Syntax_Tree.Node_Id (122043));
      State_Visibility : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (122044));
      Fingerprint : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (5, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (122045));
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
         Model : constant Apply.Shared_State_Recheck_Application_Model := Application_From (Contexts);
      begin
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Cross_Unit_Dependency) = 1,
            "dependency blocker should remain cross-unit at application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_View_Barrier) = 2,
            "view barriers should remain distinct at application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Generic_Backmapping) = 1,
            "generic backmapping should remain distinct at application");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_State_Visibility) = 0,
            "state visibility is covered by view-specific application blockers here");
         Assert
           (Apply.Count_By_Status (Model, Apply.Shared_State_Recheck_Application_Withheld_Source_Fingerprint) = 1,
            "source fingerprint mismatch should remain distinct at application");
         Assert
           (Apply.Query_Count (Apply.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (122045))) = 1,
            "node lookup should find the fingerprint row");
         Assert
           (Apply.Query_Count (Apply.Find_By_Source_Fingerprint (Model, Fingerprint.Source_Fingerprint)) = 1,
            "source fingerprint lookup should find the fingerprint row");
         Assert (Apply.Stable_Fingerprint (Model) /= 0, "application fingerprint should be stable");
      end;
   end Dependency_View_Generic_State_And_Fingerprint_Are_Findable;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Current_Evidence_Is_Applied_As_Non_Diagnostic_Current'Access,
         "current shared-state evidence is applied as non-diagnostic current evidence");
      Register_Routine
        (T, Shared_State_Prerequisites_Withhold_Downstream_Currentness'Access,
         "shared-state prerequisite blockers withhold downstream currentness");
      Register_Routine
        (T, Dependency_View_Generic_State_And_Fingerprint_Are_Findable'Access,
         "dependency, view, generic, state visibility, and fingerprint blockers are findable");
   end Register_Tests;

end Test_Ada_Shared_State_Recheck_Application_Legality;
