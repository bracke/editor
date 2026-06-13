with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Overload_RM_Completion_Closure_Consumer_Legality_Pass1264 is

   package O renames Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality;
   use type O.Overload_RM_Closure_Consumer_Id;
   use type O.Overload_RM_Kind;
   use type O.Overload_RM_Closure_Consumer_Status;
   use type O.Overload_RM_Closure_Consumer_Family;
   use type O.Overload_RM_Closure_Consumer_Context;
   use type O.Overload_RM_Closure_Consumer_Row;
   use type O.Overload_RM_Closure_Consumer_Context_Model;
   use type O.Overload_RM_Closure_Consumer_Model;
   use type O.Overload_RM_Closure_Consumer_Set;
   package Prior renames O.Prior;
   package Closure renames O.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada overload RM-completion closure consumer pass1264");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : O.Overload_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return O.Overload_RM_Closure_Consumer_Context is
      Result : O.Overload_RM_Closure_Consumer_Context;
   begin
      Result.Id := O.Overload_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Overload_RM_Row := Prior.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Prior.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
      Result.Source_Fingerprint := 1264 * Id;
      Result.Expected_Source_Fingerprint := 1264 * Id;
      Result.Substitution_Fingerprint := 4621 * Id;
      Result.Expected_Substitution_Fingerprint := 4621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return O.Overload_RM_Closure_Consumer_Model is
      Contexts : O.Overload_RM_Closure_Consumer_Context_Model;
      Accepted : O.Overload_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Overload_Generic_RM_Edge_Dispatching_Abstract_State_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (126401));
      Overload_Blocker : O.Overload_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Overload_Generic_RM_Edge_Prefixed_Call_Side_Effect_Contract,
                          Editor.Ada_Syntax_Tree.Node_Id (126402));
      Cross_Blocker : O.Overload_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Overload_Generic_RM_Edge_Access_Subprogram_Effect_Profile,
                          Editor.Ada_Syntax_Tree.Node_Id (126403));
      Representation_Blocker : O.Overload_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Overload_Generic_RM_Edge_Generic_Formal_Subprogram_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (126404));
      Fingerprint_Blocker : O.Overload_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Overload_Generic_RM_Edge_Class_Wide_Controlling_Result_State,
                          Editor.Ada_Syntax_Tree.Node_Id (126405));
   begin
      Overload_Blocker.Overload_RM_Status := Prior.Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch;
      Cross_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit;
      Representation_Blocker.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Blocker_Representation;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      O.Add_Context (Contexts, Accepted);
      O.Add_Context (Contexts, Overload_Blocker);
      O.Add_Context (Contexts, Cross_Blocker);
      O.Add_Context (Contexts, Representation_Blocker);
      O.Add_Context (Contexts, Fingerprint_Blocker);
      return O.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_Closure_And_Overload_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant O.Overload_RM_Closure_Consumer_Row := O.Row_At (Model, 1);
   begin
      Assert (O.Count (Model) = 5, "five overload RM closure consumer rows expected");
      Assert (O.Accepted_Count (Model) = 1, "only agreed overload/closure row should be accepted");
      Assert (O.Blocked_Count (Model) = 4, "four prerequisite blockers should be preserved");
      Assert (Row.Status = O.Overload_RM_Closure_Consumer_Accepted,
              "accepted row should consume stabilized RM-completion closure evidence");
   end Consumer_Accepts_Only_When_Closure_And_Overload_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (O.Count_By_Family (Model, O.Overload_RM_Closure_Consumer_Family_Overload_RM) = 1,
              "prior overload RM blocker should remain distinct");
      Assert (O.Count_By_Family (Model, O.Overload_RM_Closure_Consumer_Family_Cross_Unit) = 1,
              "cross-unit closure blocker should remain distinct");
      Assert (O.Count_By_Family (Model, O.Overload_RM_Closure_Consumer_Family_Representation) = 1,
              "representation closure blocker should remain distinct");
      Assert (O.Count_By_Family (Model, O.Overload_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant O.Overload_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126405);
   begin
      Assert (O.Query_Count (O.Find_By_Node (Model, Node)) = 1,
              "node lookup should find the source fingerprint blocker");
      Assert (O.Query_Count (O.Find_By_Source_Fingerprint (Model, 1264 * 5)) = 1,
              "source fingerprint lookup should find the source fingerprint blocker");
      Assert (O.Count_By_Status (Model, O.Overload_RM_Closure_Consumer_Closure_Cross_Unit) = 1,
              "status query should preserve cross-unit blocker identity");
      Assert (O.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (O.Stable_Fingerprint (Model) /= 0,
              "overload RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_Closure_And_Overload_Agree'Access,
         "overload RM closure consumer accepts only agreed evidence");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "overload RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "overload RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Overload_RM_Completion_Closure_Consumer_Legality_Pass1264;
