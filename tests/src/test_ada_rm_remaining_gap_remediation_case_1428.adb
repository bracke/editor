with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1428 is
   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Closure_Status;
   use type Audit.Closure_Row;
   use type Audit.Closure_Input;
   use type Audit.Closure_Entry;
   use type Audit.Closure_Model;
   package Matrix renames Audit.Matrix;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation");
   end Name;

   function Base_Row
     (Id : Natural;
      Gap : Audit.Remediated_Gap_Family;
      Pass_Number : Natural)
      return Audit.Closure_Row is
      Row : Audit.Closure_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Pass_Number := Pass_Number;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Diagnostics_Consumer;
      Row.Expected := Precision.Class_Legal;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Source_File :=
        To_Unbounded_String ("README_PASS" & Natural'Image (Pass_Number) & ".txt");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("frozen finite remaining-gap edge is closed by its pass package, "
           & "test, README, suite registration, consumer evidence, and "
           & "stable blocker family");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String
          ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass"
           & Natural'Image (Pass_Number));
      Row.Candidate_Test_Package :=
        To_Unbounded_String
          ("Test_Ada_RM_Remaining_Gap_Remediation_Pass"
           & Natural'Image (Pass_Number));
      Row.Candidate_Readme :=
        To_Unbounded_String ("README_PASS" & Natural'Image (Pass_Number) & ".txt");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Remaining_Gap.Frozen_Inventory");
      Row.Inventory_Fingerprint := Pass_Number;
      Row.Expected_Inventory_Fingerprint := Pass_Number;
      Row.Consumer_Fingerprint := Pass_Number + Id;
      Row.Expected_Consumer_Fingerprint := Pass_Number + Id;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Closure_Model;
      Id : Natural;
      Status : Audit.Closure_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Closure_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1428 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1428 precision classification");
   end Expect_Status;

   procedure Test_Final_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Closure_Input;
      Results : Audit.Closure_Model;
   begin
      Audit.Add_Row (Input, Base_Row (1, Audit.Remaining_Protected_Action_Reentrancy_Edge, 1419));
      Audit.Add_Row (Input, Base_Row (2, Audit.Remaining_Volatile_Atomic_Representation_Clause_Edge, 1420));
      Audit.Add_Row (Input, Base_Row (3, Audit.Remaining_Controlled_Finalized_Discriminant_Component_Edge, 1421));
      Audit.Add_Row (Input, Base_Row (4, Audit.Remaining_Generic_Formal_Subprogram_Call_Edge, 1422));
      Audit.Add_Row (Input, Base_Row (5, Audit.Remaining_Access_Subprogram_Effect_Profile_Edge, 1423));
      Audit.Add_Row (Input, Base_Row (6, Audit.Remaining_Universal_Numeric_Stateful_Expected_Context_Edge, 1424));
      Audit.Add_Row (Input, Base_Row (7, Audit.Remaining_Renamed_Primitive_Visibility_Edge, 1425));
      Audit.Add_Row (Input, Base_Row (8, Audit.Remaining_Inherited_Private_Extension_Primitive_Hiding_Edge, 1426));
      Audit.Add_Row (Input, Base_Row (9, Audit.Remaining_Dispatching_Abstract_State_Effect_Edge, 1427));
      Audit.Add_Row
        (Input,
         Base_Row (10, Audit.Remaining_Inventory_Closed, 1428));

      Results := Audit.Build (Input);

      Assert (Audit.Final_Closure_Achieved (Results),
              "pass1428 should close the finite remaining-gap inventory");
      Assert (Results.Total_Rows = 10, "closure row count");
      Assert (Results.Closed_Count = 9, "closed edge count");
      Assert (Results.Invalid_Count = 0, "invalid closure count");

      Expect_Status (Results, 1, Audit.Status_Edge_Closed, Precision.Class_Legal);
      Expect_Status (Results, 9, Audit.Status_Edge_Closed, Precision.Class_Legal);
      Expect_Status (Results, 10, Audit.Status_Inventory_Closed, Precision.Class_Legal);
   end Test_Final_Closure;

   procedure Test_Reopened_And_Evidence_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Closure_Input;
      Results : Audit.Closure_Model;
      Row : Audit.Closure_Row;
   begin
      Audit.Add_Row
        (Input,
         Base_Row (20, Audit.Remaining_Protected_Action_Reentrancy_Edge, 1419));

      Row := Base_Row
        (21, Audit.Remaining_Volatile_Atomic_Representation_Clause_Edge, 1420);
      Row.Edge_Closed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (22, Audit.Remaining_Controlled_Finalized_Discriminant_Component_Edge, 1421);
      Row.Implementation_Package_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (23, Audit.Remaining_Generic_Formal_Subprogram_Call_Edge, 1422);
      Row.No_New_Edge_After_Freeze := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (24, Audit.Remaining_Access_Subprogram_Effect_Profile_Edge, 1423);
      Row.Inventory_Fingerprint := 1;
      Row.Expected_Inventory_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 21, Audit.Status_Edge_Reopened,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 22, Audit.Status_Missing_Implementation_Package,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 23, Audit.Status_New_Edge_After_Freeze,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 24, Audit.Status_Inventory_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
   end Test_Reopened_And_Evidence_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Final_Closure'Access,
         "finite remaining-gap inventory closed");
      Register_Routine
        (T, Test_Reopened_And_Evidence_Rejections'Access,
         "reopened edge and evidence rejections");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1428;
