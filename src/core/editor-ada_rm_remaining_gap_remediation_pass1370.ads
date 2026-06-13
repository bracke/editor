with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1370 is

   --  Pass1370 remediates a concrete remaining gap extracted by the final
   --  inventory: parallel container iteration with reduction and tampering
   --  evidence must agree with shared-state effects, synchronized interfaces,
   --  runtime checks, and semantic consumers before the gap is removed.

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
     (Remaining_Parallel_Reduction_Tampering_Effect_Edge,
      Remaining_Parallel_Iterator_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Parallel_Item_Form is
     (Parallel_Array_Iterator,
      Parallel_Container_Element_Iterator,
      Parallel_Container_Cursor_Iterator,
      Parallel_Reduction_Expression,
      Parallel_Protected_Shared_State_Call,
      Parallel_Item_Unknown);

   type Parallel_Effect_Form is
     (Parallel_Effect_Compatible,
      Parallel_Effect_Shared_State_Write,
      Parallel_Effect_Tampering_Check,
      Parallel_Effect_Reduction_Profile_Mismatch,
      Parallel_Effect_Reduction_Seed_Mismatch,
      Parallel_Effect_Volatile_Order_Missing,
      Parallel_Effect_Atomic_Order_Missing,
      Parallel_Effect_Synchronized_Interface_Mismatch,
      Parallel_Effect_Runtime_Tampering_Check,
      Parallel_Effect_Private_View_Only,
      Parallel_Effect_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Parallel_Effect_Agreement,
      Status_Runtime_Tampering_Check_Preserved,
      Status_Illegal_Parallel_Shared_State_Write,
      Status_Illegal_Reduction_Profile_Mismatch,
      Status_Illegal_Reduction_Seed_Mismatch,
      Status_Illegal_Combiner_Result_Mismatch,
      Status_Illegal_Iterator_Element_Type_Mismatch,
      Status_Illegal_Container_Tampering_Static,
      Status_Illegal_Volatile_Order_Lost,
      Status_Illegal_Atomic_Order_Lost,
      Status_Illegal_Synchronized_Interface_Effect_Mismatch,
      Status_Illegal_Protected_Call_Effect_Lost,
      Status_Illegal_Global_Depends_Evidence_Lost,
      Status_Illegal_Dispatching_Effect_Join_Lost,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Private_View_Only,
      Status_Indeterminate_Limited_View_Only,
      Status_Indeterminate_Missing_Iterator_Profile,
      Status_Indeterminate_Missing_Effect_Evidence,
      Status_Indeterminate_Missing_Reduction_Evidence,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Stale_Inventory_Evidence,
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
      Status_Iterator_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Reduction_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Iterators_Parallel_Reductions;
      Owner : Implementing_Slice := Matrix.Slice_Iterator_Loop_Parallel;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Form : Parallel_Item_Form := Parallel_Container_Element_Iterator;
      Effect : Parallel_Effect_Form := Parallel_Effect_Compatible;
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
      Indeterminate_Test_Present : Boolean := True;
      Consumer_Surfaced_Test_Present : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Coverage_Promoted_To_Covered : Boolean := True;
      Final_Gate_No_Longer_Reports_Gap : Boolean := True;

      Iterator_Profile_Present : Boolean := True;
      Iterator_Element_Type_Agrees : Boolean := True;
      Reduction_Profile_Present : Boolean := True;
      Reduction_Profile_Agrees : Boolean := True;
      Reduction_Seed_Agrees : Boolean := True;
      Combiner_Result_Agrees : Boolean := True;
      Shared_State_Write_Without_Effect : Boolean := False;
      Static_Tampering : Boolean := False;
      Runtime_Tampering_Check : Boolean := False;
      Global_Depends_Evidence_Preserved : Boolean := True;
      Volatile_Order_Preserved : Boolean := True;
      Atomic_Order_Preserved : Boolean := True;
      Synchronized_Interface_Effect_Agrees : Boolean := True;
      Protected_Call_Effect_Preserved : Boolean := True;
      Dispatching_Effect_Join_Preserved : Boolean := True;
      Consumer_Surface_Agrees : Boolean := True;

      Private_View_Only : Boolean := False;
      Limited_View_Only : Boolean := False;
      Missing_Iterator_Profile : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Missing_Reduction_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Stale_Inventory_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Iterator_Fingerprint : Natural := 0;
      Expected_Iterator_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Reduction_Fingerprint : Natural := 0;
      Expected_Reduction_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1370;
