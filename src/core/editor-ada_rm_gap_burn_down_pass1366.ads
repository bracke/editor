with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1365;

package Editor.Ada_RM_Gap_Burn_Down_Pass1366 is

   --  Pass1366 is the twenty-fourth RM gap burn-down pass.  It uses the
   --  final semantic readiness gate from Pass1365 to extract the remaining
   --  Ada RM gaps as deterministic, source-shaped, owned inventory rows.
   --  The pass deliberately separates missing implementation from missing
   --  evidence, stale/cancelled/budget state, project/recovery blockers, and
   --  consumer surfacing gaps so that follow-up passes can burn down only
   --  concrete RM subrules instead of broad thematic guesses.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
   package Final_Gate renames Editor.Ada_RM_Gap_Burn_Down_Pass1365;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;
   subtype Final_Verdict is Final_Gate.Final_Verdict;

   type Extraction_Gap is
     (Gap_Remaining_Partial_Coverage,
      Gap_Remaining_Missing_Checker,
      Gap_Remaining_Indeterminate_Evidence,
      Gap_Remaining_Consumer_Surfacing,
      Gap_Release_Readiness_Classification,
      Gap_Unknown);

   type Release_Readiness is
     (Ready,
      Ready_With_Runtime_Checks,
      Ready_With_Warnings,
      Blocked_By_Evidence,
      Blocked_By_Project_State,
      Blocked_By_Missing_RM_Checker,
      Blocked_By_Partial_RM_Coverage,
      Blocked_By_Consumer_Disagreement,
      Readiness_Unknown);

   type Extraction_Status is
     (Status_Not_Checked,
      Status_Ready,
      Status_Ready_With_Runtime_Checks,
      Status_Ready_With_Warnings,
      Status_Evidence_Blocker_Extracted,
      Status_Project_Blocker_Extracted,
      Status_Missing_Checker_Actionable,
      Status_Partial_Coverage_Actionable,
      Status_Consumer_Disagreement_Actionable,
      Status_Vague_Partial_Row,
      Status_Missing_Subrule_Name,
      Status_Missing_Candidate_Owner,
      Status_Missing_RM_Family_Mapping,
      Status_Orphan_Missing_Checker,
      Status_Indeterminate_Misclassified_As_RM_Gap,
      Status_Stale_State_Counted_As_RM_Gap,
      Status_Cancelled_State_Counted_As_RM_Gap,
      Status_Budget_State_Counted_As_RM_Gap,
      Status_Consumer_Gap_Hidden,
      Status_Final_Clean_With_Remaining_Gaps,
      Status_Non_Source_Shaped_Report,
      Status_Nondeterministic_Report,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Project_Index_Fingerprint_Mismatch,
      Status_Closure_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Recovery_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Request_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Extraction_Row is record
      Id : Natural := 0;
      Gap : Extraction_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Coverage : Coverage_Level := Matrix.Coverage_Unknown;
      Remediation_Value : Remediation_State := Remediation.State_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Verdict : Final_Verdict := Final_Gate.Verdict_Unknown;
      Readiness : Release_Readiness := Readiness_Unknown;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Missing_Subrule : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Pass : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Source_Shaped_Report : Boolean := True;
      Deterministic_Report : Boolean := True;
      Maps_To_RM_Family : Boolean := True;
      Concrete_Subrules_Named : Boolean := True;
      Candidate_Owner_Named : Boolean := True;
      Missing_Checker_Owned : Boolean := True;
      Indeterminate_Is_Evidence_Blocker : Boolean := True;
      Evidence_Blocker_Not_RM_Gap : Boolean := True;
      Stale_Not_Counted_As_RM_Gap : Boolean := True;
      Cancelled_Not_Counted_As_RM_Gap : Boolean := True;
      Budget_Not_Counted_As_RM_Gap : Boolean := True;
      Consumer_Gap_Exposed : Boolean := True;
      Consumer_Disagreement : Boolean := False;
      Remaining_Partial_Or_Missing : Boolean := False;
      Final_Readiness_Marked_Clean : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Project_Index_Fingerprint : Natural := 0;
      Expected_Project_Index_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
      Recovery_Fingerprint : Natural := 0;
      Expected_Recovery_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
      Request_Fingerprint : Natural := 0;
      Expected_Request_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Extraction_Row);

   type Extraction_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Extraction_Entry is record
      Id : Natural := 0;
      Gap : Extraction_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Readiness : Release_Readiness := Readiness_Unknown;
      Status : Extraction_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Extraction_Entry);

   type Extraction_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Ready_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Warning_Count : Natural := 0;
      Evidence_Blocked_Count : Natural := 0;
      Project_Blocked_Count : Natural := 0;
      Missing_Checker_Count : Natural := 0;
      Partial_Coverage_Count : Natural := 0;
      Consumer_Disagreement_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Extraction_Input; Row : Extraction_Row);
   function Build (Input : Extraction_Input) return Extraction_Model;
   function Count (Results : Extraction_Model) return Natural;
   function Result_At (Results : Extraction_Model; Index : Positive) return Extraction_Entry;
   function Result_For (Results : Extraction_Model; Id : Natural) return Extraction_Entry;
   function Expected_For_Status (Status : Extraction_Status) return Precision_Classification;
   function Remaining_Gap_Inventory_Extracted (Results : Extraction_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1366;
