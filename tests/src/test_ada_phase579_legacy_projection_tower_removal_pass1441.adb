with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441;

package body Test_Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441 is
   package Removal renames Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441;
   use type Removal.Removed_Surface_Family;
   use type Removal.Removal_Status;
   use type Removal.Removal_Result_Class;
   use type Removal.Removal_Row;
   use type Removal.Removal_Input;
   use type Removal.Removal_Entry;
   use type Removal.Removal_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441");
   end Name;

   function Row
     (Id : Natural;
      Family : Removal.Removed_Surface_Family;
      Package_Name : String;
      Source_Path : String;
      Test_Path : String) return Removal.Removal_Row is
      R : Removal.Removal_Row;
   begin
      R.Id := Id;
      R.Family := Family;
      R.Package_Name := To_Unbounded_String (Package_Name);
      R.Source_Path := To_Unbounded_String (Source_Path);
      R.Test_Path := To_Unbounded_String (Test_Path);
      R.Canonical_Owner :=
        To_Unbounded_String ("Editor.Ada_Semantic_Diagnostic_Feed");
      R.Replacement_Surface :=
        To_Unbounded_String ("canonical semantic diagnostic/feed consumers after pass1436");
      R.Blocker_Family :=
        To_Unbounded_String ("Phase579.LegacyProjectionTowerRemoval.Pass1441");
      R.Source_Fingerprint := Id * 31 + 1;
      R.Expected_Source_Fingerprint := R.Source_Fingerprint;
      R.Test_Fingerprint := Id * 31 + 2;
      R.Expected_Test_Fingerprint := R.Test_Fingerprint;
      R.Removal_Fingerprint := Id * 31 + 3;
      R.Expected_Removal_Fingerprint := R.Removal_Fingerprint;
      return R;
   end Row;

   procedure Add_Removed_Tower (Input : in out Removal.Removal_Input) is
   begin
      Removal.Add_Row
        (Input, Row (1, Removal.Family_Command_Palette,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_command_palette_projection_pass1077.ads"));
      Removal.Add_Row
        (Input, Row (2, Removal.Family_Keybinding_Hint,
         "Editor.Ada_Diagnostic_Keybinding_Hint_Projection",
         "src/core/editor-ada_diagnostic_keybinding_hint_projection.ads",
         "tests/src/test_ada_diagnostic_keybinding_hint_projection_pass1078.ads"));
      Removal.Add_Row
        (Input, Row (3, Removal.Family_Workspace_Projection,
         "Editor.Ada_Diagnostic_Workspace_Projection",
         "src/core/editor-ada_diagnostic_workspace_projection.ads",
         "tests/src/test_ada_diagnostic_workspace_projection_pass1079.ads"));
      Removal.Add_Row
        (Input, Row (4, Removal.Family_Render_Projection,
         "Editor.Ada_Diagnostic_Render_Projection",
         "src/core/editor-ada_diagnostic_render_projection.ads",
         "tests/src/test_ada_diagnostic_render_projection_pass1080.ads"));
      Removal.Add_Row
        (Input, Row (5, Removal.Family_Lifecycle_Recovery,
         "Editor.Ada_Diagnostic_Lifecycle_Recovery",
         "src/core/editor-ada_diagnostic_lifecycle_recovery.ads",
         "tests/src/test_ada_diagnostic_lifecycle_recovery_pass1081.ads"));
      Removal.Add_Row
        (Input, Row (6, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Status",
         "src/core/editor-ada_diagnostic_recovery_status.ads",
         "tests/src/test_ada_diagnostic_recovery_status_pass1082.ads"));
      Removal.Add_Row
        (Input, Row (7, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Action_Projection",
         "src/core/editor-ada_diagnostic_recovery_action_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_action_projection_pass1083.ads"));
      Removal.Add_Row
        (Input, Row (8, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Command_Projection",
         "src/core/editor-ada_diagnostic_recovery_command_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_command_projection_pass1084.ads"));
      Removal.Add_Row
        (Input, Row (9, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_recovery_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_command_palette_projection_pass1085.ads"));
      Removal.Add_Row
        (Input, Row (10, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection",
         "src/core/editor-ada_diagnostic_recovery_keybinding_hint_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_keybinding_hint_projection_pass1086.ads"));
      Removal.Add_Row
        (Input, Row (11, Removal.Family_Recovery_Projection,
         "Editor.Ada_Diagnostic_Recovery_Workspace_Projection",
         "src/core/editor-ada_diagnostic_recovery_workspace_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_workspace_projection_pass1087.ads"));
      Removal.Add_Row
        (Input, Row (12, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_projection_pass1088.ads"));
      Removal.Add_Row
        (Input, Row (13, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Lifecycle",
         "src/core/editor-ada_diagnostic_recovery_render_lifecycle.ads",
         "tests/src/test_ada_diagnostic_recovery_render_lifecycle_pass1089.ads"));
      Removal.Add_Row
        (Input, Row (14, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Status",
         "src/core/editor-ada_diagnostic_recovery_render_status.ads",
         "tests/src/test_ada_diagnostic_recovery_render_status_pass1090.ads"));
      Removal.Add_Row
        (Input, Row (15, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Action_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_action_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_action_projection_pass1091.ads"));
      Removal.Add_Row
        (Input, Row (16, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Command_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_command_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_command_projection_pass1092.ads"));
      Removal.Add_Row
        (Input, Row (17, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_command_palette_projection_pass1093.ads"));
      Removal.Add_Row
        (Input, Row (18, Removal.Family_Recovery_Render_Projection,
         "Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_keybinding_hint_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_keybinding_hint_projection_pass1094.ads"));
      Removal.Add_Row
        (Input, Row (19, Removal.Family_Recovery_Render_Workspace,
         "Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_workspace_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_workspace_projection_pass1095.ads"));
   end Add_Removed_Tower;

   procedure Expect
     (Model : Removal.Removal_Model;
      Id : Natural;
      Status : Removal.Removal_Status) is
      Feed_Item : constant Removal.Removal_Entry := Removal.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1441 removal status");
      Assert (Feed_Item.Result_Class = Removal.Class_Accepted,
              "pass1441 clean removal should be accepted");
      Assert (Removal.Class_For_Status (Status) = Feed_Item.Result_Class,
              "pass1441 status/class mapping drifted");
   end Expect;

   procedure Test_Command_Projection_Tower_Removal_Is_Clean

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Removal.Removal_Input;
      Model : Removal.Removal_Model;
   begin
      Add_Removed_Tower (Input);
      Model := Removal.Build (Input);

      Assert (Removal.Removal_Batch_Clean (Model),
              "pass1441 should cleanly remove the obsolete projection tower");
      Assert (Model.Total_Rows = 19, "pass1441 removal ledger should be finite");
      Assert (Model.Removed_Source_Count = 19, "all active source surfaces removed");
      Assert (Model.Removed_Test_Count = 19, "all obsolete tests removed");
      Assert (Model.Rejected_Count = 0, "no removal blocker expected");
      Assert (Model.Indeterminate_Count = 0, "no unowned removal row expected");

      Expect (Model, 1, Removal.Status_Removed_From_Source_And_Test);
      Expect (Model, 19, Removal.Status_Removed_From_Source_And_Test);
   end Test_Command_Projection_Tower_Removal_Is_Clean;

   procedure Test_Remaining_References_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Removal.Removal_Input;
      Model : Removal.Removal_Model;
      R : Removal.Removal_Row;
   begin
      R := Row
        (30, Removal.Family_Command_Palette,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_command_palette_projection_pass1077.ads");
      R.Active_Source_Remains := True;
      Removal.Add_Row (Input, R);

      R := Row
        (31, Removal.Family_Keybinding_Hint,
         "Editor.Ada_Diagnostic_Keybinding_Hint_Projection",
         "src/core/editor-ada_diagnostic_keybinding_hint_projection.ads",
         "tests/src/test_ada_diagnostic_keybinding_hint_projection_pass1078.ads");
      R.Core_Suite_Reference_Remains := True;
      Removal.Add_Row (Input, R);

      R := Row
        (32, Removal.Family_Recovery_Render_Workspace,
         "Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection",
         "src/core/editor-ada_diagnostic_recovery_render_workspace_projection.ads",
         "tests/src/test_ada_diagnostic_recovery_render_workspace_projection_pass1095.ads");
      R.Dangling_Dependent_Source := True;
      Removal.Add_Row (Input, R);

      R := Row
        (33, Removal.Family_Command_Palette,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_command_palette_projection_pass1077.ads");
      R.Noncanonical_Replacement := True;
      Removal.Add_Row (Input, R);

      R := Row
        (34, Removal.Family_Command_Palette,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_command_palette_projection_pass1077.ads");
      R.Reopens_Remaining_Gap := True;
      Removal.Add_Row (Input, R);

      R := Row
        (35, Removal.Family_Command_Palette,
         "Editor.Ada_Diagnostic_Command_Palette_Projection",
         "src/core/editor-ada_diagnostic_command_palette_projection.ads",
         "tests/src/test_ada_diagnostic_command_palette_projection_pass1077.ads");
      R.Removal_Fingerprint := 12345;
      Removal.Add_Row (Input, R);

      Model := Removal.Build (Input);

      Assert (not Removal.Removal_Batch_Clean (Model),
              "blocked pass1441 removal batch must not be clean");
      Assert (Model.Rejected_Count = 6,
              "all pass1441 blocked removal rows should reject");
      Assert
        (Removal.Result_For (Model, 30).Status =
         Removal.Status_Rejected_Active_Source_Remains,
         "active source should reject pass1441 removal");
      Assert
        (Removal.Result_For (Model, 31).Status =
         Removal.Status_Rejected_Core_Suite_Reference_Remains,
         "core suite reference should reject pass1441 removal");
      Assert
        (Removal.Result_For (Model, 32).Status =
         Removal.Status_Rejected_Dangling_Dependent_Source,
         "dangling dependent source should reject pass1441 removal");
      Assert
        (Removal.Result_For (Model, 33).Status =
         Removal.Status_Rejected_Noncanonical_Replacement,
         "noncanonical replacement should reject pass1441 removal");
      Assert
        (Removal.Result_For (Model, 34).Status =
         Removal.Status_Rejected_Reopened_Remaining_Gap,
         "reopened remaining gap should reject pass1441 removal");
      Assert
        (Removal.Result_For (Model, 35).Status =
         Removal.Status_Rejected_Fingerprint_Mismatch,
         "stale removal fingerprint should reject pass1441 removal");
   end Test_Remaining_References_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Command_Projection_Tower_Removal_Is_Clean'Access,
         "pass1441 cleanly removes obsolete diagnostic projection tower");
      Register_Routine
        (T, Test_Remaining_References_Are_Rejected'Access,
         "pass1441 rejects stale references and noncanonical replacements");
   end Register_Tests;

end Test_Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441;
