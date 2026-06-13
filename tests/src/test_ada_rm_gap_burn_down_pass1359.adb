with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1359;

package body Test_Ada_RM_Gap_Burn_Down_Pass1359 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1359;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Source_Unit_Kind;
   use type Audit.Closure_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1359");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Unit_Kind : Audit.Source_Unit_Kind := Audit.Unit_Package_Spec_Body;
      Context : Audit.Closure_Context_Kind := Audit.Context_Whole_Source_Unit;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Source_Unit_Semantic_Closure;
      Row.Family := Matrix.Family_Library_Context_Subunits_Elaboration;
      Row.Owner := Matrix.Slice_End_To_End_Scenario_Audit;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Unit_Kind := Unit_Kind;
      Row.Context := Context;
      Row.Name := To_Unbounded_String
        ("pass1359 source-shaped source-unit semantic closure row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1359");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1359 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1359 classification");
   end Expect_Status;

   procedure Test_Balanced_Source_Unit_Closure_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Context_Clause_Private_Part);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Unit_Generic_Package_Instantiation,
                       Audit.Context_Generic_Substitution_Replay);
      Row.Generic_Substitution_Propagated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Unit_Task_Protected_Concurrent,
                       Audit.Context_Task_Protected_Parallel);
      Row.Runtime_Check_Final_Verdict := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Unit_Mixed_Compilation_Closure,
                       Audit.Context_Whole_Source_Unit);
      Row.Missing_Source_Unit_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Illegal,
                       Audit.Unit_Tagged_Interface_Hierarchy,
                       Audit.Context_Tagged_Interface_Dispatching);
      Row.Dispatching_Effect_Join_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Source_Unit_Semantic_Closure_Gap_Closed (Results),
              "balanced source-unit semantic closure closes");
      Assert (Results.Legal_Count = 1, "legal source-unit row counted");
      Assert (Results.Illegal_Count = 2, "illegal source-unit rows counted");
      Assert (Results.Runtime_Check_Count = 1,
              "runtime final verdict row counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate source-unit row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Source_Unit_Closure,
                     Precision.Class_Legal);
      Expect_Status
        (Results, 2,
         Audit.Status_Illegal_Generic_Substitution_Not_Propagated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 3,
         Audit.Status_Runtime_Check_Final_Verdict_Preserved,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 4,
         Audit.Status_Indeterminate_Missing_Source_Unit_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 5,
         Audit.Status_Illegal_Dispatching_Effect_Join_Missing,
         Precision.Class_Illegal);
   end Test_Balanced_Source_Unit_Closure_Closes;

   procedure Test_Package_And_Generic_Closure_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Context_Clause_Private_Part);
      Row.Context_Closure_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Context_Clause_Private_Part);
      Row.Private_Full_View_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Whole_Source_Unit);
      Row.Body_Spec_Conformance_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Whole_Source_Unit);
      Row.Elaboration_Closure_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Representation_Freezing_Interfacing);
      Row.Representation_Freezing_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Whole_Source_Unit);
      Row.Contract_Flow_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (16, Precision.Class_Illegal,
                       Audit.Unit_Generic_Package_Instantiation,
                       Audit.Context_Generic_Substitution_Replay);
      Row.Generic_Body_Replay_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (17, Precision.Class_Illegal,
                       Audit.Unit_Generic_Package_Instantiation,
                       Audit.Context_Generic_Substitution_Replay);
      Row.Overload_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (18, Precision.Class_Illegal,
                       Audit.Unit_Generic_Package_Instantiation,
                       Audit.Context_Generic_Substitution_Replay);
      Row.Literal_Operator_Substitution_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10,
                     Audit.Status_Illegal_Context_Closure_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Private_Full_View_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Body_Spec_Conformance_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Elaboration_Closure_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 14,
         Audit.Status_Illegal_Representation_Freezing_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 15,
                     Audit.Status_Illegal_Contract_Flow_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16,
                     Audit.Status_Illegal_Generic_Body_Replay_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17,
                     Audit.Status_Illegal_Overload_Profile_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 18,
         Audit.Status_Illegal_Literal_Operator_Substitution_Disagreement,
         Precision.Class_Illegal);
   end Test_Package_And_Generic_Closure_Blockers;

   procedure Test_Tagged_Concurrent_Representation_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Unit_Tagged_Interface_Hierarchy,
                       Audit.Context_Tagged_Interface_Dispatching);
      Row.Tagged_Interface_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Unit_Tagged_Interface_Hierarchy,
                       Audit.Context_Tagged_Interface_Dispatching);
      Row.Class_Wide_Conversion_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Unit_Task_Protected_Concurrent,
                       Audit.Context_Task_Protected_Parallel);
      Row.Concurrent_Shared_State_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Unit_Task_Protected_Concurrent,
                       Audit.Context_Task_Protected_Parallel);
      Row.Protected_Barrier_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Unit_Task_Protected_Concurrent,
                       Audit.Context_Task_Protected_Parallel);
      Row.Parallel_Iterator_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (25, Precision.Class_Illegal,
                       Audit.Unit_Task_Protected_Concurrent,
                       Audit.Context_Task_Protected_Parallel);
      Row.Finalization_Abort_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (26, Precision.Class_Illegal,
                       Audit.Unit_Representation_Interfacing,
                       Audit.Context_Representation_Freezing_Interfacing);
      Row.Representation_Consumer_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (27, Precision.Class_Illegal,
                       Audit.Unit_Mixed_Compilation_Closure,
                       Audit.Context_Whole_Source_Unit);
      Row.Canonical_Closure_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Tagged_Interface_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Class_Wide_Conversion_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 22,
         Audit.Status_Illegal_Concurrent_Shared_State_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 23,
                     Audit.Status_Illegal_Protected_Barrier_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Parallel_Iterator_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Finalization_Abort_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 26,
         Audit.Status_Illegal_Representation_Consumer_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 27,
         Audit.Status_Illegal_Source_Unit_Canonical_Closure_Failed,
         Precision.Class_Illegal);
   end Test_Tagged_Concurrent_Representation_Blockers;

   procedure Test_Consumer_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Unit_Mixed_Compilation_Closure,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Diagnostics);
      Row.Consumer_Final_Verdict_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Diagnostics);
      Row.Diagnostics_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Colouring_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Outline_Model);
      Row.Outline_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Navigation_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (35, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Hover_Details);
      Row.Hover_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (36, Precision.Class_Illegal,
                       Audit.Unit_Package_Spec_Body,
                       Audit.Context_Final_Consumer_Verdict,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (37, Precision.Class_Illegal);
      Row.RM_Coverage_Remediation_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (38, Precision.Class_Illegal);
      Row.Balanced_Final_Regression_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (39, Precision.Class_Illegal);
      Row.Partial_Evidence_Precision_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (40, Precision.Class_Illegal);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (41, Precision.Class_Illegal);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30,
                     Audit.Status_Illegal_Consumer_Final_Verdict_Conflict,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 31,
         Audit.Status_Illegal_Diagnostics_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 32,
         Audit.Status_Illegal_Colouring_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 33,
         Audit.Status_Illegal_Outline_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 34,
         Audit.Status_Illegal_Navigation_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 35,
         Audit.Status_Illegal_Hover_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 36,
         Audit.Status_Illegal_Diagnostic_Bridge_Final_Verdict_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 37,
                     Audit.Status_Illegal_RM_Coverage_Remediation_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Balanced_Regression_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Partial_Evidence_Precision_Lost,
                     Precision.Class_Illegal);
      Assert (Audit.Result_For (Results, 40).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped source unit evidence rejected");
      Assert (Audit.Result_For (Results, 41).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed source unit result rejected");
   end Test_Consumer_And_Audit_Gates;

   procedure Test_Indeterminate_And_Fingerprint_Gates

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
      Row.Missing_Full_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (53, Precision.Class_Indeterminate);
      Row.Missing_Unit_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (54, Precision.Class_Indeterminate);
      Row.Missing_Substitution_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (55, Precision.Class_Indeterminate);
      Row.Missing_Effect_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (56, Precision.Class_Indeterminate);
      Row.Missing_Policy_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (57, Precision.Class_Illegal);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (58, Precision.Class_Illegal);
      Row.Unit_Fingerprint := 1;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (59, Precision.Class_Illegal);
      Row.Effect_Fingerprint := 2;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (60, Precision.Class_Illegal);
      Row.Policy_Fingerprint := 3;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (61, Precision.Class_Illegal);
      Row.Consumer_Fingerprint := 4;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52, Audit.Status_Indeterminate_Missing_Full_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Missing_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54,
                     Audit.Status_Indeterminate_Missing_Substitution_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 55,
                     Audit.Status_Indeterminate_Missing_Effect_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 56,
                     Audit.Status_Indeterminate_Missing_Policy_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale source-unit closure evidence rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Unit_Fingerprint_Mismatch,
              "unit fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Effect_Fingerprint_Mismatch,
              "effect fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Policy_Fingerprint_Mismatch,
              "policy fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_And_Fingerprint_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Source_Unit_Closure_Closes'Access,
         "balanced source-unit semantic closure");
      Register_Routine
        (T, Test_Package_And_Generic_Closure_Blockers'Access,
         "package and generic closure blockers");
      Register_Routine
        (T, Test_Tagged_Concurrent_Representation_Blockers'Access,
         "tagged concurrent representation blockers");
      Register_Routine
        (T, Test_Consumer_And_Audit_Gates'Access,
         "consumer and source-unit audit gates");
      Register_Routine
        (T, Test_Indeterminate_And_Fingerprint_Gates'Access,
         "indeterminate and source-unit fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1359;
