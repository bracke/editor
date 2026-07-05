with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1352 is

   --  Case 1352 is the tenth RM gap burn-down case.  It closes a concrete
   --  pragma/configuration/categorization/restriction Ada legality gap by
   --  requiring configuration pragmas, restriction policies, unit
   --  categorization, assertion/suppression policies, cross-slice consumers,
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
     (Gap_Pragma_Configuration_Categorization_Restrictions,
      Gap_Configuration_Pragma,
      Gap_Restriction_Policy,
      Gap_Unit_Categorization,
      Gap_Assertion_Suppression_Policy,
      Gap_Cross_Slice_Policy_Consumer,
      Gap_Unknown);

   type Pragma_Construct_Kind is
     (Construct_Configuration_Pragma,
      Construct_Restrictions_Pragma,
      Construct_Restriction_Warnings_Pragma,
      Construct_Pure_Pragma,
      Construct_Preelaborate_Pragma,
      Construct_Remote_Types_Pragma,
      Construct_Shared_Passive_Pragma,
      Construct_Remote_Call_Interface_Pragma,
      Construct_Suppress_Pragma,
      Construct_Unsuppress_Pragma,
      Construct_Assert_Pragma,
      Construct_Assertion_Policy_Pragma,
      Construct_Pack_Pragma,
      Construct_Inline_Pragma,
      Construct_No_Inline_Pragma,
      Construct_Import_Pragma,
      Construct_Export_Pragma,
      Construct_Convention_Pragma,
      Construct_No_Return_Pragma,
      Construct_Volatile_Pragma,
      Construct_Atomic_Pragma,
      Construct_Independent_Pragma,
      Construct_Unknown);

   type Policy_Context_Kind is
     (Context_Configuration_File,
      Context_Compilation_Unit,
      Context_Library_Unit_Category,
      Context_Restriction_Enforcement,
      Context_Restriction_Warning,
      Context_Assertion_Policy,
      Context_Suppression_Policy,
      Context_Interfacing,
      Context_Tasking_Protected,
      Context_Access_Allocation,
      Context_Exception_Finalization,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Warning_Restriction_Preserved,
      Status_Runtime_Assertion_Check_Preserved,
      Status_Runtime_Suppressed_Check_Preserved,
      Status_Illegal_Configuration_Pragma_Placement,
      Status_Illegal_Configuration_Pragma_Target,
      Status_Illegal_Duplicate_Configuration_Pragma,
      Status_Illegal_Conflicting_Configuration_Pragma,
      Status_Illegal_Unknown_Restriction,
      Status_Illegal_Hard_Restriction_Violation,
      Status_Illegal_Restriction_Warning_Treated_As_Hard_Error,
      Status_Illegal_Categorization_Conflict,
      Status_Illegal_Dependency_Category,
      Status_Illegal_Body_Spec_Category_Disagreement,
      Status_Illegal_Pure_Restriction_Violation,
      Status_Illegal_Preelaborate_Restriction_Violation,
      Status_Illegal_Remote_Types_Category_Violation,
      Status_Illegal_Shared_Passive_Category_Violation,
      Status_Illegal_Remote_Call_Interface_Category_Violation,
      Status_Illegal_Suppress_Unsuppress_Placement,
      Status_Illegal_Assert_Expression_Not_Boolean,
      Status_Illegal_Unknown_Assertion_Policy,
      Status_Illegal_Pack_Target,
      Status_Illegal_Inline_No_Inline_Target,
      Status_Illegal_Import_Export_Convention_Disagreement,
      Status_Illegal_No_Return_Flow_Disagreement,
      Status_Illegal_Volatile_Atomic_Independent_Disagreement,
      Status_Illegal_Task_Restriction_Not_Consumed,
      Status_Illegal_Access_Allocation_Restriction_Not_Consumed,
      Status_Illegal_Exception_Finalization_Restriction_Not_Consumed,
      Status_Illegal_Local_Slice_Ignores_Configuration_Policy,
      Status_Warning_Restriction_Evidence_Lost,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Configuration_Evidence,
      Status_Indeterminate_Missing_Categorization_Evidence,
      Status_Indeterminate_Missing_Restriction_Evidence,
      Status_Indeterminate_Missing_Policy_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Configuration_Model_Disagreement,
      Status_Consumer_Restriction_Model_Disagreement,
      Status_Consumer_Categorization_Model_Disagreement,
      Status_Consumer_Assertion_Model_Disagreement,
      Status_Consumer_Warning_State_Hidden,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Category_Fingerprint_Mismatch,
      Status_Restriction_Fingerprint_Mismatch,
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
      Construct : Pragma_Construct_Kind := Construct_Unknown;
      Context : Policy_Context_Kind := Context_Unknown;
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
      Configuration_Placement_OK : Boolean := True;
      Configuration_Target_OK : Boolean := True;
      Duplicate_Configuration_Pragma : Boolean := False;
      Conflicting_Configuration_Pragma : Boolean := False;
      Restriction_Rule_Known : Boolean := True;
      Hard_Restriction_Violation : Boolean := False;
      Restriction_Warning_Violation : Boolean := False;
      Restriction_Warning_Preserved : Boolean := True;
      Restriction_Warning_Treated_As_Hard_Error : Boolean := False;
      Categorization_Conflict : Boolean := False;
      Dependency_Category_Legal : Boolean := True;
      Body_Spec_Category_Agrees : Boolean := True;
      Pure_Restrictions_Hold : Boolean := True;
      Preelaborate_Restrictions_Hold : Boolean := True;
      Remote_Types_Category_Legal : Boolean := True;
      Shared_Passive_Category_Legal : Boolean := True;
      Remote_Call_Interface_Category_Legal : Boolean := True;
      Suppress_Unsuppress_Placement_OK : Boolean := True;
      Assert_Expression_Boolean : Boolean := True;
      Assertion_Policy_Known : Boolean := True;
      Assertion_Runtime_Check : Boolean := False;
      Suppressed_Check_Runtime : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Pack_Target_OK : Boolean := True;
      Inline_No_Inline_Target_OK : Boolean := True;
      Import_Export_Convention_Agrees : Boolean := True;
      No_Return_Flow_Agrees : Boolean := True;
      Volatile_Atomic_Independent_Agrees : Boolean := True;
      Tasking_Consumes_Restrictions : Boolean := True;
      Access_Allocation_Consumes_Restrictions : Boolean := True;
      Exception_Finalization_Consumes_Restrictions : Boolean := True;
      Elaboration_Consumes_Categorization : Boolean := True;
      Local_Slices_Consume_Configuration_Policy : Boolean := True;
      Consumer_Configuration_Agrees : Boolean := True;
      Consumer_Restriction_Agrees : Boolean := True;
      Consumer_Categorization_Agrees : Boolean := True;
      Consumer_Assertion_Agrees : Boolean := True;
      Consumer_Warning_State_Surface : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Configuration_Evidence : Boolean := False;
      Missing_Categorization_Evidence : Boolean := False;
      Missing_Restriction_Evidence : Boolean := False;
      Missing_Policy_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
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
      Category_Fingerprint : Natural := 0;
      Expected_Category_Fingerprint : Natural := 0;
      Restriction_Fingerprint : Natural := 0;
      Expected_Restriction_Fingerprint : Natural := 0;
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
      Construct : Pragma_Construct_Kind := Construct_Unknown;
      Context : Policy_Context_Kind := Context_Unknown;
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
   function Pragma_Configuration_Categorization_Restrictions_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Case_1352;
