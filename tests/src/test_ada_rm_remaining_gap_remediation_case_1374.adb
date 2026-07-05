with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Case_1374;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1374 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Case_1374;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Literal_Context;
   use type Audit.Bounds_Form;
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
      Bounds : Audit.Bounds_Form := Audit.Bounds_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Static_String_Slice_Bounds_Edge;
      Row.Family := Matrix.Family_Static_Expressions_Choices;
      Row.Owner := Matrix.Slice_Numeric_Static_Expression;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_String_Slice;
      Row.Bounds := Bounds;
      Row.Source_File := To_Unbounded_String ("src/static-string-slice-bounds.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("static string literal slice, index, and assignment bounds must preserve canonical literal, range, subtype, and consumer evidence");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Case_1374");
      Row.Candidate_Case := To_Unbounded_String ("Case 1374");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Static_Expressions.String_Slice_Bounds");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected case 1374 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected case 1374 precision classification");
   end Expect_Status;

   procedure Test_Static_String_Slice_Bounds_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Bounds_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Bounds_Static_Index_Out_Of_Range);
      Row.Static_Index_Out_Of_Range := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Bounds_Runtime_Index_Check);
      Row.Runtime_Index_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Bounds_Missing_Expected_Array_Type);
      Row.Expected_Array_Type_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "case 1374 should close the selected static string slice bounds gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Static_String_Bounds_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Static_Index_Out_Of_Range,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Index_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Expected_Array_Type,
                     Precision.Class_Indeterminate);
   end Test_Static_String_Slice_Bounds_Gap_Remediated;

   procedure Test_Static_Bounds_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Static_Lower_Above_Upper := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.String_Length_Matches_Target := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Character_Element_Compatible := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Null_Literal_In_Access_Context := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Static_Lower_Above_Upper,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_String_Length_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Character_Element_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Null_Literal_Non_Access_Context,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_Static_Bounds_Rejections;

   procedure Test_Runtime_And_Indeterminate_Bounds

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Bounds_Runtime_Range_Check);
      Row.Runtime_Range_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Indeterminate,
                       Audit.Bounds_Missing_Index_Subtype);
      Row.Index_Subtype_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Bounds_Stale_Static_Evidence);
      Row.Stale_Static_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Runtime_Range_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 21, Audit.Status_Indeterminate_Missing_Index_Subtype,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Indeterminate_Stale_Static_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Runtime_And_Indeterminate_Bounds;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (30);
      Row.Inventory_Row_From_Final_Burn_Down := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31);
      Row.Named_Concrete_Subrule := False;
      Row.Concrete_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32);
      Row.Coverage_Promoted_To_Covered := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33);
      Row.Final_Gate_No_Longer_Reports_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34);
      Row.Indeterminate_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36);
      Row.Consumer_Fingerprint := 1;
      Row.Expected_Consumer_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Missing_Final_Inventory_Row,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 31, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 32, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 33, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 34, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 35, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 36, Audit.Status_Consumer_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Static_String_Slice_Bounds_Gap_Remediated'Access,
         "static string slice bounds gap remediated");
      Register_Routine
        (T, Test_Static_Bounds_Rejections'Access,
         "static string bounds rejections");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Bounds'Access,
         "runtime and indeterminate static bounds");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1374;
