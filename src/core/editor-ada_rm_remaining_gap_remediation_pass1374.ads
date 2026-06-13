with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1374 is

   --  Pass1374 remediates a concrete remaining gap extracted by the final
   --  inventory: static string and character literal bounds used through
   --  slices, aggregates, membership tests, assignments, and indexed names
   --  must preserve one canonical literal/root-type/range/consumer result.
   --  The pass distinguishes static illegal bounds from legal runtime checks
   --  and indeterminate evidence when the expected array or index subtype is
   --  unavailable.

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
     (Remaining_Static_String_Slice_Bounds_Edge,
      Remaining_Static_String_Slice_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Literal_Context is
     (Context_String_Assignment,
      Context_String_Aggregate_Component,
      Context_String_Slice,
      Context_String_Index,
      Context_Membership_Test,
      Context_Case_Choice,
      Context_Unknown);

   type Bounds_Form is
     (Bounds_Compatible,
      Bounds_Static_Lower_Above_Upper,
      Bounds_Static_Index_Out_Of_Range,
      Bounds_String_Length_Mismatch,
      Bounds_Character_Element_Mismatch,
      Bounds_Null_Literal_In_Non_Access_Context,
      Bounds_Runtime_Index_Check,
      Bounds_Runtime_Range_Check,
      Bounds_Missing_Expected_Array_Type,
      Bounds_Missing_Index_Subtype,
      Bounds_Stale_Static_Evidence,
      Bounds_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Static_String_Bounds_Agreement,
      Status_Runtime_Index_Check_Preserved,
      Status_Runtime_Range_Check_Preserved,
      Status_Illegal_Static_Lower_Above_Upper,
      Status_Illegal_Static_Index_Out_Of_Range,
      Status_Illegal_String_Length_Mismatch,
      Status_Illegal_Character_Element_Mismatch,
      Status_Illegal_Null_Literal_Non_Access_Context,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Expected_Array_Type,
      Status_Indeterminate_Missing_Index_Subtype,
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
      Status_Choice_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Static_Expressions_Choices;
      Owner : Implementing_Slice := Matrix.Slice_Numeric_Static_Expression;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Literal_Context := Context_String_Assignment;
      Bounds : Bounds_Form := Bounds_Compatible;
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

      Expected_Array_Type_Present : Boolean := True;
      Index_Subtype_Present : Boolean := True;
      Static_Lower_Above_Upper : Boolean := False;
      Static_Index_Out_Of_Range : Boolean := False;
      String_Length_Matches_Target : Boolean := True;
      Character_Element_Compatible : Boolean := True;
      Null_Literal_In_Access_Context : Boolean := True;
      Runtime_Index_Check : Boolean := False;
      Runtime_Range_Check : Boolean := False;
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
      Choice_Fingerprint : Natural := 0;
      Expected_Choice_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1374;
