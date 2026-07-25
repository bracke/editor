with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Service;
with Editor.Build_Command.Projections;
with Editor.Build_Command.Readiness;
with Editor.Build_Diagnostics;
with Editor.Build_Output_Details;
with Editor.Build_Public_Request;
with Editor.Build_Result_Summary;
with Editor.Build_Runner_Policy;
with Editor.Build_Process_Control;
with Editor.Build_Command.Registry;
with Editor.External_Producers;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Build_Requests;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.State;

package body Editor.Build_Command.Execution is

   Public_Build_Run_Diagnostics_Ingestion_Policy : constant
     Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_Policy :=
       Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request;

   use Editor.Build_Command.Registry;
   use Editor.Build_Command.Projections;
   use Editor.Build_Command.Readiness;

   use type Editor.Build_Runner_Policy.Build_Execution_Policy;
   use type Editor.Build_Process_Control.Build_Process_Cancel_Result;

   function Start_Public_Build_Run_Asynchronously
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
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
              (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
                 (Editor.External_Producers.Build_Run_Not_Available),
               Diagnostic_Result => Empty_Diagnostics,
               Command_Message   => To_Unbounded_String (Message));
         end;
      elsif Public_Build_Worker_Lifecycle.Stop_Requested then
         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String
              ("Build unavailable: async build worker pool is stopping."));
      elsif State.Public_Build_Job_Active then
         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
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
              (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
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
         Public_Build_Workers (Slot_Index_For (State.Public_Build_Async_Slot_Id)).Start
           (State.Public_Build_Async_Slot_Id);

         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Build_Output_Details_From_Stream
             (State.Public_Build_Output_Stream,
              Editor.Build_Output_Details.Build_Output_Runner_Succeeded,
              Output_Partial => True);

         return
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Succeeded,
               Output_Partial => True),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("Build started."));
      end;
   end Start_Public_Build_Run_Asynchronously;

   function Poll_Public_Build_Run_Completion
     (State : in out Editor.State.State_Type;
      Result : out Editor.External_Producers.Build_Requests.Build_Command_Result) return Boolean
   is
      Empty_Diagnostics : constant Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
      Ingestion : Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.
          Empty_Diagnostic_Line_Command_Result;
      Worker_State : Editor.State.State_Type;
      Active_Stream : Editor.Build_Output_Details.Build_Output_Stream_State;
      Active_Stream_Available : Boolean := False;
      Completed_Request : Editor.External_Producers.Build_Run_Request;
      Result_Gate : Editor.External_Producers.Build_Execution_Gate;
      Duration_MS : Natural := 0;
   begin
      if not Has_Queued_Public_Build_Job (State) then
         Result :=
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
              (Editor.External_Producers.Build_Run_Not_Available),
            Diagnostic_Result => Empty_Diagnostics,
            Command_Message   => To_Unbounded_String ("No queued build job."));
         return False;
      end if;

      if not Public_Build_Jobs.Result_Ready (State.Public_Build_Async_Slot_Id) then
         Public_Build_Jobs.Snapshot_While_Running
           (State.Public_Build_Async_Slot_Id, Worker_State);
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
           (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
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
      Duration_MS := Public_Build_Duration_Milliseconds (State);

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

      Result.Diagnostic_Result :=
        Ingestion;
      Feed_Language_Service_Compiler_Backend
        (State, Completed_Request, Result.Build_Result);
      Result.Command_Message := To_Unbounded_String
        (Editor.External_Producers.Build_Requests.Build_Gated_Build_Command_Feedback
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
              Result_Gate.Allow_Diagnostics_Ingestion,
              Duration_MS,
              True));
      State.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
          (State.Latest_Build_Output_Details,
           Output_Details_From_Result (Result.Build_Result));

      Public_Build_Jobs.Clear (State.Public_Build_Async_Slot_Id);
      return True;
   end Poll_Public_Build_Run_Completion;

   function Execute_Public_Build_Run
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Readiness : constant Build_Run_Readiness_Status :=
        Validate_Build_Run_Invocation (State);
   begin
      if Readiness /= Build_Run_Readiness_Ready then
         declare
            Message : constant String := Build_Run_Unavailable_Reason (Readiness);
         begin
            Result :=
              (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
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
         Ingestion : Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result :=
           Editor.External_Producers.Diagnostic_Line_Parsing.
             Empty_Diagnostic_Line_Command_Result;
         Duration_MS : Natural := 0;
      begin
         Begin_Public_Build_Job (State, To_String (Conversion.Request.Command_Label));
         Result := Editor.External_Producers.Build_Requests.Run_Build_Command_With_Gate
           (State,
            Conversion.Request,
            Runner_Only_Gate);
         Duration_MS := Public_Build_Duration_Milliseconds (State);
         Complete_Public_Build_Job (State);

         Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
           (State,
            Conversion.Request,
            Result.Build_Result,
            Public_Build_Run_Diagnostics_Ingestion_Policy,
            State.Build_UI.Show_Diagnostics_On_Result);

         Result.Diagnostic_Result :=
           Ingestion;
         Feed_Language_Service_Compiler_Backend
           (State, Conversion.Request, Result.Build_Result);
         Result.Command_Message := To_Unbounded_String
           (Editor.External_Producers.Build_Requests.Build_Gated_Build_Command_Feedback
              (Result.Build_Result,
               Ingestion,
               Gate.Allow_Diagnostics_Ingestion,
               Gate.Allow_Diagnostics_Ingestion));

         State.Latest_Build_Result :=
           Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
             (State.Latest_Build_Result,
              Summary_From_Result
                (Conversion.Request, Result, Gate.Allow_Diagnostics_Ingestion,
                 Duration_MS, True));
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
      return Editor.External_Producers.Build_Requests.Build_Command_Result
   is
      Conversion : constant Editor.Build_Public_Request.Public_Build_Request_Conversion_Result :=
        Editor.Build_Public_Request.Build_Public_Request_From_UI_State (State.Build_UI);
      Empty_Diagnostics : constant Editor.External_Producers.Build_Requests.Diagnostic_Line_Command_Result :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Empty_Diagnostic_Line_Command_Result;
      Result : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Readiness : constant Build_Run_Readiness_Status :=
        Validate_Build_Run_Invocation (State);
   begin
      if Readiness /= Build_Run_Readiness_Ready then
         declare
            Message : constant String := Build_Run_Unavailable_Reason (Readiness);
         begin
            Result :=
              (Build_Result      => Editor.External_Producers.Build_Requests.Build_Build_Run_Result
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
           Editor.External_Producers.Execution_Policy.Build_Test_Fixture_Execution_Gate
             (Allow_Diagnostics_Ingestion => False,
              Show_Diagnostics            => False,
              Max_Output_Bytes            => Gate.Process_Policy.Max_Output_Bytes,
              Consent                     =>
                Editor.External_Producers.Build_Consent_Test_Only);
         Ingestion : Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result :=
           Editor.External_Producers.Diagnostic_Line_Parsing.
             Empty_Diagnostic_Line_Command_Result;
         Duration_MS : Natural := 0;
      begin
         Begin_Public_Build_Job (State, To_String (Conversion.Request.Command_Label));
         Result := Editor.External_Producers.Build_Requests.Run_Build_Command_With_Gate
           (State,
            Conversion.Request,
            Runner_Only_Gate,
            Supplied_Result);
         Duration_MS := Public_Build_Duration_Milliseconds (State);
         Complete_Public_Build_Job (State);

         Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
           (State,
            Conversion.Request,
            Result.Build_Result,
            Public_Build_Run_Diagnostics_Ingestion_Policy,
            State.Build_UI.Show_Diagnostics_On_Result);

         Result.Diagnostic_Result :=
           Ingestion;
         Feed_Language_Service_Compiler_Backend
           (State, Conversion.Request, Result.Build_Result);
         Result.Command_Message := To_Unbounded_String
           (Editor.External_Producers.Build_Requests.Build_Gated_Build_Command_Feedback
              (Result.Build_Result,
               Ingestion,
               Gate.Allow_Diagnostics_Ingestion,
               Gate.Allow_Diagnostics_Ingestion));

         State.Latest_Build_Result :=
           Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
             (State.Latest_Build_Result,
              Summary_From_Result
                (Conversion.Request, Result, Gate.Allow_Diagnostics_Ingestion,
                 Duration_MS, True));
         State.Latest_Build_Output_Details :=
           Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
             (State.Latest_Build_Output_Details,
              Output_Details_From_Result (Result.Build_Result));
         return Result;
      end;
   end Execute_Public_Build_Run_With_Supplied_Result;

end Editor.Build_Command.Execution;
