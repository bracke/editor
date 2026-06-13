with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality_Pass1268 is

   package R renames Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
   use type R.Cross_Unit_RM_Closure_Consumer_Id;
   use type R.Cross_Unit_RM_Kind;
   use type R.Cross_Unit_RM_Dependency_State;
   use type R.Cross_Unit_RM_Closure_Consumer_Status;
   use type R.Cross_Unit_RM_Closure_Consumer_Family;
   use type R.Cross_Unit_RM_Closure_Consumer_Context;
   use type R.Cross_Unit_RM_Closure_Consumer_Row;
   use type R.Cross_Unit_RM_Closure_Consumer_Context_Model;
   use type R.Cross_Unit_RM_Closure_Consumer_Model;
   use type R.Cross_Unit_RM_Closure_Consumer_Set;
   package Prior renames R.Prior;
   package Closure renames R.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada cross-unit RM-completion closure consumer pass1268");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Cross_Unit_RM_Kind;
      Dep  : R.Cross_Unit_RM_Dependency_State;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Cross_Unit_RM_Closure_Consumer_Context is
      Result : R.Cross_Unit_RM_Closure_Consumer_Context;
   begin
      Result.Id := R.Cross_Unit_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Dependency := Dep;
      Result.Node := Node;
      Result.Unit_Node := Editor.Ada_Syntax_Tree.Node_Id (126_800 + Id);
      Result.Dependency_Node := Editor.Ada_Syntax_Tree.Node_Id (126_900 + Id);
      Result.Cross_Unit_RM_Row := Prior.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_Unit_RM_Status := Prior.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1268 * Id;
      Result.Expected_Source_Fingerprint := 1268 * Id;
      Result.Substitution_Fingerprint := 8621 * Id;
      Result.Expected_Substitution_Fingerprint := 8621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Cross_Unit_RM_Closure_Consumer_Model is
      Contexts : R.Cross_Unit_RM_Closure_Consumer_Context_Model;
      Accepted : R.Cross_Unit_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Cross_Unit_RM_Completion_Generic_Instance,
                          Prior.RM_Dependency_Generic_Instance_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (126801));
      Cross_Blocker : R.Cross_Unit_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Cross_Unit_RM_Completion_Spec_Body,
                          Prior.RM_Dependency_Spec_Body_Closed,
                          Editor.Ada_Syntax_Tree.Node_Id (126802));
      Stabilized_Representation_Blocker : R.Cross_Unit_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Cross_Unit_RM_Completion_Representation,
                          Prior.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (126803));
      Private_Child_Blocker : R.Cross_Unit_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Cross_Unit_RM_Completion_Private_Child,
                          Prior.RM_Dependency_Private_Child_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (126804));
      Fingerprint_Blocker : R.Cross_Unit_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Cross_Unit_RM_Completion_With_Use,
                          Prior.RM_Dependency_With_Visible,
                          Editor.Ada_Syntax_Tree.Node_Id (126805));
   begin
      Cross_Blocker.Cross_Unit_RM_Status := Prior.Cross_Unit_RM_Completion_Generic_Backmapping_Blocker;
      Stabilized_Representation_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Representation;
      Private_Child_Blocker.Private_Child_Visibility_Blocker := True;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Accepted);
      R.Add_Context (Contexts, Cross_Blocker);
      R.Add_Context (Contexts, Stabilized_Representation_Blocker);
      R.Add_Context (Contexts, Private_Child_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_Cross_Unit_And_Closure_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Cross_Unit_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant R.Cross_Unit_RM_Closure_Consumer_Row := R.Row_At (Model, 1);
   begin
      Assert (R.Count (Model) = 5, "five cross-unit RM closure consumer rows expected");
      Assert (R.Accepted_Count (Model) = 1, "only agreed cross-unit/closure row should be accepted");
      Assert (R.Blocked_Count (Model) = 4, "four prerequisite blockers should be preserved");
      Assert (Row.Status = R.Cross_Unit_RM_Closure_Consumer_Accepted,
              "accepted row should consume stabilized RM-completion closure evidence");
   end Consumer_Accepts_Only_When_Cross_Unit_And_Closure_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Cross_Unit_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (R.Count_By_Family (Model, R.Cross_Unit_RM_Closure_Consumer_Family_Cross_Unit_RM) = 1,
              "prior cross-unit RM blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Cross_Unit_RM_Closure_Consumer_Family_Representation) = 1,
              "stabilized representation blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Cross_Unit_RM_Closure_Consumer_Family_Private_Child) = 1,
              "private-child visibility blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Cross_Unit_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Cross_Unit_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126805);
      Unit  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126_805);
   begin
      Assert (R.Query_Count (R.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Unit (Model, Unit)) = 1,
              "unit lookup should find the source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Source_Fingerprint (Model, 1268 * 5)) = 1,
              "source fingerprint lookup should find the source fingerprint blocker");
      Assert (R.Count_By_Status (Model, R.Cross_Unit_RM_Closure_Consumer_Closure_Representation) = 1,
              "status query should preserve representation blocker identity");
      Assert (R.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "cross-unit RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_Cross_Unit_And_Closure_Agree'Access,
         "cross-unit RM closure consumer accepts only agreed evidence");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "cross-unit RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "cross-unit RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality_Pass1268;
