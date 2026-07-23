with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing is

   procedure Parse_Generic_Actual_Part
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   procedure Parse_Generic_Instantiated_Unit_Name
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Generic_Instantiation_Declaration
     (Position  : in out Editor.Ada_Token_Cursor.Cursor;
      Result    : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Unit_Kind : String);

end Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing;
