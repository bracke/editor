with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor;
with Editor.Executor.Clipboard;
with Editor.Layout;
with Editor.Overlay_Focus;
with Editor.Project_Search_Bar;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Project_Search_Bar_Handlers is

   use type Editor.Command_Kinds.Command_Kind;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Zone;

   function Handle_Project_Search_Bar
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command);
      Sync_Replace_Mode : not null access procedure) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Message_Body   : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      Config : constant Editor.Project_Search_Bar.Project_Search_Bar_Config := (others => <>);
      Hit    : Editor.Project_Search_Bar.Project_Search_Bar_Hit_Result;
      Cmd2   : Editor.Commands.Payloads.Command;
   begin
      if Cmd.Kind = Editor.Command_Kinds.Open_Project_Search_Bar then
         Execute (Editor.Command_Ids.Command_Open_Project_Search_Bar);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Panel.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Command_Kinds.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Project_Search_Bar.Select_All (S.Surface.Project_Search_Bar);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Command_Ids.Command_Run_Project_Search_From_Bar);
            elsif Cmd.Ch = ASCII.HT then
               Editor.Project_Search_Bar.Toggle_Active_Field (S.Surface.Project_Search_Bar);
               Sync_Replace_Mode.all;
               Editor.Render_Cache.Invalidate_All;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Execute_Command (Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Execute_Command (Cmd2);
            end if;
            return True;

         when Editor.Command_Kinds.Delete_Char
            | Editor.Command_Kinds.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Backspace;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Forward_Delete_Char
            | Editor.Command_Kinds.Delete_Next_Character =>
            Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Delete_Forward;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Paste_Text =>
            Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Paste_Clipboard =>
            Cmd2.Kind := Editor.Command_Kinds.Project_Search_Bar_Insert_Text;
            Cmd2.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Move_Left =>
            Editor.Project_Search_Bar.Move_Cursor_Left (S.Surface.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Right =>
            Editor.Project_Search_Bar.Move_Cursor_Right (S.Surface.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Home | Editor.Command_Kinds.Move_Line_Start =>
            Editor.Project_Search_Bar.Move_Cursor_Start (S.Surface.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_End | Editor.Command_Kinds.Move_Line_End =>
            Editor.Project_Search_Bar.Move_Cursor_End (S.Surface.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Down
            | Editor.Command_Kinds.Move_Project_Search_Selection_Down =>
            Execute (Editor.Command_Ids.Command_Move_Project_Search_Selection_Down);
            return True;

         when Editor.Command_Kinds.Move_Up
            | Editor.Command_Kinds.Move_Project_Search_Selection_Up =>
            Execute (Editor.Command_Ids.Command_Move_Project_Search_Selection_Up);
            return True;

         when Editor.Command_Kinds.Next_Project_Search_Result =>
            Execute (Editor.Command_Ids.Command_Next_Project_Search_Result);
            return True;

         when Editor.Command_Kinds.Previous_Project_Search_Result =>
            Execute (Editor.Command_Ids.Command_Previous_Project_Search_Result);
            return True;

         when Editor.Command_Kinds.Project_Search_Kind_Next =>
            Execute (Editor.Command_Ids.Command_Project_Search_Kind_Next);
            return True;

         when Editor.Command_Kinds.Project_Search_Kind_Previous =>
            Execute (Editor.Command_Ids.Command_Project_Search_Kind_Previous);
            return True;

         when Editor.Command_Kinds.Project_Search_Kind_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Kind_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Scope_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Scope_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Case_Toggle =>
            Execute (Editor.Command_Ids.Command_Project_Search_Case_Toggle);
            return True;

         when Editor.Command_Kinds.Project_Search_Case_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Case_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Whole_Word_Toggle =>
            Execute (Editor.Command_Ids.Command_Project_Search_Whole_Word_Toggle);
            return True;

         when Editor.Command_Kinds.Project_Search_Whole_Word_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Whole_Word_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Regex_Toggle =>
            Execute (Editor.Command_Ids.Command_Project_Search_Regex_Toggle);
            return True;

         when Editor.Command_Kinds.Project_Search_Regex_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Regex_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Include_Filter_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Include_Filter_Clear);
            return True;

         when Editor.Command_Kinds.Project_Search_Exclude_Filter_Clear =>
            Execute (Editor.Command_Ids.Command_Project_Search_Exclude_Filter_Clear);
            return True;

         when Editor.Command_Kinds.Palette_Accept | Editor.Command_Kinds.Run_Project_Search_From_Bar =>
            Execute (Editor.Command_Ids.Command_Run_Project_Search_From_Bar);
            return True;

         when Editor.Command_Kinds.Open_Selected_Project_Search_Result =>
            Execute (Editor.Command_Ids.Command_Open_Selected_Project_Search_Result);
            return True;

         when Editor.Command_Kinds.Clear_Project_Search =>
            Execute (Editor.Command_Ids.Command_Clear_Project_Search);
            return True;

         when Editor.Command_Kinds.Clear_Extra_Carets
            | Editor.Command_Kinds.Palette_Cancel
            | Editor.Command_Kinds.Close_Project_Search_Bar =>
            Execute (Editor.Command_Ids.Command_Close_Project_Search_Bar);
            return True;

         when Editor.Command_Kinds.Move_To_Point =>
            Hit := Editor.Project_Search_Bar.Hit_Test
              (Message_Body, Config, S.Surface.Project_Search_Bar,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            case Hit.Zone is
               when Editor.Project_Search_Bar.Outside_Project_Search_Bar =>
                  Editor.Executor.Dismiss_Active_Overlay
                    (S, Editor.Overlay_Focus.Dismiss_Outside_Click);
                  return False;
               when Editor.Project_Search_Bar.Project_Search_Query_Field_Zone =>
                  Editor.Project_Search_Bar.Focus_Query_Field (S.Surface.Project_Search_Bar);
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Project_Search_Bar.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Total_Cols : constant Natural := G.Width / Editor.Layout.Cell_W;
                     Run_Start : constant Natural :=
                       (if Total_Cols > 22 then Total_Cols - 22 else 0);
                     Field_Cols : constant Natural :=
                       (if Run_Start > 18 then Run_Start - 18
                        else Natural'Max (1, Config.Query_Field_Min_Columns));
                     Text_Start : constant Integer :=
                       G.X + Integer (17 * Editor.Layout.Cell_W);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Project_Search_Bar.Set_Cursor_From_Visible_Column
                       (S.Surface.Project_Search_Bar, Visible_Column, Field_Cols);
                  end;
               when Editor.Project_Search_Bar.Project_Search_Replace_Field_Zone =>
                  Editor.Project_Search_Bar.Focus_Replace_Field (S.Surface.Project_Search_Bar);
                  Sync_Replace_Mode.all;
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Project_Search_Bar.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Total_Cols : constant Natural := G.Width / Editor.Layout.Cell_W;
                     Run_Start : constant Natural :=
                       (if Total_Cols > 22 then Total_Cols - 22 else 0);
                     Field_Cols : constant Natural :=
                       (if Run_Start > 18 then Run_Start - 18
                        else Natural'Max (1, Config.Query_Field_Min_Columns));
                     Text_Start : constant Integer :=
                       G.X + Integer (17 * Editor.Layout.Cell_W);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Project_Search_Bar.Set_Cursor_From_Visible_Column
                       (S.Surface.Project_Search_Bar, Visible_Column, Field_Cols);
                  end;
               when Editor.Project_Search_Bar.Project_Search_Run_Button_Zone =>
                  Execute (Editor.Command_Ids.Command_Run_Project_Search_From_Bar);
               when Editor.Project_Search_Bar.Project_Search_Clear_Button_Zone =>
                  Execute (Editor.Command_Ids.Command_Clear_Project_Search);
               when Editor.Project_Search_Bar.Project_Search_Close_Button_Zone =>
                  Execute (Editor.Command_Ids.Command_Close_Project_Search_Bar);
               when others =>
                  null;
            end case;
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Pointer_Hover =>
            Hit := Editor.Project_Search_Bar.Hit_Test
              (Message_Body, Config, S.Surface.Project_Search_Bar,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            return Hit.Zone /= Editor.Project_Search_Bar.Outside_Project_Search_Bar;

         when others =>
            return True;
      end case;
   end Handle_Project_Search_Bar;

end Editor.Input_Bridge.Project_Search_Bar_Handlers;
