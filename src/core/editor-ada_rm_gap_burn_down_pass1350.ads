with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1350 is

   --  Pass1350 is the eighth RM gap burn-down pass.  It closes a concrete
   --  subtype/constraint/static-expression/choice/predicate Ada legality gap
   --  by requiring subtype constraints, static evaluation, choice coverage,
   --  predicate classification, cross-slice consumers, remediation state, and
   --  balanced source-shaped regression evidence to agree on one canonical
   --  result.

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
     (Gap_Subtype_Constraint_Static_Choice_Predicate,
      Gap_Subtype_Constraints,
      Gap_Static_Expression_Evaluation,
      Gap_Choice_Coverage,
      Gap_Predicate_Runtime_Classification,
      Gap_Cross_Slice_Staticness_Consumption,
      Gap_Unknown);

   type Static_Construct_Kind is
     (Construct_Subtype_Indication,
      Construct_Range_Constraint,
      Construct_Modular_Constraint,
      Construct_Floating_Digits_Constraint,
      Construct_Fixed_Delta_Constraint,
      Construct_Array_Index_Constraint,
      Construct_Discriminant_Constraint,
      Construct_Named_Number,
      Construct_Static_Constant,
      Construct_Integer_Literal,
      Construct_Real_Literal,
      Construct_Qualified_Static_Expression,
      Construct_Static_Attribute,
      Construct_Static_Arithmetic,
      Construct_Case_Choice,
      Construct_Case_Expression_Choice,
      Construct_Variant_Choice,
      Construct_Aggregate_Choice,
      Construct_Index_Choice,
      Construct_Discriminant_Choice,
      Construct_Membership_Choice,
      Construct_Static_Predicate,
      Construct_Dynamic_Predicate,
      Construct_Loop_Parameter,
      Construct_Representation_Position,
      Construct_Unknown);

   type Static_Context_Kind is
     (Context_Subtype_Constraint,
      Context_Static_Evaluation,
      Context_Case_Coverage,
      Context_Variant_Selection,
      Context_Aggregate_Association,
      Context_Membership_Test,
      Context_Assignment_Conversion,
      Context_Loop_Iterator,
      Context_Representation_Layout,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Non_Discrete_Subtype,
      Status_Illegal_Range_Bounds_Out_Of_Base,
      Status_Illegal_Range_Lower_Greater_Than_Upper,
      Status_Illegal_Modular_Modulus_Mismatch,
      Status_Illegal_Floating_Digits_Constraint,
      Status_Illegal_Fixed_Delta_Constraint,
      Status_Illegal_Array_Index_Non_Discrete,
      Status_Illegal_Discriminant_Constraint_Mismatch,
      Status_Illegal_Static_Expression_Required,
      Status_Illegal_Static_Divide_By_Zero,
      Status_Illegal_Static_Exponent_Not_Natural,
      Status_Illegal_Static_Universal_Resolution_Failed,
      Status_Illegal_Static_Attribute_Prefix_Mismatch,
      Status_Illegal_Choice_Type_Mismatch,
      Status_Illegal_Non_Static_Choice,
      Status_Illegal_Overlapping_Choices,
      Status_Illegal_Incomplete_Case_Coverage,
      Status_Illegal_Duplicate_Others,
      Status_Illegal_Others_Placement,
      Status_Illegal_Static_Predicate_Not_Static,
      Status_Illegal_Static_Predicate_False_For_Subtype,
      Status_Illegal_Aggregate_Static_Choice_Disagreement,
      Status_Illegal_Assignment_Range_Evidence_Disagreement,
      Status_Illegal_Loop_Discrete_Subtype_Disagreement,
      Status_Illegal_Representation_Static_Position_Disagreement,
      Status_Runtime_Range_Check_Preserved,
      Status_Runtime_Bounds_Check_Preserved,
      Status_Runtime_Predicate_Check_Preserved,
      Status_Runtime_Membership_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Static_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Subtype_Model_Disagreement,
      Status_Consumer_Static_Model_Disagreement,
      Status_Consumer_Choice_Model_Disagreement,
      Status_Consumer_Predicate_Model_Disagreement,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Static_Fingerprint_Mismatch,
      Status_Choice_Fingerprint_Mismatch,
      Status_Predicate_Fingerprint_Mismatch,
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
      Construct : Static_Construct_Kind := Construct_Unknown;
      Context : Static_Context_Kind := Context_Unknown;
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
      Discrete_Subtype_Required_Satisfied : Boolean := True;
      Range_Bounds_Within_Base : Boolean := True;
      Range_Lower_LE_Upper : Boolean := True;
      Modular_Modulus_Compatible : Boolean := True;
      Floating_Digits_Compatible : Boolean := True;
      Fixed_Delta_Compatible : Boolean := True;
      Array_Index_Discrete : Boolean := True;
      Discriminant_Constraint_Compatible : Boolean := True;
      Static_Expression_When_Required : Boolean := True;
      Static_Divide_By_Zero : Boolean := False;
      Static_Exponent_Natural : Boolean := True;
      Universal_Resolution_Agrees : Boolean := True;
      Static_Attribute_Prefix_Compatible : Boolean := True;
      Choice_Type_Compatible : Boolean := True;
      Choice_Static_When_Required : Boolean := True;
      Choices_Overlap : Boolean := False;
      Case_Coverage_Complete : Boolean := True;
      Duplicate_Others : Boolean := False;
      Others_Placement_Valid : Boolean := True;
      Static_Predicate_Is_Static : Boolean := True;
      Static_Predicate_Holds : Boolean := True;
      Range_Runtime_Check : Boolean := False;
      Bounds_Runtime_Check : Boolean := False;
      Predicate_Runtime_Check : Boolean := False;
      Membership_Runtime_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Aggregate_Static_Choice_Consumes : Boolean := True;
      Assignment_Range_Predicate_Consumes : Boolean := True;
      Loop_Discrete_Subtype_Consumes : Boolean := True;
      Representation_Static_Position_Consumes : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Static_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Consumer_Subtype_Model_Agrees : Boolean := True;
      Consumer_Static_Model_Agrees : Boolean := True;
      Consumer_Choice_Model_Agrees : Boolean := True;
      Consumer_Predicate_Model_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
      Choice_Fingerprint : Natural := 0;
      Expected_Choice_Fingerprint : Natural := 0;
      Predicate_Fingerprint : Natural := 0;
      Expected_Predicate_Fingerprint : Natural := 0;
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
   function Subtype_Static_Predicate_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1350;
