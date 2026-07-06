with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Command_Execution;
with Editor.Cursor;
with Editor.Feature_Diagnostics;
with Editor.Layout;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Build_UI_Key_Handlers is

   use type Editor.Commands.Command_Id;
   use type Editor.Keybindings.Key_Code;

   type Build_UI_Panel_Input_Projection is record
      Snapshot                   : Editor.Build_UI.Build_UI_Render_Snapshot;
      Action_Count               : Natural := 0;
      Displayed_Suppressed_Count : Natural := 0;
      Visible_Action_Rows        : Natural := 0;
   end record;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Current_Build_UI_Panel_Input_Projection
     (S : Editor.State.State_Type) return Build_UI_Panel_Input_Projection
   is
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Action_Count : constant Natural := Natural (Snapshot.Actions.Length);
      Layout_Config : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
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
      Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
        Editor.Build_UI_Panel_Layout.Layout
          (Viewport_Width       => Editor.View.Viewport_Width,
           Text_Viewport_Y      =>
             Natural (Editor.Layout.Text_Viewport_Y (Layout_Config)),
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
   begin
      return (Snapshot                   => Snapshot,
              Action_Count               => Action_Count,
              Displayed_Suppressed_Count => Displayed_Suppressed_Count,
              Visible_Action_Rows        => Visible_Action_Rows);
   end Current_Build_UI_Panel_Input_Projection;

   procedure Select_Next_Or_Previous_Action
     (S          : in out Editor.State.State_Type;
      Projection : Build_UI_Panel_Input_Projection;
      Previous   : Boolean)
   is
   begin
      if Previous then
         Editor.Build_UI.Select_Previous_Action_Row
           (S.Build_UI, Projection.Action_Count);
      else
         Editor.Build_UI.Select_Next_Action_Row
           (S.Build_UI, Projection.Action_Count);
      end if;
      Editor.Build_UI.Ensure_Selected_Action_Row_Visible
        (S.Build_UI, Projection.Action_Count, Projection.Visible_Action_Rows);
      Editor.Render_Cache.Invalidate_All;
   end Select_Next_Or_Previous_Action;

   function Handle_Build_UI_Tab_Key
     (S     : in out Editor.State.State_Type;
      Chord : Editor.Keybindings.Key_Chord) return Boolean
   is
      Projection : Build_UI_Panel_Input_Projection;
   begin
      if not S.Build_UI.Build_UI_Focused
        or else Chord.Key /= Editor.Keybindings.Key_Tab
      then
         return False;
      end if;

      Projection := Current_Build_UI_Panel_Input_Projection (S);
      Select_Next_Or_Previous_Action
        (S, Projection, Previous => Chord.Modifiers.Shift);
      Notify_Input;
      return True;
   end Handle_Build_UI_Tab_Key;

   function Handle_Build_UI_Focused_Surface_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Focused_Key_Result
   is
   begin
      if S.Latest_Build_Result_Focused then
         case Chord.Key is
            when Editor.Keybindings.Key_Enter =>
               Execute (Editor.Commands.Command_Build_Output_Details_Focus);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when others =>
               return Build_UI_Key_Not_Handled;
         end case;
      elsif S.Latest_Build_Output_Details.Build_Output_Details_Focused then
         case Chord.Key is
            when Editor.Keybindings.Key_Left =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Stdout);
            when Editor.Keybindings.Key_Right =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Stderr);
            when Editor.Keybindings.Key_Up | Editor.Keybindings.Key_Down =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Merged);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when others =>
               return Build_UI_Key_Not_Handled;
         end case;
      else
         return Build_UI_Not_Focused;
      end if;

      Notify_Input;
      return Build_UI_Key_Handled;
   end Handle_Build_UI_Focused_Surface_Key;

   procedure Activate_Selected_Action
     (S           : in out Editor.State.State_Type;
      Projection  : Build_UI_Panel_Input_Projection;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info : not null access procedure (Text : String))
   is
      Selected : constant Natural :=
        Editor.Build_UI.Selected_Action_Row
          (S.Build_UI, Projection.Action_Count);
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      if Selected = 0 then
         Execute (Editor.Commands.Command_Build_Run);
         return;
      end if;

      declare
         Row : constant Editor.Build_UI.Build_UI_Action_Row :=
           Projection.Snapshot.Actions.Element (Selected - 1);
         Reason : constant String := To_String (Row.Disabled_Reason);
      begin
         if not Row.Enabled then
            if Reason'Length > 0 then
               Report_Info (Reason);
            else
               Report_Info ("Command unavailable");
            end if;
            return;
         end if;

         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Row.Command_Name), Found);

         if Found and then Id /= Editor.Commands.No_Command then
            if Id = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
              and then Row.Quick_Fix_Action_Index > 0
            then
               declare
                  Result : constant Editor.Command_Execution.Command_Execution_Result :=
                    Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
                      (S, Row.Quick_Fix_Action_Index, Row.Diagnostic_Index);
                  pragma Unreferenced (Result);
               begin
                  null;
               end;
            else
               Execute (Id);
            end if;
         end if;
      end;
   end Activate_Selected_Action;

   function Handle_Build_UI_Key
     (S           : in out Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info : not null access procedure (Text : String)) return Boolean
   is
      Projection : Build_UI_Panel_Input_Projection;
   begin
      if S.Build_UI.Build_UI_Focused then
         Projection := Current_Build_UI_Panel_Input_Projection (S);

         if Chord.Modifiers.Ctrl
           and then Chord.Key = Editor.Keybindings.Key_Down
         then
            Editor.Feature_Diagnostics.Select_Next_Suppressed_Diagnostic
              (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
              (S.Feature_Diagnostics, Projection.Displayed_Suppressed_Count);
            Editor.Render_Cache.Invalidate_All;
         elsif Chord.Modifiers.Ctrl
           and then Chord.Key = Editor.Keybindings.Key_Up
         then
            Editor.Feature_Diagnostics.Select_Previous_Suppressed_Diagnostic
              (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
              (S.Feature_Diagnostics, Projection.Displayed_Suppressed_Count);
            Editor.Render_Cache.Invalidate_All;
         elsif Chord.Modifiers.Ctrl
           and then Chord.Key = Editor.Keybindings.Key_Enter
         then
            Execute (Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed);
         elsif Chord.Modifiers.Ctrl
           and then Chord.Key = Editor.Keybindings.Key_Delete
         then
            Execute (Editor.Commands.Command_Diagnostic_Clear_Suppressed);
         else
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute (Editor.Commands.Command_Build_Select_Previous_Candidate);
               when Editor.Keybindings.Key_Down =>
                  Execute (Editor.Commands.Command_Build_Select_Next_Candidate);
               when Editor.Keybindings.Key_Tab =>
                  Select_Next_Or_Previous_Action
                    (S, Projection, Previous => Chord.Modifiers.Shift);
               when Editor.Keybindings.Key_Enter =>
                  Activate_Selected_Action
                    (S, Projection, Execute, Report_Info);
               when Editor.Keybindings.Key_Escape =>
                  Execute (Editor.Commands.Command_Focus_Editor_Text);
               when Editor.Keybindings.Key_Delete =>
                  Execute (Editor.Commands.Command_Build_Clear_Selected_Candidate);
               when others =>
                  null;
            end case;
         end if;
      elsif S.Latest_Build_Result_Focused then
         case Chord.Key is
            when Editor.Keybindings.Key_Enter =>
               Execute (Editor.Commands.Command_Build_Output_Details_Focus);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when others =>
               null;
         end case;
      elsif S.Latest_Build_Output_Details.Build_Output_Details_Focused then
         case Chord.Key is
            when Editor.Keybindings.Key_Left =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Stdout);
            when Editor.Keybindings.Key_Right =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Stderr);
            when Editor.Keybindings.Key_Up | Editor.Keybindings.Key_Down =>
               Execute (Editor.Commands.Command_Build_Output_Details_Select_Merged);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when others =>
               null;
         end case;
      else
         return False;
      end if;

      Notify_Input;
      return True;
   end Handle_Build_UI_Key;

end Editor.Input_Bridge.Build_UI_Key_Handlers;
