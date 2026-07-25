with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
use type Ada.Strings.Unbounded.Unbounded_String;
with Editor.Commands;
with Editor.Feature_Diagnostics;
with Editor.Keybindings;
with Editor.Producer_Contracts;
limited with Editor.State;

package Editor.External_Producers is


   --  normalized public-build guardrail contract.  This version is
   --  audit/test metadata only: it is not persisted and never enables or
   --  bypasses command validation.
   Public_Build_Guardrail_Contract_Version : constant String := "";

   --  External-producer and build-diagnostic integration.  The package models
   --  deterministic producer identities, converts already-structured diagnostic
   --  records into the Diagnostics feature-owned ingestion seam, normalizes
   --  compiler/build-like records into that DTO, parses a deliberately narrow
   --  raw diagnostic line format, and owns the audited synchronous build-process
   --  execution seam for explicit user-opt-in build commands.  It still does
   --  not speak LSP, watch files, start workers, enqueue asynchronous work,
   --  persist diagnostics, open editor buffers, scan projects, or mutate generic
   --  feature-panel projection internals.  The editor build-command layer may
   --  run this seam from a transient worker task for non-blocking public
   --  build jobs.

   type External_Producer_Kind is
     (No_External_Producer,
      Build_Diagnostics_Producer,
      Compiler_Diagnostics_Producer);

   type External_Producer_Source is record
      Kind          : External_Producer_Kind := No_External_Producer;
      Stable_Name   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type External_Diagnostic_Record is record
      Severity      : Editor.Feature_Diagnostics.Diagnostic_Severity :=
        Editor.Feature_Diagnostics.Diagnostic_Info;
      Message       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Source_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := Editor.Feature_Diagnostics.No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Has_Edit          : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Detail  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package External_Diagnostic_Record_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => External_Diagnostic_Record);

   subtype External_Diagnostic_Record_Array is
     External_Diagnostic_Record_Vectors.Vector;


   --  structured compiler/build diagnostic normalization scaffold.
   --  These records are already structured test-fed inputs.  They are not raw
   --  compiler output, build logs, LSP diagnostics, file-watcher events, or
   --  async deliveries.
   type Compiler_Diagnostic_Severity is
     (Compiler_Info,
      Compiler_Note,
      Compiler_Warning,
      Compiler_Error,
      Compiler_Fatal,
      Compiler_Unknown);

   package Diagnostic_Text_Line_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Diagnostic_Text_Line_Array is Diagnostic_Text_Line_Vectors.Vector;

   type Buffer_Target_Resolution is record
      Found  : Boolean := False;
      Buffer : Natural := Editor.Feature_Diagnostics.No_Buffer;
   end record;

   type Normalized_Diagnostic_Batch is record
      Items                  : External_Diagnostic_Record_Array;
      Input_Count            : Natural := 0;
      Normalized_Count       : Natural := 0;
      Untargeted_Count       : Natural := 0;
      Empty_Message_Count    : Natural := 0;
      Invalid_Location_Count : Natural := 0;
   end record;

   type Producer_Batch_Result is record
      Accepted_Count      : Natural := 0;
      Accepted_Untargeted : Natural := 0;
      Rejected_Count      : Natural := 0;
      Evicted_Count       : Natural := 0;
      Projection_Changed  : Boolean := False;
   end record;

   type Diagnostic_Line_Ingestion_Result is record
      Parse_Input_Count                 : Natural := 0;
      Parse_Accepted_Count              : Natural := 0;
      Parse_Ignored_Blank_Count         : Natural := 0;
      Parse_Ignored_Unrecognized_Count  : Natural := 0;
      Parse_Rejected_Malformed_Count    : Natural := 0;
      Normalized_Count                  : Natural := 0;
      Parsed_Error_Count                : Natural := 0;
      Parsed_Warning_Count              : Natural := 0;
      Parsed_Info_Count                 : Natural := 0;
      Parsed_Note_Count                 : Natural := 0;
      Parsed_Unknown_Count              : Natural := 0;
      Ingestion_Result                  : Producer_Batch_Result;
   end record;

   type Diagnostic_Line_Command_Outcome is
     (Diagnostic_Line_Command_Succeeded,
      Diagnostic_Line_Command_No_Input,
      Diagnostic_Line_Command_No_Diagnostics,
      Diagnostic_Line_Command_Malformed_Only);

   type Diagnostic_Line_Command_Result is record
      Ingestion       : Diagnostic_Line_Ingestion_Result;
      Command_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Should_Show_Diagnostics : Boolean := False;
      Outcome         : Diagnostic_Line_Command_Outcome :=
        Diagnostic_Line_Command_No_Input;
   end record;


   --  structured argument vector shared by build requests and
   --  process requests. Arguments are always caller-supplied tokens; they are
   --  never shell-split from opaque strings.
   package Process_Argument_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Process_Argument_Vector is Process_Argument_Vectors.Vector;

   --  Hardened synchronous build-tool/process-runner seam.
   type Build_Tool_Kind is
     (No_Build_Tool,
      GPRbuild_Tool,
      Alire_Build_Tool,
      Custom_Build_Tool);

   type Build_Request_Provenance is
     (Build_Request_From_Test,
      Build_Request_From_Fixture,
      Build_Request_From_Internal_Command,
      Build_Request_From_User_Opt_In,
      Build_Request_From_Implicit_Source,
      Build_Request_Unknown);

   type Build_Run_Request is record
      Tool          : Build_Tool_Kind := No_Build_Tool;
      Provenance    : Build_Request_Provenance := Build_Request_Unknown;
      Working_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Command_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Arguments     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Structured_Arguments : Process_Argument_Vector :=
        Process_Argument_Vectors.Empty_Vector;
   end record;

   --  explicit user-supplied build command shape. This is only a
   --  request model: it is not implicit source input, not fixture identity, not
   --  persisted state, and not an opaque shell command.
   type User_Build_Command_Request is record
      Tool          : Build_Tool_Kind := No_Build_Tool;
      Program_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Arguments     : Process_Argument_Vector :=
        Process_Argument_Vectors.Empty_Vector;
   end record;

   type Build_Request_Validation_Status is
     (Build_Request_Valid,
      Build_Request_Rejected_No_Tool,
      Build_Request_Rejected_Unsupported_Tool,
      Build_Request_Rejected_Empty_Command,
      Build_Request_Rejected_Unknown_Provenance,
      Build_Request_Rejected_Provenance,
      Build_Request_Rejected_Implicit_Source,
      Build_Request_Rejected_Consent);

   --  /579 process-runner seam. This is deliberately lower-level
   --  than build-tool semantics and represents a completed process-like
   --  result produced by the guarded real or supplied-result runner paths.
   --  Production build.run may obtain that result from a background worker
   --  and poll for completion without blocking the command frontdoor.
   type Process_Run_Status is
     (Process_Run_Succeeded,
      Process_Run_Failed,
      Process_Run_Not_Available,
      Process_Run_Rejected,
      Process_Run_Execution_Error,
      Process_Run_Timed_Out,
      Process_Run_Cancelled,
      Process_Run_Cancellation_Unsupported,
      Process_Run_Output_Truncated);

   type Process_Output_Capture_Mode is
     (Process_Output_Capture_None,
      Process_Output_Capture_Separated,
      Process_Output_Capture_Merged_Stdout_Stderr);

   type Process_Output_Stream is
     (Process_Output_Stdout,
      Process_Output_Stderr,
      Process_Output_Merged);

   type Process_Diagnostic_Stream_Preference is
     (Process_Diagnostics_Prefer_Stderr,
      Process_Diagnostics_Merged_Output_Fallback);

   type Process_Run_Request is record
      Program_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Working_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      --  Opaque display/test metadata only. real execution
      --  rejects non-empty opaque arguments rather than shell-splitting them.
      Arguments     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Structured_Arguments : Process_Argument_Vector :=
        Process_Argument_Vectors.Empty_Vector;
   end record;

   type Process_Request_Validation_Status is
     (Process_Request_Valid,
      Process_Request_Rejected_Execution_Disabled,
      Process_Request_Rejected_Shell_Disallowed,
      Process_Request_Rejected_Empty_Program,
      Process_Request_Rejected_Opaque_Arguments,
      Process_Request_Rejected_Invalid_Argument,
      Process_Request_Rejected_Relative_Program,
      Process_Request_Rejected_Unsupported_Working_Directory);

   type Process_Execution_Mode is
     (Process_Execution_Disabled,
      Process_Execution_Test_Fixture,
      Process_Execution_Real_Fixture_Allowed,
      Process_Execution_Real_Allowed);

   --  How the editor actually runs an external tool.
   --
   --  This had one value, and a label reading "POSIX/fork-exec-waitpid-kill", because the
   --  process control was written straight into the body as fork, execvp, waitpid and
   --  kill. The extension point was anticipated and never extended, and the editor did
   --  not link on Windows at all: undefined reference to waitpid, and to kill.
   --
   --  It is Hostkit's now, and Hostkit has a body per host: fork and waitpid on POSIX,
   --  CreateProcessW and TerminateProcess on Windows. So the answer is per host, and this
   --  says which.
   type Native_Process_Control_Backend is
     (Native_Process_Control_POSIX,
      Native_Process_Control_Windows);

   --  The current real process runner is intentionally POSIX-backed.  This
   --  explicit backend contract prevents the product from silently implying
   --  Windows/CreateProcess or generic portable process-control support before
   --  a separate backend is implemented and gated.
   type Build_Execution_Consent is
     (Build_Consent_Not_Provided,
      Build_Consent_Test_Only,
      Build_Consent_User_Confirmed);


   --  minimal public-build working-context model. This is
   --  metadata only: it never canonicalizes directories, discovers project
   --  roots, reads files, or mutates the process working directory.
   type Build_Working_Context_Kind is
     (Build_Working_Context_Unsupported,
      Build_Working_Context_Inherited_Test_Context,
      Build_Working_Context_Explicit_Label);

   type Build_Working_Context is record
      Kind  : Build_Working_Context_Kind := Build_Working_Context_Unsupported;
      Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  structured public-build input DTO. This is not a command
   --  descriptor, not persisted state, not shell text, and not an execution
   --  request until a pure validation/conversion helper accepts it.

   --  public-build consent UX model. This is structured
   --  validation metadata only: it is not a modal prompt, command
   --  descriptor, persisted state, palette signal, or execution request.
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

   type Process_Fixture_Kind is
     (No_Process_Fixture,
      Echo_Diagnostic_Fixture,
      Exit_Code_Fixture);

   --  approved real build-tool invocation fixtures. This identity is
   --  explicit and is never inferred from command labels, program labels, argv,
   --  PATH, project files, or workspace metadata.
   type Real_Build_Tool_Fixture_Kind is
     (No_Real_Build_Tool_Fixture,
      GPRbuild_Version_Fixture,
      Alire_Version_Fixture,
      Diagnostic_Output_Fixture);

   type Process_Fixture_Validation_Status is
     (Fixture_Request_Valid,
      Fixture_Request_Rejected_Disabled,
      Fixture_Request_Rejected_Unknown_Fixture,
      Fixture_Request_Rejected_Shell,
      Fixture_Request_Rejected_Opaque_Arguments,
      Fixture_Request_Rejected_Invalid_Argument,
      Fixture_Request_Rejected_Output_Limit,
      Fixture_Request_Not_Available);

   type Real_Build_Tool_Fixture_Validation_Status is
     (Real_Build_Fixture_Valid,
      Real_Build_Fixture_Rejected_Disabled,
      Real_Build_Fixture_Rejected_Unknown_Fixture,
      Real_Build_Fixture_Rejected_Provenance,
      Real_Build_Fixture_Rejected_Implicit_Source,
      Real_Build_Fixture_Rejected_Custom_Tool,
      Real_Build_Fixture_Rejected_Shell,
      Real_Build_Fixture_Rejected_Opaque_Arguments,
      Real_Build_Fixture_Rejected_Working_Context,
      Real_Build_Fixture_Rejected_Ambiguous_Gate,
      Real_Build_Fixture_Not_Available);

   type Process_Fixture_Request is record
      Kind      : Process_Fixture_Kind := No_Process_Fixture;
      Arguments : Process_Argument_Vector := Process_Argument_Vectors.Empty_Vector;
   end record;

   type Process_Execution_Policy is record
      Mode                     : Process_Execution_Mode :=
        Process_Execution_Disabled;
      Allow_Real_Execution     : Boolean := False;
      Allow_Shell              : Boolean := False;
      Max_Output_Bytes         : Natural := 262_144;
      Require_Absolute_Program : Boolean := False;
      Timeout_Milliseconds     : Natural := 0;
   end record;

   type Process_Run_Result is record
      Status        : Process_Run_Status := Process_Run_Not_Available;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_None;
      Has_Exit_Code : Boolean := False;
      Exit_Code     : Integer := 0;
      Stdout_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
   end record;

   type Build_Run_Status is
     (Build_Run_Succeeded,
      Build_Run_Failed,
      Build_Run_Not_Available,
      Build_Run_Rejected,
      Build_Run_Execution_Error,
      Build_Run_Timed_Out,
      Build_Run_Cancelled,
      Build_Run_Cancellation_Unsupported,
      Build_Run_Output_Truncated);

   type Build_Preflight_Result is record
      Build_Request_Status   : Build_Request_Validation_Status :=
        Build_Request_Rejected_No_Tool;
      Process_Request_Status : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
      Has_Process_Request    : Boolean := False;
      Process_Request        : Process_Run_Request;
   end record;

   type Build_Execution_Gate is record
      Process_Policy               : Process_Execution_Policy;
      Allow_Build_Run              : Boolean := False;
      Allow_Real_Build_Tool_Execution : Boolean := False;
      Allow_Real_Build_Tool_Fixture   : Boolean := False;
      Consent                      : Build_Execution_Consent :=
        Build_Consent_Not_Provided;
      Allow_Diagnostics_Ingestion  : Boolean := True;
      Show_Diagnostics             : Boolean := False;
   end record;

   type User_Opt_In_Build_Command_Context is record
      Has_Request : Boolean := False;
      Request     : Build_Run_Request;
      Gate        : Build_Execution_Gate;
   end record;

   --  command-context validation is a pure metadata classifier.
   --  It never executes, probes PATH, reads project files, ingests Diagnostics,
   --  switches features, or persists command state.
   type User_Opt_In_Build_Command_Context_Status is
     (User_Build_Context_Valid,
      User_Build_Context_Rejected_Missing_Context,
      User_Build_Context_Rejected_Missing_Request,
      User_Build_Context_Rejected_Missing_Gate,
      User_Build_Context_Rejected_Missing_Consent,
      User_Build_Context_Rejected_Provenance,
      User_Build_Context_Rejected_Implicit_Source,
      User_Build_Context_Rejected_Custom_Tool,
      User_Build_Context_Rejected_Opaque_Arguments,
      User_Build_Context_Rejected_Shell,
      User_Build_Context_Rejected_Working_Context,
      User_Build_Context_Rejected_Ambiguous_Execution_Path);

   --  post-command-surface-freeze audit result. The audit is a
   --  read-only metadata summary: it never executes commands, performs real
   --  preflight, inspects files/PATH, ingests diagnostics, mutates descriptors,
   --  or retains command state.
   type Build_Execution_Consent_Audit_Result is record
      Has_Public_Build_Command              : Boolean := False;
      Has_Default_Build_Keybinding          : Boolean := False;
      Internal_Command_Requires_Context     : Boolean := False;
      Internal_Command_Requires_Provenance  : Boolean := False;
      Internal_Command_Requires_Gate        : Boolean := False;
      Internal_Command_Requires_Consent     : Boolean := False;
      Rejects_Implicit_Source              : Boolean := False;
      Rejects_Custom_Tool                   : Boolean := False;
      Rejects_Shell                         : Boolean := False;
      Rejects_Opaque_Arguments              : Boolean := False;
      Routes_Diagnostics_Through_Pipeline   : Boolean := False;
      Passed                                : Boolean := False;
   end record;

   --  pre-public build-command UX readiness audit. This is a
   --  side-effect-free metadata and validation summary. It deliberately reports
   --  ready only when a structured input DTO, consent UX, safe real
   --  working-directory validation, explicit-source policy, and guarded command
   --  registration are all present. The audit remains side-effect-free and does
   --  not execute or persist anything.
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

end Editor.External_Producers;
