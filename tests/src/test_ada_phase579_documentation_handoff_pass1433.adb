with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Documentation_Handoff_Pass1433;

package body Test_Ada_Phase579_Documentation_Handoff_Pass1433 is
   package Handoff renames Editor.Ada_Phase579_Documentation_Handoff_Pass1433;
   use type Handoff.Handoff_Section;
   use type Handoff.Handoff_Status;
   use type Handoff.Handoff_Result_Class;
   use type Handoff.Handoff_Row;
   use type Handoff.Handoff_Input;
   use type Handoff.Handoff_Entry;
   use type Handoff.Handoff_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Phase579_Documentation_Handoff_Pass1433");
   end Name;

   function Base_Row
     (Id : Natural;
      Section : Handoff.Handoff_Section;
      Title : String;
      Text : String) return Handoff.Handoff_Row is
      Row : Handoff.Handoff_Row;
   begin
      Row.Id := Id;
      Row.Section := Section;
      Row.Title := To_Unbounded_String (Title);
      Row.Text := To_Unbounded_String (Text);
      Row.Source_Fingerprint := Id * 100 + 31;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Documentation_Fingerprint := Id * 100 + 32;
      Row.Expected_Documentation_Fingerprint := Row.Documentation_Fingerprint;
      Row.Handoff_Fingerprint := Id * 100 + 33;
      Row.Expected_Handoff_Fingerprint := Row.Handoff_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Handoff.Handoff_Model;
      Id : Natural;
      Status : Handoff.Handoff_Status;
      Result_Class : Handoff.Handoff_Result_Class) is
      Item : constant Handoff.Handoff_Entry := Handoff.Result_For (Model, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1433 handoff status");
      Assert (Item.Result_Class = Result_Class,
              "unexpected pass1433 handoff result class");
      Assert (Handoff.Class_For_Status (Status) = Result_Class,
              "handoff status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Final_Handoff_Documentation_Accepted

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Handoff.Handoff_Input;
      Model : Handoff.Handoff_Model;
   begin
      Handoff.Add_Row (Input, Base_Row
        (1, Handoff.Section_Final_Status,
         "Phase 579 final status",
         "Remaining gap closure is frozen at pass1428; project-scale gates continue as validation."));
      Handoff.Add_Row (Input, Base_Row
        (2, Handoff.Section_Guarantees,
         "Guaranteed semantic invariants",
         "Snapshot-owned bounded analysis, stable consumers, and stale evidence rejection are documented."));
      Handoff.Add_Row (Input, Base_Row
        (3, Handoff.Section_Intentional_Approximation,
         "Intentional approximation boundary",
         "Real corpus failures may create evidence-driven fixes, but not speculative Remaining_* edges."));
      Handoff.Add_Row (Input, Base_Row
        (4, Handoff.Section_Future_Work_Rule,
         "Future work rule",
         "No new Remaining_* edge is allowed without a source-shaped failing case or RM contradiction."));
      Handoff.Add_Row (Input, Base_Row
        (5, Handoff.Section_Operational_Handoff,
         "Operational handoff",
         "Next phase consumes release validation evidence, not broad audit churn."));

      Model := Handoff.Build (Input);

      Assert (Handoff.Documentation_Handoff_Complete (Model),
              "documentation handoff should be complete");
      Assert (Model.Accepted_Count = 5, "all handoff sections accepted");
      Assert (Model.Rejected_Count = 0, "no handoff rejection expected");
      Assert (Model.Indeterminate_Count = 0, "no indeterminate handoff evidence expected");

      for Id in 1 .. 5 loop
         Expect_Status (Model, Id, Handoff.Status_Accepted, Handoff.Class_Accepted);
      end loop;
   end Test_Final_Handoff_Documentation_Accepted;

   procedure Test_Missing_Section_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Handoff.Handoff_Input;
      Model : Handoff.Handoff_Model;
      Row : Handoff.Handoff_Row;
   begin
      Row := Base_Row
        (10, Handoff.Section_Final_Status,
         "missing final status", "status omitted");
      Row.Final_Status_Documented := False;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (11, Handoff.Section_Guarantees,
         "missing guarantee", "guarantee omitted");
      Row.Guarantees_Documented := False;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (12, Handoff.Section_Intentional_Approximation,
         "missing approximation", "approximation omitted");
      Row.Approximations_Documented := False;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (13, Handoff.Section_Future_Work_Rule,
         "missing future work rule", "future-work rule omitted");
      Row.Future_Work_Rule_Documented := False;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (14, Handoff.Section_Operational_Handoff,
         "missing acceptance standard", "acceptance standard omitted");
      Row.Acceptance_Standard_Documented := False;
      Handoff.Add_Row (Input, Row);

      Model := Handoff.Build (Input);

      Expect_Status (Model, 10, Handoff.Status_Rejected_Missing_Status,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 11, Handoff.Status_Rejected_Missing_Guarantee,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 12, Handoff.Status_Rejected_Missing_Approximation,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 13, Handoff.Status_Rejected_Missing_Future_Work_Rule,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 14, Handoff.Status_Rejected_Missing_Acceptance_Standard,
                     Handoff.Class_Rejected);
      Assert (Model.Rejected_Count = 5, "all incomplete handoff sections rejected");
   end Test_Missing_Section_Rejections;

   procedure Test_Reopened_Gap_And_Speculative_Edge_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Handoff.Handoff_Input;
      Model : Handoff.Handoff_Model;
      Row : Handoff.Handoff_Row;
   begin
      Row := Base_Row
        (20, Handoff.Section_Future_Work_Rule,
         "reopened Remaining gap", "a handoff attempts to reopen the frozen gap inventory");
      Row.Reopens_Remaining_Gap := True;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (21, Handoff.Section_Future_Work_Rule,
         "speculative semantic edge", "a handoff allows speculative Remaining_* churn");
      Row.Speculative_Edge_Allowed := True;
      Handoff.Add_Row (Input, Row);

      Model := Handoff.Build (Input);

      Expect_Status (Model, 20, Handoff.Status_Rejected_Reopened_Remaining_Gap,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 21, Handoff.Status_Rejected_Speculative_Edge,
                     Handoff.Class_Rejected);
      Assert (not Handoff.Documentation_Handoff_Complete (Model),
              "handoff cannot complete when finite closure is reopened");
   end Test_Reopened_Gap_And_Speculative_Edge_Rejections;

   procedure Test_Stale_And_Missing_Evidence_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Handoff.Handoff_Input;
      Model : Handoff.Handoff_Model;
      Row : Handoff.Handoff_Row;
   begin
      Row := Base_Row
        (30, Handoff.Section_Final_Status,
         "stale handoff evidence", "documentation fingerprint has drifted");
      Row.Documentation_Fingerprint := 1;
      Row.Expected_Documentation_Fingerprint := 2;
      Handoff.Add_Row (Input, Row);

      Row := Base_Row
        (31, Handoff.Section_Unknown,
         "missing evidence", "section is unknown and must remain indeterminate");
      Row.Evidence_Present := False;
      Handoff.Add_Row (Input, Row);

      Model := Handoff.Build (Input);

      Expect_Status (Model, 30, Handoff.Status_Rejected_Stale_Documentation_Evidence,
                     Handoff.Class_Rejected);
      Expect_Status (Model, 31, Handoff.Status_Indeterminate_Missing_Evidence,
                     Handoff.Class_Indeterminate);
      Assert (Model.Rejected_Count = 1, "stale handoff evidence rejected");
      Assert (Model.Indeterminate_Count = 1, "missing handoff evidence is indeterminate");
   end Test_Stale_And_Missing_Evidence_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Final_Handoff_Documentation_Accepted'Access,
                        "pass1433 final documentation handoff accepted");
      Register_Routine (T, Test_Missing_Section_Rejections'Access,
                        "pass1433 rejects incomplete handoff sections");
      Register_Routine (T, Test_Reopened_Gap_And_Speculative_Edge_Rejections'Access,
                        "pass1433 rejects reopened finite-gap closure");
      Register_Routine (T, Test_Stale_And_Missing_Evidence_Rejections'Access,
                        "pass1433 rejects stale or missing handoff evidence");
   end Register_Tests;

end Test_Ada_Phase579_Documentation_Handoff_Pass1433;
