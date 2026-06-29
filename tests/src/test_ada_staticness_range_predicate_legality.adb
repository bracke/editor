with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Staticness_Range_Predicate_Legality is

   package SRP renames Editor.Ada_Staticness_Range_Predicate_Legality;
   use type SRP.Assignment_Legality_Id;
   use type SRP.Assignment_Legality_Status;
   use type SRP.Return_Legality_Id;
   use type SRP.Return_Legality_Status;
   use type SRP.Semantic_Legality_Id;
   use type SRP.Semantic_Legality_Status;
   use type SRP.Overload_Legality_Id;
   use type SRP.Overload_Legality_Status;
   use type SRP.Static_Context_Id;
   use type SRP.Static_Legality_Id;
   use type SRP.Static_Context_Kind;
   use type SRP.Predicate_Policy;
   use type SRP.Static_Legality_Status;
   use type SRP.Static_Legality_Context_Info;
   use type SRP.Static_Legality_Info;
   use type SRP.Static_Legality_Context_Model;
   use type SRP.Static_Legality_Result_Set;
   use type SRP.Static_Legality_Model;
   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package RL renames Editor.Ada_Return_Legality;
   use type RL.Assignment_Context_Id;
   use type RL.Assignment_Legality_Status;
   use type RL.Return_Context_Id;
   use type RL.Return_Legality_Id;
   use type RL.Return_Context_Kind;
   use type RL.Return_Legality_Status;
   use type RL.Return_Context_Info;
   use type RL.Return_Legality_Info;
   use type RL.Return_Context_Model;
   use type RL.Return_Legality_Result_Set;
   use type RL.Return_Legality_Model;
   package SL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type SL.Semantic_Context_Id;
   use type SL.Semantic_Legality_Id;
   use type SL.Semantic_Context_Kind;
   use type SL.Access_Kind;
   use type SL.Semantic_Legality_Status;
   use type SL.Semantic_Context_Info;
   use type SL.Semantic_Legality_Info;
   use type SL.Semantic_Context_Model;
   use type SL.Semantic_Legality_Result_Set;
   use type SL.Semantic_Legality_Model;
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
   package SE renames Editor.Ada_Static_Expressions;
   use type SE.Static_Value_Status;
   use type SE.Static_Value_Info;
   use type SE.Static_Fixed_Type_Id;
   use type SE.Static_Fixed_Type_Info;
   use type SE.Static_Modular_Type_Id;
   use type SE.Static_Modular_Type_Info;
   use type SE.Static_Enumeration_Literal_Id;
   use type SE.Static_Enumeration_Literal_Info;
   use type SE.Static_Type_Bound_Id;
   use type SE.Static_Type_Bound_Info;
   use type SE.Static_Binding_Id;
   use type SE.Static_Binding_Kind;
   use type SE.Static_Binding_Info;
   use type SE.Static_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Staticness_Range_Predicate_Legality");
   end Name;

   procedure Builds_Wide_Static_Range_And_Predicate_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : SRP.Static_Legality_Context_Model;
      C        : SRP.Static_Legality_Context_Info;
   begin
      C.Id := 1;
      C.Kind := SRP.Static_Context_Range_Constraint;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11101);
      C.Subtype_Name := To_Unbounded_String ("Small_Int");
      C.Requires_Static := True;
      C.Static_Status := SE.Static_Value_Integer;
      C.Static_Integer_Value := 4;
      C.Has_Static_Range := True;
      C.Static_First := 1;
      C.Static_Last := 10;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := SRP.Static_Context_Case_Choice;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11102);
      C.Subtype_Name := To_Unbounded_String ("Small_Int");
      C.Requires_Static := True;
      C.Static_Status := SE.Static_Value_Integer;
      C.Static_Integer_Value := 12;
      C.Has_Static_Range := True;
      C.Static_First := 1;
      C.Static_Last := 10;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := SRP.Static_Context_Discrete_Choice;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11103);
      C.Static_Status := SE.Static_Value_Integer;
      C.Static_Integer_Value := 3;
      C.Duplicate_Choice_Count := 1;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := SRP.Static_Context_Predicate_Check;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11104);
      C.Predicate := SRP.Predicate_Static_Known_False;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := SRP.Static_Context_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11105);
      C.Requires_Static := True;
      C.Static_Status := SE.Static_Value_Non_Static;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := SRP.Static_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11106);
      C.Assignment := AL.Assignment_Legality_Id (6);
      C.Assignment_Status := AL.Assignment_Legality_Compatible;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := SRP.Static_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11107);
      C.Return_Item := RL.Return_Legality_Id (7);
      C.Return_Status := RL.Return_Legality_Result_Static_Range_Violation;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := SRP.Static_Context_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11108);
      C.Semantic_Item := SL.Semantic_Legality_Id (8);
      C.Semantic_Status := SL.Semantic_Legality_Universal_Numeric_Unresolved;
      SRP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := SRP.Static_Context_Overload_Actual;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11109);
      C.Overload_Item := ORL.Overload_Legality_Id (9);
      C.Overload_Status := ORL.Overload_Legality_Legal_Expected_Type_Preferred;
      SRP.Add_Context (Contexts, C);

      declare
         Model : constant SRP.Static_Legality_Model := SRP.Build (Contexts);
         Small : constant SRP.Static_Legality_Result_Set :=
           SRP.Rows_For_Subtype (Model, "small_int");
         Predicate_Fails : constant SRP.Static_Legality_Result_Set :=
           SRP.Rows_For_Predicate (Model, SRP.Predicate_Static_Known_False);
      begin
         Assert (SRP.Legality_Count (Model) = 9,
                 "all static/range/predicate contexts should produce legality rows");
         Assert (SRP.Legal_Count (Model) = 3,
                 "range, linked assignment, and linked overload contexts should be legal");
         Assert (SRP.Error_Count (Model) = 6,
                 "range, duplicate choice, predicate, staticness, return, and universal numeric errors should be counted");
         Assert (SRP.Static_Required_Error_Count (Model) = 1,
                 "non-static expression in static-required context should be counted");
         Assert (SRP.Range_Error_Count (Model) = 2,
                 "choice out-of-range and duplicate choice should be range-family errors");
         Assert (SRP.Predicate_Error_Count (Model) = 1,
                 "static predicate failure should be counted");
         Assert (SRP.Linked_Error_Count (Model) = 1,
                 "linked return failure should be counted");
         Assert (SRP.Universal_Numeric_Unresolved_Count (Model) = 1,
                 "linked universal numeric unresolved status should be counted");
         Assert (SRP.Result_Count (Small) = 2,
                 "case-insensitive subtype lookup should return both Small_Int rows");
         Assert (SRP.Result_Count (Predicate_Fails) = 1,
                 "predicate lookup should find static predicate failures");
         Assert (SRP.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (11102)).Status =
                 SRP.Static_Legality_Choice_Out_Of_Range,
                 "node lookup should preserve static choice range classification");
      end;
   end Builds_Wide_Static_Range_And_Predicate_Legality;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : SRP.Static_Legality_Context_Model;
      Model    : constant SRP.Static_Legality_Model := SRP.Build (Contexts);
   begin
      Assert (SRP.Legality_Count (Model) = 0,
              "empty static/range/predicate context model should produce no rows");
      Assert (not SRP.Has_Legality
                (SRP.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (1))),
              "absent static/range/predicate node lookup should return no legality row");
   end Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Wide_Static_Range_And_Predicate_Legality'Access,
         "Pass1110 classifies staticness, range, predicate, and linked semantic legality");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Pass1110 keeps empty static/range/predicate legality models deterministic");
   end Register_Tests;

end Test_Ada_Staticness_Range_Predicate_Legality;
