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
   procedure Parse_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
   begin
      if L0 = "if" or else L0 = "elsif" or else L0 = "else" then
         Parse_Conditional_Statement_Phase (Position, Result);
      elsif L0 = "case" then
         Add_Production (Result, Production_Case_Statement, Tok, "case statement");
         Advance (Position);
         if At_Case_Statement_Selector_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "case statement selector reserved boundary recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected selector expression after case");
         else
            Add_Production
              (Result, Production_Case_Statement_Selector, Current (Position),
               "case statement selector");
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Add_Production
              (Result, Production_Case_Statement_Is_Keyword,
               Current (Position), "case statement is keyword");
         end if;
         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Case_Statement_Missing_Is_Recovery_Boundary,
               Current (Position),
               "case statement missing is recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected is in case statement");
         end if;
      elsif L0 = "when" then
         declare
            Is_Exception_Handler : Boolean := Is_In_Exception_Context (Position);
         begin
            Add_Production
              (Result, Production_Case_Alternative, Tok,
               "case or exception alternative");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              and then Lookahead_Lower (Position, 1) = ":"
            then
               --  Exception handlers have their own optional choice-parameter
               --  grammar before the exception choice list:
               --     when Error : Constraint_Error | Program_Error =>
               --  Keep this distinct from case alternatives so syntax-tree and
               --  semantic passes do not have to infer it from an opaque skip.
               Is_Exception_Handler := True;
               Add_Production
                 (Result, Production_Exception_Handler, Tok,
                  "exception handler");
               Add_Production
                 (Result, Production_Exception_Choice_Parameter,
                  Current (Position), To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Exception_Handler_Local_Name,
                  Current (Position), "exception handler local name");
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
               if not Match_Symbol (Position, ":") then
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected : in exception choice parameter");
               end if;
               Add_Production
                 (Result, Production_Exception_Choice_List, Current (Position),
                  "exception choice list");
               loop
                  exit when At_End (Position);
                  exit when To_String (Current (Position).Text) = "=>";
                  exit when To_String (Current (Position).Text) = ";";
                  Add_Production
                    (Result, Production_Exception_Choice, Current (Position),
                     To_String (Current (Position).Text));
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Exception_Others_Choice,
                        Current (Position), "exception others choice");
                     Advance (Position);
                  else
                     Add_Production
                       (Result, Production_Exception_Named_Choice,
                        Current (Position), "exception named choice");
                     if Lookahead_Lower (Position, 1) = "." then
                        Add_Production
                          (Result, Production_Exception_Selected_Choice,
                           Current (Position), "exception selected choice");
                     end if;
                     Parse_Primary (Position, Result);
                  end if;
                  if To_String (Current (Position).Text) = "|" then
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Exception_Choice_Separator,
                           Separator_Tok, "exception choice separator");
                        Advance (Position);
                        if At_End (Position)
                          or else To_String (Current (Position).Text) = "=>"
                          or else To_String (Current (Position).Text) = ";"
                          or else Current_Lower (Position) = "when"
                          or else Current_Lower (Position) = "exception"
                          or else Current_Lower (Position) = "end"
                        then
                           Add_Production
                             (Result,
                              Production_Exception_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok,
                              "exception choice separator missing following choice");
                           Add_Production
                             (Result, Production_Exception_Handler_Recovery_Boundary,
                              Separator_Tok,
                              "exception handler choice-list recovery boundary");
                           exit;
                        end if;
                     end;
                  else
                     exit;
                  end if;
               end loop;
            elsif Is_Exception_Handler then
               Add_Production
                 (Result, Production_Exception_Handler, Tok,
                  "exception handler");
               Add_Production
                 (Result, Production_Exception_Choice_List, Current (Position),
                  "exception choice list");
               loop
                  exit when At_End (Position);
                  exit when To_String (Current (Position).Text) = "=>";
                  exit when To_String (Current (Position).Text) = ";";
                  Add_Production
                    (Result, Production_Exception_Choice, Current (Position),
                     To_String (Current (Position).Text));
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Exception_Others_Choice,
                        Current (Position), "exception others choice");
                     Advance (Position);
                  else
                     Add_Production
                       (Result, Production_Exception_Named_Choice,
                        Current (Position), "exception named choice");
                     if Lookahead_Lower (Position, 1) = "." then
                        Add_Production
                          (Result, Production_Exception_Selected_Choice,
                           Current (Position), "exception selected choice");
                     end if;
                     Parse_Primary (Position, Result);
                  end if;
                  if To_String (Current (Position).Text) = "|" then
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Exception_Choice_Separator,
                           Separator_Tok, "exception choice separator");
                        Advance (Position);
                        if At_End (Position)
                          or else To_String (Current (Position).Text) = "=>"
                          or else To_String (Current (Position).Text) = ";"
                          or else Current_Lower (Position) = "when"
                          or else Current_Lower (Position) = "exception"
                          or else Current_Lower (Position) = "end"
                        then
                           Add_Production
                             (Result,
                              Production_Exception_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok,
                              "exception choice separator missing following choice");
                           Add_Production
                             (Result, Production_Exception_Handler_Recovery_Boundary,
                              Separator_Tok,
                              "exception handler choice-list recovery boundary");
                           exit;
                        end if;
                     end;
                  else
                     exit;
                  end if;
               end loop;
            else
               Add_Production
                 (Result, Production_Case_Choice_List, Current (Position),
                  "case statement choice list");
               declare
                  Probe : Cursor := Position;
               begin
                  while not At_End (Probe) loop
                     declare
                        T : constant String := To_String (Current (Probe).Text);
                        L : constant String := Current_Lower (Probe);
                     begin
                        exit when T = "=>" or else T = ";" or else L = "when" or else L = "end";
                        if L = "others" then
                           Add_Production
                             (Result, Production_Case_Others_Choice,
                              Current (Probe), "case others choice");
                        elsif T = "|" then
                           Add_Production
                             (Result, Production_Case_Choice_Separator,
                              Current (Probe), "case choice separator");
                           if Lookahead_Lower (Probe, 1) = "=>"
                             or else Lookahead_Lower (Probe, 1) = "when"
                             or else Lookahead_Lower (Probe, 1) = "end"
                             or else Lookahead_Lower (Probe, 1) = ";"
                           then
                              Add_Production
                                (Result,
                                 Production_Case_Choice_Missing_Choice_Recovery_Boundary,
                                 Current (Probe),
                                 "case choice separator missing following choice");
                              Add_Production
                                (Result, Production_Case_Alternative_Recovery_Boundary,
                                 Current (Probe),
                                 "case choice-list recovery boundary");
                           end if;
                        elsif T /= ".." then
                           Add_Production
                             (Result, Production_Case_Choice,
                              Current (Probe), "case choice");
                           if Lookahead_Lower (Probe, 1) = ".." then
                              Add_Production
                                (Result, Production_Case_Range_Choice,
                                 Current (Probe), "case range choice");
                           end if;
                        end if;
                        Advance (Probe);
                     end;
                  end loop;
               end;
               Parse_Discrete_Choice_List (Position, Result, "=>");
            end if;
            if To_String (Current (Position).Text) = "=>" then
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Choice_Arrow,
                     Current (Position), "exception choice arrow");
               else
                  Add_Production
                    (Result, Production_Case_Choice_Arrow,
                     Current (Position), "case choice arrow");
                  Add_Production
                    (Result, Production_Case_Alternative_Arrow,
                     Current (Position), "case alternative arrow");
               end if;
               Advance (Position);
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Handler_Statement_Sequence,
                     Tok, "exception handler statements");
                  if Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Exception_Handler_Null_Statement,
                        Current (Position), "exception handler null statement");
                  elsif Current_Lower (Position) = "when"
                    or else Current_Lower (Position) = "exception"
                    or else Current_Lower (Position) = "end"
                    or else To_String (Current (Position).Text) = ";"
                  then
                     --  Keep empty or malformed exception-handler bodies local
                     --  to the current handler.  The specific missing-statement
                     --  marker lets language-model consumers distinguish
                     --  ``when X =>`` recovery from ordinary exception choice
                     --  parsing without consuming the next handler or the
                     --  enclosing body's end terminator.
                     Add_Production
                       (Result,
                        Production_Exception_Handler_Missing_Statement_Recovery_Boundary,
                        Current (Position),
                        "exception handler missing statement recovery boundary");
                     if Current_Lower (Position) = "end" then
                        Add_Production
                          (Result,
                           Production_Exception_Handler_End_Statement_Recovery_Boundary,
                           Current (Position),
                           "exception handler missing statement before end");
                     end if;
                     Add_Production
                       (Result, Production_Exception_Handler_Recovery_Boundary,
                        Current (Position), "exception handler empty or malformed statement sequence");
                  end if;
               else
                  Add_Production
                    (Result, Production_Case_Alternative_Statement_Sequence,
                     Tok, "case alternative statements");
                  if Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Case_Alternative_Null_Statement,
                        Current (Position), "case alternative null statement");
                  elsif Current_Lower (Position) = "when"
                    or else Current_Lower (Position) = "end"
                    or else To_String (Current (Position).Text) = ";"
                  then
                     --  Keep empty or malformed case alternatives local to the
                     --  current alternative.  This structural recovery marker
                     --  lets outline/diagnostics/semantic-colouring consumers
                     --  distinguish ``when X =>`` from an ordinary nested
                     --  statement scan without consuming the next alternative
                     --  or the enclosing ``end case``.
                     Add_Production
                       (Result,
                        Production_Case_Alternative_Missing_Statement_Recovery_Boundary,
                        Current (Position),
                        "case alternative missing statement recovery boundary");
                     if Current_Lower (Position) = "end"
                       and then Lookahead_Lower (Position, 1) = "case"
                     then
                        Add_Production
                          (Result,
                           Production_Case_Alternative_End_Case_Statement_Recovery_Boundary,
                           Current (Position),
                           "case alternative missing statement before end case");
                     end if;
                     Add_Production
                       (Result, Production_Case_Alternative_Recovery_Boundary,
                        Current (Position),
                        "case alternative empty or malformed statement sequence");
                  end if;
               end if;
               Add_Production
                 (Result, Production_Statement_Sequence, Tok,
                  "alternative statements");
            else
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Handler_Missing_Arrow_Recovery_Boundary,
                     Tok, "exception handler missing arrow recovery boundary");
                  Add_Production
                    (Result, Production_Exception_Handler_Recovery_Boundary,
                     Tok, "exception handler recovery boundary");
               else
                  Add_Production
                    (Result, Production_Case_Alternative_Missing_Arrow_Recovery_Boundary,
                     Tok, "case alternative missing arrow recovery boundary");
                  Add_Production
                    (Result, Production_Case_Alternative_Recovery_Boundary,
                     Tok, "case alternative recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected => in alternative");
            end if;
         end;
      elsif L0 = "loop" then
         Add_Production (Result, Production_Loop_Statement, Tok, "loop statement");
         Add_Production
           (Result, Production_Loop_Begin_Keyword, Tok, "loop begin keyword");
         Add_Production
           (Result, Production_Loop_Statement_Sequence, Tok,
            "loop statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           and then Lookahead_Lower (Position, 1) = "loop"
         then
            Add_Production
              (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
               Current (Position), "loop missing statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in loop body");
         end if;
      elsif L0 = "while" then
         Add_Production (Result, Production_Loop_Statement, Tok, "while loop statement");
         Add_Production
           (Result, Production_While_Loop_Keyword, Tok, "while loop keyword");
         Advance (Position);
         if Current_Lower (Position) = "loop"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "then"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_While_Loop_Missing_Condition_Recovery_Boundary,
               Current (Position), "while loop missing condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in while loop statement");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_While_Loop_Condition, Current (Position),
                  "while loop condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Match_Keyword (Position, "loop") then
            Add_Production
              (Result, Production_Loop_Begin_Keyword, Tok,
               "while loop begin keyword");
            Add_Production
              (Result, Production_Loop_Statement_Sequence, Tok,
               "while loop statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
              if Current_Lower (Position) = "end"
                and then Lookahead_Lower (Position, 1) = "loop"
              then
                 Add_Production
                   (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                    Current (Position), "while loop missing statement recovery boundary");
                 Add_Production
                   (Result, Production_Recovery_Point, Current (Position),
                    "expected statement in while loop body");
              end if;
         else
            Add_Production
              (Result, Production_While_Loop_Missing_Loop_Recovery_Boundary,
               Tok, "while loop missing loop recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected loop in while statement");
         end if;
      elsif L0 = "declare" then
         Add_Production (Result, Production_Block_Statement, Tok, "block statement");
         Add_Production (Result, Production_Declare_Block_Statement, Tok, "declare block statement");
         Add_Production
           (Result, Production_Block_Declare_Keyword, Tok,
            "block declare keyword");
         Add_Production
           (Result, Production_Block_Declarative_Part, Tok,
            "block declarative part");
         Add_Production
           (Result, Production_Declare_Block_Declarative_Item, Tok,
            "declare block declarative items");
         declare
            Probe : Cursor := Position;
         begin
            Advance (Probe);
            while not At_End (Probe) loop
               declare
                  L : constant String := Current_Lower (Probe);
                  T : constant String := To_String (Current (Probe).Text);
               begin
                  exit when L = "begin" or else L = "exception" or else L = "end";
                  if L = "pragma" or else L = "generic" or else L = "package"
                    or else L = "procedure" or else L = "function"
                    or else L = "type" or else L = "subtype"
                    or else L = "task" or else L = "protected"
                    or else L = "for" or else Current (Probe).Kind = Token_Identifier
                  then
                     Add_Production
                       (Result, Production_Block_Declarative_Item_Start,
                        Current (Probe), "block declarative item start");
                  end if;
                  if T = ";" then
                     null;
                  elsif L = "private" or else L = "is" then
                     Add_Production
                       (Result, Production_Block_Declarative_Item_Recovery_Boundary,
                        Current (Probe), "block declarative-item recovery boundary");
                  end if;
                  Advance (Probe);
               end;
            end loop;
            if not At_End (Probe) and then Current_Lower (Probe) = "begin" then
               Add_Production
                 (Result, Production_Block_Declarative_Begin_Boundary,
                  Current (Probe), "block declarative begin boundary");
            elsif not At_End (Probe) then
               Add_Production
                 (Result, Production_Block_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "block declarative-item recovery boundary");
            end if;
         end;
         Advance (Position);
      elsif L0 = "begin" then
         Add_Production (Result, Production_Block_Statement, Tok, "block statement");
         Add_Production (Result, Production_Block_Begin_Part, Tok, "block begin part");
         Add_Production
           (Result, Production_Block_Declarative_Begin_Boundary, Tok,
            "block begin boundary");
         Add_Production
           (Result, Production_Block_Statement_Sequence, Tok,
            "block statement sequence");
         Add_Production (Result, Production_Statement_Sequence, Tok, "begin statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Block_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "block missing statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in block statement sequence");
         end if;
      elsif L0 = "exception" then
         Add_Production (Result, Production_Exception_Handler, Tok, "exception part");
         Add_Production
           (Result, Production_Block_Exception_Keyword, Tok,
            "block exception keyword");
         Add_Production
           (Result, Production_Block_Exception_Part, Tok,
            "block exception part");
         Advance (Position);
      elsif L0 = "end" then
         if L1 = "if" then
            Add_Production (Result, Production_If_Statement_End_Keyword, Tok, "end if");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_If_End_Terminator,
                  Current (Position), "if statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_If_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "if statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end if");
            end if;
         elsif L1 = "loop" then
            Add_Production (Result, Production_Loop_Statement, Tok, "end loop");
            Advance (Position);
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Loop_End_Name, Current (Position),
                  "loop end name");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Recovery_Boundary, Tok,
                  "loop end recovery boundary");
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Loop_End_Terminator,
                  Current (Position), "loop statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Loop_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "loop statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end loop");
            end if;
         elsif L1 = "case" then
            Add_Production
              (Result, Production_Case_Statement_End_Keyword, Tok,
               "end case");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Case_End_Terminator,
                  Current (Position), "case statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Case_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "case statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end case");
            end if;
         elsif L1 = "select" then
            Add_Production
              (Result, Production_Select_Statement_End_Keyword, Tok,
               "end select");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Select_End_Terminator,
                  Current (Position), "select statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Select_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "select statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end select");
            end if;
         else
            Add_Production (Result, Production_Block_Statement, Tok, "end block");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Block_End_Name, Current (Position),
                  "block end name");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Recovery_Boundary, Tok,
                  "block end recovery boundary");
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Block_End_Terminator,
                  Current (Position), "block statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "block statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end block");
            end if;
         end if;
      elsif L0 = "select" then
         Add_Production (Result, Production_Select_Statement, Tok, "select statement");
         if Select_Has_Then_Abort (Position) then
            Add_Production
              (Result, Production_Asynchronous_Select_Statement, Tok,
               "asynchronous select statement");
            Add_Production
              (Result, Production_Asynchronous_Select_Triggering_Alternative,
               Tok, "asynchronous select triggering alternative");
         end if;
         Add_Production (Result, Production_Select_Alternative, Tok, "select alternative");
         Add_Production
           (Result, Production_Select_First_Alternative, Tok,
            "select first alternative");
         Advance (Position);
         Parse_Select_Guard (Position, Result, Tok);
         Add_Production
           (Result, Production_Select_Alternative_Statement_Sequence, Tok,
            "select alternative statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "select alternative statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select first alternative missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select first alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select alternative");
         end if;
      elsif L0 = "or" then
         Add_Production (Result, Production_Select_Alternative, Tok, "select alternative");
         Add_Production (Result, Production_Select_Or_Alternative, Tok, "select or alternative");
         Advance (Position);
         Parse_Select_Guard (Position, Result, Tok);
         Add_Production
           (Result, Production_Select_Alternative_Statement_Sequence, Tok,
            "select alternative statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "select alternative statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select or alternative missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select or alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select or alternative");
         end if;
      elsif L0 = "then" and then L1 = "abort" then
         Add_Production (Result, Production_Select_Alternative, Tok, "then abort alternative");
         Add_Production (Result, Production_Select_Then_Abort_Part, Tok, "select then abort part");
         Add_Production
           (Result, Production_Asynchronous_Select_Abortable_Part, Tok,
            "asynchronous select abortable part");
         Add_Production (Result, Production_Abortable_Part, Tok, "abortable part");
         Advance (Position);
         if Current_Lower (Position) = "abort" then
            Advance (Position);
         end if;
         Add_Production
           (Result, Production_Abortable_Statement_Sequence, Tok,
            "abortable statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "abortable statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Abortable_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select abortable part missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select abortable part recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select abortable part");
         end if;
      elsif L0 = "terminate" then
         Add_Production (Result, Production_Select_Alternative, Tok, "terminate alternative");
         Add_Production
           (Result, Production_Select_Delay_Alternative, Tok,
            "select terminate/delay-family alternative");
         Add_Production
           (Result, Production_Select_Terminate_Alternative, Tok,
            "select terminate alternative");
         Add_Production (Result, Production_Terminate_Alternative, Tok, "terminate alternative");
         Add_Production (Result, Production_Null_Statement, Tok, "terminate");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Terminate_Terminator, Current (Position),
               "terminate alternative terminator");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Terminate_Missing_Terminator_Recovery_Boundary,
               Tok, "terminate missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after terminate alternative");
         end if;
      elsif L0 = "accept" or else L0 = "return" then
         Parse_Accept_Return_Phase (Position, Result);
      elsif L0 = "raise" then
         Parse_Raise_Phase (Position, Result);
      elsif L0 = "null" then
         Add_Production (Result, Production_Null_Statement, Tok, "null statement");
         if Is_In_Select_Context (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Null_Statement, Tok,
               "select alternative null statement");
         end if;
         Advance (Position);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Null_Statement_Terminator, Current (Position),
               "null statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Null_Missing_Terminator_Recovery_Boundary,
               Tok, "null missing terminator recovery boundary");
            if Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               Add_Production
                 (Result,
                  Production_Null_Reserved_Boundary_Recovery_Boundary,
                  Tok,
                  "null reserved boundary recovery boundary");
            end if;
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after null statement");
         end if;
         if Current_Lower (Position) /= "end"
           and then Current_Lower (Position) /= "or"
           and then Current_Lower (Position) /= "else"
           and then Current_Lower (Position) /= "exception"
           and then Current_Lower (Position) /= "then"
           and then Current_Lower (Position) /= "when"
         then
            Skip_Balanced_To_Semicolon (Position);
         end if;
      elsif L0 = "exit" or else L0 = "goto" then
         Parse_Exit_Goto_Phase (Position, Result);
      elsif L0 = "delay" then
         Parse_Delay_Phase (Position, Result);
      elsif L0 = "requeue" or else L0 = "abort" then
         Parse_Tasking_Phase (Position, Result);
      elsif Tok.Kind = Token_Identifier then
         Parse_Identifier_Statement_Phase (Position, Result);
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "unrecognized token");
         Advance (Position);
      end if;
   end Parse_Statement_Phase;
