with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1378 is

   --  Case 1378 remediates a concrete remaining gap extracted by the final
   --  inventory: exception handlers, reraise legality, exception propagation,
   --  controlled finalization, and task/abort finalization evidence must share
   --  one canonical exception/finalization result.  The pass keeps local
   --  handler coverage, runtime propagation/finalization checks, and
   --  indeterminate missing-handler/private-view/stale evidence separate from
   --  hard illegal diagnostics.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;
   package Inventory renames Editor.Ada_RM_Gap_Burn_Down_Case_1366;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;
   subtype Release_Readiness is Inventory.Release_Readiness;

   type Remediated_Gap_Family is
     (Remaining_Exception_Handler_Reraise_Finalization_Edge,
      Remaining_Exception_Finalization_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Exception_Context is
     (Context_Handler_Choice,
      Context_Reraise,
      Context_Exception_Propagation,
      Context_Controlled_Finalization,
      Context_Task_Abort_Finalization,
      Context_Unknown);

   type Exception_Form is
     (Exception_Finalization_Compatible,
      Exception_Missing_Handler_Evidence,
      Exception_Choice_Duplicate,
      Exception_Choice_Unreachable,
      Exception_Reraise_Outside_Handler,
      Exception_Handler_Kind_Mismatch,
      Exception_Controlled_Finalize_Profile_Mismatch,
      Exception_Finalization_Order_Hazard,
      Exception_Task_Abort_Finalization_Hazard,
      Exception_Runtime_Propagation_Check,
      Exception_Private_View_Indeterminate,
      Exception_Stale_Finalization_Evidence,
      Exception_Consumer_Disagreement,
      Exception_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Exception_Finalization_Agreement,
      Status_Runtime_Exception_Propagation_Check_Preserved,
      Status_Illegal_Duplicate_Handler_Choice,
      Status_Illegal_Unreachable_Handler_Choice,
      Status_Illegal_Reraise_Outside_Handler,
      Status_Illegal_Handler_Kind_Mismatch,
      Status_Illegal_Controlled_Finalize_Profile_Mismatch,
      Status_Illegal_Finalization_Order_Hazard,
      Status_Illegal_Task_Abort_Finalization_Hazard,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Handler_Evidence,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Stale_Finalization_Evidence,
      Status_Missing_Final_Inventory_Row,
      Status_Missing_Concrete_Subrule_Name,
      Status_Missing_Candidate_Owner,
      Status_No_New_Legality_Rule,
      Status_Source_Shaped_Evidence_Missing,
      Status_Coverage_Not_Promoted,
      Status_Remediation_State_Not_Covered,
      Status_Final_Gate_Still_Reports_Gap,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Unstable_Blocker_Family,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Exception_Fingerprint_Mismatch,
      Status_Finalization_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Exceptions_Finalization;
      Owner : Implementing_Slice := Matrix.Slice_Exception_Finalization;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Exception_Context := Context_Handler_Choice;
      Form : Exception_Form := Exception_Finalization_Compatible;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Concrete_Subrule : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Case : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Inventory_Row_From_Final_Burn_Down : Boolean := True;
      Named_Concrete_Subrule : Boolean := True;
      Candidate_Owner_Named : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Source_Shaped_Evidence : Boolean := True;
      Legal_Test_Present : Boolean := True;
      Illegal_Test_Present : Boolean := True;
      Runtime_Check_Test_Present : Boolean := True;
      Indeterminate_Test_Present : Boolean := True;
      Consumer_Surfaced_Test_Present : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Coverage_Promoted_To_Covered : Boolean := True;
      Final_Gate_No_Longer_Reports_Gap : Boolean := True;

      Handler_Evidence_Present : Boolean := True;
      Private_Full_View_Available : Boolean := True;
      Duplicate_Handler_Choice : Boolean := False;
      Unreachable_Handler_Choice : Boolean := False;
      Reraise_Outside_Handler : Boolean := False;
      Handler_Kind_Mismatch : Boolean := False;
      Controlled_Finalize_Profile_Mismatch : Boolean := False;
      Finalization_Order_Hazard : Boolean := False;
      Task_Abort_Finalization_Hazard : Boolean := False;
      Runtime_Exception_Propagation_Check : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;
      Stale_Finalization_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Exception_Fingerprint : Natural := 0;
      Expected_Exception_Fingerprint : Natural := 0;
      Finalization_Fingerprint : Natural := 0;
      Expected_Finalization_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Remediation_Row);

   type Remediation_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Remediation_Entry is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Status : Remediation_Status := Status_Not_Checked;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Remediation_Entry);

   type Remediation_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Remediated_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Remediation_Input; Row : Remediation_Row);
   function Build (Input : Remediation_Input) return Remediation_Model;
   function Result_For (Model : Remediation_Model; Id : Natural) return Remediation_Entry;
   function Expected_For_Status (Status : Remediation_Status) return Precision_Classification;
   function Gap_Remediated (Model : Remediation_Model) return Boolean;

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1378;
