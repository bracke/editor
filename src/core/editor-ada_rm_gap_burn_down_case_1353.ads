with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1353 is

   --  Case 1353 is the eleventh RM gap burn-down case.  It closes a concrete
   --  allocator/storage-pool/access-lifetime/unchecked-operation legality gap
   --  by requiring access allocation, storage-pool evidence, unchecked
   --  operations, finalization, representation/freezing, restriction policy,
   --  generic substitution, and semantic consumers to agree on one canonical
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
     (Gap_Allocator_Storage_Pool_Unchecked_Operations,
      Gap_Allocator,
      Gap_Storage_Pool,
      Gap_Access_Lifetime,
      Gap_Unchecked_Operation,
      Gap_Restriction_Policy,
      Gap_Consumer_Agreement,
      Gap_Unknown);

   type Access_Construct_Kind is
     (Construct_Initialized_Allocator,
      Construct_Uninitialized_Allocator,
      Construct_Subtype_Mark_Allocator,
      Construct_Qualified_Expression_Allocator,
      Construct_Limited_Type_Allocator,
      Construct_Access_Object_Conversion,
      Construct_Access_Discriminant,
      Construct_Anonymous_Access_Assignment,
      Construct_Unchecked_Conversion_Instantiation,
      Construct_Unchecked_Deallocation_Instantiation,
      Construct_Storage_Pool_Aspect,
      Construct_Storage_Size_Aspect,
      Construct_No_Allocators_Restriction,
      Construct_Suppress_Unsuppress_Policy,
      Construct_Unknown);

   type Memory_Context_Kind is
     (Context_Access_Type,
      Context_Anonymous_Access,
      Context_Generic_Instance,
      Context_Storage_Pool,
      Context_Representation_Freezing,
      Context_Finalization,
      Context_Restriction_Enforcement,
      Context_Restriction_Warning,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Warning_Allocation_Restriction_Preserved,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Runtime_Constraint_Check_Preserved,
      Status_Illegal_Allocator_Missing_Designated_Subtype,
      Status_Illegal_Allocator_Designated_Subtype_Unavailable,
      Status_Illegal_Limited_Type_Allocator,
      Status_Illegal_Controlled_Finalized_Allocator_Hazard,
      Status_Illegal_Null_Exclusion_Violation,
      Status_Illegal_Storage_Pool_Missing,
      Status_Illegal_Storage_Pool_Conflict,
      Status_Illegal_Storage_Size_Not_Static,
      Status_Illegal_Storage_Size_Incompatible,
      Status_Illegal_Storage_Pool_Frozen,
      Status_Illegal_Storage_Pool_Constraint,
      Status_Illegal_Representation_Freezing_Disagreement,
      Status_Illegal_Access_Conversion_Incompatible,
      Status_Illegal_Static_Accessibility_Escape,
      Status_Illegal_Access_Discriminant_Escape,
      Status_Illegal_Anonymous_Access_Assignment_Escape,
      Status_Illegal_Generic_Access_Substitution_Mismatch,
      Status_Illegal_Unchecked_Conversion_Profile,
      Status_Illegal_Unchecked_Deallocation_Incompatible_Access_Type,
      Status_Illegal_Unchecked_Deallocation_Controlled_Finalized_Hazard,
      Status_Illegal_Unknown_Restriction,
      Status_Illegal_Restriction_No_Allocators_Violation,
      Status_Illegal_Restriction_Warning_Treated_As_Hard_Error,
      Status_Illegal_Local_Slice_Ignores_Allocation_Policy,
      Status_Illegal_Generic_Replay_Access_Substitution_Lost,
      Status_Illegal_Finalization_Evidence_Disagreement,
      Status_Warning_Restriction_Evidence_Lost,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Designated_Subtype_Evidence,
      Status_Indeterminate_Missing_Storage_Pool_Evidence,
      Status_Indeterminate_Missing_Lifetime_Evidence,
      Status_Indeterminate_Missing_Unchecked_Profile_Evidence,
      Status_Indeterminate_Missing_Size_View_Evidence,
      Status_Indeterminate_Missing_Policy_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Storage_Model_Disagreement,
      Status_Consumer_Lifetime_Model_Disagreement,
      Status_Consumer_Unchecked_Operation_Model_Disagreement,
      Status_Consumer_Policy_Model_Disagreement,
      Status_Consumer_Warning_State_Hidden,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
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
      Status_Policy_Fingerprint_Mismatch,
      Status_Storage_Pool_Fingerprint_Mismatch,
      Status_Lifetime_Fingerprint_Mismatch,
      Status_Representation_Fingerprint_Mismatch,
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
      Construct : Access_Construct_Kind := Construct_Unknown;
      Context : Memory_Context_Kind := Context_Unknown;
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
      Designated_Subtype_Present : Boolean := True;
      Designated_Subtype_Available : Boolean := True;
      Limited_Type_Allocation_Allowed : Boolean := True;
      Controlled_Finalized_Allocation_Safe : Boolean := True;
      Null_Exclusion_Violation : Boolean := False;
      Storage_Pool_Present : Boolean := True;
      Storage_Pool_Conflict : Boolean := False;
      Storage_Size_Static : Boolean := True;
      Storage_Size_Compatible : Boolean := True;
      Storage_Pool_Frozen : Boolean := False;
      Pool_Specific_Constraints_OK : Boolean := True;
      Representation_Freezing_Agrees : Boolean := True;
      Allocator_Consumes_Representation : Boolean := True;
      Access_Conversion_Compatible : Boolean := True;
      Access_Discriminant_Escape : Boolean := False;
      Anonymous_Access_Assignment_Escape : Boolean := False;
      Generic_Access_Substitution_Agrees : Boolean := True;
      Static_Accessibility_Escape : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Constraint_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Unchecked_Conversion_Profile_OK : Boolean := True;
      Unchecked_Conversion_Size_View_Evidence : Boolean := True;
      Unchecked_Deallocation_Access_Type_OK : Boolean := True;
      Unchecked_Deallocation_Finalization_Safe : Boolean := True;
      Restriction_Rule_Known : Boolean := True;
      No_Allocators_Restriction_Violation : Boolean := False;
      Allocation_Restriction_Warning : Boolean := False;
      Restriction_Warning_Preserved : Boolean := True;
      Restriction_Warning_Treated_As_Hard_Error : Boolean := False;
      Suppress_Unsuppress_Agrees : Boolean := True;
      Access_Slice_Consumes_Policy : Boolean := True;
      Finalization_Consumes_Allocation_Evidence : Boolean := True;
      Generic_Replay_Consumes_Access_Actual : Boolean := True;
      Consumer_Storage_Agrees : Boolean := True;
      Consumer_Lifetime_Agrees : Boolean := True;
      Consumer_Unchecked_Operation_Agrees : Boolean := True;
      Consumer_Policy_Agrees : Boolean := True;
      Consumer_Warning_State_Surface : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Designated_Subtype_Evidence : Boolean := False;
      Missing_Storage_Pool_Evidence : Boolean := False;
      Missing_Lifetime_Evidence : Boolean := False;
      Missing_Unchecked_Profile_Evidence : Boolean := False;
      Missing_Size_View_Evidence : Boolean := False;
      Missing_Policy_Evidence : Boolean := False;
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
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
      Storage_Pool_Fingerprint : Natural := 0;
      Expected_Storage_Pool_Fingerprint : Natural := 0;
      Lifetime_Fingerprint : Natural := 0;
      Expected_Lifetime_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
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
      Construct : Access_Construct_Kind := Construct_Unknown;
      Context : Memory_Context_Kind := Context_Unknown;
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
      Warning_Count : Natural := 0;
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
   function Allocator_Storage_Pool_Unchecked_Operations_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Case_1353;
