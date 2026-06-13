with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Release_Readiness_Validation_Pass1431;

package body Test_Ada_Phase579_Release_Readiness_Validation_Pass1431 is
   package Ready renames Editor.Ada_Phase579_Release_Readiness_Validation_Pass1431;
   use type Ready.Readiness_Surface;
   use type Ready.Readiness_Status;
   use type Ready.Readiness_Result_Class;
   use type Ready.Readiness_Row;
   use type Ready.Readiness_Input;
   use type Ready.Readiness_Entry;
   use type Ready.Readiness_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Release_Readiness_Validation_Pass1431");
   end Name;

   function Base_Row
     (Id : Natural;
      Surface : Ready.Readiness_Surface;
      Name : String) return Ready.Readiness_Row is
      Row : Ready.Readiness_Row;
   begin
      Row.Id := Id;
      Row.Surface := Surface;
      Row.Name := To_Unbounded_String (Name);
      Row.Expected_Package_Name := To_Unbounded_String
        ("Editor.Ada_Phase579_Release_Readiness_Validation_Pass1431");
      Row.Expected_Test_Name := To_Unbounded_String
        ("Test_Ada_Phase579_Release_Readiness_Validation_Pass1431");
      Row.Expected_Readme_Name := To_Unbounded_String ("README_PASS1431.txt");
      Row.Source_Fingerprint := Id * 100 + 11;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 100 + 12;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Suite_Fingerprint := Id * 100 + 13;
      Row.Expected_Suite_Fingerprint := Row.Suite_Fingerprint;
      Row.Documentation_Fingerprint := Id * 100 + 14;
      Row.Expected_Documentation_Fingerprint := Row.Documentation_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Ready.Readiness_Model;
      Id : Natural;
      Status : Ready.Readiness_Status;
      Result_Class : Ready.Readiness_Result_Class) is
      Feed_Item : constant Ready.Readiness_Entry := Ready.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1431 readiness status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1431 readiness class");
      Assert (Ready.Class_For_Status (Status) = Result_Class,
              "readiness status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Release_Readiness_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Ready.Readiness_Input;
      Model : Ready.Readiness_Model;
   begin
      Ready.Add_Row (Input, Base_Row
        (1, Ready.Surface_Source_Package,
         "pass1431 source package is present"));
      Ready.Add_Row (Input, Base_Row
        (2, Ready.Surface_Test_Package,
         "pass1431 AUnit package is present"));
      Ready.Add_Row (Input, Base_Row
        (3, Ready.Surface_Readme,
         "pass1431 README is present"));
      Ready.Add_Row (Input, Base_Row
        (4, Ready.Surface_Core_Suite_Registration,
         "pass1431 Core_Suite registration is present once"));
      Ready.Add_Row (Input, Base_Row
        (5, Ready.Surface_Release_Documentation,
         "pass1431 release documentation agrees with source and tests"));
      Ready.Add_Row (Input, Base_Row
        (6, Ready.Surface_Final_Remaining_Gap_Closure,
         "pass1428 finite Remaining edge closure remains frozen"));

      Model := Ready.Build (Input);

      Assert (Ready.Release_Readiness_Achieved (Model),
              "release readiness should be achieved for coherent surfaces");
      Assert (Model.Validated_Count = 6, "all readiness rows validated");
      Assert (Model.Rejected_Count = 0, "no readiness rejection expected");
      Assert (Model.Indeterminate_Count = 0,
              "no indeterminate readiness evidence expected");

      for Id in 1 .. 6 loop
         Expect_Status
           (Model, Id, Ready.Status_Validated, Ready.Class_Validated);
      end loop;
   end Test_Release_Readiness_Closure;

   procedure Test_Orphan_And_Registration_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Ready.Readiness_Input;
      Model : Ready.Readiness_Model;
      Row : Ready.Readiness_Row;
   begin
      Row := Base_Row
        (10, Ready.Surface_Source_Package,
         "source package exists without matching test");
      Row.Test_Present := False;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (11, Ready.Surface_Test_Package,
         "test package is not registered in Core_Suite");
      Row.Registered_In_Core_Suite := False;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (12, Ready.Surface_Core_Suite_Registration,
         "test package registered twice in Core_Suite");
      Row.Duplicate_Core_Suite_Registration := True;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (13, Ready.Surface_Source_Package,
         "obsolete source package lacks canonical release surface");
      Row.Orphan_Source := True;
      Ready.Add_Row (Input, Row);

      Model := Ready.Build (Input);

      Expect_Status
        (Model, 10, Ready.Status_Rejected_Missing_Test,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 11, Ready.Status_Rejected_Unregistered_Test,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 12, Ready.Status_Rejected_Duplicate_Registration,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 13, Ready.Status_Rejected_Orphan_Source,
         Ready.Class_Rejected);
      Assert (Model.Rejected_Count = 4,
              "all release-readiness structural failures rejected");
   end Test_Orphan_And_Registration_Rejections;

   procedure Test_Readme_Documentation_Remaining_Gap_And_Stale_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Ready.Readiness_Input;
      Model : Ready.Readiness_Model;
      Row : Ready.Readiness_Row;
   begin
      Row := Base_Row
        (20, Ready.Surface_Readme,
         "README_PASS1431 is absent from the release bundle");
      Row.Readme_Present := False;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (21, Ready.Surface_Release_Documentation,
         "release documentation names a different final surface");
      Row.Release_Documentation_Agreed := False;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (22, Ready.Surface_Final_Remaining_Gap_Closure,
         "new Remaining edge appears after pass1428 closure");
      Row.Reopened_Remaining_Gap := True;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (23, Ready.Surface_Project_Index,
         "project index carries a stale suite fingerprint");
      Row.Suite_Fingerprint := 1;
      Row.Expected_Suite_Fingerprint := 2;
      Ready.Add_Row (Input, Row);

      Row := Base_Row
        (24, Ready.Surface_Unknown,
         "missing readiness evidence");
      Row.Evidence_Present := False;
      Ready.Add_Row (Input, Row);

      Model := Ready.Build (Input);

      Expect_Status
        (Model, 20, Ready.Status_Rejected_Missing_Readme,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 21, Ready.Status_Rejected_Release_Documentation_Drift,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 22, Ready.Status_Rejected_Reopened_Remaining_Gap,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 23, Ready.Status_Rejected_Stale_Readiness_Evidence,
         Ready.Class_Rejected);
      Expect_Status
        (Model, 24, Ready.Status_Indeterminate_Missing_Evidence,
         Ready.Class_Indeterminate);
      Assert (Model.Rejected_Count = 4,
              "readiness release-surface failures rejected");
      Assert (Model.Indeterminate_Count = 1,
              "missing readiness evidence is indeterminate");
   end Test_Readme_Documentation_Remaining_Gap_And_Stale_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Release_Readiness_Closure'Access,
         "release readiness validates coherent source/test/readme/suite surfaces");
      Register_Routine
        (T, Test_Orphan_And_Registration_Rejections'Access,
         "release readiness rejects orphan and registration drift");
      Register_Routine
        (T, Test_Readme_Documentation_Remaining_Gap_And_Stale_Rejections'Access,
         "release readiness rejects README/doc/remaining/stale drift");
   end Register_Tests;

end Test_Ada_Phase579_Release_Readiness_Validation_Pass1431;
