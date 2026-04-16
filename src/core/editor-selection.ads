with Editor.Cursors; use Editor.Cursors;

package Editor.Selection is

   type Selection_State is record
      Active     : Boolean := False;
      Start_Pos  : Cursor_Index := 0;
      End_Pos    : Cursor_Index := 0;
   end record;

end Editor.Selection;