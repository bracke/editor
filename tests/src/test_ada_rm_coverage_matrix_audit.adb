with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;

package body Test_Ada_RM_Coverage_Matrix_Audit is

   package Audit renames Editor.Ada_RM_Coverage_Matrix_Audit;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Audit_Status;
   use type Audit.Coverage_Claim;
   use type Audit.Slice_Result;
   use type Audit.Coverage_Matrix;
   use type Audit.Audit_Entry;
   use type Audit.Audit_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Coverage_Matrix_Audit");
   end Name;

   procedure Add_Slice
     (Matrix : in out Audit.Coverage_Matrix;
      Slice : Audit.Implementing_Slice;
      Present : Boolean := True;
      Expected_Result_FP : Natural := 0) is
      R : Audit.Slice_Result;
      FP : constant Natural := 1_338_100 + Audit.Implementing_Slice'Pos (Slice);
   begin
      R.Slice := Slice;
      R.Present := Present;
      R.Result_Fingerprint := FP;
      R.Expected_Result_Fingerprint :=
        (if Expected_Result_FP = 0 then R.Result_Fingerprint else Expected_Result_FP);
      Audit.Add_Slice_Result (Matrix, R);
   end Add_Slice;

   procedure Add_Claim
     (Matrix : in out Audit.Coverage_Matrix;
      Id : Natural;
      Family : Audit.RM_Family;
      Slice : Audit.Implementing_Slice;
      Level : Audit.Coverage_Level := Audit.Coverage_Covered;
      Source_Shaped : Boolean := True;
      Consumed : Boolean := True;
      Concrete_Evidence : Boolean := True;
      Generic_Claim : Boolean := False;
      Conflict : Boolean := False;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0) is
      C : Audit.Coverage_Claim;
      FP : constant Natural :=
        1_338_500 + Id * 100 + Audit.RM_Family'Pos (Family) + Audit.Implementing_Slice'Pos (Slice);
   begin
      C.Id := Id;
      C.Family := Family;
      C.Slice := Slice;
      C.Level := Level;
      C.Name := To_Unbounded_String
        ("source-shaped RM family coverage claim" & Natural'Image (Id));
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (1_338_000 + Id);
      C.Source_Shaped_Test_Present := Source_Shaped;
      C.Semantic_Result_Consumed := Consumed;
      C.Concrete_Rule_Family_Evidence := Concrete_Evidence;
      C.Claims_Generic_Compiler_Grade := Generic_Claim;
      C.Conflicts_With_Existing_Claim := Conflict;
      C.Source_Fingerprint := FP + 1;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then C.Source_Fingerprint else Expected_Source_FP);
      C.AST_Fingerprint := FP + 2;
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then C.AST_Fingerprint else Expected_AST_FP);
      C.Type_Fingerprint := FP + 3;
      C.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then C.Type_Fingerprint else Expected_Type_FP);
      C.Profile_Fingerprint := FP + 4;
      C.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then C.Profile_Fingerprint else Expected_Profile_FP);
      C.Substitution_Fingerprint := FP + 5;
      C.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then C.Substitution_Fingerprint else Expected_Substitution_FP);
      C.Effect_Fingerprint := FP + 6;
      C.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then C.Effect_Fingerprint else Expected_Effect_FP);
      Audit.Add_Coverage_Claim (Matrix, C);
   end Add_Claim;

   procedure Add_All_Covered_Matrix (Matrix : in out Audit.Coverage_Matrix) is
   begin
      Add_Slice (Matrix, Audit.Slice_Body_Spec_Conformance);
      Add_Slice (Matrix, Audit.Slice_Visibility_Name_Resolution);
      Add_Slice (Matrix, Audit.Slice_Selected_Name_Attribute);
      Add_Slice (Matrix, Audit.Slice_Subtype_Range_Predicate);
      Add_Slice (Matrix, Audit.Slice_Ada2022_Expression_Type_Resolution);
      Add_Slice (Matrix, Audit.Slice_Numeric_Static_Expression);
      Add_Slice (Matrix, Audit.Slice_Membership_Case_Choice);
      Add_Slice (Matrix, Audit.Slice_Aggregate);
      Add_Slice (Matrix, Audit.Slice_Assignment_Conversion);
      Add_Slice (Matrix, Audit.Slice_Overload_Resolution);
      Add_Slice (Matrix, Audit.Slice_Callable_Profile);
      Add_Slice (Matrix, Audit.Slice_Generic_Contract_Body);
      Add_Slice (Matrix, Audit.Slice_Generic_Formal_Type_Family);
      Add_Slice (Matrix, Audit.Slice_Generic_Body_Replay);
      Add_Slice (Matrix, Audit.Slice_Tagged_Dispatching);
      Add_Slice (Matrix, Audit.Slice_Interface_Synchronized);
      Add_Slice (Matrix, Audit.Slice_Array_Container_Indexing);
      Add_Slice (Matrix, Audit.Slice_Discriminant_Variant_Record);
      Add_Slice (Matrix, Audit.Slice_Access_Type_Access_Subprogram);
      Add_Slice (Matrix, Audit.Slice_Accessibility_Lifetime);
      Add_Slice (Matrix, Audit.Slice_Tasking_Protected);
      Add_Slice (Matrix, Audit.Slice_Exception_Finalization);
      Add_Slice (Matrix, Audit.Slice_Freezing_Representation);
      Add_Slice (Matrix, Audit.Slice_Representation_Aspect_Operational);
      Add_Slice (Matrix, Audit.Slice_Record_Layout_Representation);
      Add_Slice (Matrix, Audit.Slice_Enumeration_Representation);
      Add_Slice (Matrix, Audit.Slice_Context_Clause_With_Use);
      Add_Slice (Matrix, Audit.Slice_Library_Unit_Subunit);
      Add_Slice (Matrix, Audit.Slice_Elaboration);
      Add_Slice (Matrix, Audit.Slice_Contract_Aspect);
      Add_Slice (Matrix, Audit.Slice_Abstract_State_Global_Depends);
      Add_Slice (Matrix, Audit.Slice_Flow_Refinement);
      Add_Slice (Matrix, Audit.Slice_Interfacing_Import_Export);
      Add_Slice (Matrix, Audit.Slice_Iterator_Loop_Parallel);
      Add_Slice (Matrix, Audit.Slice_Parser_AST_Coverage);
      Add_Slice (Matrix, Audit.Slice_Semantic_Integration_Audit);
      Add_Slice (Matrix, Audit.Slice_Canonical_Model_Agreement_Audit);
      Add_Slice (Matrix, Audit.Slice_End_To_End_Scenario_Audit);
      Add_Slice (Matrix, Audit.Slice_Diagnostics_Consumer);

      Add_Claim (Matrix, 1, Audit.Family_Declarations_Completions,
                 Audit.Slice_Body_Spec_Conformance);
      Add_Claim (Matrix, 2, Audit.Family_Names_Visibility_Selected_Attributes,
                 Audit.Slice_Visibility_Name_Resolution);
      Add_Claim (Matrix, 3, Audit.Family_Names_Visibility_Selected_Attributes,
                 Audit.Slice_Selected_Name_Attribute);
      Add_Claim (Matrix, 4, Audit.Family_Types_Subtypes_Constraints_Predicates,
                 Audit.Slice_Subtype_Range_Predicate);
      Add_Claim (Matrix, 5, Audit.Family_Expressions_Expected_Type_Resolution,
                 Audit.Slice_Ada2022_Expression_Type_Resolution);
      Add_Claim (Matrix, 6, Audit.Family_Expressions_Expected_Type_Resolution,
                 Audit.Slice_Parser_AST_Coverage);
      Add_Claim (Matrix, 7, Audit.Family_Aggregates,
                 Audit.Slice_Aggregate);
      Add_Claim (Matrix, 8, Audit.Family_Assignments_Conversions,
                 Audit.Slice_Assignment_Conversion);
      Add_Claim (Matrix, 9, Audit.Family_Calls_Overload_Callable_Profiles,
                 Audit.Slice_Overload_Resolution);
      Add_Claim (Matrix, 10, Audit.Family_Calls_Overload_Callable_Profiles,
                 Audit.Slice_Callable_Profile);
      Add_Claim (Matrix, 11, Audit.Family_Generics_Contracts_Substitution_Replay,
                 Audit.Slice_Generic_Contract_Body);
      Add_Claim (Matrix, 12, Audit.Family_Generics_Contracts_Substitution_Replay,
                 Audit.Slice_Generic_Formal_Type_Family);
      Add_Claim (Matrix, 13, Audit.Family_Generics_Contracts_Substitution_Replay,
                 Audit.Slice_Generic_Body_Replay);
      Add_Claim (Matrix, 14, Audit.Family_Tagged_Interfaces_Dispatching,
                 Audit.Slice_Tagged_Dispatching);
      Add_Claim (Matrix, 15, Audit.Family_Tagged_Interfaces_Dispatching,
                 Audit.Slice_Interface_Synchronized);
      Add_Claim (Matrix, 16, Audit.Family_Arrays_Records_Discriminants_Variants,
                 Audit.Slice_Array_Container_Indexing);
      Add_Claim (Matrix, 17, Audit.Family_Arrays_Records_Discriminants_Variants,
                 Audit.Slice_Discriminant_Variant_Record);
      Add_Claim (Matrix, 18, Audit.Family_Access_Types_Accessibility,
                 Audit.Slice_Access_Type_Access_Subprogram);
      Add_Claim (Matrix, 19, Audit.Family_Access_Types_Accessibility,
                 Audit.Slice_Accessibility_Lifetime);
      Add_Claim (Matrix, 20, Audit.Family_Tasking_Protected_Synchronized,
                 Audit.Slice_Tasking_Protected);
      Add_Claim (Matrix, 21, Audit.Family_Exceptions_Finalization,
                 Audit.Slice_Exception_Finalization);
      Add_Claim (Matrix, 22, Audit.Family_Representation_Aspects_Freezing,
                 Audit.Slice_Freezing_Representation);
      Add_Claim (Matrix, 23, Audit.Family_Representation_Aspects_Freezing,
                 Audit.Slice_Representation_Aspect_Operational);
      Add_Claim (Matrix, 24, Audit.Family_Representation_Aspects_Freezing,
                 Audit.Slice_Record_Layout_Representation);
      Add_Claim (Matrix, 25, Audit.Family_Representation_Aspects_Freezing,
                 Audit.Slice_Enumeration_Representation);
      Add_Claim (Matrix, 26, Audit.Family_Library_Context_Subunits_Elaboration,
                 Audit.Slice_Context_Clause_With_Use);
      Add_Claim (Matrix, 27, Audit.Family_Library_Context_Subunits_Elaboration,
                 Audit.Slice_Library_Unit_Subunit);
      Add_Claim (Matrix, 28, Audit.Family_Library_Context_Subunits_Elaboration,
                 Audit.Slice_Elaboration);
      Add_Claim (Matrix, 29, Audit.Family_Contracts_Global_Depends_Flow,
                 Audit.Slice_Contract_Aspect);
      Add_Claim (Matrix, 30, Audit.Family_Contracts_Global_Depends_Flow,
                 Audit.Slice_Abstract_State_Global_Depends);
      Add_Claim (Matrix, 31, Audit.Family_Contracts_Global_Depends_Flow,
                 Audit.Slice_Flow_Refinement);
      Add_Claim (Matrix, 32, Audit.Family_Interfacing_Import_Export,
                 Audit.Slice_Interfacing_Import_Export);
      Add_Claim (Matrix, 33, Audit.Family_Iterators_Parallel_Reductions,
                 Audit.Slice_Iterator_Loop_Parallel);
      Add_Claim (Matrix, 34, Audit.Family_Static_Expressions_Choices,
                 Audit.Slice_Numeric_Static_Expression);
      Add_Claim (Matrix, 35, Audit.Family_Static_Expressions_Choices,
                 Audit.Slice_Membership_Case_Choice);
      Add_Claim (Matrix, 36, Audit.Family_Diagnostics_Consumer_Readiness,
                 Audit.Slice_Semantic_Integration_Audit);
      Add_Claim (Matrix, 37, Audit.Family_Diagnostics_Consumer_Readiness,
                 Audit.Slice_Canonical_Model_Agreement_Audit);
      Add_Claim (Matrix, 38, Audit.Family_Diagnostics_Consumer_Readiness,
                 Audit.Slice_End_To_End_Scenario_Audit);
      Add_Claim (Matrix, 39, Audit.Family_Diagnostics_Consumer_Readiness,
                 Audit.Slice_Diagnostics_Consumer);
   end Add_All_Covered_Matrix;

   procedure Expect_Status
     (Results : Audit.Audit_Model;
      Family : Audit.RM_Family;
      Status : Audit.Audit_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Family).Status = Status,
         "unexpected RM coverage matrix audit status");
   end Expect_Status;

   procedure Test_All_RM_Families_Covered_By_Source_Shaped_Semantics

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_All_Covered_Matrix (Matrix);

      Results := Audit.Build (Matrix);

      Assert (Results.Total_Families = 20, "expected twenty concrete RM families");
      Assert (Audit.Count (Results) = 20, "ready matrix should only contain family entries");
      Assert (Results.Covered_Count = 20, "every RM family should be covered");
      Assert (Results.Blocked_Count = 0, "no RM family should be blocked");
      Assert (Results.Unclaimed_Slice_Count = 0, "every present slice should be claimed by an RM family");
      Assert (Audit.RM_Coverage_Audit_Ready (Results), "RM coverage matrix should be ready");
      Expect_Status (Results, Audit.Family_Aggregates, Audit.Status_Covered);
      Expect_Status (Results, Audit.Family_Diagnostics_Consumer_Readiness, Audit.Status_Covered);
   end Test_All_RM_Families_Covered_By_Source_Shaped_Semantics;

   procedure Test_Covered_Family_Without_Implementing_Slice_Blocks

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Claim (Matrix, 1, Audit.Family_Aggregates, Audit.Slice_Aggregate);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Aggregates, Audit.Status_Missing_Implementing_Slice);
      Assert
        (Audit.Result_For (Results, Audit.Family_Aggregates).Slice = Audit.Slice_Aggregate,
         "missing aggregate slice must be named as blocker");
      Assert (not Audit.RM_Coverage_Audit_Ready (Results), "missing implementing slice must reject matrix");
   end Test_Covered_Family_Without_Implementing_Slice_Blocks;

   procedure Test_Unclaimed_Slice_Result_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Aggregate);

      Results := Audit.Build (Matrix);

      Assert (Results.Unclaimed_Slice_Count = 1, "present aggregate slice should be reported as unclaimed");
      Assert
        (Audit.Result_At (Results, Audit.Count (Results)).Status = Audit.Status_Slice_Unclaimed,
         "unclaimed slice result should append a rejecting audit entry");
      Assert
        (Audit.Result_At (Results, Audit.Count (Results)).Slice = Audit.Slice_Aggregate,
         "unclaimed aggregate slice should retain identity");
   end Test_Unclaimed_Slice_Result_Is_Rejected;

   procedure Test_Duplicate_And_Conflicting_Claims_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Aggregate);
      Add_Slice (Matrix, Audit.Slice_Assignment_Conversion);
      Add_Claim (Matrix, 1, Audit.Family_Aggregates, Audit.Slice_Aggregate);
      Add_Claim (Matrix, 2, Audit.Family_Aggregates, Audit.Slice_Aggregate);
      Add_Claim (Matrix, 3, Audit.Family_Assignments_Conversions,
                 Audit.Slice_Assignment_Conversion);
      Add_Claim (Matrix, 4, Audit.Family_Assignments_Conversions,
                 Audit.Slice_Assignment_Conversion,
                 Level => Audit.Coverage_None,
                 Conflict => True);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Aggregates, Audit.Status_Duplicate_Coverage_Claim);
      Expect_Status (Results, Audit.Family_Assignments_Conversions, Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Family_Assignments_Conversions).Blocker_Count >= 2,
         "conflicting and duplicate assignment/conversion claims should both be retained");
   end Test_Duplicate_And_Conflicting_Claims_Are_Rejected;

   procedure Test_Covered_Family_Requires_Source_Shaped_Consumed_Result

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Overload_Resolution);
      Add_Claim (Matrix, 1, Audit.Family_Calls_Overload_Callable_Profiles,
                 Audit.Slice_Overload_Resolution,
                 Source_Shaped => False,
                 Consumed => False);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Calls_Overload_Callable_Profiles,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Family_Calls_Overload_Callable_Profiles).Blocker_Count >= 2,
         "covered call/overload family should need source-shaped tests and consumed result");
   end Test_Covered_Family_Requires_Source_Shaped_Consumed_Result;

   procedure Test_Stale_Fingerprints_Block_Coverage

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Subtype_Range_Predicate);
      Add_Claim (Matrix, 1, Audit.Family_Types_Subtypes_Constraints_Predicates,
                 Audit.Slice_Subtype_Range_Predicate,
                 Expected_Source_FP => 7,
                 Expected_Type_FP => 8,
                 Expected_Effect_FP => 9);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Types_Subtypes_Constraints_Predicates,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Family_Types_Subtypes_Constraints_Predicates).Blocker_Count >= 3,
         "source, type, and effect fingerprint mismatches should all block coverage");
   end Test_Stale_Fingerprints_Block_Coverage;

   procedure Test_Generic_Compiler_Grade_Claim_Without_Rule_Evidence_Blocks

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Generic_Body_Replay);
      Add_Claim (Matrix, 1, Audit.Family_Generics_Contracts_Substitution_Replay,
                 Audit.Slice_Generic_Body_Replay,
                 Concrete_Evidence => False,
                 Generic_Claim => True);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Generics_Contracts_Substitution_Replay,
                     Audit.Status_Generic_Compiler_Grade_Claim);
      Assert
        (Audit.Result_For (Results, Audit.Family_Generics_Contracts_Substitution_Replay).Blocker_Count >= 1,
         "generic compiler-grade coverage claim must have concrete rule-family evidence");
   end Test_Generic_Compiler_Grade_Claim_Without_Rule_Evidence_Blocks;

   procedure Test_Partial_Coverage_Is_Visible_But_Not_Ready

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Matrix : Audit.Coverage_Matrix;
      Results : Audit.Audit_Model;
   begin
      Add_Slice (Matrix, Audit.Slice_Interfacing_Import_Export);
      Add_Claim (Matrix, 1, Audit.Family_Interfacing_Import_Export,
                 Audit.Slice_Interfacing_Import_Export,
                 Level => Audit.Coverage_Partial);

      Results := Audit.Build (Matrix);

      Expect_Status (Results, Audit.Family_Interfacing_Import_Export, Audit.Status_Partial);
      Assert (Results.Partial_Count = 1, "partial RM family should be counted explicitly");
      Assert (not Audit.RM_Coverage_Audit_Ready (Results), "partial coverage is not final readiness");
   end Test_Partial_Coverage_Is_Visible_But_Not_Ready;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_All_RM_Families_Covered_By_Source_Shaped_Semantics'Access,
         "all RM families covered by source-shaped semantic evidence");
      Register_Routine
        (T, Test_Covered_Family_Without_Implementing_Slice_Blocks'Access,
         "covered family without implementing slice blocks");
      Register_Routine
        (T, Test_Unclaimed_Slice_Result_Is_Rejected'Access,
         "unclaimed slice result is rejected");
      Register_Routine
        (T, Test_Duplicate_And_Conflicting_Claims_Are_Rejected'Access,
         "duplicate and conflicting coverage claims are rejected");
      Register_Routine
        (T, Test_Covered_Family_Requires_Source_Shaped_Consumed_Result'Access,
         "covered family requires source-shaped test and consumed result");
      Register_Routine
        (T, Test_Stale_Fingerprints_Block_Coverage'Access,
         "stale coverage fingerprints block matrix");
      Register_Routine
        (T, Test_Generic_Compiler_Grade_Claim_Without_Rule_Evidence_Blocks'Access,
         "generic compiler-grade claim without rule evidence blocks");
      Register_Routine
        (T, Test_Partial_Coverage_Is_Visible_But_Not_Ready'Access,
         "partial coverage visible but not ready");
   end Register_Tests;

end Test_Ada_RM_Coverage_Matrix_Audit;
