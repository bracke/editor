with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Contextual_Help;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Panels;
with Editor.View;
with Guikit.Draw;
with Guikit.Tree_Panel;

package body Editor.File_Tree.Surface_Rendering is

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
     (Snapshot       : Editor.Render_Model.Render_Snapshot;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Separator_Rectangles  : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Splitter_Rectangles   : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Row_Rectangles        : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Text                  : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility         : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Tree : Editor.File_Tree.File_Tree_State;
      Geometry : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout_Config,
           Editor.Panels.File_Tree_Panel,
           Viewport_Width,
           Viewport_Height);
      W : constant Natural := Geometry.Width;
      H : constant Natural := Geometry.Height;
      X : constant Float := Float (Geometry.X);
      Y : constant Float := Float (Geometry.Y);
      Max_Rows : constant Natural := H / Cell_H;
      Text_Columns : constant Natural :=
        (if W / Cell_W > 1 then W / Cell_W - 1 else 0);
      Active_Node : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Active_Found : Boolean := False;
      View_State : Editor.File_Tree_View.File_Tree_View_State :=
        Editor.Input_Bridge.File_Tree_View_For_Render;
      Emitted_Row : Natural := 0;
   begin
      Background_Rectangles.Clear;
      Separator_Rectangles.Clear;
      Splitter_Rectangles.Clear;
      Row_Rectangles.Clear;
      Text.Clear;
      Accessibility.Clear;
      Visible := False;

      if W = 0 or else H = 0 then
         return;
      end if;

      Editor.Input_Bridge.Get_File_Tree_For_Render (Tree);
      Visible := True;

      if Editor.Buffers.Global_Current_File.Has_Path then
         Active_Node := Editor.File_Tree.Find_By_Path
           (Tree, To_String (Editor.Buffers.Global_Current_File.Path), Active_Found);
      end if;

      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => W,
            Height => H,
            Color => Guikit.Draw.Pane_Color,
            others => <>));

      Separator_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X => Natural (Float'Floor (X + Float (W) - 1.0)),
            Y => Natural (Float'Floor (Y)),
            Width => 1,
            Height => H,
            Color => Guikit.Draw.Border_Color,
            others => <>));

      declare
         Splitter : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Splitter_Rect
             (Layout_Config,
              Editor.Panels.File_Tree_Panel,
              Viewport_Width,
              Viewport_Height);
      begin
         if Splitter.Width > 0 and then Splitter.Height > 0 then
            Splitter_Rectangles.Append
              (Guikit.Draw.Rectangle_Command'
                 (X => Natural (Splitter.X),
                  Y => Natural (Splitter.Y),
                  Width => Splitter.Width,
                  Height => Splitter.Height,
                  Color => Guikit.Draw.Border_Color,
                  others => <>));
         end if;
      end;

      if Max_Rows = 0 then
         return;
      end if;

      if Editor.File_Tree.Is_Empty (Tree) then
         Push_Text
           (Text,
            Editor.File_Tree_View.Truncate_Label
              (Editor.Contextual_Help.Empty_File_Tree_Text (Snapshot.Has_Project),
               Text_Columns),
            X + Float (Cell_W), Y,
            Guikit.Draw.Muted_Text_Color);
         return;
      end if;

      Editor.File_Tree_View.Ensure_Selected_Row_Visible
        (View_State, Tree, Max_Rows);

      declare
         Rows : Guikit.Tree_Panel.Tree_Panel_Row_Vectors.Vector;
         Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Config_Panel : constant Guikit.Tree_Panel.Tree_Panel_Configuration :=
           (Title               => Null_Unbounded_String,
            Empty_State         => Null_Unbounded_String,
            Line_Height         => Cell_H,
            Text_Padding        => Cell_W,
            Show_Alternate_Rows => False,
            Indent_In_Columns   => Layout_Config.File_Tree_View.Indent_In_Columns,
            Show_Indent_Guides  => Layout_Config.File_Tree_View.Show_Indent_Guides,
            Guide_Color         => Guikit.Draw.Muted_Text_Color);
      begin
         for Row_Index in View_State.Top_Row .. Editor.File_Tree.Visible_Row_Count (Tree) loop
            exit when Emitted_Row >= Max_Rows;

            declare
               Display_Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
                 Editor.File_Tree_View.Visible_Row_Summary
                   (Layout_Config.File_Tree_View, Tree, Row_Index);
            begin
               if Display_Node.Id /= Editor.File_Tree.No_File_Tree_Node then
                  declare
                     Is_Active : constant Boolean :=
                       Active_Found and then Display_Node.Id = Active_Node;
                     Is_Selected : constant Boolean :=
                       Row_Index = View_State.Selected_Row_Index;
                     Row_Text : constant String :=
                       Editor.File_Tree_View.Format_Row_Text
                         (Layout_Config.File_Tree_View, Display_Node, Text_Columns);
                  begin
                     Rows.Append
                       (Guikit.Tree_Panel.Tree_Panel_Row'
                          (Row =>
                             (Label            => To_Unbounded_String (Row_Text),
                              Detail           => Null_Unbounded_String,
                              Shortcut         => Null_Unbounded_String,
                              Selected         => Is_Selected,
                              Enabled          => True,
                              Label_Color      =>
                                (if Display_Node.Kind = Editor.File_Tree.Directory_Node then
                                    Guikit.Draw.Icon_Directory_Color
                                 else
                                    Guikit.Draw.Text_Color),
                              Has_Background   => Is_Active and then not Is_Selected,
                              Background_Color => Guikit.Draw.Hover_Color,
                              Accent_Color     => Guikit.Draw.Border_Color,
                              Shortcut_Color   => Guikit.Draw.Muted_Text_Color),
                           Depth => Display_Node.Depth));
                     Emitted_Row := Emitted_Row + 1;
                  end;
               end if;
            end;
         end loop;

         if Emitted_Row > 0 then
            Guikit.Tree_Panel.Draw_Frame
              (Rectangles    => Rectangles,
               Text          => Texts,
               Accessibility => Accessibility,
               Clip_Width    => Viewport_Width,
               Clip_Height   => Viewport_Height,
               Region_X      => Natural (Float'Floor (X)),
               Region_Y      => Natural (Float'Floor (Y)),
               Region_Width  => W,
               Region_Height => Emitted_Row * Cell_H,
               Config        => Config_Panel,
               Rows          => Rows,
               Draw_Chrome   => False);

            for R of Rectangles loop
               Row_Rectangles.Append (R);
            end loop;
            for T of Texts loop
               Text.Append (T);
            end loop;
         end if;
      end;
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
      Separator     : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Splitter      : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Rows          : Guikit.Draw.Rectangle_Command_Vectors.Vector;
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
         Separator_Rectangles  => Separator,
         Splitter_Rectangles   => Splitter,
         Row_Rectangles        => Rows,
         Text                  => Text,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.File_Tree_Background_Layer, R);
         end loop;
         for R of Separator loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.File_Tree_Separator_Layer, R);
         end loop;
         for R of Splitter loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.File_Tree_Splitter_Layer, R);
         end loop;
         for R of Rows loop
            Push_Guikit_Rectangle (Packet, Editor.Render_Layers.File_Tree_Row_Highlight_Layer, R);
         end loop;
         for T of Text loop
            Push_Guikit_Text (Packet, Editor.Render_Layers.File_Tree_Text_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.File_Tree.Surface_Rendering;
