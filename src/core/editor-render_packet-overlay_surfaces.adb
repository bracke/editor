with Editor.Active_Find_Prompt.Surface_Rendering;
with Editor.Buffer_Switcher.Surface_Rendering;
with Editor.Command_Palette;
with Editor.Command_Palette.Surface_Rendering;
with Editor.Go_To_Line.Surface_Rendering;
with Editor.Guided_Prompts.Surface_Rendering;
with Editor.Keybinding_Management;
with Editor.Keybinding_Management.Surface_Projection;
with Editor.Keybinding_Management.Surface_Rendering;
with Editor.Layout;
with Guikit.Draw;
with Editor.Input_Bridge;
with Editor.Render_Model;
with Editor.Messages;
with Editor.Messages.Surface_Rendering;
with Editor.Project_Search_Bar.Surface_Rendering;
with Editor.Quick_Open.Surface_Rendering;
with Editor.Render_Packet.Geometry;
with Editor.Render_Packet.Render_Context;
with Editor.Semantic_Popup.Surface_Rendering;
with Editor.Settings_Management.Surface_Rendering;
with Editor.State;
with Editor.View;

package body Editor.Render_Packet.Overlay_Surfaces is

   use Editor.Render_Packet.Geometry;

   procedure Render
     (Packet : in out Render_Packet;
      Context : Editor.Render_Packet.Render_Context.Context)
   is
      Snap   : Editor.Render_Model.Render_Snapshot renames Context.Snap;
      S      : Editor.State.State_Type renames Context.State;
      Layout : Editor.Layout.Layout_Config renames Context.Layout;
      Cell_W : Positive renames Context.Cell_W;
      Cell_H : Positive renames Context.Cell_H;
      Message_Layout : Editor.Messages.Message_Layout renames Context.Message_Layout;
      Out_Packet : Render_Packet renames Packet;
      procedure Push_Active_Find_Prompt
        (Packet : in out Render_Packet)
      is
      begin
         Editor.Active_Find_Prompt.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end Push_Active_Find_Prompt;

      procedure Push_Guided_Prompt
        (Packet : in out Render_Packet)
      is
      begin
         Editor.Guided_Prompts.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            Snapshot       => Snap.Guided_Prompt,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end Push_Guided_Prompt;
   begin
      declare
         Popup : constant Editor.State.Semantic_Popup_State := Snap.Semantic_Popup;
         Anchor_Segment : constant Natural :=
           Segment_For_Caret (Context, Popup.Anchor_Row, Popup.Anchor_Column);
         Anchor_X : constant Float :=
           (if Anchor_Segment > 0
            then Screen_X
              (Context,
               Screen_Col_For
                 (Context, Snap.Visible_Visual_Rows (Anchor_Segment), Popup.Anchor_Column))
            else Float (Editor.Layout.Editor_Body_Rect
              (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height).X + Cell_W));
         Anchor_Y : constant Float :=
           (if Anchor_Segment > 0
            then Screen_Y (Context, Anchor_Segment - 1) + Float (Cell_H)
            else Float (Editor.Layout.Editor_Body_Rect
              (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height).Y + Cell_H));
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Row_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Semantic_Popup.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Popup          => Popup,
            Anchor_X       => Anchor_X,
            Anchor_Y       => Anchor_Y,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      Push_Active_Find_Prompt (Out_Packet);

      Push_Guided_Prompt (Out_Packet);

      declare
         Search_Visible : Boolean := False;
         Search_Background : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Field : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Caret : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Search_Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Project_Search_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
      begin
         Editor.Go_To_Line.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Field_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Result_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Caret_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Quick_Open.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;
      declare
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Field_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Result_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Caret_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Buffer_Switcher.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
      begin
         Editor.Messages.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap,
            Message_Layout => Message_Layout);
      end;

      declare
      begin
         Editor.Settings_Management.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap.Settings_UI,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_H         => Cell_H);
      end;
      declare
         Palette : constant Editor.Command_Palette.Palette_State :=
           Editor.Command_Palette.Current;
         S_State : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Command_Palette.Command_Palette_Config :=
           Editor.Command_Palette.Current_Config;
      begin
         Editor.Command_Palette.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Palette        => Palette,
            State          => S_State,
            Config         => Config,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Layout_Origin_X => Layout.Origin_X,
            Layout_Origin_Y => Layout.Origin_Y,
            Status_Bar_Y    =>
              Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height)),
            Cell_W          => Cell_W,
            Cell_H          => Cell_H);
      end;

      declare
         Surface : constant Editor.Keybinding_Management.Keybinding_Surface_Snapshot :=
           Snap.Keybindings_UI;
         Text_Columns : constant Natural :=
           (if Cell_W = 0 or else Editor.View.Viewport_Width = 0 then 0
            else
              (if Natural'Min (420, Editor.View.Viewport_Width) / Cell_W > 2
               then Natural'Min (420, Editor.View.Viewport_Width) / Cell_W - 2
               else 0));
         Projection : constant
           Editor.Keybinding_Management.Surface_Projection.Keybinding_Surface_Render_Projection :=
           Editor.Keybinding_Management.Surface_Projection.Project
             (Surface, Text_Columns);
      begin
         Editor.Keybinding_Management.Surface_Rendering.Build_Packet
           (Packet          => Out_Packet,
            Surface         => Surface,
            Projection      => Projection,
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Text_Viewport_Y => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
            Cell_W          => Cell_W,
            Cell_H          => Cell_H);
      end;
   end Render;

end Editor.Render_Packet.Overlay_Surfaces;
