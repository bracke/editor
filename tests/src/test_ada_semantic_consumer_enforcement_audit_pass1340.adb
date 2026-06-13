with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;

package body Test_Ada_Semantic_Consumer_Enforcement_Audit_Pass1340 is

   package Audit renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Consumer_Status;
   use type Audit.Consumer_Row;
   use type Audit.Consumer_Input;
   use type Audit.Consumer_Entry;
   use type Audit.Consumer_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Semantic_Consumer_Enforcement_Audit_Pass1340");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Consumer_Input;
      Id : Natural;
      Consumer : Audit.Semantic_Consumer;
      Family : Audit.RM_Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Slice : Audit.Implementing_Slice := Matrix.Slice_End_To_End_Scenario_Audit;
      State : Audit.Remediation_State := Remediation.State_Covered;
      Source_Shaped : Boolean := True;
      Canonical_Model : Boolean := True;
      Consumed : Boolean := True;
      Surfaceable : Boolean := True;
      Partial_Or_Blocked_Represented : Boolean := True;
      Stable_Source_Span : Boolean := True;
      Blocker_Family : Boolean := True;
      Stable_Blocker : Boolean := True;
      Reinterprets : Boolean := False;
      Canonical_Declaration : Boolean := True;
      Canonical_Completion : Boolean := True;
      Canonical_Entity : Boolean := True;
      Canonical_Renaming : Boolean := True;
      Canonical_Type : Boolean := True;
      Canonical_View : Boolean := True;
      Canonical_Profile : Boolean := True;
      Generic_Substitution : Boolean := True;
      Cross_Unit : Boolean := True;
      Hover_Canonical : Boolean := True;
      Build_Distinct : Boolean := True;
      Build_Source_Span : Boolean := True;
      Runtime_Check : Boolean := True;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Consumer_Row;
      FP : constant Natural := 1_340_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Consumer := Consumer;
      Row.Family := Family;
      Row.Slice := Slice;
      Row.State := State;
      Row.Name := To_Unbounded_String ("source-shaped semantic consumer row");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_340_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Canonical_Model_Used := Canonical_Model;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Can_Surface_Result := Surfaceable;
      Row.Partial_Or_Blocked_Represented := Partial_Or_Blocked_Represented;
      Row.Stable_Source_Span := Stable_Source_Span;
      Row.Semantic_Blocker_Family_Present := Blocker_Family;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Consumer_Reinterprets_Names_Or_Types := Reinterprets;
      Row.Uses_Canonical_Declaration_Identity := Canonical_Declaration;
      Row.Uses_Canonical_Completion_Identity := Canonical_Completion;
      Row.Uses_Canonical_Entity_Identity := Canonical_Entity;
      Row.Uses_Canonical_Renaming_Identity := Canonical_Renaming;
      Row.Uses_Canonical_Type_Identity := Canonical_Type;
      Row.Uses_Canonical_View_Identity := Canonical_View;
      Row.Uses_Canonical_Profile_Identity := Canonical_Profile;
      Row.Uses_Generic_Substitution_Identity := Generic_Substitution;
      Row.Uses_Cross_Unit_Evidence := Cross_Unit;
      Row.Hover_Detail_From_Canonical_Evidence := Hover_Canonical;
      Row.Build_Diagnostics_Distinct_From_Internal := Build_Distinct;
      Row.Build_Diagnostic_Shares_Source_Span := Build_Source_Span;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check;
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
      Audit.Add_Consumer_Row (Input, Row);
   end Add_Row;

   procedure Add_All_Ready_Consumers (Input : in out Audit.Consumer_Input) is
   begin
      Add_Row (Input, 1, Audit.Consumer_Diagnostics,
               Matrix.Family_Aggregates, Matrix.Slice_Aggregate);
      Add_Row (Input, 2, Audit.Consumer_Semantic_Colouring,
               Matrix.Family_Names_Visibility_Selected_Attributes,
               Matrix.Slice_Visibility_Name_Resolution);
      Add_Row (Input, 3, Audit.Consumer_Outline_Model,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit);
      Add_Row (Input, 4, Audit.Consumer_Semantic_Navigation,
               Matrix.Family_Generics_Contracts_Substitution_Replay,
               Matrix.Slice_Generic_Body_Replay);
      Add_Row (Input, 5, Audit.Consumer_Hover_Details,
               Matrix.Family_Calls_Overload_Callable_Profiles,
               Matrix.Slice_Callable_Profile);
      Add_Row (Input, 6, Audit.Consumer_Build_Diagnostic_Bridge,
               Matrix.Family_Representation_Aspects_Freezing,
               Matrix.Slice_Representation_Aspect_Operational);
   end Add_All_Ready_Consumers;

   procedure Expect_Status
     (Results : Audit.Consumer_Model;
      Consumer : Audit.Semantic_Consumer;
      Status : Audit.Consumer_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Consumer).Status = Status,
         "unexpected semantic consumer enforcement status");
   end Expect_Status;

   procedure Test_All_Consumers_Use_Canonical_Model

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_All_Ready_Consumers (Input);
      Results := Audit.Build (Input);

      Assert (Results.Total_Consumers = 6, "expected six semantic consumers");
      Assert (Audit.Count (Results) = 6, "expected one row per semantic consumer");
      Assert (Results.Ready_Count = 6, "all semantic consumers should be ready");
      Assert (Results.Invalid_Count = 0, "ready consumers should have no invalid rows");
      Assert (Audit.Semantic_Consumer_Enforcement_Ready (Results), "consumer enforcement should be ready");
      Assert (Audit.All_Completed_Results_Surfaceable (Results), "completed semantic results should be surfaceable");
      Expect_Status (Results, Audit.Consumer_Diagnostics, Audit.Status_Ready);
      Expect_Status (Results, Audit.Consumer_Semantic_Colouring, Audit.Status_Ready);
      Expect_Status (Results, Audit.Consumer_Outline_Model, Audit.Status_Ready);
      Expect_Status (Results, Audit.Consumer_Semantic_Navigation, Audit.Status_Ready);
      Expect_Status (Results, Audit.Consumer_Hover_Details, Audit.Status_Ready);
      Expect_Status (Results, Audit.Consumer_Build_Diagnostic_Bridge, Audit.Status_Ready);
   end Test_All_Consumers_Use_Canonical_Model;

   procedure Test_Diagnostics_Require_Stable_Blocker_Family

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Diagnostics,
               Matrix.Family_Aggregates, Matrix.Slice_Aggregate,
               Blocker_Family => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Diagnostics,
                     Audit.Status_Diagnostics_Missing_Blocker_Family);
      Assert (Results.Invalid_Count >= 1, "diagnostic without blocker family should be invalid");
   end Test_Diagnostics_Require_Stable_Blocker_Family;

   procedure Test_Semantic_Colouring_Cannot_Reinterpret_Names_Or_Types

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Semantic_Colouring,
               Matrix.Family_Names_Visibility_Selected_Attributes,
               Matrix.Slice_Visibility_Name_Resolution,
               Reinterprets => True);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Semantic_Colouring,
                     Audit.Status_Independent_Name_Type_Resolution);
   end Test_Semantic_Colouring_Cannot_Reinterpret_Names_Or_Types;

   procedure Test_Outline_And_Navigation_Use_Canonical_Identity

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Outline_Model,
               Matrix.Family_Library_Context_Subunits_Elaboration,
               Matrix.Slice_Library_Unit_Subunit,
               Canonical_Declaration => False);
      Add_Row (Input, 2, Audit.Consumer_Semantic_Navigation,
               Matrix.Family_Generics_Contracts_Substitution_Replay,
               Matrix.Slice_Generic_Body_Replay,
               Canonical_Entity => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Outline_Model,
                     Audit.Status_Noncanonical_Declaration_Or_Completion);
      Expect_Status (Results, Audit.Consumer_Semantic_Navigation,
                     Audit.Status_Navigation_Entity_Model_Mismatch);
   end Test_Outline_And_Navigation_Use_Canonical_Identity;

   procedure Test_Hover_And_Build_Bridge_Consume_Canonical_Evidence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Hover_Details,
               Matrix.Family_Calls_Overload_Callable_Profiles,
               Matrix.Slice_Callable_Profile,
               Hover_Canonical => False);
      Add_Row (Input, 2, Audit.Consumer_Build_Diagnostic_Bridge,
               Matrix.Family_Interfacing_Import_Export,
               Matrix.Slice_Interfacing_Import_Export,
               Build_Distinct => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Hover_Details,
                     Audit.Status_Hover_Uses_Slice_Local_Evidence);
      Expect_Status (Results, Audit.Consumer_Build_Diagnostic_Bridge,
                     Audit.Status_Build_Diagnostic_Bridge_Conflates_External);
   end Test_Hover_And_Build_Bridge_Consume_Canonical_Evidence;

   procedure Test_Covered_And_Blocked_Results_Must_Be_Surfaceable

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Diagnostics,
               Matrix.Family_Aggregates, Matrix.Slice_Aggregate,
               Surfaceable => False);
      Add_Row (Input, 2, Audit.Consumer_Semantic_Colouring,
               Matrix.Family_Assignments_Conversions,
               Matrix.Slice_Assignment_Conversion,
               State => Remediation.State_Blocked,
               Partial_Or_Blocked_Represented => False);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Diagnostics,
                     Audit.Status_Covered_Result_Not_Surfaceable);
      Expect_Status (Results, Audit.Consumer_Semantic_Colouring,
                     Audit.Status_Partial_Or_Blocked_Result_Hidden);
   end Test_Covered_And_Blocked_Results_Must_Be_Surfaceable;

   procedure Test_Stale_Consumer_And_Evidence_Fingerprints_Block

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Add_Row (Input, 1, Audit.Consumer_Hover_Details,
               Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Matrix.Slice_Subtype_Range_Predicate,
               Expected_Source_FP => 7,
               Expected_Type_FP => 8,
               Expected_Consumer_FP => 9);
      Results := Audit.Build (Input);

      Expect_Status (Results, Audit.Consumer_Hover_Details,
                     Audit.Status_Multiple_Blockers);
      Assert
        (Audit.Result_For (Results, Audit.Consumer_Hover_Details).Blocker_Count >= 3,
         "stale source/type/consumer fingerprints should all be retained");
   end Test_Stale_Consumer_And_Evidence_Fingerprints_Block;

   procedure Test_Missing_Consumer_Rows_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Consumer_Input;
      Results : Audit.Consumer_Model;
   begin
      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 6, "empty consumer input should emit one missing row per consumer");
      Assert (Results.Missing_Consumer_Count = 6, "all consumers should be reported missing");
      Assert (Results.Invalid_Count = 6, "missing consumers should invalidate enforcement");
      Expect_Status (Results, Audit.Consumer_Diagnostics, Audit.Status_Missing_Consumer_Row);
      Assert (not Audit.Semantic_Consumer_Enforcement_Ready (Results), "missing consumers reject readiness");
   end Test_Missing_Consumer_Rows_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_All_Consumers_Use_Canonical_Model'Access,
         "all consumers use the canonical semantic model");
      Register_Routine
        (T, Test_Diagnostics_Require_Stable_Blocker_Family'Access,
         "diagnostics require a stable semantic blocker family");
      Register_Routine
        (T, Test_Semantic_Colouring_Cannot_Reinterpret_Names_Or_Types'Access,
         "semantic colouring cannot reinterpret names or types");
      Register_Routine
        (T, Test_Outline_And_Navigation_Use_Canonical_Identity'Access,
         "outline and navigation use canonical identity");
      Register_Routine
        (T, Test_Hover_And_Build_Bridge_Consume_Canonical_Evidence'Access,
         "hover and build bridge consume canonical evidence");
      Register_Routine
        (T, Test_Covered_And_Blocked_Results_Must_Be_Surfaceable'Access,
         "covered and blocked results must be surfaceable");
      Register_Routine
        (T, Test_Stale_Consumer_And_Evidence_Fingerprints_Block'Access,
         "stale consumer and evidence fingerprints block");
      Register_Routine
        (T, Test_Missing_Consumer_Rows_Are_Rejected'Access,
         "missing consumer rows are rejected");
   end Register_Tests;

end Test_Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
