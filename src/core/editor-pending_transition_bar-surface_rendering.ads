with Editor.State;
with Editor.Layout;
with Editor.Pending_Transitions;
with Editor.Render_Packet;
with Guikit.Draw;

package Editor.Pending_Transition_Bar.Surface_Rendering is

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Pending        : Editor.Pending_Transitions.Pending_Transition_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Summary_Text   : out Guikit.Draw.Text_Command_Vectors.Vector;
      Action_Text    : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector);

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Pending        : Editor.Pending_Transitions.Pending_Transition_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive);

end Editor.Pending_Transition_Bar.Surface_Rendering;
