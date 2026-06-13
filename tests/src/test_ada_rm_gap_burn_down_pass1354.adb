with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1354;

package body Test_Ada_RM_Gap_Burn_Down_Pass1354 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1354;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Declaration_Construct_Kind;
   use type Audit.Region_Context_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1354");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Construct : Audit.Declaration_Construct_Kind := Audit.Construct_Package_Spec;
      Context : Audit.Region_Context_Kind := Audit.Context_Package_Declaration;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Declaration_Region_Scope_Completion_Alias;
      Row.Family := Matrix.Family_Declarations_Completions;
      Row.Owner := Matrix.Slice_Body_Spec_Conformance;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("pass1354 source-shaped row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1354");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Feed_Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1354 status");
      Assert (Audit.Expected_For_Status (Feed_Item.Status) = Expected,
              "unexpected pass1354 classification");
   end Expect_Status;

   procedure Test_Balanced_Declaration_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Construct_Package_Spec,
                       Audit.Context_Library_Unit);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Construct_Subprogram_Spec,
                       Audit.Context_Package_Declaration);
      Row.Duplicate_Nonoverloadable_Declaration := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Deferred_Constant_Completion,
                       Audit.Context_Completion_Region);
      Row.Runtime_Default_Initialization_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Construct_Private_Type_Completion,
                       Audit.Context_Completion_Region);
      Row.Missing_Completion_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Illegal,
                       Audit.Construct_Alias_Chain,
                       Audit.Context_Renaming_Alias);
      Row.Alias_Cycle := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Declaration_Scope_Completion_Alias_Gap_Closed (Results),
              "balanced declaration/scope/completion/alias gap closes");
      Assert (Results.Legal_Count = 1, "legal declaration row counted");
      Assert (Results.Illegal_Count = 2, "illegal declaration rows counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime declaration row counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate declaration row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2,
                     Audit.Status_Illegal_Duplicate_Nonoverloadable_Declaration,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3,
                     Audit.Status_Runtime_Default_Initialization_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4,
                     Audit.Status_Indeterminate_Missing_Completion_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 5, Audit.Status_Illegal_Alias_Cycle,
                     Precision.Class_Illegal);
   end Test_Balanced_Declaration_Gap_Closes;

   procedure Test_Declaration_Scope_And_Completion_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal);
      Row.Declarative_Region_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal);
      Row.Scope_Parent_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal);
      Row.Overloadable_Homographs_Agree := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal);
      Row.Hiding_Vs_Conflict_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal);
      Row.Use_Visible_Conflict_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Illegal,
                       Audit.Construct_Private_Type_Completion);
      Row.Private_Full_View_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (16, Precision.Class_Illegal,
                       Audit.Construct_Incomplete_Type_Completion);
      Row.Incomplete_Type_Used_As_Complete := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (17, Precision.Class_Illegal,
                       Audit.Construct_Deferred_Constant_Completion);
      Row.Deferred_Constant_Completion_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (18, Precision.Class_Illegal,
                       Audit.Construct_Deferred_Constant_Completion);
      Row.Deferred_Constant_Completion_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (19, Precision.Class_Illegal,
                       Audit.Construct_Subprogram_Body);
      Row.Body_Spec_Kind_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Construct_Subprogram_Body);
      Row.Body_Spec_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Construct_Task_Body);
      Row.Task_Protected_Body_Completion_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Construct_Generic_Body);
      Row.Generic_Body_Completion_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Construct_Package_Body);
      Row.Duplicate_Completion := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Construct_Package_Body);
      Row.Missing_Completion := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Declarative_Region_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Scope_Parent_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 12,
         Audit.Status_Illegal_Overloadable_Homograph_Collapsed_As_Duplicate,
         Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Direct_Hiding_Conflict_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14,
                     Audit.Status_Illegal_Use_Visible_Conflict_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15,
                     Audit.Status_Illegal_Private_Full_View_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16,
                     Audit.Status_Illegal_Incomplete_Type_Used_As_Complete,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 17,
         Audit.Status_Illegal_Deferred_Constant_Missing_Completion,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 18,
         Audit.Status_Illegal_Deferred_Constant_Completion_Mismatch,
         Precision.Class_Illegal);
      Expect_Status (Results, 19, Audit.Status_Illegal_Body_Spec_Kind_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20, Audit.Status_Illegal_Body_Spec_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Task_Protected_Body_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22, Audit.Status_Illegal_Generic_Body_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Illegal_Duplicate_Completion,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Illegal_Missing_Completion,
                     Precision.Class_Illegal);
   end Test_Declaration_Scope_And_Completion_Blockers;

   procedure Test_Renaming_Alias_And_Cross_Slice_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Construct_Renaming_Declaration,
                       Audit.Context_Renaming_Alias);
      Row.Renaming_Target_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Construct_Renaming_Declaration,
                       Audit.Context_Renaming_Alias);
      Row.Renaming_Target_Visible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Construct_Renaming_Declaration,
                       Audit.Context_Renaming_Alias);
      Row.Renaming_Kind_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Construct_Renaming_Declaration,
                       Audit.Context_Renaming_Alias);
      Row.Renaming_Type_Profile_Mode_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Construct_Renaming_Declaration,
                       Audit.Context_Renaming_Alias);
      Row.Renaming_View_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (35, Precision.Class_Illegal,
                       Audit.Construct_Alias_Chain,
                       Audit.Context_Renaming_Alias);
      Row.Alias_Depth_Overflow := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (36, Precision.Class_Illegal);
      Row.Name_Resolution_Consumes_Entity := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (37, Precision.Class_Illegal);
      Row.Aggregate_Consumes_Completion_View := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (38, Precision.Class_Illegal);
      Row.Assignment_Consumes_Completion_View := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (39, Precision.Class_Illegal,
                       Audit.Construct_Generic_Body,
                       Audit.Context_Generic_Declaration);
      Row.Generic_Substitution_Preserves_Entity := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (40, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Deferred_Constant_Completion);
      Row.Runtime_Default_Initialization_Check := True;
      Row.Runtime_Check_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Renaming_Target_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Renaming_Target_Not_Visible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Renaming_Kind_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 33,
         Audit.Status_Illegal_Renaming_Type_Profile_Mode_Mismatch,
         Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Illegal_Renaming_View_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Illegal_Alias_Depth_Overflow,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 36,
         Audit.Status_Illegal_Name_Resolution_Entity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 37,
         Audit.Status_Illegal_Aggregate_Completion_View_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 38,
         Audit.Status_Illegal_Assignment_Completion_View_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Generic_Substitution_Entity_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 40, Audit.Status_Runtime_Check_Evidence_Lost,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Renaming_Alias_And_Cross_Slice_Blockers;

   procedure Test_Indeterminate_Consumer_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (50, Precision.Class_Indeterminate);
      Row.Private_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (51, Precision.Class_Indeterminate);
      Row.Limited_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (52, Precision.Class_Indeterminate);
      Row.Missing_Declaration_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (53, Precision.Class_Indeterminate);
      Row.Missing_Scope_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (54, Precision.Class_Indeterminate);
      Row.Missing_Alias_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (55, Precision.Class_Unknown);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (56, Precision.Class_Unknown);
      Row.Remediation_Entry_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (57, Precision.Class_Unknown);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (58, Precision.Class_Unknown);
      Row.Consumer_Completion_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (59, Precision.Class_Unknown);
      Row.Consumer_Alias_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (60, Precision.Class_Unknown);
      Row.Consumer_View_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (61, Precision.Class_Unknown);
      Row.Consumer_Diagnostic_Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (62, Precision.Class_Unknown);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (63, Precision.Class_Unknown);
      Row.Expected_Declaration_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (64, Precision.Class_Unknown);
      Row.Expected_Scope_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (65, Precision.Class_Unknown);
      Row.Expected_Completion_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (66, Precision.Class_Unknown);
      Row.Expected_Alias_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (67, Precision.Class_Unknown);
      Row.Expected_View_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (68, Precision.Class_Unknown);
      Row.Expected_Consumer_Fingerprint := 99;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52,
                     Audit.Status_Indeterminate_Missing_Declaration_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Missing_Scope_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54,
                     Audit.Status_Indeterminate_Missing_Alias_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped declaration lifecycle evidence rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing declaration remediation evidence rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed declaration result rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Illegal_Outline_Completion_Disagreement,
              "outline completion disagreement rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Illegal_Navigation_Alias_Disagreement,
              "navigation alias disagreement rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Illegal_Hover_View_Disagreement,
              "hover view disagreement rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Illegal_Diagnostic_Bridge_Disagreement,
              "diagnostic bridge disagreement rejected");
      Assert (Audit.Result_For (Results, 62).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale declaration lifecycle evidence rejected");
      Assert (Audit.Result_For (Results, 63).Status =
              Audit.Status_Declaration_Fingerprint_Mismatch,
              "declaration fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 64).Status =
              Audit.Status_Scope_Fingerprint_Mismatch,
              "scope fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 65).Status =
              Audit.Status_Completion_Fingerprint_Mismatch,
              "completion fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 66).Status =
              Audit.Status_Alias_Fingerprint_Mismatch,
              "alias fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 67).Status =
              Audit.Status_View_Fingerprint_Mismatch,
              "view fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_Consumer_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Declaration_Gap_Closes'Access,
         "balanced declaration scope completion alias gap closure");
      Register_Routine
        (T, Test_Declaration_Scope_And_Completion_Blockers'Access,
         "declaration scope and completion blockers");
      Register_Routine
        (T, Test_Renaming_Alias_And_Cross_Slice_Blockers'Access,
         "renaming alias and cross-slice blockers");
      Register_Routine
        (T, Test_Indeterminate_Consumer_And_Audit_Gates'Access,
         "indeterminate consumer and declaration audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1354;
