with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1354 is

   --  Case 1354 is the twelfth RM gap burn-down case.  It closes a concrete
   --  declaration-region/scope/completion/homograph/renaming/alias lifecycle
   --  gap by requiring declaration producers and all semantic consumers to
   --  agree on one canonical source-shaped entity, scope, completion, view,
   --  profile, and alias result.

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
     (Gap_Declaration_Region_Scope_Completion_Alias,
      Gap_Declarative_Region,
      Gap_Homograph_And_Hiding,
      Gap_Completion_Lifecycle,
      Gap_Renaming_Alias,
      Gap_Cross_Slice_Consumer_Agreement,
      Gap_Unknown);

   type Declaration_Construct_Kind is
     (Construct_Package_Spec,
      Construct_Package_Body,
      Construct_Subprogram_Spec,
      Construct_Subprogram_Body,
      Construct_Block_Statement,
      Construct_Task_Body,
      Construct_Protected_Body,
      Construct_Loop_Parameter,
      Construct_Generic_Spec,
      Construct_Generic_Body,
      Construct_Private_Type_Completion,
      Construct_Incomplete_Type_Completion,
      Construct_Deferred_Constant_Completion,
      Construct_Renaming_Declaration,
      Construct_Alias_Chain,
      Construct_Unknown);

   type Region_Context_Kind is
     (Context_Library_Unit,
      Context_Package_Declaration,
      Context_Subprogram_Declaration,
      Context_Block_Declaration,
      Context_Task_Protected_Declaration,
      Context_Generic_Declaration,
      Context_Use_Visible_Declaration,
      Context_Completion_Region,
      Context_Renaming_Alias,
      Context_Consumer_Surface,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Runtime_Default_Initialization_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Declarative_Region_Missing,
      Status_Illegal_Scope_Parent_Mismatch,
      Status_Illegal_Duplicate_Nonoverloadable_Declaration,
      Status_Illegal_Overloadable_Homograph_Collapsed_As_Duplicate,
      Status_Illegal_Direct_Hiding_Conflict_Mismatch,
      Status_Illegal_Use_Visible_Conflict_Mismatch,
      Status_Illegal_Private_Full_View_Disagreement,
      Status_Illegal_Incomplete_Type_Used_As_Complete,
      Status_Illegal_Deferred_Constant_Missing_Completion,
      Status_Illegal_Deferred_Constant_Completion_Mismatch,
      Status_Illegal_Body_Spec_Kind_Mismatch,
      Status_Illegal_Body_Spec_Profile_Mismatch,
      Status_Illegal_Task_Protected_Body_Missing,
      Status_Illegal_Generic_Body_Missing,
      Status_Illegal_Duplicate_Completion,
      Status_Illegal_Missing_Completion,
      Status_Illegal_Renaming_Target_Missing,
      Status_Illegal_Renaming_Target_Not_Visible,
      Status_Illegal_Renaming_Kind_Mismatch,
      Status_Illegal_Renaming_Type_Profile_Mode_Mismatch,
      Status_Illegal_Renaming_View_Lost,
      Status_Illegal_Alias_Cycle,
      Status_Illegal_Alias_Depth_Overflow,
      Status_Illegal_Name_Resolution_Entity_Disagreement,
      Status_Illegal_Aggregate_Completion_View_Disagreement,
      Status_Illegal_Assignment_Completion_View_Disagreement,
      Status_Illegal_Generic_Substitution_Entity_Lost,
      Status_Illegal_Outline_Completion_Disagreement,
      Status_Illegal_Navigation_Alias_Disagreement,
      Status_Illegal_Hover_View_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Indeterminate_Missing_Declaration_Evidence,
      Status_Indeterminate_Missing_Scope_Evidence,
      Status_Indeterminate_Missing_Completion_Evidence,
      Status_Indeterminate_Missing_Alias_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
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
      Status_Declaration_Fingerprint_Mismatch,
      Status_Scope_Fingerprint_Mismatch,
      Status_Completion_Fingerprint_Mismatch,
      Status_Alias_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
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
      Construct : Declaration_Construct_Kind := Construct_Unknown;
      Context : Region_Context_Kind := Context_Unknown;
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
      Declarative_Region_Present : Boolean := True;
      Scope_Parent_Agrees : Boolean := True;
      Duplicate_Nonoverloadable_Declaration : Boolean := False;
      Overloadable_Homographs_Agree : Boolean := True;
      Hiding_Vs_Conflict_Agrees : Boolean := True;
      Use_Visible_Conflict_Agrees : Boolean := True;
      Private_Full_View_Agrees : Boolean := True;
      Incomplete_Type_Completed_Before_Use : Boolean := True;
      Incomplete_Type_Used_As_Complete : Boolean := False;
      Deferred_Constant_Completion_Present : Boolean := True;
      Deferred_Constant_Completion_Agrees : Boolean := True;
      Body_Spec_Kind_Agrees : Boolean := True;
      Body_Spec_Profile_Agrees : Boolean := True;
      Task_Protected_Body_Completion_Present : Boolean := True;
      Generic_Body_Completion_Present : Boolean := True;
      Duplicate_Completion : Boolean := False;
      Missing_Completion : Boolean := False;
      Renaming_Target_Present : Boolean := True;
      Renaming_Target_Visible : Boolean := True;
      Renaming_Kind_Agrees : Boolean := True;
      Renaming_Type_Profile_Mode_Agrees : Boolean := True;
      Renaming_View_Preserved : Boolean := True;
      Alias_Cycle : Boolean := False;
      Alias_Depth_Overflow : Boolean := False;
      Name_Resolution_Consumes_Entity : Boolean := True;
      Aggregate_Consumes_Completion_View : Boolean := True;
      Assignment_Consumes_Completion_View : Boolean := True;
      Generic_Substitution_Preserves_Entity : Boolean := True;
      Runtime_Default_Initialization_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Consumer_Declaration_Agrees : Boolean := True;
      Consumer_Completion_Agrees : Boolean := True;
      Consumer_Alias_Agrees : Boolean := True;
      Consumer_View_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Missing_Declaration_Evidence : Boolean := False;
      Missing_Scope_Evidence : Boolean := False;
      Missing_Completion_Evidence : Boolean := False;
      Missing_Alias_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Declaration_Fingerprint : Natural := 0;
      Expected_Declaration_Fingerprint : Natural := 0;
      Scope_Fingerprint : Natural := 0;
      Expected_Scope_Fingerprint : Natural := 0;
      Completion_Fingerprint : Natural := 0;
      Expected_Completion_Fingerprint : Natural := 0;
      Alias_Fingerprint : Natural := 0;
      Expected_Alias_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
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
      Construct : Declaration_Construct_Kind := Construct_Unknown;
      Context : Region_Context_Kind := Context_Unknown;
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
   function Declaration_Scope_Completion_Alias_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Case_1354;
