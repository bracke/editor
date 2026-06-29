with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Representation_RM_Completion_Closure_Consumer_Legality is

   package R renames Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality;
   use type R.Representation_RM_Closure_Consumer_Id;
   use type R.Representation_RM_Kind;
   use type R.Representation_RM_Closure_Consumer_Status;
   use type R.Representation_RM_Closure_Consumer_Family;
   use type R.Representation_RM_Closure_Consumer_Context;
   use type R.Representation_RM_Closure_Consumer_Row;
   use type R.Representation_RM_Closure_Consumer_Context_Model;
   use type R.Representation_RM_Closure_Consumer_Model;
   use type R.Representation_RM_Closure_Consumer_Set;
   package Prior renames R.Prior;
   package Closure renames R.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada representation RM-completion closure consumer");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Representation_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Representation_RM_Closure_Consumer_Context is
      Result : R.Representation_RM_Closure_Consumer_Context;
   begin
      Result.Id := R.Representation_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Representation_RM_Row := Prior.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Prior.Representation_Generic_RM_Hard_Case_Legal_Volatile_Atomic_Representation_Clause_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
      Result.Source_Fingerprint := 1265 * Id;
      Result.Expected_Source_Fingerprint := 1265 * Id;
      Result.Substitution_Fingerprint := 5621 * Id;
      Result.Expected_Substitution_Fingerprint := 5621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Representation_RM_Closure_Consumer_Model is
      Contexts : R.Representation_RM_Closure_Consumer_Context_Model;
      Accepted : R.Representation_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Representation_Generic_RM_Hard_Case_Volatile_Atomic_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (126501));
      Representation_Blocker_Row : R.Representation_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Representation_Generic_RM_Hard_Case_Independent_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (126502));
      Cross_Blocker : R.Representation_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Representation_Generic_RM_Hard_Case_Limited_Private_Stream_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (126503));
      Closure_Representation_Blocker : R.Representation_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Representation_Generic_RM_Hard_Case_Generic_Formal_Instance_Freezing,
                          Editor.Ada_Syntax_Tree.Node_Id (126504));
      Fingerprint_Blocker : R.Representation_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (126505));
   begin
      Representation_Blocker_Row.Representation_RM_Status := Prior.Representation_Generic_RM_Hard_Case_Volatile_Atomic_Clause_Blocker;
      Cross_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit;
      Closure_Representation_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Accepted);
      R.Add_Context (Contexts, Representation_Blocker_Row);
      R.Add_Context (Contexts, Cross_Blocker);
      R.Add_Context (Contexts, Closure_Representation_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_Closure_And_Representation_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant R.Representation_RM_Closure_Consumer_Row := R.Row_At (Model, 1);
   begin
      Assert (R.Count (Model) = 5, "five representation RM closure consumer rows expected");
      Assert (R.Accepted_Count (Model) = 1, "only agreed representation/closure row should be accepted");
      Assert (R.Blocked_Count (Model) = 4, "four prerequisite blockers should be preserved");
      Assert (Row.Status = R.Representation_RM_Closure_Consumer_Accepted,
              "accepted row should consume stabilized RM-completion closure evidence");
   end Consumer_Accepts_Only_When_Closure_And_Representation_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (R.Count_By_Family (Model, R.Representation_RM_Closure_Consumer_Family_Representation_RM) = 1,
              "prior representation RM blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Representation_RM_Closure_Consumer_Family_Cross_Unit) = 1,
              "cross-unit closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Representation_RM_Closure_Consumer_Family_Representation) = 1,
              "representation closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Representation_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Representation_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126505);
   begin
      Assert (R.Query_Count (R.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Source_Fingerprint (Model, 1265 * 5)) = 1,
              "source fingerprint lookup should find the source fingerprint blocker");
      Assert (R.Count_By_Status (Model, R.Representation_RM_Closure_Consumer_Closure_Cross_Unit) = 1,
              "status query should preserve cross-unit blocker identity");
      Assert (R.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "representation RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_Closure_And_Representation_Agree'Access,
         "representation RM closure consumer accepts only agreed evidence");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "representation RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "representation RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Representation_RM_Completion_Closure_Consumer_Legality;
