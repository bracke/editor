with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1356;

package body Test_Ada_RM_Gap_Burn_Down_Pass1356 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1356;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Lifetime_Construct_Kind;
   use type Audit.Lifetime_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1356");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Construct : Audit.Lifetime_Construct_Kind := Audit.Construct_Access_Value;
      Context : Audit.Lifetime_Context_Kind := Audit.Context_Block_Master;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Master_Lifetime_Accessibility_Closure;
      Row.Family := Matrix.Family_Access_Types_Accessibility;
      Row.Owner := Matrix.Slice_Accessibility_Lifetime;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String
        ("pass1356 source-shaped master lifetime row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1356");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1356 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1356 classification");
   end Expect_Status;

   procedure Test_Balanced_Lifetime_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Construct_Access_Value,
                       Audit.Context_Block_Master);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Construct_Return_Access_Value,
                       Audit.Context_Return_Object_Master);
      Row.Return_Access_Escapes_Master := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Anonymous_Access_Parameter,
                       Audit.Context_Anonymous_Access_Master);
      Row.Runtime_Accessibility_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Controlled_Object,
                       Audit.Context_Finalization_Path);
      Row.Runtime_Finalization_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Construct_Generic_Instance,
                       Audit.Context_Generic_Substitution);
      Row.Missing_Generic_Substitution_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Illegal,
                       Audit.Construct_Access_Object_Assignment,
                       Audit.Context_Library_Master);
      Row.Assignment_To_Longer_Lived_Access_Object := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Master_Lifetime_Accessibility_Closure_Gap_Closed (Results),
              "balanced master/lifetime/accessibility gap closes");
      Assert (Results.Legal_Count = 1, "legal lifetime row counted");
      Assert (Results.Illegal_Count = 2, "illegal lifetime rows counted");
      Assert (Results.Runtime_Check_Count = 2,
              "runtime lifetime rows counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate lifetime row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Return_Access_Escapes_Master,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3,
                     Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4,
                     Audit.Status_Runtime_Finalization_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 5,
                     Audit.Status_Indeterminate_Missing_Generic_Substitution_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 6,
                     Audit.Status_Illegal_Assignment_To_Longer_Lived_Access_Object,
                     Precision.Class_Illegal);
   end Test_Balanced_Lifetime_Gap_Closes;

   procedure Test_Accessibility_And_Master_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal);
      Row.Same_Canonical_Master := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal);
      Row.Static_Accessibility_Escape := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal);
      Row.Access_Value_Escapes_Master := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Construct_Access_Discriminant,
                       Audit.Context_Block_Master);
      Row.Access_Discriminant_Escapes_Master := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal,
                       Audit.Construct_Anonymous_Access_Parameter,
                       Audit.Context_Anonymous_Access_Master);
      Row.Anonymous_Access_Escapes_Master := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Legal_With_Runtime_Check);
      Row.Runtime_Accessibility_Check := True;
      Row.Runtime_Check_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10,
                     Audit.Status_Illegal_Accessibility_Slice_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Static_Accessibility_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Access_Value_Escapes_Master,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Access_Discriminant_Escapes_Master,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14,
                     Audit.Status_Illegal_Anonymous_Access_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Runtime_Check_Evidence_Lost,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Accessibility_And_Master_Blockers;

   procedure Test_Return_Allocator_Finalization_Consumers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Construct_Return_Object,
                       Audit.Context_Return_Object_Master);
      Row.Return_Object_Master_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Construct_Return_Object,
                       Audit.Context_Return_Object_Master);
      Row.Limited_Return_Object_Lifetime_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Construct_Controlled_Object,
                       Audit.Context_Return_Object_Master);
      Row.Controlled_Return_Object_Owner_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Construct_Returned_Aggregate,
                       Audit.Context_Return_Object_Master);
      Row.Returned_Aggregate_Components_Safe := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Construct_Allocator_Object,
                       Audit.Context_Allocator_Master);
      Row.Allocator_Lifetime_Evidence_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (25, Precision.Class_Illegal,
                       Audit.Construct_Unchecked_Deallocation,
                       Audit.Context_Allocator_Master);
      Row.Unchecked_Deallocation_Lifetime_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (26, Precision.Class_Illegal,
                       Audit.Construct_Generic_Instance,
                       Audit.Context_Generic_Substitution);
      Row.Generic_Substitution_Lifetime_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (27, Precision.Class_Illegal,
                       Audit.Construct_Task_Object,
                       Audit.Context_Task_Master);
      Row.Task_Lifetime_Is_Task_Master := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (28, Precision.Class_Illegal,
                       Audit.Construct_Protected_Object,
                       Audit.Context_Protected_Master);
      Row.Protected_Lifetime_Is_Protected_Master := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (29, Precision.Class_Illegal,
                       Audit.Construct_Controlled_Object,
                       Audit.Context_Finalization_Path);
      Row.Finalization_Owner_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Construct_Controlled_Object,
                       Audit.Context_Finalization_Path);
      Row.Normal_Return_Finalization_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Construct_Controlled_Object,
                       Audit.Context_Finalization_Path);
      Row.Exception_Propagation_Finalization_Preserved := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Construct_Task_Object,
                       Audit.Context_Finalization_Path);
      Row.Task_Abort_Finalization_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Illegal_Return_Object_Master_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21,
                     Audit.Status_Illegal_Limited_Return_Object_Lifetime_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Controlled_Return_Object_Owner_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23,
                     Audit.Status_Illegal_Returned_Aggregate_Component_Escapes,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Allocator_Lifetime_Evidence_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Unchecked_Deallocation_Lifetime_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 26,
                     Audit.Status_Illegal_Generic_Substitution_Lifetime_Changed,
                     Precision.Class_Illegal);
      Expect_Status (Results, 27,
                     Audit.Status_Illegal_Task_Lifetime_Treated_As_Block,
                     Precision.Class_Illegal);
      Expect_Status (Results, 28,
                     Audit.Status_Illegal_Protected_Lifetime_Treated_As_Block,
                     Precision.Class_Illegal);
      Expect_Status (Results, 29, Audit.Status_Illegal_Finalization_Owner_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 30,
                     Audit.Status_Illegal_Normal_Return_Finalization_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Exception_Propagation_Finalization_Lost,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Illegal_Task_Abort_Finalization_Lost,
                     Precision.Class_Illegal);
   end Test_Return_Allocator_Finalization_Consumers;

   procedure Test_Cross_Slice_Consumer_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Illegal);
      Row.Aggregate_Assignment_Lifetime_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (41, Precision.Class_Illegal);
      Row.Call_Actual_Lifetime_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (42, Precision.Class_Illegal);
      Row.Control_Flow_Finalization_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (43, Precision.Class_Indeterminate);
      Row.Missing_Master_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (44, Precision.Class_Indeterminate);
      Row.Missing_Return_Object_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (45, Precision.Class_Unknown);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (46, Precision.Class_Unknown);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (47, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Diagnostics);
      Row.Consumer_Lifetime_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (48, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Colouring_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (49, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Outline_Model);
      Row.Consumer_Declaration_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (50, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Target_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (51, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Hover_Details);
      Row.Consumer_Detail_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (52, Precision.Class_Unknown,
                       Audit.Construct_Access_Value,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Consumer_Diagnostic_Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (53, Precision.Class_Unknown);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (54, Precision.Class_Unknown);
      Row.Expected_Master_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (55, Precision.Class_Unknown);
      Row.Expected_Lifetime_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (56, Precision.Class_Unknown);
      Row.Expected_Accessibility_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (57, Precision.Class_Unknown);
      Row.Expected_Return_Object_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (58, Precision.Class_Unknown);
      Row.Expected_Allocation_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (59, Precision.Class_Unknown);
      Row.Expected_Finalization_Fingerprint := 99;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (60, Precision.Class_Unknown);
      Row.Expected_Consumer_Fingerprint := 99;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40,
                     Audit.Status_Illegal_Aggregate_Assignment_Lifetime_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41,
                     Audit.Status_Illegal_Call_Actual_Lifetime_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42,
                     Audit.Status_Illegal_Control_Flow_Finalization_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Indeterminate_Missing_Master_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 44,
                     Audit.Status_Indeterminate_Missing_Return_Object_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 45).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped lifetime evidence rejected");
      Assert (Audit.Result_For (Results, 46).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed lifetime result rejected");
      Assert (Audit.Result_For (Results, 47).Status =
              Audit.Status_Illegal_Diagnostics_Lifetime_Disagreement,
              "diagnostic lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 48).Status =
              Audit.Status_Illegal_Colouring_Lifetime_Disagreement,
              "colouring lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 49).Status =
              Audit.Status_Illegal_Outline_Declaration_Lifetime_Disagreement,
              "outline declaration lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 50).Status =
              Audit.Status_Illegal_Navigation_Target_Lifetime_Disagreement,
              "navigation target lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 51).Status =
              Audit.Status_Illegal_Hover_Lifetime_Disagreement,
              "hover lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 52).Status =
              Audit.Status_Illegal_Diagnostic_Bridge_Lifetime_Disagreement,
              "diagnostic bridge lifetime disagreement rejected");
      Assert (Audit.Result_For (Results, 53).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale lifetime evidence rejected");
      Assert (Audit.Result_For (Results, 54).Status =
              Audit.Status_Master_Fingerprint_Mismatch,
              "master fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Lifetime_Fingerprint_Mismatch,
              "lifetime fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Accessibility_Fingerprint_Mismatch,
              "accessibility fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Return_Object_Fingerprint_Mismatch,
              "return-object fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Allocation_Fingerprint_Mismatch,
              "allocation fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Finalization_Fingerprint_Mismatch,
              "finalization fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Cross_Slice_Consumer_And_Fingerprint_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Lifetime_Gap_Closes'Access,
         "balanced master lifetime accessibility gap closure");
      Register_Routine
        (T, Test_Accessibility_And_Master_Blockers'Access,
         "accessibility and master blockers");
      Register_Routine
        (T, Test_Return_Allocator_Finalization_Consumers'Access,
         "return allocator finalization blockers");
      Register_Routine
        (T, Test_Cross_Slice_Consumer_And_Fingerprint_Gates'Access,
         "cross-slice consumer and lifetime fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1356;
