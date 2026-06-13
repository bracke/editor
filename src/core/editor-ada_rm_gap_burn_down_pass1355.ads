with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1355 is

   --  Pass1355 is the thirteenth RM gap burn-down pass.  It closes a
   --  concrete call-site gap by requiring actual/formal association,
   --  parameter modes, defaulted formals, null exclusions, accessibility,
   --  writable-actual aliasing, dispatching, generic substitution, renaming,
   --  access-to-subprogram calls, contracts, flow effects, and semantic
   --  consumers to agree on one canonical source-shaped call result.

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
     (Gap_Call_Actual_Parameter_Mode_Aliasing,
      Gap_Actual_Formal_Association,
      Gap_Parameter_Mode,
      Gap_Profile_Null_Accessibility,
      Gap_Aliasing_Side_Effects,
      Gap_Dispatch_Generic_Renaming_Access_Call,
      Gap_Contract_Effect_Propagation,
      Gap_Unknown);

   type Call_Construct_Kind is
     (Construct_Procedure_Call,
      Construct_Function_Call,
      Construct_Operator_Call,
      Construct_Dispatching_Call,
      Construct_Generic_Formal_Subprogram_Call,
      Construct_Renamed_Callable_Call,
      Construct_Access_To_Subprogram_Call,
      Construct_Entry_Call,
      Construct_Unknown);

   type Call_Context_Kind is
     (Context_Positional_Association,
      Context_Named_Association,
      Context_Mixed_Association,
      Context_Defaulted_Formal,
      Context_Writable_Actual,
      Context_Access_Parameter,
      Context_Dispatching_Call,
      Context_Generic_Substitution,
      Context_Renaming,
      Context_Access_To_Subprogram,
      Context_Contract_Effect,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Runtime_Accessibility_Check_Preserved,
      Status_Runtime_Range_Predicate_Check_Preserved,
      Status_Warning_Only_Policy_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Warning_Policy_Evidence_Lost,
      Status_Illegal_Missing_Required_Actual,
      Status_Illegal_Extra_Actual,
      Status_Illegal_Duplicate_Actual_Association,
      Status_Illegal_Positional_Actual_After_Named,
      Status_Illegal_Defaulted_Formal_Not_Available,
      Status_Illegal_Association_Profile_Disagreement,
      Status_Illegal_Out_Actual_Not_Variable,
      Status_Illegal_In_Out_Actual_Not_Variable,
      Status_Illegal_Constant_View_For_Writable_Formal,
      Status_Illegal_Limited_View_For_Writable_Formal,
      Status_Illegal_Out_Formal_Definite_Assignment_Missing,
      Status_Illegal_Formal_Actual_Type_Mismatch,
      Status_Illegal_Access_Parameter_Mismatch,
      Status_Illegal_Anonymous_Access_Actual_Mismatch,
      Status_Illegal_Null_Exclusion_Violation,
      Status_Illegal_Static_Accessibility_Escape,
      Status_Illegal_Callable_Profile_Disagreement,
      Status_Illegal_Overload_Profile_Disagreement,
      Status_Illegal_Writable_Actual_Alias,
      Status_Illegal_Overlapping_Writable_Actuals,
      Status_Illegal_Access_Value_Alias,
      Status_Illegal_Volatile_Atomic_Ordering_Lost,
      Status_Illegal_Protected_Shared_State_Effect_Lost,
      Status_Illegal_Dispatching_Control_Evidence_Lost,
      Status_Illegal_Generic_Substitution_Profile_Lost,
      Status_Illegal_Renamed_Callable_Profile_Lost,
      Status_Illegal_Access_To_Subprogram_Convention_Mismatch,
      Status_Illegal_Contract_Evidence_Lost,
      Status_Illegal_Global_Depends_Evidence_Lost,
      Status_Illegal_Refined_Flow_Evidence_Lost,
      Status_Illegal_Dispatching_Effect_Join_Lost,
      Status_Illegal_Hard_Policy_Violation_Downgraded,
      Status_Illegal_Diagnostics_Call_Disagreement,
      Status_Illegal_Colouring_Call_Disagreement,
      Status_Illegal_Outline_Profile_Disagreement,
      Status_Illegal_Navigation_Target_Disagreement,
      Status_Illegal_Hover_Effect_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Call_Evidence,
      Status_Indeterminate_Missing_Association_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Overload_Evidence,
      Status_Indeterminate_Missing_Substitution_Evidence,
      Status_Indeterminate_Missing_Effect_Evidence,
      Status_Indeterminate_Missing_Aliasing_Evidence,
      Status_Indeterminate_Missing_Accessibility_Evidence,
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
      Status_Call_Fingerprint_Mismatch,
      Status_Association_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Overload_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Alias_Fingerprint_Mismatch,
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
      Construct : Call_Construct_Kind := Construct_Unknown;
      Context : Call_Context_Kind := Context_Unknown;
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
      Required_Actuals_Present : Boolean := True;
      Extra_Actuals : Boolean := False;
      Duplicate_Actual_Association : Boolean := False;
      Positional_Actual_After_Named : Boolean := False;
      Defaulted_Formals_Available : Boolean := True;
      Association_Profile_Agrees : Boolean := True;
      Out_Formal : Boolean := False;
      In_Out_Formal : Boolean := False;
      Out_Actual_Is_Variable : Boolean := True;
      In_Out_Actual_Is_Variable : Boolean := True;
      Actual_Is_Constant_View : Boolean := False;
      Writable_Limited_View : Boolean := False;
      Out_Formal_Definite_Assignment_Present : Boolean := True;
      Formal_Actual_Type_Agrees : Boolean := True;
      Access_Parameter_Agrees : Boolean := True;
      Anonymous_Access_Actual_Agrees : Boolean := True;
      Null_Exclusion_Violation : Boolean := False;
      Static_Accessibility_Escape : Boolean := False;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Range_Predicate_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Callable_Profile_Agrees : Boolean := True;
      Overload_Profile_Agrees : Boolean := True;
      Writable_Actual_Alias : Boolean := False;
      Overlapping_Writable_Actuals : Boolean := False;
      Access_Value_Alias : Boolean := False;
      Volatile_Atomic_Ordering_Preserved : Boolean := True;
      Protected_Shared_State_Effect_Preserved : Boolean := True;
      Dispatching_Control_Evidence_Preserved : Boolean := True;
      Generic_Substitution_Profile_Preserved : Boolean := True;
      Renamed_Callable_Profile_Preserved : Boolean := True;
      Access_To_Subprogram_Convention_Agrees : Boolean := True;
      Contract_Evidence_Preserved : Boolean := True;
      Global_Depends_Evidence_Preserved : Boolean := True;
      Refined_Flow_Evidence_Preserved : Boolean := True;
      Dispatching_Effect_Join_Preserved : Boolean := True;
      Warning_Only_Policy : Boolean := False;
      Warning_Policy_Evidence_Preserved : Boolean := True;
      Hard_Policy_Violation_Downgraded : Boolean := False;
      Consumer_Call_Agrees : Boolean := True;
      Consumer_Actual_Agrees : Boolean := True;
      Consumer_Profile_Agrees : Boolean := True;
      Consumer_Target_Agrees : Boolean := True;
      Consumer_Effect_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Call_Evidence : Boolean := False;
      Missing_Association_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Overload_Evidence : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Missing_Aliasing_Evidence : Boolean := False;
      Missing_Accessibility_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Call_Fingerprint : Natural := 0;
      Expected_Call_Fingerprint : Natural := 0;
      Association_Fingerprint : Natural := 0;
      Expected_Association_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Overload_Fingerprint : Natural := 0;
      Expected_Overload_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Alias_Fingerprint : Natural := 0;
      Expected_Alias_Fingerprint : Natural := 0;
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
      Construct : Call_Construct_Kind := Construct_Unknown;
      Context : Call_Context_Kind := Context_Unknown;
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
      Warning_Count : Natural := 0;
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
   function Call_Actual_Parameter_Mode_Aliasing_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Pass1355;
