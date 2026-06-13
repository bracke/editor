with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445;

package body Test_Ada_Phase579_Final_Dead_Code_Sweep_Pass1445 is
   package Sweep renames Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445;
   use type Sweep.Artifact_Kind;
   use type Sweep.Sweep_Action;
   use type Sweep.Sweep_Status;
   use type Sweep.Sweep_Class;
   use type Sweep.Sweep_Row;
   use type Sweep.Sweep_Input;
   use type Sweep.Sweep_Result;
   use type Sweep.Sweep_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Final_Dead_Code_Sweep_Pass1445");
   end Name;

   function Base_Row
     (Id : Natural;
      Kind : Sweep.Artifact_Kind;
      Action : Sweep.Sweep_Action;
      Path : String;
      Owner : String;
      Reason : String) return Sweep.Sweep_Row is
      Row : Sweep.Sweep_Row;
   begin
      Row.Id := Id;
      Row.Kind := Kind;
      Row.Action := Action;
      Row.Path := To_Unbounded_String (Path);
      Row.Canonical_Owner := To_Unbounded_String (Owner);
      Row.Reason := To_Unbounded_String (Reason);
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.FinalDeadCodeSweep.Pass1445");
      Row.Source_Fingerprint := Id * 70 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 70 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Suite_Fingerprint := Id * 70 + 3;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint;
      Row.Cleanup_Fingerprint := Id * 70 + 4;
      Row.Expected_Cleanup_Fingerprint := Row.Cleanup_Fingerprint;
      return Row;
   end Base_Row;

   procedure Add_Clean_Sweep (Input : in out Sweep.Sweep_Input) is
      Row : Sweep.Sweep_Row;
   begin
      Row := Base_Row
        (1,
         Sweep.Kind_Test_Package,
         Sweep.Action_Remove_Orphan,
         "tests/src/test_ada_repair_gated_diagnostic_integration_pass1150.ads",
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "off-suite test for superseded repair-gated diagnostic integration removed");
      Row.Artifact_Present_Before := True;
      Row.Artifact_Present_After := False;
      Row.Has_Removal_Evidence := True;
      Sweep.Add_Row (Input, Row);

      Row := Base_Row
        (2,
         Sweep.Kind_Test_Package,
         Sweep.Action_Remove_Orphan,
         "tests/src/test_ada_final_semantic_remediation_worklist_legality_pass1204.ads",
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "off-suite worklist test removed after canonical API consolidation");
      Row.Artifact_Present_Before := True;
      Row.Artifact_Present_After := False;
      Row.Has_Removal_Evidence := True;
      Sweep.Add_Row (Input, Row);

      Row := Base_Row
        (3,
         Sweep.Kind_Test_Package,
         Sweep.Action_Remove_Orphan,
         "tests/src/test_ada_remaining_rm_edge_stabilized_closure_search_index_pass1294.ads",
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "off-suite stabilized closure search-index test removed after pass1428 closure");
      Row.Artifact_Present_Before := True;
      Row.Artifact_Present_After := False;
      Row.Has_Removal_Evidence := True;
      Sweep.Add_Row (Input, Row);

      Row := Base_Row
        (4,
         Sweep.Kind_Source_Package,
         Sweep.Action_Retain_Regression_Dependency,
         "src/core/editor-ada_final_semantic_remediation_worklist_legality.ads",
         "Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality",
         "legacy source retained only because active recheck regression packages depend on it");
      Row.Artifact_Present_After := True;
      Row.Has_Active_Dependent := True;
      Row.Regression_Only := True;
      Sweep.Add_Row (Input, Row);

      Row := Base_Row
        (5,
         Sweep.Kind_Source_Package,
         Sweep.Action_Retain_Regression_Dependency,
         "src/core/editor-ada_remaining_rm_edge_stabilized_closure_search_index.ads",
         "Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality",
         "legacy search-index source retained only for active coverage-proven regression evidence");
      Row.Artifact_Present_After := True;
      Row.Has_Active_Dependent := True;
      Row.Regression_Only := True;
      Sweep.Add_Row (Input, Row);

      Row := Base_Row
        (6,
         Sweep.Kind_Source_Package,
         Sweep.Action_Retain_Canonical,
         "src/core/editor-ada_language_model.ads",
         "Editor.Ada_Language_Model",
         "canonical semantic model surface remains production-owned");
      Row.Artifact_Present_After := True;
      Row.Canonical_Production_Surface := True;
      Sweep.Add_Row (Input, Row);
   end Add_Clean_Sweep;

   procedure Final_Sweep_Removes_Orphan_Tests

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Model : Sweep.Sweep_Model;
   begin
      Add_Clean_Sweep (Input);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 1).Status = Sweep.Status_Removed_Orphan,
         "repair-gated integration orphan test should be removed");
      Assert
        (Sweep.Result_For (Model, 2).Status = Sweep.Status_Removed_Orphan,
         "final semantic remediation worklist orphan test should be removed");
      Assert
        (Sweep.Result_For (Model, 3).Status = Sweep.Status_Removed_Orphan,
         "remaining-edge search-index orphan test should be removed");
      Assert
        (Model.Removed_Count = 3,
         "three orphaned legacy tests should be removed in this sweep");
   end Final_Sweep_Removes_Orphan_Tests;

   procedure Regression_Dependencies_Are_Retained

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Model : Sweep.Sweep_Model;
   begin
      Add_Clean_Sweep (Input);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 4).Status =
         Sweep.Status_Retained_Regression_Dependency,
         "worklist source must be retained while active regressions depend on it");
      Assert
        (Sweep.Result_For (Model, 5).Status =
         Sweep.Status_Retained_Regression_Dependency,
         "search-index source must be retained while active regressions depend on it");
   end Regression_Dependencies_Are_Retained;

   procedure Canonical_Surface_Is_Retained

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Model : Sweep.Sweep_Model;
   begin
      Add_Clean_Sweep (Input);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 6).Status = Sweep.Status_Retained_Canonical,
         "canonical semantic model package must remain production-owned");
      Assert
        (Sweep.Dead_Code_Sweep_Complete (Model),
         "dead-code sweep should be complete for the clean ledger");
      Assert
        (Sweep.Ready_For_Phase_Handoff (Model),
         "clean dead-code sweep should be ready for phase handoff");
   end Canonical_Surface_Is_Retained;

   procedure Core_Suite_Registration_Blocks_Removal

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Row : Sweep.Sweep_Row;
      Model : Sweep.Sweep_Model;
   begin
      Row := Base_Row
        (7,
         Sweep.Kind_Test_Package,
         Sweep.Action_Remove_Orphan,
         "tests/src/bad_still_registered.ads",
         "bad owner",
         "registered test cannot be removed as dead code");
      Row.Artifact_Present_Before := True;
      Row.Artifact_Present_After := False;
      Row.Has_Removal_Evidence := True;
      Row.Registered_In_Core_Suite := True;
      Sweep.Add_Row (Input, Row);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 7).Status =
         Sweep.Status_Rejected_Still_In_Core_Suite,
         "registered Core_Suite tests must not be removed as dead code");
   end Core_Suite_Registration_Blocks_Removal;

   procedure Removed_Surface_Reference_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Row : Sweep.Sweep_Row;
      Model : Sweep.Sweep_Model;
   begin
      Row := Base_Row
        (8,
         Sweep.Kind_Source_Package,
         Sweep.Action_Retain_Regression_Dependency,
         "src/core/bad_reference.ads",
         "bad owner",
         "active code references a removed projection tower package");
      Row.Artifact_Present_After := True;
      Row.Has_Active_Dependent := True;
      Row.Regression_Only := True;
      Row.References_Removed_Surface := True;
      Sweep.Add_Row (Input, Row);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 8).Status =
         Sweep.Status_Rejected_Active_Removed_Reference,
         "active references to removed surfaces must be rejected");
   end Removed_Surface_Reference_Is_Rejected;

   procedure Stale_Sweep_Evidence_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Sweep.Sweep_Input;
      Row : Sweep.Sweep_Row;
      Model : Sweep.Sweep_Model;
   begin
      Row := Base_Row
        (9,
         Sweep.Kind_Test_Package,
         Sweep.Action_Remove_Orphan,
         "tests/src/stale_orphan.ads",
         "bad owner",
         "stale cleanup fingerprint must block removal");
      Row.Artifact_Present_Before := True;
      Row.Artifact_Present_After := False;
      Row.Has_Removal_Evidence := True;
      Row.Expected_Cleanup_Fingerprint := Row.Cleanup_Fingerprint + 1;
      Sweep.Add_Row (Input, Row);
      Model := Sweep.Build (Input);
      Assert
        (Sweep.Result_For (Model, 9).Status =
         Sweep.Status_Rejected_Fingerprint_Mismatch,
         "stale final dead-code sweep evidence must be rejected");
   end Stale_Sweep_Evidence_Is_Rejected;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Final_Sweep_Removes_Orphan_Tests'Access,
         "final dead-code sweep removes orphan tests");
      Register_Routine
        (T, Regression_Dependencies_Are_Retained'Access,
         "regression dependencies are retained");
      Register_Routine
        (T, Canonical_Surface_Is_Retained'Access,
         "canonical production surface is retained");
      Register_Routine
        (T, Core_Suite_Registration_Blocks_Removal'Access,
         "Core_Suite registration blocks removal");
      Register_Routine
        (T, Removed_Surface_Reference_Is_Rejected'Access,
         "removed surface references are rejected");
      Register_Routine
        (T, Stale_Sweep_Evidence_Is_Rejected'Access,
         "stale sweep evidence is rejected");
   end Register_Tests;

end Test_Ada_Phase579_Final_Dead_Code_Sweep_Pass1445;
