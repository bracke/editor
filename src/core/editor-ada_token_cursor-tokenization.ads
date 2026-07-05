package Editor.Ada_Token_Cursor.Tokenization is

   function Tokenize (Text : String) return Token_Stream;
   function Length (Stream : Token_Stream) return Natural;
   function Token_At (Stream : Token_Stream; Index : Positive) return Token_Info;

   function First (Stream : Token_Stream) return Cursor;
   function At_End (Position : Cursor) return Boolean;
   function Current (Position : Cursor) return Token_Info;
   procedure Advance (Position : in out Cursor);
   function Mark (Position : Cursor) return Natural;
   procedure Restore (Position : in out Cursor; To_Mark : Natural);

end Editor.Ada_Token_Cursor.Tokenization;
