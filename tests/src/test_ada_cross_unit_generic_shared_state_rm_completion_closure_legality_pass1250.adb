with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality_Pass1250 is

   package T renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   use type T.Cross_Unit_RM_Completion_Closure_Id;
   use type T.Cross_Unit_RM_Completion_Kind;
   use type T.Cross_Unit_RM_Dependency_State;
   use type T.Cross_Unit_RM_Completion_Blocker_Family;
   use type T.Cross_Unit_RM_Completion_Status;
   use type T.Cross_Unit_RM_Completion_Context;
   use type T.Cross_Unit_RM_Completion_Row;
   use type T.Cross_Unit_RM_Completion_Context_Model;
   use type T.Cross_Unit_RM_Completion_Model;
   use type T.Cross_Unit_RM_Completion_Set;
   package Prior renames T.Prior_Cross;
   package Stable renames T.Stabilized;
   package Overload renames T.Overload_RM;
   package Rep renames T.Representation_RM;
   package Tasking renames T.Tasking_RM;
   package Repair renames T.AST_Repair;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada cross-unit generic/shared-state RM completion closure legality pass1250");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : T.Cross_Unit_RM_Completion_Kind;
      Dep  : T.Cross_Unit_RM_Dependency_State;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return T.Cross_Unit_RM_Completion_Context is
      Result : T.Cross_Unit_RM_Completion_Context;
   begin
      Result.Id := T.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Kind := Kind;
      Result.Dependency := Dep;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Dependency_Name := To_Unbounded_String ("Dep" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Prior_Cross_Row := Prior.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Prior_Cross_Status := Prior.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Stabilized_Row := Stable.Generic_Shared_State_Final_Stabilized_Closure_Id (Id);
      Result.Stabilized_Status := Stable.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Result.Overload_RM_Row := Overload.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Representation_RM_Row := Rep.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Rep.Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted;
      Result.Tasking_RM_Row := Tasking.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking.Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted;
      Result.AST_Repair_Row := Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := Repair.Coverage_Proven_AST_Repair_Not_Required;
      Result.Source_Fingerprint := 1250 * Id;
      Result.Expected_Source_Fingerprint := 1250 * Id;
      Result.Substitution_Fingerprint := 2500 * Id;
      Result.Expected_Substitution_Fingerprint := 2500 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return T.Cross_Unit_RM_Completion_Model is
      Contexts : T.Cross_Unit_RM_Completion_Context_Model;
      Local_Row : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (1, T.Cross_Unit_RM_Completion_Local, T.RM_Dependency_Local,
                          Editor.Ada_Syntax_Tree.Node_Id (125001));
      Body_Row : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (2, T.Cross_Unit_RM_Completion_Spec_Body, T.RM_Dependency_Spec_Body_Closed,
                          Editor.Ada_Syntax_Tree.Node_Id (125002));
      Instance_Row : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (3, T.Cross_Unit_RM_Completion_Generic_Instance, T.RM_Dependency_Generic_Instance_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125003));
      AST_Row : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (4, T.Cross_Unit_RM_Completion_AST_Repair, T.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125004));
      Dependency_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (5, T.Cross_Unit_RM_Completion_With_Use, T.RM_Dependency_Missing,
                          Editor.Ada_Syntax_Tree.Node_Id (125005));
      Prior_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (6, T.Cross_Unit_RM_Completion_Generic_Body, T.RM_Dependency_Generic_Body_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125006));
      Overload_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (7, T.Cross_Unit_RM_Completion_Overload_Type, T.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125007));
      Representation_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (8, T.Cross_Unit_RM_Completion_Representation, T.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125008));
      Tasking_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (9, T.Cross_Unit_RM_Completion_Tasking_Protected, T.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125009));
      Repair_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (10, T.Cross_Unit_RM_Completion_AST_Repair, T.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125010));
      Multiple_Blocker : T.Cross_Unit_RM_Completion_Context :=
        Complete_Context (11, T.Cross_Unit_RM_Completion_Private_Child, T.RM_Dependency_Private_Child_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (125011));
   begin
      AST_Row.Requires_AST_Repair := True;
      AST_Row.AST_Repair_Status := Repair.Coverage_Proven_AST_Repair_Parser_Node_Repaired;

      Prior_Blocker.Prior_Cross_Status := Prior.Cross_Unit_Generic_Final_Generic_Backmapping_Blocker;
      Overload_Blocker.Overload_RM_Status := Overload.Overload_Generic_RM_Edge_Renamed_Primitive_Visibility_Mismatch;
      Representation_Blocker.Representation_RM_Status := Rep.Representation_Generic_RM_Hard_Case_Generic_Freezing_Blocker;
      Tasking_Blocker.Tasking_RM_Status := Tasking.Tasking_Generic_RM_Hard_Case_Requeue_Select_Path_Blocker;
      Repair_Blocker.Requires_AST_Repair := True;
      Repair_Blocker.AST_Repair_Status := Repair.Coverage_Proven_AST_Repair_Token_Only_Parse_Still_Present;
      Multiple_Blocker.Private_View_Barrier := True;
      Multiple_Blocker.Source_Fingerprint := 9;
      Multiple_Blocker.Expected_Source_Fingerprint := 10;

      T.Add_Context (Contexts, Local_Row);
      T.Add_Context (Contexts, Body_Row);
      T.Add_Context (Contexts, Instance_Row);
      T.Add_Context (Contexts, AST_Row);
      T.Add_Context (Contexts, Dependency_Blocker);
      T.Add_Context (Contexts, Prior_Blocker);
      T.Add_Context (Contexts, Overload_Blocker);
      T.Add_Context (Contexts, Representation_Blocker);
      T.Add_Context (Contexts, Tasking_Blocker);
      T.Add_Context (Contexts, Repair_Blocker);
      T.Add_Context (Contexts, Multiple_Blocker);
      return T.Build (Contexts);
   end Build_Model;

   procedure Completion_Closure_Accepts_Only_When_All_Cross_Unit_RM_Evidence_Agrees
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Cross_Unit_RM_Completion_Model := Build_Model;
   begin
      Assert (T.Count (Model) = 11, "eleven RM completion closure rows expected");
      Assert (T.Accepted_Count (Model) = 4, "four cross-unit RM completion rows should be accepted");
      Assert (T.Count_By_Status (Model, T.Cross_Unit_RM_Completion_Legal_Local_Accepted) = 1,
              "local completed RM evidence should be accepted");
      Assert (T.Count_By_Status (Model, T.Cross_Unit_RM_Completion_Legal_AST_Repair_Accepted) = 1,
              "coverage-proven AST repair should be accepted only as completed evidence");
   end Completion_Closure_Accepts_Only_When_All_Cross_Unit_RM_Evidence_Agrees;

   procedure Completion_Closure_Preserves_Blocker_Families
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Cross_Unit_RM_Completion_Model := Build_Model;
   begin
      Assert (T.Blocked_Count (Model) = 7, "seven blocked completion closure rows expected");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Dependency) = 1,
              "dependency blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Prior_Cross_Unit_Generic_Shared_State) = 1,
              "prior cross-unit generic/shared-state blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Overload_RM_Completion) = 1,
              "overload RM completion blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Representation_RM_Completion) = 1,
              "representation RM completion blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Tasking_RM_Completion) = 1,
              "tasking RM completion blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_AST_Repair) = 1,
              "coverage-proven AST repair blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Cross_Unit_RM_Completion_Blocker_Multiple) = 1,
              "multiple cross-unit RM blockers should remain explicit");
   end Completion_Closure_Preserves_Blocker_Families;

   procedure Completion_Closure_Provides_Deterministic_Lookups_And_Fingerprint
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Cross_Unit_RM_Completion_Model := Build_Model;
      Node_Set : constant T.Cross_Unit_RM_Completion_Set :=
        T.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (125004));
      Fingerprint_Set : constant T.Cross_Unit_RM_Completion_Set :=
        T.Find_By_Source_Fingerprint (Model, 1250 * 8);
   begin
      Assert (T.Query_Count (Node_Set) = 1, "node lookup should find the AST repair completion row");
      Assert (T.Query_At (Node_Set, 1).Status = T.Cross_Unit_RM_Completion_Legal_AST_Repair_Accepted,
              "node lookup should preserve accepted AST repair completion status");
      Assert (T.Query_Count (Fingerprint_Set) = 1, "source fingerprint lookup should find one row");
      Assert (T.Stable_Fingerprint (Model) /= 0, "completion closure fingerprint should be deterministic and non-zero");
      Assert (T.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Completion_Closure_Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Completion_Closure_Accepts_Only_When_All_Cross_Unit_RM_Evidence_Agrees'Access,
                        "accepts completed generic/shared-state RM evidence only after cross-unit agreement");
      Register_Routine (T, Completion_Closure_Preserves_Blocker_Families'Access,
                        "preserves dependency and RM completion blocker families");
      Register_Routine (T, Completion_Closure_Provides_Deterministic_Lookups_And_Fingerprint'Access,
                        "provides deterministic lookup and fingerprinting for RM completion closure");
   end Register_Tests;

end Test_Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality_Pass1250;
