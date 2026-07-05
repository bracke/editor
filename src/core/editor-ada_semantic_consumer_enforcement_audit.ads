with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;

package Editor.Ada_Semantic_Consumer_Enforcement_Audit is

   --  Semantic consumer enforcement audit is part of the post vertical-slice
   --  integration audit campaign.
   --  It enforces that completed Ada semantic legality results are consumed
   --  by editor semantic consumers through the canonical model and RM gap
   --  remediation evidence.  Diagnostics, semantic colouring, outline,
   --  semantic navigation, hover/details, and the external build diagnostic
   --  bridge must not reinterpret names, types, views, profiles, units, or
   --  blocker families through slice-local or presentation-local state.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Remediation_State is Remediation.Remediation_State;

   type Semantic_Consumer is
     (Consumer_Diagnostics,
      Consumer_Semantic_Colouring,
      Consumer_Outline_Model,
      Consumer_Semantic_Navigation,
      Consumer_Hover_Details,
      Consumer_Build_Diagnostic_Bridge,
      Consumer_Unknown);

   type Consumer_Status is
     (Status_Not_Checked,
      Status_Ready,
      Status_Missing_Consumer_Row,
      Status_Duplicate_Consumer_Row,
      Status_Missing_Source_Shaped_Evidence,
      Status_Unconsumed_Semantic_Result,
      Status_Noncanonical_Consumer_Model,
      Status_Diagnostics_Missing_Blocker_Family,
      Status_Unstable_Blocker_Family,
      Status_Independent_Name_Type_Resolution,
      Status_Noncanonical_Declaration_Or_Completion,
      Status_Navigation_Entity_Model_Mismatch,
      Status_Noncanonical_Type_View_Profile,
      Status_Noncanonical_Generic_Substitution,
      Status_Missing_Cross_Unit_Evidence,
      Status_Hover_Uses_Slice_Local_Evidence,
      Status_Build_Diagnostic_Bridge_Conflates_External,
      Status_Unstable_Source_Span,
      Status_Covered_Result_Not_Surfaceable,
      Status_Partial_Or_Blocked_Result_Hidden,
      Status_Runtime_Check_Evidence_Lost,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Consumer_Row is record
      Id : Natural := 0;
      Consumer : Semantic_Consumer := Consumer_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := Remediation.State_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Evidence : Boolean := True;
      Canonical_Model_Used : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Can_Surface_Result : Boolean := True;
      Partial_Or_Blocked_Represented : Boolean := True;
      Stable_Source_Span : Boolean := True;
      Semantic_Blocker_Family_Present : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Consumer_Reinterprets_Names_Or_Types : Boolean := False;
      Uses_Canonical_Declaration_Identity : Boolean := True;
      Uses_Canonical_Completion_Identity : Boolean := True;
      Uses_Canonical_Entity_Identity : Boolean := True;
      Uses_Canonical_Renaming_Identity : Boolean := True;
      Uses_Canonical_Type_Identity : Boolean := True;
      Uses_Canonical_View_Identity : Boolean := True;
      Uses_Canonical_Profile_Identity : Boolean := True;
      Uses_Generic_Substitution_Identity : Boolean := True;
      Uses_Cross_Unit_Evidence : Boolean := True;
      Hover_Detail_From_Canonical_Evidence : Boolean := True;
      Build_Diagnostics_Distinct_From_Internal : Boolean := True;
      Build_Diagnostic_Shares_Source_Span : Boolean := True;
      Runtime_Check_Evidence_Preserved : Boolean := True;
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
     (Index_Type => Natural, Element_Type => Consumer_Row);

   type Consumer_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Consumer_Entry is record
      Consumer : Semantic_Consumer := Consumer_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := Remediation.State_Unknown;
      Status : Consumer_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Consumer_Entry);

   type Consumer_Model is record
      Items : Entry_Vectors.Vector;
      Total_Consumers : Natural := 0;
      Ready_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Missing_Consumer_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Consumer_Row
     (Input : in out Consumer_Input;
      Row : Consumer_Row);

   function Build (Input : Consumer_Input) return Consumer_Model;
   function Count (Results : Consumer_Model) return Natural;
   function Result_At (Results : Consumer_Model; Index : Positive) return Consumer_Entry;
   function Result_For (Results : Consumer_Model; Consumer : Semantic_Consumer) return Consumer_Entry;
   function Semantic_Consumer_Enforcement_Ready (Results : Consumer_Model) return Boolean;
   function All_Completed_Results_Surfaceable (Results : Consumer_Model) return Boolean;

end Editor.Ada_Semantic_Consumer_Enforcement_Audit;
