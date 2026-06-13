with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Remaining_RM_Edge_Precision_Legality_Pass1277 is

   package R renames Editor.Ada_Remaining_RM_Edge_Precision_Legality;
   use type R.Remaining_RM_Edge_Precision_Id;
   use type R.Remaining_RM_Edge_Kind;
   use type R.Remaining_RM_Edge_Blocker_Family;
   use type R.Remaining_RM_Edge_Status;
   use type R.Remaining_RM_Edge_Context;
   use type R.Remaining_RM_Edge_Row;
   use type R.Remaining_RM_Edge_Context_Model;
   use type R.Remaining_RM_Edge_Model;
   use type R.Remaining_RM_Edge_Set;
   package App renames R.Application;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada remaining RM edge precision legality pass1277");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Remaining_RM_Edge_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Remaining_RM_Edge_Context is
      Result : R.Remaining_RM_Edge_Context;
   begin
      Result.Id := R.Remaining_RM_Edge_Precision_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Application_Row := App.RM_Closure_Consumer_Application_Id (Id);
      Result.Application_Status := App.RM_Closure_Consumer_Application_Current_Accepted;
      Result.Source_Fingerprint := 12_770 * Id;
      Result.Expected_Source_Fingerprint := 12_770 * Id;
      Result.Substitution_Fingerprint := 7_721 * Id;
      Result.Expected_Substitution_Fingerprint := 7_721 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Remaining_RM_Edge_Model is
      Contexts : R.Remaining_RM_Edge_Context_Model;
      Dispatching : R.Remaining_RM_Edge_Context :=
        Complete_Context (1, R.Remaining_RM_Edge_Dispatching_Abstract_State_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (127701));
      Renamed : R.Remaining_RM_Edge_Context :=
        Complete_Context (2, R.Remaining_RM_Edge_Renamed_Primitive,
                          Editor.Ada_Syntax_Tree.Node_Id (127702));
      Access_Profile : R.Remaining_RM_Edge_Context :=
        Complete_Context (3, R.Remaining_RM_Edge_Access_Subprogram_Effect_Profile,
                          Editor.Ada_Syntax_Tree.Node_Id (127703));
      Volatile_Rep : R.Remaining_RM_Edge_Context :=
        Complete_Context (4, R.Remaining_RM_Edge_Volatile_Atomic_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (127704));
      Requeue_Path : R.Remaining_RM_Edge_Context :=
        Complete_Context (5, R.Remaining_RM_Edge_Requeue_Select_Path,
                          Editor.Ada_Syntax_Tree.Node_Id (127705));
      App_Blocker : R.Remaining_RM_Edge_Context :=
        Complete_Context (6, R.Remaining_RM_Edge_Generic_Formal_Subprogram_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (127706));
      Fingerprint_Blocker : R.Remaining_RM_Edge_Context :=
        Complete_Context (7, R.Remaining_RM_Edge_Universal_Numeric_Stateful_Expected_Context,
                          Editor.Ada_Syntax_Tree.Node_Id (127707));
      Local_Blocker : R.Remaining_RM_Edge_Context :=
        Complete_Context (8, R.Remaining_RM_Edge_Protected_Action_Reentrancy,
                          Editor.Ada_Syntax_Tree.Node_Id (127708));
      Multiple_Blocker : R.Remaining_RM_Edge_Context :=
        Complete_Context (9, R.Remaining_RM_Edge_Controlled_Finalized_Discriminant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (127709));
      Missing_App : R.Remaining_RM_Edge_Context :=
        Complete_Context (10, R.Remaining_RM_Edge_Entry_Family_Queue,
                          Editor.Ada_Syntax_Tree.Node_Id (127710));
   begin
      App_Blocker.Application_Status := App.RM_Closure_Consumer_Application_Withheld_Cross_Unit;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;
      Local_Blocker.Protected_Reentrancy_Mismatch := True;
      Multiple_Blocker.Controlled_Discriminant_Mismatch := True;
      Multiple_Blocker.Abort_Finalization_Mismatch := True;
      Missing_App.Application_Row := App.No_RM_Closure_Consumer_Application;

      R.Add_Context (Contexts, Dispatching);
      R.Add_Context (Contexts, Renamed);
      R.Add_Context (Contexts, Access_Profile);
      R.Add_Context (Contexts, Volatile_Rep);
      R.Add_Context (Contexts, Requeue_Path);
      R.Add_Context (Contexts, App_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      R.Add_Context (Contexts, Local_Blocker);
      R.Add_Context (Contexts, Multiple_Blocker);
      R.Add_Context (Contexts, Missing_App);
      return R.Build (Contexts);
   end Build_Model;

   procedure Accepts_Remaining_RM_Edges_When_Applied_Consumer_Evidence_Agrees
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Remaining_RM_Edge_Model := Build_Model;
   begin
      Assert (R.Count (Model) = 10, "ten remaining RM edge rows expected");
      Assert (R.Accepted_Count (Model) = 5, "five hard RM edge rows should be accepted");
      Assert
        (R.Count_By_Status
           (Model, R.Remaining_RM_Edge_Legal_Dispatching_Abstract_State_Effect) = 1,
         "dispatching abstract-state effects should be accepted when evidence agrees");
      Assert
        (R.Count_By_Status
           (Model, R.Remaining_RM_Edge_Legal_Renamed_Primitive) = 1,
         "renamed primitive edge should be accepted when visibility evidence agrees");
      Assert
        (R.Count_By_Status
           (Model, R.Remaining_RM_Edge_Legal_Volatile_Atomic_Representation_Clause) = 1,
         "volatile/atomic representation edge should be accepted when evidence agrees");
      Assert (not R.Row_At (Model, 1).Blocks_Downstream,
              "accepted remaining RM edge must not block downstream consumers");
   end Accepts_Remaining_RM_Edges_When_Applied_Consumer_Evidence_Agrees;

   procedure Preserves_Blocker_Families_For_Remaining_RM_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Remaining_RM_Edge_Model := Build_Model;
   begin
      Assert (R.Blocked_Count (Model) = 5, "five blocker rows expected");
      Assert
        (R.Count_By_Blocker_Family
           (Model, R.Remaining_RM_Edge_Blocker_RM_Completion_Consumer_Application) = 2,
         "application boundary blockers should remain distinct");
      Assert
        (R.Count_By_Blocker_Family
           (Model, R.Remaining_RM_Edge_Blocker_Source_Fingerprint) = 1,
         "source fingerprint blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family
           (Model, R.Remaining_RM_Edge_Blocker_Protected_Reentrancy) = 1,
         "protected reentrancy blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family
           (Model, R.Remaining_RM_Edge_Blocker_Multiple) = 1,
         "multiple RM edge blockers should remain explicit");
   end Preserves_Blocker_Families_For_Remaining_RM_Edges;

   procedure Provides_Deterministic_Lookups_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Remaining_RM_Edge_Model := Build_Model;
      Node_Set : constant R.Remaining_RM_Edge_Set :=
        R.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (127705));
      Fingerprint_Set : constant R.Remaining_RM_Edge_Set :=
        R.Find_By_Source_Fingerprint (Model, 12_770 * 4);
   begin
      Assert (R.Query_Count (Node_Set) = 1, "node lookup should find one requeue/select row");
      Assert
        (R.Query_At (Node_Set, 1).Status = R.Remaining_RM_Edge_Legal_Requeue_Select_Path,
         "node lookup should preserve requeue/select accepted status");
      Assert (R.Query_Count (Fingerprint_Set) = 1, "fingerprint lookup should find one row");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "remaining RM edge model fingerprint should be deterministic and non-zero");
      Assert (R.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Remaining_RM_Edges_When_Applied_Consumer_Evidence_Agrees'Access,
         "accepts remaining hard Ada RM edges when applied consumer evidence agrees");
      Register_Routine
        (T, Preserves_Blocker_Families_For_Remaining_RM_Edges'Access,
         "preserves blocker families for remaining RM edge precision");
      Register_Routine
        (T, Provides_Deterministic_Lookups_And_Fingerprint'Access,
         "provides deterministic lookup and fingerprinting for remaining RM edge precision");
   end Register_Tests;

end Test_Ada_Remaining_RM_Edge_Precision_Legality_Pass1277;
