with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Quality_Validation;

package body Test_Ada_Diagnostic_Quality_Validation is
   package Diag renames Editor.Ada_Diagnostic_Quality_Validation;
   use type Diag.Diagnostic_Scenario_Kind;
   use type Diag.Diagnostic_Severity;
   use type Diag.Diagnostic_Status;
   use type Diag.Diagnostic_Result_Class;
   use type Diag.Diagnostic_Row;
   use type Diag.Diagnostic_Input;
   use type Diag.Diagnostic_Entry;
   use type Diag.Diagnostic_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Quality_Validation");
   end Name;

   function Base_Row
     (Id : Natural;
      Scenario : Diag.Diagnostic_Scenario_Kind;
      Name : String;
      Severity : Diag.Diagnostic_Severity) return Diag.Diagnostic_Row is
      Row : Diag.Diagnostic_Row;
   begin
      Row.Id := Id;
      Row.Scenario := Scenario;
      Row.Name := To_Unbounded_String (Name);
      Row.Actual_Severity := Severity;
      Row.Expected_Severity := Severity;
      Row.Duplicate_Count := 1;
      Row.Duplicate_Limit := 2;
      Row.Source_Fingerprint := Id * 100 + 51;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Diagnostic_Fingerprint := Id * 100 + 52;
      Row.Expected_Diagnostic_Fingerprint := Row.Diagnostic_Fingerprint;
      Row.Consumer_Fingerprint := Id * 100 + 53;
      Row.Expected_Consumer_Fingerprint := Row.Consumer_Fingerprint;
      Row.Projection_Fingerprint := Id * 100 + 54;
      Row.Expected_Projection_Fingerprint := Row.Projection_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Diag.Diagnostic_Model;
      Id : Natural;
      Status : Diag.Diagnostic_Status;
      Result_Class : Diag.Diagnostic_Result_Class) is
      Item : constant Diag.Diagnostic_Entry := Diag.Result_For (Model, Id);
   begin
      Assert (Item.Status = Status, "unexpected diagnostic validation status");
      Assert (Item.Result_Class = Result_Class,
              "unexpected diagnostic validation result class");
      Assert (Diag.Class_For_Status (Status) = Result_Class,
              "diagnostic status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Diagnostic_Quality_Scenarios_Accepted

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Diag.Diagnostic_Input;
      Model : Diag.Diagnostic_Model;
   begin
      Diag.Add_Row (Input, Base_Row
        (1, Diag.Scenario_Error_Diagnostic,
         "illegal Ada source has precise error diagnostic", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (2, Diag.Scenario_Warning_Diagnostic,
         "warning-only Ada source keeps warning severity", Diag.Severity_Warning));
      Diag.Add_Row (Input, Base_Row
        (3, Diag.Scenario_Runtime_Check_Diagnostic,
         "runtime-check preservation is not escalated to error", Diag.Severity_Info));
      Diag.Add_Row (Input, Base_Row
        (4, Diag.Scenario_Indeterminate_Diagnostic,
         "missing semantic evidence is surfaced as diagnostic", Diag.Severity_Warning));
      Diag.Add_Row (Input, Base_Row
        (5, Diag.Scenario_Duplicate_Flood,
         "duplicate diagnostic policy remains within bounded limit", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (6, Diag.Scenario_Source_Span,
         "diagnostic source span is stable and precise", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (7, Diag.Scenario_Severity,
         "diagnostic severity projection matches expected severity", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (8, Diag.Scenario_Consumer_Agreement,
         "diagnostic consumers agree on family and severity", Diag.Severity_Error));

      Model := Diag.Build (Input);

      Assert (Diag.Diagnostic_Quality_Complete (Model),
              "diagnostic quality validation should complete");
      Assert (Model.Accepted_Count = 8, "all quality scenarios accepted");
      Assert (Model.Rejected_Count = 0, "no quality scenario rejected");
      Assert (Model.Indeterminate_Count = 0, "no quality scenario indeterminate");
      Assert (Model.Required_Scenario_Count = 8,
              "all required diagnostic quality scenarios are known");
      Assert (Model.Missing_Scenario_Count = 0,
              "no diagnostic quality scenario is missing");
      Assert (Model.Duplicate_Scenario_Count = 0,
              "no diagnostic quality scenario is duplicated");

      for Id in 1 .. 8 loop
         Expect_Status (Model, Id, Diag.Status_Accepted, Diag.Class_Accepted);
      end loop;
   end Test_Diagnostic_Quality_Scenarios_Accepted;

   procedure Test_Source_Span_Blocker_Severity_And_Duplicate_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Diag.Diagnostic_Input;
      Model : Diag.Diagnostic_Model;
      Row : Diag.Diagnostic_Row;
   begin
      Row := Base_Row (10, Diag.Scenario_Source_Span,
                       "missing source span", Diag.Severity_Error);
      Row.Has_Source_Span := False;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (11, Diag.Scenario_Error_Diagnostic,
                       "unstable blocker family", Diag.Severity_Error);
      Row.Stable_Blocker_Family := False;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (12, Diag.Scenario_Severity,
                       "wrong severity", Diag.Severity_Warning);
      Row.Expected_Severity := Diag.Severity_Error;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (13, Diag.Scenario_Duplicate_Flood,
                       "duplicate flood", Diag.Severity_Error);
      Row.Duplicate_Count := Row.Duplicate_Limit + 1;
      Diag.Add_Row (Input, Row);

      Model := Diag.Build (Input);

      Expect_Status (Model, 10, Diag.Status_Rejected_Missing_Source_Span,
                     Diag.Class_Rejected);
      Expect_Status (Model, 11, Diag.Status_Rejected_Unstable_Blocker_Family,
                     Diag.Class_Rejected);
      Expect_Status (Model, 12, Diag.Status_Rejected_Wrong_Severity,
                     Diag.Class_Rejected);
      Expect_Status (Model, 13, Diag.Status_Rejected_Duplicate_Flood,
                     Diag.Class_Rejected);
      Assert (Model.Rejected_Count = 4, "diagnostic quality defects rejected");
   end Test_Source_Span_Blocker_Severity_And_Duplicate_Rejections;

   procedure Test_Final_State_Consumer_And_Gap_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Diag.Diagnostic_Input;
      Model : Diag.Diagnostic_Model;
      Row : Diag.Diagnostic_Row;
   begin
      Row := Base_Row (20, Diag.Scenario_Error_Diagnostic,
                       "misleading final readiness state", Diag.Severity_Error);
      Row.Final_State_Matches_Result := False;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (21, Diag.Scenario_Consumer_Agreement,
                       "consumer disagreement", Diag.Severity_Error);
      Row.Consumer_Agreement := False;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (22, Diag.Scenario_Indeterminate_Diagnostic,
                       "reopens remaining gap", Diag.Severity_Warning);
      Row.Reopens_Remaining_Gap := True;
      Diag.Add_Row (Input, Row);

      Model := Diag.Build (Input);

      Expect_Status (Model, 20, Diag.Status_Rejected_Misleading_Final_State,
                     Diag.Class_Rejected);
      Expect_Status (Model, 21, Diag.Status_Rejected_Consumer_Disagreement,
                     Diag.Class_Rejected);
      Expect_Status (Model, 22, Diag.Status_Rejected_Reopened_Remaining_Gap,
                     Diag.Class_Rejected);
      Assert (not Diag.Diagnostic_Quality_Complete (Model),
              "diagnostic quality cannot complete when finite closure is reopened");
   end Test_Final_State_Consumer_And_Gap_Rejections;

   procedure Test_Stale_And_Missing_Evidence_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Diag.Diagnostic_Input;
      Model : Diag.Diagnostic_Model;
      Row : Diag.Diagnostic_Row;
   begin
      Row := Base_Row (30, Diag.Scenario_Source_Span,
                       "stale diagnostic fingerprint", Diag.Severity_Error);
      Row.Diagnostic_Fingerprint := 1;
      Row.Expected_Diagnostic_Fingerprint := 2;
      Diag.Add_Row (Input, Row);

      Row := Base_Row (31, Diag.Scenario_Unknown,
                       "missing diagnostic evidence", Diag.Severity_Error);
      Row.Evidence_Present := False;
      Diag.Add_Row (Input, Row);

      Model := Diag.Build (Input);

      Expect_Status (Model, 30, Diag.Status_Rejected_Stale_Evidence,
                     Diag.Class_Rejected);
      Expect_Status (Model, 31, Diag.Status_Indeterminate_Missing_Evidence,
                     Diag.Class_Indeterminate);
      Assert (Model.Rejected_Count = 1, "stale diagnostic evidence rejected");
      Assert (Model.Indeterminate_Count = 1, "missing evidence is indeterminate");
   end Test_Stale_And_Missing_Evidence_Rejections;

   procedure Test_Duplicate_And_Missing_Scenarios_Block_Completion

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Diag.Diagnostic_Input;
      Model : Diag.Diagnostic_Model;
   begin
      Diag.Add_Row (Input, Base_Row
        (40, Diag.Scenario_Error_Diagnostic,
         "illegal Ada source has precise error diagnostic", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (41, Diag.Scenario_Error_Diagnostic,
         "duplicate error diagnostic row must not substitute for severity", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (42, Diag.Scenario_Warning_Diagnostic,
         "warning-only Ada source keeps warning severity", Diag.Severity_Warning));
      Diag.Add_Row (Input, Base_Row
        (43, Diag.Scenario_Runtime_Check_Diagnostic,
         "runtime-check preservation is not escalated to error", Diag.Severity_Info));
      Diag.Add_Row (Input, Base_Row
        (44, Diag.Scenario_Indeterminate_Diagnostic,
         "missing semantic evidence is surfaced as diagnostic", Diag.Severity_Warning));
      Diag.Add_Row (Input, Base_Row
        (45, Diag.Scenario_Duplicate_Flood,
         "duplicate diagnostic policy remains within bounded limit", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (46, Diag.Scenario_Source_Span,
         "diagnostic source span is stable and precise", Diag.Severity_Error));
      Diag.Add_Row (Input, Base_Row
        (47, Diag.Scenario_Consumer_Agreement,
         "diagnostic consumers agree on family and severity", Diag.Severity_Error));

      Model := Diag.Build (Input);

      Assert (not Diag.Diagnostic_Quality_Complete (Model),
              "diagnostic quality completion must require each scenario once");
      Assert (Model.Total_Rows = 8,
              "regression keeps the previous accepted-row-count shape");
      Assert (Model.Required_Scenario_Count = 8,
              "all required diagnostic scenarios are known to the model");
      Assert (Model.Duplicate_Scenario_Count = 1,
              "duplicate diagnostic scenarios are counted");
      Assert (Model.Missing_Scenario_Count = 1,
              "omitted diagnostic scenarios are counted");
      Expect_Status (Model, 41, Diag.Status_Rejected_Duplicate_Scenario,
                     Diag.Class_Rejected);
   end Test_Duplicate_And_Missing_Scenarios_Block_Completion;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Diagnostic_Quality_Scenarios_Accepted'Access,
                        "accepts precise diagnostic quality scenarios");
      Register_Routine (T, Test_Source_Span_Blocker_Severity_And_Duplicate_Rejections'Access,
                        "rejects source span, family, severity, and duplicate defects");
      Register_Routine (T, Test_Final_State_Consumer_And_Gap_Rejections'Access,
                        "rejects misleading final state, consumer, and gap defects");
      Register_Routine (T, Test_Stale_And_Missing_Evidence_Rejections'Access,
                        "rejects stale or missing diagnostic evidence");
      Register_Routine (T, Test_Duplicate_And_Missing_Scenarios_Block_Completion'Access,
                        "rejects duplicate or missing diagnostic quality scenarios");
   end Register_Tests;

end Test_Ada_Diagnostic_Quality_Validation;
