with Editor.Cursors; use Editor.Cursors;
with Editor.Commands;

package Editor.State.Caret_Rules is

   function Transform_Carets
  (Carets : Cursors_Vector.Vector;
   Cmd    : Editor.Commands.Command;
   Len    : Natural)
   return Cursors_Vector.Vector;

end Editor.State.Caret_Rules;