with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Pragma_Parsing is

   procedure Parse_Pragma_Argument_List
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Pragma
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Pragma_Parsing;
