with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Aggregate_Parsing is

   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;
   use Editor.Ada_Token_Cursor.Range_Structure_Helpers;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Iterated_Component_Association
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Ada aggregate iterated component associations use a leading ``for``
      --  but are not quantified expressions: they have no ``all``/``some``
      --  quantifier and their domain belongs to an aggregate association.
      --  Keep a distinct production so aggregate grammar does not regress into
      --  the quantified-expression recovery path.
      Add_Production
        (Result, Production_Iterated_Component_Association, Tok,
         "iterated component association");

      if Current_Lower (Position) = "for" then
         Advance (Position);
      end if;

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Defining_Name, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
      end if;

      if Current_Lower (Position) = "in" then
         Add_Production
           (Result, Production_Loop_Parameter_Specification, Tok,
            "aggregate loop parameter specification");
         Advance (Position);
      elsif Current_Lower (Position) = "of" then
         Add_Production
           (Result, Production_Iterator_Specification, Tok,
            "aggregate iterator specification");
         Advance (Position);
      end if;

      if Current_Lower (Position) = "reverse" then
         Advance (Position);
      end if;

      --  Keep the iteration domain structural instead of skipping directly to
      --  the association arrow.  This preserves discrete ranges, container
      --  names, subtype ranges, and optional iterator filters for outline and
      --  semantic-colouring consumers while retaining bounded recovery.
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= "=>"
        and then Current_Lower (Position) /= "when"
      then
         declare
            Domain_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Domain, Domain_Tok,
               "iterated component association domain");
            Parse_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component discrete range");
               Parse_Expression (Position, Result);
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component subtype range");
               Advance (Position);
               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Box_Expression, Current (Position),
                     "iterated component box range");
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
           (Result, Production_Iterated_Component_Missing_Domain_Recovery_Boundary,
            Current (Position),
            "missing domain in iterated component association");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected iterated component association domain");
      end if;

      if Match_Keyword (Position, "when") then
         Add_Production
           (Result, Production_Iterated_Component_Iterator_Filter,
            Current (Position), "iterated component iterator filter");
         if At_Iterator_Filter_Condition_Boundary (Position) then
            Add_Production
              (Result,
               Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary,
               Current (Position),
               "missing iterated component iterator filter condition");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected iterated component iterator filter condition");
         else
            Parse_Expression (Position, Result);
         end if;
      end if;

      if To_String (Current (Position).Text) = "=>" then
         declare
            Arrow_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Association_Arrow,
               Arrow_Tok, "iterated component association arrow");
            Advance (Position);
            if At_Iterated_Component_Expression_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Iterated_Component_Missing_Expression_Recovery_Boundary,
                  Current (Position),
                  "missing iterated component expression recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected iterated component expression");
            else
               Add_Production
                 (Result, Production_Iterated_Component_Expression,
                  Current (Position), "iterated component expression");
               Parse_Expression (Position, Result);
            end if;
         end;
      else
         Add_Production
           (Result, Production_Iterated_Component_Missing_Arrow_Recovery_Boundary,
            Current (Position),
            "missing => in iterated component association");
      end if;
   end Parse_Iterated_Component_Association;

   procedure Add_Aggregate_Choice_Depth
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe        : Cursor := Position;
      Choice_Start : Token_Info := Current (Position);
      Depth        : Natural := 0;
      Saw_Range    : Boolean := False;

      procedure Emit_Choice is
      begin
         if To_String (Choice_Start.Text) /= "=>" then
            Add_Production
              (Result, Production_Aggregate_Index_Choice, Choice_Start,
               "aggregate index or component choice");
            if Saw_Range then
               Add_Production
                 (Result, Production_Aggregate_Range_Choice, Choice_Start,
                  "aggregate range choice");
            end if;
         end if;
      end Emit_Choice;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               exit when Depth = 0;
               Depth := Depth - 1;
            elsif Depth = 0 and then T = "=>" then
               Emit_Choice;
               exit;
            elsif Depth = 0 and then T = "|" then
               Emit_Choice;
               Choice_Start := Token_At (Probe.Stream, Probe.Index + 1);
               Saw_Range := False;
            elsif Depth = 0 and then T = ".." then
               Saw_Range := True;
            end if;
         end;
         Advance (Probe);
      end loop;
   end Add_Aggregate_Choice_Depth;

   procedure Parse_Component_Association_Item
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info) is
      Assoc_Tok : constant Token_Info := Current (Position);
   begin
      if Current_Lower (Position) = "for" then
         Add_Production
           (Result, Production_Component_Association, Assoc_Tok,
            "iterated component association item");
         Parse_Iterated_Component_Association (Position, Result);
      elsif Has_Top_Level_Arrow_Before_Association_End (Position) then
         Add_Production
           (Result, Production_Component_Association, Assoc_Tok,
            To_String (Assoc_Tok.Text));
         Add_Production
           (Result, Production_Aggregate_Named_Component_Association,
            Assoc_Tok, "aggregate named component association");
         Add_Production
           (Result, Production_Aggregate_Component_Choice_List,
            Assoc_Tok, "aggregate component choice list");
         Add_Aggregate_Choice_Depth (Position, Result);
         if Current_Lower (Position) = "others" then
            Add_Production
              (Result, Production_Aggregate_Others_Choice,
               Current (Position), "aggregate others choice");
         end if;
         Parse_Discrete_Choice_List (Position, Result, "=>");
         if Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Aggregate_Component_Arrow,
               Current (Position), "aggregate component association arrow");
            if To_String (Current (Position).Text) = ","
              or else To_String (Current (Position).Text) = ")"
            then
               Add_Production
                 (Result, Production_Aggregate_Recovery_Boundary,
                  Assoc_Tok, "missing aggregate component expression");
               Add_Production
                 (Result, Production_Recovery_Point, Assoc_Tok,
                  "expected aggregate component expression");
            elsif At_Aggregate_Component_Expression_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "aggregate component expression reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Aggregate_Recovery_Boundary,
                  Assoc_Tok, "missing aggregate component expression");
               Add_Production
                 (Result, Production_Recovery_Point, Assoc_Tok,
                  "expected aggregate component expression before boundary");
            elsif To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Aggregate_Box_Component,
                  Current (Position), "aggregate box component value");
               Parse_Expression (Position, Result);
            elsif Current_Lower (Position) = "for" then
               Parse_Iterated_Component_Association (Position, Result);
            else
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Aggregate_Recovery_Boundary, Assoc_Tok,
               "expected => in aggregate component association");
            Add_Production
              (Result, Production_Recovery_Point, Assoc_Tok,
               "expected => in component association");
         end if;
      else
         Add_Production
           (Result, Production_Aggregate_Positional_Component, Assoc_Tok,
            "aggregate positional component");
         if To_String (Current (Position).Text) = "<>" then
            Add_Production
              (Result, Production_Aggregate_Box_Component,
               Current (Position), "aggregate positional box component");
         end if;
         Parse_Expression (Position, Result);
         if Match_Symbol (Position, "..") then
            Add_Production
              (Result, Production_Range_Expression, Origin,
               "range expression");
            Parse_Expression (Position, Result);
         elsif Current_Lower (Position) = "range" then
            Add_Production
              (Result, Production_Range_Expression, Origin,
               "range attribute slice");
            Advance (Position);
         end if;
      end if;
   end Parse_Component_Association_Item;

   procedure Parse_Association_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Qualified_Expression_Operand : Boolean := False) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Association_List, Tok, "association list");
      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Aggregate_Open_Delimiter, Current (Position),
            "association list open delimiter");
         if Qualified_Expression_Operand then
            Add_Production
              (Result, Production_Qualified_Expression_Operand_Open_Delimiter,
               Current (Position), "qualified-expression operand open delimiter");
         end if;
         Advance (Position);
         while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
            declare
               Assoc_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Component_Association, Assoc_Tok,
                  To_String (Assoc_Tok.Text));

               if Current_Lower (Position) = "for" then
                  Parse_Iterated_Component_Association (Position, Result);
               elsif Has_Top_Level_Arrow_Before_Association_End (Position) then
                  Add_Production
                    (Result, Production_Aggregate_Named_Component_Association,
                     Assoc_Tok, "aggregate named component association");
                  Add_Production
                    (Result, Production_Aggregate_Component_Choice_List,
                     Assoc_Tok, "aggregate component choice list");
                  Add_Aggregate_Choice_Depth (Position, Result);
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Aggregate_Others_Choice,
                        Current (Position), "aggregate others choice");
                  end if;
                  Parse_Discrete_Choice_List (Position, Result, "=>");
                  if Match_Symbol (Position, "=>") then
                     Add_Production
                       (Result, Production_Aggregate_Component_Arrow,
                        Current (Position), "aggregate component association arrow");
                     if To_String (Current (Position).Text) = ","
                       or else To_String (Current (Position).Text) = ")"
                     then
                        Add_Production
                          (Result, Production_Aggregate_Recovery_Boundary,
                           Assoc_Tok, "missing aggregate component expression");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected aggregate component expression");
                     elsif At_Aggregate_Component_Expression_Boundary (Position) then
                        Add_Production
                          (Result,
                           Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary,
                           Current (Position),
                           "aggregate component expression reserved-boundary recovery boundary");
                        Add_Production
                          (Result, Production_Aggregate_Recovery_Boundary,
                           Assoc_Tok, "missing aggregate component expression");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected aggregate component expression before boundary");
                     elsif To_String (Current (Position).Text) = "<>" then
                        Add_Production
                          (Result, Production_Aggregate_Box_Component,
                           Current (Position), "aggregate box component value");
                        Parse_Expression (Position, Result);
                     elsif Current_Lower (Position) = "for" then
                        Parse_Iterated_Component_Association (Position, Result);
                     else
                        Parse_Expression (Position, Result);
                     end if;
                  else
                     Add_Production
                       (Result, Production_Aggregate_Recovery_Boundary,
                        Assoc_Tok, "expected => in aggregate component association");
                     Add_Production
                       (Result, Production_Recovery_Point, Assoc_Tok,
                        "expected => in component association");
                  end if;
               else
                  Add_Production
                    (Result, Production_Aggregate_Positional_Component,
                     Assoc_Tok, "aggregate positional component");
                  if To_String (Current (Position).Text) = "<>" then
                     Add_Production
                       (Result, Production_Aggregate_Box_Component,
                        Current (Position), "aggregate positional box component");
                  end if;
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production (Result, Production_Range_Expression, Tok, "range expression");
                     Parse_Expression (Position, Result);
                  elsif Current_Lower (Position) = "range" then
                     Add_Production (Result, Production_Range_Expression, Tok, "range attribute slice");
                     Advance (Position);
                  end if;
               end if;
            end;
            if not At_End (Position)
              and then To_String (Current (Position).Text) = ","
            then
               Add_Production
                 (Result, Production_Aggregate_Component_Separator,
                  Current (Position), "association list component separator");
            end if;
            exit when not Match_Symbol (Position, ",");
         end loop;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
            Add_Production
              (Result, Production_Aggregate_Close_Delimiter, Current (Position),
               "association list close delimiter");
            if Qualified_Expression_Operand then
               Add_Production
                 (Result, Production_Qualified_Expression_Operand_Close_Delimiter,
                  Current (Position), "qualified-expression operand close delimiter");
            end if;
            Advance (Position);
         else
            Add_Production
              (Result, Production_Aggregate_Missing_Close_Recovery_Boundary,
               Tok, "missing association list close delimiter");
            if Qualified_Expression_Operand then
               Add_Production
                 (Result, Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary,
                  Tok, "missing qualified-expression operand close delimiter");
            end if;
            Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in association list");
         end if;
      end if;
   end Parse_Association_List;

end Editor.Ada_Token_Cursor.Aggregate_Parsing;
