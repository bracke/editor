with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dataflow_RM_Completion_Closure_Consumer_Legality_Pass1267 is

   package R renames Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality;
   use type R.Dataflow_RM_Closure_Consumer_Id;
   use type R.Dataflow_RM_Kind;
   use type R.Dataflow_RM_Closure_Consumer_Status;
   use type R.Dataflow_RM_Closure_Consumer_Family;
   use type R.Dataflow_RM_Closure_Consumer_Context;
   use type R.Dataflow_RM_Closure_Consumer_Row;
   use type R.Dataflow_RM_Closure_Consumer_Context_Model;
   use type R.Dataflow_RM_Closure_Consumer_Model;
   use type R.Dataflow_RM_Closure_Consumer_Set;
   package Prior renames R.Prior;
   package Closure renames R.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada dataflow RM-completion closure consumer pass1267");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Dataflow_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Dataflow_RM_Closure_Consumer_Context is
      Result : R.Dataflow_RM_Closure_Consumer_Context;
   begin
      Result.Id := R.Dataflow_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Dataflow_RM_Row := Prior.Dataflow_RM_Completion_Row_Id (Id);
      Result.Dataflow_RM_Status := Prior.Dataflow_RM_Completion_Legal_Read_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
      Result.Source_Fingerprint := 1267 * Id;
      Result.Expected_Source_Fingerprint := 1267 * Id;
      Result.Substitution_Fingerprint := 7621 * Id;
      Result.Expected_Substitution_Fingerprint := 7621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Dataflow_RM_Closure_Consumer_Model is
      Contexts : R.Dataflow_RM_Closure_Consumer_Context_Model;
      Accepted : R.Dataflow_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (126701));
      Dataflow_Blocker_Row : R.Dataflow_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Dataflow_RM_Completion_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (126702));
      Cross_Blocker : R.Dataflow_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Dataflow_RM_Completion_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (126703));
      Closure_Representation_Blocker : R.Dataflow_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Dataflow_RM_Completion_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (126704));
      Fingerprint_Blocker : R.Dataflow_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Dataflow_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (126705));
   begin
      Dataflow_Blocker_Row.Dataflow_RM_Status := Prior.Dataflow_RM_Completion_Read_Before_Write_Blocker;
      Cross_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit;
      Closure_Representation_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Accepted);
      R.Add_Context (Contexts, Dataflow_Blocker_Row);
      R.Add_Context (Contexts, Cross_Blocker);
      R.Add_Context (Contexts, Closure_Representation_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_Closure_And_Dataflow_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Dataflow_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant R.Dataflow_RM_Closure_Consumer_Row := R.Row_At (Model, 1);
   begin
      Assert (R.Count (Model) = 5, "five dataflow RM closure consumer rows expected");
      Assert (R.Accepted_Count (Model) = 1, "only agreed dataflow/closure row should be accepted");
      Assert (R.Blocked_Count (Model) = 4, "four prerequisite blockers should be preserved");
      Assert (Row.Status = R.Dataflow_RM_Closure_Consumer_Accepted,
              "accepted row should consume stabilized RM-completion closure evidence");
   end Consumer_Accepts_Only_When_Closure_And_Dataflow_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Dataflow_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (R.Count_By_Family (Model, R.Dataflow_RM_Closure_Consumer_Family_Dataflow_RM) = 1,
              "prior dataflow RM blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Dataflow_RM_Closure_Consumer_Family_Cross_Unit) = 1,
              "cross-unit closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Dataflow_RM_Closure_Consumer_Family_Representation) = 1,
              "representation closure blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Dataflow_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Dataflow_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126705);
   begin
      Assert (R.Query_Count (R.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Source_Fingerprint (Model, 1267 * 5)) = 1,
              "source fingerprint lookup should find the source fingerprint blocker");
      Assert (R.Count_By_Status (Model, R.Dataflow_RM_Closure_Consumer_Closure_Cross_Unit) = 1,
              "status query should preserve cross-unit blocker identity");
      Assert (R.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "dataflow RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_Closure_And_Dataflow_Agree'Access,
         "dataflow RM closure consumer accepts only agreed evidence");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "dataflow RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "dataflow RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Dataflow_RM_Completion_Closure_Consumer_Legality_Pass1267;
