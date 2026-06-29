with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_AST_Semantic_Coverage_Audit is

   package AUD renames Editor.Ada_AST_Semantic_Coverage_Audit;
   use type AUD.Coverage_Item_Id;
   use type AUD.Ada_Construct_Kind;
   use type AUD.Semantic_Consumer_Family;
   use type AUD.Coverage_Status;
   use type AUD.Coverage_Context_Info;
   use type AUD.Coverage_Info;
   use type AUD.Coverage_Context_Model;
   use type AUD.Coverage_Result_Set;
   use type AUD.Coverage_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_AST_Semantic_Coverage_Audit");
   end Name;

   procedure Builds_AST_Semantic_Coverage_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Aspect_Specification;
      C.Consumer := AUD.Consumer_Contract_Aspect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113201);
      C.Construct_Name := To_Unbounded_String ("Pre");
      C.Normalized_Construct_Name := To_Unbounded_String ("pre");
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Representation_Clause;
      C.Consumer := AUD.Consumer_Representation_Freezing_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113202);
      C.Normalized_Construct_Name := To_Unbounded_String ("for_t_size_use");
      C.Representation_Metadata_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Generic_Formal_Type;
      C.Consumer := AUD.Consumer_Generic_Contracts;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113203);
      C.Structural_AST_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Container_Aggregate;
      C.Consumer := AUD.Consumer_Conversion_Access_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113204);
      C.Token_Only_Parse := True;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Construct := AUD.Construct_Select_Statement;
      C.Consumer := AUD.Consumer_Tasking_Protected_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113205);
      C.Consumer_Integrated := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Construct := AUD.Construct_Record_Aggregate;
      C.Consumer := AUD.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113206);
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Construct := AUD.Construct_Task_Body;
      C.Consumer := AUD.Consumer_Tasking_Protected_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113207);
      C.Flow_Metadata_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Construct := AUD.Construct_Separate_Body;
      C.Consumer := AUD.Consumer_Cross_Unit_Closure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113208);
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Construct := AUD.Construct_Access_Definition;
      C.Consumer := AUD.Consumer_Accessibility_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113209);
      C.Parser_Node_Present := False;
      AUD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Construct := AUD.Construct_Quantified_Expression;
      C.Consumer := AUD.Consumer_Staticness_Range_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113210);
      C.Graceful_Degradation_Only := True;
      AUD.Add_Context (Contexts, C);

      declare
         Model : constant AUD.Coverage_Model := AUD.Build (Contexts);
         Representation_Rows : constant AUD.Coverage_Result_Set :=
           AUD.Rows_For_Construct (Model, AUD.Construct_Representation_Clause);
         Tasking_Rows : constant AUD.Coverage_Result_Set :=
           AUD.Rows_For_Consumer (Model, AUD.Consumer_Tasking_Protected_Precision);
      begin
         Assert (AUD.Coverage_Count (Model) = 10,
                 "all coverage contexts should produce audit rows");
         Assert (AUD.Complete_Count (Model) = 1,
                 "only the fully shaped contract aspect should be complete");
         Assert (AUD.Error_Count (Model) = 9,
                 "incomplete grammar-to-semantic coverage should be reported");
         Assert (AUD.Missing_Parser_Count (Model) = 2,
                 "token-only and missing parser-node cases should be parser coverage gaps");
         Assert (AUD.Missing_AST_Count (Model) = 1,
                 "generic formal type should expose structural AST gap");
         Assert (AUD.Missing_Metadata_Count (Model) = 4,
                 "representation, type, flow, and cross-unit metadata gaps should be counted");
         Assert (AUD.Missing_Consumer_Count (Model) = 1,
                 "non-integrated select consumer should be counted");
         Assert (AUD.Degradation_Count (Model) = 1,
                 "graceful degradation should not be treated as complete compiler-grade coverage");
         Assert (AUD.Result_Count (Representation_Rows) = 1,
                 "construct lookup should preserve representation clause rows");
         Assert (AUD.Result_Count (Tasking_Rows) = 2,
                 "consumer lookup should preserve tasking/protected rows");
         Assert (AUD.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (113204)).Status =
                 AUD.Coverage_Token_Only_Parse,
                 "node lookup should preserve token-only classification");
         Assert (AUD.Count_Status (Model, AUD.Coverage_Representation_Metadata_Missing) = 1,
                 "representation metadata status should be counted directly");
         Assert (AUD.Count_Construct (Model, AUD.Construct_Access_Definition) = 1,
                 "access-definition construct count should be deterministic");
         Assert (AUD.Fingerprint (Model) /= 0,
                 "coverage audit fingerprint should be deterministic and non-zero");
      end;
   end Builds_AST_Semantic_Coverage_Audit;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_AST_Semantic_Coverage_Audit'Access,
         "builds parser/AST semantic coverage audit");
   end Register_Tests;

end Test_Ada_AST_Semantic_Coverage_Audit;
