package Editor.Ada_Token_Cursor.Grammar_Helpers is

   function Match_Keyword
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Keyword  : String) return Boolean;

   function Match_Symbol
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Symbol   : String) return Boolean;

   procedure Add_Production
     (Result : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Kind   : Editor.Ada_Token_Cursor.Production_Kind;
      Tok    : Editor.Ada_Token_Cursor.Token_Info;
      Label  : String);

end Editor.Ada_Token_Cursor.Grammar_Helpers;
