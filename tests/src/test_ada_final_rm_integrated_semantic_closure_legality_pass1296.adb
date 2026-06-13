with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_RM_Integrated_Semantic_Closure_Legality_Pass1296 is

   package Closure renames Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality;
   use type Closure.Final_Base_Row;
   use type Closure.RM_Completion_Row;
   use type Closure.Direct_Consumer_Row;
   use type Closure.Remaining_Edge_Row;
   use type Closure.AST_Repair_Row;
   use type Closure.Final_RM_Integrated_Closure_Id;
   use type Closure.Final_RM_Integrated_Blocker_Family;
   use type Closure.Final_RM_Integrated_Closure_Status;
   use type Closure.Final_RM_Integrated_Closure_Action;
   use type Closure.Final_RM_Integrated_Closure_Context;
   use type Closure.Final_RM_Integrated_Closure_Row;
   use type Closure.Final_RM_Integrated_Closure_Context_Model;
   use type Closure.Final_RM_Integrated_Closure_Model;
   use type Closure.Final_RM_Integrated_Closure_Set;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada final RM integrated semantic closure legality pass1296");
   end Name;

   function Base_Context
     (Id   : Natural;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Closure.Final_RM_Integrated_Closure_Context is
      Context : Closure.Final_RM_Integrated_Closure_Context;
   begin
      Context.Id := Closure.Final_RM_Integrated_Closure_Id (Id);
      Context.Node := Node;
      Context.Construct_Name := To_Unbounded_String ("final-rm-integrated" & Natural'Image (Id));
      Context.Has_Final_Stabilized_Closure := True;
      Context.Final_Stabilized_Closure.Status := Closure.Final_Base.Final_Stabilized_Closure_Accepted_Current;
      Context.Final_Stabilized_Closure.Closure_Fingerprint := 1_296_000 + Id;
      Context.Has_RM_Completion_Closure := True;
      Context.RM_Completion_Closure.Status := Closure.RM_Completion.RM_Completion_Stabilized_Closure_Accepted_Current;
      Context.RM_Completion_Closure.Accepted := True;
      Context.RM_Completion_Closure.Current := True;
      Context.RM_Completion_Closure.Closure_Fingerprint := 1_296_100 + Id;
      Context.Has_Direct_Consumer_Closure := True;
      Context.Direct_Consumer_Closure.Status := Closure.Consumers.RM_Closure_Consumer_Stabilized_Closure_Accepted_Current;
      Context.Direct_Consumer_Closure.Accepted := True;
      Context.Direct_Consumer_Closure.Current := True;
      Context.Direct_Consumer_Closure.Closure_Fingerprint := 1_296_200 + Id;
      Context.Has_Remaining_Edge_Closure := True;
      Context.Remaining_Edge_Closure.Status := Closure.Remaining_Edge.Remaining_RM_Edge_Stabilized_Closure_Accepted_Current;
      Context.Remaining_Edge_Closure.Accepted := True;
      Context.Remaining_Edge_Closure.Current := True;
      Context.Remaining_Edge_Closure.Closure_Fingerprint := 1_296_300 + Id;
      Context.Requires_AST_Repair_Evidence := True;
      Context.Has_AST_Repair_Evidence := True;
      Context.AST_Repair_Evidence.Status := Closure.AST_Repair.Remaining_RM_Edge_AST_Repair_Metadata_Repaired;
      Context.AST_Repair_Evidence.Repaired := True;
      Context.AST_Repair_Evidence.Row_Fingerprint := 1_296_400 + Id;
      Context.Source_Fingerprint := 12_960 + Id;
      Context.Expected_Source_Fingerprint := Context.Source_Fingerprint;
      Context.Substitution_Fingerprint := 129_600 + Id;
      Context.Expected_Substitution_Fingerprint := Context.Substitution_Fingerprint;
      Context.Start_Line := 20 + Id;
      Context.Start_Column := 2;
      Context.End_Line := 20 + Id;
      Context.End_Column := 40;
      return Context;
   end Base_Context;

   function Build_Model return Closure.Final_RM_Integrated_Closure_Model is
      Contexts : Closure.Final_RM_Integrated_Closure_Context_Model;
      Accepted_Context : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (1, Editor.Ada_Syntax_Tree.Node_Id (129601));
      Missing_Remaining : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (2, Editor.Ada_Syntax_Tree.Node_Id (129602));
      Representation_Blocker : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (3, Editor.Ada_Syntax_Tree.Node_Id (129603));
      Multiple_Blocker : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (4, Editor.Ada_Syntax_Tree.Node_Id (129604));
      Fingerprint_Blocker : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (5, Editor.Ada_Syntax_Tree.Node_Id (129605));
      Recheck_Context : Closure.Final_RM_Integrated_Closure_Context :=
        Base_Context (6, Editor.Ada_Syntax_Tree.Node_Id (129606));
   begin
      Missing_Remaining.Has_Remaining_Edge_Closure := False;
      Representation_Blocker.Representation_Accepted := False;
      Multiple_Blocker.Abstract_Refined_State_Accepted := False;
      Multiple_Blocker.Tasking_Accepted := False;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;
      Recheck_Context.Direct_Consumer_Closure.Status := Closure.Consumers.RM_Closure_Consumer_Stabilized_Closure_Recheck_Required;
      Recheck_Context.Direct_Consumer_Closure.Accepted := False;
      Recheck_Context.Direct_Consumer_Closure.Recheck_Required := True;

      Closure.Add_Context (Contexts, Accepted_Context);
      Closure.Add_Context (Contexts, Missing_Remaining);
      Closure.Add_Context (Contexts, Representation_Blocker);
      Closure.Add_Context (Contexts, Multiple_Blocker);
      Closure.Add_Context (Contexts, Fingerprint_Blocker);
      Closure.Add_Context (Contexts, Recheck_Context);
      return Closure.Build (Contexts);
   end Build_Model;

   procedure Integrates_All_Stabilized_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Closure.Final_RM_Integrated_Closure_Model := Build_Model;
   begin
      Assert (Closure.Count (Model) = 6,
              "integrated closure should preserve every candidate row");
      Assert (Closure.Accepted_Count (Model) = 1,
              "only the fully evidenced row should enter accepted integrated closure");
      Assert (Closure.Count_By_Status (Model, Closure.Final_RM_Integrated_Closure_Accepted_Current) = 1,
              "accepted current evidence should be explicit");
      Assert (Closure.Count_By_Blocker_Family (Model, Closure.Final_RM_Integrated_Blocker_Missing_Remaining_Edge_Closure) = 1,
              "missing remaining RM edge closure must remain a distinct blocker");
      Assert (Closure.Count_By_Blocker_Family (Model, Closure.Final_RM_Integrated_Blocker_Representation_Freezing) = 1,
              "representation/freezing evidence must remain a distinct blocker");
      Assert (Closure.Count_By_Status (Model, Closure.Final_RM_Integrated_Closure_Blocker_Multiple_Prerequisites) = 1,
              "multiple semantic prerequisite failures must be split explicitly");
      Assert (Closure.Count_By_Status (Model, Closure.Final_RM_Integrated_Closure_Blocker_Source_Fingerprint) = 1,
              "source fingerprint mismatch must block integrated closure");
      Assert (Closure.Recheck_Required_Count (Model) = 1,
              "direct-consumer recheck-required rows should stay outside trusted closure");
      Assert (Closure.Stable_Fingerprint (Model) /= 0,
              "integrated closure fingerprint should be deterministic");
   end Integrates_All_Stabilized_RM_Evidence;

   procedure Queries_By_Node_Status_And_Blocker
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Closure.Final_RM_Integrated_Closure_Model := Build_Model;
      Node_Set : constant Closure.Final_RM_Integrated_Closure_Set :=
        Closure.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (129601));
      Recheck_Set : constant Closure.Final_RM_Integrated_Closure_Set :=
        Closure.Query_Status (Model, Closure.Final_RM_Integrated_Closure_Recheck_Required);
      Representation_Set : constant Closure.Final_RM_Integrated_Closure_Set :=
        Closure.Query_Blocker_Family (Model, Closure.Final_RM_Integrated_Blocker_Representation_Freezing);
   begin
      Assert (Closure.Query_Count (Node_Set) = 1,
              "integrated closure rows should be queryable by syntax node");
      Assert (Closure.Query_Count (Recheck_Set) = 1,
              "recheck-required rows should be queryable by status");
      Assert (Closure.Query_Count (Representation_Set) = 1,
              "representation blocker should be queryable by family");
      Assert (Closure.Query_At (Node_Set, 1).Accepted,
              "node query should return accepted current evidence for node 129601");
   end Queries_By_Node_Status_And_Blocker;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Integrates_All_Stabilized_RM_Evidence'Access,
                        "integrates stabilized RM-completion, direct-consumer, remaining-edge, and AST-repair evidence");
      Register_Routine (T, Queries_By_Node_Status_And_Blocker'Access,
                        "queries final RM integrated closure by node, status, and blocker family");
   end Register_Tests;

end Test_Ada_Final_RM_Integrated_Semantic_Closure_Legality_Pass1296;
