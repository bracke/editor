with Editor.Ada_Declaration_Parser.Lexical_Helpers; use Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Text_Helpers; use Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing is

procedure Parse_Static_Integer
  (Ops   : Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing.Operations;
   Text  : String;
   Valid : out Boolean;
   Value : out Integer)
is
   T : constant String := Ops.Clean_Metadata_Name.all (Text);

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

   procedure Skip_Spaces (Pos : in out Natural) is
   begin
      while Pos <= T'Last and then Is_Static_Space (T (Pos)) loop
         Pos := Pos + 1;
      end loop;
   end Skip_Spaces;

   function Parse_Expression (Pos : in out Natural; Result : out Integer) return Boolean;
   function Parse_Term (Pos : in out Natural; Result : out Integer) return Boolean;
   function Parse_Power (Pos : in out Natural; Result : out Integer) return Boolean;
   function Parse_Primary (Pos : in out Natural; Result : out Integer) return Boolean;

   function Scan_To_Static_Outer_Right_Paren
     (Pos    : in out Natural;
      Start  : out Natural;
      Stop   : out Natural) return Boolean
   is
      Depth : Natural := 0;
   begin
      Start := Pos;
      Stop := 0;
      while Pos <= T'Last loop
         if T (Pos) = '(' then
            Depth := Depth + 1;
         elsif T (Pos) = ')' then
            if Depth = 0 then
               Stop := Pos - 1;
               return Stop >= Start;
            else
               Depth := Depth - 1;
            end if;
         end if;
         Pos := Pos + 1;
      end loop;
      return False;
   end Scan_To_Static_Outer_Right_Paren;

   function Parse_Discrete_Integer_Operand
     (Pos       : in out Natural;
      Type_Name : String;
      Delimiter : Character;
      Result    : out Integer) return Boolean
   is
      Saved_Pos : constant Natural := Pos;
      Literal_Start : Natural := 0;
      Literal_Stop  : Natural := 0;
      Lit_Position  : Natural := 0;
   begin
      Result := 0;
      if Parse_Expression (Pos, Result) then
         return True;
      end if;

      Pos := Saved_Pos;
      Skip_Spaces (Pos);
      Literal_Start := Pos;
      while Pos <= T'Last and then T (Pos) /= Delimiter loop
         Literal_Stop := Pos;
         Pos := Pos + 1;
      end loop;

      if Literal_Stop < Literal_Start then
         return False;
      end if;

      if Static_Discrete_Literal_Position
           (Type_Name, T (Literal_Start .. Literal_Stop), Lit_Position)
        or else Static_Discrete_Constant_Position
                  (Type_Name, T (Literal_Start .. Literal_Stop), Lit_Position)
      then
         Result := Integer (Lit_Position);
         return True;
      end if;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Parse_Discrete_Integer_Operand;

   function Parse_Primary (Pos : in out Natural; Result : out Integer) return Boolean is
      Start : Natural;
      Stop  : Natural;
      Nat_Value : Natural := 0;
      Has_Low  : Boolean := False;
      Low      : Integer := 0;
      Has_High : Boolean := False;
      High     : Integer := 0;
   begin
      Result := 0;
      Skip_Spaces (Pos);
      if Pos > T'Last then
         return False;
      end if;

      if Representation_Static_Values.Parse_Static_String_Bound_Primary
           (T,
            Pos,
            Result,
            Parse_Expression'Unrestricted_Access,
            Static_String_Bound_Value'Unrestricted_Access)
      then
         return True;
      end if;

      if Lexical_Helpers.Starts_At_Word (T, Pos, "abs") then
         --  signed static expressions support Ada unary abs,
         --  preserving range metadata construction from negative bounds
         --  while returning the universal-integer absolute value.
         Pos := Pos + 3;
         if not Parse_Primary (Pos, Result) then
            return False;
         end if;
         if Result < 0 then
            Result := -Result;
         end if;
         return True;
      elsif T (Pos) = '+' then
         Pos := Pos + 1;
         return Parse_Primary (Pos, Result);
      elsif T (Pos) = '-' then
         Pos := Pos + 1;
         if not Parse_Primary (Pos, Result) then
            return False;
         end if;
         Result := -Result;
         return True;
      elsif T (Pos) = '(' then
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
            Qualified_Value : Integer := 0;
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
                  if not Static_Type_Range (Name_Text, Has_Low, Low, Has_High, High) then
                     Result := Qualified_Value;
                     return True;
                  elsif (Has_Low and then Qualified_Value < Low)
                    or else (Has_High and then Qualified_Value > High)
                  then
                     return False;
                  else
                     Result := Qualified_Value;
                     return True;
                  end if;
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
                     if Static_String_Subtype_Bound_Value
                          (Name_Text, Attr_Name, Attr_Value)
                     then
                        --  constrained String subtype bounds
                        --  are available to the signed static integer
                        --  evaluator too.  This lets later String
                        --  index constraints reuse earlier retained
                        --  String subtype attributes, for example
                        --  ``subtype Derived is String
                        --  (Offset_Name'First .. Offset_Name'Last);``.
                        --
                        --  accept the optional one-dimensional
                        --  array attribute argument as well, for example
                        --  ``Offset_Name'First (1)`` in a later String
                        --  index constraint.  Only dimension 1 is static
                        --  for the bounded String model.
                        Skip_Spaces (Pos);
                        if Pos <= T'Last and then T (Pos) = '(' then
                           declare
                              Dim_Value : Integer := 0;
                           begin
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
                           end;
                        end if;

                        Result := Integer (Attr_Value);
                        return True;
                     end if;

                     if Static_String_Constant_Bound_Value
                          (Name_Text, Attr_Name, Attr_Value)
                     then
                        --  constrained String object bounds are
                        --  static signed-integer operands as well.  This
                        --  carries retained object bounds into later
                        --  index constraints such as ``String
                        --  (Offset_Object'First .. Offset_Object'Last)``
                        --  instead of exposing them only to representation
                        --  expressions.
                        --
                        --  mirror the subtype path for
                        --  one-dimensional array attribute arguments on
                        --  retained constrained String objects.
                        Skip_Spaces (Pos);
                        if Pos <= T'Last and then T (Pos) = '(' then
                           declare
                              Dim_Value : Integer := 0;
                           begin
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
                           end;
                        end if;

                        Result := Integer (Attr_Value);
                        return True;
                     end if;

                     if Static_String_Bound_Value
                          (Name_Text, Attr_Name, Attr_Value)
                     then
                        --  unconstrained retained String
                        --  constants also have static one-dimensional
                        --  First/Last/Length values.  The representation
                        --  evaluator already exposed those bounds, but
                        --  String index constraints using
                        --  ``Constant_Name'First .. Constant_Name'Last``
                        --  bypassed that fallback by checking only the
                        --  explicitly bounded object table.
                        --  Reuse the shared bound evaluator here so a
                        --  named unconstrained static String constant can
                        --  define later constrained String subtype bounds.
                        Skip_Spaces (Pos);
                        if Pos <= T'Last and then T (Pos) = '(' then
                           declare
                              Dim_Value : Integer := 0;
                           begin
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
                           end;
                        end if;

                        Result := Integer (Attr_Value);
                        return True;
                     end if;

                     if Attr_Name = "min" or else Attr_Name = "max" then
                        --  scalar T'Min/T'Max remain static in
                        --  signed expressions; both operands must satisfy the
                        --  retained subtype range before the result is reused.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Left_Value  : Integer := 0;
                           Right_Value : Integer := 0;
                        begin
                           if not Parse_Discrete_Integer_Operand
                                (Pos, Name_Text, ',', Left_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ',' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if not Parse_Discrete_Integer_Operand
                                (Pos, Name_Text, ')', Right_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if Static_Type_Range
                                (Name_Text, Has_Low, Low, Has_High, High)
                           then
                              if (Has_Low and then Left_Value < Low)
                                or else (Has_High and then Left_Value > High)
                                or else (Has_Low and then Right_Value < Low)
                                or else (Has_High and then Right_Value > High)
                              then
                                 return False;
                              end if;
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
                        --  signed static expressions also evaluate
                        --  discrete successor/predecessor attribute functions,
                        --  while preserving subtype range compatibility.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Operand_Value : Integer := 0;
                           Candidate     : Integer := 0;
                        begin
                           if not Parse_Discrete_Integer_Operand
                                (Pos, Name_Text, ')', Operand_Value)
                           then
                              return False;
                           end if;
                           Skip_Spaces (Pos);
                           if Pos > T'Last or else T (Pos) /= ')' then
                              return False;
                           end if;
                           Pos := Pos + 1;
                           if Static_Type_Range
                                (Name_Text, Has_Low, Low, Has_High, High)
                           then
                              if (Has_Low and then Operand_Value < Low)
                                or else (Has_High and then Operand_Value > High)
                              then
                                 return False;
                              end if;
                           end if;
                           if Attr_Name = "succ" then
                              Candidate := Operand_Value + 1;
                           else
                              Candidate := Operand_Value - 1;
                           end if;
                           if Static_Type_Range
                                (Name_Text, Has_Low, Low, Has_High, High)
                           then
                              if (Has_Low and then Candidate < Low)
                                or else (Has_High and then Candidate > High)
                              then
                                 return False;
                              end if;
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
                        --  discrete value and can therefore feed signed
                        --  static expressions through the retained position
                        --  model.
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
                              Result := Integer (Operand_Value);
                              return True;
                           elsif Static_Integer_Value_String_Value
                                   (Name_Text,
                                    T (Operand_Start .. Operand_Stop),
                                    Result)
                           then
                              return True;
                           end if;
                           return False;
                        exception
                           when Constraint_Error =>
                              return False;
                        end;
                     end if;

                     if Attr_Name = "pos" or else Attr_Name = "val" then
                        --  signed static expressions also resolve
                        --  enumeration literal positions for T'Pos (Literal).
                        --  Numeric T'Val operands continue to be checked against
                        --  the retained scalar range before becoming universal
                        --  integers.
                        Skip_Spaces (Pos);
                        if Pos > T'Last or else T (Pos) /= '(' then
                           return False;
                        end if;
                        Pos := Pos + 1;
                        declare
                           Operand_Start : constant Natural := Pos;
                           Operand_Value : Integer := 0;
                           Enum_Pos      : Natural := 0;
                           Literal_Start : Natural := 0;
                           Literal_Stop  : Natural := 0;
                        begin
                           if Parse_Expression (Pos, Operand_Value) then
                              Skip_Spaces (Pos);
                              if Pos > T'Last or else T (Pos) /= ')' then
                                 return False;
                              end if;
                              Pos := Pos + 1;
                              if Static_Type_Range
                                   (Name_Text, Has_Low, Low, Has_High, High)
                              then
                                 if (Has_Low and then Operand_Value < Low)
                                   or else (Has_High and then Operand_Value > High)
                                 then
                                    return False;
                                 end if;
                              end if;
                              Result := Operand_Value;
                              return True;
                           elsif Attr_Name = "pos" then
                              Pos := Operand_Start;
                              Skip_Spaces (Pos);
                              Literal_Start := Pos;
                              --  signed static expressions use
                              --  the same outer-level T'Pos operand scan
                              --  as the Natural-valued path, so nested
                              --  static discrete expressions are retained
                              --  instead of being truncated at their
                              --  first inner right parenthesis.
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
                                      and then Pos + 2 <= T'Last
                                      and then T (Pos + 2) = Character'Val (39)
                                    then
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
                                    Enum_Pos)
                                or else Static_Discrete_Literal_Position
                                   (Name_Text,
                                    T (Literal_Start .. Literal_Stop),
                                    Enum_Pos)
                                or else Static_Discrete_Constant_Position
                                          (Name_Text,
                                           T (Literal_Start .. Literal_Stop),
                                           Enum_Pos)
                              then
                                 Result := Integer (Enum_Pos);
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
                        --  preserve chained scalar base attributes in
                        --  signed static expressions as well as natural ones.
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
                                 begin
                                    if Base_Attr_Name = "min"
                                      or else Base_Attr_Name = "max"
                                    then
                                       Skip_Spaces (Pos);
                                       if Pos > T'Last or else T (Pos) /= '(' then
                                          return False;
                                       end if;
                                       Pos := Pos + 1;
                                       declare
                                          Left_Value  : Integer := 0;
                                          Right_Value : Integer := 0;
                                       begin
                                          if not Parse_Discrete_Integer_Operand
                                               (Pos, Name_Text, ',', Left_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ',' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if not Parse_Discrete_Integer_Operand
                                               (Pos, Name_Text, ')', Right_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if Static_Type_Range
                                               (Name_Text, Has_Low, Low, Has_High, High)
                                          then
                                             if (Has_Low and then Left_Value < Low)
                                               or else (Has_High and then Left_Value > High)
                                               or else (Has_Low and then Right_Value < Low)
                                               or else (Has_High and then Right_Value > High)
                                             then
                                                return False;
                                             end if;
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
                                          Operand_Value : Integer := 0;
                                          Candidate     : Integer := 0;
                                       begin
                                          if not Parse_Expression
                                              (Pos, Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if Static_Type_Range
                                               (Name_Text, Has_Low, Low, Has_High, High)
                                          then
                                             if (Has_Low and then Operand_Value < Low)
                                               or else (Has_High and then Operand_Value > High)
                                             then
                                                return False;
                                             end if;
                                          end if;
                                          if Base_Attr_Name = "succ" then
                                             Candidate := Operand_Value + 1;
                                          else
                                             Candidate := Operand_Value - 1;
                                          end if;
                                          if Static_Type_Range
                                               (Name_Text, Has_Low, Low, Has_High, High)
                                          then
                                             if (Has_Low and then Candidate < Low)
                                               or else (Has_High and then Candidate > High)
                                             then
                                                return False;
                                             end if;
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
                                          Operand_Start : constant Natural := Pos;
                                          Operand_Stop  : Natural := 0;
                                          Operand_Value : Natural := 0;
                                       begin
                                          while Pos <= T'Last and then T (Pos) /= ')' loop
                                             Operand_Stop := Pos;
                                             Pos := Pos + 1;
                                          end loop;
                                          if Operand_Stop < Operand_Start
                                            or else Pos > T'Last
                                            or else T (Pos) /= ')'
                                          then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if Static_Discrete_Value_String_Position
                                               (Name_Text,
                                                T (Operand_Start .. Operand_Stop),
                                                Operand_Value)
                                            and then Static_Value_In_Type_Range
                                              (Name_Text, Operand_Value)
                                          then
                                             Result := Integer (Operand_Value);
                                             return True;
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
                                          Operand_Value : Integer := 0;
                                       begin
                                          if not Parse_Expression
                                              (Pos, Operand_Value)
                                          then
                                             return False;
                                          end if;
                                          Skip_Spaces (Pos);
                                          if Pos > T'Last or else T (Pos) /= ')' then
                                             return False;
                                          end if;
                                          Pos := Pos + 1;
                                          if Static_Type_Range
                                               (Name_Text, Has_Low, Low, Has_High, High)
                                          then
                                             if (Has_Low and then Operand_Value < Low)
                                               or else (Has_High and then Operand_Value > High)
                                             then
                                                return False;
                                             end if;
                                          end if;
                                          Result := Operand_Value;
                                          return True;
                                       exception
                                          when Constraint_Error =>
                                             return False;
                                       end;
                                    end if;

                                    if Static_Type_Range
                                         (Name_Text, Has_Low, Low, Has_High, High)
                                    then
                                       if Base_Attr_Name = "first" and then Has_Low then
                                          Result := Low;
                                          return True;
                                       elsif Base_Attr_Name = "last" and then Has_High then
                                          Result := High;
                                          return True;
                                       elsif Base_Attr_Name = "modulus" then
                                          if Static_Type_Modulus (Name_Text, Nat_Value) then
                                             Result := Integer (Nat_Value);
                                             return True;
                                          else
                                             return False;
                                          end if;
                                       elsif Base_Attr_Name = "width" then
                                          if Static_Type_Width (Name_Text, Nat_Value) then
                                             Result := Integer (Nat_Value);
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
                           if Static_Type_Range
                                (Name_Text, Has_Low, Low, Has_High, High)
                             and then ((Has_Low and then Qualified_Value < Low)
                                       or else
                                       (Has_High and then Qualified_Value > High))
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
                        --  signed static expressions share the
                        --  retained String'First/String'Last/String'Length
                        --  source and now consume optional dimension-1 array
                        --  attribute arguments such as S'Last (1).
                        declare
                           Bound_Value : Natural := 0;
                           Dim_Value   : Integer := 0;
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
                              Result := Integer (Bound_Value);
                              return True;
                           elsif Attr_Name = "length" then
                              return False;
                           end if;
                        end;
                     end if;

                     if Static_Type_Range
                          (Name_Text, Has_Low, Low, Has_High, High)
                     then
                        if Attr_Name = "first" and then Has_Low then
                           Result := Low;
                           return True;
                        elsif Attr_Name = "last" and then Has_High then
                           Result := High;
                           return True;
                        elsif Attr_Name = "modulus" then
                           if Static_Type_Modulus (Name_Text, Nat_Value) then
                              Result := Integer (Nat_Value);
                              return True;
                           else
                              return False;
                           end if;
                        elsif Attr_Name = "width" then
                           if Static_Type_Width (Name_Text, Nat_Value) then
                              Result := Integer (Nat_Value);
                              return True;
                           else
                              return False;
                           end if;
                        end if;
                     end if;

                     if Static_Attribute_Value
                          (Name_Text, Attr_Name, Attr_Value)
                     then
                        Result := Integer (Attr_Value);
                        return True;
                     end if;
                  end;
                  return False;
               else
                  return False;
               end if;
            end if;

            return Static_Integer_Name_Value (Name_Text, Result);
         end;
      end if;

      Start := Pos;
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

      if Representation_Static_Values.Parse_Static_Unsigned_Numeric_Literal
           (T (Start .. Stop), Nat_Value)
      then
         Result := Integer (Nat_Value);
         return True;
      else
         return False;
      end if;
   exception
      when Constraint_Error =>
         return False;
   end Parse_Primary;

   function Parse_Power (Pos : in out Natural; Result : out Integer) return Boolean is
      Right : Integer := 0;
      Acc : Integer;
      Exp_Pos : Integer;
   begin
      if not Parse_Primary (Pos, Result) then
         return False;
      end if;
      Skip_Spaces (Pos);
      if Pos + 1 <= T'Last and then T (Pos .. Pos + 1) = "**" then
         Pos := Pos + 2;
         if not Parse_Power (Pos, Right) or else Right < 0 then
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
   exception
      when Constraint_Error =>
         return False;
   end Parse_Power;

   function Parse_Term (Pos : in out Natural; Result : out Integer) return Boolean is
      Right : Integer := 0;
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
   exception
      when Constraint_Error =>
         return False;
   end Parse_Term;

   function Parse_Expression (Pos : in out Natural; Result : out Integer) return Boolean is
      Right : Integer := 0;
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
            if not Parse_Term (Pos, Right) then
               return False;
            end if;
            Result := Result - Right;
         else
            return True;
         end if;
      end loop;
   exception
      when Constraint_Error =>
         return False;
   end Parse_Expression;

   Pos : Natural := T'First;
   Parsed_Value : Integer := 0;
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
end Parse_Static_Integer;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Integer_Parsing;
