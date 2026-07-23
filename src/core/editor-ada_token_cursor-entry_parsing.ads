with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Entry_Parsing is

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Tok      : Editor.Ada_Token_Cursor.Token_Info);

   procedure Add_Statement_Name_Suffix_Productions
     (Position       : Editor.Ada_Token_Cursor.Cursor;
      Result         : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Start_At       : Natural;
      End_At         : Natural;
      For_Assignment : Boolean);

   procedure Add_Entry_Body_Part_Productions
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Entry_Parsing;
