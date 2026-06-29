with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1410;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1410 is

     package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1410;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Generic_Default_Object_Predicate_Closure;
   use type Audit.Generic_Default_Object_Predicate_Form;
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
        Form : Audit.Generic_Default_Object_Predicate_Form := Audit.Form_Generic_Default_Object_Predicate_Resolved)
        return Audit.Remediation_Row is
        Row : Audit.Remediation_Row;
     begin
        Row.Id := Id;
        Row.Gap := Audit.Remaining_Generic_Default_Object_Predicate_Edge;
        Row.Family := Matrix.Family_Generics_Contracts_Substitution_Replay;
        Row.Owner := Matrix.Slice_Generic_Contract_Body;
        Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
        Row.Previous_Remediation := Remediation.State_Partial;
        Row.Target_Remediation := Remediation.State_Covered;
        Row.Matrix_Level_Before := Matrix.Coverage_Partial;
        Row.Matrix_Level_After := Matrix.Coverage_Covered;
        Row.Expected := Expected;
        Row.Consumer := Consumers.Consumer_Diagnostics;
        Row.Closure := Audit.Closure_Generic_Formal_Object;
        Row.Form := Form;
        Row.Source_File := To_Unbounded_String ("src/generic-default-object-predicate.adb");
        Row.Concrete_Subrule :=
          To_Unbounded_String
            ("generic formal object defaults must agree with subtype compatibility, predicate, null-exclusion, lim"
             & "ited-view, mode, contract, and consumer evidence");
        Row.Candidate_Implementing_Package :=
          To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1410");
        Row.Candidate_Pass := To_Unbounded_String ("Pass1410");
        Row.Blocker_Family := To_Unbounded_String ("RM.Generics.Default_Object_Predicate");
        return Row;
     end Base_Row;

     procedure Expect_Status
       (Results : Audit.Remediation_Model;
        Id : Natural;
        Status : Audit.Remediation_Status;
        Expected : Audit.Precision_Classification) is
        Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
     begin
        Assert (Item.Status = Status, "unexpected pass1410 status");
        Assert (Audit.Expected_For_Status (Item.Status) = Expected,
                "unexpected pass1410 precision classification");
     end Expect_Status;

     procedure Test_Gap_Remediated

       (T : in out AUnit.Test_Cases.Test_Case'Class) is

        pragma Unreferenced (T);
        Input : Audit.Remediation_Input;
        Results : Audit.Remediation_Model;
        Row : Audit.Remediation_Row;
     begin
        Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                        Audit.Form_Generic_Default_Object_Predicate_Resolved));

        Row := Base_Row (2, Precision.Class_Illegal,
                         Audit.Form_Illegal_Default_Type_Mismatch);
        Row.Default_Type_Mismatch := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                         Audit.Form_Runtime_Predicate_Check_Preserved);
        Row.Runtime_Predicate_Check_Preserved := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (4, Precision.Class_Legal,
                         Audit.Form_Warning_Only_Preserved);
        Row.Warning_Only_Preserved := True;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (5, Precision.Class_Indeterminate,
                         Audit.Form_Indeterminate_Missing_Predicate_Evidence);
        Row.Missing_Predicate_Evidence := True;
        Row.Complete_Generic_Default_Evidence := False;
        Audit.Add_Row (Input, Row);

        Results := Audit.Build (Input);

        Assert (Audit.Gap_Remediated (Results), "pass1410 should close the generic default object predicate gap");
        Assert (Results.Remediated_Count >= 1, "legal count");
        Assert (Results.Illegal_Count = 1, "illegal count");
        Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
        Assert (Results.Warning_Count = 1, "warning count");
        Assert (Results.Indeterminate_Count = 1, "indeterminate count");

        Expect_Status (Results, 1, Audit.Status_Generic_Default_Object_Predicate_Resolved, Precision.Class_Legal);
        Expect_Status (Results, 2, Audit.Status_Illegal_Default_Type_Mismatch, Precision.Class_Illegal);
        Expect_Status (Results, 3, Audit.Status_Runtime_Predicate_Check_Preserved,
                       Precision.Class_Legal_With_Runtime_Check);
        Expect_Status (Results, 4, Audit.Status_Warning_Only_Preserved, Precision.Class_Legal);
        Expect_Status (Results, 5, Audit.Status_Indeterminate_Missing_Predicate_Evidence,
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
Row.Static_Predicate_Failure := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (11);
Row.Null_Exclusion_Default := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (12);
Row.Limited_View_Default_Copy := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (13);
Row.Generic_Default_Mode_Mismatch := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (14);
Row.Missing_Full_View := True;
Audit.Add_Row (Input, Row);

Row := Base_Row (15);
Row.Stale_Generic_Default_Evidence := True;
Audit.Add_Row (Input, Row);

        Results := Audit.Build (Input);

        Expect_Status (Results, 10, Audit.Status_Illegal_Static_Predicate_Failure,
               Precision.Class_Illegal);
Expect_Status (Results, 11, Audit.Status_Illegal_Null_Exclusion_Default,
               Precision.Class_Illegal);
Expect_Status (Results, 12, Audit.Status_Illegal_Limited_View_Default_Copy,
               Precision.Class_Illegal);
Expect_Status (Results, 13, Audit.Status_Illegal_Generic_Default_Mode_Mismatch,
               Precision.Class_Illegal);
Expect_Status (Results, 14, Audit.Status_Indeterminate_Private_View,
               Precision.Class_Indeterminate);
Expect_Status (Results, 15, Audit.Status_Indeterminate_Stale_Generic_Default_Evidence,
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
        Row.Consumer_Predicate_State_Agrees := False;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (26);
        Row.Generic_Fingerprint := 1;
        Row.Expected_Generic_Fingerprint := 2;
        Audit.Add_Row (Input, Row);

        Row := Base_Row (27);
        Row.Predicate_Fingerprint := 1;
        Row.Expected_Predicate_Fingerprint := 2;
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
        Expect_Status (Results, 26, Audit.Status_Generic_Fingerprint_Mismatch, Precision.Class_Indeterminate);
        Expect_Status (Results, 27, Audit.Status_Predicate_Fingerprint_Mismatch, Precision.Class_Indeterminate);
end Test_Inventory_And_Fingerprint_Gates;

     overriding procedure Register_Tests (T : in out Test_Case) is
        use AUnit.Test_Cases.Registration;
     begin
        Register_Routine
          (T, Test_Gap_Remediated'Access,
           "generic default object predicate gap remediated");
        Register_Routine
          (T, Test_Rejections'Access,
           "default type, static predicate, null exclusion, limited view, mode, private view, and stale gen"
           & "eric default evidence rejections");
        Register_Routine
          (T, Test_Inventory_And_Fingerprint_Gates'Access,
           "inventory and fingerprint gates");
     end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1410;
