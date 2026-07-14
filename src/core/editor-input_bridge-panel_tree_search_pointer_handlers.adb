with Editor.Buffers;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.File_Tree_View;
with Editor.Focus_Management;
with Editor.Input_Bridge.Pointer_Routing;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Panels;
with Editor.Project_Search;
with Editor.Render_Cache;
with Editor.Search_Results;
with Editor.View;

package body Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers is

   use type Editor.Commands.Command_Kind;
   use type Editor.File_Tree_View.File_Tree_Action;
   use type Editor.File_Tree_View.File_Tree_View_Zone;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Search_Results.Search_Results_Zone;

   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Minimap_Pointer_Command (Kind);
   end Is_Minimap_Pointer_Command;

   procedure Reset_Pointer_State
     (S : in out Editor.State.State_Type)
   is
   begin
      Pointer_State.Set_Minimap_Drag_Active (False);
      Pointer_State.Clear_Scrollbar_Drag;
      Pointer_State.Clear_Gutter_Line_Selection;
      Editor.State.Clear_Gutter_Marker_Hover (S);
   end Reset_Pointer_State;

   function Handle_File_Tree_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel_Rect : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Geometry : constant Editor.File_Tree_View.File_Tree_Geometry :=
        (X      => Panel_Rect.X,
         Y      => Panel_Rect.Y,
         Width  => Panel_Rect.Width,
         Height => Panel_Rect.Height);
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      Hit := Editor.File_Tree_View.Hit_Test
        (Geometry => Geometry,
         Config   => Layout.File_Tree_View,
         Tree     => S.File_Tree,
         State    => S.File_Tree_View,
         X        => Integer (Cmd.Click_X),
         Y        => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.File_Tree_View.Outside_File_Tree then
         Reset_Pointer_State (S);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            declare
               Action : constant Editor.File_Tree_View.File_Tree_Action :=
                 Editor.File_Tree_View.Action_For_Hit
                   (Layout.File_Tree_View, S.File_Tree, Hit);
            begin
               Editor.Focus_Management.Set_Focus_Owner
                 (S, Editor.Focus_Management.Focus_File_Tree);
               Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Action
                 (S, Hit);
               if Action = Editor.File_Tree_View.Open_File_Action then
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end if;
            end;
            Editor.Render_Cache.Invalidate_All;
         end if;

         return True;
      end if;

      return False;
   end Handle_File_Tree_Pointer;

   function Handle_Search_Results_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Hit      : Editor.Search_Results.Search_Results_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        or else Editor.Panels.Active_Bottom_Content (S.Panels)
          /= Editor.Panels.Search_Results_Content
      then
         return False;
      end if;

      Snapshot := Editor.Search_Results.Visible_Snapshot
        (Editor.Search_Results.Build_Snapshot
           (S.Project_Search, Config,
            Editor.Buffers.Global_Registry_For_UI),
         S.Search_Results_View,
         (if Editor.Layout.Cell_H = 0 then 0 else Panel.Height / Editor.Layout.Cell_H));
      Hit := Editor.Search_Results.Hit_Test
        (Panel_Rect  => Panel,
         Config      => Config,
         Snapshot    => Snapshot,
         Cell_Height => Editor.Layout.Cell_H,
         X           => Integer (Cmd.Click_X),
         Y           => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.Search_Results.Outside_Search_Results then
         Reset_Pointer_State (S);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            Editor.Focus_Management.Set_Focus_Owner
              (S,
               Editor.Focus_Management.Focus_Project_Search_Results);
            if Hit.Zone = Editor.Search_Results.Search_Results_Match_Row_Zone then
               Editor.Executor.Project_Search_Result_Commands.Execute_Open_Project_Search_Result
                 (S, Hit.Result_Index);
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
            elsif Hit.Zone = Editor.Search_Results.Search_Results_File_Row_Zone then
               declare
                  Found : Boolean := False;
                  First : constant Natural :=
                    Editor.Search_Results.First_Result_In_File_Group
                      (Snapshot, Hit.Row_Index, Found);
               begin
                  if Found then
                     Editor.Project_Search.Set_Selected_Result_Index
                       (S.Project_Search, First);
                     Editor.Render_Cache.Invalidate_All;
                  end if;
               end;
            end if;
         end if;

         return True;
      end if;

      return False;
   end Handle_Search_Results_Panel_Pointer;

end Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers;
