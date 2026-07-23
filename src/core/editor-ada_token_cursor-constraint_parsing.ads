with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Constraint_Parsing is

   procedure Parse_Range_Constraint
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Digits_Constraint
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Delta_Constraint
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Null_Exclusion
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Constraint_Parsing;
