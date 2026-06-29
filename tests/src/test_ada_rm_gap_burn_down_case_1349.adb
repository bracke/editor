with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1349;

package body Test_Ada_RM_Gap_Burn_Down_Case_1349 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1349;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Name_Construct_Kind;
   use type Audit.Resolution_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Name_Visibility_Attribute_Selector;
      Construct : Audit.Name_Construct_Kind := Audit.Construct_Direct_Name;
      Context : Audit.Resolution_Context_Kind := Audit.Context_Direct_Visibility;
      Family : Audit.RM_Family := Matrix.Family_Names_Visibility_Selected_Attributes;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Visibility_Name_Resolution;
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
      Direct_Visibility : Boolean := True;
      Selected_Prefix_Visible : Boolean := True;
      Private_Child_Visibility : Boolean := True;
      Homographs_Disambiguated : Boolean := True;
      Use_Package_Homographs_Overloadable : Boolean := True;
      Use_Type_Operators_Visible : Boolean := True;
      Selector_Exists : Boolean := True;
      Selector_Ambiguous : Boolean := False;
      Attribute_Prefix_Kind_Compatible : Boolean := True;
      Attribute_Static_Requirement_Satisfied : Boolean := True;
      Attribute_Result_Type_Compatible : Boolean := True;
      Explicit_Deref_Access_Prefix : Boolean := True;
      Implicit_Deref_Allowed : Boolean := True;
      Null_Deref_Runtime_Check : Boolean := False;
      Index_Count_Compatible : Boolean := True;
      Index_Type_Compatible : Boolean := True;
      Index_Bounds_Runtime_Check : Boolean := False;
      Generalized_Profile_Present : Boolean := True;
      Generalized_Profile_Compatible : Boolean := True;
      Generalized_Runtime_Check : Boolean := False;
      Component_Type_Compatible : Boolean := True;
      Overload_Set_Canonical : Boolean := True;
      Expected_Type_Propagated : Boolean := True;
      Callable_Profile_Agrees : Boolean := True;
      Visible_Candidate_Present : Boolean := True;
      Overload_Ambiguous : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Overload : Boolean := False;
      Consumer_Name_Agrees : Boolean := True;
      Consumer_Entity_Agrees : Boolean := True;
      Consumer_View_Agrees : Boolean := True;
      Consumer_Attribute_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Entity_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_View_FP : Natural := 0;
      Expected_Overload_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_349_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Family;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("name visibility attribute burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1349");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_349_000 + Id);
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
      Row.Direct_Visibility_Agrees := Direct_Visibility;
      Row.Selected_Prefix_Visible := Selected_Prefix_Visible;
      Row.Private_Child_Visibility_Respected := Private_Child_Visibility;
      Row.Hiding_Homographs_Disambiguated := Homographs_Disambiguated;
      Row.Use_Package_Homographs_Overloadable := Use_Package_Homographs_Overloadable;
      Row.Use_Type_Operators_Visible := Use_Type_Operators_Visible;
      Row.Selector_Exists := Selector_Exists;
      Row.Selector_Ambiguous := Selector_Ambiguous;
      Row.Attribute_Prefix_Kind_Compatible := Attribute_Prefix_Kind_Compatible;
      Row.Attribute_Static_Requirement_Satisfied := Attribute_Static_Requirement_Satisfied;
      Row.Attribute_Result_Type_Compatible := Attribute_Result_Type_Compatible;
      Row.Explicit_Dereference_Access_Prefix := Explicit_Deref_Access_Prefix;
      Row.Implicit_Dereference_Allowed := Implicit_Deref_Allowed;
      Row.Null_Dereference_Runtime_Check := Null_Deref_Runtime_Check;
      Row.Index_Count_Compatible := Index_Count_Compatible;
      Row.Index_Type_Compatible := Index_Type_Compatible;
      Row.Index_Bounds_Runtime_Check := Index_Bounds_Runtime_Check;
      Row.Generalized_Indexing_Profile_Present := Generalized_Profile_Present;
      Row.Generalized_Indexing_Profile_Compatible := Generalized_Profile_Compatible;
      Row.Generalized_Indexing_Runtime_Check := Generalized_Runtime_Check;
      Row.Component_Selection_Type_Compatible := Component_Type_Compatible;
      Row.Overload_Set_Canonical := Overload_Set_Canonical;
      Row.Expected_Type_Propagated := Expected_Type_Propagated;
      Row.Callable_Profile_Agrees := Callable_Profile_Agrees;
      Row.Visible_Candidate_Present := Visible_Candidate_Present;
      Row.Overload_Ambiguous := Overload_Ambiguous;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View_Evidence := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Overload_Evidence := Missing_Overload;
      Row.Consumer_Name_Model_Agrees := Consumer_Name_Agrees;
      Row.Consumer_Entity_Model_Agrees := Consumer_Entity_Agrees;
      Row.Consumer_View_Model_Agrees := Consumer_View_Agrees;
      Row.Consumer_Attribute_Model_Agrees := Consumer_Attribute_Agrees;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
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
      Row.Entity_Fingerprint := FP + 4;
      Row.Expected_Entity_Fingerprint :=
        (if Expected_Entity_FP = 0 then Row.Entity_Fingerprint else Expected_Entity_FP);
      Row.Type_Fingerprint := FP + 5;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Profile_Fingerprint := FP + 6;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.View_Fingerprint := FP + 7;
      Row.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then Row.View_Fingerprint else Expected_View_FP);
      Row.Overload_Fingerprint := FP + 8;
      Row.Expected_Overload_Fingerprint :=
        (if Expected_Overload_FP = 0 then Row.Overload_Fingerprint else Expected_Overload_FP);
      Row.Consumer_Fingerprint := FP + 9;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Classification : Audit.Precision_Classification) is
      R : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (R.Status = Status, "unexpected status for row" & Natural'Image (Id));
      Assert (R.Classification = Classification,
              "unexpected classification for row" & Natural'Image (Id));
   end Expect_Status;

   procedure Test_Balanced_Name_Visibility_Attribute_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Selected_Name,
               Context => Audit.Context_Selected_Visibility,
               Owner => Matrix.Slice_Selected_Name_Attribute,
               Consumer => Consumers.Consumer_Semantic_Navigation);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Construct => Audit.Construct_Private_Child_Name,
               Context => Audit.Context_Child_Visibility,
               Private_Child_Visibility => False);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Explicit_Dereference,
               Context => Audit.Context_Dereference,
               Null_Deref_Runtime_Check => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Construct => Audit.Construct_Selected_Name,
               Private_View => True);

      Results := Audit.Build (Input);

      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced name/visibility/attribute gap is ready");
      Assert (Audit.Name_Visibility_Attribute_Gap_Closed (Results),
              "target name/visibility/attribute gap closed");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Private_Child_Visibility_Leak,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Null_Dereference_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
   end Test_Balanced_Name_Visibility_Attribute_Gap_Closes;

   procedure Test_Visibility_Selector_And_Use_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Direct_Visibility => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Construct => Audit.Construct_Selected_Name,
               Context => Audit.Context_Selected_Visibility,
               Selected_Prefix_Visible => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Construct => Audit.Construct_Private_Child_Name,
               Private_Child_Visibility => False);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Homographs_Disambiguated => False);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Construct => Audit.Construct_Use_Package_Clause,
               Context => Audit.Context_Use_Visibility,
               Use_Package_Homographs_Overloadable => False);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Construct => Audit.Construct_Use_Type_Clause,
               Use_Type_Operators_Visible => False);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Construct => Audit.Construct_Component_Selection,
               Selector_Exists => False);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Selector_Ambiguous => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Name_Not_Directly_Visible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Selected_Prefix_Not_Visible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Private_Child_Visibility_Leak,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Homograph_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Use_Visible_Homograph,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Use_Type_Operator_Not_Visible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Selector_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17, Audit.Status_Illegal_Ambiguous_Selector,
                     Precision.Class_Illegal);
   end Test_Visibility_Selector_And_Use_Blockers;

   procedure Test_Attribute_Dereference_Indexing_And_Overload_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Construct => Audit.Construct_Attribute_Reference,
               Context => Audit.Context_Attribute_Prefix,
               Owner => Matrix.Slice_Selected_Name_Attribute,
               Attribute_Prefix_Kind_Compatible => False);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Construct => Audit.Construct_Attribute_Reference,
               Attribute_Static_Requirement_Satisfied => False);
      Add_Row (Input, 32, Precision.Class_Illegal,
               Construct => Audit.Construct_Attribute_Reference,
               Attribute_Result_Type_Compatible => False);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Construct => Audit.Construct_Explicit_Dereference,
               Explicit_Deref_Access_Prefix => False);
      Add_Row (Input, 34, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Explicit_Dereference,
               Null_Deref_Runtime_Check => True);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Construct => Audit.Construct_Array_Indexing,
               Context => Audit.Context_Indexing,
               Index_Count_Compatible => False);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Construct => Audit.Construct_Array_Indexing,
               Index_Type_Compatible => False);
      Add_Row (Input, 37, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Array_Indexing,
               Index_Bounds_Runtime_Check => True);
      Add_Row (Input, 38, Precision.Class_Illegal,
               Construct => Audit.Construct_Generalized_Indexing,
               Generalized_Profile_Present => False);
      Add_Row (Input, 39, Precision.Class_Illegal,
               Construct => Audit.Construct_Generalized_Indexing,
               Generalized_Profile_Compatible => False);
      Add_Row (Input, 40, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Generalized_Indexing,
               Generalized_Runtime_Check => True);
      Add_Row (Input, 41, Precision.Class_Illegal,
               Construct => Audit.Construct_Component_Selection,
               Component_Type_Compatible => False);
      Add_Row (Input, 42, Precision.Class_Illegal,
               Context => Audit.Context_Overload,
               Owner => Matrix.Slice_Overload_Resolution,
               Overload_Set_Canonical => False);
      Add_Row (Input, 43, Precision.Class_Illegal,
               Context => Audit.Context_Expected_Type,
               Expected_Type_Propagated => False);
      Add_Row (Input, 44, Precision.Class_Illegal,
               Owner => Matrix.Slice_Callable_Profile,
               Callable_Profile_Agrees => False);
      Add_Row (Input, 45, Precision.Class_Illegal,
               Visible_Candidate_Present => False);
      Add_Row (Input, 46, Precision.Class_Illegal,
               Overload_Ambiguous => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Attribute_Prefix_Kind_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Attribute_Static_Requirement_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Attribute_Result_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Illegal_Dereference_Non_Access_Prefix,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34,
                     Audit.Status_Runtime_Null_Dereference_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 35, Audit.Status_Illegal_Index_Count_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Array_Index_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37, Audit.Status_Runtime_Index_Bounds_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Generalized_Indexing_Profile_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Generalized_Indexing_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 40,
                     Audit.Status_Runtime_Generalized_Indexing_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Component_Selection_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Illegal_Overload_Set_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43, Audit.Status_Illegal_Expected_Type_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 44, Audit.Status_Illegal_Callable_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 45, Audit.Status_Illegal_No_Visible_Candidate,
                     Precision.Class_Illegal);
      Expect_Status (Results, 46, Audit.Status_Illegal_Ambiguous_Overload,
                     Precision.Class_Illegal);
   end Test_Attribute_Dereference_Indexing_And_Overload_Blockers;

   procedure Test_Indeterminate_Views_Consumers_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 60, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 61, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 62, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 63, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 64, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 65, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);
      Add_Row (Input, 66, Precision.Class_Indeterminate,
               Missing_Overload => True);
      Add_Row (Input, 67, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 68, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 69, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 70, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 71, Precision.Class_Legal,
               Consumer_Name_Agrees => False);
      Add_Row (Input, 72, Precision.Class_Legal,
               Consumer_Entity_Agrees => False);
      Add_Row (Input, 73, Precision.Class_Legal,
               Consumer_View_Agrees => False);
      Add_Row (Input, 74, Precision.Class_Legal,
               Consumer_Attribute_Agrees => False);
      Add_Row (Input, 75, Precision.Class_Illegal,
               Selector_Exists => False,
               Stable_Blocker => False);
      Add_Row (Input, 76, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 77, Precision.Class_Legal,
               Expected_Entity_FP => 42);
      Add_Row (Input, 78, Precision.Class_Legal,
               Expected_Overload_FP => 42);

      Results := Audit.Build (Input);

      Expect_Status (Results, 60, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 61, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 62, Audit.Status_Indeterminate_Incomplete_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 63, Audit.Status_Indeterminate_Generic_Formal_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 64, Audit.Status_Indeterminate_Missing_Full_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 65,
                     Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 66, Audit.Status_Indeterminate_Missing_Overload_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 67).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped name evidence rejected");
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing remediation evidence rejected");
      Assert (Audit.Result_For (Results, 69).Status =
              Audit.Status_Coverage_Not_Updated_To_Covered,
              "coverage promotion gate enforced");
      Assert (Audit.Result_For (Results, 70).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed name result rejected");
      Assert (Audit.Result_For (Results, 71).Status =
              Audit.Status_Consumer_Name_Model_Disagreement,
              "consumer name disagreement rejected");
      Assert (Audit.Result_For (Results, 72).Status =
              Audit.Status_Consumer_Entity_Model_Disagreement,
              "consumer entity disagreement rejected");
      Assert (Audit.Result_For (Results, 73).Status =
              Audit.Status_Consumer_View_Model_Disagreement,
              "consumer view disagreement rejected");
      Assert (Audit.Result_For (Results, 74).Status =
              Audit.Status_Consumer_Attribute_Model_Disagreement,
              "consumer attribute disagreement rejected");
      Assert (Audit.Result_For (Results, 75).Status =
              Audit.Status_Unstable_Blocker_Family,
              "unstable name blocker family rejected");
      Assert (Audit.Result_For (Results, 76).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale burn-down fingerprint rejected");
      Assert (Audit.Result_For (Results, 77).Status =
              Audit.Status_Entity_Fingerprint_Mismatch,
              "entity fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 78).Status =
              Audit.Status_Overload_Fingerprint_Mismatch,
              "overload fingerprint mismatch rejected");
   end Test_Indeterminate_Views_Consumers_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Name_Visibility_Attribute_Gap_Closes'Access,
         "balanced name/visibility/attribute gap closure");
      Register_Routine
        (T, Test_Visibility_Selector_And_Use_Blockers'Access,
         "visibility selector and use-clause blockers");
      Register_Routine
        (T, Test_Attribute_Dereference_Indexing_And_Overload_Blockers'Access,
         "attribute dereference indexing and overload blockers");
      Register_Routine
        (T, Test_Indeterminate_Views_Consumers_And_Audit_Gates'Access,
         "indeterminate views consumers and audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1349;
