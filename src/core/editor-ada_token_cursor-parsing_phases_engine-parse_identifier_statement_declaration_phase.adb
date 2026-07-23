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
procedure Parse_Identifier_Statement_Declaration_Phase
  (Position  : in out Cursor;
   Result    : in out Grammar_Result;
   Tok       : Token_Info;
   Mark_Pos  : Natural;
   Name_End  : Natural;
   Had_Names : Boolean) is
   pragma Suppress (Overflow_Check);
begin
   if Name_End /= Mark_Pos + 1 and then not Had_Names then
      --  A defining identifier cannot be a selected/indexed name.
      --  Treat malformed/in-progress source as a recovery point instead
      --  of fabricating a declaration.
      Add_Production
        (Result, Production_Recovery_Point, Tok,
         "invalid defining name before :");
      Skip_Balanced_To_Semicolon (Position);
      return;
   end if;

   Add_Production (Result, Production_Defining_Name, Tok, To_String (Tok.Text));
   if Current_Lower (Position) = "constant"
     and then
       (Lookahead_Lower (Position, 1) = ":="
        or else Lookahead_Lower (Position, 1) = ";")
   then
      Add_Production (Result, Production_Number_Declaration, Tok, "number declaration");
      Add_Production
        (Result, Production_Object_Declaration_Recovery_Boundary,
         Current (Position),
         "object declaration missing subtype/access definition");
      Add_Production
        (Result, Production_Number_Defining_Name_List, Tok,
         "number defining name list");
      --  Number declarations share the identifier-list shape with
      --  object and exception declarations, but they do not have a
      --  subtype indication after the colon.  Retain the individual
      --  defining identifiers and separators so grouped named-number
      --  declarations are visible to local diagnostics, Outline detail
      --  consumers, and syntax colouring without treating them as
      --  object declarations.
      declare
         Colon_Index : constant Natural := Mark (Position) - 1;
      begin
         for Name_Index in Mark_Pos .. Colon_Index - 1 loop
            declare
               Name_Tok : constant Token_Info :=
                 Token_At (Position.Stream, Name_Index);
               Name_Text : constant String :=
                 To_String (Name_Tok.Text);
            begin
               if Name_Tok.Kind = Token_Identifier
                 or else Name_Tok.Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Number_Defining_Name,
                     Name_Tok, Name_Text);
               elsif Name_Text = "," then
                  Add_Production
                    (Result,
                     Production_Number_Defining_Name_Separator,
                     Name_Tok,
                     "number defining name separator");
               end if;
            end;
         end loop;
      end;
      Add_Production
        (Result, Production_Number_Constant_Keyword,
         Current (Position), "number declaration constant keyword");
      Advance (Position);
      if Match_Symbol (Position, ":=") then
         if At_Number_Initialization_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "number initialization reserved-boundary recovery boundary");
            Add_Production
              (Result,
               Production_Number_Declaration_Recovery_Boundary,
               Current (Position),
               "number declaration missing initialization expression");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected number initialization expression before boundary");
         else
            Add_Production
              (Result, Production_Number_Initialization_Expression,
               Current (Position), "number initialization expression");
            Parse_Expression (Position, Result);
         end if;
      else
         Add_Production
           (Result,
            Production_Number_Declaration_Recovery_Boundary,
            Current (Position),
            "number declaration missing := initializer");
      end if;
      Parse_Number_Declaration_Aspect_Or_Terminator (Position, Result);
   elsif Current_Lower (Position) = "exception" then
      Add_Production (Result, Production_Exception_Declaration, Tok, "exception declaration");
      Add_Production
        (Result, Production_Exception_Defining_Name_List, Tok,
         "exception defining name list");
      Advance (Position);
      if Current_Lower (Position) = "renames" then
         Add_Production (Result, Production_Renaming_Declaration, Tok, "exception renames");
         Add_Production
           (Result, Production_Renaming_Defining_Name, Tok,
            "exception renaming defining name");
         Add_Production
           (Result, Production_Exception_Renaming_Declaration, Tok,
            "exception renaming declaration");
         Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Renaming_Tail
           (Position, Result, Tok, "renamed exception");
      else
         Parse_Exception_Declaration_Aspect_Or_Terminator
           (Position, Result);
      end if;
   else
      Add_Production (Result, Production_Object_Declaration, Tok, "object declaration");
      Add_Production
        (Result, Production_Object_Defining_Name_List, Tok,
         "object defining name list");
      --  Retain the individual defining identifiers and comma
      --  separators for object declarations.  The shared
      --  identifier-colon classifier already validated that the
      --  prefix is a defining_identifier_list; exposing the per-name
      --  structure lets Outline/colouring and local diagnostics
      --  distinguish grouped object declarations from call-shaped
      --  names without doing semantic lookup.
      declare
         Colon_Index : constant Natural := Mark (Position) - 1;
      begin
         for Name_Index in Mark_Pos .. Colon_Index - 1 loop
            declare
               Name_Tok : constant Token_Info :=
                 Token_At (Position.Stream, Name_Index);
               Name_Text : constant String :=
                 To_String (Name_Tok.Text);
            begin
               if Name_Tok.Kind = Token_Identifier
                 or else Name_Tok.Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Object_Defining_Name,
                     Name_Tok, Name_Text);
               elsif Name_Text = "," then
                  Add_Production
                    (Result,
                     Production_Object_Defining_Name_Separator,
                     Name_Tok, "object defining name separator");
               end if;
            end;
         end loop;
      end;
      --  Object declarations have their own qualifier sequence after
      --  the colon:
      --     defining_identifier_list : [aliased] [constant]
      --       (subtype_indication | access_definition) [:= expr];
      --  Earlier grammar only consumed a leading ``constant``.
      --  Legal Ada forms such as ``Obj : aliased constant T := ...``
      --  and ``Handle : aliased not null access T`` therefore entered
      --  subtype parsing with ``aliased`` as if it were a subtype
      --  mark.  Retain the qualifiers structurally before handing the
      --  remaining subtype/access syntax to the shared subtype parser.
      if Current_Lower (Position) = "aliased" then
         Add_Production
           (Result, Production_Object_Qualifier,
            Current (Position), "aliased object");
         Add_Production
           (Result, Production_Object_Aliased_Qualifier,
            Current (Position), "aliased object qualifier");
         Add_Production
           (Result, Production_Aliased_Part,
            Current (Position), "object aliased part");
         Advance (Position);
      end if;
      if Current_Lower (Position) = "constant" then
         Add_Production
           (Result, Production_Object_Qualifier,
            Current (Position), "constant object");
         Add_Production
           (Result, Production_Object_Constant_Qualifier,
            Current (Position), "constant object qualifier");
         Advance (Position);
      end if;
      if Current_Lower (Position) = "not"
        or else Current_Lower (Position) = "access"
      then
         Add_Production
           (Result, Production_Object_Access_Definition,
            Current (Position), "object access definition");
         Parse_Access_Type_Definition (Position, Result);
         if Current_Lower (Position) = "with" then
            Parse_Aspect_Specification (Position, Result);
         end if;
         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Object_Declaration_Terminator,
               Current (Position),
               "object declaration terminator");
            Advance (Position);
            return;
         elsif To_String (Current (Position).Text) /= ":=" then
            Add_Production
              (Result,
               Production_Object_Declaration_Missing_Terminator_Recovery_Boundary,
               Current (Position),
               "object declaration missing terminator recovery boundary");
            return;
         end if;
      elsif To_String (Current (Position).Text) = ":="
        or else To_String (Current (Position).Text) = ";"
      then
         Add_Production
           (Result,
            Production_Object_Declaration_Recovery_Boundary,
            Current (Position),
            "object declaration missing subtype/access definition");
      elsif At_Object_Subtype_Reserved_Boundary (Position) then
         Add_Production
           (Result,
            Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary,
            Current (Position),
            "object subtype indication reserved-boundary recovery boundary");
         Add_Production
           (Result,
            Production_Object_Declaration_Recovery_Boundary,
            Current (Position),
            "object declaration missing subtype/access definition before boundary");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected object subtype/access definition before boundary");
      end if;
      if not At_End (Position)
        and then not At_Object_Subtype_Reserved_Boundary (Position)
        and then Current_Lower (Position) /= "renames"
        and then Current_Lower (Position) /= "with"
        and then To_String (Current (Position).Text) /= ";"
        and then To_String (Current (Position).Text) /= ":="
      then
         Add_Production
           (Result, Production_Object_Subtype_Indication,
            Current (Position), "object subtype indication");
         if Has_Token_Before_Semicolon (Position, "renames") then
            Add_Production
              (Result, Production_Renaming_Subtype_Indication,
               Current (Position), "object renaming subtype indication");
         end if;
         Parse_Subtype_Indication (Position, Result);
      end if;
      if Current_Lower (Position) = "renames" then
         Add_Production (Result, Production_Renaming_Declaration, Tok, "object renames");
         Add_Production
           (Result, Production_Renaming_Defining_Name, Tok,
            "object renaming defining name");
         Add_Production
           (Result, Production_Object_Renaming_Declaration, Tok,
            "object renaming declaration");
         Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Renaming_Tail
           (Position, Result, Tok, "renamed object");
      else
         Skip_Balanced_To (Position, ":=", ";", "with");
         if Match_Symbol (Position, ":=") then
            Add_Production
              (Result, Production_Object_Initialization_Expression,
               Current (Position), "object initialization expression");
            if At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else To_String (Current (Position).Text) = ","
              or else To_String (Current (Position).Text) = ")"
              or else Current_Lower (Position) = "with"
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
              or else Current_Lower (Position) = "do"
            then
               Add_Production
                 (Result,
                  Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "object initialization reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Object_Declaration_Recovery_Boundary,
                  Current (Position),
                  "object declaration initializer recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected object initialization expression before boundary");
            else
               if To_String (Current (Position).Text) = "("
                 and then Lookahead_Lower (Position, 1) = "for"
                 and then Lookahead_Lower (Position, 2) /= "all"
                 and then Lookahead_Lower (Position, 2) /= "some"
                 and then not Has_Token_Between
                   (Position.Stream, Mark_Pos, Mark (Position), "array")
               then
                  Add_Production
                    (Result, Production_Quantified_Expression,
                     Current (Position), "quantified expression");
                  Add_Production
                    (Result,
                     Production_Quantified_Missing_Quantifier_Recovery_Boundary,
                     Current (Position),
                     "quantified expression missing quantifier recovery boundary");
                  Add_Production
                    (Result, Production_Quantified_Domain,
                     Current (Position), "quantified domain");
                  Add_Production
                    (Result, Production_Quantified_Arrow,
                     Current (Position), "quantified arrow");
               end if;
               Parse_Expression (Position, Result);
            end if;
         end if;

         --  Ordinary object declarations now retain their own
         --  completion metadata instead of relying only on the shared
         --  attached-aspect/semicolon helper.  Keep this shallow and
         --  parser-owned: it records the visible terminator, or that a
         --  synchronization boundary was reached without one, but it
         --  does not attempt object subtype, aspect, or initialization
         --  legality.
         if Current_Lower (Position) = "with" then
            Parse_Aspect_Specification (Position, Result);
         end if;

         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Object_Declaration_Terminator,
               Current (Position),
               "object declaration terminator");
            Advance (Position);
         else
            Add_Production
              (Result,
               Production_Object_Declaration_Missing_Terminator_Recovery_Boundary,
               Current (Position),
               "object declaration missing terminator recovery boundary");
         end if;
      end if;
   end if;
end Parse_Identifier_Statement_Declaration_Phase;
