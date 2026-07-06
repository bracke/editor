with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Cursor;
with Editor.Feature_Diagnostics;
with Editor.Layout;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Displayed_Suppressed_Row_Count
     (S : Editor.State.State_Type) return Natural
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
   begin
      return Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
        (Text_Viewport_Height => Text_Viewport_Height,
         Cell_H               => Editor.Layout.Cell_H,
         Action_Count         => Action_Count,
         Suppressed_Count     => Suppressed_Count);
   end Displayed_Suppressed_Row_Count;

   function Handle_Suppressed_Diagnostics_Key
     (S           : in out Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Report_Info : not null access procedure (Text : String)) return Boolean
   is
      Displayed_Count : Natural;
   begin
      if not S.Build_UI.Build_UI_Focused or else not Chord.Modifiers.Ctrl then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Down =>
            Displayed_Count := Displayed_Suppressed_Row_Count (S);
            Editor.Feature_Diagnostics.Select_Next_Suppressed_Diagnostic
              (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
              (S.Feature_Diagnostics, Displayed_Count);
         when Editor.Keybindings.Key_Up =>
            Displayed_Count := Displayed_Suppressed_Row_Count (S);
            Editor.Feature_Diagnostics.Select_Previous_Suppressed_Diagnostic
              (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Ensure_Selected_Suppressed_Diagnostic_Visible
              (S.Feature_Diagnostics, Displayed_Count);
         when Editor.Keybindings.Key_Enter =>
            if Editor.Feature_Diagnostics.Restore_Selected_Suppressed_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               Report_Info ("Selected suppressed diagnostic restored.");
            else
               Report_Info ("No suppressed diagnostic selected.");
            end if;
         when Editor.Keybindings.Key_Delete =>
            declare
               Cleared : constant Natural :=
                 Editor.Feature_Diagnostics.Clear_Suppressed_Diagnostics
                   (S.Feature_Diagnostics);
            begin
               if Cleared = 0 then
                  Report_Info ("No suppressed diagnostics.");
               else
                  Report_Info ("Suppressed diagnostics cleared.");
               end if;
            end;
         when others =>
            return False;
      end case;

      Editor.Render_Cache.Invalidate_All;
      Notify_Input;
      return True;
   end Handle_Suppressed_Diagnostics_Key;

end Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers;
