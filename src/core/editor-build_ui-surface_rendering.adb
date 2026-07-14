with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Feature_Diagnostics;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.View;
with Guikit.Draw;
with Guikit.List_Panel;
with Guikit.Widgets;

package body Editor.Build_UI.Surface_Rendering is

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
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Columns - 2) & "~";
      end if;
   end Truncate_To_Columns;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (State);
      Row_Count : constant Natural := Natural (Snapshot.Actions.Length);
      Suppressed_Count : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
          (State.Feature_Diagnostics);
      Displayed_Suppressed_Count : constant Natural :=
        Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
          (Text_Viewport_Height => Editor.Layout.Text_Viewport_Height (Layout_Config, Viewport_Height),
           Cell_H               => Cell_H,
           Action_Count         => Row_Count,
           Suppressed_Count     => Suppressed_Count);
      Suppressed_Top_Row : constant Natural :=
        Editor.Feature_Diagnostics.Suppressed_Top_Row
          (State.Feature_Diagnostics, Displayed_Suppressed_Count);
      Selected_Suppressed : constant Natural :=
        Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
          (State.Feature_Diagnostics);
      Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
        Editor.Build_UI_Panel_Layout.Layout
          (Viewport_Width       => Viewport_Width,
           Text_Viewport_Y      => Natural (Editor.Layout.Text_Viewport_Y (Layout_Config)),
           Text_Viewport_Height => Editor.Layout.Text_Viewport_Height (Layout_Config, Viewport_Height),
           Cell_H               => Cell_H,
           Action_Count         => Row_Count,
           Suppressed_Count     => Displayed_Suppressed_Count);
      Width : constant Float := Float (Geometry.W);
      X : constant Float := Float (Geometry.X);
      Y : constant Float := Float (Geometry.Y);
      H : constant Float := Float (Geometry.H);
      Text_X : constant Float := X + Float (Cell_W);
      Text_Columns : constant Natural :=
        (if Natural (Width) / Cell_W > 2 then Natural (Width) / Cell_W - 2 else 0);
      Visible_Rows : constant Natural :=
        Editor.Build_UI_Panel_Layout.Visible_Row_Count (Geometry, Cell_H);
      Visible_Action_Rows : constant Natural :=
        (if Visible_Rows > Geometry.Action_Start_Row
         then Natural'Min
           (Row_Count, Visible_Rows - Geometry.Action_Start_Row)
         else 0);
      Action_Top_Row : constant Natural :=
        Editor.Build_UI.Action_Top_Row
          (State.Build_UI, Row_Count, Visible_Action_Rows);
   begin
      Background_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := Snapshot.Visible
        and then Width > 0.0
        and then H > 0.0;
      if not Visible then
         return;
      end if;

      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => Natural (Width),
            Height => Natural (H),
            Color => Guikit.Draw.Pane_Color));
      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => Natural (Width),
            Height => Natural (Cell_H),
            Color => Guikit.Draw.Pane_Color));

      Push_Text
        (Text,
         Truncate_To_Columns
           ("Build UI  " & To_String (Snapshot.Candidate_Count_Label),
            Text_Columns),
         Text_X, Y, Guikit.Draw.Text_Color);
      Push_Text
        (Text,
         Truncate_To_Columns
           (To_String (Snapshot.Request_Status_Label)
            & "  "
            & To_String (Snapshot.Run_Command_Status_Label),
            Text_Columns),
         Text_X, Y + Float (Cell_H), Guikit.Draw.Text_Color);

      if Row_Count = 0 and then Suppressed_Count = 0 then
         Push_Text
           (Text, "No build actions", Text_X, Y + Float (2 * Cell_H),
            Guikit.Draw.Text_Color);
      elsif Length (Snapshot.Diagnostics_View.Quick_Fix_Label) > 0
        or else Length (Snapshot.Diagnostics_View.Quick_Fix_Detail) > 0
      then
         Push_Text
           (Text,
            Truncate_To_Columns
              (To_String (Snapshot.Diagnostics_View.Quick_Fix_Label),
               Text_Columns),
            Text_X, Y + Float (2 * Cell_H), Guikit.Draw.Text_Color);
         Push_Text
           (Text,
            Truncate_To_Columns
              (To_String (Snapshot.Diagnostics_View.Quick_Fix_Detail),
               Text_Columns),
            Text_X, Y + Float (3 * Cell_H), Guikit.Draw.Text_Color);
      elsif Visible_Action_Rows > 0 then
         declare
            Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
            Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
            Texts : Guikit.Draw.Text_Command_Vectors.Vector;
            Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
              (Title               => Null_Unbounded_String,
               Empty_State         => Null_Unbounded_String,
               Line_Height         => Cell_H,
               Text_Padding        => Cell_W,
               Show_Alternate_Rows => False);
         begin
            for Visible_Offset in 0 .. Visible_Action_Rows - 1 loop
               declare
                  Offset : constant Natural := Action_Top_Row - 1 + Visible_Offset;
                  Row : constant Editor.Build_UI.Build_UI_Action_Row :=
                    Snapshot.Actions.Element (Offset);
                  Reason : constant String := To_String (Row.Disabled_Reason);
                  Base_Text : constant String :=
                    (if Row.Enabled or else Reason'Length = 0 then To_String (Row.Label)
                     else To_String (Row.Label) & " - " & Reason);
                  Detail_Text : constant String :=
                    (if To_String (Row.Command_Name) = "ada.diagnostic.apply-quick-fix"
                       and then
                         To_String (Snapshot.Diagnostics_View.Quick_Fix_Detail)'Length > 0
                     then Base_Text & " - " &
                       To_String (Snapshot.Diagnostics_View.Quick_Fix_Detail)
                     else Base_Text);
               begin
                  Rows.Append
                    (Guikit.List_Panel.List_Panel_Row'
                       (Label            => To_Unbounded_String
                          (Truncate_To_Columns (Detail_Text, Text_Columns)),
                        Detail           => Null_Unbounded_String,
                        Shortcut         => Null_Unbounded_String,
                        Selected         => Row.Selected,
                        Enabled          => Row.Enabled,
                        Label_Color      => Guikit.Draw.Text_Color,
                        Has_Background   => False,
                        Background_Color => Guikit.Draw.Pane_Color,
                        Accent_Color     => Guikit.Draw.Border_Color,
                        Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
               end;
            end loop;

            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Rectangles,
               Text          => Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Geometry.X),
               Region_Y      => Natural (Geometry.Y + Integer (Geometry.Action_Start_Row * Cell_H)),
               Region_Width  => Natural (Width),
               Region_Height => Visible_Action_Rows * Cell_H,
               Config        => Config_Panel,
               Rows          => Rows,
               Draw_Chrome   => False);

            for R of Rectangles loop
               Row_Rectangles.Append (R);
            end loop;
            for T of Texts loop
               Text.Append (T);
            end loop;
         end;
      end if;

      if Suppressed_Count > 0
        and then Displayed_Suppressed_Count > 0
        and then Geometry.Suppressed_Header_Row < Visible_Rows
      then
         Push_Text
           (Text,
            Truncate_To_Columns
              ("Suppressed diagnostics"
               & (if Suppressed_Count > Displayed_Suppressed_Count
                  then " "
                    & Natural'Image (Suppressed_Top_Row)
                    & "-"
                    & Natural'Image
                      (Natural'Min
                         (Suppressed_Count,
                          Suppressed_Top_Row + Displayed_Suppressed_Count - 1))
                    & "/"
                    & Natural'Image (Suppressed_Count)
                  else ""),
               Text_Columns),
            Text_X,
            Y + Float (Geometry.Suppressed_Header_Row * Cell_H),
            Guikit.Draw.Text_Color);

         declare
            Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
            Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
            Texts : Guikit.Draw.Text_Command_Vectors.Vector;
            Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
              (Title               => Null_Unbounded_String,
               Empty_State         => Null_Unbounded_String,
               Line_Height         => Cell_H,
               Text_Padding        => Cell_W,
               Show_Alternate_Rows => True);
         begin
            for Visible_Row in 1 .. Displayed_Suppressed_Count loop
               declare
                  Row : constant Natural :=
                    Suppressed_Top_Row + Visible_Row - 1;
                  Selected : constant Boolean := Row = Selected_Suppressed;
                  Row_Text : constant String :=
                    Editor.Feature_Diagnostics.Suppressed_Diagnostic_Text
                      (State.Feature_Diagnostics, Positive (Row));
               begin
                  Rows.Append
                    (Guikit.List_Panel.List_Panel_Row'
                       (Label            => To_Unbounded_String
                          (Truncate_To_Columns (Row_Text, Text_Columns)),
                        Detail           => Null_Unbounded_String,
                        Shortcut         => Null_Unbounded_String,
                        Selected         => Selected,
                        Enabled          => True,
                        Label_Color      => Guikit.Draw.Text_Color,
                        Has_Background   => False,
                        Background_Color => Guikit.Draw.Pane_Color,
                        Accent_Color     => Guikit.Draw.Border_Color,
                        Shortcut_Color   => Guikit.Draw.Muted_Text_Color));
               end;
            end loop;

            Guikit.List_Panel.Draw_Frame
              (Rectangles    => Rectangles,
               Text          => Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Geometry.X),
               Region_Y      => Natural (Geometry.Y + Integer (Geometry.Suppressed_Start_Row * Cell_H)),
               Region_Width  => Natural (Width),
               Region_Height => Displayed_Suppressed_Count * Cell_H,
               Config        => Config_Panel,
               Rows          => Rows,
               Draw_Chrome   => False);

            for R of Rectangles loop
               Row_Rectangles.Append (R);
            end loop;
            for T of Texts loop
               Text.Append (T);
            end loop;
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
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text           : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
   begin
      Build_Frame
        (State                 => State,
         Layout_Config         => Layout_Config,
         Viewport_Width        => Viewport_Width,
         Viewport_Height       => Viewport_Height,
         Cell_W                => Cell_W,
         Cell_H                => Cell_H,
         Visible               => Visible,
         Background_Rectangles => Background_Rectangles,
         Row_Rectangles        => Row_Rectangles,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background_Rectangles loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Build_UI_Background_Layer, R);
         end loop;
         for R of Row_Rectangles loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Build_UI_Row_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Build_UI_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Build_UI.Surface_Rendering;
