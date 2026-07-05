with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1346 is

   --  Case 1346 is the fourth RM gap burn-down case.  It closes a concrete
   --  tagged/interface/dispatching/contract-effect Ada legality gap by
   --  requiring tagged type extension rules, interface implementation,
   --  overriding/callable profile agreement, dispatching resolution,
   --  class-wide conversions, contract/effect propagation, remediation
   --  evidence, and semantic consumers to agree on one canonical
   --  source-shaped result.

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
     (Gap_Tagged_Interface_Dispatching_Contract_Effect,
      Gap_Tagged_Extension,
      Gap_Interface_Implementation,
      Gap_Overriding_Profile,
      Gap_Dispatching_Call,
      Gap_Contract_Effect_Join,
      Gap_Classwide_Conversion,
      Gap_Unknown);

   type Tagged_Construct_Kind is
     (Construct_Tagged_Root_Type,
      Construct_Tagged_Type_Extension,
      Construct_Tagged_Private_Extension,
      Construct_Abstract_Tagged_Type,
      Construct_Ordinary_Interface,
      Construct_Limited_Interface,
      Construct_Task_Interface,
      Construct_Protected_Interface,
      Construct_Synchronized_Interface,
      Construct_Null_Procedure,
      Construct_Unknown);

   type Dispatch_Context_Kind is
     (Dispatch_None,
      Dispatch_Static_Call,
      Dispatch_Dispatching_Call,
      Dispatch_Interface_Call,
      Dispatch_Controlling_Result,
      Dispatch_Classwide_Conversion,
      Dispatch_Access_Classwide_Conversion,
      Dispatch_Unknown);

   type Contract_Effect_Context_Kind is
     (Effect_None,
      Effect_Pre_Post,
      Effect_Global_Depends,
      Effect_Refined_Global_Depends,
      Effect_Abstract_State_Constituent,
      Effect_Dispatching_Join,
      Effect_Volatile_Atomic,
      Effect_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Untagged_Parent_Extension,
      Status_Illegal_Parent_Not_Visible,
      Status_Illegal_Interface_Primitive_Not_Implemented,
      Status_Illegal_Abstract_Primitive_Not_Implemented,
      Status_Illegal_Synchronized_Interface_Mismatch,
      Status_Illegal_Limited_Interface_Mismatch,
      Status_Illegal_Null_Procedure_Profile,
      Status_Illegal_Overriding_Indicator_Missing,
      Status_Illegal_Overriding_Indicator_Not_Allowed,
      Status_Illegal_Overriding_Profile_Nonconformant,
      Status_Illegal_Parameter_Mode_Mismatch,
      Status_Illegal_Result_Type_Mismatch,
      Status_Illegal_Default_Conformance_Mismatch,
      Status_Illegal_Null_Exclusion_Mismatch,
      Status_Illegal_Convention_Mismatch,
      Status_Illegal_Access_Subprogram_Profile_Mismatch,
      Status_Illegal_Ambiguous_Dispatching_Call,
      Status_Illegal_Static_Call_Where_Dispatching_Required,
      Status_Illegal_Controlling_Operand_Mismatch,
      Status_Illegal_Controlling_Result_Mismatch,
      Status_Illegal_Interface_Dispatch_Target_Mismatch,
      Status_Illegal_Classwide_Conversion_Root_Mismatch,
      Status_Illegal_Tagged_View_Conversion_Incompatible,
      Status_Illegal_Access_Classwide_Accessibility_Escape,
      Status_Illegal_Pre_Post_Not_Propagated,
      Status_Illegal_Global_Depends_Not_Propagated,
      Status_Illegal_Refined_Effect_Not_Propagated,
      Status_Illegal_Abstract_State_Constituent_Missing,
      Status_Illegal_Dispatching_Effect_Join_Missing,
      Status_Illegal_Volatile_Atomic_Effect_Lost,
      Status_Runtime_Tagged_Accessibility_Check_Preserved,
      Status_Runtime_Classwide_Conversion_Check_Preserved,
      Status_Runtime_Dispatching_Predicate_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Tagged_Model_Disagreement,
      Status_Consumer_Interface_Model_Disagreement,
      Status_Consumer_Dispatching_Model_Disagreement,
      Status_Consumer_Profile_Model_Disagreement,
      Status_Consumer_Contract_Effect_Model_Disagreement,
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
      Construct : Tagged_Construct_Kind := Construct_Unknown;
      Dispatch_Context : Dispatch_Context_Kind := Dispatch_Unknown;
      Effect_Context : Contract_Effect_Context_Kind := Effect_Unknown;
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
      Tagged_Parent_Is_Tagged : Boolean := True;
      Parent_Visible : Boolean := True;
      Interface_Primitives_Implemented : Boolean := True;
      Concrete_Type_Implements_Abstract_Primitives : Boolean := True;
      Synchronized_Interface_Compatible : Boolean := True;
      Limited_Interface_Compatible : Boolean := True;
      Null_Procedure_Profile_Conformant : Boolean := True;
      Overriding_Indicator_Missing : Boolean := False;
      Overriding_Indicator_Not_Allowed : Boolean := False;
      Overriding_Profile_Conformant : Boolean := True;
      Parameter_Modes_Conformant : Boolean := True;
      Result_Type_Conformant : Boolean := True;
      Defaults_Conformant : Boolean := True;
      Null_Exclusions_Conformant : Boolean := True;
      Convention_Conformant : Boolean := True;
      Access_Subprogram_Profile_Conformant : Boolean := True;
      Dispatching_Candidate_Set_Ambiguous : Boolean := False;
      Static_Call_Where_Dispatching_Required : Boolean := False;
      Controlling_Operand_Compatible : Boolean := True;
      Controlling_Result_Compatible : Boolean := True;
      Interface_Dispatch_Target_Compatible : Boolean := True;
      Classwide_Conversion_Root_Compatible : Boolean := True;
      Tagged_View_Conversion_Compatible : Boolean := True;
      Access_Classwide_Accessibility_Escape : Boolean := False;
      Pre_Post_Propagated : Boolean := True;
      Global_Depends_Propagated : Boolean := True;
      Refined_Effects_Propagated : Boolean := True;
      Abstract_State_Constituents_Present : Boolean := True;
      Dispatching_Effect_Join_Present : Boolean := True;
      Volatile_Atomic_Effect_Preserved : Boolean := True;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Classwide_Conversion_Check : Boolean := False;
      Runtime_Dispatching_Predicate_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Consumer_Tagged_Model_Agrees : Boolean := True;
      Consumer_Interface_Model_Agrees : Boolean := True;
      Consumer_Dispatching_Model_Agrees : Boolean := True;
      Consumer_Profile_Model_Agrees : Boolean := True;
      Consumer_Contract_Effect_Model_Agrees : Boolean := True;
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
   function Tagged_Interface_Dispatching_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1346;
