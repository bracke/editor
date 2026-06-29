with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package body Test_Ada_RM_Gap_Burn_Down_Case_1366 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1366;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Final_Verdict;
   use type Audit.Extraction_Gap;
   use type Audit.Release_Readiness;
   use type Audit.Extraction_Status;
   use type Audit.Extraction_Row;
   use type Audit.Extraction_Input;
   use type Audit.Extraction_Entry;
   use type Audit.Extraction_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;
   package Final_Gate renames Audit.Final_Gate;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   function Base_Row
     (Id : Natural;
      Gap : Audit.Extraction_Gap;
      Readiness : Audit.Release_Readiness;
      Verdict : Audit.Final_Verdict := Final_Gate.Verdict_Indeterminate;
      Coverage : Audit.Coverage_Level := Matrix.Coverage_Covered;
      Remediation_State : Audit.Remediation_State := Remediation.State_Covered)
      return Audit.Extraction_Row is
      Row : Audit.Extraction_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Coverage := Coverage;
      Row.Remediation_Value := Remediation_State;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Expected := Precision.Class_Indeterminate;
      Row.Verdict := Verdict;
      Row.Readiness := Readiness;
      Row.Source_File := To_Unbounded_String ("src/remaining-gaps.adb");
      Row.Missing_Subrule := To_Unbounded_String ("source-shaped remaining subrule");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1366");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1366");
      Row.Blocker_Family := To_Unbounded_String ("RM.P1366.Remaining_Gap");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Extraction_Model;
      Id : Natural;
      Status : Audit.Extraction_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Extraction_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1366 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1366 precision classification");
   end Expect_Status;

   procedure Test_Balanced_Remaining_Gap_Extraction

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Extraction_Input;
      Results : Audit.Extraction_Model;
   begin
      Audit.Add_Row
        (Input,
         Base_Row (1, Audit.Gap_Release_Readiness_Classification,
                   Audit.Ready, Final_Gate.Verdict_Clean));
      Audit.Add_Row
        (Input,
         Base_Row (2, Audit.Gap_Release_Readiness_Classification,
                   Audit.Ready_With_Runtime_Checks,
                   Final_Gate.Verdict_Runtime_Checks));
      Audit.Add_Row
        (Input,
         Base_Row (3, Audit.Gap_Release_Readiness_Classification,
                   Audit.Ready_With_Warnings,
                   Final_Gate.Verdict_Warning_Only));
      Audit.Add_Row
        (Input,
         Base_Row (4, Audit.Gap_Remaining_Indeterminate_Evidence,
                   Audit.Blocked_By_Evidence,
                   Final_Gate.Verdict_Indeterminate,
                   Matrix.Coverage_Blocked,
                   Remediation.State_Blocked));
      Audit.Add_Row
        (Input,
         Base_Row (5, Audit.Gap_Remaining_Indeterminate_Evidence,
                   Audit.Blocked_By_Project_State,
                   Final_Gate.Verdict_Project_Blocked,
                   Matrix.Coverage_Blocked,
                   Remediation.State_Blocked));
      Audit.Add_Row
        (Input,
         Base_Row (6, Audit.Gap_Remaining_Missing_Checker,
                   Audit.Blocked_By_Missing_RM_Checker,
                   Final_Gate.Verdict_Missing_Checker,
                   Matrix.Coverage_None,
                   Remediation.State_Missing));
      Audit.Add_Row
        (Input,
         Base_Row (7, Audit.Gap_Remaining_Partial_Coverage,
                   Audit.Blocked_By_Partial_RM_Coverage,
                   Final_Gate.Verdict_Partial,
                   Matrix.Coverage_Partial,
                   Remediation.State_Partial));
      Audit.Add_Row
        (Input,
         Base_Row (8, Audit.Gap_Remaining_Consumer_Surfacing,
                   Audit.Blocked_By_Consumer_Disagreement,
                   Final_Gate.Verdict_Indeterminate));

      Results := Audit.Build (Input);

      Assert (Audit.Remaining_Gap_Inventory_Extracted (Results),
              "balanced remaining-gap inventory closes");
      Assert (Results.Ready_Count = 1, "ready count");
      Assert (Results.Runtime_Check_Count = 1, "runtime count");
      Assert (Results.Warning_Count = 1, "warning count");
      Assert (Results.Evidence_Blocked_Count = 1, "evidence count");
      Assert (Results.Project_Blocked_Count = 1, "project count");
      Assert (Results.Missing_Checker_Count = 1, "missing checker count");
      Assert (Results.Partial_Coverage_Count = 1, "partial count");
      Assert (Results.Consumer_Disagreement_Count = 1, "consumer count");

      Expect_Status (Results, 1, Audit.Status_Ready, Precision.Class_Legal);
      Expect_Status
        (Results, 2, Audit.Status_Ready_With_Runtime_Checks,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 3, Audit.Status_Ready_With_Warnings, Precision.Class_Legal);
      Expect_Status
        (Results, 4, Audit.Status_Evidence_Blocker_Extracted,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 6, Audit.Status_Missing_Checker_Actionable,
         Precision.Class_Missing_Checker);
      Expect_Status
        (Results, 7, Audit.Status_Partial_Coverage_Actionable,
         Precision.Class_Partial_Coverage);
   end Test_Balanced_Remaining_Gap_Extraction;

   procedure Test_Partial_And_Missing_Gap_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Extraction_Input;
      Results : Audit.Extraction_Model;
      Row : Audit.Extraction_Row;
   begin
      Row := Base_Row (20, Audit.Gap_Remaining_Partial_Coverage,
                       Audit.Blocked_By_Partial_RM_Coverage,
                       Final_Gate.Verdict_Partial,
                       Matrix.Coverage_Covered,
                       Remediation.State_Partial);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Audit.Gap_Remaining_Partial_Coverage,
                       Audit.Blocked_By_Partial_RM_Coverage,
                       Final_Gate.Verdict_Partial,
                       Matrix.Coverage_Partial,
                       Remediation.State_Partial);
      Row.Concrete_Subrules_Named := False;
      Row.Missing_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Audit.Gap_Remaining_Missing_Checker,
                       Audit.Blocked_By_Missing_RM_Checker,
                       Final_Gate.Verdict_Missing_Checker,
                       Matrix.Coverage_None,
                       Remediation.State_Missing);
      Row.Candidate_Owner_Named := False;
      Row.Candidate_Implementing_Package := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Audit.Gap_Remaining_Missing_Checker,
                       Audit.Blocked_By_Missing_RM_Checker,
                       Final_Gate.Verdict_Missing_Checker,
                       Matrix.Coverage_None,
                       Remediation.State_Covered);
      Row.Missing_Checker_Owned := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Audit.Gap_Remaining_Missing_Checker,
                       Audit.Blocked_By_Missing_RM_Checker,
                       Final_Gate.Verdict_Missing_Checker,
                       Matrix.Coverage_None,
                       Remediation.State_Missing);
      Row.Maps_To_RM_Family := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Vague_Partial_Row,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Multiple_Blockers,
                     Precision.Class_Unknown);
      Expect_Status (Results, 22, Audit.Status_Missing_Candidate_Owner,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Orphan_Missing_Checker,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Missing_RM_Family_Mapping,
                     Precision.Class_Illegal);
   end Test_Partial_And_Missing_Gap_Rejections;

   procedure Test_Evidence_State_Separation_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Extraction_Input;
      Results : Audit.Extraction_Model;
      Row : Audit.Extraction_Row;
   begin
      Row := Base_Row (30, Audit.Gap_Remaining_Indeterminate_Evidence,
                       Audit.Blocked_By_Evidence,
                       Final_Gate.Verdict_Indeterminate,
                       Matrix.Coverage_Blocked,
                       Remediation.State_Blocked);
      Row.Evidence_Blocker_Not_RM_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31, Audit.Gap_Remaining_Indeterminate_Evidence,
                       Audit.Blocked_By_Evidence,
                       Final_Gate.Verdict_Stale,
                       Matrix.Coverage_Blocked,
                       Remediation.State_Blocked);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32, Audit.Gap_Remaining_Indeterminate_Evidence,
                       Audit.Blocked_By_Evidence,
                       Final_Gate.Verdict_Cancelled,
                       Matrix.Coverage_Blocked,
                       Remediation.State_Blocked);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33, Audit.Gap_Remaining_Indeterminate_Evidence,
                       Audit.Blocked_By_Evidence,
                       Final_Gate.Verdict_Budget_Exceeded,
                       Matrix.Coverage_Blocked,
                       Remediation.State_Blocked);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34, Audit.Gap_Remaining_Consumer_Surfacing,
                       Audit.Blocked_By_Consumer_Disagreement,
                       Final_Gate.Verdict_Indeterminate);
      Row.Consumer_Gap_Exposed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Final_Readiness_Marked_Clean := True;
      Row.Remaining_Partial_Or_Missing := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30,
                     Audit.Status_Indeterminate_Misclassified_As_RM_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Stale_State_Counted_As_RM_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Cancelled_State_Counted_As_RM_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Budget_State_Counted_As_RM_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Consumer_Gap_Hidden,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35,
                     Audit.Status_Final_Clean_With_Remaining_Gaps,
                     Precision.Class_Illegal);
   end Test_Evidence_State_Separation_Rejections;

   procedure Test_Report_And_Fingerprint_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Extraction_Input;
      Results : Audit.Extraction_Model;
      Row : Audit.Extraction_Row;
   begin
      Row := Base_Row (40, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Source_Shaped_Report := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (41, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Deterministic_Report := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (42, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Source_Fingerprint := 1;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (43, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Project_Index_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (44, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Consumer_Fingerprint := 3;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (45, Audit.Gap_Release_Readiness_Classification,
                       Audit.Ready,
                       Final_Gate.Verdict_Clean);
      Row.Request_Fingerprint := 4;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40, Audit.Status_Non_Source_Shaped_Report,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41, Audit.Status_Nondeterministic_Report,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Source_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 43,
                     Audit.Status_Project_Index_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 44, Audit.Status_Consumer_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 45, Audit.Status_Request_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Report_And_Fingerprint_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Remaining_Gap_Extraction'Access,
         "balanced final RM remaining-gap inventory is extracted");
      Register_Routine
        (T, Test_Partial_And_Missing_Gap_Rejections'Access,
         "partial and missing RM gaps must name owned concrete subrules");
      Register_Routine
        (T, Test_Evidence_State_Separation_Rejections'Access,
         "evidence, stale, cancelled, budget, and consumer states stay separate");
      Register_Routine
        (T, Test_Report_And_Fingerprint_Rejections'Access,
         "remaining-gap report shape and fingerprints are enforced");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1366;
