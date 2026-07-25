with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Hostkit.Process;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Request_Policies;

package body Editor.External_Producers.Execution_Policy is

   function Build_Default_Timeout_Milliseconds return Natural is
   begin
      return 120_000;
   end Build_Default_Timeout_Milliseconds;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean is
      Max_Build_Timeout_Milliseconds : constant Natural := 600_000;
   begin
      if Policy.Mode = Process_Execution_Disabled then
         return Policy.Timeout_Milliseconds = 0;
      end if;

      return Policy.Timeout_Milliseconds <= Max_Build_Timeout_Milliseconds;
   end Build_Timeout_Policy_Is_Bounded;

   function Build_Default_Execution_Gate
     return Editor.External_Producers.Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Disabled,
            Allow_Real_Execution     => False,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0),
         Allow_Build_Run             => False,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   end Build_Default_Execution_Gate;

   function Build_Test_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Editor.External_Producers.Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Test_Fixture,
            Allow_Real_Execution     => False,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Test_Fixture_Execution_Gate;

   function Build_Real_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Editor.External_Producers.Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Real_Fixture_Execution_Gate;

   function Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Require_Absolute_Program    : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Not_Provided) return Editor.External_Producers.Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => Require_Absolute_Program,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Real_Execution_Gate;

   function Validate_Build_Execution_Consent
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean
   is
   begin
      case Gate.Process_Policy.Mode is
         when Process_Execution_Disabled =>
            return Gate.Consent = Build_Consent_Not_Provided;
         when Process_Execution_Test_Fixture
            | Process_Execution_Real_Fixture_Allowed =>
            return Gate.Consent = Build_Consent_Test_Only;
         when Process_Execution_Real_Allowed =>
            return Gate.Consent /= Build_Consent_Test_Only;
      end case;
   end Validate_Build_Execution_Consent;

   function Validate_Build_Execution_Gate
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean
   is
   begin
      if Gate.Process_Policy.Allow_Shell then
         return False;
      end if;

      if not Build_Timeout_Policy_Is_Bounded (Gate.Process_Policy) then
         return False;
      end if;

      if not Validate_Build_Execution_Consent (Gate) then
         return False;
      end if;

      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return False;
      end if;

      if not Gate.Allow_Build_Run then
         return Gate.Process_Policy.Mode = Process_Execution_Disabled
           and then not Gate.Process_Policy.Allow_Real_Execution
           and then not Gate.Allow_Real_Build_Tool_Execution
           and then not Gate.Allow_Real_Build_Tool_Fixture;
      end if;

      case Gate.Process_Policy.Mode is
         when Process_Execution_Disabled =>
            return False;
         when Process_Execution_Test_Fixture =>
            return not Gate.Process_Policy.Allow_Real_Execution
              and then not Gate.Allow_Real_Build_Tool_Execution
              and then not Gate.Allow_Real_Build_Tool_Fixture;
         when Process_Execution_Real_Fixture_Allowed =>
            return Gate.Process_Policy.Allow_Real_Execution
              and then not Gate.Allow_Real_Build_Tool_Execution;
         when Process_Execution_Real_Allowed =>
            return Gate.Process_Policy.Allow_Real_Execution
              and then Gate.Allow_Real_Build_Tool_Execution
              and then not Gate.Allow_Real_Build_Tool_Fixture;
      end case;
   end Validate_Build_Execution_Gate;

   function Assert_Build_Execution_Gate_Consistent
     (Gate : Editor.External_Producers.Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate);
   end Assert_Build_Execution_Gate_Consistent;

   function Select_Process_Runner_Mode
     (Gate   : Editor.External_Producers.Build_Execution_Gate;
      Policy : Process_Execution_Policy) return Process_Execution_Mode
   is
   begin
      if not Validate_Build_Execution_Gate (Gate) then
         return Process_Execution_Disabled;
      end if;

      if not Gate.Allow_Build_Run then
         return Process_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Mode /= Policy.Mode
        or else Gate.Process_Policy.Allow_Real_Execution /= Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Allow_Shell /= Policy.Allow_Shell
      then
         return Process_Execution_Disabled;
      end if;

      return Gate.Process_Policy.Mode;
   end Select_Process_Runner_Mode;

   function Build_Cancellation_Unsupported_Process_Result
     return Editor.External_Producers.Process_Run_Result
   is
   begin
      return Editor.External_Producers.Request_Policies.Build_Process_Run_Result
        (Process_Run_Cancellation_Unsupported);
   end Build_Cancellation_Unsupported_Process_Result;

   function Current_Native_Process_Control_Backend
     return Editor.External_Producers.Native_Process_Control_Backend
   is
   begin
      if Hostkit.Process.Native_Backend_Label = "Windows/CreateProcess-TerminateProcess" then
         return Native_Process_Control_Windows;
      end if;

      return Native_Process_Control_POSIX;
   end Current_Native_Process_Control_Backend;

   function Native_Process_Control_Backend_Label return String is
   begin
      case Current_Native_Process_Control_Backend is
         when Native_Process_Control_POSIX =>
            return "hostkit/" & Hostkit.Process.Native_Backend_Label;
         when Native_Process_Control_Windows =>
            return "hostkit/" & Hostkit.Process.Native_Backend_Label;
      end case;
   end Native_Process_Control_Backend_Label;

   function Native_Process_Control_Is_POSIX return Boolean is
   begin
      return Current_Native_Process_Control_Backend = Native_Process_Control_POSIX;
   end Native_Process_Control_Is_POSIX;

   function Native_Process_Control_Platform_Audit_Passes return Boolean is
   begin
      return Native_Process_Control_Backend_Label /= "";
   end Native_Process_Control_Platform_Audit_Passes;

   function Real_Process_Runner_Output_Capture_Mode
     return Editor.External_Producers.Process_Output_Capture_Mode
   is
   begin
      return Process_Output_Capture_Separated;
   end Real_Process_Runner_Output_Capture_Mode;

   function Diagnostic_Stream_Preference
     (Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Process_Diagnostic_Stream_Preference
   is
   begin
      if Length (Result.Stderr_Text) > 0 then
         return Process_Diagnostics_Prefer_Stderr;
      else
         return Process_Diagnostics_Merged_Output_Fallback;
      end if;
   end Diagnostic_Stream_Preference;

   function Process_Result_Output_Stream
     (Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Process_Output_Stream
   is
   begin
      if Result.Output_Capture_Mode = Process_Output_Capture_Merged_Stdout_Stderr
        and then Length (Result.Stdout_Text) > 0
        and then Length (Result.Stderr_Text) = 0
      then
         return Process_Output_Merged;
      elsif Length (Result.Stderr_Text) > 0 then
         return Process_Output_Stderr;
      else
         return Process_Output_Stdout;
      end if;
   end Process_Result_Output_Stream;

   function Build_Result_Output_Stream
     (Result : Editor.External_Producers.Build_Types.Build_Run_Result)
      return Editor.External_Producers.Process_Output_Stream
   is
   begin
      if Result.Output_Capture_Mode = Process_Output_Capture_Merged_Stdout_Stderr
        and then Length (Result.Stdout_Text) > 0
        and then Length (Result.Stderr_Text) = 0
      then
         return Process_Output_Merged;
      elsif Length (Result.Stderr_Text) > 0 then
         return Process_Output_Stderr;
      else
         return Process_Output_Stdout;
      end if;
   end Build_Result_Output_Stream;

   function Build_Run_Diagnostic_Stream_Preference
     (Result : Editor.External_Producers.Build_Types.Build_Run_Result)
      return Editor.External_Producers.Process_Diagnostic_Stream_Preference
   is
   begin
      if Length (Result.Stderr_Text) > 0 then
         return Process_Diagnostics_Prefer_Stderr;
      else
         return Process_Diagnostics_Merged_Output_Fallback;
      end if;
   end Build_Run_Diagnostic_Stream_Preference;

end Editor.External_Producers.Execution_Policy;
