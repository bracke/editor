with Editor.Messages;
with Editor.Render_Packet;
with Editor.Render_Model;
with Guikit.Draw;

package Editor.Messages.Surface_Rendering is

   procedure Build_Frame
     (Snapshot          : Editor.Render_Model.Render_Snapshot;
      Message_Layout    : Editor.Messages.Message_Layout;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Message_Layout : Editor.Messages.Message_Layout);

end Editor.Messages.Surface_Rendering;
