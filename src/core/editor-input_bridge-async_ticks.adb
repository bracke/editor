with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Command;
with Editor.External_Producers.Build_Requests;
with Editor.Messages;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Async_Ticks is

   procedure Tick_Async_Build_Jobs
     (Instance    : in out Editor.Instance.Editor_Instance;
      Initialized : Boolean;
      Report_Info : Message_Reporter)
   is
      Result    : Editor.External_Producers.Build_Requests.Build_Command_Result;
      Completed : Boolean := False;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before ticking async build jobs");

      if Editor.Build_Command.Has_Queued_Public_Build_Job (Instance.State) then
         Completed := Editor.Build_Command.Poll_Public_Build_Run_Completion
           (Instance.State, Result);

         if Completed then
            Report_Info (To_String (Result.Command_Message));
         end if;

         --  Even a non-completing poll can import stdout/stderr stream snapshots
         --  from the worker-owned process handoff.  Invalidate unconditionally
         --  while a public build job is queued so idle frames can show partial
         --  output without waiting for another user command.
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Tick_Async_Build_Jobs;

   procedure Tick_Messages
     (Instance    : in out Editor.Instance.Editor_Instance;
      Initialized : Boolean)
   is
      Had_Messages : Boolean := False;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before ticking messages");

      Had_Messages := not Editor.Messages.Is_Empty (Instance.State.Messages);
      Editor.Messages.Tick
        (Instance.State.Messages,
         (if Editor.View.Current_Time_Seconds <= 0.0 then 0
          elsif Editor.View.Current_Time_Seconds >= Duration (Natural'Last / 1000) then Natural'Last
          else Natural (Float (Editor.View.Current_Time_Seconds) * 1000.0)));
      if Had_Messages then
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Tick_Messages;

end Editor.Input_Bridge.Async_Ticks;
