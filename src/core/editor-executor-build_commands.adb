with Ada.Strings.Unbounded;

with Editor.Build_Candidate_Refresh;
with Editor.Build_Command;
with Editor.Build_Output_Details;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_Working_Context;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.External_Producers;
with Editor.Project;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Build_Commands is

   use Ada.Strings.Unbounded;
   use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
   use type Editor.Build_UI.Public_Build_Tool_Selection;
   use type Editor.External_Producers.Build_Run_Status;

   function Build_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Hide
            | Editor.Commands.Command_Build_UI_Focus
            | Editor.Commands.Command_Build_Set_Mode_Default
            | Editor.Commands.Command_Build_Set_Mode_Debug
            | Editor.Commands.Command_Build_Set_Mode_Release
            | Editor.Commands.Command_Build_Set_Mode_Validation
            | Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion
            | Editor.Commands.Command_Build_Cycle_Output_Limit
            | Editor.Commands.Command_Build_Clear_Consent =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Refresh_Candidates =>
            if not Editor.Project.Has_Project (S.Project) then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Result_Focus =>
            if not S.Latest_Build_Result.Has_Result then
               return Editor.Commands.Unavailable ("No build result");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Output_Details_Focus
            | Editor.Commands.Command_Build_Output_Details_Select_Stdout
            | Editor.Commands.Command_Build_Output_Details_Select_Stderr
            | Editor.Commands.Command_Build_Output_Details_Select_Merged =>
            if not S.Latest_Build_Output_Details.Has_Output_Details then
               return Editor.Commands.Unavailable ("No build output details");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Select_First_Candidate
            | Editor.Commands.Command_Build_Select_Next_Candidate
            | Editor.Commands.Command_Build_Select_Previous_Candidate =>
            if Natural (S.Build_UI.Build_Candidates.Length) = 0 then
               return Editor.Commands.Unavailable ("No build candidates");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Clear_Selected_Candidate =>
            if To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length = 0 then
               return Editor.Commands.Unavailable
                 ("No build candidate selected");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Toggle_Option_Verbose
            | Editor.Commands.Command_Build_Toggle_Option_Keep_Going =>
            if S.Build_UI.Selected_Build_Tool /=
              Editor.Build_UI.Build_UI_GPRbuild
              or else not S.Build_UI.Candidate_Applied_To_Request
            then
               return Editor.Commands.Unavailable
                 ("Build option not supported for selected candidate");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Acknowledge_Consent =>
            declare
               Copy : Editor.Build_UI.Public_Build_UI_State := S.Build_UI;
            begin
               Editor.Build_UI.Acknowledge_Consent (Copy);
               if not Copy.Consent_Acknowledged then
                  return Editor.Commands.Unavailable
                    (Editor.Build_UI.Validation_Message
                       (Editor.Build_UI.Validate_Build_UI_State (S.Build_UI)));
               end if;
            end;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Build_Run =>
            return Editor.Build_Command.Build_Run_Availability (S);

         when Editor.Commands.Command_Build_Cancel =>
            return Editor.Build_Command.Build_Cancel_Availability (S);

         when Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam =>
            return Editor.Commands.Unavailable
              ("Build: structured command context required");

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a build command");
      end case;
   end Build_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Execute_Build_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Build_Refresh_Candidates =>
            declare
               Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
                 Editor.Build_Working_Context.Current_Project_Root
                   (Editor.Project.Root_Path (S.Project));
               Refresh_Result : constant Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result :=
                 Editor.Build_UI_Actions.Build_UI_Refresh_Candidates (S, Context);
               Count_Text : constant String :=
                 Natural'Image (Refresh_Result.Candidate_Count);
            begin
               if Refresh_Result.Status =
                 Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded
               then
                  Report_Info
                    (S, "Build candidates refreshed:" & Count_Text);
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               else
                  Report_Info (S, To_String (Refresh_Result.Message));
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;
            end;

         when Editor.Commands.Command_Build_Select_First_Candidate =>
            Editor.Build_UI_Actions.Build_UI_Select_First_Candidate (S);
            Report_Info (S, "Build candidate selection changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Select_Next_Candidate =>
            Editor.Build_UI_Actions.Build_UI_Select_Next_Candidate (S);
            Report_Info (S, "Build candidate selection changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Select_Previous_Candidate =>
            Editor.Build_UI_Actions.Build_UI_Select_Previous_Candidate (S);
            Report_Info (S, "Build candidate selection changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Clear_Selected_Candidate =>
            Editor.Build_UI_Actions.Build_UI_Clear_Selected_Candidate (S);
            Report_Info (S, "Build candidate selection cleared");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Set_Mode_Default =>
            Editor.Build_UI_Actions.Build_UI_Set_Mode_Default (S);
            Report_Info (S, "Build mode set to default; consent required if request changed");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Set_Mode_Debug =>
            Editor.Build_UI_Actions.Build_UI_Set_Mode_Debug (S);
            Report_Info (S, "Build mode set to debug; consent required if request changed");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Set_Mode_Release =>
            Editor.Build_UI_Actions.Build_UI_Set_Mode_Release (S);
            Report_Info (S, "Build mode set to release; consent required if request changed");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Set_Mode_Validation =>
            Editor.Build_UI_Actions.Build_UI_Set_Mode_Validation (S);
            Report_Info (S, "Build mode set to validation; consent required if request changed");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion =>
            Editor.Build_UI_Actions.Build_UI_Toggle_Diagnostics_Ingestion (S);
            Report_Info (S, "Build diagnostics ingestion option changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Cycle_Output_Limit =>
            Editor.Build_UI_Actions.Build_UI_Cycle_Output_Limit (S);
            Report_Info (S, "Build output capture limit changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Toggle_Option_Verbose =>
            Editor.Build_UI_Actions.Build_UI_Toggle_Verbose_Output (S);
            Report_Info (S, "Build verbose option changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Toggle_Option_Keep_Going =>
            Editor.Build_UI_Actions.Build_UI_Toggle_Keep_Going (S);
            Report_Info (S, "Build keep-going option changed; consent required");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Acknowledge_Consent =>
            Editor.Build_UI_Actions.Build_UI_Acknowledge_Consent (S);
            if S.Build_UI.Consent_Acknowledged then
               Report_Info (S, "Build request consent acknowledged");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Executed (Id);
            else
               Report_Info (S, "Build request is not ready for consent");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;

         when Editor.Commands.Command_Build_Clear_Consent =>
            Editor.Build_UI_Actions.Build_UI_Clear_Consent (S);
            Report_Info (S, "Build request consent cleared");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Run =>
            declare
               Result : constant Editor.External_Producers.Build_Command_Result :=
                 Editor.Build_Command.Start_Public_Build_Run_Asynchronously (S);
            begin
               Report_Info (S, To_String (Result.Command_Message));
               Editor.Render_Cache.Invalidate_All;
               if Result.Build_Result.Status =
                 Editor.External_Producers.Build_Run_Succeeded
               then
                  return Editor.Command_Execution.Executed (Id);
               elsif Result.Build_Result.Status =
                 Editor.External_Producers.Build_Run_Not_Available
               then
                  return Editor.Command_Execution.Unavailable (Id);
               else
                  return Editor.Command_Execution.Failed (Id);
               end if;
            end;

         when Editor.Commands.Command_Build_Cancel =>
            declare
               Result : constant Editor.External_Producers.Build_Command_Result :=
                 Editor.Build_Command.Request_Public_Build_Cancel (S);
            begin
               Report_Info (S, To_String (Result.Command_Message));
               Editor.Render_Cache.Invalidate_All;
               if Result.Build_Result.Status =
                 Editor.External_Producers.Build_Run_Cancelled
               then
                  return Editor.Command_Execution.Executed (Id);
               else
                  return Editor.Command_Execution.Unavailable (Id);
               end if;
            end;

         when Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam =>
            --  The bare internal test seam route intentionally has no
            --  structured payload channel. Tests/internal callers must use
            --  Execute_User_Opt_In_Build_Command on the parent executor.
            return Editor.Command_Execution.Unavailable (Id);

         when Editor.Commands.Command_Build_Output_Details_Select_Stdout =>
            Editor.Build_Output_Details.Select_Output_Stream
              (S.Latest_Build_Output_Details,
               Editor.Build_Output_Details.Build_Output_Stream_Stdout);
            Report_Info (S, "Build output stream set to stdout.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Output_Details_Select_Stderr =>
            Editor.Build_Output_Details.Select_Output_Stream
              (S.Latest_Build_Output_Details,
               Editor.Build_Output_Details.Build_Output_Stream_Stderr);
            Report_Info (S, "Build output stream set to stderr.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when Editor.Commands.Command_Build_Output_Details_Select_Merged =>
            Editor.Build_Output_Details.Select_Output_Stream
              (S.Latest_Build_Output_Details,
               Editor.Build_Output_Details.Build_Output_Stream_Merged);
            Report_Info (S, "Build output stream set to merged.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Executed (Id);

         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Build_Command;

end Editor.Executor.Build_Commands;
