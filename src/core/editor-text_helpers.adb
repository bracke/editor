with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Editor.Ada_Syntax_Core;

package body Editor.Text_Helpers is

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Trim (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trim;

   function Normalize (S : String) return String is
   begin
      return Lower (Trim (S));
   end Normalize;

   function Normalized_Line (Line : String) return String is
   begin
      return Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
   end Normalized_Line;

   function Trim_Static_Space (Text : String) return String is
      function Is_Static_Space (C : Character) return Boolean is
      begin
         return C = ' '
           or else C = Ada.Characters.Latin_1.HT
           or else C = Ada.Characters.Latin_1.VT
           or else C = Ada.Characters.Latin_1.FF
           or else C = Ada.Characters.Latin_1.CR
           or else C = Ada.Characters.Latin_1.LF;
      end Is_Static_Space;

      First : Natural := Text'First;
      Last  : Natural := Text'Last;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      while First <= Text'Last and then Is_Static_Space (Text (First)) loop
         First := First + 1;
      end loop;

      while Last >= Text'First and then Is_Static_Space (Text (Last)) loop
         if Last = Text'First then
            exit;
         end if;
         Last := Last - 1;
      end loop;

      if First > Last or else Is_Static_Space (Text (Last)) then
         return "";
      else
         return Text (First .. Last);
      end if;
   exception
      when Constraint_Error =>
         return Trim (Text);
   end Trim_Static_Space;

   function Is_Word_Char (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z')
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Word_Char;

   function Clean_Name (Raw : String) return String is
      T    : constant String := Trim (Raw);
      Stop : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;

      while Stop <= T'Last
        and then (Is_Word_Char (T (Stop)) or else T (Stop) = '.')
      loop
         Stop := Stop + 1;
      end loop;

      if Stop = T'First then
         return "";
      end if;

      return Lower (T (T'First .. Stop - 1));
   end Clean_Name;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      if Prefix'Length = 0 then
         return True;
      elsif Prefix'Length > Text'Length then
         return False;
      end if;

      return Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Starts_With_Word (Text, Word : String) return Boolean is
      After : Natural;
   begin
      if not Starts_With (Text, Word) then
         return False;
      end if;
      After := Text'First + Word'Length;
      return After > Text'Last or else not Is_Word_Char (Text (After));
   end Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean is
   begin
      if Fragment'Length = 0 then
         return True;
      elsif Fragment'Length > Text'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Fragment'Length + 1 loop
         if Text (I .. I + Fragment'Length - 1) = Fragment then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Ends_With (Text, Suffix : String) return Boolean is
   begin
      if Suffix'Length = 0 then
         return True;
      elsif Suffix'Length > Text'Length then
         return False;
      end if;

      return Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

end Editor.Text_Helpers;
