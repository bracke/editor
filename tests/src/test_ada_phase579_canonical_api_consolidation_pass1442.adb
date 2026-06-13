with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442;

package body Test_Ada_Phase579_Canonical_API_Consolidation_Pass1442 is
   package Consolidation renames
     Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442;
   use type Consolidation.API_Family;
   use type Consolidation.API_Role;
   use type Consolidation.API_Status;
   use type Consolidation.API_Result_Class;
   use type Consolidation.API_Row;
   use type Consolidation.API_Input;
   use type Consolidation.API_Entry;
   use type Consolidation.API_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Canonical_API_Consolidation_Pass1442");
   end Name;

   function Base_Row
     (Id : Natural;
      Family : Consolidation.API_Family;
      Role : Consolidation.API_Role;
      Package_Name : String;
      Public_Surface : String) return Consolidation.API_Row is
      Row : Consolidation.API_Row;
   begin
      Row.Id := Id;
      Row.Family := Family;
      Row.Role := Role;
      Row.Package_Name := To_Unbounded_String (Package_Name);
      Row.Source_Path :=
        To_Unbounded_String ("src/core/" & Package_Name & ".ads");
      Row.Canonical_Owner :=
        To_Unbounded_String ("Editor.Ada_Phase579_Project_Scale_Closure_Pass1436");
      Row.Public_Surface := To_Unbounded_String (Public_Surface);
      Row.Documentation_Path :=
        To_Unbounded_String
          ("docs/release/CANONICAL_API_CONSOLIDATION_PASS1442.md");
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.CanonicalAPIConsolidation.Pass1442");
      Row.Has_Test_Coverage := True;
      Row.Has_Documentation := True;
      Row.Source_Fingerprint := Id * 30 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 30 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Documentation_Fingerprint := Id * 30 + 3;
      Row.Expected_Documentation_Fingerprint :=
        Row.Documentation_Fingerprint;
      Row.API_Fingerprint := Id * 30 + 4;
      Row.Expected_API_Fingerprint := Row.API_Fingerprint;
      return Row;
   end Base_Row;

   procedure Add_Canonical_Surface_Set
     (Input : in out Consolidation.API_Input) is
      Row : Consolidation.API_Row;
   begin
      Row := Base_Row
        (1, Consolidation.Family_Semantic_Core,
         Consolidation.Role_Production_API,
         "editor-ada_language_model", "snapshot-owned Ada semantic model");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (2, Consolidation.Family_Parser_AST_Core,
         Consolidation.Role_Production_API,
         "editor-ada_declaration_parser", "bounded Ada parser and AST input");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (3, Consolidation.Family_Name_Resolution_Core,
         Consolidation.Role_Production_API,
         "editor-ada_symbol_resolver", "canonical name resolution surface");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (4, Consolidation.Family_Diagnostic_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_semantic_diagnostic_feed",
         "canonical semantic diagnostic feed");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (5, Consolidation.Family_Project_Index_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_project_index", "canonical cross-unit project index");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (6, Consolidation.Family_RM_Remediation_Evidence,
         Consolidation.Role_Regression_Evidence,
         "editor-ada_rm_remaining_gap_remediation_pass1428",
         "finite Remaining_* closure evidence");
      Row.Regression_Only := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (7, Consolidation.Family_Regression_Evidence_Surface,
         Consolidation.Role_Regression_Evidence,
         "editor-ada_phase579_real_ada_corpus_validation_pass1430",
         "real Ada corpus validation evidence");
      Row.Regression_Only := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (8, Consolidation.Family_Legacy_Cleanup_Surface,
         Consolidation.Role_Cleanup_Gate,
         "editor-ada_phase579_legacy_scaffold_inventory_pass1440",
         "finite cleanup inventory gate");
      Row.Cleanup_Only := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (9, Consolidation.Family_Legacy_Cleanup_Surface,
         Consolidation.Role_Cleanup_Gate,
         "editor-ada_phase579_legacy_projection_tower_removal_pass1441",
         "legacy projection tower removal gate");
      Row.Cleanup_Only := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (10, Consolidation.Family_Removed_Legacy_Surface,
         Consolidation.Role_Removed_Legacy,
         "editor-ada_diagnostic_command_palette_projection",
         "removed obsolete diagnostic projection tower surface");
      Row.Removed_Legacy := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (11, Consolidation.Family_Removed_Legacy_Surface,
         Consolidation.Role_Quarantined_Legacy,
         "editor-ada_final_semantic_remediation_worklist_legality",
         "quarantined superseded worklist surface");
      Row.Quarantined_Legacy := True;
      Consolidation.Add_Row (Input, Row);
   end Add_Canonical_Surface_Set;

   procedure Expect_Status
     (Model : Consolidation.API_Model;
      Id : Natural;
      Status : Consolidation.API_Status;
      Result_Class : Consolidation.API_Result_Class) is
      Feed_Item : constant Consolidation.API_Entry :=
        Consolidation.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status,
              "unexpected pass1442 canonical API status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1442 canonical API class");
      Assert (Consolidation.Class_For_Status (Status) = Result_Class,
              "pass1442 status/class mapping drifted");
   end Expect_Status;

   procedure Test_Canonical_API_Surface_Set_Is_Consolidated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Consolidation.API_Input;
      Model : Consolidation.API_Model;
   begin
      Add_Canonical_Surface_Set (Input);
      Model := Consolidation.Build (Input);

      Assert (Consolidation.Canonical_API_Consolidated (Model),
              "pass1442 should consolidate canonical production surfaces");
      Assert (Consolidation.Ready_For_Core_Suite_Pruning (Model),
              "pass1442 should unblock Core_Suite pruning");
      Assert (Model.Production_API_Count = 5,
              "five production APIs should be named canonical");
      Assert (Model.Regression_Evidence_Count = 2,
              "two regression-evidence surfaces should be retained");
      Assert (Model.Cleanup_Gate_Count = 2,
              "two cleanup gates should remain active");
      Assert (Model.Removed_Legacy_Count = 1,
              "one removed legacy surface should be tracked");
      Assert (Model.Quarantined_Legacy_Count = 1,
              "one quarantined legacy surface should be tracked");

      Expect_Status
        (Model, 1, Consolidation.Status_Canonical_Production_API,
         Consolidation.Class_Accepted);
      Expect_Status
        (Model, 6, Consolidation.Status_Canonical_Regression_Evidence,
         Consolidation.Class_Accepted);
      Expect_Status
        (Model, 8, Consolidation.Status_Canonical_Cleanup_Gate,
         Consolidation.Class_Accepted);
      Expect_Status
        (Model, 10, Consolidation.Status_Canonical_Removed_Legacy,
         Consolidation.Class_Accepted);
      Expect_Status
        (Model, 11, Consolidation.Status_Canonical_Quarantined_Legacy,
         Consolidation.Class_Accepted);
   end Test_Canonical_API_Surface_Set_Is_Consolidated;

   procedure Test_Noncanonical_Or_Stale_API_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Consolidation.API_Input;
      Model : Consolidation.API_Model;
      Row : Consolidation.API_Row;
   begin
      Row := Base_Row
        (20, Consolidation.Family_Diagnostic_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_diagnostic_command_palette_projection",
         "obsolete command palette projection must not return");
      Row.Production_Facing := True;
      Row.Legacy_Production_Leak := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (21, Consolidation.Family_Removed_Legacy_Surface,
         Consolidation.Role_Removed_Legacy,
         "editor-ada_diagnostic_recovery_render_final_status",
         "removed final status surface must not be referenced");
      Row.Removed_Legacy := True;
      Row.References_Removed_Surface := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (22, Consolidation.Family_Semantic_Core,
         Consolidation.Role_Production_API,
         "editor-ada_language_model_alias", "command alias leak");
      Row.Production_Facing := True;
      Row.Adds_Command_Alias := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (23, Consolidation.Family_Regression_Evidence_Surface,
         Consolidation.Role_Regression_Evidence,
         "editor-ada_rm_remaining_gap_remediation_pass1428",
         "reopened remaining gap evidence");
      Row.Regression_Only := True;
      Row.Reopens_Remaining_Gap := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (24, Consolidation.Family_Project_Index_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_project_index", "stale project index API");
      Row.Production_Facing := True;
      Row.API_Fingerprint := Row.API_Fingerprint + 1;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (25, Consolidation.Family_Diagnostic_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_semantic_diagnostic_feed", "missing API docs");
      Row.Production_Facing := True;
      Row.Has_Documentation := False;
      Consolidation.Add_Row (Input, Row);

      Model := Consolidation.Build (Input);

      Assert (not Consolidation.Canonical_API_Consolidated (Model),
              "rejected API rows must not be treated as consolidated");
      Assert (Model.Rejected_Count = 6,
              "six noncanonical/stale API rows should be rejected");
      Expect_Status
        (Model, 20, Consolidation.Status_Rejected_Legacy_Production_Leak,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 21, Consolidation.Status_Rejected_Removed_Surface_Reference,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 22, Consolidation.Status_Rejected_Production_Alias,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 23, Consolidation.Status_Rejected_Reopened_Remaining_Gap,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 24, Consolidation.Status_Rejected_Fingerprint_Mismatch,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 25, Consolidation.Status_Rejected_Missing_Documentation,
         Consolidation.Class_Rejected);
   end Test_Noncanonical_Or_Stale_API_Is_Rejected;

   procedure Test_Unknown_Or_Undocumented_API_Is_Indeterminate_Or_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Consolidation.API_Input;
      Model : Consolidation.API_Model;
      Row : Consolidation.API_Row;
   begin
      Row := Base_Row
        (30, Consolidation.Family_Unknown,
         Consolidation.Role_Production_API,
         "editor-ada_unknown_surface", "unknown API family");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (31, Consolidation.Family_Semantic_Core,
         Consolidation.Role_Unknown,
         "editor-ada_language_model", "unknown API role");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (32, Consolidation.Family_Diagnostic_Surface,
         Consolidation.Role_Production_API,
         "", "missing owner");
      Row.Production_Facing := True;
      Consolidation.Add_Row (Input, Row);

      Row := Base_Row
        (33, Consolidation.Family_Project_Index_Surface,
         Consolidation.Role_Production_API,
         "editor-ada_project_index", "missing test coverage");
      Row.Production_Facing := True;
      Row.Has_Test_Coverage := False;
      Consolidation.Add_Row (Input, Row);

      Model := Consolidation.Build (Input);

      Assert (Model.Indeterminate_Count = 2,
              "unknown family and role should be indeterminate");
      Assert (Model.Rejected_Count = 2,
              "missing owner/test coverage should be rejected");
      Expect_Status
        (Model, 30, Consolidation.Status_Indeterminate_Unknown_Family,
         Consolidation.Class_Indeterminate);
      Expect_Status
        (Model, 31, Consolidation.Status_Indeterminate_Unknown_Role,
         Consolidation.Class_Indeterminate);
      Expect_Status
        (Model, 32, Consolidation.Status_Rejected_Missing_Owner,
         Consolidation.Class_Rejected);
      Expect_Status
        (Model, 33, Consolidation.Status_Rejected_Missing_Test_Coverage,
         Consolidation.Class_Rejected);
   end Test_Unknown_Or_Undocumented_API_Is_Indeterminate_Or_Rejected;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Canonical_API_Surface_Set_Is_Consolidated'Access,
         "pass1442 consolidates canonical production, evidence, cleanup, and legacy surfaces");
      Register_Routine
        (T, Test_Noncanonical_Or_Stale_API_Is_Rejected'Access,
         "pass1442 rejects noncanonical, stale, alias, and reopened-gap API surfaces");
      Register_Routine
        (T, Test_Unknown_Or_Undocumented_API_Is_Indeterminate_Or_Rejected'Access,
         "pass1442 rejects or marks incomplete unowned API surfaces");
   end Register_Tests;

end Test_Ada_Phase579_Canonical_API_Consolidation_Pass1442;
