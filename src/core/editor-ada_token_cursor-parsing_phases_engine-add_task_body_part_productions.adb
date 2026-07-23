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
   procedure Add_Task_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Found_Is    : Boolean := False;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

      procedure Add_Task_Declarative_Synchronizer (C : Cursor) is
         Lower : constant String := Current_Lower (C);
      begin
         if Lower = "begin" then
            Add_Production
              (Result, Production_Task_Body_Declarative_Begin_Boundary,
               Current (C), "task body declarative begin boundary");
         elsif Lower = "end" then
            Add_Production
              (Result, Production_Task_Body_Declarative_End_Boundary,
               Current (C), "task body declarative end boundary");
         end if;
      end Add_Task_Declarative_Synchronizer;

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
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "begin"
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Task_Body_Declarative_Part,
                     Current (After_Is), "task body declarative part");
               elsif not At_End (After_Is)
                 and then Current_Lower (After_Is) = "begin"
               then
                  Add_Production
                    (Result, Production_Task_Body_Declarative_Part,
                     Current (After_Is), "task body declarative part");
               end if;
               goto Continue_Scan;
            end if;
         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Task_Body_Begin_Keyword,
               Current (Probe), "task body begin keyword");
            Add_Production
              (Result, Production_Task_Body_Statement_Sequence,
               Current (Probe), "task body statements");
         elsif not Found_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Task_Body_Declarative_Item_Start,
               Current (Probe), "task body declarative item start");
            Skip_Package_Declarative_Item
              (Probe, Result,
               Production_Task_Body_Declarative_Item_Recovery_Boundary,
               "task body declarative item recovery boundary");
            if not At_End (Probe) then
               Add_Task_Declarative_Synchronizer (Probe);
            end if;
            goto Continue_Scan;
         elsif not Found_Begin
           and then (Current_Lower (Probe) = "exception"
                     or else Current_Lower (Probe) = "end")
         then
            Add_Production
              (Result, Production_Task_Body_Recovery_Boundary,
               Current (Probe), "task body missing begin recovery boundary");
            if Current_Lower (Probe) = "end" then
               Add_Production
                 (Result, Production_Task_Body_End_Keyword,
                  Current (Probe), "task body end keyword");
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Add_Production
                    (Result, Production_Task_Body_End_Name,
                     Current (Probe), "task body end name");
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Task_Body_End_Terminator,
                     Current (Probe), "task body end terminator");
               else
                  Add_Production
                    (Result, Production_Task_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "task body missing end terminator recovery boundary");
               end if;
               return;
            end if;
         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Task_Body_Exception_Part,
               Current (Probe), "task body exception part");
         elsif Found_Begin and then Current_Lower (Probe) = "end" then
            declare
               Tail : Cursor := Probe;
            begin
               Advance (Tail);
               if not At_End (Tail)
                 and then Is_Nested_Statement_End_Follower (Tail)
               then
                  Parse_Declaration_Or_Statement (Probe, Result);
                  goto Continue_Scan;
               end if;
            end;
            Add_Production
              (Result, Production_Task_Body_End_Keyword,
               Current (Probe), "task body end keyword");
            Advance (Probe);
            if not At_End (Probe)
              and then (Current (Probe).Kind = Token_Identifier
                        or else Current (Probe).Kind = Token_Keyword)
            then
               Add_Production
                 (Result, Production_Task_Body_End_Name,
                  Current (Probe), "task body end name");
               Advance (Probe);
            end if;
            if not At_End (Probe)
              and then To_String (Current (Probe).Text) = ";"
            then
               Add_Production
                 (Result, Production_Task_Body_End_Terminator,
                  Current (Probe), "task body end terminator");
            else
               Add_Production
                 (Result, Production_Task_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position), "task body missing end terminator recovery boundary");
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
   end Add_Task_Body_Part_Productions;
