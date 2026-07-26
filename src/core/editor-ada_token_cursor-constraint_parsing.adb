with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Constraint_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;
   use Editor.Ada_Token_Cursor.Range_Structure_Helpers;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Range_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Range_Reserved_Boundary;

      function At_Range_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Range_Reserved_Boundary;
      end At_Range_Boundary;
   begin
      Add_Production (Result, Production_Range_Constraint, Tok, "range constraint");
      if Current_Lower (Position) = "range" then
         Advance (Position);
      end if;

      if At_Range_Boundary then
         Add_Production
           (Result, Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary,
            Tok, "missing range lower bound");
         if At_Range_Reserved_Boundary then
            Add_Production
              (Result, Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "range lower bound reserved-boundary recovery boundary");
         end if;
         Add_Production
           (Result, Production_Constraint_Recovery_Boundary, Tok,
            "missing range lower bound");
         return;
      end if;

      Add_Production
        (Result, Production_Range_Lower_Bound, Current (Position),
         "range lower bound");
      Parse_Expression (Position, Result);

      if not At_End (Position)
        and then To_String (Current (Position).Text) = ".."
      then
         Add_Production
           (Result, Production_Range_Constraint_Range_Separator,
            Current (Position), "range constraint separator");
         Advance (Position);
         if At_Range_Boundary then
            Add_Production
              (Result, Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary,
               Tok, "missing range upper bound");
            if At_Range_Reserved_Boundary then
               Add_Production
                 (Result, Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "range upper bound reserved-boundary recovery boundary");
            end if;
            Add_Production
              (Result, Production_Constraint_Recovery_Boundary, Tok,
               "missing range upper bound");
         else
            Add_Production
              (Result, Production_Range_Upper_Bound, Current (Position),
               "range upper bound");
            Parse_Expression (Position, Result);
         end if;
      end if;
   end Parse_Range_Constraint;

   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Subtype indications may carry decimal/floating point digits
      --  constraints, optionally followed by a range constraint.  Keep this
      --  grammar distinct from floating-point type definitions so subtype
      --  declarations such as ``subtype Short is Float digits 6 range ...``
      --  do not leave ``digits`` behind for statement recovery.
      Add_Production (Result, Production_Digits_Constraint, Tok, "digits constraint");
      if Current_Lower (Position) = "digits" then
         Advance (Position);
      end if;

      if At_Digits_Or_Delta_Expression_Boundary (Position) then
         Add_Production
           (Result, Production_Digits_Constraint_Missing_Expression_Recovery_Boundary,
            Tok, "missing digits constraint expression");
         if At_Digits_Or_Delta_Reserved_Boundary (Position) then
            Add_Production
              (Result, Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "digits constraint reserved-boundary recovery boundary");
         end if;
         return;
      end if;

      Add_Production
        (Result, Production_Digits_Constraint_Expression, Current (Position),
         "digits constraint expression");
      Parse_Expression (Position, Result);
      if Current_Lower (Position) = "range" then
         Parse_Range_Constraint (Position, Result);
      end if;
   end Parse_Digits_Constraint;

   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Fixed-point subtype indications may use ``delta`` constraints and
      --  decimal fixed-point subtypes may chain ``digits`` before an optional
      --  range.  This is syntactic retention only; scale/model-number legality
      --  remains outside the editor parser.
      Add_Production (Result, Production_Delta_Constraint, Tok, "delta constraint");
      if Current_Lower (Position) = "delta" then
         Advance (Position);
      end if;

      if At_Digits_Or_Delta_Expression_Boundary (Position) then
         Add_Production
           (Result, Production_Delta_Constraint_Missing_Expression_Recovery_Boundary,
            Tok, "missing delta constraint expression");
         if At_Digits_Or_Delta_Reserved_Boundary (Position) then
            Add_Production
              (Result, Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "delta constraint reserved-boundary recovery boundary");
         end if;
         return;
      end if;

      Add_Production
        (Result, Production_Delta_Constraint_Expression, Current (Position),
         "delta constraint expression");
      Parse_Expression (Position, Result);
      if Current_Lower (Position) = "digits" then
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "range" then
         Parse_Range_Constraint (Position, Result);
      end if;
   end Parse_Delta_Constraint;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
      then
         Add_Production (Result, Production_Null_Exclusion, Tok, "not null");
         Add_Production
           (Result, Production_Subtype_Null_Exclusion, Tok,
            "subtype null exclusion");
         Advance (Position);
         Advance (Position);
      end if;
   end Parse_Null_Exclusion;

end Editor.Ada_Token_Cursor.Constraint_Parsing;
