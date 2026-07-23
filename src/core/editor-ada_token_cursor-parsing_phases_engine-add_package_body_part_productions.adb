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
   procedure Add_Package_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Found_Is    : Boolean := False;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

      procedure Add_Nested_Subprogram_Body_Stubs (Start : Cursor) is
         Scan : Cursor := Start;
      begin
         while not At_End (Scan) loop
            exit when Current_Lower (Scan) = "begin"
              or else Current_Lower (Scan) = "exception"
              or else Current_Lower (Scan) = "end";
            if (Current_Lower (Scan) = "procedure"
                or else Current_Lower (Scan) = "function")
              and then Has_Token_Before_Semicolon (Scan, "separate")
            then
               Add_Production
                 (Result, Production_Subprogram_Body, Current (Scan),
                  "package body nested subprogram body");
               Add_Production
                 (Result, Production_Subprogram_Body_Stub, Current (Scan),
                  "package body nested subprogram body stub");
               Add_Production
                 (Result, Production_Body_Stub_Kind_Keyword, Current (Scan),
                  "package body nested subprogram body stub kind keyword");
               Add_Production
                 (Result, Production_Body_Stub_Separate_Keyword, Current (Scan),
                  "package body nested body stub separate keyword");
               Add_Production
                 (Result, Production_Body_Stub_Subunit_Link_Hint,
                  Current (Scan),
                  "package body nested body stub subunit link hint");
            end if;
            Advance (Scan);
         end loop;
      end Add_Nested_Subprogram_Body_Stubs;

      function Is_Nested_Statement_End_Follower (C : Cursor) return Boolean is
         Lower : constant String := Current_Lower (C);
      begin
         return Lower = "if"
           or else Lower = "loop"
           or else Lower = "case"
           or else Lower = "record"
           or else Lower = "select";
      end Is_Nested_Statement_End_Follower;
   begin
      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               Add_Nested_Subprogram_Body_Stubs (After_Is);
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Package_Body_Declarative_Part,
                     Current (After_Is), "package body declarative part");
               end if;
               goto Continue_Scan;
            end if;
         elsif not Found_Begin and then Current_Lower (Probe) = "private" then
            Add_Production
              (Result, Production_Package_Body_Unexpected_Private_Boundary,
               Current (Probe), "unexpected private in package body");
            Add_Production
              (Result, Production_Package_Body_Private_Declarative_Recovery_Boundary,
               Current (Probe), "package body private declarative recovery boundary");
            Add_Production
              (Result, Production_Package_Declarative_Recovery_Boundary,
               Current (Probe), "package body declarative recovery boundary");
            Add_Production
              (Result, Production_Package_Body_Declarative_Recovery_Boundary,
               Current (Probe), "package body declarative item recovery boundary");
         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Package_Body_Statement_Sequence,
               Current (Probe), "package body statements");
         elsif not Found_Begin and then Starts_Package_Declarative_Item (Probe) then
            Add_Production
              (Result, Production_Package_Body_Declarative_Item,
               Current (Probe), "package body declarative item");
            if (Current_Lower (Probe) = "procedure"
                or else Current_Lower (Probe) = "function")
              and then Has_Token_Before_Semicolon (Probe, "separate")
            then
               Add_Production
                 (Result, Production_Subprogram_Body, Current (Probe),
                  "package body nested subprogram body");
               Add_Production
                 (Result, Production_Subprogram_Body_Stub, Current (Probe),
                  "package body nested subprogram body stub");
               Add_Production
                 (Result, Production_Body_Stub_Kind_Keyword, Current (Probe),
                  "package body nested subprogram body stub kind keyword");
               Add_Production
                 (Result, Production_Body_Stub_Separate_Keyword, Current (Probe),
                  "package body nested body stub separate keyword");
               Add_Production
                 (Result, Production_Body_Stub_Subunit_Link_Hint,
                  Current (Probe),
                  "package body nested body stub subunit link hint");
            end if;
            Skip_Package_Declarative_Item
              (Probe, Result, Production_Package_Body_Declarative_Recovery_Boundary,
               "package body declarative item recovery boundary");
            goto Continue_Scan;
         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Package_Body_Exception_Part,
               Current (Probe), "package body exception part");
         elsif Current_Lower (Probe) = "end" then
            declare
               Tail : Cursor := Probe;
            begin
               Advance (Tail);
               if Found_Begin
                 and then not At_End (Tail)
                 and then Is_Nested_Statement_End_Follower (Tail)
               then
                  Parse_Declaration_Or_Statement (Probe, Result);
                  goto Continue_Scan;
               end if;
            end;
            Add_Production
              (Result, Production_Package_Body_End_Keyword,
               Current (Probe), "package body end keyword");
            Advance (Probe);
            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Package_Body_End_Name,
                  Current (Probe), "package body end name");
               Advance (Probe);
            end if;
            if To_String (Current (Probe).Text) = ";" then
               Add_Production
                 (Result, Production_Package_Body_End_Terminator,
                  Current (Probe), "package body end terminator");
            else
               Add_Production
                 (Result, Production_Package_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position), "package body missing end terminator recovery boundary");
            end if;
            return;
         elsif Found_Begin then
            declare
               Before : constant Natural := Mark (Probe);
            begin
               Parse_Declaration_Or_Statement (Probe, Result);
               if Mark (Probe) = Before then
                  Advance (Probe);
               end if;
            end;
            goto Continue_Scan;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Package_Body_Part_Productions;
