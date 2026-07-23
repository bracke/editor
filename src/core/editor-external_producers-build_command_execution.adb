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
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;

package body Editor.External_Producers.Build_Command_Execution is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;

   Build_Output_Capture_Sequence : Natural := 0;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_One_Process_Argument;

   function Contains_Control_Character (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Control_Character;

   function Build_Status_Label (Status : Build_Run_Status) return String is
   begin
      case Status is
         when Build_Run_Succeeded =>
            return "Build: succeeded";
         when Build_Run_Failed =>
            return "Build: failed";
         when Build_Run_Not_Available =>
            return "Build: not available";
         when Build_Run_Rejected =>
            return "Build: rejected";
         when Build_Run_Execution_Error =>
            return "Build: execution error";
         when Build_Run_Timed_Out =>
            return "Build: timed out";
         when Build_Run_Cancelled =>
            return "Build: cancelled";
         when Build_Run_Cancellation_Unsupported =>
            return "Build: cancellation unsupported";
         when Build_Run_Output_Truncated =>
            return "Build: output truncated";
      end case;
   end Build_Status_Label;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return "Build: build fixture accepted";
         when Real_Build_Fixture_Rejected_Disabled =>
            return "Build: real build fixture disabled";
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when Real_Build_Fixture_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when Real_Build_Fixture_Rejected_Shell =>
            return "Build: shell execution disabled";
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Real_Build_Fixture_Not_Available =>
            return "Build: build fixture unavailable";
         when Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Custom_Tool
            | Real_Build_Fixture_Rejected_Ambiguous_Gate =>
            return "Build: build fixture rejected";
      end case;
   end Real_Build_Tool_Fixture_Rejection_Feedback;

   procedure Append_Output_Text_Lines
     (Text  : String;
      Lines : in out Diagnostic_Text_Line_Array)
   is
      Start : Positive := Text'First;
      Stop  : Natural;
      Last  : Natural;
   begin
      if Text'Length = 0 then
         return;
      end if;

      while Start <= Text'Last loop
         Stop := Start;
         while Stop <= Text'Last and then Text (Stop) /= ASCII.LF loop
            Stop := Stop + 1;
         end loop;

         Last := Stop - 1;
         if Last >= Start and then Text (Last) = ASCII.CR then
            Last := Last - 1;
         end if;

         if Last >= Start then
            Diagnostic_Text_Line_Vectors.Append
              (Container => Lines,
               New_Item  => To_Unbounded_String (Text (Start .. Last)));
         else
            Diagnostic_Text_Line_Vectors.Append
              (Container => Lines,
               New_Item  => Null_Unbounded_String);
         end if;

         Start := Stop + 1;
      end loop;
   end Append_Output_Text_Lines;

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result) return Diagnostic_Text_Line_Array
   is
      Lines : Diagnostic_Text_Line_Array;
   begin
      if Result.Diagnostic_Lines.Length > 0 then
         return Result.Diagnostic_Lines;
      end if;

      Append_Output_Text_Lines (To_String (Result.Stderr_Text), Lines);
      Append_Output_Text_Lines (To_String (Result.Stdout_Text), Lines);
      return Lines;
   end Extract_Diagnostic_Lines_From_Build_Result;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
   is
      Max_Build_Diagnostic_Input_Lines : constant Natural := 512;
      Source : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Result);
      Lines  : Diagnostic_Text_Line_Array;
      Count  : Natural := 0;
   begin
      if not Source.Is_Empty then
         for I in Source.First_Index .. Source.Last_Index loop
            exit when Count >= Max_Build_Diagnostic_Input_Lines;
            Lines.Append (Source.Element (I));
            Count := Count + 1;
         end loop;
      end if;

      return Ingest_Diagnostic_Lines_From_Command
        (S, Producer, Lines, Show_Diagnostics);
   end Ingest_Build_Run_Diagnostics;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
      Accepted : constant Natural :=
        Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Rejected : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Rejected_Malformed_Count;
      Ignored : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Ignored_Blank_Count
        + Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count;
      Message : Unbounded_String :=
        To_Unbounded_String
          (case Build_Result.Status is
              when Build_Run_Timed_Out =>
                 "Build failed: timed out",
              when Build_Run_Cancelled =>
                 "Build cancelled",
              when Build_Run_Cancellation_Unsupported =>
                 "Build unavailable: cancellation unsupported",
              when others =>
                 Build_Status_Label (Build_Result.Status));
   begin
      if Accepted > 0
        and then Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed | Build_Run_Execution_Error
      then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String
              (", ingested "
               & Editor.Image_Helpers.Trim_Image (Accepted)
               & " diagnostics"));
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
      then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String (", no diagnostics parsed"));
         if Ignored > 0 then
            Append
              (Source => Message,
               New_Item => To_Unbounded_String
                 (", ignored "
                  & Editor.Image_Helpers.Trim_Image (Ignored)
                  & " lines"));
         end if;
      end if;

      if Accepted = 0 and then Rejected > 0 then
         Append
           (Source => Message,
            New_Item => To_Unbounded_String
              (", rejected "
               & Editor.Image_Helpers.Trim_Image (Rejected)
               & " malformed lines"));
      end if;

      return To_String (Message);
   end Build_Build_Command_Feedback;

   function Sanitized_Process_Label (Program_Label : String) return String
   is
      Clean  : constant String := Ada.Strings.Fixed.Trim (Program_Label, Both);
      Result : Unbounded_String := Null_Unbounded_String;
      Limit  : Natural := 0;
   begin
      if Clean'Length = 0 then
         return "process";
      end if;

      for C of Clean loop
         exit when Limit >= 32;
         if C in 'a' .. 'z'
           or else C in 'A' .. 'Z'
           or else C in '0' .. '9'
           or else C = '-'
           or else C = '_'
           or else C = '.'
         then
            Append (Result, C);
         else
            Append (Result, '_');
         end if;
         Limit := Limit + 1;
      end loop;

      if Length (Result) = 0 then
         return "process";
      else
         return To_String (Result);
      end if;
   end Sanitized_Process_Label;

   function Build_Output_Capture_Path
     (Working_Directory : String;
      Program_Label     : String) return String
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Working_Directory, Both);
      Stamp : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Integer (Ada.Calendar.Seconds (Ada.Calendar.Clock) * 1000.0)),
         Both);
      Name     : Unbounded_String;
   begin
      if Build_Output_Capture_Sequence = Natural'Last then
         Build_Output_Capture_Sequence := 0;
      else
         Build_Output_Capture_Sequence := Build_Output_Capture_Sequence + 1;
      end if;

      declare
         Sequence : constant String :=
           Editor.Image_Helpers.Trim_Image (Build_Output_Capture_Sequence);
      begin
         Name := To_Unbounded_String
           (".editor_build_output_"
            & Sanitized_Process_Label (Program_Label)
            & "_" & Stamp & "_" & Sequence
            & ".tmp");
      end;

      if Clean'Length = 0 or else Clean = "/" then
         return "/tmp/" & To_String (Name);
      elsif Clean (Clean'Last) = '/' then
         return Clean & To_String (Name);
      else
         return Clean & "/" & To_String (Name);
      end if;
   end Build_Output_Capture_Path;

   procedure Delete_File_If_Present (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Delete_File_If_Present;

   function Read_Bounded_Output_File
     (Path      : String;
      Max_Bytes : Natural;
      Truncated : out Boolean) return Unbounded_String
   is
      use Ada.Streams;
      package SIO renames Ada.Streams.Stream_IO;
      File   : SIO.File_Type;
      Buffer : Stream_Element_Array (1 .. 4096);
      Last   : Stream_Element_Offset;
      Result : Unbounded_String := Null_Unbounded_String;
      Read_Count : Natural := 0;
   begin
      Truncated := False;
      if Max_Bytes = 0 or else not Ada.Directories.Exists (Path) then
         return Result;
      end if;

      SIO.Open (File, SIO.In_File, Path);
      while not SIO.End_Of_File (File) loop
         SIO.Read (File, Buffer, Last);
         exit when Last < Buffer'First;

         for I in Buffer'First .. Last loop
            if Read_Count >= Max_Bytes then
               Truncated := True;
               SIO.Close (File);
               return Result;
            end if;
            Append (Result, Character'Val (Integer (Buffer (I))));
            Read_Count := Read_Count + 1;
         end loop;
      end loop;
      SIO.Close (File);
      return Result;
   exception
      when others =>
         begin
            if SIO.Is_Open (File) then
               SIO.Close (File);
            end if;
         exception
            when others =>
               null;
         end;
         Truncated := False;
         return Null_Unbounded_String;
   end Read_Bounded_Output_File;

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

   function Run_Build_Command_Test_Seam
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Show_Diagnostics : Boolean := False) return Build_Command_Result
   is
   begin
      return Run_Build_Command_Test_Seam_With_Runner
        (S, Request,
         (Mode                     => Process_Execution_Disabled,
          Allow_Real_Execution     => False,
          Allow_Shell              => False,
          Max_Output_Bytes         => 262_144,
          Require_Absolute_Program => False,
          Timeout_Milliseconds     => 0),
         Build_Process_Run_Result (Process_Run_Not_Available),
         Show_Diagnostics);
   end Run_Build_Command_Test_Seam;

   function Run_Build_Command_Test_Seam_With_Runner
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Policy           : Process_Execution_Policy;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False);
      Show_Diagnostics : Boolean := False) return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Request, Policy);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Diagnostic_Result := Empty_Diagnostic_Line_Command_Result;
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback (Preflight.Build_Request_Status));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Diagnostic_Result := Empty_Diagnostic_Line_Command_Result;
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         Build_Result := Execute_Build_Request_With_Process_Policy
           (Request, Policy, Supplied_Result);
         Diagnostic_Result := Ingest_Build_Run_Diagnostics
           (S, Producer, Build_Result, Show_Diagnostics);
         Message := To_Unbounded_String
           (Build_Build_Command_Feedback (Build_Result, Diagnostic_Result));
      end if;


      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_Test_Seam_With_Runner;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String
   is
      Message : Unbounded_String :=
        To_Unbounded_String
          (Build_Build_Command_Feedback (Build_Result, Diagnostic_Result));
   begin
      if not Diagnostics_Ingestion_Allowed then
         if Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed then
            return Build_Status_Label (Build_Result.Status)
              & ", diagnostics ingestion disabled";
         else
            return "Build: diagnostics ingestion disabled";
         end if;
      end if;

      if Build_Result.Status = Build_Run_Not_Available
        and then Diagnostic_Result.Ingestion.Parse_Input_Count = 0
      then
         return "Build: real execution unavailable";
      end if;

      return To_String (Message);
   end Build_Gated_Build_Command_Feedback;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);

      if Policy.Mode = Process_Execution_Disabled then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Policy.Allow_Shell then
         Process_Status := Process_Request_Rejected_Shell_Disallowed;
      elsif not Validate_Process_Execution_Policy (Policy) then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Ada.Strings.Fixed.Trim
        (To_String (Process_Request.Program_Label), Both)'Length = 0
      then
         Process_Status := Process_Request_Rejected_Empty_Program;
      elsif Policy.Mode = Process_Execution_Test_Fixture then
         Process_Status := Process_Request_Valid;
      elsif Policy.Mode = Process_Execution_Real_Fixture_Allowed then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      else
         Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
           (Process_Request, Policy);
      end if;

      return
        (Build_Request_Status   => Build_Status,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Build_Run_Request;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Build_Status := Validate_Build_Request_Provenance (Request, Gate);
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Provenance = Build_Request_From_User_Opt_In
        and then Gate.Consent /= Build_Consent_User_Confirmed
      then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Tool = Custom_Build_Tool then
         return
           (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Request;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_User_Opt_In_Build_Request (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Consent /= Build_Consent_User_Confirmed then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Build_Run
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Allow_Shell
        or else Gate.Process_Policy.Max_Output_Bytes = 0
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      case Request.Tool is
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
         when Custom_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
         when No_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_No_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
      end case;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_User_Opt_In_Build_Request;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         if Result.Build_Request_Status = Build_Request_Rejected_Provenance
           or else Result.Build_Request_Status = Build_Request_Rejected_Unknown_Provenance
         then
            return "Build: user opt-in required";
         else
            return Build_Request_Rejection_Feedback (Result.Build_Request_Status);
         end if;
      elsif Result.Process_Request_Status /= Process_Request_Valid then
         if Result.Process_Request_Status = Process_Request_Rejected_Execution_Disabled then
            return "Build: real build execution disabled";
         else
            return Process_Request_Rejection_Feedback
              (Result.Process_Request_Status);
         end if;
      else
         return "Build: accepted";
      end if;
   end Build_User_Opt_In_Build_Feedback;

   function Empty_User_Opt_In_Build_Command_Context
     return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => False,
         Request     => (Tool => No_Build_Tool,
                         Provenance => Build_Request_Unknown,
                         Working_Label => Null_Unbounded_String,
                         Command_Label => Null_Unbounded_String,
                         Arguments => Null_Unbounded_String,
                         Structured_Arguments => Empty_Process_Arguments),
         Gate        => Build_Default_Execution_Gate);
   end Empty_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Context
     (Tool              : Build_Tool_Kind;
      Program_Label     : String;
      Working_Label     : String;
      Arguments         : Process_Argument_Vector;
      Consent           : Build_Execution_Consent;
      Allow_Diagnostics : Boolean;
      Show_Diagnostics  : Boolean)
      return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => True,
         Request     => Build_User_Opt_In_Request
           (Tool, Program_Label, Working_Label, Arguments),
         Gate        => Build_Real_Execution_Gate
           (Allow_Diagnostics_Ingestion => Allow_Diagnostics,
            Show_Diagnostics            => Show_Diagnostics,
            Consent                     => Consent));
   end Build_User_Opt_In_Command_Context;

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status
   is
      Request : constant Build_Run_Request := Context.Request;
      Gate    : constant Build_Execution_Gate := Context.Gate;
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      if not Context.Has_Request then
         return User_Build_Context_Rejected_Missing_Context;
      end if;

      if Request.Provenance = Build_Request_Unknown
        and then Request.Tool = No_Build_Tool
        and then Clean_Command'Length = 0
        and then Request.Structured_Arguments.Is_Empty
      then
         return User_Build_Context_Rejected_Missing_Request;
      end if;

      if not Gate.Allow_Build_Run
        and then Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Gate.Process_Policy.Allow_Real_Execution
      then
         return User_Build_Context_Rejected_Missing_Gate;
      end if;

      if Gate.Consent = Build_Consent_Not_Provided then
         return User_Build_Context_Rejected_Missing_Consent;
      elsif Gate.Consent /= Build_Consent_User_Confirmed then
         return User_Build_Context_Rejected_Missing_Consent;
      end if;

      case Request.Provenance is
         when Build_Request_From_User_Opt_In =>
            null;
         when Build_Request_From_Implicit_Source =>
            return User_Build_Context_Rejected_Implicit_Source;
         when Build_Request_From_Test
            | Build_Request_From_Fixture
            | Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return User_Build_Context_Rejected_Provenance;
      end case;

      case Request.Tool is
         when No_Build_Tool | Custom_Build_Tool =>
            return User_Build_Context_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      if Length (Request.Arguments) > 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty or else Clean_Command'Length = 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return User_Build_Context_Rejected_Shell;
      end if;

      if Ada.Strings.Fixed.Trim
          (To_String (Request.Working_Label), Both)'Length > 0
      then
         return User_Build_Context_Rejected_Working_Context;
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Max_Output_Bytes = 0
        or else not Validate_Build_Execution_Gate (Gate)
      then
         return User_Build_Context_Rejected_Ambiguous_Execution_Path;
      end if;

      return User_Build_Context_Valid;
   end Validate_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
   begin
      case Status is
         when User_Build_Context_Valid =>
            case Result.Build_Result.Status is
               when Build_Run_Succeeded =>
                  if Ingested > 0 then
                     return "Build: succeeded, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: succeeded";
                  end if;
               when Build_Run_Failed =>
                  if Ingested > 0 then
                     return "Build: failed, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: failed";
                  end if;
               when Build_Run_Not_Available =>
                  return "Build: real execution unavailable";
               when Build_Run_Rejected =>
                  return "Build: rejected";
               when Build_Run_Execution_Error =>
                  return "Build: execution error";
               when Build_Run_Timed_Out =>
                  return "Build failed: timed out";
               when Build_Run_Cancelled =>
                  return "Build cancelled";
               when Build_Run_Cancellation_Unsupported =>
                  return "Build unavailable: cancellation unsupported";
               when Build_Run_Output_Truncated =>
                  return "Build: output truncated";
            end case;
         when User_Build_Context_Rejected_Missing_Context
            | User_Build_Context_Rejected_Missing_Request
            | User_Build_Context_Rejected_Provenance =>
            return "Build: user opt-in required";
         when User_Build_Context_Rejected_Missing_Gate =>
            return "Build: real build execution disabled";
         when User_Build_Context_Rejected_Missing_Consent =>
            return "Build: execution consent required";
         when User_Build_Context_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when User_Build_Context_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when User_Build_Context_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when User_Build_Context_Rejected_Shell =>
            return "Build: shell execution disabled";
         when User_Build_Context_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when User_Build_Context_Rejected_Ambiguous_Execution_Path =>
            return "Build: invalid build command context";
      end case;
   end Build_User_Opt_In_Command_Feedback;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean
   is
   begin
      return Context.Has_Request;
   end User_Opt_In_Build_Command_Context_Is_Available;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid
        or else Result.Process_Request_Status /= Process_Request_Valid
      then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Program_Label), Both)'Length > 0
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Arguments), Both)'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end User_Opt_In_Build_Preflight_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Preflight_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Preflight_Consistent;

   function User_Opt_In_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
   begin
      if Message'Length = 0 then
         return False;
      end if;

      if Result.Build_Result.Status in Build_Run_Rejected | Build_Run_Not_Available then
         return Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0;
      end if;

      return Gated_Build_Command_Result_Is_Consistent (Result);
   end User_Opt_In_Build_Command_Result_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Command_Result_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Command_Result_Consistent;

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean
   is
   begin
      case Fixture is
         when No_Real_Build_Tool_Fixture =>
            return False;
         when GPRbuild_Version_Fixture
            | Alire_Version_Fixture
            | Diagnostic_Output_Fixture =>
            return True;
      end case;
   end Real_Build_Tool_Fixture_Is_Approved;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate)
        and then Gate.Allow_Build_Run
        and then Gate.Allow_Real_Build_Tool_Fixture
        and then not Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
        and then Gate.Process_Policy.Allow_Real_Execution
        and then not Gate.Process_Policy.Allow_Shell
        and then Gate.Process_Policy.Max_Output_Bytes > 0;
   end Validate_Real_Build_Tool_Fixture_Gate;

   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Working_Status : Process_Request_Validation_Status;
      Clean_Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return Real_Build_Fixture_Rejected_Ambiguous_Gate;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return Real_Build_Fixture_Rejected_Shell;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Real_Build_Fixture_Rejected_Disabled;
      end if;

      if not Real_Build_Tool_Fixture_Is_Approved (Fixture) then
         return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end if;

      case Request.Provenance is
         when Build_Request_From_Implicit_Source =>
            return Real_Build_Fixture_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In
            | Build_Request_From_Test
            | Build_Request_From_Fixture =>
            null;
         when Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return Real_Build_Fixture_Rejected_Provenance;
      end case;

      if Build_Status = Build_Request_Rejected_Implicit_Source then
         return Real_Build_Fixture_Rejected_Implicit_Source;
      elsif Build_Status /= Build_Request_Valid then
         if Request.Tool = Custom_Build_Tool then
            return Real_Build_Fixture_Rejected_Custom_Tool;
         else
            return Real_Build_Fixture_Rejected_Provenance;
         end if;
      end if;

      if Request.Tool = Custom_Build_Tool then
         return Real_Build_Fixture_Rejected_Custom_Tool;
      end if;

      case Fixture is
         when GPRbuild_Version_Fixture =>
            if Request.Tool /= GPRbuild_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Alire_Version_Fixture =>
            if Request.Tool /= Alire_Build_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Diagnostic_Output_Fixture =>
            null;
         when No_Real_Build_Tool_Fixture =>
            return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end case;

      Working_Status := Validate_Build_Working_Context (Request, Gate);
      if Working_Status /= Process_Request_Valid then
         return Real_Build_Fixture_Rejected_Working_Context;
      end if;

      if Clean_Opaque'Length > 0 or else not Request.Structured_Arguments.Is_Empty then
         return Real_Build_Fixture_Rejected_Opaque_Arguments;
      end if;

      return Real_Build_Fixture_Valid;
   end Validate_Real_Build_Tool_Fixture_Request;

   function Real_Build_Tool_Fixture_Status_To_Build_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Build_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Build_Request_Valid;
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Real_Build_Fixture_Rejected_Custom_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when Real_Build_Fixture_Rejected_Provenance =>
            return Build_Request_Rejected_Provenance;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Shell
            | Real_Build_Fixture_Rejected_Opaque_Arguments
            | Real_Build_Fixture_Rejected_Working_Context
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Build_Request_Valid;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Build_Status;

   function Real_Build_Tool_Fixture_Status_To_Process_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Process_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Process_Request_Valid;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Real_Build_Fixture_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Real_Build_Fixture_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Real_Build_Fixture_Rejected_Working_Context =>
            return Process_Request_Rejected_Unsupported_Working_Directory;
         when Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Implicit_Source
            | Real_Build_Fixture_Rejected_Custom_Tool =>
            return Process_Request_Rejected_Execution_Disabled;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Process_Status;

   function Validate_Real_Build_Tool_Fixture_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Real_Build_Tool_Fixture_Provenance;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request
   is
      pragma Unreferenced (Request);
   begin
      case Fixture is
         when GPRbuild_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Alire_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Diagnostic_Output_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("diagnostic-output-fixture"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument
                 ("--diagnostic-output-fixture"));
         when No_Real_Build_Tool_Fixture =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Real_Build_Tool_Fixture_Process_Request;

   function Validate_Real_Build_Tool_Fixture_Process_Request
     (Request : Process_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Process_Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Max_Output_Bytes = 0 then
         return Process_Request_Rejected_Invalid_Argument;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Opaque_Args'Length > 0 then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      for Arg of Request.Structured_Arguments loop
         declare
            Value : constant String := To_String (Arg);
         begin
            if Value'Length = 0 or else Contains_Control_Character (Value) then
               return Process_Request_Rejected_Invalid_Argument;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Real_Build_Tool_Fixture_Process_Request;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Build_Status : constant Build_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Build_Status (Validation);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Process_Status (Validation);
   begin
      if Validation /= Real_Build_Fixture_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Real_Build_Tool_Fixture_Process_Request
        (Request, Fixture);
      Process_Status := Validate_Real_Build_Tool_Fixture_Process_Request
        (Process_Request, Gate);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Fixture;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
   begin
      if Build_Result.Status = Build_Run_Not_Available then
         return "Build: build fixture unavailable";
      elsif Build_Result.Status = Build_Run_Rejected then
         return "Build: build fixture rejected";
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
        and then Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0
      then
         return Build_Status_Label (Build_Result.Status)
           & ", no diagnostics parsed";
      else
         return Build_Build_Command_Feedback (Build_Result, Diagnostic_Result);
      end if;
   end Build_Real_Build_Tool_Fixture_Feedback;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         return not Result.Has_Process_Request
           and then Result.Process_Request_Status /= Process_Request_Valid;
      end if;

      if Result.Process_Request_Status = Process_Request_Valid then
         return Result.Has_Process_Request;
      end if;

      return not Result.Has_Process_Request;
   end Build_Preflight_Result_Is_Consistent;

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
      Program : constant String := To_String (Result.Process_Request.Program_Label);
      Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Result.Process_Request.Arguments), Both);
   begin
      if not Build_Preflight_Result_Is_Consistent (Result) then
         return False;
      end if;

      if Result.Build_Request_Status = Build_Request_Rejected_Implicit_Source
        and then Result.Has_Process_Request
      then
         return False;
      end if;

      if Result.Process_Request_Status /= Process_Request_Valid then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Program'Length > 0
        and then Opaque'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
   begin
      if Message'Length = 0 then
         return False;
      end if;

      case Result.Build_Result.Status is
         when Build_Run_Succeeded | Build_Run_Failed =>
            if not Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
         when Build_Run_Not_Available | Build_Run_Rejected
            | Build_Run_Execution_Error | Build_Run_Timed_Out
            | Build_Run_Cancelled | Build_Run_Cancellation_Unsupported
            | Build_Run_Output_Truncated =>
            if Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
      end case;

      if Result.Build_Result.Status = Build_Run_Not_Available
        and then Message = "Build: succeeded"
      then
         return False;
      end if;

      if Result.Build_Result.Status = Build_Run_Execution_Error
        and then Ingested > 0
      then
         return False;
      end if;

      if Ingested = 0 and then Parsed = 0 then
         return Message'Length > 0;
      end if;

      return True;
   end Real_Build_Tool_Fixture_Command_Result_Is_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Preflight_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Preflight_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Command_Result_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Command_Result_Consistent;

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String
   is
   begin
      case Status is
         when Fixture_Request_Valid =>
            return "Build: fixture accepted";
         when Fixture_Request_Rejected_Disabled =>
            return "Build: fixture execution disabled";
         when Fixture_Request_Not_Available =>
            return "Build: fixture unavailable";
         when Fixture_Request_Rejected_Unknown_Fixture
            | Fixture_Request_Rejected_Shell
            | Fixture_Request_Rejected_Opaque_Arguments
            | Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return "Build: fixture rejected";
      end case;
   end Process_Fixture_Rejection_Feedback;

   function Run_Build_Command_With_Gate
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : Build_Preflight_Result;
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Mode : Process_Execution_Mode;
      Process_Result : Process_Run_Result;
      Diagnostics_Used : Boolean := False;
   begin
      if not Validate_Build_Execution_Gate (Gate) then
         Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         return
           (Build_Result      => Build_Result,
            Diagnostic_Result => Diagnostic_Result,
            Command_Message   => To_Unbounded_String ("Build: execution disabled"));
      end if;

      if Gate.Allow_Real_Build_Tool_Execution then
         Preflight := Preflight_Real_Build_Tool_Request (Request, Gate);
      else
         Preflight := Preflight_Build_Run_Request (Request, Gate.Process_Policy);
      end if;

      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback (Preflight.Build_Request_Status));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         Mode := Select_Process_Runner_Mode (Gate, Gate.Process_Policy);
         if Mode = Process_Execution_Disabled then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
            Message := To_Unbounded_String ("Build: execution disabled");
         else
            Process_Result := Execute_Process_Request_Gated_With_State
              (S, Preflight.Process_Request, Gate.Process_Policy, Supplied_Result);
            Build_Result := Build_Result_From_Process_Result
              (Request, Process_Result);

            if Gate.Allow_Diagnostics_Ingestion then
               Diagnostic_Result := Ingest_Build_Run_Diagnostics
                 (S, Producer, Build_Result, Gate.Show_Diagnostics);
               Diagnostics_Used := True;
            end if;

            Message := To_Unbounded_String
              (Build_Gated_Build_Command_Feedback
                 (Build_Result, Diagnostic_Result, Diagnostics_Used,
                  Gate.Allow_Diagnostics_Ingestion));
         end if;
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_With_Gate;

   function Run_Build_Command_With_Fixture_Gate
     (S       : in out Editor.State.State_Type;
      Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Gate    : Build_Execution_Gate) return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Diagnostics_Used : Boolean := False;
      Fixture_Status : Process_Fixture_Validation_Status;
   begin
      if not Validate_Build_Execution_Gate (Gate)
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Fixture_Allowed
      then
         Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         return
           (Build_Result      => Build_Result,
            Diagnostic_Result => Diagnostic_Result,
            Command_Message   => To_Unbounded_String ("Build: fixture execution disabled"));
      end if;

      if Validate_Build_Run_Request_Status (Request) /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback
              (Validate_Build_Run_Request_Status (Request)));
      else
         Fixture_Status := Validate_Process_Fixture_Request
           (Fixture, Gate.Process_Policy);
         if Fixture_Status /= Fixture_Request_Valid then
            if Fixture_Status = Fixture_Request_Rejected_Disabled
              or else Fixture_Status = Fixture_Request_Not_Available
            then
               Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
            else
               Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
            end if;
            Message := To_Unbounded_String
              (Process_Fixture_Rejection_Feedback (Fixture_Status));
         else
            Build_Result := Build_Process_Fixture_Result
              (Request, Fixture, Gate.Process_Policy);

            if Gate.Allow_Diagnostics_Ingestion then
               Diagnostic_Result := Ingest_Build_Run_Diagnostics
                 (S, Producer, Build_Result, Gate.Show_Diagnostics);
               Diagnostics_Used := True;
            end if;

            Message := To_Unbounded_String
              (Build_Gated_Build_Command_Feedback
                 (Build_Result, Diagnostic_Result, Diagnostics_Used,
                  Gate.Allow_Diagnostics_Ingestion));
         end if;
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_With_Fixture_Gate;

   function Run_Real_Build_Tool_Fixture_With_Gate
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Fixture          : Real_Build_Tool_Fixture_Kind;
      Gate             : Build_Execution_Gate;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture (Request, Fixture, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Process_Result : Process_Run_Result;
   begin
      if Validation /= Real_Build_Fixture_Valid then
         if Validation = Real_Build_Fixture_Rejected_Disabled
           or else Validation = Real_Build_Fixture_Not_Available
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Real_Build_Tool_Fixture_Rejection_Feedback (Validation));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         --  keeps the real build-tool fixture path behind the same
         --  runner abstraction. Tool availability can therefore resolve to a
         --  deterministic not-available result without PATH probing in preflight.
         Process_Result := Enforce_Process_Output_Bounds
           (Supplied_Result, Gate.Process_Policy);
         Build_Result := Build_Result_From_Process_Result
           (Request, Process_Result);

         if Gate.Allow_Diagnostics_Ingestion then
            Diagnostic_Result := Ingest_Build_Run_Diagnostics
              (S, Producer, Build_Result, Gate.Show_Diagnostics);
         end if;

         Message := To_Unbounded_String
           (Build_Real_Build_Tool_Fixture_Feedback
              (Build_Result, Diagnostic_Result));
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Real_Build_Tool_Fixture_With_Gate;

   function Run_User_Opt_In_Build_Command_Test_Seam
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Request, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Process_Result : Process_Run_Result;
      Diagnostics_Used : Boolean := False;
      Message : Unbounded_String;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_User_Opt_In_Build_Feedback (Preflight));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Build_User_Opt_In_Build_Feedback (Preflight));
      else
         --  The user-opt-in test seam is internal/test-only in . It
         --  consumes a completed test-controlled process result through the
         --  same result/bounds/diagnostic pipeline, without invoking a platform
         --  runner or retaining a process handle.
         Process_Result := Enforce_Process_Output_Bounds
           (Supplied_Result, Gate.Process_Policy);
         Build_Result := Build_Result_From_Process_Result (Request, Process_Result);

         if Gate.Allow_Diagnostics_Ingestion then
            Diagnostic_Result := Ingest_Build_Run_Diagnostics
              (S, Producer, Build_Result, Gate.Show_Diagnostics);
            Diagnostics_Used := True;
         end if;

         Message := To_Unbounded_String
           (Build_Gated_Build_Command_Feedback
              (Build_Result, Diagnostic_Result, Diagnostics_Used,
               Gate.Allow_Diagnostics_Ingestion));
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_User_Opt_In_Build_Command_Test_Seam;

   function Execute_Build_Request
     (Request : Build_Run_Request) return Build_Run_Result
   is
      Process_Request : Process_Run_Request;
      Process_Result  : Process_Run_Result;
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Result := Execute_Process_Request_Default (Process_Request);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Execute_Build_Request;

   function Execute_Test_Fed_Build_Request
     (Request         : Build_Run_Request;
      Supplied_Result : Build_Run_Result) return Build_Run_Result
   is
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      return Supplied_Result;
   end Execute_Test_Fed_Build_Request;

   function Execute_Build_Request_With_Process_Policy
     (Request         : Build_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Run_Result
   is
      Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Request, Policy);
      Process_Result  : Process_Run_Result;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      if Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            return Build_Build_Run_Result (Build_Run_Not_Available);
         else
            return Build_Build_Run_Result (Build_Run_Rejected);
         end if;
      end if;

      Process_Result := Execute_Process_Request_Gated
        (Preflight.Process_Request, Policy, Supplied_Result);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Execute_Build_Request_With_Process_Policy;

   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : User_Opt_In_Build_Command_Context;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Status : constant User_Opt_In_Build_Command_Context_Status :=
        Validate_User_Opt_In_Build_Command_Context (Context);
      Empty_Result : constant Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Build_Status : Build_Run_Status := Build_Run_Rejected;
      Result : Build_Command_Result;
   begin
      if Status /= User_Build_Context_Valid then
         if Status = User_Build_Context_Rejected_Missing_Gate
           or else Status = User_Build_Context_Rejected_Ambiguous_Execution_Path
         then
            Build_Status := Build_Run_Not_Available;
         end if;

         Result :=
           (Build_Result      => Build_Build_Run_Result (Build_Status),
            Diagnostic_Result => Empty_Result,
            Command_Message   => Null_Unbounded_String);
         Result.Command_Message := To_Unbounded_String
           (Build_User_Opt_In_Command_Feedback (Status, Result));
         return Result;
      end if;

      Result := Run_User_Opt_In_Build_Command_Test_Seam
        (S, Context.Request, Context.Gate, Supplied_Result);
      Result.Command_Message := To_Unbounded_String
        (Build_User_Opt_In_Command_Feedback (Status, Result));
      return Result;
   end Execute_User_Opt_In_Build_Command;

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

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status
   is
   begin
      if Policy.Allow_Shell then
         return Fixture_Request_Rejected_Shell;
      end if;

      if not Validate_Process_Execution_Policy (Policy)
        or else Policy.Mode /= Process_Execution_Real_Fixture_Allowed
        or else not Policy.Allow_Real_Execution
      then
         return Fixture_Request_Rejected_Disabled;
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Fixture_Request_Rejected_Output_Limit;
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Fixture_Request_Rejected_Unknown_Fixture;
         when Echo_Diagnostic_Fixture | Exit_Code_Fixture =>
            null;
      end case;

      for Arg of Fixture.Arguments loop
         if Contains_Control_Character (To_String (Arg)) then
            return Fixture_Request_Rejected_Invalid_Argument;
         end if;
      end loop;

      return Fixture_Request_Valid;
   end Validate_Process_Fixture_Request;

   function Validate_Process_Fixture_Request_Status
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
   begin
      case Status is
         when Fixture_Request_Valid =>
            return Process_Request_Valid;
         when Fixture_Request_Rejected_Disabled
            | Fixture_Request_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Fixture_Request_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Fixture_Request_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Fixture_Request_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return Process_Request_Rejected_Invalid_Argument;
      end case;
   end Validate_Process_Fixture_Request_Status;

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean
   is
   begin
      return Validate_Process_Fixture_Request (Fixture, Policy) =
        Fixture_Request_Valid;
   end Process_Fixture_Request_Is_Valid;

   function Build_Process_Fixture_Request
     (Kind  : Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, First);
      Append_Process_Argument (Args, Second);
      Append_Process_Argument (Args, Third);
      return (Kind => Kind, Arguments => Args);
   end Build_Process_Fixture_Request;

   procedure Append_With_Newline
     (Target : in out Unbounded_String;
      Value  : String)
   is
   begin
      if Length (Target) > 0 then
         Append (Target, ASCII.LF);
      end if;
      Append (Target, Value);
   end Append_With_Newline;

   procedure Append_Fixture_Output_Line
     (Target   : in out Unbounded_String;
      Has_Line : in out Boolean;
      Value    : String)
   is
   begin
      if Has_Line then
         Append (Target, ASCII.LF);
      end if;
      Append (Target, Value);
      Has_Line := True;
   end Append_Fixture_Output_Line;

   function Execute_Process_Request_Real_Fixture
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
      Out_Text : Unbounded_String := Null_Unbounded_String;
      Err_Text : Unbounded_String := Null_Unbounded_String;
      Out_Has_Line : Boolean := False;
      Err_Has_Line : Boolean := False;
      Use_Stderr : Boolean := False;
      Use_Mixed   : Boolean := False;
      First_Index : Natural := 0;
      Code : Integer := 0;
   begin
      if Status = Fixture_Request_Rejected_Disabled
        or else Status = Fixture_Request_Not_Available
      then
         return Build_Process_Run_Result (Process_Run_Not_Available);
      elsif Status /= Fixture_Request_Valid then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Build_Process_Run_Result (Process_Run_Rejected);

         when Echo_Diagnostic_Fixture =>
            if Fixture.Arguments.Length > 0 then
               declare
                  First : constant String :=
                    To_String (Fixture.Arguments.First_Element);
               begin
                  if First = "stderr" then
                     Use_Stderr := True;
                     First_Index := 1;
                  elsif First = "stdout" then
                     First_Index := 1;
                  elsif First = "mixed" then
                     Use_Mixed := True;
                     First_Index := Natural (Fixture.Arguments.Length);
                  end if;
               end;
            end if;

            if Use_Mixed and then Fixture.Arguments.Length > 1 then
               Append_Fixture_Output_Line
                 (Err_Text, Err_Has_Line,
                  To_String (Fixture.Arguments.Element (1)));
               if Fixture.Arguments.Length > 2 then
                  Append_Fixture_Output_Line
                    (Out_Text, Out_Has_Line,
                     To_String (Fixture.Arguments.Element (2)));
               end if;
            elsif Natural (Fixture.Arguments.Length) > First_Index then
               for I in First_Index .. Natural (Fixture.Arguments.Length) - 1 loop
                  declare
                     Value : constant String :=
                       To_String (Fixture.Arguments.Element (I));
                     Is_Trailing_Empty : constant Boolean :=
                       I = Natural (Fixture.Arguments.Length) - 1
                       and then Value'Length = 0;
                  begin
                     if not Is_Trailing_Empty then
                        if Use_Stderr then
                           Append_Fixture_Output_Line
                             (Err_Text, Err_Has_Line, Value);
                        else
                           Append_Fixture_Output_Line
                             (Out_Text, Out_Has_Line, Value);
                        end if;
                     end if;
                  end;
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => Process_Run_Succeeded,
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => 0,
                Stdout_Text   => Out_Text,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);

         when Exit_Code_Fixture =>
            if Fixture.Arguments.Length > 0 then
               begin
                  Code := Integer'Value
                    (To_String (Fixture.Arguments.First_Element));
               exception
                  when Constraint_Error =>
                     return Build_Process_Run_Result (Process_Run_Rejected);
               end;
            end if;

            if Fixture.Arguments.Length > 1 then
               for I in 1 .. Natural (Fixture.Arguments.Length) - 1 loop
                  declare
                     Value : constant String :=
                       To_String (Fixture.Arguments.Element (I));
                     Is_Trailing_Empty : constant Boolean :=
                       I = Natural (Fixture.Arguments.Length) - 1
                       and then Value'Length = 0;
                  begin
                     if not Is_Trailing_Empty then
                        Append_Fixture_Output_Line
                          (Err_Text, Err_Has_Line, Value);
                     end if;
                  end;
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => (if Code = 0 then Process_Run_Succeeded else Process_Run_Failed),
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => Code,
                Stdout_Text   => Null_Unbounded_String,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);
      end case;
   end Execute_Process_Request_Real_Fixture;

   function Build_Process_Fixture_Result
     (Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Build_Run_Result
   is
      Process_Result : Process_Run_Result;
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      Process_Result := Execute_Process_Request_Real_Fixture (Fixture, Policy);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Build_Process_Fixture_Result;

   function Build_Result_From_Process_Result
     (Request : Build_Run_Request;
      Result  : Process_Run_Result) return Build_Run_Result
   is
      pragma Unreferenced (Request);
      Build_Status : Build_Run_Status;
   begin
      case Result.Status is
         when Process_Run_Succeeded =>
            Build_Status := Build_Run_Succeeded;
         when Process_Run_Failed =>
            Build_Status := Build_Run_Failed;
         when Process_Run_Not_Available =>
            Build_Status := Build_Run_Not_Available;
         when Process_Run_Rejected =>
            Build_Status := Build_Run_Rejected;
         when Process_Run_Execution_Error =>
            Build_Status := Build_Run_Execution_Error;
         when Process_Run_Timed_Out =>
            Build_Status := Build_Run_Timed_Out;
         when Process_Run_Cancelled =>
            Build_Status := Build_Run_Cancelled;
         when Process_Run_Cancellation_Unsupported =>
            Build_Status := Build_Run_Cancellation_Unsupported;
         when Process_Run_Output_Truncated =>
            Build_Status := Build_Run_Output_Truncated;
      end case;

      return
        (Status           => Build_Status,
         Output_Capture_Mode => Result.Output_Capture_Mode,
         Exit_Code        => Result.Exit_Code,
         Has_Exit_Code    => Result.Has_Exit_Code,
         Stdout_Text      => Result.Stdout_Text,
         Stderr_Text      => Result.Stderr_Text,
         Stdout_Truncated => Result.Stdout_Truncated,
         Stderr_Truncated => Result.Stderr_Truncated,
         Output_Partial   => Result.Status = Process_Run_Timed_Out
           or else Result.Status = Process_Run_Cancelled
           or else Result.Status = Process_Run_Cancellation_Unsupported,
         Diagnostic_Lines => Diagnostic_Text_Line_Vectors.Empty_Vector);
   end Build_Result_From_Process_Result;

   function Build_Build_Run_Result
     (Status           : Build_Run_Status;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : String := "";
      Stderr_Text      : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated;
      Diagnostic_Lines : Diagnostic_Text_Line_Array :=
        Diagnostic_Text_Line_Vectors.Empty_Vector) return Build_Run_Result
   is
   begin
      return
        (Status           => Status,
         Output_Capture_Mode =>
           (if Stdout_Text'Length = 0 and then Stderr_Text'Length = 0 then
               Process_Output_Capture_None
            else Output_Capture_Mode),
         Exit_Code        => Exit_Code,
         Has_Exit_Code    => Has_Exit_Code,
         Stdout_Text      => To_Unbounded_String (Stdout_Text),
         Stderr_Text      => To_Unbounded_String (Stderr_Text),
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated,
         Output_Partial   => Output_Partial
           or else Status = Build_Run_Timed_Out
           or else Status = Build_Run_Cancelled
           or else Status = Build_Run_Cancellation_Unsupported,
         Diagnostic_Lines => Diagnostic_Lines);
   end Build_Build_Run_Result;

end Editor.External_Producers.Build_Command_Execution;
