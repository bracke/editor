with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1384;

package body Test_Ada_RM_Remaining_Gap_Remediation_Pass1384 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1384;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Project_Index_Context;
   use type Audit.Project_Index_Form;
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
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation_Pass1384");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Form : Audit.Project_Index_Form := Audit.Project_Index_Open_Buffer_Precedence)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Project_Index_Open_Buffer_Duplicate_Unit_Edge;
      Row.Family := Matrix.Family_Library_Context_Subunits_Elaboration;
      Row.Owner := Matrix.Slice_Library_Unit_Subunit;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_Open_Dirty_Buffer_Spec;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/open-buffer-project-index.ads");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("open dirty buffer snapshots must dominate project file index rows while duplicate library units, private-child leaks, missing files, and stale index rows remain explicit blockers");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1384");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1384");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Project_Index.Open_Buffer.Duplicate_Unit.Private_Child");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1384 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1384 precision classification");
   end Expect_Status;

   procedure Test_Project_Index_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Project_Index_Open_Buffer_Precedence));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Project_Index_Illegal_Duplicate_Unit);
      Row.Duplicate_Library_Unit := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Illegal,
                       Audit.Project_Index_Illegal_Private_Child_Leak);
      Row.Private_Child_Visibility_Leak := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Project_Index_Missing_Unit_Evidence);
      Row.Unit_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1384 should close the project-index/open-buffer duplicate-unit gap");
      Assert (Results.Remediated_Count >= 1, "legal count");
      Assert (Results.Illegal_Count = 2, "illegal count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Open_Buffer_Project_Index_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Duplicate_Library_Unit,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Illegal_Private_Child_Visibility_Leak,
                     Precision.Class_Illegal);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Unit_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Project_Index_Gap_Remediated;

   procedure Test_Index_Consumer_And_Stale_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11, Precision.Class_Indeterminate,
                       Audit.Project_Index_Indeterminate_Missing_File);
      Row.Project_File_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12, Precision.Class_Indeterminate,
                       Audit.Project_Index_Indeterminate_Stale_Index);
      Row.Stale_Project_Index := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Indeterminate_Missing_Project_File,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 12, Audit.Status_Indeterminate_Stale_Project_Index,
                     Precision.Class_Indeterminate);
   end Test_Index_Consumer_And_Stale_Rejections;

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
      Row.Illegal_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26);
      Row.Project_Index_Fingerprint := 1;
      Row.Expected_Project_Index_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (27);
      Row.View_Fingerprint := 1;
      Row.Expected_View_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Missing_Pass1366_Inventory_Row,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 21, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 23, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 24, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 25, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 26, Audit.Status_Project_Index_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 27, Audit.Status_View_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Project_Index_Gap_Remediated'Access,
         "project-index/open-buffer duplicate-unit gap remediated");
      Register_Routine
        (T, Test_Index_Consumer_And_Stale_Rejections'Access,
         "project index consumer and stale evidence rejections");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Pass1384;
