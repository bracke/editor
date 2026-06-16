with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Public_Request;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Build_Runner_Policy;
with Editor.Build_Candidates;
with Editor.Build_Diagnostics;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.External_Producers;
with Editor.Keybindings;
with Editor.Project;

package body Editor.Build_Command is

   Public_Build_Run_Diagnostics_Ingestion_Policy : constant
     Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Policy :=
       Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request;

   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.External_Producers.Build_Request_Validation_Status;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Category;
   use type Build_Run_Readiness_Status;
   use type Editor.Build_Runner_Policy.Build_Execution_Policy;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use type Editor.Build_Process_Control.Build_Process_Cancel_Result;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;

   Max_Public_Build_Async_Slots : constant Positive := 8;
   subtype Public_Build_Async_Slot_Index is Positive range 1 .. Max_Public_Build_Async_Slots;

   function Slot_Index_For (Slot_Id : Natural) return Public_Build_Async_Slot_Index is
   begin
      if Slot_Id = 0 then
         return Public_Build_Async_Slot_Index'First;
      end if;
      return Public_Build_Async_Slot_Index
        (((Slot_Id - 1) mod Max_Public_Build_Async_Slots) + 1);
   end Slot_Index_For;

   type Boolean_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Boolean;
   type Natural_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Natural;
   type State_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.State.State_Type;
   type Build_Request_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Run_Request;
   type Build_Gate_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Execution_Gate;
   type Build_Result_By_Public_Build_Slot is array (Public_Build_Async_Slot_Index) of Editor.External_Producers.Build_Command_Result;

   protected Public_Build_Slot_Allocator is
      procedure Allocate (Slot_Id : out Natural);
   private
      Next_Slot_Id : Natural := 0;
   end Public_Build_Slot_Allocator;

   protected body Public_Build_Slot_Allocator is
      procedure Allocate (Slot_Id : out Natural) is
      begin
         if Next_Slot_Id = Natural'Last then
            Next_Slot_Id := 1;
         else
            Next_Slot_Id := Next_Slot_Id + 1;
         end if;
         Slot_Id := Next_Slot_Id;
      end Allocate;
   end Public_Build_Slot_Allocator;


   protected Public_Build_Worker_Lifecycle is
      procedure Request_Stop;
      procedure Mark_Stopped;
      function Stop_Requested return Boolean;
      function Stopped return Boolean;
   private
      Stop_Requested_Flag : Boolean := False;
      Stopped_Flag        : Boolean := False;
   end Public_Build_Worker_Lifecycle;

   protected body Public_Build_Worker_Lifecycle is
      procedure Request_Stop is
      begin
         Stop_Requested_Flag := True;
      end Request_Stop;

      procedure Mark_Stopped is
      begin
         Stop_Requested_Flag := True;
         Stopped_Flag := True;
      end Mark_Stopped;

      function Stop_Requested return Boolean is
      begin
         return Stop_Requested_Flag;
      end Stop_Requested;

      function Stopped return Boolean is
      begin
         return Stopped_Flag;
      end Stopped;
   end Public_Build_Worker_Lifecycle;

   protected type Public_Build_Job_Registry is
      procedure Store_Queued
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Request        : Editor.External_Producers.Build_Run_Request;
         Runner_Gate    : Editor.External_Producers.Build_Execution_Gate;
         Result_Gate    : Editor.External_Producers.Build_Execution_Gate;
         Job_Id         : Natural);

      procedure Worker_Input
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Run_Request;
         Runner_Gate    : out Editor.External_Producers.Build_Execution_Gate);

      procedure Store_Worker_Result
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Result         : Editor.External_Producers.Build_Command_Result);

      procedure Mark_Worker_Running (Slot_Id : Natural);
      procedure Mark_Cancellation_Requested (Slot_Id : Natural);
      procedure Clear (Slot_Id : Natural);

      function Has_Job (Slot_Id : Natural; Job_Id : Natural) return Boolean;
      function Result_Ready (Slot_Id : Natural) return Boolean;
      function Worker_Running (Slot_Id : Natural) return Boolean;
      function Slot_Available_For (Slot_Id : Natural) return Boolean;

      procedure Snapshot_While_Running
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type);

      procedure Final_Result
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Run_Request;
         Result_Gate    : out Editor.External_Producers.Build_Execution_Gate;
         Result         : out Editor.External_Producers.Build_Command_Result);
   private
      Occupied      : Boolean_By_Public_Build_Slot := (others => False);
      Running       : Boolean_By_Public_Build_Slot := (others => False);
      Ready         : Boolean_By_Public_Build_Slot := (others => False);
      Stored_Slot_Id : Natural_By_Public_Build_Slot := (others => 0);
      Stored_Job_Id : Natural_By_Public_Build_Slot := (others => 0);
      Stored_State  : State_By_Public_Build_Slot;
      Stored_Request : Build_Request_By_Public_Build_Slot;
      Stored_Runner_Gate : Build_Gate_By_Public_Build_Slot;
      Stored_Result_Gate : Build_Gate_By_Public_Build_Slot;
      Stored_Result : Build_Result_By_Public_Build_Slot;
   end Public_Build_Job_Registry;

   protected body Public_Build_Job_Registry is
      procedure Store_Queued
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Request        : Editor.External_Producers.Build_Run_Request;
         Runner_Gate    : Editor.External_Producers.Build_Execution_Gate;
         Result_Gate    : Editor.External_Producers.Build_Execution_Gate;
         Job_Id         : Natural)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Occupied (Index) and then Stored_Slot_Id (Index) /= Slot_Id then
            return;
         end if;

         Stored_Slot_Id (Index) := Slot_Id;
         Stored_State (Index) := State_Snapshot;
         Stored_Request (Index) := Request;
         Stored_Runner_Gate (Index) := Runner_Gate;
         Stored_Result_Gate (Index) := Result_Gate;
         Stored_Job_Id (Index) := Job_Id;
         Occupied (Index) := True;
         Running (Index) := False;
         Ready (Index) := False;
      end Store_Queued;

      procedure Worker_Input
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Run_Request;
         Runner_Gate    : out Editor.External_Producers.Build_Execution_Gate)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         State_Snapshot := Stored_State (Index);
         Request := Stored_Request (Index);
         Runner_Gate := Stored_Runner_Gate (Index);
      end Worker_Input;

      procedure Store_Worker_Result
        (Slot_Id        : Natural;
         State_Snapshot : Editor.State.State_Type;
         Result         : Editor.External_Producers.Build_Command_Result)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Stored_State (Index) := State_Snapshot;
            Stored_Result (Index) := Result;
            Running (Index) := False;
            Ready (Index) := True;
         end if;
      end Store_Worker_Result;

      procedure Mark_Worker_Running (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Running (Index) := True;
            Ready (Index) := False;
         end if;
      end Mark_Worker_Running;

      procedure Mark_Cancellation_Requested (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Stored_State (Index).Public_Build_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Requested;
         end if;
      end Mark_Cancellation_Requested;

      procedure Clear (Slot_Id : Natural) is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            Occupied (Index) := False;
            Running (Index) := False;
            Ready (Index) := False;
            Stored_Slot_Id (Index) := 0;
            Stored_Job_Id (Index) := 0;
         end if;
      end Clear;

      function Has_Job (Slot_Id : Natural; Job_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Occupied (Index)
           and then Stored_Slot_Id (Index) = Slot_Id
           and then Stored_Job_Id (Index) = Job_Id;
      end Has_Job;

      function Result_Ready (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Ready (Index) and then Slot_Id = Stored_Slot_Id (Index);
      end Result_Ready;

      function Worker_Running (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Running (Index) and then Slot_Id = Stored_Slot_Id (Index);
      end Worker_Running;

      function Slot_Available_For (Slot_Id : Natural) return Boolean is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         return Slot_Id /= 0
           and then (not Occupied (Index) or else Stored_Slot_Id (Index) = Slot_Id);
      end Slot_Available_For;

      procedure Snapshot_While_Running
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            State_Snapshot := Stored_State (Index);
         end if;
      end Snapshot_While_Running;

      procedure Final_Result
        (Slot_Id        : Natural;
         State_Snapshot : out Editor.State.State_Type;
         Request        : out Editor.External_Producers.Build_Run_Request;
         Result_Gate    : out Editor.External_Producers.Build_Execution_Gate;
         Result         : out Editor.External_Producers.Build_Command_Result)
      is
         Index : constant Public_Build_Async_Slot_Index := Slot_Index_For (Slot_Id);
      begin
         if Slot_Id = Stored_Slot_Id (Index) then
            State_Snapshot := Stored_State (Index);
            Request := Stored_Request (Index);
            Result_Gate := Stored_Result_Gate (Index);
            Result := Stored_Result (Index);
         end if;
      end Final_Result;
   end Public_Build_Job_Registry;

   Public_Build_Jobs : Public_Build_Job_Registry;

   --  State_Type owns the visible async-job id/queued/result-pending fields.
   --  This bounded protected runtime service stores transient request/result
   --  payloads by the state's async slot id.  It supports more than one live
   --  editor state without falling back to a single unnamed job handoff.
   task type Public_Build_Worker is
      entry Start (Slot_Id : Natural);
      entry Drain (Slot_Id : Natural);
      entry Stop;
   end Public_Build_Worker;

   task body Public_Build_Worker is
      Worker_State : Editor.State.State_Type;
      Worker_Request : Editor.External_Producers.Build_Run_Request;
      Worker_Runner_Gate : Editor.External_Producers.Build_Execution_Gate;
      Worker_Result : Editor.External_Producers.Build_Command_Result;
      Worker_Slot_Id : Natural := 0;
   begin
      loop
         select
            accept Start (Slot_Id : Natural) do
               Worker_Slot_Id := Slot_Id;
            end Start;
            Public_Build_Jobs.Worker_Input
              (Worker_Slot_Id, Worker_State, Worker_Request, Worker_Runner_Gate);
            Public_Build_Jobs.Mark_Worker_Running (Worker_Slot_Id);
            Worker_Result :=
              Editor.External_Producers.Run_Build_Command_With_Gate
                (Worker_State, Worker_Request, Worker_Runner_Gate);
            Public_Build_Jobs.Store_Worker_Result
              (Worker_Slot_Id, Worker_State, Worker_Result);
         or
            --  Application/lifecycle shutdown drain.  The accept completes only
            --  when this slot's worker is idle, so callers can deterministically
            --  wait for a previously requested cancellation to be observed and
            --  finalized.
            accept Drain (Slot_Id : Natural) do
               Worker_Slot_Id := Slot_Id;
            end Drain;
         or
            --  Final application shutdown.  Unlike Drain, Stop terminates the
            --  app-lifetime worker task after any current Start body has
            --  completed.  New build starts are rejected once the worker
            --  lifecycle stop flag is set.
            accept Stop;
            exit;
         or
            terminate;
         end select;
      end loop;
   end Public_Build_Worker;

   type Public_Build_Worker_Array is array (Public_Build_Async_Slot_Index) of Public_Build_Worker;
   Public_Build_Workers : Public_Build_Worker_Array;

   function Summary_Kind_For
     (Status : Editor.External_Producers.Build_Run_Status)
      return Editor.Build_Result_Summary.Build_Result_Summary_Kind
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Run_Succeeded =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Succeeded;
         when Editor.External_Producers.Build_Run_Failed
            | Editor.External_Producers.Build_Run_Rejected
            | Editor.External_Producers.Build_Run_Execution_Error =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Failed;
         when Editor.External_Producers.Build_Run_Not_Available
            | Editor.External_Producers.Build_Run_Cancellation_Unsupported =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Unavailable;
         when Editor.External_Producers.Build_Run_Timed_Out =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Timed_Out;
         when Editor.External_Producers.Build_Run_Cancelled =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Cancelled;
         when Editor.External_Producers.Build_Run_Output_Truncated =>
            return Editor.Build_Result_Summary.Build_Result_Summary_Output_Truncated;
      end case;
   end Summary_Kind_For;

   function Summary_Tool_For
     (Tool : Editor.External_Producers.Build_Tool_Kind)
      return Editor.Build_Result_Summary.Build_Result_Tool_Kind
   is
   begin
      case Tool is
         when Editor.External_Producers.GPRbuild_Tool =>
            return Editor.Build_Result_Summary.Build_Result_GPRbuild_Tool;
         when Editor.External_Producers.Alire_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_Alire_Tool;
         when Editor.External_Producers.Custom_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_Custom_Tool;
         when Editor.External_Producers.No_Build_Tool =>
            return Editor.Build_Result_Summary.Build_Result_No_Tool;
      end case;
   end Summary_Tool_For;

   function Summary_Mode_For
     (Request : Editor.External_Producers.Build_Run_Request)
      return Editor.Build_Result_Summary.Build_Result_Request_Mode
   is
   begin
      if Length (Request.Command_Label) > 0 then
         return Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived;
      end if;

      case Request.Provenance is
         when Editor.External_Producers.Build_Request_From_User_Opt_In =>
            return Editor.Build_Result_Summary.Build_Result_Request_Manual;
         when Editor.External_Producers.Build_Request_From_Project_Metadata =>
            return Editor.Build_Result_Summary.Build_Result_Request_Candidate_Derived;
         when Editor.External_Producers.Build_Request_From_Test
            | Editor.External_Producers.Build_Request_From_Fixture
            | Editor.External_Producers.Build_Request_From_Internal_Command =>
            return Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal;
         when Editor.External_Producers.Build_Request_Unknown =>
            return Editor.Build_Result_Summary.Build_Result_Request_None;
      end case;
   end Summary_Mode_For;

   function Summary_Diagnostics_For
     (Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Allowed : Boolean)
      return Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status
   is
   begin
      if not Allowed then
         return Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled;
      end if;

      case Result.Outcome is
         when Editor.External_Producers.Diagnostic_Line_Command_Succeeded =>
            if Result.Ingestion.Ingestion_Result.Accepted_Count > 0 then
               if Result.Ingestion.Parse_Rejected_Malformed_Count > 0 then
                  return Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial;
               else
                  return Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded;
               end if;
            else
               return Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
            end if;
         when Editor.External_Producers.Diagnostic_Line_Command_No_Input
            | Editor.External_Producers.Diagnostic_Line_Command_No_Diagnostics =>
            return Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
         when Editor.External_Producers.Diagnostic_Line_Command_Malformed_Only =>
            return Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed;
      end case;
   end Summary_Diagnostics_For;

   function Runner_Status_Label
     (Status : Editor.External_Producers.Build_Run_Status) return String
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Run_Succeeded => return "succeeded";
         when Editor.External_Producers.Build_Run_Failed => return "failed";
         when Editor.External_Producers.Build_Run_Not_Available => return "not available";
         when Editor.External_Producers.Build_Run_Rejected => return "rejected";
         when Editor.External_Producers.Build_Run_Execution_Error => return "execution error";
         when Editor.External_Producers.Build_Run_Timed_Out => return "timed out";
         when Editor.External_Producers.Build_Run_Cancelled => return "cancelled";
         when Editor.External_Producers.Build_Run_Cancellation_Unsupported => return "cancellation unsupported";
         when Editor.External_Producers.Build_Run_Output_Truncated => return "output truncated";
      end case;
   end Runner_Status_Label;

   function Output_Runner_Status_For
     (Status : Editor.External_Producers.Build_Run_Status)
      return Editor.Build_Output_Details.Build_Output_Runner_Status
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Run_Succeeded =>
            return Editor.Build_Output_Details.Build_Output_Runner_Succeeded;
         when Editor.External_Producers.Build_Run_Failed =>
            return Editor.Build_Output_Details.Build_Output_Runner_Failed;
         when Editor.External_Producers.Build_Run_Not_Available =>
            return Editor.Build_Output_Details.Build_Output_Runner_Not_Available;
         when Editor.External_Producers.Build_Run_Rejected =>
            return Editor.Build_Output_Details.Build_Output_Runner_Rejected;
         when Editor.External_Producers.Build_Run_Execution_Error =>
            return Editor.Build_Output_Details.Build_Output_Runner_Execution_Error;
         when Editor.External_Producers.Build_Run_Timed_Out =>
            return Editor.Build_Output_Details.Build_Output_Runner_Timed_Out;
         when Editor.External_Producers.Build_Run_Cancelled =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancelled;
         when Editor.External_Producers.Build_Run_Cancellation_Unsupported =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported;
         when Editor.External_Producers.Build_Run_Output_Truncated =>
            return Editor.Build_Output_Details.Build_Output_Runner_Output_Truncated;
      end case;
   end Output_Runner_Status_For;

   function Output_Details_From_Result
     (Build : Editor.External_Producers.Build_Run_Result)
      return Editor.Build_Output_Details.Latest_Build_Output_Details
   is
   begin
      return Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
        (Runner_Status => Output_Runner_Status_For (Build.Status),
         Stdout_Text => Build.Stdout_Text,
         Stderr_Text => Build.Stderr_Text,
         Stdout_Truncated => Build.Stdout_Truncated,
         Stderr_Truncated => Build.Stderr_Truncated,
         Output_Partial => Build.Output_Partial,
         Exit_Code => Build.Exit_Code,
         Has_Exit_Code => Build.Has_Exit_Code,
         Output_Stream =>
           (case Editor.External_Producers.Build_Result_Output_Stream (Build) is
              when Editor.External_Producers.Process_Output_Stdout =>
                 Editor.Build_Output_Details.Build_Output_Stream_Stdout,
              when Editor.External_Producers.Process_Output_Stderr =>
                 Editor.Build_Output_Details.Build_Output_Stream_Stderr,
              when Editor.External_Producers.Process_Output_Merged =>
                 Editor.Build_Output_Details.Build_Output_Stream_Merged));
   end Output_Details_From_Result;

   function Summary_From_Result
     (Request : Editor.External_Producers.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Command_Result;
      Diagnostics_Allowed : Boolean)
      return Editor.Build_Result_Summary.Latest_Build_Result_Summary
   is
      Build : constant Editor.External_Producers.Build_Run_Result := Result.Build_Result;
      Count : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Diagnostics_Status : constant
        Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status :=
          Summary_Diagnostics_For (Result.Diagnostic_Result, Diagnostics_Allowed);
      Has_Count : constant Boolean :=
        Diagnostics_Status in
          Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded |
          Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial |
          Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics;
   begin
      return Editor.Build_Result_Summary.Build_Summary
        (Kind => Summary_Kind_For (Build.Status),
         Invocation_Label => "build.run",
         Tool_Kind => Summary_Tool_For (Request.Tool),
         Request_Mode => Summary_Mode_For (Request),
         Working_Context_Label => To_String (Request.Working_Label),
         Runner_Status_Label => Runner_Status_Label (Build.Status),
         Primary_Message => To_String (Result.Command_Message),
         Exit_Code => Build.Exit_Code,
         Has_Exit_Code => Build.Has_Exit_Code,
         Timed_Out => Build.Status = Editor.External_Producers.Build_Run_Timed_Out,
         Cancelled => Build.Status = Editor.External_Producers.Build_Run_Cancelled,
         Cancellation_Unsupported =>
           Build.Status = Editor.External_Producers.Build_Run_Cancellation_Unsupported,
         Stdout_Truncated => Build.Stdout_Truncated,
         Stderr_Truncated => Build.Stderr_Truncated,
         Output_Partial => Build.Output_Partial,
         Diagnostics_Ingestion_Status => Diagnostics_Status,
         Diagnostics_Count => Count,
         Has_Diagnostics_Count => Has_Count,
         Diagnostics_Error_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Error_Count,
         Diagnostics_Warning_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Warning_Count,
         Diagnostics_Info_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Info_Count,
         Diagnostics_Note_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Note_Count,
         Diagnostics_Unknown_Count =>
           Result.Diagnostic_Result.Ingestion.Parsed_Unknown_Count,
         Has_Diagnostics_Severity_Counts => Count > 0);
   end Summary_From_Result;


   function Selected_Candidate_Preflight_Status
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      Selected_Id : constant String := To_String (State.Build_UI.Selected_Build_Candidate_Id);
      Found       : Boolean := False;
   begin
      if Selected_Id'Length = 0 then
         return Build_Run_Readiness_No_Candidate_Selected;
      end if;

      for Candidate of State.Build_UI.Build_Candidates loop
         if To_String (Candidate.Candidate_Id) = Selected_Id then
            Found := True;
            declare
               Status : constant Editor.Build_Candidates.Build_Candidate_Validation_Status :=
                 Editor.Build_Candidates.Validate_Candidate (Candidate);
            begin
               case Status is
                  when Editor.Build_Candidates.Build_Candidate_Valid =>
                     return Build_Run_Readiness_Ready;
                  when Editor.Build_Candidates.Build_Candidate_Unavailable =>
                     return Build_Run_Readiness_Candidate_File_Missing;
                  when others =>
                     return Build_Run_Readiness_Selected_Candidate_Stale;
               end case;
            end;
         end if;
      end loop;

      if not Found then
         return Build_Run_Readiness_Selected_Candidate_Stale;
      end if;

      return Build_Run_Readiness_Selected_Candidate_Stale;
   end Selected_Candidate_Preflight_Status;

   function Map_UI_Status
     (Status : Editor.Build_UI.Public_Build_UI_Validation_Status)
      return Build_Run_Readiness_Status
   is
   begin
      case Status is
         when Editor.Build_UI.Build_UI_Valid =>
            return Build_Run_Readiness_Ready;
         when Editor.Build_UI.Build_UI_Rejected_Not_Visible =>
            return Build_Run_Readiness_Request_Incomplete;
         when Editor.Build_UI.Build_UI_Rejected_No_Tool
            | Editor.Build_UI.Build_UI_Rejected_Custom_Tool =>
            return Build_Run_Readiness_Tool_Required;
         when Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected =>
            return Build_Run_Readiness_No_Candidate_Selected;
         when Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale =>
            return Build_Run_Readiness_Selected_Candidate_Stale;
         when Editor.Build_UI.Build_UI_Rejected_Unsafe_Arguments =>
            return Build_Run_Readiness_Arguments_Invalid;
         when Editor.Build_UI.Build_UI_Rejected_Unsupported_Request_Option =>
            return Build_Run_Readiness_Request_Incomplete;
         when Editor.Build_UI.Build_UI_Rejected_Working_Context_Required =>
            return Build_Run_Readiness_Working_Context_Required;
         when Editor.Build_UI.Build_UI_Rejected_Working_Context_Unavailable =>
            return Build_Run_Readiness_Working_Context_Unavailable;
         when Editor.Build_UI.Build_UI_Rejected_Unsafe_Working_Context =>
            return Build_Run_Readiness_Working_Context_Invalid;
         when Editor.Build_UI.Build_UI_Rejected_Missing_Consent =>
            return Build_Run_Readiness_Consent_Required;
         when Editor.Build_UI.Build_UI_Rejected_Stale_Consent =>
            return Build_Run_Readiness_Consent_Stale;
         when Editor.Build_UI.Build_UI_Rejected_Execution_Backend_Disabled =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
      end case;
   end Map_UI_Status;

   function Build_Run_Readiness
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      UI_Status : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (State.Build_UI);
   begin
      if State.Public_Build_Job_Active
        or else State.Public_Build_Async_Job_Queued
      then
         return Build_Run_Readiness_Job_Already_Active;
      elsif not Editor.Project.Has_Project (State.Project) then
         return Build_Run_Readiness_No_Project_Open;
      end if;

      if UI_Status /= Editor.Build_UI.Build_UI_Valid then
         return Map_UI_Status (UI_Status);
      end if;

      case State.Public_Build_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
            null;
      end case;

      declare
         Candidate_Status : constant Build_Run_Readiness_Status :=
           Selected_Candidate_Preflight_Status (State);
      begin
         if Candidate_Status /= Build_Run_Readiness_Ready then
            return Candidate_Status;
         end if;
      end;

      return Build_Run_Readiness_Ready;
   end Build_Run_Readiness;

   function Build_Run_Unavailable_Reason
     (Status : Build_Run_Readiness_Status) return String
   is
   begin
      case Status is
         when Build_Run_Readiness_Ready =>
            return "Build request ready";
         when Build_Run_Readiness_No_Project_Open =>
            return "No project open.";
         when Build_Run_Readiness_No_Candidate_Selected =>
            return "No build candidate selected.";
         when Build_Run_Readiness_Selected_Candidate_Stale =>
            return "Selected build candidate is stale.";
         when Build_Run_Readiness_Candidate_File_Missing =>
            return "Build candidate file no longer exists.";
         when Build_Run_Readiness_Request_Incomplete =>
            return "Build request is not ready.";
         when Build_Run_Readiness_Tool_Required =>
            return "Build unavailable: build tool required.";
         when Build_Run_Readiness_Arguments_Invalid =>
            return "Build unavailable: structured arguments invalid.";
         when Build_Run_Readiness_Working_Context_Required =>
            return "Build working directory is required.";
         when Build_Run_Readiness_Working_Context_Unavailable =>
            return "Build working directory is unavailable.";
         when Build_Run_Readiness_Working_Context_Invalid =>
            return "Build working directory is rejected.";
         when Build_Run_Readiness_Consent_Required =>
            return "Consent required.";
         when Build_Run_Readiness_Consent_Stale =>
            return "Consent stale.";
         when Build_Run_Readiness_Execution_Backend_Disabled =>
            return "Build execution backend is disabled.";
         when Build_Run_Readiness_Job_Already_Active =>
            return "Build unavailable: another build job is active.";
      end case;
   end Build_Run_Unavailable_Reason;

   function Build_Run_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
      Status : constant Build_Run_Readiness_Status := Build_Run_Readiness (State);
   begin
      if Status = Build_Run_Readiness_Ready then
         return Editor.Commands.Available;
      end if;
      return Editor.Commands.Unavailable (Build_Run_Unavailable_Reason (Status));
   end Build_Run_Availability;

   function Has_Active_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return State.Public_Build_Job_Active;
   end Has_Active_Public_Build_Job;

   function Build_Cancel_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
   begin
      if State.Public_Build_Job_Active then
         return Editor.Commands.Available;
      end if;
      return Editor.Commands.Unavailable ("No active build job.");
   end Build_Cancel_Availability;

   procedure Begin_Public_Build_Job
     (State : in out Editor.State.State_Type;
      Label : String)
   is
   begin
      State.Public_Build_Job_Active := True;
      State.Public_Build_Job_Id := State.Public_Build_Job_Id + 1;
      if State.Public_Build_Async_Slot_Id = 0 then
         Public_Build_Slot_Allocator.Allocate (State.Public_Build_Async_Slot_Id);
      end if;
      State.Public_Build_Job_Label := To_Unbounded_String (Label);
      State.Public_Build_Job_Cancellation :=
        Editor.Build_Runner_Policy.No_Cancellation_Requested;
      State.Public_Build_Process_Handle :=
        Editor.Build_Process_Control.No_Process_Handle;
      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (State.Public_Build_Output_Stream, State.Public_Build_Job_Id);
   end Begin_Public_Build_Job;

   procedure Register_Public_Build_Process
     (State  : in out Editor.State.State_Type;
      Handle : Editor.Build_Process_Control.Build_Process_Handle)
   is
   begin
      if State.Public_Build_Job_Active then
         State.Public_Build_Process_Handle := Handle;
      end if;
   end Register_Public_Build_Process;

   procedure Register_Public_Build_Test_Process
     (State : in out Editor.State.State_Type)
   is
   begin
      Register_Public_Build_Process
        (State, Editor.Build_Process_Control.Test_Cancellable_Handle);
   end Register_Public_Build_Test_Process;

   procedure Complete_Public_Build_Job
     (State : in out Editor.State.State_Type)
   is
   begin
      State.Public_Build_Job_Active := False;
      State.Public_Build_Job_Label := Null_Unbounded_String;
      State.Public_Build_Process_Handle :=
        Editor.Build_Process_Control.No_Process_Handle;
      Editor.Build_Process_Control.Clear_Active_Process;
      Editor.Build_Output_Details.Finish_Build_Output_Stream
        (State.Public_Build_Output_Stream);
      --  Public_Build_Async_Slot_Id is deliberately stable for the
      --  editor state.  Completion clears the transient job markers and
      --  protected registry payload, but does not reset the slot; later
      --  builds from the same state reuse the same worker-pool slot with a
      --  new Public_Build_Job_Id.
      if State.Public_Build_Job_Cancellation =
        Editor.Build_Runner_Policy.Cancellation_Requested
      then
         State.Public_Build_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Acknowledged;
      else
         State.Public_Build_Job_Cancellation :=
           Editor.Build_Runner_Policy.No_Cancellation_Requested;
      end if;
   end Complete_Public_Build_Job;

   function Request_Public_Build_Cancel
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result
   is
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      if not State.Public_Build_Job_Active then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
         return Result;
      end if;

      if State.Public_Build_Async_Job_Queued
        and then not Editor.Build_Process_Control.Is_Active
          (State.Public_Build_Process_Handle)
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle)
      then
         State.Public_Build_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Requested;
         Public_Build_Jobs.Mark_Cancellation_Requested (State.Public_Build_Async_Slot_Id);
         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build cancellation requested."));
      end if;

      declare
         Handle : Editor.Build_Process_Control.Build_Process_Handle :=
           (if Editor.Build_Process_Control.Is_Active
                 (State.Public_Build_Process_Handle)
            then State.Public_Build_Process_Handle
            else Editor.Build_Process_Control.Active_Process_Handle);
         Cancel_Result : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
           (if Editor.Build_Process_Control.Is_Active
                 (Editor.Build_Process_Control.Active_Process_Handle)
            then Editor.Build_Process_Control.Request_Active_Cancel
            else Editor.Build_Process_Control.Request_Cancel (Handle));
      begin
         case Cancel_Result is
            when Editor.Build_Process_Control.Build_Process_Cancel_Sent =>
               State.Public_Build_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Requested;
               Public_Build_Jobs.Mark_Cancellation_Requested (State.Public_Build_Async_Slot_Id);
               State.Public_Build_Process_Handle := Handle;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Run_Cancelled),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   => To_Unbounded_String ("Build cancellation requested."));
               State.Latest_Build_Result :=
                 Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                   (State.Latest_Build_Result,
                    Editor.Build_Result_Summary.Build_Summary
                      (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Cancelled,
                       Invocation_Label => "build.cancel",
                       Tool_Kind => Editor.Build_Result_Summary.Build_Result_No_Tool,
                       Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal,
                       Working_Context_Label => To_String (State.Public_Build_Job_Label),
                       Runner_Status_Label => "cancelled",
                       Primary_Message => "Build cancellation requested",
                       Cancelled => True,
                       Output_Partial => True));
               State.Latest_Build_Output_Details :=
                 Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                   (State.Latest_Build_Output_Details,
                    Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
                      (Runner_Status =>
                         Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
                       Stdout_Text => State.Public_Build_Output_Stream.Stdout_Text,
                       Stderr_Text => State.Public_Build_Output_Stream.Stderr_Text,
                       Stdout_Truncated => State.Public_Build_Output_Stream.Stdout_Truncated,
                       Stderr_Truncated => State.Public_Build_Output_Stream.Stderr_Truncated,
                       Output_Partial => True));
               return Result;

            when Editor.Build_Process_Control.Build_Process_Cancel_Not_Active
               | Editor.Build_Process_Control.Build_Process_Cancel_Not_Cancellable =>
               State.Public_Build_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Unsupported;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Run_Cancellation_Unsupported),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   =>
                    To_Unbounded_String ("Build unavailable: cancellation unsupported."));

            when Editor.Build_Process_Control.Build_Process_Cancel_Failed =>
               State.Public_Build_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Unsupported;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Run_Execution_Error),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   =>
                    To_Unbounded_String ("Build cancellation failed."));
         end case;
      end;

      State.Latest_Build_Result :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (State.Latest_Build_Result,
           Editor.Build_Result_Summary.Build_Summary
             (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              Invocation_Label => "build.cancel",
              Tool_Kind => Editor.Build_Result_Summary.Build_Result_No_Tool,
              Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal,
              Working_Context_Label => To_String (State.Public_Build_Job_Label),
              Runner_Status_Label => "cancellation unsupported",
              Primary_Message => "Build unavailable: cancellation unsupported",
              Cancellation_Unsupported => True,
              Output_Partial => True));
      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
             (Runner_Status =>
                Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported,
              Stdout_Text => State.Public_Build_Output_Stream.Stdout_Text,
              Stderr_Text => State.Public_Build_Output_Stream.Stderr_Text,
              Stdout_Truncated => State.Public_Build_Output_Stream.Stdout_Truncated,
              Stderr_Truncated => State.Public_Build_Output_Stream.Stderr_Truncated,
              Output_Partial => True));
      return Result;
   end Request_Public_Build_Cancel;


   function Request_Public_Build_Lifecycle_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Command_Result
   is
      Result : Editor.External_Producers.Build_Command_Result;
      Cancel_Result : Editor.Build_Process_Control.Build_Process_Cancel_Result :=
        Editor.Build_Process_Control.Build_Process_Cancel_Not_Active;
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Message : constant String :=
        (if Reason'Length = 0 then
            "Build cancellation requested before lifecycle transition."
         else
            "Build cancellation requested before " & Reason & ".");
   begin
      if not State.Public_Build_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
      end if;

      State.Public_Build_Job_Cancellation :=
        Editor.Build_Runner_Policy.Cancellation_Requested;

      if State.Public_Build_Async_Job_Queued then
         Public_Build_Jobs.Mark_Cancellation_Requested
           (State.Public_Build_Async_Slot_Id);
      end if;

      if Editor.Build_Process_Control.Is_Active
        (Editor.Build_Process_Control.Active_Process_Handle)
      then
         Cancel_Result := Editor.Build_Process_Control.Request_Active_Cancel;
      elsif Editor.Build_Process_Control.Is_Active
        (State.Public_Build_Process_Handle)
      then
         Cancel_Result :=
           Editor.Build_Process_Control.Request_Cancel
             (State.Public_Build_Process_Handle);
      end if;

      declare
         Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
         Available : Boolean := False;
      begin
         Editor.Build_Process_Control.Active_Output_Stream (Stream, Available);
         if Available then
            State.Public_Build_Output_Stream := Stream;
         end if;
      end;

      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
              Output_Partial => True));

      if Cancel_Result = Editor.Build_Process_Control.Build_Process_Cancel_Failed then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build cancellation requested before " & Reason & "; process signal failed."));
      else
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String (Message));
      end if;
      return Result;
   end Request_Public_Build_Lifecycle_Shutdown;


   function Drain_Public_Build_Worker_For_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Command_Result
   is
      Result : Editor.External_Producers.Build_Command_Result;
      Poll_Result : Editor.External_Producers.Build_Command_Result;
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
   begin
      if not State.Public_Build_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
      end if;

      Result := Request_Public_Build_Lifecycle_Shutdown (State, Reason);

      if State.Public_Build_Async_Slot_Id /= 0 then
         Public_Build_Workers
           (Slot_Index_For (State.Public_Build_Async_Slot_Id)).Drain
             (State.Public_Build_Async_Slot_Id);
      end if;

      if Has_Queued_Public_Build_Job (State) then
         declare
            Completed : constant Boolean :=
              Poll_Public_Build_Run_Completion (State, Poll_Result);
         begin
            if Completed then
               Result := Poll_Result;
            end if;
         end;
      end if;

      Editor.Build_Process_Control.Clear_Active_Process;
      if State.Public_Build_Async_Slot_Id /= 0
        and then not State.Public_Build_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (State.Public_Build_Async_Slot_Id);
      end if;

      return Result;
   end Drain_Public_Build_Worker_For_Shutdown;



   procedure Stop_Public_Build_Workers_For_Application_Exit is
   begin
      if Public_Build_Worker_Lifecycle.Stopped then
         return;
      end if;

      Public_Build_Worker_Lifecycle.Request_Stop;
      for Slot in Public_Build_Async_Slot_Index loop
         Public_Build_Workers (Slot).Stop;
      end loop;
      Public_Build_Worker_Lifecycle.Mark_Stopped;
   end Stop_Public_Build_Workers_For_Application_Exit;

   procedure Append_Public_Build_Output_Chunk
     (State : in out Editor.State.State_Type;
      Output_Stream : Editor.Build_Output_Details.Build_Output_Stream_Selection;
      Text : String)
   is
   begin
      if not State.Public_Build_Job_Active then
         return;
      end if;

      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (State.Public_Build_Output_Stream, Output_Stream, Text);
      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Runner_Status => Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Output_Partial => True));
   end Append_Public_Build_Output_Chunk;

   procedure Complete_Public_Build_Output_Stream
     (State : in out Editor.State.State_Type;
      Runner_Status : Editor.Build_Output_Details.Build_Output_Runner_Status;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False)
   is
   begin
      Editor.Build_Output_Details.Finish_Build_Output_Stream
        (State.Public_Build_Output_Stream);
      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Runner_Status => Runner_Status,
              Output_Partial => False,
              Exit_Code => Exit_Code,
              Has_Exit_Code => Has_Exit_Code));
   end Complete_Public_Build_Output_Stream;

   function Validate_Build_Run_Invocation
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
   begin
      if State.Public_Build_Job_Active
        or else State.Public_Build_Async_Job_Queued
      then
         return Build_Run_Readiness_Job_Already_Active;
      elsif not Editor.Project.Has_Project (State.Project) then
         return Build_Run_Readiness_No_Project_Open;
      end if;

      if Conversion.Status /= Editor.Build_UI.Build_UI_Valid then
         return Map_UI_Status (Conversion.Status);
      end if;

      case State.Public_Build_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Build_Run_Readiness_Execution_Backend_Disabled;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
            null;
      end case;

      declare
         Candidate_Status : constant Build_Run_Readiness_Status :=
           Selected_Candidate_Preflight_Status (State);
      begin
         if Candidate_Status /= Build_Run_Readiness_Ready then
            return Candidate_Status;
         end if;
      end;

      if Editor.External_Producers.Validate_Build_Run_Request_Status
        (Conversion.Request) /= Editor.External_Producers.Build_Request_Valid
      then
         return Build_Run_Readiness_Request_Incomplete;
      end if;

      return Build_Run_Readiness_Ready;
   end Validate_Build_Run_Invocation;

   function Build_Run_Execution_Gate
     (State : Editor.State.State_Type)
      return Editor.External_Producers.Build_Execution_Gate
   is
      Ready_To_Run : constant Boolean :=
        Validate_Build_Run_Invocation (State) = Build_Run_Readiness_Ready;
      Consent : constant Editor.External_Producers.Build_Execution_Consent :=
        (if Ready_To_Run
         then Editor.External_Producers.Build_Consent_User_Confirmed
         else Editor.External_Producers.Build_Consent_Not_Provided);
   begin
      case State.Public_Build_Execution_Policy is
         when Editor.Build_Runner_Policy.Build_Execution_Disabled |
              Editor.Build_Runner_Policy.Build_Execution_Stub_Only =>
            return Editor.External_Producers.Build_Default_Execution_Gate;
         when Editor.Build_Runner_Policy.Build_Execution_Bounded_Process =>
            return Editor.External_Producers.Build_Real_Execution_Gate
              (Allow_Diagnostics_Ingestion =>
                 Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Allowed
                   (Public_Build_Run_Diagnostics_Ingestion_Policy,
                    State.Build_UI.Show_Diagnostics_On_Result),
               Show_Diagnostics            =>
                 Editor.Build_Diagnostics.Build_Diagnostics_Show_Diagnostics_Allowed
                   (Public_Build_Run_Diagnostics_Ingestion_Policy,
                    State.Build_UI.Show_Diagnostics_On_Result),
               Require_Absolute_Program    => False,
               Max_Output_Bytes            =>
                 Editor.Build_UI.Output_Capture_Limit_Bytes
                   (State.Build_UI.Output_Capture_Limit),
               Consent                     => Consent);
      end case;
   end Build_Run_Execution_Gate;

   function Has_Queued_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return State.Public_Build_Async_Job_Queued
        and then Public_Build_Jobs.Has_Job (State.Public_Build_Async_Slot_Id, State.Public_Build_Job_Id);
   end Has_Queued_Public_Build_Job;

   function Start_Public_Build_Run_Asynchronously
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Readiness : constant Build_Run_Readiness_Status :=
        Validate_Build_Run_Invocation (State);
   begin
      if Readiness /= Build_Run_Readiness_Ready then
         declare
            Message : constant String := Build_Run_Unavailable_Reason (Readiness);
         begin
            if Editor.Build_Result_Summary.Retain_Pre_Run_Unavailable_Summary then
               State.Latest_Build_Result :=
                 Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                   (State.Latest_Build_Result,
                    Editor.Build_Result_Summary.Summary_From_Unavailable_Message
                      (Message));
               State.Latest_Build_Output_Details :=
                 Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                   (State.Latest_Build_Output_Details,
                    Editor.Build_Output_Details.Build_Unavailable_Output_Details
                      (Message));
            end if;
            return
              (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                 (Editor.External_Producers.Build_Run_Not_Available),
               Diagnostic_Result => Empty_Diagnostics,
               Command_Message   => To_Unbounded_String (Message));
         end;
      elsif Public_Build_Worker_Lifecycle.Stop_Requested then
         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build unavailable: async build worker pool is stopping."));
      elsif State.Public_Build_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build unavailable: another build job is active."));
      end if;

      declare
         Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           Build_Run_Execution_Gate (State);
         Runner_Only_Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           (Process_Policy                  => Gate.Process_Policy,
            Allow_Build_Run                 => Gate.Allow_Build_Run,
            Allow_Real_Build_Tool_Execution => Gate.Allow_Real_Build_Tool_Execution,
            Allow_Real_Build_Tool_Fixture   => Gate.Allow_Real_Build_Tool_Fixture,
            Consent                         => Gate.Consent,
            Allow_Diagnostics_Ingestion     => False,
            Show_Diagnostics                => False);
      begin
         Begin_Public_Build_Job
           (State, To_String (Conversion.Request.Command_Label));

         if not Public_Build_Jobs.Slot_Available_For
           (State.Public_Build_Async_Slot_Id)
         then
            Complete_Public_Build_Job (State);
            return
              (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                 (Editor.External_Producers.Build_Run_Not_Available),
               Diagnostic_Result => Empty_Diagnostics,
               Command_Message   => To_Unbounded_String
                 ("Build unavailable: async build slot pool exhausted."));
         end if;

         State.Public_Build_Async_Job_Queued := True;
         State.Public_Build_Async_Job_Result_Pending := False;
         Public_Build_Jobs.Store_Queued
           (State.Public_Build_Async_Slot_Id, State,
            Conversion.Request,
            Runner_Only_Gate,
            Gate,
            State.Public_Build_Job_Id);
         Public_Build_Workers (Slot_Index_For (State.Public_Build_Async_Slot_Id)).Start (State.Public_Build_Async_Slot_Id);

         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Output_Partial => True);

         return
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Succeeded,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("Build started."));
      end;
   end Start_Public_Build_Run_Asynchronously;

   function Poll_Public_Build_Run_Completion
     (State : in out Editor.State.State_Type;
      Result : out Editor.External_Producers.Build_Command_Result) return Boolean
   is
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Ingestion : Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Empty_Diagnostics;
      Worker_State : Editor.State.State_Type;
      Active_Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Active_Stream_Available : Boolean := False;
      Completed_Request : Editor.External_Producers.Build_Run_Request;
      Result_Gate : Editor.External_Producers.Build_Execution_Gate;
   begin
      if not Has_Queued_Public_Build_Job (State) then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No queued build job."));
         return False;
      end if;

      --  Non-blocking poll: the worker owns the native process supervisor.
      --  Until the protected handoff reports a final result, refresh the
      --  observable process handle/output stream and return immediately.
      if not Public_Build_Jobs.Result_Ready (State.Public_Build_Async_Slot_Id) then
         Public_Build_Jobs.Snapshot_While_Running (State.Public_Build_Async_Slot_Id, Worker_State);
         State.Public_Build_Process_Handle :=
           Editor.Build_Process_Control.Active_Process_Handle;
         Editor.Build_Process_Control.Active_Output_Stream
           (Active_Stream, Active_Stream_Available);
         if Active_Stream_Available then
            State.Public_Build_Output_Stream := Active_Stream;
         else
            State.Public_Build_Output_Stream :=
              Worker_State.Public_Build_Output_Stream;
         end if;
         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Output_Partial => True);
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Succeeded,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("Build still running."));
         return False;
      end if;

      Public_Build_Jobs.Final_Result
        (State.Public_Build_Async_Slot_Id, Worker_State, Completed_Request, Result_Gate, Result);
      State.Public_Build_Output_Stream :=
        Worker_State.Public_Build_Output_Stream;

      Complete_Public_Build_Job (State);
      State.Public_Build_Async_Job_Queued := False;
      State.Public_Build_Async_Job_Result_Pending := True;

      Ingestion :=
        Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
          (State,
           Completed_Request,
           Result.Build_Result,
           Public_Build_Run_Diagnostics_Ingestion_Policy,
           State.Build_UI.Show_Diagnostics_On_Result);

      Result.Diagnostic_Result := Ingestion;
      Result.Command_Message := To_Unbounded_String
        (Editor.External_Producers.Build_Gated_Build_Command_Feedback
           (Result.Build_Result,
            Ingestion,
            Result_Gate.Allow_Diagnostics_Ingestion,
            Result_Gate.Allow_Diagnostics_Ingestion));

      State.Latest_Build_Result :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (State.Latest_Build_Result,
           Summary_From_Result
             (Completed_Request,
              Result,
              Result_Gate.Allow_Diagnostics_Ingestion));
      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Output_Details_From_Result (Result.Build_Result));

      Public_Build_Jobs.Clear (State.Public_Build_Async_Slot_Id);
      return True;
   end Poll_Public_Build_Run_Completion;


   function Execute_Public_Build_Run
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Command_Result;
      Readiness : constant Build_Run_Readiness_Status :=
        Validate_Build_Run_Invocation (State);
   begin
      if Readiness /= Build_Run_Readiness_Ready then
         declare
            Message : constant String := Build_Run_Unavailable_Reason (Readiness);
         begin
            Result :=
              (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                 (Editor.External_Producers.Build_Run_Not_Available),
               Diagnostic_Result => Empty_Diagnostics,
               Command_Message   => To_Unbounded_String (Message));
            if Editor.Build_Result_Summary.Retain_Pre_Run_Unavailable_Summary then
               State.Latest_Build_Result :=
                 Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                   (State.Latest_Build_Result,
                    Editor.Build_Result_Summary.Summary_From_Unavailable_Message
                      (Message));
               State.Latest_Build_Output_Details :=
                 Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                   (State.Latest_Build_Output_Details,
                    Editor.Build_Output_Details.Build_Unavailable_Output_Details
                      (Message));
            end if;
            return Result;
         end;
      end if;

      declare
         Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           Build_Run_Execution_Gate (State);
         Runner_Only_Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           (Process_Policy                  => Gate.Process_Policy,
            Allow_Build_Run                 => Gate.Allow_Build_Run,
            Allow_Real_Build_Tool_Execution => Gate.Allow_Real_Build_Tool_Execution,
            Allow_Real_Build_Tool_Fixture   => Gate.Allow_Real_Build_Tool_Fixture,
            Consent                         => Gate.Consent,
            Allow_Diagnostics_Ingestion     => False,
            Show_Diagnostics                => False);
         Ingestion : Editor.External_Producers.Diagnostic_Line_Command_Result :=
           Empty_Diagnostics;
      begin
         --  Phase 520 canonicalization: the public build frontdoor uses the
         --  bounded runner only for process execution.  Build-produced rows are
         --  then created, if requested, exclusively through the retained
         --  Editor.Build_Diagnostics seam so no runner/direct Build-local path
         --  owns Diagnostics review state.
         Begin_Public_Build_Job (State, To_String (Conversion.Request.Command_Label));
         Result := Editor.External_Producers.Run_Build_Command_With_Gate
           (State,
            Conversion.Request,
            Runner_Only_Gate);
         Complete_Public_Build_Job (State);

         Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
           (State,
            Conversion.Request,
            Result.Build_Result,
            Public_Build_Run_Diagnostics_Ingestion_Policy,
            State.Build_UI.Show_Diagnostics_On_Result);

         Result.Diagnostic_Result := Ingestion;
         Result.Command_Message := To_Unbounded_String
           (Editor.External_Producers.Build_Gated_Build_Command_Feedback
              (Result.Build_Result,
               Ingestion,
               Gate.Allow_Diagnostics_Ingestion,
               Gate.Allow_Diagnostics_Ingestion));

         State.Latest_Build_Result :=
           Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
             (State.Latest_Build_Result,
              Summary_From_Result
                (Conversion.Request, Result, Gate.Allow_Diagnostics_Ingestion));
         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
             (State.Latest_Build_Output_Details,
              Output_Details_From_Result (Result.Build_Result));
         return Result;
      end;
   end Execute_Public_Build_Run;

   function Execute_Public_Build_Run_With_Supplied_Result
     (State           : in out Editor.State.State_Type;
      Supplied_Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Command_Result;
      Readiness : constant Build_Run_Readiness_Status :=
        Validate_Build_Run_Invocation (State);
   begin
      if Readiness /= Build_Run_Readiness_Ready then
         declare
            Message : constant String := Build_Run_Unavailable_Reason (Readiness);
         begin
            Result :=
              (Build_Result      => Editor.External_Producers.Build_Build_Run_Result
                 (Editor.External_Producers.Build_Run_Not_Available),
               Diagnostic_Result => Empty_Diagnostics,
               Command_Message   => To_Unbounded_String (Message));
            if Editor.Build_Result_Summary.Retain_Pre_Run_Unavailable_Summary then
               State.Latest_Build_Result :=
                 Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                   (State.Latest_Build_Result,
                    Editor.Build_Result_Summary.Summary_From_Unavailable_Message
                      (Message));
               State.Latest_Build_Output_Details :=
                 Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                   (State.Latest_Build_Output_Details,
                    Editor.Build_Output_Details.Build_Unavailable_Output_Details
                      (Message));
            end if;
            return Result;
         end;
      end if;

      declare
         Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           Build_Run_Execution_Gate (State);
         Runner_Only_Gate : constant Editor.External_Producers.Build_Execution_Gate :=
           Editor.External_Producers.Build_Test_Fixture_Execution_Gate
             (Allow_Diagnostics_Ingestion => False,
              Show_Diagnostics            => False,
              Max_Output_Bytes            => Gate.Process_Policy.Max_Output_Bytes,
              Consent                     =>
                Editor.External_Producers.Build_Consent_Test_Only);
         Ingestion : Editor.External_Producers.Diagnostic_Line_Command_Result :=
           Empty_Diagnostics;
      begin
         Result := Editor.External_Producers.Run_Build_Command_With_Gate
           (State,
            Conversion.Request,
            Runner_Only_Gate,
            Supplied_Result);

         Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
           (State,
            Conversion.Request,
            Result.Build_Result,
            Public_Build_Run_Diagnostics_Ingestion_Policy,
            State.Build_UI.Show_Diagnostics_On_Result);

         Result.Diagnostic_Result := Ingestion;
         Result.Command_Message := To_Unbounded_String
           (Editor.External_Producers.Build_Gated_Build_Command_Feedback
              (Result.Build_Result,
               Ingestion,
               Gate.Allow_Diagnostics_Ingestion,
               Gate.Allow_Diagnostics_Ingestion));

         State.Latest_Build_Result :=
           Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
             (State.Latest_Build_Result,
              Summary_From_Result
                (Conversion.Request, Result, Gate.Allow_Diagnostics_Ingestion));
         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
             (State.Latest_Build_Output_Details,
              Output_Details_From_Result (Result.Build_Result));
         return Result;
      end;
   end Execute_Public_Build_Run_With_Supplied_Result;

   function Assert_Build_Run_Descriptor_Stable return Boolean
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
      Name : constant String := To_String (D.Name);
      Description : constant String := To_String (D.Description);
   begin
      return Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run"
        and then Editor.Commands.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Run)
        and then D.Visibility = Editor.Commands.Palette_Command
        and then D.Category = Editor.Commands.Project_Category
        and then not D.Bindable
        and then Name = "Run Build"
        and then Description'Length > 0
        and then Description'Length < 240
        and then Ada.Strings.Fixed.Index (Description, "gprbuild ") = 0
        and then Ada.Strings.Fixed.Index (Description, "alr build") = 0
        and then Ada.Strings.Fixed.Index (Description, "cwd") = 0;
   end Assert_Build_Run_Descriptor_Stable;

   function Assert_Build_Run_Routes_Through_Executor
     (State : Editor.State.State_Type) return Boolean
   is
      A : constant Editor.Commands.Command_Availability :=
        Build_Run_Availability (State);
      Readiness : constant Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result :=
        Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (State);
   begin
      return not Editor.Commands.Is_Available (A)
        and then Readiness.Routes_Through_Executor
        and then Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run).Visibility = Editor.Commands.Palette_Command;
   end Assert_Build_Run_Routes_Through_Executor;

   function Assert_Build_Run_Availability_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean
   is
      Before : constant Build_Run_Readiness_Status := Build_Run_Readiness (State);
      After  : constant Build_Run_Readiness_Status := Build_Run_Readiness (State);
   begin
      return Before = After;
   end Assert_Build_Run_Availability_Side_Effect_Free;

   function Assert_Build_Run_Command_Palette_Boundary
     (State : Editor.State.State_Type) return Boolean
   is
      pragma Unreferenced (State);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
   begin
      --  The Command Palette projects descriptors and Executor availability;
      --  build.run supplies no request payload, cwd, or consent through its
      --  descriptor.
      return D.Visibility = Editor.Commands.Palette_Command
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run";
   end Assert_Build_Run_Command_Palette_Boundary;

   function Assert_Build_Run_Keybinding_Boundary return Boolean
   is
      Info : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run);
   begin
      return not Info.Has_Binding
        and then not Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run).Bindable;
   end Assert_Build_Run_Keybinding_Boundary;

   function Assert_Build_Run_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State.Build_UI)
        and then not Editor.Build_UI.Has_Raw_Shell_Command_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field (State.Build_UI)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Persistence_Excluded
          (State.Build_UI.Selected_Working_Context)
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted;
   end Assert_Build_Run_Persistence_Excluded;

   function Assert_Build_Cancel_Command_Descriptor_Stable return Boolean
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Cancel);
      Name : constant String := To_String (D.Name);
   begin
      return Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Cancel) = "build.cancel"
        and then Editor.Commands.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Cancel)
        and then D.Visibility = Editor.Commands.Palette_Command
        and then D.Category = Editor.Commands.Project_Category
        and then not D.Bindable
        and then Name = "Cancel Build";
   end Assert_Build_Cancel_Command_Descriptor_Stable;

   function Assert_Build_Cancel_Requires_Active_Job
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.State.State_Type := State;
      No_Job_Available : constant Boolean :=
        not Editor.Commands.Is_Available (Build_Cancel_Availability (Copy));
   begin
      Begin_Public_Build_Job (Copy, "audit");
      return No_Job_Available
        and then Editor.Commands.Is_Available (Build_Cancel_Availability (Copy));
   end Assert_Build_Cancel_Requires_Active_Job;

   function Assert_Public_Build_Command_Registration_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Run_Descriptor_Stable
        and then Assert_Build_Run_Routes_Through_Executor (State)
        and then Assert_Build_Run_Availability_Side_Effect_Free (State)
        and then Assert_Build_Run_Command_Palette_Boundary (State)
        and then Assert_Build_Run_Keybinding_Boundary
        and then Assert_Build_Run_Persistence_Excluded (State)
        and then Assert_Build_Cancel_Command_Descriptor_Stable
        and then Assert_Build_Cancel_Requires_Active_Job (State)
        and then Editor.Build_Diagnostics.Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent
        and then Validate_Build_Run_Invocation (State) /= Build_Run_Readiness_Ready;
   end Assert_Public_Build_Command_Registration_Coherent;


   function Async_Test_Request return Editor.External_Producers.Build_Run_Request is
   begin
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_Test,
         Working_Label => To_Unbounded_String ("async-test-root"),
         Command_Label => To_Unbounded_String ("async test build"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
   end Async_Test_Request;

   function Assert_Async_Build_Cancel_Handoff_Behavior return Boolean is
      S : Editor.State.State_Type;
      Worker_State : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
      Poll_Result : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async cancellation behavior");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Public_Build_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Public_Build_Async_Slot_Id);
      Editor.Build_Process_Control.Publish_Active_Process
        (Editor.Build_Process_Control.Test_Cancellable_Handle);

      if not Has_Queued_Public_Build_Job (S) then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Result := Request_Public_Build_Cancel (S);
      if Result.Build_Result.Status /= Editor.External_Producers.Build_Run_Cancelled
        or else S.Public_Build_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else not Editor.Build_Process_Control.Active_Cancel_Requested
      then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Snapshot_While_Running (S.Public_Build_Async_Slot_Id, Worker_State);
      if Worker_State.Public_Build_Job_Cancellation /=
        Editor.Build_Runner_Policy.Cancellation_Requested
      then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Store_Worker_Result
        (S.Public_Build_Async_Slot_Id, Worker_State,
         (Build_Result => Editor.External_Producers.Build_Build_Run_Result
            (Editor.External_Producers.Build_Run_Cancelled,
             Output_Partial => True),
          Diagnostic_Result => Editor.External_Producers.Empty_Diagnostic_Line_Command_Result,
          Command_Message => To_Unbounded_String ("Build cancelled")));

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      return Completed
        and then Poll_Result.Build_Result.Status =
          Editor.External_Producers.Build_Run_Cancelled
        and then not S.Public_Build_Job_Active
        and then not S.Public_Build_Async_Job_Queued
        and then S.Public_Build_Job_Cancellation =
          Editor.Build_Runner_Policy.Cancellation_Acknowledged
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle);
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Cancel_Handoff_Behavior;

   function Assert_Async_Build_Output_Snapshot_Handoff_Behavior return Boolean is
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean;
      Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async output behavior");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Public_Build_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Public_Build_Async_Slot_Id);

      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (Stream, S.Public_Build_Job_Id);
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream,
         Editor.Build_Output_Details.Build_Output_Stream_Stdout,
         "compile unit A" & Character'Val (10));
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream,
         Editor.Build_Output_Details.Build_Output_Stream_Stderr,
         "unit_b.adb:1:1: warning" & Character'Val (10));
      Editor.Build_Process_Control.Publish_Active_Output_Stream (Stream);

      Completed := Poll_Public_Build_Run_Completion (S, Result);
      if Completed
        or else Result.Build_Result.Status /=
          Editor.External_Producers.Build_Run_Succeeded
        or else not Result.Build_Result.Output_Partial
      then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      declare
         OK : constant Boolean :=
           S.Public_Build_Output_Stream.Active
           and then S.Public_Build_Output_Stream.Chunk_Count = 2
           and then S.Latest_Build_Output_Details.Output_Partial
           and then S.Latest_Build_Output_Details.Stdout_Available
           and then S.Latest_Build_Output_Details.Stderr_Available;
      begin
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Output_Snapshot_Handoff_Behavior;

   function Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion
     return Boolean
   is
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean;
      Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Consent_Test_Only);
      Stdout_Marker : constant String := "stdout-before-completion";
      Stderr_Marker : constant String := "stderr-before-completion";
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async partial output behavior");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Public_Build_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Public_Build_Async_Slot_Id);

      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (Stream, S.Public_Build_Job_Id);
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream,
         Editor.Build_Output_Details.Build_Output_Stream_Stdout,
         Stdout_Marker & Character'Val (10));
      Editor.Build_Process_Control.Publish_Active_Output_Stream (Stream);

      Completed := Poll_Public_Build_Run_Completion (S, Result);
      if Completed
        or else Result.Command_Message /= To_Unbounded_String ("Build still running.")
        or else not S.Public_Build_Output_Stream.Active
        or else S.Public_Build_Output_Stream.Chunk_Count /= 1
        or else not S.Latest_Build_Output_Details.Output_Partial
        or else not S.Latest_Build_Output_Details.Stdout_Available
        or else S.Latest_Build_Output_Details.Stderr_Available
        or else Ada.Strings.Fixed.Index
          (To_String (S.Latest_Build_Output_Details.Stdout_Excerpt),
           Stdout_Marker) = 0
        or else not S.Public_Build_Job_Active
        or else not S.Public_Build_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream,
         Editor.Build_Output_Details.Build_Output_Stream_Stderr,
         Stderr_Marker & Character'Val (10));
      Editor.Build_Process_Control.Publish_Active_Output_Stream (Stream);

      Completed := Poll_Public_Build_Run_Completion (S, Result);
      declare
         OK : constant Boolean :=
           (not Completed)
           and then Result.Command_Message = To_Unbounded_String ("Build still running.")
           and then S.Public_Build_Output_Stream.Active
           and then S.Public_Build_Output_Stream.Chunk_Count = 2
           and then S.Latest_Build_Output_Details.Kind =
             Editor.Build_Output_Details.Build_Output_Details_Partial
           and then S.Latest_Build_Output_Details.Output_Partial
           and then S.Latest_Build_Output_Details.Stdout_Available
           and then S.Latest_Build_Output_Details.Stderr_Available
           and then Ada.Strings.Fixed.Index
             (To_String (S.Latest_Build_Output_Details.Stdout_Excerpt),
              Stdout_Marker) /= 0
           and then Ada.Strings.Fixed.Index
             (To_String (S.Latest_Build_Output_Details.Stderr_Excerpt),
              Stderr_Marker) /= 0
           and then S.Public_Build_Job_Active
           and then S.Public_Build_Async_Job_Queued
           and then not S.Public_Build_Async_Job_Result_Pending;
      begin
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion;

   function Assert_Async_Build_Real_Process_Cancel_Integration
     return Boolean
   is
      use type Editor.External_Producers.Process_Run_Status;
      use type Editor.Build_Process_Control.Build_Process_Cancel_Result;

      Sleep_Path : constant String := "/bin/sleep";
      S : Editor.State.State_Type;
      Poll_Result : Editor.External_Producers.Build_Command_Result;
      Cancel_Result : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean := False;
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
      Process_Request : Editor.External_Producers.Process_Run_Request;
      Process_Result : Editor.External_Producers.Process_Run_Result;
      Build_Result : Editor.External_Producers.Build_Command_Result;
      Policy : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 4096,
         Require_Absolute_Program => True,
         Timeout_Milliseconds     => 10_000);
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Real_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Require_Absolute_Program => True,
           Max_Output_Bytes => 4096,
           Consent => Editor.External_Producers.Build_Consent_User_Confirmed);

      task type Real_Process_Cancel_Worker is
         entry Start (Slot_Id : Natural);
      end Real_Process_Cancel_Worker;

      task body Real_Process_Cancel_Worker is
         Worker_State : Editor.State.State_Type;
         Worker_Slot : Natural := 0;
      begin
         accept Start (Slot_Id : Natural) do
            Worker_Slot := Slot_Id;
         end Start;
         Public_Build_Jobs.Mark_Worker_Running (Worker_Slot);
         Public_Build_Jobs.Snapshot_While_Running (Worker_Slot, Worker_State);
         Process_Result :=
           Editor.External_Producers.Execute_Process_Request_Gated_With_State
             (Worker_State,
              Process_Request,
              Policy,
              Editor.External_Producers.Build_Process_Run_Result
                (Editor.External_Producers.Process_Run_Not_Available));
         Build_Result :=
           (Build_Result =>
              Editor.External_Producers.Build_Result_From_Process_Result
                (Async_Test_Request, Process_Result),
            Diagnostic_Result =>
              Editor.External_Producers.Empty_Diagnostic_Line_Command_Result,
            Command_Message =>
              To_Unbounded_String
                ((if Process_Result.Status =
                       Editor.External_Producers.Process_Run_Cancelled
                  then "Build cancelled"
                  else "Build finished")));
         Public_Build_Jobs.Store_Worker_Result (Worker_Slot, Worker_State, Build_Result);
      exception
         when others =>
            Public_Build_Jobs.Store_Worker_Result
              (Worker_Slot, Worker_State,
               (Build_Result => Editor.External_Producers.Build_Build_Run_Result
                  (Editor.External_Producers.Build_Run_Execution_Error),
                Diagnostic_Result =>
                  Editor.External_Producers.Empty_Diagnostic_Line_Command_Result,
                Command_Message => To_Unbounded_String ("Build worker failed")));
      end Real_Process_Cancel_Worker;

      Worker : Real_Process_Cancel_Worker;

      function Wait_For_Active_Process return Boolean is
      begin
         for Attempt in 1 .. 80 loop
            if Editor.Build_Process_Control.Is_Active
              (Editor.Build_Process_Control.Active_Process_Handle)
            then
               return True;
            end if;
            delay 0.05;
         end loop;
         return False;
      end Wait_For_Active_Process;

      function Wait_For_Final_Result return Boolean is
      begin
         for Attempt in 1 .. 100 loop
            if Public_Build_Jobs.Result_Ready (S.Public_Build_Async_Slot_Id) then
               return True;
            end if;
            delay 0.05;
         end loop;
         return False;
      end Wait_For_Final_Result;
   begin
      if not Ada.Directories.Exists (Sleep_Path) then
         --  Host fixture is unavailable; keep the test non-failing on systems
         --  without the POSIX sleep binary while release_check still guards
         --  that the real-process integration assertion exists.
         return True;
      end if;

      Editor.State.Initialize (S);
      Editor.External_Producers.Append_Process_Argument (Args, "5");
      Process_Request :=
        (Program_Label        => To_Unbounded_String (Sleep_Path),
         Working_Label        => To_Unbounded_String (Ada.Directories.Current_Directory),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Args);

      Begin_Public_Build_Job (S, "real-process async cancellation integration");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Public_Build_Job_Id);

      Worker.Start (S.Public_Build_Async_Slot_Id);

      if not Wait_For_Active_Process then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      if Completed
        or else Poll_Result.Command_Message /= To_Unbounded_String ("Build still running.")
        or else not S.Public_Build_Job_Active
        or else not S.Public_Build_Async_Job_Queued
      then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Cancel_Result := Request_Public_Build_Cancel (S);
      if Cancel_Result.Build_Result.Status /= Editor.External_Producers.Build_Run_Cancelled
        or else not Editor.Build_Process_Control.Active_Cancel_Requested
      then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      if not Wait_For_Final_Result then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      return Completed
        and then Poll_Result.Build_Result.Status =
          Editor.External_Producers.Build_Run_Cancelled
        and then Process_Result.Status =
          Editor.External_Producers.Process_Run_Cancelled
        and then not S.Public_Build_Job_Active
        and then not S.Public_Build_Async_Job_Queued
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle);
   exception
      when others =>
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Real_Process_Cancel_Integration;


   function Assert_Async_Build_State_Slots_Are_Isolated
     return Boolean
   is
      S1 : Editor.State.State_Type;
      S2 : Editor.State.State_Type;
      Snap1 : Editor.State.State_Type;
      Snap2 : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
   begin
      Editor.State.Initialize (S1);
      Editor.State.Initialize (S2);
      Begin_Public_Build_Job (S1, "async slot one");
      Begin_Public_Build_Job (S2, "async slot two");

      if S1.Public_Build_Async_Slot_Id = 0
        or else S2.Public_Build_Async_Slot_Id = 0
        or else S1.Public_Build_Async_Slot_Id = S2.Public_Build_Async_Slot_Id
      then
         return False;
      end if;

      S1.Public_Build_Async_Job_Queued := True;
      S2.Public_Build_Async_Job_Queued := True;
      Public_Build_Jobs.Store_Queued
        (S1.Public_Build_Async_Slot_Id, S1, Async_Test_Request, Gate, Gate, S1.Public_Build_Job_Id);
      Public_Build_Jobs.Store_Queued
        (S2.Public_Build_Async_Slot_Id, S2, Async_Test_Request, Gate, Gate, S2.Public_Build_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S1.Public_Build_Async_Slot_Id);
      Public_Build_Jobs.Mark_Worker_Running (S2.Public_Build_Async_Slot_Id);
      Public_Build_Jobs.Mark_Cancellation_Requested (S1.Public_Build_Async_Slot_Id);

      Public_Build_Jobs.Snapshot_While_Running (S1.Public_Build_Async_Slot_Id, Snap1);
      Public_Build_Jobs.Snapshot_While_Running (S2.Public_Build_Async_Slot_Id, Snap2);

      declare
         OK : constant Boolean :=
           Snap1.Public_Build_Job_Cancellation =
             Editor.Build_Runner_Policy.Cancellation_Requested
           and then Snap2.Public_Build_Job_Cancellation =
             Editor.Build_Runner_Policy.No_Cancellation_Requested
           and then Public_Build_Jobs.Has_Job
             (S1.Public_Build_Async_Slot_Id, S1.Public_Build_Job_Id)
           and then Public_Build_Jobs.Has_Job
             (S2.Public_Build_Async_Slot_Id, S2.Public_Build_Job_Id);
      begin
         Public_Build_Jobs.Clear (S1.Public_Build_Async_Slot_Id);
         Public_Build_Jobs.Clear (S2.Public_Build_Async_Slot_Id);
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S1.Public_Build_Async_Slot_Id);
         Public_Build_Jobs.Clear (S2.Public_Build_Async_Slot_Id);
         return False;
   end Assert_Async_Build_State_Slots_Are_Isolated;


   function Assert_Async_Build_Slot_Id_Is_Stable_Per_State
     return Boolean
   is
      S : Editor.State.State_Type;
      First_Slot : Natural;
      First_Job : Natural;
      Second_Slot : Natural;
      Second_Job : Natural;
   begin
      Editor.State.Initialize (S);

      Begin_Public_Build_Job (S, "async slot stable first build");
      First_Slot := S.Public_Build_Async_Slot_Id;
      First_Job := S.Public_Build_Job_Id;
      Complete_Public_Build_Job (S);

      if First_Slot = 0
        or else S.Public_Build_Async_Slot_Id /= First_Slot
        or else S.Public_Build_Job_Active
      then
         return False;
      end if;

      Begin_Public_Build_Job (S, "async slot stable second build");
      Second_Slot := S.Public_Build_Async_Slot_Id;
      Second_Job := S.Public_Build_Job_Id;
      Complete_Public_Build_Job (S);

      return Second_Slot = First_Slot
        and then Second_Job = First_Job + 1
        and then S.Public_Build_Async_Slot_Id = First_Slot
        and then not S.Public_Build_Job_Active
        and then not S.Public_Build_Async_Job_Queued
        and then not S.Public_Build_Async_Job_Result_Pending;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         return False;
   end Assert_Async_Build_Slot_Id_Is_Stable_Per_State;


   function Assert_Async_Build_Slot_Pool_Exhaustion_Is_Rejected
     return Boolean
   is
      S1 : Editor.State.State_Type;
      S2 : Editor.State.State_Type;
      S3 : Editor.State.State_Type;
      S4 : Editor.State.State_Type;
      S5 : Editor.State.State_Type;
      S6 : Editor.State.State_Type;
      S7 : Editor.State.State_Type;
      S8 : Editor.State.State_Type;
      S9 : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);

      procedure Queue_Test_Job (S : in out Editor.State.State_Type; Label : String) is
      begin
         Editor.State.Initialize (S);
         Begin_Public_Build_Job (S, Label);
         Public_Build_Jobs.Store_Queued
           (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate,
            S.Public_Build_Job_Id);
      end Queue_Test_Job;

      procedure Clear_Test_Job (S : in out Editor.State.State_Type) is
      begin
         if S.Public_Build_Async_Slot_Id /= 0 then
            Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         end if;
         Complete_Public_Build_Job (S);
      end Clear_Test_Job;
   begin
      Queue_Test_Job (S1, "async slot occupancy 1");
      Queue_Test_Job (S2, "async slot occupancy 2");
      Queue_Test_Job (S3, "async slot occupancy 3");
      Queue_Test_Job (S4, "async slot occupancy 4");
      Queue_Test_Job (S5, "async slot occupancy 5");
      Queue_Test_Job (S6, "async slot occupancy 6");
      Queue_Test_Job (S7, "async slot occupancy 7");
      Queue_Test_Job (S8, "async slot occupancy 8");

      Editor.State.Initialize (S9);
      Begin_Public_Build_Job (S9, "async slot occupancy 9");

      declare
         Rejected : constant Boolean :=
           not Public_Build_Jobs.Slot_Available_For (S9.Public_Build_Async_Slot_Id);
      begin
         Clear_Test_Job (S1);
         Clear_Test_Job (S2);
         Clear_Test_Job (S3);
         Clear_Test_Job (S4);
         Clear_Test_Job (S5);
         Clear_Test_Job (S6);
         Clear_Test_Job (S7);
         Clear_Test_Job (S8);
         Clear_Test_Job (S9);
         return Rejected;
      end;
   exception
      when others =>
         Clear_Test_Job (S1);
         Clear_Test_Job (S2);
         Clear_Test_Job (S3);
         Clear_Test_Job (S4);
         Clear_Test_Job (S5);
         Clear_Test_Job (S6);
         Clear_Test_Job (S7);
         Clear_Test_Job (S8);
         Clear_Test_Job (S9);
         return False;
   end Assert_Async_Build_Slot_Pool_Exhaustion_Is_Rejected;


   function Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior
     return Boolean
   is
      S : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        Async_Test_Request;
      Result : Editor.External_Producers.Build_Command_Result;
      Worker_State : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "lifecycle shutdown behavior");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Request, Gate, Gate, S.Public_Build_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Public_Build_Async_Slot_Id);

      Result := Request_Public_Build_Lifecycle_Shutdown (S, "closing project");
      Public_Build_Jobs.Snapshot_While_Running (S.Public_Build_Async_Slot_Id, Worker_State);

      if Result.Build_Result.Status /= Editor.External_Producers.Build_Run_Cancelled
        or else S.Public_Build_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else Worker_State.Public_Build_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else not S.Public_Build_Job_Active
        or else not S.Public_Build_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
      Complete_Public_Build_Job (S);
      return True;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior;


   function Assert_Async_Build_Worker_Shutdown_Drain_Behavior
     return Boolean
   is
      S : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Execution_Gate :=
        Editor.External_Producers.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
      Result : Editor.External_Producers.Build_Command_Result;
      Completed : Boolean := False;
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async worker shutdown drain behavior");
      S.Public_Build_Async_Job_Queued := True;
      S.Public_Build_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Public_Build_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Public_Build_Job_Id);

      --  A disabled-gate worker finishes quickly, but the drain path is still
      --  the same deterministic shutdown handshake used by application exit.
      Public_Build_Workers (Slot_Index_For (S.Public_Build_Async_Slot_Id)).Start
        (S.Public_Build_Async_Slot_Id);
      Result := Drain_Public_Build_Worker_For_Shutdown (S, "application shutdown");

      if S.Public_Build_Async_Job_Queued then
         Completed := Poll_Public_Build_Run_Completion (S, Result);
      else
         Completed := True;
      end if;

      return Completed
        and then not S.Public_Build_Job_Active
        and then not S.Public_Build_Async_Job_Queued
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle);
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Public_Build_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Worker_Shutdown_Drain_Behavior;


   function Assert_Async_Build_Worker_Stop_Terminates_Pool_Behavior
     return Boolean
   is
   begin
      --  This assertion is intended to be registered last: it exercises the
      --  final application-exit stop path and therefore terminates the worker
      --  pool for the process.
      if Public_Build_Worker_Lifecycle.Stopped then
         return True;
      end if;

      Stop_Public_Build_Workers_For_Application_Exit;

      return Public_Build_Worker_Lifecycle.Stopped
        and then Public_Build_Worker_Lifecycle.Stop_Requested;
   exception
      when others =>
         return False;
   end Assert_Async_Build_Worker_Stop_Terminates_Pool_Behavior;


end Editor.Build_Command;
