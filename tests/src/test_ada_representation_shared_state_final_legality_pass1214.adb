with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Representation_Shared_State_Final_Legality_Pass1214 is

   package R renames Editor.Ada_Representation_Shared_State_Final_Legality;
   use type R.Representation_Shared_State_Row_Id;
   use type R.Representation_Shared_State_Context_Kind;
   use type R.Representation_Shared_State_Status;
   use type R.Representation_Shared_State_Context_Info;
   use type R.Representation_Shared_State_Info;
   use type R.Representation_Shared_State_Context_Model;
   use type R.Representation_Shared_State_Model;
   use type R.Representation_Shared_State_Set;
   package Rep renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   use type Rep.Final_Representation_Row_Id;
   use type Rep.Final_Representation_Context_Kind;
   use type Rep.Final_Representation_Status;
   use type Rep.Final_Representation_Context_Info;
   use type Rep.Final_Representation_Info;
   use type Rep.Final_Representation_Context_Model;
   use type Rep.Final_Representation_Model;
   use type Rep.Final_Representation_Set;
   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   use type Shared.Shared_State_Row_Id;
   use type Shared.Shared_State_Context_Kind;
   use type Shared.Shared_State_Status;
   use type Shared.Shared_State_Context_Info;
   use type Shared.Shared_State_Info;
   use type Shared.Shared_State_Context_Model;
   use type Shared.Shared_State_Model;
   use type Shared.Shared_State_Set;
   package States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   use type States.Abstract_State_Row_Id;
   use type States.Abstract_State_Context_Kind;
   use type States.Abstract_State_Status;
   use type States.Abstract_State_Context_Info;
   use type States.Abstract_State_Info;
   use type States.Abstract_State_Context_Model;
   use type States.Abstract_State_Model;
   use type States.Abstract_State_Set;
   package O renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   use type O.Overload_Shared_State_Row_Id;
   use type O.Overload_Shared_State_Context_Kind;
   use type O.Overload_Shared_State_Status;
   use type O.Overload_Shared_State_Context_Info;
   use type O.Overload_Shared_State_Info;
   use type O.Overload_Shared_State_Context_Model;
   use type O.Overload_Shared_State_Model;
   use type O.Overload_Shared_State_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Representation_Shared_State_Final_Legality_Pass1214");
   end Name;

   function Complete_Context
     (Id   : R.Representation_Shared_State_Row_Id;
      Kind : R.Representation_Shared_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return R.Representation_Shared_State_Context_Info is
      C : R.Representation_Shared_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Representation_Node := Editor.Ada_Syntax_Tree.Node_Id (121_400 + Natural (Id));
      C.Object_Node := Editor.Ada_Syntax_Tree.Node_Id (121_500 + Natural (Id));
      C.State_Node := Editor.Ada_Syntax_Tree.Node_Id (121_600 + Natural (Id));
      C.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
      C.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Natural (Id)));
      C.Final_Representation_Row := Rep.Final_Representation_Row_Id (Id);
      C.Final_Representation_Status := Rep.Final_Representation_Legal_Representation_Item_Accepted;
      C.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      C.Shared_State_Status := Shared.Shared_State_Legal_Volatile_Read_Accepted;
      C.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      C.Abstract_State_Status := States.Abstract_State_Legal_Declaration_Accepted;
      C.Overload_State_Row := O.Overload_Shared_State_Row_Id (Id);
      C.Overload_State_Status := O.Overload_Shared_State_Legal_Prefixed_Call_Accepted;
      C.Requires_Final_Representation := True;
      C.Requires_Shared_State := True;
      C.Requires_Abstract_State := False;
      C.Requires_Overload_State := False;
      C.Source_Fingerprint := Natural (Id) * 1214;
      C.Expected_Source_Fingerprint := Natural (Id) * 1214;
      return C;
   end Complete_Context;

   procedure Accepted_Representation_Rows_Require_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : R.Representation_Shared_State_Context_Model;
      Volatile : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (1,
           R.Representation_Shared_State_Volatile_Object_Clause,
           Editor.Ada_Syntax_Tree.Node_Id (121401));
      Atomic : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (2,
           R.Representation_Shared_State_Atomic_Object_Clause,
           Editor.Ada_Syntax_Tree.Node_Id (121402));
      Stream : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (3,
           R.Representation_Shared_State_Stream_Attribute,
           Editor.Ada_Syntax_Tree.Node_Id (121403));
   begin
      Atomic.Shared_State_Status := Shared.Shared_State_Legal_Atomic_Read_Write_Accepted;
      Stream.Final_Representation_Status := Rep.Final_Representation_Legal_Stream_Attribute_Private_View_Accepted;
      Stream.Requires_Abstract_State := True;
      Stream.Requires_Overload_State := True;

      R.Add_Context (Contexts, Volatile);
      R.Add_Context (Contexts, Atomic);
      R.Add_Context (Contexts, Stream);

      declare
         Model : constant R.Representation_Shared_State_Model := R.Build (Contexts);
      begin
         Assert (R.Row_Count (Model) = 3, "three representation/shared-state rows expected");
         Assert (R.Legal_Count (Model) = 3, "complete representation/shared-state evidence should be legal");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121401)).Status =
            R.Representation_Shared_State_Legal_Volatile_Object_Clause_Accepted,
            "volatile object clause should be accepted");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121402)).Status =
            R.Representation_Shared_State_Legal_Atomic_Object_Clause_Accepted,
            "atomic object clause should be accepted");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121403)).Status =
            R.Representation_Shared_State_Legal_Stream_Attribute_Accepted,
            "stream attribute should be accepted");
         Assert (R.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Representation_Rows_Require_Shared_State_Evidence;

   procedure Missing_And_Blocked_Prerequisites_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : R.Representation_Shared_State_Context_Model;
      Missing_Rep : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (1, R.Representation_Shared_State_Volatile_Object_Clause, Editor.Ada_Syntax_Tree.Node_Id (121421));
      Missing_Shared : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (2, R.Representation_Shared_State_Atomic_Object_Clause, Editor.Ada_Syntax_Tree.Node_Id (121422));
      Missing_Abstract : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (3, R.Representation_Shared_State_Abstract_State_View, Editor.Ada_Syntax_Tree.Node_Id (121423));
      Missing_Overload : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (4, R.Representation_Shared_State_Operational_Attribute, Editor.Ada_Syntax_Tree.Node_Id (121424));
   begin
      Missing_Rep.Final_Representation_Status := Rep.Final_Representation_Not_Checked;
      Missing_Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Missing_Abstract.Requires_Abstract_State := True;
      Missing_Abstract.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Missing_Overload.Requires_Overload_State := True;
      Missing_Overload.Overload_State_Status := O.Overload_Shared_State_Not_Checked;

      R.Add_Context (Contexts, Missing_Rep);
      R.Add_Context (Contexts, Missing_Shared);
      R.Add_Context (Contexts, Missing_Abstract);
      R.Add_Context (Contexts, Missing_Overload);

      declare
         Model : constant R.Representation_Shared_State_Model := R.Build (Contexts);
      begin
         Assert (R.Legal_Count (Model) = 0, "missing prerequisite rows should block legality");
         Assert (R.Dependency_Error_Count (Model) = 4, "all prerequisite failures should be counted");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121421)).Status =
            R.Representation_Shared_State_Missing_Final_Representation_Row,
            "missing final representation row should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121422)).Status =
            R.Representation_Shared_State_Missing_Shared_State_Row,
            "missing shared-state row should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121423)).Status =
            R.Representation_Shared_State_Missing_Abstract_State_Row,
            "missing abstract-state row should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121424)).Status =
            R.Representation_Shared_State_Missing_Overload_State_Row,
            "missing overload shared-state row should be preserved");
      end;
   end Missing_And_Blocked_Prerequisites_Are_Preserved;

   procedure Representation_And_Shared_State_Blockers_Are_Not_Flattened
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : R.Representation_Shared_State_Context_Model;
      Volatile : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (1, R.Representation_Shared_State_Volatile_Object_Clause, Editor.Ada_Syntax_Tree.Node_Id (121441));
      Atomic : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (2, R.Representation_Shared_State_Atomic_Object_Clause, Editor.Ada_Syntax_Tree.Node_Id (121442));
      Shared_Record : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (3, R.Representation_Shared_State_Shared_Record_Layout, Editor.Ada_Syntax_Tree.Node_Id (121443));
      Blocked_Shared : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (4, R.Representation_Shared_State_Protected_Object_Representation, Editor.Ada_Syntax_Tree.Node_Id (121444));
   begin
      Volatile.Volatile_Representation_Error := True;
      Atomic.Atomic_Representation_Error := True;
      Shared_Record.Shared_Record_Layout_Error := True;
      Blocked_Shared.Shared_State_Status := Shared.Shared_State_Shared_Variable_Unprotected_Access;

      R.Add_Context (Contexts, Volatile);
      R.Add_Context (Contexts, Atomic);
      R.Add_Context (Contexts, Shared_Record);
      R.Add_Context (Contexts, Blocked_Shared);

      declare
         Model : constant R.Representation_Shared_State_Model := R.Build (Contexts);
      begin
         Assert (R.Legal_Count (Model) = 0, "blockers must not remain legal");
         Assert (R.Representation_Error_Count (Model) = 3, "representation blockers should be counted");
         Assert (R.Shared_State_Error_Count (Model) = 1, "shared-state blocker should be counted");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121441)).Status =
            R.Representation_Shared_State_Volatile_Representation_Blocker,
            "volatile representation blocker should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121442)).Status =
            R.Representation_Shared_State_Atomic_Representation_Blocker,
            "atomic representation blocker should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121443)).Status =
            R.Representation_Shared_State_Shared_Record_Layout_Blocker,
            "shared record-layout blocker should be preserved");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121444)).Status =
            R.Representation_Shared_State_Shared_State_Blocker,
            "blocked shared-state evidence should be preserved");
      end;
   end Representation_And_Shared_State_Blockers_Are_Not_Flattened;

   procedure Multiple_Blockers_And_Fingerprints_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : R.Representation_Shared_State_Context_Model;
      Multiple : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (1, R.Representation_Shared_State_Generic_Formal_Freezing, Editor.Ada_Syntax_Tree.Node_Id (121461));
      Fingerprint_Mismatch : R.Representation_Shared_State_Context_Info :=
        Complete_Context
          (2, R.Representation_Shared_State_Private_Full_View_Freezing, Editor.Ada_Syntax_Tree.Node_Id (121462));
   begin
      Multiple.Generic_Formal_Freezing_Error := True;
      Multiple.Stream_Attribute_Error := True;
      Fingerprint_Mismatch.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Multiple);
      R.Add_Context (Contexts, Fingerprint_Mismatch);

      declare
         Model : constant R.Representation_Shared_State_Model := R.Build (Contexts);
      begin
         Assert (R.Error_Count (Model) = 2, "two errors expected");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121461)).Status =
            R.Representation_Shared_State_Multiple_Blockers,
            "multiple local blockers should not be flattened");
         Assert
           (R.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121462)).Status =
            R.Representation_Shared_State_Source_Fingerprint_Mismatch,
            "source fingerprint mismatch should be preserved");
         Assert (R.Fingerprint (Model) /= 0, "fingerprint should be stable and nonzero");
      end;
   end Multiple_Blockers_And_Fingerprints_Are_Stable;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Representation_Rows_Require_Shared_State_Evidence'Access,
         "accepted representation rows require shared-state evidence");
      Register_Routine
        (T,
         Missing_And_Blocked_Prerequisites_Are_Preserved'Access,
         "missing and blocked prerequisites are preserved");
      Register_Routine
        (T,
         Representation_And_Shared_State_Blockers_Are_Not_Flattened'Access,
         "representation and shared-state blockers are not flattened");
      Register_Routine
        (T,
         Multiple_Blockers_And_Fingerprints_Are_Stable'Access,
         "multiple blockers and fingerprints are stable");
   end Register_Tests;

end Test_Ada_Representation_Shared_State_Final_Legality_Pass1214;
