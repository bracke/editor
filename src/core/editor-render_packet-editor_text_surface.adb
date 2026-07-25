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

package body Editor.Render_Packet.Editor_Text_Surface is

   use type Editor.Search.Search_Match_Index;
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
      Gutter_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Background;
      Gutter_Separator_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Separator;
      Current_Text_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Current_Text_Row;
      Current_Gutter_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Current_Gutter_Row;
      Active_Find_Inactive_Match_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Inactive_Match;
      Active_Find_Match_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Match;
      Selection_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Selection_Background;
      Selection_Text_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Syntax_Color (Editor.Syntax.Selection_Overlay);
      Cursor_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Cursor_Color;
      Minimap_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Background;
      Minimap_Text_Density_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Content;
      Minimap_Viewport_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Viewport;
      Palette_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Palette_Background;
      Palette_Text_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Palette_Text;
      Palette_Selected_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Palette_Selected_Row;
      Palette_Muted_Text_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Palette_Muted_Text;
      Command_Palette_Secondary_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Command_Palette_Secondary_Foreground;
      Command_Palette_Detail_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Command_Palette_Detail_Foreground;
      Command_Palette_Help_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Command_Palette_Help_Foreground;
      Scrollbar_Track_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Scrollbar_Track;
      Scrollbar_Thumb_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Scrollbar_Thumb;
      Status_Bar_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Status_Bar_Background;
      Status_Bar_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Status_Bar_Foreground;
      Status_Bar_Separator_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Status_Bar_Separator;
      Status_Bar_Dirty_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Status_Bar_Dirty;
      Message_Info_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Info_Background;
      Message_Info_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Info_Foreground;
      Message_Success_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Success_Background;
      Message_Success_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Success_Foreground;
      Message_Warning_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Warning_Background;
      Message_Warning_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Warning_Foreground;
      Message_Error_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Error_Background;
      Message_Error_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Message_Error_Foreground;
      Tab_Bar_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Background;
      Tab_Bar_Active_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Active_Background;
      Tab_Bar_Inactive_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Inactive_Background;
      Tab_Bar_Active_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Active_Foreground;
      Tab_Bar_Inactive_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Inactive_Foreground;
      Tab_Bar_Dirty_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Dirty;
      Tab_Bar_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Border;
      Tab_Bar_Close_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Tab_Bar_Close;
      File_Tree_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Background;
      File_Tree_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Foreground;
      File_Tree_Directory_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Directory_Foreground;
      File_Tree_Active_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Active_Background;
      File_Tree_Active_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Active_Foreground;
      File_Tree_Selected_Active_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Selected_Active_Background;
      File_Tree_Selected_Active_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Selected_Active_Foreground;
      File_Tree_Selected_Inactive_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Selected_Inactive_Background;
      File_Tree_Selected_Inactive_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Selected_Inactive_Foreground;
      File_Tree_Focused_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Focused_Border;
      File_Tree_Separator_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Separator;
      File_Tree_Splitter_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Panel_Splitter;
      Fold_Marker_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Fold_Marker_Color;
      Folded_Line_Ellipsis_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Folded_Line_Ellipsis_Color;
      Problems_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Background;
      Problems_Header_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Header_Background;
      Problems_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Foreground;
      Problems_Error_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Error;
      Problems_Warning_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Warning;
      Problems_Info_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Info;
      Problems_Hint_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Hint;
      Problems_Alternate_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Row_Alternate_Background;
      Problems_Separator_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Separator;
      Problems_Active_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Active_Row_Background;
      Problems_Selected_Active_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Selected_Active_Background;
      Problems_Selected_Active_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Selected_Active_Foreground;
      Problems_Selected_Inactive_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Selected_Inactive_Background;
      Problems_Selected_Inactive_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Selected_Inactive_Foreground;
      Problems_Focused_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Problems_Focused_Border;
      Search_Results_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Background;
      Search_Results_Header_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Header_Background;
      Search_Results_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Foreground;
      Search_Results_File_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_File_Foreground;
      Search_Results_Selected_Active_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Selected_Active_Background;
      Search_Results_Selected_Active_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Selected_Active_Foreground;
      Search_Results_Selected_Inactive_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Selected_Inactive_Background;
      Search_Results_Selected_Inactive_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Search_Results_Selected_Inactive_Foreground;
      Panel_Focus_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Panel_Focus_Border;
      Active_Find_Prompt_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Background;
      Active_Find_Prompt_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Foreground;
      Active_Find_Prompt_Field_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Field_Background;
      Active_Find_Prompt_Field_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Field_Foreground;
      Active_Find_Prompt_Button_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Button_Background;
      Active_Find_Prompt_Button_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Button_Foreground;
      Active_Find_Prompt_Caret_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_Caret;
      Active_Find_Prompt_No_Match_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Prompt_No_Match_Foreground;
      Quick_Open_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Background;
      Quick_Open_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Foreground;
      Quick_Open_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Border;
      Quick_Open_Field_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Field_Background;
      Quick_Open_Field_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Field_Foreground;
      Quick_Open_Selected_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Selected_Background;
      Quick_Open_Selected_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Selected_Foreground;
      Quick_Open_Secondary_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Secondary_Foreground;
      Quick_Open_Caret_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Quick_Open_Caret;
      Project_Search_Bar_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Background;
      Project_Search_Bar_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Foreground;
      Project_Search_Bar_Border_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Border;
      Project_Search_Bar_Field_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Field_Background;
      Project_Search_Bar_Field_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Field_Foreground;
      Project_Search_Bar_Button_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Button_Foreground;
      Project_Search_Bar_Status_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Status_Foreground;
      Project_Search_Bar_Caret_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Project_Search_Bar_Caret;
      Pending_Bar_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Background;
      Pending_Bar_Foreground_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Foreground;
      Pending_Bar_Accent_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Accent;
      Pending_Bar_Action_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Action_Foreground;
      Pending_Bar_Disabled_Action_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Action_Disabled_Foreground;
      Pending_Bar_Destructive_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Pending_Transition_Destructive_Foreground;
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
   begin
      if Editor.View.Viewport_Width > 0
        and then Editor.View.Viewport_Height > 0
        and then Editor.Layout.Gutter_Width_For_Line_Count (Layout, Line_Count) > 0
      then
         declare
            X : constant Float := Editor.Layout.Gutter_Left (Layout);
            Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
            W : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count) - X;
            H : constant Float := Float (Text_Viewport_Height);
         begin
            if In_Gutter_Viewport (X, Y, W, H) then
               Push_Rect
                 (Out_Packet, Gutter_Background_Layer,
                  X, Y, W, H,
                  Gutter_Background_Color.R,
                  Gutter_Background_Color.G,
                  Gutter_Background_Color.B);
            end if;
         end;
      end if;

      declare
         X : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count) - 1.0;
         Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         W : constant Float := 1.0;
         H : constant Float := Float (Text_Viewport_Height);
      begin
         Push_Rect
           (Out_Packet, Gutter_Separator_Layer,
            X, Y, W, H,
            Gutter_Separator_Color.R,
            Gutter_Separator_Color.G,
            Gutter_Separator_Color.B);
      end;

      -- Current visual row highlight.
      if Snap.Caret_Count > 0 then
         declare
            Caret_Row : Natural := 0;
            Caret_Col : Natural := 0;
            Segment_Index : Natural := 0;
         begin
            Row_Col_For_Index (Natural (Snap.Caret_Pos (1)), Caret_Row, Caret_Col);
            if Snap.Caret_Virtual_Column (1) > 0 then
               Caret_Col := Snap.Caret_Virtual_Column (1);
            end if;
            Segment_Index := Segment_For_Caret (Caret_Row, Caret_Col);
            if Segment_Index > 0 then
               declare
                  Screen_Row : constant Natural := Segment_Index - 1;
                  X : constant Float := Float (Editor.Layout.Text_Origin_X (Layout, Line_Count));
                  Y : constant Float := Screen_Y (Screen_Row);
                  W : constant Float := Float (Text_Viewport_Width);
                  H : constant Float := Float (Cell_H);
                  GX : constant Float := Editor.Layout.Gutter_Left (Layout);
                  GY : constant Float := Screen_Y (Screen_Row);
                  GW : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count) - GX;
                  GH : constant Float := Float (Cell_H);
               begin
                  if Settings.Highlight_Current_Gutter
                    and then In_Gutter_Viewport (GX, GY, GW, GH)
                  then
                     Push_Rect
                       (Out_Packet, Current_Line_Layer,
                        GX, GY, GW, GH,
                        Current_Gutter_Row_Color.R,
                        Current_Gutter_Row_Color.G,
                        Current_Gutter_Row_Color.B);
                  end if;
                  if Settings.Highlight_Current_Line
                    and then In_Viewport (X, Y, W, H)
                  then
                     Push_Rect
                       (Out_Packet, Current_Line_Layer,
                        X, Y, W, H,
                        Current_Text_Row_Color.R,
                        Current_Text_Row_Color.G,
                        Current_Text_Row_Color.B);
                  end if;
               end;
            end if;
         end;
      end if;

      -- Search match rectangles over visible visual segments only.
      --
      -- Unlike text glyphs, highlight rectangles are solid quads; do not rely
      -- on backend clipping to hide the portion left of the text viewport when
      -- horizontal scrolling is active.  Clip the emitted segment to the
      -- visible grid columns before converting it to screen coordinates.
      if Snap.Active_Find_Match_Count > 0 and then Snap.Line_Starts.Length > 0 then
         declare
            Viewport_Cols : constant Natural :=
              (Text_Viewport_Width + Cell_W - 1) / Cell_W;
         begin
            for MIdx in 1 .. Snap.Active_Find_Match_Count loop
               declare
                  Match     : constant Editor.Search.Search_Match := Snap.Active_Find_Matches (MIdx);
                  Is_Active : constant Boolean :=
                    Match.End_Index > Snap.Active_Find_Match.Start_Index
                    and then Match.Start_Index < Snap.Active_Find_Match.End_Index;
                  Color     : constant Editor.Theme.Color_RGB :=
                    (if Is_Active then Active_Find_Match_Background_Color
                     else Active_Find_Inactive_Match_Background_Color);
               begin
                  if Match.End_Index > Match.Start_Index and then Viewport_Cols > 0 then
                     for I in 1 .. Snap.Visible_Visual_Count loop
                        declare
                           Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                           Row_Start : constant Natural := Index_For_Row_Start (Seg.Logical_Row);
                           Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                           Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                           Hit_Start : constant Natural := Natural'Max (Natural (Match.Start_Index), Seg_Start);
                           Hit_End   : constant Natural := Natural'Min (Natural (Match.End_Index), Seg_End);
                        begin
                           if Hit_Start < Hit_End then
                              declare
                                 Start_Col : constant Natural := Hit_Start - Row_Start;
                                 End_Col   : constant Natural := Hit_End - Row_Start;
                                 Clip_Start_Col : constant Natural :=
                                   (if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                    then Natural'Max (Start_Col, Scroll_X)
                                    else Start_Col);
                                 Clip_End_Col : constant Natural :=
                                   (if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                    then Natural'Min (End_Col, Scroll_X + Viewport_Cols)
                                    else End_Col);
                              begin
                                 if Clip_Start_Col < Clip_End_Col then
                                    declare
                                       X : constant Float :=
                                         Screen_X (Screen_Col_For (Seg, Clip_Start_Col));
                                       Y : constant Float := Screen_Y (I - 1);
                                       W : constant Float :=
                                         Float
                                           (Editor.Layout.Text_Cell_Width
                                              (Clip_End_Col - Clip_Start_Col));
                                       H : constant Float := Float (Cell_H);
                                    begin
                                       if In_Viewport (X, Y, W, H) then
                                          Push_Rect
                                            (Out_Packet, Active_Find_Match_Layer,
                                             X, Y, W, H,
                                             Color.R, Color.G, Color.B);
                                       end if;
                                    end;
                                 end if;
                              end;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end loop;
         end;
      end if;

      -- Rectangular selection rectangles. These are grid-cell spans and
      -- intentionally render even when the selected cells are virtual beyond
      -- the physical end of a short line.
      if Snap.Rectangular_Selection_Count > 0 then
         for RIdx in 1 .. Snap.Rectangular_Selection_Count loop
            declare
               Span : constant Editor.Render_Model.Rectangular_Selection_Row_Span :=
                 Snap.Rectangular_Selections (RIdx);
            begin
               if Span.Start_Column < Span.End_Column then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg : constant Editor.Wrap.Visual_Row_Info :=
                          Snap.Visible_Visual_Rows (I);
                     begin
                        if Seg.Logical_Row = Span.Row then
                           declare
                              X : constant Float :=
                                Screen_X (Screen_Col_For (Seg, Span.Start_Column));
                              Y : constant Float := Screen_Y (I - 1);
                              W : constant Float :=
                                Float
                                  (Editor.Layout.Text_Cell_Width
                                     (Span.End_Column - Span.Start_Column));
                              H : constant Float := Float (Cell_H);
                           begin
                              if In_Viewport (X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Selection_Layer,
                                    X, Y, W, H,
                                    Selection_Background_Color.R,
                                    Selection_Background_Color.G,
                                    Selection_Background_Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Selection rectangles over visible visual segments only.
      if Snap.Rectangular_Selection_Count = 0
        and then Snap.Selection_Count > 0
        and then Snap.Line_Starts.Length > 0 then
         for SIdx in 1 .. Snap.Selection_Count loop
            declare
               Sel_Min : constant Natural := Natural (Snap.Sel_Start (SIdx));
               Sel_Max : constant Natural := Natural (Snap.Sel_End (SIdx));
            begin
               if Sel_Min /= Sel_Max then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                        Row_Start : constant Natural := Index_For_Row_Start (Seg.Logical_Row);
                        Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                        Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                        Hit_Start : constant Natural := Natural'Max (Sel_Min, Seg_Start);
                        Hit_End   : constant Natural := Natural'Min (Sel_Max, Seg_End);
                     begin
                        if Hit_Start < Hit_End then
                           declare
                              Start_Col : constant Natural := Hit_Start - Row_Start;
                              End_Col   : constant Natural := Hit_End - Row_Start;
                              X : constant Float := Screen_X (Screen_Col_For (Seg, Start_Col));
                              Y : constant Float := Screen_Y (I - 1);
                              W : constant Float := Float (Editor.Layout.Text_Cell_Width (End_Col - Start_Col));
                              H : constant Float := Float (Cell_H);
                           begin
                              if In_Viewport (X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Selection_Layer,
                                    X, Y, W, H,
                                    Selection_Background_Color.R,
                                    Selection_Background_Color.G,
                                    Selection_Background_Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Diagnostic underline rectangles over visible visual segments only.
      if Settings.Show_Diagnostics
        and then Snap.Diagnostic_Count > 0
        and then Snap.Line_Starts.Length > 0 then
         for DIdx in 1 .. Snap.Diagnostic_Count loop
            declare
               D     : constant Editor.Diagnostics.Diagnostic_Range :=
                 Snap.Diagnostics (DIdx);
               Color : constant Editor.Theme.Color_RGB :=
                 Editor.Theme.Diagnostic_Color (D.Severity);
            begin
               if D.Start_Index < D.End_Index then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                        Row_Start : constant Natural := Index_For_Row_Start (Seg.Logical_Row);
                        Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                        Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                        Hit_Start : constant Natural :=
                          Natural'Max (Natural (D.Start_Index), Seg_Start);
                        Hit_End   : constant Natural :=
                          Natural'Min (Natural (D.End_Index), Seg_End);
                     begin
                        if Hit_Start < Hit_End then
                           declare
                              Start_Col : constant Natural := Hit_Start - Row_Start;
                              End_Col   : constant Natural := Hit_End - Row_Start;
                              X : constant Float := Screen_X (Screen_Col_For (Seg, Start_Col));
                              H : constant Float :=
                                Editor.Theme.Diagnostic_Underline_Height;
                              Y : constant Float :=
                                Screen_Y (I - 1) + Float (Cell_H)
                                - Editor.Theme.Diagnostic_Underline_Bottom_Padding;
                              W : constant Float :=
                                Float (Editor.Layout.Text_Cell_Width (End_Col - Start_Col));
                           begin
                              if In_Viewport (X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Diagnostic_Layer,
                                    X, Y, W, H,
                                    Color.R, Color.G, Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Carets.
      if Editor.View.Caret_Visible then
         for CIdx in 1 .. Snap.Caret_Count loop
            declare
               Caret_Row : Natural := 0;
               Caret_Col : Natural := 0;
               Segment_Index : Natural := 0;
            begin
               Row_Col_For_Index (Natural (Snap.Caret_Pos (CIdx)), Caret_Row, Caret_Col);
               if Snap.Caret_Virtual_Column (CIdx) > 0 then
                  Caret_Col := Snap.Caret_Virtual_Column (CIdx);
               end if;
               Segment_Index := Segment_For_Caret (Caret_Row, Caret_Col);
               if Segment_Index > 0 then
                  declare
                     Seg : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (Segment_Index);
                     Visual_Col : constant Natural := Screen_Col_For (Seg, Caret_Col);
                     Cell_X : constant Float := Screen_X (Visual_Col);
                     Cell_Y : constant Float := Screen_Y (Segment_Index - 1);
                     Cursor_X : Float := Cell_X;
                     Cursor_Y : Float := Cell_Y;
                     Cursor_W : Float := 1.0;
                     Cursor_H : Float := Float (Cell_H);
                  begin
                     case Cursor_Config.Style is
                        when Editor.Cursor.Bar_Cursor =>
                           Cursor_W := Float (Cursor_Config.Bar_Width);
                           Cursor_H := Float (Cell_H);
                        when Editor.Cursor.Block_Cursor =>
                           Cursor_W := Float (Cell_W);
                           Cursor_H := Float (Cell_H);
                        when Editor.Cursor.Underline_Cursor =>
                           Cursor_W := Float (Cell_W);
                           Cursor_H := Float (Cursor_Config.Underline_H);
                           Cursor_Y :=
                             Cell_Y + Float (Cell_H)
                             - Float (Cursor_Config.Underline_H);
                     end case;

                     if In_Viewport (Cursor_X, Cursor_Y, Cursor_W, Cursor_H) then
                        Push_Rect
                          (Out_Packet, Caret_Layer,
                           Cursor_X, Cursor_Y, Cursor_W, Cursor_H,
                           Cursor_Color.R, Cursor_Color.G, Cursor_Color.B);
                     end if;
                  end;
               end if;
            end;
         end loop;
      end if;

      -- Glyphs.
      if Snap.Line_Starts.Length > 0 and then Snap.Visible_Visual_Count > 0 then
         declare
            Current_Row : Natural := 0;
            Current_Col : Natural := 0;
         begin
            if Snap.Caret_Count > 0 then
               Row_Col_For_Index (Natural (Snap.Caret_Pos (1)), Current_Row, Current_Col);
            end if;

            declare
               Cache_Current_Row : constant Natural :=
                 (if Line_Number_Config.Mode = Editor.Line_Numbers.Absolute_Line_Numbers
                  then 0
                  else Current_Row);
            begin
               for I in 1 .. Snap.Visible_Visual_Count loop
                  declare
                     Seg        : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                     Screen_Row : constant Natural := I - 1;
                     Row_Start  : constant Natural := Index_For_Row_Start (Seg.Logical_Row);
                     Row_End    : constant Natural := Row_End_Index (Seg.Logical_Row);
                     Emit_Start : constant Natural := Row_Start + Seg.Start_Col;
                     Emit_Stop  : constant Natural := Natural'Min (Row_Start + Seg.End_Col, Row_End);
                     First_Row_Glyph : Natural := 0;
                  begin
                  if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                    or else Seg.Start_Col = 0
                  then
                     Editor.Gutter.Surface_Rendering.Push_Gutter_Marker
                       (Out_Packet, Snap, Layout,
                        Editor.View.Viewport_Width,
                        Effective_Viewport_H,
                        Cell_W, Cell_H, Line_Count,
                        Seg.Logical_Row, Screen_Row);
                     Editor.Gutter.Surface_Rendering.Push_Fold_Marker
                       (Out_Packet, Snap, Layout,
                        Editor.View.Viewport_Width,
                        Effective_Viewport_H,
                        Cell_W, Cell_H, Line_Count,
                        Seg.Logical_Row, Screen_Row);
                  end if;

                  if not Selection_Affects_Text_Color
                    and then Editor.Render_Cache.Row_Is_Valid
                    (Row        => Seg.Logical_Row,
                     Screen_Row => Screen_Row,
                     Row_Start  => Emit_Start,
                     Row_End    => Emit_Stop,
                     Line_Count => Line_Count,
                     Scroll_X   => Scroll_X,
                     Viewport_W => Effective_Viewport_W,
                     Viewport_H => Effective_Viewport_H,
                     Wrap_Mode  => Snap.Wrap_Mode,
                     Wrap_Col   => Snap.Wrap_Col,
                     Is_Current => Seg.Logical_Row = Current_Row,
                     Line_Number_Mode => Line_Number_Config.Mode,
                     Line_Number_Current_Row => Cache_Current_Row)
                  then
                     Editor.Render_Cache.Emit_Row
                       (Row        => Seg.Logical_Row,
                        Screen_Row => Screen_Row,
                        Row_Start  => Emit_Start,
                        Row_End    => Emit_Stop,
                        Wrap_Mode  => Snap.Wrap_Mode,
                        Wrap_Col   => Snap.Wrap_Col,
                        Packet     => Out_Packet);
                  else
                     First_Row_Glyph := Natural (Out_Packet.Glyph_Count);

                     if Settings.Show_Line_Numbers
                       and then (Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                 or else Seg.Start_Col = 0)
                     then
                        Editor.Gutter.Surface_Rendering.Push_Gutter_Line_Number
                          (Out_Packet,
                           Layout,
                           Editor.View.Viewport_Width,
                           Effective_Viewport_H,
                           Cell_W,
                           Cell_H,
                           Line_Count,
                           Seg.Logical_Row,
                           Screen_Row,
                           Current_Row,
                           Settings.Highlight_Current_Gutter
                           and then Seg.Logical_Row = Current_Row,
                           Line_Number_Config);
                     end if;

                     if Emit_Start < Emit_Stop then
                        declare
                           Line_Text : String (1 .. Row_End - Row_Start);
                           type Code_Array is array (Natural range <>) of Editor.Unicode.Code_Point;
                           Segment_Codes : Code_Array (0 .. Emit_Stop - Emit_Start - 1) :=
                             (others => Wide_Wide_Character'Val (0));
                           Line_Fill_Pos : Natural := Line_Text'First;

                           procedure Fill_Line
                             (Index : Natural;
                              Code  : Editor.Unicode.Code_Point)
                           is
                              pragma Unreferenced (Index);
                              V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
                           begin
                              if V <= 255 then
                                 Line_Text (Line_Fill_Pos) := Character'Val (V);
                              else
                                 Line_Text (Line_Fill_Pos) := '?';
                              end if;
                              Line_Fill_Pos := Line_Fill_Pos + 1;
                           end Fill_Line;

                           procedure Fill_Segment_Code
                             (Index : Natural;
                              Code  : Editor.Unicode.Code_Point)
                           is
                           begin
                              Segment_Codes (Index - Emit_Start) := Code;
                           end Fill_Segment_Code;
                        begin
                           --  Classify the full logical row, not only the visible
                           --  slice.  This preserves line-local token context when
                           --  horizontal scrolling or wrapping starts inside a
                           --  comment/string/identifier token.
                           Editor.Input_Bridge.For_Each_Text_Code_Point_Range
                             (Row_Start, Row_End, Fill_Line'Access);
                           Editor.Input_Bridge.For_Each_Text_Code_Point_Range
                             (Emit_Start, Emit_Stop, Fill_Segment_Code'Access);

                           declare
                              procedure Emit_Token
                                (Token_Start : Natural;
                                 Token_Stop  : Natural;
                                 Kind        : Editor.Syntax.Syntax_Kind)
                              is
                                 Token_Color : constant Editor.Theme.Color_RGB :=
                                   (if Settings.Use_Syntax_Colouring
                                      or else Kind in Editor.Syntax.Diagnostic_Error
                                                    | Editor.Syntax.Diagnostic_Warning
                                                    | Editor.Syntax.Search_Match
                                                    | Editor.Syntax.Selection_Overlay
                                    then Editor.Theme.Syntax_Color (Kind)
                                    else Editor.Theme.Text_Default);
                              begin
                                 for Abs_Index in Token_Start .. Token_Stop - 1 loop
                                    declare
                                       Ch : constant Character :=
                                         Line_Text
                                           (Line_Text'First + Abs_Index - Row_Start);
                                       Code : constant Editor.Unicode.Code_Point :=
                                         Segment_Codes (Abs_Index - Emit_Start);
                                       Logical_Col : constant Natural :=
                                         Abs_Index - Row_Start;
                                       Glyph_Col : constant Natural := Screen_Col_For (Seg, Abs_Index - Row_Start);
                                       Color : constant Editor.Theme.Color_RGB :=
                                         (if Text_Cell_Is_Selected
                                               (Abs_Index, Seg.Logical_Row, Logical_Col)
                                          then Selection_Text_Color
                                          else Token_Color);
                                       M : Editor.Fonts.Glyph_Metric;
                                    begin
                                       if Ch /= ASCII.CR
                                         and then Ch /= ASCII.LF
                                         and then Ch /= ASCII.NUL
                                       then
                                          if Editor.Fonts.Get_Glyph (Code, M) then
                                             Editor.Fonts.Check_Glyph_Fits_Cell
                                               (M, Cell_W, Cell_H);
                                             if M.W > 0.0 and then M.H > 0.0 then
                                                declare
                                                   GX : constant Float := Glyph_X (Glyph_Col, M);
                                                   GY : constant Float := Float'Floor (Glyph_Y (Screen_Row, M) + 0.5);
                                                   GW : constant Float := M.W;
                                                   GH : constant Float := M.H;
                                                begin
                                                   if In_Viewport (GX, GY, GW, GH) then
                                                      Push_Glyph
                                                        (Out_Packet, Text_Layer,
                                                         GX, GY, GW, GH,
                                                         Float (M.U0),
                                                         Float (M.V0),
                                                         Float (M.U1),
                                                         Float (M.V1),
                                                         Color.R, Color.G, Color.B);
                                                   end if;
                                                end;
                                             end if;
                                          end if;
                                       end if;
                                    end;
                                 end loop;
                              end Emit_Token;

                              Cursor : Natural := Emit_Start;
                           begin
                              for I in 1 .. Snap.Syntax_Span_Count loop
                                 declare
                                    Span : constant Editor.Render_Model.Render_Syntax_Span :=
                                      Snap.Syntax_Spans (I);
                                    Token_Start : constant Natural :=
                                      Natural'Max (Span.Start_Index, Emit_Start);
                                    Token_Stop : constant Natural :=
                                      Natural'Min (Span.End_Index, Emit_Stop);
                                 begin
                                    if Span.Row = Seg.Logical_Row and then Token_Stop > Token_Start then
                                       if Cursor < Token_Start then
                                          Emit_Token (Cursor, Token_Start, Editor.Syntax.Plain_Text);
                                       end if;
                                       Emit_Token (Token_Start, Token_Stop, Span.Kind);
                                       Cursor := Token_Stop;
                                    end if;
                                 end;
                              end loop;

                              if Cursor < Emit_Stop then
                                 Emit_Token (Cursor, Emit_Stop, Editor.Syntax.Plain_Text);
                              end if;
                           end;
                        end;
                     end if;

                     if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                       or else Seg.Start_Col = 0
                     then
                        Editor.Gutter.Surface_Rendering.Push_Folded_Ellipsis
                          (Out_Packet,
                           Snap,
                           Layout,
                           Editor.View.Viewport_Width,
                           Effective_Viewport_H,
                           Text_Viewport_Right,
                           Cell_W,
                           Cell_H,
                           Line_Count,
                           Seg.Logical_Row,
                           Screen_Row,
                           Seg.End_Col + 1);
                     end if;

                     if not Selection_Affects_Text_Color then
                        Editor.Render_Cache.Store_Row
                          (Row         => Seg.Logical_Row,
                           Screen_Row  => Screen_Row,
                           Row_Start   => Emit_Start,
                           Row_End     => Emit_Stop,
                           Line_Count  => Line_Count,
                           Scroll_X    => Scroll_X,
                           Viewport_W  => Effective_Viewport_W,
                           Viewport_H  => Effective_Viewport_H,
                           Wrap_Mode   => Snap.Wrap_Mode,
                           Wrap_Col    => Snap.Wrap_Col,
                           Is_Current  => Seg.Logical_Row = Current_Row,
                           Line_Number_Mode => Line_Number_Config.Mode,
                           Line_Number_Current_Row => Cache_Current_Row,
                           Packet      => Out_Packet,
                           First_Glyph => First_Row_Glyph,
                           Glyph_Count => Natural (Out_Packet.Glyph_Count) - First_Row_Glyph);
                     end if;
                  end if;
                  end;
               end loop;
            end;
         end;
      end if;

      -- Minimap overview.  This pass uses only precomputed O(viewport-height)
      -- samples from the render snapshot; it does not scan the document here
      -- and it does not interact with the normal row glyph cache.
      if Effective_Minimap_Enabled
        and then Editor.View.Viewport_Width > 0
        and then Text_Viewport_Height > 0
      then
         declare
            Left   : constant Float :=
              Editor.Minimap.Left_X
                (Layout, Effective_Viewport_W, Minimap);
            Right  : constant Float :=
              Editor.Minimap.Right_X
                (Layout, Effective_Viewport_W, Minimap);
            Top    : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
            Height : constant Float := Float (Text_Viewport_Height);
            Inner_Pad : constant Float :=
              Editor.Theme.Minimap_Content_Padding;
            Content_Left : constant Float := Left + Inner_Pad;
            Content_W    : constant Float :=
              Float'Max (1.0, Right - Left - 2.0 * Inner_Pad);
            Max_Line_For_Scale : constant Natural :=
              Editor.Theme.Minimap_Max_Line_Length_For_Scale;
            Visible_Rows : constant Natural :=
              (if Snap.Visible_Last_Row >= Snap.Visible_First_Row
               then Snap.Visible_Last_Row - Snap.Visible_First_Row + 1
               else 1);
         begin
            if Right > Left then
               Push_Rect
                 (Out_Packet, Minimap_Background_Layer,
               Left, Top, Right - Left, Height,
               Minimap_Background_Color.R,
               Minimap_Background_Color.G,
               Minimap_Background_Color.B);

            if Snap.Minimap_Sample_Count > 0 then
               for I in 0 .. Snap.Minimap_Sample_Count - 1 loop
                  declare
                  Info : constant Editor.Minimap.Minimap_Line_Info :=
                    Snap.Minimap_Samples (I);
                  Scale_Len : constant Natural :=
                    Natural'Min (Info.Text_Length, Max_Line_For_Scale);
                  Line_W : constant Float :=
                    Float'Max
                      (Editor.Theme.Minimap_Min_Line_Width,
                       Float (Scale_Len) * Content_W
                         / Float (Max_Line_For_Scale));
                  Y : constant Float := Top + Info.Start_Y;
               begin
                  if Info.Has_Text then
                     Push_Rect
                       (Out_Packet, Minimap_Content_Layer,
                        Content_Left, Y,
                        Float'Min (Content_W, Line_W),
                        Editor.Theme.Minimap_Content_Line_Height,
                        Minimap_Text_Density_Color.R,
                        Minimap_Text_Density_Color.G,
                        Minimap_Text_Density_Color.B);
                  end if;

                     end;
               end loop;
            end if;

            declare
               Marker_Y : constant Float :=
                 Top + Editor.Minimap.Viewport_Marker_Y
                   (Snap.Visible_First_Row,
                    Line_Count,
                    Text_Viewport_Height);
               Raw_Marker_H : constant Float :=
                 Editor.Minimap.Viewport_Marker_Height
                   (Visible_Rows,
                    Line_Count,
                    Text_Viewport_Height);
               Marker_H : constant Float :=
                 (if Marker_Y >= Top + Height then 0.0
                  else Float'Min (Raw_Marker_H, Top + Height - Marker_Y));
            begin
               if Marker_H > 0.0 then
                  Push_Rect
                    (Out_Packet, Minimap_Viewport_Layer,
                     Left, Marker_Y, Right - Left, Marker_H,
                     Minimap_Viewport_Color.R,
                     Minimap_Viewport_Color.G,
                     Minimap_Viewport_Color.B);
               end if;
            end;
            end if;
         end;
      end if;


      -- Scrollbars are drawn above editor/minimap content but below palette.
      if Scrollbars.Enabled
        and then Editor.View.Viewport_Width > 0
        and then Editor.View.Viewport_Height > 0
      then
         declare
            Visible_Rows : constant Natural :=
              Editor.Layout.Visible_Row_Count (Layout, Effective_Viewport_H);
            Vertical : constant Editor.Scrollbars.Scrollbar_Geometry :=
              Editor.Scrollbars.Vertical_Geometry
                (Layout          => Layout,
                 Viewport_Width  => Editor.View.Viewport_Width,
                 Viewport_Height => Scrollbar_Viewport_Height,
                 Total_Rows      => Snap.Visible_Line_Count,
                 Visible_Rows    => Visible_Rows,
                 Scroll_Y        => Editor.View.Scroll_Y,
                 Config          => Scrollbars);
         begin
            if Vertical.Visible then
               Push_Rect
                 (Out_Packet, Scrollbar_Track_Layer,
                  Vertical.Track.X, Vertical.Track.Y,
                  Vertical.Track.W, Vertical.Track.H,
                  Scrollbar_Track_Color.R,
                  Scrollbar_Track_Color.G,
                  Scrollbar_Track_Color.B);
               Push_Rect
                 (Out_Packet, Scrollbar_Thumb_Layer,
                  Vertical.Thumb.X, Vertical.Thumb.Y,
                  Vertical.Thumb.W, Vertical.Thumb.H,
                  Scrollbar_Thumb_Color.R,
                  Scrollbar_Thumb_Color.G,
                  Scrollbar_Thumb_Color.B);
            end if;
         end;

         declare
            Text_Left : constant Natural :=
              Editor.Layout.Text_Origin_X (Layout, Line_Count);
            Text_W : constant Natural := Text_Viewport_Width;
            Visible_Cols : constant Natural :=
              Text_W / Editor.Layout.Cell_W;
            Total_Cols : Natural := 0;
            Horizontal : Editor.Scrollbars.Scrollbar_Geometry;
         begin
            for I in 1 .. Snap.Visible_Visual_Count loop
               declare
                  Seg : constant Editor.Wrap.Visual_Row_Info :=
                    Snap.Visible_Visual_Rows (I);
               begin
                  if not Editor.Folding.Is_Row_Hidden
                           (Snap.Folding, Seg.Logical_Row)
                    and then Seg.End_Col >= Seg.Start_Col
                  then
                     Total_Cols := Natural'Max (Total_Cols, Seg.End_Col);
                  end if;
               end;
            end loop;

            Horizontal :=
              Editor.Scrollbars.Horizontal_Geometry
                (Layout          => Layout,
                 Text_Left       => Text_Left,
                 Text_Width      => Text_W,
                 Viewport_Height => Scrollbar_Viewport_Height,
                 Total_Cols      => Total_Cols,
                 Visible_Cols    => Visible_Cols,
                 Scroll_X        => Editor.View.Scroll_X,
                 Config          => Scrollbars);

            if Horizontal.Visible then
               Push_Rect
                 (Out_Packet, Scrollbar_Track_Layer,
                  Horizontal.Track.X, Horizontal.Track.Y,
                  Horizontal.Track.W, Horizontal.Track.H,
                  Scrollbar_Track_Color.R,
                  Scrollbar_Track_Color.G,
                  Scrollbar_Track_Color.B);
               Push_Rect
                 (Out_Packet, Scrollbar_Thumb_Layer,
                  Horizontal.Thumb.X, Horizontal.Thumb.Y,
                  Horizontal.Thumb.W, Horizontal.Thumb.H,
                  Scrollbar_Thumb_Color.R,
                  Scrollbar_Thumb_Color.G,
                  Scrollbar_Thumb_Color.B);
            end if;
         end;
      end if;

   end Render;

end Editor.Render_Packet.Editor_Text_Surface;
