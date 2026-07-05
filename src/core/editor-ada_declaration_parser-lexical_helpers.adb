with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;

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

   function Trim_Static_Space (Text : String) return String is
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

   function Normalize_Character_Pos_Static_Operands
     (Text : String) return String is
      Result : Unbounded_String;
      I      : Natural := Text'First;
      Marker : constant String := "character'pos";

      function Matches_Character_Pos (Index : Natural) return Boolean is
         Last : constant Natural := Index + Marker'Length - 1;
      begin
         return Last <= Text'Last
           and then Lower (Text (Index .. Last)) = Marker
           and then
             (Index = Text'First or else not Is_Word_Char (Text (Index - 1)))
           and then
             (Last = Text'Last or else not Is_Word_Char (Text (Last + 1)));
      exception
         when Constraint_Error =>
            return False;
      end Matches_Character_Pos;
   begin
      while I <= Text'Last loop
         if Matches_Character_Pos (I) then
            declare
               Pos   : Natural := I + Marker'Length;
               C     : Character := Character'Val (0);
               Has_C : Boolean := False;
               Done  : Boolean := False;
            begin
               while Pos <= Text'Last and then Is_Static_Space (Text (Pos)) loop
                  Pos := Pos + 1;
               end loop;

               if Pos <= Text'Last and then Text (Pos) = '(' then
                  Pos := Pos + 1;
                  while Pos <= Text'Last
                    and then Is_Static_Space (Text (Pos))
                  loop
                     Pos := Pos + 1;
                  end loop;

                  if Pos + 3 <= Text'Last
                    and then Text (Pos) = Character'Val (39)
                    and then Text (Pos + 1) = Character'Val (39)
                    and then Text (Pos + 2) = Character'Val (39)
                    and then Text (Pos + 3) = Character'Val (39)
                  then
                     C := Character'Val (39);
                     Has_C := True;
                     Pos := Pos + 4;
                  elsif Pos + 2 <= Text'Last
                    and then Text (Pos) = Character'Val (39)
                    and then Text (Pos + 2) = Character'Val (39)
                  then
                     C := Text (Pos + 1);
                     Has_C := True;
                     Pos := Pos + 3;
                  end if;

                  while Pos <= Text'Last
                    and then Is_Static_Space (Text (Pos))
                  loop
                     Pos := Pos + 1;
                  end loop;

                  if Has_C
                    and then Pos <= Text'Last
                    and then Text (Pos) = ')'
                  then
                     Append (Result, Natural'Image (Character'Pos (C)));
                     I := Pos + 1;
                     Done := True;
                  end if;
               end if;

               if not Done then
                  Append (Result, Text (I));
                  I := I + 1;
               end if;
            end;
         else
            Append (Result, Text (I));
            I := I + 1;
         end if;
      end loop;

      return To_String (Result);
   exception
      when Constraint_Error =>
         return Text;
   end Normalize_Character_Pos_Static_Operands;

   function Normalize_Static_Attribute_Spacing
     (Text : String) return String is
      Result : Unbounded_String;
      I      : Integer := Text'First;
   begin
      while I <= Text'Last loop
         Append (Result, Text (I));
         if Text (I) = Character'Val (39) then
            I := I + 1;
            while I <= Text'Last and then Is_Static_Space (Text (I)) loop
               I := I + 1;
            end loop;
         else
            I := I + 1;
         end if;
      end loop;

      return To_String (Result);
   end Normalize_Static_Attribute_Spacing;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
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

   function Segment_Before (Text, Marker : String) return String is
      Marker_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Lower (Text), Lower (Marker));
   begin
      if Marker_Pos = 0 then
         return Trim (Text);
      elsif Marker_Pos <= Text'First then
         return "";
      else
         return Trim (Text (Text'First .. Marker_Pos - 1));
      end if;
   end Segment_Before;

   function Segment_After (Text, Marker : String) return String is
      Marker_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Lower (Text), Lower (Marker));
      First : Natural;
   begin
      if Marker_Pos = 0 then
         return "";
      end if;
      First := Marker_Pos + Marker'Length;
      if First > Text'Last then
         return "";
      end if;
      return Trim (Text (First .. Text'Last));
   end Segment_After;

   function Contains (Text, Fragment : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Fragment) /= 0;
   end Contains;

   function Ends_With (Text, Suffix : String) return Boolean is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Has_Null_Exclusion (Line : String) return Boolean is
      Code : constant String :=
        Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      I    : Natural := Code'First;
   begin
      if Code'Length < 8 then
         return False;
      end if;

      while I <= Code'Last - 7 loop
         if Code (I .. I + 2) = "not"
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then I + 3 <= Code'Last
           and then (Code (I + 3) = ' '
                     or else Code (I + 3) = Ada.Characters.Latin_1.HT)
         then
            declare
               J : Natural := I + 4;
            begin
               while J <= Code'Last
                 and then (Code (J) = ' '
                           or else Code (J) = Ada.Characters.Latin_1.HT)
               loop
                  J := J + 1;
               end loop;
               if J + 3 <= Code'Last
                 and then Code (J .. J + 3) = "null"
                 and then
                   (J + 4 > Code'Last
                    or else not Is_Word_Char (Code (J + 4)))
               then
                  return True;
               end if;
            end;
         end if;
         I := I + 1;
      end loop;
      return False;
   end Has_Null_Exclusion;

   function Has_Token (Line, Token : String) return Boolean is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      I    : Natural := Code'First;
   begin
      if Token'Length = 0 then
         return False;
      end if;
      while I <= Code'Last loop
         if I + Token'Length - 1 <= Code'Last
           and then Code (I .. I + Token'Length - 1) = Token
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then
             (I + Token'Length > Code'Last
              or else not Is_Word_Char (Code (I + Token'Length)))
         then
            return True;
         end if;
         I := I + 1;
      end loop;
      return False;
   end Has_Token;

   function Token_Source_Position (Line, Token : String) return Natural is
      Code : constant String :=
        Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      I    : Natural := Code'First;
   begin
      if Token'Length = 0 then
         return 0;
      end if;

      while I <= Code'Last loop
         if I + Token'Length - 1 <= Code'Last
           and then Code (I .. I + Token'Length - 1) = Token
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then
             (I + Token'Length > Code'Last
              or else not Is_Word_Char (Code (I + Token'Length)))
         then
            return Line'First + (I - Code'First);
         end if;
         I := I + 1;
      end loop;

      return 0;
   end Token_Source_Position;

   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      I    : Natural := Code'First;
   begin
      if First_Token'Length = 0 or else Second_Token'Length = 0 then
         return False;
      end if;

      while I <= Code'Last loop
         if I + First_Token'Length - 1 <= Code'Last
           and then Code (I .. I + First_Token'Length - 1) = First_Token
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then
             (I + First_Token'Length > Code'Last
              or else not Is_Word_Char (Code (I + First_Token'Length)))
         then
            declare
               J : Natural := I + First_Token'Length;
            begin
               while J <= Code'Last
                 and then (Code (J) = ' '
                           or else Code (J) = Ada.Characters.Latin_1.HT)
               loop
                  J := J + 1;
               end loop;

               if J + Second_Token'Length - 1 <= Code'Last
                 and then Code (J .. J + Second_Token'Length - 1) =
                   Second_Token
                 and then
                   (J = Code'First or else not Is_Word_Char (Code (J - 1)))
                 and then
                   (J + Second_Token'Length > Code'Last
                    or else
                      not Is_Word_Char (Code (J + Second_Token'Length)))
               then
                  return True;
               end if;
            end;
         end if;
         I := I + 1;
      end loop;
      return False;
   end Has_Token_Pair;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
