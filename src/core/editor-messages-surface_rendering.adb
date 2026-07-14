with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.View;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Theme;
with Guikit.Draw;

package body Editor.Messages.Surface_Rendering is

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

   procedure Build_Frame
     (Snapshot          : Editor.Render_Model.Render_Snapshot;
      Message_Layout    : Editor.Messages.Message_Layout;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Messages.Message_Config :=
        (Default_Lifetime_Ms   => 3_000,
         Error_Lifetime_Ms     => 5_000,
         Max_Visible_Messages  => 3,
         Max_Text_Columns      => 96,
         Replace_Same_Category => True);
      Now_Seconds : constant Duration := Editor.View.Current_Time_Seconds;
      Now_Ms : constant Natural :=
        (if Now_Seconds <= 0.0 then 0
         elsif Now_Seconds >= Duration (Natural'Last / 1000) then Natural'Last
         else Natural (Float (Now_Seconds) * 1000.0));
      Count : constant Natural :=
        Editor.Messages.Visible_Count (Snapshot.Messages, Now_Ms, Config);
   begin
      Background_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Count > 0;
      if not Visible then
         return;
      end if;

      for I in 1 .. Count loop
         declare
            Message : constant Editor.Messages.Editor_Message :=
              Editor.Messages.Visible_Message (Snapshot.Messages, I, Now_Ms, Config);
            Rect : constant Editor.Messages.Message_Rect :=
              Editor.Messages.Overlay_Rect
                (Layout          => Message_Layout,
                 Viewport_Width  => Editor.View.Viewport_Width,
                 Viewport_Height => Editor.View.Viewport_Height,
                 State           => Snapshot.Messages,
                 Index           => I,
                 Now_Ms          => Now_Ms,
                 Config          => Config);
            Background : Guikit.Draw.Render_Color;
            Foreground : Guikit.Draw.Render_Color;
            Text_Columns : Natural := 0;
         begin
            if not Rect.Visible then
               null;
            else
               case Message.Severity is
                  when Editor.Messages.Info_Message =>
                     Background := Guikit.Draw.Pane_Color;
                     Foreground := Guikit.Draw.Text_Color;
                  when Editor.Messages.Success_Message =>
                     Background := Guikit.Draw.Pane_Color;
                     Foreground := Guikit.Draw.Label_Green_Color;
                  when Editor.Messages.Warning_Message =>
                     Background := Guikit.Draw.Pane_Color;
                     Foreground := Guikit.Draw.Label_Orange_Color;
                  when Editor.Messages.Error_Message =>
                     Background := Guikit.Draw.Pane_Color;
                     Foreground := Guikit.Draw.Error_Text_Color;
               end case;

               Background_Rectangles.Append
                 (Guikit.Draw.Rectangle_Command'
                   (X      => Natural (Rect.X),
                    Y      => Natural (Rect.Y),
                    Width  => Natural (Rect.W),
                    Height => Natural (Rect.H),
                     Color  => Background));

               if Rect.W > 2 * Message_Layout.Cell_W then
                  Text_Columns := (Rect.W / Message_Layout.Cell_W) - 2;
               end if;

               Push_Text
                 (Text,
                  Editor.Messages.Display_Text
                    (Message, Text_Columns),
                  Float (Rect.X + Message_Layout.Cell_W),
                  Float (Rect.Y),
                  Foreground);
            end if;
         end;
      end loop;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Message_Layout : Editor.Messages.Message_Layout)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Snapshot              => Snapshot,
         Message_Layout        => Message_Layout,
         Visible               => Visible,
         Background_Rectangles => Background,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Message_Background_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Message_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Messages.Surface_Rendering;
