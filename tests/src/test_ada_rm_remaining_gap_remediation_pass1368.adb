with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368;

package body Test_Ada_RM_Remaining_Gap_Remediation_Pass1368 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Generic_Aggregate_Form;
   use type Audit.Aggregate_Actual_Form;
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
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation_Pass1368");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Actual : Audit.Aggregate_Actual_Form := Audit.Actual_Full_View_Aggregate)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Generic_Discriminated_Private_Aggregate_Edge;
      Row.Family := Matrix.Family_Generics_Contracts_Substitution_Replay;
      Row.Owner := Matrix.Slice_Generic_Body_Replay;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Form := Audit.Formal_Private_Type_Aggregate;
      Row.Actual := Actual;
      Row.Source_File := To_Unbounded_String ("src/generic-private-aggregate.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("generic body replay of discriminated private aggregate uses substituted full view");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1368");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Generic.Body_Replay.Discriminated_Private_Aggregate");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1368 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1368 precision classification");
   end Expect_Status;

   procedure Test_Generic_Aggregate_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Actual_Full_View_Aggregate));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Actual_Missing_Discriminant);
      Row.Required_Discriminants_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Actual_Runtime_Predicate_Check);
      Row.Runtime_Predicate_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Actual_Private_View_Only);
      Row.Private_View_Only := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1368 should close the selected generic aggregate gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Substituted_Aggregate,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Missing_Discriminant,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Predicate_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Private_View_Only,
                     Precision.Class_Indeterminate);
   end Test_Generic_Aggregate_Gap_Remediated;

   procedure Test_Substitution_And_View_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Substitution_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Body_Replay_Uses_Substituted_Actuals := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Full_View_Used_For_Replay := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Aggregate_Shape_Complete := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Generic_Substitution_Lost,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 11, Audit.Status_Illegal_Body_Replay_Uses_Formal_Placeholder,
         Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Full_View_Not_Used_For_Replay,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Indeterminate_Missing_Aggregate_Shape,
                     Precision.Class_Indeterminate);
   end Test_Substitution_And_View_Rejections;

   procedure Test_Discriminant_Variant_Predicate_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20);
      Row.Discriminant_Compatibility_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21);
      Row.Default_Component_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22);
      Row.Variant_Governor_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Actual_Inactive_Variant_Component);
      Row.Inactive_Variant_Component := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Actual_Static_Predicate_Failure);
      Row.Static_Predicate_Failure := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Predicate_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26);
      Row.Aggregate_Consumer_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 20, Audit.Status_Illegal_Discriminant_Compatibility_Lost,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 21, Audit.Status_Illegal_Default_Component_Evidence_Lost,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 22, Audit.Status_Illegal_Variant_Governor_Evidence_Lost,
         Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Illegal_Inactive_Variant_Component,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Illegal_Static_Predicate_Failure,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25, Audit.Status_Illegal_Predicate_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 26, Audit.Status_Illegal_Aggregate_Consumer_Disagreement,
                     Precision.Class_Illegal);
   end Test_Discriminant_Variant_Predicate_Rejections;

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
      Row.Source_Fingerprint := 1;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (37);
      Row.Substitution_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Missing_Pass1366_Inventory_Row,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Source_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 37, Audit.Status_Substitution_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Generic_Aggregate_Gap_Remediated'Access,
         "generic private aggregate remaining gap is remediated");
      Register_Routine
        (T, Test_Substitution_And_View_Rejections'Access,
         "generic aggregate replay rejects lost substitution and full-view evidence");
      Register_Routine
        (T, Test_Discriminant_Variant_Predicate_Rejections'Access,
         "discriminant, variant, default component, predicate, and consumer evidence agree");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory ownership, final-gate promotion, balance, and fingerprints are enforced");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Pass1368;
