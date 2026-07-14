with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Panels;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Project_Search;
with Editor.Search_Results;
with Guikit.Draw;
with Guikit.List_Panel;

package body Editor.Search_Results.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

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
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Geometry : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout_Config,
           Editor.Panels.Bottom_Panel,
           Viewport_Width,
           Viewport_Height);
      Splitter : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Splitter_Rect
          (Layout_Config,
           Editor.Panels.Bottom_Panel,
           Viewport_Width,
           Viewport_Height);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Focused : constant Boolean :=
        Editor.Input_Bridge.Search_Results_Focused_For_Render;
   begin
      pragma Unreferenced (State);
      Background_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if Geometry.Width = 0 or else Geometry.Height = 0 then
         return;
      end if;

      Editor.Input_Bridge.Get_Search_Results_For_Render (Snapshot);
      Visible := True;

      if Splitter.Width > 0 and then Splitter.Height > 0 then
         Background_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Splitter.X),
               Y      => Natural (Splitter.Y),
               Width  => Splitter.Width,
               Height => Splitter.Height,
               Color  => Guikit.Draw.Border_Color));
      end if;

      declare
         Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
         Max_Rows : constant Natural := Geometry.Height / Cell_H;
         Rows_To_Render : constant Natural :=
           Natural'Min (Editor.Search_Results.Row_Count (Snapshot), Max_Rows);
         Config_Panel : constant Guikit.List_Panel.List_Panel_Configuration :=
           (Title               => Null_Unbounded_String,
            Empty_State         => To_Unbounded_String ("No search results"),
            Line_Height         => Cell_H,
            Text_Padding        => Cell_W,
            Show_Alternate_Rows => False);
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts      : Guikit.Draw.Text_Command_Vectors.Vector;
      begin
         for I in 1 .. Rows_To_Render loop
            declare
               Row : constant Editor.Search_Results.Search_Results_Row :=
                 Editor.Search_Results.Row (Snapshot, I);
               Label_Text : constant String := To_String (Row.Display_Text);
               Is_Match : constant Boolean :=
                 (case Row.Kind is
                    when Editor.Search_Results.Search_Results_Match_Row => True,
                    when others => False);
            begin
               Rows.Append
                 (Guikit.List_Panel.List_Panel_Row'
                    (Label            => To_Unbounded_String (Label_Text),
                     Detail           => Null_Unbounded_String,
                     Shortcut         => Null_Unbounded_String,
                     Selected         => Is_Match and then Row.Is_Selected,
                     Enabled          => (if Is_Match then Focused else False),
                     Label_Color      =>
                       (case Row.Kind is
                          when Editor.Search_Results.Search_Results_Header_Row =>
                            Guikit.Draw.Text_Color,
                          when Editor.Search_Results.Search_Results_File_Row =>
                            Guikit.Draw.Text_Color,
                          when Editor.Search_Results.Search_Results_Match_Row =>
                            Guikit.Draw.Text_Color,
                          when Editor.Search_Results.Search_Results_Empty_Row =>
                            Guikit.Draw.Muted_Text_Color),
                     Has_Background   => True,
                     Background_Color =>
                       (case Row.Kind is
                          when Editor.Search_Results.Search_Results_Header_Row =>
                            Guikit.Draw.Input_Color,
                          when Editor.Search_Results.Search_Results_File_Row =>
                            Guikit.Draw.Pane_Color,
                          when Editor.Search_Results.Search_Results_Match_Row =>
                            (if Row.Is_Selected then Guikit.Draw.Selection_Color
                             else Guikit.Draw.Pane_Color),
                          when Editor.Search_Results.Search_Results_Empty_Row =>
                            Guikit.Draw.Pane_Color),
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
            Region_X      => Geometry.X,
            Region_Y      => Geometry.Y,
            Region_Width  => Geometry.Width,
            Region_Height => Geometry.Height,
            Config        => Config_Panel,
            Rows          => Rows);

         for R of Rectangles loop
            Row_Rectangles.Append (R);
         end loop;
         for T of Texts loop
            Text.Append (T);
         end loop;
      end;

      if Focused then
         Row_Rectangles.Append
           (Guikit.Draw.Rectangle_Command'
              (X      => Natural (Geometry.X),
               Y      => Natural (Geometry.Y),
               Width  => Geometry.Width,
               Height => 1,
               Color  => Guikit.Draw.Border_Color));
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
      Rows          : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Row_Rectangles        => Rows,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Background_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.Problems_Row_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.Problems_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Search_Results.Surface_Rendering;
