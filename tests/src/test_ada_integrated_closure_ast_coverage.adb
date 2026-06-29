with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.AST_Coverage;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_AST_Coverage is

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
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.AST_Coverage;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_AST_Coverage");
   end Name;

   procedure Converts_AST_Coverage_Gaps_To_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ISC.Integrated_Closure_Context_Model;
      Audit_In : AUD.Coverage_Context_Model;
      C        : AUD.Coverage_Context_Info;
   begin
      C.Id := 1;
      C.Construct := AUD.Construct_Aspect_Specification;
      C.Consumer := AUD.Consumer_Contract_Aspect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113301);
      C.Construct_Name := To_Unbounded_String ("Pre");
      C.Normalized_Construct_Name := To_Unbounded_String ("pre");
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 2;
      C.Construct := AUD.Construct_Container_Aggregate;
      C.Consumer := AUD.Consumer_Conversion_Access_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113302);
      C.Construct_Name := To_Unbounded_String ("container aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("container aggregate");
      C.Token_Only_Parse := True;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 3;
      C.Construct := AUD.Construct_Record_Aggregate;
      C.Consumer := AUD.Consumer_Record_Variant_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113303);
      C.Construct_Name := To_Unbounded_String ("record aggregate");
      C.Normalized_Construct_Name := To_Unbounded_String ("record aggregate");
      C.Type_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      C := (others => <>);
      C.Id := 4;
      C.Construct := AUD.Construct_Separate_Body;
      C.Consumer := AUD.Consumer_Cross_Unit_Closure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113304);
      C.Construct_Name := To_Unbounded_String ("separate body");
      C.Normalized_Construct_Name := To_Unbounded_String ("separate body");
      C.Cross_Unit_Metadata_Present := False;
      AUD.Add_Context (Audit_In, C);

      declare
         Audit_Model : constant AUD.Coverage_Model := AUD.Build (Audit_In);
         Closure     : constant ISC.Integrated_Closure_Model :=
           Bridge.Build_With_AST_Coverage (Contexts, Audit_Model);
         Token_Row   : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113302));
         XUnit_Row   : constant ISC.Integrated_Closure_Info :=
           ISC.First_For_Node (Closure, Editor.Ada_Syntax_Tree.Node_Id (113304));
      begin
         Assert (ISC.Closure_Count (Closure) = 4,
                 "all AST coverage audit rows should become closure rows");
         Assert (ISC.Legal_Count (Closure) = 1,
                 "complete parser/AST coverage should remain legal closure");
         Assert (ISC.Count_Blocker
                   (Closure, ISC.Closure_Blocker_AST_Coverage) = 2,
                 "parser and metadata gaps should be AST coverage blockers");
         Assert (Token_Row.Status = ISC.Integrated_Closure_AST_Coverage_Blocker,
                 "token-only parse should become an integrated closure blocker");
         Assert (Token_Row.Blocker = ISC.Closure_Blocker_AST_Coverage,
                 "token-only parse should preserve AST coverage blocker family");
         Assert (ISC.Dependency_Error_Count (Closure) = 1,
                 "cross-unit metadata gap should be represented as dependency failure");
         Assert (XUnit_Row.Status = ISC.Integrated_Closure_Missing_Dependency,
                 "cross-unit parser coverage gap should block closure through dependency state");
         Assert (ISC.Fingerprint (Closure) /= 0,
                 "AST coverage closure fingerprint should be deterministic and non-zero");
      end;
   end Converts_AST_Coverage_Gaps_To_Closure_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Converts_AST_Coverage_Gaps_To_Closure_Blockers'Access,
         "converts AST coverage gaps to integrated closure blockers");
   end Register_Tests;

end Test_Ada_Integrated_Closure_AST_Coverage;
