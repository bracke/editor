with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Messages;
with Editor.View;
with Editor.Cursor;
with Editor.Minimap;
with Editor.Settings;
with Editor.Line_Numbers;
with Editor.Scrollbars;

package body Editor.Render_Packet.Render_Context is

   function Create return Context is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cell_W : constant Positive := Editor.Layout.Cell_W;
      Cell_H : constant Positive := Editor.Layout.Cell_H;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Settings : constant Editor.Settings.Settings_State := Editor.Settings.Current;
      Minimap : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
   begin
      return Result : Context do
         Result.State := Editor.Input_Bridge.Get_State_For_Test;
         Result.Layout := Layout;
         Result.Cell_W := Cell_W;
         Result.Cell_H := Cell_H;
         Result.Message_Layout :=
           (Origin_X     => Layout.Origin_X,
            Origin_Y     => Layout.Origin_Y,
            Cell_W       => Cell_W,
            Cell_H       => Cell_H,
            Status_Bar_Y =>
              Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
         Result.Scroll_X := Editor.View.Scroll_X;
         Result.Cursor_Config := Editor.Cursor.Current;
         Result.Minimap := Minimap;
         Result.Settings := Settings;
         Result.Line_Number_Config := Editor.Line_Numbers.Current;
         Result.Scrollbars := Scrollbars;
         Result.Effective_Viewport_W :=
           Editor.Scrollbars.Effective_Viewport_Width
             (Editor.View.Viewport_Width, Scrollbars);
         Result.Effective_Viewport_H :=
           Editor.Scrollbars.Effective_Viewport_Height
             (Editor.View.Viewport_Height, Scrollbars);
         Result.Effective_Minimap_Enabled :=
           Settings.Show_Minimap and then Minimap.Enabled;
      end return;
   end Create;

   procedure Refresh (Value : in out Context) is
   begin
      Editor.Input_Bridge.Get_Render_Snapshot (Value.Snap);
      Editor.View.Update_Scroll_For_Snapshot (Value.Snap, Value.Layout);
      Value.Scroll_X := Editor.View.Scroll_X;
      Editor.Input_Bridge.Get_Render_Snapshot (Value.Snap);
      Value.Scroll_X := Editor.View.Scroll_X;
      Value.State := Editor.Input_Bridge.Get_State_For_Test;
   end Refresh;

end Editor.Render_Packet.Render_Context;
