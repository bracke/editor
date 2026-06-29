with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336;

package body Test_Ada_Canonical_Semantic_Model_Agreement_Audit is

   package Audit renames Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336;
   use type Audit.Slice_Family;
   use type Audit.Agreement_Dimension;
   use type Audit.View_Class;
   use type Audit.Scenario_Kind;
   use type Audit.Agreement_Status;
   use type Audit.Canonical_Binding;
   use type Audit.Canonical_Model;
   use type Audit.Scenario_Check;
   use type Audit.Check_Model;
   use type Audit.Agreement_Result;
   use type Audit.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Canonical_Semantic_Model_Agreement_Audit");
   end Name;

   procedure Add_Binding
     (Model : in out Audit.Canonical_Model;
      Scenario_Id : Natural;
      Dimension : Audit.Agreement_Dimension;
      Slice : Audit.Slice_Family;
      Id : Natural;
      View : Audit.View_Class := Audit.View_Full;
      Source_Shaped : Boolean := True;
      Source_Evidence : Boolean := True;
      AST_Evidence : Boolean := True;
      Consumer : Boolean := True;
      Local_Id : Natural := 0;
      Slice_View : Audit.View_Class := Audit.View_Full;
      Profile_Id : Natural := 0;
      Slice_Profile_Id : Natural := 0;
      Substitution_Id : Natural := 0;
      Slice_Substitution_Id : Natural := 0;
      Unit_Id : Natural := 0;
      Slice_Unit_Id : Natural := 0;
      Representation_Id : Natural := 0;
      Slice_Representation_Id : Natural := 0;
      Flow_Effect_Id : Natural := 0;
      Slice_Flow_Effect_Id : Natural := 0;
      Overload_Set_Id : Natural := 0;
      Slice_Overload_Set_Id : Natural := 0;
      Runtime_Check_Id : Natural := 0;
      Slice_Runtime_Check_Id : Natural := 0;
      Expected_Model_FP : Natural := 0) is
      B : Audit.Canonical_Binding;
      FP : constant Natural := 1_336_000 + Scenario_Id * 100 + Audit.Agreement_Dimension'Pos (Dimension);
   begin
      B.Scenario_Id := Scenario_Id;
      B.Dimension := Dimension;
      B.Slice := Slice;
      B.Source_Shaped := Source_Shaped;
      B.Has_Source_Evidence := Source_Evidence;
      B.Has_AST_Evidence := AST_Evidence;
      B.Consumed_By_Semantic_Path := Consumer;
      B.Canonical_Id := Id;
      B.Slice_Local_Id := (if Local_Id = 0 then Id else Local_Id);
      B.Canonical_View := View;
      B.Slice_View := Slice_View;
      B.Canonical_Profile_Id := (if Profile_Id = 0 then Id else Profile_Id);
      B.Slice_Profile_Id := (if Slice_Profile_Id = 0 then B.Canonical_Profile_Id else Slice_Profile_Id);
      B.Canonical_Substitution_Id := (if Substitution_Id = 0 then Id else Substitution_Id);
      B.Slice_Substitution_Id :=
        (if Slice_Substitution_Id = 0 then B.Canonical_Substitution_Id else Slice_Substitution_Id);
      B.Canonical_Unit_Id := (if Unit_Id = 0 then Id else Unit_Id);
      B.Slice_Unit_Id := (if Slice_Unit_Id = 0 then B.Canonical_Unit_Id else Slice_Unit_Id);
      B.Canonical_Representation_Id := (if Representation_Id = 0 then Id else Representation_Id);
      B.Slice_Representation_Id :=
        (if Slice_Representation_Id = 0 then B.Canonical_Representation_Id else Slice_Representation_Id);
      B.Canonical_Flow_Effect_Id := (if Flow_Effect_Id = 0 then Id else Flow_Effect_Id);
      B.Slice_Flow_Effect_Id :=
        (if Slice_Flow_Effect_Id = 0 then B.Canonical_Flow_Effect_Id else Slice_Flow_Effect_Id);
      B.Canonical_Overload_Set_Id := (if Overload_Set_Id = 0 then Id else Overload_Set_Id);
      B.Slice_Overload_Set_Id :=
        (if Slice_Overload_Set_Id = 0 then B.Canonical_Overload_Set_Id else Slice_Overload_Set_Id);
      B.Canonical_Runtime_Check_Id := (if Runtime_Check_Id = 0 then Id else Runtime_Check_Id);
      B.Slice_Runtime_Check_Id :=
        (if Slice_Runtime_Check_Id = 0 then B.Canonical_Runtime_Check_Id else Slice_Runtime_Check_Id);
      B.Source_Fingerprint := FP + 1;
      B.Expected_Source_Fingerprint := B.Source_Fingerprint;
      B.AST_Fingerprint := FP + 2;
      B.Expected_AST_Fingerprint := B.AST_Fingerprint;
      B.Model_Fingerprint := FP + 3;
      B.Expected_Model_Fingerprint :=
        (if Expected_Model_FP = 0 then B.Model_Fingerprint else Expected_Model_FP);
      Audit.Add_Binding (Model, B);
   end Add_Binding;

   procedure Add_Private_Type_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 1;
      C.Kind := Audit.Scenario_Private_Type_Rep_Aggregate_Assignment;
      C.Name := To_Unbounded_String
        ("private type full-view representation aggregate assignment predicate");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133601);
      C.Requires_Entity := True;
      C.Requires_Type := True;
      C.Requires_View := True;
      C.Requires_Representation_Freezing := True;
      C.Requires_Runtime_Check := True;
      Audit.Add_Check (Checks, C);
   end Add_Private_Type_Check;

   procedure Add_Generic_Replay_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 2;
      C.Kind := Audit.Scenario_Generic_Formal_Body_Replay_Flow;
      C.Name := To_Unbounded_String
        ("generic formal actual body replay aggregate actual flow refinement");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133602);
      C.Requires_Entity := True;
      C.Requires_Type := True;
      C.Requires_Profile := True;
      C.Requires_Generic_Substitution := True;
      C.Requires_Flow_Effect := True;
      Audit.Add_Check (Checks, C);
   end Add_Generic_Replay_Check;

   procedure Add_Interface_Dispatch_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 3;
      C.Kind := Audit.Scenario_Tagged_Interface_Dispatching_Contract;
      C.Name := To_Unbounded_String
        ("tagged extension synchronized interface dispatching contract class-wide conversion");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133603);
      C.Requires_Entity := True;
      C.Requires_Type := True;
      C.Requires_View := True;
      C.Requires_Profile := True;
      C.Requires_Overload_Set := True;
      C.Requires_Flow_Effect := True;
      Audit.Add_Check (Checks, C);
   end Add_Interface_Dispatch_Check;

   procedure Add_Private_Child_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 4;
      C.Kind := Audit.Scenario_Private_Child_Separate_Imported_Callable;
      C.Name := To_Unbounded_String
        ("private child separate body imported exported callable profile");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133604);
      C.Requires_Entity := True;
      C.Requires_Profile := True;
      C.Requires_Unit := True;
      C.Requires_Representation_Freezing := True;
      Audit.Add_Check (Checks, C);
   end Add_Private_Child_Check;

   procedure Add_Protected_Parallel_Check (Checks : in out Audit.Check_Model) is
      C : Audit.Scenario_Check;
   begin
      C.Id := 5;
      C.Kind := Audit.Scenario_Protected_Parallel_Volatile_Effects;
      C.Name := To_Unbounded_String
        ("protected synchronized interface parallel loop volatile atomic effect ordering");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133605);
      C.Requires_Entity := True;
      C.Requires_Type := True;
      C.Requires_Profile := True;
      C.Requires_Flow_Effect := True;
      C.Requires_Runtime_Check := True;
      Audit.Add_Check (Checks, C);
   end Add_Protected_Parallel_Check;

   procedure Add_All_Ready_Bindings (Model : in out Audit.Canonical_Model) is
   begin
      Add_Binding (Model, 1, Audit.Dimension_Entity, Audit.Slice_Aggregate, 10);
      Add_Binding (Model, 1, Audit.Dimension_Type, Audit.Slice_Assignment_Conversion, 11);
      Add_Binding (Model, 1, Audit.Dimension_View, Audit.Slice_Visibility_Name_Resolution, 12,
                   View => Audit.View_Private, Slice_View => Audit.View_Private);
      Add_Binding (Model, 1, Audit.Dimension_Representation_Freezing,
                   Audit.Slice_Representation_Freezing, 13);
      Add_Binding (Model, 1, Audit.Dimension_Runtime_Check, Audit.Slice_Contract_Aspect, 14);

      Add_Binding (Model, 2, Audit.Dimension_Entity, Audit.Slice_Generic_Contract_Body, 20);
      Add_Binding (Model, 2, Audit.Dimension_Type, Audit.Slice_Generic_Body_Replay, 21);
      Add_Binding (Model, 2, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 22);
      Add_Binding (Model, 2, Audit.Dimension_Generic_Substitution,
                   Audit.Slice_Generic_Body_Replay, 23);
      Add_Binding (Model, 2, Audit.Dimension_Flow_Effect, Audit.Slice_Flow_Refinement, 24);

      Add_Binding (Model, 3, Audit.Dimension_Entity, Audit.Slice_Tagged_Dispatching, 30);
      Add_Binding (Model, 3, Audit.Dimension_Type, Audit.Slice_Interface_Synchronized, 31);
      Add_Binding (Model, 3, Audit.Dimension_View, Audit.Slice_Assignment_Conversion, 32,
                   View => Audit.View_Class_Wide, Slice_View => Audit.View_Class_Wide);
      Add_Binding (Model, 3, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 33);
      Add_Binding (Model, 3, Audit.Dimension_Overload_Set, Audit.Slice_Tagged_Dispatching, 34);
      Add_Binding (Model, 3, Audit.Dimension_Flow_Effect, Audit.Slice_Contract_Aspect, 35);

      Add_Binding (Model, 4, Audit.Dimension_Entity, Audit.Slice_Context_Clause_With_Use, 40);
      Add_Binding (Model, 4, Audit.Dimension_Profile, Audit.Slice_Interfacing_Import_Export, 41);
      Add_Binding (Model, 4, Audit.Dimension_Unit, Audit.Slice_Library_Unit_Subunit, 42);
      Add_Binding (Model, 4, Audit.Dimension_Representation_Freezing,
                   Audit.Slice_Interfacing_Import_Export, 43);

      Add_Binding (Model, 5, Audit.Dimension_Entity, Audit.Slice_Interface_Synchronized, 50);
      Add_Binding (Model, 5, Audit.Dimension_Type, Audit.Slice_Iterator_Loop_Parallel, 51);
      Add_Binding (Model, 5, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 52);
      Add_Binding (Model, 5, Audit.Dimension_Flow_Effect, Audit.Slice_Flow_Refinement, 53);
      Add_Binding (Model, 5, Audit.Dimension_Runtime_Check, Audit.Slice_Iterator_Loop_Parallel, 54);
   end Add_All_Ready_Bindings;

   procedure Expect_Status
     (Results : Audit.Result_Model;
      Index : Positive;
      Status : Audit.Agreement_Status) is
   begin
      Assert
        (Audit.Result_At (Results, Index).Status = Status,
         "unexpected canonical semantic agreement audit status");
   end Expect_Status;

   procedure Test_Canonical_Model_Agrees_For_Source_Shaped_Multi_Slice_Scenarios

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_All_Ready_Bindings (Model);
      Add_Private_Type_Check (Checks);
      Add_Generic_Replay_Check (Checks);
      Add_Interface_Dispatch_Check (Checks);
      Add_Private_Child_Check (Checks);
      Add_Protected_Parallel_Check (Checks);

      Results := Audit.Build (Model, Checks);

      Assert (Audit.Count (Results) = 5, "expected five canonical agreement scenarios");
      Assert (Audit.Canonical_Model_Agrees (Results), "canonical model should agree");
      Assert (Results.Ready_Count = 5, "all canonical scenarios should be ready");
      Assert (Results.Blocked_Count = 0, "no canonical scenario should be blocked");
      for I in 1 .. 5 loop
         Expect_Status (Results, I, Audit.Agreement_Ready);
      end loop;
   end Test_Canonical_Model_Agrees_For_Source_Shaped_Multi_Slice_Scenarios;

   procedure Test_Entity_Type_And_View_Mismatches_Block_Agreement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_Binding (Model, 1, Audit.Dimension_Entity, Audit.Slice_Aggregate, 10,
                   Local_Id => 99);
      Add_Binding (Model, 1, Audit.Dimension_Type, Audit.Slice_Assignment_Conversion, 11);
      Add_Binding (Model, 1, Audit.Dimension_View, Audit.Slice_Visibility_Name_Resolution, 12,
                   View => Audit.View_Private, Slice_View => Audit.View_Full);
      Add_Binding (Model, 1, Audit.Dimension_Representation_Freezing,
                   Audit.Slice_Representation_Freezing, 13);
      Add_Binding (Model, 1, Audit.Dimension_Runtime_Check, Audit.Slice_Contract_Aspect, 14);
      Add_Private_Type_Check (Checks);

      Results := Audit.Build (Model, Checks);

      Expect_Status (Results, 1, Audit.Agreement_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "entity identity and view-class disagreement should both block");
   end Test_Entity_Type_And_View_Mismatches_Block_Agreement;

   procedure Test_Generic_Profile_Substitution_And_Flow_Mismatches_Block_Agreement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_Binding (Model, 2, Audit.Dimension_Entity, Audit.Slice_Generic_Contract_Body, 20);
      Add_Binding (Model, 2, Audit.Dimension_Type, Audit.Slice_Generic_Body_Replay, 21);
      Add_Binding (Model, 2, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 22,
                   Profile_Id => 220, Slice_Profile_Id => 221);
      Add_Binding (Model, 2, Audit.Dimension_Generic_Substitution,
                   Audit.Slice_Generic_Body_Replay, 23,
                   Substitution_Id => 230, Slice_Substitution_Id => 231);
      Add_Binding (Model, 2, Audit.Dimension_Flow_Effect, Audit.Slice_Flow_Refinement, 24,
                   Flow_Effect_Id => 240, Slice_Flow_Effect_Id => 241);
      Add_Generic_Replay_Check (Checks);

      Results := Audit.Build (Model, Checks);

      Expect_Status (Results, 1, Audit.Agreement_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 3,
              "profile, substitution, and flow/effect mismatches should compose as blockers");
   end Test_Generic_Profile_Substitution_And_Flow_Mismatches_Block_Agreement;

   procedure Test_Unit_Representation_Overload_And_Runtime_Mismatches_Are_Audited

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_Binding (Model, 3, Audit.Dimension_Entity, Audit.Slice_Tagged_Dispatching, 30);
      Add_Binding (Model, 3, Audit.Dimension_Type, Audit.Slice_Interface_Synchronized, 31);
      Add_Binding (Model, 3, Audit.Dimension_View, Audit.Slice_Assignment_Conversion, 32,
                   View => Audit.View_Class_Wide, Slice_View => Audit.View_Class_Wide);
      Add_Binding (Model, 3, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 33);
      Add_Binding (Model, 3, Audit.Dimension_Overload_Set, Audit.Slice_Tagged_Dispatching, 34,
                   Overload_Set_Id => 340, Slice_Overload_Set_Id => 341);
      Add_Binding (Model, 3, Audit.Dimension_Flow_Effect, Audit.Slice_Contract_Aspect, 35);
      Add_Interface_Dispatch_Check (Checks);

      Results := Audit.Build (Model, Checks);
      Expect_Status (Results, 1, Audit.Agreement_Overload_Set_Mismatch);

      Model.Bindings.Clear;
      Checks.Items.Clear;
      Add_Binding (Model, 4, Audit.Dimension_Entity, Audit.Slice_Context_Clause_With_Use, 40);
      Add_Binding (Model, 4, Audit.Dimension_Profile, Audit.Slice_Interfacing_Import_Export, 41);
      Add_Binding (Model, 4, Audit.Dimension_Unit, Audit.Slice_Library_Unit_Subunit, 42,
                   Unit_Id => 420, Slice_Unit_Id => 421);
      Add_Binding (Model, 4, Audit.Dimension_Representation_Freezing,
                   Audit.Slice_Interfacing_Import_Export, 43,
                   Representation_Id => 430, Slice_Representation_Id => 431);
      Add_Private_Child_Check (Checks);

      Results := Audit.Build (Model, Checks);
      Expect_Status (Results, 1, Audit.Agreement_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "unit completion and representation/freezing mismatches should both block");

      Model.Bindings.Clear;
      Checks.Items.Clear;
      Add_Binding (Model, 5, Audit.Dimension_Entity, Audit.Slice_Interface_Synchronized, 50);
      Add_Binding (Model, 5, Audit.Dimension_Type, Audit.Slice_Iterator_Loop_Parallel, 51);
      Add_Binding (Model, 5, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 52);
      Add_Binding (Model, 5, Audit.Dimension_Flow_Effect, Audit.Slice_Flow_Refinement, 53);
      Add_Binding (Model, 5, Audit.Dimension_Runtime_Check, Audit.Slice_Iterator_Loop_Parallel, 54,
                   Runtime_Check_Id => 540, Slice_Runtime_Check_Id => 541);
      Add_Protected_Parallel_Check (Checks);

      Results := Audit.Build (Model, Checks);
      Expect_Status (Results, 1, Audit.Agreement_Runtime_Check_Mismatch);
   end Test_Unit_Representation_Overload_And_Runtime_Mismatches_Are_Audited;

   procedure Test_Missing_Binding_Unconsumed_Result_And_Stale_Fingerprint_Block_Agreement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
   begin
      Add_Binding (Model, 2, Audit.Dimension_Entity, Audit.Slice_Generic_Contract_Body, 20,
                   Consumer => False);
      Add_Binding (Model, 2, Audit.Dimension_Type, Audit.Slice_Generic_Body_Replay, 21,
                   Expected_Model_FP => 42);
      Add_Binding (Model, 2, Audit.Dimension_Profile, Audit.Slice_Callable_Profile, 22);
      --  Required generic-substitution and flow/effect dimensions are intentionally absent.
      Add_Generic_Replay_Check (Checks);

      Results := Audit.Build (Model, Checks);

      Expect_Status (Results, 1, Audit.Agreement_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 4,
              "missing bindings, unconsumed result, and stale model fingerprint must all block");
   end Test_Missing_Binding_Unconsumed_Result_And_Stale_Fingerprint_Block_Agreement;

   procedure Test_Source_Shaped_Canonical_Audit_Is_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Model : Audit.Canonical_Model;
      Checks : Audit.Check_Model;
      Results : Audit.Result_Model;
      C : Audit.Scenario_Check;
   begin
      C.Id := 6;
      C.Kind := Audit.Scenario_Private_Type_Rep_Aggregate_Assignment;
      C.Name := To_Unbounded_String ("synthetic canonical identity closure state");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (133606);
      C.Source_Shaped := False;
      C.Requires_Entity := True;
      Audit.Add_Check (Checks, C);
      Add_Binding (Model, 6, Audit.Dimension_Entity, Audit.Slice_Aggregate, 60,
                   Source_Shaped => False);

      Results := Audit.Build (Model, Checks);
      Expect_Status (Results, 1, Audit.Agreement_Scenario_Not_Source_Shaped);
   end Test_Source_Shaped_Canonical_Audit_Is_Required;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Canonical_Model_Agrees_For_Source_Shaped_Multi_Slice_Scenarios'Access,
         "canonical model agrees for source-shaped multi-slice scenarios");
      Register_Routine
        (T, Test_Entity_Type_And_View_Mismatches_Block_Agreement'Access,
         "entity type and view mismatches block agreement");
      Register_Routine
        (T, Test_Generic_Profile_Substitution_And_Flow_Mismatches_Block_Agreement'Access,
         "generic profile substitution and flow mismatches block agreement");
      Register_Routine
        (T, Test_Unit_Representation_Overload_And_Runtime_Mismatches_Are_Audited'Access,
         "unit representation overload and runtime mismatches audited");
      Register_Routine
        (T, Test_Missing_Binding_Unconsumed_Result_And_Stale_Fingerprint_Block_Agreement'Access,
         "missing binding unconsumed result and stale fingerprint block agreement");
      Register_Routine
        (T, Test_Source_Shaped_Canonical_Audit_Is_Required'Access,
         "source-shaped canonical audit required");
   end Register_Tests;

end Test_Ada_Canonical_Semantic_Model_Agreement_Audit;
