with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Cross_Unit_Shared_State_Final_Closure_Legality_Pass1216 is

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

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada cross-unit shared-state final closure legality pass1216");
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
      C.Unit_Node := Editor.Ada_Syntax_Tree.Node_Id (121_600 + Natural (Id));
      C.Dependency_Node := Editor.Ada_Syntax_Tree.Node_Id (121_700 + Natural (Id));
      C.State_Node := Editor.Ada_Syntax_Tree.Node_Id (121_800 + Natural (Id));
      C.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Natural (Id)));
      C.Dependency_Name := To_Unbounded_String ("Dependency" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
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
      C.Source_Fingerprint := Natural (Id) * 1216;
      C.Expected_Source_Fingerprint := Natural (Id) * 1216;
      return C;
   end Complete_Context;

   procedure Accepted_Rows_Require_Cross_Unit_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Local : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Local, Editor.Ada_Syntax_Tree.Node_Id (121601));
      Abstract_State : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121602));
      Tasking_State : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121603));
   begin
      Local.Dependency := CUS.Shared_Dependency_Local;
      Local.Cross_Unit_Status := CU.Cross_Unit_Final_Local_Accepted;
      Tasking_State.Requires_Overload_State := True;
      Tasking_State.Requires_Representation_State := True;
      Tasking_State.Requires_Tasking_State := True;

      CUS.Add_Context (Contexts, Local);
      CUS.Add_Context (Contexts, Abstract_State);
      CUS.Add_Context (Contexts, Tasking_State);

      declare
         Model : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      begin
         Assert (CUS.Row_Count (Model) = 3, "three cross-unit shared-state rows expected");
         Assert (CUS.Legal_Count (Model) = 3, "complete cross-unit shared-state evidence should be legal");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121601)).Status =
            CUS.Cross_Unit_Shared_State_Legal_Local_Accepted,
            "local shared-state closure should be accepted");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121602)).Status =
            CUS.Cross_Unit_Shared_State_Legal_Abstract_State_Accepted,
            "abstract-state closure should be accepted");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121603)).Status =
            CUS.Cross_Unit_Shared_State_Legal_Tasking_Protected_Accepted,
            "tasking shared-state closure should be accepted");
         Assert (CUS.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Rows_Require_Cross_Unit_Shared_State_Evidence;

   procedure Missing_Prerequisites_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Missing_Cross : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (121621));
      Missing_Abstract : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121622));
      Missing_Shared : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Volatile_Atomic, Editor.Ada_Syntax_Tree.Node_Id (121623));
      Missing_Tasking : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121624));
   begin
      Missing_Cross.Cross_Unit_Status := CU.Cross_Unit_Final_Not_Checked;
      Missing_Abstract.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Missing_Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Missing_Tasking.Requires_Tasking_State := True;
      Missing_Tasking.Tasking_State_Status := Tasking.Tasking_Shared_State_Not_Checked;

      CUS.Add_Context (Contexts, Missing_Cross);
      CUS.Add_Context (Contexts, Missing_Abstract);
      CUS.Add_Context (Contexts, Missing_Shared);
      CUS.Add_Context (Contexts, Missing_Tasking);

      declare
         Model : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      begin
         Assert (CUS.Legal_Count (Model) = 0, "missing prerequisite rows should block legality");
         Assert (CUS.Dependency_Error_Count (Model) = 1, "missing cross-unit row should be dependency error");
         Assert (CUS.Shared_State_Error_Count (Model) = 2, "missing abstract/shared rows should be shared-state errors");
         Assert (CUS.Tasking_Error_Count (Model) = 1, "missing tasking row should be tasking error");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121621)).Status =
            CUS.Cross_Unit_Shared_State_Missing_Cross_Unit_Row,
            "missing cross-unit row should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121622)).Status =
            CUS.Cross_Unit_Shared_State_Missing_Abstract_State_Row,
            "missing abstract-state row should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121623)).Status =
            CUS.Cross_Unit_Shared_State_Missing_Shared_State_Row,
            "missing shared-state row should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121624)).Status =
            CUS.Cross_Unit_Shared_State_Missing_Tasking_State_Row,
            "missing tasking shared-state row should be preserved");
      end;
   end Missing_Prerequisites_Are_Preserved;

   procedure Dependency_And_View_Blockers_Are_Not_Flattened
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Missing_Dep : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_With_Use, Editor.Ada_Syntax_Tree.Node_Id (121641));
      Limited_View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Limited_View, Editor.Ada_Syntax_Tree.Node_Id (121642));
      Private_View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Private_Full_View, Editor.Ada_Syntax_Tree.Node_Id (121643));
      State_View : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Abstract_State, Editor.Ada_Syntax_Tree.Node_Id (121644));
   begin
      Missing_Dep.Dependency := CUS.Shared_Dependency_Missing;
      Limited_View.Limited_View_Barrier := True;
      Private_View.Private_View_Barrier := True;
      State_View.State_Visibility_Blocker := True;

      CUS.Add_Context (Contexts, Missing_Dep);
      CUS.Add_Context (Contexts, Limited_View);
      CUS.Add_Context (Contexts, Private_View);
      CUS.Add_Context (Contexts, State_View);

      declare
         Model : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      begin
         Assert (CUS.Dependency_Error_Count (Model) = 1, "dependency blocker should be counted");
         Assert (CUS.View_Error_Count (Model) = 3, "view blockers should be counted");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121641)).Status =
            CUS.Cross_Unit_Shared_State_Missing_Dependency,
            "missing dependency should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121642)).Status =
            CUS.Cross_Unit_Shared_State_Limited_View_Barrier,
            "limited view blocker should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121643)).Status =
            CUS.Cross_Unit_Shared_State_Private_View_Barrier,
            "private view blocker should be preserved");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121644)).Status =
            CUS.Cross_Unit_Shared_State_State_Visibility_Blocker,
            "state visibility blocker should be preserved");
      end;
   end Dependency_And_View_Blockers_Are_Not_Flattened;

   procedure Multiple_Blockers_And_Fingerprints_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CUS.Cross_Unit_Shared_State_Context_Model;
      Multiple : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (1, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (121661));
      Fingerprint : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (2, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121662));
      Representation : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (3, CUS.Cross_Unit_Shared_State_Representation, Editor.Ada_Syntax_Tree.Node_Id (121663));
      Tasking_Blocker : CUS.Cross_Unit_Shared_State_Context_Info :=
        Complete_Context (4, CUS.Cross_Unit_Shared_State_Tasking_Protected, Editor.Ada_Syntax_Tree.Node_Id (121664));
   begin
      Multiple.Shared_Variable_Blocker := True;
      Multiple.Volatile_Atomic_Order_Blocker := True;
      Fingerprint.Expected_Source_Fingerprint := 99;
      Representation.Representation_Effect_Blocker := True;
      Tasking_Blocker.Tasking_Effect_Blocker := True;

      CUS.Add_Context (Contexts, Multiple);
      CUS.Add_Context (Contexts, Fingerprint);
      CUS.Add_Context (Contexts, Representation);
      CUS.Add_Context (Contexts, Tasking_Blocker);

      declare
         Model : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
         First_Fingerprint : constant Natural := CUS.Fingerprint (Model);
         Rebuilt : constant CUS.Cross_Unit_Shared_State_Model := CUS.Build (Contexts);
      begin
         Assert (CUS.Error_Count (Model) = 4, "all blocker rows should be errors");
         Assert (CUS.Shared_State_Error_Count (Model) = 0, "multiple blocker should not be double-counted as shared-state family");
         Assert (CUS.Representation_Error_Count (Model) = 1, "representation blocker should be counted");
         Assert (CUS.Tasking_Error_Count (Model) = 1, "tasking blocker should be counted");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121661)).Status =
            CUS.Cross_Unit_Shared_State_Multiple_Blockers,
            "multiple blockers should remain distinct");
         Assert
           (CUS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121662)).Status =
            CUS.Cross_Unit_Shared_State_Source_Fingerprint_Mismatch,
            "fingerprint mismatch should be preserved");
         Assert (First_Fingerprint = CUS.Fingerprint (Rebuilt), "rebuilt model fingerprint should be stable");
      end;
   end Multiple_Blockers_And_Fingerprints_Are_Stable;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Rows_Require_Cross_Unit_Shared_State_Evidence'Access,
         "accepted cross-unit shared-state rows require final evidence");
      Register_Routine
        (T, Missing_Prerequisites_Are_Preserved'Access,
         "missing shared-state prerequisites are preserved");
      Register_Routine
        (T, Dependency_And_View_Blockers_Are_Not_Flattened'Access,
         "dependency and view blockers are not flattened");
      Register_Routine
        (T, Multiple_Blockers_And_Fingerprints_Are_Stable'Access,
         "multiple blockers and fingerprints are stable");
   end Register_Tests;

end Test_Ada_Cross_Unit_Shared_State_Final_Closure_Legality_Pass1216;
