with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1348 is

   --  Pass1348 is the sixth RM gap burn-down pass.  It closes a concrete
   --  tasking/protected/parallel/shared-state Ada legality gap by requiring
   --  task and protected operations, synchronized interfaces, iterators,
   --  parallel reductions, Global/Depends-style effects, volatile/atomic
   --  ordering, accessibility, abort/finalization, consumers, remediation
   --  state, and balanced source-shaped regression evidence to agree on one
   --  canonical result.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Tasking_Protected_Parallel_Shared_State,
      Gap_Protected_Action,
      Gap_Task_Entry_Select_Requeue,
      Gap_Abort_Finalization,
      Gap_Parallel_Iterator_Reduction,
      Gap_Flow_Effect_State,
      Gap_Consumer_Tasking_Projection,
      Gap_Unknown);

   type Tasking_Construct_Kind is
     (Construct_Protected_Procedure,
      Construct_Protected_Function,
      Construct_Protected_Entry,
      Construct_Entry_Family,
      Construct_Requeue_Statement,
      Construct_Accept_Statement,
      Construct_Selective_Accept,
      Construct_Terminate_Alternative,
      Construct_Abort_Statement,
      Construct_Abortable_Select,
      Construct_Parallel_Loop,
      Construct_Reduction,
      Construct_Container_Iterator,
      Construct_Synchronized_Interface,
      Construct_Volatile_State,
      Construct_Atomic_State,
      Construct_Controlled_Finalization,
      Construct_Unknown);

   type Tasking_Context_Kind is
     (Context_Protected_Action,
      Context_Protected_Barrier,
      Context_Task_Body,
      Context_Task_Entry,
      Context_Select_Statement,
      Context_Abort_Finalization,
      Context_Parallel_Loop,
      Context_Iterator,
      Context_Reduction,
      Context_Synchronized_Interface,
      Context_Flow_Refinement,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Protected_Reentrant_Call,
      Status_Illegal_Protected_Access_Mode_Mismatch,
      Status_Illegal_Protected_Barrier_Side_Effect,
      Status_Illegal_Protected_Shared_State_Write_Without_Effect,
      Status_Illegal_Entry_Family_Index_Range,
      Status_Illegal_Entry_Queue_Discipline,
      Status_Illegal_Missing_Accept_Body_Effect_Evidence,
      Status_Illegal_Requeue_Target_Mismatch,
      Status_Illegal_Select_Path_Not_Covered,
      Status_Illegal_Terminate_Alternative_Unsafe,
      Status_Illegal_Abort_Finalization_Order,
      Status_Illegal_Abortable_Select_Finalization_Unsafe,
      Status_Illegal_Task_Termination_Finalization_Blocker,
      Status_Illegal_Controlled_Finalization_Evidence_Missing,
      Status_Illegal_Parallel_Shared_State_Write,
      Status_Illegal_Iterator_Tampering,
      Status_Illegal_Reduction_Profile_Mismatch,
      Status_Illegal_Reduction_Seed_Mismatch,
      Status_Illegal_Global_Depends_Evidence_Lost,
      Status_Illegal_Refined_Flow_Evidence_Lost,
      Status_Illegal_Volatile_Ordering_Lost,
      Status_Illegal_Atomic_Ordering_Lost,
      Status_Illegal_Dispatching_Effect_Join_Missing,
      Status_Illegal_Synchronized_Interface_Effect_Disagreement,
      Status_Runtime_Tampering_Check_Preserved,
      Status_Runtime_Bounds_Check_Preserved,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Effect_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Tasking_Model_Disagreement,
      Status_Consumer_Protected_Model_Disagreement,
      Status_Consumer_Flow_Model_Disagreement,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Flow_Fingerprint_Mismatch,
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
      Construct : Tasking_Construct_Kind := Construct_Unknown;
      Context : Tasking_Context_Kind := Context_Unknown;
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
      Protected_Action_Reentrancy_Safe : Boolean := True;
      Protected_Access_Mode_Compatible : Boolean := True;
      Protected_Barrier_Pure : Boolean := True;
      Protected_Shared_State_Write_Has_Effect : Boolean := True;
      Entry_Family_Index_In_Range : Boolean := True;
      Entry_Queue_Discipline_Compatible : Boolean := True;
      Accept_Body_Effect_Evidence_Present : Boolean := True;
      Requeue_Target_Compatible : Boolean := True;
      Select_Path_Covered : Boolean := True;
      Terminate_Alternative_Dependency_Safe : Boolean := True;
      Abort_Finalization_Order_Safe : Boolean := True;
      Abortable_Select_Finalization_Safe : Boolean := True;
      Task_Termination_Finalization_Safe : Boolean := True;
      Controlled_Finalization_Evidence_Present : Boolean := True;
      Parallel_Shared_State_Effects_Valid : Boolean := True;
      Iterator_Tampering_Static_Safe : Boolean := True;
      Iterator_Tampering_Runtime_Check : Boolean := False;
      Reduction_Profile_Compatible : Boolean := True;
      Reduction_Seed_Compatible : Boolean := True;
      Global_Depends_Evidence_Preserved : Boolean := True;
      Refined_Flow_Evidence_Preserved : Boolean := True;
      Volatile_Ordering_Preserved : Boolean := True;
      Atomic_Ordering_Preserved : Boolean := True;
      Dispatching_Effect_Join_Present : Boolean := True;
      Synchronized_Interface_Effects_Agree : Boolean := True;
      Runtime_Bounds_Check : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Consumer_Tasking_Model_Agrees : Boolean := True;
      Consumer_Protected_Model_Agrees : Boolean := True;
      Consumer_Flow_Model_Agrees : Boolean := True;
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
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
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
   function Tasking_Protected_Parallel_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1348;
