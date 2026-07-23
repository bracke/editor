with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Aspect_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Renaming_Parsing;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor;
use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing is

   function Current_Lower (Position : Cursor) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower;

   function Lookahead_Lower
     (Position : Cursor;
      Offset   : Natural) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Advance
     (Position : in out Cursor)
     renames Editor.Ada_Token_Cursor.Advance;

   function At_End (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.At_End;

   function Current (Position : Cursor) return Token_Info
     renames Editor.Ada_Token_Cursor.Current;

   function Match_Symbol
     (Position : in out Cursor;
      Symbol   : String) return Boolean
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Match_Symbol;

   procedure Skip_Balanced_To
     (Position : in out Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "")
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To;

   procedure Skip_Balanced_To_Semicolon
     (Position : in out Cursor)
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To_Semicolon;

   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Defining_Program_Unit_Name;

   procedure Parse_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Expression;

   procedure Parse_Selected_Name_Suffix
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String)
     renames Editor.Ada_Token_Cursor.Selected_Name_Parsing.Parse_Selected_Name_Suffix;

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Attached_Aspect_Or_Semicolon;

   function Starts_Strong_Package_Declarative_Item
     (Position : Cursor) return Boolean is
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

   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               elsif Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Parenthesized_Actual_Has_Top_Level_Arrow;

   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe : Cursor := Position;
      Depth : Natural := 0;
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

   procedure Parse_Generic_Instantiated_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Origin : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production
        (Result, Production_Generic_Instantiated_Unit_Name, Origin,
         "instantiated generic unit name");

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Name, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected instantiated generic unit name");
         return;
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) = "."
      loop
         Parse_Selected_Name_Suffix
           (Position, Result, Origin, "instantiated generic unit name");
      end loop;
   end Parse_Generic_Instantiated_Unit_Name;

   procedure Parse_Generic_Instantiation_Declaration
     (Position  : in out Cursor;
      Result    : in out Grammar_Result;
      Unit_Kind : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Generic_Instantiation, Tok,
         Unit_Kind & " instantiation");
      if Unit_Kind = "package" then
         Add_Production
           (Result, Production_Generic_Package_Instantiation, Tok,
            "generic package instantiation");
      elsif Unit_Kind = "procedure" then
         Add_Production
           (Result, Production_Generic_Procedure_Instantiation, Tok,
            "generic procedure instantiation");
      elsif Unit_Kind = "function" then
         Add_Production
           (Result, Production_Generic_Function_Instantiation, Tok,
            "generic function instantiation");
      end if;

      if Current_Lower (Position) = Unit_Kind then
         Advance (Position);
      end if;

      if not At_End (Position) then
         Add_Production
           (Result, Production_Generic_Instance_Name, Current (Position),
            "generic instance defining name");
         Parse_Defining_Program_Unit_Name (Position, Result);
      end if;

      if Current_Lower (Position) = "is" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected is in generic instantiation");
         Skip_Balanced_To (Position, "new", ";");
      end if;

      if Current_Lower (Position) = "new" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected new in generic instantiation");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      Parse_Generic_Instantiated_Unit_Name (Position, Result);

      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Generic_Instantiation_Actual_Part,
            Current (Position), "generic instantiation actual part");
         Parse_Generic_Actual_Part (Position, Result);
      end if;

      if Starts_Strong_Package_Declarative_Item (Position) then
         return;
      end if;

      Parse_Attached_Aspect_Or_Semicolon (Position, Result);
   end Parse_Generic_Instantiation_Declaration;

end Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing;
