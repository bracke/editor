with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1348;

package body Test_Ada_RM_Gap_Burn_Down_Pass1348 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1348;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Tasking_Construct_Kind;
   use type Audit.Tasking_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1348");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Tasking_Protected_Parallel_Shared_State;
      Construct : Audit.Tasking_Construct_Kind := Audit.Construct_Protected_Procedure;
      Context : Audit.Tasking_Context_Kind := Audit.Context_Protected_Action;
      Family : Audit.RM_Family := Matrix.Family_Tasking_Protected_Synchronized;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Tasking_Protected;
      Previous_State : Audit.Remediation_State := Remediation.State_Partial;
      Matrix_Before : Audit.Coverage_Level := Matrix.Coverage_Partial;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Remediation_Present : Boolean := True;
      Matrix_Present : Boolean := True;
      Package_Present : Boolean := True;
      New_Rule : Boolean := True;
      Coverage_Updated : Boolean := True;
      Corpus_Balanced : Boolean := True;
      Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker : Boolean := True;
      Protected_Reentrant_Safe : Boolean := True;
      Protected_Access_Mode_Compatible : Boolean := True;
      Protected_Barrier_Pure : Boolean := True;
      Protected_Shared_State_Effect : Boolean := True;
      Entry_Index_In_Range : Boolean := True;
      Entry_Queue_Compatible : Boolean := True;
      Accept_Effect_Present : Boolean := True;
      Requeue_Target_Compatible : Boolean := True;
      Select_Covered : Boolean := True;
      Terminate_Safe : Boolean := True;
      Abort_Finalization_Safe : Boolean := True;
      Abortable_Select_Safe : Boolean := True;
      Task_Termination_Safe : Boolean := True;
      Controlled_Finalization_Present : Boolean := True;
      Parallel_Effects_Valid : Boolean := True;
      Iterator_Tampering_Static_Safe : Boolean := True;
      Iterator_Tampering_Runtime_Check : Boolean := False;
      Reduction_Profile_Compatible : Boolean := True;
      Reduction_Seed_Compatible : Boolean := True;
      Global_Depends_Preserved : Boolean := True;
      Refined_Flow_Preserved : Boolean := True;
      Volatile_Order_Preserved : Boolean := True;
      Atomic_Order_Preserved : Boolean := True;
      Dispatching_Effect_Join_Present : Boolean := True;
      Sync_Interface_Effects_Agree : Boolean := True;
      Runtime_Bounds_Check : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Effect : Boolean := False;
      Consumer_Tasking_Agrees : Boolean := True;
      Consumer_Protected_Agrees : Boolean := True;
      Consumer_Flow_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_348_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Family;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("tasking protected parallel burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1348");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_348_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Remediation_Entry_Present := Remediation_Present;
      Row.Matrix_Coverage_Present := Matrix_Present;
      Row.Implementing_Package_Present := Package_Present;
      Row.New_Legality_Rule_Added := New_Rule;
      Row.Coverage_Entry_Updated_To_Covered := Coverage_Updated;
      Row.Balanced_Regression_Evidence := Corpus_Balanced;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Reached := Consumer_Reached;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Protected_Action_Reentrancy_Safe := Protected_Reentrant_Safe;
      Row.Protected_Access_Mode_Compatible := Protected_Access_Mode_Compatible;
      Row.Protected_Barrier_Pure := Protected_Barrier_Pure;
      Row.Protected_Shared_State_Write_Has_Effect := Protected_Shared_State_Effect;
      Row.Entry_Family_Index_In_Range := Entry_Index_In_Range;
      Row.Entry_Queue_Discipline_Compatible := Entry_Queue_Compatible;
      Row.Accept_Body_Effect_Evidence_Present := Accept_Effect_Present;
      Row.Requeue_Target_Compatible := Requeue_Target_Compatible;
      Row.Select_Path_Covered := Select_Covered;
      Row.Terminate_Alternative_Dependency_Safe := Terminate_Safe;
      Row.Abort_Finalization_Order_Safe := Abort_Finalization_Safe;
      Row.Abortable_Select_Finalization_Safe := Abortable_Select_Safe;
      Row.Task_Termination_Finalization_Safe := Task_Termination_Safe;
      Row.Controlled_Finalization_Evidence_Present := Controlled_Finalization_Present;
      Row.Parallel_Shared_State_Effects_Valid := Parallel_Effects_Valid;
      Row.Iterator_Tampering_Static_Safe := Iterator_Tampering_Static_Safe;
      Row.Iterator_Tampering_Runtime_Check := Iterator_Tampering_Runtime_Check;
      Row.Reduction_Profile_Compatible := Reduction_Profile_Compatible;
      Row.Reduction_Seed_Compatible := Reduction_Seed_Compatible;
      Row.Global_Depends_Evidence_Preserved := Global_Depends_Preserved;
      Row.Refined_Flow_Evidence_Preserved := Refined_Flow_Preserved;
      Row.Volatile_Ordering_Preserved := Volatile_Order_Preserved;
      Row.Atomic_Ordering_Preserved := Atomic_Order_Preserved;
      Row.Dispatching_Effect_Join_Present := Dispatching_Effect_Join_Present;
      Row.Synchronized_Interface_Effects_Agree := Sync_Interface_Effects_Agree;
      Row.Runtime_Bounds_Check := Runtime_Bounds_Check;
      Row.Runtime_Accessibility_Check := Runtime_Accessibility_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Effect_Evidence := Missing_Effect;
      Row.Consumer_Tasking_Model_Agrees := Consumer_Tasking_Agrees;
      Row.Consumer_Protected_Model_Agrees := Consumer_Protected_Agrees;
      Row.Consumer_Flow_Model_Agrees := Consumer_Flow_Agrees;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Burn_Down_Fingerprint := FP + 1;
      Row.Expected_Burn_Down_Fingerprint :=
        (if Expected_Burn_FP = 0 then Row.Burn_Down_Fingerprint else Expected_Burn_FP);
      Row.Source_Fingerprint := FP + 2;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 3;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Type_Fingerprint := FP + 4;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Profile_Fingerprint := FP + 5;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 6;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 7;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Flow_Fingerprint := FP + 8;
      Row.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Row.Flow_Fingerprint else Expected_Flow_FP);
      Row.Consumer_Fingerprint := FP + 9;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Classification : Audit.Precision_Classification) is
      R : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (R.Status = Status, "unexpected status for row" & Natural'Image (Id));
      Assert (R.Classification = Classification,
              "unexpected classification for row" & Natural'Image (Id));
   end Expect_Status;

   procedure Test_Balanced_Tasking_Protected_Parallel_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal);
      Add_Row
        (Input, 2, Precision.Class_Illegal,
         Construct => Audit.Construct_Protected_Entry,
         Context => Audit.Context_Protected_Barrier,
         Protected_Barrier_Pure => False);
      Add_Row
        (Input, 3, Precision.Class_Legal_With_Runtime_Check,
         Construct => Audit.Construct_Container_Iterator,
         Context => Audit.Context_Iterator,
         Family => Matrix.Family_Iterators_Parallel_Reductions,
         Owner => Matrix.Slice_Iterator_Loop_Parallel,
         Iterator_Tampering_Static_Safe => False,
         Iterator_Tampering_Runtime_Check => True);
      Add_Row
        (Input, 4, Precision.Class_Indeterminate,
         Context => Audit.Context_Synchronized_Interface,
         Owner => Matrix.Slice_Interface_Synchronized,
         Missing_Effect => True);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 4, "balanced pass1348 rows counted");
      Assert (Results.Legal_Count = 1, "legal row counted");
      Assert (Results.Illegal_Count = 1, "illegal row counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime row counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate row counted");
      Assert (Audit.RM_Gap_Burn_Down_Ready (Results), "gap burn-down ready");
      Assert (Audit.Tasking_Protected_Parallel_Gap_Closed (Results),
              "tasking/protected/parallel gap closed");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Protected_Barrier_Side_Effect,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Tampering_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Effect_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Balanced_Tasking_Protected_Parallel_Gap_Closes;

   procedure Test_Protected_Task_And_Finalization_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Protected_Reentrant_Safe => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Protected_Access_Mode_Compatible => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Protected_Shared_State_Effect => False);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Construct => Audit.Construct_Entry_Family,
               Context => Audit.Context_Task_Entry,
               Entry_Index_In_Range => False);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Entry_Queue_Compatible => False);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Construct => Audit.Construct_Accept_Statement,
               Context => Audit.Context_Task_Body,
               Accept_Effect_Present => False);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Construct => Audit.Construct_Requeue_Statement,
               Requeue_Target_Compatible => False);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Construct => Audit.Construct_Selective_Accept,
               Context => Audit.Context_Select_Statement,
               Select_Covered => False);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Construct => Audit.Construct_Terminate_Alternative,
               Terminate_Safe => False);
      Add_Row (Input, 19, Precision.Class_Illegal,
               Construct => Audit.Construct_Abortable_Select,
               Context => Audit.Context_Abort_Finalization,
               Abortable_Select_Safe => False);
      Add_Row (Input, 20, Precision.Class_Illegal,
               Construct => Audit.Construct_Controlled_Finalization,
               Controlled_Finalization_Present => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Protected_Reentrant_Call,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Protected_Access_Mode_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Protected_Shared_State_Write_Without_Effect,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Entry_Family_Index_Range,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Entry_Queue_Discipline,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15,
                     Audit.Status_Illegal_Missing_Accept_Body_Effect_Evidence,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Requeue_Target_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17, Audit.Status_Illegal_Select_Path_Not_Covered,
                     Precision.Class_Illegal);
      Expect_Status (Results, 18, Audit.Status_Illegal_Terminate_Alternative_Unsafe,
                     Precision.Class_Illegal);
      Expect_Status (Results, 19,
                     Audit.Status_Illegal_Abortable_Select_Finalization_Unsafe,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Controlled_Finalization_Evidence_Missing,
                     Precision.Class_Illegal);
   end Test_Protected_Task_And_Finalization_Blockers;

   procedure Test_Parallel_Flow_Effect_And_Runtime_Preservation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Construct => Audit.Construct_Parallel_Loop,
               Context => Audit.Context_Parallel_Loop,
               Family => Matrix.Family_Iterators_Parallel_Reductions,
               Owner => Matrix.Slice_Iterator_Loop_Parallel,
               Parallel_Effects_Valid => False);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Construct => Audit.Construct_Reduction,
               Reduction_Profile_Compatible => False);
      Add_Row (Input, 32, Precision.Class_Illegal,
               Construct => Audit.Construct_Reduction,
               Reduction_Seed_Compatible => False);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Family => Matrix.Family_Contracts_Global_Depends_Flow,
               Owner => Matrix.Slice_Flow_Refinement,
               Global_Depends_Preserved => False);
      Add_Row (Input, 34, Precision.Class_Illegal,
               Owner => Matrix.Slice_Flow_Refinement,
               Refined_Flow_Preserved => False);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Construct => Audit.Construct_Volatile_State,
               Volatile_Order_Preserved => False);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Construct => Audit.Construct_Atomic_State,
               Atomic_Order_Preserved => False);
      Add_Row (Input, 37, Precision.Class_Illegal,
               Context => Audit.Context_Synchronized_Interface,
               Owner => Matrix.Slice_Interface_Synchronized,
               Dispatching_Effect_Join_Present => False);
      Add_Row (Input, 38, Precision.Class_Illegal,
               Context => Audit.Context_Synchronized_Interface,
               Owner => Matrix.Slice_Interface_Synchronized,
               Sync_Interface_Effects_Agree => False);
      Add_Row (Input, 39, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Parallel_Loop,
               Runtime_Bounds_Check => True);
      Add_Row (Input, 40, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Parallel_Shared_State_Write,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Illegal_Reduction_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Reduction_Seed_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Illegal_Global_Depends_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Illegal_Refined_Flow_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Illegal_Volatile_Ordering_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Atomic_Ordering_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37, Audit.Status_Illegal_Dispatching_Effect_Join_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Synchronized_Interface_Effect_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39, Audit.Status_Runtime_Bounds_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 40, Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Parallel_Flow_Effect_And_Runtime_Preservation;

   procedure Test_Indeterminate_Views_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 50, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 51, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 52, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 53, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 54, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);
      Add_Row (Input, 55, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 56, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 57, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 58, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 59, Precision.Class_Legal,
               Consumer_Flow_Agrees => False);
      Add_Row (Input, 60, Precision.Class_Illegal,
               Protected_Barrier_Pure => False,
               Stable_Blocker => False);
      Add_Row (Input, 61, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 62, Precision.Class_Legal,
               Expected_Source_FP => 42);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52, Audit.Status_Indeterminate_Incomplete_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53, Audit.Status_Indeterminate_Generic_Formal_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped evidence rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing remediation evidence rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Coverage_Not_Updated_To_Covered,
              "coverage promotion gate enforced");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed tasking result rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Consumer_Flow_Model_Disagreement,
              "consumer flow disagreement rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Unstable_Blocker_Family,
              "unstable tasking blocker family rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale burn-down fingerprint rejected");
      Assert (Audit.Result_For (Results, 62).Status =
              Audit.Status_Source_Fingerprint_Mismatch,
              "source fingerprint mismatch rejected");
   end Test_Indeterminate_Views_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Tasking_Protected_Parallel_Gap_Closes'Access,
         "balanced tasking/protected/parallel gap closure");
      Register_Routine
        (T, Test_Protected_Task_And_Finalization_Blockers'Access,
         "protected/task/finalization blockers");
      Register_Routine
        (T, Test_Parallel_Flow_Effect_And_Runtime_Preservation'Access,
         "parallel flow/effect/runtime preservation");
      Register_Routine
        (T, Test_Indeterminate_Views_And_Audit_Gates'Access,
         "indeterminate views and audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1348;
