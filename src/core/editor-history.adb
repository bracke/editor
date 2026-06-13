with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
package body Editor.History is

   use Caret_Vectors;
   function "=" (L, R : History_Entry) return Boolean is
   begin
      return L.Forward = R.Forward
        and then L.Inverse = R.Inverse
        and then L.Before_Text = R.Before_Text
        and then L.After_Text = R.After_Text
        and then L.Before_Carets = R.Before_Carets
        and then L.After_Carets = R.After_Carets
        and then L.Before_Preferred_Column = R.Before_Preferred_Column
        and then L.After_Preferred_Column = R.After_Preferred_Column
        and then L.Before_Rect_Select_Active = R.Before_Rect_Select_Active
        and then L.After_Rect_Select_Active = R.After_Rect_Select_Active
        and then L.Before_Rect_Anchor_Row = R.Before_Rect_Anchor_Row
        and then L.Before_Rect_Anchor_Col = R.Before_Rect_Anchor_Col
        and then L.After_Rect_Anchor_Row = R.After_Rect_Anchor_Row
        and then L.After_Rect_Anchor_Col = R.After_Rect_Anchor_Col
        and then L.Before_Dirty = R.Before_Dirty
        and then L.After_Dirty = R.After_Dirty
        and then L.Owner_Buffer_Token = R.Owner_Buffer_Token
        and then L.Owner_Lifecycle_Generation = R.Owner_Lifecycle_Generation
        and then L.Group_Kind = R.Group_Kind;
   end "=";

end Editor.History;
