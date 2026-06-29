with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package body Test_Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   package T renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   use type T.Tasking_Generic_RM_Hard_Case_Id;
   use type T.Tasking_Generic_RM_Hard_Case_Kind;
   use type T.Tasking_Generic_RM_Hard_Case_Blocker_Family;
   use type T.Tasking_Generic_RM_Hard_Case_Status;
   use type T.Tasking_Generic_RM_Hard_Case_Context;
   use type T.Tasking_Generic_RM_Hard_Case_Row;
   use type T.Tasking_Generic_RM_Hard_Case_Context_Model;
   use type T.Tasking_Generic_RM_Hard_Case_Model;
   use type T.Tasking_Generic_RM_Hard_Case_Set;
   package Prev renames T.Previous;
   package Rep renames T.Representation_Hard_Cases;
   package Edges renames T.Overload_Edges;
   package Closure renames T.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada tasking generic shared-state RM hard-case completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : T.Tasking_Generic_RM_Hard_Case_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return T.Tasking_Generic_RM_Hard_Case_Context is
      Result : T.Tasking_Generic_RM_Hard_Case_Context;
   begin
      Result.Id := T.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.Previous_Tasking_Row := Prev.Tasking_Generic_Final_Row_Id (Id);
      Result.Previous_Tasking_Status := Prev.Tasking_Generic_Final_Legal_Protected_Action_Accepted;
      Result.Representation_RM_Hard_Case_Row := Rep.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Hard_Case_Status := Rep.Representation_Generic_RM_Hard_Case_Legal_Protected_Task_Representation_Effect_Accepted;
      Result.Overload_RM_Edge_Row := Edges.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Stabilized_Closure_Row := Closure.Generic_Shared_State_Final_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1248 * Id;
      Result.Expected_Source_Fingerprint := 1248 * Id;
      Result.Substitution_Fingerprint := 8421 * Id;
      Result.Expected_Substitution_Fingerprint := 8421 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return T.Tasking_Generic_RM_Hard_Case_Model is
      Contexts : T.Tasking_Generic_RM_Hard_Case_Context_Model;
      Protected_Action : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (1, T.Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy,
                          Editor.Ada_Syntax_Tree.Node_Id (124801));
      Callback : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (2, T.Tasking_Generic_RM_Hard_Case_Callback_Reentrancy,
                          Editor.Ada_Syntax_Tree.Node_Id (124802));
      Entry_Queue : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (3, T.Tasking_Generic_RM_Hard_Case_Entry_Family_Queue,
                          Editor.Ada_Syntax_Tree.Node_Id (124803));
      Requeue_Select : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (4, T.Tasking_Generic_RM_Hard_Case_Requeue_Select_Path,
                          Editor.Ada_Syntax_Tree.Node_Id (124804));
      Generic_Body : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (5, T.Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124805));
      Previous_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (6, T.Tasking_Generic_RM_Hard_Case_Accept_Body_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124806));
      Representation_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (7, T.Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering,
                          Editor.Ada_Syntax_Tree.Node_Id (124807));
      Edge_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (8, T.Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering,
                          Editor.Ada_Syntax_Tree.Node_Id (124808));
      Closure_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (9, T.Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (124809));
      Fingerprint_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (10, T.Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124810));
      Local_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (11, T.Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy,
                          Editor.Ada_Syntax_Tree.Node_Id (124811));
      Multiple_Blocker : T.Tasking_Generic_RM_Hard_Case_Context :=
        Complete_Context (12, T.Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124812));
   begin
      Previous_Blocker.Previous_Tasking_Status := Prev.Tasking_Generic_Final_Abort_Finalization_Blocker;
      Representation_Blocker.Representation_RM_Hard_Case_Status := Rep.Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Blocker;
      Edge_Blocker.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch;
      Closure_Blocker.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Blocker_Tasking_Protected;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;
      Local_Blocker.Callback_Reentrancy_Blocker := True;
      Multiple_Blocker.Generic_Task_Protected_Body_Effect_Blocker := True;
      Multiple_Blocker.Abort_Finalization_Ordering_Blocker := True;

      T.Add_Context (Contexts, Protected_Action);
      T.Add_Context (Contexts, Callback);
      T.Add_Context (Contexts, Entry_Queue);
      T.Add_Context (Contexts, Requeue_Select);
      T.Add_Context (Contexts, Generic_Body);
      T.Add_Context (Contexts, Previous_Blocker);
      T.Add_Context (Contexts, Representation_Blocker);
      T.Add_Context (Contexts, Edge_Blocker);
      T.Add_Context (Contexts, Closure_Blocker);
      T.Add_Context (Contexts, Fingerprint_Blocker);
      T.Add_Context (Contexts, Local_Blocker);
      T.Add_Context (Contexts, Multiple_Blocker);
      return T.Build (Contexts);
   end Build_Model;

   procedure Completion_Accepts_Tasking_Hard_Cases_When_Evidence_Agrees
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Tasking_Generic_RM_Hard_Case_Model := Build_Model;
   begin
      Assert (T.Count (Model) = 12, "twelve tasking hard-case rows expected");
      Assert (T.Accepted_Count (Model) = 5, "five accepted tasking hard cases expected");
      Assert
        (T.Count_By_Status
           (Model, T.Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted) = 1,
         "protected-action reentrancy hard case should be accepted when evidence agrees");
      Assert
        (T.Count_By_Status
           (Model, T.Tasking_Generic_RM_Hard_Case_Legal_Callback_Reentrancy_Accepted) = 1,
         "callback reentrancy hard case should be accepted when evidence agrees");
      Assert
        (T.Count_By_Status
           (Model, T.Tasking_Generic_RM_Hard_Case_Legal_Entry_Family_Queue_Accepted) = 1,
         "entry-family queue hard case should be accepted when evidence agrees");
      Assert (not T.Row_At (Model, 1).Blocks_Downstream, "accepted hard case must not block downstream consumers");
   end Completion_Accepts_Tasking_Hard_Cases_When_Evidence_Agrees;

   procedure Completion_Preserves_Prerequisite_And_Local_Blocker_Families
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Tasking_Generic_RM_Hard_Case_Model := Build_Model;
   begin
      Assert (T.Blocked_Count (Model) = 7, "seven blocker rows expected");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Previous_Tasking) = 1,
         "previous tasking blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Representation_RM_Hard_Case) = 1,
         "representation RM hard-case blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge) = 1,
         "overload RM edge blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Stabilized_Closure) = 1,
         "stabilized closure blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Source_Fingerprint) = 1,
         "source fingerprint blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Callback_Reentrancy) = 1,
         "callback reentrancy blocker should remain distinct");
      Assert
        (T.Count_By_Blocker_Family (Model, T.Tasking_Generic_RM_Hard_Case_Blocker_Multiple) = 1,
         "multiple tasking hard-case blockers should remain explicit");
   end Completion_Preserves_Prerequisite_And_Local_Blocker_Families;

   procedure Completion_Provides_Deterministic_Lookups_And_Fingerprint
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Tasking_Generic_RM_Hard_Case_Model := Build_Model;
      Node_Set : constant T.Tasking_Generic_RM_Hard_Case_Set :=
        T.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (124803));
      Fingerprint_Set : constant T.Tasking_Generic_RM_Hard_Case_Set :=
        T.Find_By_Source_Fingerprint (Model, 1248 * 4);
   begin
      Assert (T.Query_Count (Node_Set) = 1, "node lookup should find the entry-family queue row");
      Assert
        (T.Query_At (Node_Set, 1).Status =
         T.Tasking_Generic_RM_Hard_Case_Legal_Entry_Family_Queue_Accepted,
         "node lookup should preserve accepted entry-family queue status");
      Assert (T.Query_Count (Fingerprint_Set) = 1, "fingerprint lookup should find one row");
      Assert (T.Stable_Fingerprint (Model) /= 0, "model fingerprint should be deterministic and non-zero");
      Assert (T.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Completion_Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Completion_Accepts_Tasking_Hard_Cases_When_Evidence_Agrees'Access,
         "accepts tasking/protected hard cases when final generic/shared-state evidence agrees");
      Register_Routine
        (T, Completion_Preserves_Prerequisite_And_Local_Blocker_Families'Access,
         "preserves tasking hard-case prerequisite and local blocker families");
      Register_Routine
        (T, Completion_Provides_Deterministic_Lookups_And_Fingerprint'Access,
         "provides deterministic lookup and fingerprinting for tasking hard-case completion");
   end Register_Tests;

end Test_Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
