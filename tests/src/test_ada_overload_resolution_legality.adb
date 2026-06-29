with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;

package body Test_Ada_Overload_Resolution_Legality is

   package ORL renames Editor.Ada_Overload_Resolution_Legality;
   use type ORL.Overload_Context_Id;
   use type ORL.Overload_Legality_Id;
   use type ORL.Overload_Context_Kind;
   use type ORL.Overload_Legality_Status;
   use type ORL.Overload_Context_Info;
   use type ORL.Overload_Legality_Info;
   use type ORL.Overload_Context_Model;
   use type ORL.Overload_Legality_Result_Set;
   use type ORL.Overload_Legality_Model;
   package WD renames Editor.Ada_Wide_Semantic_Legality_Diagnostics;
   use type WD.Wide_Semantic_Diagnostic_Id;
   use type WD.Wide_Semantic_Diagnostic_Family;
   use type WD.Wide_Semantic_Diagnostic_Severity;
   use type WD.Wide_Semantic_Diagnostic_Kind;
   use type WD.Wide_Semantic_Diagnostic_Info;
   use type WD.Wide_Semantic_Diagnostic_Result_Set;
   use type WD.Wide_Semantic_Diagnostic_Model;
   package RK renames Editor.Ada_Overload_Ranking;
   use type RK.Overload_Ranking_Id;
   use type RK.Overload_Ranking_Status;
   use type RK.Overload_Ranking_Info;
   use type RK.Overload_Ranking_Result_Set;
   use type RK.Overload_Ranking_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Overload_Resolution_Legality");
   end Name;

   procedure Builds_Wide_Overload_Legality_Categories
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ORL.Overload_Context_Model;
      Rankings : RK.Overload_Ranking_Model;
      Wide     : WD.Wide_Semantic_Diagnostic_Model;
      C        : ORL.Overload_Context_Info;
   begin
      C.Id := 1;
      C.Kind := ORL.Overload_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11091);
      C.Designator := To_Unbounded_String ("F");
      C.Candidate_Count := 3;
      C.Visible_Candidate_Count := 3;
      C.Expected_Type_Match_Count := 1;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := ORL.Overload_Context_Operator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11092);
      C.Designator := To_Unbounded_String ("+");
      C.Candidate_Count := 2;
      C.Visible_Candidate_Count := 2;
      C.Primitive_Operator_Count := 1;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := ORL.Overload_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11093);
      C.Designator := To_Unbounded_String ("G");
      C.Candidate_Count := 2;
      C.Visible_Candidate_Count := 2;
      C.Universal_Integer_Count := 1;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := ORL.Overload_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11094);
      C.Designator := To_Unbounded_String ("Hidden");
      C.Candidate_Count := 1;
      C.Visible_Candidate_Count := 0;
      C.Candidate_Not_Visible_Count := 1;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := ORL.Overload_Context_Dispatching_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11095);
      C.Designator := To_Unbounded_String ("P");
      C.Candidate_Count := 2;
      C.Visible_Candidate_Count := 2;
      C.Ambiguous_Candidate_Count := 2;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := ORL.Overload_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11096);
      C.Designator := To_Unbounded_String ("Private_Op");
      C.Candidate_Count := 1;
      C.Visible_Candidate_Count := 1;
      C.Private_View_Barrier := True;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := ORL.Overload_Context_Generic_Actual_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11097);
      C.Designator := To_Unbounded_String ("Formal_Action");
      C.Candidate_Count := 1;
      C.Visible_Candidate_Count := 1;
      C.Defaulted_Formal_Mismatch_Count := 1;
      ORL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := ORL.Overload_Context_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11098);
      C.Designator := To_Unbounded_String ("Remote.F");
      C.Candidate_Count := 1;
      C.Visible_Candidate_Count := 1;
      C.Cross_Unit_Unresolved := True;
      ORL.Add_Context (Contexts, C);

      declare
         Model : constant ORL.Overload_Legality_Model :=
           ORL.Build (Contexts, Rankings, Wide);
         Calls : constant ORL.Overload_Legality_Result_Set :=
           ORL.Rows_For_Kind (Model, ORL.Overload_Context_Call);
         Expected : constant ORL.Overload_Legality_Result_Set :=
           ORL.Rows_For_Status
             (Model, ORL.Overload_Legality_Legal_Expected_Type_Preferred);
      begin
         Assert (ORL.Legality_Count (Model) = 8,
                 "all overload contexts should produce legality rows");
         Assert (ORL.Legal_Count (Model) = 3,
                 "expected, primitive operator, and universal integer preferences should be legal");
         Assert (ORL.Error_Count (Model) = 5,
                 "visibility, ambiguity, view, default, and cross-unit errors should be counted");
         Assert (ORL.Ambiguous_Count (Model) = 1,
                 "ambiguous candidates should remain visible after preference checks");
         Assert (ORL.Visibility_Error_Count (Model) = 1,
                 "not-visible candidates should be classified separately from type errors");
         Assert (ORL.View_Barrier_Count (Model) = 1,
                 "private/limited view barriers should be counted");
         Assert (ORL.Cross_Unit_Unresolved_Count (Model) = 1,
                 "cross-unit unresolved overload state should be counted");
         Assert (ORL.Count_Status
                   (Model, ORL.Overload_Legality_Defaulted_Formal_Mismatch) = 1,
                 "defaulted formal mismatch should be a distinct overload failure");
         Assert (ORL.Result_Count (Calls) = 5,
                 "call-context lookups should include all call rows");
         Assert (ORL.Result_Count (Expected) = 1,
                 "status lookup should find expected-type preferred overloads");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11092)).Status =
                 ORL.Overload_Legality_Legal_Primitive_Operator_Preferred,
                 "operator node lookup should preserve primitive preference classification");
      end;
   end Builds_Wide_Overload_Legality_Categories;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ORL.Overload_Context_Model;
      Rankings : RK.Overload_Ranking_Model;
      Wide     : WD.Wide_Semantic_Diagnostic_Model;
      Model    : constant ORL.Overload_Legality_Model :=
        ORL.Build (Contexts, Rankings, Wide);
   begin
      Assert (ORL.Legality_Count (Model) = 0,
              "empty overload context model should produce no legality rows");
      Assert (not ORL.Has_Legality
                (ORL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
              "absent node lookup should return no legality item");
   end Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Overload_Legality_Categories'Access,
         "Pass1109 classifies wide overload/operator legality preferences and errors");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Pass1109 keeps empty overload legality models deterministic");
   end Register_Tests;

end Test_Ada_Overload_Resolution_Legality;
