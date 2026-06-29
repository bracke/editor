with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1346;

package body Test_Ada_RM_Gap_Burn_Down_Case_1346 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1346;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Tagged_Construct_Kind;
   use type Audit.Dispatch_Context_Kind;
   use type Audit.Contract_Effect_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Tagged_Interface_Dispatching_Contract_Effect;
      Construct : Audit.Tagged_Construct_Kind := Audit.Construct_Tagged_Type_Extension;
      Dispatch_Context : Audit.Dispatch_Context_Kind := Audit.Dispatch_Dispatching_Call;
      Effect_Context : Audit.Contract_Effect_Context_Kind := Audit.Effect_Dispatching_Join;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Tagged_Dispatching;
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
      Tagged_Parent_Is_Tagged : Boolean := True;
      Parent_Visible : Boolean := True;
      Interface_Primitives_Implemented : Boolean := True;
      Abstract_Primitives_Implemented : Boolean := True;
      Synchronized_Interface_Compatible : Boolean := True;
      Limited_Interface_Compatible : Boolean := True;
      Null_Procedure_Profile_Conformant : Boolean := True;
      Overriding_Indicator_Missing : Boolean := False;
      Overriding_Indicator_Not_Allowed : Boolean := False;
      Overriding_Profile_Conformant : Boolean := True;
      Parameter_Modes_Conformant : Boolean := True;
      Result_Type_Conformant : Boolean := True;
      Defaults_Conformant : Boolean := True;
      Null_Exclusions_Conformant : Boolean := True;
      Convention_Conformant : Boolean := True;
      Access_Profile_Conformant : Boolean := True;
      Ambiguous_Dispatching : Boolean := False;
      Static_Call_Where_Dispatching_Required : Boolean := False;
      Controlling_Operand_Compatible : Boolean := True;
      Controlling_Result_Compatible : Boolean := True;
      Interface_Target_Compatible : Boolean := True;
      Classwide_Root_Compatible : Boolean := True;
      Tagged_View_Conversion_Compatible : Boolean := True;
      Access_Classwide_Escape : Boolean := False;
      Pre_Post_Propagated : Boolean := True;
      Global_Depends_Propagated : Boolean := True;
      Refined_Effects_Propagated : Boolean := True;
      State_Constituents_Present : Boolean := True;
      Effect_Join_Present : Boolean := True;
      Volatile_Atomic_Preserved : Boolean := True;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Classwide_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Consumer_Tagged_Agrees : Boolean := True;
      Consumer_Interface_Agrees : Boolean := True;
      Consumer_Dispatching_Agrees : Boolean := True;
      Consumer_Profile_Agrees : Boolean := True;
      Consumer_Effect_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_346_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Tagged_Interfaces_Dispatching;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Dispatch_Context := Dispatch_Context;
      Row.Effect_Context := Effect_Context;
      Row.Name := To_Unbounded_String ("tagged interface dispatching burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1346");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_346_000 + Id);
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
      Row.Tagged_Parent_Is_Tagged := Tagged_Parent_Is_Tagged;
      Row.Parent_Visible := Parent_Visible;
      Row.Interface_Primitives_Implemented := Interface_Primitives_Implemented;
      Row.Concrete_Type_Implements_Abstract_Primitives := Abstract_Primitives_Implemented;
      Row.Synchronized_Interface_Compatible := Synchronized_Interface_Compatible;
      Row.Limited_Interface_Compatible := Limited_Interface_Compatible;
      Row.Null_Procedure_Profile_Conformant := Null_Procedure_Profile_Conformant;
      Row.Overriding_Indicator_Missing := Overriding_Indicator_Missing;
      Row.Overriding_Indicator_Not_Allowed := Overriding_Indicator_Not_Allowed;
      Row.Overriding_Profile_Conformant := Overriding_Profile_Conformant;
      Row.Parameter_Modes_Conformant := Parameter_Modes_Conformant;
      Row.Result_Type_Conformant := Result_Type_Conformant;
      Row.Defaults_Conformant := Defaults_Conformant;
      Row.Null_Exclusions_Conformant := Null_Exclusions_Conformant;
      Row.Convention_Conformant := Convention_Conformant;
      Row.Access_Subprogram_Profile_Conformant := Access_Profile_Conformant;
      Row.Dispatching_Candidate_Set_Ambiguous := Ambiguous_Dispatching;
      Row.Static_Call_Where_Dispatching_Required := Static_Call_Where_Dispatching_Required;
      Row.Controlling_Operand_Compatible := Controlling_Operand_Compatible;
      Row.Controlling_Result_Compatible := Controlling_Result_Compatible;
      Row.Interface_Dispatch_Target_Compatible := Interface_Target_Compatible;
      Row.Classwide_Conversion_Root_Compatible := Classwide_Root_Compatible;
      Row.Tagged_View_Conversion_Compatible := Tagged_View_Conversion_Compatible;
      Row.Access_Classwide_Accessibility_Escape := Access_Classwide_Escape;
      Row.Pre_Post_Propagated := Pre_Post_Propagated;
      Row.Global_Depends_Propagated := Global_Depends_Propagated;
      Row.Refined_Effects_Propagated := Refined_Effects_Propagated;
      Row.Abstract_State_Constituents_Present := State_Constituents_Present;
      Row.Dispatching_Effect_Join_Present := Effect_Join_Present;
      Row.Volatile_Atomic_Effect_Preserved := Volatile_Atomic_Preserved;
      Row.Runtime_Accessibility_Check := Runtime_Accessibility_Check;
      Row.Runtime_Classwide_Conversion_Check := Runtime_Classwide_Check;
      Row.Runtime_Dispatching_Predicate_Check := Runtime_Predicate_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Consumer_Tagged_Model_Agrees := Consumer_Tagged_Agrees;
      Row.Consumer_Interface_Model_Agrees := Consumer_Interface_Agrees;
      Row.Consumer_Dispatching_Model_Agrees := Consumer_Dispatching_Agrees;
      Row.Consumer_Profile_Model_Agrees := Consumer_Profile_Agrees;
      Row.Consumer_Contract_Effect_Model_Agrees := Consumer_Effect_Agrees;
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
      Row.Profile_Fingerprint := FP + 5;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 6;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 7;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 8;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Status = Status,
         "unexpected tagged/interface burn-down status");
   end Expect_Status;

   procedure Expect_Class
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Class : Audit.Precision_Classification) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Classification = Class,
         "unexpected tagged/interface burn-down classification");
   end Expect_Class;

   procedure Test_Tagged_Interface_Dispatching_Gap_Is_Burned_Down

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Tagged_Type_Extension,
               Dispatch_Context => Audit.Dispatch_Dispatching_Call,
               Effect_Context => Audit.Effect_Dispatching_Join);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Tagged_Parent_Is_Tagged => False,
               Construct => Audit.Construct_Tagged_Type_Extension);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Classwide_Check => True,
               Dispatch_Context => Audit.Dispatch_Classwide_Conversion,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True,
               Consumer => Consumers.Consumer_Hover_Details);

      Results := Audit.Build (Input);

      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "tagged/interface dispatching burn-down should be ready");
      Assert (Audit.Tagged_Interface_Dispatching_Gap_Closed (Results),
              "tagged/interface dispatching gap should be closed");
      Assert (Audit.Count (Results) = 4, "all burn-down rows should be retained");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down);
      Expect_Status (Results, 2, Audit.Status_Illegal_Untagged_Parent_Extension);
      Expect_Status (Results, 3, Audit.Status_Runtime_Classwide_Conversion_Check_Preserved);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence);
   end Test_Tagged_Interface_Dispatching_Gap_Is_Burned_Down;

   procedure Test_Tagged_And_Interface_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Tagged_Parent_Is_Tagged => False,
               Construct => Audit.Construct_Tagged_Type_Extension);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Parent_Visible => False,
               Construct => Audit.Construct_Tagged_Private_Extension);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Interface_Primitives_Implemented => False,
               Construct => Audit.Construct_Ordinary_Interface,
               Owner => Matrix.Slice_Interface_Synchronized);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Abstract_Primitives_Implemented => False,
               Construct => Audit.Construct_Abstract_Tagged_Type);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Synchronized_Interface_Compatible => False,
               Construct => Audit.Construct_Synchronized_Interface,
               Owner => Matrix.Slice_Interface_Synchronized);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Limited_Interface_Compatible => False,
               Construct => Audit.Construct_Limited_Interface,
               Owner => Matrix.Slice_Interface_Synchronized);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Null_Procedure_Profile_Conformant => False,
               Construct => Audit.Construct_Null_Procedure,
               Owner => Matrix.Slice_Callable_Profile);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Untagged_Parent_Extension);
      Expect_Status (Results, 2, Audit.Status_Illegal_Parent_Not_Visible);
      Expect_Status (Results, 3, Audit.Status_Illegal_Interface_Primitive_Not_Implemented);
      Expect_Status (Results, 4, Audit.Status_Illegal_Abstract_Primitive_Not_Implemented);
      Expect_Status (Results, 5, Audit.Status_Illegal_Synchronized_Interface_Mismatch);
      Expect_Status (Results, 6, Audit.Status_Illegal_Limited_Interface_Mismatch);
      Expect_Status (Results, 7, Audit.Status_Illegal_Null_Procedure_Profile);
      Assert (Results.Invalid_Count = 0, "tagged/interface rule rows should be valid");
   end Test_Tagged_And_Interface_Rules_Are_Enforced;

   procedure Test_Overriding_Profile_And_Dispatching_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Overriding_Indicator_Missing => True,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Overriding_Indicator_Not_Allowed => True,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Overriding_Profile_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Parameter_Modes_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Result_Type_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Defaults_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Null_Exclusions_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Convention_Conformant => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Access_Profile_Conformant => False,
               Owner => Matrix.Slice_Access_Type_Access_Subprogram);
      Add_Row (Input, 10, Precision.Class_Illegal,
               Ambiguous_Dispatching => True,
               Dispatch_Context => Audit.Dispatch_Dispatching_Call);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Static_Call_Where_Dispatching_Required => True,
               Dispatch_Context => Audit.Dispatch_Static_Call);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Controlling_Operand_Compatible => False,
               Dispatch_Context => Audit.Dispatch_Dispatching_Call);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Controlling_Result_Compatible => False,
               Dispatch_Context => Audit.Dispatch_Controlling_Result);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Interface_Target_Compatible => False,
               Dispatch_Context => Audit.Dispatch_Interface_Call,
               Owner => Matrix.Slice_Interface_Synchronized);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Overriding_Indicator_Missing);
      Expect_Status (Results, 2, Audit.Status_Illegal_Overriding_Indicator_Not_Allowed);
      Expect_Status (Results, 3, Audit.Status_Illegal_Overriding_Profile_Nonconformant);
      Expect_Status (Results, 4, Audit.Status_Illegal_Parameter_Mode_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_Result_Type_Mismatch);
      Expect_Status (Results, 6, Audit.Status_Illegal_Default_Conformance_Mismatch);
      Expect_Status (Results, 7, Audit.Status_Illegal_Null_Exclusion_Mismatch);
      Expect_Status (Results, 8, Audit.Status_Illegal_Convention_Mismatch);
      Expect_Status (Results, 9, Audit.Status_Illegal_Access_Subprogram_Profile_Mismatch);
      Expect_Status (Results, 10, Audit.Status_Illegal_Ambiguous_Dispatching_Call);
      Expect_Status (Results, 11, Audit.Status_Illegal_Static_Call_Where_Dispatching_Required);
      Expect_Status (Results, 12, Audit.Status_Illegal_Controlling_Operand_Mismatch);
      Expect_Status (Results, 13, Audit.Status_Illegal_Controlling_Result_Mismatch);
      Expect_Status (Results, 14, Audit.Status_Illegal_Interface_Dispatch_Target_Mismatch);
      Assert (Results.Invalid_Count = 0, "profile/dispatch rows should be valid");
   end Test_Overriding_Profile_And_Dispatching_Rules_Are_Enforced;

   procedure Test_Conversion_Contract_And_Effect_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Classwide_Root_Compatible => False,
               Dispatch_Context => Audit.Dispatch_Classwide_Conversion,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Tagged_View_Conversion_Compatible => False,
               Dispatch_Context => Audit.Dispatch_Classwide_Conversion,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Access_Classwide_Escape => True,
               Dispatch_Context => Audit.Dispatch_Access_Classwide_Conversion,
               Owner => Matrix.Slice_Accessibility_Lifetime);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Pre_Post_Propagated => False,
               Effect_Context => Audit.Effect_Pre_Post,
               Owner => Matrix.Slice_Contract_Aspect);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Global_Depends_Propagated => False,
               Effect_Context => Audit.Effect_Global_Depends,
               Owner => Matrix.Slice_Abstract_State_Global_Depends);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Refined_Effects_Propagated => False,
               Effect_Context => Audit.Effect_Refined_Global_Depends,
               Owner => Matrix.Slice_Flow_Refinement);
      Add_Row (Input, 7, Precision.Class_Illegal,
               State_Constituents_Present => False,
               Effect_Context => Audit.Effect_Abstract_State_Constituent,
               Owner => Matrix.Slice_Flow_Refinement);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Effect_Join_Present => False,
               Effect_Context => Audit.Effect_Dispatching_Join,
               Owner => Matrix.Slice_Flow_Refinement);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Volatile_Atomic_Preserved => False,
               Effect_Context => Audit.Effect_Volatile_Atomic,
               Owner => Matrix.Slice_Flow_Refinement);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Classwide_Conversion_Root_Mismatch);
      Expect_Status (Results, 2, Audit.Status_Illegal_Tagged_View_Conversion_Incompatible);
      Expect_Status (Results, 3, Audit.Status_Illegal_Access_Classwide_Accessibility_Escape);
      Expect_Status (Results, 4, Audit.Status_Illegal_Pre_Post_Not_Propagated);
      Expect_Status (Results, 5, Audit.Status_Illegal_Global_Depends_Not_Propagated);
      Expect_Status (Results, 6, Audit.Status_Illegal_Refined_Effect_Not_Propagated);
      Expect_Status (Results, 7, Audit.Status_Illegal_Abstract_State_Constituent_Missing);
      Expect_Status (Results, 8, Audit.Status_Illegal_Dispatching_Effect_Join_Missing);
      Expect_Status (Results, 9, Audit.Status_Illegal_Volatile_Atomic_Effect_Lost);
      Assert (Results.Invalid_Count = 0, "conversion/contract/effect rows should be valid");
   end Test_Conversion_Contract_And_Effect_Rules_Are_Enforced;

   procedure Test_Runtime_And_Indeterminate_Tagged_Cases_Are_Preserved

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True,
               Owner => Matrix.Slice_Accessibility_Lifetime);
      Add_Row (Input, 2, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Classwide_Check => True,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Predicate_Check => True,
               Owner => Matrix.Slice_Subtype_Range_Predicate);
      Add_Row (Input, 4, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Predicate_Check => True,
               Runtime_Check_Preserved => False,
               Owner => Matrix.Slice_Subtype_Range_Predicate);
      Add_Row (Input, 5, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 6, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 7, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 8, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 9, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 10, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Runtime_Tagged_Accessibility_Check_Preserved);
      Expect_Status (Results, 2, Audit.Status_Runtime_Classwide_Conversion_Check_Preserved);
      Expect_Status (Results, 3, Audit.Status_Runtime_Dispatching_Predicate_Check_Preserved);
      Expect_Status (Results, 4, Audit.Status_Runtime_Check_Evidence_Lost);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Private_View);
      Expect_Status (Results, 6, Audit.Status_Indeterminate_Limited_View);
      Expect_Status (Results, 7, Audit.Status_Indeterminate_Incomplete_View);
      Expect_Status (Results, 8, Audit.Status_Indeterminate_Generic_Formal_View);
      Expect_Status (Results, 9, Audit.Status_Indeterminate_Missing_Full_View);
      Expect_Status (Results, 10, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence);
      Assert (Results.Invalid_Count = 1, "lost runtime-check evidence should invalidate only one row");
   end Test_Runtime_And_Indeterminate_Tagged_Cases_Are_Preserved;

   procedure Test_Remediation_Consumer_Fingerprint_And_Classification_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 2, Precision.Class_Legal,
               Matrix_Present => False);
      Add_Row (Input, 3, Precision.Class_Legal,
               Package_Present => False);
      Add_Row (Input, 4, Precision.Class_Legal,
               New_Rule => False);
      Add_Row (Input, 5, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 6, Precision.Class_Legal,
               Corpus_Balanced => False);
      Add_Row (Input, 7, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 8, Precision.Class_Legal,
               Consumer_Reached => False);
      Add_Row (Input, 9, Precision.Class_Legal,
               Consumer_Tagged_Agrees => False);
      Add_Row (Input, 10, Precision.Class_Legal,
               Consumer_Interface_Agrees => False);
      Add_Row (Input, 11, Precision.Class_Legal,
               Consumer_Dispatching_Agrees => False);
      Add_Row (Input, 12, Precision.Class_Legal,
               Consumer_Profile_Agrees => False);
      Add_Row (Input, 13, Precision.Class_Legal,
               Consumer_Effect_Agrees => False);
      Add_Row (Input, 14, Precision.Class_Legal,
               Tagged_Parent_Is_Tagged => False);
      Add_Row (Input, 15, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 16, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 17, Precision.Class_Legal,
               Expected_Source_FP => 1);
      Add_Row (Input, 18, Precision.Class_Legal,
               Expected_AST_FP => 1);
      Add_Row (Input, 19, Precision.Class_Legal,
               Expected_Type_FP => 1);
      Add_Row (Input, 20, Precision.Class_Legal,
               Expected_Profile_FP => 1);
      Add_Row (Input, 21, Precision.Class_Legal,
               Expected_Substitution_FP => 1);
      Add_Row (Input, 22, Precision.Class_Legal,
               Expected_Effect_FP => 1);
      Add_Row (Input, 23, Precision.Class_Legal,
               Expected_Consumer_FP => 1);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Missing_Remediation_Evidence);
      Expect_Status (Results, 2, Audit.Status_Missing_Matrix_Coverage);
      Expect_Status (Results, 3, Audit.Status_Missing_Implementing_Package);
      Expect_Status (Results, 4, Audit.Status_No_New_Legality_Rule);
      Expect_Status (Results, 5, Audit.Status_Coverage_Not_Updated_To_Covered);
      Expect_Status (Results, 6, Audit.Status_Regression_Corpus_Not_Balanced);
      Expect_Status (Results, 7, Audit.Status_Semantic_Result_Unconsumed);
      Expect_Status (Results, 8, Audit.Status_Consumer_Not_Reached);
      Expect_Status (Results, 9, Audit.Status_Consumer_Tagged_Model_Disagreement);
      Expect_Status (Results, 10, Audit.Status_Consumer_Interface_Model_Disagreement);
      Expect_Status (Results, 11, Audit.Status_Consumer_Dispatching_Model_Disagreement);
      Expect_Status (Results, 12, Audit.Status_Consumer_Profile_Model_Disagreement);
      Expect_Status (Results, 13, Audit.Status_Consumer_Contract_Effect_Model_Disagreement);
      Expect_Status (Results, 14, Audit.Status_Unexpected_Classification);
      Expect_Status (Results, 15, Audit.Status_Stale_Burn_Down_Fingerprint);
      Expect_Status (Results, 16, Audit.Status_Source_Shaped_Evidence_Missing);
      Expect_Status (Results, 17, Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, 18, Audit.Status_AST_Fingerprint_Mismatch);
      Expect_Status (Results, 19, Audit.Status_Type_Fingerprint_Mismatch);
      Expect_Status (Results, 20, Audit.Status_Profile_Fingerprint_Mismatch);
      Expect_Status (Results, 21, Audit.Status_Substitution_Fingerprint_Mismatch);
      Expect_Status (Results, 22, Audit.Status_Effect_Fingerprint_Mismatch);
      Expect_Status (Results, 23, Audit.Status_Consumer_Fingerprint_Mismatch);
      Expect_Class (Results, 14, Precision.Class_Illegal);
      Assert (Results.Invalid_Count = 23,
              "all remediation/fingerprint/classification gate rows should be invalid");
   end Test_Remediation_Consumer_Fingerprint_And_Classification_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Tagged_Interface_Dispatching_Gap_Is_Burned_Down'Access,
         "tagged interface dispatching gap is burned down");
      Register_Routine
        (T, Test_Tagged_And_Interface_Rules_Are_Enforced'Access,
         "tagged and interface rules are enforced");
      Register_Routine
        (T, Test_Overriding_Profile_And_Dispatching_Rules_Are_Enforced'Access,
         "overriding profile and dispatching rules are enforced");
      Register_Routine
        (T, Test_Conversion_Contract_And_Effect_Rules_Are_Enforced'Access,
         "conversion contract and effect rules are enforced");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Tagged_Cases_Are_Preserved'Access,
         "runtime and indeterminate tagged cases are preserved");
      Register_Routine
        (T, Test_Remediation_Consumer_Fingerprint_And_Classification_Gates'Access,
         "remediation consumer fingerprint and classification gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1346;
