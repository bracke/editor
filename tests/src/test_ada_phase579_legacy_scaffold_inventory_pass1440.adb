with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440;

package body Test_Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440 is
   package Inventory renames Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440;
   use type Inventory.Scaffold_Family;
   use type Inventory.Scaffold_Classification;
   use type Inventory.Inventory_Status;
   use type Inventory.Inventory_Result_Class;
   use type Inventory.Inventory_Row;
   use type Inventory.Inventory_Input;
   use type Inventory.Inventory_Entry;
   use type Inventory.Inventory_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440");
   end Name;

   function Base_Row
     (Id : Natural;
      Family : Inventory.Scaffold_Family;
      Classification : Inventory.Scaffold_Classification;
      Package_Name : String;
      Surface_Path : String;
      Cleanup_Action : String) return Inventory.Inventory_Row is
      Row : Inventory.Inventory_Row;
   begin
      Row.Id := Id;
      Row.Family := Family;
      Row.Classification := Classification;
      Row.Package_Name := To_Unbounded_String (Package_Name);
      Row.Surface_Path := To_Unbounded_String (Surface_Path);
      Row.Canonical_Owner :=
        To_Unbounded_String ("Editor.Ada_Phase579_Project_Scale_Closure_Pass1436");
      Row.Cleanup_Action := To_Unbounded_String (Cleanup_Action);
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.LegacyScaffoldInventory.Pass1440");
      Row.Source_Fingerprint := Id * 20 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 20 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Inventory_Fingerprint := Id * 20 + 3;
      Row.Expected_Inventory_Fingerprint := Row.Inventory_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Inventory.Inventory_Model;
      Id : Natural;
      Status : Inventory.Inventory_Status;
      Result_Class : Inventory.Inventory_Result_Class) is
      Feed_Item : constant Inventory.Inventory_Entry :=
        Inventory.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1440 inventory status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1440 inventory class");
      Assert (Inventory.Class_For_Status (Status) = Result_Class,
              "pass1440 status/class mapping drifted");
   end Expect_Status;

   procedure Add_Finite_Inventory (Input : in out Inventory.Inventory_Input) is
      Row : Inventory.Inventory_Row;
   begin
      Row := Base_Row
        (1, Inventory.Family_Canonical_Semantic_Core,
         Inventory.Classification_Production,
         "Editor.Ada_Language_Model",
         "src/core/editor-ada_language_model.ads",
         "keep as canonical production semantic entry point");
      Row.Production_Facing := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (2, Inventory.Family_Canonical_Diagnostic_Surface,
         Inventory.Classification_Production,
         "Editor.Ada_Semantic_Diagnostic_Feed",
         "src/core/editor-ada_semantic_diagnostic_feed.ads",
         "keep as canonical diagnostic consumer surface");
      Row.Production_Facing := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (3, Inventory.Family_RM_Remediation_Evidence,
         Inventory.Classification_Regression_Evidence,
         "Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428",
         "src/core/editor-ada_rm_remaining_gap_remediation_pass1428.ads",
         "keep as finite remaining-gap closure evidence");
      Row.Regression_Only := True;
      Row.Has_Core_Suite_Coverage := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (4, Inventory.Family_Project_Closure_Evidence,
         Inventory.Classification_Regression_Evidence,
         "Editor.Ada_Phase579_Project_Scale_Closure_Pass1436",
         "src/core/editor-ada_phase579_project_scale_closure_pass1436.ads",
         "keep as project-scale closure evidence");
      Row.Regression_Only := True;
      Row.Has_Core_Suite_Coverage := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (5, Inventory.Family_Diagnostic_Recovery_Legacy,
         Inventory.Classification_Quarantine,
         "Editor.Ada_Diagnostic_Recovery_Status",
         "src/core/editor-ada_diagnostic_recovery_status.ads",
         "quarantine before destructive removal because it may still carry regression evidence");
      Row.Regression_Only := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (6, Inventory.Family_Diagnostic_Render_Legacy,
         Inventory.Classification_Quarantine,
         "Editor.Ada_Diagnostic_Recovery_Render_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_projection.ads",
         "quarantine before destructive removal because final render variants were already removed");
      Row.Regression_Only := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (7, Inventory.Family_Diagnostic_Command_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "remove after confirming canonical command projection ownership");
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (8, Inventory.Family_Diagnostic_Command_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Diagnostic_Keybinding_Hint_Projection",
         "src/core/editor-ada_diagnostic_keybinding_hint_projection.ads",
         "remove after confirming no command/keybinding mutation leak depends on it");
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (9, Inventory.Family_Repair_Gated_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Repair_Gated_Diagnostic_Integration",
         "src/core/editor-ada_repair_gated_diagnostic_integration.ads",
         "remove because repair-gated provenance has already been removed");
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (10, Inventory.Family_Remediation_Worklist_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Final_Semantic_Remediation_Worklist_Legality",
         "src/core/editor-ada_final_semantic_remediation_worklist_legality.ads",
         "remove or quarantine as superseded by pass1428 and project-scale closure");
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (11, Inventory.Family_Stabilized_Closure_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index",
         "src/core/editor-ada_remaining_rm_edge_stabilized_closure_search_index.ads",
         "remove as pre-closure stabilized search scaffold once references are clean");
      Inventory.Add_Row (Input, Row);
   end Add_Finite_Inventory;

   procedure Test_Finite_Legacy_Scaffold_Inventory

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Inventory.Inventory_Input;
      Model : Inventory.Inventory_Model;
   begin
      Add_Finite_Inventory (Input);
      Model := Inventory.Build (Input);

      Assert (Inventory.Inventory_Complete (Model),
              "pass1440 inventory should classify all finite cleanup rows");
      Assert (Inventory.Ready_For_Removal_Passes (Model),
              "pass1440 should expose enough finite removal candidates");
      Assert (Model.Production_Count = 2, "two production surfaces kept");
      Assert (Model.Regression_Evidence_Count = 2,
              "two regression evidence surfaces kept");
      Assert (Model.Quarantine_Count = 2,
              "two legacy surfaces quarantined before deletion");
      Assert (Model.Removal_Candidate_Count = 5,
              "five finite removal candidates recorded");

      Expect_Status
        (Model, 1, Inventory.Status_Classified_Production,
         Inventory.Class_Accepted);
      Expect_Status
        (Model, 3, Inventory.Status_Classified_Regression_Evidence,
         Inventory.Class_Accepted);
      Expect_Status
        (Model, 5, Inventory.Status_Classified_Quarantine,
         Inventory.Class_Accepted);
      Expect_Status
        (Model, 7, Inventory.Status_Classified_Removal_Candidate,
         Inventory.Class_Accepted);
   end Test_Finite_Legacy_Scaffold_Inventory;

   procedure Test_Unowned_Or_Removed_Legacy_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Inventory.Inventory_Input;
      Model : Inventory.Inventory_Model;
      Row : Inventory.Inventory_Row;
   begin
      Row := Base_Row
        (20, Inventory.Family_Diagnostic_Recovery_Legacy,
         Inventory.Classification_Regression_Evidence,
         "Editor.Ada_Diagnostic_Recovery_Command_Projection",
         "src/core/editor-ada_diagnostic_recovery_command_projection.ads",
         "regression-only recovery projection must not be production-facing");
      Row.Production_Facing := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (21, Inventory.Family_Diagnostic_Render_Legacy,
         Inventory.Classification_Quarantine,
         "Editor.Ada_Diagnostic_Recovery_Render_Final_Status",
         "src/core/editor-ada_diagnostic_recovery_render_final_status.ads",
         "removed final status scaffold must not be referenced");
      Row.References_Removed_Code := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (22, Inventory.Family_Diagnostic_Command_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "legacy command projection must not introduce aliases");
      Row.Adds_Command_Alias := True;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (23, Inventory.Family_RM_Remediation_Evidence,
         Inventory.Classification_Regression_Evidence,
         "Editor.Ada_RM_Remaining_Gap_Remediation_Pass9999",
         "src/core/editor-ada_rm_remaining_gap_remediation_pass9999.ads",
         "new remaining gap after pass1428 is forbidden");
      Row.Reopens_Remaining_Gap := True;
      Inventory.Add_Row (Input, Row);

      Model := Inventory.Build (Input);

      Expect_Status
        (Model, 20, Inventory.Status_Rejected_Unowned_Active_Legacy,
         Inventory.Class_Rejected);
      Expect_Status
        (Model, 21, Inventory.Status_Rejected_Removed_Code_Reference,
         Inventory.Class_Rejected);
      Expect_Status
        (Model, 22, Inventory.Status_Rejected_Production_Alias_Leak,
         Inventory.Class_Rejected);
      Expect_Status
        (Model, 23, Inventory.Status_Rejected_Reopened_Remaining_Gap,
         Inventory.Class_Rejected);
      Assert (Model.Rejected_Count = 4,
              "all unowned legacy inventory rows should be rejected");
   end Test_Unowned_Or_Removed_Legacy_Is_Rejected;

   procedure Test_Inventory_Evidence_Quality_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Inventory.Inventory_Input;
      Model : Inventory.Inventory_Model;
      Row : Inventory.Inventory_Row;
   begin
      Row := Base_Row
        (30, Inventory.Family_Repair_Gated_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Repair_Gated_Diagnostic_Integration",
         "src/core/editor-ada_repair_gated_diagnostic_integration.ads",
         "stale inventory fingerprint must be rejected");
      Row.Inventory_Fingerprint := 1;
      Row.Expected_Inventory_Fingerprint := 2;
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (31, Inventory.Family_Stabilized_Closure_Legacy,
         Inventory.Classification_Remove,
         "Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index",
         "src/core/editor-ada_remaining_rm_edge_stabilized_closure_search_index.ads",
         "missing canonical owner must be indeterminate");
      Row.Canonical_Owner := To_Unbounded_String ("");
      Inventory.Add_Row (Input, Row);

      Row := Base_Row
        (32, Inventory.Family_Unknown,
         Inventory.Classification_Unknown,
         "Editor.Ada_Unclassified_Legacy",
         "src/core/editor-ada_unclassified_legacy.ads",
         "unknown family/classification must be indeterminate");
      Inventory.Add_Row (Input, Row);

      Model := Inventory.Build (Input);

      Expect_Status
        (Model, 30, Inventory.Status_Rejected_Fingerprint_Mismatch,
         Inventory.Class_Rejected);
      Expect_Status
        (Model, 31, Inventory.Status_Indeterminate_Missing_Owner,
         Inventory.Class_Indeterminate);
      Expect_Status
        (Model, 32, Inventory.Status_Indeterminate_Unclassified_Surface,
         Inventory.Class_Indeterminate);
      Assert (Model.Rejected_Count = 1, "one stale inventory row rejected");
      Assert (Model.Indeterminate_Count = 2,
              "two incomplete inventory rows are indeterminate");
   end Test_Inventory_Evidence_Quality_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Finite_Legacy_Scaffold_Inventory'Access,
         "finite legacy scaffold inventory classifies keep/quarantine/remove rows");
      Register_Routine
        (T, Test_Unowned_Or_Removed_Legacy_Is_Rejected'Access,
         "unowned active legacy and removed-code references are rejected");
      Register_Routine
        (T, Test_Inventory_Evidence_Quality_Gates'Access,
         "inventory evidence freshness and ownership gates are enforced");
   end Register_Tests;

end Test_Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440;
