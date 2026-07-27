with Editor.Cursors;

package Editor.State_Caret is

   type Caret_Runtime_State is record
      Carets             : Editor.Cursors.Cursors_Vector.Vector;
      Preferred_Column   : Natural := 0;
      Rect_Select_Active : Boolean := False;
      Rect_Anchor_Row    : Natural := 0;
      Rect_Anchor_Col    : Natural := 0;
   end record;

end Editor.State_Caret;
