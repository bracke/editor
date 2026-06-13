with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Performance_Boundedness_Validation_Pass1434;

package body Test_Ada_Phase579_Performance_Boundedness_Validation_Pass1434 is
   package Perf renames Editor.Ada_Phase579_Performance_Boundedness_Validation_Pass1434;
   use type Perf.Scenario_Kind;
   use type Perf.Boundedness_Status;
   use type Perf.Boundedness_Result_Class;
   use type Perf.Boundedness_Row;
   use type Perf.Boundedness_Input;
   use type Perf.Boundedness_Entry;
   use type Perf.Boundedness_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Phase579_Performance_Boundedness_Validation_Pass1434");
   end Name;

   function Base_Row
     (Id : Natural;
      Scenario : Perf.Scenario_Kind;
      Name : String) return Perf.Boundedness_Row is
      Row : Perf.Boundedness_Row;
   begin
      Row.Id := Id;
      Row.Scenario := Scenario;
      Row.Name := To_Unbounded_String (Name);
      Row.Work_Budget := 1_000;
      Row.Observed_Work := 750;
      Row.Index_Traversal_Bound := 400;
      Row.Observed_Index_Traversal := 200;
      Row.Source_Fingerprint := Id * 100 + 41;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Snapshot_Fingerprint := Id * 100 + 42;
      Row.Expected_Snapshot_Fingerprint := Row.Snapshot_Fingerprint;
      Row.Schedule_Fingerprint := Id * 100 + 43;
      Row.Expected_Schedule_Fingerprint := Row.Schedule_Fingerprint;
      Row.Consumer_Fingerprint := Id * 100 + 44;
      Row.Expected_Consumer_Fingerprint := Row.Consumer_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Perf.Boundedness_Model;
      Id : Natural;
      Status : Perf.Boundedness_Status;
      Result_Class : Perf.Boundedness_Result_Class) is
      Item : constant Perf.Boundedness_Entry := Perf.Result_For (Model, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1434 boundedness status");
      Assert (Item.Result_Class = Result_Class,
              "unexpected pass1434 boundedness result class");
      Assert (Perf.Class_For_Status (Status) = Result_Class,
              "boundedness status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Bounded_Project_Scenarios_Accepted

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Perf.Boundedness_Input;
      Model : Perf.Boundedness_Model;
      Row : Perf.Boundedness_Row;
   begin
      Perf.Add_Row (Input, Base_Row
        (1, Perf.Scenario_Large_File,
         "large file semantic analysis stays within budget"));
      Perf.Add_Row (Input, Base_Row
        (2, Perf.Scenario_Multi_Buffer_Project,
         "multi-buffer project closure stays bounded"));
      Perf.Add_Row (Input, Base_Row
        (3, Perf.Scenario_Cross_Unit_Index,
         "cross-unit index traversal stays bounded"));

      Row := Base_Row
        (4, Perf.Scenario_Cancellation,
         "cancellation is acknowledged before publishing semantic consumers");
      Row.Cancellation_Requested := True;
      Row.Cancellation_Acknowledged := True;
      Perf.Add_Row (Input, Row);

      Perf.Add_Row (Input, Base_Row
        (5, Perf.Scenario_Stale_Result_Rejection,
         "stale result is rejected by snapshot fingerprints"));
      Perf.Add_Row (Input, Base_Row
        (6, Perf.Scenario_Deterministic_Replay,
         "deterministic replay preserves semantic fingerprints"));
      Perf.Add_Row (Input, Base_Row
        (7, Perf.Scenario_Budget_Exhaustion,
         "budget exhaustion degrades deterministically"));

      Model := Perf.Build (Input);

      Assert (Perf.Performance_Boundedness_Complete (Model),
              "performance boundedness validation should complete");
      Assert (Model.Accepted_Count = 7, "all bounded scenarios accepted");
      Assert (Model.Rejected_Count = 0, "no bounded scenario rejected");
      Assert (Model.Indeterminate_Count = 0, "no bounded scenario indeterminate");

      for Id in 1 .. 7 loop
         Expect_Status (Model, Id, Perf.Status_Accepted, Perf.Class_Accepted);
      end loop;
   end Test_Bounded_Project_Scenarios_Accepted;

   procedure Test_Budget_Cancellation_And_Index_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Perf.Boundedness_Input;
      Model : Perf.Boundedness_Model;
      Row : Perf.Boundedness_Row;
   begin
      Row := Base_Row (10, Perf.Scenario_Large_File, "work budget exceeded");
      Row.Observed_Work := Row.Work_Budget + 1;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (11, Perf.Scenario_Cancellation, "cancellation ignored");
      Row.Cancellation_Requested := True;
      Row.Cancellation_Acknowledged := False;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (12, Perf.Scenario_Cross_Unit_Index, "index traversal exceeded");
      Row.Observed_Index_Traversal := Row.Index_Traversal_Bound + 1;
      Perf.Add_Row (Input, Row);

      Model := Perf.Build (Input);

      Expect_Status (Model, 10, Perf.Status_Rejected_Unbounded_Work,
                     Perf.Class_Rejected);
      Expect_Status (Model, 11, Perf.Status_Rejected_Cancellation_Ignored,
                     Perf.Class_Rejected);
      Expect_Status (Model, 12, Perf.Status_Rejected_Index_Traversal_Unbounded,
                     Perf.Class_Rejected);
      Assert (Model.Rejected_Count = 3, "boundedness violations rejected");
   end Test_Budget_Cancellation_And_Index_Rejections;

   procedure Test_Stale_Nondeterministic_Consumer_And_Gap_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Perf.Boundedness_Input;
      Model : Perf.Boundedness_Model;
      Row : Perf.Boundedness_Row;
   begin
      Row := Base_Row (20, Perf.Scenario_Stale_Result_Rejection, "stale result accepted");
      Row.Stale_Result_Rejected := False;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (21, Perf.Scenario_Deterministic_Replay, "nondeterministic replay");
      Row.Deterministic_Replay := False;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (22, Perf.Scenario_Multi_Buffer_Project, "consumer disagreement");
      Row.Consumer_Agreement := False;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (23, Perf.Scenario_Budget_Exhaustion, "reopens remaining gap");
      Row.Reopens_Remaining_Gap := True;
      Perf.Add_Row (Input, Row);

      Model := Perf.Build (Input);

      Expect_Status (Model, 20, Perf.Status_Rejected_Stale_Result_Accepted,
                     Perf.Class_Rejected);
      Expect_Status (Model, 21, Perf.Status_Rejected_Nondeterministic_Replay,
                     Perf.Class_Rejected);
      Expect_Status (Model, 22, Perf.Status_Rejected_Consumer_Disagreement,
                     Perf.Class_Rejected);
      Expect_Status (Model, 23, Perf.Status_Rejected_Reopened_Remaining_Gap,
                     Perf.Class_Rejected);
      Assert (not Perf.Performance_Boundedness_Complete (Model),
              "performance gate cannot complete when closure is reopened");
   end Test_Stale_Nondeterministic_Consumer_And_Gap_Rejections;

   procedure Test_Stale_And_Missing_Evidence_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Perf.Boundedness_Input;
      Model : Perf.Boundedness_Model;
      Row : Perf.Boundedness_Row;
   begin
      Row := Base_Row (30, Perf.Scenario_Large_File, "stale schedule evidence");
      Row.Schedule_Fingerprint := 1;
      Row.Expected_Schedule_Fingerprint := 2;
      Perf.Add_Row (Input, Row);

      Row := Base_Row (31, Perf.Scenario_Unknown, "missing scenario evidence");
      Row.Evidence_Present := False;
      Perf.Add_Row (Input, Row);

      Model := Perf.Build (Input);

      Expect_Status (Model, 30, Perf.Status_Rejected_Stale_Evidence,
                     Perf.Class_Rejected);
      Expect_Status (Model, 31, Perf.Status_Indeterminate_Missing_Evidence,
                     Perf.Class_Indeterminate);
      Assert (Model.Rejected_Count = 1, "stale performance evidence rejected");
      Assert (Model.Indeterminate_Count = 1, "missing evidence is indeterminate");
   end Test_Stale_And_Missing_Evidence_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Bounded_Project_Scenarios_Accepted'Access,
                        "pass1434 accepts bounded project-scale scenarios");
      Register_Routine (T, Test_Budget_Cancellation_And_Index_Rejections'Access,
                        "pass1434 rejects budget, cancellation, and index violations");
      Register_Routine (T, Test_Stale_Nondeterministic_Consumer_And_Gap_Rejections'Access,
                        "pass1434 rejects stale, nondeterministic, consumer, and gap violations");
      Register_Routine (T, Test_Stale_And_Missing_Evidence_Rejections'Access,
                        "pass1434 rejects stale or missing performance evidence");
   end Register_Tests;

end Test_Ada_Phase579_Performance_Boundedness_Validation_Pass1434;
