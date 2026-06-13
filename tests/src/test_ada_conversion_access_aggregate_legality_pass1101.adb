with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101 is

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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101");
   end Name;

   procedure Test_Conversion_Static_And_Universal_Numeric
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : SL.Semantic_Context_Model;
      C        : SL.Semantic_Context_Info;
   begin
      C.Id := 1;
      C.Kind := SL.Semantic_Context_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (11);
      C.Target_Subtype := To_Unbounded_String ("Small_Int");
      C.Operand_Subtype := To_Unbounded_String ("Integer");
      C.Is_Numeric_Target := True;
      C.Is_Numeric_Operand := True;
      C.Target_Has_Static_Range := True;
      C.Target_Static_First := 1;
      C.Target_Static_Last := 10;
      C.Operand_Static_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Integer;
      C.Operand_Static_Integer_Value := 7;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := SL.Semantic_Context_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (12);
      C.Target_Subtype := To_Unbounded_String ("Small_Int");
      C.Operand_Subtype := To_Unbounded_String ("Integer");
      C.Is_Numeric_Target := True;
      C.Is_Numeric_Operand := True;
      C.Target_Has_Static_Range := True;
      C.Target_Static_First := 1;
      C.Target_Static_Last := 10;
      C.Operand_Static_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Integer;
      C.Operand_Static_Integer_Value := 99;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := SL.Semantic_Context_Qualified_Expression;
      C.Target_Subtype := To_Unbounded_String ("Integer");
      C.Operand_Subtype := To_Unbounded_String ("universal_integer");
      C.Operand_Is_Universal_Numeric := True;
      SL.Add_Context (Contexts, C);

      declare
         Model : constant SL.Semantic_Legality_Model := SL.Build (Contexts);
         Row   : SL.Semantic_Legality_Info;
      begin
         Assert (SL.Legality_Count (Model) = 3,
                 "three conversion legality rows expected");
         Assert (SL.Count_Status
                   (Model, SL.Semantic_Legality_Static_Range_Compatible) = 1,
                 "static in-range conversion should be accepted");
         Assert (SL.Static_Range_Violation_Count (Model) = 1,
                 "static out-of-range conversion should be rejected");
         Assert (SL.Universal_Numeric_Unresolved_Count (Model) = 1,
                 "unresolved universal numeric conversion should be tracked");
         Assert (SL.Conversion_Count (Model) = 3,
                 "all rows are conversion-family rows");
         Row := SL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (12));
         Assert (SL.Has_Legality (Row) and then
                   Row.Status = SL.Semantic_Legality_Static_Range_Violation,
                 "node lookup should find static range violation");
      end;
   end Test_Conversion_Static_And_Universal_Numeric;

   procedure Test_Access_Null_And_Accessibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : SL.Semantic_Context_Model;
      C        : SL.Semantic_Context_Info;
   begin
      C.Id := 10;
      C.Kind := SL.Semantic_Context_Null_Assignment;
      C.Target_Subtype := To_Unbounded_String ("not null access Integer");
      C.Target_Is_Null_Excluding := True;
      C.Operand_Is_Null_Literal := True;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 20;
      C.Kind := SL.Semantic_Context_Access_Conversion;
      C.Target_Subtype := To_Unbounded_String ("access Integer");
      C.Operand_Subtype := To_Unbounded_String ("access procedure");
      C.Target_Access := SL.Access_Kind_Object;
      C.Operand_Access := SL.Access_Kind_Subprogram;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 30;
      C.Kind := SL.Semantic_Context_Access_Parameter;
      C.Target_Subtype := To_Unbounded_String ("access Integer");
      C.Operand_Subtype := To_Unbounded_String ("access Integer");
      C.Target_Access := SL.Access_Kind_Object;
      C.Operand_Access := SL.Access_Kind_Object;
      C.Requires_Accessibility_Check := True;
      C.Accessibility_Known_Compatible := False;
      SL.Add_Context (Contexts, C);

      declare
         Model : constant SL.Semantic_Legality_Model := SL.Build (Contexts);
      begin
         Assert (SL.Access_Count (Model) = 3,
                 "three access-family rows expected");
         Assert (SL.Null_Exclusion_Violation_Count (Model) = 1,
                 "null-exclusion violation should be classified");
         Assert (SL.Access_Kind_Mismatch_Count (Model) = 1,
                 "access object/subprogram mismatch should be classified");
         Assert (SL.Accessibility_Indeterminate_Count (Model) = 1,
                 "accessibility placeholder should be a warning");
         Assert (SL.Error_Count (Model) = 2,
                 "two hard access legality errors expected");
         Assert (SL.Warning_Count (Model) = 1,
                 "one accessibility warning expected");
      end;
   end Test_Access_Null_And_Accessibility;

   procedure Test_Aggregate_And_Container_Structural_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : SL.Semantic_Context_Model;
      C        : SL.Semantic_Context_Info;
   begin
      C.Id := 100;
      C.Kind := SL.Semantic_Context_Record_Aggregate;
      C.Target_Subtype := To_Unbounded_String ("Rec");
      C.Aggregate_Expected_Component_Count := 3;
      C.Aggregate_Component_Count := 2;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 110;
      C.Kind := SL.Semantic_Context_Array_Aggregate;
      C.Target_Subtype := To_Unbounded_String ("Arr");
      C.Aggregate_Has_Index_Coverage_Error := True;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 120;
      C.Kind := SL.Semantic_Context_Container_Aggregate;
      C.Target_Subtype := To_Unbounded_String ("Vec");
      C.Container_Has_Required_Aspect := False;
      SL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 130;
      C.Kind := SL.Semantic_Context_Record_Aggregate;
      C.Target_Subtype := To_Unbounded_String ("Rec");
      C.Aggregate_Expected_Component_Count := 2;
      C.Aggregate_Component_Count := 2;
      SL.Add_Context (Contexts, C);

      declare
         Model : constant SL.Semantic_Legality_Model := SL.Build (Contexts);
         Rows  : SL.Semantic_Legality_Result_Set;
      begin
         Assert (SL.Aggregate_Count (Model) = 4,
                 "four aggregate-family rows expected");
         Assert (SL.Aggregate_Error_Count (Model) = 3,
                 "three aggregate legality errors expected");
         Assert (SL.Compatible_Count (Model) = 1,
                 "one aggregate should be accepted");
         Rows := SL.Results_For_Status
           (Model, SL.Semantic_Legality_Aggregate_Missing_Component);
         Assert (SL.Result_Count (Rows) = 1,
                 "missing component status lookup should find one row");
         Rows := SL.Rows_For_Kind (Model, SL.Semantic_Context_Record_Aggregate);
         Assert (SL.Result_Count (Rows) = 2,
                 "kind lookup should find both record aggregates");
         Assert (SL.Fingerprint (Model) /= 0,
                 "wide semantic legality model should expose a fingerprint");
      end;
   end Test_Aggregate_And_Container_Structural_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Conversion_Static_And_Universal_Numeric'Access,
         "Pass1101 checks conversion static range and universal numerics");
      Register_Routine
        (T, Test_Access_Null_And_Accessibility'Access,
         "Pass1101 checks access/null-exclusion/accessibility legality");
      Register_Routine
        (T, Test_Aggregate_And_Container_Structural_Legality'Access,
         "Pass1101 checks aggregate and container aggregate legality");
   end Register_Tests;

end Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101;
