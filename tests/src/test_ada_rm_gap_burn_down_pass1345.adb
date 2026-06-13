with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1345;

package body Test_Ada_RM_Gap_Burn_Down_Pass1345 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1345;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Context_Item_Kind;
   use type Audit.Library_Unit_Kind;
   use type Audit.Elaboration_Context_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1345");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Context_Library_Elaboration;
      Context_Item : Audit.Context_Item_Kind := Audit.Context_With_Clause;
      Unit_Kind : Audit.Library_Unit_Kind := Audit.Unit_Package_Spec;
      Elaboration_Context : Audit.Elaboration_Context_Kind := Audit.Elab_None;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Library_Unit_Subunit;
      Previous_State : Audit.Remediation_State := Remediation.State_Partial;
      Matrix_Before : Audit.Coverage_Level := Matrix.Coverage_Partial;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Remediation_Present : Boolean := True;
      Matrix_Present : Boolean := True;
      Package_Present : Boolean := True;
      New_Rule : Boolean := True;
      Coverage_Updated : Boolean := True;
      Corpus_Balanced : Boolean := True;
      Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker : Boolean := True;
      Context_Target_Resolved : Boolean := True;
      Unit_Name_Matches : Boolean := True;
      Duplicate_With : Boolean := False;
      Duplicate_Use : Boolean := False;
      Private_With_Placement_Legal : Boolean := True;
      Private_Child_Visibility_Allowed : Boolean := True;
      Full_View_Through_Limited : Boolean := False;
      Nonlimited_Cycle : Boolean := False;
      Limited_Cycle_Only_Limited_Views : Boolean := True;
      Library_Unit_Present : Boolean := True;
      Body_Spec_Kind_Conformant : Boolean := True;
      Body_Spec_Profile_Conformant : Boolean := True;
      Body_Completion_Present : Boolean := True;
      Duplicate_Body : Boolean := False;
      Body_Order_Legal : Boolean := True;
      Private_Child_Spec_Present : Boolean := True;
      Body_Stub_Present : Boolean := True;
      Separate_Body_Has_Matching_Stub : Boolean := True;
      Stub_Parent_Matches : Boolean := True;
      Separate_Parent_Matches : Boolean := True;
      Nested_Separate_Parent_Matches : Boolean := True;
      Duplicate_Subunit : Boolean := False;
      Inherited_Context_Visible : Boolean := True;
      Cross_Unit_View_Propagated : Boolean := True;
      Pragma_Elaborate_Satisfied : Boolean := True;
      Pragma_Elaborate_All_Satisfied : Boolean := True;
      Preelaborate_Restrictions_Satisfied : Boolean := True;
      Pure_Restrictions_Satisfied : Boolean := True;
      Call_Before_Body_Elaboration : Boolean := False;
      Elaboration_Dependency_Cycle : Boolean := False;
      Generic_Body_Available : Boolean := True;
      Runtime_Elaboration_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Consumer_Unit_Agrees : Boolean := True;
      Consumer_Completion_Agrees : Boolean := True;
      Consumer_View_Agrees : Boolean := True;
      Consumer_Elaboration_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_View_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0;
      Expected_Elaboration_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_345_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Library_Context_Subunits_Elaboration;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Context_Item := Context_Item;
      Row.Unit_Kind := Unit_Kind;
      Row.Elaboration_Context := Elaboration_Context;
      Row.Name := To_Unbounded_String ("context library elaboration burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1345");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_345_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Remediation_Entry_Present := Remediation_Present;
      Row.Matrix_Coverage_Present := Matrix_Present;
      Row.Implementing_Package_Present := Package_Present;
      Row.New_Legality_Rule_Added := New_Rule;
      Row.Coverage_Entry_Updated_To_Covered := Coverage_Updated;
      Row.Balanced_Regression_Evidence := Corpus_Balanced;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Reached := Consumer_Reached;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Context_Target_Resolved := Context_Target_Resolved;
      Row.Unit_Name_Matches := Unit_Name_Matches;
      Row.Duplicate_With_Clause := Duplicate_With;
      Row.Duplicate_Use_Clause := Duplicate_Use;
      Row.Private_With_Placement_Legal := Private_With_Placement_Legal;
      Row.Private_Child_Visibility_Allowed := Private_Child_Visibility_Allowed;
      Row.Full_View_Used_Through_Limited_With := Full_View_Through_Limited;
      Row.Nonlimited_Dependency_Cycle := Nonlimited_Cycle;
      Row.Limited_With_Cycle_Uses_Only_Limited_Views := Limited_Cycle_Only_Limited_Views;
      Row.Library_Unit_Present := Library_Unit_Present;
      Row.Body_Spec_Kind_Conformant := Body_Spec_Kind_Conformant;
      Row.Body_Spec_Profile_Conformant := Body_Spec_Profile_Conformant;
      Row.Body_Completion_Present := Body_Completion_Present;
      Row.Duplicate_Body := Duplicate_Body;
      Row.Body_Order_Legal := Body_Order_Legal;
      Row.Private_Child_Spec_Present := Private_Child_Spec_Present;
      Row.Body_Stub_Present := Body_Stub_Present;
      Row.Separate_Body_Has_Matching_Stub := Separate_Body_Has_Matching_Stub;
      Row.Stub_Parent_Matches := Stub_Parent_Matches;
      Row.Separate_Parent_Matches := Separate_Parent_Matches;
      Row.Nested_Separate_Parent_Matches := Nested_Separate_Parent_Matches;
      Row.Duplicate_Subunit := Duplicate_Subunit;
      Row.Inherited_Context_Visible := Inherited_Context_Visible;
      Row.Cross_Unit_View_Propagated := Cross_Unit_View_Propagated;
      Row.Pragma_Elaborate_Satisfied := Pragma_Elaborate_Satisfied;
      Row.Pragma_Elaborate_All_Satisfied := Pragma_Elaborate_All_Satisfied;
      Row.Preelaborate_Restrictions_Satisfied := Preelaborate_Restrictions_Satisfied;
      Row.Pure_Restrictions_Satisfied := Pure_Restrictions_Satisfied;
      Row.Call_Before_Body_Elaboration := Call_Before_Body_Elaboration;
      Row.Elaboration_Dependency_Cycle := Elaboration_Dependency_Cycle;
      Row.Generic_Body_Available := Generic_Body_Available;
      Row.Runtime_Elaboration_Check := Runtime_Elaboration_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Consumer_Unit_Model_Agrees := Consumer_Unit_Agrees;
      Row.Consumer_Completion_Model_Agrees := Consumer_Completion_Agrees;
      Row.Consumer_View_Model_Agrees := Consumer_View_Agrees;
      Row.Consumer_Elaboration_Model_Agrees := Consumer_Elaboration_Agrees;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Burn_Down_Fingerprint := FP + 1;
      Row.Expected_Burn_Down_Fingerprint :=
        (if Expected_Burn_FP = 0 then Row.Burn_Down_Fingerprint else Expected_Burn_FP);
      Row.Source_Fingerprint := FP + 2;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 3;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Unit_Fingerprint := FP + 4;
      Row.Expected_Unit_Fingerprint :=
        (if Expected_Unit_FP = 0 then Row.Unit_Fingerprint else Expected_Unit_FP);
      Row.View_Fingerprint := FP + 5;
      Row.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then Row.View_Fingerprint else Expected_View_FP);
      Row.Closure_Fingerprint := FP + 6;
      Row.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Row.Closure_Fingerprint else Expected_Closure_FP);
      Row.Elaboration_Fingerprint := FP + 7;
      Row.Expected_Elaboration_Fingerprint :=
        (if Expected_Elaboration_FP = 0 then Row.Elaboration_Fingerprint else Expected_Elaboration_FP);
      Row.Consumer_Fingerprint := FP + 8;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Status = Status,
         "unexpected RM cross-unit burn-down status");
   end Expect_Status;

   procedure Expect_Class
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Class : Audit.Precision_Classification) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Classification = Class,
         "unexpected RM cross-unit burn-down classification");
   end Expect_Class;

   procedure Test_Context_Library_Elaboration_Gap_Is_Burned_Down

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row
        (Input, 1, Precision.Class_Legal,
         Context_Item => Audit.Context_Limited_With_Clause,
         Unit_Kind => Audit.Unit_Package_Spec);
      Add_Row
        (Input, 2, Precision.Class_Illegal,
         Duplicate_With => True,
         Context_Item => Audit.Context_With_Clause);
      Add_Row
        (Input, 3, Precision.Class_Legal_With_Runtime_Check,
         Runtime_Elaboration_Check => True,
         Elaboration_Context => Audit.Elab_Call_Before_Body);
      Add_Row
        (Input, 4, Precision.Class_Indeterminate,
         Missing_Cross_Unit => True,
         Unit_Kind => Audit.Unit_Private_Child);

      Results := Audit.Build (Input);

      Assert (Audit.Count (Results) = 4, "expected four cross-unit burn-down rows");
      Assert (Results.Burned_Down_Count = 4, "all cross-unit rows should be burned down");
      Assert (Results.Invalid_Count = 0, "cross-unit rows should be valid");
      Assert (Results.Legal_Count = 1, "legal cross-unit row should be counted");
      Assert (Results.Illegal_Count = 1, "illegal cross-unit row should be counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime cross-unit row should be counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate cross-unit row should be counted");
      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced cross-unit burn-down evidence should be ready");
      Assert (Audit.Context_Library_Elaboration_Gap_Closed (Results),
              "context/library/elaboration gap should be closed");
   end Test_Context_Library_Elaboration_Gap_Is_Burned_Down;

   procedure Test_Context_Clause_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal, Duplicate_With => True);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Duplicate_Use => True,
               Context_Item => Audit.Context_Use_Package_Clause);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Context_Target_Resolved => False);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Unit_Name_Matches => False);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Private_With_Placement_Legal => False,
               Context_Item => Audit.Context_Private_With_Clause);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Private_Child_Visibility_Allowed => False,
               Unit_Kind => Audit.Unit_Private_Child);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Full_View_Through_Limited => True,
               Context_Item => Audit.Context_Limited_With_Clause);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Nonlimited_Cycle => True);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Limited_Cycle_Only_Limited_Views => False,
               Context_Item => Audit.Context_Limited_With_Clause);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Duplicate_With_Clause);
      Expect_Status (Results, 2, Audit.Status_Illegal_Duplicate_Use_Clause);
      Expect_Status (Results, 3, Audit.Status_Illegal_Context_Target_Unresolved);
      Expect_Status (Results, 4, Audit.Status_Illegal_Unit_Name_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_Private_With_Placement);
      Expect_Status (Results, 6, Audit.Status_Illegal_Private_Child_Visibility_Leak);
      Expect_Status (Results, 7, Audit.Status_Illegal_Full_View_Use_Through_Limited_With);
      Expect_Status (Results, 8, Audit.Status_Illegal_Nonlimited_Dependency_Cycle);
      Expect_Status (Results, 9, Audit.Status_Illegal_Limited_Cycle_Full_View_Leak);
      Assert (Results.Invalid_Count = 0, "context clause rows should be valid evidence");
   end Test_Context_Clause_Rules_Are_Enforced;

   procedure Test_Library_Units_And_Subunits_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Library_Unit_Present => False);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Body_Spec_Kind_Conformant => False,
               Unit_Kind => Audit.Unit_Package_Body);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Body_Spec_Profile_Conformant => False,
               Unit_Kind => Audit.Unit_Subprogram_Body);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Body_Completion_Present => False,
               Unit_Kind => Audit.Unit_Package_Body);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Duplicate_Body => True,
               Unit_Kind => Audit.Unit_Package_Body);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Body_Order_Legal => False,
               Unit_Kind => Audit.Unit_Subprogram_Body);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Private_Child_Spec_Present => False,
               Unit_Kind => Audit.Unit_Private_Child);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Body_Stub_Present => False,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Separate_Body_Has_Matching_Stub => False,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 10, Precision.Class_Illegal,
               Stub_Parent_Matches => False,
               Unit_Kind => Audit.Unit_Body_Stub);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Separate_Parent_Matches => False,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Nested_Separate_Parent_Matches => False,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Duplicate_Subunit => True,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Inherited_Context_Visible => False,
               Unit_Kind => Audit.Unit_Separate_Subunit);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Cross_Unit_View_Propagated => False,
               Unit_Kind => Audit.Unit_Child_Package);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Missing_Library_Unit);
      Expect_Status (Results, 2, Audit.Status_Illegal_Body_Spec_Kind_Mismatch);
      Expect_Status (Results, 3, Audit.Status_Illegal_Body_Spec_Profile_Mismatch);
      Expect_Status (Results, 4, Audit.Status_Illegal_Missing_Completion);
      Expect_Status (Results, 5, Audit.Status_Illegal_Duplicate_Body);
      Expect_Status (Results, 6, Audit.Status_Illegal_Body_Order);
      Expect_Status (Results, 7, Audit.Status_Illegal_Private_Child_Spec_Missing);
      Expect_Status (Results, 8, Audit.Status_Illegal_Separate_Without_Stub);
      Expect_Status (Results, 9, Audit.Status_Illegal_Separate_Without_Stub);
      Expect_Status (Results, 10, Audit.Status_Illegal_Stub_Parent_Mismatch);
      Expect_Status (Results, 11, Audit.Status_Illegal_Separate_Parent_Mismatch);
      Expect_Status (Results, 12, Audit.Status_Illegal_Nested_Separate_Parent_Mismatch);
      Expect_Status (Results, 13, Audit.Status_Illegal_Duplicate_Subunit);
      Expect_Status (Results, 14, Audit.Status_Illegal_Inherited_Context_Missing);
      Expect_Status (Results, 15, Audit.Status_Illegal_Cross_Unit_View_Not_Propagated);
      Assert (Results.Invalid_Count = 0, "library/subunit rows should be valid evidence");
   end Test_Library_Units_And_Subunits_Are_Enforced;

   procedure Test_Elaboration_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Pragma_Elaborate_Satisfied => False,
               Elaboration_Context => Audit.Elab_Pragma_Elaborate,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Pragma_Elaborate_All_Satisfied => False,
               Elaboration_Context => Audit.Elab_Pragma_Elaborate_All,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Preelaborate_Restrictions_Satisfied => False,
               Elaboration_Context => Audit.Elab_Preelaborate_Unit,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Pure_Restrictions_Satisfied => False,
               Elaboration_Context => Audit.Elab_Pure_Unit,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Call_Before_Body_Elaboration => True,
               Elaboration_Context => Audit.Elab_Call_Before_Body,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Elaboration_Dependency_Cycle => True,
               Elaboration_Context => Audit.Elab_Dependency_Cycle,
               Owner => Matrix.Slice_Elaboration);
      Add_Row (Input, 7, Precision.Class_Illegal,
               Generic_Body_Available => False,
               Elaboration_Context => Audit.Elab_Generic_Body_Availability,
               Owner => Matrix.Slice_Elaboration);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Pragma_Elaborate_Not_Satisfied);
      Expect_Status (Results, 2, Audit.Status_Illegal_Pragma_Elaborate_All_Not_Satisfied);
      Expect_Status (Results, 3, Audit.Status_Illegal_Preelaborate_Restriction);
      Expect_Status (Results, 4, Audit.Status_Illegal_Pure_Restriction);
      Expect_Status (Results, 5, Audit.Status_Illegal_Call_Before_Body_Elaboration);
      Expect_Status (Results, 6, Audit.Status_Illegal_Elaboration_Dependency_Cycle);
      Expect_Status (Results, 7, Audit.Status_Illegal_Generic_Body_Unavailable);
      Assert (Results.Invalid_Count = 0, "elaboration rows should be valid evidence");
   end Test_Elaboration_Rules_Are_Enforced;

   procedure Test_Runtime_And_Indeterminate_Cross_Unit_Cases_Are_Preserved

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Elaboration_Check => True);
      Add_Row (Input, 2, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Elaboration_Check => True,
               Runtime_Check_Preserved => False);
      Add_Row (Input, 3, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 5, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 6, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 7, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 8, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Runtime_Elaboration_Check_Preserved);
      Expect_Status (Results, 2, Audit.Status_Runtime_Check_Evidence_Lost);
      Expect_Status (Results, 3, Audit.Status_Indeterminate_Private_View);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Limited_View);
      Expect_Status (Results, 5, Audit.Status_Indeterminate_Incomplete_View);
      Expect_Status (Results, 6, Audit.Status_Indeterminate_Generic_Formal_View);
      Expect_Status (Results, 7, Audit.Status_Indeterminate_Missing_Full_View);
      Expect_Status (Results, 8, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence);
      Assert (Results.Invalid_Count = 1, "lost runtime-check evidence should invalidate only one row");
   end Test_Runtime_And_Indeterminate_Cross_Unit_Cases_Are_Preserved;

   procedure Test_Remediation_Consumer_Fingerprint_And_Classification_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 2, Precision.Class_Legal,
               Matrix_Present => False);
      Add_Row (Input, 3, Precision.Class_Legal,
               Package_Present => False);
      Add_Row (Input, 4, Precision.Class_Legal,
               New_Rule => False);
      Add_Row (Input, 5, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 6, Precision.Class_Legal,
               Corpus_Balanced => False);
      Add_Row (Input, 7, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 8, Precision.Class_Legal,
               Consumer_Reached => False);
      Add_Row (Input, 9, Precision.Class_Legal,
               Consumer_Unit_Agrees => False);
      Add_Row (Input, 10, Precision.Class_Legal,
               Consumer_Completion_Agrees => False);
      Add_Row (Input, 11, Precision.Class_Legal,
               Consumer_View_Agrees => False);
      Add_Row (Input, 12, Precision.Class_Legal,
               Consumer_Elaboration_Agrees => False);
      Add_Row (Input, 13, Precision.Class_Legal,
               Duplicate_With => True);
      Add_Row (Input, 14, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 15, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 16, Precision.Class_Legal,
               Expected_Source_FP => 1);
      Add_Row (Input, 17, Precision.Class_Legal,
               Expected_AST_FP => 1);
      Add_Row (Input, 18, Precision.Class_Legal,
               Expected_Unit_FP => 1);
      Add_Row (Input, 19, Precision.Class_Legal,
               Expected_View_FP => 1);
      Add_Row (Input, 20, Precision.Class_Legal,
               Expected_Closure_FP => 1);
      Add_Row (Input, 21, Precision.Class_Legal,
               Expected_Elaboration_FP => 1);
      Add_Row (Input, 22, Precision.Class_Legal,
               Expected_Consumer_FP => 1);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Missing_Remediation_Evidence);
      Expect_Status (Results, 2, Audit.Status_Missing_Matrix_Coverage);
      Expect_Status (Results, 3, Audit.Status_Missing_Implementing_Package);
      Expect_Status (Results, 4, Audit.Status_No_New_Legality_Rule);
      Expect_Status (Results, 5, Audit.Status_Coverage_Not_Updated_To_Covered);
      Expect_Status (Results, 6, Audit.Status_Regression_Corpus_Not_Balanced);
      Expect_Status (Results, 7, Audit.Status_Semantic_Result_Unconsumed);
      Expect_Status (Results, 8, Audit.Status_Consumer_Not_Reached);
      Expect_Status (Results, 9, Audit.Status_Consumer_Unit_Model_Disagreement);
      Expect_Status (Results, 10, Audit.Status_Consumer_Completion_Model_Disagreement);
      Expect_Status (Results, 11, Audit.Status_Consumer_View_Model_Disagreement);
      Expect_Status (Results, 12, Audit.Status_Consumer_Elaboration_Model_Disagreement);
      Expect_Status (Results, 13, Audit.Status_Unexpected_Classification);
      Expect_Status (Results, 14, Audit.Status_Stale_Burn_Down_Fingerprint);
      Expect_Status (Results, 15, Audit.Status_Source_Shaped_Evidence_Missing);
      Expect_Status (Results, 16, Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, 17, Audit.Status_AST_Fingerprint_Mismatch);
      Expect_Status (Results, 18, Audit.Status_Unit_Fingerprint_Mismatch);
      Expect_Status (Results, 19, Audit.Status_View_Fingerprint_Mismatch);
      Expect_Status (Results, 20, Audit.Status_Closure_Fingerprint_Mismatch);
      Expect_Status (Results, 21, Audit.Status_Elaboration_Fingerprint_Mismatch);
      Expect_Status (Results, 22, Audit.Status_Consumer_Fingerprint_Mismatch);
      Expect_Class (Results, 13, Precision.Class_Illegal);
      Assert (Results.Invalid_Count = 22,
              "all remediation/fingerprint/classification gate rows should be invalid");
   end Test_Remediation_Consumer_Fingerprint_And_Classification_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Context_Library_Elaboration_Gap_Is_Burned_Down'Access,
         "context library elaboration gap is burned down");
      Register_Routine
        (T, Test_Context_Clause_Rules_Are_Enforced'Access,
         "context clause rules are enforced");
      Register_Routine
        (T, Test_Library_Units_And_Subunits_Are_Enforced'Access,
         "library units and subunits are enforced");
      Register_Routine
        (T, Test_Elaboration_Rules_Are_Enforced'Access,
         "elaboration rules are enforced");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Cross_Unit_Cases_Are_Preserved'Access,
         "runtime and indeterminate cross-unit cases are preserved");
      Register_Routine
        (T, Test_Remediation_Consumer_Fingerprint_And_Classification_Gates'Access,
         "remediation consumer fingerprint and classification gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1345;
