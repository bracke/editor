with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;

with Editor.Ada_Token_Cursor.Aggregate_Parsing;
with Editor.Ada_Token_Cursor.Constraint_Parsing;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Parsing_Phases;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor;
use Editor.Ada_Token_Cursor;
use Editor.Ada_Token_Cursor.Range_Structure_Helpers;

package body Editor.Ada_Token_Cursor.Primary_Parsing is
   use Editor.Ada_Token_Cursor.Constraint_Parsing;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Type_Parsing;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   procedure Parse_Primary
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Parsing_Phases.Parse_Primary;

   function Current_Lower (Position : Cursor) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower;

   function Lookahead_Lower
     (Position : Cursor;
      Offset   : Natural) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower;

   function Lookahead_Kind
     (Position : Cursor;
      Offset   : Natural) return Token_Kind
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Kind;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Selected_Name_Suffix
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String)
     renames Editor.Ada_Token_Cursor.Selected_Name_Parsing.Parse_Selected_Name_Suffix;

   procedure Parse_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Expression;

   procedure Parse_Discrete_Choice_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Discrete_Choice_List;

   procedure Parse_Discriminant_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Discriminant_Constraint;

   procedure Parse_Index_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Index_Constraint;

   procedure Skip_Balanced_To
     (Position : in out Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "")
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To;

   function Parenthesized_Constraint_Has_Arrow
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Range_Structure_Helpers.Parenthesized_Constraint_Has_Arrow;

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Cursor) return Boolean is
   begin
      return Editor.Ada_Token_Cursor.Range_Structure_Helpers.
        Has_Top_Level_Arrow_Before_Association_End (Position);
   end Has_Top_Level_Arrow_Before_Association_End;

   function Qualified_Subtype_Mark_Has_Selected_Prefix
     (Start : Cursor) return Boolean is
      Probe        : Cursor := Start;
      Saw_Selector : Boolean := False;
   begin
      if At_End (Probe) then
         return False;
      end if;

      if Current_Lower (Probe) = "not" then
         Advance (Probe);
         if At_End (Probe) then
            return False;
         elsif Current_Lower (Probe) = "null" then
            Advance (Probe);
         end if;
      end if;

      loop
         exit when At_End (Probe);

         if To_String (Current (Probe).Text) = "'" then
            return Lookahead_Lower (Probe, 1) = "(" and then Saw_Selector;
         elsif To_String (Current (Probe).Text) = "." then
            Saw_Selector := True;
            Advance (Probe);
            if At_End (Probe) then
               return Saw_Selector;
            elsif Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
              or else Current (Probe).Kind = Token_String_Literal
              or else Current (Probe).Kind = Token_Character_Literal
            then
               Advance (Probe);
            else
               return Saw_Selector;
            end if;
         elsif Current (Probe).Kind = Token_Identifier
           or else Current (Probe).Kind = Token_Keyword
           or else Current (Probe).Kind = Token_String_Literal
           or else Current (Probe).Kind = Token_Character_Literal
         then
            Advance (Probe);
         else
            return False;
         end if;
      end loop;

      return False;
   end Qualified_Subtype_Mark_Has_Selected_Prefix;

   procedure Parse_Allocator_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production
        (Result, Production_Subtype_Indication, Tok,
         To_String (Tok.Text));

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
      then
         Add_Production
           (Result, Production_Allocator_Null_Exclusion, Current (Position),
            "allocator null exclusion");
      end if;

      Parse_Null_Exclusion (Position, Result);

      if Current_Lower (Position) = "access" then
         Add_Production
           (Result, Production_Allocator_Access_Subtype, Current (Position),
            "allocator access subtype indication");
         Parse_Access_Type_Definition (Position, Result);
      elsif Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         declare
            Name_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Name, Name_Tok,
               To_String (Name_Tok.Text));
            Add_Production
              (Result, Production_Allocator_Subtype_Mark, Name_Tok,
               To_String (Name_Tok.Text));
            Advance (Position);

            loop
               exit when At_End (Position);
               if To_String (Current (Position).Text) = "." then
                  if Lookahead_Kind (Position, 1) = Token_String_Literal then
                     Add_Production
                       (Result, Production_Allocator_Selected_Literal_Subtype_Mark,
                        Name_Tok, "allocator selected literal subtype mark");
                     Add_Production
                       (Result, Production_Allocator_Selected_Operator_Subtype_Mark,
                        Name_Tok, "allocator selected operator subtype mark");
                  elsif Lookahead_Kind (Position, 1) = Token_Character_Literal then
                     Add_Production
                       (Result, Production_Allocator_Selected_Literal_Subtype_Mark,
                        Name_Tok, "allocator selected literal subtype mark");
                     Add_Production
                       (Result, Production_Allocator_Selected_Character_Subtype_Mark,
                        Name_Tok, "allocator selected character subtype mark");
                  elsif Lookahead_Kind (Position, 1) /= Token_Identifier
                    and then Lookahead_Kind (Position, 1) /= Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Allocator_Incomplete_Selected_Subtype_Mark,
                        Name_Tok, "allocator incomplete selected subtype mark");
                  end if;
                  Parse_Selected_Name_Suffix
                    (Position, Result, Name_Tok,
                     "allocator subtype indication");
               elsif To_String (Current (Position).Text) = "'" then
                  --  In an allocator, ``Subtype_Mark'(...)`` starts the
                  --  qualified-expression form and must not be consumed as an
                  --  attribute-style subtype mark.  Other subtype attributes
                  --  such as T'Class/T'Base remain part of the subtype mark.
                  exit when Lookahead_Lower (Position, 1) = "(";
                  Add_Production
                    (Result, Production_Attribute_Reference, Name_Tok,
                     To_String (Name_Tok.Text));
                  Advance (Position);
                  if not At_End (Position) then
                     Advance (Position);
                  end if;
               else
                  exit;
               end if;
            end loop;
         end;
      else
         Parse_Expression (Position, Result);
      end if;

      if Current_Lower (Position) = "range" then
         Add_Production
           (Result, Production_Allocator_Range_Constraint, Current (Position),
            "allocator range constraint");
         Add_Production
           (Result, Production_Subtype_Range_Constraint, Current (Position),
            "subtype range constraint");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production
           (Result, Production_Allocator_Digits_Constraint, Current (Position),
            "allocator digits constraint");
         Add_Production
           (Result, Production_Subtype_Digits_Constraint, Current (Position),
            "subtype digits constraint");
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "delta" then
         Add_Production
           (Result, Production_Allocator_Delta_Constraint, Current (Position),
            "allocator delta constraint");
         Add_Production
           (Result, Production_Subtype_Delta_Constraint, Current (Position),
            "subtype delta constraint");
         Parse_Delta_Constraint (Position, Result);
      elsif To_String (Current (Position).Text) = "(" then
         if Parenthesized_Constraint_Has_Arrow (Position) then
            Add_Production
              (Result, Production_Allocator_Discriminant_Constraint,
               Current (Position), "allocator discriminant constraint");
            Add_Production
              (Result, Production_Subtype_Discriminant_Constraint,
               Current (Position), "subtype discriminant constraint");
            Parse_Discriminant_Constraint (Position, Result);
         else
            Add_Production
              (Result, Production_Allocator_Index_Constraint, Current (Position),
               "allocator index constraint");
            Add_Production
              (Result, Production_Subtype_Index_Constraint, Current (Position),
               "subtype index constraint");
            Parse_Index_Constraint (Position, Result);
         end if;
      end if;
   end Parse_Allocator_Subtype_Indication;

   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String) is
      Tok : constant Token_Info := Current (Position);
      Is_Parallel  : constant Boolean := Lower (Attribute_Name) = "parallel_reduce";

      function At_Reduction_Argument_Boundary
        (Position : Cursor) return Boolean is
         T : constant String :=
           (if At_End (Position) then "" else To_String (Current (Position).Text));
         L : constant String :=
           (if At_End (Position) then "" else Current_Lower (Position));
      begin
         return At_End (Position)
           or else T = ")"
           or else T = ","
           or else T = ";"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "loop"
           or else L = "is"
           or else L = "begin"
           or else L = "end";
      end At_Reduction_Argument_Boundary;
   begin
      --  Ada 2022 reduction attributes have a structured argument part:
      --     Prefix'Reduce (Reducer, Initial_Value)
      --     Prefix'Parallel_Reduce (Reducer, Initial_Value)
      --  Keep the reducer and initial-value positions visible to semantic
      --  consumers instead of flattening the whole parenthesized list into a
      --  generic association list.  This is syntactic only; callable profile
      --  conformance and parallel execution legality remain outside the editor
      --  grammar layer.
      Add_Production
        (Result, Production_Attribute_Argument_Part, Tok,
         "reduction attribute argument part");

      if not At_End (Position) and then To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Open_Delimiter,
            Current (Position), "reduction attribute argument-list open delimiter");
      end if;

      if not Match_Symbol (Position, "(") then
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected reduction argument part");
         return;
      end if;

      if At_Reduction_Argument_Boundary (Position) then
         Add_Production
           (Result, Production_Reduction_Missing_Reducer_Recovery_Boundary, Origin,
            "missing reduction reducer");
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "missing reduction reducer");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "missing reduction reducer");
      else
         Add_Production
           (Result, Production_Attribute_Argument_Association, Current (Position),
            "reduction attribute argument association");
         Add_Production
           (Result, Production_Attribute_Argument_Expression, Current (Position),
            "reduction attribute argument expression");
         Add_Production
           (Result, Production_Reduction_Reducer, Current (Position),
            "reduction reducer");
         Parse_Expression (Position, Result);
      end if;

      if not At_End (Position) and then To_String (Current (Position).Text) = "," then
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "reduction attribute argument association separator");
      end if;

      if Match_Symbol (Position, ",") then
         if At_Reduction_Argument_Boundary (Position) then
            Add_Production
              (Result, Production_Reduction_Missing_Initial_Value_Recovery_Boundary,
               Origin, "missing reduction initial value");
            if Is_Parallel then
               Add_Production
                 (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
                  Origin, "missing parallel reduction initial value");
            end if;
            if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Reduction_Trailing_Separator_Recovery_Boundary,
                  Origin, "trailing reduction argument separator");
            end if;
            Add_Production
              (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
               "missing reduction initial value");
            Add_Production
              (Result, Production_Recovery_Point, Origin,
               "missing reduction initial value");
         else
            Add_Production
              (Result, Production_Attribute_Argument_Association, Current (Position),
               "reduction attribute argument association");
            Add_Production
              (Result, Production_Attribute_Argument_Expression, Current (Position),
               "reduction attribute argument expression");
            Add_Production
              (Result, Production_Reduction_Initial_Value, Current (Position),
               "reduction initial value");
            Parse_Expression (Position, Result);
         end if;
      else
         Add_Production
           (Result, Production_Reduction_Missing_Initial_Value_Recovery_Boundary,
            Origin, "expected initial value in reduction argument part");
         if Is_Parallel then
            Add_Production
              (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
               Origin, "expected initial value in parallel reduction argument part");
         end if;
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected initial value in reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected initial value in reduction argument part");
      end if;

      while not At_End (Position) and then To_String (Current (Position).Text) = "," loop
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "reduction attribute argument association separator");
         Advance (Position);
         --  Retain additional implementation-defined or future reduction
         --  parameters as bounded expression nodes while still preserving the
         --  canonical reducer/initial-value pair above.
         if At_Reduction_Argument_Boundary (Position) then
            Add_Production
              (Result, Production_Reduction_Trailing_Separator_Recovery_Boundary,
               Origin, "trailing reduction argument separator");
            if Is_Parallel then
               Add_Production
                 (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
                  Origin, "trailing parallel reduction argument separator");
            end if;
            Add_Production
              (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
               "trailing reduction argument separator");
            Add_Production
              (Result, Production_Recovery_Point, Origin,
               "trailing reduction argument separator");
            exit;
         else
            Parse_Expression (Position, Result);
         end if;
      end loop;

      if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Close_Delimiter,
            Current (Position), "reduction attribute argument-list close delimiter");
      end if;

      if not Match_Symbol (Position, ")") then
         Add_Production
           (Result, Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "expected ) in reduction attribute argument part");
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected ) in reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected ) in reduction argument part");
      end if;
   end Parse_Reduction_Argument_Part;

   procedure Parse_Attribute_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Attribute_Argument_Part, Tok, Label);

      if not At_End (Position) and then To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Open_Delimiter,
            Current (Position), "attribute argument-list open delimiter");
      end if;

      if not Match_Symbol (Position, "(") then
         Add_Production
           (Result, Production_Attribute_Recovery_Boundary, Origin,
            "expected attribute argument list");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected attribute argument list");
         return;
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Assoc_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Attribute_Argument_Association, Assoc_Tok,
               "attribute argument association");

            if Has_Top_Level_Arrow_Before_Association_End (Position) then
               Parse_Discrete_Choice_List (Position, Result, "=>");
               if Match_Symbol (Position, "=>") then
                  if At_End (Position)
                    or else To_String (Current (Position).Text) = ")"
                    or else To_String (Current (Position).Text) = ","
                    or else To_String (Current (Position).Text) = ";"
                  then
                     Add_Production
                       (Result, Production_Attribute_Recovery_Boundary,
                        Assoc_Tok,
                        "missing attribute argument expression");
                     Add_Production
                       (Result, Production_Recovery_Point, Assoc_Tok,
                        "expected attribute argument expression");
                  else
                     Add_Production
                       (Result, Production_Attribute_Argument_Expression,
                        Current (Position), "attribute argument expression");
                     Parse_Expression (Position, Result);
                  end if;
               else
                  Add_Production
                    (Result, Production_Attribute_Recovery_Boundary, Assoc_Tok,
                     "expected => in attribute argument association");
                  Add_Production
                    (Result, Production_Recovery_Point, Assoc_Tok,
                     "expected => in attribute argument association");
                  Skip_Balanced_To (Position, ",", ")", ";");
               end if;
            else
               Add_Production
                 (Result, Production_Attribute_Argument_Expression,
                  Current (Position), "attribute argument expression");
               Parse_Expression (Position, Result);
            end if;
         end;

         exit when To_String (Current (Position).Text) /= ",";
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "attribute argument association separator");
         Advance (Position);
      end loop;

      if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Close_Delimiter,
            Current (Position), "attribute argument-list close delimiter");
      end if;

      if not Match_Symbol (Position, ")") then
         Add_Production
           (Result, Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "expected ) in attribute argument list");
         Add_Production
           (Result, Production_Attribute_Recovery_Boundary, Tok,
            "expected ) in attribute argument list");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in attribute argument list");
      end if;
   end Parse_Attribute_Argument_List;

   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Cursor;
      Result                 : in out Grammar_Result;
      Origin                 : Token_Info;
      Selected_Production    : Production_Kind;
      Recovery_Production    : Production_Kind;
      Label                  : String) is
      Probe : Cursor := Position;
      Saw_Name : Boolean := False;
      Saw_Selector : Boolean := False;
   begin
      --  Raise statements/expressions name exceptions with Ada names, not
      --  arbitrary statements.  Keep selected exception names visible for
      --  colouring and resolver hints, but keep this bounded and syntactic:
      --  exception resolution remains outside the token cursor.
      if At_End (Probe)
        or else To_String (Current (Probe).Text) = ";"
        or else To_String (Current (Probe).Text) = ")"
        or else Current_Lower (Probe) = "with"
      then
         Add_Production
           (Result, Recovery_Production, Origin,
            "missing " & Label);
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "missing " & Label);
         return;
      end if;

      if Current (Probe).Kind = Token_Identifier
        or else Current (Probe).Kind = Token_Keyword
      then
         Saw_Name := True;
         Advance (Probe);
      end if;

      while not At_End (Probe) loop
         exit when To_String (Current (Probe).Text) = ";";
         exit when To_String (Current (Probe).Text) = ")";
         exit when Current_Lower (Probe) = "with";

         if To_String (Current (Probe).Text) = "."
         then
            Saw_Selector := True;
            Advance (Probe);
            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
              or else Current (Probe).Kind = Token_String_Literal
              or else Current (Probe).Kind = Token_Character_Literal
            then
               Advance (Probe);
            else
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if Saw_Name and then Saw_Selector then
         Add_Production
           (Result, Selected_Production, Current (Position),
            "selected " & Label);
      end if;
   end Mark_Raise_Exception_Target_Shape;

end Editor.Ada_Token_Cursor.Primary_Parsing;
