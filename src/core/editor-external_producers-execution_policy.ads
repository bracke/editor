with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.Feature_Diagnostics;

package Editor.External_Producers.Execution_Policy is

   function Build_Default_Execution_Gate
     return Editor.External_Producers.Build_Execution_Gate;

   function Build_Default_Timeout_Milliseconds return Natural;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Editor.External_Producers.Process_Execution_Policy) return Boolean;

   function Build_Test_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Editor.External_Producers.Build_Execution_Consent :=
        Editor.External_Producers.Build_Consent_Test_Only)
      return Editor.External_Producers.Build_Execution_Gate;

   function Build_Real_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Editor.External_Producers.Build_Execution_Consent :=
        Editor.External_Producers.Build_Consent_Test_Only)
      return Editor.External_Producers.Build_Execution_Gate;

   function Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Require_Absolute_Program    : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Editor.External_Producers.Build_Execution_Consent :=
        Editor.External_Producers.Build_Consent_Not_Provided)
      return Editor.External_Producers.Build_Execution_Gate;

   function Validate_Build_Execution_Consent
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean;

   function Validate_Build_Execution_Gate
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean;

   function Assert_Build_Execution_Gate_Consistent
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean;

   function Select_Process_Runner_Mode
     (Gate   : Editor.External_Producers.Build_Execution_Gate;
      Policy : Editor.External_Producers.Process_Execution_Policy)
      return Editor.External_Producers.Process_Execution_Mode;

   function Build_Cancellation_Unsupported_Process_Result
     return Editor.External_Producers.Process_Run_Result;

   function Current_Native_Process_Control_Backend
     return Editor.External_Producers.Native_Process_Control_Backend;

   function Native_Process_Control_Backend_Label return String;

   function Native_Process_Control_Is_POSIX return Boolean;

   function Native_Process_Control_Platform_Audit_Passes return Boolean;

   function Real_Process_Runner_Output_Capture_Mode
     return Editor.External_Producers.Process_Output_Capture_Mode;

   function Diagnostic_Stream_Preference
     (Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Process_Diagnostic_Stream_Preference;

   function Process_Result_Output_Stream
     (Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Process_Output_Stream;

   function Build_Result_Output_Stream
     (Result : Editor.External_Producers.Build_Types.Build_Run_Result)
      return Editor.External_Producers.Process_Output_Stream;

   function Build_Run_Diagnostic_Stream_Preference
     (Result : Editor.External_Producers.Build_Types.Build_Run_Result)
      return Editor.External_Producers.Process_Diagnostic_Stream_Preference;

end Editor.External_Producers.Execution_Policy;
