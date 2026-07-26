with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Editor.Commands.Palette_Model; use Editor.Commands.Palette_Model;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Editor.Command_Palette;
with Editor.Executor;
with Editor.Executor.Clipboard;
with Editor.Executor.Command_Palette_Projection;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.Theme;
with Editor.View;


package body Editor.Input_Bridge.Command_Palette_Handlers is

   use type Editor.Command_Kinds.Command_Kind;
   use type Editor.Command_Ids.Command_Id;

   function Handle_Command_Palette
     (S              : in out Editor.State.State_Type;
      Cmd            : Editor.Commands.Payloads.Command;
      Execute        : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Report_Info    : not null access procedure (Message : String);
      Report_Warning : not null access procedure (Message : String))
      return Boolean
   is
      procedure Accept_Selected_Palette_Command is
         Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
         Visible_Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
         Preferred  : constant Editor.Command_Ids.Command_Id :=
           Editor.Command_Palette.Current.Selected_Command_Id;
         Still_Visible : Boolean := Preferred = Editor.Command_Ids.No_Command;
      begin
         Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates
           (S, Candidates);
         Editor.Command_Palette.Visible_Candidates (Candidates, Visible_Candidates);

         if Preferred /= Editor.Command_Ids.No_Command then
            for Candidate of Visible_Candidates loop
               if Candidate.Id = Preferred then
                  Still_Visible := True;
                  exit;
               end if;
            end loop;
         end if;

         if not Still_Visible then
            Report_Warning ("Selected command is no longer visible");
            Editor.Command_Palette.Reconcile_Selection (Visible_Candidates);
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Command_Palette.Reconcile_Selection (Visible_Candidates);

         declare
            Selected_Index : constant Natural :=
              Editor.Command_Palette.Current.Selected_Item;
         begin
            if Visible_Candidates.Length = 0
              or else Selected_Index >= Natural (Visible_Candidates.Length)
            then
               Report_Warning ("No command selected");
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;

            declare
               Candidate : constant Editor.Commands.Palette_Model.Command_Palette_Candidate :=
                 Visible_Candidates.Element (Selected_Index);
            begin
               if not Candidate.Available then
                  declare
                     Reason : constant String :=
                       (if Length (Candidate.Reason) > 0
                        then To_String (Candidate.Reason)
                        else "Command not available here");
                  begin
                     Report_Info (Reason);
                  end;
                  Editor.Render_Cache.Invalidate_All;
                  return;
               end if;

               if Candidate.Id = Editor.Command_Ids.Command_Palette_Show_Command_Help then
                  Execute (Candidate.Id);
                  Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates
                    (S, Candidates);
                  Editor.Command_Palette.Visible_Candidates
                    (Candidates, Visible_Candidates);
                  Editor.Command_Palette.Reconcile_Selection
                    (Visible_Candidates, Preferred_Command => Candidate.Id);
                  Editor.Render_Cache.Invalidate_All;
               else
                  Editor.Executor.Dismiss_Active_Overlay
                    (S, Editor.Overlay_Focus.Dismiss_Accept);
                  Execute (Candidate.Id);
               end if;
            end;
         end;
      end Accept_Selected_Palette_Command;
   begin
      if Cmd.Kind = Editor.Command_Kinds.Open_Command_Palette then
         Execute (Editor.Command_Ids.Command_Open_Command_Palette);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Command_Palette_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Command_Kinds.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Command_Palette.Select_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Accept_Selected_Palette_Command;
            elsif Length (Cmd.Text) > 0 then
               Editor.Command_Palette.Insert_Text (To_String (Cmd.Text));
            else
               Editor.Command_Palette.Append_Character (Cmd.Ch);
            end if;

         when Editor.Command_Kinds.Delete_Char
            | Editor.Command_Kinds.Delete_Previous_Character =>
            Editor.Command_Palette.Backspace;

         when Editor.Command_Kinds.Forward_Delete_Char
            | Editor.Command_Kinds.Delete_Next_Character =>
            Editor.Command_Palette.Delete_Forward;

         when Editor.Command_Kinds.Paste_Text =>
            Editor.Command_Palette.Insert_Text (To_String (Cmd.Text));

         when Editor.Command_Kinds.Paste_Clipboard =>
            Editor.Command_Palette.Insert_Text
              (To_String (Editor.Executor.Clipboard.Text_For_Local_Input));

         when Editor.Command_Kinds.Move_Left =>
            Editor.Command_Palette.Move_Cursor_Left;

         when Editor.Command_Kinds.Move_Right =>
            Editor.Command_Palette.Move_Cursor_Right;

         when Editor.Command_Kinds.Move_Home | Editor.Command_Kinds.Move_Line_Start =>
            Editor.Command_Palette.Move_Cursor_Start;

         when Editor.Command_Kinds.Move_End | Editor.Command_Kinds.Move_Line_End =>
            Editor.Command_Palette.Move_Cursor_End;

         when Editor.Command_Kinds.Move_Up =>
            declare
               Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
            begin
               Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates
                 (S, Candidates);
               Editor.Command_Palette.Move_Selection_By_Candidates
                 (Candidates, -1);
            end;

         when Editor.Command_Kinds.Move_Down =>
            declare
               Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
            begin
               Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates
                 (S, Candidates);
               Editor.Command_Palette.Move_Selection_By_Candidates
                 (Candidates, 1);
            end;

         when Editor.Command_Kinds.Palette_Accept =>
            Accept_Selected_Palette_Command;

         when Editor.Command_Kinds.Palette_Show_Command_Help =>
            Execute (Editor.Command_Ids.Command_Palette_Show_Command_Help);

         when Editor.Command_Kinds.Palette_Cancel
            | Editor.Command_Kinds.Clear_Extra_Carets =>
            declare
               Owner_Before : constant Editor.Focus_Management.Focus_Owner :=
                 Editor.Focus_Management.Effective_Focus_Owner (S);
            begin
               Editor.Executor.Dismiss_Active_Overlay
                 (S, Editor.Overlay_Focus.Dismiss_Escape);
               Editor.Focus_Management.Apply_Command_Focus_Result
                 (S, Editor.Command_Ids.Command_Cancel, Owner_Before);
            end;

         when Editor.Command_Kinds.Move_To_Point =>
            declare
               Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
               Margin : constant Natural := Editor.Theme.Palette_Margin;
               Max_W  : constant Natural := Editor.Theme.Palette_Max_Width;
               Width  : Natural := Max_W;
               X      : Integer := 0;
               Y      : Integer := 0;
               Text_X : Integer := 0;
               Field_Cols : Natural := 1;
               Click_X : constant Integer := Integer (Cmd.Click_X);
               Click_Y : constant Integer := Integer (Cmd.Click_Y);
            begin
               if Editor.View.Viewport_Width <= Margin * 2 then
                  Width := Editor.View.Viewport_Width;
               else
                  Width := Natural'Min (Max_W, Editor.View.Viewport_Width - Margin * 2);
               end if;

               X := Layout.Origin_X
                 + Integer ((Editor.View.Viewport_Width - Width) / 2);
               Y := Layout.Origin_Y
                 + Integer
                     (Float'Max
                        (Editor.Theme.Palette_Top_Min_Offset,
                         Float (Editor.View.Viewport_Height)
                         * Editor.Theme.Palette_Top_Fraction));
               Text_X := X + Integer (Editor.Theme.Palette_Text_Padding_X);
               Field_Cols :=
                 (if Width > Natural (2.0 * Editor.Theme.Palette_Text_Padding_X)
                              + 2 * Editor.Layout.Cell_W
                  then (Width - Natural (2.0 * Editor.Theme.Palette_Text_Padding_X))
                       / Editor.Layout.Cell_W - 2
                  else 1);

               if Click_X >= Text_X + Integer (2 * Editor.Layout.Cell_W)
                 and then Click_X < X + Integer (Width)
                 and then Click_Y >= Y + Integer (Editor.Theme.Palette_Text_Padding_Y)
                 and then Click_Y < Y + Integer (Editor.Theme.Palette_Text_Padding_Y)
                                      + Integer (Editor.Layout.Cell_H)
               then
                  Editor.Command_Palette.Set_Cursor_From_Visible_Column
                    (Natural ((Click_X - Text_X
                               - Integer (2 * Editor.Layout.Cell_W))
                              / Integer (Editor.Layout.Cell_W)),
                     Field_Cols);
               else
                  Editor.Executor.Dismiss_Active_Overlay
                    (S, Editor.Overlay_Focus.Dismiss_Outside_Click);
               end if;
            end;

         when Editor.Command_Kinds.Pointer_Hover =>
            null;

         when others =>
            null;
      end case;

      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Command_Palette;

end Editor.Input_Bridge.Command_Palette_Handlers;
