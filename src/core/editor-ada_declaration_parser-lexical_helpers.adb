with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;

package body Editor.Ada_Declaration_Parser.Lexical_Helpers is

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Trim (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trim;

   function Is_Word_Char (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z')
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Word_Char;

   function Is_Static_Space (C : Character) return Boolean is
   begin
      return C = ' '
        or else C = Ada.Characters.Latin_1.HT
        or else C = Ada.Characters.Latin_1.VT
        or else C = Ada.Characters.Latin_1.FF
        or else C = Ada.Characters.Latin_1.CR
        or else C = Ada.Characters.Latin_1.LF;
   end Is_Static_Space;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
