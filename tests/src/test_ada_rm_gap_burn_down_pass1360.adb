with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1360;

package body Test_Ada_RM_Gap_Burn_Down_Pass1360 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1360;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Recovered_Source_Kind;
   use type Audit.Recovery_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1360");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Source_Kind : Audit.Recovered_Source_Kind := Audit.Source_Complete_Source;
      Context : Audit.Recovery_Context_Kind := Audit.Context_Complete_Source_Unit;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Partial_Source_Recovery_Semantic_Closure;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Parser_AST_Coverage;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Source_Kind := Source_Kind;
      Row.Context := Context;
      Row.Name := To_Unbounded_String
        ("pass1360 source-shaped partial source recovery row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1360");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1360 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1360 classification");
   end Expect_Status;

   procedure Test_Balanced_Partial_Source_Recovery_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Source_Complete_Source,
                       Audit.Context_Complete_Source_Unit);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Semantic_Degradation);
      Row.Runtime_Check_Context := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Indeterminate,
                       Audit.Source_Missing_Token,
                       Audit.Context_Parser_Recovery);
      Row.Missing_Token := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Illegal,
                       Audit.Source_Partial_Call,
                       Audit.Context_Partial_Aggregate_Call_Expression);
      Row.Hard_Diagnostic_From_Incomplete_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Aggregate,
                       Audit.Context_Partial_Aggregate_Call_Expression,
                       Consumers.Consumer_Hover_Details);
      Row.Partial_Aggregate := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Partial_Source_Recovery_Gap_Closed (Results),
              "balanced partial-source recovery gap closes");
      Assert (Results.Legal_Count = 1, "legal complete-source row counted");
      Assert (Results.Runtime_Check_Count = 1,
              "runtime-check recovery row counted");
      Assert (Results.Indeterminate_Count = 2,
              "indeterminate recovery rows counted");
      Assert (Results.Illegal_Count = 1,
              "false-hard-diagnostic row counted");

      Expect_Status (Results, 1, Audit.Status_Legal_Complete_Source_Closure,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Runtime_Check_Evidence_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 3, Audit.Status_Indeterminate_Missing_Token,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 4,
         Audit.Status_Illegal_Hard_Diagnostic_From_Incomplete_Source,
         Precision.Class_Illegal);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Partial_Aggregate,
                     Precision.Class_Indeterminate);
   end Test_Balanced_Partial_Source_Recovery_Closes;

   procedure Test_Parser_Recovery_Blocks_Dependent_Checks

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Indeterminate,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Parser_Recovery);
      Row.Degraded_Construct := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11, Precision.Class_Indeterminate,
                       Audit.Source_Token_Only_Construct,
                       Audit.Context_Parser_Recovery);
      Row.Token_Only_Construct := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12, Precision.Class_Indeterminate,
                       Audit.Source_Missing_Source_Span,
                       Audit.Context_Parser_Recovery);
      Row.Missing_Source_Span := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Semantic_Degradation);
      Row.Missing_AST_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Indeterminate_Degraded_Construct,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 11,
                     Audit.Status_Indeterminate_Token_Only_Construct,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 12,
                     Audit.Status_Indeterminate_Missing_Source_Span,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 13,
                     Audit.Status_Indeterminate_Missing_AST_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Parser_Recovery_Blocks_Dependent_Checks;

   procedure Test_Partial_Unit_Closure_Degrades_Precisely

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Body,
                       Audit.Context_Partial_Body_Without_Spec);
      Row.Partial_Body := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Context_Clause,
                       Audit.Context_Partial_Package_Spec);
      Row.Partial_Context_Clause := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Generic_Instantiation,
                       Audit.Context_Partial_Generic_Instantiation);
      Row.Partial_Generic_Instantiation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Subunit_Stub,
                       Audit.Context_Partial_Subunit_Stub);
      Row.Partial_Subunit_Stub := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Declaration,
                       Audit.Context_Partial_Private_Full_View);
      Row.Private_View := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Indeterminate_Partial_Body,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 21,
                     Audit.Status_Indeterminate_Partial_Context_Clause,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22,
                     Audit.Status_Indeterminate_Partial_Generic_Instantiation,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 23,
                     Audit.Status_Indeterminate_Partial_Subunit_Stub,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 24, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
   end Test_Partial_Unit_Closure_Degrades_Precisely;

   procedure Test_Incomplete_Constructs_Are_Not_Hard_Errors

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Source_Partial_Call,
                       Audit.Context_Partial_Aggregate_Call_Expression);
      Row.Incomplete_Call_Diagnosed_Wrong_Overload := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Source_Partial_Aggregate,
                       Audit.Context_Partial_Aggregate_Call_Expression);
      Row.Incomplete_Aggregate_Diagnosed_Missing_Component := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Source_Partial_Declaration,
                       Audit.Context_Partial_Package_Spec);
      Row.Partial_Declaration_Treated_Complete := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Source_Partial_Body,
                       Audit.Context_Partial_Body_Without_Spec);
      Row.Partial_Body_Treated_Complete := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Source_Partial_Declaration,
                       Audit.Context_Partial_Private_Full_View);
      Row.Partial_View_Treated_Definitive := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 30,
         Audit.Status_Illegal_Incomplete_Call_Diagnosed_Wrong_Overload,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 31,
         Audit.Status_Illegal_Incomplete_Aggregate_Diagnosed_Missing_Component,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 32,
         Audit.Status_Illegal_Partial_Declaration_Treated_Complete,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 33,
         Audit.Status_Illegal_Partial_Body_Treated_Complete,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 34,
         Audit.Status_Illegal_Partial_View_Treated_Definitive,
         Precision.Class_Illegal);
   end Test_Incomplete_Constructs_Are_Not_Hard_Errors;

   procedure Test_Consumers_Degrade_Without_Inventing_Facts

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Illegal,
                       Audit.Source_Partial_Declaration,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Outline_Model);
      Row.Outline_Unstable_Partial_Symbol := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (41, Precision.Class_Illegal,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Navigation_Invented_Target := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (42, Precision.Class_Illegal,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Hover_Details);
      Row.Hover_Invented_Type := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (43, Precision.Class_Illegal,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Colouring_Reinterprets_Name := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (44, Precision.Class_Illegal,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Diagnostics);
      Row.Consumer_Hides_Indeterminate := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (45, Precision.Class_Illegal,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Bridge_Conflates_Recovered_Source := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40,
                     Audit.Status_Illegal_Outline_Unstable_Partial_Symbol,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Navigation_Invented_Target,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Hover_Invented_Type,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_Colouring_Reinterprets_Name,
                     Precision.Class_Illegal);
      Expect_Status (Results, 44,
                     Audit.Status_Illegal_Consumer_Hides_Indeterminate,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 45,
         Audit.Status_Illegal_Diagnostic_Bridge_Conflates_Recovered_Source,
         Precision.Class_Illegal);
   end Test_Consumers_Degrade_Without_Inventing_Facts;

   procedure Test_Recovery_Fingerprints_Reject_Stale_Evidence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (50, Precision.Class_Illegal,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Snapshot_Refresh);
      Row.Stale_Recovery_Result_Reused := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (51, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Snapshot_Refresh);
      Row.Recovery_Fingerprint := 100;
      Row.Expected_Recovery_Fingerprint := 101;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (52, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Snapshot_Refresh);
      Row.AST_Fingerprint := 200;
      Row.Expected_AST_Fingerprint := 201;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (53, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Expression,
                       Audit.Context_Snapshot_Refresh);
      Row.Missing_Substitution_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50,
                     Audit.Status_Illegal_Stale_Recovery_Result_Reused,
                     Precision.Class_Illegal);
      Expect_Status (Results, 51, Audit.Status_Recovery_Fingerprint_Mismatch,
                     Precision.Class_Unknown);
      Expect_Status (Results, 52, Audit.Status_AST_Fingerprint_Mismatch,
                     Precision.Class_Unknown);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Missing_Substitution_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Recovery_Fingerprints_Reject_Stale_Evidence;

   procedure Test_Diagnostics_Require_Blocker_Families

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (60, Precision.Class_Illegal,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Diagnostics);
      Row.Diagnostics_Blocker_Family_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (61, Precision.Class_Illegal,
                       Audit.Source_Degraded_Construct,
                       Audit.Context_Consumer_Degradation,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Independent_Name_Type_Resolution := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (62, Precision.Class_Indeterminate,
                       Audit.Source_Partial_Call,
                       Audit.Context_Partial_Aggregate_Call_Expression);
      Row.Missing_Profile_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 60,
                     Audit.Status_Illegal_Diagnostics_Missing_Blocker_Family,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 61,
         Audit.Status_Illegal_Consumer_Independent_Name_Type_Resolution,
         Precision.Class_Illegal);
      Expect_Status (Results, 62,
                     Audit.Status_Indeterminate_Missing_Profile_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Diagnostics_Require_Blocker_Families;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Partial_Source_Recovery_Closes'Access,
         "balanced partial-source recovery closure");
      Register_Routine
        (T, Test_Parser_Recovery_Blocks_Dependent_Checks'Access,
         "parser recovery blocks dependent semantic checks");
      Register_Routine
        (T, Test_Partial_Unit_Closure_Degrades_Precisely'Access,
         "partial unit closure degrades precisely");
      Register_Routine
        (T, Test_Incomplete_Constructs_Are_Not_Hard_Errors'Access,
         "incomplete constructs avoid false hard errors");
      Register_Routine
        (T, Test_Consumers_Degrade_Without_Inventing_Facts'Access,
         "consumers degrade without invented facts");
      Register_Routine
        (T, Test_Recovery_Fingerprints_Reject_Stale_Evidence'Access,
         "recovery fingerprints reject stale evidence");
      Register_Routine
        (T, Test_Diagnostics_Require_Blocker_Families'Access,
         "diagnostics require stable blocker families");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1360;
