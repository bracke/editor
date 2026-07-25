package Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks is

   procedure Add_Failure
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Field   : String);

   function Surface_Name (Surface : Projection_Surface_Id) return String;

   function Default_Contract
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract;

   function Contract_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Contract;

   function Expected_Prompt_Boundary_Rule_Count return Natural;

   function Prompt_Boundary_Rule_Name
     (Index : Positive) return String;

   function Prompt_Boundary_Rule_Holds
     (Contract : Projection_Surface_Contract;
      Index    : Positive) return Boolean;

   procedure Clear (Result : in out Projection_Surface_Audit_Result);

   procedure Validate_Surface
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);

   function Open_Buffer_Switcher_Shared_Projection_Invariant return Boolean;
   function Quick_Open_Shared_Projection_Invariant return Boolean;
   function Project_Search_Shared_Projection_Invariant return Boolean;
   function Bookmarks_Shared_Projection_Invariant return Boolean;
   function Navigation_History_Shared_Projection_Invariant return Boolean;

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
   procedure Assert_Surface_Render_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Audit_Is_Side_Effect_Free
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);
   procedure Assert_Surface_Behavior_Preserved
     (Result   : in out Projection_Surface_Audit_Result;
      Contract : Projection_Surface_Contract);

   function Failure_Count
     (Result : Projection_Surface_Audit_Result) return Natural;

   function Failure
     (Result : Projection_Surface_Audit_Result;
      Index  : Positive) return String;

   function Summary
     (Result : Projection_Surface_Audit_Result) return String;

end Editor.Projection_Surface_File_Lifecycle_Audit.Surface_Checks;
