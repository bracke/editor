with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Layout;
with Editor.Feature_Panel;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Theme;
with Guikit.List_Panel;

package body Editor.Feature_Panel.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   procedure Build_Frame
     (Panel          : Editor.Feature_Panel.Feature_Panel_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Rectangles     : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Snapshot : constant Editor.Feature_Panel.Feature_Panel_Render_Snapshot :=
        Editor.Feature_Panel.Build_Render_Snapshot (Panel);
      Width : constant Float := Float'Min (280.0, Float (Viewport_Width));
      X : constant Float := Float (Viewport_Width) - Width;
      Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout_Config));
      H : constant Float := Float (Editor.Layout.Text_Viewport_Height (Layout_Config, Viewport_Height));
   begin
      Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if not Editor.Feature_Panel.Snapshot_Is_Visible (Snapshot) then
         return;
      end if;

      Visible := True;
      declare
         Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
         Config : constant Guikit.List_Panel.List_Panel_Configuration :=
           (Title               => To_Unbounded_String (Editor.Feature_Panel.Snapshot_Header_Text (Snapshot)),
            Empty_State         => To_Unbounded_String (Editor.Feature_Panel.Snapshot_Empty_Message (Snapshot)),
            Line_Height         => Cell_H,
            Text_Padding        => Cell_W,
            Show_Alternate_Rows => True);
      begin
         for I in 1 .. Editor.Feature_Panel.Snapshot_Row_Count (Snapshot) loop
            declare
               Is_Selected : constant Boolean :=
                 Editor.Feature_Panel.Snapshot_Row_Selected (Snapshot, I);
               Is_Current_Symbol : constant Boolean :=
                 Editor.Feature_Panel.Snapshot_Row_Is_Current_Symbol (Snapshot, I);
               Label : constant String :=
                 Editor.Feature_Panel.Snapshot_Row_Label (Snapshot, I);
               Detail : constant String :=
                 Editor.Feature_Panel.Snapshot_Row_Detail (Snapshot, I);
            begin
               Rows.Append
                 (Guikit.List_Panel.List_Panel_Row'
                    (Label            => To_Unbounded_String (Label),
                     Detail           => To_Unbounded_String (Detail),
                     Shortcut         => Null_Unbounded_String,
                     Selected         => Is_Selected,
                     Enabled          => True,
                     Label_Color      => Guikit.Draw.Text_Color,
                     Has_Background   => Is_Current_Symbol and then not Is_Selected,
                     Background_Color => Guikit.Draw.Hover_Color,
                     Accent_Color     =>
                       (if Is_Current_Symbol then Guikit.Draw.Label_Orange_Color
                        else Guikit.Draw.Border_Color),
                     Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
            end;
         end loop;

         declare
            Local_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
            Local_Texts      : Guikit.Draw.Text_Command_Vectors.Vector;
         begin
            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Local_Rectangles,
               Text          => Local_Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Float'Floor (X)),
               Region_Y      => Natural (Float'Floor (Y)),
               Region_Width  => Natural (Width),
               Region_Height => Natural (H),
               Config        => Config,
               Rows          => Rows);

            for R of Local_Rectangles loop
               Rectangles.Append (R);
            end loop;
            for T of Local_Texts loop
               Text.Append (T);
            end loop;
         end;
      end;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Panel          : Editor.Feature_Panel.Feature_Panel_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Rectangles    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text          : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (Panel             => Panel,
         Layout_Config     => Layout_Config,
         Viewport_Width    => Viewport_Width,
         Viewport_Height   => Viewport_Height,
         Cell_W            => Cell_W,
         Cell_H            => Cell_H,
         Visible           => Visible,
         Rectangles        => Rectangles,
         Text              => Text,
         Accessibility     => Accessibility);

      if Visible then
         for R of Rectangles loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Feature_Panel.Surface_Rendering;
