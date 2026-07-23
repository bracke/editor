with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Generic_Formal_Parsing is

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Generic_Formal_Object_Declaration
     (Position     : in out Editor.Ada_Token_Cursor.Cursor;
      Result       : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Leading_With : Boolean := False);

   procedure Parse_Formal_Package_Actual_Part
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Generic_Formal_Parsing;
