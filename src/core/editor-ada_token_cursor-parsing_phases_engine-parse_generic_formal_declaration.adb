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
   procedure Parse_Generic_Formal_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
      L2  : constant String := Lookahead_Lower (Position, 2);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production (Result, Production_Generic_Formal_Declaration, Tok, "generic formal declaration");

      if L0 = "with" and then (L1 = "procedure" or else L1 = "function") then
         Add_Production (Result, Production_Formal_Subprogram_Declaration, Tok, "formal subprogram");
         Advance (Position);
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Subprogram_Defining_Designator,
            Current (Position), "formal subprogram defining designator");
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Formal_Subprogram_Parameter_Profile,
               Current (Position), "formal subprogram parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
         if Current_Lower (Position) = "return" then
            Advance (Position);
            Add_Production
              (Result, Production_Formal_Subprogram_Result_Subtype,
               Current (Position), "formal subprogram result subtype");
            Parse_Subtype_Indication (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Add_Production (Result, Production_Subprogram_Default, Current (Position), "formal subprogram default");
            Advance (Position);
            if To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Box,
                  Current (Position), "formal subprogram box default");
               Advance (Position);
            elsif Current_Lower (Position) = "null" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Null,
                  Current (Position), "formal subprogram null default");
               Advance (Position);
            elsif Current_Lower (Position) = "abstract" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Abstract,
                  Current (Position), "formal subprogram abstract default");
               Advance (Position);
               if not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
                 and then Current_Lower (Position) /= "with"
               then
                  Add_Production
                    (Result, Production_Formal_Subprogram_Default_Abstract_Name,
                     Current (Position), "formal subprogram abstract default name");
                  Parse_Expression (Position, Result);
               end if;
            elsif At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else Current_Lower (Position) = "with"
            then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary,
                  Current (Position), "formal subprogram missing default target");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected formal subprogram default target after is");
            elsif not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
            then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Name,
                  Current (Position), "formal subprogram name default");
               Parse_Expression (Position, Result);
            end if;
         end if;
         Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);

      elsif L0 = "with" and then L1 = "package" then
         Add_Production (Result, Production_Formal_Package_Declaration, Tok, "formal package");
         declare
            Had_Generic_Name : Boolean := False;
            Generic_Name_Tok : Token_Info := Tok;
         begin
         Advance (Position);
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Package_Defining_Name,
            Current (Position), "formal package defining name");
         Parse_Defining_Name (Position, Result);

         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Formal_Package_Missing_Is_Recovery_Boundary,
               Current (Position),
               "formal package missing is recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in formal package declaration");
         end if;

         if not Match_Keyword (Position, "new") then
            Add_Production
              (Result, Production_Formal_Package_Missing_New_Recovery_Boundary,
               Current (Position),
               "formal package missing new recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected new in formal package declaration");
         end if;

         if not At_End (Position)
           and then To_String (Current (Position).Text) /= "("
           and then To_String (Current (Position).Text) /= ";"
           and then Current_Lower (Position) /= "with"
           and then Current_Lower (Position) /= "is"
           and then Current_Lower (Position) /= "new"
         then
            --  A formal package declaration names the generic package being
            --  formalized before its formal_package_actual_part:
            --     with package P is new Ada.Containers.Vectors (<>);
            --  Keep this generic_package_name distinct from ordinary generic
            --  actual expressions, preserving selected names while leaving the
            --  following parenthesized actual part for the actual-part parser.
            Generic_Name_Tok := Current (Position);
            Had_Generic_Name := True;
            Add_Production
              (Result, Production_Formal_Package_Generic_Name,
               Current (Position), To_String (Current (Position).Text));
            Parse_Subtype_Mark (Position, Result);
         else
            Add_Production
              (Result, Production_Formal_Package_Missing_Generic_Name,
               Current (Position),
               "missing formal package generic name after is new");
            Add_Production
              (Result, Production_Formal_Package_Missing_Generic_Recovery_Boundary,
               Current (Position),
               "formal package missing generic recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected generic package name in formal package declaration");
         end if;

         if To_String (Current (Position).Text) = "(" then
            Parse_Formal_Package_Actual_Part (Position, Result);
         elsif Had_Generic_Name
           and then (To_String (Current (Position).Text) = ";"
                     or else Current_Lower (Position) = "with")
         then
            --  Ada formal_package_actual_part may be omitted after the
            --  generic_package_name.  Retain that defaulted form explicitly
            --  instead of leaving callers to infer it from the absence of a
            --  parenthesized actual list.
            Add_Production
              (Result, Production_Formal_Package_Defaulted_Actual_Part,
               Generic_Name_Tok, "defaulted formal package actual part");
         end if;
         Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);
         end;


      elsif L0 = "type" then
         Add_Production (Result, Production_Formal_Type_Declaration, Tok, "formal type");
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Type_Defining_Name,
            Current (Position), "formal type defining name");
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Formal_Type_Discriminant_Part,
               Current (Position), "formal type discriminant part");
            Parse_Discriminant_Part (Position, Result);
         end if;
         if Match_Keyword (Position, "is") then
            if Current_Lower (Position) = "tagged"
              and then (Lookahead_Lower (Position, 1) = ";"
                        or else Lookahead_Lower (Position, 1) = "with")
            then
               --  Ada formal incomplete type declarations may use the
               --  optional "is tagged" suffix without a full formal type
               --  definition.  Preserve it as an incomplete formal type, not
               --  as a malformed private/interface definition.
               Add_Production
                 (Result, Production_Formal_Incomplete_Type_Declaration,
                  Tok, "formal incomplete type");
               Add_Production
                 (Result, Production_Formal_Incomplete_Tagged_Type_Definition,
                  Current (Position), "formal incomplete tagged type");
               Add_Production
                 (Result, Production_Formal_Type_Modifier,
                  Current (Position), "tagged");
               Add_Production
                 (Result, Production_Type_Modifier,
                  Current (Position), "tagged");
               Advance (Position);
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            elsif To_String (Current (Position).Text) = ";"
              or else Current_Lower (Position) = "with"
            then
               --  "type T is;" is malformed, but retaining a
               --  formal-type-specific recovery boundary lets Outline and
               --  semantic colouring avoid consuming the next formal item.
               Add_Production
                 (Result, Production_Formal_Incomplete_Type_Recovery_Boundary,
                  Current (Position),
                  "formal type missing definition after is");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected formal type definition after is");
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            else
               --  Keep every Ada generic formal type category structural all
               --  the way down.  Earlier passes recognized the family node but
               --  then skipped scalar boxes, derived interface lists, formal
               --  array domains/components, and modified private/interface
               --  forms to the semicolon.  That was enough for outline rows
               --  but not for semantic colouring/navigation over generic
               --  contracts.
               Parse_Formal_Type_Definition_Deep (Position, Result);
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            end if;
         elsif To_String (Current (Position).Text) = ";"
           or else Current_Lower (Position) = "with"
         then
            --  Formal incomplete type declaration: "type T;" or
            --  "type T (<>) with ...;".  This is a distinct Ada generic
            --  formal type family and must not be reported as a missing "is"
            --  recovery case.
            Add_Production
              (Result, Production_Formal_Incomplete_Type_Declaration,
               Tok, "formal incomplete type");
            Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
              (Position, Result);
         else
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in formal type declaration");
            Skip_Balanced_To_Semicolon (Position);
         end if;

      elsif L0 = "with" then
         Parse_Generic_Formal_Object_Declaration
           (Position, Result, Leading_With => True);

      elsif Current (Position).Kind = Token_Identifier
        and then Has_Token_Before_Semicolon (Position, ":")
      then
         Parse_Generic_Formal_Object_Declaration
           (Position, Result, Leading_With => False);

      else
         Add_Production (Result, Production_Recovery_Point, Tok, "unrecognized generic formal declaration");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Generic_Formal_Declaration;
