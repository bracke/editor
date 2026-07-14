with Editor.Command_Execution;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Focus_Management;
with Editor.Messages;
with Editor.Panel_Focus;
with Editor.Render_Cache;

package body Editor.Executor.Feature_Panel_Commands is

   use Editor.Commands;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Search_Results.External_Result_Set_Kind;
   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Feature_Panel_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Feature_Panel =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Show_Feature_Panel =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Already_Shown);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Hide_Feature_Panel =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Hidden);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Focus_Feature_Panel =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Hidden);
            elsif Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Already_Focused);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Clear_Feature_Panel =>
            if not Editor.Feature_Panel.Feature_Can_Clear
              (Editor.Feature_Panel.Active_Feature (S.Feature_Panel))
            then
               return Editor.Commands.Unavailable
                 ("Feature panel: no active feature");
            elsif not Editor.Feature_Panel.Has_Selectable_Row (S.Feature_Panel)
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_No_Feature_Panel_Rows);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Feature_Panel_Select_Next
            | Editor.Commands.Command_Feature_Panel_Select_Previous =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Hidden);
            elsif not Editor.Feature_Panel.Has_Selectable_Row (S.Feature_Panel)
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_No_Feature_Panel_Rows);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Feature_Panel_Open_Selected =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_Feature_Panel_Hidden);
            elsif not Editor.Feature_Panel.Is_Known_Feature
              (Editor.Feature_Panel.Active_Feature (S.Feature_Panel))
            then
               return Editor.Commands.Unavailable
                 ("Feature panel: no active feature");
            elsif not Editor.Feature_Panel.Has_Selection (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Reason_No_Feature_Panel_Row_Selected);
            elsif not Editor.Feature_Panel.Row_Can_Open
              (S.Feature_Panel,
               Positive (Editor.Feature_Panel.Selected_Row (S.Feature_Panel)))
              and then Editor.Feature_Panel.Active_Feature (S.Feature_Panel) /=
                Editor.Feature_Panel.Diagnostics_Feature
              and then not
                (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                   Editor.Feature_Panel.Search_Results_Feature
                 and then Editor.State.Has_Pending_Quick_Fix_Workflow (S)
                 and then Editor.Feature_Search_Results.External_Kind
                   (S.Feature_Search_Results) =
                     Editor.Feature_Search_Results
                       .Diagnostic_Quick_Fix_Action_List)
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Panel.Message_Feature_Panel_Row_Has_No_Target);
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Not a feature-panel command");
      end case;
   end Feature_Panel_Command_Availability;

   function Execute_Feature_Panel_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);

      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result
      is
         Found : Boolean := False;
         Msg   : Editor.Messages.Editor_Message;
      begin
         if Editor.Messages.Count (S.Messages) > Before_Messages then
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found then
               if Editor.Messages.Severity (Msg) =
                 Editor.Messages.Error_Message
               then
                  return Editor.Command_Execution.Failed (Command);
               elsif Editor.Messages.Severity (Msg) =
                 Editor.Messages.Warning_Message
               then
                  return Editor.Command_Execution.Unavailable (Command);
               end if;
            end if;
         end if;

         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Feature_Panel =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);
               Report_Info
                 (S, Editor.Feature_Panel.Message_Feature_Panel_Hidden);
            else
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);
               Report_Info
                 (S, Editor.Feature_Panel.Message_Feature_Panel_Shown);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Show_Feature_Panel =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
            Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);
            Report_Info (S, Editor.Feature_Panel.Message_Feature_Panel_Shown);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Hide_Feature_Panel =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);
            Report_Info (S, Editor.Feature_Panel.Message_Feature_Panel_Hidden);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Focus_Feature_Panel =>
            if Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Focus_Management.Clear_Transient_Focus_Owners (S);
            Editor.Panel_Focus.Focus_Editor_Text (S.Panel_Focus);
            Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
            Report_Info (S, Editor.Feature_Panel.Message_Feature_Panel_Focused);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Clear_Feature_Panel =>
            if Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0 then
               return Editor.Command_Execution.No_Op (Id);
            elsif not Editor.Feature_Panel_Controller.Dispatch_Active_Feature_Clear
              (S)
            then
               Report_Info (S, "Feature panel: no active feature");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Report_Info (S, Editor.Feature_Panel.Message_Feature_Panel_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Feature_Panel_Select_Next =>
            if Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0 then
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Panel.Select_Next (S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Feature_Panel_Select_Previous =>
            if Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0 then
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Panel.Select_Previous (S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Feature_Panel_Open_Selected =>
            declare
               Row : constant Natural :=
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
            begin
               case Editor.Feature_Panel.Active_Feature (S.Feature_Panel) is
                  when Editor.Feature_Panel.Outline_Feature =>
                     declare
                        Outline_Result : constant
                          Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Executor.Outline_Commands
                            .Execute_Outline_Row_Activation (S, Row);
                     begin
                        if Outline_Result.Status =
                          Editor.Command_Execution.Command_Executed
                        then
                           return Result_After_Command (Id);
                        end if;
                     end;

                  when Editor.Feature_Panel.Messages_Feature =>
                     declare
                        Message_Result : constant
                          Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Executor.Message_Commands
                            .Execute_Message_Row_Activation (S, Row);
                     begin
                        if Message_Result.Status =
                          Editor.Command_Execution.Command_Executed
                        then
                           return Result_After_Command (Id);
                        end if;
                     end;

                  when Editor.Feature_Panel.Search_Results_Feature =>
                     declare
                        Search_Result : constant
                          Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Executor.Search_Results_Commands
                            .Execute_Search_Result_Row_Activation (S, Row);
                     begin
                        if Search_Result.Status =
                          Editor.Command_Execution.Command_Executed
                        then
                           return Result_After_Command (Id);
                        end if;
                     end;

                  when Editor.Feature_Panel.Diagnostics_Feature =>
                     declare
                        Diagnostic_Result : constant
                          Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Executor.Diagnostics_Commands
                            .Execute_Diagnostic_Row_Activation
                            (S, Row);
                     begin
                        if Diagnostic_Result.Status =
                          Editor.Command_Execution.Command_Executed
                        then
                           return Result_After_Command (Id);
                        end if;

                        --  Diagnostics activation already reports the precise
                        --  missing/stale/source-less target reason.
                        return Editor.Command_Execution.No_Op (Id);
                     end;

                  when Editor.Feature_Panel.Unknown_Feature =>
                     null;
               end case;
            end;
            Report_Info
              (S, Editor.Feature_Panel.Message_Feature_Panel_Row_Has_No_Target);
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.No_Op (Id);

         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Feature_Panel_Command;

end Editor.Executor.Feature_Panel_Commands;
