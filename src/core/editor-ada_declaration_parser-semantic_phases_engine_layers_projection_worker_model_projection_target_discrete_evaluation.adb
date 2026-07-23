with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers; use Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Language_Model; use Editor.Ada_Language_Model;
with Editor.Text_Helpers; use Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation is

function Static_Discrete_Default_Position
  (Phase                            : Target_Derivation.Context;
   Type_Name                        : String;
   Default_Text                     : String;
   Parse_Static_Natural             : not null Target_Derivation.Static_Natural_Parser;
   Parse_Static_Integer             : not null Target_Derivation.Static_Integer_Parser;
   Static_Discrete_Literal_Position : not null Static_Discrete_Literal_Query;
   Static_Discrete_Position_Image   : not null Static_Discrete_Image_Query;
   Position                         : out Natural) return Boolean
is
   T : constant String := Target_Derivation.Canonical_Static_Type_Name (Type_Name);
   D : constant String := Trim (Default_Text);
   Quote_Index : Natural := 0;
   Qualified_Open_Pos : Natural := 0;

   function Recursive_Static_Discrete_Default_Position
     (Recursive_Type_Name    : String;
      Recursive_Default_Text : String;
      Recursive_Position     : out Natural) return Boolean
   is
   begin
      return Static_Discrete_Default_Position
        (Phase,
         Recursive_Type_Name,
         Recursive_Default_Text,
         Parse_Static_Natural,
         Parse_Static_Integer,
         Static_Discrete_Literal_Position,
         Static_Discrete_Position_Image,
         Recursive_Position);
   end Recursive_Static_Discrete_Default_Position;

   function Static_Type_Is_Character (Name : String) return Boolean is
   begin
      return Target_Derivation.Static_Type_Is_Character (Phase, Name);
   end Static_Type_Is_Character;

   function Static_Subtype_Root (Name : String) return String is
   begin
      return Target_Derivation.Static_Subtype_Root (Phase, Name);
   exception
      when Constraint_Error =>
         return Target_Derivation.Canonical_Static_Type_Name (Name);
   end Static_Subtype_Root;

   function Static_Subtypes_Compatible
     (Left_Name  : String;
      Right_Name : String) return Boolean
   is
   begin
      return Static_Subtype_Root (Left_Name) = Static_Subtype_Root (Right_Name);
   end Static_Subtypes_Compatible;

   function Static_Value_In_Type_Range
     (Range_Type_Name : String;
      Value           : Natural) return Boolean
   is
   begin
      return Target_Derivation.Static_Value_In_Type_Range
        (Phase, Range_Type_Name, Value);
   end Static_Value_In_Type_Range;

   function Static_Type_Range
     (Range_Type_Name : String;
      Has_Low         : out Boolean;
      Low             : out Integer;
      Has_High        : out Boolean;
      High            : out Integer) return Boolean
   is
   begin
      return Target_Derivation.Static_Type_Range
        (Phase, Range_Type_Name, Has_Low, Low, Has_High, High);
   end Static_Type_Range;

   function Static_String_Default_Value
     (String_Default_Text : String;
      Image_Text          : out Unbounded_String) return Boolean
   is
   begin
      return Target_String_Evaluation.Static_String_Default_Value
        (Phase,
         String_Default_Text,
         Parse_Static_Integer,
         Recursive_Static_Discrete_Default_Position'Unrestricted_Access,
         Static_Discrete_Position_Image,
         Image_Text);
   end Static_String_Default_Value;

   function Static_String_Bound_Value
     (Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean
   is
   begin
      return Target_String_Evaluation.Static_String_Bound_Value
        (Phase,
         Name,
         Attr_Name,
         Static_String_Default_Value'Unrestricted_Access,
         Bound);
   end Static_String_Bound_Value;

   function Static_String_Element_Position
     (Indexed_Text : String;
      Element_Pos  : out Natural) return Boolean
   is
   begin
      return Target_String_Evaluation.Static_String_Element_Position
        (Phase,
         Indexed_Text,
         Parse_Static_Integer,
         Static_String_Default_Value'Unrestricted_Access,
         Static_String_Bound_Value'Unrestricted_Access,
         Element_Pos);
   end Static_String_Element_Position;

   function Static_Discrete_Value_String_Position
     (Value_Type_Name : String;
      String_Text     : String;
      Value_Position  : out Natural) return Boolean
   is
   begin
      return Target_String_Evaluation.Static_Discrete_Value_String_Position
        (Phase,
         Value_Type_Name,
         String_Text,
         Static_String_Default_Value'Unrestricted_Access,
         Static_Discrete_Literal_Position,
         Recursive_Static_Discrete_Default_Position'Unrestricted_Access,
         Value_Position);
   end Static_Discrete_Value_String_Position;

   function Static_Integer_Value_String_Value
     (Value_Type_Name : String;
      String_Text     : String;
      Value           : out Integer) return Boolean
   is
   begin
      return Target_String_Evaluation.Static_Integer_Value_String_Value
        (Phase,
         Value_Type_Name,
         String_Text,
         Static_String_Default_Value'Unrestricted_Access,
         Parse_Static_Integer,
         Value);
   end Static_Integer_Value_String_Value;

   function Static_Discrete_Constant_Position
     (Constant_Type_Name : String;
      Name               : String;
      Constant_Position  : out Natural) return Boolean
   is
   begin
      return Target_Derivation.Static_Discrete_Constant_Position
        (Phase, Constant_Type_Name, Name, Constant_Position);
   end Static_Discrete_Constant_Position;

   function Is_Whole_Parenthesized_Expression (Text : String) return Boolean is
      Depth : Integer := 0;
      I     : Natural := Text'First;
   begin
      if Text'Length < 2
        or else Text (Text'First) /= '('
        or else Text (Text'Last) /= ')'
      then
         return False;
      end if;

      while I <= Text'Last loop
         if Text (I) = '"' then
            I := I + 1;
            while I <= Text'Last loop
               if Text (I) = '"' then
                  if I < Text'Last and then Text (I + 1) = '"' then
                     I := I + 2;
                  else
                     I := I + 1;
                     exit;
                  end if;
               else
                  I := I + 1;
               end if;
            end loop;
         elsif Text (I) = Character'Val (39)
           and then I + 2 <= Text'Last
           and then Text (I + 2) = Character'Val (39)
         then
            I := I + 3;
         elsif Text (I) = '(' then
            Depth := Depth + 1;
            I := I + 1;
         elsif Text (I) = ')' then
            Depth := Depth - 1;
            if Depth = 0 and then I < Text'Last then
               return False;
            elsif Depth < 0 then
               return False;
            end if;
            I := I + 1;
         else
            I := I + 1;
         end if;
      end loop;

      return Depth = 0;
   end Is_Whole_Parenthesized_Expression;
begin
   Position := 0;

   if T = "" or else D = "" then
      return False;
   end if;

   --  discrete static expressions are expressions too; allow
   --  a whole parenthesized literal/constant/attribute expression to
   --  feed typed discrete constants and scalar attribute operands.
   --  This keeps ``Default : constant Color := (Green);`` and
   --  ``Color'Succ ((Default))`` compatible with the retained static
   --  environment without accepting comma-separated aggregate-like text.
   if Is_Whole_Parenthesized_Expression (D) then
      return Recursive_Static_Discrete_Default_Position
        (Type_Name, Trim (D (D'First + 1 .. D'Last - 1)), Position);
   end if;

   --  a static string component selection is a static
   --  Character value.  Allow it to initialize Character-compatible
   --  discrete constants and feed Character'Pos/Value-style operands
   --  without accepting arbitrary array indexing.
   if Static_Type_Is_Character (Type_Name)
     and then Static_String_Element_Position (D, Position)
   then
      return Static_Value_In_Type_Range (Type_Name, Position);
   end if;

   if Static_Discrete_Literal_Position (Type_Name, D, Position)
     or else Static_Discrete_Constant_Position (Type_Name, D, Position)
   then
      return Static_Value_In_Type_Range (Type_Name, Position);
   end if;

   --  retain discrete constants initialized from scalar
   --  bound attributes, for example ``Default : constant Color :=
   --  Color'First;`` and ``Last_Primary : constant Primary :=
   --  Primary'Last;``.  These attributes produce discrete values and
   --  must be checked against the declared constant subtype before the
   --  constant is added to the reusable static environment.
   declare
      Last_Quote : Natural := 0;
   begin
      for I in D'Range loop
         if D (I) = Character'Val (39) then
            Last_Quote := I;
         end if;
      end loop;

      if Last_Quote /= 0 and then Last_Quote < D'Last then
         declare
            Prefix_Text : constant String :=
              Trim (D (D'First .. Last_Quote - 1));
            Attr_Name : constant String :=
              Lower (Normalize_Name (Trim (D (Last_Quote + 1 .. D'Last))));
            Prefix_Norm : constant String :=
              Normalize_Static_Attribute_Spacing
                (Normalize_Name (Prefix_Text));
            Base_Suffix : constant String := "'base";
            Prefix_Base : Unbounded_String := To_Unbounded_String (Prefix_Norm);
            Has_Low  : Boolean := False;
            Low      : Integer := 0;
            Has_High : Boolean := False;
            High     : Integer := 0;
         begin
            if Prefix_Norm'Length > Base_Suffix'Length
              and then Prefix_Norm
                (Prefix_Norm'Last - Base_Suffix'Length + 1 ..
                 Prefix_Norm'Last) = Base_Suffix
            then
               Prefix_Base :=
                 To_Unbounded_String
                   (Prefix_Norm
                      (Prefix_Norm'First ..
                       Prefix_Norm'Last - Base_Suffix'Length));
            end if;

            if (To_String (Prefix_Base) = T
                or else Static_Subtypes_Compatible
                  (To_String (Prefix_Base), T))
              and then Static_Type_Range
                (To_String (Prefix_Base), Has_Low, Low, Has_High, High)
            then
               if Attr_Name = "first" then
                  if Has_Low
                    and then Low >= 0
                    and then Static_Value_In_Type_Range
                      (Type_Name, Natural (Low))
                  then
                     Position := Natural (Low);
                     return True;
                  end if;
               elsif Attr_Name = "last" then
                  if Has_High
                    and then High >= 0
                    and then Static_Value_In_Type_Range
                      (Type_Name, Natural (High))
                  then
                     Position := Natural (High);
                     return True;
                  end if;
               end if;
            end if;
         end;
      end if;
   exception
      when Constraint_Error =>
         null;
   end;

   --  retain discrete constants whose defaults are scalar
   --  attribute functions that produce a discrete value.  This closes
   --  the static-environment gap for declarations such as
   --  ``Default : constant Color := Color'Val (1);`` and chained forms
   --  such as ``Next : constant Color := Color'Succ (Default);``.
   declare
      Open_Paren : Natural := 0;
      Last_Quote : Natural := 0;

      procedure Locate_Outer_Attribute_Open is
         I : Natural := D'First;
      begin
         --  locate the attribute-call opening parenthesis
         --  with the same bounded literal awareness used by the later
         --  operand scanners.  A discrete default can contain character
         --  or string literals before a scanner has fully classified the
         --  expression; do not let those literals decide where the
         --  outer scalar attribute call starts.
         while I <= D'Last loop
            if D (I) = '"' then
               I := I + 1;
               while I <= D'Last loop
                  if D (I) = '"' then
                     if I < D'Last and then D (I + 1) = '"' then
                        I := I + 2;
                     else
                        I := I + 1;
                        exit;
                     end if;
                  else
                     I := I + 1;
                  end if;
               end loop;
            elsif D (I) = Character'Val (39)
              and then I + 2 <= D'Last
              and then D (I + 2) = Character'Val (39)
            then
               I := I + 3;
            elsif D (I) = '(' then
               Open_Paren := I;
               return;
            else
               I := I + 1;
            end if;
         end loop;
      exception
         when Constraint_Error =>
            Open_Paren := 0;
      end Locate_Outer_Attribute_Open;
   begin
      Locate_Outer_Attribute_Open;

      if Open_Paren /= 0 and then D (D'Last) = ')' then
         declare
            Head : constant String := Trim (D (D'First .. Open_Paren - 1));
            Args : constant String := Trim (D (Open_Paren + 1 .. D'Last - 1));
         begin
            for I in Head'Range loop
               if Head (I) = Character'Val (39) then
                  Last_Quote := I;
               end if;
            end loop;

            if Last_Quote /= 0 and then Last_Quote < Head'Last then
               declare
                  Prefix_Text : constant String :=
                    Trim (Head (Head'First .. Last_Quote - 1));
                  Attr_Name : constant String :=
                    Lower (Normalize_Name
                      (Trim (Head (Last_Quote + 1 .. Head'Last))));
                  Prefix_Norm : constant String :=
                    Normalize_Static_Attribute_Spacing
                      (Normalize_Name (Prefix_Text));
                  Base_Suffix : constant String := "'base";
                  Prefix_Base : Unbounded_String :=
                    To_Unbounded_String (Prefix_Norm);
                  Arg_Pos : Natural := 0;
                  Left_Pos : Natural := 0;
                  Right_Pos : Natural := 0;
                  Int_Valid : Boolean := False;
                  Int_Value : Integer := 0;
                  Nat_Valid : Boolean := False;
                  Nat_Value : Natural := 0;
                  Comma_Pos : Natural := 0;
               begin
                  if Prefix_Norm'Length > Base_Suffix'Length
                    and then Prefix_Norm
                      (Prefix_Norm'Last - Base_Suffix'Length + 1 ..
                       Prefix_Norm'Last) = Base_Suffix
                  then
                     Prefix_Base :=
                       To_Unbounded_String
                         (Prefix_Norm
                            (Prefix_Norm'First ..
                             Prefix_Norm'Last - Base_Suffix'Length));
                  end if;

                  if To_String (Prefix_Base) = T
                    or else Static_Subtypes_Compatible
                      (To_String (Prefix_Base), T)
                  then
                     if Attr_Name = "val" then
                        --  retained discrete defaults using
                        --  T'Val accept the same bounded natural static
                        --  expressions as representation arithmetic, not
                        --  only a single numeric literal.  This keeps
                        --  Color'Val (1 + 0) and named-number operands
                        --  on the reusable discrete-constant path while
                        --  preserving subtype range validation below.
                        Parse_Static_Natural (Args, Nat_Valid, Nat_Value);
                        if Nat_Valid
                          and then Static_Value_In_Type_Range
                            (Type_Name, Nat_Value)
                        then
                           Position := Nat_Value;
                           return True;
                        end if;

                        Parse_Static_Integer (Args, Int_Valid, Int_Value);
                        if Int_Valid
                          and then Int_Value >= 0
                          and then Static_Value_In_Type_Range
                            (Type_Name, Natural (Int_Value))
                        then
                           Position := Natural (Int_Value);
                           return True;
                        end if;
                     elsif Attr_Name = "value" then
                        if Static_Discrete_Value_String_Position
                             (Type_Name, Args, Arg_Pos)
                          and then Static_Value_In_Type_Range
                            (Type_Name, Arg_Pos)
                        then
                           Position := Arg_Pos;
                           return True;
                        end if;
                     elsif Attr_Name = "succ" then
                        if Recursive_Static_Discrete_Default_Position
                             (Type_Name, Args, Arg_Pos)
                          and then Arg_Pos < Natural'Last
                          and then Static_Value_In_Type_Range
                            (Type_Name, Arg_Pos + 1)
                        then
                           Position := Arg_Pos + 1;
                           return True;
                        end if;
                     elsif Attr_Name = "pred" then
                        if Recursive_Static_Discrete_Default_Position
                             (Type_Name, Args, Arg_Pos)
                          and then Arg_Pos > 0
                          and then Static_Value_In_Type_Range
                            (Type_Name, Arg_Pos - 1)
                        then
                           Position := Arg_Pos - 1;
                           return True;
                        end if;
                     elsif Attr_Name = "min" or else Attr_Name = "max" then
                        --  Min/Max have two discrete
                        --  operands, but either operand can itself be a
                        --  nested static attribute expression.  Select
                        --  the separating comma only at the top level so
                        --  forms such as ``Color'Max (Color'Min
                        --  (Red, Green), Blue)`` are retained instead
                        --  of being split at the inner comma.
                        declare
                           Depth : Integer := 0;
                           I     : Natural := Args'First;
                        begin
                           while I <= Args'Last loop
                              if Args (I) = '"' then
                                 I := I + 1;
                                 while I <= Args'Last loop
                                    if Args (I) = '"' then
                                       if I < Args'Last
                                         and then Args (I + 1) = '"'
                                       then
                                          I := I + 2;
                                       else
                                          I := I + 1;
                                          exit;
                                       end if;
                                    else
                                       I := I + 1;
                                    end if;
                                 end loop;
                              elsif Args (I) = Character'Val (39)
                                and then I + 2 <= Args'Last
                                and then Args (I + 2) = Character'Val (39)
                              then
                                 I := I + 3;
                              elsif Args (I) = '(' then
                                 Depth := Depth + 1;
                                 I := I + 1;
                              elsif Args (I) = ')' then
                                 if Depth > 0 then
                                    Depth := Depth - 1;
                                 end if;
                                 I := I + 1;
                              elsif Args (I) = ',' and then Depth = 0 then
                                 Comma_Pos := I;
                                 exit;
                              else
                                 I := I + 1;
                              end if;
                           end loop;
                        end;

                        if Comma_Pos /= 0
                          and then Recursive_Static_Discrete_Default_Position
                            (Type_Name,
                             Trim (Args (Args'First .. Comma_Pos - 1)),
                             Left_Pos)
                          and then Recursive_Static_Discrete_Default_Position
                            (Type_Name,
                             Trim (Args (Comma_Pos + 1 .. Args'Last)),
                             Right_Pos)
                        then
                           if Attr_Name = "min" then
                              if Left_Pos <= Right_Pos then
                                 Position := Left_Pos;
                              else
                                 Position := Right_Pos;
                              end if;
                           else
                              if Left_Pos >= Right_Pos then
                                 Position := Left_Pos;
                              else
                                 Position := Right_Pos;
                              end if;
                           end if;

                           return Static_Value_In_Type_Range
                                    (Type_Name, Position);
                        end if;
                     end if;
                  end if;
               end;
            end if;
         end;
      end if;
   exception
      when Constraint_Error =>
         null;
   end;

   --  retain discrete constants whose defaults are qualified
   --  static expressions, for example ``Default : constant Color :=
   --  Color'(Green);``.  Earlier passes handled qualified numeric
   --  expressions, but a qualified enumeration/Boolean/Character
   --  literal default was not entered into the reusable discrete static
   --  environment and therefore could not feed later ``T'Pos`` or
   --  ``T'Succ`` representation expressions.
   --
   --  accept the same Ada separator whitespace between the
   --  qualification apostrophe and opening parenthesis that the String
   --  static evaluator already accepts.  This keeps
   --  ``Character' ('A')`` and ``Color' (Green)`` on the retained
   --  qualified-discrete path instead of requiring compact spelling.
   for I in D'Range loop
      if D (I) = Character'Val (39) then
         declare
            Candidate_Open : Natural := I + 1;
         begin
            while Candidate_Open <= D'Last
              and then Is_Static_Space (D (Candidate_Open))
            loop
               Candidate_Open := Candidate_Open + 1;
            end loop;

            if Candidate_Open <= D'Last
              and then D (Candidate_Open) = '('
            then
               Quote_Index := I;
               Qualified_Open_Pos := Candidate_Open;
               exit;
            end if;
         end;
      end if;
   end loop;

   if Quote_Index /= 0
     and then Qualified_Open_Pos /= 0
     and then D (D'Last) = ')'
   then
      declare
         Prefix_Text : constant String :=
           Trim (D (D'First .. Quote_Index - 1));
         Inner_Text  : constant String :=
           Trim (D (Qualified_Open_Pos + 1 .. D'Last - 1));
         Prefix_Norm : constant String :=
           Normalize_Static_Attribute_Spacing
             (Normalize_Name (Prefix_Text));
         Base_Suffix : constant String := "'base";
         Prefix_Base : Unbounded_String := To_Unbounded_String (Prefix_Norm);
         Operand_Type : Unbounded_String := To_Unbounded_String (Prefix_Norm);
         Has_Base_Qualifier : Boolean := False;
      begin
         if Prefix_Norm'Length > Base_Suffix'Length
           and then Prefix_Norm
             (Prefix_Norm'Last - Base_Suffix'Length + 1 .. Prefix_Norm'Last)
               = Base_Suffix
         then
            Has_Base_Qualifier := True;
            Prefix_Base :=
              To_Unbounded_String
                (Prefix_Norm
                   (Prefix_Norm'First ..
                    Prefix_Norm'Last - Base_Suffix'Length));
         end if;

         if Has_Base_Qualifier then
            Operand_Type :=
              To_Unbounded_String
                (Static_Subtype_Root (To_String (Prefix_Base)));
         else
            Operand_Type := Prefix_Base;
         end if;

         --  a qualified discrete expression may use a
         --  compatible subtype mark, not only the declared constant
         --  type itself.  Evaluate the operand against the qualifier
         --  subtype first so its static range is enforced, then check
         --  the resulting value against the declared object subtype.
         --
         --  if the qualifier explicitly names 'Base, widen
         --  the operand check to the scalar root.  ``Primary'Base'(Blue)``
         --  must be accepted as a Color-compatible operand even though
         --  ``Blue`` is outside the constrained subtype Primary; the
         --  declared object subtype check below still rejects it when
         --  the object itself is constrained to Primary.
         if (To_String (Prefix_Base) = T
             or else Static_Subtypes_Compatible
               (To_String (Prefix_Base), T))
           and then Recursive_Static_Discrete_Default_Position
                      (To_String (Operand_Type), Inner_Text, Position)
           and then Static_Value_In_Type_Range (Type_Name, Position)
         then
            return True;
         end if;
      end;
   end if;

   return False;
exception
   when Constraint_Error =>
      return False;
end Static_Discrete_Default_Position;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Discrete_Evaluation;
