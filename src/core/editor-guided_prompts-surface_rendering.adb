with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Draw;
with Guikit.List_Panel;
with Guikit.Widgets;

package body Editor.Guided_Prompts.Surface_Rendering is

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

   procedure Build_Frame
     (Snapshot          : Editor.Guided_Prompts.Prompt_Snapshot;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_W            : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Button_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Message_Body : constant Editor.Layout.Rect :=
        Editor.Layout.Editor_Body_Rect
          (Layout_Config, Viewport_Width, Viewport_Height);
      Picker_Rows : constant Natural :=
        (if Snapshot.File_Picker_Active
         then Natural'Min
           (Editor.Guided_Prompts.Max_File_Picker_Rows,
            Natural (Snapshot.File_Picker_Rows.Length))
         else 0);
      G : constant Editor.Layout.Rect :=
        (X      => Message_Body.X,
         Y      => Message_Body.Y + Cell_H,
         Width  => Natural'Min (Message_Body.Width, 88 * Cell_W),
         Height => (3 + Picker_Rows + (if Snapshot.File_Picker_Active then 1 else 0)) * Cell_H);
      Field_X : constant Float := Float (G.X + 18 * Cell_W);
      Field_W : constant Float :=
        Float (if G.Width > 22 * Cell_W then G.Width - 22 * Cell_W else Cell_W);
      Input_Label : constant String :=
        (if Snapshot.Has_Captured_Chord
         then To_String (Snapshot.Captured_Chord_Label)
         else To_String (Snapshot.Input_Text));
      Header : constant String :=
        To_String (Snapshot.Title) & " [" & To_String (Snapshot.Target_Domain_Label) & "]";
      Action : constant String :=
        To_String (Snapshot.Confirm_Label) & " / " & To_String (Snapshot.Cancel_Label);
   begin
      Background_Rectangles.Clear;
      Button_Rectangles.Clear;
      Field_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Active and then G.Width > 0 and then G.Height > 0;
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

      Push_Text
        (Text, Header, Float (G.X + Cell_W), Float (G.Y), Guikit.Draw.Text_Color);
      Push_Text
        (Text, "Input", Float (G.X + Cell_W), Float (G.Y + Cell_H),
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
            Width        => Natural (Field_W),
            Height       => Cell_H,
            Fill_Color   => Guikit.Draw.Input_Color,
            Border_Color => Guikit.Draw.Border_Color);
         for R of Rectangles loop
            Field_Rectangles.Append (R);
         end loop;
      end;
      Push_Text
        (Text, Tail_Text (Input_Label, Natural (Field_W) / Cell_W - 1),
         Field_X + Float (Cell_W), Float (G.Y + Cell_H),
         Guikit.Draw.Text_Color);

      Push_Text
        (Text, To_String (Snapshot.Validation_Label),
         Float (G.X + Cell_W), Float (G.Y + 2 * Cell_H),
         (if Snapshot.Validation = Editor.Guided_Prompts.Validation_Ready
          then Guikit.Draw.Text_Color
          else Guikit.Draw.Error_Text_Color));
      Push_Text
        (Text, Action,
         Float (G.X + Integer (G.Width) - Integer (24 * Cell_W)),
         Float (G.Y + 2 * Cell_H), Guikit.Draw.Text_Color);

      if Snapshot.File_Picker_Active then
         Push_Text
           (Text,
            Tail_Text
              ("Dir " & To_String (Snapshot.File_Picker_Current_Directory),
               Natural'Max (1, G.Width / Cell_W - 2)),
            Float (G.X + Cell_W), Float (G.Y + 3 * Cell_H),
            Guikit.Draw.Muted_Text_Color);

         declare
            Picker_Rows_Model : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
            Picker_Region     : constant Editor.Layout.Rect :=
              (X      => G.X + Cell_W,
               Y      => G.Y + 4 * Cell_H,
               Width  => (if G.Width > 2 * Cell_W then G.Width - 2 * Cell_W else 0),
               Height => Natural'Max (1, Picker_Rows) * Cell_H);
            Picker_Config : constant Guikit.List_Panel.List_Panel_Configuration :=
              (Title               => Null_Unbounded_String,
               Empty_State         => Snapshot.File_Picker_Status,
               Line_Height         => Cell_H,
               Text_Padding        => Cell_W,
               Show_Alternate_Rows => False);
         begin
            if Picker_Rows > 0 then
               for I in Snapshot.File_Picker_Rows.First_Index ..
                 Snapshot.File_Picker_Rows.Last_Index
               loop
                  declare
                     Row : constant Editor.Guided_Prompts.File_Picker_Row :=
                       Snapshot.File_Picker_Rows.Element (I);
                  begin
                     Picker_Rows_Model.Append
                       (Guikit.List_Panel.List_Panel_Row'
                          (Label            => Row.Label,
                           Detail           => Row.Path,
                           Shortcut         => Null_Unbounded_String,
                           Selected         => I = Snapshot.File_Picker_Selected_Index,
                           Enabled          => True,
                           Label_Color      => Guikit.Draw.Text_Color,
                           Has_Background   => False,
                           Background_Color => Guikit.Draw.Input_Color,
                           Accent_Color     => Guikit.Draw.Border_Color,
                           Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
                  end;
               end loop;
            end if;

            declare
               Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
               Texts : Guikit.Draw.Text_Command_Vectors.Vector;
               Accessibility_Nodes : Guikit.Draw.Accessibility_Node_Vectors.Vector;
            begin
               Guikit.List_Panel.Draw_Frame
                 (Rectangles    => Rectangles,
                  Text          => Texts,
                  Accessibility => Accessibility_Nodes,
                  Clip_Width    => Viewport_Width,
                  Clip_Height   => Viewport_Height,
                  Region_X      => Picker_Region.X,
                  Region_Y      => Picker_Region.Y,
                  Region_Width  => Picker_Region.Width,
                  Region_Height => Picker_Region.Height,
                  Config        => Picker_Config,
                  Rows          => Picker_Rows_Model,
                  Draw_Chrome   => False);

               for R of Rectangles loop
                  Field_Rectangles.Append (R);
               end loop;
               for T of Texts loop
                  Text.Append (T);
               end loop;
            end;
         end;
      end if;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Guided_Prompts.Prompt_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Button        : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Field         : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Button_Rectangles     => Button,
         Field_Rectangles      => Field,
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
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Active_Find_Prompt_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Guided_Prompts.Surface_Rendering;
