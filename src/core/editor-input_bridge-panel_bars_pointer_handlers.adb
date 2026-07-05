with Editor.Buffers;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.File_Tree_View;
with Editor.Focus_Management;
with Editor.Input_Bridge.Pointer_Routing;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Panels;
with Editor.Pending_Transition_Bar;
with Editor.Render_Cache;
with Editor.Tab_Bar;
with Editor.View;

package body Editor.Input_Bridge.Panel_Bars_Pointer_Handlers is

   use type Editor.Commands.Command_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Panels.Panel_Id;

   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Minimap_Pointer_Command (Kind);
   end Is_Minimap_Pointer_Command;

   function Handle_Pending_Transition_Bar_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access) return Boolean
   is
      Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Pending_Transition_Bar.Pending_Bar_Config := (others => <>);
      Snapshot : constant Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot
          (S.Pending_Transitions, Config);
      Status_Y : constant Integer :=
        Editor.Layout.Status_Bar_Y (Layout_Config, Editor.View.Viewport_Height);
      Bar_Y : constant Integer :=
        Integer'Max (Layout_Config.Origin_Y, Status_Y - Integer (Editor.Layout.Cell_H));
      Bar_Layout : Editor.Pending_Transition_Bar.Pending_Bar_Layout;
      Hit : Editor.Pending_Transition_Bar.Pending_Bar_Hit_Result;
   begin
      if Cmd.Kind /= Editor.Commands.Move_To_Point
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Pending_Transition_Bar.Is_Visible (Snapshot) then
         return False;
      end if;

      Bar_Layout := Editor.Pending_Transition_Bar.Layout
        (Snapshot => Snapshot,
         Bounds_X => Layout_Config.Origin_X,
         Bounds_Y => Bar_Y,
         Bounds_W => Integer (Editor.View.Viewport_Width),
         Cell_W   => Editor.Layout.Cell_W,
         Cell_H   => Editor.Layout.Cell_H);

      Hit := Editor.Pending_Transition_Bar.Hit_Test
        (Snapshot, Bar_Layout, Integer (Cmd.Click_X), Integer (Cmd.Click_Y));

      case Hit.Zone is
         when Editor.Pending_Transition_Bar.Outside_Pending_Bar =>
            return False;

         when Editor.Pending_Transition_Bar.Pending_Bar_Background =>
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            return True;

         when Editor.Pending_Transition_Bar.Pending_Bar_Action_Zone =>
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            if Cmd.Kind = Editor.Commands.Move_To_Point then
               Execute.all
                 (Editor.Pending_Transition_Bar.Command_For_Action (Hit.Action));
               Editor.Render_Cache.Invalidate_All;
            end if;
            return True;
      end case;
   end Handle_Pending_Transition_Bar_Pointer;

   function Handle_Tab_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Hit : Editor.Tab_Bar.Tab_Hit_Result;
      Registry : Editor.Buffers.Buffer_Registry;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Tab_Bar.Enabled (Layout.Tab_Bar)
        or else Integer (Cmd.Click_Y) < Integer (Editor.Layout.Tab_Bar_Y (Layout))
        or else Integer (Cmd.Click_Y) >=
          Integer (Editor.Layout.Tab_Bar_Y (Layout)
                   + Editor.Layout.Tab_Bar_Height (Layout))
      then
         return False;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Registry := Editor.Buffers.Global_Registry_For_UI;

      declare
         Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
         Summaries : Editor.Tab_Bar.Tab_Buffer_Summary_Array (1 .. Count);
      begin
         for I in Summaries'Range loop
            Summaries (I) := Editor.Buffers.Summary_At (Registry, I);
         end loop;

         Hit := Editor.Tab_Bar.Hit_Test
        (Config         => Layout.Tab_Bar,
         Buffers        => Summaries,
         Viewport_Width => Editor.View.Viewport_Width,
         Cell_W         => Editor.Layout.Cell_W,
         Cell_H         => Editor.Layout.Cell_H,
         X              => Integer (Cmd.Click_X),
         Y              => Integer (Cmd.Click_Y),
         Origin_X       => Layout.Origin_X,
         Origin_Y       => Layout.Origin_Y);
      end;

      case Hit.Zone is
         when Editor.Tab_Bar.Outside_Tab_Bar =>
            return False;

         when Editor.Tab_Bar.Tab_Bar_Background_Zone
            | Editor.Tab_Bar.Tab_Overflow_Zone =>
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            return True;

         when Editor.Tab_Bar.Tab_Body_Zone =>
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Hit.Buffer_Id /= Editor.Buffers.No_Buffer
            then
               Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
                 (S, Hit.Buffer_Id);
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
            end if;
            return True;

         when Editor.Tab_Bar.Tab_Close_Zone =>
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            if Cmd.Kind = Editor.Commands.Move_To_Point
              and then Hit.Buffer_Id /= Editor.Buffers.No_Buffer
            then
               Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer
                 (S, Hit.Buffer_Id);
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
            end if;
            return True;
      end case;
   end Handle_Tab_Bar_Pointer;

   function Handle_Status_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if Editor.Layout.Is_In_Status_Bar
           (Config          => Layout,
            X               => Integer (Cmd.Click_X),
            Y               => Integer (Cmd.Click_Y),
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height)
      then
         Pointer_State.Set_Minimap_Drag_Active (False);
         Pointer_State.Clear_Scrollbar_Drag;
         Pointer_State.Clear_Gutter_Line_Selection;
         Editor.State.Clear_Gutter_Marker_Hover (S);
         return True;
      end if;

      return False;
   end Handle_Status_Bar_Pointer;

   function Handle_Panel_Splitter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;

      procedure Synchronize_File_Tree_Width is
      begin
         Editor.File_Tree_View.Set_Current_Width_In_Columns
           (Editor.Panels.Current_Size
              (S.Panels, Editor.Panels.File_Tree_Panel));
         Editor.Panels.Set_Current (S.Panels);
      end Synchronize_File_Tree_Width;
   begin
      if Editor.Panels.Resize_Active (S.Panels) then
         declare
            Resize : constant Editor.Panels.Panel_Resize_State :=
              Editor.Panels.Resize_State (S.Panels);
         begin
            if Cmd.Kind = Editor.Commands.Drag_To_Point
              or else Cmd.Kind = Editor.Commands.Drag_Rectangle_To_Point
            then
               Editor.Panels.Update_Resize
                 (Panels      => S.Panels,
                  Mouse_X     => Integer (Cmd.Click_X),
                  Mouse_Y     => Integer (Cmd.Click_Y),
                  Cell_Width  => Editor.Layout.Cell_W,
                  Cell_Height => Editor.Layout.Cell_H);
               if Resize.Panel = Editor.Panels.File_Tree_Panel then
                  Synchronize_File_Tree_Width;
               else
                  Editor.Panels.Set_Current (S.Panels);
               end if;
               Editor.Render_Cache.Invalidate_All;
               return True;
            elsif Cmd.Kind = Editor.Commands.Pointer_Hover then
               return True;
            else
               Editor.Panels.End_Resize (S.Panels);
               if Resize.Panel = Editor.Panels.File_Tree_Panel then
                  Synchronize_File_Tree_Width;
               else
                  Editor.Panels.Set_Current (S.Panels);
               end if;
               Editor.Render_Cache.Invalidate_All;
               return True;
            end if;
         end;
      end if;

      if Cmd.Kind /= Editor.Commands.Move_To_Point then
         return False;
      end if;

      for Id in Editor.Panels.Panel_Id loop
         if Editor.Layout.Is_In_Panel_Splitter
              (Config          => Layout,
               Id              => Id,
               X               => Integer (Cmd.Click_X),
               Y               => Integer (Cmd.Click_Y),
               Viewport_Width  => Editor.View.Viewport_Width,
               Viewport_Height => Editor.View.Viewport_Height)
         then
            Pointer_State.Reset_All;
            Editor.State.Clear_Gutter_Marker_Hover (S);
            Editor.Panels.Begin_Resize
              (Panels  => S.Panels,
               Id      => Id,
               Mouse_X => Integer (Cmd.Click_X),
               Mouse_Y => Integer (Cmd.Click_Y));
            Editor.Panels.Set_Current (S.Panels);
            Editor.Render_Cache.Invalidate_All;
            return True;
         end if;
      end loop;

      return False;
   end Handle_Panel_Splitter_Pointer;

end Editor.Input_Bridge.Panel_Bars_Pointer_Handlers;
