with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.External_Producers.Build_Types is

   package Diagnostic_Text_Line_Vectors renames
     Editor.External_Producers.Diagnostic_Text_Lines.Vectors;

   subtype Diagnostic_Text_Line_Array is
     Editor.External_Producers.Diagnostic_Text_Lines.Array_Type;

   package Process_Argument_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Process_Argument_Vector is Process_Argument_Vectors.Vector;

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

   type Native_Process_Control_Backend is
     (Native_Process_Control_POSIX,
      Native_Process_Control_Windows);

   type Build_Execution_Consent is
     (Build_Consent_Not_Provided,
      Build_Consent_Test_Only,
      Build_Consent_User_Confirmed);

   type Build_Working_Context_Kind is
     (Build_Working_Context_Unsupported,
      Build_Working_Context_Inherited_Test_Context,
      Build_Working_Context_Explicit_Label);

   type Build_Working_Context is record
      Kind  : Build_Working_Context_Kind := Build_Working_Context_Unsupported;
      Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Process_Fixture_Kind is
     (No_Process_Fixture,
      Echo_Diagnostic_Fixture,
      Exit_Code_Fixture);

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

   type Build_Run_Result is record
      Status           : Build_Run_Status := Build_Run_Not_Available;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_None;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Diagnostic_Lines : Diagnostic_Text_Line_Array;
   end record;

end Editor.External_Producers.Build_Types;
