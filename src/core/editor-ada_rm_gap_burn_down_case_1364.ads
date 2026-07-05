with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1364 is

   --  Case 1364 is the twenty-second RM gap burn-down case.  It closes the
   --  diagnostic, blocker-family, and source-span precision gap after
   --  project-scale semantic index ownership.  The pass verifies that
   --  consumer-visible Ada semantic evidence is normalized into stable
   --  blocker families, precise source spans, deterministic diagnostic
   --  ordering, and consistent legality states without duplicating or
   --  reclassifying canonical semantic results.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Diagnostic_Blocker_Source_Span_Closure,
      Gap_Blocker_Family_Normalization,
      Gap_Diagnostic_Source_Span_Precision,
      Gap_Diagnostic_Deduplication_Ordering,
      Gap_Consumer_Visible_State_Consistency,
      Gap_Incremental_Diagnostic_Stability,
      Gap_Unknown);

   type Span_Kind is
     (Span_None,
      Span_Declaration,
      Span_Association,
      Span_Selector,
      Span_Actual,
      Span_Attribute,
      Span_Operator,
      Span_Local_Reference,
      Span_Target_Unit_Evidence,
      Span_Recovered_Partial,
      Span_Whole_Declaration,
      Span_Unknown);

   type Blocker_Precision is
     (Blocker_None,
      Blocker_Precise_RM_Family,
      Blocker_Runtime_Check,
      Blocker_Warning_Only,
      Blocker_Indeterminate,
      Blocker_Partial,
      Blocker_Missing_Checker,
      Blocker_Generic_Fallback,
      Blocker_Duplicate_Spelling,
      Blocker_Unknown);

   type Diagnostic_Role is
     (Role_Primary,
      Role_Secondary_Evidence,
      Role_Cross_Unit_Local_Reference,
      Role_Cross_Unit_Target_Evidence,
      Role_Recovered_Syntax,
      Role_Consumer_State,
      Role_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Normalized_Diagnostic,
      Status_Legal_Runtime_Check_Surface,
      Status_Legal_Warning_Only_Surface,
      Status_Legal_Indeterminate_Surface,
      Status_Legal_Deduplicated_Ordered,
      Status_Legal_Incrementally_Stable,
      Status_Illegal_Duplicate_Canonical_Diagnostic,
      Status_Illegal_Duplicate_Blocker_Spelling,
      Status_Illegal_Generic_Fallback_Blocker,
      Status_Illegal_Precise_Blocker_Missing,
      Status_Illegal_Hard_Diagnostic_From_Indeterminate,
      Status_Illegal_Runtime_Check_Emitted_As_Hard,
      Status_Illegal_Warning_Only_Emitted_As_Hard,
      Status_Illegal_Whole_Declaration_Span_Used,
      Status_Illegal_Cross_Unit_Evidence_Span_Missing,
      Status_Illegal_Recovered_Syntax_Complete_Span_Pretended,
      Status_Illegal_Nondeterministic_Diagnostic_Order,
      Status_Illegal_Primary_Secondary_Order_Inverted,
      Status_Illegal_Consumer_Reclassified_State,
      Status_Illegal_Build_Diagnostic_Conflated,
      Status_Illegal_Unchanged_Error_Blocker_Churn,
      Status_Illegal_Source_Span_Drift,
      Status_Illegal_Stale_Diagnostic_Reused,
      Status_Illegal_Stale_Consumer_State_Reused,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Diagnostic_Row_Missing,
      Status_Smallest_Source_Span_Missing,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Project_Index_Fingerprint_Mismatch,
      Status_Closure_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Request_Fingerprint_Mismatch,
      Status_Unexpected_Classification,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Burn_Down_Row is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Target_State : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Span : Span_Kind := Span_Unknown;
      Blocker : Blocker_Precision := Blocker_Unknown;
      Diagnostic_Kind : Diagnostic_Role := Role_Unknown;
      Diagnostic_Key : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Source_Shaped_Evidence : Boolean := True;
      Remediation_Entry_Present : Boolean := True;
      Matrix_Coverage_Present : Boolean := True;
      Implementing_Package_Present : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Coverage_Entry_Updated_To_Covered : Boolean := True;
      Balanced_Regression_Evidence : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Diagnostic_Row_Present : Boolean := True;

      Duplicate_Canonical_Diagnostic : Boolean := False;
      Duplicate_Blocker_Spelling : Boolean := False;
      Generic_Fallback_Used_When_Precise_Exists : Boolean := False;
      Precise_Blocker_Available : Boolean := True;
      Precise_Blocker_Used : Boolean := True;
      Smallest_Source_Span_Available : Boolean := True;
      Smallest_Source_Span_Used : Boolean := True;
      Cross_Unit_Target_Span_Preserved : Boolean := True;
      Recovered_Syntax_Has_Complete_Span : Boolean := False;
      Runtime_Check_Emitted_As_Hard : Boolean := False;
      Warning_Only_Emitted_As_Hard : Boolean := False;
      Hard_Diagnostic_From_Indeterminate : Boolean := False;

      Duplicate_Deduplicated : Boolean := True;
      Deterministic_Diagnostic_Order : Boolean := True;
      Primary_Before_Secondary : Boolean := True;
      Consumer_State_Consistent : Boolean := True;
      Consumer_Reclassified_State : Boolean := False;
      Build_Diagnostic_Conflated : Boolean := False;
      Unchanged_Error_Blocker_Identity_Preserved : Boolean := True;
      Source_Span_Moved_Deterministically : Boolean := True;
      Stale_Diagnostic_Reused : Boolean := False;
      Stale_Consumer_State_Reused : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Project_Index_Fingerprint : Natural := 0;
      Expected_Project_Index_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
      Request_Fingerprint : Natural := 0;
      Expected_Request_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Row);

   type Burn_Down_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Burn_Down_Entry is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Span : Span_Kind := Span_Unknown;
      Blocker : Blocker_Precision := Blocker_Unknown;
      Diagnostic_Kind : Diagnostic_Role := Role_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Normalized_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Warning_Only_Count : Natural := 0;
      Indeterminate_Surface_Count : Natural := 0;
      Deduplicated_Ordering_Count : Natural := 0;
      Incremental_Stability_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row);
   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;
   function Diagnostic_Blocker_Source_Span_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1364;
