with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1350;

package body Test_Ada_RM_Gap_Burn_Down_Pass1350 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1350;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Static_Construct_Kind;
   use type Audit.Static_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1350");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Subtype_Constraint_Static_Choice_Predicate;
      Construct : Audit.Static_Construct_Kind := Audit.Construct_Subtype_Indication;
      Context : Audit.Static_Context_Kind := Audit.Context_Subtype_Constraint;
      Family : Audit.RM_Family := Matrix.Family_Types_Subtypes_Constraints_Predicates;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Subtype_Range_Predicate;
      Previous_State : Audit.Remediation_State := Remediation.State_Partial;
      Matrix_Before : Audit.Coverage_Level := Matrix.Coverage_Partial;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Remediation_Present : Boolean := True;
      Matrix_Present : Boolean := True;
      Package_Present : Boolean := True;
      New_Rule : Boolean := True;
      Coverage_Updated : Boolean := True;
      Corpus_Balanced : Boolean := True;
      Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker : Boolean := True;
      Discrete_Subtype_OK : Boolean := True;
      Range_Bounds_OK : Boolean := True;
      Range_Order_OK : Boolean := True;
      Modular_Modulus_OK : Boolean := True;
      Floating_Digits_OK : Boolean := True;
      Fixed_Delta_OK : Boolean := True;
      Array_Index_Discrete : Boolean := True;
      Discriminant_Constraint_OK : Boolean := True;
      Static_Expression_OK : Boolean := True;
      Divide_By_Zero : Boolean := False;
      Exponent_Natural : Boolean := True;
      Universal_Resolution_OK : Boolean := True;
      Static_Attribute_OK : Boolean := True;
      Choice_Type_OK : Boolean := True;
      Choice_Static_OK : Boolean := True;
      Choices_Overlap : Boolean := False;
      Case_Coverage_OK : Boolean := True;
      Duplicate_Others : Boolean := False;
      Others_Placement_OK : Boolean := True;
      Static_Predicate_Static : Boolean := True;
      Static_Predicate_Holds : Boolean := True;
      Range_Runtime_Check : Boolean := False;
      Bounds_Runtime_Check : Boolean := False;
      Predicate_Runtime_Check : Boolean := False;
      Membership_Runtime_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Aggregate_Consumes : Boolean := True;
      Assignment_Consumes : Boolean := True;
      Loop_Consumes : Boolean := True;
      Representation_Consumes : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Static : Boolean := False;
      Missing_Type : Boolean := False;
      Consumer_Subtype_Agrees : Boolean := True;
      Consumer_Static_Agrees : Boolean := True;
      Consumer_Choice_Agrees : Boolean := True;
      Consumer_Predicate_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Static_FP : Natural := 0;
      Expected_Choice_FP : Natural := 0;
      Expected_Predicate_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_350_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Family;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("subtype static choice predicate burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1350");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_350_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Remediation_Entry_Present := Remediation_Present;
      Row.Matrix_Coverage_Present := Matrix_Present;
      Row.Implementing_Package_Present := Package_Present;
      Row.New_Legality_Rule_Added := New_Rule;
      Row.Coverage_Entry_Updated_To_Covered := Coverage_Updated;
      Row.Balanced_Regression_Evidence := Corpus_Balanced;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Reached := Consumer_Reached;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Discrete_Subtype_Required_Satisfied := Discrete_Subtype_OK;
      Row.Range_Bounds_Within_Base := Range_Bounds_OK;
      Row.Range_Lower_LE_Upper := Range_Order_OK;
      Row.Modular_Modulus_Compatible := Modular_Modulus_OK;
      Row.Floating_Digits_Compatible := Floating_Digits_OK;
      Row.Fixed_Delta_Compatible := Fixed_Delta_OK;
      Row.Array_Index_Discrete := Array_Index_Discrete;
      Row.Discriminant_Constraint_Compatible := Discriminant_Constraint_OK;
      Row.Static_Expression_When_Required := Static_Expression_OK;
      Row.Static_Divide_By_Zero := Divide_By_Zero;
      Row.Static_Exponent_Natural := Exponent_Natural;
      Row.Universal_Resolution_Agrees := Universal_Resolution_OK;
      Row.Static_Attribute_Prefix_Compatible := Static_Attribute_OK;
      Row.Choice_Type_Compatible := Choice_Type_OK;
      Row.Choice_Static_When_Required := Choice_Static_OK;
      Row.Choices_Overlap := Choices_Overlap;
      Row.Case_Coverage_Complete := Case_Coverage_OK;
      Row.Duplicate_Others := Duplicate_Others;
      Row.Others_Placement_Valid := Others_Placement_OK;
      Row.Static_Predicate_Is_Static := Static_Predicate_Static;
      Row.Static_Predicate_Holds := Static_Predicate_Holds;
      Row.Range_Runtime_Check := Range_Runtime_Check;
      Row.Bounds_Runtime_Check := Bounds_Runtime_Check;
      Row.Predicate_Runtime_Check := Predicate_Runtime_Check;
      Row.Membership_Runtime_Check := Membership_Runtime_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Aggregate_Static_Choice_Consumes := Aggregate_Consumes;
      Row.Assignment_Range_Predicate_Consumes := Assignment_Consumes;
      Row.Loop_Discrete_Subtype_Consumes := Loop_Consumes;
      Row.Representation_Static_Position_Consumes := Representation_Consumes;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View_Evidence := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Static_Evidence := Missing_Static;
      Row.Missing_Type_Evidence := Missing_Type;
      Row.Consumer_Subtype_Model_Agrees := Consumer_Subtype_Agrees;
      Row.Consumer_Static_Model_Agrees := Consumer_Static_Agrees;
      Row.Consumer_Choice_Model_Agrees := Consumer_Choice_Agrees;
      Row.Consumer_Predicate_Model_Agrees := Consumer_Predicate_Agrees;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Burn_Down_Fingerprint := FP + 1;
      Row.Expected_Burn_Down_Fingerprint :=
        (if Expected_Burn_FP = 0 then Row.Burn_Down_Fingerprint else Expected_Burn_FP);
      Row.Source_Fingerprint := FP + 2;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 3;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Type_Fingerprint := FP + 4;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Static_Fingerprint := FP + 5;
      Row.Expected_Static_Fingerprint :=
        (if Expected_Static_FP = 0 then Row.Static_Fingerprint else Expected_Static_FP);
      Row.Choice_Fingerprint := FP + 6;
      Row.Expected_Choice_Fingerprint :=
        (if Expected_Choice_FP = 0 then Row.Choice_Fingerprint else Expected_Choice_FP);
      Row.Predicate_Fingerprint := FP + 7;
      Row.Expected_Predicate_Fingerprint :=
        (if Expected_Predicate_FP = 0 then Row.Predicate_Fingerprint else Expected_Predicate_FP);
      Row.Profile_Fingerprint := FP + 8;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 9;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 10;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 11;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Classification : Audit.Precision_Classification) is
      R : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (R.Status = Status, "unexpected status for row" & Natural'Image (Id));
      Assert (R.Classification = Classification,
              "unexpected classification for row" & Natural'Image (Id));
   end Expect_Status;

   procedure Test_Balanced_Subtype_Static_Predicate_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Subtype_Indication,
               Context => Audit.Context_Subtype_Constraint,
               Consumer => Consumers.Consumer_Hover_Details);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Construct => Audit.Construct_Case_Choice,
               Context => Audit.Context_Case_Coverage,
               Choices_Overlap => True,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Dynamic_Predicate,
               Context => Audit.Context_Assignment_Conversion,
               Predicate_Runtime_Check => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Construct => Audit.Construct_Qualified_Static_Expression,
               Missing_Static => True,
               Owner => Matrix.Slice_Numeric_Static_Expression,
               Family => Matrix.Family_Static_Expressions_Choices);

      Results := Audit.Build (Input);

      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced subtype/static/predicate gap is ready");
      Assert (Audit.Subtype_Static_Predicate_Gap_Closed (Results),
              "target subtype/static/predicate gap closed");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Overlapping_Choices,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Predicate_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Static_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Balanced_Subtype_Static_Predicate_Gap_Closes;

   procedure Test_Subtype_And_Static_Expression_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Discrete_Subtype_OK => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Range_Bounds_OK => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Range_Order_OK => False);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Construct => Audit.Construct_Modular_Constraint,
               Modular_Modulus_OK => False);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Construct => Audit.Construct_Floating_Digits_Constraint,
               Floating_Digits_OK => False);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Construct => Audit.Construct_Fixed_Delta_Constraint,
               Fixed_Delta_OK => False);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Construct => Audit.Construct_Array_Index_Constraint,
               Array_Index_Discrete => False);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Construct => Audit.Construct_Discriminant_Constraint,
               Discriminant_Constraint_OK => False);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Construct => Audit.Construct_Qualified_Static_Expression,
               Context => Audit.Context_Static_Evaluation,
               Static_Expression_OK => False,
               Owner => Matrix.Slice_Numeric_Static_Expression,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 19, Precision.Class_Illegal,
               Construct => Audit.Construct_Static_Arithmetic,
               Context => Audit.Context_Static_Evaluation,
               Divide_By_Zero => True,
               Owner => Matrix.Slice_Numeric_Static_Expression,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 20, Precision.Class_Illegal,
               Construct => Audit.Construct_Static_Arithmetic,
               Context => Audit.Context_Static_Evaluation,
               Exponent_Natural => False,
               Owner => Matrix.Slice_Numeric_Static_Expression,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 21, Precision.Class_Illegal,
               Construct => Audit.Construct_Integer_Literal,
               Context => Audit.Context_Static_Evaluation,
               Universal_Resolution_OK => False,
               Owner => Matrix.Slice_Numeric_Static_Expression,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 22, Precision.Class_Illegal,
               Construct => Audit.Construct_Static_Attribute,
               Context => Audit.Context_Static_Evaluation,
               Static_Attribute_OK => False,
               Owner => Matrix.Slice_Selected_Name_Attribute,
               Family => Matrix.Family_Names_Visibility_Selected_Attributes);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Non_Discrete_Subtype,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Range_Bounds_Out_Of_Base,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Range_Lower_Greater_Than_Upper,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Modular_Modulus_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Floating_Digits_Constraint,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Fixed_Delta_Constraint,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Array_Index_Non_Discrete,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17,
                     Audit.Status_Illegal_Discriminant_Constraint_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 18, Audit.Status_Illegal_Static_Expression_Required,
                     Precision.Class_Illegal);
      Expect_Status (Results, 19, Audit.Status_Illegal_Static_Divide_By_Zero,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20, Audit.Status_Illegal_Static_Exponent_Not_Natural,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Static_Universal_Resolution_Failed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Static_Attribute_Prefix_Mismatch,
                     Precision.Class_Illegal);
   end Test_Subtype_And_Static_Expression_Blockers;

   procedure Test_Choices_Predicates_Runtime_And_Cross_Slice_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Construct => Audit.Construct_Case_Choice,
               Choice_Type_OK => False,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Construct => Audit.Construct_Variant_Choice,
               Choice_Static_OK => False,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 32, Precision.Class_Illegal,
               Construct => Audit.Construct_Case_Expression_Choice,
               Choices_Overlap => True,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Construct => Audit.Construct_Case_Choice,
               Case_Coverage_OK => False,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 34, Precision.Class_Illegal,
               Construct => Audit.Construct_Aggregate_Choice,
               Duplicate_Others => True,
               Owner => Matrix.Slice_Aggregate,
               Family => Matrix.Family_Aggregates);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Construct => Audit.Construct_Aggregate_Choice,
               Others_Placement_OK => False,
               Owner => Matrix.Slice_Aggregate,
               Family => Matrix.Family_Aggregates);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Construct => Audit.Construct_Static_Predicate,
               Static_Predicate_Static => False);
      Add_Row (Input, 37, Precision.Class_Illegal,
               Construct => Audit.Construct_Static_Predicate,
               Static_Predicate_Holds => False);
      Add_Row (Input, 38, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Range_Constraint,
               Range_Runtime_Check => True,
               Owner => Matrix.Slice_Assignment_Conversion,
               Family => Matrix.Family_Assignments_Conversions);
      Add_Row (Input, 39, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Index_Choice,
               Bounds_Runtime_Check => True,
               Owner => Matrix.Slice_Array_Container_Indexing,
               Family => Matrix.Family_Arrays_Records_Discriminants_Variants);
      Add_Row (Input, 40, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Dynamic_Predicate,
               Predicate_Runtime_Check => True);
      Add_Row (Input, 41, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Membership_Choice,
               Membership_Runtime_Check => True,
               Owner => Matrix.Slice_Membership_Case_Choice,
               Family => Matrix.Family_Static_Expressions_Choices);
      Add_Row (Input, 42, Precision.Class_Illegal,
               Construct => Audit.Construct_Aggregate_Choice,
               Aggregate_Consumes => False,
               Owner => Matrix.Slice_Aggregate,
               Family => Matrix.Family_Aggregates);
      Add_Row (Input, 43, Precision.Class_Illegal,
               Context => Audit.Context_Assignment_Conversion,
               Assignment_Consumes => False,
               Owner => Matrix.Slice_Assignment_Conversion,
               Family => Matrix.Family_Assignments_Conversions);
      Add_Row (Input, 44, Precision.Class_Illegal,
               Construct => Audit.Construct_Loop_Parameter,
               Context => Audit.Context_Loop_Iterator,
               Loop_Consumes => False,
               Owner => Matrix.Slice_Iterator_Loop_Parallel,
               Family => Matrix.Family_Iterators_Parallel_Reductions);
      Add_Row (Input, 45, Precision.Class_Illegal,
               Construct => Audit.Construct_Representation_Position,
               Context => Audit.Context_Representation_Layout,
               Representation_Consumes => False,
               Owner => Matrix.Slice_Record_Layout_Representation,
               Family => Matrix.Family_Representation_Aspects_Freezing);
      Add_Row (Input, 46, Precision.Class_Legal_With_Runtime_Check,
               Range_Runtime_Check => True,
               Runtime_Check_Preserved => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Choice_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Illegal_Non_Static_Choice,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Overlapping_Choices,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Illegal_Incomplete_Case_Coverage,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Illegal_Duplicate_Others,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Illegal_Others_Placement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Static_Predicate_Not_Static,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37,
                     Audit.Status_Illegal_Static_Predicate_False_For_Subtype,
                     Precision.Class_Illegal);
      Expect_Status (Results, 38, Audit.Status_Runtime_Range_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 39, Audit.Status_Runtime_Bounds_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 40, Audit.Status_Runtime_Predicate_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 41, Audit.Status_Runtime_Membership_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Aggregate_Static_Choice_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_Assignment_Range_Evidence_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 44,
                     Audit.Status_Illegal_Loop_Discrete_Subtype_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 45,
                     Audit.Status_Illegal_Representation_Static_Position_Disagreement,
                     Precision.Class_Illegal);
      Assert (Audit.Result_For (Results, 46).Status =
              Audit.Status_Runtime_Check_Evidence_Lost,
              "lost runtime range evidence rejected");
   end Test_Choices_Predicates_Runtime_And_Cross_Slice_Blockers;

   procedure Test_Indeterminate_Consumers_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 60, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 61, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 62, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 63, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 64, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 65, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);
      Add_Row (Input, 66, Precision.Class_Indeterminate,
               Missing_Static => True);
      Add_Row (Input, 67, Precision.Class_Indeterminate,
               Missing_Type => True);
      Add_Row (Input, 68, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 69, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 70, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 71, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 72, Precision.Class_Legal,
               Consumer_Subtype_Agrees => False);
      Add_Row (Input, 73, Precision.Class_Legal,
               Consumer_Static_Agrees => False);
      Add_Row (Input, 74, Precision.Class_Legal,
               Consumer_Choice_Agrees => False);
      Add_Row (Input, 75, Precision.Class_Legal,
               Consumer_Predicate_Agrees => False);
      Add_Row (Input, 76, Precision.Class_Illegal,
               Choices_Overlap => True,
               Stable_Blocker => False);
      Add_Row (Input, 77, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 78, Precision.Class_Legal,
               Expected_Static_FP => 42);
      Add_Row (Input, 79, Precision.Class_Legal,
               Expected_Choice_FP => 42);
      Add_Row (Input, 80, Precision.Class_Legal,
               Expected_Predicate_FP => 42);
      Add_Row (Input, 81, Precision.Class_Legal,
               Expected_Substitution_FP => 42);
      Add_Row (Input, 82, Precision.Class_Legal,
               Expected_Effect_FP => 42);
      Add_Row (Input, 83, Precision.Class_Legal,
               Expected_Consumer_FP => 42);

      Results := Audit.Build (Input);

      Expect_Status (Results, 60, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 61, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 62, Audit.Status_Indeterminate_Incomplete_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 63, Audit.Status_Indeterminate_Generic_Formal_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 64, Audit.Status_Indeterminate_Missing_Full_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 65,
                     Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 66, Audit.Status_Indeterminate_Missing_Static_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 67, Audit.Status_Indeterminate_Missing_Type_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped subtype/static evidence rejected");
      Assert (Audit.Result_For (Results, 69).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing remediation evidence rejected");
      Assert (Audit.Result_For (Results, 70).Status =
              Audit.Status_Coverage_Not_Updated_To_Covered,
              "coverage promotion gate enforced");
      Assert (Audit.Result_For (Results, 71).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed subtype/static result rejected");
      Assert (Audit.Result_For (Results, 72).Status =
              Audit.Status_Consumer_Subtype_Model_Disagreement,
              "consumer subtype disagreement rejected");
      Assert (Audit.Result_For (Results, 73).Status =
              Audit.Status_Consumer_Static_Model_Disagreement,
              "consumer static disagreement rejected");
      Assert (Audit.Result_For (Results, 74).Status =
              Audit.Status_Consumer_Choice_Model_Disagreement,
              "consumer choice disagreement rejected");
      Assert (Audit.Result_For (Results, 75).Status =
              Audit.Status_Consumer_Predicate_Model_Disagreement,
              "consumer predicate disagreement rejected");
      Assert (Audit.Result_For (Results, 76).Status =
              Audit.Status_Unstable_Blocker_Family,
              "unstable static/choice blocker family rejected");
      Assert (Audit.Result_For (Results, 77).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale burn-down fingerprint rejected");
      Assert (Audit.Result_For (Results, 78).Status =
              Audit.Status_Static_Fingerprint_Mismatch,
              "static fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 79).Status =
              Audit.Status_Choice_Fingerprint_Mismatch,
              "choice fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 80).Status =
              Audit.Status_Predicate_Fingerprint_Mismatch,
              "predicate fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 81).Status =
              Audit.Status_Substitution_Fingerprint_Mismatch,
              "substitution fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 82).Status =
              Audit.Status_Effect_Fingerprint_Mismatch,
              "effect fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 83).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_Consumers_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Subtype_Static_Predicate_Gap_Closes'Access,
         "balanced subtype/static/predicate gap closure");
      Register_Routine
        (T, Test_Subtype_And_Static_Expression_Blockers'Access,
         "subtype and static expression blockers");
      Register_Routine
        (T, Test_Choices_Predicates_Runtime_And_Cross_Slice_Blockers'Access,
         "choices predicates runtime and cross-slice blockers");
      Register_Routine
        (T, Test_Indeterminate_Consumers_And_Audit_Gates'Access,
         "indeterminate consumers and audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1350;
