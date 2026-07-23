with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Selected_Name_Parsing is

   procedure Parse_Selected_Name_Suffix
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin   : Editor.Ada_Token_Cursor.Token_Info;
      Label    : String);

end Editor.Ada_Token_Cursor.Selected_Name_Parsing;
