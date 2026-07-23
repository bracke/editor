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
procedure Parse_Tasking_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
   L0  : constant String := Current_Lower (Position);
begin
   if L0 = "requeue" then
      Add_Production (Result, Production_Requeue_Statement, Tok, "requeue statement");
      Advance (Position);
      if not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
         if Is_Statement_Control_Boundary (Position)
         then
            --  A reserved statement-sequence boundary after ``requeue`` is
            --  not an entry name target.  Keep this requeue-specific so
            --  malformed edits such as ``requeue else;`` do not fabricate
            --  a target from the next enclosing construct.
            Add_Production
              (Result, Production_Requeue_Missing_Target_Recovery_Boundary, Tok,
               "requeue missing target recovery boundary");
            Add_Production
              (Result, Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary,
               Tok, "requeue target reserved boundary recovery boundary");
            Add_Production
              (Result, Production_Requeue_Target_Recovery_Boundary, Tok,
               "requeue target recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected entry name in requeue statement");
         else
            Add_Production
              (Result, Production_Requeue_Target, Current (Position),
               "requeue target");
            if Lookahead_Lower (Position, 1) = "." then
               Add_Production
                 (Result, Production_Requeue_Selected_Target, Current (Position),
                  "requeue selected target");
            end if;
            Add_Production
              (Result, Production_Requeue_Entry_Name, Current (Position),
               "requeue entry name");
            Parse_Visibility_Name
              (Position, Result, Production_Name, "requeue entry name");
            if not At_End (Position)
              and then To_String (Current (Position).Text) = "("
            then
               Add_Production
                 (Result, Production_Requeue_Indexed_Target, Current (Position),
                  "requeue indexed target");
               Add_Production
                 (Result, Production_Indexed_Component, Current (Position),
                  "requeue indexed target");
               Add_Production
                 (Result, Production_Requeue_Entry_Index, Current (Position),
                  "requeue entry index");
               Add_Production
                 (Result, Production_Entry_Index_Specification, Current (Position),
                  "requeue entry index");
               Parse_Association_List (Position, Result);
            end if;
         end if;
      else
         --  Requeue statements require an entry name target.  Keep this
         --  recovery target-specific so malformed or in-progress
         --  ``requeue ;`` edits do not reuse a later token as the target
         --  while still preserving the existing broader target recovery
         --  marker for older consumers.
         Add_Production
           (Result, Production_Requeue_Missing_Target_Recovery_Boundary, Tok,
            "requeue missing target recovery boundary");
         Add_Production
           (Result, Production_Requeue_Target_Recovery_Boundary, Tok,
            "requeue target recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected entry name in requeue statement");
      end if;
      if Current_Lower (Position) = "with" then
         if Lookahead_Lower (Position, 1) = "abort" then
            Add_Production
              (Result, Production_Requeue_With_Abort, Current (Position),
               "requeue with abort");
            Advance (Position);
            Advance (Position);
         else
            Add_Production
              (Result, Production_Requeue_With_Missing_Abort_Recovery_Boundary,
               Current (Position), "requeue with missing abort recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected abort after with in requeue statement");
            Advance (Position);
         end if;
      end if;
      if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Requeue_Terminator, Current (Position),
            "requeue statement terminator");
      elsif At_End (Position)
        or else Is_Statement_Tail_Boundary (Position)
      then
         Add_Production
           (Result, Production_Requeue_Missing_Terminator_Recovery_Boundary,
            Tok, "requeue missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected semicolon after requeue statement");
      end if;
      Skip_Balanced_To_Semicolon (Position);
   elsif L0 = "abort" then
      Add_Production (Result, Production_Abort_Statement, Tok, "abort statement");
      Advance (Position);
      if not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
         Add_Production
           (Result, Production_Abort_Target_List, Current (Position),
            "abort target list");
         loop
            Add_Production
              (Result, Production_Abort_Target, Current (Position),
               "abort target");
            Add_Production
              (Result, Production_Abort_Target_Name, Current (Position),
               "abort task name");
            declare
               Probe : Cursor := Position;
            begin
               while not At_End (Probe) loop
                  exit when To_String (Current (Probe).Text) = ","
                    or else To_String (Current (Probe).Text) = ";";
                  if To_String (Current (Probe).Text) = "." then
                     Add_Production
                       (Result, Production_Abort_Selected_Target,
                        Current (Probe), "abort selected target");
                  elsif To_String (Current (Probe).Text) = "(" then
                     Add_Production
                       (Result, Production_Abort_Indexed_Target,
                        Current (Probe), "abort indexed target");
                  elsif Current_Lower (Probe) = "all" then
                     Add_Production
                       (Result, Production_Abort_Dereferenced_Target,
                        Current (Probe), "abort dereferenced target");
                  end if;
                  Advance (Probe);
               end loop;
            end;
            Parse_Primary (Position, Result);
            exit when To_String (Current (Position).Text) /= ",";
            Add_Production
              (Result, Production_Abort_Target_Separator, Current (Position),
               "abort target separator");
            Advance (Position);
            if At_End (Position) or else To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
                  "abort missing target recovery boundary");
               Add_Production
                 (Result, Production_Abort_Recovery_Boundary, Tok,
                  "abort target list recovery boundary");
               exit;
            elsif Is_Statement_Control_Boundary (Position)
            then
               --  A reserved statement-sequence boundary after a comma is
               --  not an abort target.  Keep this target-list-specific so
               --  malformed edits such as ``abort Worker, else;`` do not
               --  fabricate a target name from the next enclosing construct.
               Add_Production
                 (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
                  "abort missing target recovery boundary");
               Add_Production
                 (Result, Production_Abort_Target_Reserved_Boundary_Recovery_Boundary,
                  Tok, "abort target reserved boundary recovery boundary");
               Add_Production
                 (Result, Production_Abort_Recovery_Boundary, Tok,
                  "abort target list recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected task name after comma in abort statement");
               exit;
            end if;
         end loop;
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected task name in abort statement");
         Add_Production
           (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
            "abort missing target recovery boundary");
         Add_Production
           (Result, Production_Abort_Recovery_Boundary, Tok,
            "abort statement recovery boundary");
      end if;
      if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Abort_Terminator, Current (Position),
            "abort statement terminator");
      elsif At_End (Position) or else Is_Statement_Tail_Boundary (Position) then
         Add_Production
           (Result, Production_Abort_Missing_Terminator_Recovery_Boundary,
            Tok, "abort missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected semicolon after abort statement");
      end if;
      Skip_Balanced_To_Semicolon (Position);
   end if;
end Parse_Tasking_Phase;
