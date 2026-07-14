with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher_Contextual_Hints;
with Editor.Buffers;
with Editor.Buffer_Switcher.Surface_Projection;
with Editor.Input_Field;
with Editor.Layout;
with Editor.Overlay_Focus;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Draw;
with Guikit.List_Panel;
with Guikit.Widgets;

package body Editor.Buffer_Switcher.Surface_Rendering is

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
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Columns - 2) & "~";
      end if;
   end Truncate_Right;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Result_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Projection : constant Editor.Buffer_Switcher.Surface_Projection.Buffer_Switcher_Render_Projection :=
        Editor.Buffer_Switcher.Surface_Projection.Project
          (State,
           Viewport_Width,
           Viewport_Height,
           Layout_Config.Origin_X,
           Layout_Config.Origin_Y,
           Cell_W,
           Cell_H);
      G : constant Editor.Layout.Rect := Projection.Panel;
      Field_Y : constant Float := Float (Projection.Field_Y);
      Rows_Y  : constant Float := Float (Projection.Rows_Y);
      Text_X : constant Float := Float (G.X + Integer (Config.Result_Padding_Columns * Cell_W));
      Text_Cols : constant Natural := Projection.Text_Columns;
      Active : constant Boolean :=
        Editor.Overlay_Focus.Is_Active
          (State.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
   begin
      Background_Rectangles.Clear;
      Field_Rectangles.Clear;
      Result_Rectangles.Clear;
      Caret_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Projection.Visible;
      if not Visible then
         return;
      end if;

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Menu_Panel
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => G.X,
            Y            => G.Y,
            Width        => G.Width,
            Height       => G.Height,
            Fill_Color   => Guikit.Draw.Pane_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Background_Rectangles.Append (R);
         end loop;
      end;

      Push_Text
        (Text,
         Truncate_Right (To_String (Projection.Header_Text), Text_Cols),
         Text_X, Float (G.Y),
         Guikit.Draw.Text_Color);

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Input_Field
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => Natural (Float'Floor (Text_X)),
            Y            => Natural (Float'Floor (Field_Y)),
            Width        => Natural (G.Width - 2 * Config.Result_Padding_Columns * Cell_W),
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;

      Push_Field_Selection
        (Projection.Query_Snapshot, Cell_W, Cell_H, Text_X + Float (Cell_W), Field_Y, Field_Rectangles);
      Push_Text
        (Text, To_String (Projection.Query_Snapshot.Visible_Text),
         Text_X + Float (Cell_W), Field_Y,
         Guikit.Draw.Text_Color);
      if Active then
         declare
            C : constant Natural := Projection.Query_Snapshot.Cursor_Visible_Column;
         begin
            Caret_Rectangles.Append
              (Guikit.Draw.Rectangle_Command'
                 (X      => Natural (Float'Floor (Text_X + Float ((C + 1) * Cell_W))),
                  Y      => Natural (Float'Floor (Field_Y + 2.0)),
                  Width  => 2,
                  Height => Natural (Cell_H - 4),
                  Color  => Guikit.Draw.Text_Color));
         end;
      end if;

      declare
         Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
           (Title               => Null_Unbounded_String,
            Empty_State         =>
              To_Unbounded_String
                (Editor.Buffer_Switcher.Buffer_List_Empty_State_Label
                   (State.Buffer_Switcher, Editor.Buffers.Global_Count)),
            Line_Height         => Cell_H,
            Text_Padding        => Cell_W,
            Show_Alternate_Rows => False);
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts      : Guikit.Draw.Text_Command_Vectors.Vector;
      begin
         Guikit.List_Panel.Draw_Frame
           (Rectangles    => Rectangles,
            Text          => Texts,
            Accessibility => Accessibility,
            Clip_Width    => Viewport_Width,
            Clip_Height   => Viewport_Height,
            Region_X      => Natural (G.X),
            Region_Y      => Natural (Float'Floor (Rows_Y)),
            Region_Width  => Natural (G.Width),
            Region_Height => Projection.Row_Height,
            Config        => Config_Panel,
            Rows          => Projection.Rows);

         for R of Rectangles loop
            Result_Rectangles.Append (R);
         end loop;
         for T of Texts loop
            Text.Append (T);
         end loop;
      end;

      if Length (Projection.Hint_Text) > 0 then
         Push_Text
           (Text,
            Truncate_Right (To_String (Projection.Hint_Text), Text_Cols),
            Text_X, Float (Projection.Footer_Y),
            Guikit.Draw.Muted_Text_Color);
      end if;

      if Projection.Preview_Visible then
         declare
            Preview_Y : constant Float := Rows_Y + Float (Projection.Row_Height);
            Preview_Text_Y : Float := Preview_Y;
         begin
            if Length (Projection.Preview_Header) > 0 then
               Push_Text
                 (Text, To_String (Projection.Preview_Header),
                  Text_X, Preview_Text_Y,
                  Guikit.Draw.Muted_Text_Color);
               Preview_Text_Y := Preview_Text_Y + Float (Cell_H);
            end if;
            if Length (Projection.Preview_Empty) > 0 then
               Push_Text
                 (Text, To_String (Projection.Preview_Empty),
                  Text_X, Preview_Text_Y,
                  Guikit.Draw.Muted_Text_Color);
            else
               for I in 1 .. Natural (Projection.Preview_Lines.Length) loop
                  Push_Text
                    (Text,
                     To_String (Projection.Preview_Lines (I)),
                     Text_X,
                     Preview_Text_Y + Float ((I - 1) * Cell_H),
                     Guikit.Draw.Muted_Text_Color);
               end loop;
            end if;
         end;
      end if;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Result        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (State                 => State,
         Layout_Config         => Layout_Config,
         Viewport_Width        => Viewport_Width,
         Viewport_Height       => Viewport_Height,
         Cell_W                => Cell_W,
         Cell_H                => Cell_H,
         Visible               => Visible,
         Background_Rectangles => Background,
         Field_Rectangles      => Field,
         Result_Rectangles     => Result,
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
         for R of Result loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Selected_Result_Layer, R);
         end loop;
         for R of Caret loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Quick_Open_Caret_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Quick_Open_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Buffer_Switcher.Surface_Rendering;
