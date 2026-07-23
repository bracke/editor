package Editor.Ada_Token_Cursor.Parsing_Predicates is

   function Is_Statement_Starter_After_Label
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Formal_Package_Actual_Has_Top_Level_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Formal_Package_Actual_Looks_Like_Missing_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Starts_Generic_Instantiation
     (Position  : Editor.Ada_Token_Cursor.Cursor;
      Unit_Kind : String) return Boolean;

   function Has_Top_Level_With_Before_Association_End
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

end Editor.Ada_Token_Cursor.Parsing_Predicates;
