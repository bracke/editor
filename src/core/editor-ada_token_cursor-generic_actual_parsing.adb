with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Parsing_Predicates;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Generic_Actual_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   function Starts_Strong_Package_Declarative_Item (Position : Cursor) return Boolean is
      L0 : constant String := Current_Lower (Position);
   begin
      return L0 = "pragma"
        or else L0 = "use"
        or else L0 = "type"
        or else L0 = "subtype"
        or else L0 = "procedure"
        or else L0 = "function"
        or else L0 = "package"
        or else L0 = "generic"
        or else L0 = "task"
        or else L0 = "protected"
        or else L0 = "entry"
        or else L0 = "for"
        or else L0 = "with";
   end Starts_Strong_Package_Declarative_Item;

   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe : Cursor := Position;
      Depth : Natural := 0;
      function Parenthesized_Actual_Has_Top_Level_Arrow (Position : Cursor) return Boolean
        renames Editor.Ada_Token_Cursor.Parsing_Predicates.Parenthesized_Actual_Has_Top_Level_Arrow;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if Depth = 0 and then (T = "," or else T = ")" or else T = ";") then
               return;
            elsif T = "(" then
               if Depth = 0
                 and then Parenthesized_Actual_Has_Top_Level_Arrow (Probe)
               then
                  Add_Production
                    (Result, Production_Generic_Actual_Nested_Actual_Part,
                     Current (Probe), "nested generic actual part");
               end if;
               Depth := Depth + 1;
            elsif T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               Add_Production
                 (Result, Production_Generic_Actual_Nested_Actual_Association,
                  Current (Probe), "nested generic actual association");
            end if;
         end;
         Advance (Probe);
      end loop;
   end Mark_Generic_Actual_Nested_Actuals;

   procedure Parse_Generic_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Generic_Actual_Value_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            Text  : constant String := To_String (Current (Position).Text);
            Lower : constant String := Current_Lower (Position);
         begin
            return Text = ")"
              or else Text = ","
              or else Text = ";"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private";
         end;
      end At_Generic_Actual_Value_Boundary;
   begin
      Add_Production (Result, Production_Generic_Actual_Part, Tok, "generic actual part");
      if not Match_Symbol (Position, "(") then
         return;
      end if;
      Add_Production
        (Result, Production_Generic_Actual_Part_Open_Delimiter, Tok,
         "generic actual part open delimiter");

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Generic_Actual_Empty_List_Recovery_Boundary,
            Current (Position), "empty generic actual list recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected generic actual association");
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Actual_Tok : constant Token_Info := Current (Position);
            Named     : Boolean := False;
         begin
            Add_Production
              (Result, Production_Generic_Actual_Association, Actual_Tok,
               To_String (Actual_Tok.Text));
            if (Current (Position).Kind = Token_Identifier
                or else Current (Position).Kind = Token_Keyword
                or else Current (Position).Kind = Token_String_Literal)
              and then Lookahead_Lower (Position, 1) = "=>"
            then
               Named := True;
               Add_Production
                 (Result, Production_Generic_Actual_Formal_Selector,
                  Current (Position), To_String (Current (Position).Text));
               if Current (Position).Kind = Token_String_Literal then
                  Add_Production
                    (Result, Production_Defining_Operator_Symbol,
                     Current (Position), To_String (Current (Position).Text));
               else
                  Add_Production
                    (Result, Production_Name, Current (Position),
                     To_String (Current (Position).Text));
               end if;
               Advance (Position);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Actual_Tok,
                     "expected => in generic actual association");
               end if;
            else
               Add_Production
                 (Result, Production_Generic_Actual_Positional_Association,
                  Actual_Tok, "generic positional actual association");
            end if;

            if To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Generic_Actual_Box, Current (Position),
                  "generic actual box default");
               if Named then
                  Add_Production
                    (Result, Production_Generic_Actual_Association_Box,
                     Current (Position),
                     "generic named actual association box");
               end if;
               Advance (Position);
            elsif At_Generic_Actual_Value_Boundary then
               Add_Production
                 (Result,
                  Production_Generic_Actual_Missing_Actual_Recovery_Boundary,
                  Current (Position),
                  "missing generic actual association value");
               Add_Production
                 (Result, Production_Generic_Actual_Recovery_Boundary,
                  Current (Position), "generic actual recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected generic actual association value");
            else
               Mark_Generic_Actual_Nested_Actuals (Position, Result);
               Parse_Expression (Position, Result);
            end if;

            if To_String (Current (Position).Text) = "," then
               Add_Production
                 (Result, Production_Generic_Actual_Association_Separator,
                  Current (Position),
                  "generic actual association separator");
               Advance (Position);
            else
               exit;
            end if;

            if To_String (Current (Position).Text) = ")"
              or else To_String (Current (Position).Text) = ";"
              or else Starts_Strong_Package_Declarative_Item (Position)
            then
               Add_Production
                 (Result,
                  Production_Generic_Actual_Trailing_Separator_Recovery_Boundary,
                  Current (Position),
                  "trailing generic actual association separator");
               Add_Production
                 (Result, Production_Generic_Actual_Recovery_Boundary,
                  Current (Position), "generic actual recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected generic actual association after separator");
               exit;
            end if;
         end;
      end loop;

      if Starts_Strong_Package_Declarative_Item (Position) then
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part before declaration boundary");
      elsif To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part");
      elsif To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Generic_Actual_Part_Close_Delimiter,
            Current (Position), "generic actual part close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part");
      end if;
   end Parse_Generic_Actual_Part;

end Editor.Ada_Token_Cursor.Generic_Actual_Parsing;
