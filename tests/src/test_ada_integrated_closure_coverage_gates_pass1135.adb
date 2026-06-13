with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_Coverage_Gates_Pass1135 is

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
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates;
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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_Coverage_Gates_Pass1135");
   end Name;

   procedure Coverage_Gates_Become_Integrated_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ISC.Integrated_Closure_Context_Model;
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Assignment;
      C.Consumer := AUD.Consumer_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113501);
      C.Construct_Name := To_Unbounded_String ("assignment");
      C.Normalized_Construct_Name := To_Unbounded_String ("assignment");
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Record_Aggregate;
      C.Consumer := AUD.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113502);
      C.Construct_Name := To_Unbounded_String ("record aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("record aggregate");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Separate_Body;
      C.Consumer := AUD.Consumer_Cross_Unit_Closure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113503);
      C.Construct_Name := To_Unbounded_String ("separate body");
      C.Normalized_Construct_Name := To_Unbounded_String ("separate body");
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Container_Aggregate;
      C.Consumer := AUD.Consumer_Conversion_Access_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113504);
      C.Construct_Name := To_Unbounded_String ("container aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("container aggregate");
      C.Token_Only_Parse := True;
      AUD.Add_Context (Audit_In, C);

      declare
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Gate_Model  : constant Gates.Gate_Model :=
           Gates.Build_From_Coverage
             (Audit_Model, Gates.Conclusion_Integrated_Closure);
         Closure     : constant ISC.Integrated_Closure_Model :=
           Bridge.Build_With_Coverage_Gates (Contexts, Gate_Model);
         Legal_Row   : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113501));
         Metadata_Row : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113502));
         XUnit_Row   : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113503));
         Parser_Row  : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113504));
      begin
         Assert (ISC.Closure_Count (Closure) = 4,
                 "all coverage gate rows should become integrated closure rows");
         Assert (ISC.Legal_Count (Closure) = 1,
                 "complete coverage gates should allow legal integrated closure");
         Assert (Legal_Row.Status = ISC.Integrated_Closure_Legal_Local,
                 "open coverage gate should preserve confident local closure");
         Assert (Metadata_Row.Status = ISC.Integrated_Closure_Coverage_Gate_Blocker,
                 "metadata gate should block unsafe semantic closure");
         Assert (Metadata_Row.Blocker = ISC.Closure_Blocker_Coverage_Gate,
                 "metadata gate should preserve coverage-gate blocker family");
         Assert (Parser_Row.Status = ISC.Integrated_Closure_Coverage_Gate_Blocker,
                 "parser/AST repair gate should block unsafe semantic closure");
         Assert (XUnit_Row.Status = ISC.Integrated_Closure_Missing_Dependency,
                 "cross-unit gate should require dependency closure");
         Assert (ISC.Count_Blocker
                   (Closure, ISC.Closure_Blocker_Coverage_Gate) = 2,
                 "parser and metadata gates should be counted as coverage gate blockers");
         Assert (ISC.Dependency_Error_Count (Closure) = 1,
                 "cross-unit gate should be counted as a dependency error");
         Assert (ISC.Fingerprint (Closure) /= 0,
                 "coverage-gated closure fingerprint should be deterministic and non-zero");
      end;
   end Coverage_Gates_Become_Integrated_Closure_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Coverage_Gates_Become_Integrated_Closure_Blockers'Access,
         "coverage gates become integrated closure blockers");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Coverage_Gates_Pass1135;
