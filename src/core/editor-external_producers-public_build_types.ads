with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;

package Editor.External_Producers.Public_Build_Types is

   type Public_Build_Consent_Source is
     (Public_Build_Consent_None,
      Public_Build_Consent_Test_Context,
      Public_Build_Consent_User_Form_Acknowledged);

   type Public_Build_Consent_Model is record
      Source : Public_Build_Consent_Source := Public_Build_Consent_None;
      User_Acknowledged_Execution : Boolean := False;
      User_Acknowledged_No_Shell : Boolean := False;
      User_Acknowledged_External_Process : Boolean := False;
      User_Acknowledged_Diagnostics_Output : Boolean := False;
   end record;

   type Public_Build_Consent_Validation_Status is
     (Public_Build_Consent_Valid_For_Internal_Test,
      Public_Build_Consent_Valid_But_Not_Public_UX,
      Public_Build_Consent_Rejected_None,
      Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement,
      Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement,
      Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement,
      Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement);

   --  public-build working-context UX scaffold. This is inert
   --  future-UX metadata only. It is not a directory picker, filesystem path
   --  validator, command descriptor, persisted preference, project-root
   --  discovery mechanism, or execution request.
   type Public_Build_Working_Context_Source is
     (Public_Build_Working_Context_None,
      Public_Build_Working_Context_Test_Context,
      Public_Build_Working_Context_User_Form_Label,
      Public_Build_Working_Context_Project_Derived);

   type Public_Build_Working_Context_Model is record
      Source : Public_Build_Working_Context_Source :=
        Public_Build_Working_Context_None;
      Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      User_Acknowledged_Context : Boolean := False;
   end record;

   type Public_Build_Working_Context_Validation_Status is
     (Public_Build_Working_Context_Valid_For_Internal_Test,
      Public_Build_Working_Context_Valid_But_Not_Public_UX,
      Public_Build_Working_Context_Rejected_None,
      Public_Build_Working_Context_Rejected_Project_Derived,
      Public_Build_Working_Context_Rejected_Missing_Label,
      Public_Build_Working_Context_Rejected_Missing_Acknowledgement,
      Public_Build_Working_Context_Rejected_Unsafe_Label);

   type Public_Build_Input_Source is
     (Public_Build_Input_None,
      Public_Build_Input_User_Form,
      Public_Build_Input_Test_Context);

   type Public_Build_Command_Input is record
      Source           : Public_Build_Input_Source := Public_Build_Input_None;
      Tool             : Build_Tool_Kind := No_Build_Tool;
      Program_Label    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Context  : Build_Working_Context :=
        (Kind  => Build_Working_Context_Unsupported,
         Label => Ada.Strings.Unbounded.Null_Unbounded_String);
      Working_Context_Model : Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Ada.Strings.Unbounded.Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Arguments        : Process_Argument_Vector :=
        Process_Argument_Vectors.Empty_Vector;
      Consent          : Build_Execution_Consent := Build_Consent_Not_Provided;
      Consent_Model    : Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_None,
         User_Acknowledged_Execution => False,
         User_Acknowledged_No_Shell => False,
         User_Acknowledged_External_Process => False,
         User_Acknowledged_Diagnostics_Output => False);
      Show_Diagnostics : Boolean := False;
   end record;

   type Public_Build_Input_Validation_Status is
     (Public_Build_Input_Valid,
      Public_Build_Input_Rejected_No_Input,
      Public_Build_Input_Rejected_Public_Not_Ready,
      Public_Build_Input_Rejected_No_Tool,
      Public_Build_Input_Rejected_Custom_Tool,
      Public_Build_Input_Rejected_Missing_Program,
      Public_Build_Input_Rejected_Missing_Consent,
      Public_Build_Input_Rejected_Test_Only_Consent,
      Public_Build_Input_Rejected_Unsupported_Working_Context,
      Public_Build_Input_Rejected_Unsafe_Working_Context,
      Public_Build_Input_Rejected_Empty_Argument,
      Public_Build_Input_Rejected_Control_Argument,
      Public_Build_Input_Rejected_Opaque_Arguments,
      Public_Build_Input_Rejected_Shell);

   type Public_Build_Input_Safety is
     (Public_Build_Input_Not_Valid,
      Public_Build_Input_Valid_For_Internal_Test,
      Public_Build_Input_Valid_But_Not_Publicly_Exposable,
      Public_Build_Input_Publicly_Exposable);

   --  public build command-surface surface entrys are design-only
   --  metadata.  They are not command descriptors, registry entries,
   --  keybinding targets, palette rows, Executor routes, persisted state, or
   --  Public build command-surface metadata.  These entries describe actual
   --  public build commands that have descriptors, palette visibility,
   --  Executor routing, structured input, explicit consent, and working-context
   --  validation.  The metadata remains audit-only and does not persist
   --  transient command state.
   type Public_Build_Command_Surface_Entry is record
      Stable_Id : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Descriptor : Boolean := False;
      Has_Input_Model : Boolean := False;
      Has_Consent_Model : Boolean := False;
      Has_Working_Context_Model : Boolean := False;
      Publicly_Invokable : Boolean := False;
      Routes_Through_Executor : Boolean := False;
   end record;

   type Public_Build_Command_Surface_Status is
     (Public_Build_Command_Surface_Valid,
      Public_Build_Command_Surface_Rejected_Empty_Id,
      Public_Build_Command_Surface_Rejected_Missing_Descriptor,
      Public_Build_Command_Surface_Rejected_Default_Keybinding,
      Public_Build_Command_Surface_Rejected_Not_Publicly_Invokable,
      Public_Build_Command_Surface_Rejected_Missing_Input_Model,
      Public_Build_Command_Surface_Rejected_Missing_Consent_Model,
      Public_Build_Command_Surface_Rejected_Missing_Working_Context_Model,
      Public_Build_Command_Surface_Rejected_Missing_Executor_Route);

   --  promotion gate. This is a pure readiness classifier for the guarded
   --  public build surface; it may report ready only after the explicit
   --  request policy, consent UX, working-context UX, command exposure,
   --  executor route, and keybinding guardrails all pass.
   type Public_Build_Command_Promotion_Status is
     (Public_Build_Promotion_Blocked,
      Public_Build_Promotion_Unsafe_Exposure_Detected,
      Public_Build_Promotion_Input_Model_Incomplete,
      Public_Build_Promotion_Consent_UX_Incomplete,
      Public_Build_Promotion_Working_Context_UX_Incomplete,
      Public_Build_Promotion_Implicit_Source_Unsupported,
      Public_Build_Promotion_Execution_Policy_Incomplete,
      Public_Build_Promotion_Public_Executor_Route_Missing,
      Public_Build_Promotion_Command_Surface_Ready);

   type Public_Build_UX_Dependency is
     (Public_Build_Dependency_Input_Model,
      Public_Build_Dependency_Structured_Argv,
      Public_Build_Dependency_Consent_Model,
      Public_Build_Dependency_Consent_UX,
      Public_Build_Dependency_Working_Context_Model,
      Public_Build_Dependency_Working_Context_UX,
      Public_Build_Dependency_Implicit_Source_Policy,
      Public_Build_Dependency_Execution_Policy,
      Public_Build_Dependency_Executor_Route,
      Public_Build_Dependency_Diagnostics_Pipeline,
      Public_Build_Dependency_Command_Result_Policy,
      Public_Build_Dependency_Availability_Purity,
      Public_Build_Dependency_No_Persistence);

   type Public_Build_UX_Dependency_Status is
     (Dependency_Satisfied,
      Dependency_Model_Not_Public,
      Dependency_Missing,
      Dependency_Intentionally_Blocked);

   type Public_Build_UX_Dependency_Matrix is
     array (Public_Build_UX_Dependency) of Public_Build_UX_Dependency_Status;

   package Public_Build_Command_Surface_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Public_Build_Command_Surface_Entry);

   subtype Public_Build_Command_Surface_Array is
     Public_Build_Command_Surface_Vectors.Vector;

   type Public_Build_Command_UX_Dependency_Audit_Result is record
      Has_Input_Model : Boolean := False;
      Has_Structured_Argv_Model : Boolean := False;
      Has_Consent_Model : Boolean := False;
      Has_Real_Consent_UX : Boolean := False;
      Has_Working_Context_Model : Boolean := False;
      Has_Safe_Working_Context_UX : Boolean := False;
      Has_Implicit_Source_Validation : Boolean := False;
      Explicitly_Rejects_Implicit_Source : Boolean := False;
      Requires_Executor_Routed_Mutation : Boolean := False;
      Requires_One_Primary_Result : Boolean := False;
      Requires_Diagnostics_Pipeline : Boolean := False;
      Requires_No_Shell_Execution : Boolean := False;
      Requires_Side_Effect_Free_Availability : Boolean := False;
      Requires_No_Persistence_Of_Transient_State : Boolean := False;
      Public_Command_Exposure_Blocked : Boolean := False;
      Passed_As_Not_Ready : Boolean := False;
   end record;

   type Public_Build_Command_Readiness_Audit_Result is record
      Public_Command_Surface_Exists     : Boolean := False;
      Public_Executable_Command_Exists      : Boolean := False;
      Public_Command_Is_Invokable           : Boolean := False;
      Has_Public_Build_Command              : Boolean := False;
      Has_Default_Public_Build_Keybinding   : Boolean := False;
      Public_Command_Has_Complete_UX_Models : Boolean := False;
      Public_Command_Publicly_Exposable     : Boolean := False;
      Public_Command_Promotion_Status       : Public_Build_Command_Promotion_Status :=
        Public_Build_Promotion_Blocked;
      Public_Command_Can_Be_Promoted        : Boolean := False;
      Public_UX_Dependency_Matrix_Exists    : Boolean := False;
      Public_UX_Dependency_Matrix_Validated : Boolean := False;
      Primary_Promotion_Blocker             : Public_Build_UX_Dependency :=
        Public_Build_Dependency_Consent_UX;
      Consent_UX_Blocker_Active             : Boolean := False;
      Working_Context_UX_Blocker_Active     : Boolean := False;
      Implicit_Source_Blocker_Active       : Boolean := False;
      Public_Executor_Route_Blocker_Active  : Boolean := False;
      Public_Command_Exposure_Hard_Failure  : Boolean := False;
      Promotion_Blocked_By_Consent_UX       : Boolean := False;
      Promotion_Blocked_By_Working_Context  : Boolean := False;
      Promotion_Blocked_By_Implicit_Source : Boolean := False;
      Promotion_Blocked_By_Command_Exposure : Boolean := False;
      Has_User_Command_Input_Model          : Boolean := False;
      Has_Structured_Argv_Input_Model       : Boolean := False;
      Has_Working_Context_Model             : Boolean := False;
      Has_Public_Input_Model_Audit          : Boolean := False;
      Public_Consent_Model_Exists           : Boolean := False;
      Public_Consent_Model_Validated        : Boolean := False;
      Public_Working_Context_Model_Exists   : Boolean := False;
      Public_Working_Context_Model_Validated : Boolean := False;
      Public_Working_Context_Publicly_Ready : Boolean := False;
      Public_Working_Context_Publicly_Exposable : Boolean := False;
      Project_Derived_Working_Context_Rejected : Boolean := False;
      Public_Consent_UX_Publicly_Ready      : Boolean := False;
      Public_Consent_Publicly_Exposable     : Boolean := False;
      Public_Input_Validation_Side_Effect_Free : Boolean := False;
      Public_Input_Conversion_Requires_Valid_Input : Boolean := False;
      Public_Input_Conversion_Preserves_Provenance : Boolean := False;
      Public_Input_Conversion_Uses_Structured_Argv : Boolean := False;
      Public_Input_Validation_Complete        : Boolean := False;
      Public_Input_Has_Safety_Classification  : Boolean := False;
      Public_Input_Publicly_Exposable         : Boolean := False;
      Working_Context_Publicly_Ready          : Boolean := False;
      Consent_UX_Publicly_Ready               : Boolean := False;
      Public_Input_Does_Not_Create_Command_Descriptors : Boolean := False;
      Public_Input_Does_Not_Enable_Public_Execution : Boolean := False;
      Has_Consent_UX_Model                  : Boolean := False;
      Has_Implicit_Source_Validation       : Boolean := False;
      Keeps_Implicit_Source_Rejected       : Boolean := False;
      Keeps_Shell_Rejected                  : Boolean := False;
      Keeps_Opaque_Arguments_Rejected       : Boolean := False;
      Routes_Through_Executor               : Boolean := False;
      Routes_Diagnostics_Through_Pipeline   : Boolean := False;
      Passed_As_Not_Ready                   : Boolean := False;
   end record;



   --  consolidated hard-freeze blocker summary. This is pure
   --  audit feedback state only; it is never persisted or promoted into a
   --  command descriptor.
   type Public_Build_Blocker_Summary is record
      Consent_UX_Missing             : Boolean := False;
      Working_Context_UX_Missing     : Boolean := False;
      Implicit_Source_Unsupported   : Boolean := False;
      Public_Route_Missing           : Boolean := False;
      Public_Command_Not_Registered  : Boolean := False;
      Default_Execution_Disabled     : Boolean := False;
      Primary_Blocker                : Public_Build_UX_Dependency :=
        Public_Build_Dependency_Consent_UX;
   end record;

   --  top-level public-build hard-freeze audit. All fields are
   --  computed from existing pure audit seams and registry snapshots.
   type Public_Build_Command_Hard_Freeze_Audit_Result is record
      Readiness_Audit_Passed_As_Not_Ready : Boolean := False;
      Dependency_Matrix_Validated         : Boolean := False;
      Promotion_Blocked                   : Boolean := False;
      Exposure_Barrier_Passed             : Boolean := False;
      No_Public_Command_Registered        : Boolean := False;
      No_Public_Default_Keybinding        : Boolean := False;
      No_Public_Command_Palette_Entry     : Boolean := False;
      No_Public_Executor_Route            : Boolean := False;
      No_Public_Invocation_Path           : Boolean := False;
      No_Public_Bindable_Command          : Boolean := False;
      No_Public_Persistence_State         : Boolean := False;
      No_Default_Execution                : Boolean := False;
      Shell_Rejected                      : Boolean := False;
      Opaque_Arguments_Rejected           : Boolean := False;
      Implicit_Source_Rejected           : Boolean := False;
      Public_Exposure_Hard_Failure        : Boolean := False;
      Passed                              : Boolean := False;
   end record;


   --  post-hard-freeze baseline. This is audit/test data only: it
   --  is never persisted, never registered as command metadata, and never used
   --  to mutate descriptors, keybindings, palette rows, or routes.
   type Public_Build_Hard_Freeze_Baseline is record
      Public_Command_Count              : Natural := 0;
      Public_Default_Keybinding_Count   : Natural := 0;
      Public_Command_Palette_Count      : Natural := 0;
      Public_Executor_Route_Count       : Natural := 0;
      Public_Invocation_Path_Count      : Natural := 0;
      Bindable_Public_Build_Count       : Natural := 0;
      Promotion_Blocked                 : Boolean := True;
      Default_Execution_Disabled        : Boolean := True;
      Consent_UX_Missing                : Boolean := True;
      Working_Context_UX_Missing        : Boolean := True;
      Implicit_Source_Unsupported      : Boolean := True;
      Public_Route_Missing              : Boolean := True;
   end record;

   type Public_Build_Hard_Freeze_Drift_Result is record
      Public_Command_Drift             : Boolean := False;
      Keybinding_Drift                 : Boolean := False;
      Palette_Drift                    : Boolean := False;
      Executor_Route_Drift             : Boolean := False;
      Invocation_Path_Drift            : Boolean := False;
      Bindability_Drift                : Boolean := False;
      Promotion_Drift                  : Boolean := False;
      Execution_Default_Drift          : Boolean := False;
      Blocker_Precedence_Drift         : Boolean := False;
      Persistence_Drift                : Boolean := False;
      Any_Drift                        : Boolean := False;
   end record;

   package Public_Build_Command_Surface_Id_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Command_Id_Vector is Public_Build_Command_Surface_Id_Vectors.Vector;

   type Public_Build_Guardrail_Status is
     (Public_Build_Guardrail_Passed,
      Public_Build_Guardrail_Not_Ready_But_Safe,
      Public_Build_Guardrail_Drift_Detected,
      Public_Build_Guardrail_Exposure_Detected,
      Public_Build_Guardrail_Inconsistent_Audits);

   type Public_Build_Guardrail_Result is record
      Status                     : Public_Build_Guardrail_Status :=
        Public_Build_Guardrail_Inconsistent_Audits;
      No_Public_Command          : Boolean := False;
      No_Public_Keybinding       : Boolean := False;
      No_Public_Palette_Entry    : Boolean := False;
      No_Public_Executor_Route   : Boolean := False;
      No_Public_Invocation_Path  : Boolean := False;
      No_Public_Bindable_Command : Boolean := False;
      Promotion_Blocked          : Boolean := False;
      Default_Execution_Disabled : Boolean := False;
      Dependency_Blockers_Active : Boolean := False;
      Persistence_Clean          : Boolean := False;
      Audits_Consistent          : Boolean := False;
   end record;

   type Public_Build_Guardrail_Contract_Mismatch is record
      Status_Mismatch              : Boolean := False;
      Public_Command_Mismatch      : Boolean := False;
      Public_Keybinding_Mismatch   : Boolean := False;
      Public_Palette_Mismatch      : Boolean := False;
      Public_Route_Mismatch        : Boolean := False;
      Public_Invocation_Mismatch   : Boolean := False;
      Public_Bindability_Mismatch  : Boolean := False;
      Promotion_Mismatch           : Boolean := False;
      Default_Execution_Mismatch   : Boolean := False;
      Dependency_Blocker_Mismatch  : Boolean := False;
      Persistence_Mismatch         : Boolean := False;
      Audit_Consistency_Mismatch   : Boolean := False;
      Any_Mismatch                 : Boolean := False;
   end record;


   --  diagnostic-only guardrail failure details.  These records are
   --  audit/test feedback only: they are never persisted and never expose raw
   --  argv, command lines, paths, environments, run ids, or projection
   --  generations.
   type Public_Build_Guardrail_Failure_Kind is
     (Public_Build_Failure_None,
      Public_Build_Failure_Public_Command_Registered,
      Public_Build_Failure_Public_Keybinding_Found,
      Public_Build_Failure_Public_Palette_Entry_Found,
      Public_Build_Failure_Public_Executor_Route_Found,
      Public_Build_Failure_Public_Invocation_Path_Found,
      Public_Build_Failure_Public_Bindable_Command_Found,
      Public_Build_Failure_Promotion_Unblocked,
      Public_Build_Failure_Default_Execution_Enabled,
      Public_Build_Failure_Dependency_Blockers_Missing,
      Public_Build_Failure_Persistence_Leak,
      Public_Build_Failure_Audit_Inconsistency,
      Public_Build_Failure_Internal_Test_Seam_Exposure);

   type Public_Build_Guardrail_Failure_Detail is record
      Kind       : Public_Build_Guardrail_Failure_Kind :=
        Public_Build_Failure_None;
      Command_Id : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Domain     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Public_Build_Guardrail_Failure_Detail_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Public_Build_Guardrail_Failure_Detail);

   subtype Public_Build_Guardrail_Failure_Detail_Vector is
     Public_Build_Guardrail_Failure_Detail_Vectors.Vector;

   type Public_Build_Surface_Id_Scan_Result is record
      Exact_Command_Id_Found        : Boolean := False;
      Exact_Display_Name_Found     : Boolean := False;
      Exact_Keybinding_Target_Found : Boolean := False;
      Exact_Runtime_Keybinding_Found: Boolean := False;
      Exact_Palette_Row_Found       : Boolean := False;
      Exact_Executor_Route_Found    : Boolean := False;
      Exact_Invocation_Path_Found   : Boolean := False;
      Exact_Persisted_Name_Found    : Boolean := False;
      Exact_Workspace_Name_Found    : Boolean := False;
      Near_Miss_Only                : Boolean := False;
      Stable_Command_Ids_Checked    : Boolean := False;
      Display_Search_Names_Checked: Boolean := False;
      Palette_Checked               : Boolean := False;
      Default_Keybindings_Checked   : Boolean := False;
      Runtime_Keybindings_Checked   : Boolean := False;
      Persisted_Keybindings_Checked : Boolean := False;
      Executor_Routes_Checked       : Boolean := False;
      Invocation_Paths_Checked      : Boolean := False;
      Persistence_Names_Checked     : Boolean := False;
      Workspace_Names_Checked       : Boolean := False;
      Passed                        : Boolean := True;
   end record;

   type Public_Build_Guardrail_Audit_Trace is record
      Readiness_Checked                  : Boolean := False;
      Dependency_Checked                 : Boolean := False;
      Promotion_Checked                  : Boolean := False;
      Exposure_Checked                   : Boolean := False;
      Drift_Checked                      : Boolean := False;
      No_Execution_Checked               : Boolean := False;
      Persistence_Checked                : Boolean := False;
      Surface_Ids_Checked               : Boolean := False;
      Contract_Checked                   : Boolean := False;
      Internal_Test_Seam_Exposure_Checked : Boolean := False;
      Hard_Freeze_Checked                : Boolean := False;
   end record;

   type Public_Build_Guardrail_Health is record
      Guardrail_Result  : Public_Build_Guardrail_Result;
      Surface_Id_Scan  : Public_Build_Surface_Id_Scan_Result;
      Audit_Trace       : Public_Build_Guardrail_Audit_Trace;
      First_Failure     : Public_Build_Guardrail_Failure_Detail;
      Failure_Count     : Natural := 0;
      Snapshot_Mismatch : Public_Build_Guardrail_Contract_Mismatch;
      Healthy           : Boolean := False;
   end record;

   --  diagnostic-only regression manifest.  This anchors the
   --  long-horizon public-build no-surface contract without creating any
   --  command, keybinding, runner, persistence, project-file, or diagnostics
   --  side effect.
   type Public_Build_Guardrail_Audit_Matrix_Dimension is
     (Public_Build_Matrix_Normalized_Guardrail_Contract,
      Public_Build_Matrix_Health_Report,
      Public_Build_Matrix_Regression_Manifest,
      Public_Build_Matrix_Readiness_Audit,
      Public_Build_Matrix_Dependency_Matrix_Validation,
      Public_Build_Matrix_Promotion_Validation,
      Public_Build_Matrix_Exposure_Barrier,
      Public_Build_Matrix_Hard_Freeze_Audit,
      Public_Build_Matrix_Drift_Detection,
      Public_Build_Matrix_No_Public_Command_Scan,
      Public_Build_Matrix_No_Public_Keybinding_Scan,
      Public_Build_Matrix_No_Public_Palette_Scan,
      Public_Build_Matrix_No_Public_Executor_Route_Scan,
      Public_Build_Matrix_No_Public_Invocation_Scan,
      Public_Build_Matrix_No_Public_Bindable_Command_Scan,
      Public_Build_Matrix_No_Public_Execution_Scan,
      Public_Build_Matrix_Surface_Id_Scan,
      Public_Build_Matrix_Surface_Id_Domain_Coverage,
      Public_Build_Matrix_Persistence_Exclusion_Scan,
      Public_Build_Matrix_Audit_Trace_Completeness,
      Public_Build_Matrix_Internal_Test_Seam_Exposure_Check,
      Public_Build_Matrix_Public_Command_Executability_Check,
      Public_Build_Matrix_Public_Input_Non_Exposability_Check,
      Public_Build_Matrix_Public_Consent_Non_Exposability_Check,
      Public_Build_Matrix_Public_Working_Context_Non_Exposability_Check,
      Public_Build_Matrix_Project_Build_Rejection_Check,
      Public_Build_Matrix_User_Opt_In_Internal_Only_Check,
      Public_Build_Matrix_Real_Runner_Default_Disabled_Check,
      Public_Build_Matrix_Fixture_User_Opt_In_Separation_Check,
      Public_Build_Matrix_Lifecycle_Stability_Check,
      Public_Build_Matrix_Side_Effect_Free_Audit_Check);

   type Public_Build_Guardrail_Audit_Matrix is
     array (Public_Build_Guardrail_Audit_Matrix_Dimension) of Boolean;

   type Public_Build_Guardrail_Regression_Manifest is record
      Health                      : Public_Build_Guardrail_Health;
      Default_Contract_Matches    : Boolean := False;
      Trace_Surface_Complete      : Boolean := False;
      Public_Command_Surface_Complete   : Boolean := False;
      Persistence_Exclusion_Clean : Boolean := False;
      Lifecycle_Stable            : Boolean := False;
      Public_Surface_Present       : Boolean := False;
      Execution_Surface_Present    : Boolean := False;
      Surface_Command_Executable  : Boolean := False;
      Promotion_Blocked           : Boolean := False;
      Dependency_Blockers_Active  : Boolean := False;
      Manifest_Healthy            : Boolean := False;
   end record;

end Editor.External_Producers.Public_Build_Types;
