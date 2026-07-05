with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Command_Execution;
with Editor.Feature_Diagnostics;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Build_UI_Pointer_Handlers is

   use type Editor.Build_UI_Panel_Layout.Build_UI_Panel_Zone;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;

   type Build_UI_Panel_Input_Projection is record
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Action_Count : Natural := 0;
      Suppressed_Count : Natural := 0;
      Displayed_Suppressed_Count : Natural := 0;
      Suppressed_Top_Row : Natural := 1;
      Geometry : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry;
      Visible_Rows : Natural := 0;
      Visible_Action_Rows : Natural := 0;
      Action_Top_Row : Natural := 1;
   end record;

   function Current_Build_UI_Panel_Input_Projection
     (S : Editor.State.State_Type) return Build_UI_Panel_Input_Projection
   is
      Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Action_Count : constant Natural := Natural (Snapshot.Actions.Length);
      Suppressed_Count : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
          (S.Feature_Diagnostics);
      Text_Viewport_Height : constant Natural :=
        Editor.Layout.Text_Viewport_Height
          (Layout_Config, Editor.View.Viewport_Height);
      Displayed_Suppressed_Count : constant Natural :=
        Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
          (Text_Viewport_Height => Text_Viewport_Height,
           Cell_H               => Editor.Layout.Cell_H,
           Action_Count         => Action_Count,
           Suppressed_Count     => Suppressed_Count);
      Suppressed_Top_Row : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Top_Row
          (S.Feature_Diagnostics, Displayed_Suppressed_Count);
      Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
        Editor.Build_UI_Panel_Layout.Layout
          (Viewport_Width       => Editor.View.Viewport_Width,
           Text_Viewport_Y      => Natural (Editor.Layout.Text_Viewport_Y (Layout_Config)),
           Text_Viewport_Height => Text_Viewport_Height,
           Cell_H               => Editor.Layout.Cell_H,
           Action_Count         => Action_Count,
           Suppressed_Count     => Displayed_Suppressed_Count);
      Visible_Rows : constant Natural :=
        Editor.Build_UI_Panel_Layout.Visible_Row_Count
          (Geometry, Editor.Layout.Cell_H);
      Visible_Action_Rows : constant Natural :=
        (if Visible_Rows > Geometry.Action_Start_Row
         then Natural'Min (Action_Count, Visible_Rows - Geometry.Action_Start_Row)
         else 0);
      Action_Top_Row : constant Natural :=
        Editor.Build_UI.Action_Top_Row
          (S.Build_UI, Action_Count, Visible_Action_Rows);
   begin
      return
        (Snapshot                   => Snapshot,
         Action_Count               => Action_Count,
         Suppressed_Count           => Suppressed_Count,
         Displayed_Suppressed_Count => Displayed_Suppressed_Count,
         Suppressed_Top_Row         => Suppressed_Top_Row,
         Geometry                   => Geometry,
         Visible_Rows               => Visible_Rows,
         Visible_Action_Rows        => Visible_Action_Rows,
         Action_Top_Row             => Action_Top_Row);
   end Current_Build_UI_Panel_Input_Projection;

   function Handle_Build_UI_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access;
      Report  : Report_Info_Access) return Boolean
   is
      Projection : constant Build_UI_Panel_Input_Projection :=
        Current_Build_UI_Panel_Input_Projection (S);
      Hit : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Hit;
   begin
      if Cmd.Kind /= Editor.Commands.Move_To_Point
        and then Cmd.Kind /= Editor.Commands.Pointer_Hover
      then
         return False;
      end if;

      if not Projection.Snapshot.Visible then
         return False;
      end if;

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Projection.Geometry, Editor.Layout.Cell_H,
         Integer (Cmd.Click_X), Integer (Cmd.Click_Y));

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Outside_Build_UI_Panel then
         return False;
      end if;

      Pointer_State.Reset_All;
      Editor.State.Clear_Gutter_Marker_Hover (S);

      if Cmd.Kind = Editor.Commands.Pointer_Hover then
         return True;
      end if;

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Action_Row
        and then Hit.Row in 1 .. Projection.Visible_Action_Rows
      then
         declare
            Action_Row : constant Natural := Projection.Action_Top_Row + Hit.Row - 1;
            Action : constant Editor.Build_UI.Build_UI_Action_Row :=
              Projection.Snapshot.Actions.Element (Action_Row - 1);
            Found : Boolean := False;
            Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
            Reason : constant String := To_String (Action.Disabled_Reason);
         begin
            Editor.Build_UI.Set_Selected_Action_Row
              (S.Build_UI, Action_Row, Projection.Action_Count);

            if not Action.Enabled then
               if Reason'Length > 0 then
                  Report.all (Reason);
               else
                  Report.all ("Command unavailable");
               end if;
            else
               Id := Editor.Commands.Command_Id_From_Stable_Name
                 (To_String (Action.Command_Name), Found);
               if Found and then Id /= Editor.Commands.No_Command then
                  if Id = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
                    and then Action.Quick_Fix_Action_Index > 0
                  then
                     declare
                        Result : constant Editor.Command_Execution.Command_Execution_Result :=
                          Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
                            (S,
                             Action.Quick_Fix_Action_Index,
                             Action.Diagnostic_Index);
                        pragma Unreferenced (Result);
                     begin
                        null;
                     end;
                  else
                     Execute.all (Id);
                  end if;
               end if;
            end if;
            Editor.Render_Cache.Invalidate_All;
         end;
      elsif Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Row
        and then Hit.Row in 1 .. Projection.Displayed_Suppressed_Count
      then
         Editor.Feature_Diagnostics.Select_Suppressed_Diagnostic
           (S.Feature_Diagnostics,
            Projection.Suppressed_Top_Row + Hit.Row - 1);
         Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
           (S.Feature_Diagnostics,
            Projection.Displayed_Suppressed_Count);
         Editor.Render_Cache.Invalidate_All;
      end if;

      return True;
   end Handle_Build_UI_Panel_Pointer;

end Editor.Input_Bridge.Build_UI_Pointer_Handlers;
