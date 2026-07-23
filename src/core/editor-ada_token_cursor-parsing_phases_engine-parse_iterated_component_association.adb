with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Contracts;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Aggregate_Parsing;
with Editor.Ada_Token_Cursor.Context_Clause_Parsing;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Pragma_Parsing;
with Editor.Ada_Token_Cursor.Primary_Parsing;
with Editor.Ada_Token_Cursor.Entry_Parsing;
with Editor.Ada_Token_Cursor.Aspect_Parsing;
with Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing;
with Editor.Ada_Token_Cursor.Generic_Formal_Parsing;
with Editor.Ada_Token_Cursor.Renaming_Parsing;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Constraint_Parsing;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor.Representation_Parsing;
with Editor.Ada_Token_Cursor.Tokenization;

use Editor.Ada_Token_Cursor.Aspect_Parsing;

separate (Editor.Ada_Token_Cursor.Parsing_Phases_Engine)
   procedure Parse_Iterated_Component_Association
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
   begin
      --  Ada aggregate iterated component associations use a leading ``for``
      --  but are not quantified expressions: they have no ``all``/``some``
      --  quantifier and their domain belongs to an aggregate association.
      --  Keep a distinct production so aggregate grammar does not regress into
      --  the quantified-expression recovery path.
      Add_Production
        (Result, Production_Iterated_Component_Association, Tok,
         "iterated component association");

      if Current_Lower (Position) = "for" then
         Advance (Position);
      end if;

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Defining_Name, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
      end if;

      if Current_Lower (Position) = "in" then
         Add_Production
           (Result, Production_Loop_Parameter_Specification, Tok,
            "aggregate loop parameter specification");
         Advance (Position);
      elsif Current_Lower (Position) = "of" then
         Add_Production
           (Result, Production_Iterator_Specification, Tok,
            "aggregate iterator specification");
         Advance (Position);
      end if;

      if Current_Lower (Position) = "reverse" then
         Advance (Position);
      end if;

      --  Keep the iteration domain structural instead of skipping directly to
      --  the association arrow.  This preserves discrete ranges, container
      --  names, subtype ranges, and optional iterator filters for outline and
      --  semantic-colouring consumers while retaining bounded recovery.
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= "=>"
        and then Current_Lower (Position) /= "when"
      then
         declare
            Domain_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Domain, Domain_Tok,
               "iterated component association domain");
            Parse_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component discrete range");
               Parse_Expression (Position, Result);
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component subtype range");
               Advance (Position);
               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Box_Expression, Current (Position),
                     "iterated component box range");
                  Advance (Position);
               else
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Parse_Expression (Position, Result);
                  end if;
               end if;
            end if;
         end;
      elsif Current_Lower (Position) = "when"
        or else To_String (Current (Position).Text) = "=>"
      then
         Add_Production
           (Result, Production_Iterated_Component_Missing_Domain_Recovery_Boundary,
            Current (Position),
            "missing domain in iterated component association");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected iterated component association domain");
      end if;

      if Match_Keyword (Position, "when") then
         Add_Production
           (Result, Production_Iterated_Component_Iterator_Filter,
            Current (Position), "iterated component iterator filter");
         if At_Iterator_Filter_Condition_Boundary (Position) then
            Add_Production
              (Result,
               Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary,
               Current (Position),
               "missing iterated component iterator filter condition");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected iterated component iterator filter condition");
         else
            Parse_Expression (Position, Result);
         end if;
      end if;

      if To_String (Current (Position).Text) = "=>" then
         declare
            Arrow_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Association_Arrow,
               Arrow_Tok, "iterated component association arrow");
            Advance (Position);
            if At_Iterated_Component_Expression_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Iterated_Component_Missing_Expression_Recovery_Boundary,
                  Current (Position),
                  "missing iterated component expression recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected iterated component expression");
            else
               Add_Production
                 (Result, Production_Iterated_Component_Expression,
                  Current (Position), "iterated component expression");
               Parse_Expression (Position, Result);
            end if;
         end;
      else
         Add_Production
           (Result, Production_Iterated_Component_Missing_Arrow_Recovery_Boundary,
            Current (Position),
            "missing => in iterated component association");
      end if;
   end Parse_Iterated_Component_Association;
