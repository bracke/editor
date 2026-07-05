with Interfaces.C;

package Editor.Render_Layers is

   --  Semantic render layers.  Order and To_C define the C ABI value and
   --  draw order: lower values are drawn first, higher values are drawn later.
   --
   --  Keep this list synchronized with src/runtime/editor_bridge.h.
   type Render_Layer is
     (Background_Layer,
      Tab_Bar_Background_Layer,
      Tab_Bar_Tab_Layer,
      Tab_Bar_Dirty_Layer,
      Tab_Bar_Close_Layer,
      Tab_Bar_Text_Layer,
      File_Tree_Background_Layer,
      File_Tree_Row_Highlight_Layer,
      File_Tree_Indent_Guide_Layer,
      File_Tree_Text_Layer,
      File_Tree_Separator_Layer,
      File_Tree_Splitter_Layer,
      Gutter_Background_Layer,
      Current_Line_Layer,
      Active_Find_Match_Layer,
      Selection_Layer,
      Gutter_Separator_Layer,
      Gutter_Text_Layer,
      Gutter_Marker_Layer,
      Gutter_Marker_Hover_Layer,
      Fold_Marker_Layer,
      Diagnostic_Layer,
      Text_Layer,
      Caret_Layer,
      Minimap_Background_Layer,
      Minimap_Content_Layer,
      Minimap_Viewport_Layer,
      Scrollbar_Track_Layer,
      Scrollbar_Thumb_Layer,
      Problems_Background_Layer,
      Problems_Header_Layer,
      Problems_Row_Layer,
      Problems_Severity_Layer,
      Problems_Text_Layer,
      Build_UI_Background_Layer,
      Build_UI_Header_Layer,
      Build_UI_Row_Layer,
      Build_UI_Text_Layer,
      Status_Bar_Background_Layer,
      Status_Bar_Text_Layer,
      Active_Find_Prompt_Background_Layer,
      Active_Find_Prompt_Field_Layer,
      Active_Find_Prompt_Button_Layer,
      Active_Find_Prompt_Text_Layer,
      Active_Find_Prompt_Caret_Layer,
      Semantic_Popup_Background_Layer,
      Semantic_Popup_Row_Layer,
      Semantic_Popup_Text_Layer,
      Quick_Open_Background_Layer,
      Quick_Open_Field_Layer,
      Quick_Open_Result_Layer,
      Quick_Open_Selected_Result_Layer,
      Quick_Open_Text_Layer,
      Quick_Open_Caret_Layer,
      Project_Search_Bar_Background_Layer,
      Project_Search_Bar_Field_Layer,
      Project_Search_Bar_Button_Layer,
      Project_Search_Bar_Text_Layer,
      Project_Search_Bar_Caret_Layer,
      Pending_Transition_Background_Layer,
      Pending_Transition_Text_Layer,
      Pending_Transition_Action_Layer,
      Message_Background_Layer,
      Message_Text_Layer,
      Palette_Background_Layer,
      Palette_Selection_Layer,
      Palette_Text_Layer);

   First_Render_Layer : constant Render_Layer := Render_Layer'First;
   Last_Render_Layer  : constant Render_Layer := Render_Layer'Last;

   Layer_Count : constant Positive :=
     Render_Layer'Pos (Last_Render_Layer)
     - Render_Layer'Pos (First_Render_Layer)
     + 1;

   function Order
     (Layer : Render_Layer) return Natural;

   function To_C
     (Layer : Render_Layer) return Interfaces.C.int;

   function C_First return Interfaces.C.int;

   function C_Last return Interfaces.C.int;

end Editor.Render_Layers;
