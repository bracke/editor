with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Tasking_RM_Completion_Closure_Consumer_Legality_Pass1266 is

   package R renames Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;
   use type R.Tasking_RM_Closure_Consumer_Id;
   use type R.Tasking_RM_Kind;
   use type R.Tasking_RM_Closure_Consumer_Status;
   use type R.Tasking_RM_Closure_Consumer_Family;
   use type R.Tasking_RM_Closure_Consumer_Context;
   use type R.Tasking_RM_Closure_Consumer_Row;
   use type R.Tasking_RM_Closure_Consumer_Context_Model;
   use type R.Tasking_RM_Closure_Consumer_Model;
   use type R.Tasking_RM_Closure_Consumer_Set;
   package Prior renames R.Prior;
   package Closure renames R.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada tasking/protected RM-completion closure consumer pass1266");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Tasking_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Tasking_RM_Closure_Consumer_Context is
      Result : R.Tasking_RM_Closure_Consumer_Context;
   begin
      Result.Id := R.Tasking_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Tasking_RM_Row := Prior.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Prior.Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
      Result.Source_Fingerprint := 1266 * Id;
      Result.Expected_Source_Fingerprint := 1266 * Id;
      Result.Substitution_Fingerprint := 6621 * Id;
      Result.Expected_Substitution_Fingerprint := 6621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Tasking_RM_Closure_Consumer_Model is
      Contexts : R.Tasking_RM_Closure_Consumer_Context_Model;
      Accepted : R.Tasking_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy,
                          Editor.Ada_Syntax_Tree.Node_Id (126601));
      Tasking_Blocker_Row : R.Tasking_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Tasking_Generic_RM_Hard_Case_Entry_Family_Queue,
                          Editor.Ada_Syntax_Tree.Node_Id (126602));
      Cross_Blocker : R.Tasking_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Tasking_Generic_RM_Hard_Case_Requeue_Select_Path,
                          Editor.Ada_Syntax_Tree.Node_Id (126603));
      Closure_Tasking_Blocker : R.Tasking_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering,
                          Editor.Ada_Syntax_Tree.Node_Id (126604));
      Fingerprint_Blocker : R.Tasking_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (126605));
   begin
      Tasking_Blocker_Row.Tasking_RM_Status := Prior.Tasking_Generic_RM_Hard_Case_Entry_Family_Queue_Blocker;
      Cross_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit;
      Closure_Tasking_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Accepted);
      R.Add_Context (Contexts, Tasking_Blocker_Row);
      R.Add_Context (Contexts, Cross_Blocker);
      R.Add_Context (Contexts, Closure_Tasking_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_Closure_And_Tasking_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Tasking_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant R.Tasking_RM_Closure_Consumer_Row := R.Row_At (Model, 1);
   begin
      Assert (R.Count (Model) = 5, "five tasking/protected RM closure consumer rows expected");
      Assert (R.Accepted_Count (Model) = 1, "only agreed tasking/closure row should be accepted");
      Assert (R.Blocked_Count (Model) = 4, "four prerequisite blockers should be preserved");
      Assert (Row.Status = R.Tasking_RM_Closure_Consumer_Accepted,
              "accepted row should consume stabilized RM-completion closure evidence");
   end Consumer_Accepts_Only_When_Closure_And_Tasking_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Tasking_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (R.Count_By_Family (Model, R.Tasking_RM_Closure_Consumer_Family_Tasking_RM) = 1,
              "prior tasking/protected RM blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Tasking_RM_Closure_Consumer_Family_Cross_Unit) = 1,
              "cross-unit closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Tasking_RM_Closure_Consumer_Family_Representation) = 1,
              "tasking/protected closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Tasking_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Tasking_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126605);
   begin
      Assert (R.Query_Count (R.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Source_Fingerprint (Model, 1266 * 5)) = 1,
              "source fingerprint lookup should find the source fingerprint blocker");
      Assert (R.Count_By_Status (Model, R.Tasking_RM_Closure_Consumer_Closure_Cross_Unit) = 1,
              "status query should preserve cross-unit blocker identity");
      Assert (R.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "tasking/protected RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_Closure_And_Tasking_Agree'Access,
         "tasking/protected RM closure consumer accepts only agreed evidence");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "tasking/protected RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "tasking/protected RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Tasking_RM_Completion_Closure_Consumer_Legality_Pass1266;
