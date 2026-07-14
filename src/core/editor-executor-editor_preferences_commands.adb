with Editor.Command_Execution;
with Editor.Cursor;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Line_Numbers;
with Editor.Messages;
with Editor.Minimap;
with Editor.Render_Cache;
with Editor.Scrollbars;
with Editor.Settings;
with Editor.Theme;

package body Editor.Executor.Editor_Preferences_Commands is

   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Report_Error
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Error;

   function Editor_Preferences_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      pragma Unreferenced (S);
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Theme
            | Editor.Commands.Command_Set_Theme_Light
            | Editor.Commands.Command_Set_Theme_Dark
            | Editor.Commands.Command_Toggle_Minimap
            | Editor.Commands.Command_Toggle_Scrollbars
            | Editor.Commands.Command_Toggle_Line_Numbers
            | Editor.Commands.Command_Toggle_Format_On_Save
            | Editor.Commands.Command_Toggle_Line_Number_Mode
            | Editor.Commands.Command_Set_Absolute_Line_Numbers
            | Editor.Commands.Command_Set_Relative_Line_Numbers
            | Editor.Commands.Command_Set_Hybrid_Line_Numbers
            | Editor.Commands.Command_Toggle_Current_Line_Highlight
            | Editor.Commands.Command_Toggle_Cursor_Blink
            | Editor.Commands.Command_Toggle_Syntax_Colouring
            | Editor.Commands.Command_Toggle_Diagnostics
            | Editor.Commands.Command_Toggle_Cursor_Style =>
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Not an editor preference command");
      end case;
   end Editor_Preferences_Command_Availability;

   function Execute_Editor_Preferences_Command
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
         when Editor.Commands.Command_Toggle_Theme =>
            Editor.Theme.Toggle_Theme;
            Report_Success (S, "Theme changed");
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Set_Theme_Light =>
            declare
               Found : Boolean := False;
            begin
               Editor.Theme.Set_Theme_By_Id ("light", Found);
               if Found then
                  Report_Success (S, "Theme changed");
               else
                  Report_Error (S, "Reload settings failed");
               end if;
            end;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Set_Theme_Dark =>
            declare
               Found : Boolean := False;
            begin
               Editor.Theme.Set_Theme_By_Id ("dark", Found);
               if Found then
                  Report_Success (S, "Theme changed");
               else
                  Report_Error (S, "Reload settings failed");
               end if;
            end;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Minimap =>
            Editor.Minimap.Set_Enabled (not Editor.Minimap.Enabled);
            Editor.Settings.Set_Show_Minimap (Editor.Minimap.Enabled);
            Report_Info
              (S,
               (if Editor.Minimap.Enabled
                then "Minimap shown"
                else "Minimap hidden"));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Scrollbars =>
            Editor.Scrollbars.Set_Enabled (not Editor.Scrollbars.Enabled);
            Report_Info
              (S,
               (if Editor.Scrollbars.Enabled
                then "Scrollbars shown"
                else "Scrollbars hidden"));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Line_Numbers =>
            Editor.Settings.Toggle_Show_Line_Numbers;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Format_On_Save =>
            Editor.Settings.Toggle_Format_On_Save;
            Report_Info
              (S,
               (if Editor.Settings.Format_On_Save
                then "Format on save enabled"
                else "Format on save disabled"));
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Line_Number_Mode =>
            Editor.Line_Numbers.Toggle_Mode;
            Report_Info (S, "Line number mode changed");
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Set_Absolute_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Absolute_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Set_Relative_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Relative_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Set_Hybrid_Line_Numbers =>
            Editor.Line_Numbers.Set_Current
              ((Mode => Editor.Line_Numbers.Hybrid_Line_Numbers));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Current_Line_Highlight =>
            Editor.Settings.Toggle_Highlight_Current_Line;
            Editor.Settings.Set_Highlight_Current_Gutter
              (Editor.Settings.Highlight_Current_Line);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Cursor_Blink =>
            Editor.Settings.Toggle_Cursor_Blink_Enabled;
            Report_Info
              (S,
               (if Editor.Settings.Cursor_Blink_Enabled
                then "Cursor blink enabled"
                else "Cursor blink disabled"));
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Syntax_Colouring =>
            Editor.Settings.Toggle_Use_Syntax_Colouring;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Diagnostics =>
            Editor.Settings.Toggle_Show_Diagnostics;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Toggle_Cursor_Style =>
            declare
               Cursor_Config : Editor.Cursor.Cursor_Config :=
                 Editor.Cursor.Current;
            begin
               case Cursor_Config.Style is
                  when Editor.Cursor.Bar_Cursor =>
                     Cursor_Config.Style := Editor.Cursor.Block_Cursor;
                  when Editor.Cursor.Block_Cursor =>
                     Cursor_Config.Style := Editor.Cursor.Underline_Cursor;
                  when Editor.Cursor.Underline_Cursor =>
                     Cursor_Config.Style := Editor.Cursor.Bar_Cursor;
               end case;
               Editor.Cursor.Set_Current (Cursor_Config);
            end;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;
   end Execute_Editor_Preferences_Command;

end Editor.Executor.Editor_Preferences_Commands;
