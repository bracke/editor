with Ada.Strings.Unbounded;

with Editor.Clipboard;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Messages;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Message_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;

   function Message_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_Show_Messages
            | Command_Toggle_Message_Info
            | Command_Toggle_Message_Warnings
            | Command_Toggle_Message_Errors
            | Command_Show_All_Messages
            | Command_Clear_Message_Filter
            | Command_Clear_Messages
            | Command_Clear_Info_Messages
            | Command_Clear_Warning_Messages
            | Command_Clear_Error_Messages =>
            return Editor.Commands.Available;

         when Command_Clear_Selected_Message
            | Command_Copy_Selected_Message_Text =>
            if Editor.Feature_Messages.Is_Empty (S.Feature_Messages) then
               return Editor.Commands.Unavailable ("No messages");
            elsif not Editor.Feature_Messages.Has_Selected_Message
              (S.Feature_Messages, S.Feature_Panel)
            then
               return Editor.Commands.Unavailable ("No message selected");
            end if;
            return Editor.Commands.Available;

         when Command_Dismiss_Latest_Message | Command_Dismiss_All_Messages =>
            if Editor.Messages.Is_Empty (S.Messages) then
               return Editor.Commands.Unavailable ("No messages");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a message command");
      end case;
   end Message_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean
      renames Editor.Executor.Feature_Target_Position_Is_Valid;

   function Focus_Feature_Target_Buffer
     (S             : in out Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
      renames Editor.Executor.Focus_Feature_Target_Buffer;

   procedure Apply_Feature_Target_Handoff
     (S             : in out Editor.State.State_Type;
      Target_Row    : Natural;
      Target_Column : Natural)
      renames Editor.Executor.Apply_Feature_Target_Handoff;

   function Executed
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.Executed;

   function No_Op
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.No_Op;

   procedure Report_Target_Unavailable
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "Navigation target unavailable.");
   end Report_Target_Unavailable;

   function Execute_Message_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Show_Messages =>
            if not Editor.Feature_Panel_Controller.Show_Feature
              (S, Editor.Feature_Panel.Messages_Feature)
            then
               Report_Info (S, Editor.Feature_Messages.Message_No_Messages);
               return No_Op (Id);
            end if;
            Report_Info (S, Editor.Feature_Messages.Message_Messages_Shown);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Clear_Messages =>
            if Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0 then
               return No_Op (Id);
            end if;
            Editor.Feature_Messages.Clear (S.Feature_Messages);
            Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
              (S.Feature_Messages, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Messages.Message_Messages_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Clear_Selected_Message =>
            if Editor.Feature_Messages.Clear_Selected_Message
              (S.Feature_Messages, S.Feature_Panel)
            then
               Report_Info (S, Editor.Feature_Messages.Message_Message_Cleared);
               Editor.Render_Cache.Invalidate_All;
               return Executed (Id);
            end if;
            Report_Info (S, Editor.Feature_Messages.Message_No_Selected_Message);
            Editor.Render_Cache.Invalidate_All;
            return No_Op (Id);

         when Editor.Commands.Command_Copy_Selected_Message_Text =>
            declare
               Text : constant String :=
                 Editor.Feature_Messages.Selected_Message_Text
                   (S.Feature_Messages, S.Feature_Panel);
            begin
               if Text'Length = 0 then
                  Report_Info
                    (S, Editor.Feature_Messages.Message_No_Selected_Message);
                  return No_Op (Id);
               end if;
               Editor.Clipboard.Set_Text (To_Unbounded_String (Text));
               Report_Info (S, Editor.Feature_Messages.Message_Message_Copied);
               Editor.Render_Cache.Invalidate_All;
               return Executed (Id);
            end;

         when Editor.Commands.Command_Clear_Info_Messages
            | Editor.Commands.Command_Clear_Warning_Messages
            | Editor.Commands.Command_Clear_Error_Messages =>
            declare
               Previous_Id : constant Editor.Feature_Messages.Message_Id :=
                 Editor.Feature_Messages.Selected_Message_Id
                   (S.Feature_Messages, S.Feature_Panel);
               Previous_Source : constant Natural :=
                 Editor.Feature_Messages.Selected_Message_Source_Index
                   (S.Feature_Messages, S.Feature_Panel);
               Severity : constant Editor.Feature_Messages.Message_Severity :=
                 (case Id is
                    when Editor.Commands.Command_Clear_Info_Messages =>
                       Editor.Feature_Messages.Info_Message,
                    when Editor.Commands.Command_Clear_Warning_Messages =>
                       Editor.Feature_Messages.Warning_Message,
                    when others =>
                       Editor.Feature_Messages.Error_Message);
               Removed : Natural := 0;
            begin
               Removed := Editor.Feature_Messages.Clear_Messages_By_Severity
                 (S.Feature_Messages, Severity);
               Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
                 (S.Feature_Messages, S.Feature_Panel, Previous_Id,
                  Previous_Source);
               Editor.Render_Cache.Invalidate_All;
               if Removed > 0 then
                  Report_Info
                    (S, Editor.Feature_Messages.Message_Messages_Cleared);
                  return Executed (Id);
               else
                  Report_Info (S, Editor.Feature_Messages.Message_No_Messages);
                  return No_Op (Id);
               end if;
            end;

         when Editor.Commands.Command_Toggle_Message_Info =>
            Editor.Feature_Messages.Toggle_Info (S.Feature_Messages);
            Editor.Feature_Messages.Project_Rows
              (S.Feature_Messages, S.Feature_Panel);
            if Editor.Feature_Messages.Severity_Is_Visible
              (S.Feature_Messages, Editor.Feature_Messages.Info_Message)
            then
               Report_Info (S, Editor.Feature_Messages.Message_Info_Shown);
            else
               Report_Info (S, Editor.Feature_Messages.Message_Info_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Toggle_Message_Warnings =>
            Editor.Feature_Messages.Toggle_Warnings (S.Feature_Messages);
            Editor.Feature_Messages.Project_Rows
              (S.Feature_Messages, S.Feature_Panel);
            if Editor.Feature_Messages.Severity_Is_Visible
              (S.Feature_Messages, Editor.Feature_Messages.Warning_Message)
            then
               Report_Info (S, Editor.Feature_Messages.Message_Warnings_Shown);
            else
               Report_Info (S, Editor.Feature_Messages.Message_Warnings_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Toggle_Message_Errors =>
            Editor.Feature_Messages.Toggle_Errors (S.Feature_Messages);
            Editor.Feature_Messages.Project_Rows
              (S.Feature_Messages, S.Feature_Panel);
            if Editor.Feature_Messages.Severity_Is_Visible
              (S.Feature_Messages, Editor.Feature_Messages.Error_Message)
            then
               Report_Info (S, Editor.Feature_Messages.Message_Errors_Shown);
            else
               Report_Info (S, Editor.Feature_Messages.Message_Errors_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Show_All_Messages =>
            Editor.Feature_Messages.Show_All (S.Feature_Messages);
            Editor.Feature_Messages.Project_Rows
              (S.Feature_Messages, S.Feature_Panel);
            Report_Info
              (S, Editor.Feature_Messages.Message_All_Severities_Shown);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Clear_Message_Filter =>
            Editor.Feature_Messages.Clear_Filter (S.Feature_Messages);
            Editor.Feature_Messages.Project_Rows
              (S.Feature_Messages, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Messages.Message_Filter_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Dismiss_Latest_Message =>
            Editor.Messages.Dismiss_Latest (S.Messages);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Dismiss_All_Messages =>
            Editor.Messages.Dismiss_All (S.Messages);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Message_Command;

   procedure Execute_Message_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
      procedure Run (Id : Editor.Commands.Command_Id);

      procedure Run (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Execute_Message_Command (S, Id);
         pragma Unreferenced (Result);
      begin
         null;
      end Run;
   begin
      case Kind is
         when Show_Messages =>
            Run (Command_Show_Messages);

         when Clear_Messages =>
            Run (Command_Clear_Messages);

         when Clear_Selected_Message =>
            Run (Command_Clear_Selected_Message);

         when Copy_Selected_Message_Text =>
            Run (Command_Copy_Selected_Message_Text);

         when Clear_Info_Messages =>
            Run (Command_Clear_Info_Messages);

         when Clear_Warning_Messages =>
            Run (Command_Clear_Warning_Messages);

         when Clear_Error_Messages =>
            Run (Command_Clear_Error_Messages);

         when Toggle_Message_Info =>
            Run (Command_Toggle_Message_Info);

         when Toggle_Message_Warnings =>
            Run (Command_Toggle_Message_Warnings);

         when Toggle_Message_Errors =>
            Run (Command_Toggle_Message_Errors);

         when Show_All_Messages =>
            Run (Command_Show_All_Messages);

         when Clear_Message_Filter =>
            Run (Command_Clear_Message_Filter);

         when others =>
            raise Program_Error with "unsupported message command kind";
      end case;
   end Execute_Message_Kind;

   function Execute_Message_Row_Click
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Feature_Messages.Map_Message_Row_To_Item
          (S.Feature_Messages, S.Feature_Panel, Row,
           Expected_Panel_Generation);
   begin
      if Mapped = 0
        or else not Editor.Feature_Messages.Validate_Row_Action
          (S.Feature_Messages, S.Feature_Panel, Row,
           Expected_Panel_Generation)
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Editor.Commands.Command_Feature_Panel_Open_Selected);
   end Execute_Message_Row_Click;

   function Execute_Message_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Feature_Messages.Map_Message_Row_To_Item
          (S.Feature_Messages, S.Feature_Panel, Row,
           Expected_Panel_Generation);
      Target_Buffer : Natural := 0;
      Target_Line   : Natural := 0;
      Target_Column_One_Based : Natural := 0;
      Target_Row    : Natural;
      Target_Column : Natural;
   begin
      if Row = 0
        or else Mapped = 0
        or else not Editor.Feature_Panel.Row_Is_Activatable
          (S.Feature_Panel, Positive (Row))
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Buffer := Editor.Feature_Messages.Item_Target_Buffer
        (S.Feature_Messages, Positive (Mapped));
      Target_Line := Editor.Feature_Messages.Item_Target_Line
        (S.Feature_Messages, Positive (Mapped));
      Target_Column_One_Based := Editor.Feature_Messages.Item_Target_Column
        (S.Feature_Messages, Positive (Mapped));

      if not Editor.Feature_Messages.Validate_Message_Target
          (S.Feature_Messages, Positive (Mapped), Target_Buffer)
        or else not Feature_Target_Position_Is_Valid
          (S, Target_Buffer, Target_Line, Target_Column_One_Based)
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      if not Focus_Feature_Target_Buffer (S, Target_Buffer) then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Row := Natural'Min
        (Target_Line - 1, Natural'Max (Editor.State.Line_Count (S), 1) - 1);
      Target_Column := Target_Column_One_Based - 1;
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
      Apply_Feature_Target_Handoff (S, Target_Row, Target_Column);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Editor.Commands.Command_Feature_Panel_Open_Selected);
   end Execute_Message_Row_Activation;

end Editor.Executor.Message_Commands;
