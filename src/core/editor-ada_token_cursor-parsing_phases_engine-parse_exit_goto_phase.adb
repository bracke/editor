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
procedure Parse_Exit_Goto_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
   L0  : constant String := Current_Lower (Position);
begin
   if L0 = "exit" then
      Add_Production (Result, Production_Exit_Statement, Tok, "exit statement");
      Advance (Position);
      if not At_End (Position)
        and then Current_Lower (Position) /= "when"
        and then To_String (Current (Position).Text) /= ";"
        and then Is_Statement_Control_Boundary (Position)
      then
         Add_Production
           (Result, Production_Exit_Target_Reserved_Boundary_Recovery_Boundary,
            Tok, "exit target reserved-boundary recovery boundary");
         Add_Production
           (Result, Production_Exit_Recovery_Boundary, Tok,
            "exit statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "reserved boundary where exit loop name was expected");
      elsif not At_End (Position)
        and then Current_Lower (Position) /= "when"
        and then To_String (Current (Position).Text) /= ";"
      then
         Add_Production
           (Result, Production_Exit_Target, Current (Position),
            "exit target");
         Add_Production
           (Result, Production_Exit_Loop_Name, Current (Position),
            "exit loop name");
         Parse_Primary (Position, Result);
      end if;
      if Current_Lower (Position) = "when" then
         Add_Production
           (Result, Production_Exit_When_Keyword, Current (Position),
            "exit when keyword");
         Advance (Position);
         if At_End (Position)
           or else To_String (Current (Position).Text) = ";"
           or else Is_Statement_Control_Boundary (Position)
         then
            Add_Production
              (Result, Production_Exit_When_Missing_Condition_Recovery_Boundary, Tok,
               "exit when missing condition recovery boundary");
            Add_Production
              (Result, Production_Exit_Recovery_Boundary, Tok,
               "exit statement recovery boundary");
            if not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
            then
               Add_Production
                 (Result,
                  Production_Exit_When_Reserved_Boundary_Recovery_Boundary,
                  Tok, "exit when reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "reserved boundary where exit when condition was expected");
            end if;
         else
            Add_Production
              (Result, Production_Exit_When_Condition, Current (Position),
               "exit when condition");
            Parse_Expression (Position, Result);
         end if;
      end if;
      if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Exit_Terminator, Current (Position),
            "exit statement terminator");
      elsif At_End (Position)
        or else Is_Statement_Tail_Boundary (Position)
      then
         Add_Production
           (Result, Production_Exit_Missing_Terminator_Recovery_Boundary,
            Tok, "exit missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected semicolon after exit statement");
      end if;
      Skip_Balanced_To_Semicolon (Position);
   elsif L0 = "goto" then
      Add_Production (Result, Production_Goto_Statement, Tok, "goto statement");
      Advance (Position);
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ";"
        and then Is_Statement_Control_Boundary (Position)
      then
         Add_Production
           (Result, Production_Goto_Missing_Target_Recovery_Boundary, Tok,
            "goto missing target recovery boundary");
         Add_Production
           (Result, Production_Goto_Target_Reserved_Boundary_Recovery_Boundary,
            Tok, "goto target reserved-boundary recovery boundary");
         Add_Production
           (Result, Production_Goto_Recovery_Boundary, Tok,
            "goto statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected label name in goto statement");
      elsif not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
         Add_Production
           (Result, Production_Goto_Target, Current (Position),
            "goto target");
         Add_Production
           (Result, Production_Goto_Label_Name, Current (Position),
            "goto label name");
         if Current (Position).Kind = Token_Identifier then
            Advance (Position);
            if not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
            then
               --  Ada goto targets are label identifiers, not general
               --  names.  Keep a bounded recovery marker if the source
               --  continues as if a selected/indexed name were valid,
               --  while still synchronizing at the statement terminator.
               Add_Production
                 (Result, Production_Goto_Label_Recovery_Boundary,
                  Current (Position),
                  "goto label-name recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_Goto_Label_Recovery_Boundary,
               Current (Position),
               "goto label-name recovery boundary");
         end if;
      else
         Add_Production
           (Result, Production_Goto_Missing_Target_Recovery_Boundary, Tok,
            "goto missing target recovery boundary");
         Add_Production
           (Result, Production_Goto_Recovery_Boundary, Tok,
            "goto statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected label name in goto statement");
      end if;
      if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Goto_Terminator, Current (Position),
            "goto statement terminator");
      elsif At_End (Position)
        or else Is_Statement_Tail_Boundary (Position)
      then
         Add_Production
           (Result, Production_Goto_Missing_Terminator_Recovery_Boundary,
            Tok, "goto missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected semicolon after goto statement");
      end if;
      Skip_Balanced_To_Semicolon (Position);
   end if;
end Parse_Exit_Goto_Phase;
