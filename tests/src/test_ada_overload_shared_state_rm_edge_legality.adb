with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Overload_Shared_State_RM_Edge_Legality is

   package O renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   use type O.Overload_Shared_State_Row_Id;
   use type O.Overload_Shared_State_Context_Kind;
   use type O.Overload_Shared_State_Status;
   use type O.Overload_Shared_State_Context_Info;
   use type O.Overload_Shared_State_Info;
   use type O.Overload_Shared_State_Context_Model;
   use type O.Overload_Shared_State_Model;
   use type O.Overload_Shared_State_Set;
   package States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   use type States.Abstract_State_Row_Id;
   use type States.Abstract_State_Context_Kind;
   use type States.Abstract_State_Status;
   use type States.Abstract_State_Context_Info;
   use type States.Abstract_State_Info;
   use type States.Abstract_State_Context_Model;
   use type States.Abstract_State_Model;
   use type States.Abstract_State_Set;
   package RM renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   use type RM.Final_RM_Row_Id;
   use type RM.Final_RM_Context_Kind;
   use type RM.Final_RM_Status;
   use type RM.Final_RM_Context_Info;
   use type RM.Final_RM_Info;
   use type RM.Final_RM_Context_Model;
   use type RM.Final_RM_Model;
   use type RM.Final_RM_Result_Set;
   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   use type Shared.Shared_State_Row_Id;
   use type Shared.Shared_State_Context_Kind;
   use type Shared.Shared_State_Status;
   use type Shared.Shared_State_Context_Info;
   use type Shared.Shared_State_Info;
   use type Shared.Shared_State_Context_Model;
   use type Shared.Shared_State_Model;
   use type Shared.Shared_State_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Overload_Shared_State_RM_Edge_Legality");
   end Name;

   function Complete_Context
     (Id   : O.Overload_Shared_State_Row_Id;
      Kind : O.Overload_Shared_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return O.Overload_Shared_State_Context_Info is
      C : O.Overload_Shared_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Natural (Id)));
      C.Type_Name := To_Unbounded_String ("T" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
      C.Final_RM_Row := RM.Final_RM_Row_Id (Id);
      C.Final_RM_Status := RM.Final_RM_Legal_Prefixed_Call_Primitive_Selected;
      C.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      C.Shared_State_Status := Shared.Shared_State_Legal_Volatile_Read_Accepted;
      C.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      C.Abstract_State_Status := States.Abstract_State_Legal_Declaration_Accepted;
      C.Requires_Final_RM := True;
      C.Requires_Shared_State := True;
      C.Requires_Abstract_State := False;
      C.Source_Fingerprint := Natural (Id) * 1213;
      C.Expected_Source_Fingerprint := Natural (Id) * 1213;
      return C;
   end Complete_Context;

   procedure Accepted_Overload_Rows_Require_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : O.Overload_Shared_State_Context_Model;
      Prefixed : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (1,
           O.Overload_Shared_State_Prefixed_Call,
           Editor.Ada_Syntax_Tree.Node_Id (121301));
      Access_Call : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (2,
           O.Overload_Shared_State_Access_Subprogram_Call,
           Editor.Ada_Syntax_Tree.Node_Id (121302));
      Dispatching : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (3,
           O.Overload_Shared_State_Dispatching_Call,
           Editor.Ada_Syntax_Tree.Node_Id (121303));
   begin
      Access_Call.Final_RM_Status := RM.Final_RM_Legal_Access_Subprogram_Profile_Accepted;
      Access_Call.Shared_State_Status := Shared.Shared_State_Legal_Atomic_Read_Write_Accepted;
      Dispatching.Final_RM_Status := RM.Final_RM_Legal_Dispatching_Inherited_Operation_Selected;
      Dispatching.Shared_State_Status := Shared.Shared_State_Legal_Protected_Object_Access_Accepted;

      O.Add_Context (Contexts, Prefixed);
      O.Add_Context (Contexts, Access_Call);
      O.Add_Context (Contexts, Dispatching);

      declare
         Model : constant O.Overload_Shared_State_Model := O.Build (Contexts);
      begin
         Assert (O.Row_Count (Model) = 3, "three overload shared-state rows expected");
         Assert (O.Legal_Count (Model) = 3, "complete final RM/shared-state evidence should be legal");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121301)).Status =
            O.Overload_Shared_State_Legal_Prefixed_Call_Accepted,
            "prefixed call should be accepted");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121302)).Status =
            O.Overload_Shared_State_Legal_Access_Subprogram_Call_Accepted,
            "access subprogram call should be accepted");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121303)).Status =
            O.Overload_Shared_State_Legal_Dispatching_Call_Accepted,
            "dispatching call should be accepted");
         Assert (O.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Overload_Rows_Require_Shared_State_Evidence;

   procedure Missing_And_Blocked_Prerequisites_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : O.Overload_Shared_State_Context_Model;
      Missing_RM : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (1, O.Overload_Shared_State_Prefixed_Call, Editor.Ada_Syntax_Tree.Node_Id (121321));
      Missing_Shared : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (2, O.Overload_Shared_State_Dispatching_Call, Editor.Ada_Syntax_Tree.Node_Id (121322));
      Missing_Abstract : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (3, O.Overload_Shared_State_Abstract_State_Effect, Editor.Ada_Syntax_Tree.Node_Id (121323));
      Blocked_Shared : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (4, O.Overload_Shared_State_Volatile_Atomic_Effect, Editor.Ada_Syntax_Tree.Node_Id (121324));
   begin
      Missing_RM.Final_RM_Status := RM.Final_RM_Not_Checked;
      Missing_Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Missing_Abstract.Requires_Abstract_State := True;
      Missing_Abstract.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Blocked_Shared.Shared_State_Status := Shared.Shared_State_Atomic_Nonatomic_Mixed_Access;

      O.Add_Context (Contexts, Missing_RM);
      O.Add_Context (Contexts, Missing_Shared);
      O.Add_Context (Contexts, Missing_Abstract);
      O.Add_Context (Contexts, Blocked_Shared);

      declare
         Model : constant O.Overload_Shared_State_Model := O.Build (Contexts);
      begin
         Assert (O.Legal_Count (Model) = 0, "missing prerequisite evidence should block legality");
         Assert (O.Dependency_Blocker_Count (Model) = 4, "all prerequisite blockers should be dependency blockers");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121321)).Status =
            O.Overload_Shared_State_Missing_Final_RM_Row,
            "missing final RM row should be preserved");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121322)).Status =
            O.Overload_Shared_State_Missing_Shared_State_Row,
            "missing shared-state row should be preserved");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121323)).Status =
            O.Overload_Shared_State_Missing_Abstract_State_Row,
            "missing abstract-state row should be preserved");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121324)).Status =
            O.Overload_Shared_State_Shared_State_Blocker,
            "blocked shared-state row should be preserved");
      end;
   end Missing_And_Blocked_Prerequisites_Are_Preserved;

   procedure Effect_Mismatches_And_Ambiguity_Are_Not_Flattened
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : O.Overload_Shared_State_Context_Model;
      Volatile : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (1, O.Overload_Shared_State_Prefixed_Call, Editor.Ada_Syntax_Tree.Node_Id (121341));
      Dispatching : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (2, O.Overload_Shared_State_Dispatching_Call, Editor.Ada_Syntax_Tree.Node_Id (121342));
      Ambiguous : O.Overload_Shared_State_Context_Info :=
        Complete_Context
          (3, O.Overload_Shared_State_Universal_Numeric_Operator, Editor.Ada_Syntax_Tree.Node_Id (121343));
   begin
      Volatile.Volatile_Effect_Blocker := True;
      Dispatching.Dispatching_Effect_Mismatch := True;
      Ambiguous.Universal_Numeric_State_Ambiguous := True;

      O.Add_Context (Contexts, Volatile);
      O.Add_Context (Contexts, Dispatching);
      O.Add_Context (Contexts, Ambiguous);

      declare
         Model : constant O.Overload_Shared_State_Model := O.Build (Contexts);
      begin
         Assert (O.Effect_Blocker_Count (Model) = 2, "effect blockers should be counted directly");
         Assert (O.Ambiguous_Count (Model) = 1, "state ambiguity should remain distinct");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121341)).Status =
            O.Overload_Shared_State_Volatile_Effect_Blocker,
            "volatile effect blocker should be preserved");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121342)).Status =
            O.Overload_Shared_State_Dispatching_Effect_Mismatch,
            "dispatching effect mismatch should be preserved");
         Assert
           (O.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121343)).Status =
            O.Overload_Shared_State_Universal_Numeric_State_Ambiguous,
            "universal numeric state ambiguity should be preserved");
      end;
   end Effect_Mismatches_And_Ambiguity_Are_Not_Flattened;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Overload_Rows_Require_Shared_State_Evidence'Access,
         "accepted overload/type rows require shared-state evidence");
      Register_Routine
        (T,
         Missing_And_Blocked_Prerequisites_Are_Preserved'Access,
         "missing and blocked prerequisites are preserved");
      Register_Routine
        (T,
         Effect_Mismatches_And_Ambiguity_Are_Not_Flattened'Access,
         "effect mismatches and ambiguity are not flattened");
   end Register_Tests;

end Test_Ada_Overload_Shared_State_RM_Edge_Legality;
