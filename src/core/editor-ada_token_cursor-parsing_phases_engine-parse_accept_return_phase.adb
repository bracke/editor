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
procedure Parse_Accept_Return_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
   L0  : constant String := Current_Lower (Position);
begin
   if L0 = "accept" then
      Add_Production (Result, Production_Accept_Statement, Tok, "accept statement");
      if Is_In_Select_Context (Position) then
         Add_Production
           (Result, Production_Select_Accept_Alternative, Tok,
            "select accept alternative");
      end if;
      Advance (Position);
      if Current (Position).Kind = Token_Identifier or else Current (Position).Kind = Token_Keyword then
         Add_Production
           (Result, Production_Accept_Entry_Name, Current (Position),
            To_String (Current (Position).Text));
         Add_Production (Result, Production_Name, Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      else
         --  Accept statements require an entry direct name.  Keep this
         --  recovery local to the accept statement so an in-progress
         --  ``accept ;`` or ``accept do`` edit does not borrow a later
         --  statement token as an entry name.  This is structural parser
         --  metadata only; tasking legality and profile conformance remain
         --  outside the token-cursor layer.
         Add_Production
           (Result, Production_Accept_Missing_Entry_Name_Recovery_Boundary,
            Tok, "accept statement missing entry name recovery boundary");
         Add_Production
           (Result, Production_Accept_Missing_End_Recovery_Boundary, Tok,
            "accept statement recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected entry name after accept");
      end if;
      if To_String (Current (Position).Text) = "(" then
         if not Parenthesized_Has_Top_Level_Token (Position, ":")
           and then To_String (Current (Position).Text) = "("
         then
            --  accept E (Index) (...) do uses an entry index expression
            --  before the optional accept parameter profile.
            Add_Production
              (Result, Production_Accept_Entry_Index, Tok,
               "accept entry index");
            Add_Production
              (Result, Production_Accept_Entry_Index_Expression, Tok,
               "accept entry index expression");
            Add_Production
              (Result, Production_Entry_Index_Specification, Tok,
               "accept entry index");
            Parse_Association_List (Position, Result);
            if To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result, Production_Accept_Parameter_Profile,
                  Current (Position), "accept parameter profile");
               Parse_Parameter_Profile (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Accept_Parameter_Profile,
               Current (Position), "accept parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
      end if;
      if Match_Keyword (Position, "do") then
         Add_Production
           (Result, Production_Accept_Do_Part, Tok,
            "accept do part");
         Add_Production
           (Result, Production_Accept_Statement_Sequence, Tok,
            "accept statement sequence");
         Add_Production (Result, Production_Statement_Sequence, Tok, "accept statements");

         if not At_End (Position) then
            declare
               BL0 : constant String := Current_Lower (Position);
               BL1 : constant String := Lookahead_Lower (Position, 1);
            begin
               if BL0 = "end"
                 or else BL0 = "or"
                 or else BL0 = "else"
                 or else BL0 = ";"
                 or else (BL0 = "then" and then BL1 = "abort")
               then
                  Add_Production
                    (Result,
                     Production_Accept_Body_Missing_Statement_Recovery_Boundary,
                     Current (Position),
                     "accept body missing statement recovery boundary");
                  if BL0 = "end" then
                     Add_Production
                       (Result,
                        Production_Accept_Body_End_Statement_Recovery_Boundary,
                        Current (Position),
                        "accept body end statement recovery boundary");
                  end if;
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected statement in accept body");
               end if;
            end;
         end if;

         declare
            Probe     : Cursor := Position;
            Found_End : Boolean := False;
         begin
            while not At_End (Probe) loop
               declare
                  PL0 : constant String := Current_Lower (Probe);
                  PL1 : constant String := Lookahead_Lower (Probe, 1);
               begin
                  if PL0 = "end"
                    and then PL1 /= "if"
                    and then PL1 /= "loop"
                    and then PL1 /= "case"
                    and then PL1 /= "select"
                    and then PL1 /= "record"
                  then
                     Add_Production
                       (Result, Production_Accept_End_Keyword,
                        Current (Probe), "accept end keyword");
                     Advance (Probe);
                     if Current (Probe).Kind = Token_Identifier
                       or else Current (Probe).Kind = Token_Keyword
                     then
                        Add_Production
                          (Result, Production_Accept_End_Name,
                           Current (Probe), "accept end name");
                        Advance (Probe);
                     end if;
                     if not At_End (Probe)
                       and then To_String (Current (Probe).Text) = ";"
                     then
                        Add_Production
                          (Result, Production_Accept_Terminator,
                           Current (Probe), "accept terminator");
                     else
                        Add_Production
                          (Result, Production_Accept_Missing_Terminator_Recovery_Boundary,
                           Current (Probe),
                           "accept missing terminator recovery boundary");
                        Add_Production
                          (Result, Production_Recovery_Point,
                           Current (Probe),
                           "expected semicolon after accept statement");
                     end if;
                     Found_End := True;
                     exit;
                  elsif PL0 = "or"
                    or else PL0 = "else"
                    or else (PL0 = "then" and then PL1 = "abort")
                    or else (PL0 = "end" and then PL1 = "select")
                  then
                     exit;
                  elsif PL0 = "requeue" then
                     declare
                        Statement_Position : Cursor := Probe;
                     begin
                        Parse_Declaration_Or_Statement
                          (Statement_Position, Result);
                     end;
                  end if;
               end;
               Advance (Probe);
            end loop;

            if not Found_End then
               Add_Production
                 (Result, Production_Accept_Missing_End_Recovery_Boundary,
                  Tok, "accept missing end recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected end for accept statement do part");
            end if;
         end;
      end if;
   elsif L0 = "return" then
      Advance (Position);
      if Current (Position).Kind = Token_Identifier and then Lookahead_Lower (Position, 1) = ":" then
         --  Extended return statements contain a return-object declaration,
         --  not just an opaque header before ``do``.  Retain the defining
         --  identifier, subtype indication, and optional initializer so
         --  later syntax-tree/semantic passes can recover the same grammar
         --  shape as an ordinary object declaration without claiming
         --  compiler-grade return-object legality.
         Add_Production (Result, Production_Extended_Return_Statement, Tok, "extended return statement");
         Add_Production (Result, Production_Return_Object_Declaration, Current (Position), "return object declaration");
         Add_Production (Result, Production_Return_Object_Defining_Name, Current (Position), "return object defining name");
         Add_Production (Result, Production_Defining_Name, Current (Position), To_String (Current (Position).Text));
         Advance (Position);
         if not Match_Symbol (Position, ":") then
            Add_Production (Result, Production_Recovery_Point, Tok, "expected : in extended return object declaration");
         end if;
         if Current_Lower (Position) = "aliased" then
            Add_Production (Result, Production_Aliased_Part, Current (Position), "return object aliased part");
            Add_Production
              (Result, Production_Return_Object_Aliased_Qualifier,
               Current (Position), "return object aliased qualifier");
            Advance (Position);
         end if;
         if Current_Lower (Position) = "constant" then
            Add_Production
              (Result, Production_Return_Object_Constant_Qualifier,
               Current (Position), "return object constant qualifier");
            Advance (Position);
         end if;
         if not At_End (Position)
           and then Current_Lower (Position) /= "do"
           and then To_String (Current (Position).Text) /= ":="
           and then To_String (Current (Position).Text) /= ";"
         then
            if Current_Lower (Position) = "not" then
               Add_Production
                 (Result, Production_Return_Object_Null_Exclusion,
                  Current (Position), "return object null exclusion");
            end if;
            if Current_Lower (Position) = "not"
              or else Current_Lower (Position) = "access"
            then
               Add_Production
                 (Result, Production_Return_Object_Access_Definition,
                  Current (Position), "return object access definition");
            end if;
            declare
               Probe : Cursor := Position;
            begin
               while not At_End (Probe) loop
                  exit when Current_Lower (Probe) = "do"
                    or else To_String (Current (Probe).Text) = ":="
                    or else To_String (Current (Probe).Text) = ";";
                  if To_String (Current (Probe).Text) = "("
                    or else Current_Lower (Probe) = "range"
                    or else Current_Lower (Probe) = "digits"
                    or else Current_Lower (Probe) = "delta"
                  then
                     Add_Production
                       (Result, Production_Return_Object_Constraint,
                        Current (Probe), "return object subtype constraint");
                     exit;
                  end if;
                  Advance (Probe);
               end loop;
            end;
            Add_Production
              (Result, Production_Return_Object_Subtype_Indication,
               Current (Position), "return object subtype indication");
            Parse_Subtype_Indication (Position, Result);
         end if;
         if Match_Symbol (Position, ":=") then
            Add_Production (Result, Production_Extended_Return_Initializer, Tok, "extended return initializer");
            Add_Production (Result, Production_Return_Object_Initializer, Tok, "return object initializer");
            if Current_Lower (Position) = "do"
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result,
                  Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "extended return initializer reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Return_Recovery_Boundary, Current (Position),
                  "extended return initializer recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected initializer expression before extended return boundary");
            else
               Parse_Expression (Position, Result);
            end if;
         end if;
         Skip_Balanced_To (Position, "do", ";");
         if Match_Keyword (Position, "do") then
            Add_Production
              (Result, Production_Extended_Return_Do_Keyword,
               Tok, "extended return do keyword");
            Add_Production
              (Result, Production_Extended_Return_Statement_Sequence,
               Tok, "extended return statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "return statements");
            declare
               Probe     : Cursor := Position;
               Found_End : Boolean := False;
            begin
               while not At_End (Probe) loop
                  if Current_Lower (Probe) = "end"
                    and then Lookahead_Lower (Probe, 1) = "return"
                  then
                     Add_Production
                       (Result, Production_Extended_Return_End_Return,
                        Current (Probe), "extended return end return");
                     declare
                        Terminator : Cursor := Probe;
                     begin
                        Advance (Terminator);
                        Advance (Terminator);
                        if not At_End (Terminator)
                          and then To_String (Current (Terminator).Text) = ";"
                        then
                           Add_Production
                             (Result, Production_Return_Terminator,
                              Current (Terminator), "extended return terminator");
                        end if;
                     end;
                     Found_End := True;
                     exit;
                  elsif To_String (Current (Probe).Text) = ";"
                    and then Lookahead_Lower (Probe, 1) = "end"
                  then
                     --  Keep bounded scanning across the return do-part.
                     null;
                  end if;
                  Advance (Probe);
               end loop;

               if not Found_End then
                  Add_Production
                    (Result, Production_Extended_Return_Missing_End_Recovery_Boundary,
                     Tok, "extended return missing end recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected end return for extended return statement");
               end if;
            end;
         else
            Add_Production
              (Result, Production_Extended_Return_Missing_Do_Recovery_Boundary, Tok,
               "extended return missing do recovery boundary");
            Add_Production
              (Result, Production_Return_Recovery_Boundary, Tok,
               "extended return missing do recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected do in extended return statement");
         end if;
      else
         Add_Production (Result, Production_Return_Statement, Tok, "return statement");
         if not At_End (Position)
           and then To_String (Current (Position).Text) /= ";"
         then
            if Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               Add_Production
                 (Result, Production_Return_Reserved_Boundary_Recovery_Boundary,
                  Tok, "return expression reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Return_Recovery_Boundary, Tok,
                  "return statement recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected return expression before statement-sequence boundary");
            else
               Add_Production
                 (Result, Production_Return_Expression, Current (Position),
                  "return expression");
               Parse_Expression (Position, Result);
            end if;
         elsif At_End (Position) then
            Add_Production
              (Result, Production_Return_Recovery_Boundary, Tok,
               "return statement missing semicolon recovery boundary");
         end if;
         declare
            Probe : Cursor := Position;
         begin
            if not At_End (Position)
              and then To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result, Production_Return_Terminator,
                  Current (Position), "return terminator");
            else
               Skip_Balanced_To_Semicolon (Probe);
               if At_End (Probe)
              or else At_End (Position)
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "exception"
               then
                  Add_Production
                    (Result, Production_Return_Missing_Terminator_Recovery_Boundary,
                     Tok, "return missing terminator recovery boundary");
                  Add_Production
                    (Result, Production_Return_Recovery_Boundary, Tok,
                     "return statement missing semicolon recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected semicolon after return statement");
               end if;
            end if;
         end;
         if Current_Lower (Position) /= "end"
           and then Current_Lower (Position) /= "or"
           and then Current_Lower (Position) /= "else"
           and then Current_Lower (Position) /= "elsif"
           and then Current_Lower (Position) /= "exception"
           and then Current_Lower (Position) /= "then"
           and then Current_Lower (Position) /= "when"
         then
            Skip_Balanced_To_Semicolon (Position);
         end if;
      end if;
   end if;
end Parse_Accept_Return_Phase;
