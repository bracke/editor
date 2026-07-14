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
package body Editor.Render_Packet is

   use Editor.Render_Packet.Guikit_Adapters;
   use type Editor.Search.Search_Match_Index;
   use type Editor.Wrap.Wrap_Mode;

   Max_Debug_Text_For_Test : constant Natural := 4096;
   Debug_Text_Buffer_For_Test : Unbounded_String := Null_Unbounded_String;

   procedure Record_Debug_Text_For_Test (Text : String) is
      Separator : constant Natural :=
        (if Length (Debug_Text_Buffer_For_Test) > 0 then 1 else 0);
      Remaining : constant Natural :=
        (if Length (Debug_Text_Buffer_For_Test) >= Max_Debug_Text_For_Test
         then 0
         elsif Length (Debug_Text_Buffer_For_Test) + Separator >= Max_Debug_Text_For_Test
         then 0
         else Max_Debug_Text_For_Test - Length (Debug_Text_Buffer_For_Test) - Separator);
   begin
      if Text'Length = 0 or else Remaining = 0 then
         return;
      end if;
      if Separator > 0 then
         Append (Debug_Text_Buffer_For_Test, ASCII.LF);
      end if;
      if Text'Length <= Remaining then
         Append (Debug_Text_Buffer_For_Test, Text);
      else
         Append (Debug_Text_Buffer_For_Test, Text (Text'First .. Text'First + Remaining - 1));
      end if;
   end Record_Debug_Text_For_Test;

   procedure Clear_Debug_Text_For_Test is
   begin
      Debug_Text_Buffer_For_Test := Null_Unbounded_String;
   end Clear_Debug_Text_For_Test;

   function Debug_Text_Contains_For_Test
     (Text : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (To_String (Debug_Text_Buffer_For_Test), Text) > 0;
   end Debug_Text_Contains_For_Test;

   function Debug_Text_For_Test return String is
   begin
      return To_String (Debug_Text_Buffer_For_Test);
   end Debug_Text_For_Test;

   function Audit_Buffer_Metadata_Render_Boundary
     return Buffer_Metadata_Render_Boundary_Audit
   is
      Result : constant Buffer_Metadata_Render_Boundary_Audit :=
        (Uses_Metadata_Snapshots_Only          => True,
         Does_Not_Switch_Buffers              => True,
         Does_Not_Close_Buffers               => True,
         Does_Not_Save_Reload_Revert          => True,
         Does_Not_Probe_Filesystem            => True,
         Does_Not_Classify_By_Mutation        => True,
         Does_Not_Expose_Runtime_Buffer_Ids   => True,
         Buffer_List_Metadata_Projection_Only => True,
         Active_Buffer_Metadata_Projection_Only => True,
         Side_Effect_Free                     => True,
         Boundary_Safe                        => True);
   begin
      return Result;
   end Audit_Buffer_Metadata_Render_Boundary;

   function Assert_Buffer_Metadata_Render_Boundary_Safe return Boolean
   is
      Audit : constant Buffer_Metadata_Render_Boundary_Audit :=
        Audit_Buffer_Metadata_Render_Boundary;
   begin
      return Audit.Uses_Metadata_Snapshots_Only
        and then Audit.Does_Not_Switch_Buffers
        and then Audit.Does_Not_Close_Buffers
        and then Audit.Does_Not_Save_Reload_Revert
        and then Audit.Does_Not_Probe_Filesystem
        and then Audit.Does_Not_Classify_By_Mutation
        and then Audit.Does_Not_Expose_Runtime_Buffer_Ids
        and then Audit.Buffer_List_Metadata_Projection_Only
        and then Audit.Active_Buffer_Metadata_Projection_Only
        and then Audit.Side_Effect_Free
        and then Audit.Boundary_Safe;
   end Assert_Buffer_Metadata_Render_Boundary_Safe;

   function Active_Find_Buffer_Token
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Buffer_Token /= 0 then
         return S.Active_Buffer_Token;
      elsif Editor.Buffers.Global_Count > 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
      then
         return Natural (Editor.Buffers.Global_Active_Buffer);
      else
         return S.Registry_Token;
      end if;
   end Active_Find_Buffer_Token;

   function Active_Find_Source_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.Active_Find_Source_Buffer_Token /= 0
        and then S.Active_Find_Source_Buffer_Token = Active_Find_Buffer_Token (S);
   end Active_Find_Source_Current;


   Last_Settings_Version : Natural := 0;

   procedure Push_Rect
     (Packet : in out Render_Packet;
      Layer : Render_Layer;
      X, Y, W, H, R, G, B : Float)
   is
      Index : constant Integer := Integer (Packet.Rect_Count);
   begin
      if Index < Max_Rectangles then
         Packet.Rects (Index).Layer := To_C (Layer);
         Packet.Rects (Index).X := C_Float (X);
         Packet.Rects (Index).Y := C_Float (Y);
         Packet.Rects (Index).W := C_Float (W);
         Packet.Rects (Index).H := C_Float (H);
         Packet.Rects (Index).R := C_Float (R);
         Packet.Rects (Index).G := C_Float (G);
         Packet.Rects (Index).B := C_Float (B);
         Packet.Rect_Count := Packet.Rect_Count + 1;
      end if;
   end Push_Rect;

   procedure Push_Glyph
     (Packet         : in out Render_Packet;
      Layer          : Render_Layer;
      X, Y, W, H     : Float;
      U0, V0, U1, V1 : Float;
      R, G, B        : Float)
   is
      Index : constant Integer := Integer (Packet.Glyph_Count);
   begin
      if Index < Max_Glyphs then
         Packet.Glyphs (Index).Layer := To_C (Layer);
         Packet.Glyphs (Index).X  := C_Float (X);
         Packet.Glyphs (Index).Y  := C_Float (Y);
         Packet.Glyphs (Index).W  := C_Float (W);
         Packet.Glyphs (Index).H  := C_Float (H);
         Packet.Glyphs (Index).U0 := C_Float (U0);
         Packet.Glyphs (Index).V0 := C_Float (V0);
         Packet.Glyphs (Index).U1 := C_Float (U1);
         Packet.Glyphs (Index).V1 := C_Float (V1);
         Packet.Glyphs (Index).R  := C_Float (R);
         Packet.Glyphs (Index).G  := C_Float (G);
         Packet.Glyphs (Index).B  := C_Float (B);
         Packet.Glyph_Count := Packet.Glyph_Count + 1;
      end if;
   end Push_Glyph;

   procedure Build_Render_Packet
     (Out_Packet : out Render_Packet)
   is
      Snap   : Editor.Render_Model.Render_Snapshot;
      S      : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Cell_W : constant Positive := Editor.Layout.Cell_W;
      Cell_H : constant Positive := Editor.Layout.Cell_H;
      Message_Layout : constant Editor.Messages.Message_Layout :=
        (Origin_X     => Layout.Origin_X,
         Origin_Y     => Layout.Origin_Y,
         Cell_W       => Cell_W,
         Cell_H       => Cell_H,
         Status_Bar_Y => Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
      Scroll_X : Natural := 0;
      Cursor_Config : constant Editor.Cursor.Cursor_Config :=
        Editor.Cursor.Current;
      Minimap : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      Settings : constant Editor.Settings.Settings_State :=
        Editor.Settings.Current;
      Line_Number_Config : constant Editor.Line_Numbers.Line_Number_Config :=
        Editor.Line_Numbers.Current;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_Viewport_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Scrollbars);
      Effective_Viewport_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Effective_Minimap_Enabled : constant Boolean :=
        Settings.Show_Minimap and then Minimap.Enabled;

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

      function Line_Mode_Text return String is
      begin
         case Line_Number_Config.Mode is
            when Editor.Line_Numbers.Absolute_Line_Numbers =>
               return "absolute lines";
            when Editor.Line_Numbers.Relative_Line_Numbers =>
               return "relative lines";
            when Editor.Line_Numbers.Hybrid_Line_Numbers =>
               return "hybrid lines";
         end case;
      end Line_Mode_Text;

      function Severity_Label
        (Severity : Editor.Messages.Message_Severity) return String
      is
      begin
         case Severity is
            when Editor.Messages.Info_Message =>
               return "info";
            when Editor.Messages.Success_Message =>
               return "ok";
            when Editor.Messages.Warning_Message =>
               return "warn";
            when Editor.Messages.Error_Message =>
               return "error";
         end case;
      end Severity_Label;

      function Focus_Owner
        return Editor.Focus_Management.Focus_Owner
      is
      begin
         case Snap.Active_Overlay is
            when Editor.Overlay_Focus.Command_Palette_Overlay =>
               return Editor.Focus_Management.Focus_Command_Palette;
            when Editor.Overlay_Focus.Quick_Open_Overlay =>
               return Editor.Focus_Management.Focus_Quick_Open;
            when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
               return Editor.Focus_Management.Focus_Project_Search_Query;
            when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
               return Editor.Focus_Management.Focus_Buffer_List;
            when Editor.Overlay_Focus.Active_Find_Prompt_Overlay
               | Editor.Overlay_Focus.Go_To_Line_Overlay
               | Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
               return Editor.Focus_Management.Focus_Workspace_Prompt;
            when Editor.Overlay_Focus.No_Overlay =>
               null;
         end case;

         if Snap.Feature_Panel_Focused then
            case Snap.Active_Feature is
               when Editor.Feature_Panel.Outline_Feature =>
                  return Editor.Focus_Management.Focus_Outline;
               when Editor.Feature_Panel.Diagnostics_Feature =>
                  return Editor.Focus_Management.Focus_Diagnostics;
               when Editor.Feature_Panel.Search_Results_Feature =>
                  return Editor.Focus_Management.Focus_Project_Search_Results;
               when others =>
                  return Editor.Focus_Management.Focus_Project_Search_Results;
            end case;
         end if;

         case Snap.Panel_Focus_Target is
            when Editor.Panel_Focus.Editor_Text_Focus =>
               return Editor.Focus_Management.Focus_Editor;
            when Editor.Panel_Focus.File_Tree_Focus =>
               return Editor.Focus_Management.Focus_File_Tree;
            when Editor.Panel_Focus.Bottom_Panel_Focus =>
               case Snap.Bottom_Focus_Content is
                  when Editor.Panel_Focus.Search_Results_Focus =>
                     return Editor.Focus_Management.Focus_Project_Search_Results;
                  when Editor.Panel_Focus.Problems_Focus =>
                     return Editor.Focus_Management.Focus_Diagnostics;
                  when Editor.Panel_Focus.No_Bottom_Focus =>
                     return Editor.Focus_Management.Focus_None;
               end case;
         end case;
      end Focus_Owner;

      function Focus_Label return String is
      begin
         --  status focus text is a projection of the same
         --  effective focus-owner model that input routing uses.  Render
         --  observes the snapshot/state only; it never repairs or changes
         --  focus while producing this label.
         return Editor.Focus_Management.Focus_Owner_Label (Focus_Owner);
      end Focus_Label;

      function Active_Panel_Label return String is
      begin
         return Editor.Focus_Management.Active_Panel_Label (Focus_Owner);
      end Active_Panel_Label;

      function Input_Mode_Label return String is
      begin
         return Editor.Focus_Management.Input_Mode_Label (Focus_Owner);
      end Input_Mode_Label;

      function Is_Restore_Feedback
        (Text : String) return Boolean
      is
      begin
         return Text = "Workspace restored."
           or else Text = "Workspace restored with missing entries skipped."
           or else
             (Text'Length >= 24
              and then Text (Text'First .. Text'First + 23) =
                "Workspace state restored")
           or else
             (Text'Length >= 34
              and then Text (Text'First .. Text'First + 33) =
                "Workspace state partially restored");
      end Is_Restore_Feedback;


      function File_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "No active buffer.";
         elsif S.File_Info.Has_Path then
            if Editor.Project.Has_Project (S.Project)
              and then Editor.Project.Is_Under_Project
                (S.Project, To_String (S.File_Info.Path))
            then
               return Editor.Project.Relative_Path
                 (S.Project, To_String (S.File_Info.Path));
            else
               return To_String (S.File_Info.Display_Name);
            end if;
         elsif Length (S.File_Info.Display_Name) > 0 then
            return To_String (S.File_Info.Display_Name);
         else
            return "Untitled";
         end if;
      end File_Label;

      function Buffer_Kind_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "No buffer";
         elsif S.File_Info.Has_Path then
            if Editor.Project.Has_Project (S.Project)
              and then not Editor.Project.Is_Under_Project
                (S.Project, To_String (S.File_Info.Path))
            then
               return "File-backed, outside project";
            else
               return "File-backed";
            end if;
         else
            return "Scratch";
         end if;
      end Buffer_Kind_Label;

      function File_State_Label return String
      is
      begin
         if not Editor.State.Has_Active_Buffer (S) then
            return "Unavailable";
         elsif S.File_Conflict_Prompt_Active then
            return "Conflict pending";
         elsif S.File_Info.Missing_Target_Surfaced then
            return "Missing on disk";
         elsif S.File_Info.External_Change_Surfaced and then S.File_Info.Dirty then
            return "Conflict pending";
         elsif S.File_Info.External_Change_Surfaced then
            return "Changed on disk";
         elsif S.File_Info.Unreadable_Target_Surfaced
           or else S.File_Info.Last_Reload_Failed
           or else S.File_Info.Last_Revert_Failed
         then
            return "Unreadable";
         elsif S.File_Info.Unwritable_Target_Surfaced then
            return "Read-only";
         elsif S.File_Info.Last_Save_Failed then
            return "Save conflict";
         elsif S.File_Info.Dirty then
            return "Modified";
         else
            return "Clean";
         end if;
      end File_State_Label;

      function Pending_Status_Label return String
      is
      begin
         if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
            return "Confirmation required: "
              & Editor.Pending_Transitions.Display_Text (S.Pending_Transitions);
         elsif S.Dirty_Close_Prompt_Active then
            if S.Dirty_Close_Prompt_Save_Failure_Count > 0 then
               return "Dirty close review: save failed; buffer remains open";
            elsif S.Dirty_Close_Prompt_Conflicted_Count > 0 then
               return "Dirty close review: file conflict requires resolution";
            elsif S.Dirty_Close_Prompt_Unwritable_Count > 0 then
               return "Dirty close review: file is unwritable";
            elsif S.Dirty_Close_Prompt_Missing_Count > 0 then
               return "Dirty close review: backing file is missing";
            elsif S.Dirty_Close_Prompt_Untitled_Count > 0 then
               return "Dirty close review: scratch buffer requires discard or cancel";
            elsif S.Dirty_Close_Prompt_All_Buffers then
               return "Dirty close review: save all, discard all, or cancel";
            else
               return "Dirty close review: save, discard, or cancel";
            end if;
         elsif S.File_Conflict_Prompt_Active then
            if S.File_Conflict_Prompt_Dirty then
               return "File conflict: keep buffer, reload from disk, overwrite disk, or cancel";
            else
               return "File conflict: keep buffer, reload from disk, or cancel";
            end if;
         elsif S.File_Target_Prompt_Active then
            return "Pending file target";
         else
            return "";
         end if;
      end Pending_Status_Label;

      function Project_State_Label return String
      is
         Pending_Kind : constant Editor.Pending_Transitions.Pending_Transition_Kind :=
           Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions);
      begin
         case Pending_Kind is
            when Editor.Pending_Transitions.Pending_Open_Project
               | Editor.Pending_Transitions.Pending_Switch_Project
               | Editor.Pending_Transitions.Pending_Open_Recent_Project
               | Editor.Pending_Transitions.Pending_Restore_Workspace =>
               return "Project switch pending";
            when Editor.Pending_Transitions.Pending_Close_Project
               | Editor.Pending_Transitions.Pending_Clear_Project =>
               return "Project close pending";
            when others =>
               null;
         end case;

         if Snap.Has_Project then
            return "Project: " & To_String (Snap.Project_Label);
         else
            return "No project open.";
         end if;
      end Project_State_Label;

      function Undo_Redo_Label return String
      is
         Undo : constant Boolean := not Editor.History.Undo_Stack.Is_Empty;
         Redo : constant Boolean := not Editor.History.Redo_Stack.Is_Empty;
      begin
         if Undo and Redo then
            return "Undo/Redo available";
         elsif Undo then
            return "Undo available";
         elsif Redo then
            return "Redo available";
         else
            return "Undo/Redo unavailable";
         end if;
      end Undo_Redo_Label;

      function Outline_Status_Label return String
      is
         Summary : constant Editor.Outline.Outline_Summary :=
           Editor.Outline.Summary (S.Outline);
         Filter  : constant String := Editor.Outline.Filter_Text (S.Outline);
      begin
         if Editor.Outline.Last_Extraction_Source_Class (S.Outline) =
           Editor.Outline.Stale_Extracted_Outline
         then
            return "Outline: stale";
         end if;

         case Summary.Source_Class is
            when Editor.Outline.No_Outline =>
               return "Outline: not refreshed";
            when Editor.Outline.Stale_Extracted_Outline =>
               return "Outline: stale";
            when Editor.Outline.Unsupported_Content | Editor.Outline.Extraction_Failed =>
               return "Outline: unavailable";
            when others =>
               if Filter /= "" then
                  return "Outline: filter " & Natural'Image
                    (Editor.Outline.Filtered_Navigable_Symbol_Count (S.Outline)) &
                    " of" & Natural'Image
                    (Editor.Outline.Navigable_Symbol_Count (S.Outline));
               elsif Editor.Outline.Has_Current_Symbol (S.Outline) then
                  return "Current: " &
                    Editor.Outline.Current_Symbol_Label (S.Outline);
               else
                  return "Outline:" & Natural'Image
                    (Editor.Outline.Navigable_Symbol_Count (S.Outline)) &
                    " symbols";
               end if;
         end case;
      end Outline_Status_Label;

      function Status_Plural
        (Count       : Natural;
         Singular    : String;
         Plural_Text : String) return String
      is
      begin
         if Count = 1 then
            return Singular;
         else
            return Plural_Text;
         end if;
      end Status_Plural;

      function Diagnostics_Status_Label return String
      is
         Errors   : Natural := 0;
         Warnings : Natural := 0;
      begin
         for D of S.Diagnostics loop
            case D.Severity is
               when Editor.Diagnostics.Error =>
                  Errors := Errors + 1;
               when Editor.Diagnostics.Warning =>
                  Warnings := Warnings + 1;
               when others =>
                  null;
            end case;
         end loop;

         if Snap.Total_Diagnostic_Count = 0 then
            return "No diagnostics.";
         elsif Errors > 0 or else Warnings > 0 then
            return "Diagnostics:"
              & Natural'Image (Errors) & " "
              & Status_Plural (Errors, "error", "errors") & ","
              & Natural'Image (Warnings) & " "
              & Status_Plural (Warnings, "warning", "warnings");
         else
            return "Diagnostics:" & Natural'Image (Snap.Total_Diagnostic_Count)
              & " total";
         end if;
      end Diagnostics_Status_Label;

      function Build_Status_Label return String
      is
         Label : constant String :=
           Editor.Build_Result_Summary.Status_Label (S.Latest_Build_Result);
         Build_UI_View : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
           Editor.Build_UI.Build_Render_Snapshot
             (S.Build_UI,
              S.Latest_Build_Result,
              S.Latest_Build_Output_Details);
         Validation : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
           Editor.Build_UI.Validate_Build_UI_State (S.Build_UI);
         Candidate_Stale : constant Boolean :=
           S.Build_UI.Selected_Candidate_Stale
           or else Validation = Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;

         function Normalized_Result_Label return String
         is
         begin
            if Label'Length >= 6
              and then Label (Label'First .. Label'First + 5) = "Build "
            then
               return Label (Label'First + 6 .. Label'Last);
            else
               return Label;
            end if;
         end Normalized_Result_Label;

         function Duration_Suffix return String
         is
         begin
            if not S.Latest_Build_Result.Has_Duration then
               return "";
            else
               return ", "
                 & Editor.Build_Result_Summary.Duration_Label (S.Latest_Build_Result);
            end if;
         end Duration_Suffix;

         function Command_Suffix return String
         is
            Label : constant String :=
              Editor.Build_Result_Summary.Command_Label (S.Latest_Build_Result);
         begin
            if Label = "command unavailable" then
               return "";
            else
               return ", " & Label;
            end if;
         end Command_Suffix;

         function Diagnostics_Suffix return String
         is
         begin
            if S.Latest_Build_Result.Has_Diagnostics_Count then
               return ", diagnostics"
                 & Natural'Image
                   (S.Latest_Build_Result.Diagnostics_Count_If_Available);
            else
               return "";
            end if;
         end Diagnostics_Suffix;

         function Detail_Suffix return String is
         begin
            return Command_Suffix & Duration_Suffix & Diagnostics_Suffix;
         end Detail_Suffix;

         function Action_Rows_Suffix return String
         is
            Result : Unbounded_String := Null_Unbounded_String;
         begin
            if Build_UI_View.Actions.Is_Empty then
               return "";
            end if;

            for I in Build_UI_View.Actions.First_Index ..
              Build_UI_View.Actions.Last_Index
            loop
               declare
                  Row : constant Editor.Build_UI.Build_UI_Action_Row :=
                    Build_UI_View.Actions.Element (I);
                  Reason : constant String := To_String (Row.Disabled_Reason);
               begin
                  Append (Result, ASCII.LF);
                  if Row.Selected then
                     Append (Result, "  > ");
                  else
                     Append (Result, "  - ");
                  end if;
                  Append (Result, To_String (Row.Label));
                  Append (Result, " [");
                  Append (Result, To_String (Row.Command_Name));
                  Append (Result, "]");
                  if Row.Enabled then
                     Append (Result, " enabled");
                  elsif Reason'Length > 0 then
                     Append (Result, " disabled: ");
                     Append (Result, Reason);
                  else
                     Append (Result, " disabled");
                  end if;
               end;
            end loop;
            return To_String (Result);
         end Action_Rows_Suffix;

      begin
         if Build_UI_View.Visible then
            return "Build: "
              & To_String (Build_UI_View.Candidate_Count_Label)
              & "; "
              & To_String (Build_UI_View.Candidate_Refresh_Action_Label)
              & "; "
              & To_String (Build_UI_View.Request_Status_Label)
              & "; "
             & To_String (Build_UI_View.Run_Command_Status_Label)
             & "; "
             & To_String (Build_UI_View.Run_Recovery_Hint)
              & ASCII.LF
              & "Actions:"
              & Action_Rows_Suffix;
         end if;

         if S.Latest_Build_Result.Has_Result then
            if S.Latest_Build_Result.Stdout_Truncated
              or else S.Latest_Build_Result.Stderr_Truncated
            then
               if Candidate_Stale then
                  return "Build: " & Normalized_Result_Label
                    & Detail_Suffix & ", output truncated, candidate stale";
               else
                  return "Build: " & Normalized_Result_Label
                    & Detail_Suffix & ", output truncated";
               end if;
            elsif Candidate_Stale then
               return "Build: " & Normalized_Result_Label
                 & Detail_Suffix & ", candidate stale";
            else
               return "Build: " & Normalized_Result_Label & Detail_Suffix;
            end if;
         elsif Candidate_Stale then
            return "Build: candidate stale";
         elsif Validation = Editor.Build_UI.Build_UI_Rejected_Missing_Consent
           or else Validation = Editor.Build_UI.Build_UI_Rejected_Stale_Consent
         then
            return "Build: consent required";
         elsif Validation = Editor.Build_UI.Build_UI_Valid then
            return "Build: ready";
         else
            return "Build: "
              & Editor.Build_UI.Recovery_Message (Validation);
         end if;
      end Build_Status_Label;

      function Search_Status_Label return String
      is
         Count : constant Natural :=
           Editor.Project_Search.Result_Count (S.Project_Search);
         Replace_Count : constant Natural :=
           Editor.Project_Search.Included_Replacement_Count (S.Project_Search);
      begin
         if Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
            return "Replace: stale preview";
         elsif Editor.Project_Search.Replace_Preview_Status (S.Project_Search) =
           Editor.Project_Search.Project_Replace_Preview_Ok
         then
            return "Replace: preview" & Natural'Image (Replace_Count)
              & " replacements";
         elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
            return "Search: stale";
         elsif not Editor.Project_Search.Has_Query (S.Project_Search) then
            return "Search: no query";
         elsif Editor.Project_Search.Results_Truncated (S.Project_Search)
           or else Editor.Project_Search.Was_Truncated (S.Project_Search)
         then
            return "Search:" & Natural'Image (Count) & " results, limit reached";
         elsif Count = 0 then
            return "Search: no matches";
         else
            return "Search:" & Natural'Image (Count) & " results";
         end if;
      end Search_Status_Label;

      function Quick_Open_Status_Label return String
      is
         Count : constant Natural := Editor.Quick_Open.Visible_Count (S.Quick_Open);
         Scope : constant String := Editor.Quick_Open.Path_Scope (S.Quick_Open);
         Filter : constant Editor.Quick_Open.Quick_Open_File_Kind_Filter :=
           Editor.Quick_Open.File_Kind_Filter (S.Quick_Open);
      begin
         if not Editor.Quick_Open.Is_Open (S.Quick_Open) then
            if Scope'Length = 0 and then Filter = Editor.Quick_Open.All_Files then
               return "";
            elsif Scope'Length > 0 then
               return "Quick Open: scope " & Scope & ", "
                 & Editor.Quick_Open.File_Kind_Filter_Name (Filter);
            else
               return "Quick Open: "
                 & Editor.Quick_Open.File_Kind_Filter_Name (Filter);
            end if;
         elsif Editor.Quick_Open.Query_Text (S.Quick_Open) = "" then
            return "Quick Open: type to open file";
         elsif Count = 0 then
            return "Quick Open: no matches";
         else
            return "Quick Open:" & Natural'Image (Count) & " matches";
         end if;
      end Quick_Open_Status_Label;

      function File_Tree_Status_Label return String
      is
         Scan : constant Editor.File_Tree.File_Tree_Scan_Result :=
           Editor.File_Tree.Scan_Status (S.File_Tree);
         Files : constant Natural := Editor.File_Tree.File_Node_Count (S.File_Tree);
      begin
         case Scan.Status is
            when Editor.File_Tree.File_Tree_No_Project =>
               return "File Tree: No project open.";
            when Editor.File_Tree.File_Tree_Scan_Ok =>
               if Files = 0 then
                  return "File Tree: ready";
               else
                  return "File Tree:" & Natural'Image (Files) & " files";
               end if;
            when Editor.File_Tree.File_Tree_Root_Not_Found
               | Editor.File_Tree.File_Tree_Invalid_Root =>
               return "File Tree: refresh required";
            when others =>
               return "File Tree: unavailable";
         end case;
      end File_Tree_Status_Label;

      function Workspace_Status_Label return String
      is
      begin
         if S.Post_Restore_Feedback_Current
           and then S.Last_Restore_Summary_Available
         then
            return "Workspace: "
              & Editor.Workspace_Persistence.Restore_Details_Label
                (S.Last_Restore_Summary);
         elsif S.Post_Restore_Feedback_Current then
            return "Workspace: restore feedback";
         else
            return "";
         end if;
      end Workspace_Status_Label;

      function Recent_Projects_Status_Label return String
      is
         Count : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
         Missing : constant Natural :=
           Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects);
      begin
         if Count = 0 then
            return "";
         elsif Missing > 0 then
            return "Recent Projects:" & Natural'Image (Count)
              & " entries," & Natural'Image (Missing) & " missing";
         else
            return "Recent Projects:" & Natural'Image (Count) & " entries";
         end if;
      end Recent_Projects_Status_Label;

      function Startup_Status_Label return String
      is
      begin
         if Editor.Startup_Readiness.Has_Recorded_Startup_Summary then
            return Editor.Startup_Readiness.Status_Bar_Label
              (Editor.Startup_Readiness.Current_Startup_Summary);
         else
            return "";
         end if;
      end Startup_Status_Label;

      function Build_Status_Snapshot
        return Editor.Status_Bar.Status_Bar_Snapshot
      is
         Result : Editor.Status_Bar.Status_Bar_Snapshot;
         Found  : Boolean := False;
         Msg    : Editor.Messages.Editor_Message;
         Msg_Text : Unbounded_String := Null_Unbounded_String;
      begin
         Result.File_Name := Snap.File_Name;
         if Length (Result.File_Name) = 0 then
            Result.File_Name := To_Unbounded_String ("Untitled");
         end if;
         Result.File_Label := To_Unbounded_String (File_Label);
         Result.Buffer_Kind_Label := To_Unbounded_String (Buffer_Kind_Label);
         Result.File_State_Label := To_Unbounded_String (File_State_Label);
         Result.Has_Active_Buffer := Editor.State.Has_Active_Buffer (S);
         Result.Is_Dirty := Snap.Is_Dirty;
         if Snap.Is_Dirty then
            Result.Dirty_State_Label := To_Unbounded_String ("Modified");
         end if;
         Result.Cursor_Row := Snap.Primary_Caret_Logical_Row;
         Result.Cursor_Column := Snap.Primary_Caret_Col;
         Result.Selection_Count := Snap.Selection_Count;
         Result.Selected_Character_Count := Snap.Selected_Character_Count;
         Result.Selected_Line_Count := Snap.Selected_Line_Count;
         Result.Rectangular_Selection_Active := Snap.Rectangular_Selection_Count > 0;
         Result.Undo_Redo_Label := To_Unbounded_String (Undo_Redo_Label);
         Result.Caret_Count := Natural'Max (1, Snap.Caret_Count);
         Result.Line_Number_Mode := To_Unbounded_String (Line_Mode_Text);
         Result.Find_Active_Match :=
           (if Snap.Active_Find_Match.Index = Editor.Search.No_Search_Match
            then 0
            else Natural (Snap.Active_Find_Match.Index));
         Result.Active_Find_Match_Count := Snap.Total_Find_Match_Count;
         --  Status/render packet projection fields are derived
         --  from canonical active-buffer Find snapshot data only.
         Result.Find_Input_Open := Snap.Find_Visible;
         Result.Find_Query_Present := Length (Snap.Find_Query) > 0;
         Result.Find_Wrapped := Snap.Find_Wrapped;
         Result.Diagnostic_Count := Snap.Total_Diagnostic_Count;
         Result.Has_Project := Snap.Has_Project;
         Result.Project_Label := Snap.Project_Label;
         Result.Project_State_Label := To_Unbounded_String (Project_State_Label);
         Result.Focus_Label := To_Unbounded_String (Focus_Label);
         Result.Active_Panel_Label := To_Unbounded_String (Active_Panel_Label);
         Result.Input_Mode_Label := To_Unbounded_String (Input_Mode_Label);
         Result.Overlay_Query_Active :=
           Editor.Focus_Management.Overlay_Query_Active (S);
         Result.Focus_Hint :=
           To_Unbounded_String
             (Editor.Contextual_Help.Focus_Hint
                (Focus_Label, Editor.Command_Palette.Current_Config.Show_Keybindings));
         Result.Lifecycle_Hint :=
           To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
         Result.Pending_Confirmation_Label := To_Unbounded_String (Pending_Status_Label);
         Result.Outline_Status_Label := To_Unbounded_String (Outline_Status_Label);
         Result.Diagnostics_Status_Label := To_Unbounded_String (Diagnostics_Status_Label);
         Result.Build_Status_Label := To_Unbounded_String (Build_Status_Label);
         Result.Search_Status_Label := To_Unbounded_String (Search_Status_Label);
         Result.Quick_Open_Status_Label :=
           To_Unbounded_String (Quick_Open_Status_Label);
         Result.File_Tree_Status_Label :=
           To_Unbounded_String (File_Tree_Status_Label);
         Result.Workspace_Status_Label :=
           To_Unbounded_String (Workspace_Status_Label);
         Result.Recent_Projects_Status_Label :=
           To_Unbounded_String (Recent_Projects_Status_Label);
         Result.Outline_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Outline_Status_Label);
         Result.Diagnostics_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Diagnostics_Status_Label);
         Result.Build_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Build_Status_Label);
         Result.Search_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Search_Status_Label);
         Result.Quick_Open_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Quick_Open_Status_Label);
         Result.File_Tree_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.File_Tree_Status_Label);
         Result.Workspace_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For (Result.Workspace_Status_Label);
         Result.Recent_Projects_Status_Kind :=
           Editor.Status_Bar.Status_Message_Kind_For
             (Result.Recent_Projects_Status_Label);
         Result.Startup_Status_Label :=
           To_Unbounded_String (Startup_Status_Label);
         if Editor.Buffers.Global_Has_Active_Buffer_Group then
            if Length (Result.Lifecycle_Hint) > 0 then
               Append (Result.Lifecycle_Hint, " | ");
            end if;
            Append
              (Result.Lifecycle_Hint,
               "Group: " & Editor.Buffers.Global_Active_Buffer_Group);
         end if;
         if Snap.Feature_Panel_Visible
           and then Editor.Feature_Panel.Is_Known_Feature (Snap.Active_Feature)
         then
            Result.Active_Feature_Label :=
              To_Unbounded_String
                (Editor.Feature_Panel.Feature_Display_Label (Snap.Active_Feature));
         end if;
         Msg := Editor.Messages.Active_Message (Snap.Messages, Found);
         if Found then
            Msg_Text := To_Unbounded_String (Editor.Messages.Text (Msg));
            if Snap.Post_Restore_Feedback_Current
              or else not Is_Restore_Feedback (To_String (Msg_Text))
            then
               Result.Has_Command_Feedback := True;
               Result.Command_Feedback := Msg_Text;
               Result.Command_Feedback_Severity :=
                 To_Unbounded_String (Severity_Label (Editor.Messages.Severity (Msg)));
            end if;
         end if;
         return Result;
      end Build_Status_Snapshot;

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
            Record_Debug_Text_For_Test (To_String (T.Text));
         end loop;
      end Push_Build_UI_Panel;

      begin
      Out_Packet.Rect_Count := 0;
      Out_Packet.Glyph_Count := 0;

      if Last_Settings_Version /= Editor.Settings.Version then
         Editor.Render_Cache.Invalidate_All;
         Last_Settings_Version := Editor.Settings.Version;
      end if;

      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Editor.View.Update_Scroll_For_Snapshot (Snap, Layout);
      Scroll_X := Editor.View.Scroll_X;
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Scroll_X := Editor.View.Scroll_X;
      S := Editor.Input_Bridge.Get_State_For_Test;

      Push_Tab_Bar (Out_Packet);
      Push_File_Tree (Out_Packet);
      declare
      begin
         Editor.Feature_Panel.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Panel          => Editor.Input_Bridge.Feature_Panel_For_Render,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
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
      declare
      begin
         Editor.Bookmarks.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Snap,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;
      Push_Build_UI_Panel (Out_Packet);

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

      if Snap.Terminal_Tasks.Visible then
         Editor.Terminal_Tasks.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      elsif Editor.Panels.Active_Bottom_Content (Layout.Panels) = Editor.Panels.Search_Results_Content then
         Editor.Search_Results.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      else
         Editor.Problems.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end if;

      declare
         Status_Snapshot : constant Editor.Status_Bar.Status_Bar_Snapshot :=
           Build_Status_Snapshot;
      begin
         Editor.Status_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            Snapshot       => Status_Snapshot,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

      declare
         Pending_Visible : Boolean := False;
         Pending_Background : Guikit.Draw.Rectangle_Command_Vectors.Vector;
         Pending_Summary_Text : Guikit.Draw.Text_Command_Vectors.Vector;
         Pending_Action_Text : Guikit.Draw.Text_Command_Vectors.Vector;
         Pending_Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
      begin
         Editor.Pending_Transition_Bar.Surface_Rendering.Build_Packet
           (Packet         => Out_Packet,
            State          => S,
            Pending        => S.Pending_Transitions,
            Layout_Config  => Layout,
            Viewport_Width => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height,
            Cell_W         => Cell_W,
            Cell_H         => Cell_H);
      end;

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

   end Build_Render_Packet;

end Editor.Render_Packet;
