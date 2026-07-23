with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;


with Editor.Ada_Token_Cursor.Parsing_Predicates;

with Editor.Ada_Token_Cursor.Range_Structure_Helpers;

with Editor.Ada_Token_Cursor.Constraint_Parsing;

with Editor.Ada_Token_Cursor.Contracts;
package body Editor.Ada_Token_Cursor.Type_Parsing is

   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;

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

   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Range_Constraint;

   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Digits_Constraint;

   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Delta_Constraint;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Null_Exclusion;

   function Parenthesized_Constraint_Has_Arrow
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Range_Structure_Helpers.Parenthesized_Constraint_Has_Arrow;

   function Has_Top_Level_Arrow_Before_Constraint_Association_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Range_Structure_Helpers.Has_Top_Level_Arrow_Before_Constraint_Association_End;

   function Has_Top_Level_With_Before_Association_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Parsing_Predicates.Has_Top_Level_With_Before_Association_End;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Parsing_Predicates.Has_Top_Level_With_Delta_Before_Association_End;

   function At_Profile_Item_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Item_End;

   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Default_Reserved_Boundary;

   function Access_Subprogram_Result_Has_Constraint
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.Access_Subprogram_Result_Has_Constraint;

   procedure Parse_Subtype_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      if Tok.Kind = Token_Identifier or else Tok.Kind = Token_Keyword then
         Add_Production (Result, Production_Subtype_Mark, Tok, "subtype mark");
         Add_Production (Result, Production_Name, Tok, To_String (Tok.Text));
         Advance (Position);
      else
         Parse_Expression (Position, Result);
         return;
      end if;

      loop
         exit when At_End (Position);
         if To_String (Current (Position).Text) = "." then
            Parse_Selected_Name_Suffix
              (Position, Result, Tok, "subtype mark");
         elsif To_String (Current (Position).Text) = "'" then
            Add_Production
              (Result, Production_Chained_Attribute_Reference, Tok,
               "chained attribute reference");
            Add_Production
              (Result, Production_Attribute_Reference, Tok, To_String (Tok.Text));
            Add_Production
              (Result, Production_Attribute_Subtype_Mark_Reference, Tok,
               "attribute reference in subtype mark");
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Attribute_Designator_Name,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
            end if;
         else
            exit;
         end if;
      end loop;
   end Parse_Subtype_Mark;

   procedure Parse_Defining_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      loop
         exit when At_End (Position);
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
               "expected defining name in profile");
            exit;
         end if;
         exit when not Match_Symbol (Position, ",");
      end loop;
   end Parse_Defining_Name_List;

   procedure Parse_Profile_Default
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if Match_Symbol (Position, ":=") then
         Add_Production
           (Result, Production_Default_Expression, Tok,
            "profile default expression");
         if At_Profile_Default_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Profile_Default_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "profile default expression reserved boundary recovery");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected profile default expression before reserved boundary");
         else
            Parse_Expression (Position, Result);
         end if;
         Skip_Balanced_To (Position, ";", ")");
      end if;
   end Parse_Profile_Default;

   procedure Parse_Parameter_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Is_Access_Subprogram_Parameter : Boolean := False;
   begin
      Add_Production
        (Result, Production_Parameter_Specification, Tok,
         To_String (Tok.Text));
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in parameter specification");
         Skip_Balanced_To (Position, ";", ")");
         return;
      end if;

      if Current_Lower (Position) = "aliased" then
         Add_Production
           (Result, Production_Aliased_Part, Current (Position), "aliased");
         Advance (Position);
      end if;

      if Current_Lower (Position) = "in" or else Current_Lower (Position) = "out" then
         Add_Production
           (Result, Production_Parameter_Mode, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         if Current_Lower (Position) = "out" then
            Add_Production
              (Result, Production_Parameter_Mode, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;
      end if;

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
      then
         Is_Access_Subprogram_Parameter :=
           Lookahead_Lower (Position, 3) = "protected"
           or else Lookahead_Lower (Position, 3) = "procedure"
           or else Lookahead_Lower (Position, 3) = "function"
           or else Lookahead_Lower (Position, 4) = "procedure"
           or else Lookahead_Lower (Position, 4) = "function";
         Parse_Subtype_Indication (Position, Result);
      elsif Current_Lower (Position) = "access" then
         Is_Access_Subprogram_Parameter :=
           Lookahead_Lower (Position, 1) = "protected"
           or else Lookahead_Lower (Position, 1) = "procedure"
           or else Lookahead_Lower (Position, 1) = "function"
           or else Lookahead_Lower (Position, 2) = "procedure"
           or else Lookahead_Lower (Position, 2) = "function";
         Parse_Subtype_Indication (Position, Result);
      elsif not At_Profile_Item_End (Position)
        and then To_String (Current (Position).Text) /= ":="
      then
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Is_Access_Subprogram_Parameter
        and then To_String (Current (Position).Text) = ":="
      then
         Add_Production
           (Result, Production_Access_Subprogram_Parameter_Default,
            Current (Position),
            "access-to-subprogram parameter default");
      end if;

      Parse_Profile_Default (Position, Result);
      if not At_Profile_Item_End (Position) then
         Skip_Balanced_To (Position, ";", ")");
      end if;
   end Parse_Parameter_Specification;

   procedure Parse_Parameter_Profile
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      Add_Production (Result, Production_Parameter_Profile, Tok, "parameter profile");
      Add_Production
        (Result, Production_Parameter_Profile_Open_Delimiter, Tok,
         "parameter profile open delimiter");
      Advance (Position);

      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         Parse_Parameter_Specification (Position, Result);
         exit when To_String (Current (Position).Text) = ")";
         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Parameter_Profile_Separator, Current (Position),
               "parameter profile separator");
            Advance (Position);
         else
            exit;
         end if;
      end loop;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Parameter_Profile_Close_Delimiter, Current (Position),
            "parameter profile close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Parameter_Profile_Missing_Close_Recovery_Boundary, Tok,
            "parameter profile missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in parameter profile");
      end if;
   end Parse_Parameter_Profile;

   procedure Parse_Discriminant_Selector_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      loop
         exit when At_End (Position);
         exit when To_String (Current (Position).Text) = "=>";
         declare
            Selector_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discriminant_Selector_Name, Selector_Tok,
               To_String (Selector_Tok.Text));

            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Name, Selector_Tok,
                  To_String (Selector_Tok.Text));
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Selector_Tok,
                  "expected discriminant selector name");
               exit;
            end if;
         end;

         if To_String (Current (Position).Text) = "|" then
            declare
               Separator_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Discrete_Choice_Separator, Separator_Tok,
                  "discrete choice separator");
               Advance (Position);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = "=>"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Discrete_Choice_Missing_Choice_Recovery_Boundary,
                     Separator_Tok, "discrete choice missing choice recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Separator_Tok,
                     "expected discrete choice after separator");
                  exit;
               end if;
            end;
         else
            exit;
         end if;
      end loop;
   end Parse_Discriminant_Selector_Name_List;


   procedure Parse_Discriminant_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Discriminant_Association_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Discriminant_Association_Reserved_Boundary;

      function At_Discriminant_Association_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Discriminant_Association_Reserved_Boundary;
      end At_Discriminant_Association_Boundary;
   begin
      Add_Production
        (Result, Production_Discriminant_Constraint, Tok,
         "discriminant constraint");
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;
      Add_Production
        (Result, Production_Discriminant_Constraint_Open_Delimiter,
         Current (Position), "discriminant constraint open delimiter");
      Advance (Position);

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Assoc_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discriminant_Association, Assoc_Tok,
               "discriminant association");

            if Has_Top_Level_Arrow_Before_Constraint_Association_End
                 (Position)
            then
               --  discriminant_association permits a selector-name list
               --  before =>.  Keep ``Left | Right => Expr`` structural
               --  instead of letting expression parsing stop at ``|`` and
               --  forcing recovery before the closing constraint.
               Parse_Discriminant_Selector_Name_List (Position, Result);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Assoc_Tok,
                     "expected => in discriminant association");
               end if;
            end if;

            if At_Discriminant_Association_Boundary then
               Add_Production
                 (Result,
                  Production_Discriminant_Association_Missing_Expression_Recovery_Boundary,
                  Assoc_Tok, "missing discriminant association expression");
               if At_Discriminant_Association_Reserved_Boundary then
                  Add_Production
                    (Result,
                     Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary,
                     Current (Position),
                     "discriminant constraint reserved-boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Assoc_Tok,
                  "missing discriminant association expression");
            else
               Add_Production
                 (Result, Production_Discriminant_Constraint_Expression,
                  Current (Position), "discriminant constraint expression");
               Parse_Expression (Position, Result);
            end if;
         end;
         if To_String (Current (Position).Text) = "," then
            Add_Production
              (Result, Production_Discriminant_Association_Separator,
               Current (Position), "discriminant association separator");
            Advance (Position);
            if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
               Add_Production
                 (Result,
                  Production_Discriminant_Association_Missing_Expression_Recovery_Boundary,
                  Tok, "missing discriminant association after comma");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing discriminant association after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Discriminant_Constraint_Close_Delimiter,
            Current (Position), "discriminant constraint close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary,
            Tok, "discriminant constraint missing close recovery boundary");
      end if;
   end Parse_Discriminant_Constraint;


   procedure Parse_Index_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Index_Item_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Index_Item_Reserved_Boundary;

      function At_Index_Item_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Index_Item_Reserved_Boundary;
      end At_Index_Item_Boundary;
   begin
      Add_Production (Result, Production_Index_Constraint, Tok, "index constraint");
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;
      Add_Production
        (Result, Production_Index_Constraint_Open_Delimiter, Current (Position),
         "index constraint open delimiter");
      Advance (Position);
      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Item_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Index_Constraint_Item, Item_Tok,
               "index constraint item");
            if Current_Lower (Position) = "range" then
               Parse_Range_Constraint (Position, Result);
            elsif At_Index_Item_Boundary then
               Add_Production
                 (Result, Production_Index_Constraint_Missing_Item_Recovery_Boundary,
                  Item_Tok, "missing index constraint item");
               if At_Index_Item_Reserved_Boundary then
                  Add_Production
                    (Result,
                     Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary,
                     Current (Position),
                     "index constraint reserved-boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Item_Tok,
                  "missing index constraint item");
            else
               Add_Production
                 (Result, Production_Range_Lower_Bound, Current (Position),
                  "index constraint lower bound");
               Parse_Expression (Position, Result);
               if To_String (Current (Position).Text) = ".." then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "range constraint");
                  Advance (Position);
                  if At_Index_Item_Boundary then
                     Add_Production
                       (Result, Production_Constraint_Recovery_Boundary,
                        Item_Tok, "missing index constraint upper bound");
                     if At_Index_Item_Reserved_Boundary then
                        Add_Production
                          (Result,
                           Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary,
                           Current (Position),
                           "index constraint upper bound reserved-boundary recovery boundary");
                     end if;
                  else
                     Add_Production
                       (Result, Production_Range_Upper_Bound,
                        Current (Position), "index constraint upper bound");
                     Parse_Expression (Position, Result);
                  end if;
               elsif Current_Lower (Position) = "range" then
                  Parse_Range_Constraint (Position, Result);
               end if;
            end if;
         end;

         if To_String (Current (Position).Text) = "," then
            Add_Production
              (Result, Production_Index_Constraint_Item_Separator,
               Current (Position), "index constraint item separator");
            Advance (Position);
            if To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Index_Constraint_Missing_Item_Recovery_Boundary,
                  Tok, "missing index constraint item after comma");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing index constraint item after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;
      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Index_Constraint_Close_Delimiter,
            Current (Position), "index constraint close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Index_Constraint_Missing_Close_Recovery_Boundary,
            Tok, "index constraint missing close recovery boundary");
      end if;
   end Parse_Index_Constraint;



   procedure Parse_Array_Index_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function Has_Box_Before_Delimiter (From : Cursor) return Boolean is
         Probe : Cursor := From;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth = 0 or else Depth = 1 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 0 and then T = "," then
                  return False;
               elsif Depth = 0 and then T = "<>" then
                  return True;
               end if;
            end;
            Advance (Probe);
         end loop;

         return False;
      end Has_Box_Before_Delimiter;

      function Has_Box_In_Index_Part (From : Cursor) return Boolean is
         Probe : Cursor := From;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth <= 1 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 1 and then T = "<>" then
                  return True;
               end if;
            end;
            Advance (Probe);
         end loop;

         return False;
      end Has_Box_In_Index_Part;

      function At_Array_Index_Reserved_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "with"
           or else L = "begin"
           or else L = "private"
           or else L = "record"
           or else L = "end"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "or"
           or else L = "when"
           or else L = "exception"
           or else L = "do";
      end At_Array_Index_Reserved_Boundary;
   begin
      Add_Production (Result, Production_Index_Constraint, Tok, "array index part");
      if Has_Box_In_Index_Part (Position) then
         Add_Production
           (Result, Production_Unconstrained_Array_Index_Part, Tok,
            "unconstrained array index part");
      else
         Add_Production
           (Result, Production_Constrained_Array_Index_Part, Tok,
            "constrained array index part");
      end if;
      if not Match_Symbol (Position, "(") then
         return;
      end if;

      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Item_Tok : constant Token_Info := Current (Position);
         begin
            --  Unconstrained array definitions use index subtype definitions,
            --  for example ``Positive range <>``.  These must be retained as
            --  distinct grammar from constrained index constraints/ranges;
            --  otherwise the token cursor treats ``<>`` as an ordinary
            --  relation tail and downstream recovery loses the array-domain
            --  shape.
            if Has_Box_Before_Delimiter (Position) then
               Add_Production
                 (Result, Production_Array_Index_Subtype_Definition, Item_Tok,
                  "array index subtype definition");
               Add_Production
                 (Result, Production_Index_Subtype_Definition, Item_Tok,
                  "index subtype definition");
               Add_Production
                 (Result, Production_Array_Index_Subtype_Name, Current (Position),
                  "array index subtype name");
               Parse_Subtype_Mark (Position, Result);
               if Current_Lower (Position) = "range" then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "index subtype range box");
                  Add_Production
                    (Result, Production_Array_Index_Range_Box, Current (Position),
                     "array index range box");
                  Advance (Position);
               end if;
               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Array_Index_Range_Box, Current (Position),
                     "array index range box");
                  Advance (Position);
               end if;
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index range item");
               Parse_Range_Constraint (Position, Result);
            elsif At_Array_Index_Reserved_Boundary then
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index constraint item");
               Add_Production
                 (Result, Production_Array_Index_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "array index reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Item_Tok,
                  "missing array index item");
            else
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index constraint item");
               Add_Production
                 (Result, Production_Range_Lower_Bound, Current (Position),
                  "array index lower bound");
               Parse_Expression (Position, Result);
               if To_String (Current (Position).Text) = ".." then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "range constraint");
                  Advance (Position);
                  if At_Array_Index_Reserved_Boundary then
                     Add_Production
                       (Result, Production_Array_Index_Reserved_Boundary_Recovery_Boundary,
                        Current (Position),
                        "array index upper bound reserved-boundary recovery boundary");
                     Add_Production
                       (Result, Production_Constraint_Recovery_Boundary,
                        Item_Tok, "missing array index upper bound");
                  else
                     Add_Production
                       (Result, Production_Range_Upper_Bound,
                        Current (Position), "array index upper bound");
                     Parse_Expression (Position, Result);
                  end if;
               elsif Current_Lower (Position) = "range" then
                  Parse_Range_Constraint (Position, Result);
               end if;
            end if;
         end;
         if Match_Symbol (Position, ",") then
            if To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing array index part after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if not Match_Symbol (Position, ")") then
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in array index part");
      end if;
   end Parse_Array_Index_Part;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Subtype_Indication, Tok, To_String (Tok.Text));
      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
        and then (Lookahead_Lower (Position, 3) = "protected"
                  or else Lookahead_Lower (Position, 3) = "procedure"
                  or else Lookahead_Lower (Position, 3) = "function"
                  or else Lookahead_Lower (Position, 4) = "procedure"
                  or else Lookahead_Lower (Position, 4) = "function")
      then
         Add_Production
           (Result, Production_Access_Subprogram_Null_Exclusion, Tok,
            "not null access-to-subprogram definition");
      end if;
      Parse_Null_Exclusion (Position, Result);
      if Current_Lower (Position) = "access" then
         Parse_Access_Type_Definition (Position, Result);
      else
         Parse_Subtype_Mark (Position, Result);
      end if;
      if Current_Lower (Position) = "range" then
         Add_Production
           (Result, Production_Subtype_Range_Constraint, Current (Position),
            "subtype range constraint");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production
           (Result, Production_Subtype_Digits_Constraint, Current (Position),
            "subtype digits constraint");
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "delta" then
         Add_Production
           (Result, Production_Subtype_Delta_Constraint, Current (Position),
            "subtype delta constraint");
         Parse_Delta_Constraint (Position, Result);
      elsif To_String (Current (Position).Text) = "(" then
         if Parenthesized_Constraint_Has_Arrow (Position) then
            --  A subtype indication can be followed by either an array index
            --  constraint or a discriminant constraint.  Named discriminant
            --  associations are syntactically distinguishable by ``=>`` and
            --  must not be flattened into generic index-constraint recovery.
            --  Positional constraints remain on the existing conservative
            --  index-constraint path because they are not distinguishable
            --  without symbol-table knowledge.
            Add_Production
              (Result, Production_Subtype_Discriminant_Constraint,
               Current (Position), "subtype discriminant constraint");
            Parse_Discriminant_Constraint (Position, Result);
         else
            Add_Production
              (Result, Production_Subtype_Index_Constraint, Current (Position),
               "subtype index constraint");
            Parse_Index_Constraint (Position, Result);
         end if;
      end if;
   end Parse_Subtype_Indication;

   procedure Parse_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Array_Type_Definition, Tok, "array type definition");
      if Current_Lower (Position) = "array" then
         Advance (Position);
      end if;
      if To_String (Current (Position).Text) = "(" then
         Parse_Array_Index_Part (Position, Result);
      end if;
      if Match_Keyword (Position, "of") then
         Add_Production
           (Result, Production_Array_Component_Definition, Current (Position),
            "array component definition");
         if Current_Lower (Position) = "not"
           or else Current_Lower (Position) = "access"
         then
            Add_Production
              (Result, Production_Array_Component_Access_Definition,
               Current (Position), "array component access definition");
         else
            Add_Production
              (Result, Production_Array_Component_Subtype_Indication,
               Current (Position), "array component subtype indication");
         end if;
         if Current_Lower (Position) = "aliased" then
            Add_Production
              (Result, Production_Aliased_Part, Current (Position),
               "array component aliased part");
            Advance (Position);
            if Current_Lower (Position) = "not"
              or else Current_Lower (Position) = "access"
            then
               Add_Production
                 (Result, Production_Array_Component_Access_Definition,
                  Current (Position), "array component access definition");
            end if;
         end if;
         Parse_Subtype_Indication (Position, Result);
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "expected of in array type definition");
      end if;
   end Parse_Array_Type_Definition;

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Has_General_Object_Mode : Boolean := False;
      Is_Access_Function : Boolean := False;
      Has_Protected_Subprogram_Part : Boolean := False;

      function At_Access_Definition_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            Text : constant String := To_String (Current (Position).Text);
            Lower : constant String := Current_Lower (Position);
         begin
            return Text = ";"
              or else Text = ","
              or else Text = ")"
              or else Lower = "with"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private"
              or else Lower = "limited"
              or else Lower = "separate";
         end;
      end At_Access_Definition_Boundary;

      function At_Access_Subprogram_Head return Boolean is
      begin
         if At_End (Position) then
            return False;
         end if;

         declare
            Lower : constant String := Current_Lower (Position);
         begin
            return Lower = "procedure"
              or else Lower = "function"
              or else Lower = "protected";
         end;
      end At_Access_Subprogram_Head;

      function Offset_Is_Access_Definition_Boundary
        (Offset : Natural) return Boolean is
         Index : constant Natural := Position.Index + Offset;
      begin
         if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
            return True;
         end if;

         declare
            Text : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Text);
            Lower : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Lower);
         begin
            return Text = ";"
              or else Text = ","
              or else Text = ")"
              or else Lower = "with"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private"
              or else Lower = "limited"
              or else Lower = "separate";
         end;
      end Offset_Is_Access_Definition_Boundary;

      function Access_Parameter_Profile_Missing_Close return Boolean is
         Depth : Natural := 0;
      begin
         if To_String (Current (Position).Text) /= "(" then
            return False;
         end if;

         for Index in Position.Index .. Natural (Position.Stream.Tokens.Length) loop
            declare
               Text : constant String :=
                 To_String (Position.Stream.Tokens (Positive (Index)).Text);
               Lower : constant String :=
                 To_String (Position.Stream.Tokens (Positive (Index)).Lower);
            begin
               if Text = "(" then
                  Depth := Depth + 1;
               elsif Text = ")" then
                  if Depth = 0 then
                     return False;
                  end if;
                  Depth := Depth - 1;
                  if Depth = 0 then
                     return False;
                  end if;
               elsif Depth = 1
                 and then (Lower = "with"
                           or else Lower = "is"
                           or else Lower = "private"
                           or else Lower = "begin"
                           or else Lower = "end")
               then
                  return True;
               end if;
            end;
         end loop;

         return True;
      end Access_Parameter_Profile_Missing_Close;
   begin
      --  access_definition / access_type_definition are used in several Ada
      --  contexts: named access types, anonymous object/component definitions,
      --  discriminants, parameters, generic formals, and access result types.
      --  Retain the common access_definition node and the object-vs-subprogram
      --  branch explicitly so downstream semantic colouring/navigation can see
      --  whether the designated entity is a subtype mark or a callable profile.
      Add_Production
        (Result, Production_Access_Type_Definition, Tok,
         "access type definition");
      Add_Production
        (Result, Production_Access_Definition, Tok, "access definition");

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
      then
         Add_Production
           (Result, Production_Access_Subprogram_Null_Exclusion, Tok,
            "not null access definition");
      end if;

      Parse_Null_Exclusion (Position, Result);

      if Current_Lower (Position) = "access" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected access in access definition");
         return;
      end if;

      if Current_Lower (Position) = "all"
        or else Current_Lower (Position) = "constant"
      then
         Add_Production
           (Result, Production_Access_Mode, Current (Position),
            To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Access_General_Object, Current (Position),
            "general access object definition");
         if Current_Lower (Position) = "all" then
            Add_Production
              (Result, Production_Access_All_Object_Mode, Current (Position),
               "access all object mode");
         else
            Add_Production
              (Result, Production_Access_Constant_Object_Mode, Current (Position),
               "access constant object mode");
         end if;
         Has_General_Object_Mode := True;
         Advance (Position);

         if At_Access_Definition_Boundary then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing designated subtype after access all/constant mode");
            Add_Production
              (Result,
               Production_Access_Object_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype after access all/constant mode");
            Add_Production
              (Result,
               Production_Access_Mode_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype after access all/constant mode");
            return;
         elsif At_Access_Subprogram_Head then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "access all/constant cannot introduce access-to-subprogram profile structurally");
            Add_Production
              (Result,
               Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary,
               Tok,
               "access all/constant before access-to-subprogram head");
            return;
         end if;
      end if;

      if Current_Lower (Position) = "protected" then
         Add_Production
           (Result, Production_Access_Protected_Part, Current (Position),
            "protected");
         Add_Production
           (Result, Production_Access_Protected_Subprogram_Definition,
            Current (Position), "protected access-to-subprogram definition");
         Has_Protected_Subprogram_Part := True;
         Advance (Position);

         if Current_Lower (Position) /= "procedure"
           and then Current_Lower (Position) /= "function"
         then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing procedure or function after access protected");
            Add_Production
              (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
               Tok, "missing procedure or function after access protected");
            Add_Production
              (Result,
               Production_Access_Protected_Missing_Subprogram_Recovery_Boundary,
               Tok, "missing procedure or function after access protected");
            Add_Production
              (Result,
               Production_Access_Protected_Missing_Subprogram_Boundary_Token,
               Current (Position),
               "boundary token after access protected without procedure/function");
            return;
         end if;
      end if;

      if Current_Lower (Position) = "procedure"
        or else Current_Lower (Position) = "function"
      then
         Is_Access_Function := Current_Lower (Position) = "function";
         if Has_Protected_Subprogram_Part then
            if Is_Access_Function then
               Add_Production
                 (Result, Production_Access_Protected_Function_Profile,
                  Current (Position), "protected access-to-function profile");
            else
               Add_Production
                 (Result, Production_Access_Protected_Procedure_Profile,
                  Current (Position), "protected access-to-procedure profile");
            end if;
         end if;
         Add_Production
           (Result, Production_Access_To_Subprogram_Definition,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Access_Named_Subprogram_Definition,
            Current (Position), "named access-to-subprogram definition");
         Add_Production
           (Result, Production_Access_Subprogram_Profile,
            Current (Position), "access-to-subprogram profile");
         Add_Production
           (Result, Production_Access_Subprogram_Kind,
            Current (Position), To_String (Current (Position).Text));
         Advance (Position);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Access_Subprogram_Parameter_Profile,
               Current (Position), "access-to-subprogram parameter profile");
            if Access_Parameter_Profile_Missing_Close then
               Add_Production
                 (Result,
                  Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary,
                  Current (Position),
                  "access-to-subprogram parameter profile missing close recovery boundary");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Current (Position),
                  "access-to-subprogram parameter profile missing close recovery");
               while not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
               loop
                  Advance (Position);
               end loop;
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Advance (Position);
               end if;
               return;
            else
               Parse_Parameter_Profile (Position, Result);
            end if;
         end if;
         if Current_Lower (Position) = "return" then
            Add_Production
              (Result, Production_Access_Subprogram_Result_Profile,
               Current (Position), "access-to-subprogram result profile");
            Add_Production
              (Result, Production_Access_Result_Subtype, Current (Position),
               "access-to-subprogram result subtype");
            Advance (Position);
            if Current_Lower (Position) = "not"
              and then Lookahead_Lower (Position, 1) = "null"
              and then Offset_Is_Access_Definition_Boundary (2)
            then
               Add_Production
                 (Result, Production_Access_Subprogram_Result_Null_Exclusion,
                  Current (Position),
                  "access-to-function result null exclusion");
               Add_Production
                 (Result, Production_Access_Type_Recovery_Boundary, Tok,
                  "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result,
                  Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result,
                  Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Advance (Position);
               Advance (Position);
            elsif At_Access_Definition_Boundary then
               Add_Production
                 (Result, Production_Access_Type_Recovery_Boundary, Tok,
                  "missing result subtype after access-to-function return");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return");
               Add_Production
                 (Result,
                  Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return");
               Add_Production
                 (Result,
                  Production_Access_Result_Missing_Subtype_Recovery_Boundary,
                  Tok, "missing access result subtype after return");
            else
               if Current_Lower (Position) = "not"
                 and then Lookahead_Lower (Position, 1) = "null"
               then
                  Add_Production
                    (Result, Production_Access_Subprogram_Result_Null_Exclusion,
                     Current (Position),
                     "access-to-function result null exclusion");
               end if;
               if Access_Subprogram_Result_Has_Constraint (Position) then
                  Add_Production
                    (Result, Production_Access_Subprogram_Result_Constraint,
                     Current (Position),
                     "access-to-function result subtype constraint");
               end if;
               Parse_Subtype_Indication (Position, Result);
            end if;
         elsif Is_Access_Function then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing return subtype in access-to-function definition");
            Add_Production
              (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
               Tok, "missing return subtype in access-to-function profile");
            Add_Production
              (Result, Production_Access_Function_Missing_Return_Recovery_Boundary,
               Tok, "missing return subtype in access-to-function profile");
         end if;
      else
         Add_Production
           (Result, Production_Access_To_Object_Definition, Current (Position),
            To_String (Current (Position).Text));
         if Has_General_Object_Mode then
            Add_Production
              (Result, Production_Access_General_Object, Current (Position),
               "general access object designated subtype");
         else
            Add_Production
              (Result, Production_Access_Pool_Specific_Object, Current (Position),
               "pool-specific access object definition");
         end if;
         if At_Access_Definition_Boundary then
            --  Access-to-object definitions require a designated subtype.
            --  Treat declaration/aspect/body boundaries as recovery points
            --  instead of parsing them as subtype marks, so malformed forms
            --  such as ``access with Inline`` or ``access private`` remain
            --  bounded and following declarations stay visible.
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing designated subtype in access object definition");
            Add_Production
              (Result,
               Production_Access_Object_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype in access object definition");
         else
            Add_Production
              (Result, Production_Access_Object_Subtype_Mark, Current (Position),
               "access object subtype mark");
            Parse_Subtype_Indication (Position, Result);
         end if;
      end if;
   end Parse_Access_Type_Definition;

   procedure Parse_Type_Modifiers
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      --  Ada type definitions can be prefixed by grammar-significant
      --  modifiers before the actual type-definition body.  Earlier passes
      --  only recognized definitions whose first token was the body keyword
      --  itself (record/private/interface/new/array/access).  Retain the
      --  modifiers structurally so forms such as ``abstract tagged limited
      --  record`` and ``synchronized interface`` do not fall through the
      --  subtype-indication recovery path.
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant Token_Info := Current (Position);
         begin
            exit when L /= "abstract"
              and then L /= "limited"
              and then L /= "tagged"
              and then L /= "synchronized"
              and then L /= "task"
              and then L /= "protected";
            Add_Production
              (Result, Production_Type_Modifier, T, To_String (T.Text));
            if L = "abstract" then
               Add_Production
                 (Result, Production_Abstract_Type_Modifier, T,
                  "abstract type modifier");
            elsif L = "tagged" then
               Add_Production
                 (Result, Production_Tagged_Type_Modifier, T,
                  "tagged type modifier");
            elsif L = "limited" then
               Add_Production
                 (Result, Production_Limited_Type_Modifier, T,
                  "limited type modifier");
            end if;
            Advance (Position);
         end;
      end loop;
   end Parse_Type_Modifiers;

   procedure Parse_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Type_Definition, Tok, To_String (Tok.Text));
      Parse_Type_Modifiers (Position, Result);
      if To_String (Current (Position).Text) = "(" then
         Parse_Enumeration_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "record" then
         Parse_Record_Definition (Position, Result);
      elsif Current_Lower (Position) = "null"
        and then Lookahead_Lower (Position, 1) = "record"
      then
         Add_Production
           (Result, Production_Record_Definition, Current (Position),
            "null record definition");
         Advance (Position);
         Advance (Position);
      elsif Current_Lower (Position) = "array" then
         Parse_Array_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "access"
        or else (Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "null"
                 and then Lookahead_Lower (Position, 2) = "access")
      then
         Parse_Access_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "new" then
         Add_Production (Result, Production_Derived_Type_Definition, Tok, "derived type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production
              (Result, Production_Derived_Parent_Subtype, Current (Position),
               "derived parent subtype");
         end if;
         Parse_Subtype_Indication (Position, Result);
         if Current_Lower (Position) = "and" then
            Add_Production
              (Result, Production_Derived_Interface_List, Current (Position),
               "derived interface list");
         end if;
         while Current_Lower (Position) = "and" loop
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Derived_Interface_Subtype, Current (Position),
                  "derived interface subtype");
            end if;
            Parse_Subtype_Indication (Position, Result);
         end loop;
         if Current_Lower (Position) = "with" then
            Advance (Position);
            if Current_Lower (Position) = "private" then
               Add_Production
                 (Result, Production_Private_Type_Definition, Current (Position),
                  "private extension");
               Add_Production
                 (Result, Production_Derived_Private_Extension, Current (Position),
                  "derived private extension");
               Advance (Position);
            elsif Current_Lower (Position) = "record" then
               Add_Production
                 (Result, Production_Derived_Record_Extension, Current (Position),
                  "derived record extension");
               Parse_Record_Definition (Position, Result);
            elsif Current_Lower (Position) = "null"
              and then Lookahead_Lower (Position, 1) = "record"
            then
               Add_Production
                 (Result, Production_Derived_Record_Extension, Current (Position),
                  "derived record extension");
               Add_Production
                 (Result, Production_Derived_Null_Record_Extension, Current (Position),
                  "derived null record extension");
               Add_Production
                 (Result, Production_Record_Definition, Current (Position),
                  "derived null record definition");
               Advance (Position);
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Derived_Type_Recovery_Boundary, Current (Position),
                  "missing private or record after derived with");
            end if;
         end if;
      elsif Current_Lower (Position) = "private" then
         Add_Production (Result, Production_Private_Type_Definition, Current (Position), "private type definition");
         Advance (Position);
      elsif Current_Lower (Position) = "interface" then
         Add_Production (Result, Production_Interface_Type_Definition, Current (Position), "interface type definition");
         Advance (Position);
         if Current_Lower (Position) = "and" then
            Add_Production
              (Result, Production_Interface_Parent_List, Current (Position),
               "interface parent list");
         end if;
         while Current_Lower (Position) = "and" loop
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Interface_Parent_Subtype, Current (Position),
                  "interface parent subtype");
            end if;
            Parse_Subtype_Indication (Position, Result);
         end loop;
      elsif Current_Lower (Position) = "range" then
         Add_Production (Result, Production_Signed_Integer_Type_Definition, Current (Position), "signed integer type definition");
         Add_Production (Result, Production_Signed_Integer_Range, Current (Position), "signed integer range");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "mod" then
         Add_Production (Result, Production_Modular_Type_Definition, Current (Position), "modular type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Modular_Modulus_Expression, Current (Position), "modular modulus expression");
         end if;
         Parse_Expression (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production (Result, Production_Floating_Point_Definition, Current (Position), "floating point type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Floating_Digits_Expression, Current (Position), "floating digits expression");
         end if;
         Parse_Expression (Position, Result);
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      elsif Current_Lower (Position) = "delta" then
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Fixed_Delta_Expression, Current (Position), "fixed delta expression");
         end if;
         Parse_Expression (Position, Result);
         if Current_Lower (Position) = "digits" then
            Add_Production (Result, Production_Decimal_Fixed_Point_Definition, Tok, "decimal fixed point type definition");
            Advance (Position);
            if not At_End (Position) then
               Add_Production (Result, Production_Fixed_Digits_Expression, Current (Position), "fixed digits expression");
            end if;
            Parse_Expression (Position, Result);
         else
            Add_Production (Result, Production_Ordinary_Fixed_Point_Definition, Tok, "ordinary fixed point type definition");
         end if;
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      else
         Parse_Subtype_Indication (Position, Result);
      end if;
   end Parse_Type_Definition;

end Editor.Ada_Token_Cursor.Type_Parsing;
