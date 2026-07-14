with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Settings;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Guikit.Layout;
with Guikit.Settings_Panel;
use type Guikit.Settings_Panel.Field_Kind;

package body Editor.Settings_Management.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   procedure Append_Option
     (Values : in out Guikit.Settings_Panel.UString_Vectors.Vector;
      Labels : in out Guikit.Settings_Panel.UString_Vectors.Vector;
      Text   : String)
   is
      U : constant Guikit.Settings_Panel.UString := To_Unbounded_String (Text);
   begin
      Values.Append (U);
      Labels.Append (U);
   end Append_Option;

   function Field_Kind_For
     (Row : Editor.Settings_Management.Setting_Row)
      return Guikit.Settings_Panel.Field_Kind
   is
   begin
      if Row.Kind = Editor.Settings_Management.Setting_Boolean then
         return Guikit.Settings_Panel.Toggle;
      elsif Row.Kind = Editor.Settings_Management.Setting_Enum then
         return Guikit.Settings_Panel.Choice;
      else
         return Guikit.Settings_Panel.Text;
      end if;
   end Field_Kind_For;

   function To_Field
     (Row : Editor.Settings_Management.Setting_Row)
      return Guikit.Settings_Panel.Field
   is
      Field : Guikit.Settings_Panel.Field;
   begin
      Field.Key := To_Unbounded_String (To_String (Row.Key));
      Field.Label := To_Unbounded_String (To_String (Row.Display_Name));
      Field.Kind := Field_Kind_For (Row);
      Field.Value := To_Unbounded_String (To_String (Row.Current_Value));
      Field.Enabled := Row.Editable;
      Field.Help :=
        (if Length (Row.Validation_Message) > 0
         then Row.Validation_Message
         else Row.Description);

      if Field.Kind = Guikit.Settings_Panel.Choice then
         if To_String (Row.Key) = Editor.Settings.Setting_Name_Theme then
            Append_Option (Field.Option_Values, Field.Option_Labels, "dark");
            Append_Option (Field.Option_Values, Field.Option_Labels, "light");
            Append_Option (Field.Option_Values, Field.Option_Labels, "default");
         elsif To_String (Row.Key) = Editor.Settings.Setting_Name_Line_Numbers then
            Append_Option (Field.Option_Values, Field.Option_Labels, "absolute");
            Append_Option (Field.Option_Values, Field.Option_Labels, "relative");
            Append_Option (Field.Option_Values, Field.Option_Labels, "hybrid");
            Append_Option (Field.Option_Values, Field.Option_Labels, "off");
         elsif To_String (Row.Key) = Editor.Settings.Setting_Name_Cursor_Style then
            Append_Option (Field.Option_Values, Field.Option_Labels, "bar");
            Append_Option (Field.Option_Values, Field.Option_Labels, "block");
            Append_Option (Field.Option_Values, Field.Option_Labels, "underline");
         end if;
      end if;

      return Field;
   end To_Field;

   function Status_Text
     (Snapshot : Editor.Settings_Management.Settings_Surface_Snapshot) return String
   is
   begin
      if Snapshot.Pending_Reset_All then
         return To_String (Snapshot.Confirmation_Message);
      else
         return To_String (Snapshot.Audit_Summary)
           & (if Length (Snapshot.Domain_Summary) > 0
              then " — " & To_String (Snapshot.Domain_Summary)
              else "");
      end if;
   end Status_Text;

   procedure Build_Frame
     (Snapshot          : Editor.Settings_Management.Settings_Surface_Snapshot;
      Layout_Config     : Editor.Layout.Layout_Config;
      Viewport_Width    : Natural;
      Viewport_Height   : Natural;
      Cell_H            : Positive;
      Visible           : out Boolean;
      Rectangles        : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text              : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility     : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Pane : constant Guikit.Layout.Settings_Pane_Layout :=
        Guikit.Layout.Calculate_Settings_Pane_Layout
          (Viewport_Width,
           Viewport_Height,
           0,
           Cell_H);
      Fields : Guikit.Settings_Panel.Field_Vectors.Vector;
      Panel : Guikit.Settings_Panel.Panel;
      Selected_Field_Index : Natural := 0;
   begin
      Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Visible
        and then Viewport_Width > 0
        and then Viewport_Height > 0
        and then Pane.Width > 0
        and then Pane.Height > 0;
      if not Visible then
         return;
      end if;

      for I in 1 .. Snapshot.Display_Row_Count loop
         declare
            Row : constant Editor.Settings_Management.Setting_Row :=
              Snapshot.Display_Rows (I);
         begin
            Fields.Append (To_Field (Row));
            if Row.Selected then
               Selected_Field_Index := Natural (Fields.Length);
            end if;
         end;
      end loop;

      Guikit.Settings_Panel.Set_Configuration
        (Panel,
         (Line_Height    => Cell_H,
          Title          => To_Unbounded_String ("Settings"),
          Status         => To_Unbounded_String (Status_Text (Snapshot)),
          Status_Is_Error => Snapshot.Invalid_Count > 0,
          Switch_Tooltip  => Null_Unbounded_String));
      Guikit.Settings_Panel.Set_Fields (Panel, Fields);
      if Selected_Field_Index > 1 then
         Guikit.Settings_Panel.Move_Focus (Panel, Integer (Selected_Field_Index - 1));
      end if;

      Guikit.Settings_Panel.Build_Frame
        (Panel,
         Region_X      => Pane.X,
         Region_Y      => Pane.Y,
         Region_Width  => Pane.Width,
         Region_Height => Pane.Height,
         Clip_Width    => Viewport_Width,
         Clip_Height   => Viewport_Height,
         Focused       => Snapshot.Focused,
         Hover_X       => -1,
         Hover_Y       => -1,
         Rectangles    => Rectangles,
         Text          => Text,
         Accessibility => Accessibility);
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Snapshot       : Editor.Settings_Management.Settings_Surface_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Rectangles    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Snapshot          => Snapshot,
         Layout_Config     => Layout_Config,
         Viewport_Width    => Viewport_Width,
         Viewport_Height   => Viewport_Height,
         Cell_H            => Cell_H,
         Visible           => Visible,
         Rectangles        => Rectangles,
         Text              => Text,
         Accessibility     => Accessibility);

      if Visible then
         for R of Rectangles loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Settings_Background_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Settings_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Settings_Management.Surface_Rendering;
