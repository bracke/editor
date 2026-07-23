with Editor.Ada_Declaration_Parser.Lexical_Helpers; use Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Text_Helpers; use Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing is

procedure Parse_Static_Natural
  (Ops   : Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing.Operations;
   Text  : String;
   Valid : out Boolean;
   Value : out Natural)
is
   T : constant String := Ops.Clean_Metadata_Name.all (Text);

   procedure Parse_Static_Integer
     (Text  : String;
      Valid : out Boolean;
      Value : out Integer)
   is
   begin
      Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing.Parse_Static_Integer (Ops, Text, Valid, Value);
   end Parse_Static_Integer;

   function Static_String_Bound_Value
     (Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
   begin
      return Ops.Static_String_Bound_Value.all (Name, Attr_Name, Bound);
   end Static_String_Bound_Value;

   function Static_Discrete_Default_Position
     (Type_Name    : String;
      Default_Text : String;
      Position     : out Natural) return Boolean
   is
   begin
      return Ops.Static_Discrete_Default_Position.all
        (Type_Name, Default_Text, Position);
   end Static_Discrete_Default_Position;

   function Static_Discrete_Literal_Position
     (Type_Name    : String;
      Literal_Text : String;
      Position     : out Natural) return Boolean
   is
   begin
      return Ops.Static_Discrete_Literal_Position.all
        (Type_Name, Literal_Text, Position);
   end Static_Discrete_Literal_Position;

   function Static_Discrete_Constant_Position
     (Type_Name : String;
      Name      : String;
      Position  : out Natural) return Boolean
   is
   begin
      return Ops.Static_Discrete_Constant_Position.all
        (Type_Name, Name, Position);
   end Static_Discrete_Constant_Position;

   function Static_Value_In_Type_Range
     (Type_Name : String;
      Value     : Natural) return Boolean
   is
   begin
      return Ops.Static_Value_In_Type_Range.all (Type_Name, Value);
   end Static_Value_In_Type_Range;

   function Static_Discrete_Value_String_Position
     (Type_Name   : String;
      String_Text : String;
      Position    : out Natural) return Boolean
   is
   begin
      return Ops.Static_Discrete_Value_String_Position.all
        (Type_Name, String_Text, Position);
   end Static_Discrete_Value_String_Position;

   function Static_Integer_Value_String_Value
     (Type_Name   : String;
      String_Text : String;
      Value       : out Integer) return Boolean
   is
   begin
      return Ops.Static_Integer_Value_String_Value.all
        (Type_Name, String_Text, Value);
   end Static_Integer_Value_String_Value;

   function Static_Type_Range
     (Name     : String;
      Has_Low  : out Boolean;
      Low      : out Integer;
      Has_High : out Boolean;
      High     : out Integer) return Boolean
   is
   begin
      return Ops.Static_Type_Range.all (Name, Has_Low, Low, Has_High, High);
   end Static_Type_Range;

   function Static_Type_Modulus
     (Name  : String;
      Value : out Natural) return Boolean
   is
   begin
      return Ops.Static_Type_Modulus.all (Name, Value);
   end Static_Type_Modulus;

   function Static_Type_Width
     (Name  : String;
      Value : out Natural) return Boolean
   is
   begin
      return Ops.Static_Type_Width.all (Name, Value);
   end Static_Type_Width;

   function Static_Attribute_Value
     (Name      : String;
      Attr_Name : String;
      Value     : out Natural) return Boolean
   is
   begin
      return Ops.Static_Attribute_Value.all (Name, Attr_Name, Value);
   end Static_Attribute_Value;

   function Static_Named_Number_Value
     (Name  : String;
      Value : out Natural) return Boolean
   is
   begin
      return Ops.Static_Named_Number_Value.all (Name, Value);
   end Static_Named_Number_Value;

   function Static_Integer_Name_Value
     (Name  : String;
      Value : out Integer) return Boolean
   is
   begin
      return Ops.Static_Integer_Name_Value.all (Name, Value);
   end Static_Integer_Name_Value;

   function Static_String_Subtype_Bound_Value
     (Type_Name : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
   begin
      return Ops.Static_String_Subtype_Bound_Value.all
        (Type_Name, Attr_Name, Bound);
   end Static_String_Subtype_Bound_Value;

   function Static_String_Constant_Bound_Value
     (Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
   begin
      return Ops.Static_String_Constant_Bound_Value.all
        (Name, Attr_Name, Bound);
   end Static_String_Constant_Bound_Value;

   function Static_Subtype_Root (Name : String) return String is
   begin
      return Ops.Static_Subtype_Root.all (Name);
   end Static_Subtype_Root;

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
     (S      : String;
      Base   : Positive;
      Result : out Natural) return Boolean
   is
      Acc : Natural := 0;
      Seen : Boolean := False;
      D : Integer;
   begin
      Result := 0;
      if S = "" then
         return False;
      end if;

      for C of S loop
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

   function Exponent_Start (S : String) return Natural is
   begin
      for I in S'Range loop
         if S (I) = 'e' or else S (I) = 'E' then
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
      Exp : Natural := 0;
      Acc : Natural := Base_Value;
      Factor : Natural := 1;
      First : Natural := Exp_Text'First;
   begin
      Result := 0;
      if Exp_Text = "" then
         return False;
      end if;

      if Exp_Text (First) = 'e' or else Exp_Text (First) = 'E' then
         First := First + 1;
      end if;

      if First > Exp_Text'Last then
         return False;
      end if;

      if Exp_Text (First) = '+' then
         First := First + 1;
      elsif Exp_Text (First) = '-' then
         return False;
      end if;

      if First > Exp_Text'Last then
         return False;
      end if;

      if not Parse_Digits (Exp_Text (First .. Exp_Text'Last), 10, Exp) then
         return False;
      end if;

      for N in 1 .. Exp loop
         pragma Unreferenced (N);
         Factor := Factor * Exponent_Base;
      end loop;

      Result := Acc * Factor;
      return True;
   end Apply_Exponent;

   procedure Skip_Spaces (Pos : in out Natural) is
   begin
      while Pos <= T'Last and then Is_Static_Space (T (Pos)) loop
         Pos := Pos + 1;
      end loop;
   end Skip_Spaces;

   function Parse_Expression (Pos : in out Natural; Result : out Natural) return Boolean;
   function Parse_Term (Pos : in out Natural; Result : out Natural) return Boolean;
   function Parse_Power (Pos : in out Natural; Result : out Natural) return Boolean;
   function Parse_Primary (Pos : in out Natural; Result : out Natural) return Boolean;

   function Scan_To_Static_Outer_Right_Paren
     (Pos    : in out Natural;
      Start  : out Natural;
      Stop   : out Natural) return Boolean
   is
      Depth : Integer := 0;
   begin
      Skip_Spaces (Pos);
      Start := Pos;
      Stop := 0;

      --  scalar Value operands can be static string
      --  expressions that themselves contain attribute calls.  Match
      --  the right parenthesis of the outer Value call while skipping
      --  nested parentheses and Ada literals, so
      --  ``Color'Value (Color'Image (Green))`` is passed intact to the
      --  bounded static string/discrete evaluator instead of being
      --  truncated after the inner Image call.
      while Pos <= T'Last loop
         if T (Pos) = '"' then
            Stop := Pos;
            Pos := Pos + 1;
            while Pos <= T'Last loop
               Stop := Pos;
               if T (Pos) = '"' then
                  if Pos < T'Last and then T (Pos + 1) = '"' then
                     Pos := Pos + 2;
                  else
                     Pos := Pos + 1;
                     exit;
                  end if;
               else
                  Pos := Pos + 1;
               end if;
            end loop;
         elsif T (Pos) = Character'Val (39)
           and then Pos + 2 <= T'Last
           and then T (Pos + 2) = Character'Val (39)
         then
            Stop := Pos + 2;
            Pos := Pos + 3;
         elsif T (Pos) = '(' then
            Depth := Depth + 1;
            Stop := Pos;
            Pos := Pos + 1;
         elsif T (Pos) = ')' then
            if Depth = 0 then
               return Stop >= Start;
            end if;
            Depth := Depth - 1;
            Stop := Pos;
            Pos := Pos + 1;
         else
            Stop := Pos;
            Pos := Pos + 1;
         end if;
      end loop;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Scan_To_Static_Outer_Right_Paren;

   function Parse_Discrete_Natural_Operand
     (Pos       : in out Natural;
      Type_Name : String;
      Delimiter : Character;
      Result    : out Natural) return Boolean
   is
      Saved_Pos : constant Natural := Pos;
      Literal_Start : Natural := 0;
      Literal_Stop  : Natural := 0;
      Depth         : Integer := 0;
   begin
      Result := 0;
      if Parse_Expression (Pos, Result) then
         return True;
      end if;

      Pos := Saved_Pos;
      Skip_Spaces (Pos);
      Literal_Start := Pos;

      --  when the arithmetic evaluator falls back from the
      --  numeric-expression path to the discrete-expression path, keep
      --  the operand scanner literal-aware and parenthesis-aware.
      --  Scalar attributes such as T'Min/T'Max use this helper for
      --  comma/right-paren delimited operands; a nested operand like
      --  ``Color'Min (Red, Green)`` must not be split at its inner comma
      --  or right parenthesis before the retained discrete evaluator gets
      --  a chance to resolve it.
      while Pos <= T'Last loop
         if T (Pos) = '"' then
            Literal_Stop := Pos;
            Pos := Pos + 1;
            while Pos <= T'Last loop
               Literal_Stop := Pos;
               if T (Pos) = '"' then
                  if Pos < T'Last and then T (Pos + 1) = '"' then
                     Pos := Pos + 2;
                  else
                     Pos := Pos + 1;
                     exit;
                  end if;
               else
                  Pos := Pos + 1;
               end if;
            end loop;
         elsif T (Pos) = Character'Val (39)
           and then Pos + 2 <= T'Last
           and then T (Pos + 2) = Character'Val (39)
         then
            Literal_Stop := Pos + 2;
            Pos := Pos + 3;
         elsif T (Pos) = '(' then
            Depth := Depth + 1;
            Literal_Stop := Pos;
            Pos := Pos + 1;
         elsif T (Pos) = ')' then
            if Depth = 0 and then Delimiter = ')' then
               exit;
            end if;
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
            Literal_Stop := Pos;
            Pos := Pos + 1;
         elsif T (Pos) = Delimiter and then Depth = 0 then
            exit;
         else
            Literal_Stop := Pos;
            Pos := Pos + 1;
         end if;
      end loop;

      if Literal_Stop < Literal_Start then
         return False;
      end if;

      if Static_Discrete_Default_Position
           (Type_Name, T (Literal_Start .. Literal_Stop), Result)
        or else Static_Discrete_Literal_Position
           (Type_Name, T (Literal_Start .. Literal_Stop), Result)
      then
         return True;
      end if;

      return Static_Discrete_Constant_Position
        (Type_Name, T (Literal_Start .. Literal_Stop), Result);
   exception
      when Constraint_Error =>
         return False;
   end Parse_Discrete_Natural_Operand;

   function Parse_Primary (Pos : in out Natural; Result : out Natural) return Boolean is
      Start : Natural;
      Stop  : Natural;

      function Parse_Dimension_As_Integer
        (Scan_Pos : in out Natural;
         Value    : out Integer) return Boolean
      is
         Nat_Value : Natural := 0;
      begin
         if not Parse_Expression (Scan_Pos, Nat_Value) then
            return False;
         end if;
         Value := Integer (Nat_Value);
         return True;
      exception
         when Constraint_Error =>
            return False;
      end Parse_Dimension_As_Integer;
   begin
      Result := 0;
      Skip_Spaces (Pos);
      if Pos > T'Last then
         return False;
      end if;

      --  direct static String expressions may be used as
      --  the prefix of Length/First/Last without naming an intermediate
      --  constant, for example String'(""Gr"" & ""een"")'Length.
      if Representation_Static_Values.Parse_Static_String_Bound_Primary
           (T,
            Pos,
            Result,
            Parse_Dimension_As_Integer'Unrestricted_Access,
            Static_String_Bound_Value'Unrestricted_Access)
      then
         return True;
      end if;

      if Lexical_Helpers.Starts_At_Word (T, Pos, "abs") then
         --  Ada static expressions include the unary abs
         --  operator.  For Natural-valued representation clauses, keep
         --  the bounded fast path for nonnegative operands and add the
         --  common parenthesized signed form, for example abs (-8),
         --  without letting a negative value flow directly into Natural
         --  arithmetic.
         Pos := Pos + 3;
         Skip_Spaces (Pos);
         if Pos <= T'Last and then T (Pos) = '(' then
            declare
               Inner_First : constant Natural := Pos + 1;
               Depth       : Natural := 1;
               Scan        : Natural := Pos + 1;
               Inner_Last  : Natural := 0;
               Signed_OK   : Boolean := False;
               Signed_Val  : Integer := 0;
            begin
               while Scan <= T'Last and then Depth > 0 loop
                  if T (Scan) = '(' then
                     Depth := Depth + 1;
                  elsif T (Scan) = ')' then
                     Depth := Depth - 1;
                     if Depth = 0 then
                        Inner_Last := Scan - 1;
                     end if;
                  end if;
                  Scan := Scan + 1;
               end loop;

               if Depth /= 0 or else Inner_Last < Inner_First then
                  return False;
               end if;

               Parse_Static_Integer
                 (T (Inner_First .. Inner_Last), Signed_OK, Signed_Val);
               if not Signed_OK then
                  return False;
               end if;
               if Signed_Val < 0 then
                  Result := Natural (-Signed_Val);
               else
                  Result := Natural (Signed_Val);
               end if;
               Pos := Scan;
               return True;
            exception
               when Constraint_Error =>
                  return False;
            end;
         else
            if not Parse_Primary (Pos, Result) then
               return False;
            end if;
            return True;
         end if;
      end if;

      if T (Pos) = '(' then
         Pos := Pos + 1;
         if not Parse_Expression (Pos, Result) then
            return False;
         end if;
         Skip_Spaces (Pos);
         if Pos > T'Last or else T (Pos) /= ')' then
            return False;
         end if;
         Pos := Pos + 1;
         return True;
      end if;

      if T (Pos) in 'A' .. 'Z' or else T (Pos) in 'a' .. 'z' then
         Start := Pos;
         while Pos <= T'Last loop
            if T (Pos) in 'A' .. 'Z'
              or else T (Pos) in 'a' .. 'z'
              or else T (Pos) in '0' .. '9'
              or else T (Pos) = '_'
              or else T (Pos) = '.'
            then
               Pos := Pos + 1;
            else
               exit;
            end if;
         end loop;

         declare
            Name_Text : constant String := T (Start .. Pos - 1);
            Attr_Start : Natural;
            Attr_Stop  : Natural;
            Qualified_Value : Natural := 0;
            Has_Low  : Boolean := False;
            Low      : Integer := 0;
            Has_High : Boolean := False;
            High     : Integer := 0;
         begin
            Skip_Spaces (Pos);
            if Pos <= T'Last and then T (Pos) = Character'Val (39) then
               Pos := Pos + 1;
               Skip_Spaces (Pos);
               if Pos <= T'Last and then T (Pos) = '(' then
                  Pos := Pos + 1;
                  if not Parse_Expression (Pos, Qualified_Value) then
                     return False;
                  end if;
                  Skip_Spaces (Pos);
                  if Pos > T'Last or else T (Pos) /= ')' then
                     return False;
                  end if;
                  Pos := Pos + 1;
                  if not Static_Value_In_Type_Range (Name_Text, Qualified_Value) then
                     return False;
                  end if;
                  Result := Qualified_Value;
                  return True;
               elsif Pos <= T'Last
                 and then (T (Pos) in 'A' .. 'Z' or else T (Pos) in 'a' .. 'z')
               then
                  Attr_Start := Pos;
                  while Pos <= T'Last
                    and then (T (Pos) in 'A' .. 'Z'
                              or else T (Pos) in 'a' .. 'z'
                              or else T (Pos) in '0' .. '9'
                              or else T (Pos) = '_')
                  loop
                     Pos := Pos + 1;
                  end loop;
                  Attr_Stop := Pos - 1;
                  declare
                     Attr_Name : constant String :=
                       Lower (T (Attr_Start .. Attr_Stop));
                     Attr_Value : Natural := 0;
                  begin
                     if Attr_Name = "base" then
                        declare
                           Saved_Pos : constant Natural := Pos;
                           Probe     : Natural := Pos;
                        begin
                           Skip_Spaces (Probe);
                           if Probe <= T'Last
                             and then T (Probe) = Character'Val (39)
                           then
                              Probe := Probe + 1;
                              Skip_Spaces (Probe);
                           end if;

                           if Probe <= T'Last and then T (Probe) = '(' then
                              Pos := Probe + 1;
                           else
                              Pos := Saved_Pos;
                           end if;
                        end;

                        if Pos > 0
                          and then Pos <= T'Last
                          and then T (Pos - 1) = '('
                        then
                           if not Parse_Expression (Pos, Qualified_Value) then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Static_Value_In_Type_Range
                                    (Name_Text, Qualified_Value)
                           then
                              return False;
                           end if;
                           Result := Qualified_Value;
                           return True;
                        end if;
                     end if;

                     if Attr_Name = "min" or else Attr_Name = "max" then
                        --  scalar T'Min/T'Max are static scalar
                        --  functions.  Evaluate the two static operands and
                        --  keep the result only when both operands are
                        --  compatible with the retained subtype range.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Left_Value  : Natural := 0;
                           Right_Value : Natural := 0;
                        begin
                           if not Parse_Discrete_Natural_Operand
                                (Pos, Name_Text, ',', Left_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ',' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Parse_Discrete_Natural_Operand
                                (Pos, Name_Text, ')', Right_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Static_Value_In_Type_Range (Name_Text, Left_Value)
                             or else not Static_Value_In_Type_Range
                               (Name_Text, Right_Value)
                           then
                              return False;
                           end if;
                           if Attr_Name = "min" then
                              if Left_Value <= Right_Value then
                                 Result := Left_Value;
                              else
                                 Result := Right_Value;
                              end if;
                           else
                              if Left_Value >= Right_Value then
                                 Result := Left_Value;
                              else
                                 Result := Right_Value;
                              end if;
                           end if;
                           return True;
                        end;
                     end if;

                     if Attr_Name = "succ" or else Attr_Name = "pred" then
                        --  scalar successor/predecessor attributes are
                        --  static for discrete operands when both the operand and
                        --  the resulting adjacent value remain in the retained
                        --  subtype range.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Operand_Value : Natural := 0;
                           Candidate     : Natural := 0;
                        begin
                           if not Parse_Discrete_Natural_Operand
                                (Pos, Name_Text, ')', Operand_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Static_Value_In_Type_Range
                                    (Name_Text, Operand_Value)
                           then
                              return False;
                           end if;
                           if Attr_Name = "succ" then
                              Candidate := Operand_Value + 1;
                           else
                              if Operand_Value = 0 then
                                 return False;
                              end if;
                              Candidate := Operand_Value - 1;
                           end if;
                           if not Static_Value_In_Type_Range
                                    (Name_Text, Candidate)
                           then
                              return False;
                           end if;
                           Result := Candidate;
                           return True;
                        exception
                           when Constraint_Error =>
                              return False;
                        end;
                     end if;

                     if Attr_Name = "value" then
                        --  scalar T'Value (static_string) yields a
                        --  discrete value and can therefore feed integer-valued
                        --  representation expressions through the retained
                        --  position model.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Operand_Start : Natural := Pos;
                           Operand_Stop  : Natural := 0;
                           Operand_Value : Natural := 0;
                        begin
                           if not Scan_To_Static_Outer_Right_Paren
                             (Pos, Operand_Start, Operand_Stop)
                             or else Pos > T'Last
                             or else T (Pos) /= ')'
                           then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if Static_Discrete_Value_String_Position
                                (Name_Text, T (Operand_Start .. Operand_Stop),
                                 Operand_Value)
                             and then Static_Value_In_Type_Range
                               (Name_Text, Operand_Value)
                           then
                              Result := Operand_Value;
                              return True;
                           else
                              declare
                                 Integer_Value : Integer := 0;
                              begin
                                 if Static_Integer_Value_String_Value
                                      (Name_Text,
                                       T (Operand_Start .. Operand_Stop),
                                       Integer_Value)
                                   and then Integer_Value >= 0
                                 then
                                    Result := Natural (Integer_Value);
                                    return True;
                                 end if;
                              end;
                           end if;
                           return False;
                        exception
                           when Constraint_Error =>
                              return False;
                        end;
                     end if;

                     if Attr_Name = "pos" or else Attr_Name = "val" then
                        --  retain enumeration-literal position
                        --  evaluation in addition to the integer-like Pos/Val
                        --  path.  T'Pos (Literal) now resolves through the
                        --  enumeration metadata captured from the type
                        --  declaration, while T'Val continues to range-check
                        --  a universal-integer operand.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Operand_Start : constant Natural := Pos;
                           Operand_Value : Natural := 0;
                           Literal_Start : Natural := 0;
                           Literal_Stop  : Natural := 0;
                        begin
                           if Parse_Expression (Pos, Operand_Value) then
                              Skip_Spaces (Pos);
                              if Pos > T'Last or else T (Pos) /= ')' then
                                 return False;
                              end if;
                              Pos := Pos + 1;
                              if not Static_Value_In_Type_Range
                                       (Name_Text, Operand_Value)
                              then
                                 return False;
                              end if;
                              Result := Operand_Value;
                              return True;
                           elsif Attr_Name = "pos" then
                              Pos := Operand_Start;
                              Skip_Spaces (Pos);
                              Literal_Start := Pos;
                              --  T'Pos accepts nested static
                              --  discrete expressions, not only a bare
                              --  literal/constant token.  Match the
                              --  closing parenthesis at the outer level
                              --  so Color'Pos (Color'Max (Red, Green))
                              --  is passed intact to the retained
                              --  discrete evaluator.
                              declare
                                 Depth : Integer := 0;
                              begin
                                 while Pos <= T'Last loop
                                    if T (Pos) = '"' then
                                       while Pos <= T'Last loop
                                          if T (Pos) = '"' then
                                             if Pos < T'Last
                                               and then T (Pos + 1) = '"'
                                             then
                                                Pos := Pos + 2;
                                             else
                                                Pos := Pos + 1;
                                                exit;
                                             end if;
                                          else
                                             Pos := Pos + 1;
                                          end if;
                                       end loop;
                                    elsif T (Pos) = Character'Val (39)
                                      and then Pos + 3 <= T'Last
                                      and then T (Pos + 1) = Character'Val (39)
                                      and then T (Pos + 2) = Character'Val (39)
                                      and then T (Pos + 3) = Character'Val (39)
                                    then
                                       Literal_Stop := Pos + 3;
                                       Pos := Pos + 4;
                                    elsif T (Pos) = Character'Val (39)
                                      and then Pos + 2 <= T'Last
                                      and then T (Pos + 2) = Character'Val (39)
                                    then
                                       Literal_Stop := Pos + 2;
                                       Pos := Pos + 3;
                                    elsif T (Pos) = '(' then
                                       Depth := Depth + 1;
                                       Literal_Stop := Pos;
                                       Pos := Pos + 1;
                                    elsif T (Pos) = ')' then
                                       if Depth = 0 then
                                          exit;
                                       end if;
                                       Depth := Depth - 1;
                                       Literal_Stop := Pos;
                                       Pos := Pos + 1;
                                    else
                                       Literal_Stop := Pos;
                                       Pos := Pos + 1;
                                    end if;
                                 end loop;
                              end;
                              if Literal_Stop < Literal_Start
                                or else Pos > T'Last
                                or else T (Pos) /= ')'
                              then
                                 return False;
                              end if;
                              Pos := Pos + 1;
                              if Static_Discrete_Default_Position
                                   (Name_Text,
                                    T (Literal_Start .. Literal_Stop),
                                    Operand_Value)
                                or else Static_Discrete_Literal_Position
                                   (Name_Text,
                                    T (Literal_Start .. Literal_Stop),
                                    Operand_Value)
                                or else Static_Discrete_Constant_Position
                                          (Name_Text,
                                           T (Literal_Start .. Literal_Stop),
                                           Operand_Value)
                              then
                                 Result := Operand_Value;
                                 return True;
                              end if;
                           end if;
                           return False;
                        exception
                           when Constraint_Error =>
                              return False;
                        end;
                     end if;

                     if Attr_Name = "base" then
                        --  a subtype mark followed by 'Base is still a
                        --  scalar subtype mark for static attribute/qualification
                        --  purposes in the retained evaluator.  Handle common
                        --  chained forms such as T'Base'First, T'Base'Last, and
                        --  T'Base'(Expr) instead of dropping them as unknown
                        --  attribute references.
                        Skip_Spaces (Pos);
                        if Pos <= T'Last and then T (Pos) = Character'Val (39) then
                           Pos := Pos + 1;
                           Skip_Spaces (Pos);
                           if Pos <= T'Last
                             and then (T (Pos) in 'A' .. 'Z'
                                       or else T (Pos) in 'a' .. 'z')
                           then
                              declare
                                 Base_Attr_Start : constant Natural := Pos;
                                 Base_Attr_Stop  : Natural := Pos;
                              begin
                                 while Pos <= T'Last
                                   and then (T (Pos) in 'A' .. 'Z'
                                             or else T (Pos) in 'a' .. 'z'
                                             or else T (Pos) in '0' .. '9'
                                             or else T (Pos) = '_')
                                 loop
                                    Base_Attr_Stop := Pos;
                                    Pos := Pos + 1;
                                 end loop;

                                 declare
                                    Base_Attr_Name : constant String :=
                                      Lower
                                        (T (Base_Attr_Start .. Base_Attr_Stop));
                                    Base_Type_Name : constant String :=
                                      Static_Subtype_Root (Name_Text);
                                 begin
                                    --  chained 'Base scalar attributes in
                                    --  representation expressions use the scalar
                                    --  root for operand and result range checks.
                                    --  Thus Primary_Color'Base'Val (2) and
                                    --  Primary_Color'Base'Succ (Green) can yield
                                    --  Blue even when Primary_Color itself ends
                                    --  at Green.
                                    if Base_Attr_Name = "min"
                                      or else Base_Attr_Name = "max"
                                    then
                                       Skip_Spaces (Pos);
                                       if Pos > T'Last or else T (Pos) /= '(' then
                                          return False;
                                       end if;
                                       Pos := Pos + 1;
                                       declare
                                          Left_Value  : Natural := 0;
                                          Right_Value : Natural := 0;
                                       begin
                                          if not Parse_Discrete_Natural_Operand
                                               (Pos, Base_Type_Name, ',', Left_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ',' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if not Parse_Discrete_Natural_Operand
                                               (Pos, Base_Type_Name, ')', Right_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if not Static_Value_In_Type_Range
                                                   (Base_Type_Name, Left_Value)
                                            or else not Static_Value_In_Type_Range
                                              (Base_Type_Name, Right_Value)
                                          then
                                             return False;
                                          end if;
                                          if Base_Attr_Name = "min" then
                                             if Left_Value <= Right_Value then
                                                Result := Left_Value;
                                             else
                                                Result := Right_Value;
                                             end if;
                                          else
                                             if Left_Value >= Right_Value then
                                                Result := Left_Value;
                                             else
                                                Result := Right_Value;
                                             end if;
                                          end if;
                                          return True;
                                       end;
                                    end if;

                                    if Base_Attr_Name = "succ"
                                      or else Base_Attr_Name = "pred"
                                    then
                                       Skip_Spaces (Pos);
                                       if Pos > T'Last or else T (Pos) /= '(' then
                                          return False;
                                       end if;
                                       Pos := Pos + 1;
                                       declare
                                          Operand_Value : Natural := 0;
                                          Candidate     : Natural := 0;
                                       begin
                                          if not Parse_Discrete_Natural_Operand
                                               (Pos, Base_Type_Name, ')', Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if not Static_Value_In_Type_Range
                                                   (Base_Type_Name, Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          if Base_Attr_Name = "succ" then
                                             Candidate := Operand_Value + 1;
                                          else
                                             if Operand_Value = 0 then
                                                return False;
                                             end if;
                                             Candidate := Operand_Value - 1;
                                          end if;
                                          if not Static_Value_In_Type_Range
                                                   (Base_Type_Name, Candidate)
                                          then
                                             return False;
                                          end if;
                                          Result := Candidate;
                                          return True;
                                       exception
                                          when Constraint_Error =>
                                             return False;
                                       end;
                                    end if;

                                    if Base_Attr_Name = "value" then
                                       Skip_Spaces (Pos);
                                       if Pos > T'Last or else T (Pos) /= '(' then
                                          return False;
                                       end if;
                                       Pos := Pos + 1;
                                       declare
                                          Operand_Start : Natural := Pos;
                                          Operand_Stop  : Natural := 0;
                                          Operand_Value : Natural := 0;
                                       begin
                                          --  keep T'Base'Value in parity with
                                          --  the direct T'Value scanner from .
                                          --  Nested static string operands such as
                                          --  Color'Base'Image (Blue) must be scanned as
                                          --  a complete operand instead of stopping at
                                          --  the Image call's right parenthesis.
                                          if not Scan_To_Static_Outer_Right_Paren
                                            (Pos, Operand_Start, Operand_Stop)
                                            or else Pos > T'Last
                                            or else T (Pos) /= ')'
                                          then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if Static_Discrete_Value_String_Position
                                               (Base_Type_Name,
                                                T (Operand_Start .. Operand_Stop),
                                                Operand_Value)
                                            and then Static_Value_In_Type_Range
                                              (Base_Type_Name, Operand_Value)
                                          then
                                             Result := Operand_Value;
                                             return True;
                                          else
                                             declare
                                                Integer_Value : Integer := 0;
                                             begin
                                                if Static_Integer_Value_String_Value
                                                     (Base_Type_Name,
                                                      T (Operand_Start .. Operand_Stop),
                                                      Integer_Value)
                                                  and then Integer_Value >= 0
                                                then
                                                   Result := Natural (Integer_Value);
                                                   return True;
                                                end if;
                                             end;
                                          end if;
                                          return False;
                                       exception
                                          when Constraint_Error =>
                                             return False;
                                       end;
                                    end if;

                                    if Base_Attr_Name = "pos"
                                      or else Base_Attr_Name = "val"
                                    then
                                       Skip_Spaces (Pos);
                                       if Pos > T'Last or else T (Pos) /= '(' then
                                          return False;
                                       end if;
                                       Pos := Pos + 1;
                                       declare
                                          Operand_Value : Natural := 0;
                                       begin
                                          if not Parse_Discrete_Natural_Operand
                                               (Pos, Base_Type_Name, ')', Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if not Static_Value_In_Type_Range
                                                   (Base_Type_Name, Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          Result := Operand_Value;
                                          return True;
                                       exception
                                          when Constraint_Error =>
                                             return False;
                                       end;
                                    end if;

                                    if Static_Type_Range
                                         (Base_Type_Name, Has_Low, Low, Has_High, High)
                                    then
                                       if Base_Attr_Name = "first" then
                                          if Has_Low and then Low >= 0 then
                                             Result := Natural (Low);
                                             return True;
                                          else
                                             return False;
                                          end if;
                                       elsif Base_Attr_Name = "last" then
                                          if Has_High and then High >= 0 then
                                             Result := Natural (High);
                                             return True;
                                          else
                                             return False;
                                          end if;
                                       elsif Base_Attr_Name = "modulus" then
                                          if Static_Type_Modulus (Base_Type_Name, Result) then
                                             return True;
                                          else
                                             return False;
                                          end if;
                                       elsif Base_Attr_Name = "width" then
                                          if Static_Type_Width (Base_Type_Name, Result) then
                                             return True;
                                          else
                                             return False;
                                          end if;
                                       end if;
                                    end if;
                                 end;
                              end;
                           end if;
                           return False;
                        elsif Pos <= T'Last and then T (Pos) = '(' then
                           Pos := Pos + 1;
                           if not Parse_Expression (Pos, Qualified_Value) then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Static_Value_In_Type_Range
                                    (Name_Text, Qualified_Value)
                           then
                              return False;
                           end if;
                           Result := Qualified_Value;
                           return True;
                        else
                           return False;
                        end if;
                     end if;

                     if Attr_Name = "length"
                       or else Attr_Name = "first"
                       or else Attr_Name = "last"
                     then
                        --  retained bounded static string constants
                        --  also accept the one-dimensional array attribute
                        --  spelling S'Length (1), S'First (1), and S'Last (1).
                        --  The dimension argument is consumed and must statically
                        --  evaluate to 1; other dimensions are deliberately
                        --  rejected because String is one-dimensional.
                        declare
                           Bound_Value : Natural := 0;
                           Dim_Value   : Natural := 0;
                        begin
                           if Static_String_Bound_Value
                                (Name_Text, Attr_Name, Bound_Value)
                           then
                              Skip_Spaces (Pos);
                              if Pos <= T'Last and then T (Pos) = '(' then
                                 Pos := Pos + 1;
                                 if not Parse_Expression (Pos, Dim_Value) then
                                    return False;
                                 end if;
                                 Skip_Spaces (Pos);
                                 if Pos > T'Last or else T (Pos) /= ')' then
                                    return False;
                                 end if;
                                 Pos := Pos + 1;
                                 if Dim_Value /= 1 then
                                    return False;
                                 end if;
                              end if;
                              Result := Bound_Value;
                              return True;
                           elsif Attr_Name = "length" then
                              return False;
                           end if;
                        end;
                     end if;

                     if Static_Type_Range
                          (Name_Text, Has_Low, Low, Has_High, High)
                     then
                        if Attr_Name = "first" then
                           if Has_Low and then Low >= 0 then
                              Result := Natural (Low);
                              return True;
                           else
                              return False;
                           end if;
                        elsif Attr_Name = "last" then
                           if Has_High and then High >= 0 then
                              Result := Natural (High);
                              return True;
                           else
                              return False;
                           end if;
                        elsif Attr_Name = "modulus" then
                           if Static_Type_Modulus (Name_Text, Result) then
                              return True;
                           else
                              return False;
                           end if;
                        elsif Attr_Name = "width" then
                           if Static_Type_Width (Name_Text, Result) then
                              return True;
                           else
                              return False;
                           end if;
                        end if;
                     end if;

                     if Static_Attribute_Value
                          (Name_Text, Attr_Name, Attr_Value)
                     then
                        Result := Attr_Value;
                        return True;
                     end if;
                  end;
                  return False;
               else
                  return False;
               end if;
            end if;

            return Static_Named_Number_Value (Name_Text, Result);
         end;
      end if;

      Start := Pos;
      if T (Pos) = '+' then
         Pos := Pos + 1;
      elsif T (Pos) = '-' then
         return False;
      end if;

      Stop := Pos - 1;
      while Pos <= T'Last loop
         if T (Pos) in 'A' .. 'Z'
           or else T (Pos) in 'a' .. 'z'
           or else T (Pos) in '0' .. '9'
           or else T (Pos) = '_'
           or else T (Pos) = '#'
         then
            Stop := Pos;
            Pos := Pos + 1;
         elsif (T (Pos) = '+' or else T (Pos) = '-')
           and then Stop >= Start
           and then (T (Stop) = 'e' or else T (Stop) = 'E')
         then
            Stop := Pos;
            Pos := Pos + 1;
         else
            exit;
         end if;
      end loop;

      if Stop < Start then
         return False;
      end if;

      return Representation_Static_Values.Parse_Static_Unsigned_Numeric_Literal
        (T (Start .. Stop), Result);
   end Parse_Primary;

   function Parse_Power (Pos : in out Natural; Result : out Natural) return Boolean is
      Right : Natural := 0;
      Acc : Natural;
      Exp_Pos : Natural;
   begin
      if not Parse_Primary (Pos, Result) then
         return False;
      end if;

      Skip_Spaces (Pos);
      if Pos + 1 <= T'Last and then T (Pos .. Pos + 1) = "**" then
         Pos := Pos + 2;
         if not Parse_Power (Pos, Right) then
            return False;
         end if;
         Acc := 1;
         Exp_Pos := 0;
         while Exp_Pos < Right loop
            Acc := Acc * Result;
            Exp_Pos := Exp_Pos + 1;
         end loop;
         Result := Acc;
      end if;

      return True;
   end Parse_Power;

   function Parse_Term (Pos : in out Natural; Result : out Natural) return Boolean is
      Right : Natural := 0;
   begin
      if not Parse_Power (Pos, Result) then
         return False;
      end if;

      loop
         Skip_Spaces (Pos);
         if Pos <= T'Last and then T (Pos) = '*' then
            if Pos + 1 <= T'Last and then T (Pos + 1) = '*' then
               return True;
            end if;
            Pos := Pos + 1;
            if not Parse_Power (Pos, Right) then
               return False;
            end if;
            Result := Result * Right;
         elsif Pos <= T'Last and then T (Pos) = '/' then
            Pos := Pos + 1;
            if not Parse_Power (Pos, Right) or else Right = 0 then
               return False;
            end if;
            if Result mod Right /= 0 then
               return False;
            end if;
            Result := Result / Right;
         elsif Lexical_Helpers.Starts_At_Word (T, Pos, "mod") then
            Pos := Pos + 3;
            if not Parse_Power (Pos, Right) or else Right = 0 then
               return False;
            end if;
            Result := Result mod Right;
         elsif Lexical_Helpers.Starts_At_Word (T, Pos, "rem") then
            Pos := Pos + 3;
            if not Parse_Power (Pos, Right) or else Right = 0 then
               return False;
            end if;
            Result := Result rem Right;
         else
            return True;
         end if;
      end loop;
   end Parse_Term;

   function Parse_Expression (Pos : in out Natural; Result : out Natural) return Boolean is
      Right : Natural := 0;
   begin
      if not Parse_Term (Pos, Result) then
         return False;
      end if;

      loop
         Skip_Spaces (Pos);
         if Pos <= T'Last and then T (Pos) = '+' then
            Pos := Pos + 1;
            if not Parse_Term (Pos, Right) then
               return False;
            end if;
            Result := Result + Right;
         elsif Pos <= T'Last and then T (Pos) = '-' then
            Pos := Pos + 1;
            if not Parse_Term (Pos, Right) or else Right > Result then
               return False;
            end if;
            Result := Result - Right;
         else
            return True;
         end if;
      end loop;
   end Parse_Expression;

   Pos : Natural := T'First;
   Parsed_Value : Natural := 0;
begin
   Valid := False;
   Value := 0;
   if T = "" then
      return;
   end if;

   if Parse_Expression (Pos, Parsed_Value) then
      Skip_Spaces (Pos);
      if Pos > T'Last then
         Valid := True;
         Value := Parsed_Value;
      end if;
   end if;
end Parse_Static_Natural;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Natural_Parsing;
