with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Name_Profile_Helpers is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Read_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
   is
      I      : Natural := Start;
      K      : Natural;
      Len    : Natural := 0;
      Result : String (1 .. 256) := (others => ' ');

      procedure Append (C : Character) is
      begin
         if Len < Result'Length then
            Len := Len + 1;
            Result (Len) := C;
         end if;
      end Append;
   begin
      while I <= Text'Last
        and then (Text (I) = ' ' or else Text (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I > Text'Last
        or else not ((Text (I) >= 'A' and then Text (I) <= 'Z')
                     or else (Text (I) >= 'a' and then Text (I) <= 'z'))
      then
         return "";
      end if;

      loop
         if I > Text'Last
           or else not ((Text (I) >= 'A' and then Text (I) <= 'Z')
                        or else (Text (I) >= 'a' and then Text (I) <= 'z'))
         then
            exit;
         end if;

         while I <= Text'Last and then Is_Word_Char (Text (I)) loop
            Append (Text (I));
            I := I + 1;
         end loop;

         exit when not Allow_Dot;

         K := I;
         while K <= Text'Last
           and then (Text (K) = ' ' or else Text (K) = Ada.Characters.Latin_1.HT)
         loop
            K := K + 1;
         end loop;

         exit when K > Text'Last or else Text (K) /= '.';

         K := K + 1;
         while K <= Text'Last
           and then (Text (K) = ' ' or else Text (K) = Ada.Characters.Latin_1.HT)
         loop
            K := K + 1;
         end loop;

         exit when K > Text'Last
           or else not ((Text (K) >= 'A' and then Text (K) <= 'Z')
                        or else (Text (K) >= 'a' and then Text (K) <= 'z'));

         Append ('.');
         I := K;
      end loop;

      if Len = 0 then
         return "";
      else
         return Result (1 .. Len);
      end if;
   end Read_Name;


   function Read_Function_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
   is
      I : Natural := Start;
      J : Natural;
   begin
      while I <= Text'Last and then (Text (I) = ' ' or else Text (I) = Ada.Characters.Latin_1.HT) loop
         I := I + 1;
      end loop;
      if I <= Text'Last and then Text (I) = '"' then
         J := I + 1;
         while J <= Text'Last and then Text (J) /= '"' loop
            J := J + 1;
         end loop;
         if J <= Text'Last and then J > I + 1 then
            return Text (I .. J);
         end if;
         return "";
      end if;
      return Read_Name (Text, Start, Allow_Dot);
   end Read_Function_Name;

   function Declaration_Name_Position
     (Text          : String;
      Declared_Name : String) return Natural
   is
      Source : constant String := Lower (Text);
      Needle : constant String := Lower (Declared_Name);

      function Boundary_Before (Pos : Natural) return Boolean is
      begin
         return Pos = Source'First
           or else not (Is_Word_Char (Source (Pos - 1))
                        or else Source (Pos - 1) = '.');
      end Boundary_Before;

      function Boundary_After (Pos : Natural) return Boolean is
      begin
         return Pos > Source'Last
           or else not (Is_Word_Char (Source (Pos))
                        or else Source (Pos) = '.'
                        or else Source (Pos) = Character'Val (16#27#));
      end Boundary_After;
   begin
      if Needle'Length = 0 or else Source'Length < Needle'Length then
         return 0;
      end if;

      for I in Source'First .. Source'Last - Needle'Length + 1 loop
         if Source (I .. I + Needle'Length - 1) = Needle
           and then (Needle (Needle'First) = '"'
                     or else (Boundary_Before (I)
                              and then Boundary_After (I + Needle'Length)))
         then
            return Text'First + (I - Source'First);
         end if;
      end loop;

      return 0;
   end Declaration_Name_Position;

   function Read_Subtype_Mark
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
   is
      I : Natural := Start;
      J : Natural;
   begin
      while I <= Text'Last and then (Text (I) = ' ' or else Text (I) = Ada.Characters.Latin_1.HT) loop
         I := I + 1;
      end loop;

      if I > Text'Last
        or else not ((Text (I) >= 'A' and then Text (I) <= 'Z')
                     or else (Text (I) >= 'a' and then Text (I) <= 'z'))
      then
         return "";
      end if;

      J := I;
      while J <= Text'Last
        and then (Is_Word_Char (Text (J)) or else (Allow_Dot and then Text (J) = '.'))
      loop
         J := J + 1;
      end loop;

      if J <= Text'Last and then Text (J) = Character'Val (16#27#) then
         declare
            Suffix : constant String := Read_Name (Text, Positive (J + 1), False);
         begin
            if Lower (Suffix) = "class" or else Lower (Suffix) = "base" then
               return Text (I .. J) & Suffix;
            end if;
         end;
      end if;

      return Text (I .. J - 1);
   end Read_Subtype_Mark;


   function Profile_From
     (Line          : String;
      Declared_Name : String) return String
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      L    : constant String := Lower (Code);
      Name_Pos : Natural := 0;
      Stop : Natural := 0;
      Start : Natural := 0;
   begin
      if Declared_Name'Length = 0 then
         return "";
      end if;

      Name_Pos := Declaration_Name_Position (Line, Declared_Name);
      if Name_Pos = 0 then
         return "";
      end if;

      Start := Name_Pos + Declared_Name'Length;
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      if Starts_With_Word (L (Start .. L'Last), "is")
        or else Starts_With_Word (L (Start .. L'Last), "renames")
        or else Starts_With_Word (L (Start .. L'Last), "with")
        or else Starts_With_Word (L (Start .. L'Last), "when")
      then
         return "";
      end if;

      Stop := Line'Last;
      declare
         function Top_Level_Index_From_Profile_Start (Pattern : String) return Natural is
            Depth : Natural := 0;
         begin
            if Pattern'Length = 0
              or else Pattern'Length > L'Length
              or else Start > L'Last
            then
               return 0;
            end if;

            declare
               Last_Start : constant Natural := L'Last - Pattern'Length + 1;
            begin
               if Start > Last_Start then
                  return 0;
               end if;

               for I in Start .. Last_Start loop
                  if L (I) = '(' then
                     Depth := Depth + 1;
                  elsif L (I) = ')' then
                     if Depth > 0 then
                        Depth := Depth - 1;
                     end if;
                  elsif Depth = 0
                    and then L (I .. I + Pattern'Length - 1) = Pattern
                  then
                     return I;
                  end if;
               end loop;
            end;

            return 0;
         end Top_Level_Index_From_Profile_Start;

         function Top_Level_Semicolon_From_Profile_Start return Natural is
            Depth : Natural := 0;
         begin
            if Start > L'Last then
               return 0;
            end if;

            for I in Start .. L'Last loop
               if L (I) = '(' then
                  Depth := Depth + 1;
               elsif L (I) = ')' then
                  if Depth > 0 then
                     Depth := Depth - 1;
                  end if;
               elsif L (I) = ';' and then Depth = 0 then
                  return I;
               end if;
            end loop;
            return 0;
         end Top_Level_Semicolon_From_Profile_Start;

         Semi     : constant Natural := Top_Level_Semicolon_From_Profile_Start;
         Is_Pos   : constant Natural := Top_Level_Index_From_Profile_Start (" is");
         Ren_Pos  : constant Natural := Top_Level_Index_From_Profile_Start (" renames");
         When_Pos : constant Natural := Top_Level_Index_From_Profile_Start (" when ");
         With_Pos : constant Natural := Top_Level_Index_From_Profile_Start (" with ");
      begin
         if Semi /= 0 then
            Stop := Natural'Min (Stop, Semi - 1);
         end if;
         if Is_Pos /= 0 then
            Stop := Natural'Min (Stop, Is_Pos - 1);
         end if;
         if Ren_Pos /= 0 then
            Stop := Natural'Min (Stop, Ren_Pos - 1);
         end if;
         if When_Pos /= 0 then
            --  Feed_Item bodies include a barrier before the body-opening "is":
            --     entry E (Item : T) when Ready is
            --  The barrier is body metadata, not part of the callable
            --  parameter/profile summary used by Outline and overload labels.
            Stop := Natural'Min (Stop, When_Pos - 1);
         end if;
         if With_Pos /= 0 then
            --  Ada 2012 aspect clauses after a subprogram declaration are
            --  declaration metadata, not overload/profile text.  Keep the
            --  profile summary bounded to the callable signature so Outline
            --  labels and overload disambiguation do not include aspect
            --  expressions such as "with Import" or "with Inline".
            Stop := Natural'Min (Stop, With_Pos - 1);
         end if;
      end;

      if Stop < Start then
         return "";
      end if;
      return Trim (Line (Start .. Stop));
   end Profile_From;

   function Profile_Continuation_From_Line (Line : String) return String is
      Clean : constant String := Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      L     : constant String := Lower (Clean);
      Stop  : Natural := Clean'Last;
      Depth : Natural := 0;
      Seen_Close : Boolean := False;
   begin
      if Clean'Length = 0 or else Clean (Clean'First) /= '(' then
         return "";
      end if;

      for I in Clean'Range loop
         if L (I) = '(' then
            Depth := Depth + 1;
         elsif L (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
            if Depth = 0 then
               Seen_Close := True;
            end if;
         elsif Depth = 0 then
            if L (I) = ';' then
               Stop := I - 1;
               exit;
            elsif I + 2 <= L'Last and then L (I .. I + 2) = " is" then
               Stop := I - 1;
               exit;
            elsif I + 5 <= L'Last and then L (I .. I + 5) = " with " then
               Stop := I - 1;
               exit;
            elsif I + 7 <= L'Last and then L (I .. I + 7) = " renames" then
               Stop := I - 1;
               exit;
            end if;
         end if;
      end loop;

      if not Seen_Close or else Stop < Clean'First then
         return "";
      end if;

      return Trim (Clean (Clean'First .. Stop));
   end Profile_Continuation_From_Line;

   function Strip_Prefixes (Line : String) return String is
      S : constant String := Trim (Editor.Ada_Syntax_Core.Strip_Separate_Prefix (Line));
   begin
      if Starts_With (Lower (S), "not overriding ") and then S'Length > 15 then
         return Strip_Prefixes (S (S'First + 15 .. S'Last));
      elsif Starts_With (Lower (S), "overriding ") and then S'Length > 11 then
         return Strip_Prefixes (S (S'First + 11 .. S'Last));
      elsif Starts_With (Lower (S), "abstract ") and then S'Length > 9 then
         return Strip_Prefixes (S (S'First + 9 .. S'Last));
      elsif Starts_With (Lower (S), "private package ")
        and then S'Length > 8
      then
         --  Preserve private child packages as package declarations without
         --  duplicating the package keyword.
         return S (S'First + 8 .. S'Last);
      else
         return S;
      end if;
   end Strip_Prefixes;

   function Target_After (Line, Marker : String) return String is
      L : constant String := Lower (Line);
      P : constant Natural := Ada.Strings.Fixed.Index (L, Marker);
      Start : Natural;
   begin
      if P = 0 then
         return "";
      end if;
      Start := Line'First + (P - L'First) + Marker'Length;
      return Read_Function_Name (Line, Positive (Start), True);
   end Target_After;


end Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
