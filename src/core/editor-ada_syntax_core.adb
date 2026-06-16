with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;

package body Editor.Ada_Syntax_Core is

   pragma Suppress (Overflow_Check);

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean
   is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean
   is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Is_Word_Char (C : Character) return Boolean
   is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z')
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Word_Char;

   function Starts_With_Word
     (Lower_Line : String;
      Word       : String) return Boolean
   is
      After : Natural;
   begin
      if not Starts_With (Lower_Line, Word) then
         return False;
      end if;

      After := Lower_Line'First + Word'Length;
      return After > Lower_Line'Last or else not Is_Word_Char (Lower_Line (After));
   end Starts_With_Word;

   function Starts_With_Keyword
     (Lower_Line : String;
      Keyword    : String) return Boolean
   is
      After : Natural;
   begin
      if not Starts_With (Lower_Line, Keyword) then
         return False;
      end if;

      After := Lower_Line'First + Keyword'Length;
      return After > Lower_Line'Last or else not Is_Word_Char (Lower_Line (After));
   end Starts_With_Keyword;

   function Starts_With_Phrase
     (Lower_Line : String;
      Phrase     : String) return Boolean
   is
   begin
      return Starts_With (Lower_Line, Phrase);
   end Starts_With_Phrase;

   function Looks_Like_Simple_Character_Literal
     (Line  : String;
      Start : Natural) return Boolean
   is
      Quote : constant Character := Character'Val (16#27#);
   begin
      if Start < Line'First or else Start + 2 > Line'Last then
         return False;
      end if;

      if Start + 3 <= Line'Last
        and then Line (Start) = Quote
        and then Line (Start + 1) = Quote
        and then Line (Start + 2) = Quote
        and then Line (Start + 3) = Quote
      then
         return True;
      end if;

      return Line (Start) = Quote
        and then Line (Start + 2) = Quote
        and then Line (Start + 1) /= Ada.Characters.Latin_1.LF
        and then Line (Start + 1) /= Ada.Characters.Latin_1.CR;
   end Looks_Like_Simple_Character_Literal;

   function Simple_Character_Literal_Length
     (Line  : String;
      Start : Natural) return Natural
   is
      Quote : constant Character := Character'Val (16#27#);
   begin
      if Start + 3 <= Line'Last
        and then Line (Start) = Quote
        and then Line (Start + 1) = Quote
        and then Line (Start + 2) = Quote
        and then Line (Start + 3) = Quote
      then
         return 4;
      elsif Looks_Like_Simple_Character_Literal (Line, Start) then
         return 3;
      else
         return 0;
      end if;
   end Simple_Character_Literal_Length;

   function Code_Mask_Line (Line : String) return String
   is
      Mask      : String := (Line'Range => 'C');
      In_String : Boolean := False;
      I         : Natural := Line'First;
   begin
      while I <= Line'Last loop
         if In_String then
            Mask (I) := ' ';
            if Line (I) = Ada.Characters.Latin_1.LF
              or else Line (I) = Ada.Characters.Latin_1.CR
            then
               In_String := False;
               I := I + 1;
            elsif Line (I) = '"' then
               if I < Line'Last and then Line (I + 1) = '"' then
                  Mask (I + 1) := ' ';
                  I := I + 2;
               else
                  In_String := False;
                  I := I + 1;
               end if;
            else
               I := I + 1;
            end if;
         elsif Line (I) = Ada.Characters.Latin_1.LF
           or else Line (I) = Ada.Characters.Latin_1.CR
         then
            Mask (I) := ' ';
            I := I + 1;
         elsif Line (I) = '"' then
            Mask (I) := ' ';
            In_String := True;
            I := I + 1;
         elsif I < Line'Last
           and then Line (I) = '-'
           and then Line (I + 1) = '-'
         then
            while I <= Line'Last loop
               exit when Line (I) = Ada.Characters.Latin_1.LF
                 or else Line (I) = Ada.Characters.Latin_1.CR;
               Mask (I) := ' ';
               I := I + 1;
            end loop;
         elsif Looks_Like_Simple_Character_Literal (Line, I) then
            declare
               Span_Length : constant Natural := Simple_Character_Literal_Length (Line, I);
            begin
               for J in I .. I + Span_Length - 1 loop
                  Mask (J) := ' ';
               end loop;
               I := I + Span_Length;
            end;
         else
            I := I + 1;
         end if;
      end loop;

      return Mask;
   end Code_Mask_Line;

   function Sanitize_Line (Line : String) return String
   is
      Result : String := Line;
      Mask   : constant String := Code_Mask_Line (Line);
   begin
      for I in Result'Range loop
         if Mask (I) = ' ' then
            Result (I) := ' ';
         end if;
      end loop;
      return Result;
   end Sanitize_Line;

   function Is_Code_Column
     (Line   : String;
      Column : Positive) return Boolean
   is
      Target : constant Natural := Line'First + Column - 1;
      Mask   : constant String := Code_Mask_Line (Line);
   begin
      if Target not in Line'Range then
         return False;
      end if;
      return Mask (Target) = 'C';
   end Is_Code_Column;

   function Strip_Comment_Safely (Line : String) return String
   is
      Sanitized : constant String := Sanitize_Line (Line);
      Last_Code : Natural := Sanitized'Last;
   begin
      while Last_Code >= Sanitized'First
        and then Sanitized (Last_Code) = ' '
        and then Line (Last_Code) /= ' '
      loop
         Last_Code := Last_Code - 1;
         exit when Last_Code < Sanitized'First;
      end loop;

      if Last_Code < Sanitized'First then
         return "";
      else
         return Sanitized (Sanitized'First .. Last_Code);
      end if;
   end Strip_Comment_Safely;

   function Is_Ada_Source_Label (Label : String) return Boolean
   is
      Lower_Label : constant String := Ada.Strings.Fixed.Translate
        (Label, Ada.Strings.Maps.Constants.Lower_Case_Map);
   begin
      return Ends_With (Lower_Label, ".ads")
        or else Ends_With (Lower_Label, ".adb")
        or else Ends_With (Lower_Label, ".ada");
   end Is_Ada_Source_Label;

   function Strip_Separate_Prefix (Line : String) return String
   is
      Lower : constant String := Ada.Strings.Fixed.Translate
        (Line, Ada.Strings.Maps.Constants.Lower_Case_Map);
      Close : Natural := 0;
   begin
      if not Starts_With_Word (Lower, "separate") then
         return Line;
      end if;

      for I in Line'Range loop
         if Line (I) = ')' then
            Close := I;
            exit;
         end if;
      end loop;

      if Close = 0 or else Close >= Line'Last then
         return "";
      end if;

      return Ada.Strings.Fixed.Trim (Line (Close + 1 .. Line'Last), Ada.Strings.Both);
   end Strip_Separate_Prefix;

   function Looks_Like_Ada_Declaration_Line (Line : String) return Boolean
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim
        (Strip_Comment_Safely (Line), Ada.Strings.Both);
      Lower : constant String := Ada.Strings.Fixed.Translate
        (Trimmed, Ada.Strings.Maps.Constants.Lower_Case_Map);
   begin
      if Lower'Length = 0 then
         return False;
      end if;

      if Starts_With_Word (Lower, "separate") then
         declare
            Stripped : constant String := Strip_Separate_Prefix (Trimmed);
         begin
            return Stripped'Length > 0
              and then Looks_Like_Ada_Declaration_Line (Stripped);
         end;
      end if;

      return Starts_With_Word (Lower, "package")
        or else Starts_With_Phrase (Lower, "private package ")
        or else Starts_With_Keyword (Lower, "package body ")
        or else Starts_With_Word (Lower, "procedure")
        or else Starts_With_Word (Lower, "function")
        or else Starts_With_Phrase (Lower, "overriding procedure ")
        or else Starts_With_Phrase (Lower, "overriding function ")
        or else Starts_With_Phrase (Lower, "not overriding procedure ")
        or else Starts_With_Phrase (Lower, "not overriding function ")
        or else Starts_With_Phrase (Lower, "abstract procedure ")
        or else Starts_With_Phrase (Lower, "abstract function ")
        or else Starts_With_Word (Lower, "type")
        or else Starts_With_Word (Lower, "subtype")
        or else Starts_With_Word (Lower, "task")
        or else Starts_With_Word (Lower, "protected")
        or else Starts_With_Word (Lower, "entry")
        or else Starts_With_Word (Lower, "generic");
   end Looks_Like_Ada_Declaration_Line;

end Editor.Ada_Syntax_Core;
