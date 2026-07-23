with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Representation_Static_Values is

   procedure Parse_Static_Natural
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural)
   is
      T     : constant String :=
        Editor.Text_Helpers.Trim (Text);
      Acc   : Natural := 0;
      Digit : Natural;
   begin
      Valid := T'Length > 0;
      Value := 0;
      if not Valid then
         return;
      end if;

      for C of T loop
         if C < '0' or else C > '9' then
            Valid := False;
            Value := 0;
            return;
         end if;

         Digit := Character'Pos (C) - Character'Pos ('0');
         if Acc > (Natural'Last - Digit) / 10 then
            Valid := False;
            Value := 0;
            return;
         end if;
         Acc := Acc * 10 + Digit;
      end loop;

      Value := Acc;
   end Parse_Static_Natural;

   function Parse_Underscored_Natural
     (Text  : String;
      Value : out Natural) return Boolean
   is
      Clean : Unbounded_String := Null_Unbounded_String;
   begin
      Value := 0;
      for Ch of Text loop
         if Ch /= '_' then
            Append (Clean, Ch);
         end if;
      end loop;
      Value := Natural'Value (To_String (Clean));
      return True;
   exception
      when others =>
         Value := 0;
         return False;
   end Parse_Underscored_Natural;

   function Parse_Static_Unsigned_Numeric_Literal
     (Text  : String;
      Value : out Natural) return Boolean
   is
      S : constant String := Editor.Text_Helpers.Trim (Text);
      Base_Text : Unbounded_String := Null_Unbounded_String;
      Body_Text : Unbounded_String := Null_Unbounded_String;
      Exp_Text  : Unbounded_String := Null_Unbounded_String;
      First : Natural := S'First;
      Hash_1 : Natural := 0;
      Hash_2 : Natural := 0;
      E      : Natural := 0;
      Parsed_Base  : Natural := 0;
      Parsed_Value : Natural := 0;

      function Digit_Value (C : Character) return Integer is
      begin
         if C >= '0' and then C <= '9' then
            return Character'Pos (C) - Character'Pos ('0');
         elsif C >= 'A' and then C <= 'F' then
            return 10 + Character'Pos (C) - Character'Pos ('A');
         elsif C >= 'a' and then C <= 'f' then
            return 10 + Character'Pos (C) - Character'Pos ('a');
         else
            return -1;
         end if;
      end Digit_Value;

      function Parse_Digits
        (Scan_Text : String;
         Base      : Positive;
         Result    : out Natural) return Boolean
      is
         Acc  : Natural := 0;
         Seen : Boolean := False;
         D    : Integer;
      begin
         Result := 0;
         if Scan_Text = "" then
            return False;
         end if;

         for C of Scan_Text loop
            if C = '_' then
               null;
            else
               D := Digit_Value (C);
               if D < 0 or else D >= Base then
                  return False;
               end if;
               Acc := Acc * Base + Natural (D);
               Seen := True;
            end if;
         end loop;

         if not Seen then
            return False;
         end if;

         Result := Acc;
         return True;
      end Parse_Digits;

      function Exponent_Start (Scan_Text : String) return Natural is
      begin
         for I in Scan_Text'Range loop
            if Scan_Text (I) = 'e' or else Scan_Text (I) = 'E' then
               return I;
            end if;
         end loop;
         return 0;
      end Exponent_Start;

      function Apply_Exponent
        (Base_Value    : Natural;
         Exponent_Base : Positive;
         Exp_Text      : String;
         Result        : out Natural) return Boolean
      is
         Exp    : Natural := 0;
         Factor : Natural := 1;
         First_Exp : Natural := Exp_Text'First;
      begin
         Result := 0;
         if Exp_Text = "" then
            return False;
         end if;

         if Exp_Text (First_Exp) = 'e' or else Exp_Text (First_Exp) = 'E' then
            First_Exp := First_Exp + 1;
         end if;

         if First_Exp > Exp_Text'Last then
            return False;
         end if;

         if Exp_Text (First_Exp) = '+' then
            First_Exp := First_Exp + 1;
         elsif Exp_Text (First_Exp) = '-' then
            return False;
         end if;

         if First_Exp > Exp_Text'Last then
            return False;
         end if;

         if not Parse_Digits (Exp_Text (First_Exp .. Exp_Text'Last), 10, Exp) then
            return False;
         end if;

         for N in 1 .. Exp loop
            pragma Unreferenced (N);
            Factor := Factor * Exponent_Base;
         end loop;

         Result := Base_Value * Factor;
         return True;
      end Apply_Exponent;
   begin
      Value := 0;
      if S = "" then
         return False;
      end if;

      if S (First) = '+' then
         First := First + 1;
      elsif S (First) = '-' then
         return False;
      end if;

      if First > S'Last then
         return False;
      end if;

      for I in First .. S'Last loop
         if S (I) = '#' then
            if Hash_1 = 0 then
               Hash_1 := I;
            else
               Hash_2 := I;
               exit;
            end if;
         end if;
      end loop;

      if Hash_1 /= 0 then
         if Hash_2 = 0 or else Hash_1 <= First or else Hash_2 <= Hash_1 + 1 then
            return False;
         end if;

         Base_Text := To_Unbounded_String (S (First .. Hash_1 - 1));
         Body_Text := To_Unbounded_String (S (Hash_1 + 1 .. Hash_2 - 1));
         if Hash_2 < S'Last then
            Exp_Text := To_Unbounded_String (S (Hash_2 + 1 .. S'Last));
         end if;

         if not Parse_Digits (To_String (Base_Text), 10, Parsed_Base) then
            return False;
         end if;
         if Parsed_Base < 2 or else Parsed_Base > 16 then
            return False;
         end if;
         if not Parse_Digits (To_String (Body_Text), Parsed_Base, Parsed_Value) then
            return False;
         end if;
         if Length (Exp_Text) /= 0 then
            declare
               With_Exponent : Natural := 0;
            begin
               if not Apply_Exponent
                 (Parsed_Value, Parsed_Base, To_String (Exp_Text), With_Exponent)
               then
                  return False;
               end if;
               Parsed_Value := With_Exponent;
            end;
         end if;

         Value := Parsed_Value;
         return True;
      end if;

      E := Exponent_Start (S (First .. S'Last));
      if E = 0 then
         if Parse_Digits (S (First .. S'Last), 10, Parsed_Value) then
            Value := Parsed_Value;
            return True;
         end if;
      elsif E > First and then E < S'Last then
         declare
            With_Exponent : Natural := 0;
         begin
            if Parse_Digits (S (First .. E - 1), 10, Parsed_Value)
              and then Apply_Exponent
                (Parsed_Value, 10, S (E + 1 .. S'Last), With_Exponent)
            then
               Value := With_Exponent;
               return True;
            end if;
         end;
      end if;

      return False;
   exception
      when others =>
         Value := 0;
         return False;
   end Parse_Static_Unsigned_Numeric_Literal;

   function Strip_Constant_Subtype_Prefix (Subtype_Text : String) return String
   is
      Raw_T : constant String := Editor.Text_Helpers.Trim (Subtype_Text);
      Raw_L : constant String := Editor.Text_Helpers.Lower (Raw_T);
   begin
      if Editor.Text_Helpers.Starts_With_Word (Raw_L, "constant")
        and then Raw_T'Length > 8
      then
         return Editor.Text_Helpers.Trim (Raw_T (Raw_T'First + 8 .. Raw_T'Last));
      else
         return Raw_T;
      end if;
   exception
      when Constraint_Error =>
         return Editor.Text_Helpers.Trim (Subtype_Text);
   end Strip_Constant_Subtype_Prefix;

   function Natural_In_Integer_Range
     (Value    : Natural;
      Has_Low  : Boolean;
      Low      : Integer;
      Has_High : Boolean;
      High     : Integer) return Boolean
   is
      Int_Value : constant Integer := Integer (Value);
   begin
      if Has_Low and then Int_Value < Low then
         return False;
      elsif Has_High and then Int_Value > High then
         return False;
      else
         return True;
      end if;
   exception
      when Constraint_Error =>
         return False;
   end Natural_In_Integer_Range;

   function Parse_Static_String_Bound_Primary
     (Text                      : String;
      Pos                       : in out Natural;
      Result                    : out Natural;
      Parse_Dimension           : not null Parse_Dimension_Function;
      Static_String_Bound_Value :
        not null Static_String_Bound_Value_Function) return Boolean
   is
      Start_Pos  : Natural := Pos;
      Quote_Pos  : Natural := 0;
      Depth      : Integer := 0;
      J          : Natural;

      procedure Skip_Spaces (Scan_Pos : in out Natural) is
      begin
         while Scan_Pos <= Text'Last
           and then Lexical_Helpers.Is_Static_Space (Text (Scan_Pos))
         loop
            Scan_Pos := Scan_Pos + 1;
         end loop;
      end Skip_Spaces;
   begin
      Result := 0;
      Skip_Spaces (Start_Pos);
      if Start_Pos > Text'Last then
         return False;
      end if;

      J := Start_Pos;
      while J <= Text'Last loop
         if Text (J) = '"' then
            J := J + 1;
            while J <= Text'Last loop
               if Text (J) = '"' then
                  if J < Text'Last and then Text (J + 1) = '"' then
                     J := J + 2;
                  else
                     J := J + 1;
                     exit;
                  end if;
               else
                  J := J + 1;
               end if;
            end loop;
         elsif Text (J) = Character'Val (39)
           and then J + 2 <= Text'Last
           and then Text (J + 2) = Character'Val (39)
         then
            J := J + 3;
         elsif Text (J) = '(' then
            Depth := Depth + 1;
            J := J + 1;
         elsif Text (J) = ')' then
            if Depth = 0 then
               exit;
            end if;
            Depth := Depth - 1;
            J := J + 1;
         elsif Text (J) = Character'Val (39) and then Depth = 0 then
            declare
               Open_Pos : Natural := J + 1;
            begin
               while Open_Pos <= Text'Last
                 and then Lexical_Helpers.Is_Static_Space (Text (Open_Pos))
               loop
                  Open_Pos := Open_Pos + 1;
               end loop;

               if Open_Pos <= Text'Last and then Text (Open_Pos) = '(' then
                  J := Open_Pos;
               else
                  Quote_Pos := J;
                  exit;
               end if;
            end;
         elsif Depth = 0 and then (Text (J) = '*'
                                    or else Text (J) = '/'
                                    or else Text (J) = '+'
                                    or else Text (J) = '-')
         then
            exit;
         else
            J := J + 1;
         end if;
      end loop;

      if Quote_Pos = 0 or else Quote_Pos <= Start_Pos then
         return False;
      end if;

      declare
         Prefix_Text : constant String := Editor.Text_Helpers.Trim (Text (Start_Pos .. Quote_Pos - 1));
         Attr_Start  : Natural := Quote_Pos + 1;
         Attr_Stop   : Natural := 0;
         Bound_Value : Natural := 0;
         Dim_Value   : Integer := 0;
      begin
         while Attr_Start <= Text'Last
           and then Lexical_Helpers.Is_Static_Space (Text (Attr_Start))
         loop
            Attr_Start := Attr_Start + 1;
         end loop;

         if Attr_Start > Text'Last
           or else not Lexical_Helpers.Is_Name_Start (Text (Attr_Start))
         then
            return False;
         end if;

         J := Attr_Start;
         while J <= Text'Last and then Lexical_Helpers.Is_Name_Char (Text (J)) loop
            Attr_Stop := J;
            J := J + 1;
         end loop;

         declare
            Attr_Name : constant String := Editor.Text_Helpers.Lower (Text (Attr_Start .. Attr_Stop));
         begin
            if Attr_Name /= "length"
              and then Attr_Name /= "first"
              and then Attr_Name /= "last"
            then
               return False;
            end if;

            if not Static_String_Bound_Value.all
                     (Prefix_Text, Attr_Name, Bound_Value)
            then
               return False;
            end if;

            Pos := J;
            Skip_Spaces (Pos);
            if Pos <= Text'Last and then Text (Pos) = '(' then
               Pos := Pos + 1;
               if not Parse_Dimension.all (Pos, Dim_Value) then
                  return False;
               end if;
               Skip_Spaces (Pos);
               if Pos > Text'Last or else Text (Pos) /= ')' then
                  return False;
               end if;
               Pos := Pos + 1;
               if Dim_Value /= 1 then
                  return False;
               end if;
            end if;

            Result := Bound_Value;
            return True;
         end;
      end;
   exception
      when Constraint_Error =>
         return False;
   end Parse_Static_String_Bound_Primary;

end Editor.Ada_Declaration_Parser.Representation_Static_Values;
