with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1377;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1377 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1377;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Lifetime_Context;
   use type Audit.Lifetime_Form;
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
      Form : Audit.Lifetime_Form := Audit.Lifetime_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Access_Discriminant_Return_Object_Finalization_Edge;
      Row.Family := Matrix.Family_Access_Types_Accessibility;
      Row.Owner := Matrix.Slice_Accessibility_Lifetime;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_Return_Object_Accessibility;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/access-discriminant-return-object-finalization.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("access discriminants, returned aggregate components, allocator-created objects, generic access actuals, and controlled finalization ownership must preserve one canonical master/lifetime/accessibility result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1377");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1377");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Accessibility.Return_Object.Access_Discriminant_Finalization");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1377 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1377 precision classification");
   end Expect_Status;

   procedure Test_Access_Lifetime_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Lifetime_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Lifetime_Access_Discriminant_Escape);
      Row.Access_Discriminant_Escape := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Lifetime_Runtime_Accessibility_Check);
      Row.Runtime_Accessibility_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Lifetime_Missing_Master_Evidence);
      Row.Master_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1377 should close the selected lifetime attribute gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Access_Discriminant_Return_Object_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Access_Discriminant_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Master_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Access_Lifetime_Gap_Remediated;

   procedure Test_Access_Lifetime_Static_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Return_Object_Component_Escape := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Controlled_Finalization_Owner_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Allocator_Finalization_Hazard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Static_Accessibility_Escape := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Generic_Substitution_Lifetime_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (15);
      Row.Alias_Consumer_Disagreement := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (16);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Return_Object_Component_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Controlled_Finalization_Owner_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Allocator_Finalization_Hazard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Static_Accessibility_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Generic_Substitution_Lifetime_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Alias_Consumer_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_Access_Lifetime_Static_Rejections;

   procedure Test_Runtime_And_Indeterminate_Lifetime

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Lifetime_Runtime_Accessibility_Check);
      Row.Runtime_Accessibility_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Indeterminate,
                       Audit.Lifetime_Private_View_Indeterminate);
      Row.Private_Full_View_Available := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Lifetime_Stale_Lifetime_Evidence);
      Row.Stale_Lifetime_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 21, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Indeterminate_Stale_Lifetime_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Runtime_And_Indeterminate_Lifetime;

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
      Row.Runtime_Check_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36);
      Row.Lifetime_Fingerprint := 1;
      Row.Expected_Lifetime_Fingerprint := 2;
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
      Expect_Status (Results, 36, Audit.Status_Lifetime_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Access_Lifetime_Gap_Remediated'Access,
         "access discriminant return-object lifetime gap remediated");
      Register_Routine
        (T, Test_Access_Lifetime_Static_Rejections'Access,
         "access lifetime static rejections");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Lifetime'Access,
         "runtime and indeterminate lifetime cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1377;
