with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1369;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1369 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1369;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Stream_Item_Form;
   use type Audit.External_Representation_Form;
   use type Audit.Remediation_Status;
   use type Audit.Remediation_Row;
   use type Audit.Remediation_Input;
   use type Audit.Remediation_Entry;
   use type Audit.Remediation_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;
   package Inventory renames Audit.Inventory;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      External : Audit.External_Representation_Form :=
        Audit.External_Representation_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Stream_Import_Export_Representation_Edge;
      Row.Family := Matrix.Family_Representation_Aspects_Freezing;
      Row.Owner := Matrix.Slice_Representation_Aspect_Operational;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Form := Audit.Stream_Read_Attribute;
      Row.External := External;
      Row.Source_File := To_Unbounded_String ("src/stream-external-representation.ads");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("stream operational item must agree with import/export convention and freezing evidence");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1369");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1369");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Representation.Stream_External_Import_Export");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1369 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1369 precision classification");
   end Expect_Status;

   procedure Test_Stream_External_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.External_Representation_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.External_Representation_Import_Conflict);
      Row.Import_Stream_Conflict := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.External_Representation_Runtime_Address_Check);
      Row.Runtime_Address_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.External_Representation_Private_View_Only);
      Row.Private_View_Only := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1369 should close the selected stream/import/export gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Stream_External_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Import_Stream_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Address_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Private_View_Only,
                     Precision.Class_Indeterminate);
   end Test_Stream_External_Gap_Remediated;

   procedure Test_Stream_Representation_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Stream_Profile_Conforms := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Export_Stream_Conflict := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Convention_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Stream_Item_Before_Freezing := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Duplicate_Operational_Item := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Stream_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Export_Stream_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Convention_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Late_Stream_Item_After_Freezing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Operational_Item_Duplicate,
                     Precision.Class_Illegal);
   end Test_Stream_Representation_Rejections;

   procedure Test_External_Profile_And_Consumer_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20);
      Row.External_Name_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21);
      Row.Link_Name_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22);
      Row.C_Callable_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23);
      Row.Access_Subprogram_Convention_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24);
      Row.Representation_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Freezing_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Illegal_External_Name_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Illegal_Link_Name_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22, Audit.Status_Illegal_C_Callable_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 23, Audit.Status_Illegal_Access_Subprogram_Convention_Lost,
         Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Illegal_Representation_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25, Audit.Status_Illegal_Freezing_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 26, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_External_Profile_And_Consumer_Rejections;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (30);
      Row.Inventory_Row_From_Pass1366 := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31);
      Row.Named_Concrete_Subrule := False;
      Row.Concrete_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32);
      Row.Coverage_Promoted_To_Covered := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33);
      Row.Final_Gate_No_Longer_Reports_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34);
      Row.Indeterminate_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36);
      Row.Stream_Fingerprint := 1;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (37);
      Row.Convention_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Missing_Pass1366_Inventory_Row,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Stream_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 37, Audit.Status_Convention_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Stream_External_Gap_Remediated'Access,
         "stream/import/export remaining gap is remediated");
      Register_Routine
        (T, Test_Stream_Representation_Rejections'Access,
         "stream profile, import/export, convention, freezing, and duplicate evidence reject precisely");
      Register_Routine
        (T, Test_External_Profile_And_Consumer_Rejections'Access,
         "external name, callable profile, representation, freezing, and consumer evidence agree");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory ownership, final-gate promotion, balance, and fingerprints are enforced");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1369;
