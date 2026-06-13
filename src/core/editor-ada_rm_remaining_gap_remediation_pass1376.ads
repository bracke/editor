with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1376 is

   --  Pass1376 remediates a concrete remaining gap extracted by the final
   --  inventory: enumeration attributes and representation evidence must be
   --  shared by literal resolution, static expression evaluation, case/choice
   --  legality, assignments/conversions, and semantic consumers.  The pass
   --  keeps static attribute failures separate from runtime checks and from
   --  indeterminate missing literal/representation/full-view evidence.

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
     (Remaining_Enumeration_Attribute_Representation_Edge,
      Remaining_Enumeration_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Enumeration_Context is
     (Context_Enumeration_Attribute,
      Context_Enumeration_Representation,
      Context_Enumeration_Static_Choice,
      Context_Enumeration_Assignment,
      Context_Enumeration_Case,
      Context_Unknown);

   type Enumeration_Form is
     (Enum_Compatible,
      Enum_Missing_Literal_Evidence,
      Enum_Duplicate_Representation_Code,
      Enum_Incomplete_Representation_Clause,
      Enum_Non_Static_Representation_Value,
      Enum_Attribute_Pos_Out_Of_Range,
      Enum_Attribute_Val_Out_Of_Range,
      Enum_Attribute_Succ_Pred_Bounds,
      Enum_Attribute_Value_Runtime_Check,
      Enum_Ambiguous_Literal,
      Enum_Private_View_Indeterminate,
      Enum_Stale_Representation_Evidence,
      Enum_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Enumeration_Attribute_Agreement,
      Status_Runtime_Value_Check_Preserved,
      Status_Illegal_Duplicate_Representation_Code,
      Status_Illegal_Incomplete_Representation_Clause,
      Status_Illegal_Non_Static_Representation_Value,
      Status_Illegal_Attribute_Pos_Out_Of_Range,
      Status_Illegal_Attribute_Val_Out_Of_Range,
      Status_Illegal_Attribute_Succ_Pred_Bounds,
      Status_Illegal_Ambiguous_Literal,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Literal_Evidence,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Stale_Representation_Evidence,
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
      Status_Representation_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Static_Expressions_Choices;
      Owner : Implementing_Slice := Matrix.Slice_Enumeration_Representation;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Context : Enumeration_Context := Context_Enumeration_Attribute;
      Form : Enumeration_Form := Enum_Compatible;
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

      Literal_Evidence_Present : Boolean := True;
      Private_Full_View_Available : Boolean := True;
      Duplicate_Representation_Code : Boolean := False;
      Incomplete_Representation_Clause : Boolean := False;
      Non_Static_Representation_Value : Boolean := False;
      Attribute_Pos_Out_Of_Range : Boolean := False;
      Attribute_Val_Out_Of_Range : Boolean := False;
      Attribute_Succ_Pred_Bounds_Error : Boolean := False;
      Runtime_Value_Check : Boolean := False;
      Ambiguous_Literal : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;
      Stale_Representation_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1376;
