with Editor.Cursor;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Layout;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Project;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.File_Tree_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   procedure Select_First_File_Tree_Row
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Select_First_Visible_Row
        (S.File_Tree_View, S.File_Tree);
      Editor.File_Tree_View.Set_Top_Row (S.File_Tree_View, 1);
      Editor.Render_Cache.Invalidate_All;
   end Select_First_File_Tree_Row;

   procedure Select_Last_File_Tree_Row
     (S : in out Editor.State.State_Type)
   is
      Layout    : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel     : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Page_Rows : constant Natural :=
        (if Editor.Layout.Cell_H = 0 then 1
         else Natural'Max (1, Panel.Height / Editor.Layout.Cell_H));
      Count     : constant Natural :=
        Editor.File_Tree.Visible_Row_Count (S.File_Tree);
   begin
      Editor.File_Tree_View.Select_Last_Visible_Row
        (S.File_Tree_View, S.File_Tree);
      if Count <= Page_Rows then
         Editor.File_Tree_View.Set_Top_Row (S.File_Tree_View, 1);
      else
         Editor.File_Tree_View.Set_Top_Row
           (S.File_Tree_View, Count - Page_Rows + 1);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Select_Last_File_Tree_Row;

   function Handle_File_Tree_Focused_Surface_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Focused_Key_Result
   is
   begin
      if not Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
         return File_Tree_Not_Focused;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_File_Tree_Move_Up);
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_File_Tree_Move_Down);
         when Editor.Keybindings.Key_Page_Up =>
            Execute (Editor.Commands.Command_File_Tree_Page_Up);
         when Editor.Keybindings.Key_Page_Down =>
            Execute (Editor.Commands.Command_File_Tree_Page_Down);
         when Editor.Keybindings.Key_Left =>
            Execute (Editor.Commands.Command_File_Tree_Collapse_Selected);
         when Editor.Keybindings.Key_Right =>
            Execute (Editor.Commands.Command_File_Tree_Expand_Selected);
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_File_Tree_Open_Selected);
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Focus_Editor_Text);
         when others =>
            return File_Tree_Key_Not_Handled;
      end case;

      Notify_Input;
      return File_Tree_Key_Handled;
   end Handle_File_Tree_Focused_Surface_Key;

   function Handle_File_Tree_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if not Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
         return False;
      end if;

      if (not Editor.Project.Has_Project (S.Project))
        or else not Editor.Panels.Is_Visible
          (S.Panels, Editor.Panels.File_Tree_Panel)
      then
         Execute (Editor.Commands.Command_Focus_Editor_Text);
         Notify_Input;
         return True;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_File_Tree_Move_Up);
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_File_Tree_Move_Down);
         when Editor.Keybindings.Key_Page_Up =>
            Execute (Editor.Commands.Command_File_Tree_Page_Up);
         when Editor.Keybindings.Key_Page_Down =>
            Execute (Editor.Commands.Command_File_Tree_Page_Down);
         when Editor.Keybindings.Key_Home =>
            Select_First_File_Tree_Row (S);
         when Editor.Keybindings.Key_End =>
            Select_Last_File_Tree_Row (S);
         when Editor.Keybindings.Key_Left =>
            Execute (Editor.Commands.Command_File_Tree_Collapse_Selected);
         when Editor.Keybindings.Key_Right =>
            Execute (Editor.Commands.Command_File_Tree_Expand_Selected);
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_File_Tree_Open_Selected);
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Focus_Editor_Text);
         when others =>
            null;
      end case;

      Notify_Input;
      return True;
   end Handle_File_Tree_Key;

end Editor.Input_Bridge.File_Tree_Key_Handlers;
