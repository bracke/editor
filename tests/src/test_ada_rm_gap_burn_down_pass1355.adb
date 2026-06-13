with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1355;

package body Test_Ada_RM_Gap_Burn_Down_Pass1355 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1355;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Call_Construct_Kind;
   use type Audit.Call_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1355");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Construct : Audit.Call_Construct_Kind := Audit.Construct_Procedure_Call;
      Context : Audit.Call_Context_Kind := Audit.Context_Positional_Association;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Call_Actual_Parameter_Mode_Aliasing;
      Row.Family := Matrix.Family_Calls_Overload_Callable_Profiles;
      Row.Owner := Matrix.Slice_Callable_Profile;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("pass1355 source-shaped call row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1355");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1355 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1355 classification");
   end Expect_Status;

   procedure Test_Balanced_Call_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Positional_Association);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Named_Association);
      Row.Required_Actuals_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Runtime_Accessibility_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Partial_Coverage,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Contract_Effect);
      Row.Warning_Only_Policy := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Construct_Generic_Formal_Subprogram_Call,
                       Audit.Context_Generic_Substitution);
      Row.Missing_Substitution_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.Writable_Actual_Alias := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Call_Actual_Parameter_Mode_Aliasing_Gap_Closed (Results),
              "balanced call actual/mode/alias gap closes");
      Assert (Results.Legal_Count = 1, "legal call row counted");
      Assert (Results.Illegal_Count = 2, "illegal call rows counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime call row counted");
      Assert (Results.Warning_Count = 1, "warning-only call row counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate call row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Missing_Required_Actual,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3,
                     Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Warning_Only_Policy_Preserved,
                     Precision.Class_Partial_Coverage);
      Expect_Status (Results, 5,
                     Audit.Status_Indeterminate_Missing_Substitution_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 6, Audit.Status_Illegal_Writable_Actual_Alias,
                     Precision.Class_Illegal);
   end Test_Balanced_Call_Gap_Closes;

   procedure Test_Association_Mode_Profile_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal);
      Row.Extra_Actuals := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal);
      Row.Duplicate_Actual_Association := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Mixed_Association);
      Row.Positional_Actual_After_Named := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Defaulted_Formal);
      Row.Defaulted_Formals_Available := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal);
      Row.Association_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.Out_Formal := True;
      Row.Out_Actual_Is_Variable := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (16, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.In_Out_Formal := True;
      Row.In_Out_Actual_Is_Variable := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (17, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.Out_Formal := True;
      Row.Actual_Is_Constant_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (18, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.In_Out_Formal := True;
      Row.Writable_Limited_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (19, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.Out_Formal := True;
      Row.Out_Formal_Definite_Assignment_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (20, Precision.Class_Illegal);
      Row.Formal_Actual_Type_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Access_Parameter_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Anonymous_Access_Actual_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Null_Exclusion_Violation := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Static_Accessibility_Escape := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (25, Precision.Class_Illegal);
      Row.Callable_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (26, Precision.Class_Illegal);
      Row.Overload_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Extra_Actual,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Duplicate_Actual_Association,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Positional_Actual_After_Named,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Defaulted_Formal_Not_Available,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14,
                     Audit.Status_Illegal_Association_Profile_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Out_Actual_Not_Variable,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16,
                     Audit.Status_Illegal_In_Out_Actual_Not_Variable,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17,
                     Audit.Status_Illegal_Constant_View_For_Writable_Formal,
                     Precision.Class_Illegal);
      Expect_Status (Results, 18,
                     Audit.Status_Illegal_Limited_View_For_Writable_Formal,
                     Precision.Class_Illegal);
      Expect_Status (Results, 19,
                     Audit.Status_Illegal_Out_Formal_Definite_Assignment_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Formal_Actual_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Illegal_Access_Parameter_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Anonymous_Access_Actual_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Illegal_Null_Exclusion_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Illegal_Static_Accessibility_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Callable_Profile_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 26,
                     Audit.Status_Illegal_Overload_Profile_Disagreement,
                     Precision.Class_Illegal);
   end Test_Association_Mode_Profile_Blockers;

   procedure Test_Aliasing_Dispatching_Contract_Effect_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Writable_Actual);
      Row.Overlapping_Writable_Actuals := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Access_Parameter);
      Row.Access_Value_Alias := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Contract_Effect);
      Row.Volatile_Atomic_Ordering_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Construct_Entry_Call,
                       Audit.Context_Contract_Effect);
      Row.Protected_Shared_State_Effect_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Construct_Dispatching_Call,
                       Audit.Context_Dispatching_Call);
      Row.Dispatching_Control_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (35, Precision.Class_Illegal,
                       Audit.Construct_Generic_Formal_Subprogram_Call,
                       Audit.Context_Generic_Substitution);
      Row.Generic_Substitution_Profile_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (36, Precision.Class_Illegal,
                       Audit.Construct_Renamed_Callable_Call,
                       Audit.Context_Renaming);
      Row.Renamed_Callable_Profile_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (37, Precision.Class_Illegal,
                       Audit.Construct_Access_To_Subprogram_Call,
                       Audit.Context_Access_To_Subprogram);
      Row.Access_To_Subprogram_Convention_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (38, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Contract_Effect);
      Row.Contract_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (39, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Contract_Effect);
      Row.Global_Depends_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (40, Precision.Class_Illegal,
                       Audit.Construct_Function_Call,
                       Audit.Context_Contract_Effect);
      Row.Refined_Flow_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (41, Precision.Class_Illegal,
                       Audit.Construct_Dispatching_Call,
                       Audit.Context_Contract_Effect);
      Row.Dispatching_Effect_Join_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (42, Precision.Class_Illegal,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Contract_Effect);
      Row.Hard_Policy_Violation_Downgraded := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (43, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Function_Call,
                       Audit.Context_Access_Parameter);
      Row.Runtime_Range_Predicate_Check := True;
      Row.Runtime_Check_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (44, Precision.Class_Partial_Coverage,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Contract_Effect);
      Row.Warning_Only_Policy := True;
      Row.Warning_Policy_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Overlapping_Writable_Actuals,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Illegal_Access_Value_Alias,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Illegal_Volatile_Atomic_Ordering_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33,
                     Audit.Status_Illegal_Protected_Shared_State_Effect_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34,
                     Audit.Status_Illegal_Dispatching_Control_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35,
                     Audit.Status_Illegal_Generic_Substitution_Profile_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36,
                     Audit.Status_Illegal_Renamed_Callable_Profile_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37,
                     Audit.Status_Illegal_Access_To_Subprogram_Convention_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 38, Audit.Status_Illegal_Contract_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Global_Depends_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 40, Audit.Status_Illegal_Refined_Flow_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Dispatching_Effect_Join_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Hard_Policy_Violation_Downgraded,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43, Audit.Status_Runtime_Check_Evidence_Lost,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 44, Audit.Status_Warning_Policy_Evidence_Lost,
                     Precision.Class_Partial_Coverage);
   end Test_Aliasing_Dispatching_Contract_Effect_Blockers;

   procedure Test_Indeterminate_Consumer_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (50, Precision.Class_Indeterminate);
      Row.Private_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (51, Precision.Class_Indeterminate);
      Row.Missing_Association_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (52, Precision.Class_Indeterminate);
      Row.Missing_Overload_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (53, Precision.Class_Indeterminate);
      Row.Missing_Effect_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (54, Precision.Class_Indeterminate);
      Row.Missing_Aliasing_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (55, Precision.Class_Unknown);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (56, Precision.Class_Unknown);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (57, Precision.Class_Unknown);
      Row.Consumer_Call_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (58, Precision.Class_Unknown,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Actual_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (59, Precision.Class_Unknown,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Outline_Model);
      Row.Consumer_Profile_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (60, Precision.Class_Unknown,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Target_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (61, Precision.Class_Unknown,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Hover_Details);
      Row.Consumer_Effect_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (62, Precision.Class_Unknown,
                       Audit.Construct_Procedure_Call,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Consumer_Diagnostic_Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (63, Precision.Class_Unknown);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (64, Precision.Class_Unknown);
      Row.Expected_Call_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (65, Precision.Class_Unknown);
      Row.Expected_Association_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (66, Precision.Class_Unknown);
      Row.Expected_Profile_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (67, Precision.Class_Unknown);
      Row.Expected_Overload_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (68, Precision.Class_Unknown);
      Row.Expected_Effect_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (69, Precision.Class_Unknown);
      Row.Expected_Alias_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (70, Precision.Class_Unknown);
      Row.Expected_Consumer_Fingerprint := 99;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51,
                     Audit.Status_Indeterminate_Missing_Association_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52,
                     Audit.Status_Indeterminate_Missing_Overload_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Missing_Effect_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54,
                     Audit.Status_Indeterminate_Missing_Aliasing_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped call evidence rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed call result rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Illegal_Diagnostics_Call_Disagreement,
              "diagnostic call disagreement rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Illegal_Colouring_Call_Disagreement,
              "colouring call disagreement rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Illegal_Outline_Profile_Disagreement,
              "outline profile disagreement rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Illegal_Navigation_Target_Disagreement,
              "navigation target disagreement rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Illegal_Hover_Effect_Disagreement,
              "hover effect disagreement rejected");
      Assert (Audit.Result_For (Results, 62).Status =
              Audit.Status_Illegal_Diagnostic_Bridge_Disagreement,
              "diagnostic bridge disagreement rejected");
      Assert (Audit.Result_For (Results, 63).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale call evidence rejected");
      Assert (Audit.Result_For (Results, 64).Status =
              Audit.Status_Call_Fingerprint_Mismatch,
              "call fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 65).Status =
              Audit.Status_Association_Fingerprint_Mismatch,
              "association fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 66).Status =
              Audit.Status_Profile_Fingerprint_Mismatch,
              "profile fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 67).Status =
              Audit.Status_Overload_Fingerprint_Mismatch,
              "overload fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Effect_Fingerprint_Mismatch,
              "effect fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 69).Status =
              Audit.Status_Alias_Fingerprint_Mismatch,
              "alias fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 70).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_Consumer_And_Fingerprint_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Call_Gap_Closes'Access,
         "balanced call actual parameter mode aliasing gap closure");
      Register_Routine
        (T, Test_Association_Mode_Profile_Blockers'Access,
         "association mode profile blockers");
      Register_Routine
        (T, Test_Aliasing_Dispatching_Contract_Effect_Blockers'Access,
         "aliasing dispatching contract effect blockers");
      Register_Routine
        (T, Test_Indeterminate_Consumer_And_Fingerprint_Gates'Access,
         "indeterminate consumer and call fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1355;
