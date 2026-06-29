with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality is

   package O renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   use type O.Overload_Generic_RM_Edge_Completion_Id;
   use type O.Overload_Generic_RM_Edge_Kind;
   use type O.Overload_Generic_RM_Edge_Blocker_Family;
   use type O.Overload_Generic_RM_Edge_Status;
   use type O.Overload_Generic_RM_Edge_Context;
   use type O.Overload_Generic_RM_Edge_Row;
   use type O.Overload_Generic_RM_Edge_Context_Model;
   use type O.Overload_Generic_RM_Edge_Model;
   use type O.Overload_Generic_RM_Edge_Set;
   package Prev renames O.Previous;
   package Closure renames O.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada overload generic shared-state RM edge completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : O.Overload_Generic_RM_Edge_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return O.Overload_Generic_RM_Edge_Context is
      Result : O.Overload_Generic_RM_Edge_Context;
   begin
      Result.Id := O.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.Previous_Overload_Row := Prev.Overload_Generic_Final_Row_Id (Id);
      Result.Previous_Overload_Status := Prev.Overload_Generic_Final_Legal_Renamed_Primitive_Accepted;
      Result.Stabilized_Closure_Row := Closure.Generic_Shared_State_Final_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1246 * Id;
      Result.Expected_Source_Fingerprint := 1246 * Id;
      Result.Substitution_Fingerprint := 6421 * Id;
      Result.Expected_Substitution_Fingerprint := 6421 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return O.Overload_Generic_RM_Edge_Model is
      Contexts : O.Overload_Generic_RM_Edge_Context_Model;
      Renamed : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (1, O.Overload_Generic_RM_Edge_Renamed_Primitive,
                          Editor.Ada_Syntax_Tree.Node_Id (124601));
      Inherited : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (2, O.Overload_Generic_RM_Edge_Inherited_Private_Extension_Primitive,
                          Editor.Ada_Syntax_Tree.Node_Id (124602));
      Dispatching : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (3, O.Overload_Generic_RM_Edge_Dispatching_Abstract_State_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124603));
      Access_Profile : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (4, O.Overload_Generic_RM_Edge_Access_Subprogram_Effect_Profile,
                          Editor.Ada_Syntax_Tree.Node_Id (124604));
      Universal : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (5, O.Overload_Generic_RM_Edge_Universal_Numeric_Expected_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124605));
      Previous_Blocker : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (6, O.Overload_Generic_RM_Edge_Prefixed_Call_Side_Effect_Contract,
                          Editor.Ada_Syntax_Tree.Node_Id (124606));
      Closure_Blocker : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (7, O.Overload_Generic_RM_Edge_Class_Wide_Controlling_Result_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124607));
      Fingerprint_Blocker : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (8, O.Overload_Generic_RM_Edge_Generic_Formal_Subprogram_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124608));
      Local_Blocker : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (9, O.Overload_Generic_RM_Edge_Renamed_Primitive,
                          Editor.Ada_Syntax_Tree.Node_Id (124609));
      Multiple_Blocker : O.Overload_Generic_RM_Edge_Context :=
        Complete_Context (10, O.Overload_Generic_RM_Edge_Access_Subprogram_Effect_Profile,
                          Editor.Ada_Syntax_Tree.Node_Id (124610));
   begin
      Previous_Blocker.Previous_Overload_Status := Prev.Overload_Generic_Final_Overload_Blocker;
      Closure_Blocker.Stabilized_Closure_Status :=
        Closure.Generic_Shared_State_Final_Stabilized_Closure_Blocker_Abstract_Or_Shared_State;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;
      Local_Blocker.Renamed_Primitive_Visibility_Mismatch := True;
      Multiple_Blocker.Access_Profile_Effect_Mismatch := True;
      Multiple_Blocker.Class_Wide_Result_State_Mismatch := True;

      O.Add_Context (Contexts, Renamed);
      O.Add_Context (Contexts, Inherited);
      O.Add_Context (Contexts, Dispatching);
      O.Add_Context (Contexts, Access_Profile);
      O.Add_Context (Contexts, Universal);
      O.Add_Context (Contexts, Previous_Blocker);
      O.Add_Context (Contexts, Closure_Blocker);
      O.Add_Context (Contexts, Fingerprint_Blocker);
      O.Add_Context (Contexts, Local_Blocker);
      O.Add_Context (Contexts, Multiple_Blocker);
      return O.Build (Contexts);
   end Build_Model;

   procedure Completion_Accepts_Hard_RM_Edges_When_Final_Evidence_Agrees
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_Generic_RM_Edge_Model := Build_Model;
   begin
      Assert (O.Count (Model) = 10, "ten RM edge completion rows expected");
      Assert (O.Accepted_Count (Model) = 5, "five accepted overload/type RM edges expected");
      Assert
        (O.Count_By_Status
           (Model, O.Overload_Generic_RM_Edge_Legal_Renamed_Primitive_Accepted) = 1,
         "renamed primitive visibility edge should be accepted when evidence agrees");
      Assert
        (O.Count_By_Status
           (Model, O.Overload_Generic_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Accepted) = 1,
         "inherited/private-extension primitive edge should be accepted when evidence agrees");
      Assert
        (O.Count_By_Status
           (Model, O.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted) = 1,
         "dispatching abstract-state edge should be accepted when evidence agrees");
      Assert (not O.Row_At (Model, 1).Blocks_Downstream, "accepted edge must not block downstream consumers");
   end Completion_Accepts_Hard_RM_Edges_When_Final_Evidence_Agrees;

   procedure Completion_Preserves_Previous_And_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_Generic_RM_Edge_Model := Build_Model;
   begin
      Assert (O.Blocked_Count (Model) = 5, "five blocker rows expected");
      Assert
        (O.Count_By_Blocker_Family (Model, O.Overload_Generic_RM_Edge_Blocker_Previous_Overload) = 1,
         "previous overload blocker should remain distinct");
      Assert
        (O.Count_By_Blocker_Family (Model, O.Overload_Generic_RM_Edge_Blocker_Stabilized_Closure) = 1,
         "stabilized closure blocker should remain distinct");
      Assert
        (O.Count_By_Blocker_Family (Model, O.Overload_Generic_RM_Edge_Blocker_Source_Fingerprint) = 1,
         "source fingerprint blocker should remain distinct");
      Assert
        (O.Count_By_Blocker_Family (Model, O.Overload_Generic_RM_Edge_Blocker_Renaming_Visibility) = 1,
         "renaming visibility blocker should remain distinct");
      Assert
        (O.Count_By_Blocker_Family (Model, O.Overload_Generic_RM_Edge_Blocker_Multiple) = 1,
         "multiple overload/type RM edge blockers should remain explicit");
   end Completion_Preserves_Previous_And_Closure_Blockers;

   procedure Completion_Provides_Deterministic_Lookups_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_Generic_RM_Edge_Model := Build_Model;
      Node_Set : constant O.Overload_Generic_RM_Edge_Set :=
        O.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (124603));
      Fingerprint_Set : constant O.Overload_Generic_RM_Edge_Set :=
        O.Find_By_Source_Fingerprint (Model, 1246 * 4);
   begin
      Assert (O.Query_Count (Node_Set) = 1, "node lookup should find the dispatching row");
      Assert
        (O.Query_At (Node_Set, 1).Status =
         O.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted,
         "node lookup should preserve accepted dispatching status");
      Assert (O.Query_Count (Fingerprint_Set) = 1, "fingerprint lookup should find one row");
      Assert (O.Stable_Fingerprint (Model) /= 0, "model fingerprint should be deterministic and non-zero");
      Assert (O.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Completion_Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Completion_Accepts_Hard_RM_Edges_When_Final_Evidence_Agrees'Access,
         "accepts hard overload/type RM edges when final generic/shared-state evidence agrees");
      Register_Routine
        (T, Completion_Preserves_Previous_And_Closure_Blockers'Access,
         "preserves previous overload and stabilized closure blocker families");
      Register_Routine
        (T, Completion_Provides_Deterministic_Lookups_And_Fingerprint'Access,
         "provides deterministic lookup and fingerprinting for completed RM edges");
   end Register_Tests;

end Test_Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
