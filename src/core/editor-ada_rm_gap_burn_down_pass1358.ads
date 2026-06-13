with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1358 is

   --  Pass1358 is the sixteenth RM gap burn-down pass.  It closes the
   --  predefined-environment and literal-resolution gap by requiring all
   --  semantic slices to agree on package Standard, root and universal
   --  types, Boolean/Character/String families, predefined exceptions,
   --  predefined attributes/operators, integer/real/character/string/
   --  enumeration/null literals, expected-type driven resolution, and the
   --  semantic consumers that surface those results.

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
     (Gap_Predefined_Environment_Literal_Resolution,
      Gap_Standard_Entity_Identity,
      Gap_Literal_Resolution,
      Gap_Root_Universal_Type_Agreement,
      Gap_String_Character_Legality,
      Gap_Cross_Slice_Predefined_Consumer,
      Gap_Unknown);

   type Predefined_Construct_Kind is
     (Construct_Standard_Boolean,
      Construct_Standard_Integer,
      Construct_Standard_Natural,
      Construct_Standard_Positive,
      Construct_Standard_Float,
      Construct_Standard_Duration,
      Construct_Character_Type,
      Construct_Wide_Character_Type,
      Construct_Wide_Wide_Character_Type,
      Construct_String_Type,
      Construct_Wide_String_Type,
      Construct_Wide_Wide_String_Type,
      Construct_Predefined_Exception,
      Construct_Predefined_Attribute,
      Construct_Predefined_Operator,
      Construct_Integer_Literal,
      Construct_Real_Literal,
      Construct_Character_Literal,
      Construct_String_Literal,
      Construct_Enumeration_Literal,
      Construct_Null_Literal,
      Construct_Root_Integer,
      Construct_Root_Real,
      Construct_Root_Fixed,
      Construct_Universal_Integer,
      Construct_Universal_Real,
      Construct_Universal_Access,
      Construct_Unknown);

   type Resolution_Context_Kind is
     (Context_Standard_Environment,
      Context_Expected_Type,
      Context_Overload_Resolution,
      Context_Static_Expression,
      Context_Aggregate_Assignment,
      Context_Subtype_Range_Predicate,
      Context_String_Array,
      Context_Exception_Resolution,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Runtime_String_Bounds_Check_Preserved,
      Status_Runtime_Range_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Standard_Entity_Identity_Disagreement,
      Status_Illegal_Standard_Entity_Missing,
      Status_Illegal_Predefined_Exception_Identity_Disagreement,
      Status_Illegal_Predefined_Attribute_Identity_Disagreement,
      Status_Illegal_Predefined_Operator_Identity_Disagreement,
      Status_Illegal_Integer_Literal_Resolution_Disagreement,
      Status_Illegal_Real_Literal_Resolution_Disagreement,
      Status_Illegal_Static_Overload_Literal_Disagreement,
      Status_Illegal_Character_Enumeration_Literal_Ambiguity,
      Status_Illegal_String_Literal_Array_Incompatible,
      Status_Illegal_Wide_String_Literal_Incompatible,
      Status_Illegal_Null_Literal_No_Access_Context,
      Status_Illegal_Null_Literal_Access_View_Disagreement,
      Status_Illegal_Root_Type_Identity_Disagreement,
      Status_Illegal_Universal_Type_Conversion_Disagreement,
      Status_Illegal_Expected_Type_Literal_Context_Lost,
      Status_Illegal_Aggregate_Assignment_Literal_Disagreement,
      Status_Illegal_Subtype_Range_Literal_Disagreement,
      Status_Illegal_Diagnostics_Predefined_Disagreement,
      Status_Illegal_Colouring_Predefined_Disagreement,
      Status_Illegal_Outline_Predefined_Disagreement,
      Status_Illegal_Navigation_Predefined_Disagreement,
      Status_Illegal_Hover_Predefined_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Predefined_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Predefined_Environment,
      Status_Indeterminate_Missing_Literal_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Indeterminate_Missing_Expected_Type_Evidence,
      Status_Indeterminate_Missing_Static_Evidence,
      Status_Indeterminate_Missing_Overload_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Substitution_Evidence,
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
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Predefined_Fingerprint_Mismatch,
      Status_Literal_Fingerprint_Mismatch,
      Status_Root_Type_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Expected_Type_Fingerprint_Mismatch,
      Status_Static_Fingerprint_Mismatch,
      Status_Overload_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
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
      Construct : Predefined_Construct_Kind := Construct_Unknown;
      Context : Resolution_Context_Kind := Context_Unknown;
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
      Same_Standard_Entity : Boolean := True;
      Standard_Entity_Present : Boolean := True;
      Predefined_Exception_Identity_Agrees : Boolean := True;
      Predefined_Attribute_Identity_Agrees : Boolean := True;
      Predefined_Operator_Identity_Agrees : Boolean := True;
      Integer_Literal_Resolution_Agrees : Boolean := True;
      Real_Literal_Resolution_Agrees : Boolean := True;
      Static_Evaluation_Agrees_With_Overload : Boolean := True;
      Character_Enumeration_Literal_Ambiguous : Boolean := False;
      String_Literal_Array_Compatible : Boolean := True;
      Wide_String_Literal_Compatible : Boolean := True;
      Null_Literal_Has_Access_Context : Boolean := True;
      Null_Literal_Access_View_Agrees : Boolean := True;
      Root_Type_Identity_Agrees : Boolean := True;
      Universal_Type_Conversion_Agrees : Boolean := True;
      Expected_Type_Context_Preserved : Boolean := True;
      Aggregate_Assignment_Literal_Agrees : Boolean := True;
      Subtype_Range_Literal_Agrees : Boolean := True;
      Runtime_String_Bounds_Check : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Consumer_Predefined_Agrees : Boolean := True;
      Consumer_Colouring_Agrees : Boolean := True;
      Consumer_Outline_Agrees : Boolean := True;
      Consumer_Navigation_Agrees : Boolean := True;
      Consumer_Hover_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Predefined_Environment : Boolean := False;
      Missing_Literal_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Missing_Expected_Type_Evidence : Boolean := False;
      Missing_Static_Evidence : Boolean := False;
      Missing_Overload_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Consumer_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Predefined_Fingerprint : Natural := 0;
      Expected_Predefined_Fingerprint : Natural := 0;
      Literal_Fingerprint : Natural := 0;
      Expected_Literal_Fingerprint : Natural := 0;
      Root_Type_Fingerprint : Natural := 0;
      Expected_Root_Type_Fingerprint : Natural := 0;
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
      Construct : Predefined_Construct_Kind := Construct_Unknown;
      Context : Resolution_Context_Kind := Context_Unknown;
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
   function Predefined_Environment_Literal_Resolution_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Pass1358;
