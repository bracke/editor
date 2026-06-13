with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1343 is

   --  Pass1343 is the first RM gap burn-down pass after the integration
   --  audit phase.  It closes a concrete partial semantic gap instead of
   --  adding another coverage wrapper: aggregate values used as assignment,
   --  conversion, qualified-expression, component-update, or generic-actual
   --  sources must share one legality result across aggregate association
   --  rules, assignment/conversion target rules, subtype range checks,
   --  predicate/runtime-check evidence, accessibility checks, private/limited
   --  view blockers, remediation state, balanced regression corpus evidence,
   --  and real semantic consumers.

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
     (Gap_Aggregate_Assignment_Predicate,
      Gap_Aggregate_Defaulted_Component,
      Gap_Aggregate_Static_Choice_Runtime_Bounds,
      Gap_Aggregate_Accessibility_Runtime_Check,
      Gap_Aggregate_Private_Full_View,
      Gap_Unknown);

   type Aggregate_Form is
     (Form_Array_Aggregate,
      Form_Record_Aggregate,
      Form_Extension_Aggregate,
      Form_Delta_Aggregate,
      Form_Container_Aggregate,
      Form_Null_Aggregate,
      Form_Unknown);

   type Aggregate_Context is
     (Context_Object_Declaration,
      Context_Assignment_Statement,
      Context_Qualified_Expression,
      Context_Type_Conversion,
      Context_View_Conversion,
      Context_Component_Update,
      Context_Generic_Actual,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Constant_Target,
      Status_Illegal_Missing_Association,
      Status_Illegal_Duplicate_Association,
      Status_Illegal_Extra_Association,
      Status_Illegal_Mixed_Association,
      Status_Illegal_Nonstatic_Choice,
      Status_Illegal_Overlapping_Choice,
      Status_Illegal_Component_Type_Mismatch,
      Status_Illegal_Discriminant_Mismatch,
      Status_Illegal_Defaulted_Component_Missing,
      Status_Illegal_Inactive_Variant_Component,
      Status_Illegal_Static_Accessibility_Escape,
      Status_Illegal_Static_Range_Violation,
      Status_Illegal_Static_Predicate_Violation,
      Status_Runtime_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Missing_Expected_Type,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Missing_Full_View,
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
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
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
      Form : Aggregate_Form := Form_Unknown;
      Context : Aggregate_Context := Context_Unknown;
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
      Expected_Type_Known : Boolean := True;
      Target_Variable_View : Boolean := True;
      Aggregate_Associations_Complete : Boolean := True;
      Duplicate_Association : Boolean := False;
      Extra_Association : Boolean := False;
      Mixed_Named_Positional_Association : Boolean := False;
      Static_Choices : Boolean := True;
      Choices_Overlap : Boolean := False;
      Component_Types_Compatible : Boolean := True;
      Discriminants_Compatible : Boolean := True;
      Variant_Component_Active : Boolean := True;
      Defaulted_Components_Available : Boolean := True;
      Accessibility_Static_Escape : Boolean := False;
      Accessibility_Runtime_Check : Boolean := False;
      Static_Range_Out_Of_Range : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Predicate_Staticly_False : Boolean := False;
      Predicate_Runtime_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Missing_Full_View : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
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
     (Index_Type => Natural, Element_Type => Burn_Down_Row);

   type Burn_Down_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Burn_Down_Entry is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Promoted_State : Remediation_State := Remediation.State_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Classification : Precision_Classification := Precision.Class_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Items : Entry_Vectors.Vector;
      Burned_Down_Count : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row);

   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry;
   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean;
   function Aggregate_Assignment_Predicate_Gap_Closed (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1343;
