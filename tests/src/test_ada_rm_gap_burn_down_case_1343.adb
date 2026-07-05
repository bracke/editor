with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Case_1343;

package body Test_Ada_RM_Gap_Burn_Down_Case_1343 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Case_1343;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Aggregate_Form;
   use type Audit.Aggregate_Context;
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
      Status_Seed : Audit.Aggregate_Form := Audit.Form_Record_Aggregate;
      Context : Audit.Aggregate_Context := Audit.Context_Assignment_Statement;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Aggregate;
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
      Expected_Type_Known : Boolean := True;
      Target_Variable_View : Boolean := True;
      Associations_Complete : Boolean := True;
      Duplicate_Association : Boolean := False;
      Extra_Association : Boolean := False;
      Mixed_Association : Boolean := False;
      Static_Choices : Boolean := True;
      Choices_Overlap : Boolean := False;
      Component_Types_Compatible : Boolean := True;
      Discriminants_Compatible : Boolean := True;
      Variant_Component_Active : Boolean := True;
      Defaulted_Components_Available : Boolean := True;
      Static_Accessibility_Escape : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Static_Range_Violation : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Static_Predicate_Violation : Boolean := False;
      Predicate_Runtime_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Missing_Full_View : Boolean := False;
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
      FP : constant Natural := 1_343_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Aggregate_Assignment_Predicate;
      Row.Family := Matrix.Family_Aggregates;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Form := Status_Seed;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("aggregate assignment predicate burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Case_1343");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_343_000 + Id);
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
      Row.Expected_Type_Known := Expected_Type_Known;
      Row.Target_Variable_View := Target_Variable_View;
      Row.Aggregate_Associations_Complete := Associations_Complete;
      Row.Duplicate_Association := Duplicate_Association;
      Row.Extra_Association := Extra_Association;
      Row.Mixed_Named_Positional_Association := Mixed_Association;
      Row.Static_Choices := Static_Choices;
      Row.Choices_Overlap := Choices_Overlap;
      Row.Component_Types_Compatible := Component_Types_Compatible;
      Row.Discriminants_Compatible := Discriminants_Compatible;
      Row.Variant_Component_Active := Variant_Component_Active;
      Row.Defaulted_Components_Available := Defaulted_Components_Available;
      Row.Accessibility_Static_Escape := Static_Accessibility_Escape;
      Row.Accessibility_Runtime_Check := Runtime_Accessibility_Check;
      Row.Static_Range_Out_Of_Range := Static_Range_Violation;
      Row.Runtime_Range_Check := Runtime_Range_Check;
      Row.Predicate_Staticly_False := Static_Predicate_Violation;
      Row.Predicate_Runtime_Check := Predicate_Runtime_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Missing_Full_View := Missing_Full_View;
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
         "unexpected RM gap burn-down status");
   end Expect_Status;

   procedure Expect_Class
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Class : Audit.Precision_Classification) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Classification = Class,
         "unexpected RM gap burn-down classification");
   end Expect_Class;

   procedure Test_Aggregate_Assignment_Predicate_Gap_Is_Burned_Down

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Status_Seed => Audit.Form_Record_Aggregate);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Duplicate_Association => True,
               Stable_Blocker => True);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Predicate_Runtime_Check => True,
               Runtime_Range_Check => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Missing_Full_View => True);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 4, "expected four burn-down rows");
      Assert (Results.Burned_Down_Count = 4, "all rows should be burned down");
      Assert (Results.Invalid_Count = 0, "burn-down rows should be valid");
      Assert (Results.Legal_Count = 1, "legal row should be counted");
      Assert (Results.Illegal_Count = 1, "illegal row should be counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check row should be counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate row should be counted");
      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced burn-down evidence should be ready");
      Assert (Audit.Aggregate_Assignment_Predicate_Gap_Closed (Results),
              "aggregate assignment predicate gap should be closed");
   end Test_Aggregate_Assignment_Predicate_Gap_Is_Burned_Down;

   procedure Test_Association_Choice_And_Type_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Associations_Complete => False);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Duplicate_Association => True);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Extra_Association => True);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Mixed_Association => True);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Static_Choices => False);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Choices_Overlap => True);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Component_Types_Compatible => False);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Discriminants_Compatible => False);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Defaulted_Components_Available => False);
      Add_Row (Input, 10, Precision.Class_Illegal,
               Variant_Component_Active => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Missing_Association);
      Expect_Status (Results, 2, Audit.Status_Illegal_Duplicate_Association);
      Expect_Status (Results, 3, Audit.Status_Illegal_Extra_Association);
      Expect_Status (Results, 4, Audit.Status_Illegal_Mixed_Association);
      Expect_Status (Results, 5, Audit.Status_Illegal_Nonstatic_Choice);
      Expect_Status (Results, 6, Audit.Status_Illegal_Overlapping_Choice);
      Expect_Status (Results, 7, Audit.Status_Illegal_Component_Type_Mismatch);
      Expect_Status (Results, 8, Audit.Status_Illegal_Discriminant_Mismatch);
      Expect_Status (Results, 9, Audit.Status_Illegal_Defaulted_Component_Missing);
      Expect_Status (Results, 10, Audit.Status_Illegal_Inactive_Variant_Component);
      Assert (Results.Invalid_Count = 0, "static illegality rows should be valid burn-down evidence");
   end Test_Association_Choice_And_Type_Rules_Are_Enforced;

   procedure Test_Runtime_Checks_Are_Preserved_And_Static_Errors_Are_Hard

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Static_Accessibility_Escape => True);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Static_Range_Violation => True);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Static_Predicate_Violation => True);
      Add_Row (Input, 4, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True,
               Runtime_Range_Check => True,
               Predicate_Runtime_Check => True);
      Add_Row (Input, 5, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Range_Check => True,
               Runtime_Check_Preserved => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Static_Accessibility_Escape);
      Expect_Status (Results, 2, Audit.Status_Illegal_Static_Range_Violation);
      Expect_Status (Results, 3, Audit.Status_Illegal_Static_Predicate_Violation);
      Expect_Status (Results, 4, Audit.Status_Runtime_Check_Preserved);
      Expect_Status (Results, 5, Audit.Status_Runtime_Check_Evidence_Lost);
      Assert (Results.Invalid_Count = 1, "lost runtime-check evidence must invalidate the row");
   end Test_Runtime_Checks_Are_Preserved_And_Static_Errors_Are_Hard;

   procedure Test_Private_Limited_And_Missing_View_Blockers_Are_Indeterminate

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Indeterminate,
               Expected_Type_Known => False);
      Add_Row (Input, 2, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 3, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Missing_Full_View => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Indeterminate_Missing_Expected_Type);
      Expect_Status (Results, 2, Audit.Status_Indeterminate_Private_View);
      Expect_Status (Results, 3, Audit.Status_Indeterminate_Limited_View);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Full_View);
      Assert (Results.Invalid_Count = 0, "view blockers should be valid indeterminate evidence");
   end Test_Private_Limited_And_Missing_View_Blockers_Are_Indeterminate;

   procedure Test_Remediation_And_Consumer_Evidence_Are_Required

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

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Missing_Remediation_Evidence);
      Expect_Status (Results, 2, Audit.Status_Missing_Matrix_Coverage);
      Expect_Status (Results, 3, Audit.Status_Missing_Implementing_Package);
      Expect_Status (Results, 4, Audit.Status_No_New_Legality_Rule);
      Expect_Status (Results, 5, Audit.Status_Coverage_Not_Updated_To_Covered);
      Expect_Status (Results, 6, Audit.Status_Regression_Corpus_Not_Balanced);
      Expect_Status (Results, 7, Audit.Status_Semantic_Result_Unconsumed);
      Expect_Status (Results, 8, Audit.Status_Consumer_Not_Reached);
      Assert (Results.Invalid_Count = 8, "all missing remediation/consumer rows should be invalid");
   end Test_Remediation_And_Consumer_Evidence_Are_Required;

   procedure Test_Fingerprint_And_Classification_Mismatches_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Duplicate_Association => True);
      Add_Row (Input, 2, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 3, Precision.Class_Legal,
               Expected_Source_FP => 1);
      Add_Row (Input, 4, Precision.Class_Legal,
               Expected_AST_FP => 1);
      Add_Row (Input, 5, Precision.Class_Legal,
               Expected_Type_FP => 1);
      Add_Row (Input, 6, Precision.Class_Legal,
               Expected_Profile_FP => 1);
      Add_Row (Input, 7, Precision.Class_Legal,
               Expected_Substitution_FP => 1);
      Add_Row (Input, 8, Precision.Class_Legal,
               Expected_Effect_FP => 1);
      Add_Row (Input, 9, Precision.Class_Legal,
               Expected_Consumer_FP => 1);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Unexpected_Classification);
      Expect_Status (Results, 2, Audit.Status_Stale_Burn_Down_Fingerprint);
      Expect_Status (Results, 3, Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, 4, Audit.Status_AST_Fingerprint_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Type_Fingerprint_Mismatch);
      Expect_Status (Results, 6, Audit.Status_Profile_Fingerprint_Mismatch);
      Expect_Status (Results, 7, Audit.Status_Substitution_Fingerprint_Mismatch);
      Expect_Status (Results, 8, Audit.Status_Effect_Fingerprint_Mismatch);
      Expect_Status (Results, 9, Audit.Status_Consumer_Fingerprint_Mismatch);
      Expect_Class (Results, 1, Precision.Class_Illegal);
      Assert (Results.Invalid_Count = 9, "fingerprint/classification mismatches should be invalid");
   end Test_Fingerprint_And_Classification_Mismatches_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Aggregate_Assignment_Predicate_Gap_Is_Burned_Down'Access,
         "aggregate assignment predicate gap is burned down");
      Register_Routine
        (T, Test_Association_Choice_And_Type_Rules_Are_Enforced'Access,
         "association choice and type rules are enforced");
      Register_Routine
        (T, Test_Runtime_Checks_Are_Preserved_And_Static_Errors_Are_Hard'Access,
         "runtime checks are preserved and static errors are hard");
      Register_Routine
        (T, Test_Private_Limited_And_Missing_View_Blockers_Are_Indeterminate'Access,
         "private limited and missing full view blockers are indeterminate");
      Register_Routine
        (T, Test_Remediation_And_Consumer_Evidence_Are_Required'Access,
         "remediation and consumer evidence are required");
      Register_Routine
        (T, Test_Fingerprint_And_Classification_Mismatches_Are_Rejected'Access,
         "fingerprint and classification mismatches are rejected");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1343;
