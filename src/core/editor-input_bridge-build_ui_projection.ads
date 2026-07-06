with Editor.Build_UI;
with Editor.Build_UI_Panel_Layout;
with Editor.State;

package Editor.Input_Bridge.Build_UI_Projection is

   type Build_UI_Panel_Input_Projection is record
      Snapshot                   : Editor.Build_UI.Build_UI_Render_Snapshot;
      Action_Count               : Natural := 0;
      Suppressed_Count           : Natural := 0;
      Displayed_Suppressed_Count : Natural := 0;
      Suppressed_Top_Row         : Natural := 1;
      Geometry                   : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry;
      Visible_Rows               : Natural := 0;
      Visible_Action_Rows        : Natural := 0;
      Action_Top_Row             : Natural := 1;
   end record;

   function Current
     (S : Editor.State.State_Type) return Build_UI_Panel_Input_Projection;

end Editor.Input_Bridge.Build_UI_Projection;
