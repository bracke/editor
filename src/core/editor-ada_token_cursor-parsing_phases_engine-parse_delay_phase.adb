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
procedure Parse_Delay_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
begin
   Add_Production (Result, Production_Delay_Statement, Tok, "delay statement");
   if Is_In_Select_Context (Position) then
      Add_Production
        (Result, Production_Select_Delay_Alternative, Tok,
         "select delay alternative");
      Add_Production
        (Result, Production_Timed_Entry_Call_Alternative, Tok,
         "timed entry call delay alternative");
      if Select_Has_Then_Abort (Position) then
         Add_Production
           (Result, Production_Asynchronous_Select_Delay_Trigger, Tok,
            "asynchronous select delay trigger");
      end if;
   end if;
   Advance (Position);
   if Current_Lower (Position) = "until" then
      if Is_In_Select_Context (Position) then
         Add_Production
           (Result, Production_Select_Delay_Until_Alternative, Tok,
            "select delay until alternative");
      end if;
      Add_Production
        (Result, Production_Delay_Mode_Keyword, Current (Position),
         "delay mode keyword");
      Add_Production
        (Result, Production_Delay_Until_Keyword, Current (Position),
         "delay until keyword");
      Add_Production
        (Result, Production_Delay_Until_Statement, Tok,
         "delay until statement");
      Advance (Position);
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ";"
        and then Current_Lower (Position) /= "end"
        and then Current_Lower (Position) /= "or"
        and then Current_Lower (Position) /= "else"
        and then Current_Lower (Position) /= "exception"
        and then Current_Lower (Position) /= "then"
        and then Current_Lower (Position) /= "when"
        and then Current_Lower (Position) /= "terminate"
        and then Current_Lower (Position) /= "abort"
      then
         Add_Production
           (Result, Production_Delay_Until_Expression,
            Current (Position), "delay until expression");
         if Lookahead_Lower (Position, 1) = "." then
            Add_Production
              (Result, Production_Delay_Selected_Time_Expression,
               Current (Position), "delay selected time expression");
         elsif Lookahead_Lower (Position, 1) = "'" then
            Add_Production
              (Result, Production_Delay_Qualified_Time_Expression,
               Current (Position), "delay qualified time expression");
         end if;
         Parse_Expression (Position, Result);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Delay_Statement_Terminator,
               Current (Position), "delay statement terminator");
         elsif At_End (Position)
           or else Is_Statement_Tail_Boundary (Position)
         then
            Add_Production
              (Result, Production_Delay_Missing_Terminator_Recovery_Boundary,
               Tok, "delay missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after delay statement");
         end if;
      else
         Add_Production
           (Result, Production_Delay_Until_Missing_Expression_Recovery_Boundary, Tok,
            "delay until missing expression recovery boundary");
         if not At_End (Position)
           and then Is_Statement_Delay_Reserved_Boundary (Position)
         then
            Add_Production
              (Result, Production_Delay_Reserved_Boundary_Recovery_Boundary, Tok,
               "delay expression reserved boundary recovery boundary");
         end if;
         Add_Production
           (Result, Production_Delay_Recovery_Boundary, Tok,
            "delay statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected expression after delay until");
      end if;
   else
      if Is_In_Select_Context (Position) then
         Add_Production
           (Result, Production_Select_Delay_Relative_Alternative, Tok,
            "select relative delay alternative");
      end if;
      Add_Production
        (Result, Production_Delay_Relative_Statement, Tok,
         "delay relative statement");
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ";"
        and then not Is_Statement_Transfer_Boundary (Position)
      then
         Add_Production
           (Result, Production_Delay_Relative_Expression,
            Current (Position), "delay relative expression");
         if Lookahead_Lower (Position, 1) = "." then
            Add_Production
              (Result, Production_Delay_Selected_Time_Expression,
               Current (Position), "delay selected time expression");
         elsif Lookahead_Lower (Position, 1) = "'" then
            Add_Production
              (Result, Production_Delay_Qualified_Time_Expression,
               Current (Position), "delay qualified time expression");
         end if;
         Parse_Expression (Position, Result);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Delay_Statement_Terminator,
               Current (Position), "delay statement terminator");
         elsif At_End (Position)
           or else Is_Statement_Tail_Boundary (Position)
         then
            Add_Production
              (Result, Production_Delay_Missing_Terminator_Recovery_Boundary,
               Tok, "delay missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after delay statement");
         end if;
      else
         Add_Production
           (Result, Production_Delay_Relative_Missing_Expression_Recovery_Boundary, Tok,
            "delay relative missing expression recovery boundary");
         if not At_End (Position)
           and then Is_Statement_Delay_Reserved_Boundary (Position)
         then
            Add_Production
              (Result, Production_Delay_Reserved_Boundary_Recovery_Boundary, Tok,
               "delay expression reserved boundary recovery boundary");
         end if;
         Add_Production
           (Result, Production_Delay_Recovery_Boundary, Tok,
            "delay statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected expression after delay");
      end if;
   end if;
   Skip_Balanced_To_Semicolon (Position);
end Parse_Delay_Phase;
