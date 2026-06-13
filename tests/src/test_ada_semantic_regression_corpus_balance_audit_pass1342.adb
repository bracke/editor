with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342;

package body Test_Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342 is

   package Audit renames Editor.Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Corpus_Group;
   use type Audit.Corpus_Scenario;
   use type Audit.Corpus_Status;
   use type Audit.Corpus_Row;
   use type Audit.Corpus_Input;
   use type Audit.Corpus_Entry;
   use type Audit.Corpus_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Corpus_Input;
      Id : Natural;
      Family : Audit.RM_Family;
      Slice : Audit.Implementing_Slice;
      Group : Audit.Corpus_Group;
      Scenario : Audit.Corpus_Scenario;
      State : Audit.Remediation_State := Remediation.State_Covered;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Actual : Audit.Precision_Classification := Precision.Class_Legal;
      Source_Shaped : Boolean := True;
      Adds_Rule_Coverage : Boolean := True;
      Consumer_Reached : Boolean := True;
      Runtime_Check_Applicable : Boolean := True;
      Indeterminate_Applicable : Boolean := True;
      Runtime_Check_Preserved : Boolean := True;
      Runtime_Check_Collapsed : Boolean := False;
      Indeterminate_Collapsed_Legal : Boolean := False;
      Indeterminate_Collapsed_Illegal : Boolean := False;
      Stable_Blocker_Family : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Corpus_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Corpus_Row;
      FP : constant Natural := 1_342_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Family := Family;
      Row.Slice := Slice;
      Row.State := State;
      Row.Consumer := Consumer;
      Row.Group := Group;
      Row.Scenario := Scenario;
      Row.Expected := Expected;
      Row.Actual := Actual;
      Row.Name := To_Unbounded_String ("source-shaped semantic regression corpus row");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_342_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Adds_Rule_Coverage := Adds_Rule_Coverage;
      Row.Semantic_Consumer_Reached := Consumer_Reached;
      Row.Runtime_Check_Applicable := Runtime_Check_Applicable;
      Row.Indeterminate_Applicable := Indeterminate_Applicable;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Runtime_Check_Collapsed_To_Illegal := Runtime_Check_Collapsed;
      Row.Indeterminate_Collapsed_To_Legal := Indeterminate_Collapsed_Legal;
      Row.Indeterminate_Collapsed_To_Illegal := Indeterminate_Collapsed_Illegal;
      Row.Stable_Blocker_Family := Stable_Blocker_Family;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Corpus_Fingerprint := FP + 1;
      Row.Expected_Corpus_Fingerprint :=
        (if Expected_Corpus_FP = 0 then Row.Corpus_Fingerprint else Expected_Corpus_FP);
      Row.Source_Fingerprint := FP + 2;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 3;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Type_Fingerprint := FP + 4;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Profile_Fingerprint := FP + 5;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 6;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 7;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 8;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Corpus_Row (Input, Row);
   end Add_Row;

   procedure Add_Balanced_Family
     (Input : in out Audit.Corpus_Input;
      Start_Id : Natural;
      Family : Audit.RM_Family;
      Slice : Audit.Implementing_Slice;
      Group : Audit.Corpus_Group) is
   begin
      Add_Row (Input, Start_Id + 0, Family, Slice, Group,
               Audit.Scenario_Legal,
               Expected => Precision.Class_Legal,
               Actual => Precision.Class_Legal);
      Add_Row (Input, Start_Id + 1, Family, Slice, Group,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal);
      Add_Row (Input, Start_Id + 2, Family, Slice, Group,
               Audit.Scenario_Legal_With_Runtime_Check,
               Expected => Precision.Class_Legal_With_Runtime_Check,
               Actual => Precision.Class_Legal_With_Runtime_Check);
      Add_Row (Input, Start_Id + 3, Family, Slice, Group,
               Audit.Scenario_Indeterminate,
               Expected => Precision.Class_Indeterminate,
               Actual => Precision.Class_Indeterminate);
      Add_Row (Input, Start_Id + 4, Family, Slice, Group,
               Audit.Scenario_Consumer_Surfaced,
               Consumer => Consumers.Consumer_Hover_Details,
               Expected => Precision.Class_Legal,
               Actual => Precision.Class_Legal);
   end Add_Balanced_Family;

   procedure Expect_Status
     (Results : Audit.Corpus_Model;
      Family : Audit.RM_Family;
      Status : Audit.Corpus_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Family).Status = Status,
         "unexpected semantic regression corpus balance status");
   end Expect_Status;

   procedure Test_Balanced_Covered_Family_Is_Accepted

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Balanced_Family
        (Input, 1,
         Matrix.Family_Aggregates,
         Matrix.Slice_Aggregate,
         Audit.Group_Aggregate_Assignment_Predicate);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 1, "expected one balanced family");
      Assert (Results.Balanced_Count = 1, "covered family should be balanced");
      Assert (Results.Invalid_Count = 0, "balanced family should be valid");
      Assert (Results.Legal_Scenario_Count = 1, "legal scenario should be counted");
      Assert (Results.Illegal_Scenario_Count = 1, "illegal scenario should be counted");
      Assert (Results.Runtime_Check_Scenario_Count = 1, "runtime scenario should be counted");
      Assert (Results.Indeterminate_Scenario_Count = 1, "indeterminate scenario should be counted");
      Assert (Results.Consumer_Surfaced_Scenario_Count = 1, "consumer scenario should be counted");
      Assert (Audit.Semantic_Regression_Corpus_Balanced (Results),
              "balanced source-shaped corpus should be accepted");
   end Test_Balanced_Covered_Family_Is_Accepted;

   procedure Test_Only_Positive_And_Only_Negative_Corpora_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Assignments_Conversions,
               Matrix.Slice_Assignment_Conversion,
               Audit.Group_Aggregate_Assignment_Predicate,
               Audit.Scenario_Legal);
      Add_Row (Input, 2,
               Matrix.Family_Calls_Overload_Callable_Profiles,
               Matrix.Slice_Callable_Profile,
               Audit.Group_Overload_Callable_Conversion,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Assignments_Conversions,
                     Audit.Status_Only_Positive_Tests);
      Expect_Status (Results, Matrix.Family_Calls_Overload_Callable_Profiles,
                     Audit.Status_Only_Negative_Tests);
   end Test_Only_Positive_And_Only_Negative_Corpora_Are_Rejected;

   procedure Test_Runtime_And_Indeterminate_Scenarios_Are_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Legal);
      Add_Row (Input, 2,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal);
      Add_Row (Input, 3,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Indeterminate,
               Expected => Precision.Class_Indeterminate,
               Actual => Precision.Class_Indeterminate);
      Add_Row (Input, 4,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Consumer_Surfaced,
               Consumer => Consumers.Consumer_Diagnostics);

      Add_Row (Input, 11,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit,
               Audit.Group_Context_Library_Elaboration,
               Audit.Scenario_Legal,
               Runtime_Check_Applicable => False);
      Add_Row (Input, 12,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit,
               Audit.Group_Context_Library_Elaboration,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal,
               Runtime_Check_Applicable => False);
      Add_Row (Input, 13,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit,
               Audit.Group_Context_Library_Elaboration,
               Audit.Scenario_Legal_With_Runtime_Check,
               Expected => Precision.Class_Legal_With_Runtime_Check,
               Actual => Precision.Class_Legal_With_Runtime_Check,
               Runtime_Check_Applicable => False);
      Add_Row (Input, 14,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit,
               Audit.Group_Context_Library_Elaboration,
               Audit.Scenario_Consumer_Surfaced,
               Runtime_Check_Applicable => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Types_Subtypes_Constraints_Predicates,
                     Audit.Status_Missing_Runtime_Check_Scenario);
      Expect_Status (Results, Matrix.Family_Library_Context_Subunits_Elaboration,
                     Audit.Status_Missing_Indeterminate_Scenario);
   end Test_Runtime_And_Indeterminate_Scenarios_Are_Required;

   procedure Test_Runtime_And_Indeterminate_Collapses_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Access_Types_Accessibility,
               Matrix.Slice_Access_Type_Access_Subprogram,
               Audit.Group_Aggregate_Assignment_Predicate,
               Audit.Scenario_Legal_With_Runtime_Check,
               Expected => Precision.Class_Legal_With_Runtime_Check,
               Actual => Precision.Class_Illegal,
               Runtime_Check_Collapsed => True);
      Add_Row (Input, 2,
               Matrix.Family_Names_Visibility_Selected_Attributes,
               Matrix.Slice_Visibility_Name_Resolution,
               Audit.Group_Private_Full_Limited_Views,
               Audit.Scenario_Indeterminate,
               Expected => Precision.Class_Indeterminate,
               Actual => Precision.Class_Legal,
               Indeterminate_Collapsed_Legal => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Access_Types_Accessibility,
                     Audit.Status_Runtime_Check_Collapsed_To_Illegal);
      Expect_Status (Results, Matrix.Family_Names_Visibility_Selected_Attributes,
                     Audit.Status_Indeterminate_Collapsed_To_Legal);
   end Test_Runtime_And_Indeterminate_Collapses_Are_Rejected;

   procedure Test_Source_Stale_And_Duplicate_Noncoverage_Rows_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Expressions_Expected_Type_Resolution,
               Matrix.Slice_Ada2022_Expression_Type_Resolution,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Legal,
               Source_Shaped => False);
      Add_Row (Input, 2,
               Matrix.Family_Static_Expressions_Choices,
               Matrix.Slice_Numeric_Static_Expression,
               Audit.Group_Static_Choice_Runtime,
               Audit.Scenario_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 3,
               Matrix.Family_Arrays_Records_Discriminants_Variants,
               Matrix.Slice_Array_Container_Indexing,
               Audit.Group_Aggregate_Assignment_Predicate,
               Audit.Scenario_Legal,
               Adds_Rule_Coverage => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Expressions_Expected_Type_Resolution,
                     Audit.Status_Source_Shaped_Evidence_Missing);
      Expect_Status (Results, Matrix.Family_Static_Expressions_Choices,
                     Audit.Status_Stale_Corpus_Fingerprint);
      Expect_Status (Results, Matrix.Family_Arrays_Records_Discriminants_Variants,
                     Audit.Status_Duplicate_Noncoverage_Row);
   end Test_Source_Stale_And_Duplicate_Noncoverage_Rows_Are_Rejected;

   procedure Test_Consumer_Surface_Is_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Interfacing_Import_Export,
               Matrix.Slice_Interfacing_Import_Export,
               Audit.Group_Representation_Interfacing_Freezing,
               Audit.Scenario_Legal);
      Add_Row (Input, 2,
               Matrix.Family_Interfacing_Import_Export,
               Matrix.Slice_Interfacing_Import_Export,
               Audit.Group_Representation_Interfacing_Freezing,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal);
      Add_Row (Input, 3,
               Matrix.Family_Interfacing_Import_Export,
               Matrix.Slice_Interfacing_Import_Export,
               Audit.Group_Representation_Interfacing_Freezing,
               Audit.Scenario_Legal_With_Runtime_Check,
               Expected => Precision.Class_Legal_With_Runtime_Check,
               Actual => Precision.Class_Legal_With_Runtime_Check);
      Add_Row (Input, 4,
               Matrix.Family_Interfacing_Import_Export,
               Matrix.Slice_Interfacing_Import_Export,
               Audit.Group_Representation_Interfacing_Freezing,
               Audit.Scenario_Indeterminate,
               Expected => Precision.Class_Indeterminate,
               Actual => Precision.Class_Indeterminate);

      Add_Row (Input, 11,
               Matrix.Family_Diagnostics_Consumer_Readiness,
               Matrix.Slice_Diagnostics_Consumer,
               Audit.Group_Diagnostics_Consumer_Readiness,
               Audit.Scenario_Consumer_Surfaced,
               Consumer => Consumers.Consumer_Diagnostics,
               Consumer_Reached => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Interfacing_Import_Export,
                     Audit.Status_Missing_Consumer_Surfaced_Scenario);
      Expect_Status (Results, Matrix.Family_Diagnostics_Consumer_Readiness,
                     Audit.Status_Semantic_Consumer_Not_Reached);
   end Test_Consumer_Surface_Is_Required;

   procedure Test_Partial_And_Missing_Cannot_Be_Balanced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Balanced_Family
        (Input, 1,
         Matrix.Family_Contracts_Global_Depends_Flow,
         Matrix.Slice_Flow_Refinement,
         Audit.Group_Generic_Replay_Flow);
      for I in 0 .. 4 loop
         declare
            Row : Audit.Corpus_Row := Input.Rows.Element (Natural (I));
         begin
            Row.State := Remediation.State_Partial;
            Input.Rows.Replace_Element (Natural (I), Row);
         end;
      end loop;

      Add_Balanced_Family
        (Input, 20,
         Matrix.Family_Representation_Aspects_Freezing,
         Matrix.Slice_Unknown,
         Audit.Group_Representation_Interfacing_Freezing);
      for I in 5 .. 9 loop
         declare
            Row : Audit.Corpus_Row := Input.Rows.Element (Natural (I));
         begin
            Row.State := Remediation.State_Missing;
            Input.Rows.Replace_Element (Natural (I), Row);
         end;
      end loop;

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Contracts_Global_Depends_Flow,
                     Audit.Status_Partial_Coverage_Treated_As_Balanced);
      Expect_Status (Results, Matrix.Family_Representation_Aspects_Freezing,
                     Audit.Status_Missing_Checker_Treated_As_Balanced);
   end Test_Partial_And_Missing_Cannot_Be_Balanced;

   procedure Test_Fingerprint_Mismatches_Block_Corpus_Evidence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Tagged_Interfaces_Dispatching,
               Matrix.Slice_Tagged_Dispatching,
               Audit.Group_Tagged_Interface_Contracts,
               Audit.Scenario_Legal,
               Expected_Source_FP => 7);
      Add_Row (Input, 2,
               Matrix.Family_Tasking_Protected_Synchronized,
               Matrix.Slice_Tasking_Protected,
               Audit.Group_Tasking_Parallel_Shared_State,
               Audit.Scenario_Legal,
               Expected_Type_FP => 8,
               Expected_Profile_FP => 9);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Tagged_Interfaces_Dispatching,
                     Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, Matrix.Family_Tasking_Protected_Synchronized,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Matrix.Family_Tasking_Protected_Synchronized).Blocker_Count >= 2,
         "type/profile fingerprint mismatches should both be retained");
   end Test_Fingerprint_Mismatches_Block_Corpus_Evidence;

   procedure Test_Unstable_Blocker_Families_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Corpus_Input;
      Results : Audit.Corpus_Model;
   begin
      Add_Row (Input, 1,
               Matrix.Family_Exceptions_Finalization,
               Matrix.Slice_Exception_Finalization,
               Audit.Group_Context_Library_Elaboration,
               Audit.Scenario_Illegal,
               Expected => Precision.Class_Illegal,
               Actual => Precision.Class_Illegal,
               Stable_Blocker_Family => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Exceptions_Finalization,
                     Audit.Status_Unstable_Blocker_Family);
   end Test_Unstable_Blocker_Families_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Covered_Family_Is_Accepted'Access,
         "balanced covered family is accepted");
      Register_Routine
        (T, Test_Only_Positive_And_Only_Negative_Corpora_Are_Rejected'Access,
         "only-positive and only-negative corpora are rejected");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Scenarios_Are_Required'Access,
         "runtime and indeterminate scenarios are required");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Collapses_Are_Rejected'Access,
         "runtime and indeterminate collapses are rejected");
      Register_Routine
        (T, Test_Source_Stale_And_Duplicate_Noncoverage_Rows_Are_Rejected'Access,
         "source, stale, and duplicate noncoverage rows are rejected");
      Register_Routine
        (T, Test_Consumer_Surface_Is_Required'Access,
         "consumer-surfaced scenarios are required");
      Register_Routine
        (T, Test_Partial_And_Missing_Cannot_Be_Balanced'Access,
         "partial and missing families cannot be balanced");
      Register_Routine
        (T, Test_Fingerprint_Mismatches_Block_Corpus_Evidence'Access,
         "fingerprint mismatches block corpus evidence");
      Register_Routine
        (T, Test_Unstable_Blocker_Families_Are_Rejected'Access,
         "unstable blocker families are rejected");
   end Register_Tests;

end Test_Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342;
