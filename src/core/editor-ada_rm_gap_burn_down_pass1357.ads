with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1357 is

   --  Pass1357 is the fifteenth RM gap burn-down pass.  It closes the
   --  predefined-operation and numeric-model gap by requiring predefined
   --  operators, user-defined operator overloads, universal numeric
   --  resolution, static expression evaluation, modular/fixed/floating
   --  arithmetic, runtime-check classification, generic formal operators,
   --  and semantic consumers to agree on one canonical source-shaped result.

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
     (Gap_Predefined_Operation_Numeric_Model,
      Gap_Predefined_Operator_Availability,
      Gap_Universal_Numeric_Resolution,
      Gap_Modular_Fixed_Floating_Arithmetic,
      Gap_Operator_Overload_Integration,
      Gap_Cross_Slice_Numeric_Consumer,
      Gap_Unknown);

   type Operator_Construct_Kind is
     (Construct_Arithmetic_Operator,
      Construct_Relational_Operator,
      Construct_Equality_Operator,
      Construct_Boolean_Operator,
      Construct_Enumeration_Ordering,
      Construct_Array_String_Operator,
      Construct_Access_Equality,
      Construct_Tagged_Equality,
      Construct_Universal_Integer_Expression,
      Construct_Universal_Real_Expression,
      Construct_Named_Number,
      Construct_Static_Constant,
      Construct_Modular_Operation,
      Construct_Fixed_Point_Operation,
      Construct_Floating_Operation,
      Construct_Division_Rem_Mod,
      Construct_Exponentiation,
      Construct_User_Defined_Operator,
      Construct_Generic_Formal_Operator,
      Construct_Unknown);

   type Numeric_Context_Kind is
     (Context_Expected_Type,
      Context_Static_Expression,
      Context_Overload_Resolution,
      Context_Use_Type_Visibility,
      Context_Assignment_Conversion,
      Context_Subtype_Range_Predicate,
      Context_Generic_Replay,
      Context_Contract_Predicate,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Runtime_Overflow_Check_Preserved,
      Status_Runtime_Range_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Canonical_Operator_Disagreement,
      Status_Illegal_Predefined_Operator_Unavailable,
      Status_Illegal_Predefined_Operator_Visibility_Disagreement,
      Status_Illegal_Universal_Resolution_Disagreement,
      Status_Illegal_Expected_Type_Resolution_Lost,
      Status_Illegal_Static_Evaluation_Overload_Disagreement,
      Status_Illegal_User_Defined_Operator_Ambiguity,
      Status_Illegal_No_Visible_Operator,
      Status_Illegal_Primitive_Operator_Preference_Lost,
      Status_Illegal_Use_Type_Operator_Visibility_Lost,
      Status_Illegal_Callable_Profile_Disagreement,
      Status_Illegal_Generic_Formal_Operator_Substitution_Lost,
      Status_Illegal_Modular_Operand_Incompatible,
      Status_Illegal_Fixed_Point_Operand_Incompatible,
      Status_Illegal_Floating_Operand_Incompatible,
      Status_Illegal_Integer_Operand_Incompatible,
      Status_Illegal_Real_Operand_Incompatible,
      Status_Illegal_Array_String_Operator_Incompatible,
      Status_Illegal_Access_Equality_Incompatible,
      Status_Illegal_Tagged_Equality_Evidence_Lost,
      Status_Illegal_Enumeration_Ordering_Evidence_Lost,
      Status_Illegal_Static_Division_By_Zero,
      Status_Illegal_Exponent_Not_Natural,
      Status_Illegal_Static_Overflow,
      Status_Illegal_Assignment_Conversion_Numeric_Disagreement,
      Status_Illegal_Subtype_Range_Predicate_Disagreement,
      Status_Illegal_Generic_Replay_Numeric_Disagreement,
      Status_Illegal_Contract_Predicate_Numeric_Disagreement,
      Status_Illegal_Diagnostics_Numeric_Disagreement,
      Status_Illegal_Colouring_Numeric_Disagreement,
      Status_Illegal_Outline_Declaration_Numeric_Disagreement,
      Status_Illegal_Navigation_Target_Numeric_Disagreement,
      Status_Illegal_Hover_Numeric_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Numeric_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Operator_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Indeterminate_Missing_Expected_Type_Evidence,
      Status_Indeterminate_Missing_Static_Evidence,
      Status_Indeterminate_Missing_Overload_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Generic_Substitution_Evidence,
      Status_Indeterminate_Missing_Effect_Evidence,
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
      Status_Operator_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Expected_Type_Fingerprint_Mismatch,
      Status_Static_Fingerprint_Mismatch,
      Status_Overload_Fingerprint_Mismatch,
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
      Construct : Operator_Construct_Kind := Construct_Unknown;
      Context : Numeric_Context_Kind := Context_Unknown;
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
      Same_Canonical_Operator : Boolean := True;
      Predefined_Operator_Available : Boolean := True;
      Predefined_Operator_Visibility_Agrees : Boolean := True;
      Universal_Resolution_Agrees : Boolean := True;
      Expected_Type_Resolution_Preserved : Boolean := True;
      Static_Evaluation_Agrees_With_Overload : Boolean := True;
      User_Defined_Operator_Ambiguous : Boolean := False;
      No_Visible_Operator : Boolean := False;
      Primitive_Operator_Preference_Preserved : Boolean := True;
      Use_Type_Operator_Visibility_Preserved : Boolean := True;
      Callable_Profile_Agrees : Boolean := True;
      Generic_Formal_Operator_Substitution_Preserved : Boolean := True;
      Modular_Operand_Compatible : Boolean := True;
      Fixed_Point_Operand_Compatible : Boolean := True;
      Floating_Operand_Compatible : Boolean := True;
      Integer_Operand_Compatible : Boolean := True;
      Real_Operand_Compatible : Boolean := True;
      Array_String_Operator_Compatible : Boolean := True;
      Access_Equality_Compatible : Boolean := True;
      Tagged_Equality_Preserved : Boolean := True;
      Enumeration_Ordering_Preserved : Boolean := True;
      Static_Division_By_Zero : Boolean := False;
      Exponent_Natural : Boolean := True;
      Static_Overflow : Boolean := False;
      Runtime_Overflow_Check : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Assignment_Conversion_Numeric_Agrees : Boolean := True;
      Subtype_Range_Predicate_Agrees : Boolean := True;
      Generic_Replay_Numeric_Agrees : Boolean := True;
      Contract_Predicate_Numeric_Agrees : Boolean := True;
      Consumer_Numeric_Agrees : Boolean := True;
      Consumer_Colouring_Agrees : Boolean := True;
      Consumer_Declaration_Agrees : Boolean := True;
      Consumer_Target_Agrees : Boolean := True;
      Consumer_Detail_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Operator_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Missing_Expected_Type_Evidence : Boolean := False;
      Missing_Static_Evidence : Boolean := False;
      Missing_Overload_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Generic_Substitution_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Operator_Fingerprint : Natural := 0;
      Expected_Operator_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Expected_Type_Context_Fingerprint : Natural := 0;
      Expected_Expected_Type_Context_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
      Overload_Fingerprint : Natural := 0;
      Expected_Overload_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Construct : Operator_Construct_Kind := Construct_Unknown;
      Context : Numeric_Context_Kind := Context_Unknown;
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
   function Predefined_Operation_Numeric_Model_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Pass1357;
