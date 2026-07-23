with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Source_Awareness is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Language_Model;

   function Starts_With_With_Context_Clause (Lower_Line : String) return Boolean is
      Rest : String (1 .. 512) := (others => ' ');
      Len  : Natural := 0;

      procedure Set_Rest (Value : String) is
      begin
         Len := Natural'Min (Value'Length, Rest'Length);
         if Len > 0 then
            Rest (1 .. Len) := Value (Value'First .. Value'First + Len - 1);
         end if;
      end Set_Rest;
   begin
      if Starts_With_Word (Lower_Line, "with") then
         return True;
      elsif Starts_With_Word (Lower_Line, "limited") then
         if Lower_Line'Length <= 7 then
            return False;
         end if;
         declare
            Tail : constant String := Trim (Lower_Line (Lower_Line'First + 7 .. Lower_Line'Last));
         begin
            Set_Rest (Tail);
         end;
      elsif Starts_With_Word (Lower_Line, "private") then
         if Lower_Line'Length <= 7 then
            return False;
         end if;
         declare
            Tail : constant String := Trim (Lower_Line (Lower_Line'First + 7 .. Lower_Line'Last));
         begin
            Set_Rest (Tail);
         end;
      else
         return False;
      end if;

      if Len = 0 then
         return False;
      end if;

      if Starts_With_Word (Rest (1 .. Len), "with") then
         return True;
      elsif Starts_With_Word (Rest (1 .. Len), "private") then
         if Len <= 7 then
            return False;
         end if;
         declare
            Tail : constant String := Trim (Rest (1 + 7 .. Len));
         begin
            return Starts_With_Word (Tail, "with");
         end;
      else
         return False;
      end if;
   end Starts_With_With_Context_Clause;

   function Starts_With_Use_Clause (Lower_Line : String) return Boolean is
   begin
      return Starts_With_Word (Lower_Line, "use");
   end Starts_With_Use_Clause;

   procedure Add_Context_Names
     (Analysis             : in out Analysis_Result;
      Kind                 : Visibility_Clause_Kind;
      Names                : String;
      Scope                : Scope_Id;
      Line_Number          : Positive;
      Base_Column          : Positive;
      Is_Context_Clause    : Boolean := False;
      Has_Limited_Modifier : Boolean := False;
      Has_Private_Modifier : Boolean := False)
   is
      I : Natural := Names'First;
      Segment_Start : Natural := Names'First;

      procedure Add_Segment (First, Last : Natural) is
         Segment_First : Natural := First;
         Segment_Last  : Natural := Last;
      begin
         if Last < First then
            return;
         end if;

         while Segment_First <= Segment_Last
           and then (Names (Segment_First) = ' '
                     or else Names (Segment_First) = ASCII.HT)
         loop
            Segment_First := Segment_First + 1;
         end loop;

         while Segment_Last >= Segment_First
           and then (Names (Segment_Last) = ' '
                     or else Names (Segment_Last) = ASCII.HT)
         loop
            Segment_Last := Segment_Last - 1;
         end loop;

         if Segment_Last < Segment_First then
            return;
         end if;

         declare
            Raw : constant String := Names (Segment_First .. Segment_Last);
         begin
            if Raw'Length = 0 then
               return;
            end if;

            Add_Visibility_Clause
              (Analysis, Kind, Raw, Scope,
               (Start_Line => Line_Number,
                Start_Column => Base_Column + Segment_First - Names'First,
                End_Line => Line_Number,
                End_Column => Base_Column + Segment_Last - Names'First),
               Is_Context_Clause,
               Has_Limited_Modifier,
               Has_Private_Modifier);
         end;
      end Add_Segment;
   begin
      if Names'Length = 0 then
         return;
      end if;

      while I <= Names'Last loop
         if Names (I) = ',' or else Names (I) = ';' then
            Add_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      if Segment_Start <= Names'Last then
         Add_Segment (Segment_Start, Names'Last);
      end if;
   end Add_Context_Names;

   function After_Context_Introducer
     (Lower_Line : String;
      Prefix     : String) return Natural
   is
      Pos : Natural := Ada.Strings.Fixed.Index (Lower_Line, Prefix);
   begin
      if Pos = 0 then
         return 0;
      end if;
      return Pos + Prefix'Length;
   end After_Context_Introducer;

   procedure Mark_Context_Clause_Awareness
     (Analysis    : in out Analysis_Result;
      Line        : String;
      Line_Number : Positive;
      Scope       : Scope_Id)
   is
      Code       : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Line);
      Trimmed    : constant String := Trim (Code);
      Lower_Line : constant String := Lower (Trimmed);
      Start      : Natural := 0;
      Kind       : Visibility_Clause_Kind := Visibility_With_Clause;
      Saw_Limited : Boolean := False;
      Saw_Private : Boolean := False;
      Is_Context  : constant Boolean := Scope = Root_Scope;
   begin
      if Lower_Line'Length = 0 then
         return;
      end if;

      if Starts_With_With_Context_Clause (Lower_Line) then
         Saw_Limited := Starts_With_Word (Lower_Line, "limited");
         Saw_Private := Starts_With_Word (Lower_Line, "private")
           or else Starts_With_Word (Lower_Line, "limited private");

         if Saw_Private then
            Kind := Visibility_Private_With_Clause;
         elsif Saw_Limited then
            Kind := Visibility_Limited_With_Clause;
         else
            Kind := Visibility_With_Clause;
         end if;

         Start := After_Context_Introducer (Lower_Line, "with " );
         if Start /= 0 and then Start <= Trimmed'Length then
            Add_Context_Names
              (Analysis, Kind, Trimmed (Start .. Trimmed'Last), Scope,
               Line_Number, Positive (Start), Is_Context,
               Saw_Limited, Saw_Private);
         else
            Mark_With_Clause_Awareness (Analysis);
         end if;
      elsif Starts_With_Use_Clause (Lower_Line) then
         Start := After_Context_Introducer (Lower_Line, "use all type " );
         if Start /= 0 then
            Kind := Visibility_Use_All_Type_Clause;
         else
            Start := After_Context_Introducer (Lower_Line, "use type " );
            if Start /= 0 then
               Kind := Visibility_Use_Type_Clause;
            else
               Start := After_Context_Introducer (Lower_Line, "use " );
               Kind := Visibility_Use_Package_Clause;
            end if;
         end if;

         if Start /= 0 and then Start <= Trimmed'Length then
            Add_Context_Names
              (Analysis, Kind, Trimmed (Start .. Trimmed'Last), Scope,
               Line_Number, Positive (Start), Is_Context);
         else
            Mark_Use_Clause_Awareness (Analysis);
         end if;
      end if;
   end Mark_Context_Clause_Awareness;

   procedure Mark_Source_Awareness
     (Analysis : in out Analysis_Result;
      Line     : String)
   is
      Lower_Line : constant String := Lower (Line);
   begin
      if Ada.Strings.Fixed.Index (Lower_Line, "@generated") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "auto-generated") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "generated by") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "do not edit") /= 0
      then
         Mark_Generated_Source_Awareness (Analysis);
      end if;

      if Ada.Strings.Fixed.Index (Lower_Line, "#if") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "#elsif") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "#else") /= 0
        or else Ada.Strings.Fixed.Index (Lower_Line, "#end") /= 0
      then
         Mark_Conditional_Source_Awareness (Analysis);
      end if;
   end Mark_Source_Awareness;

   function Is_Invalid_Compact_Owner_Name (Name : String) return Boolean is
      Lower_Name : constant String := Lower (Trim (Name));
      Start      : Positive := Lower_Name'First;
      Stop       : Natural;

      function Is_Valid_Quoted_Operator_Name (Word : String) return Boolean is
         Inner : String (1 .. Word'Length) := (others => ' ');
         Len   : Natural := 0;
      begin
         if Word'Length < 2
           or else Word (Word'First) /= '"'
           or else Word (Word'Last) /= '"'
         then
            return False;
         end if;

         for I in Word'First + 1 .. Word'Last - 1 loop
            if Word (I) /= ' ' and then Word (I) /= Ada.Characters.Latin_1.HT then
               Len := Len + 1;
               Inner (Len) := Word (I);
            end if;
         end loop;

         if Len = 0 then
            return False;
         end if;

         declare
            Op : constant String := Inner (1 .. Len);
         begin
            return Op = "+"
              or else Op = "-"
              or else Op = "*"
              or else Op = "/"
              or else Op = "**"
              or else Op = "="
              or else Op = "/="
              or else Op = "<"
              or else Op = "<="
              or else Op = ">"
              or else Op = ">="
              or else Op = "&"
              or else Op = "and"
              or else Op = "or"
              or else Op = "xor"
              or else Op = "not"
              or else Op = "abs"
              or else Op = "mod"
              or else Op = "rem";
         end;
      end Is_Valid_Quoted_Operator_Name;

      function Is_Valid_Ada_Identifier_Component (Word : String) return Boolean is
      begin
         if Word'Length = 0 then
            return False;
         elsif not ((Word (Word'First) >= 'a' and then Word (Word'First) <= 'z')
                    or else (Word (Word'First) >= 'A' and then Word (Word'First) <= 'Z'))
         then
            return False;
         elsif Word (Word'Last) = '_' then
            return False;
         end if;

         for I in Word'Range loop
            if not Is_Word_Char (Word (I)) then
               return False;
            elsif Word (I) = '_'
              and then I < Word'Last
              and then Word (I + 1) = '_'
            then
               return False;
            end if;
         end loop;

         return True;
      end Is_Valid_Ada_Identifier_Component;

      function Is_Ada_Reserved_Word (Word : String) return Boolean is
      begin
         return Word = "abort"
           or else Word = "abs"
           or else Word = "abstract"
           or else Word = "accept"
           or else Word = "access"
           or else Word = "aliased"
           or else Word = "all"
           or else Word = "and"
           or else Word = "array"
           or else Word = "at"
           or else Word = "begin"
           or else Word = "body"
           or else Word = "case"
           or else Word = "constant"
           or else Word = "declare"
           or else Word = "delay"
           or else Word = "delta"
           or else Word = "digits"
           or else Word = "do"
           or else Word = "else"
           or else Word = "elsif"
           or else Word = "end"
           or else Word = "entry"
           or else Word = "exception"
           or else Word = "exit"
           or else Word = "for"
           or else Word = "function"
           or else Word = "generic"
           or else Word = "goto"
           or else Word = "if"
           or else Word = "in"
           or else Word = "interface"
           or else Word = "is"
           or else Word = "limited"
           or else Word = "loop"
           or else Word = "mod"
           or else Word = "new"
           or else Word = "not"
           or else Word = "null"
           or else Word = "of"
           or else Word = "or"
           or else Word = "others"
           or else Word = "out"
           or else Word = "overriding"
           or else Word = "package"
           or else Word = "pragma"
           or else Word = "private"
           or else Word = "procedure"
           or else Word = "protected"
           or else Word = "raise"
           or else Word = "range"
           or else Word = "record"
           or else Word = "rem"
           or else Word = "renames"
           or else Word = "requeue"
           or else Word = "return"
           or else Word = "reverse"
           or else Word = "select"
           or else Word = "separate"
           or else Word = "some"
           or else Word = "subtype"
           or else Word = "synchronized"
           or else Word = "tagged"
           or else Word = "task"
           or else Word = "terminate"
           or else Word = "then"
           or else Word = "type"
           or else Word = "until"
           or else Word = "use"
           or else Word = "when"
           or else Word = "while"
           or else Word = "with"
           or else Word = "xor";
      end Is_Ada_Reserved_Word;
   begin
      if Lower_Name'Length = 0 then
         return True;
      elsif Lower_Name (Lower_Name'First) = '"' then
         return not Is_Valid_Quoted_Operator_Name (Lower_Name);
      end if;

      while Start <= Lower_Name'Last loop
         Stop := Start;
         while Stop <= Lower_Name'Last and then Lower_Name (Stop) /= '.' loop
            Stop := Stop + 1;
         end loop;

         if Stop = Start
           or else not Is_Valid_Ada_Identifier_Component
                         (Lower_Name (Start .. Stop - 1))
           or else Is_Ada_Reserved_Word (Lower_Name (Start .. Stop - 1))
         then
            return True;
         end if;

         Start := Stop + 1;
      end loop;

      return False;
   end Is_Invalid_Compact_Owner_Name;

end Editor.Ada_Declaration_Parser.Source_Awareness;
