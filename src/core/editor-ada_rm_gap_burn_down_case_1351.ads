with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1351 is

   --  Case 1351 is the ninth RM gap burn-down case.  It closes a concrete
   --  control-flow/exception/initialization/finalization Ada legality gap by
   --  requiring statement flow, definite assignment, object initialization,
   --  exception propagation, controlled finalization, abort/task finalization,
   --  consumers, remediation state, and balanced source-shaped regression
   --  evidence to agree on one canonical result.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Control_Exception_Initialization_Finalization,
      Gap_Control_Flow,
      Gap_Definite_Assignment_Initialization,
      Gap_Exception_Propagation,
      Gap_Controlled_Finalization,
      Gap_Cross_Slice_Lifetime_Consumer,
      Gap_Unknown);

   type Flow_Construct_Kind is
     (Construct_Return_Statement,
      Construct_Return_Expression,
      Construct_No_Return_Subprogram,
      Construct_Unreachable_Statement,
      Construct_Exit_Statement,
      Construct_Goto_Statement,
      Construct_Object_Declaration,
      Construct_Default_Expression,
      Construct_Deferred_Constant,
      Construct_Out_Parameter,
      Construct_Aggregate_Initialization,
      Construct_Subtype_Predicate_Initialization,
      Construct_Raise_Statement,
      Construct_Raise_Expression,
      Construct_Exception_Handler,
      Construct_Handler_Choice,
      Construct_Reraise_Statement,
      Construct_Controlled_Type,
      Construct_Initialize_Procedure,
      Construct_Adjust_Procedure,
      Construct_Finalize_Procedure,
      Construct_Finalization_Path,
      Construct_Abort_Finalization_Path,
      Construct_Task_Finalization_Path,
      Construct_Unknown);

   type Flow_Context_Kind is
     (Context_Control_Flow_Path,
      Context_Return_Analysis,
      Context_No_Return_Analysis,
      Context_Transfer_Statement,
      Context_Definite_Assignment,
      Context_Object_Initialization,
      Context_Exception_Handling,
      Context_Exception_Propagation,
      Context_Controlled_Finalization,
      Context_Task_Abort_Finalization,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Function_Path_Missing_Return,
      Status_Illegal_Return_Expression_Type_Mismatch,
      Status_Illegal_Return_Accessibility_Escape,
      Status_Illegal_No_Return_Has_Normal_Return,
      Status_Illegal_Unreachable_Statement,
      Status_Illegal_Exit_Target_Missing,
      Status_Illegal_Exit_Target_Not_Loop,
      Status_Illegal_Goto_Target_Missing,
      Status_Illegal_Goto_Into_Deeper_Scope,
      Status_Illegal_Goto_Into_Protected_Action,
      Status_Illegal_Required_Initializer_Missing,
      Status_Illegal_Default_Expression,
      Status_Illegal_Deferred_Constant_Completion_Mismatch,
      Status_Illegal_Out_Parameter_Not_Assigned,
      Status_Illegal_Aggregate_Initialization_Disagreement,
      Status_Illegal_Subtype_Predicate_Initialization_Disagreement,
      Status_Illegal_Raise_Exception_Missing,
      Status_Illegal_Raise_Exception_Not_Visible,
      Status_Illegal_Raise_Target_Not_Exception,
      Status_Illegal_Handler_Choice_Missing,
      Status_Illegal_Duplicate_Handler_Choice,
      Status_Illegal_Unreachable_Handler,
      Status_Illegal_Reraise_Outside_Handler,
      Status_Illegal_Local_Handler_Propagation_Disagreement,
      Status_Illegal_Controlled_Initialize_Profile_Mismatch,
      Status_Illegal_Controlled_Adjust_Profile_Mismatch,
      Status_Illegal_Controlled_Finalize_Profile_Mismatch,
      Status_Illegal_Finalization_Order_Disagreement,
      Status_Illegal_Limited_Controlled_Blocker,
      Status_Illegal_Controlled_Component_Initialization_Disagreement,
      Status_Illegal_Exception_Finalization_Hazard,
      Status_Illegal_Abort_Finalization_Disagreement,
      Status_Illegal_Task_Finalization_Disagreement,
      Status_Runtime_Constraint_Check_Preserved,
      Status_Runtime_Predicate_Check_Preserved,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Runtime_Finalization_Path_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Control_Flow_Evidence,
      Status_Indeterminate_Missing_Definite_Assignment_Evidence,
      Status_Indeterminate_Missing_Exception_Evidence,
      Status_Indeterminate_Missing_Finalization_Evidence,
      Status_Indeterminate_Missing_Lifetime_Effect_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Control_Flow_Model_Disagreement,
      Status_Consumer_Initialization_Model_Disagreement,
      Status_Consumer_Exception_Model_Disagreement,
      Status_Consumer_Finalization_Model_Disagreement,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Flow_Fingerprint_Mismatch,
      Status_Initialization_Fingerprint_Mismatch,
      Status_Exception_Fingerprint_Mismatch,
      Status_Finalization_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Burn_Down_Row is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Target_State : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Construct : Flow_Construct_Kind := Construct_Unknown;
      Context : Flow_Context_Kind := Context_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Evidence : Boolean := True;
      Remediation_Entry_Present : Boolean := True;
      Matrix_Coverage_Present : Boolean := True;
      Implementing_Package_Present : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Coverage_Entry_Updated_To_Covered : Boolean := True;
      Balanced_Regression_Evidence : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Function_Path_Returns : Boolean := True;
      Return_Expression_Type_Compatible : Boolean := True;
      Return_Accessibility_OK : Boolean := True;
      No_Return_Has_Normal_Return : Boolean := False;
      Unreachable_Statement_Present : Boolean := False;
      Exit_Target_Present : Boolean := True;
      Exit_Target_Is_Loop : Boolean := True;
      Goto_Target_Present : Boolean := True;
      Goto_Into_Deeper_Scope : Boolean := False;
      Goto_Into_Protected_Action : Boolean := False;
      Required_Initializer_Present : Boolean := True;
      Default_Expression_Legal : Boolean := True;
      Deferred_Constant_Completion_Matches : Boolean := True;
      Out_Parameter_Definitely_Assigned : Boolean := True;
      Aggregate_Initialization_Consumes : Boolean := True;
      Subtype_Predicate_Initialization_Consumes : Boolean := True;
      Exception_Name_Present : Boolean := True;
      Exception_Name_Visible : Boolean := True;
      Raise_Target_Is_Exception : Boolean := True;
      Handler_Choice_Present : Boolean := True;
      Duplicate_Handler_Choice : Boolean := False;
      Unreachable_Handler_Present : Boolean := False;
      Reraise_Inside_Handler : Boolean := True;
      Local_Handler_Propagation_Agrees : Boolean := True;
      Controlled_Initialize_Profile_Compatible : Boolean := True;
      Controlled_Adjust_Profile_Compatible : Boolean := True;
      Controlled_Finalize_Profile_Compatible : Boolean := True;
      Finalization_Order_Agrees : Boolean := True;
      Limited_Controlled_Blocker : Boolean := False;
      Controlled_Component_Initialization_Consumes : Boolean := True;
      Exception_Finalization_Hazard : Boolean := False;
      Abort_Finalization_Agrees : Boolean := True;
      Task_Finalization_Agrees : Boolean := True;
      Runtime_Constraint_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Finalization_Path : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Control_Flow_Evidence : Boolean := False;
      Missing_Definite_Assignment_Evidence : Boolean := False;
      Missing_Exception_Evidence : Boolean := False;
      Missing_Finalization_Evidence : Boolean := False;
      Missing_Lifetime_Effect_Evidence : Boolean := False;
      Consumer_Control_Flow_Model_Agrees : Boolean := True;
      Consumer_Initialization_Model_Agrees : Boolean := True;
      Consumer_Exception_Model_Agrees : Boolean := True;
      Consumer_Finalization_Model_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
      Initialization_Fingerprint : Natural := 0;
      Expected_Initialization_Fingerprint : Natural := 0;
      Exception_Fingerprint : Natural := 0;
      Expected_Exception_Fingerprint : Natural := 0;
      Finalization_Fingerprint : Natural := 0;
      Expected_Finalization_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Row);

   type Burn_Down_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Burn_Down_Entry is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Promoted_State : Remediation_State := Remediation.State_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Classification : Precision_Classification := Precision.Class_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Items : Entry_Vectors.Vector;
      Burned_Down_Count : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row);

   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry;
   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean;
   function Control_Exception_Initialization_Finalization_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1351;
