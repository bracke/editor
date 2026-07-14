with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Input_Field;
with Editor.Overlay_Focus;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Draw;
with Guikit.Widgets;

use type Editor.Overlay_Focus.Overlay_Target;

package body Editor.Active_Find_Prompt.Surface_Rendering is

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

   function Image_Of (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Image_Of;

   function Match_Text
     (Snap : Editor.Render_Model.Render_Snapshot) return String
   is
      Active_Renderable : constant Boolean :=
        Snap.Find_Visible
        and then Length (Snap.Find_Query) > 0
        and then not Snap.Find_Matches_Stale
        and then Snap.Find_Matches_For_Active_Buffer;
      Active_Count : constant Natural :=
        (if Active_Renderable then Snap.Find_Match_Count else 0);
   begin
      if not Snap.Find_Visible then
         return "";
      elsif Length (Snap.Find_Status_Text) > 0 then
         return To_String (Snap.Find_Status_Text);
      elsif Length (Snap.Find_Query) = 0 then
         return "No query";
      elsif not Active_Renderable then
         return "Stale";
      elsif Active_Count = 0 then
         return "No matches";
      elsif Snap.Find_Selected_Match_Ordinal > 0 then
         return Image_Of (Snap.Find_Selected_Match_Ordinal)
           & "/" & Image_Of (Active_Count);
      elsif Active_Count = 1 then
         return "1 match";
      else
         return Image_Of (Active_Count) & " matches";
      end if;
   end Match_Text;

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
      Button_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Caret_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      G : constant Editor.Layout.Rect :=
        (X      => Message_Body.X,
         Y      => Message_Body.Y,
         Width  => Natural'Min (Message_Body.Width, 64 * Cell_W),
         Height => (if Snapshot.Replace_Visible then 2 * Cell_H else Cell_H));
      Field_X : constant Float := Float (G.X + 15 * Cell_W);
      Field_Pixels : constant Natural :=
        (if G.Width > 28 * Cell_W then G.Width - 28 * Cell_W else Cell_W);
      Field_W : constant Float := Float (Field_Pixels);
      Query_Snap : constant Editor.Input_Field.Field_Snapshot :=
        Snapshot.Active_Find_Field;
      Query_Text : constant String := To_String (Snapshot.Active_Find_Field.Visible_Text);
      Match_Text_Value : constant String := Match_Text (Snapshot);
      Case_Text  : constant String :=
        (if Snapshot.Find_Visible then
           (if Snapshot.Find_Case_Sensitive then "Case: sensitive" else "Case: insensitive")
           & "     "
           & (if Snapshot.Find_Whole_Word then "Whole word: on" else "Whole word: off")
         else "");
      Active_Renderable : constant Boolean :=
        Snapshot.Find_Visible
        and then Length (Snapshot.Find_Query) > 0
        and then not Snapshot.Find_Matches_Stale
        and then Snapshot.Find_Matches_For_Active_Buffer;
      Match_Color : constant Guikit.Draw.Render_Color :=
        (if Active_Renderable
            and then Length (Snapshot.Find_Query) > 0
            and then Snapshot.Find_Match_Count = 0
         then Guikit.Draw.Error_Text_Color else Guikit.Draw.Text_Color);
      Active : constant Boolean :=
        Snapshot.Active_Overlay = Editor.Overlay_Focus.Active_Find_Prompt_Overlay;
   begin
      Background_Rectangles.Clear;
      Field_Rectangles.Clear;
      Button_Rectangles.Clear;
      Caret_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Find_Visible
        and then G.Width > 0
        and then G.Height > 0;
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
      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Menu_Panel
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => G.X + Cell_W,
            Y            => G.Y,
            Width        => 4 * Cell_W,
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Selection_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Button_Rectangles.Append (R);
         end loop;
      end;

      Push_Text (Text, "X", Float (G.X + 2 * Cell_W), Float (G.Y), Guikit.Draw.Text_Color);
      Push_Text (Text, "<", Float (G.X + 7 * Cell_W), Float (G.Y), Guikit.Draw.Text_Color);
      Push_Text (Text, ">", Float (G.X + 11 * Cell_W), Float (G.Y), Guikit.Draw.Text_Color);
      Push_Text (Text, "Find", Float (G.X + 15 * Cell_W), Float (G.Y), Guikit.Draw.Text_Color);

      declare
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      begin
         Guikit.Widgets.Draw_Input_Field
           (Rectangles,
            Clip_Width   => Viewport_Width,
            Clip_Height  => Viewport_Height,
            X            => Natural (Field_X),
            Y            => G.Y,
            Width        => Field_Pixels,
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;
      Push_Field_Selection
        (Query_Snap, Cell_W, Cell_H, Field_X + Float (Cell_W), Float (G.Y), Field_Rectangles);
      Push_Text
        (Text, Query_Text,
         Field_X + Float (Cell_W), Float (G.Y), Guikit.Draw.Text_Color);
      Push_Text
        (Text, Match_Text_Value,
         Float (G.X + Integer (G.Width) - Integer (12 * Cell_W)),
         Float (G.Y), Match_Color);
      if Case_Text'Length > 0 and then G.Width > 30 * Cell_W then
         Push_Text
           (Text, Case_Text,
            Float (G.X + Integer (G.Width) - Integer (32 * Cell_W)),
            Float (G.Y), Guikit.Draw.Text_Color);
      end if;

      if Snapshot.Replace_Visible then
         Push_Text
           (Text, "Replace", Float (G.X + 15 * Cell_W), Float (G.Y + Cell_H),
            Guikit.Draw.Text_Color);
         declare
            Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         begin
            Guikit.Widgets.Draw_Input_Field
              (Rectangles,
               Clip_Width   => Viewport_Width,
               Clip_Height  => Viewport_Height,
               X            => Natural (Field_X),
               Y            => Natural (G.Y + Cell_H),
               Width        => Field_Pixels,
               Height       => Cell_H,
               Fill_Color   => Guikit.Draw.Input_Color,
               Border_Color => Guikit.Draw.Border_Color);
            for R of Rectangles loop
               Field_Rectangles.Append (R);
            end loop;
         end;
         Push_Text
           (Text, To_String (Snapshot.Replace_Text),
            Field_X + Float (Cell_W), Float (G.Y + Cell_H),
            Guikit.Draw.Text_Color);
      end if;

      if Active then
         declare
            C : constant Natural := Query_Snap.Cursor_Visible_Column;
         begin
            Caret_Rectangles.Append
              (Guikit.Draw.Rectangle_Command'
                 (X      => Natural (Float'Floor (Field_X + Float ((C + 1) * Cell_W))),
                  Y      => Natural (Float'Floor (Float (G.Y) + 2.0)),
                  Width  => 2,
                  Height => Natural (Cell_H - 4),
                  Color  => Guikit.Draw.Text_Color));
         end;
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
      Button        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Button_Rectangles     => Button,
         Caret_Rectangles      => Caret,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Active_Find_Prompt_Background_Layer, R);
         end loop;
         for R of Button loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Active_Find_Prompt_Button_Layer, R);
         end loop;
         for R of Field loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Active_Find_Prompt_Field_Layer, R);
         end loop;
         for R of Caret loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Active_Find_Prompt_Caret_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Active_Find_Prompt_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Active_Find_Prompt.Surface_Rendering;
