with Editor.Projection_Surface_File_Lifecycle_Audit.Adapters;
with Editor.Projection_Surface_File_Lifecycle_Audit.Persistence;
with Editor.Projection_Surface_File_Lifecycle_Audit.Registry;
with Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;

package body Editor.Projection_Surface_File_Lifecycle_Audit is

   function Surface_Name (Surface : Projection_Surface_Id) return String
     renames Surface_Checks.Surface_Name;

   function Default_Contract
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract
     renames Surface_Checks.Default_Contract;

   --  Build the shared contract from the covered surface's own
   --  exported invariant predicates.  This is the reusable adapter seam for
   --  future projection surfaces: product surfaces expose pure observation
   --  predicates; the shared audit folds them into the common contract.
   function Contract_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract
     renames Surface_Checks.Contract_For_Surface;

   function Adapter_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Adapter
     renames Adapters.Adapter_For_Surface;

   function Adapter_Supports_Shared_Harness
     (Adapter : Projection_Surface_Adapter) return Boolean
     renames Adapters.Adapter_Supports_Shared_Harness;

   function Expected_Canonical_Source_Count
     (Surface : Projection_Surface_Id) return Natural
     renames Adapters.Expected_Canonical_Source_Count;

   function Expected_Forbidden_Field_Count
     (Surface : Projection_Surface_Id) return Natural
     renames Adapters.Expected_Forbidden_Field_Count;

   function Expected_Forbidden_Route_Count
     (Surface : Projection_Surface_Id) return Natural
     renames Adapters.Expected_Forbidden_Route_Count;

   function Expected_Forbidden_Render_Field_Count
     (Surface : Projection_Surface_Id) return Natural
     renames Adapters.Expected_Forbidden_Render_Field_Count;

   function Canonical_Source_Name
     (Surface : Projection_Surface_Id;
      Index   : Positive) return String
     renames Adapters.Canonical_Source_Name;

   function Forbidden_Lifecycle_Field_Name
     (Index : Positive) return String
     renames Adapters.Forbidden_Lifecycle_Field_Name;

   function Forbidden_Lifecycle_Route_Name
     (Index : Positive) return String
     renames Adapters.Forbidden_Lifecycle_Route_Name;

   function Forbidden_Rendered_Field_Name
     (Index : Positive) return String
     renames Adapters.Forbidden_Rendered_Field_Name;

   function Cross_Surface_Import_Name
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return String
     renames Persistence.Cross_Surface_Import_Name;

   function Cross_Surface_Import_Forbidden
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return Boolean
     renames Persistence.Cross_Surface_Import_Forbidden;

   function Prompt_Boundary_Rule_Name
     (Index : Positive) return String
     renames Surface_Checks.Prompt_Boundary_Rule_Name;

   function Expected_Prompt_Boundary_Rule_Count return Natural
     renames Surface_Checks.Expected_Prompt_Boundary_Rule_Count;

   function Prompt_Boundary_Rule_Holds
     (Contract : Projection_Surface_Contract;
      Index    : Positive) return Boolean
     renames Surface_Checks.Prompt_Boundary_Rule_Holds;

   function Operation_Name
     (Operation : File_Lifecycle_Operation) return String
     renames Persistence.Operation_Name;

   function Observation_Expectation
     (Operation : File_Lifecycle_Operation)
      return Projection_Surface_Observation_Expectation
     renames Persistence.Observation_Expectation;

   function Observation_Expectation_Coherent
     (Expectation : Projection_Surface_Observation_Expectation) return Boolean
     renames Persistence.Observation_Expectation_Coherent;

   function Surface_Operation_Observation_Coherent
     (Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation) return Boolean
     renames Persistence.Surface_Operation_Observation_Coherent;

   function Lifecycle_Event_Name
     (Event : Projection_Surface_Lifecycle_Event) return String
     renames Persistence.Lifecycle_Event_Name;

   function Lifecycle_Event_Expectation
     (Event : Projection_Surface_Lifecycle_Event)
      return Projection_Surface_Lifecycle_Event_Expectation
     renames Persistence.Lifecycle_Event_Expectation;

   function Lifecycle_Event_Expectation_Coherent
     (Expectation : Projection_Surface_Lifecycle_Event_Expectation) return Boolean
     renames Persistence.Lifecycle_Event_Expectation_Coherent;

   function Surface_Lifecycle_Event_Coherent
     (Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event) return Boolean
     renames Persistence.Surface_Lifecycle_Event_Coherent;

   function Workflow_Context_Name
     (Context : Projection_Surface_Workflow_Context) return String
     renames Persistence.Workflow_Context_Name;

   function Reliability_Family_Name
     (Family : Projection_Surface_Reliability_Family) return String
     renames Persistence.Reliability_Family_Name;

   function Reliability_Expectation
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context)
      return Projection_Surface_Reliability_Expectation
     renames Persistence.Reliability_Expectation;

   function Reliability_Expectation_Coherent
     (Expectation : Projection_Surface_Reliability_Expectation) return Boolean
     renames Persistence.Reliability_Expectation_Coherent;

   function Surface_Reliability_Coherent
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context) return Boolean
     renames Persistence.Surface_Reliability_Coherent;

   function Final_Freeze_Expectation
     (Surface : Projection_Surface_Id)
      return Projection_Surface_Final_Freeze_Expectation
     renames Persistence.Final_Freeze_Expectation;

   function Final_Freeze_Expectation_Coherent
     (Expectation : Projection_Surface_Final_Freeze_Expectation) return Boolean
     renames Persistence.Final_Freeze_Expectation_Coherent;

   function Surface_Final_Freeze_Coherent
     (Surface : Projection_Surface_Id) return Boolean
     renames Persistence.Surface_Final_Freeze_Coherent;

   function Classification_Name
     (Classification : Projection_Surface_Classification) return String
     renames Registry.Classification_Name;

   function Registration_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Registration
     renames Registry.Registration_For_Surface;

   function Surface_Is_Registered
     (Surface : Projection_Surface_Id) return Boolean
     renames Registry.Surface_Is_Registered;

   function Surface_Classification
     (Surface : Projection_Surface_Id) return Projection_Surface_Classification
     renames Registry.Surface_Classification;

   function Projection_Surface_Registration_Coherent
     (Registration : Projection_Surface_Registration) return Boolean
     renames Registry.Projection_Surface_Registration_Coherent;

   function Projection_Surface_Inspection_Lifecycle_Sensitive
     (Inspection : Projection_Surface_Inspection) return Boolean
     renames Registry.Projection_Surface_Inspection_Lifecycle_Sensitive;

   function Projection_Surface_Inspection_Coherent
     (Inspection : Projection_Surface_Inspection) return Boolean
     renames Registry.Projection_Surface_Inspection_Coherent;

   function Build_Future_Surface_Projection_Surface_Adapter
     (Surface        : Projection_Surface_Id;
      Classification : Projection_Surface_Classification)
      return Projection_Surface_Adapter
     renames Registry.Build_Future_Surface_Projection_Surface_Adapter;

   procedure Validate_Projection_Surface_Registration
     (Result       : in out Projection_Surface_Audit_Result;
      Registration : Projection_Surface_Registration)
     renames Registry.Validate_Projection_Surface_Registration;

   procedure Validate_Projection_Surface_Inspection
     (Result     : in out Projection_Surface_Audit_Result;
      Inspection : Projection_Surface_Inspection)
     renames Registry.Validate_Projection_Surface_Inspection;

   procedure Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent;

   function Projection_Surface_Invariant_Adoption_Gate_Coherent
     return Boolean
     renames Persistence.Projection_Surface_Invariant_Adoption_Gate_Coherent;

   function Open_Buffer_Switcher_Shared_Projection_Invariant return Boolean
     renames Surface_Checks.Open_Buffer_Switcher_Shared_Projection_Invariant;

   function Quick_Open_Shared_Projection_Invariant return Boolean
     renames Surface_Checks.Quick_Open_Shared_Projection_Invariant;

   function Project_Search_Shared_Projection_Invariant return Boolean
     renames Surface_Checks.Project_Search_Shared_Projection_Invariant;

   function Bookmarks_Shared_Projection_Invariant return Boolean
     renames Surface_Checks.Bookmarks_Shared_Projection_Invariant;

   function Navigation_History_Shared_Projection_Invariant return Boolean
     renames Surface_Checks.Navigation_History_Shared_Projection_Invariant;

   procedure Clear (Result : in out Projection_Surface_Audit_Result)
     renames Surface_Checks.Clear;

   procedure Validate_Surface
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Validate_Surface;

   procedure Validate_All_Covered_Surfaces
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Validate_All_Covered_Surfaces;

   procedure Validate_Adapter
     (Result  : in out Projection_Surface_Audit_Result;
      Adapter : Projection_Surface_Adapter)
     renames Adapters.Validate_Adapter;

   procedure Validate_Surface_Operation
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation)
     renames Persistence.Validate_Surface_Operation;

   procedure Validate_Surface_Lifecycle_Event
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event)
     renames Persistence.Validate_Surface_Lifecycle_Event;

   procedure Validate_Cross_Surface_Import
     (Result   : in out Projection_Surface_Audit_Result;
      Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id)
     renames Persistence.Validate_Cross_Surface_Import;

   procedure Validate_Surface_Reliability
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Family   : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context  : Projection_Surface_Workflow_Context)
     renames Persistence.Validate_Surface_Reliability;

   procedure Validate_Surface_Final_Freeze
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id)
     renames Persistence.Validate_Surface_Final_Freeze;

   function Surface_Observes_Retained_Sources_Only
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Observes_Retained_Sources_Only;

   function Surface_Does_Not_Own_File_Lifecycle_Routes
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Own_File_Lifecycle_Routes;

   function Surface_Does_Not_Own_Target_Prompt
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Own_Target_Prompt;

   function Surface_Does_Not_Infer_Source_Or_Target
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Infer_Source_Or_Target;

   function Surface_Does_Not_Repair_Associations
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Repair_Associations;

   function Surface_Does_Not_Repair_Retained_Targets
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Repair_Retained_Targets;

   function Surface_Does_Not_Migrate_Targets
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Migrate_Targets;

   function Surface_Does_Not_Probe_Filesystem
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Probe_Filesystem;

   function Surface_Does_Not_Record_Operation_Or_Target_History
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Record_Operation_Or_Target_History;

   function Surface_Does_Not_Cache_Path_Or_Dirty_Observation
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Cache_Path_Or_Dirty_Observation;

   function Surface_Row_Identity_Is_Retained
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Row_Identity_Is_Retained;

   function Surface_Row_Order_Follows_Retained_Policy
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Row_Order_Follows_Retained_Policy;

   function Surface_Local_UI_State_Is_Not_Lifecycle_Input
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Local_UI_State_Is_Not_Lifecycle_Input;

   function Surface_Source_Target_Prompt_Boundary_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Source_Target_Prompt_Boundary_Is_Canonical;

   function Surface_Target_Prompt_Lifecycle_Is_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Target_Prompt_Lifecycle_Is_Canonical;

   function Surface_Activation_Does_Not_Execute_File_Lifecycle
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Activation_Does_Not_Execute_File_Lifecycle;

   function Surface_Does_Not_Import_Projection_Truth
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Import_Projection_Truth;

   function Surface_Does_Not_Persist_Lifecycle_State
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Does_Not_Persist_Lifecycle_State;

   function Surface_Adapter_Is_Raw_And_Nonrepairing
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Adapter_Is_Raw_And_Nonrepairing;

   function Surface_Projection_Helper_Is_Pure
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Projection_Helper_Is_Pure;

   function Surface_Render_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Render_Is_Side_Effect_Free;

   function Surface_Audit_Is_Side_Effect_Free
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Audit_Is_Side_Effect_Free;

   function Surface_Command_Routes_Remain_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Command_Routes_Remain_Canonical;

   function Surface_Persistence_Boundary_Remains_Canonical
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Persistence_Boundary_Remains_Canonical;

   function Surface_Behavior_Preserved
     (Contract : Projection_Surface_Contract) return Boolean
     renames Surface_Checks.Surface_Behavior_Preserved;

   procedure Assert_Surface_Observes_Retained_Sources_Only
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Observes_Retained_Sources_Only;

   procedure Assert_Surface_Does_Not_Own_File_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Does_Not_Own_File_Lifecycle_Routes;

   procedure Assert_Surface_Does_Not_Own_Target_Prompt
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Does_Not_Own_Target_Prompt;

   procedure Assert_Surface_Does_Not_Infer_Source_Or_Target
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Does_Not_Infer_Source_Or_Target;

   procedure Assert_Surface_Does_Not_Persist_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Does_Not_Persist_Lifecycle_State;

   procedure Assert_Surface_Adapter_Is_Raw_And_NonRepairing
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Adapter_Is_Raw_And_NonRepairing;

   procedure Assert_Surface_Projection_Helper_Is_Pure
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Projection_Helper_Is_Pure;

   procedure Assert_Surface_Has_No_Local_Lifecycle_Routes
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Has_No_Local_Lifecycle_Routes;

   procedure Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Has_No_Cross_Surface_Lifecycle_Imports;

   procedure Assert_Render_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Render_Has_No_Projection_Lifecycle_State;

   procedure Assert_Audit_Has_No_Product_Truth_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Audit_Has_No_Product_Truth_State;

   procedure Assert_Persistence_Has_No_Projection_Lifecycle_State
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Persistence_Has_No_Projection_Lifecycle_State;

   procedure Assert_Removed_Projection_Lifecycle_Fields_Dropped
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Removed_Projection_Lifecycle_Fields_Dropped;

   procedure Assert_Shared_Invariant_Coverage_Not_Reduced
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_Shared_Invariant_Coverage_Not_Reduced;

   procedure Assert_Surface_Render_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Render_Is_Side_Effect_Free;

   procedure Assert_Surface_Audit_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Audit_Is_Side_Effect_Free;

   procedure Assert_Surface_Behavior_Preserved
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract)
     renames Surface_Checks.Assert_Surface_Behavior_Preserved;

   procedure Assert_Surface_Lifecycle_Operation_Semantics
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation)
     renames Persistence.Assert_Surface_Lifecycle_Operation_Semantics;

   procedure Assert_Surface_Lifecycle_Event_Semantics
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event)
     renames Persistence.Assert_Surface_Lifecycle_Event_Semantics;

   procedure Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent;

   procedure Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     (Result : in out Projection_Surface_Audit_Result)
     renames Persistence.Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent;

   function Failure_Count
     (Result : Projection_Surface_Audit_Result) return Natural
     renames Surface_Checks.Failure_Count;

   function Failure
     (Result : Projection_Surface_Audit_Result;
      Index  : Positive) return String
     renames Surface_Checks.Failure;

   function Summary
     (Result : Projection_Surface_Audit_Result) return String
     renames Surface_Checks.Summary;

   function File_Lifecycle_Projection_Surface_Milestone_Coherent
     return Boolean
     renames Persistence.File_Lifecycle_Projection_Surface_Milestone_Coherent;

   function File_Lifecycle_Projection_Surface_Reliability_Coherent
     return Boolean
     renames Persistence.File_Lifecycle_Projection_Surface_Reliability_Coherent;

   function File_Lifecycle_Projection_Surface_Cleanup_Coherent
     return Boolean
     renames Persistence.File_Lifecycle_Projection_Surface_Cleanup_Coherent;

   function File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     return Boolean
     renames Persistence.File_Lifecycle_Projection_Surface_Final_Freeze_Coherent;

end Editor.Projection_Surface_File_Lifecycle_Audit;
