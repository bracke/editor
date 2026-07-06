with Editor.Build_UI_Actions;
with Editor.Feature_Diagnostics;
with Editor.Layout;
with Editor.View;

package body Editor.Input_Bridge.Build_UI_Projection is

   function Current
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
   end Current;

end Editor.Input_Bridge.Build_UI_Projection;
