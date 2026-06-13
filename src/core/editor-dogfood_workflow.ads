package Editor.Dogfood_Workflow is

   Dogfood_Fixture_Relative_Root : constant String :=
     "tests/fixtures/dogfood_project";

   type Dogfood_Surface is
     (Dogfood_Surface_File_Tree,
      Dogfood_Surface_Quick_Open,
      Dogfood_Surface_Project_Search,
      Dogfood_Surface_Outline,
      Dogfood_Surface_Diagnostics,
      Dogfood_Surface_Build,
      Dogfood_Surface_Editing,
      Dogfood_Surface_Command_Palette,
      Dogfood_Surface_Persistence);

   type Dogfood_State is
     (Dogfood_State_Ready,
      Dogfood_State_No_Project,
      Dogfood_State_No_Selection,
      Dogfood_State_Empty,
      Dogfood_State_Stale,
      Dogfood_State_Target_Unavailable,
      Dogfood_State_Consent_Missing,
      Dogfood_State_Succeeded,
      Dogfood_State_Failed);

   --  Phase 536 dogfood usability labels are pure display helpers.  They do
   --  not inspect files, refresh state, parse buffers, run builds, repair
   --  persistence, or mutate the editor.  They centralize the first layer of
   --  practical dogfood wording so command outcomes and disabled reasons can
   --  name the surface, prerequisite, and next useful action.
   function Dogfood_Status_Label
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String;

   function Dogfood_Unavailable_Reason_Label
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String;

   function Dogfood_Label_Is_User_Readable (Label : String) return Boolean;

   function Assert_Dogfood_Messages_User_Readable return Boolean;

   function Assert_Dogfood_Focus_Transitions_Coherent return Boolean;

   function Assert_Dogfood_Usability_Fixes_Coherent
     (Workspace_Text : String) return Boolean;


   type Startup_Surface is
     (Startup_Project,
      Startup_Active_Buffer,
      Startup_File_Tree,
      Startup_Quick_Open,
      Startup_Project_Search,
      Startup_Diagnostics,
      Startup_Outline,
      Startup_Build,
      Startup_Command_Palette,
      Startup_Recent_Projects);

   type Workspace_Reload_State is
     (Workspace_Loaded,
      Workspace_Saved,
      Workspace_No_Project_To_Restore,
      Workspace_Some_Files_Not_Reopened,
      Workspace_Unsupported_Fields_Ignored);

   --  Phase 537 milestone-readiness helpers.  These are pure policy and
   --  fixture-audit helpers: they do not open projects, reload workspaces,
   --  refresh project surfaces, execute commands, render, or write
   --  persistence files.
   function Startup_State_Label
     (Surface : Startup_Surface) return String;

   function First_Run_Command_Disabled_Reason
     (Surface : Dogfood_Surface;
      State   : Dogfood_State) return String;

   function Workspace_Reload_User_Message
     (State : Workspace_Reload_State) return String;

   function Assert_Fresh_Startup_Coherent return Boolean;

   function Assert_First_Run_Command_Surface_Coherent return Boolean;

   function Assert_Recent_Project_Does_Not_Restore_Transient_State
     (Recent_Project_Text : String) return Boolean;

   function Assert_Workspace_Reload_Minimal
     (Workspace_Text : String) return Boolean;

   function Assert_Dogfood_Repeatable
     (First_Run_Workspace_Text  : String;
      Second_Run_Workspace_Text : String) return Boolean;

   function Assert_Product_Artifacts_No_Demo_State
     (Product_Text : String) return Boolean;

   function Assert_Default_Keybindings_Safe
     (Keybindings_Text : String) return Boolean;

   function Assert_Milestone_Startup_And_Dogfood_Readiness_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean;



   type Recent_Project_Open_State is
     (Recent_Project_Opened,
      Recent_Project_Unavailable,
      Recent_Project_Path_Missing,
      Recent_Project_Open_Failed);

   type Stale_Target_Surface is
     (Stale_Target_File_Tree,
      Stale_Target_Quick_Open,
      Stale_Target_Project_Search,
      Stale_Target_Outline,
      Stale_Target_Diagnostics,
      Stale_Target_Build);

   type Project_Dirty_Guard_State is
     (Project_Dirty_Guard_Allows,
      Project_Dirty_Guard_Blocked_Switch,
      Project_Dirty_Guard_Blocked_Close,
      Project_Dirty_Guard_Cancelled);

   --  Phase 538 repeated-local-use helpers.  These pure helpers centralize
   --  the user-readable labels and audit predicates used when stale recent
   --  projects, workspace reloads, project switches, and stale activation
   --  attempts are exercised repeatedly across sessions.
   function Recent_Project_Open_Result_Label
     (State : Recent_Project_Open_State) return String;

   function Workspace_Reload_Recovery_Label
     (State : Workspace_Reload_State) return String;

   function Project_Switch_Dirty_Guard_Label
     (State : Project_Dirty_Guard_State) return String;

   function Stale_Target_Activation_Label
     (Surface : Stale_Target_Surface) return String;

   function Assert_Repeated_Startup_Coherent return Boolean;

   function Assert_Recent_Project_Uses_Project_Lifecycle
     (Recent_Project_Text : String) return Boolean;

   function Assert_Workspace_Reload_Does_Not_Restore_Transient_State
     (Workspace_Text : String) return Boolean;

   function Assert_Project_Close_Clears_Project_Scoped_State return Boolean;

   function Assert_Dogfood_Repeated_Use_Coherent
     (First_Run_Workspace_Text  : String;
      Second_Run_Workspace_Text : String) return Boolean;

   function Assert_Repeated_Local_Use_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean;



   type Integrated_Workflow_Condition is
     (Workflow_No_Project_Open,
      Workflow_No_Active_Buffer,
      Workflow_No_Buffer_Selected,
      Workflow_No_File_Selected,
      Workflow_Target_Stale,
      Workflow_Target_No_Longer_Exists,
      Workflow_Backing_File_No_Longer_Exists,
      Workflow_Unsaved_Changes_Require_Confirmation,
      Workflow_Confirmation_Pending,
      Workflow_No_Search_Query,
      Workflow_No_Search_Results,
      Workflow_No_Build_Request,
      Workflow_No_Diagnostics);

   type Integrated_Workflow_Action is
     (Workflow_Open_Project_Succeeded,
      Workflow_File_Tree_File_Activated,
      Workflow_Quick_Open_File_Activated,
      Workflow_Search_Result_Activated,
      Workflow_Outline_Target_Activated,
      Workflow_Diagnostic_Target_Activated,
      Workflow_Build_Diagnostics_Revealed,
      Workflow_Prompt_Cancelled,
      Workflow_Command_Failed);

   type Integrated_Focus_Result is
     (Focus_Result_Editor,
      Focus_Result_File_Tree,
      Focus_Result_Search_Results,
      Focus_Result_Outline,
      Focus_Result_Diagnostics,
      Focus_Result_Build_Output,
      Focus_Result_Empty_State,
      Focus_Result_Originating_Surface,
      Focus_Result_Correction_Surface);

   type Integrated_Surface_Event is
     (Workflow_Event_Project_Opened,
      Workflow_Event_Project_Switched,
      Workflow_Event_File_Created,
      Workflow_Event_File_Renamed,
      Workflow_Event_File_Deleted,
      Workflow_Event_Buffer_Edited,
      Workflow_Event_Buffer_Saved,
      Workflow_Event_Buffer_Reloaded,
      Workflow_Event_Build_Finished);

   type Integrated_Surface_Disposition is
     (Workflow_Surface_Unchanged,
      Workflow_Surface_Refresh_Required,
      Workflow_Surface_Marked_Stale,
      Workflow_Surface_Cleared,
      Workflow_Surface_Recomputed_By_Explicit_Command);

   --  Phase 578 product workflow labels.  These helpers intentionally model
   --  only user-visible policy: they do not inspect files, open projects,
   --  refresh surfaces, run builds, mutate prompts, or write persistence.
   function Integrated_Workflow_Message
     (Condition : Integrated_Workflow_Condition) return String;

   function Integrated_Focus_After_Action
     (Action : Integrated_Workflow_Action) return Integrated_Focus_Result;

   function Integrated_Focus_Result_Label
     (Result : Integrated_Focus_Result) return String;

   function Integrated_Surface_Disposition_After
     (Event   : Integrated_Surface_Event;
      Surface : Dogfood_Surface) return Integrated_Surface_Disposition;

   function Integrated_Surface_Disposition_Label
     (Disposition : Integrated_Surface_Disposition) return String;

   function Assert_Phase578_Message_Consistency return Boolean;

   function Assert_Phase578_Focus_Policy_Coherent return Boolean;

   function Assert_Phase578_Surface_Dispositions_Coherent return Boolean;

   function Assert_Phase578_Workflow_Polish_Coherent
     (Workspace_Text      : String;
      Recent_Project_Text : String;
      Keybindings_Text    : String;
      Product_Text        : String) return Boolean;


   type Product_Workflow_Step is
     (Product_Empty_Editor_State,
      Product_Open_Project,
      Product_Open_File_From_File_Tree,
      Product_Open_File_From_Quick_Open,
      Product_Edit_Buffer,
      Product_Save_Buffer,
      Product_Reload_Buffer,
      Product_Revert_Buffer,
      Product_Create_File,
      Product_Create_Directory,
      Product_Rename_File_Or_Directory,
      Product_Delete_File_Or_Directory,
      Product_Search_Project,
      Product_Navigate_Search_Result,
      Product_View_Outline,
      Product_Run_Build,
      Product_Inspect_Build_Output,
      Product_Inspect_Diagnostics,
      Product_Switch_Buffers,
      Product_Close_Active_Buffer,
      Product_Close_Project,
      Product_Switch_Project,
      Product_Restore_Workspace,
      Product_Quit_Safely);

   --  Phase 579 product workflow reference.  These helpers are the small
   --  command/test reference for the daily editor loop; they do not execute
   --  commands, repair state, run build tools, or introduce new workflows.
   function Product_Workflow_Command
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Label
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Success_Message
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Failure_Message
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Success_Status
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Failure_Status
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Focus_Result
     (Step : Product_Workflow_Step) return Integrated_Focus_Result;

   function Product_Workflow_Dirty_Buffer_Behavior
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Prompt_Title
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Cancel_Status
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Persistence_Effect
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_File_Buffer_Effect
     (Step : Product_Workflow_Step) return String;

   function Product_Workflow_Panel_Effect
     (Step : Product_Workflow_Step) return String;

   function Product_Label_Contains_Internal_Term
     (Label : String) return Boolean;

   function Assert_Phase579_Product_Workflow_Reference_Coherent
     return Boolean;

   function Assert_Phase579_Product_Messages_User_Readable
     return Boolean;

   function Assert_Phase579_Product_Focus_Policy_Coherent
     return Boolean;

   function Assert_Phase579_Product_Prompt_Policy_Coherent
     return Boolean;

   function Assert_Phase579_Product_File_Buffer_Coherent
     return Boolean;

   function Assert_Phase579_Product_Navigation_Coherent
     return Boolean;

   function Assert_Phase579_Product_Build_Diagnostics_Coherent
     return Boolean;

   function Assert_Phase579_Product_Workspace_Restore_Coherent
     return Boolean;

   function Assert_Phase579_Product_Surface_Coherent
     (Product_Text : String) return Boolean;

   --  Phase 535 dogfood milestone helper.  The persisted workspace text must
   --  contain only retained structural session data.  This predicate is
   --  side-effect-free: it does not parse project files, inspect runtime state,
   --  repair persistence, render, refresh, or execute commands.
   function Assert_Dogfood_Transient_State_Not_Persisted
     (Workspace_Text : String) return Boolean;

end Editor.Dogfood_Workflow;
