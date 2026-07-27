with Ada.Strings.Unbounded;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.Build_Result_Summary;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.Terminal_Tasks;

package Editor.State_Build is

   type Build_Runtime_State is record
      --  Transient public build UX input/consent state. This is not
      --  workspace, settings, recent-project, keybinding, Diagnostics, or
      --  persistence state.
      Build_UI : Editor.Build_UI.Public_Build_UI_State;

      --  Transient integrated terminal/task state. It owns visible task rows,
      --  selected task, bounded output, and rerun metadata only; it is not
      --  persisted into workspace/settings files.
      Terminal_Tasks : Editor.Terminal_Tasks.Terminal_Task_State;

      --  Transient latest build.run result summary. It is a snapshot
      --  projection only: no history, rerun payload, process handle,
      --  cancellation token, Diagnostics rows, or persistence state.
      Latest_Result : Editor.Build_Result_Summary.Latest_Build_Result_Summary;

      --  Transient focus marker for the latest build result summary surface.
      --  The summary data remains display-only and this flag is never
      --  persisted.
      Latest_Result_Focused : Boolean := False;

      --  Transient latest build.run bounded output details. It is a snapshot
      --  projection over bounded stdout/stderr captures and active stream
      --  excerpts: no history, terminal emulation, rerun payload, process
      --  handle, Diagnostics rows, or persistence state.
      Latest_Output_Details :
        Editor.Build_Output_Details.Latest_Build_Output_Details;

      --  Transient runtime execution policy for public build.run. It is
      --  deliberately outside workspace/settings/recent/keybinding persistence
      --  and is not supplied by palette/keybinding/UI payloads.
      Public_Execution_Policy :
        Editor.Build_Runner_Policy.Build_Execution_Policy :=
          Editor.Build_Runner_Policy.Build_Execution_Disabled;

      --  Transient active build job model for build.cancel. It records only
      --  the current live process-control handle and cancellation state while
      --  the build is active; it is never persisted, never exposed through
      --  keybinding payloads, and never stores rerun argv or full output logs.
      Public_Job_Active : Boolean := False;
      Public_Job_Id : Natural := 0;
      Public_Job_Started_At : Duration := 0.0;
      Public_Job_Has_Start_Time : Boolean := False;
      Public_Job_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Public_Job_Cancellation :
        Editor.Build_Runner_Policy.Build_Cancellation_State :=
          Editor.Build_Runner_Policy.No_Cancellation_Requested;
      Public_Process_Handle :
        Editor.Build_Process_Control.Build_Process_Handle :=
          Editor.Build_Process_Control.No_Process_Handle;

      --  Transient asynchronous public build job markers. State_Type owns
      --  the observable job lifecycle, stable async slot id, and cancellation
      --  state. The build command runner transfers copied request/gate/result
      --  payloads through a bounded protected build-job service keyed by
      --  Public_Async_Slot_Id and Public_Job_Id; it must not keep one unnamed
      --  package-level job payload or worker singleton.
      Public_Async_Slot_Id : Natural := 0;
      Public_Async_Job_Queued : Boolean := False;
      Public_Async_Job_Result_Pending : Boolean := False;

      --  Transient incremental build output stream for the active public build
      --  job. It stores bounded display excerpts only; no process handle,
      --  rerun payload, full terminal log, or persistence state is stored here.
      Public_Output_Stream :
        Editor.Build_Output_Details.Build_Output_Stream_State;
   end record;

end Editor.State_Build;
