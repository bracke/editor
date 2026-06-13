with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_AST_Coverage_Repair_Gate_Application_Pass1148 is

   package App renames Editor.Ada_AST_Coverage_Repair_Gate_Application;
   use type App.Application_Row_Id;
   use type App.Application_Status;
   use type App.Application_Context_Info;
   use type App.Application_Info;
   use type App.Application_Context_Model;
   use type App.Application_Model;
   use type App.Application_Set;
   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   use type Repair.Repair_Item_Id;
   use type Repair.Repair_Kind;
   use type Repair.Repair_Status;
   use type Repair.Repair_Context_Info;
   use type Repair.Repair_Info;
   use type Repair.Repair_Context_Model;
   use type Repair.Repair_Model;
   use type Repair.Repair_Result_Set;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   use type Audit.Coverage_Item_Id;
   use type Audit.Ada_Construct_Kind;
   use type Audit.Semantic_Consumer_Family;
   use type Audit.Coverage_Status;
   use type Audit.Coverage_Context_Info;
   use type Audit.Coverage_Info;
   use type Audit.Coverage_Context_Model;
   use type Audit.Coverage_Result_Set;
   use type Audit.Coverage_Model;
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
   package Enforce renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Enforce.Enforcement_Row_Id;
   use type Enforce.Widened_Legality_Engine;
   use type Enforce.Enforcement_Status;
   use type Enforce.Enforcement_Context_Info;
   use type Enforce.Enforcement_Info;
   use type Enforce.Enforcement_Context_Model;
   use type Enforce.Enforcement_Set;
   use type Enforce.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_AST_Coverage_Repair_Gate_Application_Pass1148");
   end Name;

   procedure Add_Repair
     (Contexts : in out Repair.Repair_Context_Model;
      Id       : Natural;
      Node     : Editor.Ada_Syntax_Tree.Node_Id;
      Kind     : Repair.Repair_Kind;
      Status   : Audit.Coverage_Status;
      Consumer : Audit.Semantic_Consumer_Family;
      Name     : String;
      Complete : Boolean) is
      C : Repair.Repair_Context_Info;
   begin
      C.Id := Repair.Repair_Item_Id (Id);
      C.Kind := Kind;
      C.Construct := Audit.Construct_Aspect_Specification;
      C.Consumer := Consumer;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String (Name);
      C.Normalized_Construct_Name := To_Unbounded_String (Name);
      C.Before_Coverage := Status;
      C.Source_Fingerprint := 1_148_000 + Id;
      case Kind is
         when Repair.Repair_Parser_Node =>
            C.Parser_Node_Repaired := Complete;
         when Repair.Repair_Flow_Metadata =>
            C.Flow_Metadata_Repaired := Complete;
         when Repair.Repair_Consumer_Integration =>
            C.Consumer_Integrated := Complete;
         when Repair.Repair_Combined_Construct_Coverage =>
            C.Parser_Node_Repaired := Complete;
            C.Structural_AST_Repaired := Complete;
            C.Source_Span_Repaired := Complete;
            C.Type_Metadata_Repaired := Complete;
            C.Consumer_Integrated := Complete;
         when others =>
            null;
      end case;
      Repair.Add_Context (Contexts, C);
   end Add_Repair;

   procedure Add_Enforcement
     (Contexts : in out Enforce.Enforcement_Context_Model;
      Id       : Natural;
      Node     : Editor.Ada_Syntax_Tree.Node_Id;
      Engine   : Enforce.Widened_Legality_Engine;
      Conclusion : Gates.Semantic_Conclusion_Kind;
      Status   : Gated.Gated_Result_Status;
      Consumer : Audit.Semantic_Consumer_Family;
      Name     : String) is
      C : Enforce.Enforcement_Context_Info;
   begin
      C.Id := Enforce.Enforcement_Row_Id (Id);
      C.Engine := Engine;
      C.Conclusion := Conclusion;
      C.Original_State := Gated.Original_Result_Legal;
      C.Gated_Status := Status;
      C.Gate_Status := Gates.Gate_Parser_Node_Missing;
      C.Gate_Action := Gates.Gate_Require_Parser_AST_Repair;
      C.Construct := Audit.Construct_Aspect_Specification;
      C.Consumer := Consumer;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String (Name);
      C.Normalized_Name := To_Unbounded_String (Name);
      C.Source_Fingerprint := 2_148_000 + Id;
      Enforce.Add_Context (Contexts, C);
   end Add_Enforcement;

   function Sample_Repairs return Repair.Repair_Model is
      Contexts : Repair.Repair_Context_Model;
   begin
      Add_Repair (Contexts, 1, Editor.Ada_Syntax_Tree.Node_Id (114801),
                  Repair.Repair_Parser_Node,
                  Audit.Coverage_Parser_Node_Missing,
                  Audit.Consumer_Contract_Aspect,
                  "aspect_specification", True);
      Add_Repair (Contexts, 2, Editor.Ada_Syntax_Tree.Node_Id (114802),
                  Repair.Repair_Flow_Metadata,
                  Audit.Coverage_Flow_Metadata_Missing,
                  Audit.Consumer_Dataflow_Global_Depends,
                  "call", True);
      Add_Repair (Contexts, 3, Editor.Ada_Syntax_Tree.Node_Id (114803),
                  Repair.Repair_Consumer_Integration,
                  Audit.Coverage_Consumer_Not_Integrated,
                  Audit.Consumer_Record_Variant_Aggregate,
                  "container_aggregate", True);
      Add_Repair (Contexts, 4, Editor.Ada_Syntax_Tree.Node_Id (114804),
                  Repair.Repair_Parser_Node,
                  Audit.Coverage_Parser_Node_Missing,
                  Audit.Consumer_Accessibility_Lifetime,
                  "access_definition", False);
      Add_Repair (Contexts, 5, Editor.Ada_Syntax_Tree.Node_Id (114805),
                  Repair.Repair_Combined_Construct_Coverage,
                  Audit.Coverage_AST_Shape_Missing,
                  Audit.Consumer_Expression_Types,
                  "quantified_expression", False);
      Add_Repair (Contexts, 6, Editor.Ada_Syntax_Tree.Node_Id (114806),
                  Repair.Repair_Combined_Construct_Coverage,
                  Audit.Coverage_Complete,
                  Audit.Consumer_Integrated_Closure,
                  "assignment_statement", True);
      return Repair.Build (Contexts);
   end Sample_Repairs;

   function Sample_Enforcement return Enforce.Enforcement_Model is
      Contexts : Enforce.Enforcement_Context_Model;
   begin
      Add_Enforcement (Contexts, 1, Editor.Ada_Syntax_Tree.Node_Id (114801),
                       Enforce.Engine_Contract_Aspect,
                       Gates.Conclusion_Contract,
                       Gated.Gated_Result_Parser_AST_Repair_Required,
                       Audit.Consumer_Contract_Aspect,
                       "aspect_specification");
      Add_Enforcement (Contexts, 2, Editor.Ada_Syntax_Tree.Node_Id (114802),
                       Enforce.Engine_Dataflow_Global_Depends,
                       Gates.Conclusion_Dataflow,
                       Gated.Gated_Result_Metadata_Repair_Required,
                       Audit.Consumer_Dataflow_Global_Depends,
                       "call");
      Add_Enforcement (Contexts, 3, Editor.Ada_Syntax_Tree.Node_Id (114803),
                       Enforce.Engine_Record_Variant_Aggregate,
                       Gates.Conclusion_Record_Variant,
                       Gated.Gated_Result_Consumer_Integration_Required,
                       Audit.Consumer_Record_Variant_Aggregate,
                       "container_aggregate");
      Add_Enforcement (Contexts, 4, Editor.Ada_Syntax_Tree.Node_Id (114804),
                       Enforce.Engine_Accessibility_Lifetime,
                       Gates.Conclusion_Accessibility,
                       Gated.Gated_Result_Parser_AST_Repair_Required,
                       Audit.Consumer_Accessibility_Lifetime,
                       "access_definition");
      Add_Enforcement (Contexts, 5, Editor.Ada_Syntax_Tree.Node_Id (114805),
                       Enforce.Engine_Staticness_Range_Predicate,
                       Gates.Conclusion_Staticness,
                       Gated.Gated_Result_Degraded_Indeterminate,
                       Audit.Consumer_Expression_Types,
                       "quantified_expression");
      Add_Enforcement (Contexts, 6, Editor.Ada_Syntax_Tree.Node_Id (114806),
                       Enforce.Engine_Integrated_Closure,
                       Gates.Conclusion_Integrated_Closure,
                       Gated.Gated_Result_Confident,
                       Audit.Consumer_Integrated_Closure,
                       "assignment_statement");
      Add_Enforcement (Contexts, 7, Editor.Ada_Syntax_Tree.Node_Id (114807),
                       Enforce.Engine_Elaboration,
                       Gates.Conclusion_Elaboration,
                       Gated.Gated_Result_Cross_Unit_Required,
                       Audit.Consumer_Elaboration_Dependence,
                       "library_call");
      Add_Enforcement (Contexts, 8, Editor.Ada_Syntax_Tree.Node_Id (114808),
                       Enforce.Engine_Call_Overload,
                       Gates.Conclusion_Overload,
                       Gated.Gated_Result_Original_Error_Preserved,
                       Audit.Consumer_Overload,
                       "call");
      return Enforce.Build (Contexts);
   end Sample_Enforcement;

   procedure Repairs_Are_Applied_To_Widened_Gate_Enforcement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : constant App.Application_Model :=
        App.Build_From_Repair_And_Enforcement
          (Sample_Repairs, Sample_Enforcement);
   begin
      Assert (App.Row_Count (Model) = 8, "all enforcement rows are considered");
      Assert (App.Cleared_Count (Model) = 4,
              "parser, metadata, consumer, and already-confident rows are cleared");
      Assert (App.Still_Blocking_Count (Model) = 4,
              "missing/partial/cross-unit/original-error rows remain blocking");
      Assert (App.Missing_Repair_Count (Model) = 1,
              "missing parser repair remains explicit");
      Assert (App.Partial_Repair_Count (Model) = 1,
              "partial repair remains explicit");
      Assert (App.Cross_Unit_Required_Count (Model) = 1,
              "cross-unit repair cannot be cleared locally");
      Assert (App.Original_Error_Count (Model) = 1,
              "original semantic error is preserved");
      Assert (App.Count_Status
                (Model, App.Application_Repair_Clears_Parser_AST_Blocker) = 1,
              "parser/AST repair clears matching blocker");
      Assert (App.Count_Status
                (Model, App.Application_Repair_Clears_Metadata_Blocker) = 1,
              "metadata repair clears matching blocker");
      Assert (App.Count_Status
                (Model, App.Application_Repair_Clears_Consumer_Blocker) = 1,
              "consumer repair clears matching blocker");
      Assert (App.Count_Engine
                (Model, Enforce.Engine_Dataflow_Global_Depends) = 1,
              "engine lookup is deterministic");
      Assert (App.Count_Construct
                (Model, Audit.Construct_Aspect_Specification) = 8,
              "construct lookup remains deterministic");
      Assert (App.Fingerprint (Model) /= 0, "application fingerprint is stable");
   end Repairs_Are_Applied_To_Widened_Gate_Enforcement;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Repairs_Are_Applied_To_Widened_Gate_Enforcement'Access,
         "coverage repairs are applied to widened gate enforcement results");
   end Register_Tests;

end Test_Ada_AST_Coverage_Repair_Gate_Application_Pass1148;
