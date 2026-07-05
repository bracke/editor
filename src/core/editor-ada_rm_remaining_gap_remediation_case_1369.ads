with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1369 is

   --  Case 1369 remediates a concrete remaining gap extracted by the final
   --  inventory: stream operational attributes attached to imported/exported
   --  entities with convention and external representation evidence.  The
   --  rule requires stream profile conformance, import/export compatibility,
   --  freezing, private/limited view barriers, and consumer surfacing to agree
   --  before the remaining gap may be removed from final readiness.

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
     (Remaining_Stream_Import_Export_Representation_Edge,
      Remaining_Stream_External_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Stream_Item_Form is
     (Stream_Read_Attribute,
      Stream_Write_Attribute,
      Stream_Input_Attribute,
      Stream_Output_Attribute,
      Imported_Callable_Stream_Item,
      Exported_Callable_Stream_Item,
      Stream_Item_Unknown);

   type External_Representation_Form is
     (External_Representation_Compatible,
      External_Representation_Import_Conflict,
      External_Representation_Export_Conflict,
      External_Representation_Convention_Mismatch,
      External_Representation_Stream_Profile_Mismatch,
      External_Representation_Late_After_Freezing,
      External_Representation_Private_View_Only,
      External_Representation_Runtime_Address_Check,
      External_Representation_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Stream_External_Agreement,
      Status_Runtime_Address_Check_Preserved,
      Status_Illegal_Stream_Profile_Mismatch,
      Status_Illegal_Import_Stream_Conflict,
      Status_Illegal_Export_Stream_Conflict,
      Status_Illegal_Convention_Profile_Mismatch,
      Status_Illegal_Late_Stream_Item_After_Freezing,
      Status_Illegal_Stream_Target_Kind_Mismatch,
      Status_Illegal_Operational_Item_Duplicate,
      Status_Illegal_External_Name_Missing,
      Status_Illegal_Link_Name_Mismatch,
      Status_Illegal_C_Callable_Profile_Mismatch,
      Status_Illegal_Access_Subprogram_Convention_Lost,
      Status_Illegal_Representation_Evidence_Lost,
      Status_Illegal_Freezing_Evidence_Lost,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Private_View_Only,
      Status_Indeterminate_Limited_View_Only,
      Status_Indeterminate_Missing_Stream_Profile,
      Status_Indeterminate_Missing_Convention_Evidence,
      Status_Indeterminate_Missing_Freezing_Evidence,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Stale_Inventory_Evidence,
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
      Status_Stream_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Representation_Fingerprint_Mismatch,
      Status_Freezing_Fingerprint_Mismatch,
      Status_Convention_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Representation_Aspects_Freezing;
      Owner : Implementing_Slice := Matrix.Slice_Representation_Aspect_Operational;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Form : Stream_Item_Form := Stream_Read_Attribute;
      External : External_Representation_Form := External_Representation_Compatible;
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

      Stream_Profile_Present : Boolean := True;
      Stream_Profile_Conforms : Boolean := True;
      Target_Kind_Valid : Boolean := True;
      Import_Stream_Conflict : Boolean := False;
      Export_Stream_Conflict : Boolean := False;
      Convention_Profile_Agrees : Boolean := True;
      C_Callable_Profile_Agrees : Boolean := True;
      Access_Subprogram_Convention_Preserved : Boolean := True;
      External_Name_Present : Boolean := True;
      Link_Name_Agrees : Boolean := True;
      Duplicate_Operational_Item : Boolean := False;
      Representation_Evidence_Preserved : Boolean := True;
      Freezing_Evidence_Preserved : Boolean := True;
      Stream_Item_Before_Freezing : Boolean := True;
      Runtime_Address_Check : Boolean := False;
      Consumer_Surface_Agrees : Boolean := True;

      Private_View_Only : Boolean := False;
      Limited_View_Only : Boolean := False;
      Missing_Stream_Profile : Boolean := False;
      Missing_Convention_Evidence : Boolean := False;
      Missing_Freezing_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Stale_Inventory_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Stream_Fingerprint : Natural := 0;
      Expected_Stream_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
      Freezing_Fingerprint : Natural := 0;
      Expected_Freezing_Fingerprint : Natural := 0;
      Convention_Fingerprint : Natural := 0;
      Expected_Convention_Fingerprint : Natural := 0;
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
   function Count (Results : Remediation_Model) return Natural;
   function Result_At (Results : Remediation_Model; Index : Positive)
     return Remediation_Entry;
   function Result_For (Results : Remediation_Model; Id : Natural)
     return Remediation_Entry;
   function Expected_For_Status
     (Status : Remediation_Status) return Precision_Classification;
   function Gap_Remediated (Results : Remediation_Model) return Boolean;

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1369;
