with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Representation_Parsing is

   procedure Parse_Representation_Clause
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Record_Representation_Clause
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Representation_Parsing;
