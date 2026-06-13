with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1375 is

   --  Pass1375 remediates a concrete remaining gap extracted by the final
   --  inventory: decimal/ordinary fixed-point conversion, rounding, scale,
   --  and range evidence must be shared by static expressions, conversions,
   --  assignments, predicates, contracts, and diagnostics.  The pass keeps
   --  static illegal fixed-point failures separate from legal runtime checks
   --  and from indeterminate missing delta/digits/expected-type evidence.

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
     (Remaining_Fixed_Point_Conversion_Rounding_Edge,
      Remaining_Fixed_Point_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Fixed_Point_Context is
     (Context_Fixed_Point_Conversion,
      Context_Fixed_Point_Assignment,
      Context_Fixed_Point_Static_Expression,
      Context_Fixed_Point_Predicate,
      Context_Fixed_Point_Contract,
      Context_Unknown);

   type Fixed_Point_Form is
     (Fixed_Compatible,
      Fixed_Static_Range_Overflow,
      Fixed_Static_Delta_Mismatch,
      Fixed_Static_Digits_Mismatch,
      Fixed_Non_Static_Delta_Required,
      Fixed_Invalid_Universal_Real_Resolution,
      Fixed_Rounding_Mode_Disagreement,
      Fixed_Runtime_Range_Check,
      Fixed_Runtime_Predicate_Check,
      Fixed_Missing_Target_Fixed_Type,
      Fixed_Missing_Delta_Evidence,
      Fixed_Missing_Digits_Evidence,
      Fixed_Stale_Static_Evidence,
      Fixed_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Fixed_Point_Conversion_Agreement,
      Status_Runtime_Range_Check_Preserved,
      Status_Runtime_Predicate_Check_Preserved,
      Status_Illegal_Static_Range_Overflow,
      Status_Illegal_Static_Delta_Mismatch,
      Status_Illegal_Static_Digits_Mismatch,
      Status_Illegal_Non_Static_Delta_Required,
      Status_Illegal_Universal_Real_Resolution,
      Status_Illegal_Rounding_Mode_Disagreement,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Target_Fixed_Type,
      Status_Indeterminate_Missing_Delta_Evidence,
      Status_Indeterminate_Missing_Digits_Evidence,
      Status_Indeterminate_Stale_Static_Evidence,
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
      Status_Static_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Types_Subtypes_Constraints_Predicates;
      Owner : Implementing_Slice := Matrix.Slice_Subtype_Range_Predicate;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Fixed_Point_Context := Context_Fixed_Point_Conversion;
      Form : Fixed_Point_Form := Fixed_Compatible;
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

      Target_Fixed_Type_Present : Boolean := True;
      Delta_Evidence_Present : Boolean := True;
      Digits_Evidence_Present : Boolean := True;
      Static_Range_Overflow : Boolean := False;
      Static_Delta_Mismatch : Boolean := False;
      Static_Digits_Mismatch : Boolean := False;
      Non_Static_Delta_Required : Boolean := False;
      Universal_Real_Resolution_Valid : Boolean := True;
      Rounding_Mode_Agrees : Boolean := True;
      Runtime_Range_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;
      Stale_Static_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1375;
