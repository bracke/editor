with Editor.Render_Packet;
with Editor.Render_Layers;
with Guikit.Draw;
with Guikit.Item_Grid;

package Editor.Render_Packet.Guikit_Adapters is

   procedure Push_Guikit_Rectangle
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Rect   : Guikit.Draw.Rectangle_Command);

   procedure Push_Guikit_Text
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Cmd    : Guikit.Draw.Text_Command);

   procedure Push_Item_Grid_Background
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Clip_Width  : Natural;
      Clip_Height : Natural;
      X, Y, W, H  : Float;
      Kind        : Guikit.Item_Grid.Background_Kind);

end Editor.Render_Packet.Guikit_Adapters;
