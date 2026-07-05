with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.External_Producers;
with Editor.Project;
with Editor.Render_Cache;
with Editor.State;
with Editor.Terminal_Tasks;

package body Editor.Executor.Terminal_Commands is

   use type Editor.Commands.Command_Id;
   use type Editor.External_Producers.Process_Run_Status;

   function Terminal_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Run_Project
            | Editor.Commands.Command_Run_Tests =>
            if not Editor.Project.Has_Project (S.Project) then
               return Editor.Commands.Unavailable ("No project is open.");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Terminal_Toggle
            | Editor.Commands.Command_Terminal_Show
            | Editor.Commands.Command_Terminal_Hide
            | Editor.Commands.Command_Terminal_Focus
            | Editor.Commands.Command_Terminal_Clear
            | Editor.Commands.Command_Terminal_Clear_Output =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Terminal_Select_Next_Task
            | Editor.Commands.Command_Terminal_Select_Previous_Task
            | Editor.Commands.Command_Terminal_Run_Selected_Task =>
            if not Editor.Terminal_Tasks.Has_Selected_Task
              (S.Terminal_Tasks)
            then
               return Editor.Commands.Unavailable
                 ("No terminal task selected");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Terminal_Rerun_Last_Task =>
            if not Editor.Terminal_Tasks.Can_Rerun_Last (S.Terminal_Tasks) then
               return Editor.Commands.Unavailable ("No terminal task has run");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Terminal_Cancel_Task =>
            return Editor.Commands.Unavailable
              ("No cancellable terminal task is running");

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a terminal command");
      end case;
   end Terminal_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   procedure Ensure_Terminal_Project_Tasks
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project.Has_Project (S.Project) then
         Editor.Terminal_Tasks.Ensure_Project_Default_Tasks
           (S.Terminal_Tasks, Editor.Project.Root_Path (S.Project));
      end if;
   end Ensure_Terminal_Project_Tasks;

   function Terminal_Process_Status_Message
     (Status : Editor.External_Producers.Process_Run_Status) return String
   is
   begin
      case Status is
         when Editor.External_Producers.Process_Run_Succeeded =>
            return "Terminal task succeeded.";
         when Editor.External_Producers.Process_Run_Failed
            | Editor.External_Producers.Process_Run_Execution_Error
            | Editor.External_Producers.Process_Run_Output_Truncated =>
            return "Terminal task failed.";
         when Editor.External_Producers.Process_Run_Not_Available =>
            return "Terminal task is not available.";
         when Editor.External_Producers.Process_Run_Rejected =>
            return "Terminal task rejected.";
         when Editor.External_Producers.Process_Run_Timed_Out =>
            return "Terminal task timed out.";
         when Editor.External_Producers.Process_Run_Cancelled =>
            return "Terminal task cancelled.";
         when Editor.External_Producers.Process_Run_Cancellation_Unsupported =>
            return "Terminal task cancellation is not supported.";
      end case;
   end Terminal_Process_Status_Message;

   function Terminal_Process_Policy
      return Editor.External_Producers.Process_Execution_Policy
   is
   begin
      return
        (Mode                     =>
           Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 600_000);
   end Terminal_Process_Policy;

   function Result_For_Process_Status
     (Id     : Editor.Commands.Command_Id;
      Status : Editor.External_Producers.Process_Run_Status)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      if Status = Editor.External_Producers.Process_Run_Succeeded then
         return Editor.Command_Execution.Executed (Id);
      elsif Status = Editor.External_Producers.Process_Run_Not_Available then
         return Editor.Command_Execution.Unavailable (Id);
      else
         return Editor.Command_Execution.Failed (Id);
      end if;
   end Result_For_Process_Status;

   function Execute_Project_Task_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Profile : constant Editor.Terminal_Tasks.Terminal_Task_Profile :=
        (if Id = Editor.Commands.Command_Run_Project
         then Editor.Terminal_Tasks.Task_Profile_Run
         else Editor.Terminal_Tasks.Task_Profile_Test);
      Selected : Boolean := False;
      Result   : Editor.External_Producers.Process_Run_Result;
   begin
      Ensure_Terminal_Project_Tasks (S);
      Selected :=
        Editor.Terminal_Tasks.Select_First_Profile
          (S.Terminal_Tasks, Profile);
      if not Selected then
         Report_Info (S, "Project task unavailable.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.Unavailable (Id);
      end if;

      Editor.Terminal_Tasks.Show (S.Terminal_Tasks);
      Result :=
        Editor.External_Producers.Execute_Process_Request_Real_Gated
          (Editor.Terminal_Tasks.Selected_Task_Request (S.Terminal_Tasks),
           Terminal_Process_Policy);
      Editor.Terminal_Tasks.Run_Selected_With_Result
        (S.Terminal_Tasks, Result);
      Report_Info (S, Terminal_Process_Status_Message (Result.Status));
      Editor.Render_Cache.Invalidate_All;
      return Result_For_Process_Status (Id, Result.Status);
   end Execute_Project_Task_Command;

   function Execute_Terminal_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Terminal_Toggle =>
            Editor.Terminal_Tasks.Toggle (S.Terminal_Tasks);
            Report_Info (S, "Terminal toggled.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Show =>
            Editor.Terminal_Tasks.Show (S.Terminal_Tasks);
            Report_Info (S, "Terminal shown.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Hide =>
            Editor.Terminal_Tasks.Hide (S.Terminal_Tasks);
            Report_Info (S, "Terminal hidden.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Focus =>
            Editor.Terminal_Tasks.Focus (S.Terminal_Tasks);
            Report_Info (S, "Terminal focused.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Clear =>
            Editor.Terminal_Tasks.Clear (S.Terminal_Tasks);
            Report_Info (S, "Terminal tasks cleared.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Clear_Output =>
            Editor.Terminal_Tasks.Clear_Output (S.Terminal_Tasks);
            Report_Info (S, "Terminal output cleared.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Select_Next_Task =>
            Editor.Terminal_Tasks.Select_Next (S.Terminal_Tasks);
            Report_Info (S, "Terminal task selection changed.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Select_Previous_Task =>
            Editor.Terminal_Tasks.Select_Previous (S.Terminal_Tasks);
            Report_Info (S, "Terminal task selection changed.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Terminal_Run_Selected_Task =>
            declare
               Result : constant Editor.External_Producers.Process_Run_Result :=
                 Editor.External_Producers.Execute_Process_Request_Real_Gated
                   (Editor.Terminal_Tasks.Selected_Task_Request
                      (S.Terminal_Tasks),
                    Terminal_Process_Policy);
            begin
               Editor.Terminal_Tasks.Run_Selected_With_Result
                 (S.Terminal_Tasks, Result);
               Report_Info (S, Terminal_Process_Status_Message (Result.Status));
               Editor.Render_Cache.Invalidate_All;
               return Result_For_Process_Status (Id, Result.Status);
            end;

         when Editor.Commands.Command_Terminal_Rerun_Last_Task =>
            declare
               Result : constant Editor.External_Producers.Process_Run_Result :=
                 Editor.External_Producers.Execute_Process_Request_Real_Gated
                   (Editor.Terminal_Tasks.Last_Task_Request
                      (S.Terminal_Tasks),
                    Terminal_Process_Policy);
            begin
               Editor.Terminal_Tasks.Rerun_Last_With_Result
                 (S.Terminal_Tasks, Result);
               Report_Info (S, Terminal_Process_Status_Message (Result.Status));
               Editor.Render_Cache.Invalidate_All;
               return Result_For_Process_Status (Id, Result.Status);
            end;

         when Editor.Commands.Command_Terminal_Cancel_Task =>
            Report_Info (S, "No cancellable terminal task is running.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Unavailable (Id);

         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Terminal_Command;

end Editor.Executor.Terminal_Commands;
