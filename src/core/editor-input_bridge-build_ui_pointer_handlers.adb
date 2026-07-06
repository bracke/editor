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
with Editor.Input_Bridge.Build_UI_Projection;

package body Editor.Input_Bridge.Build_UI_Pointer_Handlers is

   use type Editor.Build_UI_Panel_Layout.Build_UI_Panel_Zone;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;

   function Handle_Build_UI_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access;
      Report  : Report_Info_Access) return Boolean
   is
      Projection : constant Editor.Input_Bridge.Build_UI_Projection.Build_UI_Panel_Input_Projection :=
        Editor.Input_Bridge.Build_UI_Projection.Current (S);
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
