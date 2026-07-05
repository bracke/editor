with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Token_Cursor.Tokenization is

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Is_Letter (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z') or else (C >= 'a' and then C <= 'z');
   end Is_Letter;

   function Is_Digit (C : Character) return Boolean is
   begin
      return C >= '0' and then C <= '9';
   end Is_Digit;

   function Is_Identifier_Char (C : Character) return Boolean is
   begin
      return Is_Letter (C) or else Is_Digit (C) or else C = '_';
   end Is_Identifier_Char;

   function Is_Keyword (S : String) return Boolean is
      L : constant String := Lower (S);
   begin
      return L = "abort" or else L = "abs" or else L = "abstract"
        or else L = "accept" or else L = "access" or else L = "aliased"
        or else L = "all" or else L = "and" or else L = "array"
        or else L = "at" or else L = "begin" or else L = "body"
        or else L = "case" or else L = "constant" or else L = "declare"
        or else L = "delay" or else L = "delta" or else L = "digits"
        or else L = "do" or else L = "else" or else L = "elsif"
        or else L = "end" or else L = "entry" or else L = "exception"
        or else L = "exit" or else L = "for" or else L = "function"
        or else L = "generic" or else L = "goto" or else L = "if"
        or else L = "in" or else L = "interface" or else L = "is"
        or else L = "limited" or else L = "loop" or else L = "mod"
        or else L = "new" or else L = "not" or else L = "null"
        or else L = "of" or else L = "or" or else L = "others"
        or else L = "out" or else L = "overriding" or else L = "package"
        or else L = "parallel"
        or else L = "pragma" or else L = "private" or else L = "procedure"
        or else L = "protected" or else L = "raise" or else L = "range"
        or else L = "record" or else L = "rem" or else L = "renames"
        or else L = "requeue" or else L = "return" or else L = "reverse"
        or else L = "select" or else L = "separate" or else L = "some"
        or else L = "subtype" or else L = "synchronized" or else L = "tagged"
        or else L = "task" or else L = "terminate" or else L = "then"
        or else L = "type" or else L = "until" or else L = "use"
        or else L = "when" or else L = "while" or else L = "with" or else L = "xor";
   end Is_Keyword;

   procedure Append_Token
     (Stream : in out Token_Stream;
      Kind   : Token_Kind;
      Text   : String;
      Line   : Positive;
      Column : Positive) is
      Info : Token_Info;
   begin
      Info.Kind := Kind;
      Info.Text := To_Unbounded_String (Text);
      Info.Lower := To_Unbounded_String (Lower (Text));
      Info.Line := Line;
      Info.Column := Column;
      Stream.Tokens.Append (Info);
   end Append_Token;

   function Tokenize (Text : String) return Token_Stream is
      Stream : Token_Stream;
      I      : Natural := Text'First;
      Line   : Positive := 1;
      Column : Positive := 1;
   begin
      if Text'Length = 0 then
         Append_Token (Stream, Token_End_Of_Input, "", Line, Column);
         return Stream;
      end if;

      while I <= Text'Last loop
         declare
            C : constant Character := Text (I);
         begin
            if C = Ada.Characters.Latin_1.LF then
               Line := Line + 1;
               Column := 1;
               I := I + 1;
            elsif C = Ada.Characters.Latin_1.CR or else C = ' ' or else C = Ada.Characters.Latin_1.HT then
               Column := Column + 1;
               I := I + 1;
            elsif C = '-' and then I < Text'Last and then Text (I + 1) = '-' then
               while I <= Text'Last and then Text (I) /= Ada.Characters.Latin_1.LF loop
                  I := I + 1;
                  Column := Column + 1;
               end loop;
            elsif Is_Letter (C) then
               declare
                  Start : constant Natural := I;
                  Col   : constant Positive := Column;
               begin
                  while I <= Text'Last and then Is_Identifier_Char (Text (I)) loop
                     I := I + 1;
                     Column := Column + 1;
                  end loop;
                  declare
                     Lexeme : constant String := Text (Start .. I - 1);
                  begin
                     Append_Token
                       (Stream,
                        (if Is_Keyword (Lexeme) then Token_Keyword else Token_Identifier),
                        Lexeme, Line, Col);
                  end;
               end;
            elsif Is_Digit (C) then
               declare
                  Start : constant Natural := I;
                  Col   : constant Positive := Column;
               begin
                  while I <= Text'Last
                    and then (Is_Identifier_Char (Text (I)) or else Text (I) = '.' or else Text (I) = '#')
                  loop
                     exit when Text (I) = '.' and then I < Text'Last and then Text (I + 1) = '.';
                     I := I + 1;
                     Column := Column + 1;
                  end loop;
                  Append_Token (Stream, Token_Numeric_Literal, Text (Start .. I - 1), Line, Col);
               end;
            elsif C = '"' then
               declare
                  Start : constant Natural := I;
                  Col   : constant Positive := Column;
               begin
                  I := I + 1;
                  Column := Column + 1;
                  while I <= Text'Last loop
                     if Text (I) = '"' then
                        I := I + 1;
                        Column := Column + 1;
                        exit when I > Text'Last or else Text (I) /= '"';
                     elsif Text (I) = Ada.Characters.Latin_1.LF then
                        exit;
                     else
                        I := I + 1;
                        Column := Column + 1;
                     end if;
                  end loop;
                  Append_Token (Stream, Token_String_Literal, Text (Start .. I - 1), Line, Col);
               end;
            elsif Character'Pos (C) = 39 then
               declare
                  Start : constant Natural := I;
                  Col   : constant Positive := Column;
               begin
                  if I + 2 <= Text'Last and then Character'Pos (Text (I + 2)) = 39 then
                     I := I + 3;
                     Column := Column + 3;
                     Append_Token (Stream, Token_Character_Literal, Text (Start .. I - 1), Line, Col);
                  else
                     Append_Token (Stream, Token_Operator, Text (I .. I), Line, Col);
                     I := I + 1;
                     Column := Column + 1;
                  end if;
               end;
            else
               declare
                  Col : constant Positive := Column;
               begin
                  if I < Text'Last then
                     declare
                        Two : constant String := Text (I .. I + 1);
                     begin
                        if Two = ":=" or else Two = "=>" or else Two = ".." or else Two = "**"
                          or else Two = "/=" or else Two = "<=" or else Two = ">="
                          or else Two = "<>" or else Two = "<<" or else Two = ">>"
                        then
                           Append_Token (Stream, Token_Operator, Two, Line, Col);
                           I := I + 2;
                           Column := Column + 2;
                        else
                           Append_Token
                             (Stream,
                              (if C = '(' or else C = ')' or else C = ';' or else C = ',' or else C = ':' then Token_Separator else Token_Operator),
                              Text (I .. I), Line, Col);
                           I := I + 1;
                           Column := Column + 1;
                        end if;
                     end;
                  else
                     Append_Token
                       (Stream,
                        (if C = '(' or else C = ')' or else C = ';' or else C = ',' or else C = ':' then Token_Separator else Token_Operator),
                        Text (I .. I), Line, Col);
                     I := I + 1;
                     Column := Column + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      Append_Token (Stream, Token_End_Of_Input, "", Line, Column);
      return Stream;
   end Tokenize;

   function Length (Stream : Token_Stream) return Natural is
   begin
      return Natural (Stream.Tokens.Length);
   end Length;

   function Token_At (Stream : Token_Stream; Index : Positive) return Token_Info is
   begin
      if Index > Natural (Stream.Tokens.Length) then
         return (Kind => Token_End_Of_Input, Text => Null_Unbounded_String,
                 Lower => Null_Unbounded_String, Line => 1, Column => 1);
      end if;
      return Stream.Tokens (Index);
   end Token_At;

   function First (Stream : Token_Stream) return Cursor is
   begin
      return (Stream => Stream, Index => 1);
   end First;

   function At_End (Position : Cursor) return Boolean is
   begin
      return Position.Index > Natural (Position.Stream.Tokens.Length)
        or else Position.Stream.Tokens (Position.Index).Kind = Token_End_Of_Input;
   end At_End;

   function Current (Position : Cursor) return Token_Info is
   begin
      return Token_At (Position.Stream, Position.Index);
   end Current;

   procedure Advance (Position : in out Cursor) is
   begin
      if Position.Index < Natural (Position.Stream.Tokens.Length) then
         Position.Index := Position.Index + 1;
      end if;
   end Advance;

   function Mark (Position : Cursor) return Natural is
   begin
      return Position.Index;
   end Mark;

   procedure Restore (Position : in out Cursor; To_Mark : Natural) is
   begin
      if To_Mark >= 1 and then To_Mark <= Natural (Position.Stream.Tokens.Length) then
         Position.Index := To_Mark;
      end if;
   end Restore;

end Editor.Ada_Token_Cursor.Tokenization;
