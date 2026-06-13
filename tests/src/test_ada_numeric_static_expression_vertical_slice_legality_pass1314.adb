with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Numeric_Static_Expression_Vertical_Slice_Legality_Pass1314 is

   package NS renames Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality;
   use type NS.Expression_Id;
   use type NS.Result_Id;
   use type NS.Expression_Kind;
   use type NS.Numeric_Class;
   use type NS.Operator_Kind;
   use type NS.Legality_Status;
   use type NS.Expression_Info;
   use type NS.Result_Info;
   use type NS.Expression_Model;
   use type NS.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Numeric_Static_Expression_Vertical_Slice_Legality_Pass1314");
   end Name;

   procedure Add_Expr
     (Model : in out NS.Expression_Model;
      Id    : Natural;
      Kind  : NS.Expression_Kind;
      Text  : String;
      Op    : NS.Operator_Kind := NS.Operator_None;
      Actual : NS.Numeric_Class := NS.Numeric_Integer;
      Expected : NS.Numeric_Class := NS.Numeric_Unknown;
      Left : NS.Numeric_Class := NS.Numeric_Integer;
      Right : NS.Numeric_Class := NS.Numeric_Integer;
      Static : Boolean := True;
      Requires_Static : Boolean := True;
      AST : Boolean := True;
      Type_Evidence : Boolean := True;
      Named_Static : Boolean := True;
      Constant_Static : Boolean := True;
      Left_Static : Boolean := True;
      Right_Static : Boolean := True;
      Operator_Static : Boolean := True;
      Attribute_Static : Boolean := True;
      Qualified_OK : Boolean := True;
      Universal_Ambiguous : Boolean := False;
      Universal_Resolved : Boolean := True;
      Runtime_Check : Boolean := False;
      Range_Check : Boolean := False;
      Range_In_Base : Boolean := True;
      Modular_In_Modulus : Boolean := True;
      Divisor_Zero : Boolean := False;
      Exponent_Natural : Boolean := True;
      Fixed_Delta_OK : Boolean := True;
      Source_FP : Natural := 131400;
      AST_FP : Natural := 231400;
      Type_FP : Natural := 331400;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      I : NS.Expression_Info;
   begin
      I.Id := NS.Expression_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131400 + Id);
      I.Kind := Kind;
      I.Operator := Op;
      I.Source_Name := To_Unbounded_String (Text);
      I.Actual_Type := Actual;
      I.Expected_Type := Expected;
      I.Left_Type := Left;
      I.Right_Type := Right;
      I.Resolved_Type := Actual;
      I.Expression_Is_Static := Static;
      I.Requires_Static_Context := Requires_Static;
      I.Has_AST_Coverage := AST;
      I.Has_Type_Evidence := Type_Evidence;
      I.Named_Number_Is_Static := Named_Static;
      I.Static_Constant_Is_Static := Constant_Static;
      I.Left_Operand_Static := Left_Static;
      I.Right_Operand_Static := Right_Static;
      I.Operator_Static_Allowed := Operator_Static;
      I.Attribute_Static := Attribute_Static;
      I.Qualified_Type_Compatible := Qualified_OK;
      I.Universal_Ambiguous := Universal_Ambiguous;
      I.Universal_Resolved := Universal_Resolved;
      I.Runtime_Check_Required := Runtime_Check;
      I.Range_Check_Required := Range_Check;
      I.Range_In_Base := Range_In_Base;
      I.Modular_In_Modulus := Modular_In_Modulus;
      I.Divisor_Is_Zero := Divisor_Zero;
      I.Exponent_Is_Natural := Exponent_Natural;
      I.Fixed_Delta_Compatible := Fixed_Delta_OK;
      I.Static_Integer_Value := Long_Long_Integer (Id);
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Type_Fingerprint := Type_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      NS.Add_Expression (Model, I);
   end Add_Expr;

   procedure Accepts_Source_Shaped_Static_Numeric_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : NS.Expression_Model;
      Results : NS.Result_Model;
   begin
      Add_Expr (Model, 1, NS.Expr_Named_Number,
                "N : constant := 10", Actual => NS.Numeric_Universal_Integer,
                Expected => NS.Numeric_Integer);
      Add_Expr (Model, 2, NS.Expr_Static_Constant,
                "C : constant Integer := N + 1", Actual => NS.Numeric_Integer,
                Expected => NS.Numeric_Integer);
      Add_Expr (Model, 3, NS.Expr_Binary_Operator,
                "2 + 3", Op => NS.Operator_Add,
                Actual => NS.Numeric_Universal_Integer,
                Expected => NS.Numeric_Integer);
      Add_Expr (Model, 4, NS.Expr_Qualified_Expression,
                "Integer'(2)", Actual => NS.Numeric_Integer,
                Expected => NS.Numeric_Integer);
      Add_Expr (Model, 5, NS.Expr_Static_Attribute,
                "Integer'Last", Actual => NS.Numeric_Integer,
                Expected => NS.Numeric_Integer);
      Add_Expr (Model, 6, NS.Expr_Real_Literal,
                "1.25", Actual => NS.Numeric_Universal_Real,
                Expected => NS.Numeric_Real);

      Results := NS.Build (Model);

      Assert (NS.Result_Count (Results) = 6, "all source-shaped expressions should produce results");
      Assert (NS.Legal_Count (Results) = 6, "static numeric expressions should be legal");
      Assert (NS.Error_Count (Results) = 0, "legal static expressions should not produce errors");
      Assert (NS.Fingerprint (Results) /= 0, "result fingerprint should be stable and nonzero");
   end Accepts_Source_Shaped_Static_Numeric_Expressions;

   procedure Rejects_Staticness_And_Universal_Numeric_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : NS.Expression_Model;
      Results : NS.Result_Model;
   begin
      Add_Expr (Model, 1, NS.Expr_Named_Number,
                "N : constant := Non_Static", Named_Static => False);
      Add_Expr (Model, 2, NS.Expr_Static_Constant,
                "C : constant Integer := F", Constant_Static => False);
      Add_Expr (Model, 3, NS.Expr_Binary_Operator,
                "X + 1", Op => NS.Operator_Add, Left_Static => False);
      Add_Expr (Model, 4, NS.Expr_Binary_Operator,
                "1 ** -1", Op => NS.Operator_Exponent,
                Exponent_Natural => False);
      Add_Expr (Model, 5, NS.Expr_Integer_Literal,
                "universal integer with no expected type",
                Actual => NS.Numeric_Universal_Integer,
                Universal_Ambiguous => True);
      Add_Expr (Model, 6, NS.Expr_Real_Literal,
                "unresolved universal real",
                Actual => NS.Numeric_Universal_Real,
                Universal_Resolved => False);

      Results := NS.Build (Model);

      Assert (NS.Count_Status (Results, NS.Legality_Named_Number_Not_Static) = 1,
              "nonstatic named number should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Static_Constant_Not_Static) = 1,
              "nonstatic static constant should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Operand_Not_Static) = 1,
              "nonstatic operand should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Exponent_Not_Natural) = 1,
              "negative static exponent should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Universal_Numeric_Ambiguous) = 1,
              "ambiguous universal numeric expression should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Universal_Numeric_Not_Resolved) = 1,
              "unresolved universal numeric expression should be rejected");
   end Rejects_Staticness_And_Universal_Numeric_Errors;

   procedure Rejects_Range_Modular_Fixed_And_Attribute_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : NS.Expression_Model;
      Results : NS.Result_Model;
   begin
      Add_Expr (Model, 1, NS.Expr_Range_Bound,
                "Small range 1000", Range_In_Base => False);
      Add_Expr (Model, 2, NS.Expr_Modular_Expression,
                "Mod_Type'(Modulus + 1)", Actual => NS.Numeric_Modular,
                Modular_In_Modulus => False);
      Add_Expr (Model, 3, NS.Expr_Binary_Operator,
                "10 / 0", Op => NS.Operator_Divide,
                Divisor_Zero => True);
      Add_Expr (Model, 4, NS.Expr_Fixed_Point_Expression,
                "Fixed_Type'(0.03)", Actual => NS.Numeric_Fixed,
                Fixed_Delta_OK => False);
      Add_Expr (Model, 5, NS.Expr_Static_Attribute,
                "X'Callable", Attribute_Static => False);
      Add_Expr (Model, 6, NS.Expr_Qualified_Expression,
                "Integer'(1.5)", Qualified_OK => False);

      Results := NS.Build (Model);

      Assert (NS.Count_Status (Results, NS.Legality_Range_Out_Of_Base) = 1,
              "out-of-base static range bound should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Modular_Out_Of_Modulus) = 1,
              "modular value outside modulus should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Divide_By_Zero_Static) = 1,
              "static division by zero should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Fixed_Delta_Mismatch) = 1,
              "fixed-point delta mismatch should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Attribute_Not_Static) = 1,
              "nonstatic attribute in static context should be rejected");
      Assert (NS.Count_Status (Results, NS.Legality_Qualification_Mismatch) = 1,
              "qualified expression type mismatch should be rejected");
   end Rejects_Range_Modular_Fixed_And_Attribute_Errors;

   procedure Preserves_Evidence_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : NS.Expression_Model;
      Results : NS.Result_Model;
   begin
      Add_Expr (Model, 1, NS.Expr_Integer_Literal,
                "token-only literal", AST => False);
      Add_Expr (Model, 2, NS.Expr_Integer_Literal,
                "literal without type evidence", Type_Evidence => False,
                Actual => NS.Numeric_Unknown);
      Add_Expr (Model, 3, NS.Expr_Integer_Literal,
                "runtime range check allowed", Requires_Static => False,
                Static => False, Runtime_Check => True);
      Add_Expr (Model, 4, NS.Expr_Integer_Literal,
                "expected type mismatch", Actual => NS.Numeric_Integer,
                Expected => NS.Numeric_Boolean);
      Add_Expr (Model, 5, NS.Expr_Integer_Literal,
                "stale source fingerprint", Expected_Source_FP => 999999);
      Add_Expr (Model, 6, NS.Expr_Integer_Literal,
                "stale ast fingerprint", Expected_AST_FP => 999999);
      Add_Expr (Model, 7, NS.Expr_Integer_Literal,
                "stale type fingerprint", Expected_Type_FP => 999999);

      Results := NS.Build (Model);

      Assert (NS.Count_Status (Results, NS.Legality_Missing_AST_Coverage) = 1,
              "AST coverage blocker should be preserved");
      Assert (NS.Count_Status (Results, NS.Legality_Missing_Type_Evidence) = 1,
              "type evidence blocker should be preserved");
      Assert (NS.Count_Status (Results, NS.Legality_Legal_Nonstatic_Runtime_Check) = 1,
              "runtime-check context should remain legal but nonstatic");
      Assert (NS.Count_Status (Results, NS.Legality_Expected_Type_Mismatch) = 1,
              "expected-type mismatch should be preserved");
      Assert (NS.Count_Status (Results, NS.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be preserved");
      Assert (NS.Count_Status (Results, NS.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be preserved");
      Assert (NS.Count_Status (Results, NS.Legality_Type_Fingerprint_Mismatch) = 1,
              "type fingerprint mismatch should be preserved");
   end Preserves_Evidence_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Static_Numeric_Expressions'Access,
         "accepts source-shaped static numeric expressions");
      Register_Routine
        (T, Rejects_Staticness_And_Universal_Numeric_Errors'Access,
         "rejects staticness and universal numeric errors");
      Register_Routine
        (T, Rejects_Range_Modular_Fixed_And_Attribute_Errors'Access,
         "rejects range/modular/fixed/attribute errors");
      Register_Routine
        (T, Preserves_Evidence_And_Fingerprint_Blockers'Access,
         "preserves evidence and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Numeric_Static_Expression_Vertical_Slice_Legality_Pass1314;
