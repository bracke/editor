with Editor.Commands.Payloads;
with Editor.Cursors; use Editor.Cursors;

package Editor.State.Caret_Rules is

   function Transform_Carets
  (Carets : Cursors_Vector.Vector;
   Cmd    : Editor.Commands.Payloads.Command;
   Len    : Natural)
   return Cursors_Vector.Vector;

end Editor.State.Caret_Rules;