with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1361 is

   --  Case 1361 is the nineteenth RM gap burn-down case.  It closes the
   --  incremental snapshot and semantic invalidation gap for a live editor.
   --  The pass verifies that source-owned semantic results are preserved,
   --  invalidated, or recomputed across edits according to buffer identity,
   --  source revision, lifecycle generation, request token, recovery
   --  generation, source span identity, dependency fingerprints, and consumer
   --  fingerprints.  It also preserves editor invariants: semantic analysis
   --  may not save/reload files, mutate dirty state, parse on the rendering
   --  path, leak command/keybinding/workspace/render mutations, or perform
   --  unbounded recomputation.

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
     (Gap_Incremental_Snapshot_Semantic_Invalidation,
      Gap_Snapshot_Identity,
      Gap_Semantic_Dependency_Invalidation,
      Gap_Stable_Result_Preservation,
      Gap_Consumer_Stale_Row_Rejection,
      Gap_Editor_Invariant_Safety,
      Gap_Unknown);

   type Snapshot_Change_Kind is
     (Change_None,
      Change_Whitespace_Or_Comment,
      Change_Source_Revision,
      Change_AST_Shape,
      Change_Declaration,
      Change_Type,
      Change_Generic_Formal,
      Change_Context_Clause,
      Change_Representation,
      Change_Contract_Or_Flow,
      Change_Recovery_Shape,
      Change_Request_Token,
      Change_Lifecycle_Generation,
      Change_Unknown);

   type Semantic_Result_Kind is
     (Result_None,
      Result_AST,
      Result_Name_Visibility,
      Result_Type_Profile,
      Result_Aggregate_Assignment_Call,
      Result_Generic_Substitution_Replay,
      Result_Cross_Unit_Elaboration,
      Result_Representation_Freezing,
      Result_Contract_Flow_Consumer,
      Result_Recovery,
      Result_Consumer_All,
      Result_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Result_Preserved,
      Status_Legal_Result_Invalidated,
      Status_Legal_Result_Recomputed,
      Status_Legal_Stable_Identity_Preserved,
      Status_Legal_Runtime_Check_Preserved,
      Status_Illegal_Stale_Semantic_Result_Reused,
      Status_Illegal_Needless_Entity_Identity_Churn,
      Status_Illegal_Diagnostic_From_Old_Request_Token,
      Status_Illegal_Stale_Outline_Or_Navigation_Row,
      Status_Illegal_Stale_Hover_Type_Profile,
      Status_Illegal_Stale_Cross_Unit_Result,
      Status_Illegal_Stale_Generic_Body_Replay,
      Status_Illegal_Stale_Representation_Freezing_Result,
      Status_Illegal_Stale_Recovery_Result,
      Status_Illegal_Consumer_Recomputed_Names_Types_Independently,
      Status_Illegal_File_Save_Reload_During_Analysis,
      Status_Illegal_Dirty_State_Mutation,
      Status_Illegal_Rendering_Side_Parsing,
      Status_Illegal_Command_Keybinding_Workspace_Render_Mutation,
      Status_Illegal_Unbounded_Recomputation,
      Status_Illegal_Result_Not_Invalidated_For_AST_Change,
      Status_Illegal_Result_Not_Invalidated_For_Declaration_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Type_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Generic_Formal_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Context_Clause_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Representation_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Contract_Flow_Edit,
      Status_Illegal_Result_Not_Invalidated_For_Recovery_Shape_Edit,
      Status_Illegal_Diagnostics_Missing_Blocker_Family,
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
      Status_Buffer_Identity_Mismatch,
      Status_Source_Revision_Mismatch,
      Status_Lifecycle_Generation_Mismatch,
      Status_Request_Token_Mismatch,
      Status_Recovery_Generation_Mismatch,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Recovery_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Unexpected_Classification,
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
      Change : Snapshot_Change_Kind := Change_Unknown;
      Result : Semantic_Result_Kind := Result_Unknown;
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
      Diagnostics_Blocker_Family_Present : Boolean := True;

      Buffer_Identity : Natural := 0;
      Expected_Buffer_Identity : Natural := 0;
      Source_Revision : Natural := 0;
      Expected_Source_Revision : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      Expected_Lifecycle_Generation : Natural := 0;
      Request_Token : Natural := 0;
      Expected_Request_Token : Natural := 0;
      Recovery_Generation : Natural := 0;
      Expected_Recovery_Generation : Natural := 0;

      Result_Preserved : Boolean := False;
      Result_Invalidated : Boolean := False;
      Result_Recomputed : Boolean := False;
      Stable_Entity_Identity_Preserved : Boolean := True;
      Unrelated_Edit : Boolean := False;
      Underlying_Error_Unchanged : Boolean := False;
      Runtime_Check_Context : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;

      AST_Changed : Boolean := False;
      Declaration_Edited : Boolean := False;
      Type_Edited : Boolean := False;
      Generic_Formal_Edited : Boolean := False;
      Context_Clause_Edited : Boolean := False;
      Representation_Edited : Boolean := False;
      Contract_Flow_Edited : Boolean := False;
      Recovery_Shape_Changed : Boolean := False;

      Stale_Semantic_Result_Reused : Boolean := False;
      Needless_Entity_Identity_Churn : Boolean := False;
      Diagnostic_From_Old_Request_Token : Boolean := False;
      Stale_Outline_Or_Navigation_Row : Boolean := False;
      Stale_Hover_Type_Profile : Boolean := False;
      Stale_Cross_Unit_Result : Boolean := False;
      Stale_Generic_Body_Replay : Boolean := False;
      Stale_Representation_Freezing_Result : Boolean := False;
      Stale_Recovery_Result : Boolean := False;
      Consumer_Recomputed_Names_Types_Independently : Boolean := False;

      File_Save_Reload_During_Analysis : Boolean := False;
      Dirty_State_Mutation : Boolean := False;
      Rendering_Side_Parsing : Boolean := False;
      Command_Keybinding_Workspace_Render_Mutation : Boolean := False;
      Unbounded_Recomputation : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
      Recovery_Fingerprint : Natural := 0;
      Expected_Recovery_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Change : Snapshot_Change_Kind := Change_Unknown;
      Result : Semantic_Result_Kind := Result_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Preserved_Count : Natural := 0;
      Invalidated_Count : Natural := 0;
      Recomputed_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row);
   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;
   function Incremental_Invalidation_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1361;
