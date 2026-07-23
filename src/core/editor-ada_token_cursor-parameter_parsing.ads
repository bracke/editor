with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Parameter_Parsing is

   procedure Parse_Profile_Default
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Parameter_Profile
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Parameter_Parsing;
