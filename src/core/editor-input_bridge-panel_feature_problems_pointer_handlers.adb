with Editor.Diagnostics;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.Input_Bridge.Pointer_Routing;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Panels;
with Editor.Problems;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers is

   use type Editor.Commands.Command_Kind;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Problems.Problems_Group_Mode;
   use type Editor.Problems.Problems_Zone;
   use type Editor.Problems.Problems_Severity_Filter;
   use type Editor.Problems.Problems_Sort_Mode;

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
      Pointer_State.Reset_All;
      Editor.State.Clear_Gutter_Marker_Hover (S);
   end Reset_Pointer_State;

   function Handle_Feature_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Width  : constant Natural :=
        Natural'Min (280, Editor.View.Viewport_Width);
      X0     : constant Integer := Integer (Editor.View.Viewport_Width) - Integer (Width);
      Y0     : constant Integer := Editor.Layout.Text_Viewport_Y (Layout);
      Height : constant Natural :=
        Editor.Layout.Text_Viewport_Height
          (Layout, Editor.View.Viewport_Height);
      Row    : Natural := 0;
      Gen    : constant Natural :=
        Editor.Feature_Panel.Projection_Generation
          (S.Feature_Panel);
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
         return False;
      end if;

      if Integer (Cmd.Click_X) < X0
        or else Integer (Cmd.Click_X) >= X0 + Integer (Width)
        or else Integer (Cmd.Click_Y) < Y0
        or else Integer (Cmd.Click_Y) >= Y0 + Integer (Height)
      then
         return False;
      end if;

      Reset_Pointer_State (S);

      if Cmd.Kind = Editor.Commands.Pointer_Hover then
         return True;
      end if;

      if Editor.Layout.Cell_H /= 0
        and then Integer (Cmd.Click_Y) >= Y0 + Integer (Editor.Layout.Cell_H)
      then
         Row := Editor.Feature_Panel.Visible_Row_To_Row_Index
           (S.Feature_Panel,
            Natural ((Integer (Cmd.Click_Y) - Y0) / Integer (Editor.Layout.Cell_H)));
      end if;

      if Cmd.Kind = Editor.Commands.Move_To_Point then
         Editor.Focus_Management.Clear_Transient_Focus_Owners (S);
         Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
         case Editor.Feature_Panel.Active_Feature (S.Feature_Panel) is
            when Editor.Feature_Panel.Outline_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Outline_Commands.Execute_Outline_Row_Click
                      (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Messages_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Message_Commands.Execute_Message_Row_Click
                      (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Search_Results_Feature
               | Editor.Feature_Panel.Diagnostics_Feature =>
               if Row /= 0
                 and then Editor.Feature_Panel.Projection_Row_Index_Is_Valid
                   (S.Feature_Panel, Row)
                 and then Editor.Feature_Panel.Row_Is_Selectable
                   (S.Feature_Panel, Positive (Row))
               then
                  Editor.Feature_Panel.Select_Row
                    (S.Feature_Panel, Row);
                  Editor.Render_Cache.Invalidate_All;
               end if;

            when Editor.Feature_Panel.Unknown_Feature =>
               null;
         end case;
      elsif Cmd.Kind = Editor.Commands.Select_Word_At_Point
        or else Cmd.Kind = Editor.Commands.Select_Line_At_Point
      then
         case Editor.Feature_Panel.Active_Feature (S.Feature_Panel) is
            when Editor.Feature_Panel.Outline_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation
                      (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end;

            when Editor.Feature_Panel.Messages_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Message_Commands.Execute_Message_Row_Activation
                      (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;

            when Editor.Feature_Panel.Search_Results_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Search_Results_Commands
                      .Execute_Search_Result_Row_Activation
                      (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end;

            when Editor.Feature_Panel.Diagnostics_Feature =>
               declare
                  Result : constant Editor.Executor.Command_Execution_Result :=
                    Editor.Executor.Diagnostics_Commands
                      .Execute_Diagnostic_Row_Activation
                        (S, Row, Gen);
                  pragma Unreferenced (Result);
               begin
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end;

            when Editor.Feature_Panel.Unknown_Feature =>
               null;
         end case;
      end if;

      return True;
   end Handle_Feature_Panel_Pointer;

   function Handle_Problems_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Problems.Problems_View_Config :=
        (Enabled_By_Default      => False,
         Header_Height_In_Rows   => 1,
         Row_Height_In_Rows      => 1,
         Show_Header             => True,
         Show_File_Name          => False,
         Show_Severity           => True,
         Show_Row_Column         => True,
         Maximum_Message_Columns => 120);
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Full_Snapshot    : Editor.Problems.Problems_Snapshot;
      Visible_Snapshot : Editor.Problems.Problems_Snapshot;
      Visible_Rows     : Natural := 0;
      Hit              : Editor.Problems.Problems_Hit_Result;
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind)
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        or else Editor.Panels.Active_Bottom_Content (S.Panels)
          /= Editor.Panels.Problems_Content
      then
         return False;
      end if;

      Full_Snapshot := Editor.Problems.Build_Snapshot (S.Diagnostics);
      if Editor.Layout.Cell_H /= 0 then
         Visible_Rows := Panel.Height / Editor.Layout.Cell_H;
         if Visible_Rows > 1 then
            Visible_Rows := Visible_Rows - 1;
         end if;
      end if;
      Visible_Snapshot := Editor.Problems.Visible_Snapshot
        (Full_Snapshot, S.Problems_View, Visible_Rows);

      Hit := Editor.Problems.Hit_Test
        (Panel_Rect  => Panel,
         Config      => Config,
         Snapshot    => Visible_Snapshot,
         Cell_Height => Editor.Layout.Cell_H,
         X           => Integer (Cmd.Click_X),
         Y           => Integer (Cmd.Click_Y));

      if Hit.Zone /= Editor.Problems.Outside_Problems then
         Pointer_State.Set_Minimap_Drag_Active (False);
         Pointer_State.Clear_Scrollbar_Drag;
         Pointer_State.Clear_Gutter_Line_Selection;
         Editor.State.Clear_Gutter_Marker_Hover (S);

         if Cmd.Kind = Editor.Commands.Move_To_Point then
            Editor.Focus_Management.Set_Focus_Owner
              (S, Editor.Focus_Management.Focus_Diagnostics);
         end if;

         if Cmd.Kind = Editor.Commands.Move_To_Point
           and then Hit.Zone = Editor.Problems.Problems_Row_Zone
           and then Hit.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic
         then
            declare
               Found : Boolean := False;
               Row   : constant Natural :=
                 Editor.Problems.Row_For_Diagnostic
                   (Full_Snapshot, Hit.Diagnostic_Index, Found);
            begin
               if Found then
                  Editor.Problems.Set_Selected_Row_Index
                    (S.Problems_View, Row);
               end if;
            end;
            Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic
              (S, Hit.Diagnostic_Index);
            Editor.Focus_Management.Restore_Focus_To_Editor (S);
         elsif Cmd.Kind = Editor.Commands.Move_To_Point
           and then Hit.Zone = Editor.Problems.Problems_Header_Zone
         then
            declare
               Relative_X : constant Natural :=
                 Natural (Integer'Max (0, Integer (Cmd.Click_X) - Panel.X));
               Action : constant Editor.Problems.Problems_Header_Action :=
                 Editor.Problems.Header_Action_At_X (Panel.Width, Relative_X);
            begin
               case Action is
                  when Editor.Problems.Problems_Header_Filter_Action =>
                  if Editor.Problems.Severity_Filter
                       (S.Problems_View) =
                     Editor.Problems.Problems_Show_Errors
                  then
                     Execute.all (Editor.Commands.Command_Problems_Filter_All);
                  else
                     Execute.all (Editor.Commands.Command_Problems_Filter_Errors);
                  end if;

                  when Editor.Problems.Problems_Header_Sort_Action =>
                  case S.Problems_View.Sort_Mode is
                     when Editor.Problems.Problems_Sort_By_Location =>
                        Execute.all (Editor.Commands.Command_Problems_Sort_By_Severity);
                     when Editor.Problems.Problems_Sort_By_Severity =>
                        Execute.all (Editor.Commands.Command_Problems_Sort_By_Source);
                     when Editor.Problems.Problems_Sort_By_Source =>
                        Execute.all (Editor.Commands.Command_Problems_Sort_By_Location);
                  end case;

                  when Editor.Problems.Problems_Header_Group_Action =>
                  case S.Problems_View.Group_Mode is
                     when Editor.Problems.Problems_Group_By_Severity =>
                        Execute.all (Editor.Commands.Command_Problems_Group_By_Source);
                     when Editor.Problems.Problems_Group_By_Source =>
                        Execute.all (Editor.Commands.Command_Problems_Group_By_Severity);
                  end case;
               end case;
            end;
         end if;

         return True;
      end if;

      return False;
   end Handle_Problems_Panel_Pointer;

end Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers;
