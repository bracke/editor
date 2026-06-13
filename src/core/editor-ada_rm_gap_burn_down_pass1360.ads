with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1360 is

   --  Pass1360 is the eighteenth RM gap burn-down pass.  It closes the
   --  partial-source and recovery semantic closure gap for a live editor.
   --  Complete source units may produce hard legality results; recovered,
   --  token-only, degraded, stale, or still-being-typed Ada source must
   --  produce canonical indeterminate/blocker states instead of false hard
   --  diagnostics, invented entity/type/profile identities, or reused stale
   --  semantic results.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Partial_Source_Recovery_Semantic_Closure,
      Gap_Parser_Recovery_Evidence,
      Gap_Semantic_Degradation,
      Gap_Partial_Unit_Closure,
      Gap_Consumer_Degradation,
      Gap_Snapshot_Fingerprint_Correctness,
      Gap_Unknown);

   type Recovered_Source_Kind is
     (Source_Complete_Source,
      Source_Missing_Token,
      Source_Degraded_Construct,
      Source_Token_Only_Construct,
      Source_Missing_Source_Span,
      Source_Partial_Declaration,
      Source_Partial_Body,
      Source_Partial_Aggregate,
      Source_Partial_Call,
      Source_Partial_Expression,
      Source_Partial_Context_Clause,
      Source_Partial_Generic_Instantiation,
      Source_Partial_Subunit_Stub,
      Source_Unknown);

   type Recovery_Context_Kind is
     (Context_Complete_Source_Unit,
      Context_Parser_Recovery,
      Context_Semantic_Degradation,
      Context_Partial_Package_Spec,
      Context_Partial_Body_Without_Spec,
      Context_Partial_Private_Full_View,
      Context_Partial_Generic_Instantiation,
      Context_Partial_Subunit_Stub,
      Context_Partial_Aggregate_Call_Expression,
      Context_Consumer_Degradation,
      Context_Snapshot_Refresh,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Complete_Source_Closure,
      Status_Runtime_Check_Evidence_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Complete_Evidence_Violation,
      Status_Illegal_Hard_Diagnostic_From_Incomplete_Source,
      Status_Illegal_Partial_Declaration_Treated_Complete,
      Status_Illegal_Partial_Body_Treated_Complete,
      Status_Illegal_Stale_Recovery_Result_Reused,
      Status_Illegal_Incomplete_Call_Diagnosed_Wrong_Overload,
      Status_Illegal_Incomplete_Aggregate_Diagnosed_Missing_Component,
      Status_Illegal_Partial_View_Treated_Definitive,
      Status_Illegal_Consumer_Hides_Indeterminate,
      Status_Illegal_Consumer_Independent_Name_Type_Resolution,
      Status_Illegal_Outline_Unstable_Partial_Symbol,
      Status_Illegal_Navigation_Invented_Target,
      Status_Illegal_Hover_Invented_Type,
      Status_Illegal_Colouring_Reinterprets_Name,
      Status_Illegal_Diagnostics_Missing_Blocker_Family,
      Status_Illegal_Diagnostic_Bridge_Conflates_Recovered_Source,
      Status_Indeterminate_Missing_Token,
      Status_Indeterminate_Degraded_Construct,
      Status_Indeterminate_Token_Only_Construct,
      Status_Indeterminate_Missing_Source_Span,
      Status_Indeterminate_Partial_Declaration,
      Status_Indeterminate_Partial_Body,
      Status_Indeterminate_Partial_Aggregate,
      Status_Indeterminate_Partial_Call,
      Status_Indeterminate_Partial_Expression,
      Status_Indeterminate_Partial_Context_Clause,
      Status_Indeterminate_Partial_Generic_Instantiation,
      Status_Indeterminate_Partial_Subunit_Stub,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_AST_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Unit_Evidence,
      Status_Indeterminate_Missing_Substitution_Evidence,
      Status_Indeterminate_Missing_Effect_Evidence,
      Status_Indeterminate_Missing_Policy_Evidence,
      Status_Indeterminate_Missing_Consumer_Evidence,
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
      Status_Stale_Recovery_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Recovery_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
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
      Source_Kind : Recovered_Source_Kind := Source_Unknown;
      Context : Recovery_Context_Kind := Context_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
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
      Complete_Source_Closure_Agrees : Boolean := True;
      Complete_Evidence_Violation : Boolean := False;
      Runtime_Check_Context : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Missing_Token : Boolean := False;
      Degraded_Construct : Boolean := False;
      Token_Only_Construct : Boolean := False;
      Missing_Source_Span : Boolean := False;
      Partial_Declaration : Boolean := False;
      Partial_Body : Boolean := False;
      Partial_Aggregate : Boolean := False;
      Partial_Call : Boolean := False;
      Partial_Expression : Boolean := False;
      Partial_Context_Clause : Boolean := False;
      Partial_Generic_Instantiation : Boolean := False;
      Partial_Subunit_Stub : Boolean := False;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_AST_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Unit_Evidence : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Missing_Policy_Evidence : Boolean := False;
      Missing_Consumer_Evidence : Boolean := False;
      Hard_Diagnostic_From_Incomplete_Evidence : Boolean := False;
      Partial_Declaration_Treated_Complete : Boolean := False;
      Partial_Body_Treated_Complete : Boolean := False;
      Stale_Recovery_Result_Reused : Boolean := False;
      Incomplete_Call_Diagnosed_Wrong_Overload : Boolean := False;
      Incomplete_Aggregate_Diagnosed_Missing_Component : Boolean := False;
      Partial_View_Treated_Definitive : Boolean := False;
      Consumer_Hides_Indeterminate : Boolean := False;
      Consumer_Independent_Name_Type_Resolution : Boolean := False;
      Outline_Unstable_Partial_Symbol : Boolean := False;
      Navigation_Invented_Target : Boolean := False;
      Hover_Invented_Type : Boolean := False;
      Colouring_Reinterprets_Name : Boolean := False;
      Diagnostics_Blocker_Family_Present : Boolean := True;
      Bridge_Conflates_Recovered_Source : Boolean := False;
      Evidence_Stale : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
      Recovery_Fingerprint : Natural := 0;
      Expected_Recovery_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Source_Kind : Recovered_Source_Kind := Source_Unknown;
      Context : Recovery_Context_Kind := Context_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Recovery_Row_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row);
   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry;
   function Partial_Source_Recovery_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Pass1360;
