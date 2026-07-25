with Editor.Render_Model;
with Editor.State;
with Editor.Layout;
with Editor.Messages;
with Editor.Cursor;
with Editor.Minimap;
with Editor.Settings;
with Editor.Line_Numbers;
with Editor.Scrollbars;

package Editor.Render_Packet.Render_Context is

   type Context is record
      Snap   : Editor.Render_Model.Render_Snapshot;
      State  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Cell_W : Positive := 1;
      Cell_H : Positive := 1;
      Message_Layout : Editor.Messages.Message_Layout;
      Scroll_X : Natural := 0;
      Cursor_Config : Editor.Cursor.Cursor_Config;
      Minimap : Editor.Minimap.Minimap_Config;
      Settings : Editor.Settings.Settings_State;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config;
      Scrollbars : Editor.Scrollbars.Scrollbar_Config;
      Effective_Viewport_W : Natural := 0;
      Effective_Viewport_H : Natural := 0;
      Effective_Minimap_Enabled : Boolean := False;
   end record;

   function Create return Context;

   procedure Refresh (Value : in out Context);

end Editor.Render_Packet.Render_Context;
