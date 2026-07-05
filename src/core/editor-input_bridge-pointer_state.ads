with Editor.Scrollbars;

package Editor.Input_Bridge.Pointer_State is

   function Minimap_Drag_Active return Boolean;
   procedure Set_Minimap_Drag_Active (Active : Boolean);

   function Scrollbar_Drag_Active return Boolean;
   function Scrollbar_Drag_Orientation
     return Editor.Scrollbars.Scrollbar_Orientation;
   function Scrollbar_Drag_Offset return Natural;
   procedure Start_Scrollbar_Drag
     (Orientation : Editor.Scrollbars.Scrollbar_Orientation;
      Offset      : Natural);
   procedure Clear_Scrollbar_Drag;

   function Gutter_Line_Selection_Active return Boolean;
   function Gutter_Line_Selection_Anchor_Row return Natural;
   procedure Start_Gutter_Line_Selection (Anchor_Row : Natural);
   procedure Clear_Gutter_Line_Selection;

   procedure Reset_All;

end Editor.Input_Bridge.Pointer_State;
