with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Generic_Actual_Parsing is

   procedure Parse_Generic_Actual_Part
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Generic_Actual_Parsing;
