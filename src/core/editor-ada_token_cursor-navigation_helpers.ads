package Editor.Ada_Token_Cursor.Navigation_Helpers is

   function Lookahead_Lower
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Offset   : Natural) return String;

   function Lookahead_Kind
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Offset   : Natural) return Editor.Ada_Token_Cursor.Token_Kind;

   function Current_Lower
     (Position : Editor.Ada_Token_Cursor.Cursor) return String;

   procedure Skip_Balanced_To_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor);

   procedure Advance_Through_Keyword
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Keyword  : String);

   function Has_Token_Before_Semicolon
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Text     : String) return Boolean;

   function Has_Token_Between
     (Stream : Editor.Ada_Token_Cursor.Token_Stream;
      First  : Natural;
      Last   : Natural;
      Text   : String) return Boolean;

   procedure Skip_Balanced_To
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "");

end Editor.Ada_Token_Cursor.Navigation_Helpers;
