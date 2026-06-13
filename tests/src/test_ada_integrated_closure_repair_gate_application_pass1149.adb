with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Integrated_Closure_Repair_Gate_Application_Pass1149 is

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
   package Gated renames Editor.Ada_Coverage_Gated_Semantic_Results;
   use type Gated.Gated_Result_Id;
   use type Gated.Original_Result_State;
   use type Gated.Gated_Result_Status;
   use type Gated.Gated_Result_Context_Info;
   use type Gated.Gated_Result_Info;
   use type Gated.Gated_Result_Context_Model;
   use type Gated.Gated_Result_Set;
   use type Gated.Gated_Result_Model;
   package Closure renames Editor.Ada_Integrated_Semantic_Closure;
   use type Closure.Wide_Diagnostic_Status;
   use type Closure.Overload_Status;
   use type Closure.Static_Status;
   use type Closure.Accessibility_Status;
   use type Closure.Contract_Status;
   use type Closure.Elaboration_Status;
   use type Closure.Completion_Status;
   use type Closure.Renaming_Status;
   use type Closure.Exception_Status;
   use type Closure.Representation_Status;
   use type Closure.Refined_Global_Depends_Status;
   use type Closure.Integrated_Closure_Context_Id;
   use type Closure.Integrated_Closure_Id;
   use type Closure.Integrated_Closure_Context_Kind;
   use type Closure.Closure_Dependency_State;
   use type Closure.Closure_Blocker_Family;
   use type Closure.Integrated_Closure_Status;
   use type Closure.Integrated_Closure_Context_Info;
   use type Closure.Integrated_Closure_Info;
   use type Closure.Integrated_Closure_Context_Model;
   use type Closure.Integrated_Closure_Result_Set;
   use type Closure.Integrated_Closure_Model;
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application;
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
      return AUnit.Format ("Test_Ada_Integrated_Closure_Repair_Gate_Application_Pass1149");
   end Name;

   procedure Add_App
     (Contexts : in out App.Application_Context_Model;
      Id       : Natural;
      Node     : Editor.Ada_Syntax_Tree.Node_Id;
      Enforced : Enforce.Enforcement_Status;
      Repair_Status : Repair.Repair_Status;
      Repair_Kind : Repair.Repair_Kind;
      Conclusion : Gates.Semantic_Conclusion_Kind;
      Consumer : Audit.Semantic_Consumer_Family;
      Construct : Audit.Ada_Construct_Kind;
      Name : String) is
      C : App.Application_Context_Info;
   begin
      C.Id := App.Application_Row_Id (Id);
      C.Repair_Id := Repair.Repair_Item_Id (Id);
      C.Enforcement_Id := Enforce.Enforcement_Row_Id (Id);
      C.Engine := Enforce.Engine_For (Conclusion, Consumer);
      C.Enforcement_Status := Enforced;
      C.Repair_Status := Repair_Status;
      C.Repair_Kind := Repair_Kind;
      C.Conclusion := Conclusion;
      C.Construct := Construct;
      C.Consumer := Consumer;
      C.Original_State := Gated.Original_Result_Legal;
      C.Gate_Status := Gates.Gate_Parser_Node_Missing;
      C.Gate_Action := Gates.Gate_Require_Parser_AST_Repair;
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String (Name);
      C.Normalized_Name := To_Unbounded_String (Name);
      C.Source_Fingerprint := 1_149_000 + Id;
      App.Add_Context (Contexts, C);
   end Add_App;

   function Sample_Applications return App.Application_Model is
      Contexts : App.Application_Context_Model;
   begin
      Add_App (Contexts, 1, Editor.Ada_Syntax_Tree.Node_Id (114901),
               Enforce.Enforcement_Parser_AST_Blocker,
               Repair.Repair_Parser_Node_Repaired,
               Repair.Repair_Parser_Node,
               Gates.Conclusion_Contract,
               Audit.Consumer_Contract_Aspect,
               Audit.Construct_Aspect_Specification,
               "aspect_specification");
      Add_App (Contexts, 2, Editor.Ada_Syntax_Tree.Node_Id (114902),
               Enforce.Enforcement_Metadata_Blocker,
               Repair.Repair_Metadata_Repaired,
               Repair.Repair_Flow_Metadata,
               Gates.Conclusion_Dataflow,
               Audit.Consumer_Dataflow_Global_Depends,
               Audit.Construct_Call,
               "call");
      Add_App (Contexts, 3, Editor.Ada_Syntax_Tree.Node_Id (114903),
               Enforce.Enforcement_Consumer_Integration_Blocker,
               Repair.Repair_Consumer_Integrated,
               Repair.Repair_Consumer_Integration,
               Gates.Conclusion_Record_Variant,
               Audit.Consumer_Record_Variant_Aggregate,
               Audit.Construct_Record_Aggregate,
               "record_aggregate");
      Add_App (Contexts, 4, Editor.Ada_Syntax_Tree.Node_Id (114904),
               Enforce.Enforcement_Parser_AST_Blocker,
               Repair.Repair_Parser_Node_Still_Missing,
               Repair.Repair_Parser_Node,
               Gates.Conclusion_Accessibility,
               Audit.Consumer_Accessibility_Lifetime,
               Audit.Construct_Access_Definition,
               "access_definition");
      Add_App (Contexts, 5, Editor.Ada_Syntax_Tree.Node_Id (114905),
               Enforce.Enforcement_Degraded_To_Indeterminate,
               Repair.Repair_Indeterminate,
               Repair.Repair_Combined_Construct_Coverage,
               Gates.Conclusion_Staticness,
               Audit.Consumer_Expression_Types,
               Audit.Construct_Quantified_Expression,
               "quantified_expression");
      Add_App (Contexts, 6, Editor.Ada_Syntax_Tree.Node_Id (114906),
               Enforce.Enforcement_Cross_Unit_Closure_Required,
               Repair.Repair_Cross_Unit_Metadata_Repaired,
               Repair.Repair_Cross_Unit_Metadata,
               Gates.Conclusion_Elaboration,
               Audit.Consumer_Elaboration_Dependence,
               Audit.Construct_Pragma,
               "with_clause");
      Add_App (Contexts, 7, Editor.Ada_Syntax_Tree.Node_Id (114907),
               Enforce.Enforcement_Original_Error_Preserved,
               Repair.Repair_Complete,
               Repair.Repair_Combined_Construct_Coverage,
               Gates.Conclusion_Overload,
               Audit.Consumer_Overload,
               Audit.Construct_Call,
               "ambiguous_call");
      return App.Build (Contexts);
   end Sample_Applications;

   procedure Repair_Applied_Gates_Feed_Integrated_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Empty : Closure.Integrated_Closure_Context_Model;
      Model : constant Closure.Integrated_Closure_Model :=
        Bridge.Build_With_Repair_Gate_Application (Empty, Sample_Applications);
   begin
      Assert (Closure.Closure_Count (Model) = 7,
              "all repair-applied rows flow into integrated closure");
      Assert (Closure.Legal_Count (Model) = 3,
              "cleared repairs regain legal closure rows");
      Assert (Closure.Count_Status
                (Model, Closure.Integrated_Closure_Coverage_Gate_Blocker) = 2,
              "unrepaired and original-error rows remain gate blockers");
      Assert (Closure.Count_Status
                (Model, Closure.Integrated_Closure_Indeterminate) = 1,
              "partial or indeterminate repair remains indeterminate");
      Assert (Closure.Count_Status
                (Model, Closure.Integrated_Closure_Missing_Dependency) = 1,
              "cross-unit required row remains a dependency failure");
      Assert (Closure.Count_Blocker
                (Model, Closure.Closure_Blocker_Coverage_Gate) = 2,
              "coverage gate blocker family is preserved");
      Assert (Closure.Count_Dependency
                (Model, Closure.Dependency_Missing) = 1,
              "dependency lookup is deterministic");
      Assert (Closure.Fingerprint (Model) /= 0,
              "repair-gate integrated closure fingerprint is stable");
   end Repair_Applied_Gates_Feed_Integrated_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Repair_Applied_Gates_Feed_Integrated_Closure'Access,
         "repair-applied coverage gates feed integrated semantic closure");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Repair_Gate_Application_Pass1149;
