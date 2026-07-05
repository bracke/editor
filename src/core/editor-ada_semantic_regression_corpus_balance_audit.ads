with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_Semantic_Regression_Corpus_Balance_Audit is

   --  Semantic regression corpus balance audit is part of the post
   --  vertical-slice integration audit campaign.
   --  It checks that each covered Ada RM semantic family has a balanced,
   --  source-shaped regression corpus: legal, illegal, legal-with-runtime-
   --  check, indeterminate/blocked, and consumer-surfaced scenarios where
   --  applicable.  The audit prevents false confidence from one-sided test
   --  evidence and preserves the partial-evidence precision classifications through
   --  real editor semantic consumers.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Corpus_Group is
     (Group_Aggregate_Assignment_Predicate,
      Group_Overload_Callable_Conversion,
      Group_Generic_Replay_Flow,
      Group_Private_Full_Limited_Views,
      Group_Context_Library_Elaboration,
      Group_Representation_Interfacing_Freezing,
      Group_Tasking_Parallel_Shared_State,
      Group_Tagged_Interface_Contracts,
      Group_Static_Choice_Runtime,
      Group_Diagnostics_Consumer_Readiness,
      Group_Unknown);

   type Corpus_Scenario is
     (Scenario_Legal,
      Scenario_Illegal,
      Scenario_Legal_With_Runtime_Check,
      Scenario_Indeterminate,
      Scenario_Consumer_Surfaced,
      Scenario_Unknown);

   type Corpus_Status is
     (Status_Not_Checked,
      Status_Balanced,
      Status_Missing_Covered_Family,
      Status_Only_Positive_Tests,
      Status_Only_Negative_Tests,
      Status_Missing_Legal_Scenario,
      Status_Missing_Illegal_Scenario,
      Status_Missing_Runtime_Check_Scenario,
      Status_Missing_Indeterminate_Scenario,
      Status_Missing_Consumer_Surfaced_Scenario,
      Status_Runtime_Check_Collapsed_To_Illegal,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Collapsed_To_Legal,
      Status_Indeterminate_Collapsed_To_Illegal,
      Status_Source_Shaped_Evidence_Missing,
      Status_Semantic_Consumer_Not_Reached,
      Status_Duplicate_Noncoverage_Row,
      Status_Unstable_Blocker_Family,
      Status_Partial_Coverage_Treated_As_Balanced,
      Status_Missing_Checker_Treated_As_Balanced,
      Status_Stale_Corpus_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Corpus_Row is record
      Id : Natural := 0;
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := Remediation.State_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Group : Corpus_Group := Group_Unknown;
      Scenario : Corpus_Scenario := Scenario_Unknown;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Actual : Precision_Classification := Precision.Class_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Evidence : Boolean := True;
      Adds_Rule_Coverage : Boolean := True;
      Semantic_Consumer_Reached : Boolean := True;
      Runtime_Check_Applicable : Boolean := True;
      Indeterminate_Applicable : Boolean := True;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Runtime_Check_Collapsed_To_Illegal : Boolean := False;
      Indeterminate_Collapsed_To_Legal : Boolean := False;
      Indeterminate_Collapsed_To_Illegal : Boolean := False;
      Stable_Blocker_Family : Boolean := True;
      Evidence_Stale : Boolean := False;
      Corpus_Fingerprint : Natural := 0;
      Expected_Corpus_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Corpus_Row);

   type Corpus_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Corpus_Entry is record
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := Remediation.State_Unknown;
      Group : Corpus_Group := Group_Unknown;
      Status : Corpus_Status := Status_Not_Checked;
      Row_Count : Natural := 0;
      Blocker_Count : Natural := 0;
      Has_Legal : Boolean := False;
      Has_Illegal : Boolean := False;
      Has_Runtime_Check : Boolean := False;
      Has_Indeterminate : Boolean := False;
      Has_Consumer_Surfaced : Boolean := False;
      Runtime_Check_Required : Boolean := False;
      Indeterminate_Required : Boolean := False;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Corpus_Entry);

   type Corpus_Model is record
      Items : Entry_Vectors.Vector;
      Total_Families : Natural := 0;
      Balanced_Count : Natural := 0;
      Legal_Scenario_Count : Natural := 0;
      Illegal_Scenario_Count : Natural := 0;
      Runtime_Check_Scenario_Count : Natural := 0;
      Indeterminate_Scenario_Count : Natural := 0;
      Consumer_Surfaced_Scenario_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Corpus_Row
     (Input : in out Corpus_Input;
      Row : Corpus_Row);

   function Build (Input : Corpus_Input) return Corpus_Model;
   function Count (Results : Corpus_Model) return Natural;
   function Result_At (Results : Corpus_Model; Index : Positive) return Corpus_Entry;
   function Result_For (Results : Corpus_Model; Family : RM_Family) return Corpus_Entry;
   function Semantic_Regression_Corpus_Balanced (Results : Corpus_Model) return Boolean;
   function Balanced_For_All_Covered_Families (Results : Corpus_Model) return Boolean;

end Editor.Ada_Semantic_Regression_Corpus_Balance_Audit;
