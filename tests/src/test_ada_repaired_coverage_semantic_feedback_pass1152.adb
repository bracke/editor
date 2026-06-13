with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application;
with Editor.Ada_Repaired_Coverage_Semantic_Feedback;
with Editor.Ada_Repair_Gated_Diagnostic_Integration;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Repaired_Coverage_Semantic_Feedback_Pass1152 is

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
   package Feedback renames Editor.Ada_Repaired_Coverage_Semantic_Feedback;
   use type Feedback.Feedback_Row_Id;
   use type Feedback.Feedback_Status;
   use type Feedback.Feedback_Info;
   use type Feedback.Feedback_Model;
   use type Feedback.Feedback_Set;
   package Diag renames Editor.Ada_Repair_Gated_Diagnostic_Integration;
   use type Diag.Repair_Gated_Diagnostic_Id;
   use type Diag.Repair_Gated_Diagnostic_Status;
   use type Diag.Repair_Gated_Diagnostic_Action;
   use type Diag.Repair_Gated_Diagnostic_Info;
   use type Diag.Repair_Gated_Diagnostic_Model;
   use type Diag.Repair_Gated_Diagnostic_Set;
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
      return AUnit.Format ("Test_Ada_Repaired_Coverage_Semantic_Feedback_Pass1152");
   end Name;

   procedure Add_App
     (Contexts      : in out App.Application_Context_Model;
      Id            : Natural;
      Node          : Editor.Ada_Syntax_Tree.Node_Id;
      Enforced      : Enforce.Enforcement_Status;
      Repair_Status : Repair.Repair_Status;
      Repair_Kind   : Repair.Repair_Kind;
      Conclusion    : Gates.Semantic_Conclusion_Kind;
      Consumer      : Audit.Semantic_Consumer_Family;
      Construct     : Audit.Ada_Construct_Kind;
      Name          : String) is
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
      C.Node := Node;
      C.Construct_Name := To_Unbounded_String (Name);
      C.Normalized_Name := To_Unbounded_String (Name);
      C.Repair_Message := To_Unbounded_String ("repair row " & Natural'Image (Id));
      C.Enforcement_Message := To_Unbounded_String ("enforcement row " & Natural'Image (Id));
      C.Source_Fingerprint := 1_152_000 + Id;
      App.Add_Context (Contexts, C);
   end Add_App;

   function Sample_Applications return App.Application_Model is
      Contexts : App.Application_Context_Model;
   begin
      Add_App (Contexts, 1, Editor.Ada_Syntax_Tree.Node_Id (115201),
               Enforce.Enforcement_Parser_AST_Blocker,
               Repair.Repair_Parser_Node_Repaired,
               Repair.Repair_Parser_Node,
               Gates.Conclusion_Contract,
               Audit.Consumer_Contract_Aspect,
               Audit.Construct_Aspect_Specification,
               "aspect_specification");
      Add_App (Contexts, 2, Editor.Ada_Syntax_Tree.Node_Id (115202),
               Enforce.Enforcement_Metadata_Blocker,
               Repair.Repair_Metadata_Repaired,
               Repair.Repair_Flow_Metadata,
               Gates.Conclusion_Dataflow,
               Audit.Consumer_Dataflow_Global_Depends,
               Audit.Construct_Call,
               "call");
      Add_App (Contexts, 3, Editor.Ada_Syntax_Tree.Node_Id (115203),
               Enforce.Enforcement_Consumer_Integration_Blocker,
               Repair.Repair_Consumer_Integrated,
               Repair.Repair_Consumer_Integration,
               Gates.Conclusion_Record_Variant,
               Audit.Consumer_Record_Variant_Aggregate,
               Audit.Construct_Record_Aggregate,
               "record_aggregate");
      Add_App (Contexts, 4, Editor.Ada_Syntax_Tree.Node_Id (115204),
               Enforce.Enforcement_Parser_AST_Blocker,
               Repair.Repair_Parser_Node_Still_Missing,
               Repair.Repair_Parser_Node,
               Gates.Conclusion_Accessibility,
               Audit.Consumer_Accessibility_Lifetime,
               Audit.Construct_Access_Definition,
               "access_definition");
      Add_App (Contexts, 5, Editor.Ada_Syntax_Tree.Node_Id (115205),
               Enforce.Enforcement_Cross_Unit_Closure_Required,
               Repair.Repair_Cross_Unit_Metadata_Repaired,
               Repair.Repair_Cross_Unit_Metadata,
               Gates.Conclusion_Elaboration,
               Audit.Consumer_Elaboration_Dependence,
               Audit.Construct_Generic_Instantiation,
               "generic_instantiation");
      Add_App (Contexts, 6, Editor.Ada_Syntax_Tree.Node_Id (115206),
               Enforce.Enforcement_Original_Error_Preserved,
               Repair.Repair_Complete,
               Repair.Repair_Combined_Construct_Coverage,
               Gates.Conclusion_Overload,
               Audit.Consumer_Overload,
               Audit.Construct_Call,
               "ambiguous_call");
      Add_App (Contexts, 7, Editor.Ada_Syntax_Tree.Node_Id (115207),
               Enforce.Enforcement_Degraded_To_Indeterminate,
               Repair.Repair_Indeterminate,
               Repair.Repair_Combined_Construct_Coverage,
               Gates.Conclusion_Staticness,
               Audit.Consumer_Staticness_Range_Predicate,
               Audit.Construct_Quantified_Expression,
               "quantified_expression");
      Add_App (Contexts, 8, Editor.Ada_Syntax_Tree.Node_Id (115208),
               Enforce.Enforcement_Confident_Result_Allowed,
               Repair.Repair_Audit_Already_Complete,
               Repair.Repair_Combined_Construct_Coverage,
               Gates.Conclusion_Assignment,
               Audit.Consumer_Assignment,
               Audit.Construct_Assignment,
               "assignment_statement");
      return App.Build (Contexts);
   end Sample_Applications;

   procedure Repaired_Coverage_Feeds_Legality_Consumers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Empty : Closure.Integrated_Closure_Context_Model;
      Applications : constant App.Application_Model := Sample_Applications;
      Closure_Model : constant Closure.Integrated_Closure_Model :=
        Bridge.Build_With_Repair_Gate_Application (Empty, Applications);
      Diagnostics : constant Diag.Repair_Gated_Diagnostic_Model :=
        Diag.Build (Applications, Closure_Model);
      Model : constant Feedback.Feedback_Model :=
        Feedback.Build (Applications, Diagnostics);
   begin
      Assert (Feedback.Row_Count (Model) = 8,
              "all repaired coverage applications produce semantic feedback");
      Assert (Feedback.Restored_Count (Model) = 4,
              "parser, metadata, consumer, and already-confident rows are restored");
      Assert (Feedback.Eligible_Count (Model) = 4,
              "restored local rows become direct legality inputs");
      Assert (Feedback.Blocker_Count (Model) = 4,
              "missing repair, dependency, original error, and indeterminate rows block");
      Assert (Feedback.Cross_Unit_Required_Count (Model) = 1,
              "cross-unit metadata repair still requires closure");
      Assert (Feedback.Original_Error_Count (Model) = 1,
              "original semantic error is not cleared by repair feedback");
      Assert (Feedback.Indeterminate_Count (Model) = 1,
              "degraded staticness row remains indeterminate");
      Assert (Feedback.Count_Status
                (Model, Feedback.Feedback_Construct_Structurally_Restored) = 1,
              "parser/AST repair restores construct structure");
      Assert (Feedback.Count_Status
                (Model, Feedback.Feedback_Metadata_Restored) = 1,
              "metadata repair restores a semantic consumer input");
      Assert (Feedback.Count_Status
                (Model, Feedback.Feedback_Consumer_Restored) = 1,
              "consumer integration repair restores consumer eligibility");
      Assert (Feedback.Is_Eligible_For_Engine
                (Model,
                 Editor.Ada_Syntax_Tree.Node_Id (115202),
                 Enforce.Engine_Dataflow_Global_Depends),
              "dataflow engine may consume the repaired call metadata");
      Assert (not Feedback.Is_Eligible_For_Engine
                (Model,
                 Editor.Ada_Syntax_Tree.Node_Id (115204),
                 Enforce.Engine_Accessibility_Lifetime),
              "unrepaired access definition cannot re-enter accessibility legality");
      Assert (Feedback.Count_Construct
                (Model, Audit.Construct_Call) = 2,
              "construct lookup distinguishes call repair feedback rows");
      Assert (Feedback.Fingerprint (Model) /= 0,
              "feedback fingerprint is stable");
   end Repaired_Coverage_Feeds_Legality_Consumers;

   procedure Stale_Diagnostic_Integration_Blocks_Feedback

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Empty : Closure.Integrated_Closure_Model;
      Applications : constant App.Application_Model := Sample_Applications;
      Diagnostics : constant Diag.Repair_Gated_Diagnostic_Model :=
        Diag.Build (Applications, Empty, Closure_Input_Current => False,
                    Closure_Rejected_Count => 3);
      Model : constant Feedback.Feedback_Model :=
        Feedback.Build (Applications, Diagnostics);
   begin
      Assert (Feedback.Row_Count (Model) = 8,
              "stale diagnostic integration still preserves feedback row identities");
      Assert (Feedback.Stale_Rejected_Count (Model) = 8,
              "every stale repair-gated diagnostic row blocks semantic feedback");
      Assert (Feedback.Eligible_Count (Model) = 0,
              "stale rows cannot be accepted by legality engines");
      Assert (not Feedback.Is_Eligible_For_Engine
                (Model,
                 Editor.Ada_Syntax_Tree.Node_Id (115201),
                 Enforce.Engine_Contract_Aspect),
              "stale aspect repair is rejected before contract legality consumes it");
   end Stale_Diagnostic_Integration_Blocks_Feedback;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Repaired_Coverage_Feeds_Legality_Consumers'Access,
         "repaired coverage feeds concrete widened legality consumers");
      Register_Routine
        (T,
         Stale_Diagnostic_Integration_Blocks_Feedback'Access,
         "stale repair-gated diagnostics block semantic feedback");
   end Register_Tests;

end Test_Ada_Repaired_Coverage_Semantic_Feedback_Pass1152;
