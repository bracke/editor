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
procedure Parse_Raise_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
   L0  : constant String := Current_Lower (Position);
begin
   Add_Production (Result, Production_Raise_Statement, Tok, "raise statement");
   Advance (Position);

   --  Ada raise statements have two shapes:
   --     raise;
   --     raise Exception_Name [with String_Expression];
   --  Earlier grammar always tried to parse an expression after
   --  ``raise``, so a bare re-raise treated the semicolon as an
   --  expression primary and the optional ``with`` message was lost to
   --  opaque semicolon recovery.  Keep both pieces structural without
   --  claiming exception legality or handler-placement validation.
   if At_End (Position) or else To_String (Current (Position).Text) = ";" then
      Add_Production
        (Result, Production_Reraise_Statement, Tok,
         "bare raise statement");
   else
      if Current_Lower (Position) = "with" then
         --  ``raise with Message`` is not a legal Ada raise-statement
         --  shape, but it is a common in-progress edit after typing
         --  the optional message introducer before the exception name.
         --  Keep the message keyword and payload recoverable without
         --  mis-tagging ``with`` as an exception name.
         Add_Production
           (Result,
            Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary,
            Tok,
            "raise statement missing exception name recovery boundary");
         Add_Production
           (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
            "raise statement missing exception name");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected exception name before raise with message");
      elsif Is_Statement_Control_Boundary (Position)
      then
         --  Reserved statement-sequence boundaries after ``raise`` are
         --  not exception names.  Keep this raise-specific so malformed
         --  edits such as ``raise else;`` do not seed a bogus exception
         --  target or semantic-colouring binding from the next construct.
         Add_Production
           (Result,
            Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary,
            Tok,
            "raise statement missing exception name recovery boundary");
         Add_Production
           (Result, Production_Raise_Target_Reserved_Boundary_Recovery_Boundary,
            Tok, "raise target reserved boundary recovery boundary");
         Add_Production
           (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
            "raise statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected exception name in raise statement");
      else
         Add_Production
           (Result, Production_Raise_Statement_Target, Current (Position),
            "raise statement target");
         Add_Production
           (Result, Production_Raise_Exception_Name, Current (Position),
            "raise statement exception name");
         Mark_Raise_Exception_Target_Shape
           (Position, Result, Current (Position),
            Production_Raise_Selected_Exception_Name,
            Production_Raise_Statement_Recovery_Boundary,
            "raise statement exception name");
         Parse_Expression (Position, Result);
      end if;
      if Current_Lower (Position) = "with" then
         Add_Production
           (Result, Production_Raise_With_Message_Keyword, Current (Position),
            "raise with keyword");
         Advance (Position);
         if At_End (Position)
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Raise_Message_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result, Production_Raise_Statement_Message_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "raise statement missing message expression");
         elsif Is_Statement_Transfer_Boundary (Position)
         then
            --  Reserved statement-sequence boundaries after ``raise ...
            --  with`` are not message expressions.  Keep the recovery
            --  message-specific so semantic colouring and outline data
            --  do not treat the next construct keyword as a string
            --  expression while still preserving the broader raise
            --  recovery metadata.
            Add_Production
              (Result, Production_Raise_Message_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result,
               Production_Raise_Message_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "raise message reserved boundary recovery boundary");
            Add_Production
              (Result, Production_Raise_Statement_Message_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
               "raise statement missing message expression");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "raise statement missing message expression");
         else
            Add_Production
              (Result, Production_Raise_With_Message, Current (Position),
               "raise with message");
            Add_Production
              (Result, Production_Raise_Message_Expression, Current (Position),
               "raise message expression");
            Parse_Expression (Position, Result);
         end if;
      end if;
   end if;
   if not At_End (Position)
     and then To_String (Current (Position).Text) = ";"
   then
      Add_Production
        (Result, Production_Raise_Terminator, Current (Position),
         "raise statement terminator");
   elsif At_End (Position)
     or else Is_Statement_Tail_Boundary (Position)
   then
      Add_Production
        (Result, Production_Raise_Missing_Terminator_Recovery_Boundary,
         Tok, "raise missing terminator recovery boundary");
      Add_Production
        (Result, Production_Recovery_Point, Tok,
         "expected semicolon after raise statement");
   end if;
   Skip_Balanced_To_Semicolon (Position);
end Parse_Raise_Phase;
