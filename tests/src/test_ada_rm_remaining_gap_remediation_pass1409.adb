with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1409;

package body Test_Ada_RM_Remaining_Gap_Remediation_Pass1409 is

     package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1409;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Access_Parameter_Allocator_Master_Closure;
   use type Audit.Access_Parameter_Allocator_Master_Form;
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
        return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation_Pass1409");
     end Name;

     function Base_Row
       (Id : Natural;
        Expected : Audit.Precision_Classification := Precision.Class_Legal;
        Form : Audit.Access_Parameter_Allocator_Master_Form := Audit.Form_Access_Parameter_Allocator_Master_Resolved)
        return Audit.Remediation_Row is
        Row : Audit.Remediation_Row;
     begin
        Row.Id := Id;
        Row.Gap := Audit.Remaining_Access_Parameter_Allocator_Master_Edge;
        Row.Family := Matrix.Family_Access_Types_Accessibility;
        Row.Owner := Matrix.Slice_Accessibility_Lifetime;
        Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
        Row.Previous_Remediation := Remediation.State_Partial;
        Row.Target_Remediation := Remediation.State_Covered;
        Row.Matrix_Level_Before := Matrix.Coverage_Partial;
        Row.Matrix_Level_After := Matrix.Coverage_Covered;
        Row.Expected := Expected;
        Row.Consumer := Consumers.Consumer_Diagnostics;
        Row.Closure := Audit.Closure_Access_Parameter_Association;
        Row.Form := Form;
        Row.Source_File := To_Unbounded_String ("src/access-parameter-allocator-master.adb");
        Row.Concrete_Subrule :=
          To_Unbounded_String
            ("access parameters initialized from allocator-created objects must preserve master, lifetime, storage"
             & "-pool, null-exclusion, deallocation, finalization, and consumer evidence");
        Row.Candidate_Implementing_Package :=
          To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1409");
        Row.Candidate_Pass := To_Unbounded_String ("Pass1409");
        Row.Blocker_Family := To_Unbounded_String ("RM.Accessibility.Access_Parameter_Allocator_Master");
        return Row;
     end Base_Row;

     procedure Expect_Status
       (Results : Audit.Remediation_Model;
        Id : Natural;
        Status : Audit.Remediation_Status;
        Expected : Audit.Precision_Classification) is
        Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
     begin
        Assert (Item.Status = Status, "unexpected pass1409 status");
        Assert (Audit.Expected_For_Status (Item.Status) = Expected,
                "unexpected pass1409 precision classification");
     end Expect_Status;

     procedure Test_Gap_Remediated

       (T : in out AUnit.Test_Cases.Test_Case'Class) is

        pragma Unreferenced (T);
        Input : Audit.Remediation_Input;
        Results : Audit.Remediation_Model;
        Row : Audit.Remediation_Row;
     begin
        Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                        Audit.Form_Access_Parameter_Allocator_Master_Resolved));

        Row := Base_Row (2, Precision.Class_Illegal,
                         Audit.Form_Illegal_Static_Accessibility_Escape);
        Row.Static_Accessibility_Escape := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                         Audit.Form_Runtime_Accessibility_Check_Preserved);
        Row.Runtime_Accessibility_Check_Preserved := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (4, Precision.Class_Legal,
                         Audit.Form_Warning_Only_Preserved);
        Row.Warning_Only_Preserved := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (5, Precision.Class_Indeterminate,
                         Audit.Form_Indeterminate_Missing_Master_Evidence);
        Row.Missing_Master_Evidence := True;
        Row.Complete_Master_Evidence := False;
        Audit.Add_Row (Input, Row);

        Results := Audit.Build (Input);

        Assert (Audit.Gap_Remediated (Results), "pass1409 should close the access parameter allocator master gap");
        Assert (Results.Remediated_Count >= 1, "legal count");
        Assert (Results.Illegal_Count = 1, "illegal count");
        Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
        Assert (Results.Warning_Count = 1, "warning count");
        Assert (Results.Indeterminate_Count = 1, "indeterminate count");

        Expect_Status (Results, 1, Audit.Status_Access_Parameter_Allocator_Master_Resolved, Precision.Class_Legal);
        Expect_Status (Results, 2, Audit.Status_Illegal_Static_Accessibility_Escape, Precision.Class_Illegal);
        Expect_Status (Results, 3, Audit.Status_Runtime_Accessibility_Check_Preserved,
                       Precision.Class_Legal_With_Runtime_Check);
        Expect_Status (Results, 4, Audit.Status_Warning_Only_Preserved, Precision.Class_Legal);
        Expect_Status (Results, 5, Audit.Status_Indeterminate_Missing_Master_Evidence,
                       Precision.Class_Indeterminate);
end Test_Gap_Remediated;

     procedure Test_Rejections

       (T : in out AUnit.Test_Cases.Test_Case'Class) is

        pragma Unreferenced (T);
        Input : Audit.Remediation_Input;
        Results : Audit.Remediation_Model;
        Row : Audit.Remediation_Row;
     begin
        Row := Base_Row (10);
Row.Null_Exclusion_Violation := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (11);
Row.Storage_Pool_Mismatch := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (12);
Row.Unchecked_Deallocation_Hazard := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (13);
Row.Controlled_Allocation_Finalization_Hazard := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (14);
Row.Missing_Full_View := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (15);
Row.Stale_Lifetime_Evidence := True;
Audit.Add_Row (Input, Row);

        Results := Audit.Build (Input);

        Expect_Status (Results, 10, Audit.Status_Illegal_Null_Exclusion_Violation,
               Precision.Class_Illegal);
Expect_Status (Results, 11, Audit.Status_Illegal_Storage_Pool_Mismatch,
               Precision.Class_Illegal);
Expect_Status (Results, 12, Audit.Status_Illegal_Unchecked_Deallocation_Hazard,
               Precision.Class_Illegal);
Expect_Status (Results, 13, Audit.Status_Illegal_Controlled_Allocation_Finalization_Hazard,
               Precision.Class_Illegal);
Expect_Status (Results, 14, Audit.Status_Indeterminate_Private_View,
               Precision.Class_Indeterminate);
Expect_Status (Results, 15, Audit.Status_Indeterminate_Stale_Lifetime_Evidence,
               Precision.Class_Indeterminate);
end Test_Rejections;

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
        Row.Runtime_Check_Test_Present := False;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (25);
        Row.Consumer_Lifetime_State_Agrees := False;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (26);
        Row.Profile_Fingerprint := 1;
        Row.Expected_Profile_Fingerprint := 2;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (27);
        Row.Lifetime_Fingerprint := 1;
        Row.Expected_Lifetime_Fingerprint := 2;
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
        Expect_Status (Results, 25, Audit.Status_Consumer_Not_Reached,
                       Precision.Class_Indeterminate);
        Expect_Status (Results, 26, Audit.Status_Profile_Fingerprint_Mismatch, Precision.Class_Indeterminate);
        Expect_Status (Results, 27, Audit.Status_Lifetime_Fingerprint_Mismatch, Precision.Class_Indeterminate);
end Test_Inventory_And_Fingerprint_Gates;

     overriding procedure Register_Tests (T : in out Test_Case) is
        use AUnit.Test_Cases.Registration;
     begin
        Register_Routine
          (T, Test_Gap_Remediated'Access,
           "access parameter allocator master gap remediated");
        Register_Routine
          (T, Test_Rejections'Access,
           "static accessibility, null exclusion, storage-pool, deallocation, finalization, private view, a"
           & "nd stale lifetime evidence rejections");
        Register_Routine
          (T, Test_Inventory_And_Fingerprint_Gates'Access,
           "inventory and fingerprint gates");
     end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Pass1409;
