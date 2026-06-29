with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1344;

package body Test_Ada_RM_Gap_Burn_Down_Case_1344 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1344;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Generic_Formal_Kind;
   use type Audit.Generic_Replay_Context;
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
      Formal : Audit.Generic_Formal_Kind := Audit.Formal_Type;
      Context : Audit.Generic_Replay_Context := Audit.Context_Replayed_Call;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Generic_Body_Replay;
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
      Formal_Binding_Present : Boolean := True;
      Formal_Actual_Kind_Compatible : Boolean := True;
      Type_Substitution_Compatible : Boolean := True;
      Object_Mode_Compatible : Boolean := True;
      Callable_Profile_Compatible : Boolean := True;
      Defaulted_Formals_Compatible : Boolean := True;
      Null_Exclusions_Compatible : Boolean := True;
      Conventions_Compatible : Boolean := True;
      Access_Subprogram_Profile_Compatible : Boolean := True;
      Overload_Result_Agrees_With_Profile : Boolean := True;
      Body_Replay_Uses_Substituted_Actuals : Boolean := True;
      Nested_Instantiation_Cycle : Boolean := False;
      Replay_Depth_Overflow : Boolean := False;
      Contracts_Preserved : Boolean := True;
      Global_Depends_Preserved : Boolean := True;
      Refined_Flow_Preserved : Boolean := True;
      Volatile_Atomic_Order_Preserved : Boolean := True;
      Dispatching_Effect_Join_Preserved : Boolean := True;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
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
      FP : constant Natural := 1_344_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Generic_Substitution_Body_Replay_Profile_Flow;
      Row.Family := Matrix.Family_Generics_Contracts_Substitution_Replay;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Formal := Formal;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("generic substitution body replay profile flow burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1344");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_344_000 + Id);
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
      Row.Formal_Binding_Present := Formal_Binding_Present;
      Row.Formal_Actual_Kind_Compatible := Formal_Actual_Kind_Compatible;
      Row.Type_Substitution_Compatible := Type_Substitution_Compatible;
      Row.Object_Mode_Compatible := Object_Mode_Compatible;
      Row.Callable_Profile_Compatible := Callable_Profile_Compatible;
      Row.Defaulted_Formals_Compatible := Defaulted_Formals_Compatible;
      Row.Null_Exclusions_Compatible := Null_Exclusions_Compatible;
      Row.Conventions_Compatible := Conventions_Compatible;
      Row.Access_Subprogram_Profile_Compatible := Access_Subprogram_Profile_Compatible;
      Row.Overload_Result_Agrees_With_Profile := Overload_Result_Agrees_With_Profile;
      Row.Body_Replay_Uses_Substituted_Actuals := Body_Replay_Uses_Substituted_Actuals;
      Row.Nested_Instantiation_Cycle := Nested_Instantiation_Cycle;
      Row.Replay_Depth_Overflow := Replay_Depth_Overflow;
      Row.Contracts_Preserved := Contracts_Preserved;
      Row.Global_Depends_Preserved := Global_Depends_Preserved;
      Row.Refined_Flow_Preserved := Refined_Flow_Preserved;
      Row.Volatile_Atomic_Order_Preserved := Volatile_Atomic_Order_Preserved;
      Row.Dispatching_Effect_Join_Preserved := Dispatching_Effect_Join_Preserved;
      Row.Runtime_Accessibility_Check := Runtime_Accessibility_Check;
      Row.Runtime_Range_Check := Runtime_Range_Check;
      Row.Runtime_Predicate_Check := Runtime_Predicate_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
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
         "unexpected RM generic burn-down status");
   end Expect_Status;

   procedure Expect_Class
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Class : Audit.Precision_Classification) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Classification = Class,
         "unexpected RM generic burn-down classification");
   end Expect_Class;

   procedure Test_Generic_Profile_Flow_Gap_Is_Burned_Down

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Context => Audit.Context_Nested_Instantiation);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Callable_Profile_Compatible => False);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True,
               Runtime_Range_Check => True,
               Runtime_Predicate_Check => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Private_View => True);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 4, "expected four generic burn-down rows");
      Assert (Results.Burned_Down_Count = 4, "all generic rows should be burned down");
      Assert (Results.Invalid_Count = 0, "generic burn-down rows should be valid");
      Assert (Results.Legal_Count = 1, "legal generic row should be counted");
      Assert (Results.Illegal_Count = 1, "illegal generic row should be counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check generic row should be counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate generic row should be counted");
      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced generic burn-down evidence should be ready");
      Assert (Audit.Generic_Profile_Flow_Gap_Closed (Results),
              "generic substitution/body/profile/flow gap should be closed");
   end Test_Generic_Profile_Flow_Gap_Is_Burned_Down;

   procedure Test_Substitution_And_Body_Replay_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Formal_Binding_Present => False);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Formal_Actual_Kind_Compatible => False,
               Formal => Audit.Formal_Package);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Type_Substitution_Compatible => False);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Object_Mode_Compatible => False,
               Formal => Audit.Formal_Object);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Body_Replay_Uses_Substituted_Actuals => False,
               Context => Audit.Context_Replayed_Call);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Nested_Instantiation_Cycle => True,
               Context => Audit.Context_Nested_Instantiation);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Replay_Depth_Overflow => True,
               Context => Audit.Context_Nested_Instantiation);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Missing_Formal_Binding);
      Expect_Status (Results, 2, Audit.Status_Illegal_Formal_Actual_Kind_Mismatch);
      Expect_Status (Results, 3, Audit.Status_Illegal_Type_Substitution_Mismatch);
      Expect_Status (Results, 4, Audit.Status_Illegal_Object_Mode_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_Body_Replay_Uses_Formal_Placeholder);
      Expect_Status (Results, 6, Audit.Status_Illegal_Nested_Instance_Cycle);
      Expect_Status (Results, 7, Audit.Status_Illegal_Replay_Depth_Overflow);
      Assert (Results.Invalid_Count = 0, "substitution/body replay rows should be valid evidence");
   end Test_Substitution_And_Body_Replay_Rules_Are_Enforced;

   procedure Test_Callable_Profile_Overload_And_Convention_Agreement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Callable_Profile_Compatible => False,
               Formal => Audit.Formal_Subprogram);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Defaulted_Formals_Compatible => False,
               Formal => Audit.Formal_Subprogram);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Null_Exclusions_Compatible => False,
               Formal => Audit.Formal_Access_Type);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Conventions_Compatible => False,
               Formal => Audit.Formal_Subprogram);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Access_Subprogram_Profile_Compatible => False,
               Formal => Audit.Formal_Access_Type);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Overload_Result_Agrees_With_Profile => False,
               Context => Audit.Context_Replayed_Operator);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Callable_Profile_Mismatch);
      Expect_Status (Results, 2, Audit.Status_Illegal_Default_Formal_Mismatch);
      Expect_Status (Results, 3, Audit.Status_Illegal_Null_Exclusion_Mismatch);
      Expect_Status (Results, 4, Audit.Status_Illegal_Convention_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_Access_Subprogram_Profile_Mismatch);
      Expect_Status (Results, 6, Audit.Status_Illegal_Overload_Profile_Disagreement);
      Assert (Results.Invalid_Count = 0, "callable profile rows should be valid evidence");
   end Test_Callable_Profile_Overload_And_Convention_Agreement;

   procedure Test_Contracts_And_Flow_Effects_Survive_Substitution

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Contracts_Preserved => False,
               Context => Audit.Context_Contract_Aspect);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Global_Depends_Preserved => False,
               Context => Audit.Context_Flow_Aspect);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Refined_Flow_Preserved => False,
               Context => Audit.Context_Flow_Aspect);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Volatile_Atomic_Order_Preserved => False,
               Context => Audit.Context_Flow_Aspect);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Dispatching_Effect_Join_Preserved => False,
               Context => Audit.Context_Flow_Aspect);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Contract_Pre_Post_Mismatch);
      Expect_Status (Results, 2, Audit.Status_Illegal_Global_Depends_Mismatch);
      Expect_Status (Results, 3, Audit.Status_Illegal_Refined_Flow_Mismatch);
      Expect_Status (Results, 4, Audit.Status_Illegal_Volatile_Atomic_Order_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_Dispatching_Effect_Join_Mismatch);
      Assert (Results.Invalid_Count = 0, "contract/flow rows should be valid evidence");
   end Test_Contracts_And_Flow_Effects_Survive_Substitution;

   procedure Test_Runtime_And_Indeterminate_Generic_Cases_Are_Preserved

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True,
               Runtime_Range_Check => True,
               Runtime_Predicate_Check => True);
      Add_Row (Input, 2, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Range_Check => True,
               Runtime_Check_Preserved => False);
      Add_Row (Input, 3, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 5, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 6, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 7, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Runtime_Check_Preserved);
      Expect_Status (Results, 2, Audit.Status_Runtime_Check_Evidence_Lost);
      Expect_Status (Results, 3, Audit.Status_Indeterminate_Private_View);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Limited_View);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Incomplete_View);
      Expect_Status (Results, 6, Audit.Status_Indeterminate_Missing_Full_View);
      Expect_Status (Results, 7, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence);
      Assert (Results.Invalid_Count = 1, "lost runtime-check evidence should invalidate only one row");
   end Test_Runtime_And_Indeterminate_Generic_Cases_Are_Preserved;

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
               Callable_Profile_Compatible => False);
      Add_Row (Input, 10, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 11, Precision.Class_Legal,
               Expected_Source_FP => 1);
      Add_Row (Input, 12, Precision.Class_Legal,
               Expected_AST_FP => 1);
      Add_Row (Input, 13, Precision.Class_Legal,
               Expected_Type_FP => 1);
      Add_Row (Input, 14, Precision.Class_Legal,
               Expected_Profile_FP => 1);
      Add_Row (Input, 15, Precision.Class_Legal,
               Expected_Substitution_FP => 1);
      Add_Row (Input, 16, Precision.Class_Legal,
               Expected_Effect_FP => 1);
      Add_Row (Input, 17, Precision.Class_Legal,
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
      Expect_Status (Results, 9, Audit.Status_Unexpected_Classification);
      Expect_Status (Results, 10, Audit.Status_Stale_Burn_Down_Fingerprint);
      Expect_Status (Results, 11, Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, 12, Audit.Status_AST_Fingerprint_Mismatch);
      Expect_Status (Results, 13, Audit.Status_Type_Fingerprint_Mismatch);
      Expect_Status (Results, 14, Audit.Status_Profile_Fingerprint_Mismatch);
      Expect_Status (Results, 15, Audit.Status_Substitution_Fingerprint_Mismatch);
      Expect_Status (Results, 16, Audit.Status_Effect_Fingerprint_Mismatch);
      Expect_Status (Results, 17, Audit.Status_Consumer_Fingerprint_Mismatch);
      Expect_Class (Results, 9, Precision.Class_Illegal);
      Assert (Results.Invalid_Count = 17, "all remediation/fingerprint/classification gate rows should be invalid");
   end Test_Remediation_Consumer_Fingerprint_And_Classification_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Generic_Profile_Flow_Gap_Is_Burned_Down'Access,
         "generic profile flow gap is burned down");
      Register_Routine
        (T, Test_Substitution_And_Body_Replay_Rules_Are_Enforced'Access,
         "substitution and body replay rules are enforced");
      Register_Routine
        (T, Test_Callable_Profile_Overload_And_Convention_Agreement'Access,
         "callable profile overload and convention agreement");
      Register_Routine
        (T, Test_Contracts_And_Flow_Effects_Survive_Substitution'Access,
         "contracts and flow effects survive substitution");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Generic_Cases_Are_Preserved'Access,
         "runtime and indeterminate generic cases are preserved");
      Register_Routine
        (T, Test_Remediation_Consumer_Fingerprint_And_Classification_Gates'Access,
         "remediation consumer fingerprint and classification gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1344;
