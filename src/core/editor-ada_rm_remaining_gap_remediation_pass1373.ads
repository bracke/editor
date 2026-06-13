with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1373 is

   --  Pass1373 remediates a concrete remaining gap extracted by the final
   --  inventory: a body stub and separate body reached through private-view
   --  elaboration evidence must preserve canonical unit, completion,
   --  private/full-view, body-profile, alias, and consumer evidence.  This
   --  closes a real edge where diagnostics and navigation can otherwise
   --  disagree about whether the completed body is visible, elaborated,
   --  matched to its stub, or indeterminate.

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
     (Remaining_Body_Stub_Elaboration_Private_View_Edge,
      Remaining_Body_Stub_Elaboration_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Renaming_Form is
     (Object_Renaming,
      Subprogram_Renaming,
      Package_Renaming,
      Exception_Renaming,
      Generic_Renaming,
      Entry_Renaming,
      Operator_Renaming,
      Renaming_Form_Unknown);

   type Visibility_Form is
     (Visibility_Compatible,
      Visibility_Private_Child_Leak,
      Visibility_Renamed_Target_Invisible,
      Visibility_Selected_Name_Ambiguous,
      Visibility_Alias_Cycle,
      Visibility_Profile_Mismatch,
      Visibility_Runtime_Access_Check,
      Visibility_Limited_View_Only,
      Visibility_Missing_Cross_Unit_Evidence,
      Visibility_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Renamed_Visibility_Agreement,
      Status_Runtime_Access_Check_Preserved,
      Status_Illegal_Private_Child_Visibility_Leak,
      Status_Illegal_Renamed_Target_Invisible,
      Status_Illegal_Selected_Name_Ambiguous,
      Status_Illegal_Alias_Cycle,
      Status_Illegal_Alias_Depth_Overflow,
      Status_Illegal_Renamed_Profile_Mismatch,
      Status_Illegal_Renamed_Type_View_Mismatch,
      Status_Illegal_Use_Visible_Homograph_Conflict,
      Status_Illegal_Private_Full_View_Disagreement,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Limited_View_Only,
      Status_Indeterminate_Private_View_Only,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Selected_Name_Evidence,
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
      Status_Entity_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Alias_Fingerprint_Mismatch,
      Status_Visibility_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Names_Visibility_Selected_Attributes;
      Owner : Implementing_Slice := Matrix.Slice_Visibility_Name_Resolution;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Form : Renaming_Form := Object_Renaming;
      Visibility : Visibility_Form := Visibility_Compatible;
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

      Private_Child_Visible : Boolean := True;
      Renamed_Target_Visible : Boolean := True;
      Selected_Name_Unambiguous : Boolean := True;
      Alias_Cycle : Boolean := False;
      Alias_Depth_Overflow : Boolean := False;
      Renamed_Profile_Agrees : Boolean := True;
      Renamed_Type_View_Agrees : Boolean := True;
      Use_Visible_Homograph_Conflict : Boolean := False;
      Private_Full_View_Agrees : Boolean := True;
      Runtime_Access_Check : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;

      Limited_View_Only : Boolean := False;
      Private_View_Only : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Selected_Name_Evidence : Boolean := False;
      Stale_Inventory_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Entity_Fingerprint : Natural := 0;
      Expected_Entity_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Alias_Fingerprint : Natural := 0;
      Expected_Alias_Fingerprint : Natural := 0;
      Visibility_Fingerprint : Natural := 0;
      Expected_Visibility_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1373;
