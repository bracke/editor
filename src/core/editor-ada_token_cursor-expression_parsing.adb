with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Primary_Parsing;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Expression_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Primary_Parsing;
   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Current_Lower (Position : Cursor) return String is
   begin
      return To_String (Current (Position).Lower);
   end Current_Lower;

   function Lookahead_Lower
     (Position : Cursor;
      Offset   : Natural) return String is
      Index : Positive := Position.Index + Offset;
   begin
      if Index <= Positive (Position.Stream.Tokens.Length) then
         return To_String (Position.Stream.Tokens (Index).Lower);
      else
         return "";
      end if;
   end Lookahead_Lower;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Factor (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      declare
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         if T = "=>"
           or else T = "|"
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "then"
           or else L = "else"
           or else L = "loop"
           or else L = "begin"
           or else L = "end"
           or else L = "when"
         then
            return;
         end if;
      end;
      Add_Production (Result, Production_Factor, Tok, To_String (Tok.Text));
      if Current_Lower (Position) = "abs" or else Current_Lower (Position) = "not"
        or else To_String (Current (Position).Text) = "+"
        or else To_String (Current (Position).Text) = "-"
      then
         Add_Production (Result, Production_Unary_Expression, Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      end if;
      Parse_Primary (Position, Result);
      if not At_End (Position) and then To_String (Current (Position).Text) = "**" then
         Add_Production
           (Result, Production_Expression_Operator, Current (Position), "**");
         Advance (Position);
         Parse_Primary (Position, Result);
      end if;
   end Parse_Factor;

   procedure Parse_Term (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Term, Tok, To_String (Tok.Text));
      Parse_Factor (Position, Result);
      while not At_End (Position)
        and then (To_String (Current (Position).Text) = "*"
                  or else To_String (Current (Position).Text) = "/"
                  or else Current_Lower (Position) = "mod"
                  or else Current_Lower (Position) = "rem")
      loop
         Add_Production
           (Result, Production_Expression_Operator, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         Parse_Factor (Position, Result);
      end loop;
   end Parse_Term;

   procedure Parse_Simple_Expression (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Simple_Expression, Tok, To_String (Tok.Text));
      Parse_Term (Position, Result);
      while not At_End (Position)
        and then (To_String (Current (Position).Text) = "+"
                  or else To_String (Current (Position).Text) = "-"
                  or else To_String (Current (Position).Text) = "&")
      loop
         Add_Production
           (Result, Production_Expression_Operator, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         Parse_Term (Position, Result);
      end loop;
   end Parse_Simple_Expression;

   procedure Parse_Relation (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Membership_Choice_Recovery_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            T : constant String := To_String (Current (Position).Text);
            L : constant String := Current_Lower (Position);
         begin
            return T = "|"
              or else T = ";"
              or else T = ")"
              or else T = ","
              or else T = "=>"
              or else L = "then"
              or else L = "else"
              or else L = "loop"
              or else L = "is"
              or else L = "begin"
              or else L = "end";
         end;
      end At_Membership_Choice_Recovery_Boundary;

      procedure Parse_Membership_Choice is
         Choice_Tok : constant Token_Info := Current (Position);
      begin
         Add_Production
           (Result, Production_Membership_Choice, Choice_Tok,
            "membership choice");

         if Current_Lower (Position) = "range" then
            Add_Production
              (Result, Production_Range_Expression, Choice_Tok,
               "membership range");
            Advance (Position);
            Parse_Simple_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Parse_Simple_Expression (Position, Result);
            end if;
         else
            Parse_Simple_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Add_Production
                 (Result, Production_Range_Expression, Choice_Tok,
                  "membership choice range");
               Parse_Simple_Expression (Position, Result);
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Range_Expression, Choice_Tok,
                  "membership subtype range");
               Advance (Position);
               Parse_Simple_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Parse_Simple_Expression (Position, Result);
               end if;
            end if;
         end if;
      end Parse_Membership_Choice;
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Relation, Tok, To_String (Tok.Text));
      Parse_Simple_Expression (Position, Result);
      if not At_End (Position)
        and then (To_String (Current (Position).Text) = "="
                  or else To_String (Current (Position).Text) = "/="
                  or else To_String (Current (Position).Text) = "<"
                  or else To_String (Current (Position).Text) = "<="
                  or else To_String (Current (Position).Text) = ">"
                  or else To_String (Current (Position).Text) = ">="
                  or else Current_Lower (Position) = "in"
                  or else (Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "in"))
      then
         declare
            Op_Tok : constant Token_Info := Current (Position);
         begin
            if Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "in" then
               Add_Production (Result, Production_Membership_Operator, Op_Tok, "not in");
               Advance (Position);
               Advance (Position);
               Add_Production (Result, Production_Membership_Choice_List, Op_Tok, "not in");
               if At_Membership_Choice_Recovery_Boundary then
                  Add_Production
                    (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                     Op_Tok, "membership choice list missing first choice recovery boundary");
               else
                  Parse_Membership_Choice;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) = "|"
                  loop
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Membership_Choice_Separator,
                           Separator_Tok, "membership choice separator");
                        Advance (Position);
                        if At_Membership_Choice_Recovery_Boundary then
                           Add_Production
                             (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok, "membership choice list missing choice recovery boundary");
                           exit;
                        end if;
                        Parse_Membership_Choice;
                     end;
                  end loop;
               end if;
            elsif Current_Lower (Position) = "in" then
               Add_Production (Result, Production_Membership_Operator, Op_Tok, "in");
               Advance (Position);
               Add_Production (Result, Production_Membership_Choice_List, Op_Tok, "in");
               if At_Membership_Choice_Recovery_Boundary then
                  Add_Production
                    (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                     Op_Tok, "membership choice list missing first choice recovery boundary");
               else
                  Parse_Membership_Choice;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) = "|"
                  loop
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Membership_Choice_Separator,
                           Separator_Tok, "membership choice separator");
                        Advance (Position);
                        if At_Membership_Choice_Recovery_Boundary then
                           Add_Production
                             (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok, "membership choice list missing choice recovery boundary");
                           exit;
                        end if;
                        Parse_Membership_Choice;
                     end;
                  end loop;
               end if;
            else
               Add_Production
                 (Result, Production_Relational_Operator, Op_Tok,
                  To_String (Op_Tok.Text));
               Advance (Position);
               Parse_Simple_Expression (Position, Result);
            end if;
         end;
      end if;
   end Parse_Relation;

   procedure Parse_Expression (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Expression, Tok, To_String (Tok.Text));
      Parse_Relation (Position, Result);
      while not At_End (Position)
        and then (Current_Lower (Position) = "and" or else Current_Lower (Position) = "or" or else Current_Lower (Position) = "xor")
      loop
         declare
            Op_Tok : constant Token_Info := Current (Position);
            Op     : constant String := Current_Lower (Position);
         begin
            Add_Production
              (Result, Production_Expression_Operator, Op_Tok, Op);
            if Op = "and" or else Op = "or" then
               Add_Production
                 (Result, Production_Short_Circuit_Operation, Op_Tok, Op);
            end if;
            Advance (Position);
            if (Op = "and" and then Current_Lower (Position) = "then")
              or else (Op = "or" and then Current_Lower (Position) = "else")
            then
               Advance (Position);
            end if;
            Parse_Relation (Position, Result);
         end;
      end loop;
   end Parse_Expression;

   procedure Parse_Discrete_Choice_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Discrete_Choice_List, Tok,
         "discrete choice list");

      loop
         exit when At_End (Position);
         exit when To_String (Current (Position).Text) = Stop;
         exit when Current_Lower (Position) = Stop;
         exit when To_String (Current (Position).Text) = ";";

         declare
            Choice_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discrete_Choice, Choice_Tok,
               To_String (Choice_Tok.Text));

            if Current_Lower (Position) = "others" then
               Advance (Position);
            elsif (Current (Position).Kind = Token_Identifier
                   or else Current (Position).Kind = Token_Keyword)
              and then (Lookahead_Lower (Position, 1) = "|"
                        or else Lookahead_Lower (Position, 1) = Stop)
            then
               Advance (Position);
            else
               Parse_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Add_Production
                    (Result, Production_Range_Expression, Choice_Tok,
                     "discrete choice range");
                  Parse_Expression (Position, Result);
               end if;
            end if;
         end;

         if To_String (Current (Position).Text) = "|" then
            Add_Production
              (Result, Production_Discrete_Choice_Separator, Current (Position),
               "discrete choice separator");
            Advance (Position);
            if At_End (Position)
              or else To_String (Current (Position).Text) = Stop
              or else Current_Lower (Position) = Stop
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result, Production_Discrete_Choice_Missing_Choice_Recovery_Boundary,
                  Tok, "discrete choice missing choice recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected discrete choice after separator");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;
   end Parse_Discrete_Choice_List;

   procedure Parse_Select_Guard
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Anchor   : Token_Info) is
      function At_Select_Guard_Condition_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = "=>"
           or else T = ";"
           or else L = "accept"
           or else L = "delay"
           or else L = "terminate"
           or else L = "else"
           or else L = "or"
           or else L = "then"
           or else L = "abort"
           or else L = "end";
      end At_Select_Guard_Condition_Boundary;
   begin
      if Current_Lower (Position) = "when" then
         Add_Production
           (Result, Production_Select_Guard, Current (Position),
            "select guard");
         Advance (Position);
         if At_Select_Guard_Condition_Boundary then
            Add_Production
              (Result, Production_Select_Guard_Missing_Condition_Recovery_Boundary, Anchor,
               "select guard missing condition recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary, Anchor,
               "select guard condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected condition after select guard when");
         else
            Add_Production
              (Result, Production_Select_Guard_Condition, Current (Position),
               "select guard condition");
            Parse_Expression (Position, Result);
         end if;
         if To_String (Current (Position).Text) = "=>" then
            Add_Production
              (Result, Production_Select_Guard_Arrow, Current (Position),
               "select guard arrow");
         end if;
         if not Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Select_Guard_Missing_Arrow_Recovery_Boundary, Anchor,
               "select guard missing arrow recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary, Anchor,
               "select guard recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected => after select guard");
         end if;
      end if;
   end Parse_Select_Guard;

end Editor.Ada_Token_Cursor.Expression_Parsing;
