with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Token_Cursor.Aspect_Parsing;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing;
with Editor.Ada_Token_Cursor.Renaming_Parsing;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor;
use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Generic_Formal_Parsing is

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

   function Match_Keyword
     (Position : in out Cursor;
      Keyword  : String) return Boolean
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Match_Keyword;

   function Match_Symbol
     (Position : in out Cursor;
      Symbol   : String) return Boolean
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Match_Symbol;

   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Parenthesized_Actual_Has_Top_Level_Arrow;

   procedure Parse_Defining_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Defining_Name_List;

   procedure Parse_Defining_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Defining_Name;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Subtype_Indication;

   procedure Parse_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Expression;

   procedure Parse_Aspect_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Aspect_Specification;

   procedure Skip_Balanced_To_Semicolon
     (Position : in out Cursor)
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To_Semicolon;

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) = "with" then
         Add_Production
           (Result, Production_Attached_Aspect_Specification,
            Current (Position), "generic formal attached aspect");
         Add_Production
           (Result, Production_Generic_Formal_Aspect_Specification,
            Current (Position), "generic formal aspect placement");
         Parse_Aspect_Specification (Position, Result);
      end if;

      if To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Generic_Formal_Declaration_Terminator,
            Current (Position), "generic formal declaration terminator");
         Advance (Position);
      else
         Add_Production
           (Result,
            Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary,
            Current (Position),
            "generic formal declaration missing terminator recovery boundary");
      end if;
   end Parse_Generic_Formal_Declaration_Aspect_Or_Terminator;

   procedure Parse_Generic_Formal_Object_Declaration
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Leading_With : Boolean := False) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Object_Declaration, Tok,
         "formal object declaration");

      if Leading_With and then Current_Lower (Position) = "with" then
         Advance (Position);
      end if;

      Add_Production
        (Result, Production_Formal_Object_Defining_Name_List,
         Current (Position), "formal object defining name list");
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in formal object declaration");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      if Current_Lower (Position) = "in" or else Current_Lower (Position) = "out" then
         Add_Production
           (Result, Production_Formal_Object_Mode, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         if Current_Lower (Position) = "out" then
            Add_Production
              (Result, Production_Formal_Object_Mode, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;
      end if;

      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ":="
        and then To_String (Current (Position).Text) /= ";"
      then
         Add_Production
           (Result, Production_Formal_Object_Subtype_Indication,
            Current (Position), "formal object subtype indication");
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Match_Symbol (Position, ":=") then
         Add_Production
           (Result, Production_Formal_Object_Default, Current (Position),
            "formal object default");
         if To_String (Current (Position).Text) = "<>" then
            Add_Production
              (Result, Production_Box_Expression, Current (Position),
               "formal object default box");
            Advance (Position);
         else
            Parse_Expression (Position, Result);
         end if;
      end if;

      Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);
   end Parse_Generic_Formal_Object_Declaration;

   function Formal_Package_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               return False;
            elsif Depth = 0 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Formal_Package_Actual_Has_Top_Level_Arrow;

   function Formal_Package_Actual_Looks_Like_Missing_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
      Top_Level_Tokens : Natural := 0;
      Saw_Operator : Boolean := False;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               exit;
            elsif Depth = 0 and then T = "=>" then
               return False;
            elsif Depth = 0 then
               Top_Level_Tokens := Top_Level_Tokens + 1;
               if T = "+" or else T = "-" or else T = "*"
                 or else T = "/" or else T = "**" or else T = "&"
                 or else T = "=" or else T = "/=" or else T = "<"
                 or else T = "<=" or else T = ">" or else T = ">="
               then
                  Saw_Operator := True;
               end if;
            end if;
         end;
         Advance (Probe);
      end loop;

      return Top_Level_Tokens >= 2 and then not Saw_Operator;
   end Formal_Package_Actual_Looks_Like_Missing_Arrow;

   procedure Mark_Formal_Package_Nested_Actuals
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
                    (Result, Production_Formal_Package_Nested_Actual_Part,
                     Current (Probe), "nested formal package actual part");
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
                 (Result, Production_Formal_Package_Nested_Actual_Association,
                  Current (Probe), "nested formal package actual association");
               if Lookahead_Lower (Probe, 1) = "<>" then
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Association_Box,
                     Current (Probe),
                     "nested formal package actual association box");
                  Add_Production
                    (Result, Production_Generic_Actual_Box, Current (Probe),
                     "nested generic actual box default");
               end if;
            end if;
         end;
         Advance (Probe);
      end loop;
   end Mark_Formal_Package_Nested_Actuals;

   procedure Parse_Formal_Package_Actual_Selector
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Anchor   : Token_Info) is
      First : Boolean := True;
   begin
      while not At_End (Position)
        and then To_String (Current (Position).Text) /= "=>"
        and then To_String (Current (Position).Text) /= ","
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         if First then
            Add_Production
              (Result, Production_Formal_Package_Actual_Formal_Selector,
               Current (Position), To_String (Current (Position).Text));
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
            First := False;
         elsif To_String (Current (Position).Text) = "." then
            Add_Production
              (Result, Production_Selected_Name, Anchor,
               "formal package actual selector selected name");
         end if;
         Advance (Position);
      end loop;

      if not Match_Symbol (Position, "=>") then
         Add_Production
           (Result, Production_Recovery_Point, Anchor,
            "expected => in formal package actual association");
      end if;
   end Parse_Formal_Package_Actual_Selector;

   procedure Parse_Formal_Package_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Package_Actual_Part, Tok,
         "formal package actual part");

      if not Match_Symbol (Position, "(") then
         return;
      end if;
      Add_Production
        (Result, Production_Formal_Package_Actual_Part_Open_Delimiter,
         Tok, "formal package actual part open delimiter");

      if To_String (Current (Position).Text) = "<>"
        and then Lookahead_Lower (Position, 1) = ")"
      then
         Add_Production
           (Result, Production_Formal_Package_Actual_Box, Current (Position),
            "formal package box actual part");
         Advance (Position);
         if To_String (Current (Position).Text) = ")" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
               Current (Position), "formal package actual part close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package box actual part");
         end if;
      elsif To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Formal_Package_Actual_Empty_Recovery_Boundary,
            Current (Position),
            "formal package actual empty recovery boundary");
         Add_Production
           (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
            Current (Position), "formal package actual part close delimiter");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected formal package actual association or <> box");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Generic_Actual_Part,
            Tok, "generic actual part");

         declare
            Saw_Named_Association : Boolean := False;
         begin
            while not At_End (Position)
              and then To_String (Current (Position).Text) /= ")"
              and then To_String (Current (Position).Text) /= ";"
            loop
               declare
                  Assoc_Tok : constant Token_Info := Current (Position);
                  Named     : constant Boolean :=
                    Formal_Package_Actual_Has_Top_Level_Arrow (Position);
               begin
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Association,
                     Assoc_Tok, To_String (Assoc_Tok.Text));
                  Add_Production
                    (Result, Production_Generic_Actual_Association,
                     Assoc_Tok, To_String (Assoc_Tok.Text));

                  if Named then
                     Saw_Named_Association := True;
                     Parse_Formal_Package_Actual_Selector
                       (Position, Result, Assoc_Tok);
                  else
                     if Saw_Named_Association then
                        Add_Production
                          (Result,
                           Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary,
                           Assoc_Tok,
                           "formal package positional actual after named actual");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected named formal package actual after named association");
                     end if;

                     if Formal_Package_Actual_Looks_Like_Missing_Arrow (Position) then
                        Add_Production
                          (Result,
                           Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary,
                           Assoc_Tok,
                           "formal package actual missing arrow recovery boundary");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected => in formal package actual association");
                     end if;

                     Add_Production
                       (Result,
                        Production_Formal_Package_Actual_Positional_Association,
                        Assoc_Tok,
                        "formal package positional actual association");
                     Add_Production
                       (Result, Production_Generic_Actual_Positional_Association,
                        Assoc_Tok, "generic positional actual association");
                  end if;

                  if To_String (Current (Position).Text) = "<>" then
                     Add_Production
                       (Result, Production_Formal_Package_Actual_Association_Box,
                        Current (Position),
                        "formal package actual association box");
                     Add_Production
                       (Result, Production_Generic_Actual_Box, Current (Position),
                        "generic actual box default");
                     Advance (Position);
                  else
                     Mark_Formal_Package_Nested_Actuals (Position, Result);
                     Parse_Expression (Position, Result);
                  end if;

                  if To_String (Current (Position).Text) = "," then
                     Add_Production
                       (Result, Production_Formal_Package_Actual_Association_Separator,
                        Current (Position),
                        "formal package actual association separator");
                     Advance (Position);
                  else
                     exit;
                  end if;
                  if To_String (Current (Position).Text) = ")"
                    or else To_String (Current (Position).Text) = ";"
                    or else Current_Lower (Position) = "with"
                  then
                     Add_Production
                       (Result, Production_Formal_Package_Actual_Recovery_Boundary,
                        Current (Position),
                        "formal package actual recovery boundary");
                     exit;
                  end if;
               end;
            end loop;
         end;

         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part before aspect");
         elsif To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part");
         elsif To_String (Current (Position).Text) = ")" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
               Current (Position), "formal package actual part close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part");
            while not At_End (Position)
              and then Current_Lower (Position) /= "with"
              and then To_String (Current (Position).Text) /= ";"
            loop
               Advance (Position);
            end loop;
         end if;
      end if;
   end Parse_Formal_Package_Actual_Part;

end Editor.Ada_Token_Cursor.Generic_Formal_Parsing;
