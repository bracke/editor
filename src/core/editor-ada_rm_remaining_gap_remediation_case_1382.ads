with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1382 is

   --  Case 1382 remediates a concrete remaining gap extracted by the final
   --  inventory: dispatching calls through interfaces, abstract/null primitive
   --  completion, class-wide conversions, and contract/effect joins must share
   --  one canonical tagged/interface result.

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
     (Remaining_Dispatching_Null_Abstract_Effect_Edge,
      Remaining_Tagged_Interface_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Dispatch_Context is
     (Context_Interface_Dispatching_Call,
      Context_Null_Procedure_Primitive,
      Context_Abstract_Primitive_Completion,
      Context_Class_Wide_Conversion,
      Context_Dispatching_Effect_Join,
      Context_Unknown);

   type Dispatch_Form is
     (Dispatch_Interface_Call_Agreement,
      Dispatch_Missing_Interface_Evidence,
      Dispatch_Illegal_Abstract_Primitive_Left_Unimplemented,
      Dispatch_Illegal_Null_Procedure_Profile,
      Dispatch_Illegal_Ambiguous_Dispatching_Candidate,
      Dispatch_Illegal_Class_Wide_Conversion,
      Dispatch_Illegal_Effect_Join_Mismatch,
      Dispatch_Runtime_Tag_Check,
      Dispatch_Private_View_Indeterminate,
      Dispatch_Stale_Dispatch_Evidence,
      Dispatch_Consumer_Disagreement,
      Dispatch_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Dispatching_Interface_Agreement,
      Status_Runtime_Tag_Check_Preserved,
      Status_Illegal_Abstract_Primitive_Unimplemented,
      Status_Illegal_Null_Procedure_Profile,
      Status_Illegal_Ambiguous_Dispatching_Candidate,
      Status_Illegal_Class_Wide_Conversion,
      Status_Illegal_Effect_Join_Mismatch,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Interface_Evidence,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Stale_Dispatch_Evidence,
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
      Status_Profile_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Tagged_Interfaces_Dispatching;
      Owner : Implementing_Slice := Matrix.Slice_Tagged_Dispatching;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Dispatch_Context := Context_Interface_Dispatching_Call;
      Form : Dispatch_Form := Dispatch_Interface_Call_Agreement;
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

      Interface_Evidence_Present : Boolean := True;
      Private_Full_View_Available : Boolean := True;
      Abstract_Primitive_Unimplemented : Boolean := False;
      Null_Procedure_Profile_Mismatch : Boolean := False;
      Ambiguous_Dispatching_Candidate : Boolean := False;
      Class_Wide_Conversion_Mismatch : Boolean := False;
      Effect_Join_Mismatch : Boolean := False;
      Runtime_Tag_Check : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;
      Stale_Dispatch_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1382;
