with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_End_To_End_Semantic_Scenario_Audit;

package body Test_Ada_End_To_End_Semantic_Scenario_Audit is

   package Audit renames Editor.Ada_End_To_End_Semantic_Scenario_Audit;
   use type Audit.Scenario_Kind;
   use type Audit.Slice_Result;
   use type Audit.Audit_Status;
   use type Audit.End_To_End_Scenario;
   use type Audit.Scenario_Model;
   use type Audit.Slice_Evidence;
   use type Audit.Evidence_Model;
   use type Audit.Audit_Result;
   use type Audit.Audit_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_End_To_End_Semantic_Scenario_Audit");
   end Name;

   procedure Add_Scenario
     (Model : in out Audit.Scenario_Model;
      Id : Natural;
      Kind : Audit.Scenario_Kind;
      Name : String;
      Source_Shaped : Boolean := True;
      Source_Evidence : Boolean := True;
      AST_Evidence : Boolean := True;
      Canonical_Agrees : Boolean := True;
      Cross_Unit_Fresh : Boolean := True;
      Substitution_Propagated : Boolean := True;
      View_Agrees : Boolean := True;
      Overload_Profile_Agrees : Boolean := True;
      Flow_Consumed : Boolean := True;
      Representation_Consistent : Boolean := True;
      Runtime_Check_Preserved : Boolean := True;
      Blocker_Family_Stable : Boolean := True;
      Expected_Consumer_FP : Natural := 0) is
      S : Audit.End_To_End_Scenario;
      FP : constant Natural := 1_337_000 + Id * 100 + Audit.Scenario_Kind'Pos (Kind);
   begin
      S.Id := Id;
      S.Kind := Kind;
      S.Name := To_Unbounded_String (Name);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (1_337_000 + Id);
      S.Source_Shaped := Source_Shaped;
      S.Has_Source_Evidence := Source_Evidence;
      S.Has_AST_Evidence := AST_Evidence;
      S.Canonical_Model_Agrees := Canonical_Agrees;
      S.Cross_Unit_Evidence_Fresh := Cross_Unit_Fresh;
      S.Generic_Substitution_Propagated := Substitution_Propagated;
      S.View_Model_Agrees := View_Agrees;
      S.Overload_Profile_Agrees := Overload_Profile_Agrees;
      S.Flow_Effect_Consumed := Flow_Consumed;
      S.Representation_Freezing_Consistent := Representation_Consistent;
      S.Runtime_Check_Preserved := Runtime_Check_Preserved;
      S.Blocker_Family_Stable := Blocker_Family_Stable;
      S.Source_Fingerprint := FP + 1;
      S.Expected_Source_Fingerprint := S.Source_Fingerprint;
      S.AST_Fingerprint := FP + 2;
      S.Expected_AST_Fingerprint := S.AST_Fingerprint;
      S.Canonical_Fingerprint := FP + 3;
      S.Expected_Canonical_Fingerprint := S.Canonical_Fingerprint;
      S.Consumer_Fingerprint := FP + 4;
      S.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then S.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Scenario (Model, S);
   end Add_Scenario;

   procedure Add_Evidence
     (Model : in out Audit.Evidence_Model;
      Scenario_Id : Natural;
      Slice : Audit.Slice_Result;
      Present : Boolean := True;
      Consumed : Boolean := True;
      Source_Shaped : Boolean := True;
      Source_Evidence : Boolean := True;
      AST_Evidence : Boolean := True;
      Expected_Result_FP : Natural := 0) is
      E : Audit.Slice_Evidence;
      FP : constant Natural := 1_337_500 + Scenario_Id * 100 + Audit.Slice_Result'Pos (Slice);
   begin
      E.Scenario_Id := Scenario_Id;
      E.Slice := Slice;
      E.Present := Present;
      E.Consumed := Consumed;
      E.Source_Shaped := Source_Shaped;
      E.Has_Source_Evidence := Source_Evidence;
      E.Has_AST_Evidence := AST_Evidence;
      E.Result_Fingerprint := FP;
      E.Expected_Result_Fingerprint :=
        (if Expected_Result_FP = 0 then E.Result_Fingerprint else Expected_Result_FP);
      Audit.Add_Evidence (Model, E);
   end Add_Evidence;

   procedure Add_Private_Type_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 1) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Aggregate);
      Add_Evidence (Model, Id, Audit.Slice_Assignment_Conversion);
      Add_Evidence (Model, Id, Audit.Slice_Contract_Aspect);
      Add_Evidence (Model, Id, Audit.Slice_Representation_Freezing);
      Add_Evidence (Model, Id, Audit.Slice_Visibility_Name_Resolution);
      Add_Evidence (Model, Id, Audit.Slice_Accessibility_Lifetime);
   end Add_Private_Type_Evidence;

   procedure Add_Generic_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 2) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Aggregate);
      Add_Evidence (Model, Id, Audit.Slice_Assignment_Conversion);
      Add_Evidence (Model, Id, Audit.Slice_Contract_Aspect);
      Add_Evidence (Model, Id, Audit.Slice_Flow_Refinement);
      Add_Evidence (Model, Id, Audit.Slice_Callable_Profile);
      Add_Evidence (Model, Id, Audit.Slice_Generic_Contract_Body);
      Add_Evidence (Model, Id, Audit.Slice_Generic_Body_Replay);
      Add_Evidence (Model, Id, Audit.Slice_Overload_Resolution);
   end Add_Generic_Evidence;

   procedure Add_Tagged_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 3) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Assignment_Conversion);
      Add_Evidence (Model, Id, Audit.Slice_Contract_Aspect);
      Add_Evidence (Model, Id, Audit.Slice_Interface_Synchronized);
      Add_Evidence (Model, Id, Audit.Slice_Flow_Refinement);
      Add_Evidence (Model, Id, Audit.Slice_Callable_Profile);
      Add_Evidence (Model, Id, Audit.Slice_Tagged_Dispatching);
      Add_Evidence (Model, Id, Audit.Slice_Overload_Resolution);
   end Add_Tagged_Evidence;

   procedure Add_Library_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 4) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Context_Clause_With_Use);
      Add_Evidence (Model, Id, Audit.Slice_Library_Unit_Subunit);
      Add_Evidence (Model, Id, Audit.Slice_Interfacing_Import_Export);
      Add_Evidence (Model, Id, Audit.Slice_Callable_Profile);
      Add_Evidence (Model, Id, Audit.Slice_Elaboration);
      Add_Evidence (Model, Id, Audit.Slice_Visibility_Name_Resolution);
   end Add_Library_Evidence;

   procedure Add_Protected_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 5) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Iterator_Loop_Parallel);
      Add_Evidence (Model, Id, Audit.Slice_Contract_Aspect);
      Add_Evidence (Model, Id, Audit.Slice_Interface_Synchronized);
      Add_Evidence (Model, Id, Audit.Slice_Flow_Refinement);
      Add_Evidence (Model, Id, Audit.Slice_Callable_Profile);
   end Add_Protected_Evidence;

   procedure Add_Representation_Evidence (Model : in out Audit.Evidence_Model; Id : Natural := 6) is
   begin
      Add_Evidence (Model, Id, Audit.Slice_Interfacing_Import_Export);
      Add_Evidence (Model, Id, Audit.Slice_Representation_Freezing);
      Add_Evidence (Model, Id, Audit.Slice_Record_Layout);
      Add_Evidence (Model, Id, Audit.Slice_Enumeration_Representation);
      Add_Evidence (Model, Id, Audit.Slice_Callable_Profile);
   end Add_Representation_Evidence;

   procedure Add_All_Ready_Scenarios
     (Scenarios : in out Audit.Scenario_Model;
      Evidence : in out Audit.Evidence_Model) is
   begin
      Add_Scenario
        (Scenarios, 1, Audit.Scenario_Private_Type_Full_View,
         "package private type full view representation aggregate assignment predicate");
      Add_Private_Type_Evidence (Evidence);

      Add_Scenario
        (Scenarios, 2, Audit.Scenario_Generic_Instantiation,
         "generic formal object subprogram body replay aggregate actual flow refinement");
      Add_Generic_Evidence (Evidence);

      Add_Scenario
        (Scenarios, 3, Audit.Scenario_Tagged_Interface_Dispatch,
         "tagged extension synchronized interface overriding dispatch contract class-wide conversion");
      Add_Tagged_Evidence (Evidence);

      Add_Scenario
        (Scenarios, 4, Audit.Scenario_Library_Separate_Body,
         "context private child limited with package body stub separate subunit imported callable");
      Add_Library_Evidence (Evidence);

      Add_Scenario
        (Scenarios, 5, Audit.Scenario_Task_Protected_Parallel,
         "protected synchronized interface volatile atomic global depends parallel loop");
      Add_Protected_Evidence (Evidence);

      Add_Scenario
        (Scenarios, 6, Audit.Scenario_Representation_Interfacing,
         "record layout enumeration representation convention import export stream conflict freezing");
      Add_Representation_Evidence (Evidence);
   end Add_All_Ready_Scenarios;

   procedure Expect_Status
     (Results : Audit.Audit_Model;
      Index : Positive;
      Status : Audit.Audit_Status) is
   begin
      Assert
        (Audit.Result_At (Results, Index).Status = Status,
         "unexpected end-to-end semantic scenario audit status");
   end Expect_Status;

   procedure Test_End_To_End_Source_Shaped_Scenarios_Are_Ready

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_All_Ready_Scenarios (Scenarios, Evidence);

      Results := Audit.Build (Scenarios, Evidence);

      Assert (Audit.Count (Results) = 6, "expected six end-to-end scenarios");
      Assert (Audit.End_To_End_Audit_Ready (Results), "end-to-end semantic audit should be ready");
      Assert (Results.Ready_Count = 6, "all semantic stories should be ready");
      Assert (Results.Blocked_Count = 0, "no semantic story should be blocked");
      for I in 1 .. 6 loop
         Expect_Status (Results, I, Audit.Status_Ready);
      end loop;
   end Test_End_To_End_Source_Shaped_Scenarios_Are_Ready;

   procedure Test_Missing_Required_Slice_Result_Blocks_Story

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_Scenario
        (Scenarios, 1, Audit.Scenario_Private_Type_Full_View,
         "private type missing aggregate slice result");
      Add_Evidence (Evidence, 1, Audit.Slice_Assignment_Conversion);
      Add_Evidence (Evidence, 1, Audit.Slice_Contract_Aspect);
      Add_Evidence (Evidence, 1, Audit.Slice_Representation_Freezing);
      Add_Evidence (Evidence, 1, Audit.Slice_Visibility_Name_Resolution);
      Add_Evidence (Evidence, 1, Audit.Slice_Accessibility_Lifetime);

      Results := Audit.Build (Scenarios, Evidence);

      Expect_Status (Results, 1, Audit.Status_Missing_Required_Slice_Result);
      Assert (Audit.Result_At (Results, 1).Blocking_Slice = Audit.Slice_Aggregate,
              "aggregate slice must be named as the missing source-story participant");
   end Test_Missing_Required_Slice_Result_Blocks_Story;

   procedure Test_Generic_Substitution_View_And_Profile_Disagreement_Block_Story

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_Scenario
        (Scenarios, 2, Audit.Scenario_Generic_Instantiation,
         "generic instantiation stale substitution and callable profile disagreement",
         Substitution_Propagated => False,
         View_Agrees => False,
         Overload_Profile_Agrees => False);
      Add_Generic_Evidence (Evidence);

      Results := Audit.Build (Scenarios, Evidence);

      Expect_Status (Results, 1, Audit.Status_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 3,
              "substitution, view, and overload/profile disagreement should all block");
   end Test_Generic_Substitution_View_And_Profile_Disagreement_Block_Story;

   procedure Test_Cross_Unit_Representation_Flow_And_Runtime_Blockers_Are_Audited

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_Scenario
        (Scenarios, 4, Audit.Scenario_Library_Separate_Body,
         "library separate body stale cross unit and representation disagreement",
         Cross_Unit_Fresh => False,
         Representation_Consistent => False);
      Add_Library_Evidence (Evidence);

      Results := Audit.Build (Scenarios, Evidence);
      Expect_Status (Results, 1, Audit.Status_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "cross-unit and representation/freezing blockers should both be retained");

      Scenarios.Items.Clear;
      Evidence.Items.Clear;
      Add_Scenario
        (Scenarios, 5, Audit.Scenario_Task_Protected_Parallel,
         "protected parallel story flow effect unconsumed and runtime check lost",
         Flow_Consumed => False,
         Runtime_Check_Preserved => False);
      Add_Protected_Evidence (Evidence);

      Results := Audit.Build (Scenarios, Evidence);
      Expect_Status (Results, 1, Audit.Status_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "flow/effect and runtime-check blockers should both be retained");
   end Test_Cross_Unit_Representation_Flow_And_Runtime_Blockers_Are_Audited;

   procedure Test_Unconsumed_Or_Stale_Slice_Result_Blocks_Story

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_Scenario
        (Scenarios, 6, Audit.Scenario_Representation_Interfacing,
         "representation interfacing story with stale record layout consumer fingerprint");
      Add_Evidence (Evidence, 6, Audit.Slice_Interfacing_Import_Export);
      Add_Evidence (Evidence, 6, Audit.Slice_Representation_Freezing);
      Add_Evidence (Evidence, 6, Audit.Slice_Record_Layout,
                    Expected_Result_FP => 42);
      Add_Evidence (Evidence, 6, Audit.Slice_Enumeration_Representation,
                    Consumed => False);
      Add_Evidence (Evidence, 6, Audit.Slice_Callable_Profile);

      Results := Audit.Build (Scenarios, Evidence);

      Expect_Status (Results, 1, Audit.Status_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 2,
              "unconsumed enum representation and stale record layout result should both block");
   end Test_Unconsumed_Or_Stale_Slice_Result_Blocks_Story;

   procedure Test_Non_Source_Shaped_And_Unstable_Blocker_Family_Are_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Scenarios : Audit.Scenario_Model;
      Evidence : Audit.Evidence_Model;
      Results : Audit.Audit_Model;
   begin
      Add_Scenario
        (Scenarios, 3, Audit.Scenario_Tagged_Interface_Dispatch,
         "synthetic tagged dispatch closure row without source story",
         Source_Shaped => False,
         Blocker_Family_Stable => False,
         Expected_Consumer_FP => 99);
      Add_Tagged_Evidence (Evidence);

      Results := Audit.Build (Scenarios, Evidence);

      Expect_Status (Results, 1, Audit.Status_Multiple_Blockers);
      Assert (Audit.Result_At (Results, 1).Blocker_Count >= 3,
              "non-source-shaped story, unstable blocker family, and stale consumer fingerprint should block");
   end Test_Non_Source_Shaped_And_Unstable_Blocker_Family_Are_Rejected;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_End_To_End_Source_Shaped_Scenarios_Are_Ready'Access,
         "end-to-end source-shaped scenarios are ready");
      Register_Routine
        (T, Test_Missing_Required_Slice_Result_Blocks_Story'Access,
         "missing required slice result blocks story");
      Register_Routine
        (T, Test_Generic_Substitution_View_And_Profile_Disagreement_Block_Story'Access,
         "generic substitution view and profile disagreement block story");
      Register_Routine
        (T, Test_Cross_Unit_Representation_Flow_And_Runtime_Blockers_Are_Audited'Access,
         "cross-unit representation flow and runtime blockers audited");
      Register_Routine
        (T, Test_Unconsumed_Or_Stale_Slice_Result_Blocks_Story'Access,
         "unconsumed or stale slice result blocks story");
      Register_Routine
        (T, Test_Non_Source_Shaped_And_Unstable_Blocker_Family_Are_Rejected'Access,
         "non-source-shaped and unstable blocker family rejected");
   end Register_Tests;

end Test_Ada_End_To_End_Semantic_Scenario_Audit;
