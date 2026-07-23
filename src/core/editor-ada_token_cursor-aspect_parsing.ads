with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Aspect_Parsing is

   procedure Parse_Aspect_Specification
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Context  : Editor.Ada_Token_Cursor.Production_Kind);

   procedure Parse_Subprogram_Declaration_Aspect_Or_Terminator
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Number_Declaration_Aspect_Or_Terminator
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Exception_Declaration_Aspect_Or_Terminator
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Keyword  : String);

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Keyword  : String;
      Context  : Editor.Ada_Token_Cursor.Production_Kind);

end Editor.Ada_Token_Cursor.Aspect_Parsing;
