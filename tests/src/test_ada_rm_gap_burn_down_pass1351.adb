with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1351;

package body Test_Ada_RM_Gap_Burn_Down_Pass1351 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1351;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Flow_Construct_Kind;
   use type Audit.Flow_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1351");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Control_Exception_Initialization_Finalization;
      Construct : Audit.Flow_Construct_Kind := Audit.Construct_Return_Statement;
      Context : Audit.Flow_Context_Kind := Audit.Context_Control_Flow_Path;
      Family : Audit.RM_Family := Matrix.Family_Exceptions_Finalization;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Exception_Finalization;
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
      Function_Path_Returns : Boolean := True;
      Return_Type_OK : Boolean := True;
      Return_Accessibility_OK : Boolean := True;
      No_Return_Normal_Return : Boolean := False;
      Unreachable_Statement : Boolean := False;
      Exit_Target_Present : Boolean := True;
      Exit_Target_Is_Loop : Boolean := True;
      Goto_Target_Present : Boolean := True;
      Goto_Into_Deeper_Scope : Boolean := False;
      Goto_Into_Protected_Action : Boolean := False;
      Required_Initializer : Boolean := True;
      Default_Expression_OK : Boolean := True;
      Deferred_Constant_OK : Boolean := True;
      Out_Parameter_Assigned : Boolean := True;
      Aggregate_Init_Consumes : Boolean := True;
      Subtype_Predicate_Init_Consumes : Boolean := True;
      Exception_Name_Present : Boolean := True;
      Exception_Name_Visible : Boolean := True;
      Raise_Target_Exception : Boolean := True;
      Handler_Choice_Present : Boolean := True;
      Duplicate_Handler : Boolean := False;
      Unreachable_Handler : Boolean := False;
      Reraise_Inside_Handler : Boolean := True;
      Local_Handler_Propagation : Boolean := True;
      Initialize_Profile_OK : Boolean := True;
      Adjust_Profile_OK : Boolean := True;
      Finalize_Profile_OK : Boolean := True;
      Finalization_Order_OK : Boolean := True;
      Limited_Controlled : Boolean := False;
      Controlled_Component_Init : Boolean := True;
      Exception_Finalization_Hazard : Boolean := False;
      Abort_Finalization_OK : Boolean := True;
      Task_Finalization_OK : Boolean := True;
      Runtime_Constraint_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Finalization_Path : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Control_Flow : Boolean := False;
      Missing_Definite_Assignment : Boolean := False;
      Missing_Exception : Boolean := False;
      Missing_Finalization : Boolean := False;
      Missing_Lifetime_Effect : Boolean := False;
      Consumer_Control_Flow_Agrees : Boolean := True;
      Consumer_Initialization_Agrees : Boolean := True;
      Consumer_Exception_Agrees : Boolean := True;
      Consumer_Finalization_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Flow_FP : Natural := 0;
      Expected_Initialization_FP : Natural := 0;
      Expected_Exception_FP : Natural := 0;
      Expected_Finalization_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_351_000 + Id * 100;
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
      Row.Name := To_Unbounded_String ("control exception initialization finalization burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1351");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_351_000 + Id);
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
      Row.Function_Path_Returns := Function_Path_Returns;
      Row.Return_Expression_Type_Compatible := Return_Type_OK;
      Row.Return_Accessibility_OK := Return_Accessibility_OK;
      Row.No_Return_Has_Normal_Return := No_Return_Normal_Return;
      Row.Unreachable_Statement_Present := Unreachable_Statement;
      Row.Exit_Target_Present := Exit_Target_Present;
      Row.Exit_Target_Is_Loop := Exit_Target_Is_Loop;
      Row.Goto_Target_Present := Goto_Target_Present;
      Row.Goto_Into_Deeper_Scope := Goto_Into_Deeper_Scope;
      Row.Goto_Into_Protected_Action := Goto_Into_Protected_Action;
      Row.Required_Initializer_Present := Required_Initializer;
      Row.Default_Expression_Legal := Default_Expression_OK;
      Row.Deferred_Constant_Completion_Matches := Deferred_Constant_OK;
      Row.Out_Parameter_Definitely_Assigned := Out_Parameter_Assigned;
      Row.Aggregate_Initialization_Consumes := Aggregate_Init_Consumes;
      Row.Subtype_Predicate_Initialization_Consumes := Subtype_Predicate_Init_Consumes;
      Row.Exception_Name_Present := Exception_Name_Present;
      Row.Exception_Name_Visible := Exception_Name_Visible;
      Row.Raise_Target_Is_Exception := Raise_Target_Exception;
      Row.Handler_Choice_Present := Handler_Choice_Present;
      Row.Duplicate_Handler_Choice := Duplicate_Handler;
      Row.Unreachable_Handler_Present := Unreachable_Handler;
      Row.Reraise_Inside_Handler := Reraise_Inside_Handler;
      Row.Local_Handler_Propagation_Agrees := Local_Handler_Propagation;
      Row.Controlled_Initialize_Profile_Compatible := Initialize_Profile_OK;
      Row.Controlled_Adjust_Profile_Compatible := Adjust_Profile_OK;
      Row.Controlled_Finalize_Profile_Compatible := Finalize_Profile_OK;
      Row.Finalization_Order_Agrees := Finalization_Order_OK;
      Row.Limited_Controlled_Blocker := Limited_Controlled;
      Row.Controlled_Component_Initialization_Consumes := Controlled_Component_Init;
      Row.Exception_Finalization_Hazard := Exception_Finalization_Hazard;
      Row.Abort_Finalization_Agrees := Abort_Finalization_OK;
      Row.Task_Finalization_Agrees := Task_Finalization_OK;
      Row.Runtime_Constraint_Check := Runtime_Constraint_Check;
      Row.Runtime_Predicate_Check := Runtime_Predicate_Check;
      Row.Runtime_Accessibility_Check := Runtime_Accessibility_Check;
      Row.Runtime_Finalization_Path := Runtime_Finalization_Path;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View_Evidence := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Control_Flow_Evidence := Missing_Control_Flow;
      Row.Missing_Definite_Assignment_Evidence := Missing_Definite_Assignment;
      Row.Missing_Exception_Evidence := Missing_Exception;
      Row.Missing_Finalization_Evidence := Missing_Finalization;
      Row.Missing_Lifetime_Effect_Evidence := Missing_Lifetime_Effect;
      Row.Consumer_Control_Flow_Model_Agrees := Consumer_Control_Flow_Agrees;
      Row.Consumer_Initialization_Model_Agrees := Consumer_Initialization_Agrees;
      Row.Consumer_Exception_Model_Agrees := Consumer_Exception_Agrees;
      Row.Consumer_Finalization_Model_Agrees := Consumer_Finalization_Agrees;
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
      Row.Type_Fingerprint := FP + 4;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Flow_Fingerprint := FP + 5;
      Row.Expected_Flow_Fingerprint :=
        (if Expected_Flow_FP = 0 then Row.Flow_Fingerprint else Expected_Flow_FP);
      Row.Initialization_Fingerprint := FP + 6;
      Row.Expected_Initialization_Fingerprint :=
        (if Expected_Initialization_FP = 0 then Row.Initialization_Fingerprint else Expected_Initialization_FP);
      Row.Exception_Fingerprint := FP + 7;
      Row.Expected_Exception_Fingerprint :=
        (if Expected_Exception_FP = 0 then Row.Exception_Fingerprint else Expected_Exception_FP);
      Row.Finalization_Fingerprint := FP + 8;
      Row.Expected_Finalization_Fingerprint :=
        (if Expected_Finalization_FP = 0 then Row.Finalization_Fingerprint else Expected_Finalization_FP);
      Row.Profile_Fingerprint := FP + 9;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 10;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Effect_Fingerprint := FP + 11;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 12;
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

   procedure Test_Balanced_Control_Exception_Finalization_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Return_Statement,
               Context => Audit.Context_Return_Analysis,
               Consumer => Consumers.Consumer_Hover_Details);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Construct => Audit.Construct_Return_Statement,
               Context => Audit.Context_Control_Flow_Path,
               Function_Path_Returns => False,
               Family => Matrix.Family_Diagnostics_Consumer_Readiness,
               Owner => Matrix.Slice_Diagnostics_Consumer);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Subtype_Predicate_Initialization,
               Context => Audit.Context_Object_Initialization,
               Runtime_Predicate_Check => True,
               Family => Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Owner => Matrix.Slice_Subtype_Range_Predicate);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Construct => Audit.Construct_Finalization_Path,
               Context => Audit.Context_Controlled_Finalization,
               Missing_Finalization => True);

      Results := Audit.Build (Input);

      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "balanced control/exception/finalization gap is ready");
      Assert (Audit.Control_Exception_Initialization_Finalization_Gap_Closed (Results),
              "target control/exception/initialization/finalization gap closed");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Function_Path_Missing_Return,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Predicate_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4,
                     Audit.Status_Indeterminate_Missing_Finalization_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Balanced_Control_Exception_Finalization_Gap_Closes;

   procedure Test_Control_Flow_And_Initialization_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Function_Path_Returns => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Construct => Audit.Construct_Return_Expression,
               Return_Type_OK => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Construct => Audit.Construct_Return_Statement,
               Return_Accessibility_OK => False);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Construct => Audit.Construct_No_Return_Subprogram,
               Context => Audit.Context_No_Return_Analysis,
               No_Return_Normal_Return => True);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Construct => Audit.Construct_Unreachable_Statement,
               Unreachable_Statement => True);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Construct => Audit.Construct_Exit_Statement,
               Context => Audit.Context_Transfer_Statement,
               Exit_Target_Present => False);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Construct => Audit.Construct_Exit_Statement,
               Context => Audit.Context_Transfer_Statement,
               Exit_Target_Is_Loop => False);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Construct => Audit.Construct_Goto_Statement,
               Context => Audit.Context_Transfer_Statement,
               Goto_Target_Present => False);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Construct => Audit.Construct_Goto_Statement,
               Context => Audit.Context_Transfer_Statement,
               Goto_Into_Deeper_Scope => True);
      Add_Row (Input, 19, Precision.Class_Illegal,
               Construct => Audit.Construct_Goto_Statement,
               Context => Audit.Context_Transfer_Statement,
               Goto_Into_Protected_Action => True);
      Add_Row (Input, 20, Precision.Class_Illegal,
               Construct => Audit.Construct_Object_Declaration,
               Context => Audit.Context_Object_Initialization,
               Required_Initializer => False,
               Family => Matrix.Family_Declarations_Completions,
               Owner => Matrix.Slice_Body_Spec_Conformance);
      Add_Row (Input, 21, Precision.Class_Illegal,
               Construct => Audit.Construct_Default_Expression,
               Context => Audit.Context_Object_Initialization,
               Default_Expression_OK => False,
               Family => Matrix.Family_Declarations_Completions,
               Owner => Matrix.Slice_Ada2022_Expression_Type_Resolution);
      Add_Row (Input, 22, Precision.Class_Illegal,
               Construct => Audit.Construct_Deferred_Constant,
               Context => Audit.Context_Object_Initialization,
               Deferred_Constant_OK => False,
               Family => Matrix.Family_Declarations_Completions,
               Owner => Matrix.Slice_Body_Spec_Conformance);
      Add_Row (Input, 23, Precision.Class_Illegal,
               Construct => Audit.Construct_Out_Parameter,
               Context => Audit.Context_Definite_Assignment,
               Out_Parameter_Assigned => False,
               Family => Matrix.Family_Assignments_Conversions,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 24, Precision.Class_Illegal,
               Construct => Audit.Construct_Aggregate_Initialization,
               Context => Audit.Context_Object_Initialization,
               Aggregate_Init_Consumes => False,
               Family => Matrix.Family_Aggregates,
               Owner => Matrix.Slice_Aggregate);
      Add_Row (Input, 25, Precision.Class_Illegal,
               Construct => Audit.Construct_Subtype_Predicate_Initialization,
               Context => Audit.Context_Object_Initialization,
               Subtype_Predicate_Init_Consumes => False,
               Family => Matrix.Family_Types_Subtypes_Constraints_Predicates,
               Owner => Matrix.Slice_Subtype_Range_Predicate);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Function_Path_Missing_Return,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Return_Expression_Type_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Return_Accessibility_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_No_Return_Has_Normal_Return,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Unreachable_Statement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Exit_Target_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Exit_Target_Not_Loop,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17, Audit.Status_Illegal_Goto_Target_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 18, Audit.Status_Illegal_Goto_Into_Deeper_Scope,
                     Precision.Class_Illegal);
      Expect_Status (Results, 19, Audit.Status_Illegal_Goto_Into_Protected_Action,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20, Audit.Status_Illegal_Required_Initializer_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Illegal_Default_Expression,
                     Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Deferred_Constant_Completion_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Illegal_Out_Parameter_Not_Assigned,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Aggregate_Initialization_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Subtype_Predicate_Initialization_Disagreement,
                     Precision.Class_Illegal);
   end Test_Control_Flow_And_Initialization_Blockers;

   procedure Test_Exception_And_Finalization_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Construct => Audit.Construct_Raise_Statement,
               Context => Audit.Context_Exception_Propagation,
               Exception_Name_Present => False);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Construct => Audit.Construct_Raise_Expression,
               Context => Audit.Context_Exception_Propagation,
               Exception_Name_Visible => False);
      Add_Row (Input, 32, Precision.Class_Illegal,
               Construct => Audit.Construct_Raise_Statement,
               Raise_Target_Exception => False);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Construct => Audit.Construct_Handler_Choice,
               Context => Audit.Context_Exception_Handling,
               Handler_Choice_Present => False);
      Add_Row (Input, 34, Precision.Class_Illegal,
               Construct => Audit.Construct_Exception_Handler,
               Context => Audit.Context_Exception_Handling,
               Duplicate_Handler => True);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Construct => Audit.Construct_Exception_Handler,
               Context => Audit.Context_Exception_Handling,
               Unreachable_Handler => True);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Construct => Audit.Construct_Reraise_Statement,
               Context => Audit.Context_Exception_Handling,
               Reraise_Inside_Handler => False);
      Add_Row (Input, 37, Precision.Class_Illegal,
               Construct => Audit.Construct_Exception_Handler,
               Context => Audit.Context_Exception_Propagation,
               Local_Handler_Propagation => False);
      Add_Row (Input, 38, Precision.Class_Illegal,
               Construct => Audit.Construct_Initialize_Procedure,
               Context => Audit.Context_Controlled_Finalization,
               Initialize_Profile_OK => False);
      Add_Row (Input, 39, Precision.Class_Illegal,
               Construct => Audit.Construct_Adjust_Procedure,
               Context => Audit.Context_Controlled_Finalization,
               Adjust_Profile_OK => False);
      Add_Row (Input, 40, Precision.Class_Illegal,
               Construct => Audit.Construct_Finalize_Procedure,
               Context => Audit.Context_Controlled_Finalization,
               Finalize_Profile_OK => False);
      Add_Row (Input, 41, Precision.Class_Illegal,
               Construct => Audit.Construct_Finalization_Path,
               Context => Audit.Context_Controlled_Finalization,
               Finalization_Order_OK => False);
      Add_Row (Input, 42, Precision.Class_Illegal,
               Construct => Audit.Construct_Controlled_Type,
               Context => Audit.Context_Controlled_Finalization,
               Limited_Controlled => True);
      Add_Row (Input, 43, Precision.Class_Illegal,
               Construct => Audit.Construct_Aggregate_Initialization,
               Context => Audit.Context_Controlled_Finalization,
               Controlled_Component_Init => False,
               Family => Matrix.Family_Aggregates,
               Owner => Matrix.Slice_Aggregate);
      Add_Row (Input, 44, Precision.Class_Illegal,
               Construct => Audit.Construct_Finalization_Path,
               Context => Audit.Context_Exception_Propagation,
               Exception_Finalization_Hazard => True);
      Add_Row (Input, 45, Precision.Class_Illegal,
               Construct => Audit.Construct_Abort_Finalization_Path,
               Context => Audit.Context_Task_Abort_Finalization,
               Abort_Finalization_OK => False,
               Family => Matrix.Family_Tasking_Protected_Synchronized,
               Owner => Matrix.Slice_Tasking_Protected);
      Add_Row (Input, 46, Precision.Class_Illegal,
               Construct => Audit.Construct_Task_Finalization_Path,
               Context => Audit.Context_Task_Abort_Finalization,
               Task_Finalization_OK => False,
               Family => Matrix.Family_Tasking_Protected_Synchronized,
               Owner => Matrix.Slice_Tasking_Protected);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Raise_Exception_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Illegal_Raise_Exception_Not_Visible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Raise_Target_Not_Exception,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Illegal_Handler_Choice_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Illegal_Duplicate_Handler_Choice,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Illegal_Unreachable_Handler,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Reraise_Outside_Handler,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37,
                     Audit.Status_Illegal_Local_Handler_Propagation_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Controlled_Initialize_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Controlled_Adjust_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 40,
                     Audit.Status_Illegal_Controlled_Finalize_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41, Audit.Status_Illegal_Finalization_Order_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Illegal_Limited_Controlled_Blocker,
                     Precision.Class_Illegal);
      Expect_Status (Results, 43,
                     Audit.Status_Illegal_Controlled_Component_Initialization_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 44, Audit.Status_Illegal_Exception_Finalization_Hazard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 45, Audit.Status_Illegal_Abort_Finalization_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 46, Audit.Status_Illegal_Task_Finalization_Disagreement,
                     Precision.Class_Illegal);
   end Test_Exception_And_Finalization_Blockers;

   procedure Test_Runtime_Indeterminate_Consumers_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 60, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Constraint_Check => True);
      Add_Row (Input, 61, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Predicate_Check => True);
      Add_Row (Input, 62, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Accessibility_Check => True);
      Add_Row (Input, 63, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Finalization_Path => True);
      Add_Row (Input, 64, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Constraint_Check => True,
               Runtime_Check_Preserved => False);
      Add_Row (Input, 70, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 71, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 72, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 73, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 74, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 75, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);
      Add_Row (Input, 76, Precision.Class_Indeterminate,
               Missing_Control_Flow => True);
      Add_Row (Input, 77, Precision.Class_Indeterminate,
               Missing_Definite_Assignment => True);
      Add_Row (Input, 78, Precision.Class_Indeterminate,
               Missing_Exception => True);
      Add_Row (Input, 79, Precision.Class_Indeterminate,
               Missing_Finalization => True);
      Add_Row (Input, 80, Precision.Class_Indeterminate,
               Missing_Lifetime_Effect => True);
      Add_Row (Input, 81, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 82, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 83, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 84, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 85, Precision.Class_Legal,
               Consumer_Control_Flow_Agrees => False);
      Add_Row (Input, 86, Precision.Class_Legal,
               Consumer_Initialization_Agrees => False);
      Add_Row (Input, 87, Precision.Class_Legal,
               Consumer_Exception_Agrees => False);
      Add_Row (Input, 88, Precision.Class_Legal,
               Consumer_Finalization_Agrees => False);
      Add_Row (Input, 89, Precision.Class_Legal,
               Consumer_Bridge_Agrees => False);
      Add_Row (Input, 90, Precision.Class_Illegal,
               Function_Path_Returns => False,
               Stable_Blocker => False);
      Add_Row (Input, 91, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 92, Precision.Class_Legal,
               Expected_Flow_FP => 42);
      Add_Row (Input, 93, Precision.Class_Legal,
               Expected_Initialization_FP => 42);
      Add_Row (Input, 94, Precision.Class_Legal,
               Expected_Exception_FP => 42);
      Add_Row (Input, 95, Precision.Class_Legal,
               Expected_Finalization_FP => 42);
      Add_Row (Input, 96, Precision.Class_Legal,
               Expected_Substitution_FP => 42);
      Add_Row (Input, 97, Precision.Class_Legal,
               Expected_Effect_FP => 42);
      Add_Row (Input, 98, Precision.Class_Legal,
               Expected_Consumer_FP => 42);

      Results := Audit.Build (Input);

      Expect_Status (Results, 60, Audit.Status_Runtime_Constraint_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 61, Audit.Status_Runtime_Predicate_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 62, Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 63, Audit.Status_Runtime_Finalization_Path_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Assert (Audit.Result_For (Results, 64).Status =
              Audit.Status_Runtime_Check_Evidence_Lost,
              "lost runtime/finalization evidence rejected");
      Expect_Status (Results, 70, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 71, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 72, Audit.Status_Indeterminate_Incomplete_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 73, Audit.Status_Indeterminate_Generic_Formal_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 74, Audit.Status_Indeterminate_Missing_Full_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 75,
                     Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 76,
                     Audit.Status_Indeterminate_Missing_Control_Flow_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 77,
                     Audit.Status_Indeterminate_Missing_Definite_Assignment_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 78,
                     Audit.Status_Indeterminate_Missing_Exception_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 79,
                     Audit.Status_Indeterminate_Missing_Finalization_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 80,
                     Audit.Status_Indeterminate_Missing_Lifetime_Effect_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 81).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped flow evidence rejected");
      Assert (Audit.Result_For (Results, 82).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing remediation evidence rejected");
      Assert (Audit.Result_For (Results, 83).Status =
              Audit.Status_Coverage_Not_Updated_To_Covered,
              "coverage promotion gate enforced");
      Assert (Audit.Result_For (Results, 84).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed control result rejected");
      Assert (Audit.Result_For (Results, 85).Status =
              Audit.Status_Consumer_Control_Flow_Model_Disagreement,
              "consumer control-flow disagreement rejected");
      Assert (Audit.Result_For (Results, 86).Status =
              Audit.Status_Consumer_Initialization_Model_Disagreement,
              "consumer initialization disagreement rejected");
      Assert (Audit.Result_For (Results, 87).Status =
              Audit.Status_Consumer_Exception_Model_Disagreement,
              "consumer exception disagreement rejected");
      Assert (Audit.Result_For (Results, 88).Status =
              Audit.Status_Consumer_Finalization_Model_Disagreement,
              "consumer finalization disagreement rejected");
      Assert (Audit.Result_For (Results, 89).Status =
              Audit.Status_Consumer_Diagnostic_Bridge_Disagreement,
              "consumer bridge disagreement rejected");
      Assert (Audit.Result_For (Results, 90).Status =
              Audit.Status_Unstable_Blocker_Family,
              "unstable control blocker family rejected");
      Assert (Audit.Result_For (Results, 91).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale burn-down fingerprint rejected");
      Assert (Audit.Result_For (Results, 92).Status =
              Audit.Status_Flow_Fingerprint_Mismatch,
              "flow fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 93).Status =
              Audit.Status_Initialization_Fingerprint_Mismatch,
              "initialization fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 94).Status =
              Audit.Status_Exception_Fingerprint_Mismatch,
              "exception fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 95).Status =
              Audit.Status_Finalization_Fingerprint_Mismatch,
              "finalization fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 96).Status =
              Audit.Status_Substitution_Fingerprint_Mismatch,
              "substitution fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 97).Status =
              Audit.Status_Effect_Fingerprint_Mismatch,
              "effect fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 98).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Runtime_Indeterminate_Consumers_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Control_Exception_Finalization_Gap_Closes'Access,
         "balanced control/exception/finalization gap closure");
      Register_Routine
        (T, Test_Control_Flow_And_Initialization_Blockers'Access,
         "control flow and initialization blockers");
      Register_Routine
        (T, Test_Exception_And_Finalization_Blockers'Access,
         "exception and finalization blockers");
      Register_Routine
        (T, Test_Runtime_Indeterminate_Consumers_And_Audit_Gates'Access,
         "runtime indeterminate consumers and audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1351;
