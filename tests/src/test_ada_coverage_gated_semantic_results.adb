with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Gated_Results;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Coverage_Gated_Semantic_Results is

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
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   use type Gates.Gate_Item_Id;
   use type Gates.Semantic_Conclusion_Kind;
   use type Gates.Gate_Action;
   use type Gates.Gate_Status;
   use type Gates.Gate_Context_Info;
   use type Gates.Gate_Info;
   use type Gates.Gate_Context_Model;
   use type Gates.Gate_Result_Set;
   use type Gates.Gate_Model;
   package Gated renames Editor.Ada_Coverage_Gated_Semantic_Results;
   use type Gated.Gated_Result_Id;
   use type Gated.Original_Result_State;
   use type Gated.Gated_Result_Status;
   use type Gated.Gated_Result_Context_Info;
   use type Gated.Gated_Result_Info;
   use type Gated.Gated_Result_Context_Model;
   use type Gated.Gated_Result_Set;
   use type Gated.Gated_Result_Model;
   package ISC renames Editor.Ada_Integrated_Semantic_Closure;
   use type ISC.Wide_Diagnostic_Status;
   use type ISC.Overload_Status;
   use type ISC.Static_Status;
   use type ISC.Accessibility_Status;
   use type ISC.Contract_Status;
   use type ISC.Elaboration_Status;
   use type ISC.Completion_Status;
   use type ISC.Renaming_Status;
   use type ISC.Exception_Status;
   use type ISC.Representation_Status;
   use type ISC.Refined_Global_Depends_Status;
   use type ISC.Integrated_Closure_Context_Id;
   use type ISC.Integrated_Closure_Id;
   use type ISC.Integrated_Closure_Context_Kind;
   use type ISC.Closure_Dependency_State;
   use type ISC.Closure_Blocker_Family;
   use type ISC.Integrated_Closure_Status;
   use type ISC.Integrated_Closure_Context_Info;
   use type ISC.Integrated_Closure_Info;
   use type ISC.Integrated_Closure_Context_Model;
   use type ISC.Integrated_Closure_Result_Set;
   use type ISC.Integrated_Closure_Model;
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Gated_Results;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Coverage_Gated_Semantic_Results");
   end Name;

   procedure Coverage_Gates_Annotate_Original_Semantic_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Assignment;
      C.Consumer := AUD.Consumer_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113601);
      C.Construct_Name := To_Unbounded_String ("assignment");
      C.Normalized_Construct_Name := To_Unbounded_String ("assignment");
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Record_Aggregate;
      C.Consumer := AUD.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113602);
      C.Construct_Name := To_Unbounded_String ("record aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("record aggregate");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Generic_Instantiation;
      C.Consumer := AUD.Consumer_Generic_Instance_Body_Expansion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113603);
      C.Construct_Name := To_Unbounded_String ("generic instantiation");
      C.Normalized_Construct_Name := To_Unbounded_String ("generic instantiation");
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Reduction_Expression;
      C.Consumer := AUD.Consumer_Expression_Types;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113604);
      C.Construct_Name := To_Unbounded_String ("reduction expression");
      C.Normalized_Construct_Name := To_Unbounded_String ("reduction expression");
      C.Graceful_Degradation_Only := True;
      AUD.Add_Context (Audit_In, C);

      declare
         Contexts    : ISC.Integrated_Closure_Context_Model;
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Gate_Model  : constant Gates.Gate_Model :=
           Gates.Build_From_Coverage (Audit_Model, Gates.Conclusion_Aggregate);
         Gated_Model : constant Gated.Gated_Result_Model :=
           Gated.Build_From_Gates (Gate_Model, Gated.Original_Result_Legal);
         Legal_Row   : constant Gated.Gated_Result_Info :=
           Gated.First_For_Node (Gated_Model, Editor.Ada_Syntax_Tree.Node_Id (113601));
         Metadata_Row : constant Gated.Gated_Result_Info :=
           Gated.First_For_Node (Gated_Model, Editor.Ada_Syntax_Tree.Node_Id (113602));
         XUnit_Row   : constant Gated.Gated_Result_Info :=
           Gated.First_For_Node (Gated_Model, Editor.Ada_Syntax_Tree.Node_Id (113603));
         Suppressed_Row : constant Gated.Gated_Result_Info :=
           Gated.First_For_Node (Gated_Model, Editor.Ada_Syntax_Tree.Node_Id (113604));
         Closure     : constant ISC.Integrated_Closure_Model :=
           Bridge.Build_With_Gated_Results
             (Contexts, Gated_Model);
         Closure_Metadata : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113602));
         Closure_XUnit : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113603));
      begin
         Assert (Gated.Result_Count (Gated_Model) = 4,
                 "all gate rows should become coverage-gated semantic rows");
         Assert (Legal_Row.Status = Gated.Gated_Result_Confident,
                 "complete coverage should preserve confident legality");
         Assert (Metadata_Row.Status = Gated.Gated_Result_Metadata_Repair_Required,
                 "missing type metadata should require metadata repair");
         Assert (Metadata_Row.Consumer = AUD.Consumer_Record_Variant_Aggregate,
                 "original record/variant semantic consumer should be preserved");
         Assert (XUnit_Row.Status = Gated.Gated_Result_Cross_Unit_Required,
                 "cross-unit gaps should be preserved as cross-unit requirements");
         Assert (Suppressed_Row.Status = Gated.Gated_Result_Legal_Suppressed,
                 "graceful degradation should suppress legal conclusions");
         Assert (Gated.Confident_Count (Gated_Model) = 1,
                 "one row should remain confident");
         Assert (Gated.Repair_Required_Count (Gated_Model) = 1,
                 "one row should require metadata repair");
         Assert (Gated.Cross_Unit_Required_Count (Gated_Model) = 1,
                 "one row should require cross-unit closure");
         Assert (Gated.Suppressed_Count (Gated_Model) = 1,
                 "one row should be suppressed");
         Assert (Gated.Unsafe_Blocker_Count (Gated_Model) = 3,
                 "all non-confident rows should be counted as unsafe blockers");
         Assert (Gated.Count_Conclusion
                   (Gated_Model, Gates.Conclusion_Aggregate) = 4,
                 "original conclusion family should be queryable");
         Assert (Gated.Fingerprint (Gated_Model) /= 0,
                 "coverage-gated semantic fingerprint should be deterministic and non-zero");
         Assert (ISC.Closure_Count (Closure) = 4,
                 "gated semantic rows should flow into integrated closure");
         Assert (Closure_Metadata.Status = ISC.Integrated_Closure_Coverage_Gate_Blocker,
                 "metadata-repair gated result should become closure blocker");
         Assert (Closure_Metadata.Blocker = ISC.Closure_Blocker_Coverage_Gate,
                 "metadata-repair result should preserve coverage-gate blocker family");
         Assert (Closure_XUnit.Status = ISC.Integrated_Closure_Missing_Dependency,
                 "cross-unit gated result should become dependency failure");
      end;
   end Coverage_Gates_Annotate_Original_Semantic_Families;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Coverage_Gates_Annotate_Original_Semantic_Families'Access,
         "coverage gates annotate original semantic families");
   end Register_Tests;

end Test_Ada_Coverage_Gated_Semantic_Results;
