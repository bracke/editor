with Ada.Calendar;
with Ada.Directories;
with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Hostkit.Process;
with Editor.Image_Helpers;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.Build_Runner_Policy;
with Editor.State;
with Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;
with Editor.External_Producers.Source_Metadata;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Command_Execution.Output_Capture; use Editor.External_Producers.Build_Command_Execution.Output_Capture;
with Editor.External_Producers.Build_Command_Execution.Diagnostics; use Editor.External_Producers.Build_Command_Execution.Diagnostics;
with Editor.External_Producers.Build_Command_Execution.Feedback; use Editor.External_Producers.Build_Command_Execution.Feedback;
with Editor.External_Producers.Build_Command_Execution.Preflight; use Editor.External_Producers.Build_Command_Execution.Preflight;
with Editor.External_Producers.Build_Command_Execution.Fixture_Gates; use Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Real_Process is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

   function Execute_Process_Request_Real_Gated_With_State
     (S       : in out Editor.State.State_Type;
      Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Requested_Working : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Working_Label), Both);
      Working : constant String :=
        (if Requested_Working'Length = 0
         then Ada.Directories.Current_Directory
         else Requested_Working);
      Stdout_Capture_File : constant String :=
        Build_Output_Capture_Path (Working, Program & "_stdout");
      Stderr_Capture_File : constant String :=
        Build_Output_Capture_Path (Working, Program & "_stderr");
      Stdout_Output    : Unbounded_String := Null_Unbounded_String;
      Stderr_Output    : Unbounded_String := Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Last_Streamed_Stdout_Length : Natural := 0;
      Last_Streamed_Stderr_Length : Natural := 0;

      procedure Stream_Capture_File_Delta
        (Path          : String;
         Output_Stream : Editor.Build_Output_Details.Build_Output_Stream_Selection;
         Last_Length   : in out Natural)
      is
         Truncated : Boolean := False;
         Snapshot  : constant Unbounded_String :=
           Read_Bounded_Output_File (Path, Policy.Max_Output_Bytes, Truncated);
         Text      : constant String := To_String (Snapshot);
      begin
         if S.Public_Build_Output_Stream.Active
           and then Text'Length > Last_Length
         then
            Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
              (S.Public_Build_Output_Stream,
               Output_Stream,
               Text (Text'First + Last_Length .. Text'Last));
            Last_Length := Text'Length;
            Editor.Build_Process_Control.Publish_Active_Output_Stream
              (S.Public_Build_Output_Stream);
         end if;
      end Stream_Capture_File_Delta;

      procedure Stream_Capture_Deltas is
      begin
         Stream_Capture_File_Delta
           (Stdout_Capture_File,
            Editor.Build_Output_Details.Build_Output_Stream_Stdout,
            Last_Streamed_Stdout_Length);
         Stream_Capture_File_Delta
           (Stderr_Capture_File,
            Editor.Build_Output_Details.Build_Output_Stream_Stderr,
            Last_Streamed_Stderr_Length);
      end Stream_Capture_Deltas;

      function Execute_With_Native_Process_Supervisor return Process_Run_Result is
         use type Hostkit.Process.Process_Outcome;

         Stdout_Output    : Unbounded_String;
         Stderr_Output    : Unbounded_String;
         Stdout_Truncated : Boolean := False;
         Stderr_Truncated : Boolean := False;
         Exit_Code        : Integer := 0;

         Cancellation_Observed : Boolean := False;

         procedure Register_Active_Build_Process (System_Process_Id : Integer) is
         begin
            if S.Public_Build_Job_Active then
               S.Public_Build_Process_Handle :=
                 Editor.Build_Process_Control.From_System_Process_Id (System_Process_Id);
               Editor.Build_Process_Control.Publish_Active_Process
                 (S.Public_Build_Process_Handle);
            end if;
         end Register_Active_Build_Process;

         procedure Clear_Active_Build_Process is
         begin
            if S.Public_Build_Job_Active then
               S.Public_Build_Process_Handle :=
                 Editor.Build_Process_Control.No_Process_Handle;
               Editor.Build_Process_Control.Clear_Active_Process;
            end if;
         end Clear_Active_Build_Process;

         --  Hostkit asks this while it waits, and kills the process if it says yes. The
         --  cancel used to be carried out from elsewhere, by signalling the process id we
         --  published; asking here is the same answer, and it works on a host with no
         --  signals to send.
         function Cancellation_Requested return Boolean is
         begin
            return (S.Public_Build_Job_Active
                    and then S.Public_Build_Job_Cancellation =
                      Editor.Build_Runner_Policy.Cancellation_Requested)
              or else Editor.Build_Process_Control.Active_Cancel_Requested;
         end Cancellation_Requested;

         --  Called on the same slices as the wait, so the compiler's output reaches the UI
         --  while it is still being produced rather than all at once at the end.
         procedure Stream_While_Running is
         begin
            Stream_Capture_Deltas;
         end Stream_While_Running;

         procedure Publish (Process_Id : Integer) is
         begin
            Register_Active_Build_Process (Process_Id);
         end Publish;

         Arguments : Hostkit.String_Vectors.Vector;
         Outcome   : Hostkit.Process.Process_Outcome;
      begin
         for Argument of Request.Structured_Arguments loop
            Arguments.Append (Argument);
         end loop;

         Delete_File_If_Present (Stdout_Capture_File);
         Delete_File_If_Present (Stderr_Capture_File);

         --  This was fork, execvp, waitpid and kill, written out here -- which is why the
         --  editor did not link on Windows at all: undefined reference to waitpid, and to
         --  kill. It is Hostkit's now, with a body per host, and the POSIX one does exactly
         --  what this did.
         Outcome :=
           Hostkit.Process.Run_Captured
             (Program           => Program,
              Arguments         => Arguments,
              Working_Directory => Working,
              Stdout_Path       => Stdout_Capture_File,
              Stderr_Path       => Stderr_Capture_File,
              Timeout_Ms        => Policy.Timeout_Milliseconds,
              --  These are nested and the access types are library-level, which Ada will
              --  not allow through 'Access. They cannot outlive this call -- Run_Captured
              --  has returned before the frame goes -- so the accessibility rule is
              --  protecting against something that cannot happen here.
              Cancelled         => Cancellation_Requested'Unrestricted_Access,
              Poll              => Stream_While_Running'Unrestricted_Access,
              Started           => Publish'Unrestricted_Access);

         if not Outcome.Started then
            Clear_Active_Build_Process;
            Delete_File_If_Present (Stdout_Capture_File);
            Delete_File_If_Present (Stderr_Capture_File);
            return Build_Process_Run_Result (Process_Run_Execution_Error);
         end if;

         --  A cancellation and a deadline both end the process, and Hostkit reports both
         --  the same way -- it stopped because we stopped it. Which of the two it was is
         --  ours to know, and they do not mean the same thing to a user.
         Cancellation_Observed := Cancellation_Requested;

         Stream_Capture_Deltas;
         Clear_Active_Build_Process;

         Stdout_Output := Read_Bounded_Output_File
           (Stdout_Capture_File, Policy.Max_Output_Bytes, Stdout_Truncated);
         Stderr_Output := Read_Bounded_Output_File
           (Stderr_Capture_File, Policy.Max_Output_Bytes, Stderr_Truncated);

         Delete_File_If_Present (Stdout_Capture_File);
         Delete_File_If_Present (Stderr_Capture_File);

         --  124 is what a timed-out command exits with, by convention, and the callers
         --  already read it that way.
         if Outcome.Timed_Out and then not Cancellation_Observed then
            Exit_Code := 124;
         else
            Exit_Code := Outcome.Exit_Status;
         end if;

         return Enforce_Process_Output_Bounds
           ((Status        =>
               (if Stdout_Truncated or else Stderr_Truncated then
                   Process_Run_Output_Truncated
                elsif Cancellation_Observed then Process_Run_Cancelled
                elsif Outcome.Timed_Out then Process_Run_Timed_Out
                elsif Exit_Code = 0 then Process_Run_Succeeded
                else Process_Run_Failed),
             Output_Capture_Mode => Process_Output_Capture_Separated,
             Has_Exit_Code => True,
             Exit_Code     => Exit_Code,
             Stdout_Text   => Stdout_Output,
             Stderr_Text   => Stderr_Output,
             Stdout_Truncated => Stdout_Truncated,
             Stderr_Truncated => Stderr_Truncated),
            Policy);
      exception
         when others =>
            Clear_Active_Build_Process;
            Delete_File_If_Present (Stdout_Capture_File);
            Delete_File_If_Present (Stderr_Capture_File);
            return Build_Process_Run_Result (Process_Run_Execution_Error);
      end Execute_With_Native_Process_Supervisor;
   begin
      if not Validate_Process_Run_Request_For_Real_Execution (Request, Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      return Execute_With_Native_Process_Supervisor;
   end Execute_Process_Request_Real_Gated_With_State;

   function Execute_Process_Request_Real_Gated
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Detached_State : Editor.State.State_Type;
   begin
      return Execute_Process_Request_Real_Gated_With_State
        (Detached_State, Request, Policy);
   end Execute_Process_Request_Real_Gated;

   function Enforce_Process_Output_Bounds
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Process_Run_Result
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      return Result;
   end Enforce_Process_Output_Bounds;

   function Process_Fixture_Result_Is_Consistent
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Boolean
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return False;
      end if;

      case Result.Status is
         when Process_Run_Succeeded | Process_Run_Failed =>
            return Result.Has_Exit_Code;
         when Process_Run_Not_Available | Process_Run_Rejected
            | Process_Run_Execution_Error
            | Process_Run_Cancellation_Unsupported =>
            return not Result.Has_Exit_Code
              and then Length (Result.Stdout_Text) = 0
              and then Length (Result.Stderr_Text) = 0;
         when Process_Run_Timed_Out | Process_Run_Cancelled
            | Process_Run_Output_Truncated =>
            return not Result.Has_Exit_Code;
      end case;
   end Process_Fixture_Result_Is_Consistent;

   procedure Assert_Process_Fixture_Result_Consistent
     (Result : Process_Run_Result)
   is
      Conservative_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Fixture_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   begin
      pragma Assert
        (Process_Fixture_Result_Is_Consistent (Result, Conservative_Policy));
   end Assert_Process_Fixture_Result_Consistent;

   function Execute_Test_Fed_Process_Request
     (Request         : Process_Run_Request;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
   begin
      if Clean_Program'Length = 0 then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      return Supplied_Result;
   end Execute_Test_Fed_Process_Request;

   function Execute_Process_Request_Gated
     (Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
   begin
      if not Validate_Process_Execution_Policy (Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return Build_Process_Run_Result (Process_Run_Not_Available);
         when Process_Execution_Test_Fixture =>
            return Enforce_Process_Output_Bounds
              (Execute_Test_Fed_Process_Request (Request, Supplied_Result),
               Policy);
         when Process_Execution_Real_Fixture_Allowed =>
            return Build_Process_Run_Result (Process_Run_Rejected);
         when Process_Execution_Real_Allowed =>
            return Execute_Process_Request_Real_Gated (Request, Policy);
      end case;
   end Execute_Process_Request_Gated;

   function Execute_Process_Request_Gated_With_State
     (S               : in out Editor.State.State_Type;
      Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
   begin
      if not Validate_Process_Execution_Policy (Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return Build_Process_Run_Result (Process_Run_Not_Available);
         when Process_Execution_Test_Fixture =>
            return Enforce_Process_Output_Bounds
              (Execute_Test_Fed_Process_Request (Request, Supplied_Result),
               Policy);
         when Process_Execution_Real_Fixture_Allowed =>
            return Build_Process_Run_Result (Process_Run_Rejected);
         when Process_Execution_Real_Allowed =>
            return Execute_Process_Request_Real_Gated_With_State
              (S, Request, Policy);
      end case;
   end Execute_Process_Request_Gated_With_State;

   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Build/process runs are synchronous and retain no run id, pending
      --  result, late-delivery queue, output text, or build-owned feature state.
      null;
   end Reset_Build_Run_State_For_Project_Close;

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Workspace close has no build-run state to clear.
      null;
   end Reset_Build_Run_State_For_Workspace_Close;


end Editor.External_Producers.Build_Command_Execution.Real_Process;
