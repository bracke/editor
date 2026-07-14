with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.State;
with Guikit.Draw;
with Guikit.Widgets;
use type Editor.State.Semantic_Popup_Kind;

package body Editor.Semantic_Popup.Surface_Rendering is

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

   function Tail_Text
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      else
         return Text (Text'Last - Columns + 1 .. Text'Last);
      end if;
   end Tail_Text;

   procedure Push_Rect
     (Rectangles : in out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      X          : Natural;
      Y          : Natural;
      W          : Natural;
      H          : Natural;
      Color      : Guikit.Draw.Render_Color)
   is
   begin
      Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => X, Y => Y, Width => W, Height => H, Color => Color));
   end Push_Rect;

   procedure Build_Frame
     (Popup                 : Editor.State.Semantic_Popup_State;
      Anchor_X              : Float;
      Anchor_Y              : Float;
      Layout_Config         : Editor.Layout.Layout_Config;
      Viewport_Width        : Natural;
      Viewport_Height       : Natural;
      Cell_W                : Natural;
      Cell_H                : Positive;
      Visible               : out Boolean;
      Background_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles        : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text                  : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility         : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      Max_Rows : constant Natural :=
        (case Popup.Kind is
           when Editor.State.Semantic_Hover_Popup => 2,
           when Editor.State.Semantic_Completion_Popup =>
              Natural'Min
                (Editor.State.Max_Semantic_Completion_Items,
                 Natural'Max (1, Popup.Item_Count)) + 1,
           when Editor.State.No_Semantic_Popup => 0);
      Width_Cols : constant Natural := 56;
      Popup_W : constant Natural :=
        Natural'Min (Message_Body.Width, Width_Cols * Cell_W);
      Popup_H : constant Natural :=
        Natural'Min
          (Message_Body.Height,
           Natural'Max (1, Max_Rows) * Cell_H);
      Text_Cols : constant Natural :=
        (if Popup_W / Cell_W > 2 then Popup_W / Cell_W - 2 else 1);
      X : constant Float :=
        Float'Min
          (Float'Max (Float (Message_Body.X), Anchor_X),
           Float (Message_Body.X + Message_Body.Width - Popup_W));
      Y : constant Float :=
        Float'Min
          (Float'Max (Float (Message_Body.Y), Anchor_Y),
           Float (Message_Body.Y + Message_Body.Height - Popup_H));
      Foreground : constant Guikit.Draw.Render_Color := Guikit.Draw.Muted_Text_Color;
      Title_Color : constant Guikit.Draw.Render_Color := Guikit.Draw.Text_Color;
      Background : constant Guikit.Draw.Render_Color := Guikit.Draw.Pane_Color;
      Selected_Background : constant Guikit.Draw.Render_Color := Guikit.Draw.Selection_Color;
   begin
      Background_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Popup.Active
        and then Popup.Kind /= Editor.State.No_Semantic_Popup
        and then Popup_W > 0
        and then Popup_H > 0;
      if not Visible then
         return;
      end if;

      Push_Rect
        (Background_Rectangles,
         Natural (Float'Floor (X)),
         Natural (Float'Floor (Y)),
         Popup_W,
         Popup_H,
         Background);

      case Popup.Kind is
         when Editor.State.Semantic_Hover_Popup =>
            Push_Text
              (Text,
               Tail_Text (To_String (Popup.Title), Text_Cols),
               X + Float (Cell_W), Y,
               Title_Color);
            Push_Text
              (Text,
               Tail_Text (To_String (Popup.Detail), Text_Cols),
               X + Float (Cell_W), Y + Float (Cell_H),
               Foreground);

         when Editor.State.Semantic_Completion_Popup =>
            Push_Text
              (Text,
               Tail_Text (To_String (Popup.Title), Text_Cols),
               X + Float (Cell_W), Y,
               Title_Color);
            for I in 1 ..
              Natural'Min
                (Popup.Item_Count, Editor.State.Max_Semantic_Completion_Items)
            loop
               declare
                  Row_Y : constant Float := Y + Float (I * Cell_H);
                  Item : constant Editor.State.Semantic_Completion_Item :=
                    Popup.Items (Editor.State.Semantic_Completion_Item_Index (I));
                  Label : constant String :=
                    To_String (Item.Label)
                    & (if Length (Item.Detail) > 0
                       then "  " & To_String (Item.Detail)
                       else "");
               begin
                  if Popup.Selected_Item = I then
                     Push_Rect
                       (Row_Rectangles,
                        Natural (Float'Floor (X)),
                        Natural (Float'Floor (Row_Y)),
                        Popup_W,
                        Cell_H,
                        Selected_Background);
                  end if;
                  Push_Text
                    (Text,
                     Tail_Text (Label, Text_Cols),
                     X + Float (Cell_W), Row_Y,
                     Foreground);
               end;
            end loop;

         when Editor.State.No_Semantic_Popup =>
            null;
      end case;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Popup          : Editor.State.Semantic_Popup_State;
      Anchor_X       : Float;
      Anchor_Y       : Float;
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
        (Popup                 => Popup,
         Anchor_X              => Anchor_X,
         Anchor_Y              => Anchor_Y,
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
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Semantic_Popup_Background_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Semantic_Popup_Row_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Semantic_Popup_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Semantic_Popup.Surface_Rendering;
