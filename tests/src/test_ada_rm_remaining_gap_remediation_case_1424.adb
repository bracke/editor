with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Remaining_Gap_Remediation_Case_1424;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1424 is
   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Case_1424;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Universal_Numeric_Expected_Context_Closure;
   use type Audit.Universal_Numeric_Expected_Context_Form;
   use type Audit.Remediation_Status;
   use type Audit.Remediation_Row;
   use type Audit.Remediation_Input;
   use type Audit.Remediation_Entry;
   use type Audit.Remediation_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;
   package Inventory renames Audit.Inventory;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Form : Audit.Universal_Numeric_Expected_Context_Form := Audit.Form_Universal_Numeric_Expected_Context_Resolved)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Universal_Numeric_Stateful_Expected_Context_Edge;
      Row.Family := Matrix.Family_Expressions_Expected_Type_Resolution;
      Row.Owner := Matrix.Slice_Ada2022_Expression_Type_Resolution;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Closure := Audit.Closure_Expected_Type_Evidence;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/universal-numeric-expected-context.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("universal numeric operands in expected-type contexts, stateful"
           & "expected-context changes, static numeric range evidence, runtime"
           & "numeric checks, warning diagnostics, stale expected-context"
           & "evidence, and semantic consumers must share one source-shaped"
           & "legality result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Case_1424");
      Row.Candidate_Case := To_Unbounded_String ("Case 1424");
      Row.Blocker_Family := To_Unbounded_String ("RM.Expressions.Universal_Numeric.Expected_Context");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected case 1424 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected case 1424 precision classification");
   end Expect_Status;

   procedure Test_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row
        (Input,
         Base_Row (1, Precision.Class_Legal,
                   Audit.Form_Universal_Numeric_Expected_Context_Resolved));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Form_Illegal_Ambiguous_Universal_Expression);
      Row.Ambiguous_Universal_Expression := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Form_Runtime_Numeric_Check_Preserved);
      Row.Runtime_Numeric_Check_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal,
                       Audit.Form_Warning_Only_Preserved);
      Row.Warning_Only_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Form_Indeterminate_Missing_Expected_Type_Evidence);
      Row.Missing_Expected_Type_Evidence := True;
      Row.Complete_Expected_Type_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Legal,
                       Audit.Form_Universal_Operand_Context_Resolved);
      Row.Closure := Audit.Closure_Universal_Operand_Evidence;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "case 1424 should close the universal numeric stateful expected context gap");
      Assert (Results.Remediated_Count >= 2, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Warning_Count = 1, "warning count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status
        (Results, 1,
         Audit.Status_Universal_Numeric_Expected_Context_Resolved,
         Precision.Class_Legal);
      Expect_Status
        (Results, 2,
         Audit.Status_Illegal_Ambiguous_Universal_Expression,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 3,
         Audit.Status_Runtime_Numeric_Check_Preserved,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 4,
         Audit.Status_Warning_Only_Preserved,
         Precision.Class_Legal);
      Expect_Status
        (Results, 5,
         Audit.Status_Indeterminate_Missing_Expected_Type_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 6,
         Audit.Status_Universal_Operand_Context_Resolved,
         Precision.Class_Legal);
   end Test_Gap_Remediated;

   procedure Test_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Ambiguous_Universal_Expression := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Universal_Integer_Real_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Modular_Expected_Context_Overflow := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Stateful_Context_Changes_Resolution := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Static_Numeric_Range_Violation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (15);
      Row.Missing_Full_View := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (16);
      Row.Stale_Expected_Context_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (17);
      Row.Missing_Static_Numeric_Evidence := True;
      Row.Complete_Static_Numeric_Evidence := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 10,
         Audit.Status_Illegal_Ambiguous_Universal_Expression,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 11,
         Audit.Status_Illegal_Universal_Integer_Real_Mismatch,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 12,
         Audit.Status_Illegal_Modular_Expected_Context_Overflow,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 13,
         Audit.Status_Illegal_Stateful_Context_Changes_Resolution,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 14,
         Audit.Status_Illegal_Static_Numeric_Range_Violation,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 15,
         Audit.Status_Indeterminate_Private_Numeric_View,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 16,
         Audit.Status_Indeterminate_Stale_Expected_Context_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 17,
         Audit.Status_Indeterminate_Missing_Static_Numeric_Evidence,
         Precision.Class_Indeterminate);
   end Test_Rejections;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20);
      Row.Inventory_Row_From_Final_Burn_Down := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21);
      Row.Named_Concrete_Subrule := False;
      Row.Concrete_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22);
      Row.Coverage_Promoted_To_Covered := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23);
      Row.Final_Gate_No_Longer_Reports_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24);
      Row.Runtime_Check_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Consumer_State_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26);
      Row.Expected_Context_Fingerprint := 1;
      Row.Expected_Expected_Context_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (27);
      Row.Numeric_Fingerprint := 1;
      Row.Expected_Numeric_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (28);
      Row.Consumer_Fingerprint := 1;
      Row.Expected_Consumer_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 20,
         Audit.Status_Missing_Final_Inventory_Row,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 21,
         Audit.Status_Missing_Concrete_Subrule_Name,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 22,
         Audit.Status_Coverage_Not_Promoted,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 23,
         Audit.Status_Final_Gate_Still_Reports_Gap,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 24,
         Audit.Status_Regression_Corpus_Not_Balanced,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 25,
         Audit.Status_Consumer_Not_Reached,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 26,
         Audit.Status_Expected_Context_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 27,
         Audit.Status_Numeric_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 28,
         Audit.Status_Consumer_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Gap_Remediated'Access,
         "universal numeric stateful expected context gap remediated");
      Register_Routine
        (T, Test_Rejections'Access,
         "universal numeric stateful expected context rejection cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1424;
