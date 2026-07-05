with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Case_1362;

package body Test_Ada_RM_Gap_Burn_Down_Case_1362 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Case_1362;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Work_Unit_Kind;
   use type Audit.Schedule_Phase;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Work : Audit.Work_Unit_Kind;
      Phase : Audit.Schedule_Phase;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Bounded_Semantic_Work_Cancellation_Scheduling;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Work := Work;
      Row.Phase := Phase;
      Row.Name := To_Unbounded_String
        ("case 1362 source-shaped bounded scheduling row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Case_1362");
      Row.Per_Buffer_Budget := 100;
      Row.Request_Budget := 80;
      Row.Slice_Budget := 40;
      Row.Candidate_Limit := 16;
      Row.Replay_Depth_Limit := 8;
      Row.Cross_Unit_Depth_Limit := 8;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected case 1362 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected case 1362 classification");
   end Expect_Status;

   procedure Test_Balanced_Bounded_Scheduling_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Work_Name_Visibility,
                       Audit.Phase_Completed,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Work_Completed := True;
      Row.Steps_Consumed := 20;
      Row.Slice_Steps_Consumed := 10;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Legal,
                       Audit.Work_Overload_Call,
                       Audit.Phase_Cancelled,
                       Consumers.Consumer_Diagnostics);
      Row.Work_Cancelled := True;
      Row.Request_Token := 10;
      Row.Expected_Request_Token := 10;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Indeterminate,
                       Audit.Work_Generic_Body_Replay,
                       Audit.Phase_Budget_Exhausted,
                       Consumers.Consumer_Hover_Details);
      Row.Budget_Exhausted := True;
      Row.Partial_Result_Available := True;
      Row.Partial_Result_Preserved := True;
      Row.Partial_Evidence_Preserved_On_Budget_Exhaustion := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Queued,
                       Consumers.Consumer_Outline_Model);
      Row.Deterministic_Work_Order := True;
      Row.Deterministic_Blocker_Order := True;
      Row.Deterministic_Diagnostic_Order := True;
      Row.Deterministic_Outline_Order := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Work_Type_Profile,
                       Audit.Phase_Completed,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Runtime_Check_Context := True;
      Row.Runtime_Check_Evidence_Preserved := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Bounded_Work_Scheduling_Gap_Closed (Results),
              "bounded scheduling gap closes with complete, cancelled, budgeted, deterministic rows");
      Assert (Results.Completed_Count = 1, "completed work counted");
      Assert (Results.Cancelled_Count = 1, "cancelled work counted");
      Assert (Results.Budget_Exceeded_Count = 1, "budget exhaustion counted");
      Assert (Results.Deterministic_Count = 1, "deterministic ordering counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check evidence counted");

      Expect_Status (Results, 1,
                     Audit.Status_Legal_Work_Completed_Within_Budget,
                     Precision.Class_Legal);
      Expect_Status (Results, 2,
                     Audit.Status_Legal_Work_Cancelled_By_Newer_Request,
                     Precision.Class_Legal);
      Expect_Status (Results, 3, Audit.Status_Indeterminate_Budget_Exceeded,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 4,
                     Audit.Status_Legal_Deterministic_Order_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 5,
                     Audit.Status_Legal_Runtime_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Balanced_Bounded_Scheduling_Closes;

   procedure Test_Work_Budgets_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal,
                       Audit.Work_Name_Visibility,
                       Audit.Phase_Running);
      Row.Steps_Consumed := 90;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11, Precision.Class_Illegal,
                       Audit.Work_Overload_Call,
                       Audit.Phase_Running);
      Row.Candidate_Count := 32;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Work_Generic_Body_Replay,
                       Audit.Phase_Running);
      Row.Replay_Depth := 12;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Work_Cross_Unit_Closure,
                       Audit.Phase_Running);
      Row.Cross_Unit_Depth := 12;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10,
                     Audit.Status_Illegal_Work_Budget_Exceeded_As_Legal,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Unbounded_Overload_Exploration,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Unbounded_Generic_Replay,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Unbounded_Cross_Unit_Closure,
                     Precision.Class_Illegal);
   end Test_Work_Budgets_Are_Enforced;

   procedure Test_Cancellation_And_Supersession_Are_Consumer_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Work_Overload_Call,
                       Audit.Phase_Cancelled);
      Row.Work_Cancelled := True;
      Row.Diagnostic_Emitted := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Work_Type_Profile,
                       Audit.Phase_Cancelled);
      Row.Work_Cancelled := True;
      Row.Cancelled_Result_Consumed := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Work_Generic_Body_Replay,
                       Audit.Phase_Superseded);
      Row.Work_Superseded := True;
      Row.Superseded_Result_Consumed := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Work_AST_Recovery,
                       Audit.Phase_Running);
      Row.Stale_Partial_Result_Reused := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running,
                       Consumers.Consumer_Hover_Details);
      Row.Consumer_Bypassed_Cancellation_State := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Bypassed_Budget_State := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Diagnostic_Emitted_After_Cancellation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Cancelled_Result_Consumed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Superseded_Result_Consumed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23,
                     Audit.Status_Illegal_Stale_Partial_Result_Reused,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Consumer_Bypassed_Cancellation_State,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Consumer_Bypassed_Budget_State,
                     Precision.Class_Illegal);
   end Test_Cancellation_And_Supersession_Are_Consumer_Gates;

   procedure Test_Deterministic_Ordering_Is_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Work_Name_Visibility,
                       Audit.Phase_Queued);
      Row.Deterministic_Work_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Queued);
      Row.Deterministic_Blocker_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Queued);
      Row.Deterministic_Diagnostic_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Queued,
                       Consumers.Consumer_Outline_Model);
      Row.Deterministic_Outline_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Work_Overload_Call,
                       Audit.Phase_Queued);
      Row.Hash_Or_Timing_Dependent_Order := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30,
                     Audit.Status_Illegal_Nondeterministic_Work_Order,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Nondeterministic_Blocker_Order,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Illegal_Nondeterministic_Diagnostic_Order,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33,
                     Audit.Status_Illegal_Nondeterministic_Outline_Order,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34,
                     Audit.Status_Illegal_Hash_Or_Timing_Dependent_Order,
                     Precision.Class_Illegal);
   end Test_Deterministic_Ordering_Is_Required;

   procedure Test_Budget_Exhaustion_Degrades_To_Indeterminate

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Indeterminate,
                       Audit.Work_Cross_Unit_Closure,
                       Audit.Phase_Budget_Exhausted);
      Row.Budget_Exhausted := True;
      Row.Budget_Exhaustion_Classified_Indeterminate := True;
      Row.Partial_Evidence_Preserved_On_Budget_Exhaustion := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (41, Precision.Class_Illegal,
                       Audit.Work_Cross_Unit_Closure,
                       Audit.Phase_Budget_Exhausted);
      Row.Budget_Exhausted := True;
      Row.Budget_Exhaustion_Treated_As_Legal := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (42, Precision.Class_Illegal,
                       Audit.Work_Cross_Unit_Closure,
                       Audit.Phase_Budget_Exhausted);
      Row.Budget_Exhausted := True;
      Row.Budget_Exhaustion_Treated_As_Illegal := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (43, Precision.Class_Illegal,
                       Audit.Work_AST_Recovery,
                       Audit.Phase_Budget_Exhausted);
      Row.Budget_Exhausted := True;
      Row.Partial_Evidence_Preserved_On_Budget_Exhaustion := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40, Audit.Status_Indeterminate_Budget_Exceeded,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Work_Budget_Exceeded_As_Legal,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Work_Budget_Exceeded_As_Illegal,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_Stale_Partial_Result_Reused,
                     Precision.Class_Illegal);
   end Test_Budget_Exhaustion_Degrades_To_Indeterminate;

   procedure Test_Invariants_And_Fingerprints_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (50, Precision.Class_Illegal,
                       Audit.Work_AST_Recovery,
                       Audit.Phase_Running);
      Row.Rendering_Side_Parsing := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (51, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running);
      Row.Dirty_State_Mutation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (52, Precision.Class_Illegal,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running);
      Row.File_Save_Reload_During_Analysis := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (53, Precision.Class_Indeterminate,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running);
      Row.Source_Revision := 2;
      Row.Expected_Source_Revision := 3;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (54, Precision.Class_Indeterminate,
                       Audit.Work_Consumer_Surface,
                       Audit.Phase_Running);
      Row.Schedule_Fingerprint := 9;
      Row.Expected_Schedule_Fingerprint := 10;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Illegal_Rendering_Side_Parsing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 51, Audit.Status_Illegal_Dirty_State_Mutation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 52,
                     Audit.Status_Illegal_File_Save_Reload_During_Analysis,
                     Precision.Class_Illegal);
      Expect_Status (Results, 53, Audit.Status_Source_Revision_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54, Audit.Status_Schedule_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Invariants_And_Fingerprints_Are_Enforced;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Bounded_Scheduling_Closes'Access,
         "balanced bounded scheduling closes");
      Register_Routine
        (T, Test_Work_Budgets_Are_Enforced'Access,
         "work budgets are enforced");
      Register_Routine
        (T, Test_Cancellation_And_Supersession_Are_Consumer_Gates'Access,
         "cancellation and supersession are consumer gates");
      Register_Routine
        (T, Test_Deterministic_Ordering_Is_Required'Access,
         "deterministic ordering is required");
      Register_Routine
        (T, Test_Budget_Exhaustion_Degrades_To_Indeterminate'Access,
         "budget exhaustion degrades to indeterminate");
      Register_Routine
        (T, Test_Invariants_And_Fingerprints_Are_Enforced'Access,
         "invariants and fingerprints are enforced");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1362;
