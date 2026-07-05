with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1356 is

   --  Case 1356 is the fourteenth RM gap burn-down case.  It closes the
   --  master/lifetime/accessibility-closure gap by requiring access values,
   --  return objects, allocators, access discriminants, task/protected
   --  objects, finalization ownership, generic substitution, call-site
   --  parameter passing, and semantic consumers to agree on one canonical
   --  source-shaped master model.

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
     (Gap_Master_Lifetime_Accessibility_Closure,
      Gap_Master_Identity,
      Gap_Accessibility_Closure,
      Gap_Return_Object_Lifetime,
      Gap_Finalization_Ownership,
      Gap_Cross_Slice_Lifetime_Consumer,
      Gap_Unknown);

   type Lifetime_Construct_Kind is
     (Construct_Access_Value,
      Construct_Access_Object_Assignment,
      Construct_Return_Access_Value,
      Construct_Anonymous_Access_Parameter,
      Construct_Access_Discriminant,
      Construct_Allocator_Object,
      Construct_Return_Object,
      Construct_Returned_Aggregate,
      Construct_Controlled_Object,
      Construct_Task_Object,
      Construct_Protected_Object,
      Construct_Unchecked_Deallocation,
      Construct_Generic_Instance,
      Construct_Unknown);

   type Lifetime_Context_Kind is
     (Context_Library_Master,
      Context_Subprogram_Master,
      Context_Block_Master,
      Context_Return_Object_Master,
      Context_Allocator_Master,
      Context_Task_Master,
      Context_Protected_Master,
      Context_Anonymous_Access_Master,
      Context_Generic_Substitution,
      Context_Finalization_Path,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Runtime_Finalization_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Static_Accessibility_Escape,
      Status_Illegal_Access_Value_Escapes_Master,
      Status_Illegal_Return_Access_Escapes_Master,
      Status_Illegal_Assignment_To_Longer_Lived_Access_Object,
      Status_Illegal_Access_Discriminant_Escapes_Master,
      Status_Illegal_Anonymous_Access_Escape,
      Status_Illegal_Return_Object_Master_Lost,
      Status_Illegal_Limited_Return_Object_Lifetime_Lost,
      Status_Illegal_Controlled_Return_Object_Owner_Lost,
      Status_Illegal_Returned_Aggregate_Component_Escapes,
      Status_Illegal_Allocator_Lifetime_Evidence_Lost,
      Status_Illegal_Unchecked_Deallocation_Lifetime_Lost,
      Status_Illegal_Generic_Substitution_Lifetime_Changed,
      Status_Illegal_Task_Lifetime_Treated_As_Block,
      Status_Illegal_Protected_Lifetime_Treated_As_Block,
      Status_Illegal_Finalization_Owner_Lost,
      Status_Illegal_Normal_Return_Finalization_Lost,
      Status_Illegal_Exception_Propagation_Finalization_Lost,
      Status_Illegal_Task_Abort_Finalization_Lost,
      Status_Illegal_Aggregate_Assignment_Lifetime_Disagreement,
      Status_Illegal_Call_Actual_Lifetime_Disagreement,
      Status_Illegal_Control_Flow_Finalization_Disagreement,
      Status_Illegal_Accessibility_Slice_Disagreement,
      Status_Illegal_Diagnostics_Lifetime_Disagreement,
      Status_Illegal_Colouring_Lifetime_Disagreement,
      Status_Illegal_Outline_Declaration_Lifetime_Disagreement,
      Status_Illegal_Navigation_Target_Lifetime_Disagreement,
      Status_Illegal_Hover_Lifetime_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Lifetime_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Master_Evidence,
      Status_Indeterminate_Missing_Lifetime_Evidence,
      Status_Indeterminate_Missing_Accessibility_Evidence,
      Status_Indeterminate_Missing_Return_Object_Evidence,
      Status_Indeterminate_Missing_Finalization_Evidence,
      Status_Indeterminate_Missing_Allocator_Evidence,
      Status_Indeterminate_Missing_Generic_Substitution_Evidence,
      Status_Indeterminate_Missing_Call_Evidence,
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
      Status_Master_Fingerprint_Mismatch,
      Status_Lifetime_Fingerprint_Mismatch,
      Status_Accessibility_Fingerprint_Mismatch,
      Status_Return_Object_Fingerprint_Mismatch,
      Status_Allocation_Fingerprint_Mismatch,
      Status_Finalization_Fingerprint_Mismatch,
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
      Construct : Lifetime_Construct_Kind := Construct_Unknown;
      Context : Lifetime_Context_Kind := Context_Unknown;
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
      Same_Canonical_Master : Boolean := True;
      Access_Value_Escapes_Master : Boolean := False;
      Return_Access_Escapes_Master : Boolean := False;
      Assignment_To_Longer_Lived_Access_Object : Boolean := False;
      Access_Discriminant_Escapes_Master : Boolean := False;
      Anonymous_Access_Escapes_Master : Boolean := False;
      Static_Accessibility_Escape : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Finalization_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Return_Object_Master_Preserved : Boolean := True;
      Limited_Return_Object_Lifetime_Preserved : Boolean := True;
      Controlled_Return_Object_Owner_Preserved : Boolean := True;
      Returned_Aggregate_Components_Safe : Boolean := True;
      Allocator_Lifetime_Evidence_Preserved : Boolean := True;
      Unchecked_Deallocation_Lifetime_Preserved : Boolean := True;
      Generic_Substitution_Lifetime_Preserved : Boolean := True;
      Task_Lifetime_Is_Task_Master : Boolean := True;
      Protected_Lifetime_Is_Protected_Master : Boolean := True;
      Finalization_Owner_Preserved : Boolean := True;
      Normal_Return_Finalization_Preserved : Boolean := True;
      Exception_Propagation_Finalization_Preserved : Boolean := True;
      Task_Abort_Finalization_Preserved : Boolean := True;
      Aggregate_Assignment_Lifetime_Agrees : Boolean := True;
      Call_Actual_Lifetime_Agrees : Boolean := True;
      Control_Flow_Finalization_Agrees : Boolean := True;
      Accessibility_Slice_Agrees : Boolean := True;
      Consumer_Lifetime_Agrees : Boolean := True;
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
      Missing_Master_Evidence : Boolean := False;
      Missing_Lifetime_Evidence : Boolean := False;
      Missing_Accessibility_Evidence : Boolean := False;
      Missing_Return_Object_Evidence : Boolean := False;
      Missing_Finalization_Evidence : Boolean := False;
      Missing_Allocator_Evidence : Boolean := False;
      Missing_Generic_Substitution_Evidence : Boolean := False;
      Missing_Call_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Master_Fingerprint : Natural := 0;
      Expected_Master_Fingerprint : Natural := 0;
      Lifetime_Fingerprint : Natural := 0;
      Expected_Lifetime_Fingerprint : Natural := 0;
      Accessibility_Fingerprint : Natural := 0;
      Expected_Accessibility_Fingerprint : Natural := 0;
      Return_Object_Fingerprint : Natural := 0;
      Expected_Return_Object_Fingerprint : Natural := 0;
      Allocation_Fingerprint : Natural := 0;
      Expected_Allocation_Fingerprint : Natural := 0;
      Finalization_Fingerprint : Natural := 0;
      Expected_Finalization_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Construct : Lifetime_Construct_Kind := Construct_Unknown;
      Context : Lifetime_Context_Kind := Context_Unknown;
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
   function Master_Lifetime_Accessibility_Closure_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Case_1356;
