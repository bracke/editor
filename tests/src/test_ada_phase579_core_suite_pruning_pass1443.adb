with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443;

package body Test_Ada_Phase579_Core_Suite_Pruning_Pass1443 is
   package Pruning renames Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443;
   use type Pruning.Suite_Surface;
   use type Pruning.Prune_Action;
   use type Pruning.Prune_Status;
   use type Pruning.Prune_Class;
   use type Pruning.Prune_Row;
   use type Pruning.Prune_Input;
   use type Pruning.Prune_Entry;
   use type Pruning.Prune_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Core_Suite_Pruning_Pass1443");
   end Name;

   function Base_Row
     (Id : Natural;
      Surface : Pruning.Suite_Surface;
      Action : Pruning.Prune_Action;
      Package_Name : String;
      Test_Package_Name : String;
      Justification : String) return Pruning.Prune_Row is
      Row : Pruning.Prune_Row;
   begin
      Row.Id := Id;
      Row.Surface := Surface;
      Row.Action := Action;
      Row.Package_Name := To_Unbounded_String (Package_Name);
      Row.Test_Package_Name := To_Unbounded_String (Test_Package_Name);
      Row.Justification := To_Unbounded_String (Justification);
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.CoreSuitePruning.Pass1443");
      Row.Source_Package_Present := True;
      Row.Suite_Fingerprint := Id * 40 + 1;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint;
      Row.Test_Fingerprint := Id * 40 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Inventory_Fingerprint := Id * 40 + 3;
      Row.Expected_Inventory_Fingerprint := Row.Inventory_Fingerprint;
      return Row;
   end Base_Row;

   procedure Add_Prune_Ledger (Input : in out Pruning.Prune_Input) is
      Row : Pruning.Prune_Row;
   begin
      Row := Base_Row
        (1, Pruning.Surface_Canonical_Production,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Language_Model",
         "Test_Ada_RM_Remaining_Gap_Remediation_Pass1428",
         "canonical semantic closure tests remain active");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (2, Pruning.Surface_Regression_Evidence,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430",
         "Test_Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430",
         "real corpus regression evidence remains suite-active");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Meaningful_Regression_Evidence := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (3, Pruning.Surface_Cleanup_Gate,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440",
         "Test_Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440",
         "cleanup inventory gate must remain active until cleanup closes");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (4, Pruning.Surface_Removed_Legacy,
         Pruning.Action_Prune_From_Core_Suite,
         "Editor.Ada_Repair_Gated_Diagnostic_Integration",
         "Test_Ada_Repair_Gated_Diagnostic_Integration_Pass1150",
         "superseded repair-gated diagnostic integration is no longer active");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Removed_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (5, Pruning.Surface_Quarantined_Legacy,
         Pruning.Action_Prune_From_Core_Suite,
         "Editor.Ada_Final_Semantic_Remediation_Worklist_Legality",
         "Test_Ada_Final_Semantic_Remediation_Worklist_Legality_Pass1204",
         "superseded remediation worklist remains quarantined, not suite-active");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Quarantined_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (6, Pruning.Surface_Removed_Legacy,
         Pruning.Action_Prune_From_Core_Suite,
         "Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index",
         "Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index_Pass1294",
         "superseded search-index closure is removed from active Core_Suite");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Removed_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (7, Pruning.Surface_Removed_Legacy,
         Pruning.Action_Remove_Test_Files,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "Test_Ada_Diagnostic_Command_Palette_Projection_Pass1077",
         "legacy projection tower test files were physically removed");
      Row.Source_Package_Present := False;
      Row.Removed_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (8, Pruning.Surface_Regression_Evidence,
         Pruning.Action_Keep_Unregistered_Evidence,
         "Editor.Ada_Final_Semantic_Blocker_Trace_Closure",
         "Test_Ada_Final_Semantic_Blocker_Trace_Closure_Pass1198",
         "historical trace evidence retained off-suite as reference only");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Meaningful_Regression_Evidence := True;
      Pruning.Add_Row (Input, Row);
   end Add_Prune_Ledger;

   procedure Expect_Status
     (Model : Pruning.Prune_Model;
      Id : Natural;
      Status : Pruning.Prune_Status;
      Result_Class : Pruning.Prune_Class) is
      Feed_Item : constant Pruning.Prune_Entry := Pruning.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1443 prune status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1443 prune class");
      Assert (Pruning.Class_For_Status (Status) = Result_Class,
              "pass1443 status/class mapping drifted");
   end Expect_Status;

   procedure Test_Core_Suite_Prune_Ledger_Is_Closed

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Pruning.Prune_Input;
      Model : Pruning.Prune_Model;
   begin
      Add_Prune_Ledger (Input);
      Model := Pruning.Build (Input);

      Assert (Pruning.Core_Suite_Pruned (Model),
              "pass1443 should close active Core_Suite pruning");
      Assert (Pruning.Ready_For_Documentation_Cleanup (Model),
              "pass1443 should unblock documentation cleanup");
      Assert (Model.Kept_Registered_Count = 3,
              "three canonical/regression/cleanup tests should stay active");
      Assert (Model.Pruned_From_Suite_Count = 3,
              "three legacy tests should be pruned from Core_Suite");
      Assert (Model.Removed_Test_File_Count = 1,
              "one removed test-file family should be recorded");
      Assert (Model.Unregistered_Evidence_Count = 1,
              "one off-suite evidence family should be retained");

      Expect_Status
        (Model, 1, Pruning.Status_Kept_Canonical_Test,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 2, Pruning.Status_Kept_Regression_Test,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 3, Pruning.Status_Kept_Cleanup_Gate_Test,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 4, Pruning.Status_Pruned_Removed_Legacy_Test,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 5, Pruning.Status_Pruned_Quarantined_Legacy_Test,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 7, Pruning.Status_Removed_Legacy_Test_Files,
         Pruning.Class_Accepted);
      Expect_Status
        (Model, 8, Pruning.Status_Kept_Unregistered_Evidence,
         Pruning.Class_Accepted);
   end Test_Core_Suite_Prune_Ledger_Is_Closed;

   procedure Test_Stale_Or_Dangling_Core_Suite_Entries_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Pruning.Prune_Input;
      Model : Pruning.Prune_Model;
      Row : Pruning.Prune_Row;
   begin
      Row := Base_Row
        (20, Pruning.Surface_Removed_Legacy,
         Pruning.Action_Prune_From_Core_Suite,
         "Editor.Ada_Repair_Gated_Diagnostic_Integration",
         "Test_Ada_Repair_Gated_Diagnostic_Integration_Pass1150",
         "stale registration must be rejected");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Removed_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (21, Pruning.Surface_Canonical_Production,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Semantic_Diagnostic_Feed",
         "Test_Ada_Phase579_Diagnostic_Quality_Validation_Pass1435",
         "canonical test cannot silently disappear from Core_Suite");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (22, Pruning.Surface_Removed_Legacy,
         Pruning.Action_Remove_Test_Files,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "Test_Ada_Diagnostic_Command_Palette_Projection_Pass1077",
         "removed legacy test files must not remain on disk");
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Removed_Legacy_Surface := True;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (23, Pruning.Surface_Cleanup_Gate,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "Test_Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "freshness mismatch must block pruning closure");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint + 1;
      Pruning.Add_Row (Input, Row);

      Row := Base_Row
        (24, Pruning.Surface_Canonical_Production,
         Pruning.Action_Keep_Registered,
         "Editor.Ada_Language_Model",
         "Test_Ada_RM_Remaining_Gap_Remediation_Pass1428",
         "Remaining gap reopening must remain impossible");
      Row.Suite_With_Present := True;
      Row.Suite_Add_Test_Present := True;
      Row.Test_Spec_Present := True;
      Row.Test_Body_Present := True;
      Row.Reopens_Remaining_Gap := True;
      Pruning.Add_Row (Input, Row);

      Model := Pruning.Build (Input);

      Assert (Model.Rejected_Count = 5,
              "all stale/dangling pass1443 rows should reject");
      Expect_Status
        (Model, 20, Pruning.Status_Rejected_Stale_Legacy_Registration,
         Pruning.Class_Rejected);
      Expect_Status
        (Model, 21, Pruning.Status_Rejected_Missing_Registered_Test,
         Pruning.Class_Rejected);
      Expect_Status
        (Model, 22, Pruning.Status_Rejected_Removed_Test_File_Still_Present,
         Pruning.Class_Rejected);
      Expect_Status
        (Model, 23, Pruning.Status_Rejected_Fingerprint_Mismatch,
         Pruning.Class_Rejected);
      Expect_Status
        (Model, 24, Pruning.Status_Rejected_Reopened_Remaining_Gap,
         Pruning.Class_Rejected);
   end Test_Stale_Or_Dangling_Core_Suite_Entries_Are_Rejected;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Core_Suite_Prune_Ledger_Is_Closed'Access,
         "pass1443 closes Core_Suite pruning ledger");
      Register_Routine
        (T, Test_Stale_Or_Dangling_Core_Suite_Entries_Are_Rejected'Access,
         "pass1443 rejects stale or dangling suite entries");
   end Register_Tests;

end Test_Ada_Phase579_Core_Suite_Pruning_Pass1443;
