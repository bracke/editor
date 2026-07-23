with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Lexical_Helpers is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Is_Word_Char (C : Character) return Boolean
     renames Editor.Text_Helpers.Is_Word_Char;

   function Normalized_Line (Line : String) return String
     renames Editor.Text_Helpers.Normalized_Line;

   function Is_Name_Start (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z');
   end Is_Name_Start;

   function Is_Name_Char (C : Character) return Boolean is
   begin
      return Is_Name_Start (C)
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Name_Char;

   function Is_Static_Space (C : Character) return Boolean is
   begin
      return C = ' '
        or else C = Ada.Characters.Latin_1.HT
        or else C = Ada.Characters.Latin_1.VT
        or else C = Ada.Characters.Latin_1.FF
        or else C = Ada.Characters.Latin_1.CR
        or else C = Ada.Characters.Latin_1.LF;
   end Is_Static_Space;

   procedure Skip_Blanks (Text : String; Pos : in out Natural) is
   begin
      while Pos <= Text'Last and then Is_Static_Space (Text (Pos)) loop
         Pos := Pos + 1;
      end loop;
   end Skip_Blanks;

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

   function Starts_With (Text, Prefix : String) return Boolean
     renames Editor.Text_Helpers.Starts_With;

   function Starts_With_Word (Text, Word : String) return Boolean
     renames Editor.Text_Helpers.Starts_With_Word;

   function Starts_At_Word
     (Text  : String;
      Pos   : Natural;
      Word  : String) return Boolean
   is
   begin
      return Pos >= Text'First
        and then Pos + Word'Length - 1 <= Text'Last
        and then Lower (Text (Pos .. Pos + Word'Length - 1)) = Word
        and then (Pos = Text'First or else not Is_Word_Char (Text (Pos - 1)))
        and then (Pos + Word'Length > Text'Last
                  or else not Is_Word_Char (Text (Pos + Word'Length)));
   end Starts_At_Word;

   function Word_At
     (Text  : String;
      Pos   : Natural;
      Word  : String) return Boolean
   is
   begin
      return Starts_At_Word (Text, Pos, Word);
   end Word_At;

   function Next_Non_Blank
     (Text  : String;
      From  : Natural) return Natural
   is
      Pos : Natural := From;
   begin
      Skip_Blanks (Text, Pos);
      return Pos;
   end Next_Non_Blank;

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

   function Contains (Text, Fragment : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   function Ends_With (Text, Suffix : String) return Boolean
     renames Editor.Text_Helpers.Ends_With;

   function Is_Declaration_Or_Metadata_Line (Line : String) return Boolean is
   begin
      return Starts_With_Word (Line, "package")
        or else Starts_With_Word (Line, "procedure")
        or else Starts_With_Word (Line, "function")
        or else Starts_With_Word (Line, "type")
        or else Starts_With_Word (Line, "subtype")
        or else Starts_With_Word (Line, "task")
        or else Starts_With_Word (Line, "protected")
        or else Starts_With_Word (Line, "entry")
        or else Starts_With_Word (Line, "generic")
        or else Starts_With_Word (Line, "with")
        or else Starts_With_Word (Line, "use")
        or else Starts_With_Word (Line, "pragma")
        or else Starts_With_Word (Line, "private")
        or else Starts_With_Word (Line, "separate")
        or else Starts_With_Word (Line, "overriding")
        or else Starts_With_Word (Line, "not overriding")
        or else Starts_With_Word (Line, "end")
        or else (Starts_With_Word (Line, "for")
                 and then Has_Token (Line, "use"));
   end Is_Declaration_Or_Metadata_Line;

   function Is_Executable_Scan_Keyword (Name : String) return Boolean is
      L : constant String := Lower (Name);
   begin
      return L = "abort"
        or else L = "abs"
        or else L = "accept"
        or else L = "and"
        or else L = "begin"
        or else L = "case"
        or else L = "declare"
        or else L = "delay"
        or else L = "else"
        or else L = "elsif"
        or else L = "end"
        or else L = "entry"
        or else L = "exception"
        or else L = "exit"
        or else L = "for"
        or else L = "function"
        or else L = "goto"
        or else L = "if"
        or else L = "is"
        or else L = "loop"
        or else L = "mod"
        or else L = "new"
        or else L = "not"
        or else L = "null"
        or else L = "or"
        or else L = "others"
        or else L = "package"
        or else L = "pragma"
        or else L = "procedure"
        or else L = "raise"
        or else L = "record"
        or else L = "rem"
        or else L = "renames"
        or else L = "return"
        or else L = "select"
        or else L = "separate"
        or else L = "subtype"
        or else L = "task"
        or else L = "then"
        or else L = "terminate"
        or else L = "type"
        or else L = "until"
        or else L = "use"
        or else L = "when"
        or else L = "while"
        or else L = "with"
        or else L = "xor";
   end Is_Executable_Scan_Keyword;

   function Is_Executable_Declaration_Line (LWork : String) return Boolean is
   begin
      return Starts_With_Word (LWork, "procedure")
        or else Starts_With_Word (LWork, "function")
        or else Starts_With_Word (LWork, "package")
        or else Starts_With_Word (LWork, "type")
        or else Starts_With_Word (LWork, "subtype")
        or else Starts_With_Word (LWork, "task")
        or else Starts_With_Word (LWork, "protected")
        or else Starts_With_Word (LWork, "entry")
        or else Starts_With_Word (LWork, "generic")
        or else Starts_With_Word (LWork, "with")
        or else Starts_With_Word (LWork, "use")
        or else Starts_With_Word (LWork, "for");
   end Is_Executable_Declaration_Line;

   function Starts_With_Subprogram_Keyword (Text : String) return Boolean is
   begin
      return Starts_With_Word (Text, "procedure")
        or else Starts_With_Word (Text, "function");
   end Starts_With_Subprogram_Keyword;

   function Has_Null_Exclusion (Line : String) return Boolean is
      Code : constant String := Normalized_Line (Line);
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

   function Has_Code_Char (Line : String; C : Character) return Boolean is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
   begin
      for X of Code loop
         if X = C then
            return True;
         end if;
      end loop;
      return False;
   end Has_Code_Char;

   function Declaration_Colon_Position (Line : String) return Natural is
      Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Nesting : Natural := 0;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            return 0;
         elsif Code (I) = ':' and then Nesting = 0 then
            if I < Code'Last and then Code (I + 1) = '=' then
               null;
            else
               return I;
            end if;
         end if;
      end loop;

      return 0;
   end Declaration_Colon_Position;

   function Has_Declaration_Colon (Line : String) return Boolean is
   begin
      return Declaration_Colon_Position (Line) /= 0;
   end Has_Declaration_Colon;

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
      Code : constant String := Normalized_Line (Line);
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

   function Has_Object_Constant_Qualifier (Line : String) return Boolean is
      Code  : constant String := Normalized_Line (Line);
      Colon : constant Natural := Ada.Strings.Fixed.Index (Code, ":");
      I     : Natural;

      procedure Skip_Blanks is
      begin
         while I <= Code'Last
           and then (Code (I) = ' ' or else Code (I) = Ada.Characters.Latin_1.HT)
         loop
            I := I + 1;
         end loop;
      end Skip_Blanks;

      function Token_At (Token : String) return Boolean is
      begin
         return I + Token'Length - 1 <= Code'Last
           and then Code (I .. I + Token'Length - 1) = Token
           and then (I = Code'First or else not Is_Word_Char (Code (I - 1)))
           and then (I + Token'Length > Code'Last
                     or else not Is_Word_Char (Code (I + Token'Length)));
      end Token_At;
   begin
      if Colon = 0 or else Colon >= Code'Last then
         return False;
      end if;

      I := Colon + 1;
      Skip_Blanks;
      if I <= Code'Last and then Token_At ("aliased") then
         I := I + 7;
         Skip_Blanks;
      end if;

      return I <= Code'Last and then Token_At ("constant");
   end Has_Object_Constant_Qualifier;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
