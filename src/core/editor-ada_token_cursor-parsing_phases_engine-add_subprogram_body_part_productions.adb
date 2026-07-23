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
   procedure Add_Subprogram_Body_Part_Productions
     (Position  : Cursor;
      Result    : in out Grammar_Result;
      Body_Name : String) is
      pragma Suppress (Overflow_Check);
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Found_Is    : Boolean := True;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

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
      if not At_End (After_Is)
        and then Current_Lower (After_Is) /= "separate"
      then
         Add_Production
           (Result, Production_Subprogram_Body_Declarative_Part,
            Current (After_Is), "subprogram body declarative part");
      end if;

      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Subprogram_Body_Declarative_Part,
                     Current (After_Is), "subprogram body declarative part");
               end if;
               goto Continue_Scan;
            end if;

         elsif not Found_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Subprogram_Body_Declarative_Item,
               Current (Probe), "subprogram body declarative item");
            if (Current (Probe).Kind = Token_Identifier
                or else Current (Probe).Kind = Token_Keyword)
              and then Has_Token_Before_Semicolon (Probe, ":=")
            then
               declare
                  Item_Position : Cursor := Probe;
               begin
                  Parse_Declaration_Or_Statement (Item_Position, Result);
               end;
            end if;
            if Has_Token_Before_Semicolon (Probe, "for")
              and then Has_Token_Before_Semicolon (Probe, "=>")
            then
               declare
                  Item_Scan : Cursor := Probe;
               begin
                  while not At_End (Item_Scan)
                    and then To_String (Current (Item_Scan).Text) /= ";"
                  loop
                     if Current_Lower (Item_Scan) = "for" then
                        declare
                           Iterated_Position : Cursor := Item_Scan;
                        begin
                           Parse_Iterated_Component_Association
                             (Iterated_Position, Result);
                        end;
                        exit;
                     end if;
                     Advance (Item_Scan);
                  end loop;
               end;
            end if;
            Skip_Subprogram_Body_Declarative_Item (Probe, Result);
            goto Continue_Scan;

         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Subprogram_Body_Begin_Keyword,
               Current (Probe), "subprogram body begin keyword");
            Add_Production
              (Result, Production_Subprogram_Body_Statement_Sequence,
               Current (Probe), "subprogram body statements");

         elsif not Found_Begin
           and then (Current_Lower (Probe) = "exception"
                     or else Current_Lower (Probe) = "end")
         then
            Add_Production
              (Result, Production_Subprogram_Body_Recovery_Boundary,
               Current (Probe), "missing begin in subprogram body");
            if Current_Lower (Probe) = "end" then
               Add_Production
                 (Result, Production_Subprogram_Body_End_Keyword,
                  Current (Probe), "subprogram body end keyword");
               Advance (Probe);
               if Current (Probe).Kind = Token_Identifier
                 or else Current (Probe).Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Name,
                     Current (Probe), "subprogram body end name");
                  Advance (Probe);
               end if;
               if To_String (Current (Probe).Text) = ";" then
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Terminator,
                     Current (Probe), "subprogram body end terminator");
               else
                  Add_Production
                    (Result, Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "subprogram body missing end terminator recovery boundary");
               end if;
               return;
            end if;

         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Subprogram_Body_Exception_Part,
               Current (Probe), "subprogram body exception part");

         elsif Found_Begin and then Current_Lower (Probe) = "end" then
            declare
               End_Token : constant Token_Info := Current (Probe);
               Tail      : Cursor := Probe;
            begin
               Advance (Tail);
               if not At_End (Tail)
                 and then Is_Nested_Statement_End_Follower (Tail)
               then
                  Parse_Declaration_Or_Statement (Probe, Result);
                  goto Continue_Scan;
               elsif not At_End (Tail)
                 and then (Current (Tail).Kind = Token_Identifier
                           or else Current (Tail).Kind = Token_Keyword)
                 and then Body_Name'Length > 0
                 and then Current_Lower (Tail) /= Body_Name
               then
                  null;
               else
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Keyword,
                     End_Token, "subprogram body end keyword");
                  Probe := Tail;
                  if Current (Probe).Kind = Token_Identifier
                    or else Current (Probe).Kind = Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Subprogram_Body_End_Name,
                        Current (Probe), "subprogram body end name");
                     Advance (Probe);
                  end if;
                  if To_String (Current (Probe).Text) = ";" then
                     Add_Production
                       (Result, Production_Subprogram_Body_End_Terminator,
                        Current (Probe), "subprogram body end terminator");
                  else
                     Add_Production
                       (Result,
                        Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary,
                        Current (Position),
                        "subprogram body missing end terminator recovery boundary");
                  end if;
                  return;
               end if;
            end;
         elsif Found_Begin then
            if Current_Lower (Probe) = "pragma" then
               Skip_Balanced_To_Semicolon (Probe);
            else
               declare
                  Before : constant Natural := Mark (Probe);
               begin
                  Parse_Declaration_Or_Statement (Probe, Result);
                  if Mark (Probe) = Before then
                     Advance (Probe);
                  end if;
               end;
            end if;
            goto Continue_Scan;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;

      if Found_Is and then not Found_Begin then
         Add_Production
           (Result, Production_Subprogram_Body_Recovery_Boundary,
            Current (Position), "subprogram body missing begin/end boundary");
      end if;
   end Add_Subprogram_Body_Part_Productions;
