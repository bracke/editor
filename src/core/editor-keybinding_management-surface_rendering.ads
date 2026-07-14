with Editor.Render_Packet;
with Guikit.Draw;
with Editor.Keybinding_Management.Surface_Projection;

package Editor.Keybinding_Management.Surface_Rendering is

   procedure Build_Frame
     (Surface        : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Projection     : Editor.Keybinding_Management.Surface_Projection.Keybinding_Surface_Render_Projection;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Text_Viewport_Y : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Tooltips       : out Guikit.Draw.Tooltip_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Surface        : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Projection     : Editor.Keybinding_Management.Surface_Projection.Keybinding_Surface_Render_Projection;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Text_Viewport_Y : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Keybinding_Management.Surface_Rendering;
