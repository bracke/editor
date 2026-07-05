with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;
with Editor.Ada_RM_Gap_Burn_Down_Case_1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Case_1368 is

   --  Case 1368 remediates a concrete remaining gap extracted by the final
   --  inventory: a generic body replay of an aggregate actual for a
   --  discriminated private formal type.  The rule requires the substituted
   --  full view, discriminant/variant/default component evidence,
   --  predicate/runtime-check evidence, and aggregate consumer evidence to
   --  agree before the gap may be promoted to covered.

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
     (Remaining_Generic_Discriminated_Private_Aggregate_Edge,
      Remaining_Generic_Aggregate_Consumer_Surface_Edge,
      Remaining_Gap_Unknown);

   type Generic_Aggregate_Form is
     (Formal_Private_Type_Aggregate,
      Formal_Derived_Type_Aggregate,
      Formal_Record_Type_Aggregate,
      Formal_Array_Component_Aggregate,
      Nested_Generic_Aggregate_Replay,
      Aggregate_Form_Unknown);

   type Aggregate_Actual_Form is
     (Actual_Full_View_Aggregate,
      Actual_Private_View_Only,
      Actual_Missing_Discriminant,
      Actual_Defaulted_Discriminant,
      Actual_Inactive_Variant_Component,
      Actual_Runtime_Predicate_Check,
      Actual_Static_Predicate_Failure,
      Actual_Missing_Substitution,
      Actual_Unknown);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Gap_Remediated,
      Status_Legal_Substituted_Aggregate,
      Status_Runtime_Predicate_Check_Preserved,
      Status_Illegal_Missing_Discriminant,
      Status_Illegal_Inactive_Variant_Component,
      Status_Illegal_Static_Predicate_Failure,
      Status_Illegal_Full_View_Not_Used_For_Replay,
      Status_Illegal_Aggregate_Consumer_Disagreement,
      Status_Illegal_Generic_Substitution_Lost,
      Status_Illegal_Body_Replay_Uses_Formal_Placeholder,
      Status_Illegal_Discriminant_Compatibility_Lost,
      Status_Illegal_Default_Component_Evidence_Lost,
      Status_Illegal_Variant_Governor_Evidence_Lost,
      Status_Illegal_Predicate_Evidence_Lost,
      Status_Illegal_Consumer_Surface_Disagreement,
      Status_Indeterminate_Private_View_Only,
      Status_Indeterminate_Missing_Substitution_Evidence,
      Status_Indeterminate_Missing_Full_View_Evidence,
      Status_Indeterminate_Missing_Aggregate_Shape,
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
      Status_Aggregate_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Predicate_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Family : RM_Family := Matrix.Family_Generics_Contracts_Substitution_Replay;
      Owner : Implementing_Slice := Matrix.Slice_Generic_Body_Replay;
      Previous_Readiness : Release_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Previous_Remediation : Remediation_State := Remediation.State_Partial;
      Target_Remediation : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Partial;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Form : Generic_Aggregate_Form := Formal_Private_Type_Aggregate;
      Actual : Aggregate_Actual_Form := Actual_Full_View_Aggregate;
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

      Substitution_Evidence_Present : Boolean := True;
      Body_Replay_Uses_Substituted_Actuals : Boolean := True;
      Full_View_Available : Boolean := True;
      Full_View_Used_For_Replay : Boolean := True;
      Aggregate_Shape_Complete : Boolean := True;
      Required_Discriminants_Present : Boolean := True;
      Discriminant_Compatibility_Preserved : Boolean := True;
      Default_Component_Evidence_Preserved : Boolean := True;
      Variant_Governor_Evidence_Preserved : Boolean := True;
      Inactive_Variant_Component : Boolean := False;
      Static_Predicate_Failure : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Predicate_Evidence_Preserved : Boolean := True;
      Aggregate_Consumer_Agrees : Boolean := True;
      Consumer_Surface_Agrees : Boolean := True;

      Private_View_Only : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Full_View_Evidence : Boolean := False;
      Missing_Aggregate_Shape : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Stale_Inventory_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Aggregate_Fingerprint : Natural := 0;
      Expected_Aggregate_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Predicate_Fingerprint : Natural := 0;
      Expected_Predicate_Fingerprint : Natural := 0;
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

end Editor.Ada_RM_Remaining_Gap_Remediation_Case_1368;
