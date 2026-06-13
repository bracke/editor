with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;

package body Test_Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339 is

   package Audit renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Matrix_Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Required_Evidence;
   use type Audit.Remediation_Status;
   use type Audit.Remediation_Item;
   use type Audit.Remediation_Input;
   use type Audit.Remediation_Entry;
   use type Audit.Remediation_Model;
   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   use type Matrix.RM_Family;
   use type Matrix.Implementing_Slice;
   use type Matrix.Coverage_Level;
   use type Matrix.Audit_Status;
   use type Matrix.Coverage_Claim;
   use type Matrix.Slice_Result;
   use type Matrix.Coverage_Matrix;
   use type Matrix.Audit_Entry;
   use type Matrix.Audit_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339");
   end Name;

   function Default_Level (State : Audit.Remediation_State) return Matrix.Coverage_Level is
   begin
      case State is
         when Audit.State_Covered =>
            return Matrix.Coverage_Covered;
         when Audit.State_Partial =>
            return Matrix.Coverage_Partial;
         when Audit.State_Blocked =>
            return Matrix.Coverage_Blocked;
         when Audit.State_Missing | Audit.State_Unknown =>
            return Matrix.Coverage_None;
      end case;
   end Default_Level;

   function Default_Missing_Subrules (State : Audit.Remediation_State) return Natural is
   begin
      if State = Audit.State_Covered then
         return 0;
      else
         return 2;
      end if;
   end Default_Missing_Subrules;

   function Default_Evidence (State : Audit.Remediation_State) return Audit.Required_Evidence is
   begin
      if State = Audit.State_Blocked then
         return Audit.Evidence_Type;
      else
         return Audit.Evidence_None;
      end if;
   end Default_Evidence;

   procedure Add_Item
     (Input : in out Audit.Remediation_Input;
      Id : Natural;
      Family : Audit.RM_Family;
      Owner : Audit.Implementing_Slice;
      State : Audit.Remediation_State := Audit.State_Covered;
      Matrix_Level : Matrix.Coverage_Level := Matrix.Coverage_Unknown;
      Package_Name : String := "Editor.Ada_Test_Remediation_Owner";
      Matrix_Entry : Boolean := True;
      Source_Shaped : Boolean := True;
      Consumed : Boolean := True;
      End_To_End : Boolean := True;
      Missing_Subrules_Named : Boolean := True;
      Missing_Subrule_Count : Natural := Natural'Last;
      Required_Evidence_Absent : Audit.Required_Evidence := Audit.Evidence_Consumer;
      Concrete_Blocker : Boolean := True;
      Traceable_Blocker : Boolean := True;
      Duplicate_Owner : Boolean := False;
      Expected_Remediation_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0) is
      Item : Audit.Remediation_Item;
      FP : constant Natural :=
        1_339_200 + Id * 100 + Matrix.RM_Family'Pos (Family) + Matrix.Implementing_Slice'Pos (Owner);
      Effective_Level : constant Matrix.Coverage_Level :=
        (if Matrix_Level = Matrix.Coverage_Unknown and then State /= Audit.State_Missing
         then Default_Level (State)
         else Matrix_Level);
      Effective_Count : constant Natural :=
        (if Missing_Subrule_Count = Natural'Last
         then Default_Missing_Subrules (State)
         else Missing_Subrule_Count);
      Effective_Evidence : constant Audit.Required_Evidence :=
        (if Required_Evidence_Absent = Audit.Evidence_Consumer
         then Default_Evidence (State)
         else Required_Evidence_Absent);
   begin
      Item.Id := Id;
      Item.Family := Family;
      Item.Owner := Owner;
      Item.State := State;
      Item.Matrix_Level := Effective_Level;
      Item.Name := To_Unbounded_String ("source-shaped RM remediation row" & Natural'Image (Id));
      Item.Implementing_Package := To_Unbounded_String (Package_Name);
      Item.Node := Editor.Ada_Syntax_Tree.Node_Id (1_339_000 + Id);
      Item.Matrix_Entry_Present := Matrix_Entry;
      Item.Source_Shaped_Evidence := Source_Shaped;
      Item.Semantic_Result_Consumed := Consumed;
      Item.End_To_End_Consumed := End_To_End;
      Item.Missing_Subrules_Named := Missing_Subrules_Named;
      Item.Missing_Subrule_Count := Effective_Count;
      Item.Required_Evidence_Absent := Effective_Evidence;
      Item.Concrete_Blocker_Family := Concrete_Blocker;
      Item.Blocker_Source_Traceable := Traceable_Blocker;
      Item.Duplicate_Ownership := Duplicate_Owner;
      Item.Remediation_Fingerprint := FP + 1;
      Item.Expected_Remediation_Fingerprint :=
        (if Expected_Remediation_FP = 0 then Item.Remediation_Fingerprint else Expected_Remediation_FP);
      Item.Source_Fingerprint := FP + 2;
      Item.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Item.Source_Fingerprint else Expected_Source_FP);
      Item.AST_Fingerprint := FP + 3;
      Item.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Item.AST_Fingerprint else Expected_AST_FP);
      Item.Type_Fingerprint := FP + 4;
      Item.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Item.Type_Fingerprint else Expected_Type_FP);
      Item.Profile_Fingerprint := FP + 5;
      Item.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Item.Profile_Fingerprint else Expected_Profile_FP);
      Item.Substitution_Fingerprint := FP + 6;
      Item.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Item.Substitution_Fingerprint else Expected_Substitution_FP);
      Item.Effect_Fingerprint := FP + 7;
      Item.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Item.Effect_Fingerprint else Expected_Effect_FP);
      Audit.Add_Remediation_Item (Input, Item);
   end Add_Item;

   procedure Add_All_Covered_Remediation (Input : in out Audit.Remediation_Input) is
   begin
      Add_Item (Input, 1, Matrix.Family_Declarations_Completions,
                Matrix.Slice_Body_Spec_Conformance,
                Package_Name => "Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality");
      Add_Item (Input, 2, Matrix.Family_Names_Visibility_Selected_Attributes,
                Matrix.Slice_Visibility_Name_Resolution,
                Package_Name => "Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality");
      Add_Item (Input, 3, Matrix.Family_Types_Subtypes_Constraints_Predicates,
                Matrix.Slice_Subtype_Range_Predicate,
                Package_Name => "Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality");
      Add_Item (Input, 4, Matrix.Family_Expressions_Expected_Type_Resolution,
                Matrix.Slice_Ada2022_Expression_Type_Resolution,
                Package_Name => "Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality");
      Add_Item (Input, 5, Matrix.Family_Aggregates,
                Matrix.Slice_Aggregate,
                Package_Name => "Editor.Ada_Aggregate_Legality_Vertical_Slice");
      Add_Item (Input, 6, Matrix.Family_Assignments_Conversions,
                Matrix.Slice_Assignment_Conversion,
                Package_Name => "Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality");
      Add_Item (Input, 7, Matrix.Family_Calls_Overload_Callable_Profiles,
                Matrix.Slice_Callable_Profile,
                Package_Name => "Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality");
      Add_Item (Input, 8, Matrix.Family_Generics_Contracts_Substitution_Replay,
                Matrix.Slice_Generic_Body_Replay,
                Package_Name => "Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality");
      Add_Item (Input, 9, Matrix.Family_Tagged_Interfaces_Dispatching,
                Matrix.Slice_Interface_Synchronized,
                Package_Name => "Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality");
      Add_Item (Input, 10, Matrix.Family_Arrays_Records_Discriminants_Variants,
                Matrix.Slice_Discriminant_Variant_Record,
                Package_Name => "Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality");
      Add_Item (Input, 11, Matrix.Family_Access_Types_Accessibility,
                Matrix.Slice_Access_Type_Access_Subprogram,
                Package_Name => "Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality");
      Add_Item (Input, 12, Matrix.Family_Tasking_Protected_Synchronized,
                Matrix.Slice_Tasking_Protected,
                Package_Name => "Editor.Ada_Tasking_Protected_Vertical_Slice_Legality");
      Add_Item (Input, 13, Matrix.Family_Exceptions_Finalization,
                Matrix.Slice_Exception_Finalization,
                Package_Name => "Editor.Ada_Exception_Finalization_Vertical_Slice_Legality");
      Add_Item (Input, 14, Matrix.Family_Representation_Aspects_Freezing,
                Matrix.Slice_Representation_Aspect_Operational,
                Package_Name => "Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality");
      Add_Item (Input, 15, Matrix.Family_Library_Context_Subunits_Elaboration,
                Matrix.Slice_Library_Unit_Subunit,
                Package_Name => "Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality");
      Add_Item (Input, 16, Matrix.Family_Contracts_Global_Depends_Flow,
                Matrix.Slice_Contract_Aspect,
                Package_Name => "Editor.Ada_Contract_Aspect_Vertical_Slice_Legality");
      Add_Item (Input, 17, Matrix.Family_Interfacing_Import_Export,
                Matrix.Slice_Interfacing_Import_Export,
                Package_Name => "Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality");
      Add_Item (Input, 18, Matrix.Family_Iterators_Parallel_Reductions,
                Matrix.Slice_Iterator_Loop_Parallel,
                Package_Name => "Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality");
      Add_Item (Input, 19, Matrix.Family_Static_Expressions_Choices,
                Matrix.Slice_Numeric_Static_Expression,
                Package_Name => "Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality");
      Add_Item (Input, 20, Matrix.Family_Diagnostics_Consumer_Readiness,
                Matrix.Slice_End_To_End_Scenario_Audit,
                Package_Name => "Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337");
   end Add_All_Covered_Remediation;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Family : Audit.RM_Family;
      Status : Audit.Remediation_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Family).Status = Status,
         "unexpected RM remediation status");
   end Expect_Status;

   procedure Test_All_Covered_Families_Are_Final_Ready

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_All_Covered_Remediation (Input);
      Results := Audit.Build (Input);

      Assert (Results.Total_Families = 20, "expected twenty RM remediation families");
      Assert (Audit.Count (Results) = 20, "covered remediation matrix should have one row per family");
      Assert (Results.Covered_Count = 20, "all remediation families should be covered");
      Assert (Results.Invalid_Count = 0, "covered remediation matrix should have no invalid rows");
      Assert (not Audit.Actionable_Gaps_Present (Results), "covered remediation should have no gaps");
      Assert (Audit.Coverage_Gap_Remediation_Audit_Valid (Results), "covered remediation matrix should be valid");
      Assert (Audit.RM_Gaps_Remediated (Results), "all RM gaps should be remediated");
      Expect_Status (Results, Matrix.Family_Aggregates, Audit.Status_Covered);
   end Test_All_Covered_Families_Are_Final_Ready;

   procedure Test_Actionable_Partial_Blocked_And_Missing_Gaps_Are_Valid

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Declarations_Completions,
                Matrix.Slice_Body_Spec_Conformance);
      Add_Item (Input, 2, Matrix.Family_Names_Visibility_Selected_Attributes,
                Matrix.Slice_Visibility_Name_Resolution);
      Add_Item (Input, 3, Matrix.Family_Types_Subtypes_Constraints_Predicates,
                Matrix.Slice_Subtype_Range_Predicate);
      Add_Item (Input, 4, Matrix.Family_Expressions_Expected_Type_Resolution,
                Matrix.Slice_Ada2022_Expression_Type_Resolution);
      Add_Item (Input, 5, Matrix.Family_Aggregates, Matrix.Slice_Aggregate,
                State => Audit.State_Partial,
                Matrix_Level => Matrix.Coverage_Partial,
                Missing_Subrule_Count => 3,
                Required_Evidence_Absent => Audit.Evidence_Source);
      Add_Item (Input, 6, Matrix.Family_Assignments_Conversions,
                Matrix.Slice_Assignment_Conversion,
                State => Audit.State_Blocked,
                Matrix_Level => Matrix.Coverage_Blocked,
                Missing_Subrule_Count => 1,
                Required_Evidence_Absent => Audit.Evidence_Type);
      Add_Item (Input, 7, Matrix.Family_Calls_Overload_Callable_Profiles,
                Matrix.Slice_Callable_Profile);
      Add_Item (Input, 8, Matrix.Family_Generics_Contracts_Substitution_Replay,
                Matrix.Slice_Generic_Body_Replay);
      Add_Item (Input, 9, Matrix.Family_Tagged_Interfaces_Dispatching,
                Matrix.Slice_Interface_Synchronized);
      Add_Item (Input, 10, Matrix.Family_Arrays_Records_Discriminants_Variants,
                Matrix.Slice_Discriminant_Variant_Record);
      Add_Item (Input, 11, Matrix.Family_Access_Types_Accessibility,
                Matrix.Slice_Access_Type_Access_Subprogram);
      Add_Item (Input, 12, Matrix.Family_Tasking_Protected_Synchronized,
                Matrix.Slice_Tasking_Protected);
      Add_Item (Input, 13, Matrix.Family_Exceptions_Finalization,
                Matrix.Slice_Exception_Finalization);
      Add_Item (Input, 14, Matrix.Family_Representation_Aspects_Freezing,
                Matrix.Slice_Representation_Aspect_Operational);
      Add_Item (Input, 15, Matrix.Family_Library_Context_Subunits_Elaboration,
                Matrix.Slice_Library_Unit_Subunit);
      Add_Item (Input, 16, Matrix.Family_Contracts_Global_Depends_Flow,
                Matrix.Slice_Contract_Aspect);
      Add_Item (Input, 17, Matrix.Family_Interfacing_Import_Export,
                Matrix.Slice_Interfacing_Import_Export,
                State => Audit.State_Missing,
                Matrix_Level => Matrix.Coverage_None,
                Package_Name => "Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality",
                Missing_Subrule_Count => 2);
      Add_Item (Input, 18, Matrix.Family_Iterators_Parallel_Reductions,
                Matrix.Slice_Iterator_Loop_Parallel);
      Add_Item (Input, 19, Matrix.Family_Static_Expressions_Choices,
                Matrix.Slice_Numeric_Static_Expression);
      Add_Item (Input, 20, Matrix.Family_Diagnostics_Consumer_Readiness,
                Matrix.Slice_End_To_End_Scenario_Audit);

      Results := Audit.Build (Input);

      Assert (Audit.Coverage_Gap_Remediation_Audit_Valid (Results), "actionable gaps should still form a valid remediation matrix");
      Assert (not Audit.RM_Gaps_Remediated (Results), "partial/blocked/missing rows are not final readiness");
      Assert (Audit.Actionable_Gaps_Present (Results), "actionable gaps should be visible");
      Assert (Results.Partial_Count = 1, "one partial gap expected");
      Assert (Results.Blocked_Count = 1, "one blocked gap expected");
      Assert (Results.Missing_Count = 1, "one missing gap expected");
      Expect_Status (Results, Matrix.Family_Aggregates, Audit.Status_Partial_Actionable);
      Expect_Status (Results, Matrix.Family_Assignments_Conversions, Audit.Status_Blocked_Actionable);
      Expect_Status (Results, Matrix.Family_Interfacing_Import_Export, Audit.Status_Missing_Actionable);
   end Test_Actionable_Partial_Blocked_And_Missing_Gaps_Are_Valid;

   procedure Test_Vague_Partial_Without_Named_Subrules_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Aggregates, Matrix.Slice_Aggregate,
                State => Audit.State_Partial,
                Matrix_Level => Matrix.Coverage_Partial,
                Missing_Subrules_Named => False,
                Missing_Subrule_Count => 2);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Aggregates, Audit.Status_Vague_Partial);
      Assert (Results.Invalid_Count >= 1, "vague partial gap should invalidate remediation audit");
   end Test_Vague_Partial_Without_Named_Subrules_Is_Rejected;

   procedure Test_Duplicate_Remediation_Ownership_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Aggregates, Matrix.Slice_Aggregate);
      Add_Item (Input, 2, Matrix.Family_Aggregates, Matrix.Slice_Array_Container_Indexing);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Aggregates, Audit.Status_Duplicate_Remediation_Owner);
      Assert (Results.Invalid_Count >= 1, "duplicate remediation owner should invalidate audit");
   end Test_Duplicate_Remediation_Ownership_Is_Rejected;

   procedure Test_Missing_Implementing_Package_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Calls_Overload_Callable_Profiles,
                Matrix.Slice_Callable_Profile,
                Package_Name => "");

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Calls_Overload_Callable_Profiles,
                     Audit.Status_Missing_Implementing_Package);
   end Test_Missing_Implementing_Package_Is_Rejected;

   procedure Test_Stale_Remediation_And_Evidence_Fingerprints_Block

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Types_Subtypes_Constraints_Predicates,
                Matrix.Slice_Subtype_Range_Predicate,
                Expected_Remediation_FP => 7,
                Expected_Source_FP => 8,
                Expected_Type_FP => 9);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Types_Subtypes_Constraints_Predicates,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Matrix.Family_Types_Subtypes_Constraints_Predicates).Blocker_Count >= 3,
         "stale remediation/source/type fingerprints should all be retained");
   end Test_Stale_Remediation_And_Evidence_Fingerprints_Block;

   procedure Test_Untraceable_Blocker_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Assignments_Conversions,
                Matrix.Slice_Assignment_Conversion,
                State => Audit.State_Blocked,
                Matrix_Level => Matrix.Coverage_Blocked,
                Missing_Subrule_Count => 1,
                Required_Evidence_Absent => Audit.Evidence_Type,
                Traceable_Blocker => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Assignments_Conversions,
                     Audit.Status_Untraceable_Blocker);
   end Test_Untraceable_Blocker_Is_Rejected;

   procedure Test_Covered_Row_Must_Be_Consumed_End_To_End

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Add_Item (Input, 1, Matrix.Family_Generics_Contracts_Substitution_Replay,
                Matrix.Slice_Generic_Body_Replay,
                End_To_End => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, Matrix.Family_Generics_Contracts_Substitution_Replay,
                     Audit.Status_Unconsumed_End_To_End_Result);
   end Test_Covered_Row_Must_Be_Consumed_End_To_End;

   procedure Test_Missing_Remediation_Entries_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
   begin
      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 20, "empty remediation input should emit one missing row per RM family");
      Assert (Results.Invalid_Count = 20, "every missing remediation entry should be invalid");
      Expect_Status (Results, Matrix.Family_Aggregates, Audit.Status_Missing_Remediation_Entry);
      Assert (not Audit.Coverage_Gap_Remediation_Audit_Valid (Results), "missing entries reject audit validity");
   end Test_Missing_Remediation_Entries_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_All_Covered_Families_Are_Final_Ready'Access,
         "all covered families are final ready");
      Register_Routine
        (T, Test_Actionable_Partial_Blocked_And_Missing_Gaps_Are_Valid'Access,
         "actionable partial blocked and missing gaps are valid but not final");
      Register_Routine
        (T, Test_Vague_Partial_Without_Named_Subrules_Is_Rejected'Access,
         "vague partial without named subrules is rejected");
      Register_Routine
        (T, Test_Duplicate_Remediation_Ownership_Is_Rejected'Access,
         "duplicate remediation ownership is rejected");
      Register_Routine
        (T, Test_Missing_Implementing_Package_Is_Rejected'Access,
         "missing implementing package is rejected");
      Register_Routine
        (T, Test_Stale_Remediation_And_Evidence_Fingerprints_Block'Access,
         "stale remediation and evidence fingerprints block");
      Register_Routine
        (T, Test_Untraceable_Blocker_Is_Rejected'Access,
         "untraceable blocker is rejected");
      Register_Routine
        (T, Test_Covered_Row_Must_Be_Consumed_End_To_End'Access,
         "covered row must be consumed end to end");
      Register_Routine
        (T, Test_Missing_Remediation_Entries_Are_Rejected'Access,
         "missing remediation entries are rejected");
   end Register_Tests;

end Test_Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
