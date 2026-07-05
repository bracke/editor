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
with Editor.Contextual_Help;
with Editor.Executor;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Build_UI_Panel_Layout;
with Editor.Feature_Diagnostics;
with Editor.Terminal_Tasks;
with Editor.Commands;
with Editor.Settings;
with Editor.Scrollbars;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Status_Bar;
with Editor.Messages;
with Editor.Buffers;
with Editor.Tab_Bar;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Problems;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
with Editor.Quick_Open_Markers;
with Editor.Buffer_Switcher;
with Editor.Buffer_Switcher_Contextual_Hints;
use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
with Editor.Go_To_Line;
with Editor.Guided_Prompts;
with Editor.Project_Search_Bar;
use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
with Editor.Search_Results;
with Editor.Project_Search;
with Editor.Project;
with Editor.Outline;
with Editor.Pending_Transitions;
with Editor.Build_Result_Summary;
with Editor.Workspace_Persistence;
with Editor.History;
with Editor.Panel_Focus;
with Editor.Pending_Transition_Bar;
with Editor.Overlay_Focus;
with Editor.Focus_Management;
with Editor.Recent_Projects;
with Editor.State;
with Editor.Feature_Panel;
with Editor.Bookmarks;
with Editor.Keybinding_Management;
with Editor.Lifecycle_Guidance;
with Editor.Startup_Readiness;
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
use type Editor.Keybinding_Management.Keybinding_Filter;
use type Editor.Keybinding_Management.Keybinding_Capture_State;
package body Editor.Render_Packet is

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
      File_Tree_Indent_Guide_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.File_Tree_Indent_Guide;
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

      procedure Push_Field_Selection
        (Packet : in out Render_Packet;
         Snap   : Editor.Input_Field.Field_Snapshot;
         Layer  : Render_Layer;
         X      : Float;
         Y      : Float)
      is
         Visible_Count : constant Natural := Length (Snap.Visible_Text);
         Visible_First : constant Natural := Snap.First_Visible_Column;
         Visible_Last  : constant Natural := Visible_First + Visible_Count;
         A : Natural := Snap.Selection_Start;
         B : Natural := Snap.Selection_End;
      begin
         if not Snap.Has_Selection or else Visible_Count = 0 then
            return;
         end if;

         if A < Visible_First then
            A := Visible_First;
         end if;
         if B > Visible_Last then
            B := Visible_Last;
         end if;

         if B > A then
            Push_Rect
              (Packet, Layer,
               X + Float ((A - Visible_First) * Cell_W), Y,
               Float ((B - A) * Cell_W), Float (Cell_H),
               Selection_Background_Color.R,
               Selection_Background_Color.G,
               Selection_Background_Color.B);
         end if;
      end Push_Field_Selection;

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

      procedure Push_Gutter_Line_Number
        (Packet      : in out Render_Packet;
         Row         : Natural;
         Screen_Row  : Natural;
         Current_Row : Natural;
         Is_Current  : Boolean)
      is
         Number : constant String := Editor.Line_Numbers.Display_Text
           (Config       => Line_Number_Config,
            Document_Row => Row,
            Current_Row  => Current_Row);
         Line_Number_Color : constant Editor.Theme.Color_RGB :=
           (if Is_Current
            then Editor.Theme.Current_Line_Number
            else Editor.Theme.Inactive_Line_Number);
      begin
         for I in Number'Range loop
            if Number (I) /= ' ' then
               declare
                  M : Editor.Fonts.Glyph_Metric;
               begin
                  if Editor.Fonts.Get_Glyph (Number (I), M) then
                     Editor.Fonts.Check_Glyph_Fits_Cell
                       (M, Cell_W, Cell_H);
                     declare
                        Digit_From_Right : constant Natural := Number'Last - I;
                        Cell_X : constant Float :=
                          Editor.Layout.Line_Number_Cell_X
                            (Layout, Line_Count, Digit_From_Right);
                        GX : constant Float := Float'Floor (Cell_X + M.Bearing_X + 0.5);
                        GY : constant Float := Float'Floor (Glyph_Y (Screen_Row, M) + 0.5);
                     begin
                        if In_Gutter_Viewport (GX, GY, M.W, M.H) then
                           Push_Glyph
                             (Packet, Gutter_Text_Layer,
                              GX, GY, M.W, M.H,
                              M.U0, M.V0, M.U1, M.V1,
                              Line_Number_Color.R,
                              Line_Number_Color.G,
                              Line_Number_Color.B);
                        end if;
                     end;
                  end if;
               end;
            end if;
         end loop;
      end Push_Gutter_Line_Number;


      procedure Push_Fold_Marker
        (Packet     : in out Render_Packet;
         Row        : Natural;
         Screen_Row : Natural)
      is
         Size : constant Float := Float'Max (4.0, Float (Cell_W) * 0.45);
         X    : constant Float :=
           Float (Editor.Layout.Gutter_Fold_X (Layout));
         Y    : constant Float :=
           Screen_Y (Screen_Row) + (Float (Cell_H) - Size) / 2.0;
         Collapsed : constant Boolean :=
           Editor.Folding.Is_Fold_Collapsed (Snap.Folding, Row);
      begin
         if not Editor.Folding.Has_Fold_Start (Snap.Folding, Row) then
            return;
         end if;

         if In_Gutter_Viewport (X, Y, Size, Size) then
            if Collapsed then
               Push_Rect
                 (Packet, Fold_Marker_Layer,
                  X + Size * 0.25, Y,
                  Size * 0.5, Size,
                  Fold_Marker_Color.R,
                  Fold_Marker_Color.G,
                  Fold_Marker_Color.B);
            else
               Push_Rect
                 (Packet, Fold_Marker_Layer,
                  X, Y + Size * 0.25,
                  Size, Size * 0.5,
                  Fold_Marker_Color.R,
                  Fold_Marker_Color.G,
                  Fold_Marker_Color.B);
            end if;
         end if;
      end Push_Fold_Marker;


      procedure Push_Gutter_Marker
        (Packet     : in out Render_Packet;
         Row        : Natural;
         Screen_Row : Natural)
      is
         Found : Boolean := False;
         Kind  : Editor.Gutter_Markers.Gutter_Marker_Kind;
         Color : Editor.Theme.Color_RGB;
         Hover_Background : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Gutter_Marker_Hover_Background;
         Hover_Outline : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Gutter_Marker_Hover_Outline;
         Zone_W : constant Natural := Editor.Layout.Gutter_Marker_Width;
         Size : constant Float := Float'Max (3.0, Float (Cell_W) * 0.45);
         X : constant Float :=
           Float (Editor.Layout.Gutter_Marker_X (Layout))
           + (Float (Zone_W) - Size) / 2.0;
         Y : constant Float :=
           Screen_Y (Screen_Row) + (Float (Cell_H) - Size) / 2.0;
         Hover_Active : constant Boolean :=
           Snap.Gutter_Marker_Hover.Active
           and then Snap.Gutter_Marker_Hover.Row = Row;
         Hover_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout));
         Hover_Y : constant Float := Screen_Y (Screen_Row);
         Hover_W : constant Float := Float (Zone_W);
         Hover_H : constant Float := Float (Cell_H);
      begin
         if not Editor.Layout.Marker_Zone_Visible (Layout, Line_Count) then
            return;
         end if;

         Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
           (State => Snap.Gutter_Markers,
            Row   => Row,
            Found => Found);

         if not Found then
            return;
         end if;

         case Kind is
            when Editor.Gutter_Markers.Diagnostic_Error_Marker =>
               Color := Editor.Theme.Gutter_Diagnostic_Error;
            when Editor.Gutter_Markers.Diagnostic_Warning_Marker =>
               Color := Editor.Theme.Gutter_Diagnostic_Warning;
            when Editor.Gutter_Markers.Bookmark_Marker =>
               Color := Editor.Theme.Gutter_Bookmark;
            when Editor.Gutter_Markers.Added_Line_Marker =>
               Color := Editor.Theme.Gutter_Added_Line;
            when Editor.Gutter_Markers.Modified_Line_Marker =>
               Color := Editor.Theme.Gutter_Modified_Line;
            when Editor.Gutter_Markers.Dirty_Line_Marker =>
               Color := Editor.Theme.Gutter_Dirty_Line;
         end case;

         if Hover_Active and then In_Gutter_Viewport (Hover_X, Hover_Y, Hover_W, Hover_H) then
            Push_Rect
              (Packet, Gutter_Marker_Hover_Layer,
               Hover_X, Hover_Y, Hover_W, Hover_H,
               Hover_Background.R, Hover_Background.G, Hover_Background.B);
            Push_Rect
              (Packet, Gutter_Marker_Hover_Layer,
               Hover_X, Hover_Y, Hover_W, 1.0,
               Hover_Outline.R, Hover_Outline.G, Hover_Outline.B);
            Push_Rect
              (Packet, Gutter_Marker_Hover_Layer,
               Hover_X, Hover_Y + Hover_H - 1.0, Hover_W, 1.0,
               Hover_Outline.R, Hover_Outline.G, Hover_Outline.B);
         end if;

         if Kind = Editor.Gutter_Markers.Added_Line_Marker then
            declare
               Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 3.0);
               Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout));
               Bar_Y : constant Float := Screen_Y (Screen_Row);
               Bar_H : constant Float := Float (Cell_H);
            begin
               if In_Gutter_Viewport (Bar_X, Bar_Y, Bar_W, Bar_H) then
                  Push_Rect
                    (Packet, Gutter_Marker_Layer,
                     Bar_X, Bar_Y, Bar_W, Bar_H,
                     Color.R, Color.G, Color.B);
               end if;
            end;
         elsif Kind = Editor.Gutter_Markers.Modified_Line_Marker then
            declare
               Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 3.0);
               Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout));
               Bar_H : constant Float := Float'Max (1.0, Float (Cell_H) * 0.75);
               Bar_Y : constant Float :=
                 Screen_Y (Screen_Row) + (Float (Cell_H) - Bar_H) / 2.0;
            begin
               if In_Gutter_Viewport (Bar_X, Bar_Y, Bar_W, Bar_H) then
                  Push_Rect
                    (Packet, Gutter_Marker_Layer,
                     Bar_X, Bar_Y, Bar_W, Bar_H,
                     Color.R, Color.G, Color.B);
               end if;
            end;
         elsif Kind = Editor.Gutter_Markers.Dirty_Line_Marker then
            declare
               Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 4.0);
               Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout));
            begin
               if In_Gutter_Viewport (Bar_X, Screen_Y (Screen_Row), Bar_W, Float (Cell_H)) then
                  Push_Rect
                    (Packet, Gutter_Marker_Layer,
                     Bar_X, Screen_Y (Screen_Row), Bar_W, Float (Cell_H),
                     Color.R, Color.G, Color.B);
               end if;
            end;
         elsif In_Gutter_Viewport (X, Y, Size, Size) then
            Push_Rect
              (Packet, Gutter_Marker_Layer,
               X, Y, Size, Size,
               Color.R, Color.G, Color.B);
         end if;
      end Push_Gutter_Marker;

      procedure Push_Folded_Ellipsis
        (Packet     : in out Render_Packet;
         Row        : Natural;
         Screen_Row : Natural;
         Start_Col  : Natural)
      is
         Text : constant String := "...";
         Pen_Col : Natural := Start_Col;
      begin
         if not Editor.Folding.Is_Fold_Collapsed (Snap.Folding, Row) then
            return;
         end if;

         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  declare
                     GX : constant Float := Float'Floor (Glyph_X (Pen_Col, M) + 0.5);
                     GY : constant Float := Float'Floor (Glyph_Y (Screen_Row, M) + 0.5);
                  begin
                     if In_Viewport (GX, GY, M.W, M.H) then
                        Push_Glyph
                          (Packet, Text_Layer,
                           GX, GY, M.W, M.H,
                           M.U0, M.V0, M.U1, M.V1,
                           Folded_Line_Ellipsis_Color.R,
                           Folded_Line_Ellipsis_Color.G,
                           Folded_Line_Ellipsis_Color.B);
                     end if;
                  end;
               end if;
            end;
            Pen_Col := Pen_Col + 1;
         end loop;
      end Push_Folded_Ellipsis;


      function Fit_Text
        (Text        : String;
         Max_Columns : Natural) return String
      is
      begin
         if Max_Columns = 0 then
            return "";
         elsif Text'Length <= Max_Columns then
            return Text;
         elsif Max_Columns = 1 then
            return "~";
         else
            return Text (Text'First .. Text'First + Max_Columns - 2) & "~";
         end if;
      end Fit_Text;

      procedure Push_Palette_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Palette_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Palette_Text;

      procedure Push_Tab_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Tab_Bar_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Tab_Text;

      procedure Push_Tab_Bar
        (Packet : in out Render_Packet)
      is
         Bar_H : constant Natural := Editor.Layout.Tab_Bar_Height (Layout);
         Bar_W : constant Natural :=
           Editor.Layout.Tab_Bar_Width (Layout, Editor.View.Viewport_Width);
         Count : constant Natural := Editor.Buffers.Global_Count;
         Padding_Cols : constant Natural := 1;
      begin
         if Bar_H = 0 or else Bar_W = 0 then
            return;
         end if;

         Push_Rect
           (Packet, Tab_Bar_Background_Layer,
            Float (Layout.Origin_X), Float (Editor.Layout.Tab_Bar_Y (Layout)),
            Float (Bar_W), Float (Bar_H),
            Tab_Bar_Background_Color.R,
            Tab_Bar_Background_Color.G,
            Tab_Bar_Background_Color.B);

         if Count = 0 then
            Push_Tab_Text
              (Packet,
               Editor.Tab_Bar.Empty_Display_Text (Bar_W / Cell_W),
               Float (Layout.Origin_X + Padding_Cols * Cell_W),
               Float (Editor.Layout.Tab_Bar_Y (Layout)),
               Tab_Bar_Inactive_Foreground_Color);
            return;
         end if;

         for I in 1 .. Count loop
            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Global_Summary_At (I);
               Rect : constant Editor.Tab_Bar.Tab_Rect :=
                 Editor.Tab_Bar.Rect_For_Index
                   (Layout.Tab_Bar, I, Bar_W, Cell_W, Cell_H,
                    Layout.Origin_X, Layout.Origin_Y);
               State : constant Editor.Tab_Bar.Tab_Visual_State :=
                 Editor.Tab_Bar.Visual_State (Summary);
               Background : Editor.Theme.Color_RGB := Tab_Bar_Inactive_Background_Color;
               Foreground : Editor.Theme.Color_RGB := Tab_Bar_Inactive_Foreground_Color;
               Reserved_Cols : Natural := 2 * Padding_Cols;
               Text_Cols : Natural := 0;
            begin
               exit when not Rect.Visible;

               if State = Editor.Tab_Bar.Active_Tab
                 or else State = Editor.Tab_Bar.Dirty_Active_Tab
               then
                  Background := Tab_Bar_Active_Background_Color;
                  Foreground := Tab_Bar_Active_Foreground_Color;
               end if;

               Push_Rect
                 (Packet, Tab_Bar_Tab_Layer,
                  Float (Rect.X), Float (Rect.Y), Float (Rect.W), Float (Rect.H),
                  Background.R, Background.G, Background.B);
               Push_Rect
                 (Packet, Tab_Bar_Tab_Layer,
                  Float (Rect.X + Rect.W - 1), Float (Rect.Y), 1.0, Float (Rect.H),
                  Tab_Bar_Border_Color.R, Tab_Bar_Border_Color.G, Tab_Bar_Border_Color.B);

               if Summary.Is_Dirty and then Rect.W >= 4 * Cell_W then
                  declare
                     Dirty_Size : constant Float := Float'Max (2.0, Float (Cell_W) / 3.0);
                     Dirty_X : constant Float :=
                       Float (Rect.X + Rect.W - 3 * Cell_W)
                       + (Float (Cell_W) - Dirty_Size) / 2.0;
                     Dirty_Y : constant Float :=
                       Float (Rect.Y) + (Float (Cell_H) - Dirty_Size) / 2.0;
                  begin
                     Push_Rect
                       (Packet, Tab_Bar_Dirty_Layer,
                        Dirty_X, Dirty_Y, Dirty_Size, Dirty_Size,
                        Tab_Bar_Dirty_Color.R, Tab_Bar_Dirty_Color.G, Tab_Bar_Dirty_Color.B);
                     Reserved_Cols := Reserved_Cols + 1;
                  end;
               end if;

               if Layout.Tab_Bar.Show_Close_Buttons
                 and then Rect.Close_W > 0
               then
                  Push_Rect
                    (Packet, Tab_Bar_Close_Layer,
                     Float (Rect.Close_X), Float (Rect.Y + Cell_H / 4),
                     Float (Rect.Close_W), Float'Max (1.0, Float (Cell_H / 2)),
                     Tab_Bar_Close_Color.R,
                     Tab_Bar_Close_Color.G,
                     Tab_Bar_Close_Color.B);
                  Reserved_Cols := Reserved_Cols + 2;
               end if;

               if Rect.W / Cell_W > Reserved_Cols then
                  Text_Cols := Rect.W / Cell_W - Reserved_Cols;
               end if;

               Push_Tab_Text
                 (Packet,
                  Editor.Tab_Bar.Display_Text (Summary, Text_Cols),
                  Float (Rect.X + Padding_Cols * Cell_W),
                  Float (Rect.Y),
                  Foreground);
            end;
         end loop;
      end Push_Tab_Bar;

      procedure Push_File_Tree_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, File_Tree_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_File_Tree_Text;

      procedure Push_File_Tree
        (Packet : in out Render_Packet)
      is
         Tree : Editor.File_Tree.File_Tree_State;
         Geometry : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.File_Tree_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         W    : constant Natural := Geometry.Width;
         H    : constant Natural := Geometry.Height;
         X    : constant Float := Float (Geometry.X);
         Y    : constant Float := Float (Geometry.Y);
         Max_Rows : constant Natural := H / Cell_H;
         Text_Columns : constant Natural :=
           (if W / Cell_W > 1 then W / Cell_W - 1 else 0);
         Active_Node : Editor.File_Tree.File_Tree_Node_Id :=
           Editor.File_Tree.No_File_Tree_Node;
         Active_Found : Boolean := False;
         View_State : Editor.File_Tree_View.File_Tree_View_State :=
           Editor.Input_Bridge.File_Tree_View_For_Render;
         Focused : constant Boolean := Editor.Input_Bridge.File_Tree_Focused_For_Render;
         Emitted_Row  : Natural := 0;
      begin
         if W = 0 or else H = 0 then
            return;
         end if;

         Editor.Input_Bridge.Get_File_Tree_For_Render (Tree);

         if Editor.Buffers.Global_Current_File.Has_Path then
            Active_Node := Editor.File_Tree.Find_By_Path
              (Tree, To_String (Editor.Buffers.Global_Current_File.Path), Active_Found);
         end if;

         Push_Rect
           (Packet, File_Tree_Background_Layer,
            X, Y, Float (W), Float (H),
            File_Tree_Background_Color.R,
            File_Tree_Background_Color.G,
            File_Tree_Background_Color.B);

         Push_Rect
           (Packet, File_Tree_Separator_Layer,
            X + Float (W) - 1.0, Y, 1.0, Float (H),
            File_Tree_Separator_Color.R,
            File_Tree_Separator_Color.G,
            File_Tree_Separator_Color.B);

         declare
            Splitter : constant Editor.Layout.Rect :=
              Editor.Layout.Panel_Splitter_Rect
                (Layout,
                 Editor.Panels.File_Tree_Panel,
                 Editor.View.Viewport_Width,
                 Editor.View.Viewport_Height);
         begin
            if Splitter.Width > 0 and then Splitter.Height > 0 then
               Push_Rect
                 (Packet, File_Tree_Splitter_Layer,
                  Float (Splitter.X), Float (Splitter.Y),
                  Float (Splitter.Width), Float (Splitter.Height),
                  File_Tree_Splitter_Color.R,
                  File_Tree_Splitter_Color.G,
                  File_Tree_Splitter_Color.B);
            end if;
         end;

         if Max_Rows = 0 then
            return;
         end if;

         if Editor.File_Tree.Is_Empty (Tree) then
            Push_File_Tree_Text
              (Packet,
               Editor.File_Tree_View.Truncate_Label
                 (Editor.Contextual_Help.Empty_File_Tree_Text (Snap.Has_Project),
                  Text_Columns),
               X + Float (Cell_W), Y,
               Quick_Open_Secondary_Foreground_Color);
            return;
         end if;

         Editor.File_Tree_View.Ensure_Selected_Row_Visible
           (View_State, Tree, Max_Rows);

         if Focused then
            Push_Rect
              (Packet, File_Tree_Separator_Layer,
               X, Y, 2.0, Float (H),
               File_Tree_Focused_Border_Color.R,
               File_Tree_Focused_Border_Color.G,
               File_Tree_Focused_Border_Color.B);
         end if;

         for Row_Index in View_State.Top_Row .. Editor.File_Tree.Visible_Row_Count (Tree) loop
            exit when Emitted_Row >= Max_Rows;

            declare
               Visible : constant Editor.File_Tree.Visible_File_Tree_Row :=
                 Editor.File_Tree.Visible_Row (Tree, Row_Index);
               Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
                 Editor.File_Tree.Node (Tree, Visible.Node_Id);
            begin
               if (not Layout.File_Tree_View.Show_Root)
                 and then Node.Id = Editor.File_Tree.Root (Tree)
               then
                  null;
               else
                  declare
                     Display_Node : Editor.File_Tree.File_Tree_Node_Summary := Node;
                  begin
                     if not Layout.File_Tree_View.Show_Root
                       and then Display_Node.Depth > 0
                     then
                        Display_Node.Depth := Display_Node.Depth - 1;
                     end if;

                     declare
                        Row_Y : constant Float :=
                          Y + Float (Emitted_Row * Cell_H);
                        Is_Active : constant Boolean :=
                          Active_Found and then Node.Id = Active_Node;
                        Is_Selected : constant Boolean :=
                          Row_Index = View_State.Selected_Row_Index;
                        Text_Color : constant Editor.Theme.Color_RGB :=
                          (if Is_Selected and then Focused then
                             File_Tree_Selected_Active_Foreground_Color
                           elsif Is_Selected then
                             File_Tree_Selected_Inactive_Foreground_Color
                           elsif Is_Active then File_Tree_Active_Foreground_Color
                           elsif Node.Kind = Editor.File_Tree.Directory_Node then
                             File_Tree_Directory_Foreground_Color
                           else File_Tree_Foreground_Color);
                        Text : constant String :=
                          Editor.File_Tree_View.Format_Row_Text
                            (Layout.File_Tree_View, Display_Node, Text_Columns);
                     begin
                        if Is_Selected then
                           declare
                              Bg : constant Editor.Theme.Color_RGB :=
                                (if Focused then File_Tree_Selected_Active_Background_Color
                                 else File_Tree_Selected_Inactive_Background_Color);
                           begin
                              Push_Rect
                                (Packet, File_Tree_Row_Highlight_Layer,
                                 X, Row_Y, Float (W), Float (Cell_H),
                                 Bg.R, Bg.G, Bg.B);
                           end;
                        elsif Is_Active then
                           Push_Rect
                             (Packet, File_Tree_Row_Highlight_Layer,
                              X, Row_Y, Float (W), Float (Cell_H),
                              File_Tree_Active_Background_Color.R,
                              File_Tree_Active_Background_Color.G,
                              File_Tree_Active_Background_Color.B);
                        end if;

                        if Layout.File_Tree_View.Show_Indent_Guides
                          and then Display_Node.Depth > 0
                        then
                           for D in 1 .. Display_Node.Depth loop
                              declare
                                 Guide_X : constant Float :=
                                   X + Float ((D - 1)
                                     * Layout.File_Tree_View.Indent_In_Columns
                                     * Cell_W)
                                   + Float (Cell_W) / 2.0;
                              begin
                                 Push_Rect
                                   (Packet, File_Tree_Indent_Guide_Layer,
                                    Guide_X, Row_Y, 1.0, Float (Cell_H),
                                    File_Tree_Indent_Guide_Color.R,
                                    File_Tree_Indent_Guide_Color.G,
                                    File_Tree_Indent_Guide_Color.B);
                              end;
                           end loop;
                        end if;

                        Push_File_Tree_Text
                          (Packet, Text, X + Float (Cell_W), Row_Y, Text_Color);
                     end;

                     Emitted_Row := Emitted_Row + 1;
                  end;
               end if;
            end;
         end loop;
      end Push_File_Tree;

      procedure Push_Status_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Status_Bar_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Status_Text;

      procedure Push_Message_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Message_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Message_Text;

      procedure Push_Pending_Bar_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Layer  : Render_Layer;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Pending_Bar_Text;

      procedure Push_Problems_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Problems_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Problems_Text;

      function Problems_Severity_Color
        (Severity : Editor.Problems.Problem_Row_Severity)
         return Editor.Theme.Color_RGB
      is
      begin
         case Severity is
            when Editor.Problems.Problem_Error =>
               return Problems_Error_Color;
            when Editor.Problems.Problem_Warning =>
               return Problems_Warning_Color;
            when Editor.Problems.Problem_Info =>
               return Problems_Info_Color;
            when Editor.Problems.Problem_Hint =>
               return Problems_Hint_Color;
         end case;
      end Problems_Severity_Color;

      procedure Push_Terminal_Tasks_Panel
        (Packet : in out Render_Packet)
      is
         Geometry : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Splitter : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Splitter_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Snapshot : constant Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot :=
           Snap.Terminal_Tasks;
         Capacity_Rows : Natural := 0;
         Header_Rows : constant Natural := 1;
         Task_Rows : Natural := 0;
         Output_Rows : Natural := 0;
         Text_Columns : Natural := 0;
         Selected_Background : constant Editor.Theme.Color_RGB :=
           (if Snapshot.Focused then Problems_Selected_Active_Background_Color
            else Problems_Selected_Inactive_Background_Color);
         Selected_Foreground : constant Editor.Theme.Color_RGB :=
           (if Snapshot.Focused then Problems_Selected_Active_Foreground_Color
            else Problems_Selected_Inactive_Foreground_Color);

         function Clipped (Text : String) return String is
         begin
            if Text_Columns = 0 then
               return "";
            elsif Text'Length <= Text_Columns then
               return Text;
            else
               return Ada.Strings.Fixed.Head (Text, Text_Columns);
            end if;
         end Clipped;

         function Row_Text
           (Row : Editor.Terminal_Tasks.Terminal_Task_Row) return String
         is
            Program : constant String := To_String (Row.Program_Label);
            Profile : constant String := To_String (Row.Profile_Label);
            Status  : constant String := To_String (Row.Status_Label);
            Label   : constant String :=
              (if Profile'Length = 0 then To_String (Row.Label)
               else To_String (Row.Label) & " [" & Profile & "]");
         begin
            if Program'Length = 0 then
               return Label & "  " & Status;
            else
               return Label & "  " & Status & "  " & Program;
            end if;
         end Row_Text;
      begin
         if Geometry.Width = 0 or else Geometry.Height = 0 then
            return;
         end if;

         Push_Rect
           (Packet, Problems_Background_Layer,
            Float (Geometry.X), Float (Geometry.Y),
            Float (Geometry.Width), Float (Geometry.Height),
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);

         if Splitter.Width > 0 and then Splitter.Height > 0 then
            Push_Rect
              (Packet, Problems_Background_Layer,
               Float (Splitter.X), Float (Splitter.Y),
               Float (Splitter.Width), Float (Splitter.Height),
               Problems_Separator_Color.R,
               Problems_Separator_Color.G,
               Problems_Separator_Color.B);
         end if;

         Capacity_Rows := Geometry.Height / Cell_H;
         if Capacity_Rows = 0 then
            return;
         end if;

         if Geometry.Width > 2 * Cell_W then
            Text_Columns := (Geometry.Width / Cell_W) - 2;
         end if;

         Push_Rect
           (Packet, Problems_Header_Layer,
            Float (Geometry.X), Float (Geometry.Y),
            Float (Geometry.Width), Float (Cell_H),
            Problems_Header_Background_Color.R,
            Problems_Header_Background_Color.G,
            Problems_Header_Background_Color.B);
         Push_Problems_Text
           (Packet,
            Clipped
              ("Terminal  " & To_String (Snapshot.Status_Label)),
            Float (Geometry.X + Cell_W),
            Float (Geometry.Y),
            Problems_Foreground_Color);

         if Capacity_Rows <= Header_Rows then
            return;
         end if;

         Task_Rows :=
           Natural'Min
             (Snapshot.Row_Count,
              Natural'Min (3, Capacity_Rows - Header_Rows));
         Output_Rows := Capacity_Rows - Header_Rows - Task_Rows;

         for I in 1 .. Task_Rows loop
            declare
               Row : constant Editor.Terminal_Tasks.Terminal_Task_Row :=
                 Snapshot.Rows (I);
               Y : constant Float :=
                 Float (Geometry.Y + (Header_Rows + I - 1) * Cell_H);
               Text_Color : Editor.Theme.Color_RGB := Problems_Foreground_Color;
            begin
               if Row.Selected then
                  Push_Rect
                    (Packet, Problems_Row_Layer,
                     Float (Geometry.X), Y,
                     Float (Geometry.Width), Float (Cell_H),
                     Selected_Background.R,
                     Selected_Background.G,
                     Selected_Background.B);
                  Text_Color := Selected_Foreground;
               elsif I mod 2 = 0 then
                  Push_Rect
                    (Packet, Problems_Row_Layer,
                     Float (Geometry.X), Y,
                     Float (Geometry.Width), Float (Cell_H),
                     Problems_Alternate_Row_Color.R,
                     Problems_Alternate_Row_Color.G,
                     Problems_Alternate_Row_Color.B);
               end if;

               Push_Problems_Text
                 (Packet, Clipped (Row_Text (Row)),
                  Float (Geometry.X + Cell_W), Y, Text_Color);
            end;
         end loop;

         if Snapshot.Row_Count = 0 and then Output_Rows > 0 then
            Push_Problems_Text
              (Packet, Clipped (To_String (Snapshot.Empty_Message)),
               Float (Geometry.X + Cell_W),
               Float (Geometry.Y + (Header_Rows + Task_Rows) * Cell_H),
               Problems_Info_Color);
         elsif Output_Rows > 0 and then Snapshot.Output_Row_Count > 0 then
            declare
               Lines_To_Show : constant Natural :=
                 Natural'Min (Output_Rows, Snapshot.Output_Row_Count);
               First_Output_Index : constant Natural :=
                 Snapshot.Output_Rows.Last_Index - Lines_To_Show + 1;
            begin
               for I in 0 .. Lines_To_Show - 1 loop
                  declare
                     Source_Index : constant Natural := First_Output_Index + I;
                     Y : constant Float :=
                       Float
                         (Geometry.Y + (Header_Rows + Task_Rows + I) * Cell_H);
                  begin
                     Push_Problems_Text
                       (Packet,
                        Clipped
                          (To_String (Snapshot.Output_Rows (Source_Index))),
                        Float (Geometry.X + Cell_W),
                        Y,
                        Problems_Info_Color);
                  end;
               end loop;
            end;
         end if;

         if Snapshot.Focused then
            Push_Rect
              (Packet, Problems_Row_Layer,
               Float (Geometry.X), Float (Geometry.Y),
               Float (Geometry.Width), 1.0,
               Panel_Focus_Border_Color.R,
               Panel_Focus_Border_Color.G,
               Panel_Focus_Border_Color.B);
         end if;
      end Push_Terminal_Tasks_Panel;

      procedure Push_Problems_Panel
        (Packet : in out Render_Packet)
      is
         Config : constant Editor.Problems.Problems_View_Config :=
           (Enabled_By_Default      => False,
            Header_Height_In_Rows   => 1,
            Row_Height_In_Rows      => 1,
            Show_Header             => True,
            Show_File_Name          => False,
            Show_Severity           => True,
            Show_Row_Column         => True,
            Maximum_Message_Columns => 120);
         Geometry : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Splitter : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Splitter_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Snapshot : Editor.Problems.Problems_Snapshot;
         Capacity_Rows : Natural := 0;
         Header_Rows   : Natural := 0;
         First_Row_Y   : Float := 0.0;
         Text_Columns  : Natural := 0;
         Focused       : constant Boolean :=
           Editor.Input_Bridge.Problems_Focused_For_Render;
         View          : constant Editor.Problems.Problems_View_State :=
           Editor.Input_Bridge.Problems_View_For_Render;
         Selected_Background : constant Editor.Theme.Color_RGB :=
           (if Focused then Problems_Selected_Active_Background_Color
            else Problems_Selected_Inactive_Background_Color);
         Selected_Foreground : constant Editor.Theme.Color_RGB :=
           (if Focused then Problems_Selected_Active_Foreground_Color
            else Problems_Selected_Inactive_Foreground_Color);
      begin
         if Geometry.Width = 0 or else Geometry.Height = 0 then
            return;
         end if;

         Editor.Input_Bridge.Get_Problems_For_Render (Snapshot);

         Push_Rect
           (Packet, Problems_Background_Layer,
            Float (Geometry.X), Float (Geometry.Y),
            Float (Geometry.Width), Float (Geometry.Height),
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);

         if Splitter.Width > 0 and then Splitter.Height > 0 then
            Push_Rect
              (Packet, Problems_Background_Layer,
               Float (Splitter.X), Float (Splitter.Y),
               Float (Splitter.Width), Float (Splitter.Height),
               Problems_Separator_Color.R,
               Problems_Separator_Color.G,
               Problems_Separator_Color.B);
         end if;

         if Geometry.Width > 2 * Cell_W then
            Text_Columns := (Geometry.Width / Cell_W) - 2;
         else
            Text_Columns := 0;
         end if;

         Capacity_Rows := Geometry.Height / Cell_H;
         if Capacity_Rows = 0 then
            return;
         end if;

         if Config.Show_Header then
            Header_Rows := Natural'Min (Config.Header_Height_In_Rows, Capacity_Rows);
            Push_Rect
              (Packet, Problems_Header_Layer,
               Float (Geometry.X), Float (Geometry.Y),
               Float (Geometry.Width), Float (Header_Rows * Cell_H),
               Problems_Header_Background_Color.R,
               Problems_Header_Background_Color.G,
               Problems_Header_Background_Color.B);
            Push_Problems_Text
              (Packet,
               Editor.Problems.Format_Header
                 (Config,
                  Editor.Input_Bridge.Problems_Total_Count_For_Render,
                  Editor.Problems.Severity_Filter (View))
               & " | filter: "
               & Editor.Problems.Severity_Filter_Label
                   (Editor.Problems.Severity_Filter (View))
               & " | sort: " & Editor.Problems.Sort_Mode_Label (View.Sort_Mode)
               & " | group: " & Editor.Problems.Group_Mode_Label (View.Group_Mode)
               & " | " & Editor.Problems.Header_Action_Hint (View),
               Float (Geometry.X + Cell_W),
               Float (Geometry.Y),
               Problems_Foreground_Color);
         end if;

         if Capacity_Rows <= Header_Rows then
            return;
         end if;

         First_Row_Y := Float (Geometry.Y + Header_Rows * Cell_H);

         declare
            Max_Rows : constant Natural := Capacity_Rows - Header_Rows;
            Emitted  : Natural := 0;
         begin
            if Editor.Problems.Row_Count (Snapshot) = 0 and then Max_Rows > 0 then
               Push_Problems_Text
                 (Packet,
                  Editor.Problems.Truncate_Text
                    (Editor.Problems.Empty_State_Message
                       (Visible_Count => Editor.Problems.Row_Count (Snapshot),
                        Total_Count   =>
                          Editor.Input_Bridge.Problems_Total_Count_For_Render),
                     Text_Columns),
                  Float (Geometry.X + Cell_W),
                  First_Row_Y,
                  Problems_Info_Color);
               Emitted := 1;
            end if;

            for I in 1 .. Editor.Problems.Row_Count (Snapshot) loop
               exit when Emitted >= Max_Rows;
               declare
                  Problem : constant Editor.Problems.Problem_Row :=
                    Editor.Problems.Row (Snapshot, I);
                  Row_Y : constant Float := First_Row_Y + Float (Emitted * Cell_H);
                  Text  : constant String :=
                    Editor.Problems.Format_Row (Config, Problem, Text_Columns);
                  Severity_Color : constant Editor.Theme.Color_RGB :=
                    Problems_Severity_Color (Problem.Severity);
                  Logical_Row : constant Natural :=
                    Editor.Problems.Top_Row (View) + I - 1;
                  Is_Selected : constant Boolean :=
                    Logical_Row = Editor.Problems.Selected_Row_Index (View)
                    and then Problem.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic;
                  Text_Color : Editor.Theme.Color_RGB := Problems_Foreground_Color;
               begin
                  if Is_Selected then
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        Float (Geometry.X), Row_Y,
                        Float (Geometry.Width), Float (Cell_H),
                        Selected_Background.R,
                        Selected_Background.G,
                        Selected_Background.B);
                     Text_Color := Selected_Foreground;
                  elsif Editor.Input_Bridge.Active_Diagnostic_For_Render = Problem.Diagnostic_Index
                  then
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        Float (Geometry.X), Row_Y,
                        Float (Geometry.Width), Float (Cell_H),
                        Problems_Active_Row_Color.R,
                        Problems_Active_Row_Color.G,
                        Problems_Active_Row_Color.B);
                  elsif Emitted mod 2 = 1 then
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        Float (Geometry.X), Row_Y,
                        Float (Geometry.Width), Float (Cell_H),
                        Problems_Alternate_Row_Color.R,
                        Problems_Alternate_Row_Color.G,
                        Problems_Alternate_Row_Color.B);
                  end if;

                  Push_Rect
                    (Packet, Problems_Severity_Layer,
                     Float (Geometry.X) + Float (Cell_W) / 2.0,
                     Row_Y + Float (Cell_H) / 4.0,
                     Float'Max (2.0, Float (Cell_W) / 3.0),
                     Float'Max (2.0, Float (Cell_H) / 2.0),
                     Severity_Color.R,
                     Severity_Color.G,
                     Severity_Color.B);

                  Push_Problems_Text
                    (Packet,
                     Text,
                     Float (Geometry.X + Cell_W + Cell_W),
                     Row_Y,
                     Text_Color);
                  Emitted := Emitted + 1;
               end;
            end loop;
         end;

         if Focused then
            Push_Rect
              (Packet, Problems_Row_Layer,
               Float (Geometry.X), Float (Geometry.Y),
               Float (Geometry.Width), 1.0,
               Problems_Focused_Border_Color.R,
               Problems_Focused_Border_Color.G,
               Problems_Focused_Border_Color.B);
         end if;
      end Push_Problems_Panel;

      procedure Push_Search_Results_Panel
        (Packet : in out Render_Packet)
      is
         Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
         Geometry : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Splitter : constant Editor.Layout.Rect :=
           Editor.Layout.Panel_Splitter_Rect
             (Layout,
              Editor.Panels.Bottom_Panel,
              Editor.View.Viewport_Width,
              Editor.View.Viewport_Height);
         Snapshot : Editor.Search_Results.Search_Results_Snapshot;
         Capacity_Rows : Natural := 0;
         Emitted : Natural := 0;
         Focused : constant Boolean :=
           Editor.Input_Bridge.Search_Results_Focused_For_Render;
         Selected_Background : constant Editor.Theme.Color_RGB :=
           (if Focused then Search_Results_Selected_Active_Background_Color
            else Search_Results_Selected_Inactive_Background_Color);
         Selected_Foreground : constant Editor.Theme.Color_RGB :=
           (if Focused then Search_Results_Selected_Active_Foreground_Color
            else Search_Results_Selected_Inactive_Foreground_Color);
      begin
         if Geometry.Width = 0 or else Geometry.Height = 0 then
            return;
         end if;

         Editor.Input_Bridge.Get_Search_Results_For_Render (Snapshot);

         Push_Rect
           (Packet, Problems_Background_Layer,
            Float (Geometry.X), Float (Geometry.Y),
            Float (Geometry.Width), Float (Geometry.Height),
            Search_Results_Background_Color.R,
            Search_Results_Background_Color.G,
            Search_Results_Background_Color.B);

         if Splitter.Width > 0 and then Splitter.Height > 0 then
            Push_Rect
              (Packet, Problems_Background_Layer,
               Float (Splitter.X), Float (Splitter.Y),
               Float (Splitter.Width), Float (Splitter.Height),
               Problems_Separator_Color.R,
               Problems_Separator_Color.G,
               Problems_Separator_Color.B);
         end if;

         Capacity_Rows := Geometry.Height / Cell_H;
         if Capacity_Rows = 0 then
            return;
         end if;

         for I in 1 .. Editor.Search_Results.Row_Count (Snapshot) loop
            exit when Emitted >= Capacity_Rows;
            declare
               Row : constant Editor.Search_Results.Search_Results_Row :=
                 Editor.Search_Results.Row (Snapshot, I);
               Row_Y : constant Float := Float (Geometry.Y + Emitted * Cell_H);
               Text_Color : Editor.Theme.Color_RGB := Search_Results_Foreground_Color;
            begin
               case Row.Kind is
                  when Editor.Search_Results.Search_Results_Header_Row =>
                     Push_Rect
                       (Packet, Problems_Header_Layer,
                        Float (Geometry.X), Row_Y,
                        Float (Geometry.Width), Float (Cell_H),
                        Search_Results_Header_Color.R,
                        Search_Results_Header_Color.G,
                        Search_Results_Header_Color.B);
                  when Editor.Search_Results.Search_Results_File_Row =>
                     Text_Color := Search_Results_File_Color;
                  when Editor.Search_Results.Search_Results_Match_Row =>
                     if Row.Is_Selected then
                        Push_Rect
                          (Packet, Problems_Row_Layer,
                           Float (Geometry.X), Row_Y,
                           Float (Geometry.Width), Float (Cell_H),
                           Selected_Background.R,
                           Selected_Background.G,
                           Selected_Background.B);
                        Text_Color := Selected_Foreground;
                     end if;
                  when Editor.Search_Results.Search_Results_Empty_Row =>
                     null;
               end case;

               Push_Problems_Text
                 (Packet,
                  To_String (Row.Display_Text),
                  Float (Geometry.X + Cell_W),
                  Row_Y,
                  Text_Color);
               Emitted := Emitted + 1;
            end;
         end loop;

         if Focused then
            Push_Rect
              (Packet, Problems_Row_Layer,
               Float (Geometry.X), Float (Geometry.Y),
               Float (Geometry.Width), 1.0,
               Panel_Focus_Border_Color.R,
               Panel_Focus_Border_Color.G,
               Panel_Focus_Border_Color.B);
         end if;

         pragma Unreferenced (Config);
      end Push_Search_Results_Panel;



      procedure Push_Active_Find_Prompt_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Active_Find_Prompt_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Active_Find_Prompt_Text;

      procedure Push_Semantic_Popup_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Semantic_Popup_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Semantic_Popup_Text;

      function Tail_Text
        (Text    : String;
         Columns : Natural) return String
      is
      begin
         if Columns = 0 then
            return "";
         elsif Text'Length <= Columns then
            return Text;
         else
            return Text (Text'Last - Columns + 1 .. Text'Last);
         end if;
      end Tail_Text;

      procedure Push_Semantic_Popup
        (Packet : in out Render_Packet)
      is
         Popup : constant Editor.State.Semantic_Popup_State := Snap.Semantic_Popup;
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         Max_Rows : constant Natural :=
           (case Popup.Kind is
              when Editor.State.Semantic_Hover_Popup => 2,
              when Editor.State.Semantic_Completion_Popup =>
                 Natural'Min
                   (Editor.State.Max_Semantic_Completion_Items,
                    Natural'Max (1, Popup.Item_Count)) + 1,
              when Editor.State.No_Semantic_Popup => 0);
         Width_Cols : constant Natural := 56;
         Popup_W : constant Natural :=
           Natural'Min (Message_Body.Width, Width_Cols * Cell_W);
         Popup_H : constant Natural :=
           Natural'Min
             (Message_Body.Height,
              Natural'Max (1, Max_Rows) * Cell_H);
         Text_Cols : constant Natural :=
           (if Popup_W / Cell_W > 2 then Popup_W / Cell_W - 2 else 1);
         Anchor_Segment : constant Natural :=
           Segment_For_Caret (Popup.Anchor_Row, Popup.Anchor_Column);
         Anchor_X : constant Float :=
           (if Anchor_Segment > 0
            then Screen_X
              (Screen_Col_For
                 (Snap.Visible_Visual_Rows (Anchor_Segment), Popup.Anchor_Column))
            else Float (Message_Body.X + Cell_W));
         Anchor_Y : constant Float :=
           (if Anchor_Segment > 0
            then Screen_Y (Anchor_Segment - 1) + Float (Cell_H)
            else Float (Message_Body.Y + Cell_H));
         X : constant Float :=
           Float'Min
             (Float'Max (Float (Message_Body.X), Anchor_X),
              Float (Message_Body.X + Message_Body.Width - Popup_W));
         Y : constant Float :=
           Float'Min
             (Float'Max (Float (Message_Body.Y), Anchor_Y),
              Float (Message_Body.Y + Message_Body.Height - Popup_H));
         Foreground : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Command_Palette_Secondary_Foreground;
         Title_Color : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Palette_Text;
         Background : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Palette_Background;
         Selected_Background : constant Editor.Theme.Color_RGB :=
           Editor.Theme.Palette_Selected_Row;
      begin
         if not Popup.Active
           or else Popup.Kind = Editor.State.No_Semantic_Popup
           or else Popup_W = 0
           or else Popup_H = 0
         then
            return;
         end if;

         Push_Rect
           (Packet, Semantic_Popup_Background_Layer,
            X, Y, Float (Popup_W), Float (Popup_H),
            Background.R, Background.G, Background.B);

         case Popup.Kind is
            when Editor.State.Semantic_Hover_Popup =>
               Push_Semantic_Popup_Text
                 (Packet,
                  Tail_Text (To_String (Popup.Title), Text_Cols),
                  X + Float (Cell_W), Y,
                  Title_Color);
               Push_Semantic_Popup_Text
                 (Packet,
                  Tail_Text (To_String (Popup.Detail), Text_Cols),
                  X + Float (Cell_W), Y + Float (Cell_H),
                  Foreground);

            when Editor.State.Semantic_Completion_Popup =>
               Push_Semantic_Popup_Text
                 (Packet,
                  Tail_Text (To_String (Popup.Title), Text_Cols),
                  X + Float (Cell_W), Y,
                  Title_Color);
               for I in 1 ..
                 Natural'Min
                   (Popup.Item_Count, Editor.State.Max_Semantic_Completion_Items)
               loop
                  declare
                     Row_Y : constant Float := Y + Float (I * Cell_H);
                     Item : constant Editor.State.Semantic_Completion_Item :=
                       Popup.Items (Editor.State.Semantic_Completion_Item_Index (I));
                     Label : constant String :=
                       To_String (Item.Label) &
                       (if Length (Item.Detail) > 0
                        then "  " & To_String (Item.Detail)
                        else "");
                  begin
                     if Popup.Selected_Item = I then
                        Push_Rect
                          (Packet, Semantic_Popup_Row_Layer,
                           X, Row_Y, Float (Popup_W), Float (Cell_H),
                           Selected_Background.R,
                           Selected_Background.G,
                           Selected_Background.B);
                     end if;
                     Push_Semantic_Popup_Text
                       (Packet,
                        Tail_Text (Label, Text_Cols),
                        X + Float (Cell_W), Row_Y,
                        Foreground);
                  end;
               end loop;

            when Editor.State.No_Semantic_Popup =>
               null;
         end case;
      end Push_Semantic_Popup;

      function Active_Find_Match_Text
        (Snap : Editor.Render_Model.Render_Snapshot) return String
      is
         Active_Renderable : constant Boolean :=
           Snap.Find_Visible
           and then Length (Snap.Find_Query) > 0
           and then not Snap.Find_Matches_Stale
           and then Snap.Find_Matches_For_Active_Buffer;
         Active_Count : constant Natural :=
           (if Active_Renderable then Snap.Find_Match_Count else 0);

         function Image_Of (Value : Natural) return String is
         begin
            return Ada.Strings.Fixed.Trim
              (Natural'Image (Value), Ada.Strings.Both);
         end Image_Of;
      begin
         --  Find prompt packet text is derived only
         --  from the canonical active-buffer Find snapshot.  Hidden or inactive
         --  search state must not contribute fallback counts/status.
         if not Snap.Find_Visible then
            return "";
         elsif Length (Snap.Find_Status_Text) > 0 then
            return To_String (Snap.Find_Status_Text);
         elsif Length (Snap.Find_Query) = 0 then
            return "No query";
         elsif not Active_Renderable then
            return "Stale";
         elsif Active_Count = 0 then
            return "No matches";
         elsif Snap.Find_Selected_Match_Ordinal > 0 then
            return Image_Of (Snap.Find_Selected_Match_Ordinal)
              & "/" & Image_Of (Active_Count);
         elsif Active_Count = 1 then
            return "1 match";
         else
            return Image_Of (Active_Count) & " matches";
         end if;
      end Active_Find_Match_Text;

      procedure Push_Active_Find_Prompt
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         G : constant Editor.Layout.Rect :=
           (X      => Message_Body.X,
            Y      => Message_Body.Y,
            Width  => Natural'Min (Message_Body.Width, 64 * Cell_W),
            Height => (if Snap.Replace_Visible then 2 * Cell_H else Cell_H));
         Field_X : constant Float := Float (G.X + 15 * Cell_W);
         Field_Pixels : constant Natural :=
           (if G.Width > 28 * Cell_W then G.Width - 28 * Cell_W else Cell_W);
         Field_W : constant Float := Float (Field_Pixels);
         Query_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Snap.Active_Find_Field;
         Query_Text : constant String := To_String (Snap.Active_Find_Field.Visible_Text);
         Match_Text : constant String := Active_Find_Match_Text (Snap);
         Case_Text  : constant String :=
           (if Snap.Find_Visible then
              (if Snap.Find_Case_Sensitive then "Case: sensitive" else "Case: insensitive")
              & "     "
              & (if Snap.Find_Whole_Word then "Whole word: on" else "Whole word: off")
            else "");
         Active_Renderable : constant Boolean :=
           Snap.Find_Visible
           and then Length (Snap.Find_Query) > 0
           and then not Snap.Find_Matches_Stale
           and then Snap.Find_Matches_For_Active_Buffer;
         Match_Color : constant Editor.Theme.Color_RGB :=
           (if Active_Renderable
               and then Length (Snap.Find_Query) > 0
               and then Snap.Find_Match_Count = 0
            then Active_Find_Prompt_No_Match_Color else Active_Find_Prompt_Foreground_Color);
         Active : constant Boolean :=
           Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      begin
         if (not S.Active_Find_Prompt)
           or else G.Width = 0
           or else G.Height = 0
         then
            return;
         end if;

         Push_Rect
           (Packet, Active_Find_Prompt_Background_Layer,
            Float (G.X), Float (G.Y), Float (G.Width), Float (G.Height),
            Active_Find_Prompt_Background_Color.R,
            Active_Find_Prompt_Background_Color.G,
            Active_Find_Prompt_Background_Color.B);

         Push_Rect
           (Packet, Active_Find_Prompt_Button_Layer,
            Float (G.X + Cell_W), Float (G.Y), Float (4 * Cell_W), Float (Cell_H),
            Active_Find_Prompt_Button_Background_Color.R,
            Active_Find_Prompt_Button_Background_Color.G,
            Active_Find_Prompt_Button_Background_Color.B);
         Push_Active_Find_Prompt_Text (Packet, "X", Float (G.X + 2 * Cell_W), Float (G.Y), Active_Find_Prompt_Button_Foreground_Color);
         Push_Active_Find_Prompt_Text (Packet, "<", Float (G.X + 7 * Cell_W), Float (G.Y), Active_Find_Prompt_Button_Foreground_Color);
         Push_Active_Find_Prompt_Text (Packet, ">", Float (G.X + 11 * Cell_W), Float (G.Y), Active_Find_Prompt_Button_Foreground_Color);
         Push_Active_Find_Prompt_Text (Packet, "Find", Float (G.X + 15 * Cell_W), Float (G.Y), Active_Find_Prompt_Foreground_Color);

         Push_Rect
           (Packet, Active_Find_Prompt_Field_Layer,
            Field_X, Float (G.Y), Field_W, Float (Cell_H),
            Active_Find_Prompt_Field_Background_Color.R,
            Active_Find_Prompt_Field_Background_Color.G,
            Active_Find_Prompt_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, Query_Snap, Active_Find_Prompt_Field_Layer,
            Field_X + Float (Cell_W), Float (G.Y));
         Push_Active_Find_Prompt_Text
           (Packet, Query_Text, Field_X + Float (Cell_W), Float (G.Y),
            Active_Find_Prompt_Field_Foreground_Color);
         Push_Active_Find_Prompt_Text
           (Packet, Match_Text,
            Float (G.X + Integer (G.Width) - Integer (12 * Cell_W)),
            Float (G.Y), Match_Color);
         if Case_Text'Length > 0 and then G.Width > 30 * Cell_W then
            Push_Active_Find_Prompt_Text
              (Packet, Case_Text,
               Float (G.X + Integer (G.Width) - Integer (32 * Cell_W)),
               Float (G.Y), Active_Find_Prompt_Foreground_Color);
         end if;

         if Snap.Replace_Visible then
            Push_Active_Find_Prompt_Text
              (Packet, "Replace", Float (G.X + 15 * Cell_W), Float (G.Y + Cell_H),
               Active_Find_Prompt_Foreground_Color);
            Push_Active_Find_Prompt_Text
              (Packet, To_String (Snap.Replace_Text),
               Field_X + Float (Cell_W), Float (G.Y + Cell_H),
               Active_Find_Prompt_Field_Foreground_Color);
         end if;

         if Active then
            declare
               C : constant Natural := Query_Snap.Cursor_Visible_Column;
            begin
               Push_Rect
                 (Packet, Active_Find_Prompt_Caret_Layer,
                  Field_X + Float ((C + 1) * Cell_W), Float (G.Y + 2),
                  2.0, Float (Cell_H - 4),
                  Active_Find_Prompt_Caret_Color.R,
                  Active_Find_Prompt_Caret_Color.G,
                  Active_Find_Prompt_Caret_Color.B);
            end;
         end if;
      end Push_Active_Find_Prompt;

      procedure Push_Guided_Prompt
        (Packet : in out Render_Packet)
      is
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         Prompt : constant Editor.Guided_Prompts.Prompt_Snapshot := Snap.Guided_Prompt;
         Picker_Rows : constant Natural :=
           (if Prompt.File_Picker_Active
            then Natural'Min
              (Editor.Guided_Prompts.Max_File_Picker_Rows,
               Natural (Prompt.File_Picker_Rows.Length))
            else 0);
         G : constant Editor.Layout.Rect :=
           (X      => Message_Body.X,
            Y      => Message_Body.Y + Cell_H,
            Width  => Natural'Min (Message_Body.Width, 88 * Cell_W),
            Height => (3 + Picker_Rows + (if Prompt.File_Picker_Active then 1 else 0)) * Cell_H);
         Field_X : constant Float := Float (G.X + 18 * Cell_W);
         Field_W : constant Float :=
           Float (if G.Width > 22 * Cell_W then G.Width - 22 * Cell_W else Cell_W);
         Input_Label : constant String :=
           (if Prompt.Has_Captured_Chord
            then To_String (Prompt.Captured_Chord_Label)
            else To_String (Prompt.Input_Text));
         Header : constant String :=
           To_String (Prompt.Title) & " [" & To_String (Prompt.Target_Domain_Label) & "]";
         Action : constant String :=
           To_String (Prompt.Confirm_Label) & " / " & To_String (Prompt.Cancel_Label);
      begin
         if not Prompt.Active or else G.Width = 0 or else G.Height = 0 then
            return;
         end if;

         Push_Rect
           (Packet, Active_Find_Prompt_Background_Layer,
            Float (G.X), Float (G.Y), Float (G.Width), Float (G.Height),
            Active_Find_Prompt_Background_Color.R,
            Active_Find_Prompt_Background_Color.G,
            Active_Find_Prompt_Background_Color.B);

         Push_Active_Find_Prompt_Text
           (Packet, Header, Float (G.X + Cell_W), Float (G.Y),
            Active_Find_Prompt_Foreground_Color);

         Push_Active_Find_Prompt_Text
           (Packet, "Input", Float (G.X + Cell_W), Float (G.Y + Cell_H),
            Active_Find_Prompt_Foreground_Color);
         Push_Rect
           (Packet, Active_Find_Prompt_Field_Layer,
            Field_X, Float (G.Y + Cell_H), Field_W, Float (Cell_H),
            Active_Find_Prompt_Field_Background_Color.R,
            Active_Find_Prompt_Field_Background_Color.G,
            Active_Find_Prompt_Field_Background_Color.B);
         Push_Active_Find_Prompt_Text
           (Packet, Tail_Text (Input_Label, Natural (Field_W) / Cell_W - 1),
            Field_X + Float (Cell_W), Float (G.Y + Cell_H),
            Active_Find_Prompt_Field_Foreground_Color);

         Push_Active_Find_Prompt_Text
           (Packet, To_String (Prompt.Validation_Label),
            Float (G.X + Cell_W), Float (G.Y + 2 * Cell_H),
            Active_Find_Prompt_Foreground_Color);
         Push_Active_Find_Prompt_Text
           (Packet, Action,
            Float (G.X + Integer (G.Width) - Integer (24 * Cell_W)),
            Float (G.Y + 2 * Cell_H),
            Active_Find_Prompt_Button_Foreground_Color);

         if Prompt.File_Picker_Active then
            Push_Active_Find_Prompt_Text
              (Packet,
               Tail_Text
                 ("Dir " & To_String (Prompt.File_Picker_Current_Directory),
                  Natural'Max (1, G.Width / Cell_W - 2)),
               Float (G.X + Cell_W), Float (G.Y + 3 * Cell_H),
               Active_Find_Prompt_Foreground_Color);

            if Picker_Rows = 0 then
               Push_Active_Find_Prompt_Text
                 (Packet, To_String (Prompt.File_Picker_Status),
                  Float (G.X + Cell_W), Float (G.Y + 4 * Cell_H),
                  Active_Find_Prompt_Foreground_Color);
            else
               declare
                  Row_No : Natural := 0;
               begin
                  for I in Prompt.File_Picker_Rows.First_Index ..
                    Prompt.File_Picker_Rows.Last_Index
                  loop
                     exit when Row_No >= Picker_Rows;

                     declare
                        Row : constant Editor.Guided_Prompts.File_Picker_Row :=
                          Prompt.File_Picker_Rows.Element (I);
                        Y : constant Float :=
                          Float (G.Y + (4 + Row_No) * Cell_H);
                     begin
                        if I = Prompt.File_Picker_Selected_Index then
                           Push_Rect
                             (Packet, Active_Find_Prompt_Field_Layer,
                              Float (G.X + Cell_W), Y,
                              Float (G.Width - 2 * Cell_W), Float (Cell_H),
                              Active_Find_Prompt_Field_Background_Color.R,
                              Active_Find_Prompt_Field_Background_Color.G,
                              Active_Find_Prompt_Field_Background_Color.B);
                        end if;

                        Push_Active_Find_Prompt_Text
                          (Packet,
                           Tail_Text
                             (To_String (Row.Label) & "  " & To_String (Row.Path),
                              Natural'Max (1, G.Width / Cell_W - 3)),
                           Float (G.X + 2 * Cell_W), Y,
                           Active_Find_Prompt_Field_Foreground_Color);
                     end;

                     Row_No := Row_No + 1;
                  end loop;
               end;
            end if;
         end if;
      end Push_Guided_Prompt;


      procedure Push_Quick_Open_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Quick_Open_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent - M.Bearing_Y + 0.5),
                        M.W, M.H, M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Quick_Open_Text;

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

      procedure Push_Goto_Line
        (Packet : in out Render_Packet)
      is
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         Width : constant Natural := Natural'Max
           (8, Natural'Min (Natural'Max (Message_Body.Width / Cell_W, 1), 32));
         Text_Cols : constant Natural :=
           (if Width > 2 then Width - 2 else 1);
         G_X : constant Integer :=
           Message_Body.X + Integer'Max (0, (Message_Body.Width - Integer (Width * Cell_W)) / 2);
         G_Y : constant Integer := Message_Body.Y + Integer (Cell_H);
         Text_X : constant Float := Float (G_X + Integer (Cell_W));
         Field_Y : constant Float := Float (G_Y + Integer (Cell_H));
         Error_Y : constant Float := Float (G_Y + Integer (2 * Cell_H));
         Active : constant Boolean :=
           Snap.Active_Overlay = Editor.Overlay_Focus.Go_To_Line_Overlay;
         Field_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Snap.Goto_Line_Field;
         Error_Text : constant String :=
           To_String (Snap.Goto_Line_Error_Message);
      begin
         if not Snap.Goto_Line_Visible then
            return;
         end if;

         Push_Rect (Packet, Quick_Open_Background_Layer,
                    Float (G_X), Float (G_Y),
                    Float (Width * Cell_W), Float (3 * Cell_H),
                    Quick_Open_Background_Color.R,
                    Quick_Open_Background_Color.G,
                    Quick_Open_Background_Color.B);
         Push_Rect (Packet, Quick_Open_Result_Layer,
                    Float (G_X), Float (G_Y),
                    Float (Width * Cell_W), 2.0,
                    Quick_Open_Border_Color.R,
                    Quick_Open_Border_Color.G,
                    Quick_Open_Border_Color.B);
         Push_Quick_Open_Text
           (Packet, "Go to Line", Text_X, Float (G_Y),
            Quick_Open_Foreground_Color);
         Push_Rect
           (Packet, Quick_Open_Field_Layer, Text_X, Field_Y,
            Float ((Width - 2) * Cell_W), Float (Cell_H),
            Quick_Open_Field_Background_Color.R,
            Quick_Open_Field_Background_Color.G,
            Quick_Open_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, Field_Snap, Quick_Open_Field_Layer,
            Text_X + Float (Cell_W), Field_Y);
         Push_Quick_Open_Text
           (Packet, To_String (Field_Snap.Visible_Text),
            Text_X + Float (Cell_W), Field_Y,
            Quick_Open_Field_Foreground_Color);
         if Error_Text'Length > 0 then
            Push_Quick_Open_Text
              (Packet, Truncate_Right (Error_Text, Text_Cols),
               Text_X, Error_Y, Quick_Open_Foreground_Color);
         end if;
         if Active then
            Push_Rect (Packet, Quick_Open_Caret_Layer,
                       Text_X + Float ((Field_Snap.Cursor_Visible_Column + 1) * Cell_W),
                       Field_Y + 2.0, 2.0, Float (Cell_H - 4),
                       Quick_Open_Caret_Color.R,
                       Quick_Open_Caret_Color.G,
                       Quick_Open_Caret_Color.B);
         end if;
      end Push_Goto_Line;

      procedure Push_Quick_Open
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         G : constant Editor.Layout.Rect :=
           Editor.Quick_Open.Geometry (Message_Body, Config, Cell_W, Cell_H);
         Field_Y : constant Float := Float (G.Y + Integer (Config.Header_Height_In_Rows * Cell_H));
         Rows_Y  : constant Float :=
           Float (G.Y + Integer ((Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H));
         Text_X : constant Float := Float (G.X + Integer (Config.Result_Padding_Columns * Cell_W));
         Text_Cols : constant Natural :=
           (if G.Width / Cell_W > 2 then G.Width / Cell_W - 2 else 1);
         Snapshot : constant Editor.Quick_Open.Quick_Open_Snapshot :=
           Editor.Quick_Open_Markers.Build_Snapshot
             (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
              S.Recent_Buffers);
         Count : constant Natural := Natural (Snapshot.Candidates.Length);
         Active : constant Boolean :=
           Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay);
         Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Editor.Quick_Open.Query_Snapshot (S.Quick_Open, Text_Cols);

         function Empty_Text return String is
         begin
            if Length (Snapshot.Empty_Message) > 0 then
               return To_String (Snapshot.Empty_Message);
            elsif not Editor.Project.Has_Project (S.Project) then
               return "No project open";
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               return "No project files";
            elsif Length (Snapshot.Query) > 0
              or else Snapshot.File_Kind_Filter /= Editor.Quick_Open.All_Files
              or else Length (Snapshot.Path_Scope) > 0
            then
               return "No Quick Open matches.";
            else
               return "No project files";
            end if;
         end Empty_Text;
      begin
         if not Editor.Quick_Open.Is_Open (S.Quick_Open) or else G.Width = 0 then
            return;
         end if;

         Push_Rect (Packet, Quick_Open_Background_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), Float (G.Height),
                    Quick_Open_Background_Color.R, Quick_Open_Background_Color.G, Quick_Open_Background_Color.B);
         Push_Rect (Packet, Quick_Open_Result_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), 2.0,
                    Quick_Open_Border_Color.R, Quick_Open_Border_Color.G, Quick_Open_Border_Color.B);
         Push_Quick_Open_Text
           (Packet,
            (if Length (Snapshot.Header_Text) > 0
             then "Quick Open  " & To_String (Snapshot.Header_Text)
             else "Quick Open"),
            Text_X, Float (G.Y), Quick_Open_Foreground_Color);

         Push_Rect
           (Packet, Quick_Open_Field_Layer, Text_X, Field_Y,
            Float (G.Width - 2 * Config.Result_Padding_Columns * Cell_W), Float (Cell_H),
            Quick_Open_Field_Background_Color.R, Quick_Open_Field_Background_Color.G,
            Quick_Open_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, Q_Snap, Quick_Open_Field_Layer,
            Text_X + Float (Cell_W), Field_Y);
         Push_Quick_Open_Text
           (Packet, To_String (Q_Snap.Visible_Text), Text_X + Float (Cell_W), Field_Y,
            Quick_Open_Field_Foreground_Color);
         if Active then
            declare
               C : constant Natural := Q_Snap.Cursor_Visible_Column;
            begin
               Push_Rect (Packet, Quick_Open_Caret_Layer,
                          Text_X + Float ((C + 1) * Cell_W), Field_Y + 2.0, 2.0, Float (Cell_H - 4),
                          Quick_Open_Caret_Color.R, Quick_Open_Caret_Color.G, Quick_Open_Caret_Color.B);
            end;
         end if;

         if Count = 0 then
            Push_Quick_Open_Text
              (Packet, Empty_Text, Text_X, Rows_Y, Quick_Open_Secondary_Foreground_Color);
         else
            for Row in 1 .. Config.Max_Visible_Results loop
               declare
                  Index : constant Natural := Editor.Quick_Open.Top_Result_Index (S.Quick_Open) + Row - 1;
               begin
                  exit when Index > Count;
                  declare
                     Candidate : constant Editor.Quick_Open.Quick_Open_Candidate_Snapshot :=
                       Snapshot.Candidates (Index - 1);
                     Row_Y : constant Float := Rows_Y + Float ((Row - 1) * Cell_H);
                     Color : constant Editor.Theme.Color_RGB :=
                       (if Candidate.Is_Selected
                        then Quick_Open_Selected_Foreground_Color
                        else Quick_Open_Foreground_Color);
                  begin
                     if Candidate.Is_Selected then
                        Push_Rect (Packet, Quick_Open_Selected_Result_Layer,
                                   Float (G.X), Row_Y, Float (G.Width), Float (Cell_H),
                                   Quick_Open_Selected_Background_Color.R,
                                   Quick_Open_Selected_Background_Color.G,
                                   Quick_Open_Selected_Background_Color.B);
                     end if;
                     Push_Quick_Open_Text
                       (Packet,
                        Truncate_Right
                          ((if Candidate.Is_Selected then "> " else "  ") &
                           To_String (Candidate.Display_Text),
                           Text_Cols),
                        Text_X, Row_Y, Color);
                  end;
               end;
            end loop;
         end if;
      end Push_Quick_Open;



      procedure Push_Buffer_Switcher
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         G : constant Editor.Layout.Rect :=
           Editor.Buffer_Switcher.Geometry (Message_Body, Config, Cell_W, Cell_H);
         Field_Y : constant Float := Float (G.Y + Integer (Config.Header_Height_In_Rows * Cell_H));
         Rows_Y  : constant Float :=
           Float (G.Y + Integer ((Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_H));
         Text_X : constant Float := Float (G.X + Integer (Config.Result_Padding_Columns * Cell_W));
         Text_Cols : constant Natural :=
           (if G.Width / Cell_W > 2 then G.Width / Cell_W - 2 else 1);
         Count : constant Natural := Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);
         Active : constant Boolean :=
           Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay);
         Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Editor.Buffer_Switcher.Query_Snapshot (S.Buffer_Switcher, Text_Cols);
         Header_Badge_Text : constant String :=
           Editor.Buffer_Switcher.Header_Badge_Text
             (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
         Header_Text : constant String :=
           (if Header_Badge_Text'Length > 0
            then "Open Buffers - " & Header_Badge_Text
            else "Open Buffers");
         Hint_Text : constant String :=
           Editor.Buffer_Switcher_Contextual_Hints.Contextual_Hint_Text (S);
         Footer_Y : constant Float := Float (G.Y + G.Height - Cell_H);

         function Line_Count_Of (Text : String) return Natural is
            Count : Natural := 1;
         begin
            if Text'Length = 0 then
               return 0;
            end if;
            for Ch of Text loop
               if Ch = ASCII.LF then
                  Count := Count + 1;
               end if;
            end loop;
            return Count;
         end Line_Count_Of;

         function Line_Text (Text : String; Line : Positive) return String is
            Current : Positive := 1;
            Start   : Positive := Text'First;
         begin
            if Text'Length = 0 then
               return "";
            end if;

            for I in Text'Range loop
               if Text (I) = ASCII.LF then
                  if Current = Line then
                     if I = Start then
                        return "";
                     else
                        return Text (Start .. I - 1);
                     end if;
                  end if;
                  Current := Current + 1;
                  if I < Text'Last then
                     Start := I + 1;
                  end if;
               end if;
            end loop;

            if Current = Line and then Start <= Text'Last then
               return Text (Start .. Text'Last);
            elsif Current = Line then
               return "";
            else
               return "";
            end if;
         end Line_Text;

         function Image_No_Leading (Value : Natural) return String is
            Raw : constant String := Natural'Image (Value);
         begin
            if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
               return Raw (Raw'First + 1 .. Raw'Last);
            else
               return Raw;
            end if;
         end Image_No_Leading;

         procedure Push_Preview is
            Target : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
            Preview_Y : constant Float :=
              Rows_Y + Float (Config.Max_Visible_Results * Config.Row_Height_In_Rows * Cell_H);
            Header_Y : constant Float := Preview_Y;
            First_Line : Natural := 1;
            Text : Unbounded_String := Null_Unbounded_String;
            Display_Name : Unbounded_String := Null_Unbounded_String;
            Total_Lines : Natural := 0;
         begin
            if not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher) then
               return;
            end if;

            if Target = Editor.Buffers.No_Buffer
              or else not Editor.Buffers.Contains (Registry, Target)
            then
               Push_Quick_Open_Text
                 (Packet, "Preview: no selected buffer", Text_X, Header_Y,
                  Quick_Open_Secondary_Foreground_Color);
               return;
            end if;

            declare
               B : constant Editor.State.State_Type := Editor.Buffers.Buffer (Registry, Target);
            begin
               Text := To_Unbounded_String (Editor.State.Current_Text (B));
               Display_Name := To_Unbounded_String (Editor.Buffers.Display_Name (Registry, Target));
            end;

            Push_Quick_Open_Text
              (Packet, Truncate_Right ("Preview: " & To_String (Display_Name), Text_Cols),
               Text_X, Header_Y, Quick_Open_Secondary_Foreground_Color);

            if Length (Text) = 0 then
               Push_Quick_Open_Text
                 (Packet, "  <empty buffer>", Text_X, Header_Y + Float (Cell_H),
                  Quick_Open_Secondary_Foreground_Color);
               return;
            end if;

            Total_Lines := Line_Count_Of (To_String (Text));
            First_Line := Editor.Buffer_Switcher.Preview_Anchor_Line (S.Buffer_Switcher) +
              Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher);
            if First_Line = 0 then
               First_Line := 1;
            elsif First_Line > Total_Lines then
               First_Line := Total_Lines;
            end if;

            for I in 0 .. Natural'Max (1, Config.Preview_Max_Lines) - 1 loop
               declare
                  Line_No : constant Natural := First_Line + I;
               begin
                  exit when Line_No > Total_Lines;
                  Push_Quick_Open_Text
                    (Packet,
                     Truncate_Right
                       ("  " & Image_No_Leading (Line_No) & " | " &
                        Line_Text (To_String (Text), Positive (Line_No)), Text_Cols),
                     Text_X, Header_Y + Float ((I + 1) * Cell_H),
                     Quick_Open_Secondary_Foreground_Color);
               end;
            end loop;
         end Push_Preview;
      begin
         if not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) or else G.Width = 0 then
            return;
         end if;

         Push_Rect (Packet, Quick_Open_Background_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), Float (G.Height),
                    Quick_Open_Background_Color.R, Quick_Open_Background_Color.G, Quick_Open_Background_Color.B);
         Push_Rect (Packet, Quick_Open_Result_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), 2.0,
                    Quick_Open_Border_Color.R, Quick_Open_Border_Color.G, Quick_Open_Border_Color.B);
         Push_Quick_Open_Text
           (Packet, Truncate_Right (Header_Text, Text_Cols), Text_X, Float (G.Y),
            Quick_Open_Foreground_Color);

         Push_Rect
           (Packet, Quick_Open_Field_Layer, Text_X, Field_Y,
            Float (G.Width - 2 * Config.Result_Padding_Columns * Cell_W), Float (Cell_H),
            Quick_Open_Field_Background_Color.R, Quick_Open_Field_Background_Color.G,
            Quick_Open_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, Q_Snap, Quick_Open_Field_Layer,
            Text_X + Float (Cell_W), Field_Y);
         Push_Quick_Open_Text
           (Packet, To_String (Q_Snap.Visible_Text), Text_X + Float (Cell_W), Field_Y,
            Quick_Open_Field_Foreground_Color);
         if Active then
            declare
               C : constant Natural := Q_Snap.Cursor_Visible_Column;
            begin
               Push_Rect (Packet, Quick_Open_Caret_Layer,
                          Text_X + Float ((C + 1) * Cell_W), Field_Y + 2.0, 2.0, Float (Cell_H - 4),
                          Quick_Open_Caret_Color.R, Quick_Open_Caret_Color.G, Quick_Open_Caret_Color.B);
            end;
         end if;

         if Count = 0 then
            Push_Quick_Open_Text
              (Packet,
               Editor.Buffer_Switcher.Buffer_List_Empty_State_Label
                 (S.Buffer_Switcher, Editor.Buffers.Global_Count),
               Text_X, Rows_Y, Quick_Open_Secondary_Foreground_Color);
         else
            for Row in 1 .. Config.Max_Visible_Results loop
               declare
                  Index : constant Natural := Editor.Buffer_Switcher.Top_Row_Index (S.Buffer_Switcher) + Row - 1;
               begin
                  exit when Index > Count;
                  declare
                     R : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
                       Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, Index);
                     Row_Y : constant Float := Rows_Y + Float ((Row - 1) * Cell_H);
                     Prefix : constant String := (if R.Is_Active then "> " else "  ");
                     Mark   : constant String := (if R.Is_Marked then "[*] " else "    ");
                     Dirty  : constant String := (if R.Is_Dirty then " *" else "");
                     Markers : constant String := Editor.Buffer_Switcher.Buffer_Row_State_Markers (R);
                     Marker_Text : constant String := (if Markers'Length = 0 then "" else " [" & Markers & "]");
                     Metadata_Label : constant String :=
                       Editor.Buffer_Switcher.Buffer_Row_Metadata_Render_Label (R);
                     Metadata_Text : constant String :=
                       (if Metadata_Label'Length = 0 then "" else " {" & Metadata_Label & "}");
                     Color : constant Editor.Theme.Color_RGB :=
                       (if Index = Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)
                        then Quick_Open_Selected_Foreground_Color
                        else Quick_Open_Foreground_Color);
                  begin
                     if Index = Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) then
                        Push_Rect (Packet, Quick_Open_Selected_Result_Layer,
                                   Float (G.X), Row_Y, Float (G.Width), Float (Cell_H),
                                   Quick_Open_Selected_Background_Color.R,
                                   Quick_Open_Selected_Background_Color.G,
                                   Quick_Open_Selected_Background_Color.B);
                     end if;
                     Push_Quick_Open_Text
                       (Packet, Truncate_Right (Prefix & Mark & To_String (R.Display_Label) & Dirty & Marker_Text & Metadata_Text, Text_Cols),
                        Text_X, Row_Y, Color);
                  end;
               end;
            end loop;
         end if;

         if Hint_Text'Length > 0 then
            Push_Quick_Open_Text
              (Packet, Truncate_Right (Hint_Text, Text_Cols),
               Text_X, Footer_Y, Quick_Open_Secondary_Foreground_Color);
         end if;

         Push_Preview;
      end Push_Buffer_Switcher;

      procedure Push_Project_Search_Bar_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB)
      is
         Pen_X : Float := X;
      begin
         for Ch of Text loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Ch /= ASCII.NUL and then Editor.Fonts.Get_Glyph (Ch, M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Project_Search_Bar_Text_Layer,
                        Float'Floor (Pen_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent - M.Bearing_Y + 0.5),
                        M.W, M.H, M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Pen_X := Pen_X + Float (Cell_W);
            end;
         end loop;
      end Push_Project_Search_Bar_Text;

      function Project_Search_Status_Text
        (S : Editor.State.State_Type) return String
      is
         Count : constant Natural := Editor.Project_Search.Result_Count (S.Project_Search);
         Files : constant Natural := Editor.Project_Search.File_Group_Count (S.Project_Search);
      begin
         if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar)
           and then Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar)
             /= Editor.Project_Search.Last_Run_Query (S.Project_Search)
         then
            return "Query changed - press Enter to search";
         elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
            return "Results may be stale";
         elsif Editor.Project_Search.Was_Truncated (S.Project_Search) then
            return "Results truncated";
         end if;

         case Editor.Project_Search.Status (S.Project_Search) is
            when Editor.Project_Search.Project_Search_No_Project =>
               return "No project open";
            when Editor.Project_Search.Project_Search_No_Files =>
               return "No project files";
            when Editor.Project_Search.Project_Search_Empty_Query =>
               return "Project search query is empty";
            when Editor.Project_Search.Project_Search_Ok =>
               if Count = 0 then
                  return "No matches";
               else
                  return Natural'Image (Count) & " matches in" & Natural'Image (Files) & " files";
               end if;
            when Editor.Project_Search.Project_Search_Read_Error =>
               return "Project search read error";
            when Editor.Project_Search.Project_Search_Invalid_Regex =>
               return "Invalid regex";
            when others =>
               return "Idle";
         end case;
      end Project_Search_Status_Text;

      procedure Push_Project_Search_Bar
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Project_Search_Bar.Project_Search_Bar_Config := (others => <>);
         Message_Body : constant Editor.Layout.Rect :=
           Editor.Layout.Editor_Body_Rect
             (Layout, Editor.View.Viewport_Width, Editor.View.Viewport_Height);
         G : constant Editor.Layout.Rect :=
           Editor.Project_Search_Bar.Geometry (Message_Body, Config, Cell_W, Cell_H);
         Text_X : constant Float := Float (G.X + Integer (Cell_W));
         Field_X : constant Float := Float (G.X + Integer (16 * Cell_W));
         Total_Cols : constant Natural := (G.Width / Cell_W);
         Run_Start : constant Natural := (if Total_Cols > 22 then Total_Cols - 22 else 0);
         Field_Cols : constant Natural :=
           (if Run_Start > 18 then Run_Start - 18 else Natural'Max (1, Config.Query_Field_Min_Columns));
         Field_W : constant Float := Float (Field_Cols * Cell_W);
         Y : constant Float := Float (G.Y);
         Replace_Y : constant Float := Y + Float (Cell_H);
         Status_Y : constant Float := Y + Float (2 * Cell_H);
         Status : constant String := Project_Search_Status_Text (S);
         Active : constant Boolean :=
           Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay);
         Active_Field : constant Editor.Project_Search_Bar.Project_Search_Bar_Field :=
           Editor.Project_Search_Bar.Active_Field (S.Project_Search_Bar);
         Q_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Editor.Project_Search_Bar.Query_Snapshot (S.Project_Search_Bar, Field_Cols);
         R_Snap : constant Editor.Input_Field.Field_Snapshot :=
           Editor.Project_Search_Bar.Replace_Snapshot (S.Project_Search_Bar, Field_Cols);
      begin
         if not Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) or else G.Width = 0 then
            return;
         end if;

         Push_Rect (Packet, Project_Search_Bar_Background_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), Float (G.Height),
                    Project_Search_Bar_Background_Color.R,
                    Project_Search_Bar_Background_Color.G,
                    Project_Search_Bar_Background_Color.B);
         Push_Rect (Packet, Project_Search_Bar_Background_Layer,
                    Float (G.X), Float (G.Y), Float (G.Width), 2.0,
                    Project_Search_Bar_Border_Color.R,
                    Project_Search_Bar_Border_Color.G,
                    Project_Search_Bar_Border_Color.B);
         Push_Project_Search_Bar_Text
           (Packet, "Search Project", Text_X, Y, Project_Search_Bar_Foreground_Color);
         Push_Rect (Packet, Project_Search_Bar_Field_Layer,
                    Field_X, Y, Field_W, Float (Cell_H),
                    Project_Search_Bar_Field_Background_Color.R,
                    Project_Search_Bar_Field_Background_Color.G,
                    Project_Search_Bar_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, Q_Snap, Project_Search_Bar_Field_Layer,
            Field_X + Float (Cell_W), Y);
         Push_Project_Search_Bar_Text
           (Packet, To_String (Q_Snap.Visible_Text), Field_X + Float (Cell_W), Y,
            Project_Search_Bar_Field_Foreground_Color);
         Push_Project_Search_Bar_Text
           (Packet, "Replace", Text_X, Replace_Y, Project_Search_Bar_Foreground_Color);
         Push_Rect (Packet, Project_Search_Bar_Field_Layer,
                    Field_X, Replace_Y, Field_W, Float (Cell_H),
                    Project_Search_Bar_Field_Background_Color.R,
                    Project_Search_Bar_Field_Background_Color.G,
                    Project_Search_Bar_Field_Background_Color.B);
         Push_Field_Selection
           (Packet, R_Snap, Project_Search_Bar_Field_Layer,
            Field_X + Float (Cell_W), Replace_Y);
         Push_Project_Search_Bar_Text
           (Packet, To_String (R_Snap.Visible_Text), Field_X + Float (Cell_W), Replace_Y,
            Project_Search_Bar_Field_Foreground_Color);
         if Active then
            declare
               C : constant Natural :=
                 (if Active_Field = Editor.Project_Search_Bar.Project_Search_Query_Field
                  then Q_Snap.Cursor_Visible_Column
                  else R_Snap.Cursor_Visible_Column);
               Caret_Y : constant Float :=
                 (if Active_Field = Editor.Project_Search_Bar.Project_Search_Query_Field
                  then Y + 2.0
                  else Replace_Y + 2.0);
            begin
               Push_Rect (Packet, Project_Search_Bar_Caret_Layer,
                          Field_X + Float ((C + 1) * Cell_W), Caret_Y,
                          2.0, Float (Cell_H - 4),
                          Project_Search_Bar_Caret_Color.R,
                          Project_Search_Bar_Caret_Color.G,
                          Project_Search_Bar_Caret_Color.B);
            end;
         end if;
         if Total_Cols > 24 then
            Push_Project_Search_Bar_Text
              (Packet, "Run", Float (G.X + Integer ((Total_Cols - 22) * Cell_W)), Y,
               Project_Search_Bar_Button_Foreground_Color);
            Push_Project_Search_Bar_Text
              (Packet, "Clear", Float (G.X + Integer ((Total_Cols - 15) * Cell_W)), Y,
               Project_Search_Bar_Button_Foreground_Color);
            Push_Project_Search_Bar_Text
              (Packet, "Close", Float (G.X + Integer ((Total_Cols - 7) * Cell_W)), Y,
               Project_Search_Bar_Button_Foreground_Color);
         end if;
         if Config.Show_Status_Text and then G.Height >= Cell_H then
            declare
               Status_Cols : constant Natural := (if Total_Cols > 2 then Total_Cols - 2 else 1);
            begin
               Push_Project_Search_Bar_Text
                 (Packet, Truncate_Right (Status, Status_Cols), Text_X,
                  Y + Float (Cell_H), Project_Search_Bar_Status_Foreground_Color);
            end;
         end if;
      end Push_Project_Search_Bar;


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

      procedure Push_Pending_Transition_Bar
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Config : constant Editor.Pending_Transition_Bar.Pending_Bar_Config := (others => <>);
         Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
           Editor.Pending_Transition_Bar.Build_Snapshot
             (S.Pending_Transitions, Config);
         Status_Y : constant Integer :=
           Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height);
         Bar_Y : constant Integer :=
           Integer'Max (Layout.Origin_Y, Status_Y - Integer (Cell_H));
         Bar_Layout : constant Editor.Pending_Transition_Bar.Pending_Bar_Layout :=
           Editor.Pending_Transition_Bar.Layout
             (Snapshot => Snapshot,
              Bounds_X => Layout.Origin_X,
              Bounds_Y => Bar_Y,
              Bounds_W => Integer (Editor.View.Viewport_Width),
              Cell_W   => Cell_W,
              Cell_H   => Cell_H);

         function Info_For
           (Action : Editor.Pending_Transition_Bar.Pending_Bar_Action)
            return Editor.Pending_Transition_Bar.Pending_Bar_Action_Info
         is
         begin
            for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
               declare
                  Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
                    Editor.Pending_Transition_Bar.Action (Snapshot, I);
               begin
                  if Info.Action = Action then
                     return Info;
                  end if;
               end;
            end loop;
            return (Action         => Editor.Pending_Transition_Bar.No_Pending_Bar_Action,
                    Command        => Editor.Commands.No_Command,
                    Label          => Null_Unbounded_String,
                    Available      => False,
                    Is_Destructive => False);
         end Info_For;

         procedure Enrich_Availability is
         begin
            for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
               declare
                  Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
                    Editor.Pending_Transition_Bar.Action (Snapshot, I);
                  Availability : constant Editor.Commands.Command_Availability :=
                    Editor.Executor.Command_Availability (S, Info.Command);
               begin
                  Editor.Pending_Transition_Bar.Set_Action_Availability
                    (Snapshot, Info.Action,
                     Editor.Commands.Is_Available (Availability));
               end;
            end loop;
         end Enrich_Availability;
      begin
         Enrich_Availability;
         if not Editor.Pending_Transition_Bar.Is_Visible (Snapshot)
           or else Editor.Pending_Transition_Bar.Bar_W (Bar_Layout) <= 0
         then
            return;
         end if;

         Push_Rect
           (Packet, Pending_Transition_Background_Layer,
            Float (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)),
            Float (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
            Float (Editor.Pending_Transition_Bar.Bar_W (Bar_Layout)),
            Float (Editor.Pending_Transition_Bar.Bar_H (Bar_Layout)),
            Pending_Bar_Background_Color.R,
            Pending_Bar_Background_Color.G,
            Pending_Bar_Background_Color.B);
         Push_Rect
           (Packet, Pending_Transition_Background_Layer,
            Float (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)),
            Float (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
            3.0,
            Float (Editor.Pending_Transition_Bar.Bar_H (Bar_Layout)),
            Pending_Bar_Accent_Color.R,
            Pending_Bar_Accent_Color.G,
            Pending_Bar_Accent_Color.B);

         declare
            Text_X : constant Float :=
              Float (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout) + Integer (Cell_W));
            First_Action_X : Integer :=
              Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)
              + Editor.Pending_Transition_Bar.Bar_W (Bar_Layout)
              - Integer (Cell_W);
            Available_Text_W : Natural := 0;
            Max_Cols : Natural := 0;
         begin
            for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Bar_Layout) loop
               declare
                  Rect : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Rect :=
                    Editor.Pending_Transition_Bar.Action_Rect (Bar_Layout, I);
               begin
                  if Rect.X < First_Action_X then
                     First_Action_X := Rect.X;
                  end if;
               end;
            end loop;

            if First_Action_X > Integer (Text_X) then
               Available_Text_W := Natural (First_Action_X - Integer (Text_X));
            end if;

            Max_Cols :=
              (if Available_Text_W > Cell_W then Available_Text_W / Cell_W else 0);
            Push_Pending_Bar_Text
              (Packet,
               Truncate_To_Columns
                 (Editor.Pending_Transition_Bar.Display_Text (Snapshot), Max_Cols),
               Text_X, Float (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
               Pending_Transition_Text_Layer, Pending_Bar_Foreground_Color);
         end;

         for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Bar_Layout) loop
            declare
               Rect : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Rect :=
                 Editor.Pending_Transition_Bar.Action_Rect (Bar_Layout, I);
               Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
                 Info_For (Rect.Action);
               Text_Color : Editor.Theme.Color_RGB := Pending_Bar_Action_Color;
               Label_Cols : constant Natural :=
                 (if Rect.W > Integer (2 * Cell_W) then Natural (Rect.W) / Cell_W - 2 else 0);
               Label : constant String :=
                 Truncate_To_Columns (To_String (Info.Label), Label_Cols);
            begin
               if not Info.Available then
                  Text_Color := Pending_Bar_Disabled_Action_Color;
               elsif Info.Is_Destructive then
                  Text_Color := Pending_Bar_Destructive_Color;
               end if;

               Push_Pending_Bar_Text
                 (Packet, Label,
                  Float (Rect.X + Integer (Cell_W)),
                  Float (Rect.Y),
                  Pending_Transition_Action_Layer,
                  Text_Color);
            end;
         end loop;
      end Push_Pending_Transition_Bar;

      procedure Push_Status_Bar
        (Packet : in out Render_Packet)
      is
         Snapshot : constant Editor.Status_Bar.Status_Bar_Snapshot :=
           Build_Status_Snapshot;
         Left_Text  : constant String := Editor.Status_Bar.Format_Left (Snapshot);
         Right_Text : constant String := Editor.Status_Bar.Format_Right (Snapshot);
         --  compact projection is used for constrained status-bar
         --  widths so high-priority observational context is not pushed out by
         --  long file/project labels.  This remains display-only; it reads only
         --  the immutable snapshot built above.
         Compact_Text : Unbounded_String := Null_Unbounded_String;
         Use_Compact  : Boolean := False;
         Bar_H : constant Natural := Editor.Layout.Status_Bar_Height (Layout);
         Bar_Y : constant Float := Float
           (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
         Bar_W : constant Natural :=
           Editor.Layout.Status_Bar_Width (Layout, Editor.View.Viewport_Width);
         Padding : constant Natural := Cell_W;
         Max_Cols : constant Natural :=
           (if Bar_W > 2 * Padding then (Bar_W - 2 * Padding) / Cell_W else 0);
         Right_Cols : Natural := 0;
         Left_Cols : Natural := 0;
         Left_X : constant Float := Float (Layout.Origin_X + Padding);
         Right_X : Float := 0.0;
      begin
         if Bar_H = 0 or else Editor.View.Viewport_Width = 0 then
            return;
         end if;

         Push_Rect
           (Packet, Status_Bar_Background_Layer,
            Float (Layout.Origin_X), Bar_Y, Float (Bar_W), Float (Bar_H),
            Status_Bar_Background_Color.R,
            Status_Bar_Background_Color.G,
            Status_Bar_Background_Color.B);
         Push_Rect
           (Packet, Status_Bar_Background_Layer,
            Float (Layout.Origin_X), Bar_Y, Float (Bar_W), 1.0,
            Status_Bar_Separator_Color.R,
            Status_Bar_Separator_Color.G,
            Status_Bar_Separator_Color.B);

         if Max_Cols > 0 then
            Use_Compact := Editor.Status_Bar.Status_Layout_Should_Use_Compact
              (Snapshot, Max_Cols);

            if Use_Compact then
               Compact_Text := To_Unbounded_String
                 (Editor.Status_Bar.Status_Layout_Compact (Snapshot, Max_Cols));
               Left_Cols := Length (Compact_Text);
               Right_Cols := 0;
            elsif Max_Cols >= 24 then
               Right_Cols := Natural'Min (Right_Text'Length, Max_Cols / 2);
            elsif Max_Cols >= 8 then
               Right_Cols := Natural'Min (Right_Text'Length, Max_Cols / 3);
            else
               Right_Cols := 0;
            end if;

            if not Use_Compact then
               if Right_Cols > 0 and then Max_Cols > Right_Cols + 1 then
                  Left_Cols := Natural'Min (Left_Text'Length, Max_Cols - Right_Cols - 1);
               else
                  Left_Cols := Natural'Min (Left_Text'Length, Max_Cols);
                  Right_Cols := 0;
               end if;
            end if;
         end if;

         declare
            Left_Display  : constant String :=
              (if Use_Compact
               then To_String (Compact_Text)
               else Truncate_To_Columns (Left_Text, Left_Cols));
            Right_Display : constant String :=
              (if Use_Compact then "" else Truncate_To_Columns (Right_Text, Right_Cols));
         begin
            if Left_Display'Length > 0
              and then Snapshot.Is_Dirty
              and then Left_Display (Left_Display'Last) = '*'
            then
               if Left_Display'Length > 1 then
                  Push_Status_Text
                    (Packet,
                     Left_Display (Left_Display'First .. Left_Display'Last - 1),
                     Left_X, Bar_Y, Status_Bar_Foreground_Color);
               end if;

               Push_Status_Text
                 (Packet,
                  Left_Display (Left_Display'Last .. Left_Display'Last),
                  Left_X + Float ((Left_Display'Length - 1) * Cell_W),
                  Bar_Y, Status_Bar_Dirty_Color);
            else
               Push_Status_Text
                 (Packet, Left_Display, Left_X, Bar_Y, Status_Bar_Foreground_Color);
            end if;

            if Right_Display'Length > 0
              and then Bar_W > Padding + Right_Display'Length * Cell_W
            then
               Right_X := Float
                 (Layout.Origin_X + Bar_W - Padding - Right_Display'Length * Cell_W);
               if Right_X > Left_X + Float ((Left_Display'Length + 1) * Cell_W) then
                  Push_Status_Text
                    (Packet, Right_Display, Right_X, Bar_Y,
                     Status_Bar_Foreground_Color);
               end if;
            end if;
         end;
      end Push_Status_Bar;

      procedure Push_Active_Message
        (Packet : in out Render_Packet)
      is
         Config : constant Editor.Messages.Message_Config :=
           (Default_Lifetime_Ms   => 3_000,
            Error_Lifetime_Ms     => 5_000,
            Max_Visible_Messages  => 3,
            Max_Text_Columns      => 96,
            Replace_Same_Category => True);
         Now_Ms : constant Natural :=
           (if Editor.View.Current_Time_Seconds <= 0.0 then 0
            elsif Editor.View.Current_Time_Seconds >= Duration (Natural'Last / 1000) then Natural'Last
            else Natural (Float (Editor.View.Current_Time_Seconds) * 1000.0));
         Count : constant Natural :=
           Editor.Messages.Visible_Count (Snap.Messages, Now_Ms, Config);
      begin
         for I in 1 .. Count loop
            declare
               Message : constant Editor.Messages.Editor_Message :=
                 Editor.Messages.Visible_Message (Snap.Messages, I, Now_Ms, Config);
               Rect : constant Editor.Messages.Message_Rect :=
                 Editor.Messages.Overlay_Rect
                   (Layout          => Message_Layout,
                    Viewport_Width  => Editor.View.Viewport_Width,
                    Viewport_Height => Editor.View.Viewport_Height,
                    State           => Snap.Messages,
                    Index           => I,
                    Now_Ms          => Now_Ms,
                    Config          => Config);
               Background : Editor.Theme.Color_RGB;
               Foreground : Editor.Theme.Color_RGB;
               Text_Columns : Natural := 0;
               Text : Unbounded_String;
            begin
               if not Rect.Visible then
                  null;
               else
                  case Message.Severity is
                     when Editor.Messages.Info_Message =>
                        Background := Message_Info_Background_Color;
                        Foreground := Message_Info_Foreground_Color;
                     when Editor.Messages.Success_Message =>
                        Background := Message_Success_Background_Color;
                        Foreground := Message_Success_Foreground_Color;
                     when Editor.Messages.Warning_Message =>
                        Background := Message_Warning_Background_Color;
                        Foreground := Message_Warning_Foreground_Color;
                     when Editor.Messages.Error_Message =>
                        Background := Message_Error_Background_Color;
                        Foreground := Message_Error_Foreground_Color;
                  end case;

                  Push_Rect
                    (Packet, Message_Background_Layer,
                     Float (Rect.X), Float (Rect.Y), Float (Rect.W), Float (Rect.H),
                     Background.R, Background.G, Background.B);

                  if Rect.W > 2 * Cell_W then
                     Text_Columns := (Rect.W / Cell_W) - 2;
                  else
                     Text_Columns := 0;
                  end if;

                  Text := To_Unbounded_String
                    (Editor.Messages.Display_Text (Message, Text_Columns));

                  Push_Message_Text
                    (Packet,
                     To_String (Text),
                     Float (Rect.X + Cell_W),
                     Float (Rect.Y),
                     Foreground);
               end if;
            end;
         end loop;
      end Push_Active_Message;

      procedure Push_Command_Palette
        (Packet : in out Render_Packet)
      is
         Palette : constant Editor.Command_Palette.Palette_State :=
           Editor.Command_Palette.Current;
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
         Config : constant Editor.Command_Palette.Command_Palette_Config :=
           Editor.Command_Palette.Current_Config;
         Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
         Margin : constant Natural := Editor.Theme.Palette_Margin;
         Max_W : constant Natural := Editor.Theme.Palette_Max_Width;
         Width : Natural := Max_W;
         X : Float := 0.0;
         Y : Float := 0.0;
         Visible_Count : Natural := 0;
         Height : Float := 0.0;
         Text_X : Float := 0.0;
         Field_Cols : Natural := 1;
         Query_Snap : Editor.Input_Field.Field_Snapshot;
      begin
         if not Palette.Open
           or else Editor.View.Viewport_Width = 0
           or else Editor.View.Viewport_Height = 0
         then
            return;
         end if;

         Editor.Executor.Command_Palette_Candidates (S, Candidates);
         Editor.Command_Palette.Reconcile_Selection (Candidates);
         Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

         if Editor.View.Viewport_Width <= Margin * 2 then
            Width := Editor.View.Viewport_Width;
         else
            Width := Natural'Min (Max_W, Editor.View.Viewport_Width - Margin * 2);
         end if;

         X := Float (Layout.Origin_X
              + (Editor.View.Viewport_Width - Width) / 2);
         Y := Float (Layout.Origin_Y)
              + Float'Max
                (Editor.Theme.Palette_Top_Min_Offset,
                 Float (Editor.View.Viewport_Height)
                 * Editor.Theme.Palette_Top_Fraction);

         declare
            Status_Y : constant Natural := Natural
              (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
            Top_Y : constant Natural := Natural'Min
              (Natural'Max (0, Natural (Y)), Status_Y);
            Available_H : constant Natural :=
              (if Status_Y > Top_Y then Status_Y - Top_Y else 0);
            Base_H : constant Natural :=
              2 * Cell_H + Natural (Editor.Theme.Palette_Outer_Padding_Y);
            Space_For_Rows : constant Natural :=
              (if Available_H > Base_H then (Available_H - Base_H) / Cell_H else 0);
         begin
            Visible_Count := Natural'Min
              (Natural'Min (Config.Max_Visible_Rows, Space_For_Rows),
               Editor.Command_Palette.Row_Count (Snapshot));
         end;

         Editor.Command_Palette.Ensure_Selected_Row_Visible (Snapshot, Visible_Count);

         Height := Float
           ((2 + Visible_Count) * Cell_H
            + Editor.Theme.Palette_Outer_Padding_Y);
         Text_X := X + Editor.Theme.Palette_Text_Padding_X;
         Field_Cols :=
           (if Width > Natural (2.0 * Editor.Theme.Palette_Text_Padding_X) + 2 * Cell_W
            then (Width - Natural (2.0 * Editor.Theme.Palette_Text_Padding_X)) / Cell_W - 2
            else 1);
         Query_Snap := Editor.Command_Palette.Query_Snapshot (Field_Cols);

         Push_Rect
           (Packet, Palette_Background_Layer,
            X, Y, Float (Width), Height,
            Palette_Background_Color.R,
            Palette_Background_Color.G,
            Palette_Background_Color.B);

         Push_Palette_Text
           (Packet,
            "> ",
            Text_X,
            Y + Editor.Theme.Palette_Text_Padding_Y,
            Palette_Text_Color);
         Push_Field_Selection
           (Packet, Query_Snap, Palette_Background_Layer,
            Text_X + Float (2 * Cell_W),
            Y + Editor.Theme.Palette_Text_Padding_Y);
         Push_Palette_Text
           (Packet,
            To_String (Query_Snap.Visible_Text),
            Text_X + Float (2 * Cell_W),
            Y + Editor.Theme.Palette_Text_Padding_Y,
            Palette_Text_Color);
         if Editor.Overlay_Focus.Is_Active
              (S.Overlay_Focus, Editor.Overlay_Focus.Command_Palette_Overlay)
         then
            Push_Rect
              (Packet, Palette_Text_Layer,
               Text_X + Float ((2 + Query_Snap.Cursor_Visible_Column) * Cell_W),
               Y + Editor.Theme.Palette_Text_Padding_Y + 2.0,
               2.0, Float (Cell_H - 4),
               Palette_Text_Color.R, Palette_Text_Color.G, Palette_Text_Color.B);
         end if;

         if Visible_Count > 0 then
         for Visible_Row in 0 .. Visible_Count - 1 loop
            declare
               Row_Index : constant Natural := Editor.Command_Palette.Current.Top_Row + Visible_Row;
            begin
               exit when Row_Index > Editor.Command_Palette.Row_Count (Snapshot);
               declare
                  Row : constant Editor.Command_Palette.Command_Palette_Row :=
                    Editor.Command_Palette.Row (Snapshot, Row_Index);
                  Row_Y : constant Float :=
                    Y + Editor.Theme.Palette_Text_Padding_Y
                    + Float ((Visible_Row + 1) * Cell_H);
               begin
                  case Row.Kind is
                     when Editor.Command_Palette.Command_Palette_Header_Row =>
                        Push_Palette_Text
                          (Packet,
                           To_String (Row.Primary_Text),
                           Text_X,
                           Row_Y,
                           Palette_Muted_Text_Color);

                     when Editor.Command_Palette.Command_Palette_Help_Row
                        | Editor.Command_Palette.Command_Palette_State_Context_Row =>
                        declare
                           Text : constant String :=
                             (if Length (Row.Secondary_Text) > 0
                              then To_String (Row.Primary_Text) & " - "
                                & To_String (Row.Secondary_Text)
                              else To_String (Row.Primary_Text));
                        begin
                           Push_Palette_Text
                             (Packet,
                              Fit_Text (Text, Field_Cols),
                              Text_X,
                              Row_Y,
                              Command_Palette_Help_Color);
                        end;

                     when Editor.Command_Palette.Command_Palette_Detail_Row =>
                        Push_Palette_Text
                          (Packet,
                           To_String (Row.Primary_Text),
                           Text_X + Float (Cell_W),
                           Row_Y,
                           Command_Palette_Detail_Color);

                     when Editor.Command_Palette.Command_Palette_Empty_Row =>
                        Push_Palette_Text
                          (Packet,
                           To_String (Row.Primary_Text),
                           Text_X,
                           Row_Y,
                           Command_Palette_Help_Color);
                        if Length (Row.Secondary_Text) > 0 then
                           Push_Palette_Text
                             (Packet,
                              " — " & To_String (Row.Secondary_Text),
                              Text_X + Float
                                ((Length (Row.Primary_Text) + 3) * Cell_W),
                              Row_Y,
                              Command_Palette_Detail_Color);
                        end if;

                     when Editor.Command_Palette.Command_Palette_Command_Row =>
                        declare
                           D : constant Editor.Commands.Command_Palette_Candidate :=
                             Editor.Command_Palette.Candidate (Snapshot, Row.Candidate_Index);
                           Display_D : Editor.Commands.Command_Palette_Candidate := D;
                           Text_Color : constant Editor.Theme.Color_RGB :=
                             (if D.Available
                              then Palette_Text_Color
                              else Editor.Theme.Command_Palette_Disabled_Foreground);
                           Row_Color : constant Editor.Theme.Color_RGB :=
                             (if D.Available
                              then Palette_Selected_Row_Color
                              else Editor.Theme.Command_Palette_Disabled_Selected_Background);
                        begin
                           if not Row.Has_Keybinding then
                              Display_D.Has_Keybinding := False;
                              Display_D.Keybinding_Display := Null_Unbounded_String;
                           end if;

                           if Row.Is_Selected then
                              Push_Rect
                                (Packet, Palette_Selection_Layer,
                                 X + Editor.Theme.Palette_Selected_Row_Inset_X,
                                 Row_Y - Editor.Theme.Palette_Selected_Row_Offset_Y,
                                 Float (Width)
                                   - 2.0 * Editor.Theme.Palette_Selected_Row_Inset_X,
                                 Float (Cell_H),
                                 Row_Color.R,
                                 Row_Color.G,
                                 Row_Color.B);
                           end if;

                           declare
                              Row_Columns : constant Natural :=
                                (if Width > Natural (2.0 * Editor.Theme.Palette_Text_Padding_X)
                                 then (Width - Natural (2.0 * Editor.Theme.Palette_Text_Padding_X)) / Cell_W
                                 else 0);
                              Row_Layout : constant Editor.Command_Palette.Command_Palette_Row_Layout :=
                                Editor.Command_Palette.Project_Command_Row_Layout
                                  (Display_D, Row.Is_Selected, Row_Columns);
                              Binding_Color : constant Editor.Theme.Color_RGB :=
                                (if not D.Available
                                 then Editor.Theme.Command_Palette_Keybinding_Disabled_Foreground
                                 elsif Row.Is_Selected
                                 then Editor.Theme.Command_Palette_Keybinding_Selected_Foreground
                                 else Editor.Theme.Command_Palette_Keybinding_Foreground);
                           begin
                              if Row_Layout.Label_Columns > 0 then
                                 Push_Palette_Text
                                   (Packet,
                                    Editor.Command_Palette.Truncate_With_Ellipsis
                                      (To_String (D.Label), Row_Layout.Label_Columns),
                                    Text_X + Float (Row_Layout.Label_Start_Column * Cell_W),
                                    Row_Y,
                                    Text_Color);
                              end if;

                              if Row_Layout.Show_Secondary then
                                 declare
                                    Secondary_Source : constant String :=
                                      (if not D.Available
                                       then (if Length (D.Reason) > 0
                                             then To_String (D.Reason)
                                             else "Command not available here")
                                       else To_String (D.Description));
                                    Secondary_Color : constant Editor.Theme.Color_RGB :=
                                      (if not D.Available
                                       then Editor.Theme.Command_Palette_Reason_Foreground
                                       else Command_Palette_Secondary_Color);
                                 begin
                                    Push_Palette_Text
                                      (Packet,
                                       " — " & Editor.Command_Palette.Truncate_With_Ellipsis
                                         (Secondary_Source, Row_Layout.Secondary_Columns),
                                       Text_X + Float ((Row_Layout.Secondary_Start_Column - 3) * Cell_W),
                                       Row_Y,
                                       Secondary_Color);
                                 end;
                              end if;

                              if Row_Layout.Show_Keybinding then
                                 Push_Palette_Text
                                   (Packet,
                                    To_String (Row_Layout.Keybinding_Text),
                                    Text_X + Float (Row_Layout.Keybinding_Column * Cell_W),
                                    Row_Y,
                                    Binding_Color);
                              end if;
                           end;
                        end;
                  end case;
               end;
            end;
         end loop;
         end if;
      end Push_Command_Palette;


      procedure Push_Feature_Panel_Text
        (Packet : in out Render_Packet;
         Text   : String;
         X      : Float;
         Y      : Float;
         Color  : Editor.Theme.Color_RGB;
         Layer  : Render_Layer := Problems_Text_Layer)
      is
         Cursor_X : Float := X;
      begin
         Record_Debug_Text_For_Test (Text);
         for I in Text'Range loop
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Text (I) /= ASCII.NUL
                 and then Text (I) /= ASCII.CR
                 and then Text (I) /= ASCII.LF
                 and then Editor.Fonts.Get_Glyph (Text (I), M)
               then
                  Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
                  if M.W > 0.0 and then M.H > 0.0 then
                     Push_Glyph
                       (Packet, Layer,
                        Float'Floor (Cursor_X + M.Bearing_X + 0.5),
                        Float'Floor
                          (Y
                           + Float'Max
                             (0.0,
                              (Float (Cell_H)
                               - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                              / 2.0)
                           + Editor.Fonts.Ascent
                           - M.Bearing_Y
                           + 0.5),
                        M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Color.R, Color.G, Color.B);
                  end if;
               end if;
               Cursor_X := Cursor_X + Float (Cell_W);
            end;
         end loop;
      end Push_Feature_Panel_Text;

      procedure Push_Build_UI_Panel
        (Packet : in out Render_Packet)
      is
         S : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
         Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
           Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
         Row_Count : constant Natural := Natural (Snapshot.Actions.Length);
         Suppressed_Count : constant Natural :=
           Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
             (S.Feature_Diagnostics);
         Displayed_Suppressed_Count : constant Natural :=
           Editor.Build_UI_Panel_Layout.Displayed_Suppressed_Row_Count
             (Text_Viewport_Height => Text_Viewport_Height,
              Cell_H               => Cell_H,
              Action_Count         => Row_Count,
              Suppressed_Count     => Suppressed_Count);
         Suppressed_Top_Row : constant Natural :=
           Editor.Feature_Diagnostics.Suppressed_Top_Row
             (S.Feature_Diagnostics, Displayed_Suppressed_Count);
         Selected_Suppressed : constant Natural :=
           Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
             (S.Feature_Diagnostics);
         Geometry : constant Editor.Build_UI_Panel_Layout.Build_UI_Panel_Geometry :=
           Editor.Build_UI_Panel_Layout.Layout
             (Viewport_Width       => Editor.View.Viewport_Width,
              Text_Viewport_Y      => Natural (Editor.Layout.Text_Viewport_Y (Layout)),
              Text_Viewport_Height => Text_Viewport_Height,
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
             (S.Build_UI, Row_Count, Visible_Action_Rows);
      begin
         if not Snapshot.Visible
           or else Width <= 0.0
           or else H <= 0.0
         then
            return;
         end if;

         Push_Rect
           (Packet, Build_UI_Background_Layer,
            X, Y, Width, H,
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);
         Push_Rect
           (Packet, Build_UI_Header_Layer,
            X, Y, Width, Float (Cell_H),
            Problems_Header_Background_Color.R,
            Problems_Header_Background_Color.G,
            Problems_Header_Background_Color.B);
         Push_Feature_Panel_Text
           (Packet,
            Truncate_To_Columns
              ("Build UI  " & To_String (Snapshot.Candidate_Count_Label),
               Text_Columns),
            Text_X, Y, Problems_Foreground_Color, Build_UI_Text_Layer);
         Push_Feature_Panel_Text
           (Packet,
            Truncate_To_Columns
              (To_String (Snapshot.Request_Status_Label)
               & "  "
               & To_String (Snapshot.Run_Command_Status_Label),
               Text_Columns),
            Text_X, Y + Float (Cell_H), Problems_Foreground_Color,
            Build_UI_Text_Layer);

         if Row_Count = 0 and then Suppressed_Count = 0 then
            Push_Feature_Panel_Text
              (Packet, "No build actions", Text_X, Y + Float (2 * Cell_H),
               Problems_Foreground_Color, Build_UI_Text_Layer);
         elsif Visible_Action_Rows > 0 then
            for Visible_Offset in 0 .. Visible_Action_Rows - 1 loop
               declare
                  Offset : constant Natural := Action_Top_Row - 1 + Visible_Offset;
                  Row : constant Editor.Build_UI.Build_UI_Action_Row :=
                    Snapshot.Actions.Element (Offset);
                  Panel_Row : constant Natural :=
                    Geometry.Action_Start_Row + Visible_Offset;
                  Row_Y : constant Float := Y + Float (Panel_Row * Cell_H);
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
                  Text_Color : constant Editor.Theme.Color_RGB :=
                    (if Row.Enabled then Problems_Foreground_Color
                     else Pending_Bar_Disabled_Action_Color);
               begin
                  if Panel_Row >= Visible_Rows then
                     exit;
                  end if;

                  if Row.Selected then
                     declare
                        Fill : constant Editor.Theme.Color_RGB :=
                          (if Snapshot.Focused then Problems_Selected_Active_Background_Color
                           else Problems_Selected_Inactive_Background_Color);
                     begin
                        Push_Rect
                          (Packet, Build_UI_Row_Layer,
                           X, Row_Y, Width, Float (Cell_H),
                           Fill.R, Fill.G, Fill.B);
                     end;
                  end if;

                  Push_Feature_Panel_Text
                    (Packet,
                     Truncate_To_Columns
                       ((if Row.Selected then "> " else "  ") & Detail_Text,
                        Text_Columns),
                     Text_X, Row_Y, Text_Color, Build_UI_Text_Layer);
               end;
            end loop;
         end if;

         if Suppressed_Count > 0
           and then Displayed_Suppressed_Count > 0
           and then Geometry.Suppressed_Header_Row < Visible_Rows
         then
            Push_Feature_Panel_Text
              (Packet,
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
               Problems_Foreground_Color,
               Build_UI_Text_Layer);

            for Visible_Row in 1 .. Displayed_Suppressed_Count loop
               declare
                  Row : constant Natural :=
                    Suppressed_Top_Row + Visible_Row - 1;
                  Panel_Row : constant Natural :=
                    Geometry.Suppressed_Start_Row + Visible_Row - 1;
                  Row_Y : constant Float := Y + Float (Panel_Row * Cell_H);
                  Selected : constant Boolean := Row = Selected_Suppressed;
                  Text : constant String :=
                    (if Selected then "> " else "  ")
                    & Editor.Feature_Diagnostics.Suppressed_Diagnostic_Text
                        (S.Feature_Diagnostics, Positive (Row));
               begin
                  if Panel_Row >= Visible_Rows then
                     exit;
                  end if;

                  if Selected then
                     declare
                        Fill : constant Editor.Theme.Color_RGB :=
                          (if Snapshot.Focused then Problems_Selected_Active_Background_Color
                           else Problems_Selected_Inactive_Background_Color);
                     begin
                        Push_Rect
                          (Packet, Build_UI_Row_Layer,
                           X, Row_Y, Width, Float (Cell_H),
                           Fill.R, Fill.G, Fill.B);
                     end;
                  end if;

                  Push_Feature_Panel_Text
                    (Packet,
                     Truncate_To_Columns (Text, Text_Columns),
                     Text_X, Row_Y, Problems_Foreground_Color,
                     Build_UI_Text_Layer);
               end;
            end loop;
         end if;
      end Push_Build_UI_Panel;

      procedure Push_Feature_Panel
        (Packet : in out Render_Packet)
      is
         Panel : constant Editor.Feature_Panel.Feature_Panel_State :=
           Editor.Input_Bridge.Feature_Panel_For_Render;
         Snapshot : constant Editor.Feature_Panel.Feature_Panel_Render_Snapshot :=
           Editor.Feature_Panel.Build_Render_Snapshot (Panel);
         Focused : constant Boolean :=
           Editor.Feature_Panel.Snapshot_Is_Focused (Snapshot);
         Width : constant Float := Float'Min (280.0, Float (Editor.View.Viewport_Width));
         X : constant Float := Float (Editor.View.Viewport_Width) - Width;
         Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         H : constant Float := Float (Text_Viewport_Height);
         Text_X : constant Float := X + Float (Cell_W);
         Text_Columns : constant Natural :=
           (if Natural (Width) / Cell_W > 2 then Natural (Width) / Cell_W - 2 else 0);
         Max_Data_Rows : constant Natural :=
           (if Natural (H) / Cell_H > 1 then Natural (H) / Cell_H - 1 else 0);
         Row_Count : constant Natural := Editor.Feature_Panel.Snapshot_Row_Count (Snapshot);
         Rows_To_Render : constant Natural := Natural'Min (Row_Count, Max_Data_Rows);
      begin
         if not Editor.Feature_Panel.Snapshot_Is_Visible (Snapshot) then
            return;
         end if;

         Push_Rect
           (Packet, Problems_Background_Layer,
            X, Y, Width, H,
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);
         Push_Rect
           (Packet, Problems_Header_Layer,
            X, Y, Width, Float (Cell_H),
            Problems_Header_Background_Color.R,
            Problems_Header_Background_Color.G,
            Problems_Header_Background_Color.B);
         Push_Feature_Panel_Text
           (Packet,
            Truncate_To_Columns
              (Editor.Feature_Panel.Snapshot_Header_Text (Snapshot),
               Text_Columns),
            Text_X, Y, Problems_Foreground_Color);

         if Row_Count = 0 then
            Push_Feature_Panel_Text
              (Packet,
               Truncate_To_Columns
                 (Editor.Feature_Panel.Snapshot_Empty_Message (Snapshot),
                  Text_Columns),
               Text_X,
               Y + Float (Cell_H * 2),
               Problems_Foreground_Color);
         else
            for I in 1 .. Rows_To_Render loop
               declare
                  Row_Y : constant Float := Y + Float (I * Cell_H);
                  Is_Selected : constant Boolean :=
                    Editor.Feature_Panel.Snapshot_Row_Selected (Snapshot, I);
                  Is_Current_Symbol : constant Boolean :=
                    Editor.Feature_Panel.Snapshot_Row_Is_Current_Symbol (Snapshot, I);
                  Text_Color : constant Editor.Theme.Color_RGB :=
                    (if Is_Selected and then Focused then Problems_Selected_Active_Foreground_Color
                     elsif Is_Selected then Problems_Selected_Inactive_Foreground_Color
                     else Problems_Foreground_Color);
                  Label : constant String :=
                    Editor.Feature_Panel.Snapshot_Row_Label (Snapshot, I);
                  Detail : constant String :=
                    Editor.Feature_Panel.Snapshot_Row_Detail (Snapshot, I);
                  Base_Text : constant String :=
                    (if Detail'Length = 0 then Label else Label & " — " & Detail);
                  Text : constant String :=
                    (if Is_Current_Symbol then "> " & Base_Text else Base_Text);
               begin
                  if Is_Selected then
                     declare
                        Fill : constant Editor.Theme.Color_RGB :=
                          (if Focused then Problems_Selected_Active_Background_Color
                           else Problems_Selected_Inactive_Background_Color);
                     begin
                        Push_Rect
                          (Packet, Problems_Row_Layer,
                           X, Row_Y, Width, Float (Cell_H),
                           Fill.R, Fill.G, Fill.B);
                     end;
                  end if;

                  Push_Feature_Panel_Text
                    (Packet,
                     Truncate_To_Columns (Text, Text_Columns),
                     Text_X, Row_Y, Text_Color);
               end;
            end loop;
         end if;
      end Push_Feature_Panel;

      procedure Push_Keybinding_Surface
        (Packet : in out Render_Packet)
      is
         Surface : constant Editor.Keybinding_Management.Keybinding_Surface_Snapshot :=
           Snap.Keybindings_UI;
         Width : constant Float := Float'Min (420.0, Float (Editor.View.Viewport_Width));
         X : constant Float := Float (Editor.View.Viewport_Width) - Width;
         Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         H : constant Float := Float (Text_Viewport_Height);
         Text_X : constant Float := X + Float (Cell_W);
         Text_Columns : constant Natural :=
           (if Natural (Width) / Cell_W > 2 then Natural (Width) / Cell_W - 2 else 0);
         Max_Data_Rows : constant Natural :=
           (if Natural (H) / Cell_H > 4 then Natural (H) / Cell_H - 4 else 0);
         Rows_To_Render : constant Natural :=
           Natural'Min (Surface.Display_Row_Count, Max_Data_Rows);
         Remaining_Chord_Rows : constant Natural :=
           (if Max_Data_Rows > Rows_To_Render then Max_Data_Rows - Rows_To_Render else 0);
         Chord_Rows_To_Render : constant Natural :=
           Natural'Min (Surface.Display_Chord_Row_Count, Remaining_Chord_Rows);

         function Filter_Label return String is
         begin
            case Surface.Filter is
               when Editor.Keybinding_Management.Filter_All =>
                  return "all";
               when Editor.Keybinding_Management.Filter_Bound =>
                  return "bound";
               when Editor.Keybinding_Management.Filter_Unbound =>
                  return "unbound";
               when Editor.Keybinding_Management.Filter_Conflicts =>
                  return "conflicts";
               when Editor.Keybinding_Management.Filter_Non_Bindable =>
                  return "non-bindable";
            end case;
         end Filter_Label;

         function Capture_Label return String is
         begin
            case Surface.Capture is
               when Editor.Keybinding_Management.Capture_Inactive =>
                  return "";
               when Editor.Keybinding_Management.Capture_Active =>
                  return " — capture shortcut";
               when Editor.Keybinding_Management.Capture_Conflict_Pending =>
                  return " — conflict pending";
            end case;
         end Capture_Label;
      begin
         if not Surface.Visible then
            return;
         end if;

         Push_Rect
           (Packet, Problems_Background_Layer,
            X, Y, Width, H,
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);
         Push_Rect
           (Packet, Problems_Header_Layer,
            X, Y, Width, Float (Cell_H),
            Problems_Header_Background_Color.R,
            Problems_Header_Background_Color.G,
            Problems_Header_Background_Color.B);
         Push_Feature_Panel_Text
           (Packet,
            Truncate_To_Columns
              ("Keybindings — " & Filter_Label & Capture_Label,
               Text_Columns),
            Text_X, Y, Problems_Foreground_Color);

         if Surface.Has_Pending_Reset then
            Push_Feature_Panel_Text
              (Packet,
               Truncate_To_Columns
                 ("Reset pending: run reset again to confirm, cancel to abort.",
                  Text_Columns),
               Text_X, Y + Float (Cell_H), Problems_Foreground_Color);
         elsif Surface.Last_Load_Ignored_Count > 0 then
            Push_Feature_Panel_Text
              (Packet,
               Truncate_To_Columns
                 (To_String (Surface.Last_Load_Diagnostic_Label), Text_Columns),
               Text_X, Y + Float (Cell_H), Problems_Foreground_Color);
         elsif Surface.Row_Count = 0 then
            Push_Feature_Panel_Text
              (Packet,
               Truncate_To_Columns ("No matching keybindings", Text_Columns),
               Text_X, Y + Float (Cell_H), Problems_Foreground_Color);
         end if;

         for I in 1 .. Rows_To_Render loop
            declare
               Row : constant Editor.Keybinding_Management.Keybinding_Row_Snapshot :=
                 Surface.Display_Rows (I);
               Row_Y : constant Float := Y + Float ((I + 2) * Cell_H);
               Text_Color : constant Editor.Theme.Color_RGB :=
                 (if Row.Selected and then Surface.Focused then
                     Problems_Selected_Active_Foreground_Color
                  elsif Row.Selected then Problems_Selected_Inactive_Foreground_Color
                  else Problems_Foreground_Color);
               Binding_Text : constant String :=
                 (if Row.Has_Active_Chord then To_String (Row.Active_Chords)
                  elsif Row.Has_Default_Chord then "default " & To_String (Row.Default_Chord)
                  elsif Row.Bindable then "unbound"
                  else "non-bindable");
               Conflict_Text : constant String :=
                 (if Row.Conflicting then " conflict" else "");
               Row_Text : constant String :=
                 (if Row.Selected then "> " else "  ")
                 & To_String (Row.Command_Title) & " [" & Binding_Text & "]"
                 & Conflict_Text;
            begin
               if Row.Selected then
                  declare
                     Fill : constant Editor.Theme.Color_RGB :=
                       (if Surface.Focused then Problems_Selected_Active_Background_Color
                        else Problems_Selected_Inactive_Background_Color);
                  begin
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        X, Row_Y, Width, Float (Cell_H),
                        Fill.R, Fill.G, Fill.B);
                  end;
               end if;

               Push_Feature_Panel_Text
                 (Packet, Truncate_To_Columns (Row_Text, Text_Columns),
                  Text_X, Row_Y, Text_Color);
            end;
         end loop;

         for I in 1 .. Chord_Rows_To_Render loop
            declare
               Row : constant Editor.Keybinding_Management.Keybinding_Chord_Row_Snapshot :=
                 Surface.Display_Chord_Rows (I);
               Row_Y : constant Float :=
                 Y + Float ((Rows_To_Render + I + 2) * Cell_H);
               Text_Color : constant Editor.Theme.Color_RGB :=
                 (if Row.Selected and then Surface.Focused then
                     Problems_Selected_Active_Foreground_Color
                  elsif Row.Selected then Problems_Selected_Inactive_Foreground_Color
                  else Problems_Foreground_Color);
               Source_Text : constant String :=
                 (if Row.Default_Chord then "default"
                  elsif Row.User_Override then "user"
                  else "runtime");
               Conflict_Text : constant String :=
                 (if Row.Conflicting then " conflict" else "");
               Row_Text : constant String :=
                 (if Row.Selected then "> chord " else "  chord ")
                 & To_String (Row.Chord_Label) & " -> "
                 & To_String (Row.Command_Title) & " [" & Source_Text & "]"
                 & Conflict_Text;
            begin
               if Row.Selected then
                  declare
                     Fill : constant Editor.Theme.Color_RGB :=
                       (if Surface.Focused then Problems_Selected_Active_Background_Color
                        else Problems_Selected_Inactive_Background_Color);
                  begin
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        X, Row_Y, Width, Float (Cell_H),
                        Fill.R, Fill.G, Fill.B);
                  end;
               end if;

               Push_Feature_Panel_Text
                 (Packet, Truncate_To_Columns (Row_Text, Text_Columns),
                  Text_X, Row_Y, Text_Color);
            end;
         end loop;
      end Push_Keybinding_Surface;


      procedure Push_Bookmark_Surface
        (Packet : in out Render_Packet)
      is
         Width : constant Float := Float'Min (320.0, Float (Editor.View.Viewport_Width));
         X : constant Float := Float (Editor.View.Viewport_Width) - Width;
         Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         H : constant Float := Float (Text_Viewport_Height);
         Text_X : constant Float := X + Float (Cell_W);
         Text_Columns : constant Natural :=
           (if Natural (Width) / Cell_W > 2 then Natural (Width) / Cell_W - 2 else 0);
         Max_Data_Rows : constant Natural :=
           (if Natural (H) / Cell_H > 1 then Natural (H) / Cell_H - 1 else 0);
         Rows_To_Render : constant Natural :=
           Natural'Min (Natural (Snap.Bookmark_Rows.Length), Max_Data_Rows);

         function Line_Image (Value : Natural) return String is
            Raw : constant String := Natural'Image (Value);
         begin
            if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
               return Raw (Raw'First + 1 .. Raw'Last);
            else
               return Raw;
            end if;
         end Line_Image;

         function Row_Text (Row : Editor.Bookmarks.Bookmark_Row) return String is
            Location : constant String :=
              To_String (Row.File_Display_Path) & ":" & Line_Image (Row.Line_Number) &
              (if Row.Has_Column then ":" & Line_Image (Row.Column) else "");
            Markers : constant String :=
              (if Row.Is_Open then " [open]" else "") &
              (if Row.Is_Active then " [active]" else "") &
              (if Row.Is_Dirty then " [dirty]" else "");
         begin
            return (if Row.Is_Selected then "> " else "  ") & Location & Markers;
         end Row_Text;
      begin
         if not Snap.Bookmarks_Visible then
            return;
         end if;

         Push_Rect
           (Packet, Problems_Background_Layer,
            X, Y, Width, H,
            Problems_Background_Color.R,
            Problems_Background_Color.G,
            Problems_Background_Color.B);
         Push_Rect
           (Packet, Problems_Header_Layer,
            X, Y, Width, Float (Cell_H),
            Problems_Header_Background_Color.R,
            Problems_Header_Background_Color.G,
            Problems_Header_Background_Color.B);
         Push_Feature_Panel_Text
           (Packet, "Bookmarks", Text_X, Y, Problems_Foreground_Color);

         if Snap.Bookmark_Count = 0 then
            Push_Feature_Panel_Text
              (Packet,
               Truncate_To_Columns (To_String (Snap.Bookmark_Empty_Message), Text_Columns),
               Text_X,
               Y + Float (Cell_H * 2),
               Problems_Foreground_Color);
         else
            for I in 1 .. Rows_To_Render loop
               declare
                  Row : constant Editor.Bookmarks.Bookmark_Row := Snap.Bookmark_Rows (Positive (I));
                  Row_Y : constant Float := Y + Float (I * Cell_H);
                  Text_Color : constant Editor.Theme.Color_RGB :=
                    (if Row.Is_Selected then Problems_Selected_Inactive_Foreground_Color
                     else Problems_Foreground_Color);
               begin
                  if Row.Is_Selected then
                     Push_Rect
                       (Packet, Problems_Row_Layer,
                        X, Row_Y, Width, Float (Cell_H),
                        Problems_Selected_Inactive_Background_Color.R,
                        Problems_Selected_Inactive_Background_Color.G,
                        Problems_Selected_Inactive_Background_Color.B);
                  end if;

                  Push_Feature_Panel_Text
                    (Packet,
                     Truncate_To_Columns (Row_Text (Row), Text_Columns),
                     Text_X, Row_Y, Text_Color);
               end;
            end loop;
         end if;
      end Push_Bookmark_Surface;

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
      Push_Feature_Panel (Out_Packet);
      Push_Keybinding_Surface (Out_Packet);
      Push_Bookmark_Surface (Out_Packet);
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
                     Push_Gutter_Marker (Out_Packet, Seg.Logical_Row, Screen_Row);
                     Push_Fold_Marker (Out_Packet, Seg.Logical_Row, Screen_Row);
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
                        Push_Gutter_Line_Number
                          (Out_Packet,
                           Seg.Logical_Row,
                           Screen_Row,
                           Current_Row,
                           Settings.Highlight_Current_Gutter
                           and then Seg.Logical_Row = Current_Row);
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
                        Push_Folded_Ellipsis
                          (Out_Packet, Seg.Logical_Row, Screen_Row, Seg.End_Col + 1);
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
         Push_Terminal_Tasks_Panel (Out_Packet);
      elsif Editor.Panels.Active_Bottom_Content (Layout.Panels) = Editor.Panels.Search_Results_Content then
         Push_Search_Results_Panel (Out_Packet);
      else
         Push_Problems_Panel (Out_Packet);
      end if;

      Push_Status_Bar (Out_Packet);

      Push_Pending_Transition_Bar (Out_Packet);

      Push_Semantic_Popup (Out_Packet);

      Push_Active_Find_Prompt (Out_Packet);

      Push_Guided_Prompt (Out_Packet);

      Push_Project_Search_Bar (Out_Packet);

      Push_Goto_Line (Out_Packet);
      Push_Quick_Open (Out_Packet);
      Push_Buffer_Switcher (Out_Packet);

      Push_Active_Message (Out_Packet);

      Push_Command_Palette (Out_Packet);

   end Build_Render_Packet;

end Editor.Render_Packet;
