package Editor.Ada_Declaration_Parser.Lexical_Helpers is

   function Lower (S : String) return String;
   function Trim (S : String) return String;
   function Is_Word_Char (C : Character) return Boolean;
   function Is_Static_Space (C : Character) return Boolean;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
