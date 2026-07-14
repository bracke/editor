with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Render_Model;
with Editor.Render_Packet;

package Editor.Gutter.Surface_Rendering is

   procedure Push_Gutter_Line_Number
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural;
      Current_Row   : Natural;
      Is_Current    : Boolean;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config);

   procedure Push_Fold_Marker
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural);

   procedure Push_Gutter_Marker
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural);

   procedure Push_Folded_Ellipsis
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Text_Viewport_Right : Float;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural;
      Start_Col     : Natural);

end Editor.Gutter.Surface_Rendering;
