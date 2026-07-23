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
   procedure Parse_Primary (Position : in out Cursor; Result : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);

      function At_Allocator_Subtype_Boundary
        (Position : Cursor) return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else T = "=>"
           or else L = "with"
           or else L = "is"
           or else L = "begin"
           or else L = "private"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "exception"
           or else L = "end";
      end At_Allocator_Subtype_Boundary;

      function Qualified_Operand_Is_Missing
        (Open_Position : Cursor) return Boolean is
         L : constant String := Lookahead_Lower (Open_Position, 1);
      begin
         return L = ""
           or else L = ")"
           or else L = ";"
           or else L = ","
           or else L = "with"
           or else L = "is"
           or else L = "begin"
           or else L = "private"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "exception"
           or else L = "end";
      end Qualified_Operand_Is_Missing;

   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Primary, Tok, To_String (Tok.Text));

      if To_String (Tok.Text) = "<>" then
         --  Ada box expressions are first-class syntactic placeholders in
         --  aggregates, generic actuals, aspect/default associations, and
         --  other grammar contexts.  Retain them as expression primaries
         --  instead of treating the <> token as an opaque operator.
         Add_Production (Result, Production_Box_Expression, Tok, "box expression");
         Advance (Position);
      elsif Current_Lower (Position) = "new" then
         Add_Production (Result, Production_Allocator, Tok, "allocator");
         Advance (Position);

         declare
            Allocator_Subtype_Is_Selected : constant Boolean :=
              Editor.Ada_Token_Cursor.Primary_Parsing.
                Qualified_Subtype_Mark_Has_Selected_Prefix (Position);
         begin
            --  Ada allocators have two distinct shapes:
            --
            --     new Subtype_Mark
            --     new Subtype_Mark'(Expression_Or_Aggregate)
            --
            --  Older parsing kept only the outer allocator and then reused the
            --  generic subtype/association productions.  That was sufficient for
            --  recovery, but it hid whether a semantic consumer was looking at an
            --  uninitialized allocator, a qualified-expression allocator, or an
            --  initialized allocator using an aggregate/association part.
            if At_Allocator_Subtype_Boundary (Position) then
               Add_Production
                 (Result, Production_Allocator_Missing_Subtype_Recovery_Boundary,
                  Current (Position), "allocator missing subtype recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected allocator subtype before boundary");
            else
               Add_Production
                 (Result, Production_Allocator_Subtype_Indication, Current (Position),
                  "allocator subtype indication");
               Parse_Allocator_Subtype_Indication (Position, Result);
            end if;

            if To_String (Current (Position).Text) = "'" then
               Add_Production
                 (Result, Production_Allocator_Qualified_Expression, Tok,
                  "allocator qualified expression");
               Add_Production
                 (Result, Production_Allocator_Nested_Qualified_Expression, Tok,
                  "allocator nested qualified expression");
               Add_Production
                 (Result, Production_Qualified_Expression, Tok,
                  "allocator qualified expression");
               Add_Production
                 (Result, Production_Qualified_Expression_Subtype_Mark, Tok,
                  "allocator qualified-expression subtype mark");
               if Allocator_Subtype_Is_Selected then
                  Add_Production
                    (Result, Production_Qualified_Expression_Selected_Subtype_Mark,
                     Tok, "allocator qualified-expression selected subtype mark");
               end if;
               Add_Production
                 (Result, Production_Qualified_Expression_Apostrophe, Current (Position),
                  "qualified-expression apostrophe");
               Advance (Position);
               if To_String (Current (Position).Text) = "(" then
                  Add_Production
                    (Result, Production_Allocator_Initialized_Expression,
                     Current (Position), "allocator initialized expression");
                  Add_Production
                    (Result, Production_Qualified_Expression_Operand,
                     Current (Position), "allocator qualified-expression operand");
                  if Qualified_Operand_Is_Missing (Position) then
                     Add_Production
                       (Result, Production_Qualified_Expression_Missing_Operand_Recovery_Boundary,
                        Current (Position), "allocator qualified-expression missing operand recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected allocator qualified-expression operand before boundary");
                  end if;
                  Parse_Association_List (Position, Result, Qualified_Expression_Operand => True);
               end if;
            elsif To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result, Production_Allocator_Initialized_Expression,
                  Current (Position), "allocator initialized expression");
               Parse_Association_List (Position, Result);
            end if;
         end;
      elsif Current_Lower (Position) = "raise" then
         Add_Production (Result, Production_Raise_Expression, Tok, "raise expression");
         Advance (Position);

         --  Raise expressions mirror the statement form:
         --     raise Exception_Name [with String_Expression]
         --  Keep the exception-name and message-expression positions visible
         --  instead of relying only on generic expression nodes.  This remains
         --  syntactic: exception resolution and message type legality are
         --  outside the editor grammar layer.
         if not At_End (Position)
           and then Current_Lower (Position) /= "with"
           and then To_String (Current (Position).Text) /= ";"
           and then To_String (Current (Position).Text) /= ")"
         then
            Add_Production
              (Result, Production_Raise_Expression_Target, Current (Position),
               "raise expression target");
            Add_Production
              (Result, Production_Raise_Exception_Name, Current (Position),
               "raise expression exception name");
            Mark_Raise_Exception_Target_Shape
              (Position, Result, Current (Position),
               Production_Raise_Expression_Selected_Exception_Name,
               Production_Raise_Expression_Recovery_Boundary,
               "raise expression exception name");
            Parse_Expression (Position, Result);
         else
            Add_Production
              (Result, Production_Raise_Expression_Recovery_Boundary, Tok,
               "raise expression missing exception name");
         end if;
         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Raise_With_Message_Keyword, Current (Position),
               "raise expression with keyword");
            Advance (Position);
            if At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else To_String (Current (Position).Text) = ")"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_Raise_Expression_Message_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Raise_Message_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Raise_Expression_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "raise expression missing message expression");
            else
               Add_Production
                 (Result, Production_Raise_Expression_With_Message, Current (Position),
                  "raise expression with message");
               Add_Production
                 (Result, Production_Raise_With_Message, Current (Position),
                  "raise expression with message");
               Add_Production
                 (Result, Production_Raise_Expression_Message, Current (Position),
                  "raise expression message");
               Add_Production
                 (Result, Production_Raise_Message_Expression, Current (Position),
                  "raise expression message");
               Parse_Expression (Position, Result);
            end if;
         end if;
      elsif Current_Lower (Position) = "if" then
         Add_Production (Result, Production_Conditional_Expression, Tok, "if expression");
         Add_Production (Result, Production_If_Expression, Tok, "if expression");
         Advance (Position);
         if At_Conditional_Expression_Dependent_Boundary (Position) then
            Add_Production
              (Result, Production_If_Expression_Condition_Reserved_Boundary,
               Current (Position), "if expression condition reserved boundary");
            Add_Production
              (Result, Production_If_Expression_Missing_Condition_Recovery_Boundary,
               Tok, "if expression missing condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected condition in if expression");
         else
            Add_Production
              (Result, Production_If_Expression_Condition, Current (Position),
               "if expression condition");
            Parse_Expression (Position, Result);
         end if;
         if Match_Keyword (Position, "then") then
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Missing_Then_Branch_Recovery_Boundary,
                  Tok, "if expression missing then-branch recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected then-dependent expression in if expression");
            else
               Add_Production
                 (Result, Production_If_Expression_Then_Dependent_Expression,
                  Current (Position), "then dependent expression");
               Add_Production
                 (Result, Production_If_Expression_Branch_Expression,
                  Current (Position), "then branch expression");
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_If_Expression_Missing_Then_Recovery_Boundary,
               Tok, "if expression missing then recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in if expression");
         end if;
         while Match_Keyword (Position, "elsif") loop
            Add_Production
              (Result, Production_Elsif_Expression_Part, Current (Position),
               "elsif expression part");
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Condition_Reserved_Boundary,
                  Current (Position), "elsif expression condition reserved boundary");
               Add_Production
                 (Result, Production_If_Expression_Missing_Condition_Recovery_Boundary,
                  Tok, "elsif expression missing condition recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected condition in elsif expression");
            else
               Add_Production
                 (Result, Production_Elsif_Expression_Condition, Current (Position),
                  "elsif expression condition");
               Parse_Expression (Position, Result);
            end if;
            if Match_Keyword (Position, "then") then
               if At_Conditional_Expression_Dependent_Boundary (Position) then
                  Add_Production
                    (Result, Production_If_Expression_Missing_Then_Branch_Recovery_Boundary,
                     Tok, "elsif expression missing then-branch recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected then-dependent expression in elsif expression");
               else
                  Add_Production
                    (Result, Production_Elsif_Expression_Then_Dependent_Expression,
                     Current (Position), "elsif dependent expression");
                  Add_Production
                    (Result, Production_If_Expression_Branch_Expression,
                     Current (Position), "elsif branch expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Elsif_Expression_Missing_Then_Recovery_Boundary,
                  Tok, "elsif expression missing then recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected then in elsif expression");
            end if;
         end loop;
         if Match_Keyword (Position, "else") then
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Missing_Else_Branch_Recovery_Boundary,
                  Tok, "if expression missing else-branch recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected else-dependent expression in if expression");
            else
               Add_Production
                 (Result, Production_Else_Expression_Part, Current (Position),
                  "else expression part");
               Add_Production
                 (Result, Production_If_Expression_Else_Dependent_Expression,
                  Current (Position), "else dependent expression");
               Add_Production
                 (Result, Production_If_Expression_Branch_Expression,
                  Current (Position), "else branch expression");
               Parse_Expression (Position, Result);
            end if;
         else
            --  Ada conditional expressions require an else-dependent
            --  expression.  Keep this syntactic recovery local and bounded so
            --  malformed in-progress code such as ``if A then B`` is visible
            --  to diagnostics/colouring without consuming the surrounding
            --  delimiter or declaration boundary.
            Add_Production
              (Result, Production_If_Expression_Missing_Else_Recovery_Boundary,
               Tok, "if expression missing else recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected else in if expression");
         end if;
      elsif Current_Lower (Position) = "case" then
         Add_Production (Result, Production_Case_Expression, Tok, "case expression");
         Advance (Position);
         if At_Case_Expression_Selector_Boundary (Position) then
            Add_Production
              (Result, Production_Case_Expression_Missing_Selector_Recovery_Boundary,
               Tok, "case expression missing selector recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected selector in case expression");
         else
            Add_Production
              (Result, Production_Case_Expression_Selector, Current (Position),
               "case expression selector");
            Parse_Expression (Position, Result);
         end if;
         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Case_Expression_Missing_Is_Recovery_Boundary,
               Tok, "case expression missing is recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in case expression");
         end if;
         if Current_Lower (Position) /= "when" then
            Add_Production
              (Result, Production_Case_Expression_Missing_Alternative_Recovery_Boundary,
               Tok, "case expression missing alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected when alternative in case expression");
         end if;
         while Match_Keyword (Position, "when") loop
            Add_Production
              (Result, Production_Case_Expression_Alternative, Current (Position),
               "case expression alternative");
            Add_Production
              (Result, Production_Case_Expression_Choice_List, Current (Position),
               "case expression choice list");
            Parse_Discrete_Choice_List (Position, Result, "=>");
            if Match_Symbol (Position, "=>") then
               Add_Production
                 (Result, Production_Case_Expression_Arrow, Current (Position),
                  "case expression arrow");
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ","
                 or else To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
                 or else Current_Lower (Position) = "when"
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "then"
               then
                  Add_Production
                    (Result,
                     Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary,
                     Tok, "case expression missing dependent expression recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected dependent expression in case expression alternative");
               else
                  Add_Production
                    (Result, Production_Case_Expression_Dependent_Expression,
                     Current (Position), "case expression dependent expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Case_Expression_Missing_Arrow_Recovery_Boundary,
                  Tok, "case expression missing arrow recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected => in case expression");
            end if;
            if To_String (Current (Position).Text) = "," then
               Add_Production
                 (Result, Production_Case_Expression_Alternative_Separator,
                  Current (Position), "case expression alternative separator");
               Advance (Position);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Case_Expression_Missing_Alternative_Recovery_Boundary,
                     Tok, "case expression missing alternative recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected case expression alternative after separator");
                  exit;
               end if;
            else
               exit;
            end if;
         end loop;
      elsif Current_Lower (Position) = "for" then
         Add_Production (Result, Production_Quantified_Expression, Tok, "quantified expression");
         Advance (Position);

         --  Ada quantified expressions use a quantified loop scheme:
         --
         --     for all  I    in Source_Span     => Predicate
         --     for some Item of Container => Predicate
         --
         --  Keep the parameter, iteration domain, optional iterator filter,
         --  and predicate as separate grammar productions.  Earlier recovery
         --  skipped the whole domain to ``=>``; that preserved the outer
         --  expression but hid range bounds, container names, and filter
         --  expressions from the language model.
         if Current_Lower (Position) = "all" or else Current_Lower (Position) = "some" then
            Add_Production
              (Result, Production_Quantifier, Current (Position),
               Current_Lower (Position));
            Advance (Position);
         else
            --  Ada quantified expressions require an explicit quantifier
            --  (``all`` or ``some``) after ``for``.  Keep malformed
            --  in-progress expressions such as ``(for I in Items => P (I))``
            --  visible to downstream consumers without treating the missing
            --  quantifier as an ordinary loop-parameter token.
            Add_Production
              (Result,
               Production_Quantified_Missing_Quantifier_Recovery_Boundary,
               Tok, "quantified expression missing quantifier recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected all or some in quantified expression");
         end if;

         Add_Production
           (Result, Production_Quantified_Loop_Scheme, Current (Position),
            "quantified loop scheme");

         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
         then
            Add_Production
              (Result, Production_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
            Add_Production
              (Result, Production_Quantified_Parameter, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;

         if Current_Lower (Position) = "in" then
            Add_Production
              (Result, Production_Loop_Parameter_Specification, Tok,
               "quantified loop parameter specification");
            Advance (Position);
         elsif Current_Lower (Position) = "of" then
            Add_Production
              (Result, Production_Iterator_Specification, Tok,
               "quantified iterator specification");
            Advance (Position);
         end if;

         if Current_Lower (Position) = "reverse" then
            Advance (Position);
         end if;

         if not At_End (Position)
           and then To_String (Current (Position).Text) /= "=>"
           and then Current_Lower (Position) /= "when"
         then
            declare
               Domain_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Quantified_Domain, Domain_Tok,
                  "quantified domain");
               Parse_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Add_Production
                    (Result, Production_Range_Expression, Domain_Tok,
                     "quantified discrete range");
                  Parse_Expression (Position, Result);
               elsif Current_Lower (Position) = "range" then
                  Add_Production
                    (Result, Production_Range_Expression, Domain_Tok,
                     "quantified subtype range");
                  Advance (Position);
                  if To_String (Current (Position).Text) = "<>" then
                     Add_Production
                       (Result, Production_Box_Expression, Current (Position),
                        "quantified box range");
                     Advance (Position);
                  else
                     Parse_Expression (Position, Result);
                     if Match_Symbol (Position, "..") then
                        Parse_Expression (Position, Result);
                     end if;
                  end if;
               end if;
            end;
         elsif Current_Lower (Position) = "when"
           or else To_String (Current (Position).Text) = "=>"
         then
            Add_Production
              (Result, Production_Quantified_Missing_Domain_Recovery_Boundary,
               Tok, "quantified expression missing domain recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected quantified expression domain");
         end if;

         if Match_Keyword (Position, "when") then
            Add_Production
              (Result, Production_Quantified_Iterator_Filter,
               Current (Position), "quantified iterator filter");
            if At_Iterator_Filter_Condition_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                  Current (Position),
                  "missing quantified iterator filter condition");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected quantified iterator filter condition");
            else
               Parse_Expression (Position, Result);
            end if;
         end if;

         if Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Quantified_Arrow, Current (Position),
               "quantified arrow");
            if At_Quantified_Predicate_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Quantified_Missing_Predicate_Recovery_Boundary,
                  Current (Position),
                  "quantified expression missing predicate recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected quantified predicate");
            else
               Add_Production
                 (Result, Production_Quantified_Predicate, Current (Position),
                  "quantified predicate");
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Quantified_Missing_Arrow_Recovery_Boundary,
               Tok, "quantified expression missing arrow recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected => in quantified expression");
         end if;
      elsif Current_Lower (Position) = "null" then
         Add_Production (Result, Production_Null_Literal, Tok, "null literal");
         Advance (Position);
      elsif Tok.Kind = Token_Numeric_Literal then
         --  Keep Ada numeric literals distinct from ordinary primaries so
         --  downstream expression consumers can recognize literal-valued
         --  ranges, static bounds, and named-number defaults without
         --  re-tokenizing the source text.
         Add_Production
           (Result, Production_Numeric_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif Tok.Kind = Token_String_Literal then
         Add_Production
           (Result, Production_String_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif Tok.Kind = Token_Character_Literal then
         Add_Production
           (Result, Production_Character_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif To_String (Tok.Text) = "@" then
         --  Ada 2022 target_name is a primary used inside assignment
         --  expressions to denote the current value of the assignment
         --  target.  Keep it distinct from ordinary identifiers so
         --  expression recovery does not treat @ as a stray operator.
         Add_Production (Result, Production_Target_Name, Tok, "target name");
         Advance (Position);
      elsif To_String (Tok.Text) = "(" then
         Add_Production (Result, Production_Parenthesized_Expression, Tok, "parenthesized expression");
         Add_Production
           (Result, Production_Parenthesized_Expression_Open_Delimiter, Tok,
            "parenthesized expression open delimiter");
         Add_Production (Result, Production_Aggregate, Tok, "parenthesized expression or aggregate");
         Add_Production
           (Result, Production_Aggregate_Open_Delimiter, Tok,
            "aggregate or parenthesized expression open delimiter");
         Add_Production (Result, Production_Association_List, Tok, "parenthesized association list");
         Advance (Position);
         if Current_Lower (Position) = "for"
           and then (Lookahead_Lower (Position, 1) = "all"
                     or else Lookahead_Lower (Position, 1) = "some")
         then
            Parse_Expression (Position, Result);
         elsif Current_Lower (Position) = "for" then
            Parse_Component_Association_Item (Position, Result, Tok);
         elsif Current_Lower (Position) = "declare" then
            --  Ada 2022 declare expressions have a declarative part followed
            --  by a single body expression.  Treat this as an expression
            --  primary, not as a block statement, so expression recovery and
            --  nested declarations remain structurally visible to the language
            --  model.
            Add_Production (Result, Production_Declare_Expression, Current (Position), "declare expression");
            Advance (Position);
            if not At_End (Position)
              and then Current_Lower (Position) /= "begin"
              and then To_String (Current (Position).Text) /= ")"
            then
               Add_Production
                 (Result, Production_Declare_Expression_Declarative_Part,
                  Current (Position), "declare expression declarative part");
            end if;
            while not At_End (Position)
              and then Current_Lower (Position) /= "begin"
              and then To_String (Current (Position).Text) /= ")"
            loop
               Parse_Declaration_Or_Statement (Position, Result);
            end loop;
            if Current_Lower (Position) = "begin" then
               Add_Production
                 (Result, Production_Declare_Expression_Begin_Keyword,
                  Current (Position), "declare expression begin keyword");
               Advance (Position);
               if At_Declare_Expression_Body_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Declare_Expression_Missing_Body_Recovery_Boundary,
                     Current (Position),
                     "declare expression missing body recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected declare expression body expression");
               else
                  Add_Production
                    (Result, Production_Declare_Expression_Body_Expression,
                     Current (Position), "declare expression body expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Declare_Expression_Missing_Begin_Recovery_Boundary,
                  Tok, "declare expression missing begin recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected begin in declare expression");
            end if;
         elsif not At_End (Position) and then To_String (Current (Position).Text) /= ")" then
            if Has_Top_Level_With_Delta_Before_Association_End (Position) then
               Add_Production
                 (Result, Production_Delta_Aggregate_Base, Current (Position),
                  "delta aggregate base expression");
            elsif Has_Top_Level_With_Before_Association_End (Position) then
               Add_Production
                 (Result, Production_Extension_Aggregate_Ancestor,
                  Current (Position), "extension aggregate ancestor");
            end if;

            Parse_Component_Association_Item (Position, Result, Tok);

            if Current_Lower (Position) = "with" then
               if Lookahead_Lower (Position, 1) = "delta" then
                  Add_Production
                    (Result, Production_Delta_Aggregate_With_Keyword,
                     Current (Position), "delta aggregate with keyword");
                  Advance (Position);
                  Add_Production (Result, Production_Delta_Aggregate, Tok, "delta aggregate");
                  Add_Production
                    (Result, Production_Delta_Aggregate_Delta_Keyword,
                     Current (Position), "delta aggregate delta keyword");
                  Advance (Position);
                  Add_Production (Result, Production_Association_List, Current (Position), "delta associations");
                  if not At_End (Position)
                    and then (To_String (Current (Position).Text) = ")"
                              or else To_String (Current (Position).Text) = ";")
                  then
                     Add_Production
                       (Result, Production_Delta_Aggregate_Missing_Association_Recovery_Boundary,
                        Current (Position), "missing delta aggregate association");
                  end if;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) /= ")"
                    and then To_String (Current (Position).Text) /= ";"
                  loop
                     Add_Production
                       (Result, Production_Delta_Aggregate_Association,
                        Current (Position), "delta aggregate association");
                     Parse_Component_Association_Item (Position, Result, Tok);
                     if not At_End (Position)
                       and then To_String (Current (Position).Text) = ","
                     then
                        Add_Production
                          (Result, Production_Aggregate_Component_Separator,
                           Current (Position),
                           "delta aggregate association separator");
                        Add_Production
                          (Result, Production_Delta_Aggregate_Association_Separator,
                           Current (Position),
                           "delta aggregate association separator");
                     end if;
                     exit when not Match_Symbol (Position, ",");
                  end loop;
               else
                  Add_Production
                    (Result, Production_Extension_Aggregate_With_Keyword,
                     Current (Position), "extension aggregate with keyword");
                  Advance (Position);
                  Add_Production
                    (Result, Production_Extension_Aggregate, Tok,
                     "extension aggregate");
                  Add_Production
                    (Result, Production_Association_List, Current (Position),
                     "extension aggregate associations");
                  if Current_Lower (Position) = "null"
                    and then Lookahead_Lower (Position, 1) = "record"
                  then
                     Add_Production
                       (Result, Production_Null_Record_Aggregate,
                        Current (Position), "null record aggregate extension");
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Null_Keyword,
                        Current (Position), "null-record aggregate null keyword");
                     Advance (Position);
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Record_Keyword,
                        Current (Position), "null-record aggregate record keyword");
                     Advance (Position);
                  elsif Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Null_Record_Aggregate,
                        Current (Position), "null record aggregate extension");
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Null_Keyword,
                        Current (Position), "null-record aggregate null keyword");
                     Add_Production
                       (Result,
                        Production_Null_Record_Aggregate_Missing_Record_Recovery_Boundary,
                        Current (Position),
                        "missing record keyword in null-record aggregate");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected record in null-record aggregate");
                     Advance (Position);
                  else
                     if not At_End (Position)
                       and then (To_String (Current (Position).Text) = ")"
                                 or else To_String (Current (Position).Text) = ";")
                     then
                        Add_Production
                          (Result,
                           Production_Extension_Aggregate_Missing_Association_Recovery_Boundary,
                           Current (Position),
                           "missing extension aggregate association");
                     end if;
                     while not At_End (Position)
                       and then To_String (Current (Position).Text) /= ")"
                       and then To_String (Current (Position).Text) /= ";"
                     loop
                        Add_Production
                          (Result,
                           Production_Extension_Aggregate_Component_Association,
                           Current (Position),
                           "extension aggregate component association");
                        Parse_Component_Association_Item (Position, Result, Tok);
                        if not At_End (Position)
                          and then To_String (Current (Position).Text) = ","
                        then
                           Add_Production
                             (Result, Production_Aggregate_Component_Separator,
                              Current (Position),
                              "extension aggregate component separator");
                           Add_Production
                             (Result,
                              Production_Extension_Aggregate_Component_Separator,
                              Current (Position),
                              "extension aggregate component separator");
                        end if;
                        exit when not Match_Symbol (Position, ",");
                     end loop;
                  end if;
               end if;
            else
               while not At_End (Position)
                 and then To_String (Current (Position).Text) = ","
               loop
                  Add_Production
                    (Result, Production_Aggregate_Component_Separator,
                     Current (Position), "aggregate component separator");
                  Advance (Position);
                  Parse_Component_Association_Item (Position, Result, Tok);
               end loop;
            end if;
         end if;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
            Add_Production
              (Result, Production_Aggregate_Close_Delimiter, Current (Position),
               "aggregate or parenthesized expression close delimiter");
            Add_Production
              (Result, Production_Parenthesized_Expression_Close_Delimiter,
               Current (Position),
               "parenthesized expression close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Aggregate_Missing_Close_Recovery_Boundary,
               Tok, "missing aggregate or parenthesized expression close delimiter");
            Add_Production
              (Result, Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary,
               Tok, "missing parenthesized expression close delimiter");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in primary");
         end if;
      else
         declare
            Saw_Selected_Subtype_Mark           : Boolean := False;
            Saw_Selected_Literal_Subtype_Mark   : Boolean := False;
            Saw_Selected_Operator_Subtype_Mark  : Boolean := False;
            Saw_Selected_Character_Subtype_Mark : Boolean := False;
         begin
            if Tok.Kind = Token_Identifier or else Tok.Kind = Token_Keyword then
               Add_Production (Result, Production_Name, Tok, To_String (Tok.Text));
            end if;
            Advance (Position);
            loop
               exit when At_End (Position);
               if To_String (Current (Position).Text) = "." then
                  Saw_Selected_Subtype_Mark := True;
                  if Lookahead_Kind (Position, 1) = Token_String_Literal then
                     Saw_Selected_Literal_Subtype_Mark := True;
                     Saw_Selected_Operator_Subtype_Mark := True;
                  elsif Lookahead_Kind (Position, 1) = Token_Character_Literal then
                     Saw_Selected_Literal_Subtype_Mark := True;
                     Saw_Selected_Character_Subtype_Mark := True;
                  elsif Lookahead_Kind (Position, 1) /= Token_Identifier
                    and then Lookahead_Kind (Position, 1) /= Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark,
                        Tok, "qualified-expression incomplete selected subtype mark");
                  end if;
                  Parse_Selected_Name_Suffix
                    (Position, Result, Tok, "selected name");
               elsif To_String (Current (Position).Text) = "'" then
                  if Lookahead_Lower (Position, 1) = "(" then
                     Add_Production (Result, Production_Qualified_Expression, Tok, To_String (Tok.Text));
                     Add_Production
                       (Result, Production_Conversion_Or_Qualified_Expression,
                        Tok, "qualified expression or conversion context");
                     Add_Production
                       (Result, Production_Qualified_Expression_Subtype_Mark,
                        Tok, "qualified-expression subtype mark");
                     if Saw_Selected_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Subtype_Mark,
                           Tok, "qualified-expression selected subtype mark");
                     end if;
                     if Saw_Selected_Literal_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Literal_Subtype_Mark,
                           Tok, "qualified-expression selected literal subtype mark");
                     end if;
                     if Saw_Selected_Operator_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Operator_Subtype_Mark,
                           Tok, "qualified-expression selected operator subtype mark");
                     end if;
                     if Saw_Selected_Character_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Character_Subtype_Mark,
                           Tok, "qualified-expression selected character subtype mark");
                     end if;
                     Add_Production
                       (Result, Production_Qualified_Expression_Apostrophe,
                        Current (Position), "qualified-expression apostrophe");
                     Advance (Position);
                     if To_String (Current (Position).Text) = "(" then
                        Add_Production
                          (Result, Production_Qualified_Expression_Operand,
                           Current (Position), "qualified-expression operand");
                        if Qualified_Operand_Is_Missing (Position) then
                           Add_Production
                             (Result, Production_Qualified_Expression_Missing_Operand_Recovery_Boundary,
                              Current (Position), "qualified-expression missing operand recovery boundary");
                           Add_Production
                             (Result, Production_Recovery_Point, Current (Position),
                              "expected qualified-expression operand before boundary");
                        end if;
                     end if;
                     Parse_Association_List (Position, Result, Qualified_Expression_Operand => True);
                  else
                  if Saw_Selected_Subtype_Mark then
                     Add_Production
                       (Result, Production_Attribute_Selected_Prefix, Tok,
                        "attribute reference with selected-name prefix");
                     Add_Production
                       (Result, Production_Attribute_Complex_Prefix, Tok,
                        "attribute reference with complex prefix");
                  end if;
                  Add_Production
                    (Result, Production_Chained_Attribute_Reference, Tok,
                     "chained attribute reference");
                  Add_Production (Result, Production_Attribute_Reference, Tok, To_String (Tok.Text));
                  Advance (Position);
                  if not At_End (Position) then
                     declare
                        Attribute_Name : constant String := Current_Lower (Position);
                     begin
                        Add_Production
                          (Result, Production_Attribute_Designator_Name,
                           Current (Position), To_String (Current (Position).Text));
                        if Attribute_Name = "range" then
                           Add_Production
                             (Result, Production_Range_Attribute_Reference,
                              Tok, "range attribute reference");
                           Add_Production
                             (Result, Production_Range_Attribute_Prefix,
                              Tok, "range attribute prefix");
                        end if;
                        if Attribute_Name = "class"
                          and then Lookahead_Lower (Position, 1) = "'"
                        then
                           Add_Production
                             (Result, Production_Classwide_Attribute_Reference,
                              Tok, "class-wide attribute reference");
                        end if;
                        if Attribute_Name = "reduce"
                          or else Attribute_Name = "parallel_reduce"
                          or else Attribute_Name = "map_reduce"
                        then
                           Add_Production
                             (Result, Production_Reduction_Expression, Tok,
                              Attribute_Name);
                           if Attribute_Name = "parallel_reduce" then
                              Add_Production
                                (Result, Production_Parallel_Reduction_Expression, Tok,
                                 Attribute_Name);
                           elsif Attribute_Name = "map_reduce" then
                              Add_Production
                                (Result, Production_Map_Reduction_Expression, Tok,
                                 Attribute_Name);
                           end if;
                           Advance (Position);
                           if To_String (Current (Position).Text) = "(" then
                              Parse_Reduction_Argument_Part
                                (Position, Result, Tok, Attribute_Name);
                           end if;
                        else
                           Advance (Position);
                           if To_String (Current (Position).Text) = "(" then
                              --  Ada attribute references can carry an optional
                              --  argument association part, for example
                              --  ``A'First (1)`` and Ada 2022 image-style
                              --  attribute calls.  Keep those parentheses
                              --  attached to the attribute reference rather than
                              --  letting the name-suffix loop misclassify them as
                              --  an ordinary indexed component of the attribute
                              --  result.
                              Parse_Attribute_Argument_List
                                (Position, Result, Tok,
                                 "attribute argument part");
                           end if;
                        end if;
                     end;
                  end if;
               end if;
            elsif To_String (Current (Position).Text) = "(" then
               if Parenthesized_Name_Suffix_Is_Slice (Position) then
                  Add_Production (Result, Production_Slice, Tok, To_String (Tok.Text));
               else
                  Add_Production
                    (Result, Production_Call_Or_Indexed_Component, Tok,
                     "call or indexed component suffix");
                  Add_Production (Result, Production_Indexed_Component, Tok, To_String (Tok.Text));
               end if;
               Parse_Association_List (Position, Result);
               else
                  exit;
               end if;
            end loop;
         end;
      end if;
   end Parse_Primary;
