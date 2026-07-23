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
procedure Parse_Identifier_Statement_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
begin
   declare
      Mark_Pos        : constant Natural := Mark (Position);
      Has_Actual_Part : constant Boolean :=
        Has_Token_Before_Semicolon (Position, "(");
      Name_End        : Natural := Mark_Pos;
      Had_Name_List   : Boolean := False;
   begin
      --  Parse the full Ada name prefix before classifying the construct.
      --  Earlier passes looked only at the first identifier, so legal
      --  statement targets such as Obj.Field := X, Arr (I) := X,
      --  Slice (A .. B) := X, Ptr.all := X, and Pkg.Op (X); were
      --  flattened into generic calls.  Keeping the name suffixes here
      --  moves the token-cursor layer closer to complete Ada statement
      --  grammar while still avoiding compiler-grade type/legality work.
      Parse_Primary (Position, Result);
      Name_End := Mark (Position);

      if Name_End = Mark_Pos + 1
        and then To_String (Current (Position).Text) = ","
      then
         --  Defining-name lists are shared by object, number, and
         --  exception declarations.  Retain each additional defining
         --  name instead of classifying grouped declarations such as
         --  ``A, B : exception;`` or ``X, Y : constant := 1;`` as
         --  call-shaped recovery.
         Had_Name_List := True;
         while Match_Symbol (Position, ",") loop
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected defining name after comma");
               exit;
            end if;
         end loop;
      end if;

      if Match_Symbol (Position, ":") then
         if Name_End /= Mark_Pos + 1 and then not Had_Name_List then
            --  A defining identifier cannot be a selected/indexed name.
            --  Treat malformed/in-progress source as a recovery point
            --  instead of fabricating an object declaration.
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "invalid defining name before :");
            Skip_Balanced_To_Semicolon (Position);
         elsif Is_Statement_Starter_After_Label (Position) then
            --  Statement identifiers are legal before any statement,
            --  for example Named_Loop : for ..., Named_Block : declare,
            --  and Named_Call : Pkg.Op (...);.  Previous passes treated
            --  every identifier-colon form as a declaration and therefore
            --  lost the following statement grammar.
            Add_Production (Result, Production_Label, Tok, To_String (Tok.Text));
            Add_Production (Result, Production_Label_Name, Tok, "statement identifier name");
            Add_Production (Result, Production_Labeled_Statement, Tok, "statement identifier");
            Add_Production (Result, Production_Statement_Identifier, Tok, "statement identifier");
            if Current_Lower (Position) = "for"
              or else Current_Lower (Position) = "while"
              or else Current_Lower (Position) = "loop"
            then
               Add_Production
                 (Result, Production_Named_Loop_Statement, Tok,
                  "named loop statement");
            elsif Current_Lower (Position) = "declare"
              or else Current_Lower (Position) = "begin"
            then
               Add_Production
                 (Result, Production_Named_Block_Statement, Tok,
                  "named block statement");
               Add_Production
                 (Result, Production_Block_Label_Name, Tok,
                  "block label name");
            end if;
            Parse_Declaration_Or_Statement (Position, Result);
         else
            Parse_Identifier_Statement_Declaration_Phase
              (Position, Result, Tok, Mark_Pos, Name_End, Had_Name_List);
         end if;
      elsif Match_Symbol (Position, ":=") then
         Add_Production (Result, Production_Assignment_Statement, Tok, "assignment");
         Add_Production
           (Result, Production_Assignment_Target, Tok,
            "assignment target name");
         Add_Statement_Name_Suffix_Productions
           (Position, Result, Mark_Pos, Name_End,
            For_Assignment => True);
         if At_End (Position)
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result,
               Production_Assignment_Missing_Expression_Recovery_Boundary,
               Tok,
               "assignment missing expression recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected expression after assignment statement");
         elsif Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
           or else Current_Lower (Position) = "then"
           or else Current_Lower (Position) = "when"
         then
            Add_Production
              (Result,
               Production_Assignment_Missing_Expression_Recovery_Boundary,
               Tok,
               "assignment missing expression recovery boundary");
            Add_Production
              (Result,
               Production_Assignment_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "assignment reserved boundary recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected expression after assignment statement");
         else
            Add_Production
              (Result, Production_Assignment_Expression,
               Current (Position), "assignment expression");
            Parse_Expression (Position, Result);
         end if;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Assignment_Terminator,
               Current (Position), "assignment statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result,
               Production_Assignment_Missing_Terminator_Recovery_Boundary,
               Tok,
               "assignment missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after assignment statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      else
         Add_Production (Result, Production_Call_Statement, Tok, "call");
         Add_Production
           (Result, Production_Call_Target, Tok, "call target name");
         Add_Statement_Name_Suffix_Productions
           (Position, Result, Mark_Pos, Name_End,
            For_Assignment => False);
         if To_String (Current (Position).Text) /= ";" then
            Add_Production
              (Result, Production_Assignment_Target_Recovery_Boundary,
               Current (Position),
               "possible missing := after statement target");
         end if;
         if Has_Actual_Part then
            Add_Production
              (Result, Production_Call_Actual_Part, Tok,
               "call actual part");
         end if;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Call_Terminator, Current (Position),
               "call statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result,
               Production_Call_Missing_Terminator_Recovery_Boundary,
               Tok,
               "call missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after call statement");
         end if;
         if Name_End /= Mark_Pos + 1 or else Has_Actual_Part then
            Add_Production
              (Result, Production_Entry_Call_Statement, Tok,
               "entry or call with name suffix/actual part");
            Add_Production
              (Result, Production_Entry_Call_Target, Tok,
               "entry or call target name");
            if Name_End /= Mark_Pos + 1 then
               Add_Production
                 (Result, Production_Entry_Call_Selected_Target, Tok,
                  "selected entry call target");
            end if;
            Add_Production
              (Result, Production_Entry_Call_Entry_Name, Tok,
               "entry call entry name");
            if Name_End /= Mark_Pos + 1 then
               Add_Production
                 (Result, Production_Entry_Call_Selected_Entry_Name, Tok,
                  "selected entry call entry name");
            end if;
            if Is_In_Select_Context (Position) then
               Add_Production
                 (Result, Production_Select_Entry_Call_Alternative, Tok,
                  "select entry call alternative");
               if Select_Has_Delay_Alternative (Position) then
                  Add_Production
                    (Result, Production_Timed_Entry_Call_Statement, Tok,
                     "timed entry call statement");
                  Add_Production
                    (Result, Production_Timed_Entry_Call_Entry_Call_Part, Tok,
                     "timed entry call entry-call part");
               end if;
               if Select_Has_Else_Alternative (Position) then
                  Add_Production
                    (Result, Production_Conditional_Entry_Call_Statement, Tok,
                     "conditional entry call statement");
                  Add_Production
                    (Result, Production_Conditional_Entry_Call_Entry_Call_Part, Tok,
                     "conditional entry call entry-call part");
               end if;
            end if;
            if Has_Actual_Part then
               Add_Production
                 (Result, Production_Entry_Call_Actual_Part, Tok,
                  "entry or call actual part");
               if Name_End /= Mark_Pos + 1 then
                  Add_Production
                    (Result, Production_Entry_Call_Index, Tok,
                     "entry call index or actual selector");
                  Add_Production
                    (Result, Production_Entry_Call_Family_Index, Tok,
                     "entry family index in call");
               end if;
            end if;
         end if;
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end;
end Parse_Identifier_Statement_Phase;
