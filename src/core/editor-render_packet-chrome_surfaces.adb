with Ada.Containers; use Ada.Containers;
with Interfaces.C; use Interfaces.C;
with Editor.Fonts;
with Editor.Input_Bridge;
with Editor.Input_Field;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.View;
with Editor.Wrap;
with Editor.Render_Model; use Editor.Render_Model;
with Editor.Render_Layers; use Editor.Render_Layers;
with Editor.Render_Cache;
with Editor.Render_Packet.Debug_Support;
with Editor.Syntax;
with Editor.Theme;
with Editor.Unicode;
with Editor.Minimap;
with Editor.Diagnostics;
with Editor.Cursor;
with Editor.Search;
with Editor.Command_Palette;
with Editor.Command_Palette.Surface_Rendering;
with Editor.Contextual_Help;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.Build_UI;
with Editor.Build_UI.Surface_Rendering;
with Editor.Feature_Panel.Surface_Rendering;
with Editor.Terminal_Tasks;
with Editor.Terminal_Tasks.Surface_Rendering;
with Editor.Commands;
with Editor.Settings;
with Editor.Settings_Management;
with Editor.Settings_Management.Surface_Rendering;
with Editor.Scrollbars;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Gutter.Surface_Rendering;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.Status_Bar;
with Editor.Status_Bar.Surface_Rendering;
with Editor.Messages;
with Editor.Messages.Surface_Rendering;
with Editor.Buffers;
with Guikit.Command_Palette;
with Guikit.Draw;
with Guikit.List_Panel;
with Guikit.Item_Grid;
with Guikit.Layout;
with Guikit.Segmented;
with Guikit.Settings_Panel;
with Guikit.Tree_Panel;
with Guikit.Utf8;
with Guikit.Widgets;
with Editor.Tab_Bar;
with Editor.Tab_Bar.Surface_Rendering;
with Editor.File_Tree;
with Editor.File_Tree.Surface_Rendering;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Problems;
with Editor.Problems.Surface_Rendering;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
with Editor.Buffer_Switcher;
with Editor.Buffer_Switcher.Surface_Rendering;
with Editor.Buffer_Switcher_Contextual_Hints;
use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
with Editor.Go_To_Line;
with Editor.Go_To_Line.Surface_Rendering;
with Editor.Guided_Prompts;
with Editor.Project_Search_Bar;
with Editor.Project_Search_Bar.Surface_Rendering;
use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
with Editor.Search_Results;
with Editor.Search_Results.Surface_Rendering;
with Editor.Active_Find_Prompt.Surface_Rendering;
with Editor.Guided_Prompts.Surface_Rendering;
with Editor.Project_Search;
with Editor.Project;
with Editor.Outline;
with Editor.Semantic_Popup.Surface_Rendering;
with Editor.Pending_Transitions;
with Editor.Build_Result_Summary;
with Editor.Workspace_Persistence;
with Editor.History;
with Editor.Panel_Focus;
with Editor.Pending_Transition_Bar;
with Editor.Pending_Transition_Bar.Surface_Rendering;
with Editor.Overlay_Focus;
with Editor.Focus_Management;
with Editor.Recent_Projects;
with Editor.State;
with Editor.Feature_Panel;
with Editor.Bookmarks;
with Editor.Bookmarks.Surface_Rendering;
with Editor.Buffer_Switcher.Surface_Projection;
with Editor.Keybinding_Management;
with Editor.Keybinding_Management.Surface_Projection;
with Editor.Keybinding_Management.Surface_Rendering;
with Editor.Lifecycle_Guidance;
with Editor.Startup_Readiness;
with Editor.Quick_Open.Surface_Rendering;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;
with Ada.Strings.Fixed;
use type Editor.Line_Numbers.Line_Number_Mode;
use type Editor.Gutter_Markers.Gutter_Marker_Kind;
use type Editor.Messages.Message_Severity;
use type Editor.Tab_Bar.Tab_Visual_State;
use type Editor.File_Tree.File_Tree_Node_Kind;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.Panel_Focus.Bottom_Focus_Content;
use type Editor.Overlay_Focus.Overlay_Target;
use type Editor.Problems.Problem_Row_Severity;
use type Editor.Buffers.Buffer_Id;
use type Editor.Diagnostics.Diagnostic_Index;
use type Editor.File_Tree.File_Tree_Scan_Status;
use type Editor.State.Semantic_Popup_Kind;
use type Editor.Panels.Bottom_Panel_Content;
use type Editor.Pending_Transition_Bar.Pending_Bar_Action;
use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
use type Editor.Outline.Outline_Source_Class;
use type Editor.Project_Search.Project_Search_Status;
use type Editor.Project_Search.Project_Replace_Preview_Status;
use type Editor.Build_Result_Summary.Build_Result_Summary_Kind;
use type Editor.Build_UI.Public_Build_UI_Validation_Status;
use type Editor.Terminal_Tasks.Terminal_Task_Status;
use type Editor.Commands.Command_Id;
use type Editor.Settings_Management.Setting_Value_Kind;
use type Guikit.Settings_Panel.Field_Kind;
use type Guikit.Draw.Render_Color;
use type Guikit.Item_Grid.Background_Kind;
with Editor.Render_Packet.Render_Context;
with Editor.Render_Packet.Surface_Registry; use Editor.Render_Packet.Surface_Registry;

package body Editor.Render_Packet.Chrome_Surfaces is

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
      Message_Layout : Editor.Messages.Message_Layout renames Context.Message_Layout;
      Scroll_X : Natural renames Context.Scroll_X;
      Cursor_Config : Editor.Cursor.Cursor_Config renames Context.Cursor_Config;
      Minimap : Editor.Minimap.Minimap_Config renames Context.Minimap;
      Settings : Editor.Settings.Settings_State renames Context.Settings;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config renames Context.Line_Number_Config;
      Scrollbars : Editor.Scrollbars.Scrollbar_Config renames Context.Scrollbars;
      Effective_Viewport_W : Natural renames Context.Effective_Viewport_W;
      Effective_Viewport_H : Natural renames Context.Effective_Viewport_H;
      Effective_Minimap_Enabled : Boolean renames Context.Effective_Minimap_Enabled;
      Out_Packet : Render_Packet renames Packet;
      function Line_Count return Natural is
      begin
         return Natural'Max (1, Snap.Total_Line_Count);
      end Line_Count;

      function Screen_X (C : Natural) return Float is
      begin
         return Editor.View.Visual_Screen_X
           (Layout, Line_Count, C);
      end Screen_X;

      function Screen_Y (Visible_Row : Natural) return Float is
      begin
         return Editor.View.Visual_Screen_Y (Layout, Visible_Row);
      end Screen_Y;

      function Text_Viewport_Right return Float is
      begin
         if Effective_Minimap_Enabled then
            return Editor.Layout.Text_Viewport_Right
              (Layout,
               Effective_Viewport_W,
               Minimap.Enabled,
               Minimap.Width,
               Minimap.Padding_Left,
               Minimap.Padding_Right);
         else
            return Editor.Layout.Text_Right_X
              (Layout, Effective_Viewport_W);
         end if;
      end Text_Viewport_Right;

      function Text_Viewport_Width return Natural is
      begin
         if Effective_Minimap_Enabled then
            return Editor.Layout.Text_Viewport_Width
              (Layout,
               Line_Count,
               Effective_Viewport_W,
               Minimap.Enabled,
               Minimap.Width,
               Minimap.Padding_Left,
               Minimap.Padding_Right);
         else
            return Editor.Layout.Text_Viewport_Width
              (Layout, Line_Count, Effective_Viewport_W);
         end if;
      end Text_Viewport_Width;

      function Scrollbar_Viewport_Height return Natural is
      begin
         return Editor.Layout.Text_Viewport_Height
           (Layout, Editor.View.Viewport_Height);
      end Scrollbar_Viewport_Height;

      function Text_Viewport_Height return Natural is
      begin
         return Editor.Layout.Text_Viewport_Height
           (Layout, Effective_Viewport_H);
      end Text_Viewport_Height;
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

      procedure Push_Active_Find_Prompt
        (Packet : in out Render_Packet)
      is
      begin
         Editor.Active_Find_Prompt.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end Push_Active_Find_Prompt;

      procedure Push_Guided_Prompt
        (Packet : in out Render_Packet)
      is
      begin
         Editor.Guided_Prompts.Surface_Rendering.Build_Packet
           (Packet         => Packet,
            Snapshot       => Snap.Guided_Prompt,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end Push_Guided_Prompt;


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
            Viewport_Height       => Text_Viewport_Height,
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
