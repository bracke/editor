with Editor.Ada_Token_Cursor.Aspect_Parsing;

separate (Editor.Ada_Token_Cursor.Parsing_Phases_Engine)
procedure Parse_Conditional_Statement_Phase
  (Position : in out Cursor;
   Result   : in out Grammar_Result) is
   pragma Suppress (Overflow_Check);
   Tok : constant Token_Info := Current (Position);
   L0  : constant String := Current_Lower (Position);
begin
      if L0 = "if" then
         Add_Production (Result, Production_If_Statement, Tok, "if statement");
         Advance (Position);
         if Current_Lower (Position) = "then"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_If_Statement_Missing_Condition_Recovery_Boundary,
               Current (Position), "if statement missing condition recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "if statement condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in if statement");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_If_Statement_Condition,
                  Current (Position), "if statement condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "then" then
            Add_Production
              (Result, Production_If_Statement_Then_Keyword,
               Current (Position), "if statement then keyword");
            Advance (Position);
            Add_Production
              (Result, Production_If_Statement_Then_Statements,
               Tok, "if statement then statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "then statements");
            if Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_If_Then_Missing_Statement_Recovery_Boundary,
                  Current (Position), "if then branch missing statement recovery boundary");
               Add_Production
                 (Result, Production_If_Statement_Recovery_Boundary,
                  Current (Position), "if then branch recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_If_Statement_Missing_Then_Recovery_Boundary,
               Tok, "if statement missing then recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Tok, "if statement recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in if statement");
         end if;
      elsif L0 = "elsif" then
         Add_Production (Result, Production_Elsif_Part, Tok, "elsif part");
         Add_Production
           (Result, Production_Elsif_Statement_Branch, Tok,
            "elsif statement branch");
         Advance (Position);
         if Current_Lower (Position) = "then"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Elsif_Statement_Missing_Condition_Recovery_Boundary,
               Current (Position), "elsif statement missing condition recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "elsif condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in elsif part");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Elsif_Statement_Condition,
                  Current (Position), "elsif statement condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "then" then
            Add_Production
              (Result, Production_Elsif_Statement_Then_Keyword,
               Current (Position), "elsif statement then keyword");
            Advance (Position);
            Add_Production
              (Result, Production_Elsif_Statement_Then_Statements,
               Tok, "elsif statement then statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "elsif statements");
            if Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_Elsif_Missing_Statement_Recovery_Boundary,
                  Current (Position), "elsif branch missing statement recovery boundary");
               Add_Production
                 (Result, Production_If_Statement_Recovery_Boundary,
                  Current (Position), "elsif branch recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_Elsif_Statement_Missing_Then_Recovery_Boundary,
               Tok, "elsif statement missing then recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Tok, "elsif statement recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in elsif part");
         end if;
      elsif L0 = "else" then
         Add_Production (Result, Production_Else_Part, Tok, "else part");
         Add_Production
           (Result, Production_If_Statement_Else_Branch, Tok,
            "if statement else branch");
         if Is_In_Select_Context (Position) then
            Add_Production (Result, Production_Select_Else_Part, Tok, "select else part");
            Add_Production
              (Result, Production_Conditional_Entry_Call_Alternative, Tok,
               "conditional entry call else alternative");
            Add_Production
              (Result, Production_Select_Else_Statement_Sequence, Tok,
               "select else statements");
         end if;
         Add_Production
           (Result, Production_Else_Statement_Sequence,
            Tok, "else statement sequence");
         Add_Production (Result, Production_Statement_Sequence, Tok, "else statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "terminate"
           or else (Current_Lower (Position) = "then"
                    and then Lookahead_Lower (Position, 1) = "abort")
         then
            Add_Production
              (Result, Production_Else_Missing_Statement_Recovery_Boundary,
               Current (Position), "else branch missing statement recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "else branch recovery boundary");
            if Is_In_Select_Context (Position) then
               Add_Production
                 (Result, Production_Select_Else_Missing_Statement_Recovery_Boundary,
                  Current (Position),
                  "select else missing statement recovery boundary");
               Add_Production
                 (Result, Production_Select_Alternative_Recovery_Boundary,
                  Current (Position),
                  "select else recovery boundary");
            end if;
         end if;
      end if;
end Parse_Conditional_Statement_Phase;
