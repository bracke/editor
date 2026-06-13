with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Pass1361;

package body Test_Ada_RM_Gap_Burn_Down_Pass1361 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1361;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Snapshot_Change_Kind;
   use type Audit.Semantic_Result_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1361");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Change : Audit.Snapshot_Change_Kind;
      Result : Audit.Semantic_Result_Kind;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Incremental_Snapshot_Semantic_Invalidation;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Change := Change;
      Row.Result := Result;
      Row.Name := To_Unbounded_String
        ("pass1361 source-shaped incremental snapshot invalidation row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1361");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1361 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1361 classification");
   end Expect_Status;

   procedure Test_Balanced_Incremental_Invalidation_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Change_Whitespace_Or_Comment,
                       Audit.Result_Name_Visibility,
                       Consumers.Consumer_Outline_Model);
      Row.Unrelated_Edit := True;
      Row.Result_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Legal,
                       Audit.Change_Type,
                       Audit.Result_Aggregate_Assignment_Call);
      Row.Type_Edited := True;
      Row.Result_Invalidated := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal,
                       Audit.Change_Context_Clause,
                       Audit.Result_Cross_Unit_Elaboration,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Context_Clause_Edited := True;
      Row.Result_Recomputed := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Change_Source_Revision,
                       Audit.Result_Type_Profile,
                       Consumers.Consumer_Hover_Details);
      Row.Runtime_Check_Context := True;
      Row.Runtime_Check_Evidence_Preserved := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Incremental_Invalidation_Gap_Closed (Results),
              "incremental invalidation gap closes with preservation and invalidation");
      Assert (Results.Preserved_Count = 1, "stable result preserved");
      Assert (Results.Invalidated_Count = 1, "dependent result invalidated");
      Assert (Results.Recomputed_Count = 1, "dependent result recomputed");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check evidence preserved");

      Expect_Status (Results, 1, Audit.Status_Legal_Stable_Identity_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Legal_Result_Invalidated,
                     Precision.Class_Legal);
      Expect_Status (Results, 3, Audit.Status_Legal_Result_Recomputed,
                     Precision.Class_Legal);
      Expect_Status (Results, 4, Audit.Status_Legal_Runtime_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Balanced_Incremental_Invalidation_Closes;

   procedure Test_Dependent_Edits_Require_Invalidation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal,
                       Audit.Change_AST_Shape,
                       Audit.Result_AST);
      Row.AST_Changed := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11, Precision.Class_Illegal,
                       Audit.Change_Declaration,
                       Audit.Result_Name_Visibility);
      Row.Declaration_Edited := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Change_Generic_Formal,
                       Audit.Result_Generic_Substitution_Replay);
      Row.Generic_Formal_Edited := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Change_Representation,
                       Audit.Result_Representation_Freezing);
      Row.Representation_Edited := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14, Precision.Class_Illegal,
                       Audit.Change_Recovery_Shape,
                       Audit.Result_Recovery);
      Row.Recovery_Shape_Changed := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 10,
         Audit.Status_Illegal_Result_Not_Invalidated_For_AST_Change,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 11,
         Audit.Status_Illegal_Result_Not_Invalidated_For_Declaration_Edit,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 12,
         Audit.Status_Illegal_Result_Not_Invalidated_For_Generic_Formal_Edit,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 13,
         Audit.Status_Illegal_Result_Not_Invalidated_For_Representation_Edit,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 14,
         Audit.Status_Illegal_Result_Not_Invalidated_For_Recovery_Shape_Edit,
         Precision.Class_Illegal);
   end Test_Dependent_Edits_Require_Invalidation;

   procedure Test_Stale_Live_Editor_Rows_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Change_Request_Token,
                       Audit.Result_Consumer_All);
      Row.Diagnostic_From_Old_Request_Token := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Change_Context_Clause,
                       Audit.Result_Cross_Unit_Elaboration,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Stale_Cross_Unit_Result := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Change_Generic_Formal,
                       Audit.Result_Generic_Substitution_Replay);
      Row.Stale_Generic_Body_Replay := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Change_Representation,
                       Audit.Result_Representation_Freezing);
      Row.Stale_Representation_Freezing_Result := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Change_Recovery_Shape,
                       Audit.Result_Recovery);
      Row.Stale_Recovery_Result := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Diagnostic_From_Old_Request_Token,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Stale_Cross_Unit_Result,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Stale_Generic_Body_Replay,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 23,
         Audit.Status_Illegal_Stale_Representation_Freezing_Result,
         Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Stale_Recovery_Result,
                     Precision.Class_Illegal);
   end Test_Stale_Live_Editor_Rows_Are_Rejected;

   procedure Test_Stable_Preservation_Does_Not_Churn_Identity

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Legal,
                       Audit.Change_Whitespace_Or_Comment,
                       Audit.Result_Name_Visibility,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Unrelated_Edit := True;
      Row.Result_Preserved := True;
      Row.Stable_Entity_Identity_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Change_Whitespace_Or_Comment,
                       Audit.Result_Name_Visibility,
                       Consumers.Consumer_Outline_Model);
      Row.Needless_Entity_Identity_Churn := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Change_None,
                       Audit.Result_Consumer_All);
      Row.Diagnostics_Blocker_Family_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Legal_Stable_Identity_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Needless_Entity_Identity_Churn,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Illegal_Diagnostics_Missing_Blocker_Family,
                     Precision.Class_Illegal);
   end Test_Stable_Preservation_Does_Not_Churn_Identity;

   procedure Test_Consumers_And_Invariants_Cannot_Bypass_Invalidation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Illegal,
                       Audit.Change_Declaration,
                       Audit.Result_Name_Visibility,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Recomputed_Names_Types_Independently := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (41, Precision.Class_Illegal,
                       Audit.Change_Source_Revision,
                       Audit.Result_AST);
      Row.Rendering_Side_Parsing := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (42, Precision.Class_Illegal,
                       Audit.Change_Source_Revision,
                       Audit.Result_Consumer_All);
      Row.Dirty_State_Mutation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (43, Precision.Class_Illegal,
                       Audit.Change_Source_Revision,
                       Audit.Result_Consumer_All);
      Row.File_Save_Reload_During_Analysis := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (44, Precision.Class_Illegal,
                       Audit.Change_Source_Revision,
                       Audit.Result_Consumer_All);
      Row.Command_Keybinding_Workspace_Render_Mutation := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 40,
         Audit.Status_Illegal_Consumer_Recomputed_Names_Types_Independently,
         Precision.Class_Illegal);
      Expect_Status (Results, 41, Audit.Status_Illegal_Rendering_Side_Parsing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Illegal_Dirty_State_Mutation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_File_Save_Reload_During_Analysis,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 44,
         Audit.Status_Illegal_Command_Keybinding_Workspace_Render_Mutation,
         Precision.Class_Illegal);
   end Test_Consumers_And_Invariants_Cannot_Bypass_Invalidation;

   procedure Test_Snapshot_And_Fingerprint_Staleness_Is_Indeterminate

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (50, Precision.Class_Indeterminate,
                       Audit.Change_Source_Revision,
                       Audit.Result_Consumer_All);
      Row.Source_Revision := 2;
      Row.Expected_Source_Revision := 3;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (51, Precision.Class_Indeterminate,
                       Audit.Change_Lifecycle_Generation,
                       Audit.Result_Consumer_All);
      Row.Lifecycle_Generation := 1;
      Row.Expected_Lifecycle_Generation := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (52, Precision.Class_Indeterminate,
                       Audit.Change_Request_Token,
                       Audit.Result_Consumer_All);
      Row.Request_Token := 10;
      Row.Expected_Request_Token := 11;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (53, Precision.Class_Indeterminate,
                       Audit.Change_AST_Shape,
                       Audit.Result_AST);
      Row.AST_Fingerprint := 4;
      Row.Expected_AST_Fingerprint := 5;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (54, Precision.Class_Indeterminate,
                       Audit.Change_Type,
                       Audit.Result_Type_Profile);
      Row.Type_Fingerprint := 8;
      Row.Expected_Type_Fingerprint := 9;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (55, Precision.Class_Indeterminate,
                       Audit.Change_Recovery_Shape,
                       Audit.Result_Recovery);
      Row.Recovery_Fingerprint := 12;
      Row.Expected_Recovery_Fingerprint := 13;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Source_Revision_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Lifecycle_Generation_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52, Audit.Status_Request_Token_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53, Audit.Status_AST_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54, Audit.Status_Type_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 55, Audit.Status_Recovery_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Snapshot_And_Fingerprint_Staleness_Is_Indeterminate;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Incremental_Invalidation_Closes'Access,
         "balanced incremental invalidation closes");
      Register_Routine
        (T, Test_Dependent_Edits_Require_Invalidation'Access,
         "dependent edits require invalidation or recomputation");
      Register_Routine
        (T, Test_Stale_Live_Editor_Rows_Are_Rejected'Access,
         "stale live-editor rows are rejected");
      Register_Routine
        (T, Test_Stable_Preservation_Does_Not_Churn_Identity'Access,
         "stable preservation does not churn identity");
      Register_Routine
        (T, Test_Consumers_And_Invariants_Cannot_Bypass_Invalidation'Access,
         "consumers and invariants cannot bypass invalidation");
      Register_Routine
        (T, Test_Snapshot_And_Fingerprint_Staleness_Is_Indeterminate'Access,
         "snapshot and fingerprint staleness is indeterminate");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1361;
