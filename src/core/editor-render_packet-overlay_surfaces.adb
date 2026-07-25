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

package body Editor.Render_Packet.Overlay_Surfaces is

   use type Editor.Wrap.Wrap_Mode;

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
      function In_Viewport (X, Y, W, H : Float) return Boolean is
         Left : constant Float :=
           Float (Editor.Layout.Text_Origin_X (Layout, Line_Count));
         Right : constant Float := Text_Viewport_Right;
         Top : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         Bottom : constant Float :=
           Editor.Layout.View_Bottom_Y (Layout, Effective_Viewport_H);
      begin
         if Editor.View.Viewport_Width = 0
           or else Editor.View.Viewport_Height = 0
         then
            --  Preserve test/default rendering when no runtime viewport
            --  has been installed.  Constrained real viewports are clipped by
            --  the computed text/gutter bounds below.
            return True;
         elsif Right <= Left or else Bottom <= Top then
            return False;
         end if;

         return X + W > Left
           and then X < Right
           and then Y + H > Top
           and then Y < Bottom;
      end In_Viewport;

      function In_Gutter_Viewport (X, Y, W, H : Float) return Boolean is
         Left : constant Float := Editor.Layout.Gutter_Left (Layout);
         Right : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count);
         Top : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         Bottom : constant Float :=
           Editor.Layout.View_Bottom_Y (Layout, Effective_Viewport_H);
      begin
         if Editor.View.Viewport_Width = 0
           or else Editor.View.Viewport_Height = 0
         then
            --  Preserve test/default rendering when no runtime viewport
            --  has been installed.  Constrained real viewports are clipped by
            --  the computed text/gutter bounds below.
            return True;
         elsif Right <= Left or else Bottom <= Top then
            return False;
         end if;

         return X + W > Left
           and then X < Right
           and then Y + H > Top
           and then Y < Bottom;
      end In_Gutter_Viewport;

      function Text_End_Index return Natural is
      begin
         return Snap.Text_Base_Index + Snap.Length;
      end Text_End_Index;

      function Has_Row_Start (Target_Row : Natural) return Boolean is
      begin
         return Snap.Line_Starts.Length > 0
           and then Target_Row >= Snap.Line_Start_Row_Base
           and then Target_Row - Snap.Line_Start_Row_Base <= Snap.Line_Starts.Last_Index;
      end Has_Row_Start;

      function Local_Row_Index (Target_Row : Natural) return Natural is
      begin
         return Target_Row - Snap.Line_Start_Row_Base;
      end Local_Row_Index;

      function Index_For_Row_Start (Target_Row : Natural) return Natural is
      begin
         if Has_Row_Start (Target_Row) then
            return Snap.Line_Starts.Element (Local_Row_Index (Target_Row));
         else
            return Text_End_Index;
         end if;
      end Index_For_Row_Start;

      function Row_End_Index (Target_Row : Natural) return Natural is
         Row_Start : constant Natural := Index_For_Row_Start (Target_Row);
         Row_End   : Natural := Text_End_Index;
      begin
         if Has_Row_Start (Target_Row + 1) then
            declare
               Next_Start : constant Natural := Index_For_Row_Start (Target_Row + 1);
            begin
               if Next_Start > Row_Start then
                  Row_End := Next_Start - 1;
               else
                  Row_End := Row_Start;
               end if;
            end;
         end if;
         return Natural'Min (Row_End, Text_End_Index);
      end Row_End_Index;

      function Row_For_Index (Index : Natural) return Natural is
         Lo  : Natural := 0;
         Hi  : Natural := 0;
         Mid : Natural := 0;
      begin
         if Snap.Line_Starts.Length = 0 then
            return 0;
         end if;
         if Index < Snap.Line_Starts.Element (0) then
            return 0;
         end if;
         Hi := Snap.Line_Starts.Last_Index;
         while Lo <= Hi loop
            Mid := (Lo + Hi) / 2;
            if Snap.Line_Starts.Element (Mid) <= Index then
               if Mid = Snap.Line_Starts.Last_Index
                 or else Snap.Line_Starts.Element (Mid + 1) > Index
               then
                  return Snap.Line_Start_Row_Base + Mid;
               end if;
               Lo := Mid + 1;
            else
               exit when Mid = 0;
               Hi := Mid - 1;
            end if;
         end loop;
         return 0;
      end Row_For_Index;

      procedure Row_Col_For_Index
        (Index : Natural;
         Row   : out Natural;
         Col   : out Natural)
      is
         Start : Natural := 0;
      begin
         Row := Row_For_Index (Index);
         if Editor.Folding.Is_Row_Hidden (Snap.Folding, Row) then
            declare
               Found : Boolean := False;
            begin
               Row := Editor.Folding.Fold_Start_For_Hidden_Row
                 (Snap.Folding, Row, Found);
               Col := 0;
               return;
            end;
         end if;
         if Snap.Line_Starts.Length = 0 then
            Col := Index;
            return;
         end if;
         Start := Index_For_Row_Start (Row);
         if Index >= Start then
            Col := Index - Start;
         else
            Col := 0;
         end if;
      end Row_Col_For_Index;

      function Segment_Contains_Caret
        (Seg : Editor.Wrap.Visual_Row_Info;
         Col : Natural) return Boolean
      is
      begin
         if Snap.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
            return Col >= Seg.Start_Col
              and then Col <= Seg.End_Col
              and then
                (Col < Seg.End_Col
                 or else Seg.End_Col =
                   Row_End_Index (Seg.Logical_Row)
                   - Index_For_Row_Start (Seg.Logical_Row));
         else
            return True;
         end if;
      end Segment_Contains_Caret;

      function Segment_For_Caret
        (Row : Natural;
         Col : Natural) return Natural
      is
      begin
         for I in 1 .. Snap.Visible_Visual_Count loop
            declare
               Seg : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
            begin
               if Seg.Logical_Row = Row then
                  if Snap.Wrap_Mode = Editor.Wrap.Wrap_None then
                     return I;
                  elsif Segment_Contains_Caret (Seg, Col) then
                     return I;
                  end if;
               end if;
            end;
         end loop;
         return 0;
      end Segment_For_Caret;

      function Screen_Col_For
        (Seg         : Editor.Wrap.Visual_Row_Info;
         Logical_Col : Natural) return Natural
      is
      begin
         if Snap.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
            if Logical_Col >= Seg.Start_Col then
               return Logical_Col - Seg.Start_Col;
            else
               return 0;
            end if;
         else
            return Logical_Col;
         end if;
      end Screen_Col_For;

      function Selection_Affects_Text_Color return Boolean is
      begin
         return Snap.Selection_Count > 0
           or else Snap.Rectangular_Selection_Count > 0;
      end Selection_Affects_Text_Color;

      function Text_Cell_Is_Selected
        (Buffer_Index : Natural;
         Row          : Natural;
         Col          : Natural) return Boolean
      is
      begin
         for RIdx in 1 .. Snap.Rectangular_Selection_Count loop
            declare
               Span : constant Editor.Render_Model.Rectangular_Selection_Row_Span :=
                 Snap.Rectangular_Selections (RIdx);
            begin
               if Span.Row = Row
                 and then Col >= Span.Start_Column
                 and then Col < Span.End_Column
               then
                  return True;
               end if;
            end;
         end loop;

         if Snap.Rectangular_Selection_Count > 0 then
            return False;
         end if;

         for SIdx in 1 .. Snap.Selection_Count loop
            declare
               Sel_Min : constant Natural := Natural (Snap.Sel_Start (SIdx));
               Sel_Max : constant Natural := Natural (Snap.Sel_End (SIdx));
            begin
               if Buffer_Index >= Sel_Min and then Buffer_Index < Sel_Max then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Text_Cell_Is_Selected;

      function Baseline_Y (Row : Natural) return Float is
         Text_Height : constant Float := Editor.Fonts.Ascent - Editor.Fonts.Descent;
         Extra : constant Float := Float (Cell_H) - Text_Height;
      begin
         return Screen_Y (Row) + Float'Max (0.0, Extra / 2.0) + Editor.Fonts.Ascent;
      end Baseline_Y;

      function Glyph_Y
        (Row : Natural;
         M   : Editor.Fonts.Glyph_Metric) return Float
      is
      begin
         return Baseline_Y (Row) - M.Bearing_Y;
      end Glyph_Y;

      function Glyph_X
        (Col : Natural;
         M   : Editor.Fonts.Glyph_Metric) return Float
      is
         Cell_X : constant Float := Screen_X (Col);
         X      : Float := Float'Floor (Cell_X + M.Bearing_X + 0.5);
      begin
         if X < Cell_X then
            return Cell_X;
         elsif X > Cell_X + Float (Cell_W) - M.W then
            return Cell_X + Float (Cell_W) - M.W;
         else
            return X;
         end if;
      end Glyph_X;
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
   begin
      declare
         Popup : constant Editor.State.Semantic_Popup_State := Snap.Semantic_Popup;
         Anchor_Segment : constant Natural :=
           Segment_For_Caret (Popup.Anchor_Row, Popup.Anchor_Column);
         Anchor_X : constant Float :=
           (if Anchor_Segment > 0
            then Screen_X
              (Screen_Col_For
                 (Snap.Visible_Visual_Rows (Anchor_Segment), Popup.Anchor_Column))
            else Float (Editor.Layout.Editor_Body_Rect
              (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height).X + Cell_W));
         Anchor_Y : constant Float :=
           (if Anchor_Segment > 0
            then Screen_Y (Anchor_Segment - 1) + Float (Cell_H)
            else Float (Editor.Layout.Editor_Body_Rect
              (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height).Y + Cell_H));
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Row_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Semantic_Popup.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Popup          => Popup,
            Anchor_X       => Anchor_X,
            Anchor_Y       => Anchor_Y,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      Push_Active_Find_Prompt (Out_Packet);

      Push_Guided_Prompt (Out_Packet);

      declare
         Search_Visible : Boolean := False;
         Search_Background : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Field : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Caret : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Search_Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Search_Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Project_Search_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
      begin
         Editor.Go_To_Line.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Field_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Result_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Caret_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Quick_Open.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;
      declare
         Visible : Boolean := False;
         Background_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Field_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Result_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Caret_Rectangles : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Texts : Guikit.Draw.Text_Command_Vectors.Vector;
         Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Buffer_Switcher.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
      begin
         Editor.Messages.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap,
            Message_Layout => Message_Layout);
      end;

      declare
      begin
         Editor.Settings_Management.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap.Settings_UI,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_H         => Cell_H);
      end;
      declare
         Palette : constant Editor.Command_Palette.Palette_State :=
           Editor.Command_Palette.Current;
         S_State : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Command_Palette.Command_Palette_Config :=
           Editor.Command_Palette.Current_Config;
      begin
         Editor.Command_Palette.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Palette        => Palette,
            State          => S_State,
            Config         => Config,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Layout_Origin_X => Layout.Origin_X,
            Layout_Origin_Y => Layout.Origin_Y,
            Status_Bar_Y    =>
              Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height)),
            Cell_W          => Cell_W,
            Cell_H          => Cell_H);
      end;

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
           (Packet          => Out_Packet,
            Surface         => Surface,
            Projection      => Projection,
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Text_Viewport_Y => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
            Cell_W          => Cell_W,
            Cell_H          => Cell_H);
      end;
   end Render;

end Editor.Render_Packet.Overlay_Surfaces;
