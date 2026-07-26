with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Pragma_Parsing is
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

   procedure Parse_Pragma_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Pragma_Argument_List, Tok,
         "pragma argument list");
      Add_Production
        (Result, Production_Association_List, Tok,
         "pragma argument list");
      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Open_Delimiter,
            Current (Position), "pragma argument-list open delimiter");
      end if;
      if not Match_Symbol (Position, "(") then
         return;
      end if;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Empty_Recovery_Boundary,
            Tok, "pragma argument-list empty recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma argument association before )");
         Add_Production
           (Result, Production_Pragma_Argument_List_Close_Delimiter,
            Current (Position), "pragma argument-list close delimiter");
         Advance (Position);
         return;
      end if;

      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Arg_Tok : constant Token_Info := Current (Position);
         begin
            if To_String (Arg_Tok.Text) = ";" then
               Add_Production
                 (Result, Production_Recovery_Point, Arg_Tok,
                  "expected ) in pragma argument list");
               exit;
            end if;

            Add_Production
              (Result, Production_Pragma_Argument_Association, Arg_Tok,
               To_String (Arg_Tok.Text));

            if (Current (Position).Kind = Token_Identifier
                or else Current (Position).Kind = Token_Keyword)
              and then Lookahead_Lower (Position, 1) = "=>"
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Named_Association,
                  Arg_Tok, To_String (Arg_Tok.Text));
               Add_Production
                 (Result, Production_Pragma_Argument_Identifier,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Arg_Tok,
                     "expected => in pragma argument association");
               end if;
            else
               Add_Production
                 (Result, Production_Pragma_Argument_Positional_Association,
                  Arg_Tok, To_String (Arg_Tok.Text));
            end if;

            if To_String (Current (Position).Text) = ")"
              or else To_String (Current (Position).Text) = ","
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Missing_Expression_Recovery_Boundary,
                  Arg_Tok, "pragma argument missing expression recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Arg_Tok,
                  "expected pragma argument expression");
            elsif To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Pragma_Argument_Box,
                  Current (Position), "pragma argument box");
               Add_Production
                 (Result, Production_Pragma_Argument_Expression,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Pragma_Argument_Expression,
                  Current (Position), To_String (Current (Position).Text));
               Parse_Expression (Position, Result);
            end if;

            if not At_End (Position)
              and then To_String (Current (Position).Text) = ","
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Association_Separator,
                  Current (Position), "pragma argument association separator");
               Advance (Position);
               if To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Pragma_Argument_Trailing_Separator_Recovery_Boundary,
                     Arg_Tok, "pragma argument trailing separator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Arg_Tok,
                     "expected pragma argument after separator");
               end if;
            else
               exit;
            end if;
         end;
      end loop;
      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Close_Delimiter,
            Current (Position), "pragma argument-list close delimiter");
         Advance (Position);
      else
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Pragma_Argument_Association_Separator,
               Current (Position),
               "pragma argument missing-close synchronization separator");
         end if;
         Add_Production
           (Result, Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "pragma argument-list missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in pragma argument list");
      end if;
   end Parse_Pragma_Argument_List;

   function Is_Representation_Pragma_Identifier (Lower_Name : String) return Boolean is
   begin
      return Lower_Name = "pack"
        or else Lower_Name = "atomic"
        or else Lower_Name = "volatile"
        or else Lower_Name = "independent"
        or else Lower_Name = "atomic_components"
        or else Lower_Name = "volatile_components"
        or else Lower_Name = "independent_components"
        or else Lower_Name = "unchecked_union"
        or else Lower_Name = "convention"
        or else Lower_Name = "import"
        or else Lower_Name = "export"
        or else Lower_Name = "interface"
        or else Lower_Name = "external"
        or else Lower_Name = "linker_section"
        or else Lower_Name = "machine_attribute"
        or else Lower_Name = "attach_handler"
        or else Lower_Name = "interrupt_handler"
        or else Lower_Name = "discard_names"
        or else Lower_Name = "suppress_initialization";
   end Is_Representation_Pragma_Identifier;

   function Is_Operational_Pragma_Identifier (Lower_Name : String) return Boolean is
   begin
      return Is_Representation_Pragma_Identifier (Lower_Name)
        or else Lower_Name = "priority"
        or else Lower_Name = "interrupt_priority"
        or else Lower_Name = "cpu"
        or else Lower_Name = "dispatching_domain"
        or else Lower_Name = "relative_deadline"
        or else Lower_Name = "max_entry_queue_length"
        or else Lower_Name = "inline"
        or else Lower_Name = "inline_always"
        or else Lower_Name = "no_return"
        or else Lower_Name = "preelaborate"
        or else Lower_Name = "pure"
        or else Lower_Name = "elaborate_body"
        or else Lower_Name = "remote_types"
        or else Lower_Name = "remote_call_interface"
        or else Lower_Name = "all_calls_remote"
        or else Lower_Name = "shared_passive"
        or else Lower_Name = "no_tagged_streams"
        or else Lower_Name = "assertion_policy"
        or else Lower_Name = "check_policy"
        or else Lower_Name = "debug_policy"
        or else Lower_Name = "restrictions"
        or else Lower_Name = "restriction_warnings"
        or else Lower_Name = "profile"
        or else Lower_Name = "suppress"
        or else Lower_Name = "unsuppress"
        or else Lower_Name = "spark_mode";
   end Is_Operational_Pragma_Identifier;

   procedure Parse_Pragma
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Pragma_Name : Unbounded_String := Null_Unbounded_String;
   begin
      Add_Production (Result, Production_Pragma, Tok, "pragma");
      if not Match_Keyword (Position, "pragma") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma keyword");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Pragma_Name := To_Unbounded_String (Current_Lower (Position));
         Add_Production
           (Result, Production_Pragma_Identifier, Current (Position),
            To_String (Current (Position).Text));
         if Is_Representation_Pragma_Identifier (To_String (Pragma_Name)) then
            Add_Production
              (Result, Production_Representation_Pragma, Current (Position),
               To_String (Current (Position).Text));
         end if;
         if Is_Operational_Pragma_Identifier (To_String (Pragma_Name)) then
            Add_Production
              (Result, Production_Operational_Pragma, Current (Position),
               To_String (Current (Position).Text));
            Add_Production
              (Result, Production_Operational_Item, Current (Position),
               "pragma operational item");
         end if;
         Advance (Position);
      else
         Add_Production
           (Result, Production_Pragma_Identifier_Missing_Recovery_Boundary, Tok,
            "pragma identifier missing recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma identifier");
      end if;

      if To_String (Current (Position).Text) = "(" then
         Parse_Pragma_Argument_List (Position, Result);
      else
         Add_Production
           (Result, Production_Nullary_Pragma, Tok,
            "nullary pragma");
      end if;

      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Pragma_Missing_Terminator_Recovery_Boundary, Tok,
            "pragma missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ; after pragma");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Pragma;

end Editor.Ada_Token_Cursor.Pragma_Parsing;
