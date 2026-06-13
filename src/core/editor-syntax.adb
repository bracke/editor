with Ada.Characters.Handling;

package body Editor.Syntax is

   Apostrophe : constant Character := Character'Val (39);

   function Is_Letter (Ch : Character) return Boolean is
   begin
      return (Ch >= 'A' and then Ch <= 'Z')
        or else (Ch >= 'a' and then Ch <= 'z')
        or else Character'Pos (Ch) >= 128;
   end Is_Letter;

   function Is_Digit (Ch : Character) return Boolean is
   begin
      return Ch >= '0' and then Ch <= '9';
   end Is_Digit;

   function Is_Hex_Digit (Ch : Character) return Boolean is
   begin
      return Is_Digit (Ch)
        or else (Ch >= 'A' and then Ch <= 'F')
        or else (Ch >= 'a' and then Ch <= 'f');
   end Is_Hex_Digit;

   function Is_Identifier_Start (Ch : Character) return Boolean is
   begin
      return Is_Letter (Ch);
   end Is_Identifier_Start;

   function Is_Identifier_Body (Ch : Character) return Boolean is
   begin
      return Is_Letter (Ch) or else Is_Digit (Ch) or else Ch = '_';
   end Is_Identifier_Body;

   function Lower (S : String) return String is
      Result : String (S'Range);
   begin
      for I in S'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (S (I));
      end loop;

      return Result;
   end Lower;

   function Is_Keyword (Word : String) return Boolean is
      L : constant String := Lower (Word);
   begin
      return L = "abort"
        or else L = "abs"
        or else L = "abstract"
        or else L = "accept"
        or else L = "access"
        or else L = "aliased"
        or else L = "all"
        or else L = "and"
        or else L = "array"
        or else L = "at"
        or else L = "begin"
        or else L = "body"
        or else L = "case"
        or else L = "constant"
        or else L = "declare"
        or else L = "delay"
        or else L = "delta"
        or else L = "digits"
        or else L = "do"
        or else L = "else"
        or else L = "elsif"
        or else L = "end"
        or else L = "entry"
        or else L = "exception"
        or else L = "exit"
        or else L = "for"
        or else L = "function"
        or else L = "generic"
        or else L = "goto"
        or else L = "if"
        or else L = "in"
        or else L = "interface"
        or else L = "is"
        or else L = "limited"
        or else L = "loop"
        or else L = "mod"
        or else L = "new"
        or else L = "not"
        or else L = "null"
        or else L = "of"
        or else L = "or"
        or else L = "others"
        or else L = "out"
        or else L = "overriding"
        or else L = "package"
        or else L = "pragma"
        or else L = "private"
        or else L = "procedure"
        or else L = "protected"
        or else L = "raise"
        or else L = "range"
        or else L = "record"
        or else L = "rem"
        or else L = "renames"
        or else L = "requeue"
        or else L = "return"
        or else L = "reverse"
        or else L = "select"
        or else L = "separate"
        or else L = "some"
        or else L = "subtype"
        or else L = "synchronized"
        or else L = "tagged"
        or else L = "task"
        or else L = "terminate"
        or else L = "then"
        or else L = "type"
        or else L = "until"
        or else L = "use"
        or else L = "when"
        or else L = "while"
        or else L = "with"
        or else L = "xor";
   end Is_Keyword;

   function Is_Predefined_Type (Word : String) return Boolean is
      L : constant String := Lower (Word);
   begin
      return L = "boolean"
        or else L = "character"
        or else L = "wide_character"
        or else L = "wide_wide_character"
        or else L = "string"
        or else L = "wide_string"
        or else L = "wide_wide_string"
        or else L = "integer"
        or else L = "natural"
        or else L = "positive"
        or else L = "float"
        or else L = "long_float"
        or else L = "duration";
   end Is_Predefined_Type;

   function Is_Operator_Char (Ch : Character) return Boolean is
   begin
      return Ch = '+'
        or else Ch = '-'
        or else Ch = '*'
        or else Ch = '/'
        or else Ch = '='
        or else Ch = '<'
        or else Ch = '>'
        or else Ch = ':';
   end Is_Operator_Char;

   function Is_Punctuation_Char (Ch : Character) return Boolean is
   begin
      return Ch = '('
        or else Ch = ')'
        or else Ch = '['
        or else Ch = ']'
        or else Ch = ','
        or else Ch = ';'
        or else Ch = '.';
   end Is_Punctuation_Char;

   function Is_Multi_Char_Operator (Line : String; I : Integer) return Natural is
   begin
      if I < Line'Last then
         if (Line (I) = ':' and then Line (I + 1) = '=')
           or else (Line (I) = '=' and then Line (I + 1) = '>')
           or else (Line (I) = '.' and then Line (I + 1) = '.')
           or else (Line (I) = '*' and then Line (I + 1) = '*')
           or else (Line (I) = '/' and then Line (I + 1) = '=')
           or else (Line (I) = '<' and then Line (I + 1) = '=')
           or else (Line (I) = '>' and then Line (I + 1) = '=')
           or else (Line (I) = '<' and then Line (I + 1) = '>')
         then
            return 2;
         end if;
      end if;

      return 1;
   end Is_Multi_Char_Operator;

   function Previous_Non_Space (Line : String; Before : Integer) return Character is
      J : Integer := Before;
   begin
      while J >= Line'First loop
         if Line (J) /= ' ' and then Line (J) /= ASCII.HT then
            return Line (J);
         end if;
         J := J - 1;
      end loop;

      return ASCII.NUL;
   end Previous_Non_Space;


   function Last_Word_Before (Line : String; Before : Integer) return String is
      Stop : Integer := Before;
   begin
      while Stop >= Line'First
        and then (Line (Stop) = ' ' or else Line (Stop) = ASCII.HT)
      loop
         Stop := Stop - 1;
      end loop;

      if Stop < Line'First or else not Is_Identifier_Body (Line (Stop)) then
         return "";
      end if;

      declare
         Start : Integer := Stop;
      begin
         while Start - 1 >= Line'First and then Is_Identifier_Body (Line (Start - 1)) loop
            Start := Start - 1;
         end loop;

         return Lower (Line (Start .. Stop));
      end;
   end Last_Word_Before;

   function Looks_Like_Attribute (Line : String; I : Integer) return Boolean is
      Prev : constant Character := Previous_Non_Space (Line, I - 1);
   begin
      return I < Line'Last
        and then Is_Identifier_Start (Line (I + 1))
        and then (Is_Identifier_Body (Prev) or else Prev = ')' or else Prev = ']');
   end Looks_Like_Attribute;

   procedure Classify_Line
     (Line          : String;
      Initial_State : Lexical_State;
      Visit         : not null access procedure
        (Start_Col : Natural;
         End_Col   : Natural;
         Kind      : Token_Kind);
      Final_State   : out Lexical_State)
   is
      I : Integer := Line'First;
      State : Lexical_State := Initial_State;

      procedure Emit
        (First : Integer;
         Last  : Integer;
         Kind  : Token_Kind)
      is
      begin
         if Last >= First then
            Visit
              (Start_Col => Natural (First - Line'First),
               End_Col   => Natural (Last - Line'First + 1),
               Kind      => Kind);
         end if;
      end Emit;

      procedure Scan_String (Starts_In_String : Boolean := False) is
         J : Integer := (if Starts_In_String then I else I + 1);
         Closed : Boolean := False;
      begin
         while J <= Line'Last loop
            if Line (J) = '"' then
               if J < Line'Last and then Line (J + 1) = '"' then
                  J := J + 2;
               else
                  Closed := True;
                  exit;
               end if;
            else
               J := J + 1;
            end if;
         end loop;

         if Closed then
            Emit (I, J, String_Literal);
            I := J + 1;
            State := Normal_State;
         else
            Emit (I, Line'Last, String_Literal);
            I := Line'Last + 1;
            State := In_Unterminated_String;
         end if;
      end Scan_String;

      procedure Scan_Number is
         J : Integer := I;
         Invalid : Boolean := False;
         Saw_Based_Mark : Boolean := False;
      begin
         while J <= Line'Last
           and then (Is_Digit (Line (J)) or else Line (J) = '_')
         loop
            J := J + 1;
         end loop;

         if J <= Line'Last and then Line (J) = '#' then
            Saw_Based_Mark := True;
            J := J + 1;
            while J <= Line'Last
              and then (Is_Hex_Digit (Line (J)) or else Line (J) = '_')
            loop
               J := J + 1;
            end loop;
            if J <= Line'Last and then Line (J) = '#' then
               J := J + 1;
            else
               Invalid := True;
            end if;
         end if;

         if not Saw_Based_Mark
           and then J <= Line'Last
           and then Line (J) = '.'
           and then (J = Line'Last or else Line (J + 1) /= '.')
         then
            J := J + 1;
            while J <= Line'Last
              and then (Is_Digit (Line (J)) or else Line (J) = '_')
            loop
               J := J + 1;
            end loop;
         end if;

         if J <= Line'Last and then (Line (J) = 'e' or else Line (J) = 'E') then
            J := J + 1;
            if J <= Line'Last and then (Line (J) = '+' or else Line (J) = '-') then
               J := J + 1;
            end if;
            if J > Line'Last or else not Is_Digit (Line (J)) then
               Invalid := True;
            end if;
            while J <= Line'Last
              and then (Is_Digit (Line (J)) or else Line (J) = '_')
            loop
               J := J + 1;
            end loop;
         end if;

         Emit (I, J - 1, Number_Literal);
         I := J;
         State := (if Invalid then In_Invalid_Number else Normal_State);
      end Scan_Number;

   begin
      Final_State := Normal_State;

      if Line'Length = 0 then
         Final_State := Normal_State;
         return;
      end if;

      if State = In_Unterminated_String then
         Scan_String (Starts_In_String => True);
      elsif State = In_Unterminated_Character then
         if I <= Line'Last and then Line (I) = Apostrophe then
            Emit (Line'First, I, Character_Literal);
            I := I + 1;
            State := Normal_State;
         else
            Emit (Line'First, Line'Last, Character_Literal);
            Final_State := In_Unterminated_Character;
            return;
         end if;
      else
         State := Normal_State;
      end if;

      while I <= Line'Last loop
         declare
            Ch : constant Character := Line (I);
         begin
            if Ch = '-'
              and then I < Line'Last
              and then Line (I + 1) = '-'
            then
               Emit (I, Line'Last, Comment);
               State := Normal_State;
               exit;

            elsif Ch = '"' then
               Scan_String;

            elsif Ch = Apostrophe
              and then Looks_Like_Attribute (Line, I)
            then
               declare
                  J : Integer := I + 1;
               begin
                  while J + 1 <= Line'Last and then Is_Identifier_Body (Line (J + 1)) loop
                     J := J + 1;
                  end loop;
                  Emit (I, J, Attribute);
                  I := J + 1;
                  State := Normal_State;
               end;

            elsif Ch = Apostrophe then
               declare
                  J : Integer := I + 1;
                  Closed : Boolean := False;
               begin
                  while J <= Line'Last loop
                     if Line (J) = Apostrophe then
                        Closed := True;
                        exit;
                     end if;
                     J := J + 1;
                  end loop;

                  if Closed then
                     Emit (I, J, Character_Literal);
                     I := J + 1;
                     State := Normal_State;
                  else
                     Emit (I, Line'Last, Character_Literal);
                     I := Line'Last + 1;
                     State := In_Unterminated_Character;
                  end if;
               end;

            elsif Is_Digit (Ch) then
               Scan_Number;

            elsif Is_Identifier_Start (Ch) then
               declare
                  J : Integer := I;
                  Kind : Token_Kind := Identifier;
                  Prev : constant String := Last_Word_Before (Line, I - 1);
               begin
                  while J + 1 <= Line'Last and then Is_Identifier_Body (Line (J + 1)) loop
                     J := J + 1;
                  end loop;

                  if Is_Keyword (Line (I .. J)) then
                     Kind := Keyword;
                  elsif Is_Predefined_Type (Line (I .. J)) then
                     Kind := Type_Identifier;
                  elsif Prev = "pragma"
                  then
                     Kind := Pragma_Name;
                  elsif Prev = "with"
                  then
                     Kind := Aspect_Name;
                  end if;

                  Emit (I, J, Kind);
                  I := J + 1;
                  State := Normal_State;
               end;

            elsif Ch = '<'
              and then I + 1 <= Line'Last
              and then Line (I + 1) = '<'
            then
               declare
                  J : Integer := I + 2;
               begin
                  while J + 1 <= Line'Last loop
                     exit when Line (J) = '>' and then Line (J + 1) = '>';
                     J := J + 1;
                  end loop;
                  if J + 1 <= Line'Last then
                     Emit (I, J + 1, Identifier);
                     I := J + 2;
                  else
                     Emit (I, Line'Last, Identifier);
                     I := Line'Last + 1;
                  end if;
               end;

            elsif Is_Operator_Char (Ch) then
               declare
                  Len : constant Natural := Is_Multi_Char_Operator (Line, I);
               begin
                  Emit (I, I + Integer (Len) - 1, Operator);
                  I := I + Integer (Len);
                  State := Normal_State;
               end;

            elsif Ch = '.'
              and then I < Line'Last
              and then Line (I + 1) = '.'
            then
               Emit (I, I + 1, Operator);
               I := I + 2;
               State := Normal_State;

            elsif Is_Punctuation_Char (Ch) then
               Emit (I, I, Punctuation);
               I := I + 1;
               State := Normal_State;

            else
               Emit (I, I, Plain_Text);
               I := I + 1;
            end if;
         end;
      end loop;

      Final_State := State;
   end Classify_Line;

   procedure Classify_Range
     (Line             : String;
      Line_Start_Index : Natural;
      Start_Index      : Natural;
      Stop_Index       : Natural;
      Visit            : not null access procedure
        (Start_Index : Natural;
         Stop_Index  : Natural;
         Kind        : Syntax_Kind))
   is
      procedure Local_Visit
        (Start_Col : Natural;
         End_Col   : Natural;
         Kind      : Token_Kind)
      is
         Abs_First : constant Natural := Line_Start_Index + Start_Col;
         Abs_Stop  : constant Natural := Line_Start_Index + End_Col;
         Clip_First : constant Natural := Natural'Max (Abs_First, Start_Index);
         Clip_Stop  : constant Natural := Natural'Min (Abs_Stop, Stop_Index);
      begin
         if Clip_First < Clip_Stop then
            Visit (Clip_First, Clip_Stop, Kind);
         end if;
      end Local_Visit;

      Final_State : Lexical_State;
   begin
      if Stop_Index <= Start_Index or else Line'Length = 0 then
         return;
      end if;

      Classify_Line
        (Line          => Line,
         Initial_State => Normal_State,
         Visit         => Local_Visit'Access,
         Final_State   => Final_State);
   end Classify_Range;

   function Kind_At
     (Line   : String;
      Column : Natural) return Syntax_Kind
   is
      Result : Syntax_Kind := Plain_Text;

      procedure Visit
        (Start_Index : Natural;
         Stop_Index  : Natural;
         Kind        : Syntax_Kind)
      is
      begin
         if Column >= Start_Index and then Column < Stop_Index then
            Result := Kind;
         end if;
      end Visit;
   begin
      if Column >= Line'Length then
         return Plain_Text;
      end if;

      Classify_Range
        (Line             => Line,
         Line_Start_Index => 0,
         Start_Index      => Column,
         Stop_Index       => Column + 1,
         Visit            => Visit'Access);

      return Result;
   end Kind_At;

   function Classify
     (Line : String;
      Col  : Natural) return Token_Kind is
   begin
      return Kind_At (Line, Col);
   end Classify;

end Editor.Syntax;
