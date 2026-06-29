with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1372;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1372 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1372;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Renaming_Form;
   use type Audit.Visibility_Form;
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
      Visibility : Audit.Visibility_Form := Audit.Visibility_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Limited_With_Generic_Formal_View_Edge;
      Row.Family := Matrix.Family_Names_Visibility_Selected_Attributes;
      Row.Owner := Matrix.Slice_Visibility_Name_Resolution;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Form := Audit.Subprogram_Renaming;
      Row.Visibility := Visibility;
      Row.Source_File := To_Unbounded_String ("src/limited-with-generic-formal-view.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("limited-with generic formal view must preserve canonical selected-name, alias, and consumer evidence");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1372");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1372");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Names.Visibility.Limited_With_Generic_Formal_View");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1372 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1372 precision classification");
   end Expect_Status;

   procedure Test_Limited_With_Generic_Formal_View_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Visibility_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Visibility_Private_Child_Leak);
      Row.Private_Child_Visible := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Visibility_Runtime_Access_Check);
      Row.Runtime_Access_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Visibility_Limited_View_Only);
      Row.Limited_View_Only := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1372 should close the selected limited-with generic formal view gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Renamed_Visibility_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Private_Child_Visibility_Leak,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Access_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Limited_View_Only,
                     Precision.Class_Indeterminate);
   end Test_Limited_With_Generic_Formal_View_Gap_Remediated;

   procedure Test_Generic_Formal_View_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Renamed_Target_Visible := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Selected_Name_Unambiguous := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Alias_Cycle := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Alias_Depth_Overflow := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Renamed_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (15);
      Row.Renamed_Type_View_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Renamed_Target_Invisible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Selected_Name_Ambiguous,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Alias_Cycle,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Alias_Depth_Overflow,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Renamed_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Renamed_Type_View_Mismatch,
                     Precision.Class_Illegal);
   end Test_Generic_Formal_View_Rejections;

   procedure Test_Consumer_And_View_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20);
      Row.Use_Visible_Homograph_Conflict := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21);
      Row.Private_Full_View_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23);
      Row.Private_View_Only := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24);
      Row.Missing_Cross_Unit_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Missing_Selected_Name_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Illegal_Use_Visible_Homograph_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Illegal_Private_Full_View_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Indeterminate_Private_View_Only,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 24, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 25, Audit.Status_Indeterminate_Missing_Selected_Name_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Consumer_And_View_Rejections;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (30);
      Row.Inventory_Row_From_Pass1366 := False;
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

      Expect_Status (Results, 30, Audit.Status_Missing_Pass1366_Inventory_Row,
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
        (T, Test_Limited_With_Generic_Formal_View_Gap_Remediated'Access,
         "private child generic formal view gap remediated");
      Register_Routine
        (T, Test_Generic_Formal_View_Rejections'Access,
         "generic formal view rejections");
      Register_Routine
        (T, Test_Consumer_And_View_Rejections'Access,
         "consumer and view rejections");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1372;
