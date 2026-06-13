with Editor.Syntax;
with Editor.Diagnostics;

package Editor.Theme is

   --  RGB colour in normalized renderer channel space.
   --
   --  Each channel must remain in 0.0 .. 1.0.  The render packet passes these
   --  values directly to the C/Vulkan renderer.
   type Color_RGB is record
      R : Float;
      G : Float;
      B : Float;
   end record;


   function RGB (R, G, B : Float) return Color_RGB;

   --  Return the stable id of the active built-in theme.
   function Active_Theme_Id return String;

   --  Return True when Id names a built-in theme accepted by settings.
   function Is_Valid_Theme_Id (Id : String) return Boolean;

   --  Select a built-in theme by stable id.
   procedure Set_Theme_By_Id (Id : String; Found : out Boolean);

   --  Cycle between the stable built-in theme ids exposed as commands.
   procedure Toggle_Theme;

   --  Semantic editor colour slots used by the in-code default theme.
   --
   --  Rendering code should request one of these semantic colours instead of
   --  owning hardcoded RGB literals.  External theme loading and multiple theme
   --  variants are intentionally out of scope for the current renderer slice.
   type Theme_Color is
     (TC_Editor_Background,
      TC_Gutter_Background,
      TC_Gutter_Separator,
      TC_Current_Text_Row,
      TC_Current_Gutter_Row,
      TC_Active_Find_Inactive_Match_Background,
      TC_Active_Find_Match_Background,
      TC_Selection_Background,
      TC_Caret_Color,
      TC_Text_Default,
      TC_Line_Number_Inactive,
      TC_Line_Number_Current,
      TC_Diagnostic_Hint,
      TC_Diagnostic_Information,
      TC_Diagnostic_Warning,
      TC_Diagnostic_Error,
      TC_Gutter_Diagnostic_Error,
      TC_Gutter_Diagnostic_Warning,
      TC_Gutter_Dirty_Line,
      TC_Gutter_Added_Line,
      TC_Gutter_Modified_Line,
      TC_Gutter_Deleted_Line,
      TC_Gutter_Bookmark,
      TC_Gutter_Marker_Hover_Background,
      TC_Gutter_Marker_Hover_Outline,
      TC_Minimap_Background,
      TC_Minimap_Text_Density,
      TC_Minimap_Viewport,
      TC_Scrollbar_Track,
      TC_Scrollbar_Thumb,
      TC_Scrollbar_Thumb_Hover,
      TC_Scrollbar_Thumb_Active,
      TC_Palette_Background,
      TC_Palette_Text,
      TC_Palette_Selected_Row,
      TC_Palette_Muted_Text,
      TC_Status_Bar_Background,
      TC_Status_Bar_Foreground,
      TC_Status_Bar_Separator,
      TC_Status_Bar_Dirty,
      TC_Tab_Bar_Background,
      TC_Tab_Bar_Active_Background,
      TC_Tab_Bar_Inactive_Background,
      TC_Tab_Bar_Active_Foreground,
      TC_Tab_Bar_Inactive_Foreground,
      TC_Tab_Bar_Dirty,
      TC_Tab_Bar_Border,
      TC_Tab_Bar_Close,
      TC_File_Tree_Background,
      TC_File_Tree_Foreground,
      TC_File_Tree_Directory_Foreground,
      TC_File_Tree_Active_Background,
      TC_File_Tree_Active_Foreground,
      TC_File_Tree_Selected_Active_Background,
      TC_File_Tree_Selected_Active_Foreground,
      TC_File_Tree_Selected_Inactive_Background,
      TC_File_Tree_Selected_Inactive_Foreground,
      TC_File_Tree_Focused_Border,
      TC_File_Tree_Separator,
      TC_File_Tree_Splitter,
      TC_File_Tree_Splitter_Active,
      TC_File_Tree_Indent_Guide,
      TC_Message_Info_Background,
      TC_Message_Info_Foreground,
      TC_Message_Success_Background,
      TC_Message_Success_Foreground,
      TC_Message_Warning_Background,
      TC_Message_Warning_Foreground,
      TC_Message_Error_Background,
      TC_Message_Error_Foreground,
      TC_Pending_Transition_Background,
      TC_Pending_Transition_Foreground,
      TC_Pending_Transition_Accent,
      TC_Pending_Transition_Action_Foreground,
      TC_Pending_Transition_Action_Disabled_Foreground,
      TC_Pending_Transition_Destructive_Foreground,
      TC_Problems_Background,
      TC_Problems_Header_Background,
      TC_Problems_Foreground,
      TC_Problems_Error,
      TC_Problems_Warning,
      TC_Problems_Info,
      TC_Problems_Hint,
      TC_Problems_Row_Alternate_Background,
      TC_Problems_Active_Row_Background,
      TC_Problems_Active_Row_Foreground,
      TC_Problems_Separator,
      TC_Search_Results_Background,
      TC_Search_Results_Header_Background,
      TC_Search_Results_Foreground,
      TC_Search_Results_File_Foreground,
      TC_Search_Results_Path_Foreground,
      TC_Search_Results_Match_Foreground,
      TC_Search_Results_Selected_Background,
      TC_Search_Results_Selected_Foreground,
      TC_Search_Results_Secondary_Foreground,
      TC_Syntax_Plain_Text,
      TC_Syntax_Keyword,
      TC_Syntax_Identifier,
      TC_Syntax_Type_Identifier,
      TC_Syntax_Subprogram_Identifier,
      TC_Syntax_Package_Identifier,
      TC_Syntax_Parameter_Identifier,
      TC_Syntax_Number_Literal,
      TC_Syntax_String_Literal,
      TC_Syntax_Character_Literal,
      TC_Syntax_Comment,
      TC_Syntax_Operator,
      TC_Syntax_Punctuation,
      TC_Syntax_Attribute,
      TC_Syntax_Aspect_Name,
      TC_Syntax_Pragma_Name,
      TC_Syntax_Generic_Formal,
      TC_Syntax_Diagnostic_Error,
      TC_Syntax_Diagnostic_Warning,
      TC_Syntax_Search_Match,
      TC_Syntax_Selection);

   --  Return the RGB value for a semantic theme colour.
   function Color
     (Kind : Theme_Color) return Color_RGB;

   function Editor_Background return Color_RGB;
   function Gutter_Background return Color_RGB;
   function Gutter_Separator return Color_RGB;
   function Current_Gutter_Row return Color_RGB;
   function Inactive_Line_Number return Color_RGB;
   function Current_Line_Number return Color_RGB;
   function Current_Text_Row return Color_RGB;
   function Selection_Background return Color_RGB;
   function Cursor_Color return Color_RGB;
   function Text_Default return Color_RGB;

   --  Map a syntax classification to its semantic syntax colour.
   --
   --  Theme may depend on Syntax for this mapping.  Syntax must remain
   --  independent of Theme.
   function Syntax_Color
     (Kind : Editor.Syntax.Token_Kind) return Color_RGB;

   function Diagnostic_Color
     (Severity : Editor.Diagnostics.Diagnostic_Severity) return Color_RGB;

   function Active_Find_Inactive_Match return Color_RGB;
   function Active_Find_Match return Color_RGB;
   function Minimap_Background return Color_RGB;
   function Minimap_Content return Color_RGB;
   function Minimap_Viewport return Color_RGB;
   function Scrollbar_Track return Color_RGB;
   function Scrollbar_Thumb return Color_RGB;
   function Fold_Marker_Color return Color_RGB;
   function Folded_Line_Ellipsis_Color return Color_RGB;
   function Gutter_Diagnostic_Error return Color_RGB;
   function Gutter_Diagnostic_Warning return Color_RGB;
   function Gutter_Dirty_Line return Color_RGB;
   function Gutter_Added_Line return Color_RGB;
   function Gutter_Modified_Line return Color_RGB;
   function Gutter_Deleted_Line return Color_RGB;
   function Gutter_Bookmark return Color_RGB;
   function Gutter_Marker_Hover_Background return Color_RGB;
   function Gutter_Marker_Hover_Outline return Color_RGB;
   function Scrollbar_Thumb_Hover return Color_RGB;
   function Scrollbar_Thumb_Active return Color_RGB;
   function Palette_Background return Color_RGB;
   function Palette_Text return Color_RGB;
   function Palette_Muted_Text return Color_RGB;
   function Palette_Selected_Row return Color_RGB;
   function Command_Palette_Disabled_Foreground return Color_RGB;
   function Command_Palette_Disabled_Selected_Background return Color_RGB;
   function Command_Palette_Reason_Foreground return Color_RGB;
   function Command_Palette_Detail_Foreground return Color_RGB;
   function Command_Palette_Help_Foreground return Color_RGB;
   function Command_Palette_Secondary_Foreground return Color_RGB;
   function Command_Palette_Keybinding_Foreground return Color_RGB;
   function Command_Palette_Keybinding_Selected_Foreground return Color_RGB;
   function Command_Palette_Keybinding_Disabled_Foreground return Color_RGB;
   function Status_Bar_Background return Color_RGB;
   function Status_Bar_Foreground return Color_RGB;
   function Status_Bar_Separator return Color_RGB;
   function Status_Bar_Dirty return Color_RGB;
   function Tab_Bar_Background return Color_RGB;
   function Tab_Bar_Active_Background return Color_RGB;
   function Tab_Bar_Inactive_Background return Color_RGB;
   function Tab_Bar_Active_Foreground return Color_RGB;
   function Tab_Bar_Inactive_Foreground return Color_RGB;
   function Tab_Bar_Dirty return Color_RGB;
   function Tab_Bar_Border return Color_RGB;
   function Tab_Bar_Close return Color_RGB;
   function Panel_Background return Color_RGB;
   function Panel_Splitter return Color_RGB;
   function Panel_Splitter_Active return Color_RGB;
   function File_Tree_Background return Color_RGB;
   function File_Tree_Foreground return Color_RGB;
   function File_Tree_Directory_Foreground return Color_RGB;
   function File_Tree_Active_Background return Color_RGB;
   function File_Tree_Active_Foreground return Color_RGB;
   function File_Tree_Selected_Active_Background return Color_RGB;
   function File_Tree_Selected_Active_Foreground return Color_RGB;
   function File_Tree_Selected_Inactive_Background return Color_RGB;
   function File_Tree_Selected_Inactive_Foreground return Color_RGB;
   function File_Tree_Focused_Border return Color_RGB;
   function File_Tree_Separator return Color_RGB;
   function File_Tree_Splitter return Color_RGB;
   function File_Tree_Splitter_Active return Color_RGB;
   function File_Tree_Indent_Guide return Color_RGB;
   function Message_Info_Background return Color_RGB;
   function Message_Info_Foreground return Color_RGB;
   function Message_Success_Background return Color_RGB;
   function Message_Success_Foreground return Color_RGB;
   function Message_Warning_Background return Color_RGB;
   function Message_Warning_Foreground return Color_RGB;
   function Message_Error_Background return Color_RGB;
   function Message_Error_Foreground return Color_RGB;
   function Pending_Transition_Background return Color_RGB;
   function Pending_Transition_Foreground return Color_RGB;
   function Pending_Transition_Accent return Color_RGB;
   function Pending_Transition_Action_Foreground return Color_RGB;
   function Pending_Transition_Action_Disabled_Foreground return Color_RGB;
   function Pending_Transition_Destructive_Foreground return Color_RGB;
   function Problems_Background return Color_RGB;
   function Problems_Header_Background return Color_RGB;
   function Problems_Foreground return Color_RGB;
   function Problems_Error return Color_RGB;
   function Problems_Warning return Color_RGB;
   function Problems_Info return Color_RGB;
   function Problems_Hint return Color_RGB;
   function Problems_Row_Alternate_Background return Color_RGB;
   function Problems_Active_Row_Background return Color_RGB;
   function Problems_Active_Row_Foreground return Color_RGB;
   function Problems_Selected_Active_Background return Color_RGB;
   function Problems_Selected_Active_Foreground return Color_RGB;
   function Problems_Selected_Inactive_Background return Color_RGB;
   function Problems_Selected_Inactive_Foreground return Color_RGB;
   function Problems_Focused_Border return Color_RGB;
   function Problems_Separator return Color_RGB;

   function Active_Find_Prompt_Background return Color_RGB;
   function Active_Find_Prompt_Foreground return Color_RGB;
   function Active_Find_Prompt_Field_Background return Color_RGB;
   function Active_Find_Prompt_Field_Foreground return Color_RGB;
   function Active_Find_Prompt_Field_Active_Border return Color_RGB;
   function Active_Find_Prompt_Button_Background return Color_RGB;
   function Active_Find_Prompt_Button_Foreground return Color_RGB;
   function Active_Find_Prompt_No_Match_Foreground return Color_RGB;
   function Active_Find_Prompt_Caret return Color_RGB;
   function Quick_Open_Background return Color_RGB;
   function Quick_Open_Foreground return Color_RGB;
   function Quick_Open_Border return Color_RGB;
   function Quick_Open_Field_Background return Color_RGB;
   function Quick_Open_Field_Foreground return Color_RGB;
   function Quick_Open_Selected_Background return Color_RGB;
   function Quick_Open_Selected_Foreground return Color_RGB;
   function Quick_Open_Match_Foreground return Color_RGB;
   function Quick_Open_Secondary_Foreground return Color_RGB;
   function Quick_Open_Caret return Color_RGB;
   function Project_Search_Bar_Background return Color_RGB;
   function Project_Search_Bar_Foreground return Color_RGB;
   function Project_Search_Bar_Border return Color_RGB;
   function Project_Search_Bar_Field_Background return Color_RGB;
   function Project_Search_Bar_Field_Foreground return Color_RGB;
   function Project_Search_Bar_Field_Active_Border return Color_RGB;
   function Project_Search_Bar_Button_Background return Color_RGB;
   function Project_Search_Bar_Button_Foreground return Color_RGB;
   function Project_Search_Bar_Status_Foreground return Color_RGB;
   function Project_Search_Bar_Caret return Color_RGB;
   function Search_Results_Background return Color_RGB;
   function Search_Results_Header_Background return Color_RGB;
   function Search_Results_Foreground return Color_RGB;
   function Search_Results_File_Foreground return Color_RGB;
   function Search_Results_Path_Foreground return Color_RGB;
   function Search_Results_Match_Foreground return Color_RGB;
   function Search_Results_Selected_Background return Color_RGB;
   function Search_Results_Selected_Foreground return Color_RGB;
   function Search_Results_Selected_Active_Background return Color_RGB;
   function Search_Results_Selected_Active_Foreground return Color_RGB;
   function Search_Results_Selected_Inactive_Background return Color_RGB;
   function Search_Results_Selected_Inactive_Foreground return Color_RGB;
   function Panel_Focus_Border return Color_RGB;
   function Search_Results_Secondary_Foreground return Color_RGB;


   --  Small default-theme style constants.
   --
   --  These are visual tuning knobs, not layout ownership.  Layout remains in
   --  Editor.Layout; Theme only owns the small stylistic offsets/thicknesses
   --  that determine how a visual decoration looks.
   function Diagnostic_Underline_Height return Float;
   function Diagnostic_Underline_Bottom_Padding return Float;

   function Minimap_Content_Padding return Float;
   function Minimap_Min_Line_Width return Float;
   function Minimap_Content_Line_Height return Float;
   function Minimap_Max_Line_Length_For_Scale return Natural;

   function Palette_Margin return Natural;
   function Palette_Max_Width return Natural;
   function Palette_Top_Min_Offset return Float;
   function Palette_Top_Fraction return Float;
   function Palette_Outer_Padding_Y return Natural;
   function Palette_Text_Padding_X return Float;
   function Palette_Text_Padding_Y return Float;
   function Palette_Selected_Row_Inset_X return Float;
   function Palette_Selected_Row_Offset_Y return Float;

   --  Semantic colour convenience accessors used by render-packet code.
   function Active_Find_Inactive_Match_Color return Color_RGB;
   function Active_Find_Match_Color return Color_RGB;
   function Palette_Background_Color return Color_RGB;
   function Palette_Text_Color return Color_RGB;
   function Palette_Selected_Row_Color return Color_RGB;
   function Palette_Muted_Text_Color return Color_RGB;

end Editor.Theme;
