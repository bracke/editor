with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_AST_Coverage_Repair_Legality is

   package R renames Editor.Ada_AST_Coverage_Repair_Legality;
   use type R.Repair_Item_Id;
   use type R.Repair_Kind;
   use type R.Repair_Status;
   use type R.Repair_Context_Info;
   use type R.Repair_Info;
   use type R.Repair_Context_Model;
   use type R.Repair_Model;
   use type R.Repair_Result_Set;
   package A renames Editor.Ada_AST_Semantic_Coverage_Audit;
   use type A.Coverage_Item_Id;
   use type A.Ada_Construct_Kind;
   use type A.Semantic_Consumer_Family;
   use type A.Coverage_Status;
   use type A.Coverage_Context_Info;
   use type A.Coverage_Info;
   use type A.Coverage_Context_Model;
   use type A.Coverage_Result_Set;
   use type A.Coverage_Model;
   package G renames Editor.Ada_Semantic_Coverage_Gates;
   use type G.Gate_Item_Id;
   use type G.Semantic_Conclusion_Kind;
   use type G.Gate_Action;
   use type G.Gate_Status;
   use type G.Gate_Context_Info;
   use type G.Gate_Info;
   use type G.Gate_Context_Model;
   use type G.Gate_Result_Set;
   use type G.Gate_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_AST_Coverage_Repair_Legality");
   end Name;

   function Sample_Contexts return R.Repair_Context_Model is
      Contexts : R.Repair_Context_Model;
      C        : R.Repair_Context_Info;
   begin
      C.Id := 1;
      C.Kind := R.Repair_Parser_Node;
      C.Construct := A.Construct_Aspect_Specification;
      C.Consumer := A.Consumer_Contract_Aspect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114701);
      C.Construct_Name := To_Unbounded_String ("aspect_specification");
      C.Normalized_Construct_Name := To_Unbounded_String ("aspect_specification");
      C.Before_Coverage := A.Coverage_Parser_Node_Missing;
      C.Before_Gate := G.Gate_Parser_Node_Missing;
      C.Parser_Node_Repaired := True;
      C.Source_Fingerprint := 1_147_001;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := R.Repair_Structural_AST;
      C.Construct := A.Construct_Generic_Formal_Type;
      C.Consumer := A.Consumer_Generic_Contracts;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114702);
      C.Construct_Name := To_Unbounded_String ("generic_formal_type");
      C.Normalized_Construct_Name := To_Unbounded_String ("generic_formal_type");
      C.Before_Coverage := A.Coverage_AST_Shape_Missing;
      C.Structural_AST_Repaired := True;
      C.Source_Fingerprint := 1_147_002;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := R.Repair_Token_Only_Replacement;
      C.Construct := A.Construct_Select_Statement;
      C.Consumer := A.Consumer_Tasking_Protected;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114703);
      C.Construct_Name := To_Unbounded_String ("select_statement");
      C.Normalized_Construct_Name := To_Unbounded_String ("select_statement");
      C.Before_Coverage := A.Coverage_Token_Only_Parse;
      C.Token_Only_Replaced := True;
      C.Source_Fingerprint := 1_147_003;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := R.Repair_Flow_Metadata;
      C.Construct := A.Construct_Call;
      C.Consumer := A.Consumer_Dataflow_Global_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114704);
      C.Construct_Name := To_Unbounded_String ("call");
      C.Normalized_Construct_Name := To_Unbounded_String ("call");
      C.Before_Coverage := A.Coverage_Flow_Metadata_Missing;
      C.Flow_Metadata_Repaired := True;
      C.Source_Fingerprint := 1_147_004;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := R.Repair_Representation_Metadata;
      C.Construct := A.Construct_Representation_Clause;
      C.Consumer := A.Consumer_Representation_Layout_Stream;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114705);
      C.Construct_Name := To_Unbounded_String ("representation_clause");
      C.Normalized_Construct_Name := To_Unbounded_String ("representation_clause");
      C.Before_Coverage := A.Coverage_Representation_Metadata_Missing;
      C.Representation_Metadata_Repaired := True;
      C.Source_Fingerprint := 1_147_005;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := R.Repair_Cross_Unit_Metadata;
      C.Construct := A.Construct_Separate_Body;
      C.Consumer := A.Consumer_Cross_Unit_Closure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114706);
      C.Construct_Name := To_Unbounded_String ("separate_body");
      C.Normalized_Construct_Name := To_Unbounded_String ("separate_body");
      C.Before_Coverage := A.Coverage_Cross_Unit_Metadata_Missing;
      C.Cross_Unit_Metadata_Repaired := True;
      C.Source_Fingerprint := 1_147_006;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := R.Repair_Semantic_Consumer;
      C.Construct := A.Construct_Delta_Aggregate;
      C.Consumer := A.Consumer_Conversion_Access_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114707);
      C.Construct_Name := To_Unbounded_String ("delta_aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("delta_aggregate");
      C.Before_Coverage := A.Coverage_Consumer_Missing;
      C.Consumer_Repaired := True;
      C.Source_Fingerprint := 1_147_007;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := R.Repair_Consumer_Integration;
      C.Construct := A.Construct_Container_Aggregate;
      C.Consumer := A.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114708);
      C.Construct_Name := To_Unbounded_String ("container_aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("container_aggregate");
      C.Before_Coverage := A.Coverage_Consumer_Not_Integrated;
      C.Consumer_Integrated := True;
      C.Source_Fingerprint := 1_147_008;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := R.Repair_Degradation_Replacement;
      C.Construct := A.Construct_Requeue_Statement;
      C.Consumer := A.Consumer_Tasking_Protected_Precision;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114709);
      C.Construct_Name := To_Unbounded_String ("requeue_statement");
      C.Normalized_Construct_Name := To_Unbounded_String ("requeue_statement");
      C.Before_Coverage := A.Coverage_Graceful_Degradation_Only;
      C.Degradation_Replaced := True;
      C.Source_Fingerprint := 1_147_009;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := R.Repair_Combined_Construct_Coverage;
      C.Construct := A.Construct_Variant_Part;
      C.Consumer := A.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114710);
      C.Construct_Name := To_Unbounded_String ("variant_part");
      C.Normalized_Construct_Name := To_Unbounded_String ("variant_part");
      C.Parser_Node_Repaired := True;
      C.Structural_AST_Repaired := True;
      C.Source_Span_Repaired := True;
      C.Type_Metadata_Repaired := True;
      C.Consumer_Integrated := True;
      C.Source_Fingerprint := 1_147_010;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := R.Repair_Parser_Node;
      C.Construct := A.Construct_Access_Definition;
      C.Consumer := A.Consumer_Accessibility_Lifetime;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114711);
      C.Construct_Name := To_Unbounded_String ("access_definition");
      C.Normalized_Construct_Name := To_Unbounded_String ("access_definition");
      C.Source_Fingerprint := 1_147_011;
      R.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := R.Repair_Combined_Construct_Coverage;
      C.Construct := A.Construct_Quantified_Expression;
      C.Consumer := A.Consumer_Expression_Types;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114712);
      C.Construct_Name := To_Unbounded_String ("quantified_expression");
      C.Normalized_Construct_Name := To_Unbounded_String ("quantified_expression");
      C.Parser_Node_Repaired := True;
      C.Source_Fingerprint := 1_147_012;
      R.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Repairs_Clear_Gaps_And_Preserve_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : constant R.Repair_Model := R.Build (Sample_Contexts);
      Consumer_Row : constant R.Repair_Info :=
        R.First_For_Node
          (Model, Editor.Ada_Syntax_Tree.Node_Id (114708));
   begin
      Assert (R.Repair_Count (Model) = 12, "all repair rows recorded");
      Assert (R.Repaired_Count (Model) = 10, "ten complete repairs recorded");
      Assert (R.Still_Missing_Count (Model) = 2, "unrepaired/partial coverage remains blocking");
      Assert (R.Metadata_Repair_Count (Model) >= 2, "metadata repairs counted");
      Assert (R.Consumer_Repair_Count (Model) = 2, "consumer repairs counted");
      Assert (R.Count_Status (Model, R.Repair_Parser_Node_Repaired) = 1,
              "parser-node repair classified");
      Assert (R.Count_Status (Model, R.Repair_Complete) = 1,
              "combined construct coverage can become complete");
      Assert (R.Count_Status (Model, R.Repair_Parser_Node_Still_Missing) = 1,
              "missing repair remains explicit");
      Assert (R.Count_Status (Model, R.Repair_Inconsistent_Repair) = 1,
              "partial combined repair remains explicit");
      Assert (R.Count_Construct (Model, A.Construct_Select_Statement) = 1,
              "construct lookup is deterministic");
      Assert (R.Count_Consumer (Model, A.Consumer_Record_Variant_Aggregate) = 2,
              "consumer lookup is deterministic");
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Consumer_Row.Detail),
            A.Semantic_Consumer_Family'Image
              (A.Consumer_Record_Variant_Aggregate)) > 0,
         "repair detail preserves consumer-family provenance");
      Assert (R.Fingerprint (Model) /= 0, "model fingerprint is stable and nonzero");
   end Repairs_Clear_Gaps_And_Preserve_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Repairs_Clear_Gaps_And_Preserve_Blockers'Access,
         "parser/AST coverage repairs clear gates without hiding remaining gaps");
   end Register_Tests;

end Test_Ada_AST_Coverage_Repair_Legality;
