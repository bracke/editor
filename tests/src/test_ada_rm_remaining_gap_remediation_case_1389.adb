with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1389;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1389 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1389;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Representation_Closure;
   use type Audit.Representation_Form;
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
      Form : Audit.Representation_Form := Audit.Form_Record_Component_Layout_Resolved)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Record_Layout_Variant_Component_Edge;
      Row.Family := Matrix.Family_Representation_Aspects_Freezing;
      Row.Owner := Matrix.Slice_Record_Layout_Representation;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Closure := Audit.Closure_Record_Representation;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/record-layout-variant-component.ads");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("record representation clauses must preserve discriminant, variant, controlled-component, range/predicate, and consumer evidence as one canonical result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1389");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1389");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Representation.Record_Variant_Component");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1389 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1389 precision classification");
   end Expect_Status;

   procedure Test_Record_Representation_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Form_Record_Component_Layout_Resolved));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Form_Illegal_Variant_Component_Overlap);
      Row.Variant_Component_Overlap := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Form_Runtime_Check_Preserved);
      Row.Runtime_Check_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal,
                       Audit.Form_Warning_Only_Preserved);
      Row.Warning_Only_Preserved := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Form_Indeterminate_Private_View);
      Row.Missing_Full_View := True;
      Row.Complete_Representation_Evidence := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1389 should close the record-layout variant component gap");
      Assert (Results.Remediated_Count >= 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Warning_Count = 1, "warning count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Record_Component_Layout_Resolved,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Variant_Component_Overlap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Warning_Only_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
   end Test_Record_Representation_Gap_Remediated;

   procedure Test_Record_Representation_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Variant_Component_Overlap := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Discriminant_Dependent_Layout := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Controlled_Component_Layout := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Missing_Component_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Stale_Representation_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Variant_Component_Overlap,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Discriminant_Dependent_Layout,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Controlled_Component_Layout,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 14, Audit.Status_Indeterminate_Stale_Representation_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Record_Representation_Rejections;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20);
      Row.Inventory_Row_From_Pass1366 := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21);
      Row.Named_Concrete_Subrule := False;
      Row.Concrete_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22);
      Row.Coverage_Promoted_To_Covered := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23);
      Row.Final_Gate_No_Longer_Reports_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24);
      Row.Warning_Only_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26);
      Row.Representation_Fingerprint := 1;
      Row.Expected_Representation_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (27);
      Row.Discriminant_Fingerprint := 1;
      Row.Expected_Discriminant_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Missing_Pass1366_Inventory_Row,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 21, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 23, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 24, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 25, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 26, Audit.Status_Representation_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 27, Audit.Status_Discriminant_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Record_Representation_Gap_Remediated'Access,
         "record layout variant component gap remediated");
      Register_Routine
        (T, Test_Record_Representation_Rejections'Access,
         "inactive variant component overlap, discriminant-dependent layout, controlled component layout, and stale representation rejections");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1389;
