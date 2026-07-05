with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1349 is

   --  Case 1349 is the seventh RM gap burn-down case.  It closes a concrete
   --  name/visibility/attribute/selector resolution Ada legality gap by
   --  requiring direct visibility, selected names, attributes, dereference,
   --  indexing, overload-fed resolution, private/limited views, consumers,
   --  remediation state, and balanced source-shaped regression evidence to
   --  agree on one canonical result.

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
     (Gap_Name_Visibility_Attribute_Selector,
      Gap_Direct_Selected_Visibility,
      Gap_Attribute_Resolution,
      Gap_Dereference_Indexing,
      Gap_Overload_Fed_Name_Resolution,
      Gap_Consumer_Name_Projection,
      Gap_Unknown);

   type Name_Construct_Kind is
     (Construct_Direct_Name,
      Construct_Selected_Name,
      Construct_Expanded_Name,
      Construct_Child_Unit_Name,
      Construct_Private_Child_Name,
      Construct_Use_Package_Clause,
      Construct_Use_Type_Clause,
      Construct_Attribute_Reference,
      Construct_Explicit_Dereference,
      Construct_Implicit_Dereference,
      Construct_Array_Indexing,
      Construct_Generalized_Indexing,
      Construct_Component_Selection,
      Construct_Operator_Symbol,
      Construct_Callable_Name,
      Construct_Unknown);

   type Resolution_Context_Kind is
     (Context_Direct_Visibility,
      Context_Selected_Visibility,
      Context_Use_Visibility,
      Context_Child_Visibility,
      Context_Attribute_Prefix,
      Context_Dereference,
      Context_Indexing,
      Context_Overload,
      Context_Expected_Type,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Private_Child_Visibility_Leak,
      Status_Illegal_Name_Not_Directly_Visible,
      Status_Illegal_Selected_Prefix_Not_Visible,
      Status_Illegal_Selector_Missing,
      Status_Illegal_Ambiguous_Selector,
      Status_Illegal_Homograph_Conflict,
      Status_Illegal_Use_Visible_Homograph,
      Status_Illegal_Use_Type_Operator_Not_Visible,
      Status_Illegal_Attribute_Prefix_Kind_Mismatch,
      Status_Illegal_Attribute_Static_Requirement_Missing,
      Status_Illegal_Attribute_Result_Type_Mismatch,
      Status_Illegal_Dereference_Non_Access_Prefix,
      Status_Illegal_Index_Count_Mismatch,
      Status_Illegal_Array_Index_Type_Mismatch,
      Status_Illegal_Generalized_Indexing_Profile_Missing,
      Status_Illegal_Generalized_Indexing_Profile_Mismatch,
      Status_Illegal_Component_Selection_Type_Mismatch,
      Status_Illegal_Overload_Set_Mismatch,
      Status_Illegal_Expected_Type_Lost,
      Status_Illegal_Callable_Profile_Mismatch,
      Status_Illegal_No_Visible_Candidate,
      Status_Illegal_Ambiguous_Overload,
      Status_Runtime_Null_Dereference_Check_Preserved,
      Status_Runtime_Index_Bounds_Check_Preserved,
      Status_Runtime_Generalized_Indexing_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Overload_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Name_Model_Disagreement,
      Status_Consumer_Entity_Model_Disagreement,
      Status_Consumer_View_Model_Disagreement,
      Status_Consumer_Attribute_Model_Disagreement,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Entity_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Overload_Fingerprint_Mismatch,
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
      Construct : Name_Construct_Kind := Construct_Unknown;
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
      Direct_Visibility_Agrees : Boolean := True;
      Selected_Prefix_Visible : Boolean := True;
      Private_Child_Visibility_Respected : Boolean := True;
      Hiding_Homographs_Disambiguated : Boolean := True;
      Use_Package_Homographs_Overloadable : Boolean := True;
      Use_Type_Operators_Visible : Boolean := True;
      Selector_Exists : Boolean := True;
      Selector_Ambiguous : Boolean := False;
      Attribute_Prefix_Kind_Compatible : Boolean := True;
      Attribute_Static_Requirement_Satisfied : Boolean := True;
      Attribute_Result_Type_Compatible : Boolean := True;
      Explicit_Dereference_Access_Prefix : Boolean := True;
      Implicit_Dereference_Allowed : Boolean := True;
      Null_Dereference_Runtime_Check : Boolean := False;
      Index_Count_Compatible : Boolean := True;
      Index_Type_Compatible : Boolean := True;
      Index_Bounds_Runtime_Check : Boolean := False;
      Generalized_Indexing_Profile_Present : Boolean := True;
      Generalized_Indexing_Profile_Compatible : Boolean := True;
      Generalized_Indexing_Runtime_Check : Boolean := False;
      Component_Selection_Type_Compatible : Boolean := True;
      Overload_Set_Canonical : Boolean := True;
      Expected_Type_Propagated : Boolean := True;
      Callable_Profile_Agrees : Boolean := True;
      Visible_Candidate_Present : Boolean := True;
      Overload_Ambiguous : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View_Evidence : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Overload_Evidence : Boolean := False;
      Consumer_Name_Model_Agrees : Boolean := True;
      Consumer_Entity_Model_Agrees : Boolean := True;
      Consumer_View_Model_Agrees : Boolean := True;
      Consumer_Attribute_Model_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Entity_Fingerprint : Natural := 0;
      Expected_Entity_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Overload_Fingerprint : Natural := 0;
      Expected_Overload_Fingerprint : Natural := 0;
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
   function Name_Visibility_Attribute_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1349;
