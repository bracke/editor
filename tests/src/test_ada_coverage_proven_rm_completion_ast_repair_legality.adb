with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality is

   package T renames Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality;
   use type T.Coverage_Proven_AST_Repair_Id;
   use type T.Coverage_Proven_AST_Repair_Kind;
   use type T.Coverage_Proven_AST_Repair_Blocker_Family;
   use type T.Coverage_Proven_AST_Repair_Status;
   use type T.Coverage_Proven_AST_Repair_Context;
   use type T.Coverage_Proven_AST_Repair_Row;
   use type T.Coverage_Proven_AST_Repair_Context_Model;
   use type T.Coverage_Proven_AST_Repair_Model;
   use type T.Coverage_Proven_AST_Repair_Set;
   package Gates renames T.Gates;
   package Closure renames T.Closure;
   package Edges renames T.Overload_Edges;
   package Rep renames T.Representation_Hard_Cases;
   package Tasking renames T.Tasking_Hard_Cases;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada coverage-proven RM-completion AST repair legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : T.Coverage_Proven_AST_Repair_Kind;
      Gate : Gates.Gate_Status;
      Action : Gates.Gate_Action;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return T.Coverage_Proven_AST_Repair_Context is
      Result : T.Coverage_Proven_AST_Repair_Context;
   begin
      Result.Id := T.Coverage_Proven_AST_Repair_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Construct_Name := To_Unbounded_String ("Construct" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.Coverage_Gate_Status := Gate;
      Result.Coverage_Gate_Action := Action;
      Result.Has_Coverage_Gate := True;
      Result.Stabilized_Closure_Row := Closure.Generic_Shared_State_Final_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Result.Overload_RM_Edge_Row := Edges.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Representation_RM_Hard_Case_Row := Rep.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Hard_Case_Status := Rep.Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted;
      Result.Tasking_RM_Hard_Case_Row := Tasking.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Hard_Case_Status := Tasking.Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted;
      Result.Source_Fingerprint := 1258 * Id;
      Result.Expected_Source_Fingerprint := 1258 * Id;
      return Result;
   end Complete_Context;

   function Build_Model return T.Coverage_Proven_AST_Repair_Model is
      Contexts : T.Coverage_Proven_AST_Repair_Context_Model;
      Parser_Node : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (1, T.Coverage_Proven_AST_Repair_Parser_Node,
                          Gates.Gate_Parser_Node_Missing, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125801));
      Shape : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (2, T.Coverage_Proven_AST_Repair_Structural_AST,
                          Gates.Gate_AST_Shape_Missing, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125802));
      Token : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (3, T.Coverage_Proven_AST_Repair_Token_Only_Parse,
                          Gates.Gate_Token_Only_Parse, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125803));
      Metadata : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (4, T.Coverage_Proven_AST_Repair_Metadata,
                          Gates.Gate_Flow_Metadata_Missing, Gates.Gate_Require_Metadata_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125804));
      Not_Required : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (5, T.Coverage_Proven_AST_Repair_Source_Span,
                          Gates.Gate_Open, Gates.Gate_Allow_Confident_Result,
                          Editor.Ada_Syntax_Tree.Node_Id (125805));
      Closure_Blocker : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (6, T.Coverage_Proven_AST_Repair_Consumer_Integration,
                          Gates.Gate_Consumer_Not_Integrated, Gates.Gate_Require_Consumer_Integration,
                          Editor.Ada_Syntax_Tree.Node_Id (125806));
      Edge_Blocker : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (7, T.Coverage_Proven_AST_Repair_Parser_Node,
                          Gates.Gate_Parser_Node_Missing, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125807));
      Local_Blocker : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (8, T.Coverage_Proven_AST_Repair_Token_Only_Parse,
                          Gates.Gate_Token_Only_Parse, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125808));
      Missing_Gate : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (9, T.Coverage_Proven_AST_Repair_Metadata,
                          Gates.Gate_Not_Checked, Gates.Gate_Block_Unsafe_Result,
                          Editor.Ada_Syntax_Tree.Node_Id (125809));
      Multiple_Blocker : T.Coverage_Proven_AST_Repair_Context :=
        Complete_Context (10, T.Coverage_Proven_AST_Repair_Structural_AST,
                          Gates.Gate_AST_Shape_Missing, Gates.Gate_Require_Parser_AST_Repair,
                          Editor.Ada_Syntax_Tree.Node_Id (125810));
   begin
      Closure_Blocker.Stabilized_Closure_Status := Closure.Generic_Shared_State_Final_Stabilized_Closure_Blocker_AST_Or_Coverage;
      Edge_Blocker.Overload_RM_Edge_Status := Edges.Overload_Generic_RM_Edge_Dispatching_Abstract_State_Mismatch;
      Local_Blocker.Token_Only_Parse_Still_Present := True;
      Missing_Gate.Has_Coverage_Gate := False;
      Multiple_Blocker.Structural_AST_Still_Missing := True;
      Multiple_Blocker.Source_Span_Still_Missing := True;

      T.Add_Context (Contexts, Parser_Node);
      T.Add_Context (Contexts, Shape);
      T.Add_Context (Contexts, Token);
      T.Add_Context (Contexts, Metadata);
      T.Add_Context (Contexts, Not_Required);
      T.Add_Context (Contexts, Closure_Blocker);
      T.Add_Context (Contexts, Edge_Blocker);
      T.Add_Context (Contexts, Local_Blocker);
      T.Add_Context (Contexts, Missing_Gate);
      T.Add_Context (Contexts, Multiple_Blocker);
      return T.Build (Contexts);
   end Build_Model;

   procedure Repairs_Only_When_Coverage_Gates_Prove_Real_Blockers
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Coverage_Proven_AST_Repair_Model := Build_Model;
   begin
      Assert (T.Count (Model) = 10, "ten coverage-proven AST repair rows expected");
      Assert (T.Repaired_Count (Model) = 4, "four coverage-proven AST repairs should be accepted");
      Assert (T.Not_Required_Count (Model) = 1, "open coverage gate should be not required, not repaired");
      Assert (T.Count_By_Status (Model, T.Coverage_Proven_AST_Repair_Parser_Node_Repaired) = 1,
              "parser-node repair should require a parser/AST coverage gate");
      Assert (T.Count_By_Status (Model, T.Coverage_Proven_AST_Repair_Metadata_Repaired) = 1,
              "metadata repair should require a metadata coverage gate");
   end Repairs_Only_When_Coverage_Gates_Prove_Real_Blockers;

   procedure Repair_Preserves_Prerequisite_And_AST_Blocker_Families
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Coverage_Proven_AST_Repair_Model := Build_Model;
   begin
      Assert (T.Withheld_Count (Model) = 5, "five withheld AST repair rows expected");
      Assert (T.Count_By_Blocker_Family (Model, T.Coverage_Proven_AST_Repair_Blocker_Stabilized_Closure) = 1,
              "stabilized closure blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Coverage_Proven_AST_Repair_Blocker_Overload_RM_Edge) = 1,
              "overload RM edge blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Coverage_Proven_AST_Repair_Blocker_Token_Only_Parse) = 1,
              "token-only repair blocker should remain distinct");
      Assert (T.Count_By_Blocker_Family (Model, T.Coverage_Proven_AST_Repair_Blocker_No_Coverage_Gate) = 1,
              "missing coverage gate should block speculative parser repair");
      Assert (T.Count_By_Blocker_Family (Model, T.Coverage_Proven_AST_Repair_Blocker_Multiple) = 1,
              "multiple AST repair blockers should remain explicit");
   end Repair_Preserves_Prerequisite_And_AST_Blocker_Families;

   procedure Repair_Provides_Deterministic_Lookups_And_Fingerprint
     (TC : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (TC);
      Model : constant T.Coverage_Proven_AST_Repair_Model := Build_Model;
      Node_Set : constant T.Coverage_Proven_AST_Repair_Set :=
        T.Find_By_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (125803));
      Fingerprint_Set : constant T.Coverage_Proven_AST_Repair_Set :=
        T.Find_By_Source_Fingerprint (Model, 1258 * 4);
   begin
      Assert (T.Query_Count (Node_Set) = 1, "node lookup should find the token-only repair row");
      Assert (T.Query_At (Node_Set, 1).Status = T.Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired,
              "node lookup should preserve token-only repair status");
      Assert (T.Query_Count (Fingerprint_Set) = 1, "source fingerprint lookup should find one row");
      Assert (T.Stable_Fingerprint (Model) /= 0, "repair model fingerprint should be deterministic and non-zero");
      Assert (T.Indeterminate_Count (Model) = 0, "fixture should not produce indeterminate rows");
   end Repair_Provides_Deterministic_Lookups_And_Fingerprint;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Repairs_Only_When_Coverage_Gates_Prove_Real_Blockers'Access,
                        "accepts AST repair only when coverage gates prove a semantic blocker");
      Register_Routine (T, Repair_Preserves_Prerequisite_And_AST_Blocker_Families'Access,
                        "preserves prerequisite and AST repair blocker families");
      Register_Routine (T, Repair_Provides_Deterministic_Lookups_And_Fingerprint'Access,
                        "provides deterministic lookup and fingerprinting for coverage-proven AST repair");
   end Register_Tests;

end Test_Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality;
