with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   package R renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   use type R.Representation_Generic_RM_Hard_Case_Id;
   use type R.Representation_Generic_RM_Hard_Case_Kind;
   use type R.Representation_Generic_RM_Hard_Case_Blocker_Family;
   use type R.Representation_Generic_RM_Hard_Case_Status;
   use type R.Representation_Generic_RM_Hard_Case_Context;
   use type R.Representation_Generic_RM_Hard_Case_Row;
   use type R.Representation_Generic_RM_Hard_Case_Context_Model;
   use type R.Representation_Generic_RM_Hard_Case_Model;
   use type R.Representation_Generic_RM_Hard_Case_Set;
   package Prev renames R.Previous;
   package Edges renames R.Overload_Edges;
   package Closure renames R.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada representation generic shared-state RM hard-case completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Representation_Generic_RM_Hard_Case_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Representation_Generic_RM_Hard_Case_Context is
      Result : R.Representation_Generic_RM_Hard_Case_Context;
   begin
      Result.Id := R.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Representation_Name := To_Unbounded_String ("Rep" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.Previous_Representation_Row := Prev.Representation_Generic_Final_Row_Id (Id);
      Result.Previous_Representation_Status := Prev.Representation_Generic_Final_Legal_Volatile_Atomic_Record_Layout_Accepted;
      Result.Overload_RM_Edge_Row := Edges.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Stabilized_Closure_Row := Closure.Generic_Shared_State_Final_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1247 * Id;
      Result.Expected_Source_Fingerprint := 1247 * Id;
      Result.Substitution_Fingerprint := 7421 * Id;
      Result.Expected_Substitution_Fingerprint := 7421 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Representation_Generic_RM_Hard_Case_Model is
      Contexts : R.Representation_Generic_RM_Hard_Case_Context_Model;
      Volatile_Clause : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (1, R.Representation_Generic_RM_Hard_Case_Volatile_Atomic_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (124701));
      Independent : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (2, R.Representation_Generic_RM_Hard_Case_Independent_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124702));
      Stream_View : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (3, R.Representation_Generic_RM_Hard_Case_Limited_Private_Stream_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (124703));
      Generic_Freezing : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (4, R.Representation_Generic_RM_Hard_Case_Generic_Formal_Instance_Freezing,
                          Editor.Ada_Syntax_Tree.Node_Id (124704));
      Protected_Task : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (5, R.Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124705));
      Previous_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (6, R.Representation_Generic_RM_Hard_Case_Discriminant_Dependent_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (124706));
      Edge_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (7, R.Representation_Generic_RM_Hard_Case_Inherited_Operational_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (124707));
      Closure_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (8, R.Representation_Generic_RM_Hard_Case_Controlled_Finalized_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124708));
      Fingerprint_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (9, R.Representation_Generic_RM_Hard_Case_Independent_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124709));
      Local_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (10, R.Representation_Generic_RM_Hard_Case_Volatile_Atomic_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (124710));
      Multiple_Blocker : R.Representation_Generic_RM_Hard_Case_Context :=
        Complete_Context (11, R.Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (124711));
   begin
      Previous_Blocker.Previous_Representation_Status := Prev.Representation_Generic_Final_Representation_Shared_State_Blocker;
      Edge_Blocker.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Access_Profile_Effect_Mismatch;
      Closure_Blocker.Stabilized_Closure_Status :=
        Closure.Generic_Shared_State_Final_Stabilized_Closure_Blocker_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;
      Local_Blocker.Volatile_Atomic_Clause_Blocker := True;
      Multiple_Blocker.Protected_Task_Representation_Blocker := True;
      Multiple_Blocker.Discriminant_Layout_Blocker := True;

      R.Add_Context (Contexts, Volatile_Clause);
      R.Add_Context (Contexts, Independent);
      R.Add_Context (Contexts, Stream_View);
      R.Add_Context (Contexts, Generic_Freezing);
      R.Add_Context (Contexts, Protected_Task);
      R.Add_Context (Contexts, Previous_Blocker);
      R.Add_Context (Contexts, Edge_Blocker);
      R.Add_Context (Contexts, Closure_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      R.Add_Context (Contexts, Local_Blocker);
      R.Add_Context (Contexts, Multiple_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Completion_Accepts_Representation_Hard_Cases_When_Evidence_Agrees
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_Generic_RM_Hard_Case_Model := Build_Model;
   begin
      Assert (R.Count (Model) = 11, "eleven representation hard-case rows expected");
      Assert (R.Accepted_Count (Model) = 5, "five accepted representation hard cases expected");
      Assert
        (R.Count_By_Status
           (Model, R.Representation_Generic_RM_Hard_Case_Legal_Volatile_Atomic_Representation_Clause_Accepted) = 1,
         "volatile/atomic representation-clause hard case should be accepted when evidence agrees");
      Assert
        (R.Count_By_Status
           (Model, R.Representation_Generic_RM_Hard_Case_Legal_Independent_Component_Accepted) = 1,
         "independent component hard case should be accepted when evidence agrees");
      Assert
        (R.Count_By_Status
           (Model, R.Representation_Generic_RM_Hard_Case_Legal_Limited_Private_Stream_Attribute_Accepted) = 1,
         "limited/private stream attribute hard case should be accepted when evidence agrees");
      Assert (not R.Row_At (Model, 1).Blocks_Downstream, "accepted hard case must not block downstream consumers");
   end Completion_Accepts_Representation_Hard_Cases_When_Evidence_Agrees;

   procedure Completion_Preserves_Prerequisite_And_Local_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_Generic_RM_Hard_Case_Model := Build_Model;
   begin
      Assert (R.Blocked_Count (Model) = 6, "six blocker rows expected");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Previous_Representation) = 1,
         "previous representation blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge) = 1,
         "overload RM edge blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Stabilized_Closure) = 1,
         "stabilized closure blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Source_Fingerprint) = 1,
         "source fingerprint blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Volatile_Atomic_Clause) = 1,
         "volatile/atomic clause blocker should remain distinct");
      Assert
        (R.Count_By_Blocker_Family (Model, R.Representation_Generic_RM_Hard_Case_Blocker_Multiple) = 1,
         "multiple representation hard-case blockers should remain explicit");
   end Completion_Preserves_Prerequisite_And_Local_Blocker_Families;

   procedure Completion_Provides_Deterministic_Lookups_And_Fingerprint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_Generic_RM_Hard_Case_Model := Build_Model;
      Node_Set : constant R.Representation_Generic_RM_Hard_Case_Set :=
        R.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (124703));
      Fingerprint_Set : constant R.Representation_Generic_RM_Hard_Case_Set :=
        R.Find_By_Source_Fingerprint (Model, 1247 * 4);
   begin
      Assert (R.Query_Count (Node_Set) = 1, "node lookup should find the stream view row");
      Assert
        (R.Query_At (Node_Set, 1).Status =
         R.Representation_Generic_RM_Hard_Case_Legal_Limited_Private_Stream_Attribute_Accepted,
         "node lookup should preserve accepted limited/private stream status");
      Assert (R.Query_Count (Fingerprint_Set) = 1, "fingerprint lookup should find one row");
      Assert (R.Stable_Fingerprint (Model) /= 0, "model fingerprint should be deterministic and non-zero");
      Assert (R.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Completion_Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Completion_Accepts_Representation_Hard_Cases_When_Evidence_Agrees'Access,
         "accepts representation/freezing hard cases when final generic/shared-state evidence agrees");
      Register_Routine
        (T, Completion_Preserves_Prerequisite_And_Local_Blocker_Families'Access,
         "preserves representation hard-case prerequisite and local blocker families");
      Register_Routine
        (T, Completion_Provides_Deterministic_Lookups_And_Fingerprint'Access,
         "provides deterministic lookup and fingerprinting for representation hard-case completion");
   end Register_Tests;

end Test_Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
