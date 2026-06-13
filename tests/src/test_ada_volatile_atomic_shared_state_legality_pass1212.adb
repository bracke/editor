with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Volatile_Atomic_Shared_State_Legality_Pass1212 is

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
   package Flow renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   use type Flow.Flow_Contract_Proof_Row_Id;
   use type Flow.Flow_Contract_Proof_Context_Kind;
   use type Flow.Flow_Contract_Proof_Status;
   use type Flow.Flow_Contract_Proof_Context_Info;
   use type Flow.Flow_Contract_Proof_Info;
   use type Flow.Flow_Contract_Proof_Context_Model;
   use type Flow.Flow_Contract_Proof_Set;
   use type Flow.Flow_Contract_Proof_Model;
   package Stabilized renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   use type Stabilized.Final_Blocker_Family;
   use type Stabilized.Final_Stabilization_Gate_Status;
   use type Stabilized.Final_Stabilization_Gate_Action;
   use type Stabilized.Final_Stabilized_Closure_Id;
   use type Stabilized.Final_Stabilized_Closure_Status;
   use type Stabilized.Final_Stabilized_Closure_Action;
   use type Stabilized.Final_Stabilized_Closure_Row;
   use type Stabilized.Final_Stabilized_Closure_Model;
   use type Stabilized.Final_Stabilized_Closure_Set;
   package Tasking renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
   use type Tasking.Deep_Tasking_Row_Id;
   use type Tasking.Deep_Tasking_Context_Kind;
   use type Tasking.Deep_Tasking_Status;
   use type Tasking.Deep_Tasking_Context_Info;
   use type Tasking.Deep_Tasking_Info;
   use type Tasking.Deep_Tasking_Context_Model;
   use type Tasking.Deep_Tasking_Set;
   use type Tasking.Deep_Tasking_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Volatile_Atomic_Shared_State_Legality_Pass1212");
   end Name;

   function Complete_Context
     (Id   : Shared.Shared_State_Row_Id;
      Kind : Shared.Shared_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Shared.Shared_State_Context_Info is
      C : Shared.Shared_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Object_Node := Node;
      C.State_Node := Editor.Ada_Syntax_Tree.Node_Id (121200 + Natural (Id));
      C.Operation_Node := Editor.Ada_Syntax_Tree.Node_Id (121300 + Natural (Id));
      C.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
      C.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Natural (Id)));
      C.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      C.Abstract_State_Status := States.Abstract_State_Legal_Declaration_Accepted;
      C.Flow_Proof_Row := Flow.Flow_Contract_Proof_Row_Id (Id);
      C.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Volatile_Effect_Accepted;
      C.Tasking_Row := Tasking.Deep_Tasking_Row_Id (Id);
      C.Tasking_Status := Tasking.Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted;
      C.Stabilized_Row := Stabilized.Final_Stabilized_Closure_Id (Id);
      C.Stabilized_Status := Stabilized.Final_Stabilized_Closure_Accepted_Current;
      C.Requires_Abstract_State := False;
      C.Requires_Flow_Proof := True;
      C.Requires_Tasking := False;
      C.Requires_Stabilized_Closure := True;
      C.Source_Fingerprint := Natural (Id) * 1212;
      C.Expected_Source_Fingerprint := Natural (Id) * 1212;
      return C;
   end Complete_Context;

   procedure Accepted_Volatile_Atomic_And_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Shared.Shared_State_Context_Model;
      Volatile_Read : Shared.Shared_State_Context_Info :=
        Complete_Context
          (1,
           Shared.Shared_State_Volatile_Read,
           Editor.Ada_Syntax_Tree.Node_Id (121201));
      Atomic_RW : Shared.Shared_State_Context_Info :=
        Complete_Context
          (2,
           Shared.Shared_State_Atomic_Read_Write,
           Editor.Ada_Syntax_Tree.Node_Id (121202));
      Protected_Access : Shared.Shared_State_Context_Info :=
        Complete_Context
          (3,
           Shared.Shared_State_Protected_Object_Access,
           Editor.Ada_Syntax_Tree.Node_Id (121203));
   begin
      Atomic_RW.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Atomic_Effect_Accepted;
      Protected_Access.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Task_Protected_State_Accepted;
      Protected_Access.Requires_Tasking := True;

      Shared.Add_Context (Contexts, Volatile_Read);
      Shared.Add_Context (Contexts, Atomic_RW);
      Shared.Add_Context (Contexts, Protected_Access);

      declare
         Model : constant Shared.Shared_State_Model := Shared.Build (Contexts);
      begin
         Assert (Shared.Row_Count (Model) = 3, "three shared-state rows expected");
         Assert (Shared.Legal_Count (Model) = 3, "complete shared-state evidence should remain legal");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121201)).Status =
            Shared.Shared_State_Legal_Volatile_Read_Accepted,
            "volatile read should be accepted");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121202)).Status =
            Shared.Shared_State_Legal_Atomic_Read_Write_Accepted,
            "atomic read/write should be accepted");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121203)).Status =
            Shared.Shared_State_Legal_Protected_Object_Access_Accepted,
            "protected shared-state access should be accepted");
         Assert (Shared.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Volatile_Atomic_And_Shared_State_Evidence;

   procedure Missing_Prerequisite_Evidence_Blocks_Shared_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Shared.Shared_State_Context_Model;
      Missing_Abstract : Shared.Shared_State_Context_Info :=
        Complete_Context
          (1,
           Shared.Shared_State_Abstract_State_Effect,
           Editor.Ada_Syntax_Tree.Node_Id (121221));
      Missing_Flow : Shared.Shared_State_Context_Info :=
        Complete_Context
          (2,
           Shared.Shared_State_Volatile_Write,
           Editor.Ada_Syntax_Tree.Node_Id (121222));
      Missing_Tasking : Shared.Shared_State_Context_Info :=
        Complete_Context
          (3,
           Shared.Shared_State_Task_Activation_Effect,
           Editor.Ada_Syntax_Tree.Node_Id (121223));
      Missing_Closure : Shared.Shared_State_Context_Info :=
        Complete_Context
          (4,
           Shared.Shared_State_Shared_Variable_Access,
           Editor.Ada_Syntax_Tree.Node_Id (121224));
   begin
      Missing_Abstract.Requires_Abstract_State := True;
      Missing_Abstract.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Missing_Flow.Flow_Proof_Status := Flow.Flow_Contract_Proof_Not_Checked;
      Missing_Tasking.Requires_Tasking := True;
      Missing_Tasking.Tasking_Status := Tasking.Deep_Tasking_Not_Checked;
      Missing_Closure.Stabilized_Status := Stabilized.Final_Stabilized_Closure_Not_Checked;

      Shared.Add_Context (Contexts, Missing_Abstract);
      Shared.Add_Context (Contexts, Missing_Flow);
      Shared.Add_Context (Contexts, Missing_Tasking);
      Shared.Add_Context (Contexts, Missing_Closure);

      declare
         Model : constant Shared.Shared_State_Model := Shared.Build (Contexts);
      begin
         Assert (Shared.Legal_Count (Model) = 0, "missing prerequisite evidence must block shared-state legality");
         Assert (Shared.Dependency_Error_Count (Model) = 4, "all prerequisite failures should be counted");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121221)).Status =
            Shared.Shared_State_Missing_Abstract_State_Row,
            "abstract state evidence should be required");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121222)).Status =
            Shared.Shared_State_Missing_Flow_Proof_Row,
            "flow proof evidence should be required");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121223)).Status =
            Shared.Shared_State_Missing_Tasking_Row,
            "tasking evidence should be required");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121224)).Status =
            Shared.Shared_State_Missing_Stabilized_Closure_Row,
            "stabilized closure evidence should be required");
      end;
   end Missing_Prerequisite_Evidence_Blocks_Shared_State;

   procedure Volatile_Atomic_And_Shared_Blockers_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Shared.Shared_State_Context_Model;
      Volatile_Blocker : Shared.Shared_State_Context_Info :=
        Complete_Context
          (1,
           Shared.Shared_State_Volatile_Read_Write_Order,
           Editor.Ada_Syntax_Tree.Node_Id (121241));
      Atomic_Blocker : Shared.Shared_State_Context_Info :=
        Complete_Context
          (2,
           Shared.Shared_State_Atomic_Read_Write,
           Editor.Ada_Syntax_Tree.Node_Id (121242));
      Shared_Blocker : Shared.Shared_State_Context_Info :=
        Complete_Context
          (3,
           Shared.Shared_State_Shared_Variable_Access,
           Editor.Ada_Syntax_Tree.Node_Id (121243));
   begin
      Volatile_Blocker.Volatile_Reordering := True;
      Atomic_Blocker.Atomic_Nonatomic_Mixed_Access := True;
      Shared_Blocker.Shared_Variable_Unprotected := True;

      Shared.Add_Context (Contexts, Volatile_Blocker);
      Shared.Add_Context (Contexts, Atomic_Blocker);
      Shared.Add_Context (Contexts, Shared_Blocker);

      declare
         Model : constant Shared.Shared_State_Model := Shared.Build (Contexts);
      begin
         Assert (Shared.Legal_Count (Model) = 0, "shared-state blockers must not remain legal");
         Assert (Shared.Volatile_Error_Count (Model) = 1, "volatile blocker should be counted");
         Assert (Shared.Atomic_Error_Count (Model) = 1, "atomic blocker should be counted");
         Assert (Shared.Shared_Variable_Error_Count (Model) = 1, "shared variable blocker should be counted");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121241)).Status =
            Shared.Shared_State_Volatile_Read_Write_Reordering,
            "volatile read/write ordering blocker should be preserved");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121242)).Status =
            Shared.Shared_State_Atomic_Nonatomic_Mixed_Access,
            "atomic/non-atomic mixed access blocker should be preserved");
         Assert
           (Shared.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (121243)).Status =
            Shared.Shared_State_Shared_Variable_Unprotected_Access,
            "unprotected shared-variable access blocker should be preserved");
      end;
   end Volatile_Atomic_And_Shared_Blockers_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Volatile_Atomic_And_Shared_State_Evidence'Access,
         "accepted volatile atomic and shared state evidence");
      Register_Routine
        (T,
         Missing_Prerequisite_Evidence_Blocks_Shared_State'Access,
         "missing prerequisite evidence blocks shared state");
      Register_Routine
        (T,
         Volatile_Atomic_And_Shared_Blockers_Are_Preserved'Access,
         "volatile atomic and shared blockers are preserved");
   end Register_Tests;

end Test_Ada_Volatile_Atomic_Shared_State_Legality_Pass1212;
