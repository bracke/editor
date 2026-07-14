with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Bookmarks;
with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Panels;
with Guikit.Draw;
with Guikit.List_Panel;

package body Editor.Bookmarks.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   function Line_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Line_Image;

   function Row_Text (Row : Editor.Bookmarks.Bookmark_Row) return String is
      Location : constant String :=
        To_String (Row.File_Display_Path) & ":" & Line_Image (Row.Line_Number) &
        (if Row.Has_Column then ":" & Line_Image (Row.Column) else "");
      Markers : constant String :=
        (if Row.Is_Open then " [open]" else "") &
        (if Row.Is_Active then " [active]" else "") &
        (if Row.Is_Dirty then " [dirty]" else "");
   begin
      return (if Row.Is_Selected then "> " else "  ") & Location & Markers;
   end Row_Text;

   procedure Build_Frame
     (Snapshot          : Editor.Render_Model.Render_Snapshot;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_W            : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles    : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Width : constant Float := Float'Min (320.0, Float (Viewport_Width));
      X : constant Float := Float (Viewport_Width) - Width;
      Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout_Config));
      H : constant Float := Float (Editor.Layout.Text_Viewport_Height (Layout_Config, Viewport_Height));
      Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
      Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Texts      : Guikit.Draw.Text_Command_Vectors.Vector;
      Config : constant Guikit.List_Panel.List_Panel_Configuration :=
        (Title               => To_Unbounded_String ("Bookmarks"),
         Empty_State         => To_Unbounded_String (To_String (Snapshot.Bookmark_Empty_Message)),
         Line_Height         => Cell_H,
         Text_Padding        => Cell_W,
         Show_Alternate_Rows => True);
   begin
      Background_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Bookmarks_Visible and then Width > 0.0 and then H > 0.0;
      if not Visible then
         return;
      end if;

      for I in 1 .. Natural (Snapshot.Bookmark_Rows.Length) loop
         declare
            Row : constant Editor.Bookmarks.Bookmark_Row := Snapshot.Bookmark_Rows (Positive (I));
         begin
            Rows.Append
              (Guikit.List_Panel.List_Panel_Row'
                 (Label            => To_Unbounded_String (Row_Text (Row)),
                  Detail           => Null_Unbounded_String,
                  Shortcut         => Null_Unbounded_String,
                  Selected         => Row.Is_Selected,
                  Enabled          => True,
                  Label_Color      => Guikit.Draw.Text_Color,
                  Has_Background   => False,
                  Background_Color => Guikit.Draw.Pane_Color,
                  Accent_Color     => Guikit.Draw.Border_Color,
                  Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
         end;
      end loop;

      Guikit.List_Panel.Draw_Frame
        (Rectangles    => Rectangles,
         Text          => Texts,
         Accessibility => Accessibility,
         Clip_Width    => Viewport_Width,
         Clip_Height   => Viewport_Height,
         Region_X      => Natural (Float'Floor (X)),
         Region_Y      => Natural (Float'Floor (Y)),
         Region_Width  => Natural (Width),
         Region_Height => Natural (H),
         Config        => Config,
         Rows          => Rows);

      for R of Rectangles loop
         Row_Rectangles.Append (R);
      end loop;
      for T of Texts loop
         Text.Append (T);
      end loop;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Rows          : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Snapshot              => Snapshot,
         Layout_Config         => Layout_Config,
         Viewport_Width        => Viewport_Width,
         Viewport_Height       => Viewport_Height,
         Cell_W                => Cell_W,
         Cell_H                => Cell_H,
         Visible               => Visible,
         Background_Rectangles => Background,
         Row_Rectangles        => Rows,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Text_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Bookmarks.Surface_Rendering;
