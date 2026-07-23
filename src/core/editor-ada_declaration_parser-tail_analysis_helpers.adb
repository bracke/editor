with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers is
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Tail_Token_At
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean
   is
   begin
      return Lexical_Helpers.Starts_At_Word (Lowered_Text, Pos, Token);
   end Tail_Token_At;

   function Previous_Token_Is_End
     (Lowered_Text : String;
      Pos          : Natural) return Boolean
   is
      J : Natural := Pos;
   begin
      if Pos <= Lowered_Text'First then
         return False;
      end if;

      J := Pos - 1;
      while J >= Lowered_Text'First and then Lowered_Text (J) = ' ' loop
         exit when J = Lowered_Text'First;
         J := J - 1;
      end loop;

      return J >= Lowered_Text'First + 2
        and then Lowered_Text (J - 2 .. J) = "end"
        and then (J = Lowered_Text'Last
                  or else not Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J + 1)))
        and then (J - 2 = Lowered_Text'First
                  or else not Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J - 3)));
   end Previous_Token_Is_End;

   function End_Followed_By
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean
   is
      J : Natural := Pos + 3;
   begin
      if not Tail_Token_At (Lowered_Text, Pos, "end") then
         return False;
      end if;

      while J <= Lowered_Text'Last
        and then (Lowered_Text (J) = ' '
                  or else Lowered_Text (J) = Ada.Characters.Latin_1.HT)
      loop
         J := J + 1;
      end loop;

      return Tail_Token_At (Lowered_Text, J, Token);
   end End_Followed_By;

   function Tail_After_Arrow (Line : String) return String is
      Code  : constant String := Normalized_Line (Line);
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Code, "=>");
   begin
      if Arrow = 0 or else Arrow + 2 > Code'Last then
         return "";
      end if;

      return Trim (Code (Arrow + 2 .. Code'Last));
   end Tail_After_Arrow;

   function Tail_After_Leading_Word
     (Line, Word : String) return String
   is
      Start : constant Natural := Line'First + Word'Length;
   begin
      if not Editor.Text_Helpers.Starts_With_Word (Line, Word)
        or else Start > Line'Last
      then
         return "";
      end if;

      return Trim (Line (Start .. Line'Last));
   end Tail_After_Leading_Word;

   function Strip_Leading_Statement_Labels (Text : String) return String is
      Work : constant String := Trim (Text);
   begin
      if Work'Length >= 4
        and then Work (Work'First .. Work'First + 1) = "<<"
      then
         declare
            Close : constant Natural := Ada.Strings.Fixed.Index (Work, ">>");
         begin
            if Close /= 0 and then Close + 2 <= Work'Last then
               return Strip_Leading_Statement_Labels
                 (Work (Close + 2 .. Work'Last));
            elsif Close /= 0 then
               return "";
            end if;
         end;
      end if;
      return Work;
   end Strip_Leading_Statement_Labels;

   function Strip_Leading_Named_Statement_Prefix
     (Text : String) return String
   is
      Work  : constant String := Trim (Text);
      Colon : constant Natural := Ada.Strings.Fixed.Index (Work, ":");

      function Prefix_Is_Identifier return Boolean is
      begin
         if Colon = 0 or else Colon = Work'First then
            return False;
         end if;

         declare
            Prefix : constant String := Trim (Work (Work'First .. Colon - 1));
         begin
            if Prefix'Length = 0 then
               return False;
            elsif not ((Prefix (Prefix'First) >= 'A' and then Prefix (Prefix'First) <= 'Z')
                       or else (Prefix (Prefix'First) >= 'a' and then Prefix (Prefix'First) <= 'z'))
            then
               return False;
            elsif Prefix (Prefix'Last) = '_' then
               return False;
            end if;

            for I in Prefix'Range loop
               if not Lexical_Helpers.Is_Name_Char (Prefix (I)) then
                  return False;
               elsif Prefix (I) = '_'
                 and then I < Prefix'Last
                 and then Prefix (I + 1) = '_'
               then
                  return False;
               end if;
            end loop;
         end;

         return True;
      end Prefix_Is_Identifier;
   begin
      if Prefix_Is_Identifier and then Colon < Work'Last then
         declare
            Tail : constant String := Trim (Work (Colon + 1 .. Work'Last));
         begin
            if Editor.Text_Helpers.Starts_With_Word (Tail, "declare")
              or else Editor.Text_Helpers.Starts_With_Word (Tail, "begin")
              or else Editor.Text_Helpers.Starts_With_Word (Tail, "loop")
              or else Editor.Text_Helpers.Starts_With_Word (Tail, "while")
              or else Editor.Text_Helpers.Starts_With_Word (Tail, "for")
            then
               return Tail;
            end if;
         end;
      end if;

      return Work;
   end Strip_Leading_Named_Statement_Prefix;

   function Leading_Statement_Label_Count (Text : String) return Natural is
      Work : constant String := Trim (Text);
   begin
      if Work'Length >= 4
        and then Work (Work'First .. Work'First + 1) = "<<"
      then
         declare
            Close : constant Natural := Ada.Strings.Fixed.Index (Work, ">>");
         begin
            if Close = 0 then
               return 0;
            elsif Close + 2 <= Work'Last then
               return 1 +
                 Leading_Statement_Label_Count (Work (Close + 2 .. Work'Last));
            else
               return 1;
            end if;
         end;
      end if;

      return 0;
   end Leading_Statement_Label_Count;

   function Is_Selected_Name_Blank (C : Character) return Boolean is
   begin
      return C = ' ' or else C = Ada.Characters.Latin_1.HT;
   end Is_Selected_Name_Blank;

   function Compact_Selected_Name_At
     (Lowered_Text : String;
      Pos          : Natural;
      Max_Length   : Positive) return String
   is
      J      : Natural := Pos;
      Len    : Natural := 0;
      Result : String (1 .. Max_Length) := (others => ' ');

      procedure Append (C : Character) is
      begin
         if Len < Result'Length then
            Len := Len + 1;
            Result (Len) := C;
         end if;
      end Append;
   begin
      while J <= Lowered_Text'Last loop
         while J <= Lowered_Text'Last and then Is_Selected_Name_Blank (Lowered_Text (J)) loop
            J := J + 1;
         end loop;

         exit when J > Lowered_Text'Last
           or else not Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J));

         while J <= Lowered_Text'Last
           and then Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J))
         loop
            Append (Lowered_Text (J));
            J := J + 1;
         end loop;

         while J <= Lowered_Text'Last and then Is_Selected_Name_Blank (Lowered_Text (J)) loop
            J := J + 1;
         end loop;

         exit when J > Lowered_Text'Last or else Lowered_Text (J) /= '.';
         Append ('.');
         J := J + 1;
      end loop;

      if Len = 0 or else Result (Len) = '.' then
         return "";
      else
         return Result (1 .. Len);
      end if;
   end Compact_Selected_Name_At;

   function Compact_Selected_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
   begin
      return Compact_Selected_Name_At (Lowered_Text, Pos, 80);
   end Compact_Selected_Name_At;

   function Previous_Selected_Name_Before
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
      J          : Natural := Pos;
      Last_Name   : Natural;
      First_Name  : Natural;
   begin
      if Pos <= Lowered_Text'First then
         return "";
      end if;

      J := Pos - 1;
      while J >= Lowered_Text'First and then Is_Selected_Name_Blank (Lowered_Text (J)) loop
         exit when J = Lowered_Text'First;
         J := J - 1;
      end loop;

      if J < Lowered_Text'First or else not Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J)) then
         return "";
      end if;

      Last_Name := J;
      while J > Lowered_Text'First and then Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J - 1)) loop
         J := J - 1;
      end loop;
      First_Name := J;

      return Lowered_Text (First_Name .. Last_Name);
   end Previous_Selected_Name_Before;

   function Anonymous_Declare_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
      J : Natural := Pos;
   begin
      if Pos <= Lowered_Text'First then
         return "";
      end if;

      J := Pos - 1;
      while J >= Lowered_Text'First and then Is_Selected_Name_Blank (Lowered_Text (J)) loop
         exit when J = Lowered_Text'First;
         J := J - 1;
      end loop;

      if J < Lowered_Text'First or else not Editor.Text_Helpers.Is_Word_Char (Lowered_Text (J)) then
         return "";
      end if;

      return Previous_Selected_Name_Before (Lowered_Text, J);
   end Anonymous_Declare_Name_At;

   function Compact_Package_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
      J : Natural := Pos;
   begin
      if not Tail_Token_At (Lowered_Text, Pos, "package") then
         return "";
      end if;

      J := Pos + 7;
      while J <= Lowered_Text'Last
        and then (Lowered_Text (J) = ' '
                  or else Lowered_Text (J) = Ada.Characters.Latin_1.HT)
      loop
         J := J + 1;
      end loop;

      if Tail_Token_At (Lowered_Text, J, "body") then
         J := J + 4;
         while J <= Lowered_Text'Last
           and then (Lowered_Text (J) = ' '
                     or else Lowered_Text (J) = Ada.Characters.Latin_1.HT)
         loop
            J := J + 1;
         end loop;
      end if;

      return Compact_Selected_Name_At (Lowered_Text, J);
   end Compact_Package_Name_At;

   function Compact_Callable_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
      J : Natural := Pos;
      K : Natural;
   begin
      if Tail_Token_At (Lowered_Text, Pos, "procedure") then
         J := Pos + 9;
      elsif Tail_Token_At (Lowered_Text, Pos, "function") then
         J := Pos + 8;
      else
         return "";
      end if;

      while J <= Lowered_Text'Last
        and then (Lowered_Text (J) = ' '
                  or else Lowered_Text (J) = Ada.Characters.Latin_1.HT)
      loop
         J := J + 1;
      end loop;

      if J > Lowered_Text'Last then
         return "";
      elsif Lowered_Text (J) = '"' then
         K := J + 1;
         while K <= Lowered_Text'Last and then Lowered_Text (K) /= '"' loop
            K := K + 1;
         end loop;
         if K <= Lowered_Text'Last then
            return Lowered_Text (J .. K);
         else
            return "";
         end if;
      end if;

      return Compact_Selected_Name_At (Lowered_Text, J);
   end Compact_Callable_Name_At;

   function Has_Nested_Compact_Scope_Opener
     (Lowered_Text : String;
      Pos          : Natural) return Boolean
   is
      J      : Natural := Pos;
      Saw_Is : Boolean := False;
   begin
      if not Tail_Token_At (Lowered_Text, Pos, "package") then
         return False;
      end if;

      declare
         Candidate_Name : constant String := Compact_Package_Name_At (Lowered_Text, Pos);
      begin
         if Candidate_Name'Length = 0 then
            return False;
         end if;
      end;

      while J <= Lowered_Text'Last loop
         exit when Lowered_Text (J) = ';';

         if Tail_Token_At (Lowered_Text, J, "renames")
           or else Tail_Token_At (Lowered_Text, J, "new")
         then
            return False;
         elsif Tail_Token_At (Lowered_Text, J, "is") then
            Saw_Is := True;
         end if;

         J := J + 1;
      end loop;

      return Saw_Is;
   end Has_Nested_Compact_Scope_Opener;

   function Generic_Anonymous_Declare_Name_At
     (Lowered_Text : String;
      Pos          : Natural) return String
   is
   begin
      return Anonymous_Declare_Name_At (Lowered_Text, Pos);
   end Generic_Anonymous_Declare_Name_At;

   function Generic_End_Followed_By
     (Lowered_Text : String;
      Pos          : Natural;
      Token        : String) return Boolean
   is
   begin
      return End_Followed_By (Lowered_Text, Pos, Token);
   end Generic_End_Followed_By;

   function Generic_End_Is_Metadata_Or_Control
     (Lowered_Text : String;
      Pos          : Natural) return Boolean
   is
   begin
      return End_Followed_By (Lowered_Text, Pos, "record")
        or else End_Followed_By (Lowered_Text, Pos, "case")
        or else End_Followed_By (Lowered_Text, Pos, "if")
        or else End_Followed_By (Lowered_Text, Pos, "loop")
        or else End_Followed_By (Lowered_Text, Pos, "select")
        or else End_Followed_By (Lowered_Text, Pos, "return");
   end Generic_End_Is_Metadata_Or_Control;

end Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
