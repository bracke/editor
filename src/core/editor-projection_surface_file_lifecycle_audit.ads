with Ada.Strings.Unbounded;

package Editor.Projection_Surface_File_Lifecycle_Audit is

   type Projection_Surface_Id is
     (Open_Buffer_Switcher_Surface,
      Quick_Open_Surface,
      Project_Search_Surface,
      Bookmarks_Surface,
      Navigation_History_Surface);

   type Projection_Surface_Contract is record
      Surface : Projection_Surface_Id := Open_Buffer_Switcher_Surface;
      Observes_Retained_Sources_Only      : Boolean := True;
      No_Duplicate_Lifecycle_State        : Boolean := True;
      No_File_Lifecycle_Routes            : Boolean := True;
      No_Target_Prompt_Ownership          : Boolean := True;
      No_Source_Or_Target_Inference       : Boolean := True;
      No_Association_Repair               : Boolean := True;
      No_Retained_Target_Repair           : Boolean := True;
      No_Target_Migration                 : Boolean := True;
      No_Filesystem_Probe                 : Boolean := True;
      No_Operation_History                : Boolean := True;
      No_Target_History                   : Boolean := True;
      No_Stale_Path_Label_Cache           : Boolean := True;
      No_Dirty_Hint_Cache                 : Boolean := True;
      Row_Identity_Not_Path_Label         : Boolean := True;
      Row_Order_Retained_Policy           : Boolean := True;
      Selection_Query_Local_Only          : Boolean := True;
      Activation_Not_Lifecycle_Command    : Boolean := True;
      No_Cross_Surface_Projection_Imports : Boolean := True;
      Adapter_Raw_Retained_State          : Boolean := True;
      No_Adapter_Lifecycle_Normalization  : Boolean := True;
      Projection_Helpers_Retained_Only    : Boolean := True;
      Projection_Helpers_No_Lifecycle_Inputs : Boolean := True;
      No_Render_Lifecycle_State           : Boolean := True;
      No_Audit_Product_Truth_State        : Boolean := True;
      No_Lifecycle_Persistence_State      : Boolean := True;
      Source_Target_Prompt_Boundary       : Boolean := True;
      Surface_Selected_Row_Not_Source     : Boolean := True;
      Surface_Selected_Row_Not_Target     : Boolean := True;
      Surface_Query_Text_Not_Target       : Boolean := True;
      Surface_Row_Label_Not_Target        : Boolean := True;
      Surface_Retained_Target_Not_Input   : Boolean := True;
      Surface_Prompt_Input_Not_Mutated    : Boolean := True;
      Surface_Does_Not_Open_Target_Prompt : Boolean := True;
      Surface_Does_Not_Confirm_Target_Prompt : Boolean := True;
      Surface_Does_Not_Cancel_Target_Prompt  : Boolean := True;
      Prompt_Confirmation_Executor_Routed    : Boolean := True;
      Prompt_Cancellation_Non_Mutating       : Boolean := True;
      Prompt_Cleanup_Canonical               : Boolean := True;
      Render_Side_Effect_Free             : Boolean := True;
      Render_Consumes_Snapshots_Only      : Boolean := True;
      No_Forbidden_Rendered_Lifecycle_Fields : Boolean := True;
      Audit_Side_Effect_Free              : Boolean := True;
      Audit_Not_Product_Truth             : Boolean := True;
      File_Lifecycle_Commands_Executor_Routed : Boolean := True;
      Command_Invocation_Surface_Canonical    : Boolean := True;
      Persistence_Domains_Separated           : Boolean := True;
      Removed_Lifecycle_Fields_Dropped         : Boolean := True;
      Behavior_Preserved                  : Boolean := True;
   end record;


   type File_Lifecycle_Operation is
     (Save_Operation,
      Save_As_Operation,
      Rename_Operation,
      Copy_Operation,
      Move_Operation,
      Delete_Operation,
      Close_Operation,
      Reopen_Operation,
      Reload_Operation,
      Revert_Operation);

   type Projection_Surface_Observation_Expectation is record
      Operation                         : File_Lifecycle_Operation := Save_Operation;
      Dirty_Follows_Canonical_State     : Boolean := True;
      Association_Follows_Canonical_Update : Boolean := True;
      Row_Identity_Preserved            : Boolean := True;
      Row_Order_Follows_Retained_Policy : Boolean := True;
      No_Surface_Specific_State         : Boolean := True;
      No_Target_History_Created         : Boolean := True;
      No_Failed_Target_Displayed        : Boolean := True;
      Retained_Static_Target_Not_Repaired : Boolean := True;
      Projection_Unchanged_On_Failure   : Boolean := True;
      No_New_Target_Row_From_Operation  : Boolean := True;
      No_Delete_Recovery_Row            : Boolean := True;
      No_Reopen_Candidate_Ownership     : Boolean := True;
      Open_Buffer_Membership_Canonical  : Boolean := True;
      No_Reload_Revert_Surface_State    : Boolean := True;
   end record;

   type Projection_Surface_Lifecycle_Event is
     (Project_Close_Event,
      Project_Switch_Event,
      Project_Reset_Event,
      Workspace_Reload_Event,
      Settings_Load_Event,
      Recent_Projects_Load_Event,
      Keybindings_Load_Event,
      Session_Restart_Event,
      Active_Buffer_Close_Event,
      Target_Prompt_Cleanup_Event,
      Overlay_Supersession_Event,
      Retained_Surface_Load_Save_Event);

   type Projection_Surface_Lifecycle_Event_Expectation is record
      Event                                : Projection_Surface_Lifecycle_Event := Project_Close_Event;
      Transient_UI_Follows_Retained_Cleanup : Boolean := True;
      No_Lifecycle_Observation_State       : Boolean := True;
      No_Target_Or_Operation_History_Survives : Boolean := True;
      No_Prompt_State_Survives             : Boolean := True;
      Canonical_Open_Buffer_Policy_Only    : Boolean := True;
      Retained_Surface_Persistence_Only    : Boolean := True;
      Failed_Transition_Does_Not_Create_State : Boolean := True;
   end record;

   type Projection_Surface_Workflow_Context is
     (Surface_Hidden_Context,
      Surface_Visible_Context,
      Surface_Visible_Selected_Row_Context,
      Surface_Visible_Path_Like_Selected_Row_Context,
      Surface_Visible_Query_Filter_Context,
      Surface_Visible_Current_Row_Context,
      All_Surfaces_Co_Visible_Context);

   type Projection_Surface_Reliability_Family is
     (Successful_Operation_Reliability,
      Failed_Blocked_Operation_Preservation,
      Source_Target_Boundary_Reliability,
      Prompt_Boundary_Reliability,
      Direct_Prompted_Equivalence_Reliability,
      Cross_Surface_Co_Visibility_Reliability,
      Snapshot_Freshness_Reliability,
      Render_Side_Effect_Reliability,
      Route_Audit_Reliability,
      Lifecycle_Cleanup_Reliability,
      Persistence_Exclusion_Reliability);

   type Projection_Surface_Reliability_Expectation is record
      Surface                         : Projection_Surface_Id := Open_Buffer_Switcher_Surface;
      Family                          : Projection_Surface_Reliability_Family := Successful_Operation_Reliability;
      Operation                       : File_Lifecycle_Operation := Save_Operation;
      Context                         : Projection_Surface_Workflow_Context := Surface_Hidden_Context;
      Adapter_Complete                : Boolean := True;
      Successful_Observation          : Boolean := True;
      Failure_Preservation            : Boolean := True;
      Source_Target_Boundary          : Boolean := True;
      Prompt_Boundary                 : Boolean := True;
      Direct_Prompted_Equivalence     : Boolean := True;
      Cross_Surface_Co_Visibility     : Boolean := True;
      Snapshot_Freshness              : Boolean := True;
      Render_Reliability              : Boolean := True;
      Audit_Reliability               : Boolean := True;
      Lifecycle_Cleanup               : Boolean := True;
      Persistence_Exclusion           : Boolean := True;
      Behavior_Preserved              : Boolean := True;
   end record;


   type Projection_Surface_Final_Freeze_Expectation is record
      Surface                              : Projection_Surface_Id := Open_Buffer_Switcher_Surface;
      Shared_Invariant_Single_Authority    : Boolean := True;
      Coverage_Not_Reduced                 : Boolean := True;
      Adapter_Raw_State_Frozen             : Boolean := True;
      Projection_Helper_Purity_Frozen      : Boolean := True;
      Successful_Observation_Frozen        : Boolean := True;
      Failed_Blocked_Preservation_Frozen   : Boolean := True;
      Direct_Prompted_Equivalence_Frozen   : Boolean := True;
      Source_Target_Prompt_Boundary_Frozen : Boolean := True;
      Activation_Boundary_Frozen           : Boolean := True;
      Cross_Surface_Import_Absent_Frozen   : Boolean := True;
      Render_Boundary_Frozen               : Boolean := True;
      Audit_Boundary_Frozen                : Boolean := True;
      Lifecycle_Cleanup_Frozen             : Boolean := True;
      Persistence_Exclusion_Frozen         : Boolean := True;
      Removed_Field_Drop_Frozen             : Boolean := True;
      Duplicate_Ownership_Absent_Frozen    : Boolean := True;
      Behavior_Preserved                   : Boolean := True;
   end record;


   type Projection_Surface_Classification is
     (Projection_Surface_None,
      Projection_Surface_File_Like,
      Projection_Surface_Buffer_Like,
      Projection_Surface_Path_Like,
      Projection_Surface_Target_Like,
      Projection_Surface_Candidate_Like,
      Projection_Surface_Result_Like,
      Projection_Surface_Bookmark_Like,
      Projection_Surface_History_Like,
      Projection_Surface_Mixed);

   type Projection_Surface_Audit_Result is private;

   type Projection_Surface_Adapter is record
      Surface                    : Projection_Surface_Id := Open_Buffer_Switcher_Surface;
      Has_Visibility_State        : Boolean := True;
      Has_Row_Projection          : Boolean := True;
      Has_Row_Identity            : Boolean := True;
      Has_Row_Label               : Boolean := True;
      Has_Selected_Or_Current_State : Boolean := True;
      Has_Query_State             : Boolean := True;
      Has_Dirty_Hint_State        : Boolean := True;
      Has_Retained_Target_State   : Boolean := True;
      Has_Retained_Source_Snapshot : Boolean := True;
      Has_Forbidden_Field_List    : Boolean := True;
      Has_Forbidden_Route_List    : Boolean := True;
      Has_Persistence_Output      : Boolean := True;
      Has_Prompt_Ownership_Metadata : Boolean := True;
      Has_Cross_Surface_Import_Metadata : Boolean := True;
      Has_Snapshot_Freshness_Metadata : Boolean := True;
      Exposes_Raw_Retained_State    : Boolean := True;
      No_Path_Label_Normalization   : Boolean := True;
      No_Dirty_Hint_Normalization   : Boolean := True;
      No_Inferred_Target_Reconstruction : Boolean := True;
      No_Command_Execution          : Boolean := True;
      No_Prompt_Control             : Boolean := True;
      No_Filesystem_Probe           : Boolean := True;
      No_Row_Repair                 : Boolean := True;
      No_Cross_Surface_Row_Lookup   : Boolean := True;
      No_Persistence_Field_Filtering : Boolean := True;
      Has_Projection_Helper_Metadata : Boolean := True;
      Projection_Helpers_Pure       : Boolean := True;
      Canonical_Source_Count       : Natural := 0;
      Forbidden_Field_Count        : Natural := 0;
      Forbidden_Route_Count        : Natural := 0;
      Forbidden_Render_Field_Count : Natural := 0;
   end record;


   type Projection_Surface_Registration is record
      Surface                         : Projection_Surface_Id := Open_Buffer_Switcher_Surface;
      Classification                  : Projection_Surface_Classification := Projection_Surface_None;
      Is_Registered                   : Boolean := True;
      Rows_May_Contain_Buffer_Identity : Boolean := False;
      Rows_May_Contain_Retained_Target : Boolean := False;
      Rows_May_Contain_Path_File_Labels : Boolean := False;
      Rows_May_Contain_Dirty_Hints    : Boolean := False;
      Rows_May_Contain_Current_Markers : Boolean := False;
      Has_Query_Or_Filter_Text        : Boolean := False;
      Has_Selected_Or_Current_Row     : Boolean := True;
      Has_Activation_Behavior         : Boolean := True;
      Has_Retained_Persistence        : Boolean := False;
      Has_Surface_Adapter_Factory     : Boolean := True;
      Has_Forbidden_Field_Metadata    : Boolean := True;
      Has_Forbidden_Route_Metadata    : Boolean := True;
      Has_Persistence_Inspection_Hook : Boolean := True;
      Has_Render_Snapshot_Inspection_Hook : Boolean := True;
      Runs_Shared_Invariant_Harness   : Boolean := True;
   end record;

   type Projection_Surface_Inspection is record
      Registered                      : Boolean := False;
      Classification                  : Projection_Surface_Classification := Projection_Surface_None;
      Exposes_Buffer_Identity         : Boolean := False;
      Exposes_Retained_Target         : Boolean := False;
      Exposes_Path_File_Label         : Boolean := False;
      Exposes_Dirty_Hint              : Boolean := False;
      Exposes_Current_Or_Open_Marker  : Boolean := False;
      Exposes_Candidate_Result_Target : Boolean := False;
      Exposes_Bookmark_Or_History_Target : Boolean := False;
      Has_Local_Lifecycle_Route       : Boolean := False;
      Has_Target_Prompt_Ownership     : Boolean := False;
      Has_Source_Override_Or_Target_Inference : Boolean := False;
      Has_Repair_Migration_Or_Probe   : Boolean := False;
      Has_Cross_Surface_Import        : Boolean := False;
      Has_Retained_Persistence        : Boolean := False;
      Has_Lifecycle_Persistence_Field : Boolean := False;
      Has_Explicit_Audit_Exemption    : Boolean := False;
   end record;

   function Surface_Name (Surface : Projection_Surface_Id) return String;

   function Default_Contract
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract;

   --  Build the shared contract from the covered surface's own
   --  exported invariant predicates.  This is the reusable adapter seam for
   --  future projection surfaces: product surfaces expose pure observation
   --  predicates; the shared audit folds them into the common contract.
   function Contract_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract;

   function Adapter_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Adapter;

   function Adapter_Supports_Shared_Harness
     (Adapter : Projection_Surface_Adapter) return Boolean;

   function Expected_Canonical_Source_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Field_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Route_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Render_Field_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Canonical_Source_Name
     (Surface : Projection_Surface_Id;
      Index   : Positive) return String;

   function Forbidden_Lifecycle_Field_Name
     (Index : Positive) return String;

   function Forbidden_Lifecycle_Route_Name
     (Index : Positive) return String;

   function Forbidden_Rendered_Field_Name
     (Index : Positive) return String;

   function Cross_Surface_Import_Name
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return String;

   function Cross_Surface_Import_Forbidden
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return Boolean;

   function Prompt_Boundary_Rule_Name
     (Index : Positive) return String;

   function Expected_Prompt_Boundary_Rule_Count return Natural;

   function Prompt_Boundary_Rule_Holds
     (Contract : Projection_Surface_Contract;
      Index    : Positive) return Boolean;

   function Operation_Name
     (Operation : File_Lifecycle_Operation) return String;

   function Observation_Expectation
     (Operation : File_Lifecycle_Operation)
      return Projection_Surface_Observation_Expectation;

   function Observation_Expectation_Coherent
     (Expectation : Projection_Surface_Observation_Expectation) return Boolean;

   function Surface_Operation_Observation_Coherent
     (Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation) return Boolean;

   function Lifecycle_Event_Name
     (Event : Projection_Surface_Lifecycle_Event) return String;

   function Lifecycle_Event_Expectation
     (Event : Projection_Surface_Lifecycle_Event)
      return Projection_Surface_Lifecycle_Event_Expectation;

   function Lifecycle_Event_Expectation_Coherent
     (Expectation : Projection_Surface_Lifecycle_Event_Expectation) return Boolean;

   function Surface_Lifecycle_Event_Coherent
     (Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event) return Boolean;

   function Workflow_Context_Name
     (Context : Projection_Surface_Workflow_Context) return String;

   function Reliability_Family_Name
     (Family : Projection_Surface_Reliability_Family) return String;

   function Reliability_Expectation
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context)
      return Projection_Surface_Reliability_Expectation;

   function Reliability_Expectation_Coherent
     (Expectation : Projection_Surface_Reliability_Expectation) return Boolean;

   function Surface_Reliability_Coherent
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context) return Boolean;

   function Final_Freeze_Expectation
     (Surface : Projection_Surface_Id)
      return Projection_Surface_Final_Freeze_Expectation;

   function Final_Freeze_Expectation_Coherent
     (Expectation : Projection_Surface_Final_Freeze_Expectation) return Boolean;

   function Surface_Final_Freeze_Coherent
     (Surface : Projection_Surface_Id) return Boolean;


   function Classification_Name
     (Classification : Projection_Surface_Classification) return String;

   function Registration_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Registration;

   function Surface_Is_Registered
     (Surface : Projection_Surface_Id) return Boolean;

   function Surface_Classification
     (Surface : Projection_Surface_Id) return Projection_Surface_Classification;

   function Projection_Surface_Registration_Coherent
     (Registration : Projection_Surface_Registration) return Boolean;

   function Projection_Surface_Inspection_Lifecycle_Sensitive
     (Inspection : Projection_Surface_Inspection) return Boolean;

   function Projection_Surface_Inspection_Coherent
     (Inspection : Projection_Surface_Inspection) return Boolean;

   function Build_Future_Surface_Projection_Surface_Adapter
     (Surface        : Projection_Surface_Id;
      Classification : Projection_Surface_Classification)
      return Projection_Surface_Adapter;

   procedure Validate_Projection_Surface_Registration
     (Result       : in out Projection_Surface_Audit_Result;
      Registration : Projection_Surface_Registration);

   procedure Validate_Projection_Surface_Inspection
     (Result     : in out Projection_Surface_Audit_Result;
      Inspection : Projection_Surface_Inspection);

   procedure Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   function Projection_Surface_Invariant_Adoption_Gate_Coherent
     return Boolean;


   function Open_Buffer_Switcher_Shared_Projection_Invariant return Boolean;
   function Quick_Open_Shared_Projection_Invariant return Boolean;
   function Project_Search_Shared_Projection_Invariant return Boolean;
   function Bookmarks_Shared_Projection_Invariant return Boolean;
   function Navigation_History_Shared_Projection_Invariant return Boolean;

   procedure Clear (Result : in out Projection_Surface_Audit_Result);

   procedure Validate_Surface
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);

   procedure Validate_All_Covered_Surfaces
     (Result : in out Projection_Surface_Audit_Result);

   procedure Validate_Adapter
     (Result  : in out Projection_Surface_Audit_Result;
      Adapter : Projection_Surface_Adapter);

   procedure Validate_Surface_Operation
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation);

   procedure Validate_Surface_Lifecycle_Event
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event);

   procedure Validate_Cross_Surface_Import
     (Result   : in out Projection_Surface_Audit_Result;
      Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id);

   procedure Validate_Surface_Reliability
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Family   : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context  : Projection_Surface_Workflow_Context);

   procedure Validate_Surface_Final_Freeze
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id);

   function Surface_Observes_Retained_Sources_Only
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Own_File_Lifecycle_Routes
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Own_Target_Prompt
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Infer_Source_Or_Target
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Repair_Associations
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Repair_Retained_Targets
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Migrate_Targets
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Probe_Filesystem
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Record_Operation_Or_Target_History
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Cache_Path_Or_Dirty_Observation
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Row_Identity_Is_Retained
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Row_Order_Follows_Retained_Policy
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Local_UI_State_Is_Not_Lifecycle_Input
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Source_Target_Prompt_Boundary_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Target_Prompt_Lifecycle_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Activation_Does_Not_Execute_File_Lifecycle
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Import_Projection_Truth
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Does_Not_Persist_Lifecycle_State
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Adapter_Is_Raw_And_Nonrepairing
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Projection_Helper_Is_Pure
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Render_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Audit_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Command_Routes_Remain_Canonical
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Persistence_Boundary_Remains_Canonical
     (Contract : Projection_Surface_Contract) return Boolean;
   function Surface_Behavior_Preserved
     (Contract : Projection_Surface_Contract) return Boolean;

   procedure Assert_Surface_Observes_Retained_Sources_Only
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Does_Not_Own_File_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Does_Not_Own_Target_Prompt
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Does_Not_Infer_Source_Or_Target
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Does_Not_Persist_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Adapter_Is_Raw_And_NonRepairing
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Projection_Helper_Is_Pure
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Has_No_Local_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Render_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Audit_Has_No_Product_Truth_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Persistence_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Removed_Projection_Lifecycle_Fields_Dropped
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Shared_Invariant_Coverage_Not_Reduced
     (Result : in out Projection_Surface_Audit_Result);
   procedure Assert_Surface_Render_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Audit_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Behavior_Preserved
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Lifecycle_Operation_Semantics
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation);
   procedure Assert_Surface_Lifecycle_Event_Semantics
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event);
   procedure Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   function Failure_Count
     (Result : Projection_Surface_Audit_Result) return Natural;

   function Failure
     (Result : Projection_Surface_Audit_Result;
      Index  : Positive) return String;

   function Summary
     (Result : Projection_Surface_Audit_Result) return String;

   function File_Lifecycle_Projection_Surface_Milestone_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Reliability_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Cleanup_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     return Boolean;

private
   use Ada.Strings.Unbounded;

   type Failure_Array is array (Positive range 1 .. 256) of Unbounded_String;

   type Projection_Surface_Audit_Result is record
      Count    : Natural := 0;
      Failures : Failure_Array := (others => Null_Unbounded_String);
   end record;

end Editor.Projection_Surface_File_Lifecycle_Audit;
