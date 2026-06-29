with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;

package body Test_Ada_Overload_Preference_Legality is

   package OP renames Editor.Ada_Overload_Preference_Legality;
   use type OP.Preference_Context_Id;
   use type OP.Preference_Legality_Id;
   use type OP.Preference_Context_Kind;
   use type OP.Preference_Legality_Status;
   use type OP.Preference_Context_Info;
   use type OP.Preference_Legality_Info;
   use type OP.Preference_Context_Model;
   use type OP.Preference_Legality_Result_Set;
   use type OP.Preference_Legality_Model;
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
   package RK renames Editor.Ada_Overload_Ranking;
   use type RK.Overload_Ranking_Id;
   use type RK.Overload_Ranking_Status;
   use type RK.Overload_Ranking_Info;
   use type RK.Overload_Ranking_Result_Set;
   use type RK.Overload_Ranking_Model;
   package WD renames Editor.Ada_Wide_Semantic_Legality_Diagnostics;
   use type WD.Wide_Semantic_Diagnostic_Id;
   use type WD.Wide_Semantic_Diagnostic_Family;
   use type WD.Wide_Semantic_Diagnostic_Severity;
   use type WD.Wide_Semantic_Diagnostic_Kind;
   use type WD.Wide_Semantic_Diagnostic_Info;
   use type WD.Wide_Semantic_Diagnostic_Result_Set;
   use type WD.Wide_Semantic_Diagnostic_Model;

   use type OP.Preference_Legality_Status;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Overload_Preference_Legality");
   end Name;

   procedure Build_Overload_Preference_Model
     (Overloads : out ORL.Overload_Legality_Model;
      Contexts  : in out OP.Preference_Context_Model)
   is
      Overload_Contexts : ORL.Overload_Context_Model;
      Rankings          : RK.Overload_Ranking_Model;
      Wide              : WD.Wide_Semantic_Diagnostic_Model;
      OC                : ORL.Overload_Context_Info;
      PC                : OP.Preference_Context_Info;
   begin
      OC.Id := 1;
      OC.Kind := ORL.Overload_Context_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11261);
      OC.Designator := To_Unbounded_String ("F");
      OC.Candidate_Count := 3;
      OC.Visible_Candidate_Count := 3;
      OC.Expected_Type_Match_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC.Id := 1;
      PC.Kind := OP.Preference_Context_Call;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11261);
      PC.Designator := To_Unbounded_String ("F");
      PC.Direct_Visibility_Count := 1;
      PC.Use_Visibility_Count := 2;
      PC.Selected_Profile_Count := 1;
      PC.Legal_Candidate_Count := 3;
      OP.Add_Context (Contexts, PC);

      OC := (others => <>);
      OC.Id := 2;
      OC.Kind := ORL.Overload_Context_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11262);
      OC.Designator := To_Unbounded_String ("G");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Universal_Integer_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC := (others => <>);
      PC.Id := 2;
      PC.Kind := OP.Preference_Context_Call;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11262);
      PC.Designator := To_Unbounded_String ("G");
      PC.Universal_Integer_Count := 1;
      PC.Universal_Real_Count := 0;
      PC.Selected_Profile_Count := 1;
      PC.Legal_Candidate_Count := 2;
      OP.Add_Context (Contexts, PC);

      OC := (others => <>);
      OC.Id := 3;
      OC.Kind := ORL.Overload_Context_Operator;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11263);
      OC.Designator := To_Unbounded_String ("+");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Primitive_Operator_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC := (others => <>);
      PC.Id := 3;
      PC.Kind := OP.Preference_Context_Operator;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11263);
      PC.Designator := To_Unbounded_String ("+");
      PC.Primitive_Operator_Count := 1;
      PC.Selected_Profile_Count := 1;
      PC.Legal_Candidate_Count := 2;
      OP.Add_Context (Contexts, PC);

      OC := (others => <>);
      OC.Id := 4;
      OC.Kind := ORL.Overload_Context_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11264);
      OC.Designator := To_Unbounded_String ("Tie");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Exact_Match_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC := (others => <>);
      PC.Id := 4;
      PC.Kind := OP.Preference_Context_Call;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11264);
      PC.Designator := To_Unbounded_String ("Tie");
      PC.Expected_Type_Tie_Count := 2;
      PC.Selected_Profile_Count := 2;
      PC.Legal_Candidate_Count := 2;
      OP.Add_Context (Contexts, PC);

      OC := (others => <>);
      OC.Id := 5;
      OC.Kind := ORL.Overload_Context_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11265);
      OC.Designator := To_Unbounded_String ("Hidden");
      OC.Candidate_Count := 1;
      OC.Visible_Candidate_Count := 0;
      OC.Candidate_Not_Visible_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC := (others => <>);
      PC.Id := 5;
      PC.Kind := OP.Preference_Context_Call;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11265);
      PC.Designator := To_Unbounded_String ("Hidden");
      PC.Rejected_Candidate_Count := 1;
      OP.Add_Context (Contexts, PC);

      OC := (others => <>);
      OC.Id := 6;
      OC.Kind := ORL.Overload_Context_Dispatching_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (11266);
      OC.Designator := To_Unbounded_String ("Dispatch");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Class_Wide_Conversion_Count := 1;
      ORL.Add_Context (Overload_Contexts, OC);

      PC := (others => <>);
      PC.Id := 6;
      PC.Kind := OP.Preference_Context_Dispatching_Call;
      PC.Node := Editor.Ada_Syntax_Tree.Node_Id (11266);
      PC.Designator := To_Unbounded_String ("Dispatch");
      PC.Dispatching_Primitive_Count := 1;
      PC.Class_Wide_Count := 1;
      PC.Selected_Profile_Count := 1;
      PC.Legal_Candidate_Count := 2;
      OP.Add_Context (Contexts, PC);

      Overloads := ORL.Build (Overload_Contexts, Rankings, Wide);
   end Build_Overload_Preference_Model;

   procedure Applies_Ada_Preference_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Overloads : ORL.Overload_Legality_Model;
      Contexts  : OP.Preference_Context_Model;
   begin
      Build_Overload_Preference_Model (Overloads, Contexts);

      declare
         Model : constant OP.Preference_Legality_Model := OP.Build (Overloads, Contexts);
         Calls : constant OP.Preference_Legality_Result_Set :=
           OP.Rows_For_Kind (Model, OP.Preference_Context_Call);
      begin
         Assert (OP.Legality_Count (Model) = 6,
                 "all overload preference contexts should produce legality rows");
         Assert (OP.Legal_Count (Model) = 4,
                 "direct visibility, universal integer, primitive, and dispatching preferences should be legal");
         Assert (OP.Ambiguous_Count (Model) = 1,
                 "expected-type ties should remain ambiguous after preference refinement");
         Assert (OP.Linked_Overload_Error_Count (Model) = 1,
                 "not-visible overload legality should block preference refinement");
         Assert (OP.Result_Count (Calls) = 4,
                 "call preference lookups should preserve context kind");
         Assert (OP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11261)).Status =
                 OP.Preference_Legality_Legal_Direct_Visibility_Preferred,
                 "direct visibility should outrank use-visible overload candidates");
         Assert (OP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11263)).Status =
                 OP.Preference_Legality_Legal_Primitive_Operator_Preferred,
                 "primitive operator preference should be preserved");
         Assert (OP.Count_Status
                   (Model, OP.Preference_Legality_Ambiguous_Expected_Type_Tie) = 1,
                 "expected-type ties should be a distinct ambiguity class");
         Assert (OP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11266)).Status =
                 OP.Preference_Legality_Legal_Dispatching_Primitive_Preferred,
                 "dispatching primitive evidence should refine class-wide overload legality");
      end;
   end Applies_Ada_Preference_Order;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Overloads : ORL.Overload_Legality_Model;
      Contexts  : OP.Preference_Context_Model;
      Model     : constant OP.Preference_Legality_Model := OP.Build (Overloads, Contexts);
   begin
      Assert (OP.Legality_Count (Model) = 0,
              "empty preference contexts should produce no legality rows");
      Assert (not OP.Has_Legality
                (OP.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
              "absent preference node lookup should return no legality item");
   end Empty_Inputs_Are_Deterministic;

   procedure Builds_Contexts_From_Overload_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Overload_Contexts : ORL.Overload_Context_Model;
      OC                : ORL.Overload_Context_Info;
      Rankings          : RK.Overload_Ranking_Model;
      Wide              : WD.Wide_Semantic_Diagnostic_Model;
   begin
      OC.Id := 31;
      OC.Kind := ORL.Overload_Context_Operator;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (112631);
      OC.Designator := To_Unbounded_String ("+");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Primitive_Operator_Count := 1;
      OC.Start_Line := 19;
      OC.End_Line := 19;
      ORL.Add_Context (Overload_Contexts, OC);

      OC := (others => <>);
      OC.Id := 32;
      OC.Kind := ORL.Overload_Context_Call;
      OC.Node := Editor.Ada_Syntax_Tree.Node_Id (112632);
      OC.Designator := To_Unbounded_String ("Tie");
      OC.Candidate_Count := 2;
      OC.Visible_Candidate_Count := 2;
      OC.Ambiguous_Candidate_Count := 2;
      ORL.Add_Context (Overload_Contexts, OC);

      declare
         Overloads : constant ORL.Overload_Legality_Model :=
           ORL.Build (Overload_Contexts, Rankings, Wide);
         Contexts : constant OP.Preference_Context_Model :=
           OP.Build_Contexts_From_Overload_Legality (Overloads);
         Preferences : constant OP.Preference_Legality_Model :=
           OP.Build (Overloads, Contexts);
      begin
         Assert (OP.Context_Count (Contexts) = ORL.Legality_Count (Overloads),
                 "overload legality rows should derive preference contexts");
         Assert (OP.First_For_Node
                   (Preferences, Editor.Ada_Syntax_Tree.Node_Id (112631)).Status =
                 OP.Preference_Legality_Legal_Primitive_Operator_Preferred,
                 "derived primitive operator evidence should preserve preference status");
         Assert (OP.Ambiguous_Count (Preferences) = 1,
                 "derived ambiguous overload evidence should remain a preference ambiguity");
         Assert (OP.First_For_Node
                   (Preferences, Editor.Ada_Syntax_Tree.Node_Id (112631)).Start_Line = 19,
                 "derived preference context should preserve source span");
         Assert (OP.Fingerprint (Preferences) /= 0,
                 "derived preference model should fingerprint deterministically");
      end;
   end Builds_Contexts_From_Overload_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Applies_Ada_Preference_Order'Access,
         "Pass1126 applies Ada overload preference ordering to legal overload rows");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Pass1126 keeps empty overload preference models deterministic");
      Register_Routine
        (T, Builds_Contexts_From_Overload_Legality'Access,
         "Pass1126 derives preference contexts from overload legality");
   end Register_Tests;

end Test_Ada_Overload_Preference_Legality;
