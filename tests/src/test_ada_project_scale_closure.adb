with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Project_Scale_Closure;

package body Test_Ada_Project_Scale_Closure is
   package Close renames Editor.Ada_Project_Scale_Closure;
   use type Close.Closure_Area;
   use type Close.Closure_Status;
   use type Close.Closure_Result_Class;
   use type Close.Closure_Row;
   use type Close.Closure_Input;
   use type Close.Closure_Entry;
   use type Close.Closure_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Project_Scale_Closure");
   end Name;

   function Base_Row
     (Id : Natural;
      Area : Close.Closure_Area;
      Name : String) return Close.Closure_Row is
      Row : Close.Closure_Row;
   begin
      Row.Id := Id;
      Row.Area := Area;
      Row.Name := To_Unbounded_String (Name);
      Row.Source_Fingerprint := Id * 100 + 61;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 100 + 62;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Documentation_Fingerprint := Id * 100 + 63;
      Row.Expected_Documentation_Fingerprint := Row.Documentation_Fingerprint;
      Row.Closure_Fingerprint := Id * 100 + 64;
      Row.Expected_Closure_Fingerprint := Row.Closure_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Close.Closure_Model;
      Id : Natural;
      Status : Close.Closure_Status;
      Result_Class : Close.Closure_Result_Class) is
      Item : constant Close.Closure_Entry := Close.Result_For (Model, Id);
   begin
      Assert (Item.Status = Status, "unexpected closure status");
      Assert (Item.Result_Class = Result_Class,
              "unexpected closure result class");
      Assert (Close.Class_For_Status (Status) = Result_Class,
              "closure status-to-class mapping drifted");
   end Expect_Status;

   procedure Add_Project_Scale_Closure_Rows (Input : in out Close.Closure_Input) is
   begin
      Close.Add_Row (Input, Base_Row
        (1, Close.Area_Release_Readiness,
         "release readiness validation closed"));
      Close.Add_Row (Input, Base_Row
        (2, Close.Area_End_To_End_Integration,
         "end-to-end editor integration validation closed"));
      Close.Add_Row (Input, Base_Row
        (3, Close.Area_Real_Ada_Corpus,
         "real Ada corpus validation closed"));
      Close.Add_Row (Input, Base_Row
        (4, Close.Area_Performance_Boundedness,
         "performance and boundedness validation closed"));
      Close.Add_Row (Input, Base_Row
        (5, Close.Area_Diagnostic_Quality,
         "diagnostic quality validation closed"));
      Close.Add_Row (Input, Base_Row
        (6, Close.Area_Architecture_Cleanup,
         "architecture cleanup closed"));
      Close.Add_Row (Input, Base_Row
        (7, Close.Area_Documentation_Handoff,
         "documentation handoff validation closed"));
   end Add_Project_Scale_Closure_Rows;

   procedure Test_Project_Scale_Closure_Accepts_Frozen_Seven_Items

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Close.Closure_Input;
      Model : Close.Closure_Model;
   begin
      Add_Project_Scale_Closure_Rows (Input);
      Model := Close.Build (Input);

      Assert (Close.Project_Scale_Closed (Model),
              "project-scale closure should be complete");
      Assert (Model.Total_Rows = 7, "exact seven project-scale items are frozen");
      Assert (Model.Accepted_Count = 7, "all project-scale items accepted");
      Assert (Model.Rejected_Count = 0, "no project-scale item rejected");
      Assert (Model.Indeterminate_Count = 0, "no project-scale item indeterminate");

      for Id in 1 .. 7 loop
         Expect_Status (Model, Id, Close.Status_Accepted, Close.Class_Accepted);
      end loop;
   end Test_Project_Scale_Closure_Accepts_Frozen_Seven_Items;

   procedure Test_Project_Item_Test_Documentation_And_Consumer_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Close.Closure_Input;
      Model : Close.Closure_Model;
      Row : Close.Closure_Row;
   begin
      Row := Base_Row (10, Close.Area_Release_Readiness,
                       "missing release-readiness project item");
      Row.Project_Item_Complete := False;
      Close.Add_Row (Input, Row);

      Row := Base_Row (11, Close.Area_End_To_End_Integration,
                       "unregistered end-to-end validation test");
      Row.Test_Registered := False;
      Close.Add_Row (Input, Row);

      Row := Base_Row (12, Close.Area_Documentation_Handoff,
                       "missing handoff documentation");
      Row.Documentation_Present := False;
      Close.Add_Row (Input, Row);

      Row := Base_Row (13, Close.Area_Diagnostic_Quality,
                       "diagnostic closure consumer disagreement");
      Row.Consumer_Agreement := False;
      Close.Add_Row (Input, Row);

      Model := Close.Build (Input);

      Expect_Status (Model, 10, Close.Status_Rejected_Missing_Project_Item,
                     Close.Class_Rejected);
      Expect_Status (Model, 11, Close.Status_Rejected_Unregistered_Test,
                     Close.Class_Rejected);
      Expect_Status (Model, 12, Close.Status_Rejected_Missing_Documentation,
                     Close.Class_Rejected);
      Expect_Status (Model, 13, Close.Status_Rejected_Consumer_Disagreement,
                     Close.Class_Rejected);
      Assert (Model.Rejected_Count = 4, "project closure defects rejected");
   end Test_Project_Item_Test_Documentation_And_Consumer_Rejections;

   procedure Test_Reopened_Gap_And_Speculative_Work_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Close.Closure_Input;
      Model : Close.Closure_Model;
      Row : Close.Closure_Row;
   begin
      Row := Base_Row (20, Close.Area_Architecture_Cleanup,
                       "reopens Remaining_* gap after case 1428");
      Row.Reopens_Remaining_Gap := True;
      Close.Add_Row (Input, Row);

      Row := Base_Row (21, Close.Area_Real_Ada_Corpus,
                       "speculative new semantic work without failing evidence");
      Row.Proposes_Speculative_Work := True;
      Row.Has_Real_Failing_Evidence := False;
      Close.Add_Row (Input, Row);

      Row := Base_Row (22, Close.Area_Real_Ada_Corpus,
                       "evidence-backed future corpus failure is allowed");
      Row.Proposes_Speculative_Work := True;
      Row.Has_Real_Failing_Evidence := True;
      Close.Add_Row (Input, Row);

      Model := Close.Build (Input);

      Expect_Status (Model, 20, Close.Status_Rejected_Reopened_Remaining_Gap,
                     Close.Class_Rejected);
      Expect_Status (Model, 21, Close.Status_Rejected_Speculative_New_Work,
                     Close.Class_Rejected);
      Expect_Status (Model, 22, Close.Status_Accepted,
                     Close.Class_Accepted);
      Assert (not Close.Project_Scale_Closed (Model),
              "closure cannot complete when new speculative work is present");
   end Test_Reopened_Gap_And_Speculative_Work_Rejections;

   procedure Test_Stale_And_Missing_Closure_Evidence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Close.Closure_Input;
      Model : Close.Closure_Model;
      Row : Close.Closure_Row;
   begin
      Row := Base_Row (30, Close.Area_Performance_Boundedness,
                       "stale closure fingerprint");
      Row.Closure_Fingerprint := 1;
      Row.Expected_Closure_Fingerprint := 2;
      Close.Add_Row (Input, Row);

      Row := Base_Row (31, Close.Area_Unknown,
                       "missing closure evidence");
      Row.Evidence_Present := False;
      Close.Add_Row (Input, Row);

      Model := Close.Build (Input);

      Expect_Status (Model, 30, Close.Status_Rejected_Stale_Evidence,
                     Close.Class_Rejected);
      Expect_Status (Model, 31, Close.Status_Indeterminate_Missing_Evidence,
                     Close.Class_Indeterminate);
      Assert (Model.Rejected_Count = 1, "stale closure evidence rejected");
      Assert (Model.Indeterminate_Count = 1, "missing closure evidence indeterminate");
   end Test_Stale_And_Missing_Closure_Evidence;

   procedure Test_Duplicate_And_Missing_Project_Scale_Areas_Block_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Close.Closure_Input;
      Model : Close.Closure_Model;
   begin
      Close.Add_Row (Input, Base_Row
        (40, Close.Area_Release_Readiness,
         "release readiness validation closed"));
      Close.Add_Row (Input, Base_Row
        (41, Close.Area_Release_Readiness,
         "duplicate release readiness row must not substitute for corpus"));
      Close.Add_Row (Input, Base_Row
        (42, Close.Area_End_To_End_Integration,
         "end-to-end editor integration validation closed"));
      Close.Add_Row (Input, Base_Row
        (43, Close.Area_Performance_Boundedness,
         "performance and boundedness validation closed"));
      Close.Add_Row (Input, Base_Row
        (44, Close.Area_Diagnostic_Quality,
         "diagnostic quality validation closed"));
      Close.Add_Row (Input, Base_Row
        (45, Close.Area_Architecture_Cleanup,
         "architecture cleanup closed"));
      Close.Add_Row (Input, Base_Row
        (46, Close.Area_Documentation_Handoff,
         "documentation handoff validation closed"));

      Model := Close.Build (Input);

      Assert (not Close.Project_Scale_Closed (Model),
              "closure must require each project-scale area exactly once");
      Assert (Model.Total_Rows = 7,
              "regression keeps the old exact-row-count shape");
      Assert (Model.Required_Area_Count = 7,
              "all required closure areas are known to the model");
      Assert (Model.Duplicate_Area_Count = 1,
              "duplicate required closure areas are counted");
      Assert (Model.Missing_Area_Count = 1,
              "omitted required closure areas are counted");
      Expect_Status (Model, 41, Close.Status_Rejected_Duplicate_Project_Area,
                     Close.Class_Rejected);
   end Test_Duplicate_And_Missing_Project_Scale_Areas_Block_Closure;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Project_Scale_Closure_Accepts_Frozen_Seven_Items'Access,
                        "accepts the frozen seven project-scale validation items");
      Register_Routine (T, Test_Project_Item_Test_Documentation_And_Consumer_Rejections'Access,
                        "rejects project item, test, documentation, and consumer defects");
      Register_Routine (T, Test_Reopened_Gap_And_Speculative_Work_Rejections'Access,
                        "rejects reopened gaps and speculative work without evidence");
      Register_Routine (T, Test_Stale_And_Missing_Closure_Evidence'Access,
                        "rejects stale or missing closure evidence");
      Register_Routine (T, Test_Duplicate_And_Missing_Project_Scale_Areas_Block_Closure'Access,
                        "rejects duplicate or missing project-scale closure areas");
   end Register_Tests;

end Test_Ada_Project_Scale_Closure;
