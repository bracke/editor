with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1425;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1425 is
   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1425;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Renamed_Primitive_Visibility_Closure;
   use type Audit.Renamed_Primitive_Visibility_Form;
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
      Form : Audit.Renamed_Primitive_Visibility_Form := Audit.Form_Renamed_Primitive_Visibility_Resolved)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Renamed_Primitive_Visibility_Edge;
      Row.Family := Matrix.Family_Names_Visibility_Selected_Attributes;
      Row.Owner := Matrix.Slice_Visibility_Name_Resolution;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Closure := Audit.Closure_Renaming_View_Evidence;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/renamed-primitive-visibility.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("renamed primitive visibility, homograph/use-clause interactions,"
           & "private primitive views, profile agreement, runtime dispatching"
           & "checks, warning diagnostics, stale renaming evidence, and"
           & "semantic consumers must share one source-shaped legality result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1425");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1425");
      Row.Blocker_Family := To_Unbounded_String ("RM.Visibility.Renamed_Primitive");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1425 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1425 precision classification");
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
                   Audit.Form_Renamed_Primitive_Visibility_Resolved));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Form_Illegal_Renamed_Primitive_Not_Visible);
      Row.Renamed_Primitive_Not_Visible := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Form_Runtime_Tag_Check_Preserved);
      Row.Runtime_Tag_Check_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal,
                       Audit.Form_Warning_Only_Preserved);
      Row.Warning_Only_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Form_Indeterminate_Missing_Renaming_Evidence);
      Row.Missing_Renaming_Evidence := True;
      Row.Complete_Renaming_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Legal,
                       Audit.Form_Renamed_Primitive_Overload_Resolved);
      Row.Closure := Audit.Closure_Primitive_Visibility_Evidence;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1425 should close the renamed primitive visibility gap");
      Assert (Results.Remediated_Count >= 2, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Warning_Count = 1, "warning count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status
        (Results, 1,
         Audit.Status_Renamed_Primitive_Visibility_Resolved,
         Precision.Class_Legal);
      Expect_Status
        (Results, 2,
         Audit.Status_Illegal_Renamed_Primitive_Not_Visible,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 3,
         Audit.Status_Runtime_Tag_Check_Preserved,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 4,
         Audit.Status_Warning_Only_Preserved,
         Precision.Class_Legal);
      Expect_Status
        (Results, 5,
         Audit.Status_Indeterminate_Missing_Renaming_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 6,
         Audit.Status_Renamed_Primitive_Overload_Resolved,
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
      Row.Renamed_Primitive_Not_Visible := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Homograph_Hides_Renamed_Primitive := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Private_Primitive_View_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Renaming_Mode_Profile_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Use_Clause_Ambiguity := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (15);
      Row.Missing_Full_View := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (16);
      Row.Stale_Renaming_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (17);
      Row.Missing_Visibility_Evidence := True;
      Row.Complete_Visibility_Evidence := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 10,
         Audit.Status_Illegal_Renamed_Primitive_Not_Visible,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 11,
         Audit.Status_Illegal_Homograph_Hides_Renamed_Primitive,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 12,
         Audit.Status_Illegal_Private_Primitive_View_Mismatch,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 13,
         Audit.Status_Illegal_Renaming_Mode_Profile_Mismatch,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 14,
         Audit.Status_Illegal_Use_Clause_Ambiguity,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 15,
         Audit.Status_Indeterminate_Private_Primitive_View,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 16,
         Audit.Status_Indeterminate_Stale_Renaming_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 17,
         Audit.Status_Indeterminate_Missing_Visibility_Evidence,
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
      Row.Inventory_Row_From_Pass1366 := False;
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
      Row.Renaming_Fingerprint := 1;
      Row.Expected_Renaming_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (27);
      Row.Visibility_Fingerprint := 1;
      Row.Expected_Visibility_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (28);
      Row.Consumer_Fingerprint := 1;
      Row.Expected_Consumer_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 20,
         Audit.Status_Missing_Pass1366_Inventory_Row,
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
         Audit.Status_Renaming_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 27,
         Audit.Status_Visibility_Fingerprint_Mismatch,
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
         "renamed primitive visibility gap remediated");
      Register_Routine
        (T, Test_Rejections'Access,
         "renamed primitive visibility rejection cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1425;
