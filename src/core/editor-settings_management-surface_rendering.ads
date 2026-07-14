with Editor.Layout;
with Editor.Render_Packet;
with Editor.Settings_Management;
with Guikit.Draw;

package Editor.Settings_Management.Surface_Rendering is

   procedure Build_Frame
     (Snapshot          : Editor.Settings_Management.Settings_Surface_Snapshot;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Rectangles        : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Settings_Management.Settings_Surface_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_H         : Positive);

end Editor.Settings_Management.Surface_Rendering;
