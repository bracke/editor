with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1344 is

   --  Pass1344 is the second RM gap burn-down pass.  It closes a concrete
   --  generic-instantiation gap by requiring one shared legality result across
   --  formal-to-actual substitution, generic body replay, callable-profile
   --  conformance, overload/expected-type evidence, contract and flow
   --  propagation, private/limited/incomplete view blockers, balanced
   --  regression evidence, and real semantic consumers.

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
     (Gap_Generic_Substitution_Body_Replay_Profile_Flow,
      Gap_Generic_Formal_To_Actual_Substitution,
      Gap_Generic_Body_Replay_Actualization,
      Gap_Generic_Callable_Profile_Agreement,
      Gap_Generic_Contract_Flow_Propagation,
      Gap_Generic_Private_View_Indeterminacy,
      Gap_Unknown);

   type Generic_Formal_Kind is
     (Formal_Type,
      Formal_Object,
      Formal_Subprogram,
      Formal_Package,
      Formal_Access_Type,
      Formal_Private_Type,
      Formal_Unknown);

   type Generic_Replay_Context is
     (Context_Replayed_Call,
      Context_Replayed_Operator,
      Context_Object_Declaration,
      Context_Aggregate_Actual,
      Context_Assignment_Statement,
      Context_Representation_Clause,
      Context_Nested_Instantiation,
      Context_Contract_Aspect,
      Context_Flow_Aspect,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Missing_Formal_Binding,
      Status_Illegal_Formal_Actual_Kind_Mismatch,
      Status_Illegal_Type_Substitution_Mismatch,
      Status_Illegal_Object_Mode_Mismatch,
      Status_Illegal_Callable_Profile_Mismatch,
      Status_Illegal_Default_Formal_Mismatch,
      Status_Illegal_Null_Exclusion_Mismatch,
      Status_Illegal_Convention_Mismatch,
      Status_Illegal_Access_Subprogram_Profile_Mismatch,
      Status_Illegal_Overload_Profile_Disagreement,
      Status_Illegal_Body_Replay_Uses_Formal_Placeholder,
      Status_Illegal_Nested_Instance_Cycle,
      Status_Illegal_Replay_Depth_Overflow,
      Status_Illegal_Contract_Pre_Post_Mismatch,
      Status_Illegal_Global_Depends_Mismatch,
      Status_Illegal_Refined_Flow_Mismatch,
      Status_Illegal_Volatile_Atomic_Order_Mismatch,
      Status_Illegal_Dispatching_Effect_Join_Mismatch,
      Status_Runtime_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
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
      Formal : Generic_Formal_Kind := Formal_Unknown;
      Context : Generic_Replay_Context := Context_Unknown;
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
      Formal_Binding_Present : Boolean := True;
      Formal_Actual_Kind_Compatible : Boolean := True;
      Type_Substitution_Compatible : Boolean := True;
      Object_Mode_Compatible : Boolean := True;
      Callable_Profile_Compatible : Boolean := True;
      Defaulted_Formals_Compatible : Boolean := True;
      Null_Exclusions_Compatible : Boolean := True;
      Conventions_Compatible : Boolean := True;
      Access_Subprogram_Profile_Compatible : Boolean := True;
      Overload_Result_Agrees_With_Profile : Boolean := True;
      Body_Replay_Uses_Substituted_Actuals : Boolean := True;
      Nested_Instantiation_Cycle : Boolean := False;
      Replay_Depth_Overflow : Boolean := False;
      Contracts_Preserved : Boolean := True;
      Global_Depends_Preserved : Boolean := True;
      Refined_Flow_Preserved : Boolean := True;
      Volatile_Atomic_Order_Preserved : Boolean := True;
      Dispatching_Effect_Join_Preserved : Boolean := True;
      Runtime_Accessibility_Check : Boolean := False;
      Runtime_Range_Check : Boolean := False;
      Runtime_Predicate_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
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
   function Generic_Profile_Flow_Gap_Closed (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1344;
