with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Elaboration_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_RM_Completion_Closure_Consumer_Legality_Pass1269 is

   package R renames Editor.Ada_Elaboration_RM_Completion_Closure_Consumer_Legality;
   use type R.Elaboration_RM_Closure_Consumer_Id;
   use type R.Elaboration_RM_Kind;
   use type R.Elaboration_RM_Closure_Consumer_Status;
   use type R.Elaboration_RM_Closure_Consumer_Family;
   use type R.Elaboration_RM_Closure_Consumer_Context;
   use type R.Elaboration_RM_Closure_Consumer_Row;
   use type R.Elaboration_RM_Closure_Consumer_Context_Model;
   use type R.Elaboration_RM_Closure_Consumer_Model;
   use type R.Elaboration_RM_Closure_Consumer_Set;
   package Prior renames R.Prior;
   package Closure renames R.Closure;
   package Cross_Unit renames R.Cross_Unit;
   package Overload renames R.Overload;
   package Representation renames R.Representation;
   package Tasking renames R.Tasking;
   package Dataflow renames R.Dataflow;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada elaboration RM-completion closure consumer pass1269");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : R.Elaboration_RM_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return R.Elaboration_RM_Closure_Consumer_Context is
      Result : R.Elaboration_RM_Closure_Consumer_Context;
   begin
      Result.Id := R.Elaboration_RM_Closure_Consumer_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Elaboration_RM_Row := Prior.Elaboration_RM_Completion_Row_Id (Id);
      Result.Elaboration_RM_Status := Prior.Elaboration_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Stabilized_Closure_Row := Closure.RM_Completion_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Accepted_Current;
      Result.Cross_Unit_Consumer_Row := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Id (Id);
      Result.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Accepted;
      Result.Overload_Consumer_Row := Overload.Overload_RM_Closure_Consumer_Id (Id);
      Result.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Accepted;
      Result.Representation_Consumer_Row := Representation.Representation_RM_Closure_Consumer_Id (Id);
      Result.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Accepted;
      Result.Tasking_Consumer_Row := Tasking.Tasking_RM_Closure_Consumer_Id (Id);
      Result.Tasking_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Accepted;
      Result.Dataflow_Consumer_Row := Dataflow.Dataflow_RM_Closure_Consumer_Id (Id);
      Result.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Accepted;
      Result.Source_Fingerprint := 1269 * Id;
      Result.Expected_Source_Fingerprint := 1269 * Id;
      Result.Substitution_Fingerprint := 9621 * Id;
      Result.Expected_Substitution_Fingerprint := 9621 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return R.Elaboration_RM_Closure_Consumer_Model is
      Contexts : R.Elaboration_RM_Closure_Consumer_Context_Model;
      Accepted : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (1, Prior.Elaboration_RM_Completion_Generic_Instance,
                          Editor.Ada_Syntax_Tree.Node_Id (126901));
      Cross_Blocker : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (2, Prior.Elaboration_RM_Completion_Cross_Unit_Body,
                          Editor.Ada_Syntax_Tree.Node_Id (126902));
      Overload_Blocker : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (3, Prior.Elaboration_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (126903));
      Representation_Blocker : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (4, Prior.Elaboration_RM_Completion_Representation_Item,
                          Editor.Ada_Syntax_Tree.Node_Id (126904));
      Dataflow_Blocker : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (5, Prior.Elaboration_RM_Completion_Dataflow_Edge,
                          Editor.Ada_Syntax_Tree.Node_Id (126905));
      Fingerprint_Blocker : R.Elaboration_RM_Closure_Consumer_Context :=
        Complete_Context (6, Prior.Elaboration_RM_Completion_Aspect_Expression,
                          Editor.Ada_Syntax_Tree.Node_Id (126906));
   begin
      Cross_Blocker.Cross_Unit_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      Overload_Blocker.Overload_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Closure_Overload_Type;
      Representation_Blocker.Representation_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Closure_Representation;
      Dataflow_Blocker.Dataflow_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Closure_Dataflow;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      R.Add_Context (Contexts, Accepted);
      R.Add_Context (Contexts, Cross_Blocker);
      R.Add_Context (Contexts, Overload_Blocker);
      R.Add_Context (Contexts, Representation_Blocker);
      R.Add_Context (Contexts, Dataflow_Blocker);
      R.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (Contexts);
   end Build_Model;

   procedure Consumer_Accepts_Only_When_All_Direct_Consumers_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Elaboration_RM_Closure_Consumer_Model := Build_Model;
      Row   : constant R.Elaboration_RM_Closure_Consumer_Row := R.Row_At (Model, 1);
   begin
      Assert (R.Count (Model) = 6, "six elaboration RM closure consumer rows expected");
      Assert (R.Accepted_Count (Model) = 1, "only fully agreed elaboration row should be accepted");
      Assert (R.Blocked_Count (Model) = 5, "five prerequisite blockers should be preserved");
      Assert (Row.Status = R.Elaboration_RM_Closure_Consumer_Accepted,
              "accepted row should consume direct RM-completion closure consumers");
   end Consumer_Accepts_Only_When_All_Direct_Consumers_Agree;

   procedure Consumer_Preserves_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Elaboration_RM_Closure_Consumer_Model := Build_Model;
   begin
      Assert (R.Count_By_Family (Model, R.Elaboration_RM_Closure_Consumer_Family_Cross_Unit) = 1,
              "cross-unit RM closure consumer blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Elaboration_RM_Closure_Consumer_Family_Overload_Type) = 1,
              "overload/type RM closure consumer blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Elaboration_RM_Closure_Consumer_Family_Representation) = 1,
              "representation/freezing RM closure consumer blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Elaboration_RM_Closure_Consumer_Family_Dataflow) = 1,
              "dataflow RM closure consumer blocker should remain distinct");
      Assert (R.Count_By_Family (Model, R.Elaboration_RM_Closure_Consumer_Family_Source_Fingerprint) = 1,
              "source fingerprint blocker should remain distinct");
   end Consumer_Preserves_Blocker_Families;

   procedure Consumer_Lookups_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Elaboration_RM_Closure_Consumer_Model := Build_Model;
      Node  : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (126906);
   begin
      Assert (R.Query_Count (R.Find_By_Node (Model, Node)) = 1,
              "node lookup should find source fingerprint blocker");
      Assert (R.Query_Count (R.Find_By_Source_Fingerprint (Model, 1269 * 6)) = 1,
              "source fingerprint lookup should find source fingerprint blocker");
      Assert (R.Count_By_Status (Model, R.Elaboration_RM_Closure_Consumer_Cross_Unit_Consumer_Blocker) = 1,
              "status query should preserve cross-unit consumer blocker identity");
      Assert (R.Indeterminate_Count (Model) = 0,
              "fixture should not produce indeterminate rows");
      Assert (R.Stable_Fingerprint (Model) /= 0,
              "elaboration RM closure consumer fingerprint should be non-zero");
   end Consumer_Lookups_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Consumer_Accepts_Only_When_All_Direct_Consumers_Agree'Access,
         "elaboration RM closure consumer accepts only direct-consumer agreement");
      Register_Routine
        (T, Consumer_Preserves_Blocker_Families'Access,
         "elaboration RM closure consumer preserves blocker families");
      Register_Routine
        (T, Consumer_Lookups_And_Fingerprints_Are_Deterministic'Access,
         "elaboration RM closure consumer lookups and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Elaboration_RM_Completion_Closure_Consumer_Legality_Pass1269;
