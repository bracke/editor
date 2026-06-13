with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1363 is

   --  Pass1363 is the twenty-first RM gap burn-down pass.  It closes the
   --  project semantic index, open-buffer precedence, and multi-buffer
   --  cross-unit closure gap.  The pass verifies that live Ada semantics use
   --  one project-wide snapshot index whose source ownership, unit mapping,
   --  invalidation, stale evidence, and consumer feeds agree without reading
   --  disk text in place of dirty buffers or mutating editor state.

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
     (Gap_Project_Semantic_Index_Multi_Buffer_Closure,
      Gap_Source_Ownership,
      Gap_Project_Unit_Index,
      Gap_Cross_Buffer_Invalidation,
      Gap_Stale_Project_Evidence,
      Gap_Project_Consumer_Agreement,
      Gap_Editor_State_Isolation,
      Gap_Unknown);

   type Source_Origin is
     (Source_None,
      Source_Open_Buffer,
      Source_Project_File,
      Source_Dirty_Open_Buffer,
      Source_Scratch_Buffer,
      Source_Missing_File,
      Source_Deleted_File,
      Source_Duplicate_Unit,
      Source_Unknown);

   type Unit_Role is
     (Role_None,
      Role_Package_Spec,
      Role_Package_Body,
      Role_Subprogram_Spec,
      Role_Subprogram_Body,
      Role_Generic_Spec,
      Role_Generic_Body,
      Role_Child_Unit,
      Role_Private_Child,
      Role_Body_Stub,
      Role_Separate_Subunit,
      Role_Context_Client,
      Role_Unknown);

   type Invalidation_Kind is
     (Invalidation_None,
      Invalidation_Spec_Edit,
      Invalidation_Body_Edit,
      Invalidation_Private_Part_Edit,
      Invalidation_Generic_Spec_Edit,
      Invalidation_Context_Clause_Edit,
      Invalidation_File_Delete_Or_Rename,
      Invalidation_Unrelated_Edit,
      Invalidation_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Open_Buffer_Snapshot_Precedence,
      Status_Legal_Project_Index_Closure,
      Status_Legal_Cross_Buffer_Invalidation,
      Status_Legal_Stable_Unrelated_Edit_Preserved,
      Status_Legal_Missing_File_Blocked,
      Status_Illegal_Disk_Text_Used_For_Open_Buffer,
      Status_Illegal_Scratch_Buffer_Became_Library_Unit,
      Status_Illegal_Missing_File_Treated_As_Empty_Unit,
      Status_Illegal_Duplicate_Library_Unit_Accepted,
      Status_Illegal_Private_Child_Visibility_Leak,
      Status_Illegal_Context_Lookup_Bypassed_Index,
      Status_Illegal_Consumer_Resolved_Cross_Unit_Independently,
      Status_Illegal_Dependent_Spec_Not_Invalidated,
      Status_Illegal_Body_Availability_Not_Invalidated,
      Status_Illegal_Private_View_Not_Invalidated,
      Status_Illegal_Generic_Instances_Not_Invalidated,
      Status_Illegal_File_Identity_Not_Invalidated,
      Status_Illegal_Stale_Project_Index_Row_Used,
      Status_Illegal_Stale_Cross_Unit_Closure_Used,
      Status_Illegal_Stale_Consumer_Feed_Used,
      Status_Illegal_Spec_Body_Pairing_Stale_Reused,
      Status_Illegal_Open_Buffer_Identity_Churn,
      Status_Illegal_Diagnostics_Missing_Blocker_Family,
      Status_Illegal_File_Save_Reload_During_Analysis,
      Status_Illegal_Dirty_State_Mutation,
      Status_Illegal_Rendering_Side_Parsing,
      Status_Illegal_Command_Keybinding_Workspace_Render_Mutation,
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
      Status_Project_Index_Row_Missing,
      Status_Unit_Name_Mismatch,
      Status_Spec_Body_Pairing_Missing,
      Status_Child_Index_Missing,
      Status_Separate_Subunit_Index_Missing,
      Status_Missing_File_Blocker_Missing,
      Status_Open_Buffer_Precedence_Missing,
      Status_Dirty_Buffer_Snapshot_Missing,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Buffer_Fingerprint_Mismatch,
      Status_Project_Fingerprint_Mismatch,
      Status_Index_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Closure_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Unexpected_Classification,
      Status_Multiple_Blockers,
      Status_Indeterminate_Stale_Project_Evidence,
      Status_Indeterminate_Missing_Project_Source,
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
      Source : Source_Origin := Source_Unknown;
      Role : Unit_Role := Role_Unknown;
      Invalidation : Invalidation_Kind := Invalidation_Unknown;
      Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Path : Ada.Strings.Unbounded.Unbounded_String;
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

      Open_Buffer_Precedence : Boolean := True;
      Dirty_Buffer_Uses_Snapshot : Boolean := True;
      Disk_Text_Used_For_Open_Buffer : Boolean := False;
      Scratch_Became_Library_Unit : Boolean := False;
      Missing_File_Treated_As_Empty_Unit : Boolean := False;
      Missing_File_Blocker_Preserved : Boolean := True;

      Project_Index_Row_Present : Boolean := True;
      Unit_Name_Matches_Source : Boolean := True;
      Duplicate_Library_Unit : Boolean := False;
      Duplicate_Unit_Rejected : Boolean := True;
      Spec_Body_Paired : Boolean := True;
      Spec_Body_Pairing_Stale : Boolean := False;
      Child_Index_Present : Boolean := True;
      Private_Child_Visibility_Leaked : Boolean := False;
      Separate_Subunit_Indexed : Boolean := True;
      Context_Lookup_Uses_Index : Boolean := True;
      Consumer_Resolved_Independently : Boolean := False;

      Dependent_Spec_Invalidated : Boolean := True;
      Body_Availability_Invalidated : Boolean := True;
      Private_View_Invalidated : Boolean := True;
      Generic_Instances_Invalidated : Boolean := True;
      File_Identity_Invalidated : Boolean := True;
      Stable_Entity_Identity_Preserved : Boolean := True;
      Stale_Project_Index_Row_Used : Boolean := False;
      Cross_Unit_Closure_Stale : Boolean := False;
      Consumer_Feed_Stale : Boolean := False;

      File_Save_Reload_During_Analysis : Boolean := False;
      Dirty_State_Mutation : Boolean := False;
      Rendering_Side_Parsing : Boolean := False;
      Command_Keybinding_Workspace_Render_Mutation : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Buffer_Fingerprint : Natural := 0;
      Expected_Buffer_Fingerprint : Natural := 0;
      Project_Fingerprint : Natural := 0;
      Expected_Project_Fingerprint : Natural := 0;
      Index_Fingerprint : Natural := 0;
      Expected_Index_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Source : Source_Origin := Source_Unknown;
      Role : Unit_Role := Role_Unknown;
      Invalidation : Invalidation_Kind := Invalidation_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Open_Buffer_Precedence_Count : Natural := 0;
      Project_Index_Count : Natural := 0;
      Invalidation_Count : Natural := 0;
      Missing_File_Blocker_Count : Natural := 0;
      Stable_Preservation_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Illegal_Count : Natural := 0;
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
   function Project_Index_Multi_Buffer_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1363;
