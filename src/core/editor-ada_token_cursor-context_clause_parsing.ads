with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Context_Clause_Parsing is

   procedure Parse_Visibility_Name
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Kind     : Editor.Ada_Token_Cursor.Production_Kind;
      Label    : String);

   procedure Parse_Visibility_Name_List
     (Position  : in out Editor.Ada_Token_Cursor.Cursor;
      Result    : in out Editor.Ada_Token_Cursor.Grammar_Result;
      List_Kind : Editor.Ada_Token_Cursor.Production_Kind;
      Item_Kind : Editor.Ada_Token_Cursor.Production_Kind;
      Label     : String);

   procedure Parse_Use_Clause
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Context_Clause
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Context_Clause_Parsing;
