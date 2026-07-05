with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1424 is

   --  Case 1424 remediates a concrete remaining gap extracted by the frozen
   --  inventory: universal numeric operands in expected-type contexts,
   --  stateful expected-context changes, static numeric range evidence,
   --  runtime numeric checks, warning diagnostics, stale expected-context
   --  evidence, and semantic consumers must be checked as one source-shaped
   --  Ada legality result. The closure preserves legal, illegal, runtime-
   --  check, warning-only, indeterminate, consumer, final-gate, and
   --  fingerprint freshness outcomes under one stable blocker family.

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
     (Remaining_Universal_Numeric_Stateful_Expected_Context_Edge,
      Remaining_Gap_Unknown);

   type Universal_Numeric_Expected_Context_Closure is
     (Closure_Expected_Type_Evidence,
     Closure_Universal_Operand_Evidence,
     Closure_Static_Numeric_Evidence,
     Closure_Numeric_Consumer,
     Closure_Unknown);

   type Universal_Numeric_Expected_Context_Form is
     (Form_Universal_Numeric_Expected_Context_Resolved,
     Form_Universal_Operand_Context_Resolved,
     Form_Runtime_Numeric_Check_Preserved,
     Form_Warning_Only_Preserved,
     Form_Illegal_Ambiguous_Universal_Expression,
     Form_Illegal_Universal_Integer_Real_Mismatch,
     Form_Illegal_Modular_Expected_Context_Overflow,
     Form_Illegal_Stateful_Context_Changes_Resolution,
     Form_Illegal_Static_Numeric_Range_Violation,
     Form_Indeterminate_Private_Numeric_View,
     Form_Indeterminate_Missing_Expected_Type_Evidence,
     Form_Indeterminate_Missing_Static_Numeric_Evidence,
     Form_Indeterminate_Stale_Expected_Context_Evidence,
     Form_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
     Status_Gap_Remediated,
     Status_Universal_Numeric_Expected_Context_Resolved,
     Status_Universal_Operand_Context_Resolved,
     Status_Runtime_Numeric_Check_Preserved,
     Status_Warning_Only_Preserved,
     Status_Illegal_Ambiguous_Universal_Expression,
     Status_Illegal_Universal_Integer_Real_Mismatch,
     Status_Illegal_Modular_Expected_Context_Overflow,
     Status_Illegal_Stateful_Context_Changes_Resolution,
     Status_Illegal_Static_Numeric_Range_Violation,
     Status_Indeterminate_Private_Numeric_View,
     Status_Indeterminate_Missing_Expected_Type_Evidence,
     Status_Indeterminate_Missing_Static_Numeric_Evidence,
     Status_Indeterminate_Stale_Expected_Context_Evidence,
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
     Status_Expected_Context_Fingerprint_Mismatch,
     Status_Numeric_Fingerprint_Mismatch,
     Status_Effect_Fingerprint_Mismatch,
     Status_Consumer_Fingerprint_Mismatch,
     Status_Multiple_Blockers,
     Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Expressions_Expected_Type_Resolution;
      Owner : Implementing_Slice := Matrix.Slice_Ada2022_Expression_Type_Resolution;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Closure : Universal_Numeric_Expected_Context_Closure := Closure_Expected_Type_Evidence;
      Form : Universal_Numeric_Expected_Context_Form := Form_Universal_Numeric_Expected_Context_Resolved;
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
      Warning_Only_Test_Present : Boolean := True;
      Indeterminate_Test_Present : Boolean := True;
      Consumer_Surfaced_Test_Present : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Coverage_Promoted_To_Covered : Boolean := True;
      Final_Gate_No_Longer_Reports_Gap : Boolean := True;

      Complete_Expected_Type_Evidence : Boolean := True;
      Complete_Static_Numeric_Evidence : Boolean := True;
      Consumer_State_Agrees : Boolean := True;
      Missing_Full_View : Boolean := False;
      Missing_Expected_Type_Evidence : Boolean := False;
      Missing_Static_Numeric_Evidence : Boolean := False;
      Stale_Expected_Context_Evidence : Boolean := False;
      Ambiguous_Universal_Expression : Boolean := False;
      Universal_Integer_Real_Mismatch : Boolean := False;
      Modular_Expected_Context_Overflow : Boolean := False;
      Stateful_Context_Changes_Resolution : Boolean := False;
      Static_Numeric_Range_Violation : Boolean := False;
      Runtime_Numeric_Check_Preserved : Boolean := False;
      Warning_Only_Preserved : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Context_Fingerprint : Natural := 0;
      Expected_Expected_Context_Fingerprint : Natural := 0;
      Numeric_Fingerprint : Natural := 0;
      Expected_Numeric_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1424;
