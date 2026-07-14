with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Tab_Bar;
with Editor.View;
with Guikit.Draw;

package body Editor.Tab_Bar.Surface_Rendering is

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

   function Fit_Text
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      if Max_Columns = 0 then
         return "";
      elsif Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Max_Columns - 2) & "~";
      end if;
   end Fit_Text;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Tab_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Inactive_Tab_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Border_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Dirty_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Close_Rectangles      : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Inactive_Text         : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility         : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      pragma Unreferenced (State);
      Bar_H : constant Natural := Editor.Layout.Tab_Bar_Height (Layout_Config);
      Bar_W : constant Natural :=
        Editor.Layout.Tab_Bar_Width (Layout_Config, Editor.View.Viewport_Width);
      Count : constant Natural := Editor.Buffers.Global_Count;
      Padding_Cols : constant Natural := 1;
      begin
      Background_Rectangles.Clear;
      Active_Tab_Rectangles.Clear;
      Inactive_Tab_Rectangles.Clear;
      Border_Rectangles.Clear;
      Dirty_Rectangles.Clear;
      Close_Rectangles.Clear;
      Active_Text.Clear;
      Inactive_Text.Clear;
      Accessibility.Clear;
      Visible := Bar_H > 0 and then Bar_W > 0;
      if not Visible then
         return;
      end if;

      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Layout_Config.Origin_X),
            Y => Natural (Editor.Layout.Tab_Bar_Y (Layout_Config)),
            Width => Bar_W,
            Height => Bar_H,
            Color => Guikit.Draw.Pane_Color,
            others => <>));
      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Layout_Config.Origin_X),
            Y => Natural (Editor.Layout.Tab_Bar_Y (Layout_Config)),
            Width => Bar_W,
            Height => 1,
            Color => Guikit.Draw.Border_Color,
            others => <>));

      if Count = 0 then
         Push_Text
           (Inactive_Text,
            Fit_Text
              (Editor.Tab_Bar.Empty_Display_Text (Bar_W / Cell_W),
               Bar_W / Cell_W),
            Float (Layout_Config.Origin_X + Padding_Cols * Cell_W),
            Float (Editor.Layout.Tab_Bar_Y (Layout_Config)),
            Guikit.Draw.Muted_Text_Color);
         return;
      end if;

      for I in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Global_Summary_At (I);
            Rect : constant Editor.Tab_Bar.Tab_Rect :=
              Editor.Tab_Bar.Rect_For_Index
                (Layout_Config.Tab_Bar, I, Bar_W, Cell_W, Cell_H,
                 Layout_Config.Origin_X, Layout_Config.Origin_Y);
            State_Kind : constant Editor.Tab_Bar.Tab_Visual_State :=
              Editor.Tab_Bar.Visual_State (Summary);
            Reserved_Cols : Natural := 2 * Padding_Cols;
            Text_Cols : Natural := 0;
         begin
            exit when not Rect.Visible;

            if State_Kind = Editor.Tab_Bar.Active_Tab
              or else State_Kind = Editor.Tab_Bar.Dirty_Active_Tab
            then
               Active_Tab_Rectangles.Append
                 (Guikit.Draw.Rectangle_Command'
                    (X => Natural (Rect.X),
                     Y => Natural (Rect.Y),
                     Width => Rect.W,
                     Height => Rect.H,
                     Color => Guikit.Draw.Pane_Color,
                     others => <>));
            end if;

            if State_Kind /= Editor.Tab_Bar.Active_Tab
              and then State_Kind /= Editor.Tab_Bar.Dirty_Active_Tab
            then
               Inactive_Tab_Rectangles.Append
                 (Guikit.Draw.Rectangle_Command'
                    (X => Natural (Rect.X),
                     Y => Natural (Rect.Y),
                     Width => Rect.W,
                     Height => Rect.H,
                     Color => Guikit.Draw.Pane_Color,
                     others => <>));
            end if;

            Border_Rectangles.Append
              (Guikit.Draw.Rectangle_Command'
                 (X => Natural (Rect.X + Rect.W - 1),
                  Y => Natural (Rect.Y),
                  Width => 1,
                  Height => Rect.H,
                  Color => Guikit.Draw.Border_Color,
                  others => <>));

            if Summary.Is_Dirty and then Rect.W >= 4 * Cell_W then
               declare
                  Dirty_Size : constant Float := Float'Max (2.0, Float (Cell_W) / 3.0);
                  Dirty_X : constant Float :=
                    Float (Rect.X + Rect.W - 3 * Cell_W)
                    + (Float (Cell_W) - Dirty_Size) / 2.0;
                  Dirty_Y : constant Float :=
                    Float (Rect.Y) + (Float (Cell_H) - Dirty_Size) / 2.0;
               begin
                  Dirty_Rectangles.Append
                    (Guikit.Draw.Rectangle_Command'
                       (X => Natural (Float'Floor (Dirty_X)),
                        Y => Natural (Float'Floor (Dirty_Y)),
                        Width => Natural (Float'Ceiling (Dirty_Size)),
                        Height => Natural (Float'Ceiling (Dirty_Size)),
                        Color => Guikit.Draw.Error_Text_Color,
                        others => <>));
                  Reserved_Cols := Reserved_Cols + 1;
               end;
            end if;

            if Layout_Config.Tab_Bar.Show_Close_Buttons
              and then Rect.Close_W > 0
            then
               Close_Rectangles.Append
                 (Guikit.Draw.Rectangle_Command'
                    (X => Natural (Rect.Close_X),
                     Y => Natural (Rect.Y + Cell_H / 4),
                     Width => Rect.Close_W,
                     Height => Natural'Max (1, Cell_H / 2),
                     Color => Guikit.Draw.Error_Text_Color,
                     others => <>));
               Reserved_Cols := Reserved_Cols + 2;
            end if;

            if Rect.W / Cell_W > Reserved_Cols then
               Text_Cols := Rect.W / Cell_W - Reserved_Cols;
            end if;

            if State_Kind = Editor.Tab_Bar.Active_Tab
              or else State_Kind = Editor.Tab_Bar.Dirty_Active_Tab
            then
               Push_Text
                 (Active_Text,
                  Fit_Text (Editor.Tab_Bar.Display_Text (Summary, Text_Cols), Text_Cols),
                  Float (Rect.X + Padding_Cols * Cell_W),
                  Float (Rect.Y),
                  Guikit.Draw.Text_Color);
            else
               Push_Text
                 (Inactive_Text,
                  Fit_Text (Editor.Tab_Bar.Display_Text (Summary, Text_Cols), Text_Cols),
                  Float (Rect.X + Padding_Cols * Cell_W),
                  Float (Rect.Y),
                  Guikit.Draw.Muted_Text_Color);
            end if;
         end;
      end loop;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible           : Boolean;
      Background        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Tabs       : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Inactive_Tabs     : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Borders           : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Dirty             : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Close             : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Active_Text       : Guikit.Draw.Text_Command_Vectors.Vector;
      Inactive_Text     : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (State                  => State,
         Layout_Config          => Layout_Config,
         Viewport_Width         => Viewport_Width,
         Cell_W                 => Cell_W,
         Cell_H                 => Cell_H,
         Visible                => Visible,
         Background_Rectangles  => Background,
         Active_Tab_Rectangles  => Active_Tabs,
         Inactive_Tab_Rectangles => Inactive_Tabs,
         Border_Rectangles      => Borders,
         Dirty_Rectangles       => Dirty,
         Close_Rectangles       => Close,
         Active_Text            => Active_Text,
         Inactive_Text          => Inactive_Text,
         Accessibility          => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Background_Layer, R);
         end loop;
         for R of Active_Tabs loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Tab_Layer, R);
         end loop;
         for R of Inactive_Tabs loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Tab_Layer, R);
         end loop;
         for R of Borders loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Tab_Layer, R);
         end loop;
         for R of Dirty loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Dirty_Layer, R);
         end loop;
         for R of Close loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Tab_Bar_Close_Layer, R);
         end loop;
         for T of Active_Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Tab_Bar_Text_Layer, T);
         end loop;
         for T of Inactive_Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Tab_Bar_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Tab_Bar.Surface_Rendering;
