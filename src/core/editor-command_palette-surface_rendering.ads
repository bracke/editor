with Editor.Command_Palette;
with Editor.Render_Packet;
with Editor.State;
with Guikit.Command_Palette;
with Guikit.Draw;

package Editor.Command_Palette.Surface_Rendering is

   procedure Build_Frame
     (Palette        : Editor.Command_Palette.Palette_State;
      State          : Editor.State.State_Type;
      Config         : Editor.Command_Palette.Command_Palette_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Layout_Origin_X : Natural;
      Layout_Origin_Y : Natural;
      Status_Bar_Y   : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Icons          : out Guikit.Draw.Icon_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Palette        : Editor.Command_Palette.Palette_State;
      State          : Editor.State.State_Type;
      Config         : Editor.Command_Palette.Command_Palette_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Layout_Origin_X : Natural;
      Layout_Origin_Y : Natural;
      Status_Bar_Y   : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Command_Palette.Surface_Rendering;
