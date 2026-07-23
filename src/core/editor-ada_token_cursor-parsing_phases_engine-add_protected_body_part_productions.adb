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
   procedure Add_Protected_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Probe                 : Cursor := Position;
      After_Is              : Cursor := Position;
      Found_Is              : Boolean := False;
      In_Operation_Body     : Boolean := False;
      Operation_After_Is    : Boolean := False;
      Operation_In_Begin    : Boolean := False;
      Operation_Is_Entry   : Boolean := False;
      Operation_Name        : Ada.Strings.Unbounded.Unbounded_String;

      procedure Add_Protected_Declarative_Synchronizer (C : Cursor) is
         Lower : constant String := Current_Lower (C);
      begin
         if Lower = "begin" then
            Add_Production
              (Result, Production_Protected_Body_Declarative_Begin_Boundary,
               Current (C), "protected body declarative begin boundary");
         elsif Lower = "end" then
            Add_Production
              (Result, Production_Protected_Body_Declarative_End_Boundary,
               Current (C), "protected body declarative end boundary");
         end if;
      end Add_Protected_Declarative_Synchronizer;

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
                 and then Current_Lower (After_Is) /= "separate"
                 and then Current_Lower (After_Is) /= "end"
               then
                  Add_Production
                    (Result, Production_Protected_Body_Operation_Part,
                     Current (After_Is), "protected body operation part");
               end if;
               goto Continue_Scan;
            end if;
         elsif Current_Lower (Probe) = "procedure"
           or else Current_Lower (Probe) = "function"
           or else Current_Lower (Probe) = "entry"
         then
            In_Operation_Body := False;
            Operation_After_Is := False;
            Operation_In_Begin := False;
            Operation_Is_Entry := Current_Lower (Probe) = "entry";
            Operation_Name :=
              Ada.Strings.Unbounded.To_Unbounded_String
                (Lookahead_Lower (Probe, 1));
            Add_Production
              (Result, Production_Protected_Operation_Declaration,
               Current (Probe), "protected body operation");
            if Current_Lower (Probe) = "procedure" then
               Add_Production
                 (Result, Production_Protected_Procedure_Body,
                  Current (Probe), "protected procedure body");
            elsif Current_Lower (Probe) = "function" then
               Add_Production
                 (Result, Production_Protected_Function_Body,
                  Current (Probe), "protected function body");
            else
               Add_Production
                 (Result, Production_Protected_Entry_Body,
                  Current (Probe), "protected entry body");
               declare
                  Entry_Parts : Cursor := Probe;
               begin
                  Advance (Entry_Parts);
                  if not At_End (Entry_Parts)
                    and then (Current (Entry_Parts).Kind = Token_Identifier
                              or else Current (Entry_Parts).Kind = Token_Keyword)
                  then
                     Add_Production
                       (Result, Production_Entry_Identifier,
                        Current (Entry_Parts), "entry identifier");
                     Advance (Entry_Parts);
                  end if;
                  Parse_Entry_Parenthesized_Parts
                    (Entry_Parts, Result, Current (Probe));
               end;
            end if;
         elsif Current_Lower (Probe) = "when" then
            Add_Production
              (Result, Production_Protected_Entry_Barrier,
               Current (Probe), "protected entry barrier");
            if not At_End (Probe) then
               declare
                  Condition_Start : Cursor := Probe;
               begin
                  Advance (Condition_Start);
                  if At_End (Condition_Start)
                    or else Current_Lower (Condition_Start) = "is"
                    or else Current_Lower (Condition_Start) = "with"
                    or else Current_Lower (Condition_Start) = "begin"
                    or else Current_Lower (Condition_Start) = "end"
                    or else To_String (Current (Condition_Start).Text) = ";"
                  then
                     Add_Production
                       (Result,
                        Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary,
                        Current (Probe),
                        "protected entry barrier missing condition recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Probe),
                        "expected protected entry barrier condition");
                  else
                     Add_Production
                       (Result, Production_Protected_Entry_Barrier_Condition,
                        Current (Condition_Start),
                        "protected entry barrier condition");
                  end if;
               end;
            end if;
         elsif Operation_After_Is
           and then not Operation_In_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Protected_Body_Declarative_Item_Start,
               Current (Probe), "protected body declarative item start");
            Skip_Package_Declarative_Item
              (Probe, Result,
               Production_Protected_Body_Declarative_Item_Recovery_Boundary,
               "protected body declarative item recovery boundary");
            if not At_End (Probe) then
               Add_Protected_Declarative_Synchronizer (Probe);
            end if;
            goto Continue_Scan;
         elsif Current_Lower (Probe) = "is" and then not Operation_After_Is then
            if Operation_Is_Entry then
               Add_Production
                 (Result, Production_Entry_Body_Missing_Barrier_Recovery_Boundary,
                  Current (Probe), "entry body missing barrier recovery boundary");
               Add_Production
                 (Result, Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary,
                  Current (Probe), "protected entry body missing barrier recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Probe),
                  "expected when barrier before protected entry body is");
            end if;
            Operation_After_Is := True;
         elsif Current_Lower (Probe) = "with" then
            Add_Production
              (Result, Production_Protected_Operation_Aspect_Specification,
               Current (Probe), "protected operation aspect specification");
         elsif Current_Lower (Probe) = "begin" then
            In_Operation_Body := True;
            Operation_In_Begin := True;
            Add_Production
              (Result, Production_Protected_Body_Operation_Begin_Keyword,
               Current (Probe), "protected body operation begin keyword");
            if Operation_Is_Entry then
               Add_Production
                 (Result, Production_Entry_Body_Begin_Keyword,
                  Current (Probe), "entry body begin keyword");
               declare
                  Body_Start : Cursor := Probe;
               begin
                  Advance (Body_Start);
                  if At_End (Body_Start)
                    or else Current_Lower (Body_Start) = "end"
                    or else Current_Lower (Body_Start) = "or"
                    or else Current_Lower (Body_Start) = "else"
                    or else Current_Lower (Body_Start) = "then"
                    or else To_String (Current (Body_Start).Text) = ";"
                  then
                     Add_Production
                       (Result,
                        Production_Entry_Body_Missing_Statement_Recovery_Boundary,
                        Current (Body_Start),
                        "entry body missing statement recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Body_Start),
                        "expected statement sequence in entry body");
                  else
                     Add_Production
                       (Result, Production_Entry_Body_Statement_Sequence,
                        Current (Body_Start), "entry body statement sequence");
                     Add_Production
                       (Result, Production_Statement_Sequence,
                        Current (Body_Start), "entry body statement sequence");
                  end if;
               end;
            end if;
         elsif Operation_In_Begin
           and then Current_Lower (Probe) /= "end"
           and then Current_Lower (Probe) /= "exception"
         then
            declare
               Before : constant Natural := Mark (Probe);
            begin
               Parse_Declaration_Or_Statement (Probe, Result);
               if Mark (Probe) = Before then
                  Advance (Probe);
               end if;
            end;
            goto Continue_Scan;
         elsif Current_Lower (Probe) = "private" then
            Add_Production
              (Result, Production_Protected_Body_Recovery_Boundary,
               Current (Probe), "unexpected private in protected body recovery boundary");
         elsif Current_Lower (Probe) = "end" then
            if In_Operation_Body then
               declare
                  End_Token : constant Token_Info := Current (Probe);
                  Tail      : Cursor := Probe;
               begin
                  Advance (Tail);
                  if not At_End (Tail)
                    and then Is_Nested_Statement_End_Follower (Tail)
                  then
                     null;
                  else
                     declare
                        End_Name_Matches : Boolean := True;
                     begin
                        if Operation_Is_Entry
                          and then not At_End (Tail)
                          and then (Current (Tail).Kind = Token_Identifier
                                    or else Current (Tail).Kind = Token_String_Literal)
                          and then Current_Lower (Tail) /=
                            Ada.Strings.Unbounded.To_String (Operation_Name)
                        then
                           End_Name_Matches := False;
                           Add_Production
                             (Result,
                              Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                              End_Token,
                              "entry body missing end terminator recovery boundary");
                        end if;

                        if not End_Name_Matches then
                           In_Operation_Body := False;
                           Operation_After_Is := False;
                           Operation_In_Begin := False;
                           Operation_Is_Entry := False;
                           goto Continue_Scan;
                        end if;
                     end;

                     if Operation_Is_Entry then
                        Add_Production
                          (Result, Production_Entry_Body_End_Keyword,
                           End_Token, "entry body end keyword");
                     end if;
                     In_Operation_Body := False;
                     Operation_After_Is := False;
                     Operation_In_Begin := False;
                     Add_Production
                       (Result, Production_Protected_Body_Operation_End_Keyword,
                        End_Token, "protected body operation end keyword");
                     if not At_End (Tail)
                       and then (Current (Tail).Kind = Token_Identifier
                                 or else Current (Tail).Kind = Token_String_Literal)
                     then
                        if Operation_Is_Entry then
                           Add_Production
                             (Result, Production_Entry_Body_End_Name,
                              Current (Tail), "entry body end name");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_End_Name,
                           Current (Tail), "protected body operation end name");
                        Advance (Tail);
                     end if;
                     if not At_End (Tail)
                       and then To_String (Current (Tail).Text) = ";"
                     then
                        if Operation_Is_Entry then
                           Add_Production
                             (Result, Production_Entry_Body_End_Terminator,
                              Current (Tail), "entry body end terminator");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_End_Terminator,
                           Current (Tail), "protected body operation end terminator");
                        Probe := Tail;
                     else
                        if Operation_Is_Entry then
                           Add_Production
                             (Result,
                              Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                              End_Token,
                              "entry body missing end terminator recovery boundary");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary,
                           End_Token, "protected body operation missing end terminator recovery boundary");
                     end if;
                     Operation_Is_Entry := False;
                  end if;
               end;
            else
               Add_Production
                 (Result, Production_Protected_Body_End_Keyword,
                  Current (Probe), "protected body end keyword");
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Add_Production
                    (Result, Production_Protected_Body_End_Name,
                     Current (Probe), "protected body end name");
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Protected_Body_End_Terminator,
                     Current (Probe), "protected body end terminator");
               else
                  Add_Production
                    (Result, Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "protected body missing end terminator recovery boundary");
               end if;
               return;
            end if;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Protected_Body_Part_Productions;
