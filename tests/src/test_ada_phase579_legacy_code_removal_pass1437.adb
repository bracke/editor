with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Legacy_Code_Removal_Pass1437;

package body Test_Ada_Phase579_Legacy_Code_Removal_Pass1437 is
   package Removal renames Editor.Ada_Phase579_Legacy_Code_Removal_Pass1437;
   use type Removal.Legacy_Surface;
   use type Removal.Removal_Status;
   use type Removal.Removal_Result_Class;
   use type Removal.Removal_Row;
   use type Removal.Removal_Input;
   use type Removal.Removal_Entry;
   use type Removal.Removal_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Phase579_Legacy_Code_Removal_Pass1437");
   end Name;

   function Base_Row
     (Id : Natural;
      Surface : Removal.Legacy_Surface;
      Legacy_Path : String;
      Legacy_Package : String) return Removal.Removal_Row is
      Row : Removal.Removal_Row;
   begin
      Row.Id := Id;
      Row.Surface := Surface;
      Row.Legacy_Path := To_Unbounded_String (Legacy_Path);
      Row.Legacy_Package := To_Unbounded_String (Legacy_Package);
      Row.Replacement_Owner :=
        To_Unbounded_String ("Editor.Ada_Phase579_Final_Validation_Surface");
      Row.Removal_Reason :=
        To_Unbounded_String
          ("diagnostic provenance repair-gate scaffold was superseded by "
           & "pass1428 remaining-gap closure and pass1429 architecture cleanup");
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.LegacyCodeRemoval.Pass1437");
      Row.Source_Fingerprint := Id * 10 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 10 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Suite_Fingerprint := Id * 10 + 3;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint;
      Row.Removal_Fingerprint := Id * 10 + 4;
      Row.Expected_Removal_Fingerprint := Row.Removal_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Removal.Removal_Model;
      Id : Natural;
      Status : Removal.Removal_Status;
      Result_Class : Removal.Removal_Result_Class) is
      Feed_Item : constant Removal.Removal_Entry := Removal.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1437 removal status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1437 removal class");
      Assert (Removal.Class_For_Status (Status) = Result_Class,
              "removal status mapping drifted");
   end Expect_Status;

   procedure Test_Removed_Repair_Gated_Diagnostic_Provenance

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Removal.Removal_Input;
      Model : Removal.Removal_Model;
   begin
      Removal.Add_Row
        (Input,
         Base_Row
           (1,
            Removal.Surface_Source_Spec,
            "src/core/editor-ada_repair_gated_diagnostic_provenance.ads",
            "Editor.Ada_Repair_Gated_Diagnostic_Provenance"));
      Removal.Add_Row
        (Input,
         Base_Row
           (2,
            Removal.Surface_Source_Body,
            "src/core/editor-ada_repair_gated_diagnostic_provenance.adb",
            "Editor.Ada_Repair_Gated_Diagnostic_Provenance"));
      Removal.Add_Row
        (Input,
         Base_Row
           (3,
            Removal.Surface_AUnit_Spec,
            "tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.ads",
            "Test_Ada_Repair_Gated_Diagnostic_Provenance_Pass1151"));
      Removal.Add_Row
        (Input,
         Base_Row
           (4,
            Removal.Surface_AUnit_Body,
            "tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.adb",
            "Test_Ada_Repair_Gated_Diagnostic_Provenance_Pass1151"));
      Removal.Add_Row
        (Input,
         Base_Row
           (5,
            Removal.Surface_Core_Suite_Registration,
            "tests/src/core_suite.adb",
            "Test_Ada_Repair_Gated_Diagnostic_Provenance_Pass1151"));
      Removal.Add_Row
        (Input,
         Base_Row
           (6,
            Removal.Surface_Release_Document,
            "docs/release/LEGACY_CODE_REMOVAL_PASS1437.md",
            "docs.release.LEGACY_CODE_REMOVAL_PASS1437"));

      Model := Removal.Build (Input);

      Assert (Removal.Legacy_Code_Removal_Achieved (Model),
              "pass1437 legacy code removal should be closed");
      Assert (Model.Removed_Source_Count = 2, "removed source spec/body");
      Assert (Model.Removed_Test_Count = 2, "removed test spec/body");
      Assert (Model.Removed_Suite_Count = 1, "removed suite registration");
      Assert (Model.Documented_Count = 1, "documented legacy removal");
      Assert (Model.Rejected_Count = 0, "no rejected removal rows");

      Expect_Status
        (Model, 1, Removal.Status_Removed_From_Source_Tree,
         Removal.Class_Accepted);
      Expect_Status
        (Model, 3, Removal.Status_Removed_From_Test_Tree,
         Removal.Class_Accepted);
      Expect_Status
        (Model, 5, Removal.Status_Removed_From_Core_Suite,
         Removal.Class_Accepted);
      Expect_Status
        (Model, 6, Removal.Status_Documented_Removal,
         Removal.Class_Accepted);
   end Test_Removed_Repair_Gated_Diagnostic_Provenance;

   procedure Test_Active_Reference_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Removal.Removal_Input;
      Model : Removal.Removal_Model;
      Row : Removal.Removal_Row;
   begin
      Row := Base_Row
        (10, Removal.Surface_Source_Spec,
         "src/core/editor-ada_legacy.ads", "Editor.Ada_Legacy");
      Row.Source_File_Present := True;
      Removal.Add_Row (Input, Row);

      Row := Base_Row
        (11, Removal.Surface_AUnit_Body,
         "tests/src/test_ada_legacy.adb", "Test_Ada_Legacy");
      Row.Test_File_Present := True;
      Removal.Add_Row (Input, Row);

      Row := Base_Row
        (12, Removal.Surface_Core_Suite_Registration,
         "tests/src/core_suite.adb", "Test_Ada_Legacy");
      Row.Core_Suite_Reference_Present := True;
      Removal.Add_Row (Input, Row);

      Row := Base_Row
        (13, Removal.Surface_Source_Body,
         "src/core/editor-ada_legacy.adb", "Editor.Ada_Legacy");
      Row.Replacement_Is_Canonical := False;
      Removal.Add_Row (Input, Row);

      Model := Removal.Build (Input);

      Expect_Status
        (Model, 10, Removal.Status_Rejected_Active_Source_File,
         Removal.Class_Rejected);
      Expect_Status
        (Model, 11, Removal.Status_Rejected_Active_Test_File,
         Removal.Class_Rejected);
      Expect_Status
        (Model, 12, Removal.Status_Rejected_Core_Suite_Reference,
         Removal.Class_Rejected);
      Expect_Status
        (Model, 13, Removal.Status_Rejected_Replacement_Not_Canonical,
         Removal.Class_Rejected);
      Assert (Model.Rejected_Count = 4,
              "all active legacy references should be rejected");
   end Test_Active_Reference_Rejections;

   procedure Test_Fingerprint_And_Reopened_Gap_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Removal.Removal_Input;
      Model : Removal.Removal_Model;
      Row : Removal.Removal_Row;
   begin
      Row := Base_Row
        (20, Removal.Surface_Source_Spec,
         "src/core/editor-ada_rm_remaining_gap_remediation_pass9999.ads",
         "Editor.Ada_RM_Remaining_Gap_Remediation_Pass9999");
      Row.Reopens_Remaining_Gap := True;
      Removal.Add_Row (Input, Row);

      Row := Base_Row
        (21, Removal.Surface_Source_Body,
         "src/core/editor-ada_stale_legacy.adb", "Editor.Ada_Stale_Legacy");
      Row.Removal_Fingerprint := 1;
      Row.Expected_Removal_Fingerprint := 2;
      Removal.Add_Row (Input, Row);

      Row := Base_Row
        (22, Removal.Surface_Release_Document,
         "docs/release/LEGACY_CODE_REMOVAL_PASS1437.md",
         "docs.release.LEGACY_CODE_REMOVAL_PASS1437");
      Row.Legacy_Package := To_Unbounded_String ("");
      Removal.Add_Row (Input, Row);

      Model := Removal.Build (Input);

      Expect_Status
        (Model, 20, Removal.Status_Rejected_Reopened_Remaining_Gap,
         Removal.Class_Rejected);
      Expect_Status
        (Model, 21, Removal.Status_Rejected_Fingerprint_Mismatch,
         Removal.Class_Rejected);
      Expect_Status
        (Model, 22, Removal.Status_Indeterminate_Missing_Removal_Evidence,
         Removal.Class_Indeterminate);
      Assert (Model.Rejected_Count = 2, "two rejected cleanup rows");
      Assert (Model.Indeterminate_Count = 1, "one indeterminate cleanup row");
   end Test_Fingerprint_And_Reopened_Gap_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Removed_Repair_Gated_Diagnostic_Provenance'Access,
         "removed repair-gated diagnostic provenance scaffold");
      Register_Routine
        (T, Test_Active_Reference_Rejections'Access,
         "active legacy references are rejected");
      Register_Routine
        (T, Test_Fingerprint_And_Reopened_Gap_Rejections'Access,
         "fingerprints and reopened remaining gaps are rejected");
   end Register_Tests;

end Test_Ada_Phase579_Legacy_Code_Removal_Pass1437;
