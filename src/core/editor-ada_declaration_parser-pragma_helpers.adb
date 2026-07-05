with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Pragma_Helpers is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Is_Pragma_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean
   is
   begin
      --  Shared pragma argument scanners must ignore commas, parentheses and
      --  arrows that occur inside Ada character literals, for example
      --  ``Character'Val (44)`` is not needed here but ``','`` and ``')'``
      --  are common positional values.  Use Character'Val (39) to avoid
      --  source-level quoting ambiguity for the apostrophe delimiter.
      return Pos + 2 <= Last
        and then Text (Pos) = Character'Val (39)
        and then Text (Pos + 2) = Character'Val (39);
   end Is_Pragma_Character_Literal_At;


   function Pragma_Code_Preserving_Literals (Line : String) return String is
      In_String : Boolean := False;
      I         : Natural := Line'First;
   begin
      --  Pragma target extraction needs the real text of string-literal
      --  targets, notably imported operator symbols such as "+".  The
      --  generic syntax sanitizer intentionally blanks literals, which is
      --  correct for declaration keyword scanning but wrong here because the
      --  literal can be the entity name itself.  Strip comments with a small
      --  pragma-aware scanner while preserving literals for the downstream
      --  string/character-safe argument parser.
      while I <= Line'Last loop
         if In_String then
            if Line (I) = '"' then
               if I + 1 <= Line'Last and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Pragma_Character_Literal_At (Line, I, Line'Last) then
            I := I + 2;
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '-'
           and then I + 1 <= Line'Last
           and then Line (I + 1) = '-'
         then
            if I = Line'First then
               return "";
            else
               return Line (Line'First .. I - 1);
            end if;
         end if;
         I := I + 1;
      end loop;

      return Line;
   end Pragma_Code_Preserving_Literals;


   function Pragma_Target (Line : String) return String is
      Code        : constant String := Pragma_Code_Preserving_Literals (Line);
      Lowered     : constant String := Lower (Code);
      Trimmed     : constant String := Trim (Lowered);
      Open_Pos    : Natural := 0;
      Close_Pos   : Natural := 0;
      First_Comma : Natural := 0;
      Start_Pos   : Natural := 0;
      Stop_Pos    : Natural := 0;

      function Is_Name_Start (C : Character) return Boolean is
      begin
         return (C >= 'A' and then C <= 'Z')
           or else (C >= 'a' and then C <= 'z');
      end Is_Name_Start;

      procedure Skip_Separators (Pos : in out Natural) is
      begin
         while Pos <= Close_Pos
           and then (Code (Pos) = ' '
                     or else Code (Pos) = Ada.Characters.Latin_1.HT
                     or else Code (Pos) = ',')
         loop
            Pos := Pos + 1;
         end loop;
      end Skip_Separators;

      function Named_Pragma_Target_Start (Name : String) return Natural is
         Wanted   : constant String := Lower (Name);
         Arg_Start : Natural := Open_Pos + 1;
         Level     : Natural := 0;
         In_String : Boolean := False;
         I         : Natural := Arg_Start;

         function Top_Level_Arrow_In
           (First : Natural; Last : Natural) return Natural
         is
            Local_Level     : Natural := 0;
            Local_In_String : Boolean := False;
            J               : Natural := First;
         begin
            while J <= Last loop
               if Local_In_String then
                  if Code (J) = '"' then
                     if J + 1 <= Last and then Code (J + 1) = '"' then
                        J := J + 1;
                     else
                        Local_In_String := False;
                     end if;
                  end if;
               elsif Is_Pragma_Character_Literal_At (Code, J, Last) then
                  J := J + 2;
               elsif Code (J) = '"' then
                  Local_In_String := True;
               elsif Code (J) = '(' then
                  Local_Level := Local_Level + 1;
               elsif Code (J) = ')' then
                  if Local_Level > 0 then
                     Local_Level := Local_Level - 1;
                  end if;
               elsif Code (J) = '='
                 and then J + 1 <= Last
                 and then Code (J + 1) = '>'
                 and then Local_Level = 0
               then
                  return J;
               end if;
               J := J + 1;
            end loop;
            return 0;
         end Top_Level_Arrow_In;

         function Label_Of (First : Natural; Last : Natural) return String is
            Start_Label : Natural := First;
            Stop_Label  : Natural;
         begin
            while Start_Label <= Last
              and then (Code (Start_Label) = ' '
                        or else Code (Start_Label) = Ada.Characters.Latin_1.HT)
            loop
               Start_Label := Start_Label + 1;
            end loop;

            Stop_Label := Start_Label;
            while Stop_Label <= Last
              and then (Is_Word_Char (Code (Stop_Label)) or else Code (Stop_Label) = '.')
            loop
               Stop_Label := Stop_Label + 1;
            end loop;

            if Stop_Label <= Start_Label then
               return "";
            end if;
            return Lower (Code (Start_Label .. Stop_Label - 1));
         end Label_Of;

         procedure Check_Argument (First : Natural; Last : Natural; Found : in out Natural) is
            Arrow : constant Natural := Top_Level_Arrow_In (First, Last);
         begin
            if Arrow /= 0 and then Label_Of (First, Arrow - 1) = Wanted then
               Found := Arrow + 2;
            end if;
         end Check_Argument;

         Found_Start : Natural := 0;
      begin
         --  Named pragma target extraction must only consider top-level
         --  pragma associations.  A nested expression may legitimately contain
         --  labels such as ``Entity =>`` or ``On =>`` inside a positional
         --  value; those must not be mistaken for the pragma's declaration
         --  target.
         while I <= Close_Pos - 1 loop
            if In_String then
               if Code (I) = '"' then
                  if I + 1 <= Close_Pos - 1 and then Code (I + 1) = '"' then
                     I := I + 1;
                  else
                     In_String := False;
                  end if;
               end if;
            elsif Is_Pragma_Character_Literal_At (Code, I, Close_Pos - 1) then
               I := I + 2;
            elsif Code (I) = '"' then
               In_String := True;
            elsif Code (I) = '(' then
               Level := Level + 1;
            elsif Code (I) = ')' then
               if Level > 0 then
                  Level := Level - 1;
               end if;
            elsif Code (I) = ',' and then Level = 0 then
               Check_Argument (Arg_Start, I - 1, Found_Start);
               if Found_Start /= 0 then
                  return Found_Start;
               end if;
               Arg_Start := I + 1;
            end if;
            I := I + 1;
         end loop;

         if Arg_Start <= Close_Pos - 1 then
            Check_Argument (Arg_Start, Close_Pos - 1, Found_Start);
         end if;
         return Found_Start;
      end Named_Pragma_Target_Start;

      function First_Top_Level_Pragma_Comma return Natural is
         Level     : Natural := 0;
         In_String : Boolean := False;
         I         : Natural := Open_Pos + 1;
      begin
         while I <= Close_Pos - 1 loop
            if In_String then
               if Code (I) = '"' then
                  if I + 1 <= Close_Pos - 1 and then Code (I + 1) = '"' then
                     I := I + 1;
                  else
                     In_String := False;
                  end if;
               end if;
            elsif Is_Pragma_Character_Literal_At (Code, I, Close_Pos - 1) then
               I := I + 2;
            elsif Code (I) = '"' then
               In_String := True;
            elsif Code (I) = '(' then
               Level := Level + 1;
            elsif Code (I) = ')' then
               if Level > 0 then
                  Level := Level - 1;
               end if;
            elsif Code (I) = ',' and then Level = 0 then
               return I;
            end if;
            I := I + 1;
         end loop;
         return 0;
      end First_Top_Level_Pragma_Comma;
   begin
      if not Starts_With_Word (Trimmed, "pragma") then
         return "";
      end if;

      Open_Pos := Ada.Strings.Fixed.Index (Code, "(");
      Close_Pos := Matching_Pragma_Close_Pos (Code, Open_Pos);
      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos + 1 then
         return "";
      end if;

      First_Comma := First_Top_Level_Pragma_Comma;
      if Starts_With_Word (Trimmed, "pragma suppress")
        or else Starts_With_Word (Trimmed, "pragma unsuppress")
      then
         --  Suppress/Unsuppress apply to the optional On => entity argument.
         --  The first argument names the check and is not a declaration target.
         --  Use the same named-association scanner as other pragmas so
         --  spellings such as ``On=>Obj`` or out-of-order named arguments are
         --  retained instead of being silently ignored.
         Start_Pos := Named_Pragma_Target_Start ("on");
         if Start_Pos = 0 then
            return "";
         end if;
      elsif Starts_With_Word (Trimmed, "pragma convention")
        or else Starts_With_Word (Trimmed, "pragma import")
        or else Starts_With_Word (Trimmed, "pragma export")
        or else Starts_With_Word (Trimmed, "pragma interface")
      then
         --  Convention/import/export/interface pragmas normally name the
         --  entity in the second argument: pragma Import (C, Entity, ...).
         --  Prefer Entity => when present so named associations may appear in
         --  any order without binding the convention argument as the target.
         Start_Pos := Named_Pragma_Target_Start ("entity");
         if Start_Pos = 0 then
            if First_Comma = 0 then
               return "";
            end if;
            Start_Pos := First_Comma + 1;
         end if;
      elsif Starts_With_Word (Trimmed, "pragma external") then
         --  External is the opposite positional shape: pragma External
         --  (Entity, ...), but the named Entity => form should still bind the
         --  declaration target when it appears after External_Name/Link_Name.
         Start_Pos := Named_Pragma_Target_Start ("entity");
         if Start_Pos = 0 then
            Start_Pos := Open_Pos + 1;
         end if;
      elsif Starts_With_Word (Trimmed, "pragma attach_handler") then
         --  Attach_Handler may be written positionally or with Handler =>
         --  after Interrupt =>.  The handler, not the interrupt expression,
         --  is the declaration target.
         Start_Pos := Named_Pragma_Target_Start ("handler");
         if Start_Pos = 0 then
            Start_Pos := Open_Pos + 1;
         end if;
      elsif Starts_With_Word (Trimmed, "pragma linker_section")
        or else Starts_With_Word (Trimmed, "pragma machine_attribute")
      then
         --  GNAT code-generation pragmas accept Entity => named arguments;
         --  keep them bound to the entity even when the value argument is
         --  written first.
         Start_Pos := Named_Pragma_Target_Start ("entity");
         if Start_Pos = 0 then
            Start_Pos := Open_Pos + 1;
         end if;
      else
         --  Inline, No_Return, Unreferenced, Volatile, Atomic and similar
         --  entity pragmas put the first referenced entity first.
         Start_Pos := Open_Pos + 1;
      end if;

      Skip_Separators (Start_Pos);
      if Start_Pos <= Close_Pos then
         declare
            Tail_First : constant Natural := Start_Pos;
            Tail_Last  : constant Natural := Close_Pos - 1;
            Level      : Natural := 0;
            In_String  : Boolean := False;
            Arrow_Pos  : Natural := 0;
            Comma_Pos  : Natural := 0;
            J          : Natural := Tail_First;
         begin
            --  A fallback target may itself be written as a named association,
            --  for example ``pragma Pack (Entity => Rec)``.  Strip that
            --  outer label only when the association arrow is at the pragma
            --  argument's top level.  Earlier code used raw Index calls here,
            --  so a nested expression like ``Entity => Pick (A => B)`` could
            --  make the target scanner jump into the nested value and lose the
            --  real target.  Keep this scanner in lock-step with the hardened
            --  pragma argument splitting logic: strings, character literals,
            --  and nested parentheses are opaque.
            while J <= Tail_Last loop
               if In_String then
                  if Code (J) = '"' then
                     if J + 1 <= Tail_Last and then Code (J + 1) = '"' then
                        J := J + 1;
                     else
                        In_String := False;
                     end if;
                  end if;
               elsif Is_Pragma_Character_Literal_At (Code, J, Tail_Last) then
                  J := J + 2;
               elsif Code (J) = '"' then
                  In_String := True;
               elsif Code (J) = '(' then
                  Level := Level + 1;
               elsif Code (J) = ')' then
                  if Level > 0 then
                     Level := Level - 1;
                  end if;
               elsif Code (J) = ',' and then Level = 0 then
                  Comma_Pos := J;
                  exit;
               elsif Code (J) = '='
                 and then J + 1 <= Tail_Last
                 and then Code (J + 1) = '>'
                 and then Level = 0
               then
                  Arrow_Pos := J;
                  J := J + 1;
               end if;
               J := J + 1;
            end loop;

            if Arrow_Pos /= 0 and then (Comma_Pos = 0 or else Arrow_Pos < Comma_Pos) then
               Start_Pos := Arrow_Pos + 2;
               Skip_Separators (Start_Pos);
            end if;
         end;
      end if;

      if Start_Pos > Close_Pos then
         return "";
      end if;

      if Code (Start_Pos) = '"' then
         --  Operator subprograms may be named by an Ada operator symbol in
         --  pragmas, for example ``pragma Import (C, "+")``.  The earlier
         --  identifier-only scanner silently dropped those targets, so the
         --  pragma never reached the unified representation/operational
         --  legality path.  Retain the complete string literal target and
         --  keep doubled quotes inside the literal intact.
         Stop_Pos := Start_Pos + 1;
         while Stop_Pos <= Close_Pos loop
            if Code (Stop_Pos) = '"' then
               if Stop_Pos + 1 <= Close_Pos and then Code (Stop_Pos + 1) = '"' then
                  Stop_Pos := Stop_Pos + 2;
               else
                  return Code (Start_Pos .. Stop_Pos);
               end if;
            else
               Stop_Pos := Stop_Pos + 1;
            end if;
         end loop;
         return "";
      end if;

      if not Is_Name_Start (Code (Start_Pos)) then
         return "";
      end if;

      Stop_Pos := Start_Pos;
      while Stop_Pos <= Close_Pos
        and then (Is_Word_Char (Code (Stop_Pos)) or else Code (Stop_Pos) = '.')
      loop
         Stop_Pos := Stop_Pos + 1;
      end loop;

      if Stop_Pos <= Start_Pos then
         return "";
      end if;

      return Code (Start_Pos .. Stop_Pos - 1);
   end Pragma_Target;


   function Pragma_Name_Of (Line : String) return String is
      Code : constant String := Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Open_Pos : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      Start : Natural := Code'First;
      Stop  : Natural;
   begin
      if not Starts_With_Word (Lower (Code), "pragma") then
         return "";
      end if;

      Start := Code'First + 6;
      while Start <= Code'Last
        and then (Code (Start) = ' '
                  or else Code (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Code'Last then
         return "";
      end if;

      Stop := Start;
      while Stop <= Code'Last and then Is_Word_Char (Code (Stop)) loop
         Stop := Stop + 1;
      end loop;

      if Open_Pos /= 0 and then Stop > Open_Pos then
         Stop := Open_Pos;
      end if;

      if Stop <= Start then
         return "";
      end if;

      return Lower (Code (Start .. Stop - 1));
   end Pragma_Name_Of;

   function Matching_Pragma_Close_Pos (Line : String; Open_Pos : Natural) return Natural is
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Open_Pos;
   begin
      if Open_Pos = 0 or else Open_Pos > Line'Last or else Line (Open_Pos) /= '(' then
         return 0;
      end if;

      while I <= Line'Last loop
         if In_String then
            if Line (I) = '"' then
               if I + 1 <= Line'Last and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Pragma_Character_Literal_At (Line, I, Line'Last) then
            I := I + 2;
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '(' then
            Level := Level + 1;
         elsif Line (I) = ')' then
            if Level = 1 then
               return I;
            elsif Level > 1 then
               Level := Level - 1;
            end if;
         end if;
         I := I + 1;
      end loop;

      return 0;
   end Matching_Pragma_Close_Pos;

   function Pragma_Argument_Count (Line : String) return Natural is
      Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Line, "(");
      Close_Pos : constant Natural := Matching_Pragma_Close_Pos (Line, Open_Pos);
      Count     : Natural := 0;
      Level     : Natural := 0;
      In_String : Boolean := False;
      Had_Text  : Boolean := False;
      I         : Natural;
   begin
      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos then
         return 0;
      end if;

      I := Open_Pos + 1;
      while I <= Close_Pos - 1 loop
         if In_String then
            Had_Text := True;
            if Line (I) = '"' then
               if I + 1 <= Close_Pos - 1 and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Pragma_Character_Literal_At (Line, I, Close_Pos - 1) then
            I := I + 2;
            Had_Text := True;
         elsif Line (I) = '"' then
            In_String := True;
            Had_Text := True;
         elsif Line (I) = '(' then
            Level := Level + 1;
            Had_Text := True;
         elsif Line (I) = ')' then
            if Level > 0 then
               Level := Level - 1;
            end if;
            Had_Text := True;
         elsif Line (I) = ',' and then Level = 0 then
            Count := Count + 1;
            Had_Text := False;
         elsif Line (I) /= ' ' and then Line (I) /= Ada.Characters.Latin_1.HT then
            Had_Text := True;
         end if;
         I := I + 1;
      end loop;

      if Had_Text or else Count > 0 then
         Count := Count + 1;
      end if;
      return Count;
   end Pragma_Argument_Count;

   function Pragma_Argument (Line : String; Index : Positive) return String is
      Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Line, "(");
      Close_Pos : constant Natural := Matching_Pragma_Close_Pos (Line, Open_Pos);
      Current   : Positive := 1;
      Start     : Natural;
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural;
   begin
      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos then
         return "";
      end if;

      Start := Open_Pos + 1;
      I := Start;
      while I <= Close_Pos - 1 loop
         if In_String then
            if Line (I) = '"' then
               if I + 1 <= Close_Pos - 1 and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Pragma_Character_Literal_At (Line, I, Close_Pos - 1) then
            I := I + 2;
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '(' then
            Level := Level + 1;
         elsif Line (I) = ')' then
            if Level > 0 then
               Level := Level - 1;
            end if;
         elsif Line (I) = ',' and then Level = 0 then
            if Current = Index then
               return Trim (Line (Start .. I - 1));
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      if Current = Index and then Start <= Close_Pos - 1 then
         return Trim (Line (Start .. Close_Pos - 1));
      end if;
      return "";
   end Pragma_Argument;

   function Top_Level_Pragma_Association_Arrow (Arg : String) return Natural is
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Arg'First;
   begin
      --  A pragma argument is a named association only when the arrow appears
      --  at the argument top level.  Positional values may themselves contain
      --  named associations, for example ``Milliseconds (Value => 10)``; those
      --  nested arrows must remain part of the retained value.
      while I <= Arg'Last loop
         if In_String then
            if Arg (I) = '"' then
               if I + 1 <= Arg'Last and then Arg (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Pragma_Character_Literal_At (Arg, I, Arg'Last) then
            I := I + 2;
         elsif Arg (I) = '"' then
            In_String := True;
         elsif Arg (I) = '(' then
            Level := Level + 1;
         elsif Arg (I) = ')' then
            if Level > 0 then
               Level := Level - 1;
            end if;
         elsif Arg (I) = '='
           and then I + 1 <= Arg'Last
           and then Arg (I + 1) = '>'
           and then Level = 0
         then
            return I;
         end if;
         I := I + 1;
      end loop;
      return 0;
   end Top_Level_Pragma_Association_Arrow;

   function Pragma_Argument_Name (Arg : String) return String is
      Arrow : constant Natural := Top_Level_Pragma_Association_Arrow (Arg);
      Clean : constant String := Trim (Arg);
      Stop  : Natural := Clean'First;
   begin
      if Arrow = 0 or else Clean = "" then
         return "";
      end if;

      while Stop <= Clean'Last
        and then (Is_Word_Char (Clean (Stop)) or else Clean (Stop) = '.')
      loop
         Stop := Stop + 1;
      end loop;

      if Stop = Clean'First then
         return "";
      end if;
      return Lower (Clean (Clean'First .. Stop - 1));
   end Pragma_Argument_Name;

   function Pragma_Argument_Value (Arg : String) return String is
      Arrow : constant Natural := Top_Level_Pragma_Association_Arrow (Arg);
   begin
      if Arrow = 0 then
         return Trim (Arg);
      elsif Arrow + 2 <= Arg'Last then
         return Trim (Arg (Arrow + 2 .. Arg'Last));
      else
         return "";
      end if;
   end Pragma_Argument_Value;

   function Named_Pragma_Argument (Line, Name : String) return String is
      Wanted : constant String := Lower (Name);
   begin
      for I in 1 .. Pragma_Argument_Count (Line) loop
         declare
            Arg : constant String := Pragma_Argument (Line, I);
         begin
            if Pragma_Argument_Name (Arg) = Wanted then
               return Pragma_Argument_Value (Arg);
            end if;
         end;
      end loop;
      return "";
   end Named_Pragma_Argument;

   function Interfacing_Pragma_Value
     (Line               : String;
      Name               : String;
      Positional_Fallback : Positive) return String
   is
      Named : constant String := Named_Pragma_Argument (Line, Name);
   begin
      if Named /= "" then
         return Named;
      end if;
      return Pragma_Argument_Value (Pragma_Argument (Line, Positional_Fallback));
   end Interfacing_Pragma_Value;


end Editor.Ada_Declaration_Parser.Pragma_Helpers;
