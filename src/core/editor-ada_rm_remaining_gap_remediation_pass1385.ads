with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1385 is

   --  Pass1385 remediates a concrete remaining gap extracted by the final
   --  inventory: diagnostic/runtime-check/warning-only source spans must keep
   --  the same canonical blocker family, smallest meaningful span, secondary
   --  evidence ordering, and consumer-visible state across incremental edits.

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
     (Remaining_Diagnostic_Runtime_Warning_Source_Span_Edge,
      Remaining_Diagnostic_Consumer_State_Edge,
      Remaining_Gap_Unknown);

   type Diagnostic_Context is
     (Context_Call_Actual,
      Context_Aggregate_Association,
      Context_Attribute_Selector,
      Context_Operator,
      Context_Cross_Unit_Reference,
      Context_Recovered_Syntax,
      Context_Unknown);

   type Diagnostic_Form is
     (Diagnostic_Legal_No_Message,
      Diagnostic_Hard_Illegal_Precise_Span,
      Diagnostic_Runtime_Check_Preserved,
      Diagnostic_Warning_Only_Preserved,
      Diagnostic_Indeterminate_Recovered_Span,
      Diagnostic_Illegal_Duplicate_Blocker,
      Diagnostic_Illegal_Generic_Blocker_Used,
      Diagnostic_Illegal_Whole_Declaration_Span,
      Diagnostic_Illegal_Consumer_State_Disagreement,
      Diagnostic_Indeterminate_Stale_Diagnostic,
      Diagnostic_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_No_Diagnostic,
      Status_Illegal_Precise_Diagnostic,
      Status_Runtime_Check_Preserved,
      Status_Warning_Only_Preserved,
      Status_Indeterminate_Recovered_Source_Span,
      Status_Illegal_Duplicate_Diagnostic,
      Status_Illegal_Generic_Blocker_When_Precise_Exists,
      Status_Illegal_Imprecise_Whole_Declaration_Span,
      Status_Illegal_Consumer_State_Disagreement,
      Status_Indeterminate_Stale_Diagnostic,
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
      Status_Diagnostic_Fingerprint_Mismatch,
      Status_Span_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Owner : Implementing_Slice := Matrix.Slice_Diagnostics_Consumer;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Consumer_Disagreement;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Diagnostic_Context := Context_Call_Actual;
      Form : Diagnostic_Form := Diagnostic_Legal_No_Message;
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

      Precise_Blocker_Available : Boolean := True;
      Generic_Blocker_Used : Boolean := False;
      Duplicate_Diagnostic : Boolean := False;
      Smallest_Meaningful_Span : Boolean := True;
      Whole_Declaration_Span_Used : Boolean := False;
      Runtime_Check_Preserved : Boolean := False;
      Warning_Only_Preserved : Boolean := False;
      Recovered_Syntax : Boolean := False;
      Complete_Span_Evidence : Boolean := True;
      Consumer_State_Agrees : Boolean := True;
      Stale_Diagnostic : Boolean := False;
      Secondary_Evidence_Ordered : Boolean := True;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Expected_Diagnostic_Fingerprint : Natural := 0;
      Span_Fingerprint : Natural := 0;
      Expected_Span_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1385;
