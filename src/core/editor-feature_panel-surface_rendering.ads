with Editor.Feature_Panel;
with Editor.Layout;
with Editor.Render_Packet;
with Guikit.Draw;

package Editor.Feature_Panel.Surface_Rendering is

   procedure Build_Frame
     (Panel          : Editor.Feature_Panel.Feature_Panel_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Panel          : Editor.Feature_Panel.Feature_Panel_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Feature_Panel.Surface_Rendering;
