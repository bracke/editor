with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Input_Field;
with Editor.Overlay_Focus;
with Editor.Quick_Open;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Draw;
with Guikit.Widgets;

use type Editor.Overlay_Focus.Overlay_Target;

package body Editor.Go_To_Line.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   procedure Push_Text
     (Texts  : in out Guikit.Draw.Text_Command_Vectors.Vector;
      Text   : String;
      X      : Float;
      Y      : Float;
      Color  : Guikit.Draw.Render_Color)
   is
   begin
      Texts.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => 0,
            Height => 0,
            Text => To_Unbounded_String (Text),
            Color => Color,
            others => <>));
   end Push_Text;

   procedure Push_Field_Selection
     (Snap   : Editor.Input_Field.Field_Snapshot;
      Cell_W : Natural;
      Cell_H : Positive;
      X      : Float;
      Y      : Float;
      Rectangles : in out Guikit.Draw.Rectangle_Command_Vectors.Vector)
   is
      Visible_Count : constant Natural := Natural (Length (Snap.Visible_Text));
      Visible_First : constant Natural := Snap.First_Visible_Column;
      Visible_Last  : constant Natural := Visible_First + Visible_Count;
      A : Natural := Snap.Selection_Start;
      B : Natural := Snap.Selection_End;
   begin
      if not Snap.Has_Selection or else Visible_Count = 0 then
         return;
      end if;

      if A < Visible_First then
         A := Visible_First;
      end if;
      if B > Visible_Last then
         B := Visible_Last;
      end if;

      if B > A then
         Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Float'Floor (X + Float ((A - Visible_First) * Cell_W))),
               Y      => Natural (Float'Floor (Y)),
               Width  => Natural ((B - A) * Cell_W),
               Height => Natural (Cell_H),
               Color  => Guikit.Draw.Selection_Color));
      end if;
   end Push_Field_Selection;

   function Truncate_Right
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Text'Length <= Columns then
         return Text;
      elsif Columns <= 3 then
         return Text (Text'First .. Text'First + Columns - 1);
      else
         return Text (Text'First .. Text'First + Columns - 4) & "...";
      end if;
   end Truncate_Right;

   procedure Build_Frame
     (Snapshot          : Editor.Render_Model.Render_Snapshot;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_W            : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      G_X : constant Integer :=
        Message_Body.X + Integer'Max (0, (Message_Body.Width - Integer (32 * Cell_W)) / 2);
      G_Y : constant Integer := Message_Body.Y + Integer (Cell_H);
      Width : constant Natural :=
        Natural'Max (8, Natural'Min (Natural'Max (Message_Body.Width / Cell_W, 1), 32));
      Text_Cols : constant Natural :=
        (if Width > 2 then Width - 2 else 1);
      Text_X : constant Float := Float (G_X + Integer (Cell_W));
      Field_Y : constant Float := Float (G_Y + Integer (Cell_H));
      Error_Y : constant Float := Float (G_Y + Integer (2 * Cell_H));
      Active : constant Boolean :=
        Snapshot.Active_Overlay = Editor.Overlay_Focus.Go_To_Line_Overlay;
      Field_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Snapshot.Goto_Line_Field;
      Error_Text : constant String :=
        To_String (Snapshot.Goto_Line_Error_Message);
   begin
      Background_Rectangles.Clear;
      Field_Rectangles.Clear;
      Caret_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Goto_Line_Visible
        and then G_X >= 0
        and then Viewport_Width > 0
        and then Viewport_Height > 0;
      if not Visible then
         return;
      end if;

      declare
         Panel_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Menu_Panel
           (Panel_Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => G_X,
            Y            => G_Y,
            Width        => Width * Cell_W,
            Height       => 3 * Cell_H,
            Fill_Color   => Guikit.Draw.Pane_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Panel_Rectangles loop
            Background_Rectangles.Append (R);
         end loop;
      end;

      Push_Text
        (Text, "Go to Line",
         Text_X, Float (G_Y),
         Guikit.Draw.Text_Color);
      Field_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Natural (Float'Floor (Text_X)),
            Y      => Natural (Float'Floor (Field_Y)),
            Width  => Natural ((Width - 2) * Cell_W),
            Height => Cell_H,
            Color  => Guikit.Draw.Input_Color));
      Push_Field_Selection
        (Field_Snap, Cell_W, Cell_H, Text_X + Float (Cell_W), Field_Y, Field_Rectangles);
      Push_Text
        (Text, To_String (Field_Snap.Visible_Text),
         Text_X + Float (Cell_W), Field_Y,
         Guikit.Draw.Text_Color);
      if Error_Text'Length > 0 then
         Push_Text
           (Text, Truncate_Right (Error_Text, Text_Cols),
            Text_X, Error_Y, Guikit.Draw.Text_Color);
      end if;
      if Active then
         Caret_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Float'Floor (Text_X + Float ((Field_Snap.Cursor_Visible_Column + 1) * Cell_W))),
               Y      => Natural (Float'Floor (Field_Y + 2.0)),
               Width  => 2,
               Height => Natural (Cell_H - 4),
               Color  => Guikit.Draw.Text_Color));
      end if;
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
      Field         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Field_Rectangles      => Field,
         Caret_Rectangles      => Caret,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Background_Layer, R);
         end loop;
         for R of Field loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Field_Layer, R);
         end loop;
         for R of Caret loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Caret_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Quick_Open_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Go_To_Line.Surface_Rendering;
