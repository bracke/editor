with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Shared_State_Stabilized_Diagnostic_Integration_Pass1217 is

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
   package DI renames Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
   use type DI.Shared_State_Stabilized_Diagnostic_Id;
   use type DI.Shared_State_Stabilized_Family;
   use type DI.Shared_State_Stabilized_Severity;
   use type DI.Shared_State_Stabilized_Status;
   use type DI.Shared_State_Stabilized_Row;
   use type DI.Shared_State_Stabilized_Set;
   use type DI.Shared_State_Stabilized_Model;
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
      return AUnit.Format ("Ada shared-state stabilized diagnostic integration pass1217");
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
      C.Unit_Name := To_Unbounded_String ("Shared_State_Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Shared_State_Dep" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("Shared_State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1217;
      C.Expected_Source_Fingerprint := Natural (Id) * 1217;
      return C;
   end Complete_Context;

   procedure Accepted_Rows_Are_Withheld_As_Current_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      A : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (121701));
      B : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121702));
   begin
      A.Dependency := CUS.Shared_Dependency_Local;
      A.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      B.Requires_Overload_State := True;
      B.Requires_Representation_State := True;
      B.Requires_Tasking_State := True;
      CUS.Add_Context (Contexts, A);
      CUS.Add_Context (Contexts, B);

      declare
         Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
         Model : constant DI.Shared_State_Stabilized_Model := DI.Build (Closure);
      begin
         Assert (DI.Row_Count (Model) = 2, "two stabilized rows expected");
         Assert (DI.Withheld_Current_Count (Model) = 2, "accepted rows should be withheld as current evidence");
         Assert (DI.Emitted_Count (Model) = 0, "accepted rows should not emit diagnostics");
         Assert (DI.Info_Count (Model) = 2, "accepted evidence is informational");
         Assert (DI.Fingerprint (Model) /= 0, "stabilized model fingerprint should be stable");
         Assert
           (DI.Row_At (Model, 1).Status = DI.Shared_State_Stabilized_Withheld_Accepted_Current,
            "first accepted row should be withheld");
      end;
   end Accepted_Rows_Are_Withheld_As_Current_Evidence;

   procedure Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Abstract_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121721));
      Shared_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (121722));
      Representation_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (121723));
      Tasking_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121724));
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
         Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
         Model : constant DI.Shared_State_Stabilized_Model := DI.Build (Closure);
      begin
         Assert (DI.Emitted_Count (Model) = 4, "all blockers should emit stabilized diagnostics");
         Assert (DI.Error_Count (Model) = 4, "hard shared-state blockers should be errors");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Abstract_State) = 1,
            "abstract-state family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Volatile_Atomic) = 1,
            "volatile/atomic family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Representation) = 1,
            "representation family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Tasking_Protected) = 1,
            "tasking family should be preserved");
      end;
   end Blocker_Families_Are_Preserved;

   procedure Dependency_View_Generic_And_Fingerprint_Blockers_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Dep : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (121741));
      View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (121742));
      Gen : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Generic_Instance, Editor.Ada_Syntax_Tree.Node_Id (121743));
      Fingerprint : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121744));
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
         Closure : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
         Model : constant DI.Shared_State_Stabilized_Model := DI.Build (Closure);
      begin
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Dependency) = 1,
            "dependency family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_View_Barrier) = 1,
            "view family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Generic_Backmapping) = 1,
            "generic backmapping family should be preserved");
         Assert
           (DI.Count_Family (Model, DI.Shared_State_Stabilized_Diagnostic_Fingerprint) = 1,
            "fingerprint family should be preserved");
         Assert
           (DI.Query_Count (DI.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121744))) = 1,
            "query by source node should find the fingerprint blocker");
      end;
   end Dependency_View_Generic_And_Fingerprint_Blockers_Are_Distinct;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Rows_Are_Withheld_As_Current_Evidence'Access,
         "accepted shared-state closure rows are withheld as current evidence");
      Register_Routine
        (T, Blocker_Families_Are_Preserved'Access,
         "shared-state blocker families are preserved");
      Register_Routine
        (T, Dependency_View_Generic_And_Fingerprint_Blockers_Are_Distinct'Access,
         "dependency, view, generic, and fingerprint blockers stay distinct");
   end Register_Tests;

end Test_Ada_Shared_State_Stabilized_Diagnostic_Integration_Pass1217;
