with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Status_Bar;
with Editor.Theme;

package body Editor.Status_Bar.Surface_Rendering is

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

   function Truncate_To_Columns
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
   end Truncate_To_Columns;

   procedure Build_Frame
     (Snapshot       : Editor.Status_Bar.Status_Bar_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Left_Text  : constant String := Editor.Status_Bar.Format_Left (Snapshot);
      Right_Text : constant String := Editor.Status_Bar.Format_Right (Snapshot);
      Bar_H : constant Natural := Editor.Layout.Status_Bar_Height (Layout_Config);
      Bar_Y : constant Float := Float (Editor.Layout.Status_Bar_Y (Layout_Config, Viewport_Height));
      Bar_W : constant Natural := Editor.Layout.Status_Bar_Width (Layout_Config, Viewport_Width);
      Padding : constant Natural := Cell_W;
      Max_Cols : constant Natural :=
        (if Bar_W > 2 * Padding then (Bar_W - 2 * Padding) / Cell_W else 0);
      Compact_Text  : Unbounded_String := Null_Unbounded_String;
      Use_Compact   : Boolean := False;
      Left_Cols     : Natural := 0;
      Right_Cols    : Natural := 0;
      Left_X : constant Float := Float (Layout_Config.Origin_X + Padding);
      Right_X : Float := 0.0;
   begin
      Background_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if Bar_H = 0 or else Viewport_Width = 0 then
         return;
      end if;

      Visible := True;
      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Layout_Config.Origin_X,
            Y      => Natural (Bar_Y),
            Width  => Bar_W,
            Height => Bar_H,
            Color  => Guikit.Draw.Pane_Color));
      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Layout_Config.Origin_X,
            Y      => Natural (Bar_Y),
            Width  => Bar_W,
            Height => 1,
            Color  => Guikit.Draw.Border_Color));

      if Max_Cols > 0 then
         Use_Compact := Editor.Status_Bar.Status_Layout_Should_Use_Compact
           (Snapshot, Max_Cols);
         if Use_Compact then
            Compact_Text := To_Unbounded_String
              (Editor.Status_Bar.Status_Layout_Compact (Snapshot, Max_Cols));
            Left_Cols := Length (Compact_Text);
         elsif Max_Cols >= 24 then
            Right_Cols := Natural'Min (Right_Text'Length, Max_Cols / 2);
         elsif Max_Cols >= 8 then
            Right_Cols := Natural'Min (Right_Text'Length, Max_Cols / 3);
         end if;

         if not Use_Compact then
            if Right_Cols > 0 and then Max_Cols > Right_Cols + 1 then
               Left_Cols := Natural'Min (Left_Text'Length, Max_Cols - Right_Cols - 1);
            else
               Left_Cols := Natural'Min (Left_Text'Length, Max_Cols);
               Right_Cols := 0;
            end if;
         end if;
      end if;

      declare
         Left_Display  : constant String :=
           (if Use_Compact
            then To_String (Compact_Text)
            else Truncate_To_Columns (Left_Text, Left_Cols));
         Right_Display : constant String :=
           (if Use_Compact then "" else Truncate_To_Columns (Right_Text, Right_Cols));
      begin
         if Left_Display'Length > 0
           and then Snapshot.Is_Dirty
           and then Left_Display (Left_Display'Last) = '*'
         then
            if Left_Display'Length > 1 then
                Push_Text
                  (Text,
                   Left_Display (Left_Display'First .. Left_Display'Last - 1),
                  Left_X, Bar_Y, Guikit.Draw.Text_Color);
            end if;

            Push_Text
              (Text,
               Left_Display (Left_Display'Last .. Left_Display'Last),
               Left_X + Float ((Left_Display'Length - 1) * Cell_W),
               Bar_Y, Guikit.Draw.Label_Orange_Color);
         else
            Push_Text
              (Text, Left_Display, Left_X, Bar_Y,
               Guikit.Draw.Text_Color);
         end if;

         if Right_Display'Length > 0
           and then Bar_W > Padding + Right_Display'Length * Cell_W
         then
            Right_X := Float
              (Layout_Config.Origin_X + Bar_W - Padding - Right_Display'Length * Cell_W);
            if Right_X > Left_X + Float ((Left_Display'Length + 1) * Cell_W) then
               Push_Text
                 (Text, Right_Display, Right_X, Bar_Y,
                  Guikit.Draw.Text_Color);
            end if;
         end if;
      end;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Status_Bar.Status_Bar_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Status_Bar_Background_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Status_Bar_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Status_Bar.Surface_Rendering;
