with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package body Test_Ada_Tasking_Shared_State_Final_Legality_Pass1215 is

   package TSS renames Editor.Ada_Tasking_Shared_State_Final_Legality;
   use type TSS.Tasking_Shared_State_Row_Id;
   use type TSS.Tasking_Shared_State_Context_Kind;
   use type TSS.Tasking_Shared_State_Status;
   use type TSS.Tasking_Shared_State_Context_Info;
   use type TSS.Tasking_Shared_State_Info;
   use type TSS.Tasking_Shared_State_Context_Model;
   use type TSS.Tasking_Shared_State_Model;
   use type TSS.Tasking_Shared_State_Set;
   package Deep renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
   use type Deep.Deep_Tasking_Row_Id;
   use type Deep.Deep_Tasking_Context_Kind;
   use type Deep.Deep_Tasking_Status;
   use type Deep.Deep_Tasking_Context_Info;
   use type Deep.Deep_Tasking_Info;
   use type Deep.Deep_Tasking_Context_Model;
   use type Deep.Deep_Tasking_Set;
   use type Deep.Deep_Tasking_Model;
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
   package Rep renames Editor.Ada_Representation_Shared_State_Final_Legality;
   use type Rep.Representation_Shared_State_Row_Id;
   use type Rep.Representation_Shared_State_Context_Kind;
   use type Rep.Representation_Shared_State_Status;
   use type Rep.Representation_Shared_State_Context_Info;
   use type Rep.Representation_Shared_State_Info;
   use type Rep.Representation_Shared_State_Context_Model;
   use type Rep.Representation_Shared_State_Model;
   use type Rep.Representation_Shared_State_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Tasking_Shared_State_Final_Legality_Pass1215");
   end Name;

   function Complete_Context
     (Id   : TSS.Tasking_Shared_State_Row_Id;
      Kind : TSS.Tasking_Shared_State_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return TSS.Tasking_Shared_State_Context_Info is
      C : TSS.Tasking_Shared_State_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Task_Node := Editor.Ada_Syntax_Tree.Node_Id (121_500 + Natural (Id));
      C.Protected_Node := Editor.Ada_Syntax_Tree.Node_Id (121_600 + Natural (Id));
      C.Operation_Node := Editor.Ada_Syntax_Tree.Node_Id (121_700 + Natural (Id));
      C.State_Node := Editor.Ada_Syntax_Tree.Node_Id (121_800 + Natural (Id));
      C.Operation_Name := To_Unbounded_String ("Operation" & Natural'Image (Natural (Id)));
      C.State_Name := To_Unbounded_String ("State" & Natural'Image (Natural (Id)));
      C.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Natural (Id)));
      C.Deep_Tasking_Row := Deep.Deep_Tasking_Row_Id (Id);
      C.Deep_Tasking_Status := Deep.Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted;
      C.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      C.Shared_State_Status := Shared.Shared_State_Legal_Protected_Object_Access_Accepted;
      C.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      C.Abstract_State_Status := States.Abstract_State_Legal_Declaration_Accepted;
      C.Overload_State_Row := O.Overload_Shared_State_Row_Id (Id);
      C.Overload_State_Status := O.Overload_Shared_State_Legal_Prefixed_Call_Accepted;
      C.Representation_State_Row := Rep.Representation_Shared_State_Row_Id (Id);
      C.Representation_State_Status := Rep.Representation_Shared_State_Legal_Protected_Object_Representation_Accepted;
      C.Requires_Deep_Tasking := True;
      C.Requires_Shared_State := True;
      C.Requires_Abstract_State := False;
      C.Requires_Overload_State := False;
      C.Requires_Representation_State := False;
      C.Source_Fingerprint := Natural (Id) * 1215;
      C.Expected_Source_Fingerprint := Natural (Id) * 1215;
      return C;
   end Complete_Context;

   procedure Accepted_Tasking_Rows_Require_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TSS.Tasking_Shared_State_Context_Model;
      Protected_Read : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context
          (1,
           TSS.Tasking_Shared_State_Protected_Function_Read,
           Editor.Ada_Syntax_Tree.Node_Id (121501));
      Entry_Barrier : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context
          (2,
           TSS.Tasking_Shared_State_Protected_Entry_Barrier,
           Editor.Ada_Syntax_Tree.Node_Id (121502));
      Representation_Effect : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context
          (3,
           TSS.Tasking_Shared_State_Representation_Effect,
           Editor.Ada_Syntax_Tree.Node_Id (121503));
   begin
      Entry_Barrier.Shared_State_Status := Shared.Shared_State_Legal_Volatile_Order_Accepted;
      Representation_Effect.Requires_Abstract_State := True;
      Representation_Effect.Requires_Overload_State := True;
      Representation_Effect.Requires_Representation_State := True;

      TSS.Add_Context (Contexts, Protected_Read);
      TSS.Add_Context (Contexts, Entry_Barrier);
      TSS.Add_Context (Contexts, Representation_Effect);

      declare
         Model : constant TSS.Tasking_Shared_State_Model := TSS.Build (Contexts);
      begin
         Assert (TSS.Row_Count (Model) = 3, "three tasking/shared-state rows expected");
         Assert (TSS.Legal_Count (Model) = 3, "complete tasking shared-state evidence should be legal");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121501)).Status =
            TSS.Tasking_Shared_State_Legal_Protected_Function_Read_Accepted,
            "protected read should be accepted");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121502)).Status =
            TSS.Tasking_Shared_State_Legal_Protected_Entry_Barrier_Accepted,
            "entry barrier should be accepted");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121503)).Status =
            TSS.Tasking_Shared_State_Legal_Representation_Effect_Accepted,
            "representation effect should be accepted");
         Assert (TSS.Fingerprint (Model) /= 0, "model fingerprint should be deterministic");
      end;
   end Accepted_Tasking_Rows_Require_Shared_State_Evidence;

   procedure Missing_Prerequisites_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TSS.Tasking_Shared_State_Context_Model;
      Missing_Tasking : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (1, TSS.Tasking_Shared_State_Task_Activation, Editor.Ada_Syntax_Tree.Node_Id (121521));
      Missing_Shared : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (2, TSS.Tasking_Shared_State_Protected_Function_Read, Editor.Ada_Syntax_Tree.Node_Id (121522));
      Missing_Abstract : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (3, TSS.Tasking_Shared_State_Abstract_State_Access, Editor.Ada_Syntax_Tree.Node_Id (121523));
      Missing_Rep : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (4, TSS.Tasking_Shared_State_Representation_Effect, Editor.Ada_Syntax_Tree.Node_Id (121524));
   begin
      Missing_Tasking.Deep_Tasking_Status := Deep.Deep_Tasking_Not_Checked;
      Missing_Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Missing_Abstract.Requires_Abstract_State := True;
      Missing_Abstract.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Missing_Rep.Requires_Representation_State := True;
      Missing_Rep.Representation_State_Status := Rep.Representation_Shared_State_Not_Checked;

      TSS.Add_Context (Contexts, Missing_Tasking);
      TSS.Add_Context (Contexts, Missing_Shared);
      TSS.Add_Context (Contexts, Missing_Abstract);
      TSS.Add_Context (Contexts, Missing_Rep);

      declare
         Model : constant TSS.Tasking_Shared_State_Model := TSS.Build (Contexts);
      begin
         Assert (TSS.Legal_Count (Model) = 0, "missing prerequisite rows should block legality");
         Assert (TSS.Dependency_Error_Count (Model) = 4, "all missing prerequisites should be counted");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121521)).Status =
            TSS.Tasking_Shared_State_Missing_Deep_Tasking_Row,
            "missing deep tasking row should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121522)).Status =
            TSS.Tasking_Shared_State_Missing_Shared_State_Row,
            "missing shared-state row should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121523)).Status =
            TSS.Tasking_Shared_State_Missing_Abstract_State_Row,
            "missing abstract-state row should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121524)).Status =
            TSS.Tasking_Shared_State_Missing_Representation_State_Row,
            "missing representation-state row should be preserved");
      end;
   end Missing_Prerequisites_Are_Preserved;

   procedure Local_And_Dependency_Blockers_Are_Not_Flattened
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TSS.Tasking_Shared_State_Context_Model;
      Barrier : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (1, TSS.Tasking_Shared_State_Protected_Entry_Barrier, Editor.Ada_Syntax_Tree.Node_Id (121541));
      Queue : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (2, TSS.Tasking_Shared_State_Entry_Family_Queue, Editor.Ada_Syntax_Tree.Node_Id (121542));
      Shared_Blocker : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (3, TSS.Tasking_Shared_State_Protected_Procedure_Write, Editor.Ada_Syntax_Tree.Node_Id (121543));
      Rep_Blocker : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (4, TSS.Tasking_Shared_State_Representation_Effect, Editor.Ada_Syntax_Tree.Node_Id (121544));
   begin
      Barrier.Barrier_Side_Effect_Error := True;
      Queue.Entry_Family_Queue_Error := True;
      Shared_Blocker.Shared_State_Status := Shared.Shared_State_Shared_Variable_Unprotected_Access;
      Rep_Blocker.Requires_Representation_State := True;
      Rep_Blocker.Representation_State_Status := Rep.Representation_Shared_State_Atomic_Representation_Blocker;

      TSS.Add_Context (Contexts, Barrier);
      TSS.Add_Context (Contexts, Queue);
      TSS.Add_Context (Contexts, Shared_Blocker);
      TSS.Add_Context (Contexts, Rep_Blocker);

      declare
         Model : constant TSS.Tasking_Shared_State_Model := TSS.Build (Contexts);
      begin
         Assert (TSS.Legal_Count (Model) = 0, "blockers must not remain legal");
         Assert (TSS.Tasking_Error_Count (Model) = 1, "tasking blocker should be counted");
         Assert (TSS.Shared_State_Error_Count (Model) = 2, "shared-state blockers should be counted");
         Assert (TSS.Representation_Error_Count (Model) = 1, "representation blocker should be counted");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121541)).Status =
            TSS.Tasking_Shared_State_Barrier_Side_Effect_Blocker,
            "barrier side effect blocker should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121542)).Status =
            TSS.Tasking_Shared_State_Entry_Family_Queue_Blocker,
            "entry family queue blocker should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121543)).Status =
            TSS.Tasking_Shared_State_Shared_State_Blocker,
            "shared-state dependency blocker should be preserved");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121544)).Status =
            TSS.Tasking_Shared_State_Representation_State_Blocker,
            "representation dependency blocker should be preserved");
      end;
   end Local_And_Dependency_Blockers_Are_Not_Flattened;

   procedure Multiple_Blockers_And_Fingerprints_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TSS.Tasking_Shared_State_Context_Model;
      Multiple : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (1, TSS.Tasking_Shared_State_Abortable_Finalization, Editor.Ada_Syntax_Tree.Node_Id (121561));
      Fingerprint_Mismatch : TSS.Tasking_Shared_State_Context_Info :=
        Complete_Context (2, TSS.Tasking_Shared_State_Task_Termination, Editor.Ada_Syntax_Tree.Node_Id (121562));
   begin
      Multiple.Abort_Finalization_Shared_State_Error := True;
      Multiple.Task_Termination_Shared_State_Error := True;
      Fingerprint_Mismatch.Expected_Source_Fingerprint := 999_999;

      TSS.Add_Context (Contexts, Multiple);
      TSS.Add_Context (Contexts, Fingerprint_Mismatch);

      declare
         Model : constant TSS.Tasking_Shared_State_Model := TSS.Build (Contexts);
      begin
         Assert (TSS.Error_Count (Model) = 2, "two errors expected");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121561)).Status =
            TSS.Tasking_Shared_State_Multiple_Blockers,
            "multiple local blockers should not be flattened");
         Assert
           (TSS.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (121562)).Status =
            TSS.Tasking_Shared_State_Source_Fingerprint_Mismatch,
            "source fingerprint mismatch should be preserved");
         Assert (TSS.Fingerprint (Model) /= 0, "fingerprint should be stable and nonzero");
      end;
   end Multiple_Blockers_And_Fingerprints_Are_Stable;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Tasking_Rows_Require_Shared_State_Evidence'Access,
         "accepted tasking rows require shared-state evidence");
      Register_Routine
        (T,
         Missing_Prerequisites_Are_Preserved'Access,
         "missing prerequisites are preserved");
      Register_Routine
        (T,
         Local_And_Dependency_Blockers_Are_Not_Flattened'Access,
         "local and dependency blockers are not flattened");
      Register_Routine
        (T,
         Multiple_Blockers_And_Fingerprints_Are_Stable'Access,
         "multiple blockers and fingerprints are stable");
   end Register_Tests;

end Test_Ada_Tasking_Shared_State_Final_Legality_Pass1215;
