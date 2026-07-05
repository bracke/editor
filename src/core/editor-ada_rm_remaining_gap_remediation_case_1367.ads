with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1367 is

   --  Case 1367 is the first remaining-gap remediation case after the final
   --  final burn-down inventory.  It closes one concrete inventory item instead of
   --  adding another broad audit: call actual association when a defaulted
   --  access formal has a null exclusion and accessibility/runtime-check
   --  evidence must be preserved through overload, callable-profile,
   --  generic-substitution, renaming, and consumer surfaces.

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
     (Remaining_Call_Defaulted_Null_Exclusion_Access_Edge,
      Remaining_Consumer_Surface_Edge_Case,
      Remaining_Gap_Unknown);

   type Call_Form is
     (Call_Direct_Subprogram,
      Call_Dispatching,
      Call_Generic_Formal_Subprogram,
      Call_Renamed_Subprogram,
      Call_Access_To_Subprogram,
      Call_Unknown);

   type Actual_Form is
     (Actual_Explicit_Nonnull_Access,
      Actual_Explicit_Null,
      Actual_Defaulted_Nonnull_Access,
      Actual_Defaulted_Null,
      Actual_Static_Escape,
      Actual_Runtime_Accessibility_Check,
      Actual_Missing_Profile_Evidence,
      Actual_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Defaulted_Access_Formal,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Warning_Only_Consumer_Surface_Preserved,
      Status_Illegal_Default_Null_For_Null_Excluded_Formal,
      Status_Illegal_Explicit_Null_For_Null_Excluded_Formal,
      Status_Illegal_Static_Accessibility_Escape,
      Status_Illegal_Missing_Required_Actual,
      Status_Illegal_Extra_Actual,
      Status_Illegal_Duplicate_Actual,
      Status_Illegal_Named_Positional_Order,
      Status_Illegal_Defaulted_Formal_Lost,
      Status_Illegal_Null_Exclusion_Not_Checked,
      Status_Illegal_Callable_Profile_Disagreement,
      Status_Illegal_Overload_Profile_Disagreement,
      Status_Illegal_Generic_Substitution_Profile_Lost,
      Status_Illegal_Renaming_Profile_Lost,
      Status_Illegal_Access_To_Subprogram_Convention_Lost,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Missing_Call_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Indeterminate_Missing_Substitution_Evidence,
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
      Status_Call_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Overload_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Accessibility_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Calls_Overload_Callable_Profiles;
      Owner : Implementing_Slice := Matrix.Slice_Callable_Profile;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Form : Call_Form := Call_Direct_Subprogram;
      Actual : Actual_Form := Actual_Explicit_Nonnull_Access;
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

      Actual_Association_Shape_Complete : Boolean := True;
      Required_Actual_Present_Or_Defaulted : Boolean := True;
      Extra_Actual : Boolean := False;
      Duplicate_Actual : Boolean := False;
      Named_Positional_Order_OK : Boolean := True;
      Defaulted_Formal_Preserved : Boolean := True;
      Null_Exclusion_Checked : Boolean := True;
      Explicit_Null_For_Null_Excluded_Formal : Boolean := False;
      Default_Null_For_Null_Excluded_Formal : Boolean := False;
      Static_Accessibility_Escape : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Callable_Profile_Agrees : Boolean := True;
      Overload_Profile_Agrees : Boolean := True;
      Generic_Substitution_Profile_Preserved : Boolean := True;
      Renaming_Profile_Preserved : Boolean := True;
      Access_To_Subprogram_Convention_Preserved : Boolean := True;
      Consumer_Surface_Agrees : Boolean := True;

      Missing_Call_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Stale_Inventory_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Call_Fingerprint : Natural := 0;
      Expected_Call_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Overload_Fingerprint : Natural := 0;
      Expected_Overload_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Accessibility_Fingerprint : Natural := 0;
      Expected_Accessibility_Fingerprint : Natural := 0;
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
   function Count (Results : Remediation_Model) return Natural;
   function Result_At (Results : Remediation_Model; Index : Positive)
     return Remediation_Entry;
   function Result_For (Results : Remediation_Model; Id : Natural)
     return Remediation_Entry;
   function Expected_For_Status
     (Status : Remediation_Status) return Precision_Classification;
   function Gap_Remediated (Results : Remediation_Model) return Boolean;

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1367;
