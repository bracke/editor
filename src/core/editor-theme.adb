with Editor.Syntax;
with Editor.Diagnostics;

package body Editor.Theme is

   Active_Id : String (1 .. 7) := "dark   ";
   Active_Len : Natural := 4;

   procedure Set_Active_Id (Id : String) is
   begin
      Active_Id := (others => ' ');
      Active_Id (1 .. Id'Length) := Id;
      Active_Len := Id'Length;
   end Set_Active_Id;

   function RGB (R, G, B : Float) return Color_RGB is
   begin
      return (R => R, G => G, B => B);
   end RGB;

   function Active_Theme_Id return String is
   begin
      return Active_Id (1 .. Active_Len);
   end Active_Theme_Id;

   function Is_Valid_Theme_Id (Id : String) return Boolean is
   begin
      return Id = "dark" or else Id = "light" or else Id = "default";
   end Is_Valid_Theme_Id;

   procedure Set_Theme_By_Id (Id : String; Found : out Boolean) is
   begin
      Found := Is_Valid_Theme_Id (Id);
      if Found then
         if Id = "default" then
            Set_Active_Id ("dark");
         else
            Set_Active_Id (Id);
         end if;
      end if;
   end Set_Theme_By_Id;

   procedure Toggle_Theme is
      Found : Boolean := False;
   begin
      if Active_Theme_Id = "dark" then
         Set_Theme_By_Id ("light", Found);
      else
         Set_Theme_By_Id ("dark", Found);
      end if;
   end Toggle_Theme;

   function Color
     (Kind : Theme_Color) return Color_RGB
   is
   begin
      case Kind is
         when TC_Editor_Background =>
            return RGB (0.10, 0.10, 0.12);
         when TC_Gutter_Background =>
            return RGB (0.12, 0.12, 0.12);
         when TC_Gutter_Separator =>
            return RGB (0.22, 0.22, 0.27);
         when TC_Current_Text_Row =>
            return RGB (0.16, 0.16, 0.20);
         when TC_Current_Gutter_Row =>
            return RGB (0.18, 0.18, 0.23);
         when TC_Active_Find_Inactive_Match_Background =>
            return RGB (0.45, 0.35, 0.10);
         when TC_Active_Find_Match_Background =>
            return RGB (0.95, 0.62, 0.12);
         when TC_Selection_Background =>
            return RGB (0.30, 0.45, 0.75);
         when TC_Caret_Color =>
            return RGB (1.0, 1.0, 1.0);
         when TC_Text_Default =>
            return RGB (1.0, 1.0, 1.0);
         when TC_Line_Number_Inactive =>
            return RGB (0.42, 0.42, 0.46);
         when TC_Line_Number_Current =>
            return RGB (0.92, 0.92, 0.96);
         when TC_Diagnostic_Hint =>
            return RGB (0.45, 0.55, 0.65);
         when TC_Diagnostic_Information =>
            return RGB (0.25, 0.55, 1.0);
         when TC_Diagnostic_Warning =>
            return RGB (1.0, 0.68, 0.20);
         when TC_Diagnostic_Error =>
            return RGB (1.0, 0.25, 0.22);
         when TC_Gutter_Diagnostic_Error =>
            return RGB (1.0, 0.20, 0.18);
         when TC_Gutter_Diagnostic_Warning =>
            return RGB (1.0, 0.68, 0.20);
         when TC_Gutter_Dirty_Line =>
            return RGB (0.20, 0.62, 0.90);
         when TC_Gutter_Added_Line =>
            return RGB (0.25, 0.78, 0.36);
         when TC_Gutter_Modified_Line =>
            return RGB (0.95, 0.68, 0.25);
         when TC_Gutter_Deleted_Line =>
            return RGB (0.95, 0.32, 0.28);
         when TC_Gutter_Bookmark =>
            return RGB (0.62, 0.45, 0.95);
         when TC_Gutter_Marker_Hover_Background =>
            return RGB (0.24, 0.24, 0.30);
         when TC_Gutter_Marker_Hover_Outline =>
            return RGB (0.85, 0.85, 0.92);
         when TC_Minimap_Background =>
            return RGB (0.08, 0.08, 0.10);
         when TC_Minimap_Text_Density =>
            return RGB (0.42, 0.42, 0.48);
         when TC_Minimap_Viewport =>
            return RGB (0.28, 0.32, 0.40);
         when TC_Scrollbar_Track =>
            return RGB (0.11, 0.11, 0.14);
         when TC_Scrollbar_Thumb =>
            return RGB (0.35, 0.35, 0.42);
         when TC_Scrollbar_Thumb_Hover =>
            return RGB (0.45, 0.45, 0.52);
         when TC_Scrollbar_Thumb_Active =>
            return RGB (0.55, 0.55, 0.64);
         when TC_Palette_Background =>
            return RGB (0.13, 0.13, 0.16);
         when TC_Palette_Text =>
            return RGB (0.94, 0.94, 0.96);
         when TC_Palette_Selected_Row =>
            return RGB (0.24, 0.30, 0.44);
         when TC_Palette_Muted_Text =>
            return RGB (0.56, 0.56, 0.62);
         when TC_Status_Bar_Background =>
            return RGB (0.10, 0.10, 0.13);
         when TC_Status_Bar_Foreground =>
            return RGB (0.88, 0.88, 0.92);
         when TC_Status_Bar_Separator =>
            return RGB (0.24, 0.24, 0.30);
         when TC_Status_Bar_Dirty =>
            return RGB (1.0, 0.68, 0.20);
         when TC_Tab_Bar_Background =>
            return RGB (0.09, 0.09, 0.12);
         when TC_Tab_Bar_Active_Background =>
            return RGB (0.18, 0.20, 0.27);
         when TC_Tab_Bar_Inactive_Background =>
            return RGB (0.12, 0.12, 0.16);
         when TC_Tab_Bar_Active_Foreground =>
            return RGB (0.95, 0.95, 0.98);
         when TC_Tab_Bar_Inactive_Foreground =>
            return RGB (0.66, 0.66, 0.72);
         when TC_Tab_Bar_Dirty =>
            return RGB (1.0, 0.68, 0.20);
         when TC_Tab_Bar_Border =>
            return RGB (0.24, 0.24, 0.30);
         when TC_Tab_Bar_Close =>
            return RGB (0.78, 0.78, 0.84);
         when TC_File_Tree_Background =>
            return RGB (0.09, 0.09, 0.11);
         when TC_File_Tree_Foreground =>
            return RGB (0.82, 0.82, 0.86);
         when TC_File_Tree_Directory_Foreground =>
            return RGB (0.90, 0.90, 0.96);
         when TC_File_Tree_Active_Background =>
            return RGB (0.20, 0.26, 0.38);
         when TC_File_Tree_Active_Foreground =>
            return RGB (0.98, 0.98, 1.0);
         when TC_File_Tree_Selected_Active_Background =>
            return RGB (0.24, 0.36, 0.56);
         when TC_File_Tree_Selected_Active_Foreground =>
            return RGB (1.0, 1.0, 1.0);
         when TC_File_Tree_Selected_Inactive_Background =>
            return RGB (0.19, 0.21, 0.27);
         when TC_File_Tree_Selected_Inactive_Foreground =>
            return RGB (0.88, 0.88, 0.92);
         when TC_File_Tree_Focused_Border =>
            return RGB (0.48, 0.62, 0.90);
         when TC_File_Tree_Separator =>
            return RGB (0.24, 0.24, 0.30);
         when TC_File_Tree_Splitter =>
            return RGB (0.28, 0.28, 0.34);
         when TC_File_Tree_Splitter_Active =>
            return RGB (0.40, 0.40, 0.48);
         when TC_File_Tree_Indent_Guide =>
            return RGB (0.22, 0.22, 0.27);
         when TC_Message_Info_Background =>
            return RGB (0.16, 0.18, 0.24);
         when TC_Message_Info_Foreground =>
            return RGB (0.92, 0.94, 1.0);
         when TC_Message_Success_Background =>
            return RGB (0.12, 0.25, 0.16);
         when TC_Message_Success_Foreground =>
            return RGB (0.82, 1.0, 0.86);
         when TC_Message_Warning_Background =>
            return RGB (0.30, 0.22, 0.08);
         when TC_Message_Warning_Foreground =>
            return RGB (1.0, 0.86, 0.52);
         when TC_Message_Error_Background =>
            return RGB (0.30, 0.10, 0.10);
         when TC_Message_Error_Foreground =>
            return RGB (1.0, 0.78, 0.76);
         when TC_Pending_Transition_Background =>
            return Color (TC_Message_Warning_Background);
         when TC_Pending_Transition_Foreground =>
            return Color (TC_Message_Warning_Foreground);
         when TC_Pending_Transition_Accent =>
            return Color (TC_Diagnostic_Warning);
         when TC_Pending_Transition_Action_Foreground =>
            return RGB (0.96, 0.96, 1.0);
         when TC_Pending_Transition_Action_Disabled_Foreground =>
            return Color (TC_Palette_Muted_Text);
         when TC_Pending_Transition_Destructive_Foreground =>
            return Color (TC_Diagnostic_Error);
         when TC_Problems_Background =>
            return RGB (0.09, 0.09, 0.11);
         when TC_Problems_Header_Background =>
            return RGB (0.12, 0.12, 0.15);
         when TC_Problems_Foreground =>
            return RGB (0.86, 0.86, 0.90);
         when TC_Problems_Error =>
            return RGB (1.0, 0.42, 0.40);
         when TC_Problems_Warning =>
            return RGB (1.0, 0.72, 0.28);
         when TC_Problems_Info =>
            return RGB (0.52, 0.70, 1.0);
         when TC_Problems_Hint =>
            return RGB (0.62, 0.66, 0.72);
         when TC_Problems_Row_Alternate_Background =>
            return RGB (0.11, 0.11, 0.14);
         when TC_Problems_Active_Row_Background =>
            return RGB (0.16, 0.18, 0.24);
         when TC_Problems_Active_Row_Foreground =>
            return RGB (1.0, 1.0, 1.0);
         when TC_Problems_Separator =>
            return RGB (0.24, 0.24, 0.30);
         when TC_Search_Results_Background =>
            return RGB (0.09, 0.09, 0.11);
         when TC_Search_Results_Header_Background =>
            return RGB (0.12, 0.12, 0.15);
         when TC_Search_Results_Foreground =>
            return RGB (0.86, 0.86, 0.90);
         when TC_Search_Results_File_Foreground =>
            return RGB (0.94, 0.94, 0.98);
         when TC_Search_Results_Path_Foreground =>
            return RGB (0.66, 0.70, 0.78);
         when TC_Search_Results_Match_Foreground =>
            return RGB (1.0, 0.86, 0.52);
         when TC_Search_Results_Selected_Background =>
            return RGB (0.20, 0.26, 0.38);
         when TC_Search_Results_Selected_Foreground =>
            return RGB (1.0, 1.0, 1.0);
         when TC_Search_Results_Secondary_Foreground =>
            return RGB (0.60, 0.62, 0.70);
         when TC_Syntax_Plain_Text =>
            return RGB (1.0, 1.0, 1.0);
         when TC_Syntax_Keyword =>
            return RGB (0.55, 0.70, 1.0);
         when TC_Syntax_Identifier =>
            return RGB (0.92, 0.92, 0.92);
         when TC_Syntax_Type_Identifier =>
            return RGB (0.40, 0.86, 0.94);
         when TC_Syntax_Subprogram_Identifier =>
            return RGB (0.96, 0.82, 0.48);
         when TC_Syntax_Package_Identifier =>
            return RGB (0.72, 0.78, 1.0);
         when TC_Syntax_Parameter_Identifier =>
            return RGB (0.88, 0.88, 0.72);
         when TC_Syntax_Number_Literal =>
            return RGB (0.85, 0.65, 1.0);
         when TC_Syntax_String_Literal =>
            return RGB (0.70, 0.90, 0.65);
         when TC_Syntax_Character_Literal =>
            return RGB (0.70, 0.90, 0.65);
         when TC_Syntax_Comment =>
            return RGB (0.50, 0.55, 0.55);
         when TC_Syntax_Operator =>
            return RGB (0.85, 0.85, 0.85);
         when TC_Syntax_Punctuation =>
            return RGB (0.75, 0.75, 0.75);
         when TC_Syntax_Attribute =>
            return RGB (0.90, 0.70, 1.0);
         when TC_Syntax_Aspect_Name =>
            return RGB (0.96, 0.76, 0.55);
         when TC_Syntax_Pragma_Name =>
            return RGB (0.96, 0.76, 0.55);
         when TC_Syntax_Generic_Formal =>
            return RGB (0.88, 0.88, 0.72);
         when TC_Syntax_Diagnostic_Error =>
            return Color (TC_Diagnostic_Error);
         when TC_Syntax_Diagnostic_Warning =>
            return Color (TC_Diagnostic_Warning);
         when TC_Syntax_Search_Match =>
            return Color (TC_Active_Find_Match_Background);
         when TC_Syntax_Selection =>
            return Color (TC_Text_Default);
      end case;
   end Color;

   function Editor_Background return Color_RGB is
   begin
      return Color (TC_Editor_Background);
   end Editor_Background;

   function Gutter_Background return Color_RGB is
   begin
      return Color (TC_Gutter_Background);
   end Gutter_Background;

   function Gutter_Separator return Color_RGB is
   begin
      return Color (TC_Gutter_Separator);
   end Gutter_Separator;

   function Current_Gutter_Row return Color_RGB is
   begin
      return Color (TC_Current_Gutter_Row);
   end Current_Gutter_Row;

   function Inactive_Line_Number return Color_RGB is
   begin
      return Color (TC_Line_Number_Inactive);
   end Inactive_Line_Number;

   function Current_Line_Number return Color_RGB is
   begin
      return Color (TC_Line_Number_Current);
   end Current_Line_Number;

   function Current_Text_Row return Color_RGB is
   begin
      return Color (TC_Current_Text_Row);
   end Current_Text_Row;

   function Selection_Background return Color_RGB is
   begin
      return Color (TC_Selection_Background);
   end Selection_Background;

   function Cursor_Color return Color_RGB is
   begin
      return Color (TC_Caret_Color);
   end Cursor_Color;

   function Text_Default return Color_RGB is
   begin
      return Color (TC_Text_Default);
   end Text_Default;

   function Syntax_Color
     (Kind : Editor.Syntax.Token_Kind) return Color_RGB is
   begin
      case Kind is
         when Editor.Syntax.Plain_Text =>
            return Color (TC_Syntax_Plain_Text);
         when Editor.Syntax.Keyword =>
            return Color (TC_Syntax_Keyword);
         when Editor.Syntax.Identifier =>
            return Color (TC_Syntax_Identifier);
         when Editor.Syntax.Type_Identifier =>
            return Color (TC_Syntax_Type_Identifier);
         when Editor.Syntax.Subprogram_Identifier =>
            return Color (TC_Syntax_Subprogram_Identifier);
         when Editor.Syntax.Package_Identifier =>
            return Color (TC_Syntax_Package_Identifier);
         when Editor.Syntax.Parameter_Identifier =>
            return Color (TC_Syntax_Parameter_Identifier);
         when Editor.Syntax.Number_Literal =>
            return Color (TC_Syntax_Number_Literal);
         when Editor.Syntax.String_Literal =>
            return Color (TC_Syntax_String_Literal);
         when Editor.Syntax.Character_Literal =>
            return Color (TC_Syntax_Character_Literal);
         when Editor.Syntax.Comment =>
            return Color (TC_Syntax_Comment);
         when Editor.Syntax.Operator =>
            return Color (TC_Syntax_Operator);
         when Editor.Syntax.Punctuation =>
            return Color (TC_Syntax_Punctuation);
         when Editor.Syntax.Attribute =>
            return Color (TC_Syntax_Attribute);
         when Editor.Syntax.Aspect_Name =>
            return Color (TC_Syntax_Aspect_Name);
         when Editor.Syntax.Pragma_Name =>
            return Color (TC_Syntax_Pragma_Name);
         when Editor.Syntax.Generic_Formal =>
            return Color (TC_Syntax_Generic_Formal);
         when Editor.Syntax.Diagnostic_Error =>
            return Color (TC_Syntax_Diagnostic_Error);
         when Editor.Syntax.Diagnostic_Warning =>
            return Color (TC_Syntax_Diagnostic_Warning);
         when Editor.Syntax.Search_Match =>
            return Color (TC_Syntax_Search_Match);
         when Editor.Syntax.Selection_Overlay =>
            return Color (TC_Syntax_Selection);
      end case;
   end Syntax_Color;

   function Diagnostic_Color
     (Severity : Editor.Diagnostics.Diagnostic_Severity) return Color_RGB is
   begin
      case Severity is
         when Editor.Diagnostics.Hint =>
            return Color (TC_Diagnostic_Hint);
         when Editor.Diagnostics.Information =>
            return Color (TC_Diagnostic_Information);
         when Editor.Diagnostics.Note =>
            return Color (TC_Diagnostic_Information);
         when Editor.Diagnostics.Unknown =>
            return Color (TC_Diagnostic_Information);
         when Editor.Diagnostics.Warning =>
            return Color (TC_Diagnostic_Warning);
         when Editor.Diagnostics.Error =>
            return Color (TC_Diagnostic_Error);
      end case;
   end Diagnostic_Color;

   function Active_Find_Inactive_Match return Color_RGB is
   begin
      return Color (TC_Active_Find_Inactive_Match_Background);
   end Active_Find_Inactive_Match;

   function Active_Find_Match return Color_RGB is
   begin
      return Color (TC_Active_Find_Match_Background);
   end Active_Find_Match;

   function Minimap_Background return Color_RGB is
   begin
      return Color (TC_Minimap_Background);
   end Minimap_Background;

   function Minimap_Content return Color_RGB is
   begin
      return Color (TC_Minimap_Text_Density);
   end Minimap_Content;

   function Minimap_Viewport return Color_RGB is
   begin
      return Color (TC_Minimap_Viewport);
   end Minimap_Viewport;

   function Scrollbar_Track return Color_RGB is
   begin
      return Color (TC_Scrollbar_Track);
   end Scrollbar_Track;

   function Scrollbar_Thumb return Color_RGB is
   begin
      return Color (TC_Scrollbar_Thumb);
   end Scrollbar_Thumb;

   function Fold_Marker_Color return Color_RGB is
   begin
      return Color (TC_Line_Number_Inactive);
   end Fold_Marker_Color;

   function Folded_Line_Ellipsis_Color return Color_RGB is
   begin
      return Color (TC_Line_Number_Inactive);
   end Folded_Line_Ellipsis_Color;

   function Gutter_Diagnostic_Error return Color_RGB is
   begin
      return Color (TC_Gutter_Diagnostic_Error);
   end Gutter_Diagnostic_Error;

   function Gutter_Diagnostic_Warning return Color_RGB is
   begin
      return Color (TC_Gutter_Diagnostic_Warning);
   end Gutter_Diagnostic_Warning;

   function Gutter_Dirty_Line return Color_RGB is
   begin
      return Color (TC_Gutter_Dirty_Line);
   end Gutter_Dirty_Line;

   function Gutter_Added_Line return Color_RGB is
   begin
      return Color (TC_Gutter_Added_Line);
   end Gutter_Added_Line;

   function Gutter_Modified_Line return Color_RGB is
   begin
      return Color (TC_Gutter_Modified_Line);
   end Gutter_Modified_Line;

   function Gutter_Deleted_Line return Color_RGB is
   begin
      return Color (TC_Gutter_Deleted_Line);
   end Gutter_Deleted_Line;

   function Gutter_Bookmark return Color_RGB is
   begin
      return Color (TC_Gutter_Bookmark);
   end Gutter_Bookmark;

   function Gutter_Marker_Hover_Background return Color_RGB is
   begin
      return Color (TC_Gutter_Marker_Hover_Background);
   end Gutter_Marker_Hover_Background;

   function Gutter_Marker_Hover_Outline return Color_RGB is
   begin
      return Color (TC_Gutter_Marker_Hover_Outline);
   end Gutter_Marker_Hover_Outline;

   function Scrollbar_Thumb_Hover return Color_RGB is
   begin
      return Color (TC_Scrollbar_Thumb_Hover);
   end Scrollbar_Thumb_Hover;

   function Scrollbar_Thumb_Active return Color_RGB is
   begin
      return Color (TC_Scrollbar_Thumb_Active);
   end Scrollbar_Thumb_Active;

   function Palette_Background return Color_RGB is
   begin
      return Color (TC_Palette_Background);
   end Palette_Background;

   function Palette_Text return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Palette_Text;

   function Palette_Muted_Text return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Palette_Muted_Text;

   function Palette_Selected_Row return Color_RGB is
   begin
      return Color (TC_Palette_Selected_Row);
   end Palette_Selected_Row;

   function Command_Palette_Disabled_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Disabled_Foreground;

   function Command_Palette_Disabled_Selected_Background return Color_RGB is
   begin
      return Color (TC_Palette_Selected_Row);
   end Command_Palette_Disabled_Selected_Background;

   function Command_Palette_Reason_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Reason_Foreground;

   function Command_Palette_Detail_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Detail_Foreground;

   function Command_Palette_Help_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Help_Foreground;

   function Command_Palette_Secondary_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Secondary_Foreground;

   function Command_Palette_Keybinding_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Keybinding_Foreground;

   function Command_Palette_Keybinding_Selected_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Command_Palette_Keybinding_Selected_Foreground;

   function Command_Palette_Keybinding_Disabled_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Command_Palette_Keybinding_Disabled_Foreground;

   function Status_Bar_Background return Color_RGB is
   begin
      return Color (TC_Status_Bar_Background);
   end Status_Bar_Background;

   function Status_Bar_Foreground return Color_RGB is
   begin
      return Color (TC_Status_Bar_Foreground);
   end Status_Bar_Foreground;

   function Status_Bar_Separator return Color_RGB is
   begin
      return Color (TC_Status_Bar_Separator);
   end Status_Bar_Separator;

   function Status_Bar_Dirty return Color_RGB is
   begin
      return Color (TC_Status_Bar_Dirty);
   end Status_Bar_Dirty;

   function Tab_Bar_Background return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Background);
   end Tab_Bar_Background;

   function Tab_Bar_Active_Background return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Active_Background);
   end Tab_Bar_Active_Background;

   function Tab_Bar_Inactive_Background return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Inactive_Background);
   end Tab_Bar_Inactive_Background;

   function Tab_Bar_Active_Foreground return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Active_Foreground);
   end Tab_Bar_Active_Foreground;

   function Tab_Bar_Inactive_Foreground return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Inactive_Foreground);
   end Tab_Bar_Inactive_Foreground;

   function Tab_Bar_Dirty return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Dirty);
   end Tab_Bar_Dirty;

   function Tab_Bar_Border return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Border);
   end Tab_Bar_Border;

   function Tab_Bar_Close return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Close);
   end Tab_Bar_Close;


   function Panel_Background return Color_RGB is
   begin
      return Color (TC_File_Tree_Background);
   end Panel_Background;

   function Panel_Splitter return Color_RGB is
   begin
      return Color (TC_File_Tree_Splitter);
   end Panel_Splitter;

   function Panel_Splitter_Active return Color_RGB is
   begin
      return Color (TC_File_Tree_Splitter_Active);
   end Panel_Splitter_Active;

   function File_Tree_Background return Color_RGB is
   begin
      return Color (TC_File_Tree_Background);
   end File_Tree_Background;

   function File_Tree_Foreground return Color_RGB is
   begin
      return Color (TC_File_Tree_Foreground);
   end File_Tree_Foreground;

   function File_Tree_Directory_Foreground return Color_RGB is
   begin
      return Color (TC_File_Tree_Directory_Foreground);
   end File_Tree_Directory_Foreground;

   function File_Tree_Active_Background return Color_RGB is
   begin
      return Color (TC_File_Tree_Active_Background);
   end File_Tree_Active_Background;

   function File_Tree_Active_Foreground return Color_RGB is
   begin
      return Color (TC_File_Tree_Active_Foreground);
   end File_Tree_Active_Foreground;

   function File_Tree_Selected_Active_Background return Color_RGB is
   begin
      return Color (TC_File_Tree_Selected_Active_Background);
   end File_Tree_Selected_Active_Background;

   function File_Tree_Selected_Active_Foreground return Color_RGB is
   begin
      return Color (TC_File_Tree_Selected_Active_Foreground);
   end File_Tree_Selected_Active_Foreground;

   function File_Tree_Selected_Inactive_Background return Color_RGB is
   begin
      return Color (TC_File_Tree_Selected_Inactive_Background);
   end File_Tree_Selected_Inactive_Background;

   function File_Tree_Selected_Inactive_Foreground return Color_RGB is
   begin
      return Color (TC_File_Tree_Selected_Inactive_Foreground);
   end File_Tree_Selected_Inactive_Foreground;

   function File_Tree_Focused_Border return Color_RGB is
   begin
      return Color (TC_File_Tree_Focused_Border);
   end File_Tree_Focused_Border;

   function File_Tree_Separator return Color_RGB is
   begin
      return Color (TC_File_Tree_Separator);
   end File_Tree_Separator;

   function File_Tree_Splitter return Color_RGB is
   begin
      return Color (TC_File_Tree_Splitter);
   end File_Tree_Splitter;

   function File_Tree_Splitter_Active return Color_RGB is
   begin
      return Color (TC_File_Tree_Splitter_Active);
   end File_Tree_Splitter_Active;

   function File_Tree_Indent_Guide return Color_RGB is
   begin
      return Color (TC_File_Tree_Indent_Guide);
   end File_Tree_Indent_Guide;

   function Message_Info_Background return Color_RGB is
   begin
      return Color (TC_Message_Info_Background);
   end Message_Info_Background;

   function Message_Info_Foreground return Color_RGB is
   begin
      return Color (TC_Message_Info_Foreground);
   end Message_Info_Foreground;

   function Message_Success_Background return Color_RGB is
   begin
      return Color (TC_Message_Success_Background);
   end Message_Success_Background;

   function Message_Success_Foreground return Color_RGB is
   begin
      return Color (TC_Message_Success_Foreground);
   end Message_Success_Foreground;

   function Message_Warning_Background return Color_RGB is
   begin
      return Color (TC_Message_Warning_Background);
   end Message_Warning_Background;

   function Message_Warning_Foreground return Color_RGB is
   begin
      return Color (TC_Message_Warning_Foreground);
   end Message_Warning_Foreground;

   function Message_Error_Background return Color_RGB is
   begin
      return Color (TC_Message_Error_Background);
   end Message_Error_Background;

   function Message_Error_Foreground return Color_RGB is
   begin
      return Color (TC_Message_Error_Foreground);
   end Message_Error_Foreground;

   function Pending_Transition_Background return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Background);
   end Pending_Transition_Background;

   function Pending_Transition_Foreground return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Foreground);
   end Pending_Transition_Foreground;

   function Pending_Transition_Accent return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Accent);
   end Pending_Transition_Accent;

   function Pending_Transition_Action_Foreground return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Action_Foreground);
   end Pending_Transition_Action_Foreground;

   function Pending_Transition_Action_Disabled_Foreground return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Action_Disabled_Foreground);
   end Pending_Transition_Action_Disabled_Foreground;

   function Pending_Transition_Destructive_Foreground return Color_RGB is
   begin
      return Color (TC_Pending_Transition_Destructive_Foreground);
   end Pending_Transition_Destructive_Foreground;


   function Problems_Background return Color_RGB is
   begin
      return Color (TC_Problems_Background);
   end Problems_Background;

   function Problems_Header_Background return Color_RGB is
   begin
      return Color (TC_Problems_Header_Background);
   end Problems_Header_Background;

   function Problems_Foreground return Color_RGB is
   begin
      return Color (TC_Problems_Foreground);
   end Problems_Foreground;

   function Problems_Error return Color_RGB is
   begin
      return Color (TC_Problems_Error);
   end Problems_Error;

   function Problems_Warning return Color_RGB is
   begin
      return Color (TC_Problems_Warning);
   end Problems_Warning;

   function Problems_Info return Color_RGB is
   begin
      return Color (TC_Problems_Info);
   end Problems_Info;

   function Problems_Hint return Color_RGB is
   begin
      return Color (TC_Problems_Hint);
   end Problems_Hint;

   function Problems_Row_Alternate_Background return Color_RGB is
   begin
      return Color (TC_Problems_Row_Alternate_Background);
   end Problems_Row_Alternate_Background;

   function Problems_Active_Row_Background return Color_RGB is
   begin
      return Color (TC_Problems_Active_Row_Background);
   end Problems_Active_Row_Background;

   function Problems_Active_Row_Foreground return Color_RGB is
   begin
      return Color (TC_Problems_Active_Row_Foreground);
   end Problems_Active_Row_Foreground;

   function Problems_Selected_Active_Background return Color_RGB is
   begin
      return Problems_Active_Row_Background;
   end Problems_Selected_Active_Background;

   function Problems_Selected_Active_Foreground return Color_RGB is
   begin
      return Problems_Active_Row_Foreground;
   end Problems_Selected_Active_Foreground;

   function Problems_Selected_Inactive_Background return Color_RGB is
   begin
      return Problems_Row_Alternate_Background;
   end Problems_Selected_Inactive_Background;

   function Problems_Selected_Inactive_Foreground return Color_RGB is
   begin
      return Problems_Foreground;
   end Problems_Selected_Inactive_Foreground;

   function Problems_Focused_Border return Color_RGB is
   begin
      return Panel_Focus_Border;
   end Problems_Focused_Border;

   function Problems_Separator return Color_RGB is
   begin
      return Color (TC_Problems_Separator);
   end Problems_Separator;


   function Active_Find_Prompt_Background return Color_RGB is
   begin
      return Color (TC_Palette_Background);
   end Active_Find_Prompt_Background;

   function Active_Find_Prompt_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Active_Find_Prompt_Foreground;

   function Active_Find_Prompt_Field_Background return Color_RGB is
   begin
      return Color (TC_Editor_Background);
   end Active_Find_Prompt_Field_Background;

   function Active_Find_Prompt_Field_Foreground return Color_RGB is
   begin
      return Color (TC_Text_Default);
   end Active_Find_Prompt_Field_Foreground;

   function Active_Find_Prompt_Field_Active_Border return Color_RGB is
   begin
      return Color (TC_Active_Find_Match_Background);
   end Active_Find_Prompt_Field_Active_Border;

   function Active_Find_Prompt_Button_Background return Color_RGB is
   begin
      return Color (TC_Palette_Selected_Row);
   end Active_Find_Prompt_Button_Background;

   function Active_Find_Prompt_Button_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Active_Find_Prompt_Button_Foreground;

   function Active_Find_Prompt_No_Match_Foreground return Color_RGB is
   begin
      return Color (TC_Diagnostic_Error);
   end Active_Find_Prompt_No_Match_Foreground;

   function Active_Find_Prompt_Caret return Color_RGB is
   begin
      return Color (TC_Caret_Color);
   end Active_Find_Prompt_Caret;

   function Quick_Open_Background return Color_RGB is
   begin
      return Color (TC_Palette_Background);
   end Quick_Open_Background;

   function Quick_Open_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Quick_Open_Foreground;

   function Quick_Open_Border return Color_RGB is
   begin
      return Color (TC_Tab_Bar_Border);
   end Quick_Open_Border;

   function Quick_Open_Field_Background return Color_RGB is
   begin
      return Color (TC_Editor_Background);
   end Quick_Open_Field_Background;

   function Quick_Open_Field_Foreground return Color_RGB is
   begin
      return Color (TC_Text_Default);
   end Quick_Open_Field_Foreground;

   function Quick_Open_Selected_Background return Color_RGB is
   begin
      return Color (TC_Palette_Selected_Row);
   end Quick_Open_Selected_Background;

   function Quick_Open_Selected_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Text);
   end Quick_Open_Selected_Foreground;

   function Quick_Open_Match_Foreground return Color_RGB is
   begin
      return Color (TC_Active_Find_Match_Background);
   end Quick_Open_Match_Foreground;

   function Quick_Open_Secondary_Foreground return Color_RGB is
   begin
      return Color (TC_Palette_Muted_Text);
   end Quick_Open_Secondary_Foreground;

   function Quick_Open_Caret return Color_RGB is
   begin
      return Color (TC_Caret_Color);
   end Quick_Open_Caret;



   function Project_Search_Bar_Background return Color_RGB is
   begin
      return Quick_Open_Background;
   end Project_Search_Bar_Background;

   function Project_Search_Bar_Foreground return Color_RGB is
   begin
      return Quick_Open_Foreground;
   end Project_Search_Bar_Foreground;

   function Project_Search_Bar_Border return Color_RGB is
   begin
      return Quick_Open_Border;
   end Project_Search_Bar_Border;

   function Project_Search_Bar_Field_Background return Color_RGB is
   begin
      return Quick_Open_Field_Background;
   end Project_Search_Bar_Field_Background;

   function Project_Search_Bar_Field_Foreground return Color_RGB is
   begin
      return Quick_Open_Field_Foreground;
   end Project_Search_Bar_Field_Foreground;

   function Project_Search_Bar_Field_Active_Border return Color_RGB is
   begin
      return Active_Find_Prompt_Field_Active_Border;
   end Project_Search_Bar_Field_Active_Border;

   function Project_Search_Bar_Button_Background return Color_RGB is
   begin
      return Active_Find_Prompt_Button_Background;
   end Project_Search_Bar_Button_Background;

   function Project_Search_Bar_Button_Foreground return Color_RGB is
   begin
      return Active_Find_Prompt_Button_Foreground;
   end Project_Search_Bar_Button_Foreground;

   function Project_Search_Bar_Status_Foreground return Color_RGB is
   begin
      return Quick_Open_Secondary_Foreground;
   end Project_Search_Bar_Status_Foreground;

   function Project_Search_Bar_Caret return Color_RGB is
   begin
      return Quick_Open_Caret;
   end Project_Search_Bar_Caret;

   function Search_Results_Background return Color_RGB is
   begin
      return Color (TC_Search_Results_Background);
   end Search_Results_Background;

   function Search_Results_Header_Background return Color_RGB is
   begin
      return Color (TC_Search_Results_Header_Background);
   end Search_Results_Header_Background;

   function Search_Results_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Foreground);
   end Search_Results_Foreground;

   function Search_Results_File_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_File_Foreground);
   end Search_Results_File_Foreground;

   function Search_Results_Path_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Path_Foreground);
   end Search_Results_Path_Foreground;

   function Search_Results_Match_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Match_Foreground);
   end Search_Results_Match_Foreground;

   function Search_Results_Selected_Background return Color_RGB is
   begin
      return Color (TC_Search_Results_Selected_Background);
   end Search_Results_Selected_Background;

   function Search_Results_Selected_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Selected_Foreground);
   end Search_Results_Selected_Foreground;

   function Search_Results_Selected_Active_Background return Color_RGB is
   begin
      return Search_Results_Selected_Background;
   end Search_Results_Selected_Active_Background;

   function Search_Results_Selected_Active_Foreground return Color_RGB is
   begin
      return Search_Results_Selected_Foreground;
   end Search_Results_Selected_Active_Foreground;

   function Search_Results_Selected_Inactive_Background return Color_RGB is
   begin
      return Color (TC_Problems_Active_Row_Background);
   end Search_Results_Selected_Inactive_Background;

   function Search_Results_Selected_Inactive_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Foreground);
   end Search_Results_Selected_Inactive_Foreground;

   function Panel_Focus_Border return Color_RGB is
   begin
      return Project_Search_Bar_Field_Active_Border;
   end Panel_Focus_Border;

   function Search_Results_Secondary_Foreground return Color_RGB is
   begin
      return Color (TC_Search_Results_Secondary_Foreground);
   end Search_Results_Secondary_Foreground;

   function Diagnostic_Underline_Height return Float is
   begin
      return 2.0;
   end Diagnostic_Underline_Height;

   function Diagnostic_Underline_Bottom_Padding return Float is
   begin
      return 3.0;
   end Diagnostic_Underline_Bottom_Padding;

   function Minimap_Content_Padding return Float is
   begin
      return 2.0;
   end Minimap_Content_Padding;

   function Minimap_Min_Line_Width return Float is
   begin
      return 2.0;
   end Minimap_Min_Line_Width;

   function Minimap_Content_Line_Height return Float is
   begin
      return 1.0;
   end Minimap_Content_Line_Height;

   function Minimap_Max_Line_Length_For_Scale return Natural is
   begin
      return 120;
   end Minimap_Max_Line_Length_For_Scale;

   function Palette_Margin return Natural is
   begin
      return 32;
   end Palette_Margin;

   function Palette_Max_Width return Natural is
   begin
      return 600;
   end Palette_Max_Width;

   function Palette_Top_Min_Offset return Float is
   begin
      return 32.0;
   end Palette_Top_Min_Offset;

   function Palette_Top_Fraction return Float is
   begin
      return 0.10;
   end Palette_Top_Fraction;

   function Palette_Outer_Padding_Y return Natural is
   begin
      return 16;
   end Palette_Outer_Padding_Y;

   function Palette_Text_Padding_X return Float is
   begin
      return 12.0;
   end Palette_Text_Padding_X;

   function Palette_Text_Padding_Y return Float is
   begin
      return 8.0;
   end Palette_Text_Padding_Y;

   function Palette_Selected_Row_Inset_X return Float is
   begin
      return 6.0;
   end Palette_Selected_Row_Inset_X;

   function Palette_Selected_Row_Offset_Y return Float is
   begin
      return 2.0;
   end Palette_Selected_Row_Offset_Y;

   function Active_Find_Inactive_Match_Color return Color_RGB is
   begin
      return Active_Find_Inactive_Match;
   end Active_Find_Inactive_Match_Color;

   function Active_Find_Match_Color return Color_RGB is
   begin
      return Active_Find_Match;
   end Active_Find_Match_Color;

   function Palette_Background_Color return Color_RGB is
   begin
      return Palette_Background;
   end Palette_Background_Color;

   function Palette_Text_Color return Color_RGB is
   begin
      return Palette_Text;
   end Palette_Text_Color;

   function Palette_Selected_Row_Color return Color_RGB is
   begin
      return Palette_Selected_Row;
   end Palette_Selected_Row_Color;

   function Palette_Muted_Text_Color return Color_RGB is
   begin
      return Palette_Muted_Text;
   end Palette_Muted_Text_Color;

end Editor.Theme;
