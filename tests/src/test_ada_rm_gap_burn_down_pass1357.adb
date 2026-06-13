with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1357;

package body Test_Ada_RM_Gap_Burn_Down_Pass1357 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1357;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Operator_Construct_Kind;
   use type Audit.Numeric_Context_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1357");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Construct : Audit.Operator_Construct_Kind :=
        Audit.Construct_Arithmetic_Operator;
      Context : Audit.Numeric_Context_Kind := Audit.Context_Expected_Type;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Predefined_Operation_Numeric_Model;
      Row.Family := Matrix.Family_Expressions_Expected_Type_Resolution;
      Row.Owner := Matrix.Slice_Numeric_Static_Expression;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String
        ("pass1357 source-shaped predefined operation numeric row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1357");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1357 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1357 classification");
   end Expect_Status;

   procedure Test_Balanced_Numeric_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Expected_Type);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Construct_User_Defined_Operator,
                       Audit.Context_Overload_Resolution);
      Row.User_Defined_Operator_Ambiguous := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Universal_Integer_Expression,
                       Audit.Context_Assignment_Conversion);
      Row.Runtime_Overflow_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Modular_Operation,
                       Audit.Context_Subtype_Range_Predicate);
      Row.Runtime_Range_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Construct_Generic_Formal_Operator,
                       Audit.Context_Generic_Replay);
      Row.Missing_Generic_Substitution_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Illegal,
                       Audit.Construct_Division_Rem_Mod,
                       Audit.Context_Static_Expression);
      Row.Static_Division_By_Zero := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Predefined_Operation_Numeric_Model_Gap_Closed (Results),
              "balanced predefined operation numeric gap closes");
      Assert (Results.Legal_Count = 1, "legal numeric row counted");
      Assert (Results.Illegal_Count = 2, "illegal numeric rows counted");
      Assert (Results.Runtime_Check_Count = 2,
              "runtime numeric rows counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate numeric row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2,
                     Audit.Status_Illegal_User_Defined_Operator_Ambiguity,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3,
                     Audit.Status_Runtime_Overflow_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4,
                     Audit.Status_Runtime_Range_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 5,
                     Audit.Status_Indeterminate_Missing_Generic_Substitution_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 6, Audit.Status_Illegal_Static_Division_By_Zero,
                     Precision.Class_Illegal);
   end Test_Balanced_Numeric_Gap_Closes;

   procedure Test_Predefined_Universal_And_Overload_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal);
      Row.Same_Canonical_Operator := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal);
      Row.Predefined_Operator_Available := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Construct_Universal_Real_Expression,
                       Audit.Context_Expected_Type);
      Row.Universal_Resolution_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Construct_Static_Constant,
                       Audit.Context_Static_Expression);
      Row.Static_Evaluation_Agrees_With_Overload := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal,
                       Audit.Construct_User_Defined_Operator,
                       Audit.Context_Use_Type_Visibility);
      Row.No_Visible_Operator := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Illegal,
                       Audit.Construct_User_Defined_Operator,
                       Audit.Context_Use_Type_Visibility);
      Row.Use_Type_Operator_Visibility_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (16, Precision.Class_Illegal,
                       Audit.Construct_Generic_Formal_Operator,
                       Audit.Context_Generic_Replay);
      Row.Callable_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (17, Precision.Class_Illegal,
                       Audit.Construct_Generic_Formal_Operator,
                       Audit.Context_Generic_Replay);
      Row.Generic_Formal_Operator_Substitution_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10,
                     Audit.Status_Illegal_Canonical_Operator_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Predefined_Operator_Unavailable,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Universal_Resolution_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Static_Evaluation_Overload_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_No_Visible_Operator,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15,
                     Audit.Status_Illegal_Use_Type_Operator_Visibility_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16,
                     Audit.Status_Illegal_Callable_Profile_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17,
                     Audit.Status_Illegal_Generic_Formal_Operator_Substitution_Lost,
                     Precision.Class_Illegal);
   end Test_Predefined_Universal_And_Overload_Blockers;

   procedure Test_Numeric_Model_Static_Runtime_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Construct_Modular_Operation);
      Row.Modular_Operand_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Construct_Fixed_Point_Operation);
      Row.Fixed_Point_Operand_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Construct_Floating_Operation);
      Row.Floating_Operand_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Construct_Arithmetic_Operator);
      Row.Integer_Operand_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Construct_Array_String_Operator);
      Row.Array_String_Operator_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (25, Precision.Class_Illegal,
                       Audit.Construct_Access_Equality);
      Row.Access_Equality_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (26, Precision.Class_Illegal,
                       Audit.Construct_Tagged_Equality);
      Row.Tagged_Equality_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (27, Precision.Class_Illegal,
                       Audit.Construct_Enumeration_Ordering);
      Row.Enumeration_Ordering_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (28, Precision.Class_Illegal,
                       Audit.Construct_Exponentiation,
                       Audit.Context_Static_Expression);
      Row.Exponent_Natural := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (29, Precision.Class_Illegal,
                       Audit.Construct_Universal_Integer_Expression,
                       Audit.Context_Static_Expression);
      Row.Static_Overflow := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (30, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Universal_Integer_Expression,
                       Audit.Context_Assignment_Conversion);
      Row.Runtime_Overflow_Check := True;
      Row.Runtime_Check_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Modular_Operand_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Fixed_Point_Operand_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Floating_Operand_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23,
                     Audit.Status_Illegal_Integer_Operand_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Array_String_Operator_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Access_Equality_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 26,
                     Audit.Status_Illegal_Tagged_Equality_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 27,
                     Audit.Status_Illegal_Enumeration_Ordering_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 28, Audit.Status_Illegal_Exponent_Not_Natural,
                     Precision.Class_Illegal);
      Expect_Status (Results, 29, Audit.Status_Illegal_Static_Overflow,
                     Precision.Class_Illegal);
      Expect_Status (Results, 30, Audit.Status_Runtime_Check_Evidence_Lost,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Numeric_Model_Static_Runtime_Blockers;

   procedure Test_Cross_Slice_Consumer_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Illegal,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Assignment_Conversion);
      Row.Assignment_Conversion_Numeric_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (41, Precision.Class_Illegal,
                       Audit.Construct_Relational_Operator,
                       Audit.Context_Subtype_Range_Predicate);
      Row.Subtype_Range_Predicate_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (42, Precision.Class_Illegal,
                       Audit.Construct_Generic_Formal_Operator,
                       Audit.Context_Generic_Replay);
      Row.Generic_Replay_Numeric_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (43, Precision.Class_Illegal,
                       Audit.Construct_Boolean_Operator,
                       Audit.Context_Contract_Predicate);
      Row.Contract_Predicate_Numeric_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (44, Precision.Class_Indeterminate);
      Row.Missing_Operator_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (45, Precision.Class_Indeterminate);
      Row.Missing_Expected_Type_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (46, Precision.Class_Unknown);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (47, Precision.Class_Unknown);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (48, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Diagnostics);
      Row.Consumer_Numeric_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (49, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Colouring_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (50, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Outline_Model);
      Row.Consumer_Declaration_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (51, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Target_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (52, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Hover_Details);
      Row.Consumer_Detail_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (53, Precision.Class_Unknown,
                       Audit.Construct_Arithmetic_Operator,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Consumer_Diagnostic_Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (54, Precision.Class_Unknown);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (55, Precision.Class_Unknown);
      Row.Expected_Operator_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (56, Precision.Class_Unknown);
      Row.Expected_Expected_Type_Context_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (57, Precision.Class_Unknown);
      Row.Expected_Static_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (58, Precision.Class_Unknown);
      Row.Expected_Overload_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (59, Precision.Class_Unknown);
      Row.Expected_Consumer_Fingerprint := 99;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40,
                     Audit.Status_Illegal_Assignment_Conversion_Numeric_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Subtype_Range_Predicate_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Generic_Replay_Numeric_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_Contract_Predicate_Numeric_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 44,
                     Audit.Status_Indeterminate_Missing_Operator_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 45,
                     Audit.Status_Indeterminate_Missing_Expected_Type_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 46).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped numeric evidence rejected");
      Assert (Audit.Result_For (Results, 47).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed numeric result rejected");
      Assert (Audit.Result_For (Results, 48).Status =
              Audit.Status_Illegal_Diagnostics_Numeric_Disagreement,
              "diagnostic numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 49).Status =
              Audit.Status_Illegal_Colouring_Numeric_Disagreement,
              "colouring numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 50).Status =
              Audit.Status_Illegal_Outline_Declaration_Numeric_Disagreement,
              "outline numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 51).Status =
              Audit.Status_Illegal_Navigation_Target_Numeric_Disagreement,
              "navigation numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 52).Status =
              Audit.Status_Illegal_Hover_Numeric_Disagreement,
              "hover numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 53).Status =
              Audit.Status_Illegal_Diagnostic_Bridge_Numeric_Disagreement,
              "diagnostic bridge numeric disagreement rejected");
      Assert (Audit.Result_For (Results, 54).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale numeric evidence rejected");
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Operator_Fingerprint_Mismatch,
              "operator fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Expected_Type_Fingerprint_Mismatch,
              "expected-type fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Static_Fingerprint_Mismatch,
              "static fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Overload_Fingerprint_Mismatch,
              "overload fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Cross_Slice_Consumer_And_Fingerprint_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Numeric_Gap_Closes'Access,
         "balanced predefined operation numeric gap closure");
      Register_Routine
        (T, Test_Predefined_Universal_And_Overload_Blockers'Access,
         "predefined universal and overload blockers");
      Register_Routine
        (T, Test_Numeric_Model_Static_Runtime_Blockers'Access,
         "numeric model static and runtime blockers");
      Register_Routine
        (T, Test_Cross_Slice_Consumer_And_Fingerprint_Gates'Access,
         "cross-slice consumer and numeric fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1357;
