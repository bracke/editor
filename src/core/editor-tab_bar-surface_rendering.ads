with Editor.Layout;
with Editor.Render_Packet;
with Editor.State;
with Guikit.Draw;

package Editor.Tab_Bar.Surface_Rendering is

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Tab_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Inactive_Tab_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Border_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Dirty_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Close_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Inactive_Text         : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility         : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Tab_Bar.Surface_Rendering;
