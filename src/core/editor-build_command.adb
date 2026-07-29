with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
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
with Editor.Build_Command_Audit;
with Editor.Build_Command.Projections;
with Editor.Build_Command.Readiness;
with Editor.Build_Command.Registry;
with Editor.Build_Command.Execution;
with Editor.Ada_Language_Service;
with Editor.External_Producers;
with Editor.External_Producers.Build_Types;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Build_Command_Execution;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.Keybindings;
with Editor.Project;
with Editor.View;


package body Editor.Build_Command is

   use Editor.Build_Command.Registry;

   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.External_Producers.Build_Types.Build_Request_Validation_Status;
   use type Editor.External_Producers.Build_Types.Build_Run_Status;
   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Commands.Descriptors.Command_Category;
   use type Build_Run_Readiness_Status;
   use type Editor.Build_Runner_Policy.Build_Execution_Policy;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use type Editor.Build_Process_Control.Build_Process_Cancel_Result;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use Editor.Build_Command.Projections;
   use Editor.Build_Command.Readiness;


   function Build_Run_Readiness
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
     renames Editor.Build_Command.Readiness.Build_Run_Readiness;

   function Build_Run_Unavailable_Reason
     (Status : Build_Run_Readiness_Status) return String
     renames Editor.Build_Command.Readiness.Build_Run_Unavailable_Reason;

   function Build_Run_Recovery_Hint
     (Status : Build_Run_Readiness_Status) return String
     renames Editor.Build_Command.Readiness.Build_Run_Recovery_Hint;

   function Build_Run_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Availability_Metadata.Command_Availability
     renames Editor.Build_Command.Readiness.Build_Run_Availability;

   function Has_Active_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean
     renames Editor.Build_Command.Readiness.Has_Active_Public_Build_Job;

   function Build_Cancel_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Availability_Metadata.Command_Availability
     renames Editor.Build_Command.Readiness.Build_Cancel_Availability;

   procedure Begin_Public_Build_Job
     (State : in out Editor.State.State_Type;
      Label : String)
   is
   begin
      State.Build.Public_Job_Active := True;
      State.Build.Public_Job_Id := State.Build.Public_Job_Id + 1;
      State.Build.Public_Job_Started_At := Editor.View.Current_Time_Seconds;
      State.Build.Public_Job_Has_Start_Time := True;
      if State.Build.Public_Async_Slot_Id = 0 then
         Public_Build_Slot_Allocator.Allocate (State.Build.Public_Async_Slot_Id);
      end if;
      State.Build.Public_Job_Label := To_Unbounded_String (Label);
      State.Build.Public_Job_Cancellation :=
        Editor.Build_Runner_Policy.No_Cancellation_Requested;
      State.Build.Public_Process_Handle :=
        Editor.Build_Process_Control.No_Process_Handle;
      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (State.Build.Public_Output_Stream, State.Build.Public_Job_Id);
   end Begin_Public_Build_Job;

   procedure Register_Public_Build_Process
     (State  : in out Editor.State.State_Type;
      Handle : Editor.Build_Process_Control.Build_Process_Handle)
   is
   begin
      if State.Build.Public_Job_Active then
         State.Build.Public_Process_Handle := Handle;
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
      State.Build.Public_Job_Active := False;
      State.Build.Public_Job_Has_Start_Time := False;
      State.Build.Public_Job_Label := Null_Unbounded_String;
      State.Build.Public_Process_Handle :=
        Editor.Build_Process_Control.No_Process_Handle;
      Editor.Build_Process_Control.Clear_Active_Process;
      Editor.Build_Output_Details.Finish_Build_Output_Stream
        (State.Build.Public_Output_Stream);
      --  Public_Build_Async_Slot_Id is deliberately stable for the
      --  editor state.  Completion clears the transient job markers and
      --  protected registry payload, but does not reset the slot; later
      --  builds from the same state reuse the same worker-pool slot with a
      --  new Public_Build_Job_Id.
      if State.Build.Public_Job_Cancellation =
        Editor.Build_Runner_Policy.Cancellation_Requested
      then
         State.Build.Public_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Acknowledged;
      else
         State.Build.Public_Job_Cancellation :=
           Editor.Build_Runner_Policy.No_Cancellation_Requested;
      end if;
   end Complete_Public_Build_Job;

   function Request_Public_Build_Cancel
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Empty_Diagnostics : constant
        Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
          Editor.External_Producers.Diagnostic_Line_Parsing.
            Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
   begin
      if not State.Build.Public_Job_Active then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
         return Result;
      end if;

      if State.Build.Public_Async_Job_Queued
        and then not Editor.Build_Process_Control.Is_Active
          (State.Build.Public_Process_Handle)
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle)
      then
         State.Build.Public_Job_Cancellation :=
           Editor.Build_Runner_Policy.Cancellation_Requested;
         Public_Build_Jobs.Mark_Cancellation_Requested (State.Build.Public_Async_Slot_Id);
         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build cancellation requested."));
      end if;

      declare
         Handle : Editor.Build_Process_Control.Build_Process_Handle :=
           (if Editor.Build_Process_Control.Is_Active
                 (State.Build.Public_Process_Handle)
            then State.Build.Public_Process_Handle
            else Editor.Build_Process_Control.Active_Process_Handle);
         Cancel_Result : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
           (if Editor.Build_Process_Control.Is_Active
                 (Editor.Build_Process_Control.Active_Process_Handle)
            then Editor.Build_Process_Control.Request_Active_Cancel
            else Editor.Build_Process_Control.Request_Cancel (Handle));
      begin
         case Cancel_Result is
            when Editor.Build_Process_Control.Build_Process_Cancel_Sent =>
               State.Build.Public_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Requested;
               Public_Build_Jobs.Mark_Cancellation_Requested (State.Build.Public_Async_Slot_Id);
               State.Build.Public_Process_Handle := Handle;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Types.Build_Run_Cancelled),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   => To_Unbounded_String ("Build cancellation requested."));
               State.Build.Latest_Result :=
                 Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                   (State.Build.Latest_Result,
                    Editor.Build_Result_Summary.Build_Summary
                      (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Cancelled,
                       Invocation_Label => "build.cancel",
                       Tool_Kind => Editor.Build_Result_Summary.Build_Result_No_Tool,
                       Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal,
                       Working_Context_Label => To_String (State.Build.Public_Job_Label),
                       Runner_Status_Label => "cancelled",
                       Primary_Message => "Build cancellation requested",
                       Cancelled => True,
                       Output_Partial => True));
               State.Build.Latest_Output_Details :=
                 Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                   (State.Build.Latest_Output_Details,
                    Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
                      (Runner_Status =>
                         Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
                       Stdout_Text => State.Build.Public_Output_Stream.Stdout_Text,
                       Stderr_Text => State.Build.Public_Output_Stream.Stderr_Text,
                       Stdout_Truncated => State.Build.Public_Output_Stream.Stdout_Truncated,
                       Stderr_Truncated => State.Build.Public_Output_Stream.Stderr_Truncated,
                       Output_Partial => True));
               return Result;

            when Editor.Build_Process_Control.Build_Process_Cancel_Not_Active
               | Editor.Build_Process_Control.Build_Process_Cancel_Not_Cancellable =>
               State.Build.Public_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Unsupported;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Types.Build_Run_Cancellation_Unsupported),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   =>
                    To_Unbounded_String ("Build unavailable: cancellation unsupported."));

            when Editor.Build_Process_Control.Build_Process_Cancel_Failed =>
               State.Build.Public_Job_Cancellation :=
                 Editor.Build_Runner_Policy.Cancellation_Unsupported;
               Result :=
                 (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
                    (Editor.External_Producers.Build_Types.Build_Run_Execution_Error),
                  Diagnostic_Result => Empty_Diagnostics,
                  Command_Message   =>
                    To_Unbounded_String ("Build cancellation failed."));
         end case;
      end;

      State.Build.Latest_Result :=
        Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
          (State.Build.Latest_Result,
           Editor.Build_Result_Summary.Build_Summary
             (Kind => Editor.Build_Result_Summary.Build_Result_Summary_Unavailable,
              Invocation_Label => "build.cancel",
              Tool_Kind => Editor.Build_Result_Summary.Build_Result_No_Tool,
              Request_Mode => Editor.Build_Result_Summary.Build_Result_Request_Test_Or_Internal,
              Working_Context_Label => To_String (State.Build.Public_Job_Label),
              Runner_Status_Label => "cancellation unsupported",
              Primary_Message => "Build unavailable: cancellation unsupported",
              Cancellation_Unsupported => True,
              Output_Partial => True));
      State.Build.Latest_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Build.Latest_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
             (Runner_Status =>
                Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported,
              Stdout_Text => State.Build.Public_Output_Stream.Stdout_Text,
              Stderr_Text => State.Build.Public_Output_Stream.Stderr_Text,
              Stdout_Truncated => State.Build.Public_Output_Stream.Stdout_Truncated,
              Stderr_Truncated => State.Build.Public_Output_Stream.Stderr_Truncated,
              Output_Partial => True));
      return Result;
   end Request_Public_Build_Cancel;


   function Request_Public_Build_Lifecycle_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Cancel_Result : Editor.Build_Process_Control.Build_Process_Cancel_Result :=
        Editor.Build_Process_Control.Build_Process_Cancel_Not_Active;
      Empty_Diagnostics : constant
        Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
          Editor.External_Producers.Diagnostic_Line_Parsing.
            Empty_Diagnostic_Line_Command_Result;
      Message : constant String :=
        (if Reason'Length = 0 then
            "Build cancellation requested before lifecycle transition."
         else
            "Build cancellation requested before " & Reason & ".");
   begin
      if not State.Build.Public_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
      end if;

      State.Build.Public_Job_Cancellation :=
        Editor.Build_Runner_Policy.Cancellation_Requested;

      if State.Build.Public_Async_Job_Queued then
         Public_Build_Jobs.Mark_Cancellation_Requested
           (State.Build.Public_Async_Slot_Id);
      end if;

      if Editor.Build_Process_Control.Is_Active
        (Editor.Build_Process_Control.Active_Process_Handle)
      then
         Cancel_Result := Editor.Build_Process_Control.Request_Active_Cancel;
      elsif Editor.Build_Process_Control.Is_Active
        (State.Build.Public_Process_Handle)
      then
         Cancel_Result :=
           Editor.Build_Process_Control.Request_Cancel
             (State.Build.Public_Process_Handle);
      end if;

      declare
         Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
         Available : Boolean := False;
      begin
         Editor.Build_Process_Control.Active_Output_Stream (Stream, Available);
         if Available then
            State.Build.Public_Output_Stream := Stream;
         end if;
      end;

      State.Build.Latest_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Build.Latest_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Build.Public_Output_Stream,
              Editor.Build_Output_Details.Build_Output_Runner_Cancelled,
              Output_Partial => True));

      if Cancel_Result = Editor.Build_Process_Control.Build_Process_Cancel_Failed then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build cancellation requested before " & Reason & "; process signal failed."));
      else
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Cancelled,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String (Message));
      end if;
      return Result;
   end Request_Public_Build_Lifecycle_Shutdown;


   function Drain_Public_Build_Worker_For_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Poll_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Empty_Diagnostics : constant
        Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
          Editor.External_Producers.Diagnostic_Line_Parsing.
            Empty_Diagnostic_Line_Command_Result;
   begin
      if not State.Build.Public_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Types.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No active build job."));
      end if;

      Result := Request_Public_Build_Lifecycle_Shutdown (State, Reason);

      if State.Build.Public_Async_Slot_Id /= 0 then
         Public_Build_Workers
           (Slot_Index_For (State.Build.Public_Async_Slot_Id)).Drain
             (State.Build.Public_Async_Slot_Id);
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
      if State.Build.Public_Async_Slot_Id /= 0
        and then not State.Build.Public_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (State.Build.Public_Async_Slot_Id);
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
      if not State.Build.Public_Job_Active then
         return;
      end if;

      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (State.Build.Public_Output_Stream, Output_Stream, Text);
      State.Build.Latest_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Build.Latest_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Build.Public_Output_Stream,
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
        (State.Build.Public_Output_Stream);
      State.Build.Latest_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Build.Latest_Output_Details,
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Build.Public_Output_Stream,
              Runner_Status => Runner_Status,
              Output_Partial => False,
              Exit_Code => Exit_Code,
              Has_Exit_Code => Has_Exit_Code));
   end Complete_Public_Build_Output_Stream;

   function Validate_Build_Run_Invocation
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status
     renames Editor.Build_Command.Readiness.Validate_Build_Run_Invocation;

   function Build_Run_Execution_Gate
     (State : Editor.State.State_Type)
      return Editor.External_Producers.Build_Types.Build_Execution_Gate
     renames Editor.Build_Command.Readiness.Build_Run_Execution_Gate;

   function Has_Queued_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return State.Build.Public_Async_Job_Queued
        and then Public_Build_Jobs.Has_Job (State.Build.Public_Async_Slot_Id, State.Build.Public_Job_Id);
   end Has_Queued_Public_Build_Job;

   function Start_Public_Build_Run_Asynchronously
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
   begin
      return Editor.Build_Command.Execution.Start_Public_Build_Run_Asynchronously (State);
   end Start_Public_Build_Run_Asynchronously;

   function Poll_Public_Build_Run_Completion
     (State : in out Editor.State.State_Type;
      Result : out Editor.External_Producers.Build_Requests.Build_Command_Result) return Boolean
   is
   begin
      return Editor.Build_Command.Execution.Poll_Public_Build_Run_Completion
        (State, Result);
   end Poll_Public_Build_Run_Completion;


   function Execute_Public_Build_Run
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
   begin
      return Editor.Build_Command.Execution.Execute_Public_Build_Run (State);
   end Execute_Public_Build_Run;

   function Execute_Public_Build_Run_With_Supplied_Result
     (State           : in out Editor.State.State_Type;
      Supplied_Result : Editor.External_Producers.Build_Types.Process_Run_Result)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
   begin
      return Editor.Build_Command.Execution.Execute_Public_Build_Run_With_Supplied_Result
        (State, Supplied_Result);
   end Execute_Public_Build_Run_With_Supplied_Result;

   function Assert_Build_Run_Descriptor_Stable return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Descriptor_Stable;
   end Assert_Build_Run_Descriptor_Stable;

   function Assert_Build_Run_Routes_Through_Executor
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Routes_Through_Executor (State);
   end Assert_Build_Run_Routes_Through_Executor;

   function Assert_Build_Run_Availability_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Availability_Side_Effect_Free
        (State);
   end Assert_Build_Run_Availability_Side_Effect_Free;

   function Assert_Build_Run_Command_Palette_Boundary
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Command_Palette_Boundary (State);
   end Assert_Build_Run_Command_Palette_Boundary;

   function Assert_Build_Run_Keybinding_Boundary return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Keybinding_Boundary;
   end Assert_Build_Run_Keybinding_Boundary;

   function Assert_Build_Run_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Run_Persistence_Excluded (State);
   end Assert_Build_Run_Persistence_Excluded;

   function Assert_Build_Cancel_Command_Descriptor_Stable return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Cancel_Command_Descriptor_Stable;
   end Assert_Build_Cancel_Command_Descriptor_Stable;

   function Assert_Build_Cancel_Requires_Active_Job
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Build_Cancel_Requires_Active_Job (State);
   end Assert_Build_Cancel_Requires_Active_Job;

   function Assert_Public_Build_Command_Registration_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command_Audit.Assert_Public_Build_Command_Registration_Coherent
        (State);
   end Assert_Public_Build_Command_Registration_Coherent;


   function Async_Test_Request return Editor.External_Producers.Build_Types.Build_Run_Request is
   begin
      return
        (Tool => Editor.External_Producers.Build_Types.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Types.Build_Request_From_Test,
         Working_Label => To_Unbounded_String ("async-test-root"),
         Command_Label => To_Unbounded_String ("async test build"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Build_Requests.Empty_Process_Arguments);
   end Async_Test_Request;

   function Assert_Async_Build_Cancel_Handoff_Behavior return Boolean is
      S : Editor.State.State_Type;
      Worker_State : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Poll_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean;
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Types.Build_Consent_Test_Only);
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async cancellation behavior");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Build.Public_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Build.Public_Async_Slot_Id);
      Editor.Build_Process_Control.Publish_Active_Process
        (Editor.Build_Process_Control.Test_Cancellable_Handle);

      if not Has_Queued_Public_Build_Job (S) then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Result := Request_Public_Build_Cancel (S);
      if Result.Build_Result.Status /= Editor.External_Producers.Build_Types.Build_Run_Cancelled
        or else S.Build.Public_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else not Editor.Build_Process_Control.Active_Cancel_Requested
      then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Snapshot_While_Running (S.Build.Public_Async_Slot_Id, Worker_State);
      if Worker_State.Build.Public_Job_Cancellation /=
        Editor.Build_Runner_Policy.Cancellation_Requested
      then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Store_Worker_Result
        (S.Build.Public_Async_Slot_Id, Worker_State,
          (Build_Result => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
            (Editor.External_Producers.Build_Types.Build_Run_Cancelled,
             Output_Partial => True),
          Diagnostic_Result =>
            Editor.External_Producers.Diagnostic_Line_Parsing.
              Empty_Diagnostic_Line_Command_Result,
          Command_Message => To_Unbounded_String ("Build cancelled")));

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      return Completed
        and then Poll_Result.Build_Result.Status =
          Editor.External_Producers.Build_Types.Build_Run_Cancelled
        and then not S.Build.Public_Job_Active
        and then not S.Build.Public_Async_Job_Queued
        and then S.Build.Public_Job_Cancellation =
          Editor.Build_Runner_Policy.Cancellation_Acknowledged
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle);
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Cancel_Handoff_Behavior;

   function Assert_Async_Build_Output_Snapshot_Handoff_Behavior return Boolean is
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean;
      Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Types.Build_Consent_Test_Only);
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async output behavior");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Build.Public_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Build.Public_Async_Slot_Id);

      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (Stream, S.Build.Public_Job_Id);
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
          Editor.External_Producers.Build_Types.Build_Run_Succeeded
        or else not Result.Build_Result.Output_Partial
      then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      declare
         OK : constant Boolean :=
           S.Build.Public_Output_Stream.Active
           and then S.Build.Public_Output_Stream.Chunk_Count = 2
           and then S.Build.Latest_Output_Details.Output_Partial
           and then S.Build.Latest_Output_Details.Stdout_Available
           and then S.Build.Latest_Output_Details.Stderr_Available;
      begin
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Output_Snapshot_Handoff_Behavior;

   function Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion
     return Boolean
   is
      S : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean;
      Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Consent => Editor.External_Producers.Build_Types.Build_Consent_Test_Only);
      Stdout_Marker : constant String := "stdout-before-completion";
      Stderr_Marker : constant String := "stderr-before-completion";
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async partial output behavior");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Build.Public_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Build.Public_Async_Slot_Id);

      Editor.Build_Output_Details.Begin_Build_Output_Stream
        (Stream, S.Build.Public_Job_Id);
      Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
        (Stream,
         Editor.Build_Output_Details.Build_Output_Stream_Stdout,
         Stdout_Marker & Character'Val (10));
      Editor.Build_Process_Control.Publish_Active_Output_Stream (Stream);

      Completed := Poll_Public_Build_Run_Completion (S, Result);
      if Completed
        or else Result.Command_Message /= To_Unbounded_String ("Build still running.")
        or else not S.Build.Public_Output_Stream.Active
        or else S.Build.Public_Output_Stream.Chunk_Count /= 1
        or else not S.Build.Latest_Output_Details.Output_Partial
        or else not S.Build.Latest_Output_Details.Stdout_Available
        or else S.Build.Latest_Output_Details.Stderr_Available
        or else Ada.Strings.Fixed.Index
          (To_String (S.Build.Latest_Output_Details.Stdout_Excerpt),
           Stdout_Marker) = 0
        or else not S.Build.Public_Job_Active
        or else not S.Build.Public_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
           and then S.Build.Public_Output_Stream.Active
           and then S.Build.Public_Output_Stream.Chunk_Count = 2
           and then S.Build.Latest_Output_Details.Kind =
             Editor.Build_Output_Details.Build_Output_Details_Partial
           and then S.Build.Latest_Output_Details.Output_Partial
           and then S.Build.Latest_Output_Details.Stdout_Available
           and then S.Build.Latest_Output_Details.Stderr_Available
           and then Ada.Strings.Fixed.Index
             (To_String (S.Build.Latest_Output_Details.Stdout_Excerpt),
              Stdout_Marker) /= 0
           and then Ada.Strings.Fixed.Index
             (To_String (S.Build.Latest_Output_Details.Stderr_Excerpt),
              Stderr_Marker) /= 0
           and then S.Build.Public_Job_Active
           and then S.Build.Public_Async_Job_Queued
           and then not S.Build.Public_Async_Job_Result_Pending;
      begin
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion;

   function Assert_Async_Build_Real_Process_Cancel_Integration
     return Boolean
   is
      use type Editor.External_Producers.Build_Types.Process_Run_Status;
      use type Editor.Build_Process_Control.Build_Process_Cancel_Result;

      Sleep_Path : constant String := "/bin/sleep";
      S : Editor.State.State_Type;
      Poll_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Cancel_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean := False;
      Args : Editor.External_Producers.Build_Types.Process_Argument_Vector :=
        Editor.External_Producers.Build_Requests.Empty_Process_Arguments;
      Process_Request : Editor.External_Producers.Build_Types.Process_Run_Request;
      Process_Result : Editor.External_Producers.Build_Types.Process_Run_Result;
      Build_Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Policy : constant Editor.External_Producers.Build_Types.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Build_Types.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 4096,
         Require_Absolute_Program => True,
         Timeout_Milliseconds     => 10_000);
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Real_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False,
           Require_Absolute_Program => True,
           Max_Output_Bytes => 4096,
           Consent => Editor.External_Producers.Build_Types.Build_Consent_User_Confirmed);

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
           Editor.External_Producers.Build_Command_Execution.Execute_Process_Request_Gated_With_State
             (Worker_State,
              Process_Request,
              Policy,
              Editor.External_Producers.Build_Requests.Build_Process_Run_Result
                (Editor.External_Producers.Build_Types.Process_Run_Not_Available));
         Build_Result :=
           (Build_Result =>
              Editor.External_Producers.Build_Requests.Build_Result_From_Process_Result
                (Async_Test_Request, Process_Result),
            Diagnostic_Result =>
              Editor.External_Producers.Diagnostic_Line_Parsing.
                Empty_Diagnostic_Line_Command_Result,
            Command_Message =>
              To_Unbounded_String
                ((if Process_Result.Status =
                       Editor.External_Producers.Build_Types.Process_Run_Cancelled
                  then "Build cancelled"
                  else "Build finished")));
         Public_Build_Jobs.Store_Worker_Result (Worker_Slot, Worker_State, Build_Result);
      exception
         when others =>
            Public_Build_Jobs.Store_Worker_Result
              (Worker_Slot, Worker_State,
               (Build_Result => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
                  (Editor.External_Producers.Build_Types.Build_Run_Execution_Error),
                Diagnostic_Result =>
                  Editor.External_Producers.Diagnostic_Line_Parsing.
                    Empty_Diagnostic_Line_Command_Result,
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
            if Public_Build_Jobs.Result_Ready (S.Build.Public_Async_Slot_Id) then
               return True;
            end if;
            delay 0.05;
         end loop;
         return False;
      end Wait_For_Final_Result;
   begin
      if not Editor.External_Producers.Execution_Policy.Native_Process_Control_Is_POSIX
        or else not Ada.Directories.Exists (Sleep_Path)
      then
         --  POSIX-only integration: it spawns /bin/sleep and cancels it through
         --  the POSIX process-control backend. On Windows a stray MSYS/Git
         --  /bin/sleep makes the Exists check pass, and the test then drives a
         --  real-process cancel on a non-POSIX host where the local worker task
         --  never finishes -- and the function's scope exit blocks on it forever
         --  (this is the Windows CI hang). Gate on the backend being POSIX, not
         --  merely on the path existing, so the test skips cleanly off POSIX.
         --  release_check still guards that this integration assertion exists.
         return True;
      end if;

      Editor.State.Initialize (S);
      Editor.External_Producers.Build_Requests.Append_Process_Argument (Args, "5");
      Process_Request :=
        (Program_Label        => To_Unbounded_String (Sleep_Path),
         Working_Label        => To_Unbounded_String (Ada.Directories.Current_Directory),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Args);

      Begin_Public_Build_Job (S, "real-process async cancellation integration");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Build.Public_Job_Id);

      Worker.Start (S.Build.Public_Async_Slot_Id);

      if not Wait_For_Active_Process then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      if Completed
        or else Poll_Result.Command_Message /= To_Unbounded_String ("Build still running.")
        or else not S.Build.Public_Job_Active
        or else not S.Build.Public_Async_Job_Queued
      then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Cancel_Result := Request_Public_Build_Cancel (S);
      if Cancel_Result.Build_Result.Status /= Editor.External_Producers.Build_Types.Build_Run_Cancelled
        or else not Editor.Build_Process_Control.Active_Cancel_Requested
      then
         declare
            Ignored : constant Editor.Build_Process_Control.Build_Process_Cancel_Result :=
              Editor.Build_Process_Control.Request_Active_Cancel;
         begin
            null;
         end;
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Completed := Poll_Public_Build_Run_Completion (S, Poll_Result);
      return Completed
        and then Poll_Result.Build_Result.Status =
          Editor.External_Producers.Build_Types.Build_Run_Cancelled
        and then Process_Result.Status =
          Editor.External_Producers.Build_Types.Process_Run_Cancelled
        and then not S.Build.Public_Job_Active
        and then not S.Build.Public_Async_Job_Queued
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
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
   begin
      Editor.State.Initialize (S1);
      Editor.State.Initialize (S2);
      Begin_Public_Build_Job (S1, "async slot one");
      Begin_Public_Build_Job (S2, "async slot two");

      if S1.Build.Public_Async_Slot_Id = 0
        or else S2.Build.Public_Async_Slot_Id = 0
        or else S1.Build.Public_Async_Slot_Id = S2.Build.Public_Async_Slot_Id
      then
         return False;
      end if;

      S1.Build.Public_Async_Job_Queued := True;
      S2.Build.Public_Async_Job_Queued := True;
      Public_Build_Jobs.Store_Queued
        (S1.Build.Public_Async_Slot_Id, S1, Async_Test_Request, Gate, Gate, S1.Build.Public_Job_Id);
      Public_Build_Jobs.Store_Queued
        (S2.Build.Public_Async_Slot_Id, S2, Async_Test_Request, Gate, Gate, S2.Build.Public_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S1.Build.Public_Async_Slot_Id);
      Public_Build_Jobs.Mark_Worker_Running (S2.Build.Public_Async_Slot_Id);
      Public_Build_Jobs.Mark_Cancellation_Requested (S1.Build.Public_Async_Slot_Id);

      Public_Build_Jobs.Snapshot_While_Running (S1.Build.Public_Async_Slot_Id, Snap1);
      Public_Build_Jobs.Snapshot_While_Running (S2.Build.Public_Async_Slot_Id, Snap2);

      declare
         OK : constant Boolean :=
           Snap1.Build.Public_Job_Cancellation =
             Editor.Build_Runner_Policy.Cancellation_Requested
           and then Snap2.Build.Public_Job_Cancellation =
             Editor.Build_Runner_Policy.No_Cancellation_Requested
           and then Public_Build_Jobs.Has_Job
             (S1.Build.Public_Async_Slot_Id, S1.Build.Public_Job_Id)
           and then Public_Build_Jobs.Has_Job
             (S2.Build.Public_Async_Slot_Id, S2.Build.Public_Job_Id);
      begin
         Public_Build_Jobs.Clear (S1.Build.Public_Async_Slot_Id);
         Public_Build_Jobs.Clear (S2.Build.Public_Async_Slot_Id);
         return OK;
      end;
   exception
      when others =>
         Public_Build_Jobs.Clear (S1.Build.Public_Async_Slot_Id);
         Public_Build_Jobs.Clear (S2.Build.Public_Async_Slot_Id);
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
      First_Slot := S.Build.Public_Async_Slot_Id;
      First_Job := S.Build.Public_Job_Id;
      Complete_Public_Build_Job (S);

      if First_Slot = 0
        or else S.Build.Public_Async_Slot_Id /= First_Slot
        or else S.Build.Public_Job_Active
      then
         return False;
      end if;

      Begin_Public_Build_Job (S, "async slot stable second build");
      Second_Slot := S.Build.Public_Async_Slot_Id;
      Second_Job := S.Build.Public_Job_Id;
      Complete_Public_Build_Job (S);

      return Second_Slot = First_Slot
        and then Second_Job = First_Job + 1
        and then S.Build.Public_Async_Slot_Id = First_Slot
        and then not S.Build.Public_Job_Active
        and then not S.Build.Public_Async_Job_Queued
        and then not S.Build.Public_Async_Job_Result_Pending;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);

      procedure Queue_Test_Job (S : in out Editor.State.State_Type; Label : String) is
      begin
         Editor.State.Initialize (S);
         Begin_Public_Build_Job (S, Label);
         Public_Build_Jobs.Store_Queued
           (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate,
            S.Build.Public_Job_Id);
      end Queue_Test_Job;

      procedure Clear_Test_Job (S : in out Editor.State.State_Type) is
      begin
         if S.Build.Public_Async_Slot_Id /= 0 then
            Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
           not Public_Build_Jobs.Slot_Available_For (S9.Build.Public_Async_Slot_Id);
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
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
      Request : constant Editor.External_Producers.Build_Types.Build_Run_Request :=
        Async_Test_Request;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Worker_State : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "lifecycle shutdown behavior");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Request, Gate, Gate, S.Build.Public_Job_Id);
      Public_Build_Jobs.Mark_Worker_Running (S.Build.Public_Async_Slot_Id);

      Result := Request_Public_Build_Lifecycle_Shutdown (S, "closing project");
      Public_Build_Jobs.Snapshot_While_Running (S.Build.Public_Async_Slot_Id, Worker_State);

      if Result.Build_Result.Status /= Editor.External_Producers.Build_Types.Build_Run_Cancelled
        or else S.Build.Public_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else Worker_State.Build.Public_Job_Cancellation /=
          Editor.Build_Runner_Policy.Cancellation_Requested
        or else not S.Build.Public_Job_Active
        or else not S.Build.Public_Async_Job_Queued
      then
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
      end if;

      Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
      Complete_Public_Build_Job (S);
      return True;
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
         Editor.Build_Process_Control.Clear_Active_Process;
         return False;
   end Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior;


   function Assert_Async_Build_Worker_Shutdown_Drain_Behavior
     return Boolean
   is
      S : Editor.State.State_Type;
      Gate : constant Editor.External_Producers.Build_Types.Build_Execution_Gate :=
        Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
          (Allow_Diagnostics_Ingestion => False,
           Show_Diagnostics => False);
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean := False;
   begin
      Editor.State.Initialize (S);
      Begin_Public_Build_Job (S, "async worker shutdown drain behavior");
      S.Build.Public_Async_Job_Queued := True;
      S.Build.Public_Async_Job_Result_Pending := False;
      Public_Build_Jobs.Store_Queued
        (S.Build.Public_Async_Slot_Id, S, Async_Test_Request, Gate, Gate, S.Build.Public_Job_Id);

      --  A disabled-gate worker finishes quickly, but the drain path is still
      --  the same deterministic shutdown handshake used by application exit.
      Public_Build_Workers (Slot_Index_For (S.Build.Public_Async_Slot_Id)).Start
        (S.Build.Public_Async_Slot_Id);
      Result := Drain_Public_Build_Worker_For_Shutdown (S, "application shutdown");

      if S.Build.Public_Async_Job_Queued then
         Completed := Poll_Public_Build_Run_Completion (S, Result);
      else
         Completed := True;
      end if;

      return Completed
        and then not S.Build.Public_Job_Active
        and then not S.Build.Public_Async_Job_Queued
        and then not Editor.Build_Process_Control.Is_Active
          (Editor.Build_Process_Control.Active_Process_Handle);
   exception
      when others =>
         Public_Build_Jobs.Clear (S.Build.Public_Async_Slot_Id);
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
