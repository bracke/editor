with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1379;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1379 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1379;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Policy_Context;
   use type Audit.Policy_Form;
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
      Form : Audit.Policy_Form := Audit.Policy_Preelaborate_Restriction_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Preelaborate_Restriction_Allocator_Edge;
      Row.Family := Matrix.Family_Contracts_Global_Depends_Flow;
      Row.Owner := Matrix.Slice_Contract_Aspect;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_Preelaborable_Initialization;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/preelaborate-restriction-allocator.ads");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("configuration policy, restrictions, preelaborable initialization, allocator/access legality, and consumers must preserve one canonical policy result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1379");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1379");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Policy.Preelaborate.Restriction.Allocator");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1379 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1379 precision classification");
   end Expect_Status;

   procedure Test_Policy_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Policy_Preelaborate_Restriction_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Policy_Illegal_No_Allocators_Violation);
      Row.No_Allocators_Violation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Policy_Runtime_Assertion_Check);
      Row.Runtime_Assertion_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal,
                       Audit.Policy_Warning_Only_Allocator_Restriction);
      Row.Warning_Only_Allocator_Restriction := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Policy_Missing_Policy_Evidence);
      Row.Policy_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1379 should close the selected policy/allocator gap");
      Assert (Results.Remediated_Count >= 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Warning_Only_Count = 1, "warning-only count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Policy_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_No_Allocators_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Assertion_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Warning_Only_Restriction_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Missing_Policy_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Policy_Gap_Remediated;

   procedure Test_Static_Policy_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Illegal_Configuration_Placement := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Categorization_Conflict := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Preelaborate_Access_Initializer := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Configuration_Placement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Categorization_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Preelaborate_Access_Initializer,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_Static_Policy_Rejections;

   procedure Test_Runtime_Warning_And_Indeterminate_Policy

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Policy_Runtime_Assertion_Check);
      Row.Runtime_Assertion_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Legal,
                       Audit.Policy_Warning_Only_Allocator_Restriction);
      Row.Warning_Only_Allocator_Restriction := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Policy_Private_View_Indeterminate);
      Row.Private_Full_View_Available := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Precision.Class_Indeterminate,
                       Audit.Policy_Stale_Policy_Evidence);
      Row.Stale_Policy_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Runtime_Assertion_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 21, Audit.Status_Warning_Only_Restriction_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 22, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 23, Audit.Status_Indeterminate_Stale_Policy_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Runtime_Warning_And_Indeterminate_Policy;

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
      Row.Warning_Only_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36);
      Row.Policy_Fingerprint := 1;
      Row.Expected_Policy_Fingerprint := 2;
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
      Expect_Status (Results, 36, Audit.Status_Policy_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Policy_Gap_Remediated'Access,
         "policy allocator gap remediated");
      Register_Routine
        (T, Test_Static_Policy_Rejections'Access,
         "static policy rejections");
      Register_Routine
        (T, Test_Runtime_Warning_And_Indeterminate_Policy'Access,
         "runtime warning and indeterminate policy cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1379;
