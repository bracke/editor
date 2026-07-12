with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Executor.Quick_Open_Commands;
with Editor.Layout;
with Editor.Overlay_Focus;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Quick_Open_Handlers is

   use type Editor.Commands.Command_Kind;
   use type Editor.Quick_Open.Quick_Open_Zone;

   function Handle_Quick_Open
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Message_Body   : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Hit    : Editor.Quick_Open.Quick_Open_Hit_Result;
      Cmd2   : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Quick_Open then
         Execute (Editor.Commands.Command_Open_Quick_Open);
         return True;
      elsif Cmd.Kind = Editor.Commands.Toggle_Quick_Open then
         Execute (Editor.Commands.Command_Toggle_Quick_Open);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Quick_Open.Select_All (S.Quick_Open);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Commands.Command_Accept_Quick_Open);
            elsif Cmd.Ch = ASCII.HT then
               if Cmd.Shift then
                  Execute (Editor.Commands.Command_Quick_Open_Previous_Result);
               else
                  Execute (Editor.Commands.Command_Quick_Open_Next_Result);
               end if;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Execute_Command (Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Execute_Command (Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Backspace;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Delete_Forward;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Quick_Open_Insert_Text;
            Cmd2.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Quick_Open.Move_Cursor_Left (S.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Quick_Open.Move_Cursor_Right (S.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Quick_Open.Move_Cursor_Start (S.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Quick_Open.Move_Cursor_End (S.Quick_Open);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Down | Editor.Commands.Quick_Open_Next_Result =>
            Execute (Editor.Commands.Command_Quick_Open_Next_Result);
            return True;

         when Editor.Commands.Move_Up | Editor.Commands.Quick_Open_Previous_Result =>
            Execute (Editor.Commands.Command_Quick_Open_Previous_Result);
            return True;

         when Editor.Commands.Palette_Accept | Editor.Commands.Accept_Quick_Open =>
            Execute (Editor.Commands.Command_Accept_Quick_Open);
            return True;

         when Editor.Commands.Quick_Open_Query_Set =>
            Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query
              (S, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Quick_Open_Query_Clear =>
            Execute (Editor.Commands.Command_Quick_Open_Query_Clear);
            return True;

         when Editor.Commands.Quick_Open_Kind_Next =>
            Execute (Editor.Commands.Command_Quick_Open_Kind_Next);
            return True;

         when Editor.Commands.Quick_Open_Kind_Previous =>
            Execute (Editor.Commands.Command_Quick_Open_Kind_Previous);
            return True;

         when Editor.Commands.Quick_Open_Kind_Clear =>
            Execute (Editor.Commands.Command_Quick_Open_Kind_Clear);
            return True;

         when Editor.Commands.Quick_Open_Scope_Set =>
            Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Set
              (S, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Quick_Open_Scope_Clear =>
            Execute (Editor.Commands.Command_Quick_Open_Scope_Clear);
            return True;

         when Editor.Commands.Quick_Open_Scope_From_Selected =>
            Execute (Editor.Commands.Command_Quick_Open_Scope_From_Selected);
            return True;

         when Editor.Commands.Quick_Open_Scope_Parent =>
            Execute (Editor.Commands.Command_Quick_Open_Scope_Parent);
            return True;

         when Editor.Commands.Quick_Open_Reveal_Active =>
            Execute (Editor.Commands.Command_Quick_Open_Reveal_Active);
            return True;

         when Editor.Commands.Quick_Open_Scope_Active_Directory =>
            Execute (Editor.Commands.Command_Quick_Open_Scope_Active_Directory);
            return True;

         when Editor.Commands.Quick_Open_Create_From_Query =>
            Execute (Editor.Commands.Command_Quick_Open_Create_From_Query);
            return True;

         when Editor.Commands.Quick_Open_Create_With_Parents_From_Query =>
            Execute (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query);
            return True;

         when Editor.Commands.Quick_Open_Priority_Toggle =>
            Execute (Editor.Commands.Command_Quick_Open_Priority_Toggle);
            return True;

         when Editor.Commands.Quick_Open_Priority_Clear =>
            Execute (Editor.Commands.Command_Quick_Open_Priority_Clear);
            return True;

         when Editor.Commands.First_Project_Search_Result =>
            Execute (Editor.Commands.Command_First_Project_Search_Result);
            return True;

         when Editor.Commands.Last_Project_Search_Result =>
            Execute (Editor.Commands.Command_Last_Project_Search_Result);
            return True;

         when Editor.Commands.Reveal_Active_Project_Search_Result =>
            Execute (Editor.Commands.Command_Reveal_Active_Project_Search_Result);
            return True;

         when Editor.Commands.Project_Search_Scope_Selected_Directory =>
            Execute (Editor.Commands.Command_Project_Search_Scope_Selected_Directory);
            return True;

         when Editor.Commands.Clear_Extra_Carets
            | Editor.Commands.Palette_Cancel
            | Editor.Commands.Close_Quick_Open =>
            Execute (Editor.Commands.Command_Close_Quick_Open);
            return True;

         when Editor.Commands.Move_To_Point =>
            Hit := Editor.Quick_Open.Hit_Test
              (Message_Body, Config, S.Quick_Open,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            case Hit.Zone is
               when Editor.Quick_Open.Outside_Quick_Open =>
                  Execute (Editor.Commands.Command_Close_Quick_Open);
               when Editor.Quick_Open.Quick_Open_Query_Field_Zone =>
                  declare
                     G : constant Editor.Layout.Rect :=
                       Editor.Quick_Open.Geometry
                         (Message_Body, Config, Editor.Layout.Cell_W, Editor.Layout.Cell_H);
                     Text_Start : constant Integer :=
                       G.X + Integer ((Config.Result_Padding_Columns + 1)
                                      * Editor.Layout.Cell_W);
                     Text_Cols : constant Natural :=
                       (if G.Width / Editor.Layout.Cell_W > 2
                        then G.Width / Editor.Layout.Cell_W - 2 else 1);
                     Visible_Column : constant Natural :=
                       (if Integer (Cmd.Click_X) <= Text_Start then 0
                        else Natural ((Integer (Cmd.Click_X) - Text_Start)
                                      / Integer (Editor.Layout.Cell_W)));
                  begin
                     Editor.Quick_Open.Set_Cursor_From_Visible_Column
                       (S.Quick_Open, Visible_Column, Text_Cols);
                  end;
               when Editor.Quick_Open.Quick_Open_Result_Row_Zone =>
                  while Editor.Quick_Open.Selected_Result_Index (S.Quick_Open) /= Hit.Result_Index loop
                     Execute (Editor.Commands.Command_Quick_Open_Next_Result);
                     exit when Editor.Quick_Open.Result_Count (S.Quick_Open) = 0;
                  end loop;
               when others =>
                  null;
            end case;
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Pointer_Hover =>
            Hit := Editor.Quick_Open.Hit_Test
              (Message_Body, Config, S.Quick_Open,
               Integer (Cmd.Click_X), Integer (Cmd.Click_Y),
               Editor.Layout.Cell_W, Editor.Layout.Cell_H);
            return Hit.Zone /= Editor.Quick_Open.Outside_Quick_Open;

         when others =>
            return True;
      end case;
   end Handle_Quick_Open;

end Editor.Input_Bridge.Quick_Open_Handlers;
