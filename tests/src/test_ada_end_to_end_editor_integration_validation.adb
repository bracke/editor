with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_End_To_End_Editor_Integration_Validation;

package body Test_Ada_End_To_End_Editor_Integration_Validation is
   package Integration renames Editor.Ada_End_To_End_Editor_Integration_Validation;
   use type Integration.Integration_Surface;
   use type Integration.Integration_Status;
   use type Integration.Integration_Result_Class;
   use type Integration.Integration_Row;
   use type Integration.Integration_Input;
   use type Integration.Integration_Entry;
   use type Integration.Integration_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_End_To_End_Editor_Integration_Validation");
   end Name;

   function Base_Row
     (Id : Natural;
      Surface : Integration.Integration_Surface;
      Name : String) return Integration.Integration_Row is
      Row : Integration.Integration_Row;
   begin
      Row.Id := Id;
      Row.Surface := Surface;
      Row.Scenario_Name := To_Unbounded_String (Name);
      Row.Source_Fingerprint := Id * 100 + 21;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Snapshot_Fingerprint := Id * 100 + 22;
      Row.Expected_Snapshot_Fingerprint := Row.Snapshot_Fingerprint;
      Row.Consumer_Fingerprint := Id * 100 + 23;
      Row.Expected_Consumer_Fingerprint := Row.Consumer_Fingerprint;
      Row.Workflow_Fingerprint := Id * 100 + 24;
      Row.Expected_Workflow_Fingerprint := Row.Workflow_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Integration.Integration_Model;
      Id : Natural;
      Status : Integration.Integration_Status;
      Result_Class : Integration.Integration_Result_Class) is
      Feed_Item : constant Integration.Integration_Entry := Integration.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected integration status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected integration result class");
      Assert (Integration.Class_For_Status (Status) = Result_Class,
              "integration status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_End_To_End_Workflow_Validation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Integration.Integration_Input;
      Model : Integration.Integration_Model;
   begin
      Integration.Add_Row (Input, Base_Row
        (1, Integration.Surface_Startup_Project_Open,
         "startup opens project and schedules snapshot-owned analysis"));
      Integration.Add_Row (Input, Base_Row
        (2, Integration.Surface_Buffer_Edit_Save_Reload_Revert,
         "edit/save/reload/revert preserves buffer lifecycle invariants"));
      Integration.Add_Row (Input, Base_Row
        (3, Integration.Surface_File_Tree_Create_Rename_Delete,
         "file tree mutations feed analysis through project index snapshots"));
      Integration.Add_Row (Input, Base_Row
        (4, Integration.Surface_Project_Search,
         "project search consumes stable semantic/project-index snapshots"));
      Integration.Add_Row (Input, Base_Row
        (5, Integration.Surface_Outline_Projection,
         "outline consumes semantic model without rendering-side parsing"));
      Integration.Add_Row (Input, Base_Row
        (6, Integration.Surface_Semantic_Colouring,
         "semantic colouring consumes fresh semantic tokens only"));
      Integration.Add_Row (Input, Base_Row
        (7, Integration.Surface_Diagnostics_Problems,
         "diagnostics and problems agree on blocker-family results"));
      Integration.Add_Row (Input, Base_Row
        (8, Integration.Surface_Build_Panel,
         "build panel preserves independent diagnostics and analysis state"));
      Integration.Add_Row (Input, Base_Row
        (9, Integration.Surface_Workspace_Restore,
         "workspace restore rejects stale semantic projection evidence"));
      Integration.Add_Row (Input, Base_Row
        (10, Integration.Surface_Project_Close_Switch,
         "project close and switch reject stale lifecycle generations"));

      Model := Integration.Build (Input);

      Assert (Integration.End_To_End_Integration_Achieved (Model),
              "end-to-end integration should be achieved for coherent workflow surfaces");
      Assert (Model.Validated_Count = 10, "all integration rows validated");
      Assert (Model.Rejected_Count = 0, "no integration rejection expected");
      Assert (Model.Indeterminate_Count = 0,
              "no indeterminate integration evidence expected");
      Assert (Model.Required_Surface_Count = 10,
              "all required integration surfaces tracked");
      Assert (Model.Missing_Surface_Count = 0,
              "no required integration surface missing");
      Assert (Model.Duplicate_Surface_Count = 0,
              "no duplicate integration surface expected");

      for Id in 1 .. 10 loop
         Expect_Status
           (Model, Id, Integration.Status_Validated, Integration.Class_Validated);
      end loop;
   end Test_End_To_End_Workflow_Validation;

   procedure Test_Duplicate_And_Missing_Surfaces_Block_Completion

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Integration.Integration_Input;
      Model : Integration.Integration_Model;
   begin
      Integration.Add_Row (Input, Base_Row
        (101, Integration.Surface_Startup_Project_Open,
         "startup opens project and schedules snapshot-owned analysis"));
      Integration.Add_Row (Input, Base_Row
        (102, Integration.Surface_Buffer_Edit_Save_Reload_Revert,
         "edit/save/reload/revert preserves buffer lifecycle invariants"));
      Integration.Add_Row (Input, Base_Row
        (103, Integration.Surface_File_Tree_Create_Rename_Delete,
         "file tree mutations feed analysis through project index snapshots"));
      Integration.Add_Row (Input, Base_Row
        (104, Integration.Surface_Project_Search,
         "project search consumes stable semantic/project-index snapshots"));
      Integration.Add_Row (Input, Base_Row
        (105, Integration.Surface_Outline_Projection,
         "outline consumes semantic model without rendering-side parsing"));
      Integration.Add_Row (Input, Base_Row
        (106, Integration.Surface_Semantic_Colouring,
         "semantic colouring consumes fresh semantic tokens only"));
      Integration.Add_Row (Input, Base_Row
        (107, Integration.Surface_Diagnostics_Problems,
         "diagnostics and problems agree on blocker-family results"));
      Integration.Add_Row (Input, Base_Row
        (108, Integration.Surface_Build_Panel,
         "build panel preserves independent diagnostics and analysis state"));
      Integration.Add_Row (Input, Base_Row
        (109, Integration.Surface_Workspace_Restore,
         "workspace restore rejects stale semantic projection evidence"));
      Integration.Add_Row (Input, Base_Row
        (110, Integration.Surface_Project_Search,
         "duplicate project search row cannot replace project close/switch"));

      Model := Integration.Build (Input);

      Assert (not Integration.End_To_End_Integration_Achieved (Model),
              "duplicate and missing integration surfaces must block closure");
      Assert (Model.Required_Surface_Count = 10,
              "required integration surface count remains stable");
      Assert (Model.Missing_Surface_Count = 1,
              "missing project close/switch surface detected");
      Assert (Model.Duplicate_Surface_Count = 1,
              "duplicate project search surface detected");
      Expect_Status
        (Model, 110, Integration.Status_Rejected_Duplicate_Surface,
         Integration.Class_Rejected);
   end Test_Duplicate_And_Missing_Surfaces_Block_Completion;

   procedure Test_Invariant_Mutation_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Integration.Integration_Input;
      Model : Integration.Integration_Model;
      Row : Integration.Integration_Row;
   begin
      Row := Base_Row
        (20, Integration.Surface_Outline_Projection,
         "outline attempts rendering-side parsing");
      Row.Rendering_Side_Parsing := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (21, Integration.Surface_Buffer_Edit_Save_Reload_Revert,
         "analysis attempts file save or reload");
      Row.Save_Reload_During_Analysis := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (22, Integration.Surface_Buffer_Edit_Save_Reload_Revert,
         "analysis mutates dirty state");
      Row.Dirty_State_Mutated := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (23, Integration.Surface_Project_Search,
         "analysis mutates command surface projection");
      Row.Command_Surface_Mutated := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (24, Integration.Surface_Diagnostics_Problems,
         "analysis mutates keybinding projection");
      Row.Keybinding_Mutated := True;
      Integration.Add_Row (Input, Row);

      Model := Integration.Build (Input);

      Expect_Status
        (Model, 20, Integration.Status_Rejected_Rendering_Side_Parsing,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 21, Integration.Status_Rejected_Save_Reload_During_Analysis,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 22, Integration.Status_Rejected_Dirty_State_Mutation,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 23, Integration.Status_Rejected_Command_Surface_Mutation_Leak,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 24, Integration.Status_Rejected_Keybinding_Mutation_Leak,
         Integration.Class_Rejected);
      Assert (Model.Rejected_Count = 5,
              "all editor-invariant mutation leaks rejected");
   end Test_Invariant_Mutation_Rejections;

   procedure Test_Stale_Budget_Consumer_And_Closure_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Integration.Integration_Input;
      Model : Integration.Integration_Model;
      Row : Integration.Integration_Row;
   begin
      Row := Base_Row
        (30, Integration.Surface_Workspace_Restore,
         "analysis mutates workspace restore state");
      Row.Workspace_Mutated_By_Analysis := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (31, Integration.Surface_Semantic_Colouring,
         "analysis mutates render model state");
      Row.Render_Model_Mutated_By_Analysis := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (32, Integration.Surface_Project_Close_Switch,
         "stale snapshot accepted after project switch");
      Row.Stale_Snapshot_Accepted := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (33, Integration.Surface_Project_Search,
         "project search analysis runs without bounded work evidence");
      Row.Bounded_Work := False;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (34, Integration.Surface_Diagnostics_Problems,
         "diagnostic and semantic-colour consumers disagree");
      Row.Consumers_Agree := False;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (35, Integration.Surface_Startup_Project_Open,
         "new Remaining edge appears after finite closure");
      Row.Reopened_Remaining_Gap := True;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (36, Integration.Surface_Build_Panel,
         "build panel carries stale workflow fingerprint");
      Row.Workflow_Fingerprint := 1;
      Row.Expected_Workflow_Fingerprint := 2;
      Integration.Add_Row (Input, Row);

      Row := Base_Row
        (37, Integration.Surface_Unknown,
         "missing integration evidence");
      Row.Evidence_Present := False;
      Integration.Add_Row (Input, Row);

      Model := Integration.Build (Input);

      Expect_Status
        (Model, 30, Integration.Status_Rejected_Workspace_Mutation_Leak,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 31, Integration.Status_Rejected_Render_Mutation_Leak,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 32, Integration.Status_Rejected_Stale_Snapshot_Accepted,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 33, Integration.Status_Rejected_Unbounded_Work,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 34, Integration.Status_Rejected_Consumer_Disagreement,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 35, Integration.Status_Rejected_Reopened_Remaining_Gap,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 36, Integration.Status_Rejected_Stale_Integration_Evidence,
         Integration.Class_Rejected);
      Expect_Status
        (Model, 37, Integration.Status_Indeterminate_Missing_Evidence,
         Integration.Class_Indeterminate);
      Assert (Model.Rejected_Count = 7,
              "integration stale/budget/consumer/closure failures rejected");
      Assert (Model.Indeterminate_Count = 1,
              "missing integration evidence is indeterminate");
   end Test_Stale_Budget_Consumer_And_Closure_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_End_To_End_Workflow_Validation'Access,
         "end-to-end workflow validates project/buffer/search/outline/build surfaces");
      Register_Routine
        (T, Test_Duplicate_And_Missing_Surfaces_Block_Completion'Access,
         "end-to-end integration requires each named surface exactly once");
      Register_Routine
        (T, Test_Invariant_Mutation_Rejections'Access,
         "end-to-end integration rejects editor invariant mutation leaks");
      Register_Routine
        (T, Test_Stale_Budget_Consumer_And_Closure_Rejections'Access,
         "end-to-end integration rejects stale/budget/consumer/closure failures");
   end Register_Tests;

end Test_Ada_End_To_End_Editor_Integration_Validation;
