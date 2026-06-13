with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Semantic_Integration_Audit_Pass1335;

package body Test_Ada_Semantic_Integration_Audit_Pass1335 is

   package Audit renames Editor.Ada_Semantic_Integration_Audit_Pass1335;
   use type Audit.Slice_Family;
   use type Audit.Scenario_Kind;
   use type Audit.Audit_Status;
   use type Audit.Slice_Info;
   use type Audit.Slice_Model;
   use type Audit.Scenario_Check;
   use type Audit.Check_Model;
   use type Audit.Audit_Result;
   use type Audit.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Semantic_Integration_Audit_Pass1335");
   end Name;

   procedure Add_Slice
     (Model : in out Audit.Slice_Model;
      Family : Audit.Slice_Family;
      Name : String;
      Source_Shaped : Boolean := True;
      Source_Evidence : Boolean := True;
      AST_Evidence : Boolean := True;
      Type_Evidence : Boolean := True;
      Profile_Evidence : Boolean := True;
      View_Evidence : Boolean := True;
      Overload_Evidence : Boolean := True;
      Freezing_Evidence : Boolean := True;
      Generic_Substitution_Evidence : Boolean := True;
      Cross_Unit_Evidence : Boolean := True;
      Flow_Effect_Evidence : Boolean := True;
      Representation_Evidence : Boolean := True;
      Runtime_Check_Evidence : Boolean := True;
      Consumer : Boolean := True;
      Canonical_Agreement : Boolean := True;
      FP_Base : Natural := 1_335_000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0) is
      S : Audit.Slice_Info;
      Offset : constant Natural := Audit.Slice_Family'Pos (Family) + 1;
   begin
      S.Family := Family;
      S.Name := To_Unbounded_String (Name);
      S.Present := True;
      S.Source_Shaped := Source_Shaped;
      S.Has_Source_Evidence := Source_Evidence;
      S.Has_AST_Evidence := AST_Evidence;
      S.Has_Type_Evidence := Type_Evidence;
      S.Has_Profile_Evidence := Profile_Evidence;
      S.Has_View_Evidence := View_Evidence;
      S.Has_Overload_Evidence := Overload_Evidence;
      S.Has_Freezing_Evidence := Freezing_Evidence;
      S.Has_Generic_Substitution_Evidence := Generic_Substitution_Evidence;
      S.Has_Cross_Unit_Evidence := Cross_Unit_Evidence;
      S.Has_Flow_Effect_Evidence := Flow_Effect_Evidence;
      S.Has_Representation_Evidence := Representation_Evidence;
      S.Has_Runtime_Check_Evidence := Runtime_Check_Evidence;
      S.Consumed_By_Semantic_Path := Consumer;
      S.Agrees_With_Canonical_Model := Canonical_Agreement;
      S.Source_Fingerprint := FP_Base + Offset;
      S.AST_Fingerprint := FP_Base + 100 + Offset;
      S.Type_Fingerprint := FP_Base + 200 + Offset;
      S.Profile_Fingerprint := FP_Base + 300 + Offset;
      S.Substitution_Fingerprint := FP_Base + 400 + Offset;
      S.Effect_Fingerprint := FP_Base + 500 + Offset;
      S.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then S.Source_Fingerprint else Expected_Source_FP);
      S.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then S.AST_Fingerprint else Expected_AST_FP);
      S.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then S.Type_Fingerprint else Expected_Type_FP);
      S.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then S.Profile_Fingerprint else Expected_Profile_FP);
      S.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then S.Substitution_Fingerprint else Expected_Substitution_FP);
      S.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then S.Effect_Fingerprint else Expected_Effect_FP);
      Audit.Add_Slice (Model, S);
   end Add_Slice;

   procedure Add_All_Ready_Slices (Model : in out Audit.Slice_Model) is
   begin
      Add_Slice (Model, Audit.Slice_Aggregate, "aggregate");
      Add_Slice (Model, Audit.Slice_Assignment_Conversion, "assignment conversion");
      Add_Slice (Model, Audit.Slice_Iterator_Loop_Parallel, "iterator loop parallel");
      Add_Slice (Model, Audit.Slice_Contract_Aspect, "contract aspect");
      Add_Slice (Model, Audit.Slice_Context_Clause_With_Use, "context with use");
      Add_Slice (Model, Audit.Slice_Library_Unit_Subunit, "library subunit");
      Add_Slice (Model, Audit.Slice_Interface_Synchronized, "interface synchronized");
      Add_Slice (Model, Audit.Slice_Interfacing_Import_Export, "interfacing import export");
      Add_Slice (Model, Audit.Slice_Flow_Refinement, "flow refinement");
      Add_Slice (Model, Audit.Slice_Callable_Profile, "callable profile");
   end Add_All_Ready_Slices;

   procedure Add_Generic_Private_Aggregate_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 1;
      C.Kind := Audit.Scenario_Generic_Private_Aggregate_Assignment;
      C.Name := To_Unbounded_String
        ("generic private type with aggregate initialization and assignment conversion");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133501);
      C.Requires_Aggregate := True;
      C.Requires_Assignment_Conversion := True;
      C.Requires_Contract_Aspect := True;
      C.Requires_Callable_Profile := True;
      C.Requires_Profile_Evidence := True;
      C.Requires_View_Evidence := True;
      C.Requires_Overload_Evidence := True;
      C.Requires_Generic_Substitution_Evidence := True;
      C.Requires_Runtime_Check_Evidence := True;
      Audit.Add_Check (Checks, C);
   end Add_Generic_Private_Aggregate_Check;

   procedure Add_Cross_Unit_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 2;
      C.Kind := Audit.Scenario_Separate_Body_Context_Elaboration;
      C.Name := To_Unbounded_String
        ("context clause propagated into separate body and library completion");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133502);
      C.Requires_Context_Clause_With_Use := True;
      C.Requires_Library_Unit_Subunit := True;
      C.Requires_Contract_Aspect := True;
      C.Requires_Cross_Unit_Evidence := True;
      C.Requires_View_Evidence := True;
      Audit.Add_Check (Checks, C);
   end Add_Cross_Unit_Check;

   procedure Add_Interface_Flow_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 3;
      C.Kind := Audit.Scenario_Interface_Dispatching_Flow;
      C.Name := To_Unbounded_String
        ("synchronized interface dispatching with flow refinement and contract effects");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133503);
      C.Requires_Interface_Synchronized := True;
      C.Requires_Flow_Refinement := True;
      C.Requires_Contract_Aspect := True;
      C.Requires_Callable_Profile := True;
      C.Requires_Profile_Evidence := True;
      C.Requires_Overload_Evidence := True;
      C.Requires_Flow_Effect_Evidence := True;
      Audit.Add_Check (Checks, C);
   end Add_Interface_Flow_Check;

   procedure Add_Import_Profile_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 4;
      C.Kind := Audit.Scenario_Import_Export_Profile_Representation;
      C.Name := To_Unbounded_String
        ("imported callable profile with external representation evidence");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133504);
      C.Requires_Interfacing_Import_Export := True;
      C.Requires_Callable_Profile := True;
      C.Requires_Profile_Evidence := True;
      C.Requires_Representation_Evidence := True;
      Audit.Add_Check (Checks, C);
   end Add_Import_Profile_Check;

   procedure Add_Parallel_Flow_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 5;
      C.Kind := Audit.Scenario_Iterator_Parallel_Contract_Flow;
      C.Name := To_Unbounded_String
        ("parallel iterator with reduction, contract, and flow-effect evidence");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133505);
      C.Requires_Iterator_Loop_Parallel := True;
      C.Requires_Contract_Aspect := True;
      C.Requires_Flow_Refinement := True;
      C.Requires_Profile_Evidence := True;
      C.Requires_Flow_Effect_Evidence := True;
      C.Requires_Runtime_Check_Evidence := True;
      Audit.Add_Check (Checks, C);
   end Add_Parallel_Flow_Check;

   procedure Expect_Status
     (Results : Audit.Result_Model;
      Index : Positive;
      Status : Audit.Audit_Status) is
   begin
      Assert
        (Audit.Result_At (Results, Index).Status = Status,
         "unexpected semantic integration audit status");
   end Expect_Status;

   procedure Test_Composition_Ready_Source_Shaped_Scenarios

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Slices : Audit.Slice_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_All_Ready_Slices (Slices);
      Add_Generic_Private_Aggregate_Check (Checks);
      Add_Cross_Unit_Check (Checks);
      Add_Interface_Flow_Check (Checks);
      Add_Import_Profile_Check (Checks);
      Add_Parallel_Flow_Check (Checks);

      Results := Audit.Build (Slices, Checks);

      Assert (Audit.Count (Results) = 5, "expected five integration audit scenarios");
      Assert (Audit.Integration_Ready (Results), "expected composition-ready audit result");
      Assert (Results.Ready_Count = 5, "all integration scenarios should be ready");
      Assert (Results.Blocked_Count = 0, "no integration scenario should be blocked");
      for I in 1 .. 5 loop
         Expect_Status (Results, I, Audit.Audit_Ready);
      end loop;
   end Test_Composition_Ready_Source_Shaped_Scenarios;

   procedure Test_Missing_Slice_And_Unconsumed_Result_Are_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Slices : Audit.Slice_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_All_Ready_Slices (Slices);
      --  Re-add the aggregate slice as absent by omitting it from a new model.
      Slices.Items.Clear;
      Add_Slice (Slices, Audit.Slice_Assignment_Conversion, "assignment conversion");
      Add_Slice (Slices, Audit.Slice_Contract_Aspect, "contract aspect", Consumer => False);
      Add_Slice (Slices, Audit.Slice_Callable_Profile, "callable profile");

      Add_Generic_Private_Aggregate_Check (Checks);
      Results := Audit.Build (Slices, Checks);

      Assert (not Audit.Integration_Ready (Results), "missing/unconsumed slices must block readiness");
      Expect_Status (Results, 1, Audit.Audit_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "expected both missing aggregate and unconsumed contract blockers");
   end Test_Missing_Slice_And_Unconsumed_Result_Are_Blockers;

   procedure Test_Cross_Unit_Evidence_Is_Required_For_Unit_Scenario

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Slices : Audit.Slice_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_All_Ready_Slices (Slices);
      Slices.Items.Clear;
      Add_Slice (Slices, Audit.Slice_Context_Clause_With_Use, "context with use",
                 Cross_Unit_Evidence => False);
      Add_Slice (Slices, Audit.Slice_Library_Unit_Subunit, "library subunit");
      Add_Slice (Slices, Audit.Slice_Contract_Aspect, "contract aspect");

      Add_Cross_Unit_Check (Checks);
      Results := Audit.Build (Slices, Checks);

      Expect_Status (Results, 1, Audit.Audit_Missing_Cross_Unit_Evidence);
      Assert (Results.Blocked_Count = 1, "cross-unit evidence absence should block the unit scenario");
   end Test_Cross_Unit_Evidence_Is_Required_For_Unit_Scenario;

   procedure Test_Fingerprint_And_Model_Agreement_Are_Audited

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Slices : Audit.Slice_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_Slice
        (Slices, Audit.Slice_Interface_Synchronized, "interface synchronized",
         Canonical_Agreement => False);
      Add_Slice
        (Slices, Audit.Slice_Flow_Refinement, "flow refinement",
         Expected_Effect_FP => 42);
      Add_Slice
        (Slices, Audit.Slice_Contract_Aspect, "contract aspect");
      Add_Slice
        (Slices, Audit.Slice_Callable_Profile, "callable profile");

      Add_Interface_Flow_Check (Checks);
      Results := Audit.Build (Slices, Checks);

      Expect_Status (Results, 1, Audit.Audit_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "expected canonical disagreement and effect fingerprint blockers");
   end Test_Fingerprint_And_Model_Agreement_Are_Audited;

   procedure Test_Source_Shaped_Scenarios_Are_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Slices : Audit.Slice_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
      C : Audit.Scenario_Check;
   begin
      Add_All_Ready_Slices (Slices);
      C.Id := 6;
      C.Kind := Audit.Scenario_Generic_Private_Aggregate_Assignment;
      C.Name := To_Unbounded_String ("synthetic aggregate closure state");
      C.Source_Shaped := False;
      C.Requires_Aggregate := True;
      C.Requires_Assignment_Conversion := True;
      Audit.Add_Check (Checks, C);

      Results := Audit.Build (Slices, Checks);
      Expect_Status (Results, 1, Audit.Audit_Scenario_Not_Source_Shaped);
   end Test_Source_Shaped_Scenarios_Are_Required;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Composition_Ready_Source_Shaped_Scenarios'Access,
         "composition-ready source-shaped scenarios");
      Register_Routine
        (T, Test_Missing_Slice_And_Unconsumed_Result_Are_Blockers'Access,
         "missing slice and unconsumed result blockers");
      Register_Routine
        (T, Test_Cross_Unit_Evidence_Is_Required_For_Unit_Scenario'Access,
         "cross-unit evidence required for unit scenario");
      Register_Routine
        (T, Test_Fingerprint_And_Model_Agreement_Are_Audited'Access,
         "fingerprint and model agreement audited");
      Register_Routine
        (T, Test_Source_Shaped_Scenarios_Are_Required'Access,
         "source-shaped scenario requirement");
   end Register_Tests;

end Test_Ada_Semantic_Integration_Audit_Pass1335;
