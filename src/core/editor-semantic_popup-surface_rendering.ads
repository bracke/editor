with Editor.Layout;
with Editor.State;
with Editor.Render_Packet;
with Guikit.Draw;

package Editor.Semantic_Popup.Surface_Rendering is

   procedure Build_Frame
     (Popup             : Editor.State.Semantic_Popup_State;
      Anchor_X          : Float;
      Anchor_Y          : Float;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_W            : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles    : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Popup          : Editor.State.Semantic_Popup_State;
      Anchor_X       : Float;
      Anchor_Y       : Float;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Semantic_Popup.Surface_Rendering;
