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
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;

package body Editor.External_Producers.Build_Command_Execution.Results is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

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
      Producer : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Diagnostics.Build_External_Producer_Source
          (Editor.External_Producers.Diagnostics.Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Request, Policy);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Diagnostic_Result :=
           Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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
         Diagnostic_Result :=
           Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
      Message : constant String := To_String (Result.Command_Message);
   begin
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

      if not Diagnostics_Ingestion_Allowed then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      if Result.Build_Result.Status = Build_Run_Not_Available then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      return Message'Length > 0;
   end Gated_Build_Command_Result_Is_Consistent;

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
      Producer : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Diagnostics.Build_External_Producer_Source
          (Editor.External_Producers.Diagnostics.Build_Diagnostics_Producer);
      Preflight : Build_Preflight_Result;
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Mode : Editor.External_Producers.Build_Types.Process_Execution_Mode;
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
      Producer : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Diagnostics.Build_External_Producer_Source
          (Editor.External_Producers.Diagnostics.Build_Diagnostics_Producer);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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
      Producer : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Diagnostics.Build_External_Producer_Source
          (Editor.External_Producers.Diagnostics.Build_Diagnostics_Producer);
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture (Request, Fixture, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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
      Producer : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Diagnostics.Build_External_Producer_Source
          (Editor.External_Producers.Diagnostics.Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Request, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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


end Editor.External_Producers.Build_Command_Execution.Results;
