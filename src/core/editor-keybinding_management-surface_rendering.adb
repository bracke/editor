with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.List_Panel;
with Guikit.Segmented;

package body Editor.Keybinding_Management.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

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
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Width : constant Float := Float'Min (420.0, Float (Viewport_Width));
      X : constant Float := Float (Viewport_Width) - Width;
      Y : constant Float := Float (Text_Viewport_Y);
      H : constant Float := Float (Viewport_Height);
      Text_X : constant Float := X + Float (Cell_W);
      Filter_X : constant Natural := Natural (Float'Floor (X)) + 14 * Cell_W;
      Filter_W : constant Natural :=
        (if Natural (Float'Floor (Width)) > 16 * Cell_W
         then Natural (Float'Floor (Width)) - 16 * Cell_W
         else 0);
      Row_Start_Y : constant Float := Y + Float (2 * Cell_H);
      Row_Height : constant Natural :=
        (if H > Float (2 * Cell_H) then Natural (H - Float (2 * Cell_H)) else 0);
      Config : constant Guikit.List_Panel.List_Panel_Configuration :=
        (Title               => Null_Unbounded_String,
         Empty_State         => Null_Unbounded_String,
         Line_Height         => Cell_H,
         Text_Padding        => Cell_W,
         Show_Alternate_Rows => True);
      Rows : constant Guikit.List_Panel.List_Panel_Row_Vectors.Vector :=
        Projection.Command_Rows;
      Chord_Rows : constant Guikit.List_Panel.List_Panel_Row_Vectors.Vector :=
        Projection.Chord_Rows;
   begin
      Rectangles.Clear;
      Text.Clear;
      Tooltips.Clear;
      Accessibility.Clear;
      Visible := Surface.Visible;
      if not Surface.Visible then
         return;
      end if;

      Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Natural (Float'Floor (X)),
            Y      => Natural (Float'Floor (Y)),
            Width  => Natural (Width),
            Height => Natural (H),
            Color  => Guikit.Draw.Pane_Color));
      Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Natural (Float'Floor (X)),
            Y      => Natural (Float'Floor (Y)),
            Width  => Natural (Width),
            Height => Cell_H,
            Color  => Guikit.Draw.Border_Color));
      Text.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (Text_X)),
            Y => Natural (Float'Floor (Y)),
            Width => 0,
            Height => 0,
            Text => To_Unbounded_String ("Keybindings"),
            Color => Guikit.Draw.Text_Color,
            others => <>));

      if Filter_W > 0 then
         Guikit.Segmented.Build_Frame
           (Segments      => Projection.Segments,
            Active        => Projection.Filter_Index,
            Region_X      => Filter_X,
            Region_Y      => Natural (Float'Floor (Y)),
            Region_Width  => Filter_W,
            Region_Height => Cell_H,
            Clip_Width    => Viewport_Width,
            Clip_Height   => Viewport_Height,
            Line_Height   => Cell_H,
            Hover_X       => -1,
            Hover_Y       => -1,
            Rectangles    => Rectangles,
            Text          => Text,
            Tooltips      => Tooltips,
            Accessibility => Accessibility);
      end if;

      if Length (Projection.Status_Line) > 0 then
         Text.Append
           (Guikit.Draw.Text_Command'
              (X => Natural (Float'Floor (Text_X)),
               Y => Natural (Float'Floor (Y + Float (Cell_H))),
               Width => 0,
               Height => 0,
               Text => Projection.Status_Line,
               Color => Guikit.Draw.Text_Color,
               others => <>));
      end if;

      if Row_Height > 0 then
         Guikit.List_Panel.Draw_Frame
           (Rectangles    => Rectangles,
            Text          => Text,
            Accessibility => Accessibility,
            Clip_Width    => Viewport_Width,
            Clip_Height   => Viewport_Height,
            Region_X      => Natural (Float'Floor (X)),
            Region_Y      => Natural (Float'Floor (Row_Start_Y)),
            Region_Width  => Natural (Width),
            Region_Height => Row_Height,
            Config        => Config,
            Rows          => Rows);

         if Chord_Rows.Length > 0 then
            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Rectangles,
               Text          => Text,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Float'Floor (X)),
               Region_Y      => Natural (Float'Floor (Row_Start_Y)),
               Region_Width  => Natural (Width),
               Region_Height => Row_Height,
               Config        => Config,
               Rows          => Chord_Rows);
         end if;
      end if;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Surface        : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Projection     : Editor.Keybinding_Management.Surface_Projection.Keybinding_Surface_Render_Projection;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Text_Viewport_Y : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Rectangles    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Tooltips      : Guikit.Draw.Tooltip_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Surface         => Surface,
         Projection      => Projection,
         Viewport_Width  => Viewport_Width,
         Viewport_Height => Viewport_Height,
         Text_Viewport_Y => Text_Viewport_Y,
         Cell_W          => Cell_W,
         Cell_H          => Cell_H,
         Visible         => Visible,
         Rectangles      => Rectangles,
         Text            => Text,
         Tooltips        => Tooltips,
         Accessibility   => Accessibility);

      if Visible then
         for R of Rectangles loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Keybinding_Management.Surface_Rendering;
