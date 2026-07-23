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
   procedure Parse_Declaration_Or_Statement
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
   begin
      if At_End (Position) then
         return;
      elsif To_String (Tok.Text) = "<<" then
         Add_Production (Result, Production_Label, Tok, "label");
         Add_Production
           (Result, Production_Label_Open_Delimiter, Tok,
            "label open delimiter");
         Add_Production (Result, Production_Labeled_Statement, Tok, "labeled statement");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) /= ">>" then
            Add_Production
              (Result, Production_Label_Name, Current (Position),
               "label name");
         else
            Add_Production
              (Result, Production_Label_Recovery_Boundary, Tok,
               "empty label recovery boundary");
         end if;
         while not At_End (Position)
           and then Current (Position).Line = Tok.Line
           and then To_String (Current (Position).Text) /= ">>"
         loop
            Advance (Position);
         end loop;
         if not At_End (Position) and then To_String (Current (Position).Text) = ">>" then
            Add_Production
              (Result, Production_Label_Close_Delimiter, Current (Position),
               "label close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Label_Missing_Close_Recovery_Boundary, Tok,
               "label missing close delimiter recovery boundary");
            Add_Production
              (Result, Production_Label_Recovery_Boundary, Tok,
               "label recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected >> in label");
         end if;
      elsif (L0 = "with" and then not Has_Token_Before_Semicolon (Position, "=>"))
        or else (L0 = "limited" and then (L1 = "with" or else (L1 = "private" and then Lookahead_Lower (Position, 2) = "with")))
        or else (L0 = "private" and then L1 = "with")
      then
         Parse_Context_Clause (Position, Result);
      elsif L0 = "use" then
         Parse_Use_Clause (Position, Result);
      elsif L0 = "separate" then
         Add_Production (Result, Production_Separate_Subunit, Tok, "separate subunit");
         Advance (Position);
         if Match_Symbol (Position, "(") then
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Separate_Parent_Unit_Name,
                  Current (Position), "separate parent unit name");
               declare
                  Scan : Cursor := Position;
                  After_Dot : Boolean := False;
               begin
                  while not At_End (Scan)
                    and then To_String (Current (Scan).Text) /= ")"
                  loop
                     if To_String (Current (Scan).Text) = "." then
                        Add_Production
                          (Result, Production_Separate_Parent_Unit_Separator,
                           Current (Scan), "separate parent unit separator");
                        After_Dot := True;
                     elsif After_Dot then
                        Add_Production
                          (Result, Production_Separate_Parent_Unit_Child,
                           Current (Scan), "separate parent unit child");
                        After_Dot := False;
                     end if;
                     Advance (Scan);
                  end loop;
               end;
            end if;
            Parse_Expression (Position, Result);
            if not Match_Symbol (Position, ")") then
               Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in separate subunit");
            end if;
         else
            Add_Production (Result, Production_Recovery_Point, Tok, "expected parent unit in separate subunit");
         end if;
         if not At_End (Position) then
            Add_Production
              (Result, Production_Separate_Body_Declaration, Current (Position),
               "separate body declaration");
            Add_Production
              (Result, Production_Separate_Body_Kind_Keyword, Current (Position),
               "separate body kind keyword");
            if Current_Lower (Position) = "package"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Package_Body, Current (Position),
                  "separate package body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate package body unit name");
               end if;
            elsif Current_Lower (Position) = "procedure"
              or else Current_Lower (Position) = "function"
            then
               Add_Production
                 (Result, Production_Separate_Subprogram_Body, Current (Position),
                  "separate subprogram body");
               if Lookahead_Lower (Position, 1) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 1)),
                     "separate subprogram body unit name");
               end if;
            elsif Current_Lower (Position) = "task"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Task_Body, Current (Position),
                  "separate task body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate task body unit name");
               end if;
            elsif Current_Lower (Position) = "protected"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Protected_Body, Current (Position),
                  "separate protected body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate protected body unit name");
               end if;
            elsif Current_Lower (Position) = "entry" then
               Add_Production
                 (Result, Production_Separate_Entry_Body, Current (Position),
                  "separate entry body");
               if Lookahead_Lower (Position, 1) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 1)),
                     "separate entry body unit name");
               end if;
            end if;
            Parse_Declaration_Or_Statement (Position, Result);
         end if;
      elsif L0 = "pragma" then
         Parse_Pragma (Position, Result);
      elsif L0 = "generic" then
         if (L1 = "package" or else L1 = "procedure" or else L1 = "function")
           and then Has_Token_Before_Semicolon (Position, "renames")
         then
            Parse_Generic_Renaming_Declaration (Position, Result);
         else
            Add_Production (Result, Production_Generic_Declaration, Tok, "generic");
            Add_Production (Result, Production_Generic_Formal_Part, Tok, "generic formal part");
            Advance (Position);
            while not At_End (Position)
              and then Current_Lower (Position) /= "package"
              and then Current_Lower (Position) /= "procedure"
              and then Current_Lower (Position) /= "function"
            loop
               Parse_Generic_Formal_Declaration (Position, Result);
            end loop;
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Generic_Declaration_Aspect_Specification,
                  Current (Position), "generic declaration aspect placement");
            end if;
         end if;
      elsif L0 = "package" and then L1 = "body" then
         Add_Production (Result, Production_Package_Body, Tok, "package body");
         Advance (Position); -- package
         Advance (Position); -- body
         if not At_End (Position)
           and then Current_Lower (Position) /= "is"
           and then Current_Lower (Position) /= "with"
           and then To_String (Current (Position).Text) /= ";"
         then
            Add_Production
              (Result, Production_Package_Body_Name, Current (Position),
               "package body name");
            Parse_Subtype_Mark (Position, Result);
         end if;
         if Current_Lower (Position) = "is"
           and then Lookahead_Lower (Position, 1) = "separate"
         then
            Add_Production (Result, Production_Package_Body_Stub, Tok, "package body stub");
            Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "package body stub kind keyword");
            Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
            Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
            end if;
            Parse_Attached_Aspect_Or_Semicolon
              (Position, Result, Production_Body_Stub_Aspect_Specification);
         else
            Add_Package_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Package_Body_Aspect_Specification,
                  Current (Position), "package body aspect placement");
            end if;
            Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
              (Position, Result, "is", Production_Body_Aspect_Specification);
         end if;
      elsif L0 = "package" then
         if Lookahead_Lower (Position, 2) = "renames" then
            Parse_Package_Renaming_Declaration (Position, Result);
         elsif Starts_Generic_Instantiation (Position, "package") then
            Parse_Generic_Instantiation_Declaration
              (Position, Result, "package");
         else
            Add_Production (Result, Production_Package_Declaration, Tok, "package declaration");
            Add_Package_Declaration_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Package_Declaration_Aspect_Specification,
                  Current (Position), "package declaration aspect placement");
            end if;
            Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
              (Position, Result, "is", Production_Private_Completion_Aspect_Specification);
         end if;
      elsif L0 = "overriding" or else (L0 = "not" and then L1 = "overriding") then
         Add_Production (Result, Production_Overriding_Indicator, Tok, To_String (Tok.Text));
         Advance (Position);
         if L0 = "not" and then Current_Lower (Position) = "overriding" then
            Advance (Position);
         end if;
         if Current_Lower (Position) = "procedure" or else Current_Lower (Position) = "function" then
            Parse_Subprogram_Construct (Position, Result);
         else
            Add_Production (Result, Production_Recovery_Point, Tok, "expected subprogram after overriding indicator");
            Skip_Balanced_To_Semicolon (Position);
         end if;
      elsif L0 = "procedure" or else L0 = "function" then
         Parse_Subprogram_Construct (Position, Result);
      elsif L0 = "type" then
         Add_Production (Result, Production_Type_Declaration, Tok, "type declaration");
         Advance (Position);
         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
           or else Current (Position).Kind = Token_String_Literal
         then
            Add_Production
              (Result, Production_Type_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
         end if;
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Type_Discriminant_Part, Current (Position),
               "type discriminant part");
            Parse_Discriminant_Part (Position, Result);
         end if;
         Skip_Balanced_To (Position, "is", ";");
         if Match_Keyword (Position, "is") then
            if Current_Lower (Position) = "tagged"
              and then To_String (Current (Position).Text) /= ";"
              and then Lookahead_Lower (Position, 1) = ";"
            then
               --  Ada incomplete type declarations include the tagged form:
               --     type T is tagged;
               --  Retain it as incomplete-type grammar instead of sending the
               --  lone tagged modifier through full type-definition recovery.
               Add_Production
                 (Result, Production_Incomplete_Type_Declaration, Tok,
                  "incomplete type declaration");
               Add_Production
                 (Result, Production_Tagged_Incomplete_Type_Declaration,
                  Current (Position), "tagged incomplete type declaration");
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Add_Production
                    (Result, Production_Type_Declaration_Terminator,
                     Current (Position), "type declaration terminator");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                     Current (Position),
                     "type declaration missing terminator recovery boundary");
               end if;
            else
               Parse_Type_Definition (Position, Result);
               if Current_Lower (Position) = "with" then
                  Add_Production
                    (Result, Production_Private_Type_Aspect_Specification,
                     Current (Position), "private type aspect placement");
                  Add_Production
                    (Result, Production_Private_Completion_Aspect_Specification,
                     Current (Position), "type/private-completion aspect placement");
                  Parse_Aspect_Specification (Position, Result);
               end if;

               if To_String (Current (Position).Text) = ";" then
                  Add_Production
                    (Result, Production_Type_Declaration_Terminator,
                     Current (Position), "type declaration terminator");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                     Current (Position),
                     "type declaration missing terminator recovery boundary");
               end if;
            end if;
         else
            --  Ada also permits plain incomplete type declarations:
            --     type T;
            --     type T (D : Positive);
            --  Keep these explicit so outline/semantic recovery sees a real
            --  declaration node rather than only a generic type declaration
            --  followed by opaque semicolon recovery.
            Add_Production
              (Result, Production_Incomplete_Type_Declaration, Tok,
               "incomplete type declaration");
            Skip_Balanced_To (Position, ";");
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Type_Declaration_Terminator,
                  Current (Position), "type declaration terminator");
               Advance (Position);
            else
               Add_Production
                 (Result,
                  Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                  Current (Position),
                  "type declaration missing terminator recovery boundary");
            end if;
         end if;
      elsif L0 = "subtype" then
         Add_Production (Result, Production_Subtype_Declaration, Tok, "subtype declaration");
         Advance (Position);
         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
         then
            Add_Production
              (Result, Production_Subtype_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
         end if;
         Parse_Defining_Name (Position, Result);
         if Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Subtype_Declaration_Subtype_Indication,
               Current (Position), "subtype declaration subtype indication");
            Parse_Subtype_Indication (Position, Result);
         end if;
         if Current_Lower (Position) = "with" then
            Parse_Aspect_Specification (Position, Result);
         end if;

         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Subtype_Declaration_Terminator,
               Current (Position), "subtype declaration terminator");
            Advance (Position);
         else
            Add_Production
              (Result,
               Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary,
               Current (Position),
               "subtype declaration missing terminator recovery boundary");
         end if;
      elsif L0 = "task" then
         if L1 = "body" then
            Add_Production (Result, Production_Task_Body, Tok, "task body");
            Advance (Position); -- task
            Advance (Position); -- body
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Task_Body_Name, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "separate") then
               Add_Production (Result, Production_Task_Body_Stub, Tok, "task body stub");
               Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "task body stub kind keyword");
               Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
               Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Body_Aspect_Specification,
                     Current (Position), "body aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Task_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Task_Body_Aspect_Specification,
                  Current (Position), "task body aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Body_Aspect_Specification);
            end if;
         else
            Add_Production (Result, Production_Task_Declaration, Tok, "task declaration");
            Advance (Position); -- task
            if Current_Lower (Position) = "type" then
               Add_Production
                 (Result, Production_Task_Type_Declaration, Tok,
                  "task type declaration");
               Advance (Position);
            end if;
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Parse_Defining_Name (Position, Result);
            end if;
            if To_String (Current (Position).Text) = "(" then
               Parse_Discriminant_Part (Position, Result);
            end if;
            if Has_Token_Before_Semicolon (Position, "is") then
               Add_Production (Result, Production_Task_Definition, Tok, "task definition");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Task_Declaration_Aspect_Specification,
                     Current (Position), "task declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Concurrent_Type_Aspect_Specification);
               Add_Concurrent_Definition_Part_Productions
                 (Position, Result,
                  Production_Task_Definition_Public_Part,
                  Production_Task_Definition_Private_Part,
                  "task definition");
            else
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Task_Declaration_Aspect_Specification,
                     Current (Position), "task declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Concurrent_Type_Aspect_Specification);
            end if;
         end if;
      elsif L0 = "protected" then
         if L1 = "body" then
            Add_Production (Result, Production_Protected_Body, Tok, "protected body");
            Advance (Position); -- protected
            Advance (Position); -- body
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Protected_Body_Name, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "separate") then
               Add_Production (Result, Production_Protected_Body_Stub, Tok, "protected body stub");
               Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "protected body stub kind keyword");
               Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
               Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Body_Aspect_Specification,
                     Current (Position), "body aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Protected_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Protected_Body_Aspect_Specification,
                  Current (Position), "protected body aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Body_Aspect_Specification);
            end if;
         else
            Add_Production (Result, Production_Protected_Declaration, Tok, "protected declaration");
            Advance (Position); -- protected
            if Current_Lower (Position) = "type" then
               Add_Production
                 (Result, Production_Protected_Type_Declaration, Tok,
                  "protected type declaration");
               Advance (Position);
            end if;
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Parse_Defining_Name (Position, Result);
            end if;
            if To_String (Current (Position).Text) = "(" then
               Parse_Discriminant_Part (Position, Result);
            end if;
            if Has_Token_Before_Semicolon (Position, "is") then
               Add_Production (Result, Production_Protected_Definition, Tok, "protected definition");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Protected_Declaration_Aspect_Specification,
                     Current (Position), "protected declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Concurrent_Type_Aspect_Specification);
               Add_Concurrent_Definition_Part_Productions
                 (Position, Result,
                  Production_Protected_Definition_Public_Part,
                  Production_Protected_Definition_Private_Part,
                  "protected definition");
            else
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Protected_Declaration_Aspect_Specification,
                     Current (Position), "protected declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Concurrent_Type_Aspect_Specification);
            end if;
         end if;
      elsif L0 = "entry" then
         if Has_Token_Before_Semicolon (Position, "separate")
           and then Has_Token_Before_Semicolon (Position, "is")
         then
            Add_Production (Result, Production_Entry_Body, Tok, "entry body");
            Add_Production (Result, Production_Entry_Body_Stub, Tok, "entry body stub");
            Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "entry body stub kind keyword");
            Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
            Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
         elsif Has_Token_Before_Semicolon (Position, "when")
           and then Has_Token_Before_Semicolon (Position, "is")
         then
            Add_Production (Result, Production_Entry_Body, Tok, "entry body");
            Add_Production (Result, Production_Entry_Barrier, Tok, "entry barrier");
         else
            Add_Production (Result, Production_Entry_Declaration, Tok, "entry declaration");
         end if;
         Advance (Position);
         if Current (Position).Kind = Token_Identifier or else Current (Position).Kind = Token_Keyword then
            Add_Production
              (Result, Production_Entry_Identifier, Current (Position),
               To_String (Current (Position).Text));
            Add_Production (Result, Production_Defining_Name, Current (Position), To_String (Current (Position).Text));
            Advance (Position);
         end if;
         Parse_Entry_Parenthesized_Parts (Position, Result, Tok);
         if Current_Lower (Position) = "is" then
            Add_Production
              (Result, Production_Entry_Body_Missing_Barrier_Recovery_Boundary,
               Current (Position), "entry body missing barrier recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected when barrier before entry body is");
         end if;
         if Current_Lower (Position) = "when" then
            Add_Production (Result, Production_Entry_Barrier, Current (Position), "entry barrier");
            Add_Production
              (Result, Production_Entry_Barrier_When_Keyword,
               Current (Position), "entry barrier when keyword");
            Advance (Position);
            if At_End (Position)
              or else Current_Lower (Position) = "is"
              or else Current_Lower (Position) = "with"
              or else Current_Lower (Position) = "begin"
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "then"
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result,
                  Production_Entry_Barrier_Missing_Condition_Recovery_Boundary,
                  Current (Position),
                  "entry barrier missing condition recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected entry barrier condition");
            else
               Add_Production
                 (Result, Production_Entry_Barrier_Condition,
                  Current (Position), "entry barrier condition");
               Parse_Expression (Position, Result);
            end if;
         end if;
         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Entry_Aspect_Specification,
               Current (Position), "entry aspect placement");
            Parse_Aspect_Specification (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Advance (Position);
            if Current_Lower (Position) = "separate" then
               Advance (Position);
               if Current_Lower (Position) = "with" then
                  Add_Production
                    (Result, Production_Entry_Aspect_Specification,
                     Current (Position), "entry aspect placement");
               end if;
               --  Feed_Item body stubs share entry grammar before ``is`` but their
               --  trailing aspect belongs to the body-stub placement family.
               --  Retain that structural distinction for bounded parser-owned
               --  metadata; this is placement coverage, not entry-body legality
               --  checking.
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Entry_Body_Part_Productions (Position, Result);
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Entry_Aspect_Specification);
            end if;
         else
            --  Feed_Item declarations have their own terminator/recovery
            --  metadata so task/protected declaration scans can distinguish
            --  an in-progress entry specification from following declarations
            --  without relying on rendering or compiler feedback.
            Skip_Balanced_To (Position, "with", ";");
            if Current_Lower (Position) = "with" then
               Add_Production
                 (Result, Production_Entry_Aspect_Specification,
                  Current (Position), "entry aspect placement");
               Parse_Aspect_Specification (Position, Result);
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Entry_Terminator,
                  Current (Position), "entry declaration terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Entry_Missing_Terminator_Recovery_Boundary,
                  Tok, "entry declaration missing terminator recovery boundary");
            end if;
         end if;
      elsif L0 = "parallel" then
         Add_Production (Result, Production_Parallel_Loop_Statement, Tok, "parallel loop statement");
         Add_Production
           (Result, Production_Parallel_Loop_Keyword, Tok,
            "parallel loop keyword");
         Advance (Position);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = "("
         then
            Add_Production
              (Result, Production_Parallel_Loop_Chunk_Specification,
               Current (Position), "parallel loop chunk specification");
            declare
               Chunk_Pos : Cursor := Position;
            begin
               Advance (Chunk_Pos);
               if not At_End (Chunk_Pos)
                 and then To_String (Current (Chunk_Pos).Text) /= ")"
               then
                  Add_Production
                    (Result, Production_Parallel_Loop_Chunk_Expression,
                     Current (Chunk_Pos), "parallel loop chunk expression");
               end if;
            end;
            Parse_Association_List (Position, Result);
         end if;
         if Current_Lower (Position) = "for"
           or else Current_Lower (Position) = "while"
           or else Current_Lower (Position) = "loop"
         then
            Add_Production
              (Result, Production_Parallel_Loop_Iteration_Scheme,
               Current (Position), "parallel loop iteration scheme");
            Parse_Declaration_Or_Statement (Position, Result);
         else
            Add_Production
              (Result, Production_Parallel_Loop_Recovery_Boundary, Tok,
               "parallel loop recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected loop scheme after parallel");
            Skip_Balanced_To (Position, "loop", ";");
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "parallel loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "parallel loop statements");
               Add_Production
                 (Result, Production_Statement_Sequence, Tok,
                  "parallel loop statements");
            end if;
         end if;
      elsif L0 = "for" then
         if Lookahead_Lower (Position, 2) = "in" or else Lookahead_Lower (Position, 3) = "in" then
            Add_Production (Result, Production_Loop_Statement, Tok, "for loop statement");
            Add_Production
              (Result, Production_For_Loop_Iteration_Scheme, Tok,
               "for loop iteration scheme");
            Add_Production (Result, Production_Loop_Parameter_Specification, Tok, "for loop parameter specification");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_For_Loop_Parameter, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Match_Keyword (Position, "in") then
               null;
            end if;
            if Current_Lower (Position) = "reverse" then
               Add_Production
                 (Result, Production_For_Loop_Reverse_Iteration,
                  Current (Position), "for loop reverse iteration");
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "when") then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
            end if;
            if not At_Loop_Domain_Reserved_Boundary (Position) then
               declare
                  Domain_Tok : constant Token_Info := Current (Position);
               begin
                  Add_Production
                    (Result, Production_For_Loop_Iteration_Domain, Domain_Tok,
                     "for loop iteration domain");
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production
                       (Result, Production_For_Loop_Range_Iteration, Domain_Tok,
                        "for loop range iteration");
                     Add_Production
                       (Result, Production_Range_Expression, Domain_Tok,
                        "for loop discrete range");
                     Parse_Expression (Position, Result);
                  end if;
               end;
            elsif not At_End (Position) then
               Add_Production
                 (Result, Production_For_Loop_Missing_Domain_Recovery_Boundary,
                  Tok, "for loop missing domain recovery boundary");
               Add_Production
                 (Result, Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary,
                  Current (Position), "for loop domain reserved boundary recovery");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected iteration domain in for loop statement");
            end if;
            if Current_Lower (Position) = "when" then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
               Advance (Position);
               if At_Iterator_Filter_Condition_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                     Current (Position),
                     "missing loop iterator filter condition");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected loop iterator filter condition");
               else
                  Add_Production
                    (Result, Production_Loop_Iterator_Filter_Condition,
                     Current (Position), "loop iterator filter condition");
                  Parse_Expression (Position, Result);
               end if;
            end if;
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "for loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "for loop statements");
               Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
               if Current_Lower (Position) = "end"
                 and then Lookahead_Lower (Position, 1) = "loop"
               then
                  Add_Production
                    (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                     Current (Position), "for loop missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected statement in for loop body");
               end if;
            else
               Add_Production
                 (Result, Production_For_Loop_Missing_Loop_Recovery_Boundary,
                  Tok, "for loop missing loop recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected loop in for loop statement");
               Skip_Balanced_To (Position, "loop", ";");
               if Match_Keyword (Position, "loop") then
                  Add_Production
                    (Result, Production_Loop_Begin_Keyword, Tok,
                     "for loop begin keyword");
                  Add_Production
                    (Result, Production_Loop_Statement_Sequence, Tok,
                     "for loop statements");
                  Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
               end if;
            end if;
         elsif Lookahead_Lower (Position, 2) = "of" or else Lookahead_Lower (Position, 3) = "of" then
            --  Ada iterator loops use ``for C of Container loop`` (and the
            --  reverse form) rather than a discrete loop parameter.  Keep the
            --  element name and iterable domain structural instead of skipping
            --  the entire iteration scheme to ``loop``.
            Add_Production (Result, Production_Loop_Statement, Tok, "iterator loop statement");
            Add_Production
              (Result, Production_Iterator_Loop_Iteration_Scheme, Tok,
               "iterator loop iteration scheme");
            Add_Production (Result, Production_Iterator_Specification, Tok, "iterator specification");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Iterator_Loop_Element, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Match_Keyword (Position, "of") then
               null;
            end if;
            if Current_Lower (Position) = "reverse" then
               Add_Production
                 (Result, Production_Iterator_Loop_Reverse_Iteration,
                  Current (Position), "iterator loop reverse iteration");
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "when") then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
            end if;
            if not At_Loop_Domain_Reserved_Boundary (Position) then
               Add_Production
                 (Result, Production_Iterator_Loop_Domain, Current (Position),
                  "iterator loop domain");
               Parse_Expression (Position, Result);
            elsif not At_End (Position) then
               Add_Production
                 (Result, Production_Iterator_Loop_Missing_Domain_Recovery_Boundary,
                  Tok, "iterator loop missing domain recovery boundary");
               Add_Production
                 (Result, Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary,
                  Current (Position), "iterator loop domain reserved boundary recovery");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected iteration domain in iterator loop statement");
            end if;
            if Current_Lower (Position) = "when" then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
               Advance (Position);
               if At_Iterator_Filter_Condition_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                     Current (Position),
                     "missing loop iterator filter condition");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected loop iterator filter condition");
               else
                  Add_Production
                    (Result, Production_Loop_Iterator_Filter_Condition,
                     Current (Position), "loop iterator filter condition");
                  Parse_Expression (Position, Result);
               end if;
            end if;
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "iterator loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "iterator loop statements");
               Add_Production (Result, Production_Statement_Sequence, Tok, "iterator loop statements");
               if Current_Lower (Position) = "end"
                 and then Lookahead_Lower (Position, 1) = "loop"
               then
                  Add_Production
                    (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                     Current (Position), "iterator loop missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected statement in iterator loop body");
               end if;
            else
               Add_Production
                 (Result, Production_Iterator_Loop_Missing_Loop_Recovery_Boundary,
                  Tok, "iterator loop missing loop recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected loop in iterator statement");
               Skip_Balanced_To (Position, "loop", ";");
               if Match_Keyword (Position, "loop") then
                  Add_Production
                    (Result, Production_Loop_Begin_Keyword, Tok,
                     "iterator loop begin keyword");
                  Add_Production
                    (Result, Production_Loop_Statement_Sequence, Tok,
                     "iterator loop statements");
                  Add_Production (Result, Production_Statement_Sequence, Tok, "iterator loop statements");
               end if;
            end if;
         else
            Parse_Representation_Clause (Position, Result);
         end if;
      elsif L0 = "private" then
         Add_Production (Result, Production_Private_Part, Tok, "private");
         Advance (Position);
      elsif L0 = "with" then
         --  Ada aspect clauses are representation/operational items in
         --  declarative contexts.  Keep standalone ``with Aspect => ...;``
         --  clauses distinct from attached aspect specifications while
         --  reusing the aspect-association parser.
         Add_Production (Result, Production_Aspect_Clause, Tok, "aspect clause");
         Add_Production (Result, Production_Operational_Item, Tok, "operational item");
         Parse_Aspect_Specification (Position, Result);
         if To_String (Current (Position).Text) = ";" then
            Advance (Position);
         end if;
      elsif L0 = "for" then
         if Lookahead_Lower (Position, 2) = "in"
           or else Lookahead_Lower (Position, 3) = "in"
         then
            Parse_Statement_Phase (Position, Result);
         else
            Parse_Representation_Clause (Position, Result);
         end if;
      elsif Tok.Kind = Token_Identifier
        or else L0 = "if"
        or else L0 = "elsif"
        or else L0 = "else"
        or else L0 = "parallel"
        or else L0 = "while"
        or else L0 = "loop"
        or else L0 = "case"
        or else L0 = "declare"
        or else L0 = "begin"
        or else L0 = "exception"
        or else L0 = "end"
        or else L0 = "when"
        or else L0 = "pragma"
        or else L0 = "select"
        or else L0 = "or"
        or else L0 = "then"
        or else L0 = "accept"
        or else L0 = "return"
        or else L0 = "raise"
        or else L0 = "null"
        or else L0 = "exit"
        or else L0 = "goto"
        or else L0 = "delay"
        or else L0 = "terminate"
        or else L0 = "requeue"
        or else L0 = "abort"
      then
         Parse_Statement_Phase (Position, Result);
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "unrecognized token");
         Advance (Position);
      end if;
   end Parse_Declaration_Or_Statement;
