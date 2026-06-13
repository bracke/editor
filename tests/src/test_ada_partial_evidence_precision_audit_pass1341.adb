with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package body Test_Ada_Partial_Evidence_Precision_Audit_Pass1341 is

   package Audit renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Area;
   use type Audit.Precision_Classification;
   use type Audit.Precision_Status;
   use type Audit.Precision_Row;
   use type Audit.Precision_Input;
   use type Audit.Precision_Entry;
   use type Audit.Precision_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Partial_Evidence_Precision_Audit_Pass1341");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Precision_Input;
      Id : Natural;
      Area : Audit.Precision_Area;
      Expected : Audit.Precision_Classification;
      Actual : Audit.Precision_Classification;
      Family : Audit.RM_Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Slice : Audit.Implementing_Slice := Matrix.Slice_End_To_End_Scenario_Audit;
      State : Audit.Remediation_State := Remediation.State_Covered;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Source_AST_Complete : Boolean := True;
      Type_Profile_Complete : Boolean := True;
      View_Cross_Unit_Complete : Boolean := True;
      Flow_Effect_Complete : Boolean := True;
      Representation_Freezing_Complete : Boolean := True;
      Hard_Diagnostic : Boolean := False;
      Blocker_Family : Boolean := True;
      Consumer_Represents_Blocker : Boolean := True;
      Runtime_Check_Preserved : Boolean := True;
      Partial_Coverage_Represented : Boolean := True;
      Missing_Checker_Represented : Boolean := True;
      Evidence_Stale : Boolean := False;
      Authoritative_Result : Boolean := False;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Precision_Row;
      FP : constant Natural := 1_341_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Area := Area;
      Row.Family := Family;
      Row.Slice := Slice;
      Row.State := State;
      Row.Consumer := Consumer;
      Row.Name := To_Unbounded_String ("source-shaped partial-evidence precision row");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_341_000 + Id);
      Row.Expected := Expected;
      Row.Actual := Actual;
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Required_Source_AST_Evidence_Complete := Source_AST_Complete;
      Row.Required_Type_Profile_Evidence_Complete := Type_Profile_Complete;
      Row.Required_View_Cross_Unit_Evidence_Complete := View_Cross_Unit_Complete;
      Row.Required_Flow_Effect_Evidence_Complete := Flow_Effect_Complete;
      Row.Required_Representation_Freezing_Evidence_Complete := Representation_Freezing_Complete;
      Row.Hard_Diagnostic_Emitted := Hard_Diagnostic;
      Row.Semantic_Blocker_Family_Present := Blocker_Family;
      Row.Consumer_Represents_Blocker_State := Consumer_Represents_Blocker;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Partial_Coverage_Represented := Partial_Coverage_Represented;
      Row.Missing_Checker_Represented := Missing_Checker_Represented;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Authoritative_Result_Used := Authoritative_Result;
      Row.Source_Fingerprint := FP + 1;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 2;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Type_Fingerprint := FP + 3;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Profile_Fingerprint := FP + 4;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 5;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 6;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 7;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Precision_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Precision_Model;
      Area : Audit.Precision_Area;
      Status : Audit.Precision_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Area).Status = Status,
         "unexpected partial-evidence precision audit status");
   end Expect_Status;

   procedure Test_All_Classification_States_Are_Preserved

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Aggregate_Assignment_Predicate,
               Audit.Class_Legal, Audit.Class_Legal,
               Matrix.Family_Aggregates, Matrix.Slice_Aggregate);
      Add_Row (Input, 2, Audit.Area_Generic_Overload_Profile,
               Audit.Class_Illegal, Audit.Class_Illegal,
               Matrix.Family_Calls_Overload_Callable_Profiles,
               Matrix.Slice_Callable_Profile,
               Hard_Diagnostic => True);
      Add_Row (Input, 3, Audit.Area_Type_Profile_Evidence,
               Audit.Class_Legal_With_Runtime_Check,
               Audit.Class_Legal_With_Runtime_Check,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate);
      Add_Row (Input, 4, Audit.Area_View_Cross_Unit_Evidence,
               Audit.Class_Indeterminate, Audit.Class_Indeterminate,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Context_Clause_With_Use,
               State => Remediation.State_Blocked,
               Type_Profile_Complete => False);
      Add_Row (Input, 5, Audit.Area_Flow_Effect_Evidence,
               Audit.Class_Partial_Coverage, Audit.Class_Partial_Coverage,
               Matrix.Family_Contracts_Global_Depends_Flow,
               Matrix.Slice_Flow_Refinement,
               State => Remediation.State_Partial);
      Add_Row (Input, 6, Audit.Area_Representation_Freezing_Evidence,
               Audit.Class_Missing_Checker, Audit.Class_Missing_Checker,
               Matrix.Family_Representation_Aspects_Freezing,
               Matrix.Slice_Unknown,
               State => Remediation.State_Missing);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 6, "expected six precision rows");
      Assert (Results.Invalid_Count = 0, "preserved classifications should be valid");
      Assert (Results.Ready_Count = 6, "all classification states should be ready");
      Assert (Results.Legal_Count = 1, "legal state should be counted");
      Assert (Results.Illegal_Count = 1, "illegal state should be counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check state should be counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate state should be counted");
      Assert (Results.Partial_Coverage_Count = 1, "partial coverage state should be counted");
      Assert (Results.Missing_Checker_Count = 1, "missing checker state should be counted");
      Assert (Audit.False_Positive_False_Negative_Hardened (Results),
              "all precision states should be represented without false diagnostics");
   end Test_All_Classification_States_Are_Preserved;

   procedure Test_Hard_Diagnostic_From_Incomplete_Evidence_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Source_AST_Evidence,
               Audit.Class_Indeterminate, Audit.Class_Indeterminate,
               Source_AST_Complete => False,
               Hard_Diagnostic => True);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Source_AST_Evidence,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Area_Source_AST_Evidence).Blocker_Count >= 2,
         "hard diagnostics from incomplete source/AST evidence should keep both blockers");
   end Test_Hard_Diagnostic_From_Incomplete_Evidence_Is_Rejected;

   procedure Test_Runtime_Check_Cannot_Be_Marked_Illegal

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Aggregate_Assignment_Predicate,
               Audit.Class_Legal_With_Runtime_Check, Audit.Class_Illegal,
               Matrix.Family_Assignments_Conversions,
               Matrix.Slice_Assignment_Conversion);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Aggregate_Assignment_Predicate,
                     Audit.Status_Runtime_Check_Marked_Illegal);
   end Test_Runtime_Check_Cannot_Be_Marked_Illegal;

   procedure Test_Indeterminate_Cannot_Be_Treated_As_Legal_Or_Illegal

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Type_Profile_Evidence,
               Audit.Class_Indeterminate, Audit.Class_Legal);
      Add_Row (Input, 2, Audit.Area_View_Cross_Unit_Evidence,
               Audit.Class_Indeterminate, Audit.Class_Illegal,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Type_Profile_Evidence,
                     Audit.Status_Indeterminate_Treated_As_Legal);
      Expect_Status (Results, Audit.Area_View_Cross_Unit_Evidence,
                     Audit.Status_Indeterminate_Treated_As_Illegal);
   end Test_Indeterminate_Cannot_Be_Treated_As_Legal_Or_Illegal;

   procedure Test_Partial_And_Missing_Cannot_Be_Treated_As_Complete

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Flow_Effect_Evidence,
               Audit.Class_Partial_Coverage, Audit.Class_Legal,
               Matrix.Family_Contracts_Global_Depends_Flow,
               Matrix.Slice_Flow_Refinement,
               State => Remediation.State_Partial);
      Add_Row (Input, 2, Audit.Area_Representation_Freezing_Evidence,
               Audit.Class_Missing_Checker, Audit.Class_Illegal,
               Matrix.Family_Representation_Aspects_Freezing,
               Matrix.Slice_Unknown,
               State => Remediation.State_Missing);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Flow_Effect_Evidence,
                     Audit.Status_Partial_Coverage_Treated_As_Complete);
      Expect_Status (Results, Audit.Area_Representation_Freezing_Evidence,
                     Audit.Status_Missing_Checker_Treated_As_Complete);
   end Test_Partial_And_Missing_Cannot_Be_Treated_As_Complete;

   procedure Test_Complete_Violations_And_Legal_Cases_Are_Not_Hidden

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Generic_Overload_Profile,
               Audit.Class_Illegal, Audit.Class_Legal,
               Matrix.Family_Calls_Overload_Callable_Profiles,
               Matrix.Slice_Overload_Resolution);
      Add_Row (Input, 2, Audit.Area_Tasking_Parallel_Shared_State,
               Audit.Class_Legal, Audit.Class_Illegal,
               Matrix.Family_Tasking_Protected_Synchronized,
               Matrix.Slice_Tasking_Protected);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Generic_Overload_Profile,
                     Audit.Status_Complete_Evidence_Violation_Not_Diagnosed);
      Expect_Status (Results, Audit.Area_Tasking_Parallel_Shared_State,
                     Audit.Status_Legal_Case_Diagnosed);
   end Test_Complete_Violations_And_Legal_Cases_Are_Not_Hidden;

   procedure Test_Stale_Evidence_Cannot_Be_Authoritative

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Consumer_Precision,
               Audit.Class_Legal, Audit.Class_Legal,
               Evidence_Stale => True,
               Authoritative_Result => True);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Consumer_Precision,
                     Audit.Status_Stale_Evidence_Treated_As_Authoritative);
   end Test_Stale_Evidence_Cannot_Be_Authoritative;

   procedure Test_Fingerprint_Mismatches_Block_Precision

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Source_AST_Evidence,
               Audit.Class_Legal, Audit.Class_Legal,
               Expected_Source_FP => 7);
      Add_Row (Input, 2, Audit.Area_Type_Profile_Evidence,
               Audit.Class_Legal, Audit.Class_Legal,
               Expected_Type_FP => 8,
               Expected_Profile_FP => 9);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Source_AST_Evidence,
                     Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, Audit.Area_Type_Profile_Evidence,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Area_Type_Profile_Evidence).Blocker_Count >= 2,
         "type/profile fingerprint mismatches should both be retained");
   end Test_Fingerprint_Mismatches_Block_Precision;

   procedure Test_Consumers_Must_Surface_Blocker_States

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_View_Cross_Unit_Evidence,
               Audit.Class_Indeterminate, Audit.Class_Indeterminate,
               Consumer_Represents_Blocker => False);
      Add_Row (Input, 2, Audit.Area_Flow_Effect_Evidence,
               Audit.Class_Partial_Coverage, Audit.Class_Partial_Coverage,
               State => Remediation.State_Partial,
               Partial_Coverage_Represented => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_View_Cross_Unit_Evidence,
                     Audit.Status_Consumer_Hides_Blocker_State);
      Expect_Status (Results, Audit.Area_Flow_Effect_Evidence,
                     Audit.Status_Consumer_Hides_Blocker_State);
   end Test_Consumers_Must_Surface_Blocker_States;

   procedure Test_Diagnostics_Require_Blocker_Families

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Precision_Input;
      Results : Audit.Precision_Model;
   begin
      Add_Row (Input, 1, Audit.Area_Consumer_Precision,
               Audit.Class_Illegal, Audit.Class_Illegal,
               Hard_Diagnostic => True,
               Blocker_Family => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Area_Consumer_Precision,
                     Audit.Status_Diagnostic_Missing_Blocker_Family);
   end Test_Diagnostics_Require_Blocker_Families;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_All_Classification_States_Are_Preserved'Access,
         "all precision classification states are preserved");
      Register_Routine
        (T, Test_Hard_Diagnostic_From_Incomplete_Evidence_Is_Rejected'Access,
         "hard diagnostic from incomplete evidence is rejected");
      Register_Routine
        (T, Test_Runtime_Check_Cannot_Be_Marked_Illegal'Access,
         "legal-with-runtime-check cannot be marked illegal");
      Register_Routine
        (T, Test_Indeterminate_Cannot_Be_Treated_As_Legal_Or_Illegal'Access,
         "indeterminate evidence cannot be treated as legal or illegal");
      Register_Routine
        (T, Test_Partial_And_Missing_Cannot_Be_Treated_As_Complete'Access,
         "partial and missing coverage cannot be treated as complete");
      Register_Routine
        (T, Test_Complete_Violations_And_Legal_Cases_Are_Not_Hidden'Access,
         "complete violations and legal cases are not hidden");
      Register_Routine
        (T, Test_Stale_Evidence_Cannot_Be_Authoritative'Access,
         "stale evidence cannot be authoritative");
      Register_Routine
        (T, Test_Fingerprint_Mismatches_Block_Precision'Access,
         "fingerprint mismatches block precision");
      Register_Routine
        (T, Test_Consumers_Must_Surface_Blocker_States'Access,
         "consumers must surface blocker states");
      Register_Routine
        (T, Test_Diagnostics_Require_Blocker_Families'Access,
         "diagnostics require semantic blocker families");
   end Register_Tests;

end Test_Ada_Partial_Evidence_Precision_Audit_Pass1341;
