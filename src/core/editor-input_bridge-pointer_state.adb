package body Editor.Input_Bridge.Pointer_State is

   Minimap_Active : Boolean := False;

   type Scrollbar_Drag_State is record
      Active      : Boolean := False;
      Orientation : Editor.Scrollbars.Scrollbar_Orientation :=
        Editor.Scrollbars.Vertical_Scrollbar;
      Drag_Offset : Natural := 0;
   end record;

   Scrollbar_Drag : Scrollbar_Drag_State;

   type Gutter_Line_Selection_State is record
      Active     : Boolean := False;
      Anchor_Row : Natural := 0;
   end record;

   Gutter_Line_Selection : Gutter_Line_Selection_State;

   function Minimap_Drag_Active return Boolean is
   begin
      return Minimap_Active;
   end Minimap_Drag_Active;

   procedure Set_Minimap_Drag_Active (Active : Boolean) is
   begin
      Minimap_Active := Active;
   end Set_Minimap_Drag_Active;

   function Scrollbar_Drag_Active return Boolean is
   begin
      return Scrollbar_Drag.Active;
   end Scrollbar_Drag_Active;

   function Scrollbar_Drag_Orientation
     return Editor.Scrollbars.Scrollbar_Orientation is
   begin
      return Scrollbar_Drag.Orientation;
   end Scrollbar_Drag_Orientation;

   function Scrollbar_Drag_Offset return Natural is
   begin
      return Scrollbar_Drag.Drag_Offset;
   end Scrollbar_Drag_Offset;

   procedure Start_Scrollbar_Drag
     (Orientation : Editor.Scrollbars.Scrollbar_Orientation;
      Offset      : Natural) is
   begin
      Scrollbar_Drag.Active := True;
      Scrollbar_Drag.Orientation := Orientation;
      Scrollbar_Drag.Drag_Offset := Offset;
   end Start_Scrollbar_Drag;

   procedure Clear_Scrollbar_Drag is
   begin
      Scrollbar_Drag.Active := False;
      Scrollbar_Drag.Drag_Offset := 0;
   end Clear_Scrollbar_Drag;

   function Gutter_Line_Selection_Active return Boolean is
   begin
      return Gutter_Line_Selection.Active;
   end Gutter_Line_Selection_Active;

   function Gutter_Line_Selection_Anchor_Row return Natural is
   begin
      return Gutter_Line_Selection.Anchor_Row;
   end Gutter_Line_Selection_Anchor_Row;

   procedure Start_Gutter_Line_Selection (Anchor_Row : Natural) is
   begin
      Gutter_Line_Selection.Active := True;
      Gutter_Line_Selection.Anchor_Row := Anchor_Row;
   end Start_Gutter_Line_Selection;

   procedure Clear_Gutter_Line_Selection is
   begin
      Gutter_Line_Selection.Active := False;
      Gutter_Line_Selection.Anchor_Row := 0;
   end Clear_Gutter_Line_Selection;

   procedure Reset_All is
   begin
      Minimap_Active := False;
      Clear_Scrollbar_Drag;
      Clear_Gutter_Line_Selection;
   end Reset_All;

end Editor.Input_Bridge.Pointer_State;
