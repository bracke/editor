with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Bookmarks.Surface_Rendering;
with Editor.Build_UI.Surface_Rendering;
with Editor.Feature_Panel.Surface_Rendering;
with Editor.File_Tree.Surface_Rendering;
with Editor.Input_Bridge;
with Editor.Keybinding_Management;
with Editor.Keybinding_Management.Surface_Projection;
with Editor.Keybinding_Management.Surface_Rendering;
with Editor.Layout;
with Editor.Render_Model;
with Editor.Panels;
with Editor.Render_Layers; use Editor.Render_Layers;
with Editor.Render_Packet.Debug_Support;
with Editor.Render_Packet.Geometry;
with Editor.Render_Packet.Render_Context;
with Editor.Render_Packet.Surface_Registry; use Editor.Render_Packet.Surface_Registry;
with Editor.State;
with Editor.Tab_Bar.Surface_Rendering;
with Editor.Theme;
with Editor.View;
with Guikit.Draw;

package body Editor.Render_Packet.Chrome_Surfaces is

   use Editor.Render_Packet.Geometry;

   use Editor.Render_Packet.Debug_Support;

   File_Tree_Focused_Border_Color : constant Editor.Theme.Color_RGB :=
     Editor.Theme.File_Tree_Focused_Border;

   procedure Render
     (Packet : in out Render_Packet;
      Context : Editor.Render_Packet.Render_Context.Context)
   is
      Snap   : Editor.Render_Model.Render_Snapshot renames Context.Snap;
      S      : Editor.State.State_Type renames Context.State;
      Layout : Editor.Layout.Layout_Config renames Context.Layout;
      Cell_W : Positive renames Context.Cell_W;
      Cell_H : Positive renames Context.Cell_H;
      procedure Push_Tab_Bar
        (Packet : in out Render_Packet)
      is
         Visible : Boolean := False;
      begin
         Editor.Tab_Bar.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end Push_Tab_Bar;

      procedure Push_File_Tree
        (Packet : in out Render_Packet)
      is
         Focused : constant Boolean := Editor.Input_Bridge.File_Tree_Focused_For_Render;
         begin
            Editor.File_Tree.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
         if Focused then
            declare
               Geometry : constant Editor.Layout.Rect :=
                 Editor.Layout.Panel_Rect
                   (Layout,
                    Editor.Panels.File_Tree_Panel,
                    Editor.View.Viewport_Width,
                    Editor.View.Viewport_Height);
            begin
               Push_Rect
                 (Packet, File_Tree_Separator_Layer,
                  Float (Geometry.X), Float (Geometry.Y),
                  2.0, Float (Geometry.Height),
                  File_Tree_Focused_Border_Color.R,
                  File_Tree_Focused_Border_Color.G,
                  File_Tree_Focused_Border_Color.B);
            end;
         end if;
      end Push_File_Tree;

      function Truncate_Right
        (Text    : String;
         Columns : Natural) return String
      is
      begin
         if Text'Length <= Columns then
            return Text;
         elsif Columns <= 3 then
            return Text (Text'First .. Text'First + Columns - 1);
         else
            return Text (Text'First .. Text'First + Columns - 4) & "...";
         end if;
      end Truncate_Right;

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

      procedure Push_Build_UI_Panel
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Visible : Boolean;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Row_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Text : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Build_UI.Surface_Rendering.Build_Packet
           (Packet                => Packet,
            State                 => S,
            Layout_Config         => Layout,
            Viewport_Width        => Editor.View.Viewport_Width,
            Viewport_Height       => Text_Viewport_Height (Context),
            Cell_W                => Cell_W,
            Cell_H                => Cell_H,
            Visible               => Visible,
            Background_Rectangles => Background_Rectangles,
            Row_Rectangles        => Row_Rectangles,
            Text                  => Text,
            Accessibility         => Accessibility);
         for T of Text loop
            Editor.Render_Packet.Debug_Support.Record_Debug_Text_For_Test
              (To_String (T.Text));
         end loop;
      end Push_Build_UI_Panel;

      function Surface_Name_For (Text : String) return Surface_Name
      is
         Result : Surface_Name := (others => ' ');
         Last   : constant Natural := Natural'Min (Text'Length, Result'Length);
      begin
         if Last > 0 then
            Result (Result'First .. Result'First + Last - 1) :=
              Text (Text'First .. Text'First + Last - 1);
         end if;
         return Result;
      end Surface_Name_For;

      Surface_Order : constant array (Positive range <>) of Surface_Renderer :=
        ((Id    => Tab_Bar_Surface,
          Name  => Surface_Name_For ("tab-bar"),
          Group => Chrome_Surface_Group),
         (Id    => File_Tree_Surface,
          Name  => Surface_Name_For ("file-tree"),
          Group => Panel_Surface_Group),
         (Id    => Feature_Panel_Surface,
          Name  => Surface_Name_For ("feature-panel"),
          Group => Panel_Surface_Group),
         (Id    => Keybinding_Management_Surface,
          Name  => Surface_Name_For ("keybindings"),
          Group => Overlay_Surface_Group),
         (Id    => Bookmarks_Surface,
          Name  => Surface_Name_For ("bookmarks"),
          Group => Overlay_Surface_Group),
         (Id    => Build_UI_Surface,
          Name  => Surface_Name_For ("build-ui"),
          Group => Panel_Surface_Group));

      procedure Render_Surface
        (Renderer : Surface_Renderer;
         Packet   : in out Render_Packet)
      is
      begin
         case Renderer.Id is
            when Tab_Bar_Surface =>
               Push_Tab_Bar (Packet);
            when File_Tree_Surface =>
               Push_File_Tree (Packet);
            when Feature_Panel_Surface =>
               Editor.Feature_Panel.Surface_Rendering.Build_Packet
                 (Packet         => Packet,
                  Panel          => Editor.Input_Bridge.Feature_Panel_For_Render,
                  Layout_Config  => Layout,
                  Viewport_Width => Editor.View.Viewport_Width,
                  Viewport_Height => Editor.View.Viewport_Height,
                  Cell_W         => Cell_W,
                  Cell_H         => Cell_H);
            when Keybinding_Management_Surface =>
               declare
                  Surface : constant Editor.Keybinding_Management.Keybinding_Surface_Snapshot :=
                    Snap.Keybindings_UI;
                  Text_Columns : constant Natural :=
                    (if Cell_W = 0 or else Editor.View.Viewport_Width = 0 then 0
                     else
                       (if Natural'Min (420, Editor.View.Viewport_Width) / Cell_W > 2
                        then Natural'Min (420, Editor.View.Viewport_Width) / Cell_W - 2
                        else 0));
                  Projection : constant
                    Editor.Keybinding_Management.Surface_Projection.Keybinding_Surface_Render_Projection :=
                    Editor.Keybinding_Management.Surface_Projection.Project
                      (Surface, Text_Columns);
               begin
                  Editor.Keybinding_Management.Surface_Rendering.Build_Packet
                    (Packet          => Packet,
                     Surface         => Surface,
                     Projection      => Projection,
                     Viewport_Width  => Editor.View.Viewport_Width,
                     Viewport_Height => Editor.View.Viewport_Height,
                     Text_Viewport_Y => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
                     Cell_W          => Cell_W,
                     Cell_H          => Cell_H);
               end;
            when Bookmarks_Surface =>
               Editor.Bookmarks.Surface_Rendering.Build_Packet
                 (Packet         => Packet,
                  Snapshot       => Snap,
                  Layout_Config  => Layout,
                  Viewport_Width => Editor.View.Viewport_Width,
                  Viewport_Height => Editor.View.Viewport_Height,
                  Cell_W         => Cell_W,
                  Cell_H         => Cell_H);
            when Build_UI_Surface =>
               Push_Build_UI_Panel (Packet);
         end case;
      end Render_Surface;
   begin
      for Renderer of Surface_Order loop
         Render_Surface (Renderer, Packet);
      end loop;
   end Render;

end Editor.Render_Packet.Chrome_Surfaces;
