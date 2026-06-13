with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1419 is

   --  Pass1419 remediates a concrete remaining gap extracted by the frozen
   --  inventory: protected action reentrancy, self-calls, entry calls,
   --  requeue/select interactions, runtime protected-action checks, warning
   --  diagnostics, stale protected-action evidence, and semantic consumers
   --  must be checked as one source-shaped Ada legality result. The closure
   --  preserves legal, illegal, runtime-check, warning-only, indeterminate,
   --  consumer, final-gate, and fingerprint freshness outcomes under one
   --  stable blocker family.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
   package Inventory renames Editor.Ada_RM_Gap_Burn_Down_Pass1366;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;
   subtype Release_Readiness is Inventory.Release_Readiness;

   type Remediated_Gap_Family is
     (Remaining_Protected_Action_Reentrancy_Edge,
      Remaining_Gap_Unknown);

   type Protected_Action_Reentrancy_Closure is
     (Closure_Protected_Action_Call_Graph,
     Closure_Reentrant_Call_Evidence,
     Closure_Requeue_Select_Evidence,
     Closure_Protected_Action_Consumer,
     Closure_Unknown);

   type Protected_Action_Reentrancy_Form is
     (Form_Protected_Action_Reentrancy_Resolved,
     Form_Protected_Self_Call_Resolved,
     Form_Runtime_Protected_Action_Check_Preserved,
     Form_Warning_Only_Preserved,
     Form_Illegal_Reentrant_Protected_Function_Call,
     Form_Illegal_Protected_Procedure_Barrier_Call,
     Form_Illegal_Entry_Call_During_Protected_Action,
     Form_Illegal_Requeue_Target_Reenters_Protected_Object,
     Form_Illegal_Select_Alternative_Reentrancy_Conflict,
     Form_Indeterminate_Private_Protected_View,
     Form_Indeterminate_Missing_Protected_Action_Evidence,
     Form_Indeterminate_Missing_Call_Graph_Evidence,
     Form_Indeterminate_Stale_Reentrancy_Evidence,
     Form_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
     Status_Gap_Remediated,
     Status_Protected_Action_Reentrancy_Resolved,
     Status_Protected_Self_Call_Resolved,
     Status_Runtime_Protected_Action_Check_Preserved,
     Status_Warning_Only_Preserved,
     Status_Illegal_Reentrant_Protected_Function_Call,
     Status_Illegal_Protected_Procedure_Barrier_Call,
     Status_Illegal_Entry_Call_During_Protected_Action,
     Status_Illegal_Requeue_Target_Reenters_Protected_Object,
     Status_Illegal_Select_Alternative_Reentrancy_Conflict,
     Status_Indeterminate_Private_Protected_View,
     Status_Indeterminate_Missing_Protected_Action_Evidence,
     Status_Indeterminate_Missing_Call_Graph_Evidence,
     Status_Indeterminate_Stale_Reentrancy_Evidence,
     Status_Missing_Pass1366_Inventory_Row,
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
     Status_Profile_Fingerprint_Mismatch,
     Status_Protected_Action_Fingerprint_Mismatch,
     Status_Call_Graph_Fingerprint_Mismatch,
     Status_Effect_Fingerprint_Mismatch,
     Status_Consumer_Fingerprint_Mismatch,
     Status_Multiple_Blockers,
     Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Tasking_Protected_Synchronized;
      Owner : Implementing_Slice := Matrix.Slice_Tasking_Protected;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Closure : Protected_Action_Reentrancy_Closure := Closure_Protected_Action_Call_Graph;
      Form : Protected_Action_Reentrancy_Form := Form_Protected_Action_Reentrancy_Resolved;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Concrete_Subrule : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Pass : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Inventory_Row_From_Pass1366 : Boolean := True;
      Named_Concrete_Subrule : Boolean := True;
      Candidate_Owner_Named : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Source_Shaped_Evidence : Boolean := True;
      Legal_Test_Present : Boolean := True;
      Illegal_Test_Present : Boolean := True;
      Runtime_Check_Test_Present : Boolean := True;
      Warning_Only_Test_Present : Boolean := True;
      Indeterminate_Test_Present : Boolean := True;
      Consumer_Surfaced_Test_Present : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Coverage_Promoted_To_Covered : Boolean := True;
      Final_Gate_No_Longer_Reports_Gap : Boolean := True;

      Complete_Protected_Action_Evidence : Boolean := True;
      Complete_Call_Graph_Evidence : Boolean := True;
      Consumer_State_Agrees : Boolean := True;
      Missing_Full_View : Boolean := False;
      Missing_Protected_Action_Evidence : Boolean := False;
      Missing_Call_Graph_Evidence : Boolean := False;
      Stale_Reentrancy_Evidence : Boolean := False;
      Reentrant_Protected_Function_Call : Boolean := False;
      Protected_Procedure_Barrier_Call : Boolean := False;
      Entry_Call_During_Protected_Action : Boolean := False;
      Requeue_Target_Reenters_Protected_Object : Boolean := False;
      Select_Alternative_Reentrancy_Conflict : Boolean := False;
      Runtime_Protected_Action_Check_Preserved : Boolean := False;
      Warning_Only_Preserved : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Protected_Action_Fingerprint : Natural := 0;
      Expected_Protected_Action_Fingerprint : Natural := 0;
      Call_Graph_Fingerprint : Natural := 0;
      Expected_Call_Graph_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
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
      Warning_Count : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1419;
