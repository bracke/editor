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
   procedure Parse_Discriminant_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      Add_Production (Result, Production_Discriminant_Part, Tok, "discriminant part");
      Add_Production
        (Result, Production_Discriminant_Part_Open_Delimiter, Tok,
         "discriminant part open delimiter");
      Advance (Position);

      if To_String (Current (Position).Text) = "<>" then
         --  Ada unknown discriminant parts use the compact ``(<>)``
         --  grammar.  They are not discriminant specifications and should
         --  not be sent through profile-item recovery, where the box token
         --  would otherwise be treated as a malformed defining name.
         Add_Production
           (Result, Production_Unknown_Discriminant_Part, Current (Position),
            "unknown discriminant part");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Known_Discriminant_Part, Current (Position),
            "known discriminant part");
         while not At_End (Position)
           and then To_String (Current (Position).Text) /= ")"
         loop
            Parse_Discriminant_Specification (Position, Result);
            exit when To_String (Current (Position).Text) = ")";
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Discriminant_Specification_Separator,
                  Current (Position), "discriminant specification separator");
               Advance (Position);
            else
               exit;
            end if;
         end loop;
      end if;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Discriminant_Part_Close_Delimiter, Current (Position),
            "discriminant part close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Discriminant_Part_Missing_Close_Recovery_Boundary,
            Tok, "discriminant part missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in discriminant part");
      end if;
   end Parse_Discriminant_Part;
