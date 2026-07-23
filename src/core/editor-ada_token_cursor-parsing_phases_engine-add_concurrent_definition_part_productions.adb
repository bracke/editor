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
   procedure Add_Concurrent_Definition_Part_Productions
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Public_Kind  : Production_Kind;
      Private_Kind : Production_Kind;
      Label        : String)
   is
      pragma Suppress (Overflow_Check);
      Probe : Cursor := Position;
   begin
      if not At_End (Probe)
        and then Current_Lower (Probe) /= "private"
        and then Current_Lower (Probe) /= "end"
      then
         Add_Production
           (Result, Public_Kind, Current (Probe), Label & " public part");
      end if;

      while not At_End (Probe) loop
         declare
            L : constant String := Current_Lower (Probe);
         begin
            if L = "private" then
               Add_Production
                 (Result, Production_Private_Part, Current (Probe),
                  Label & " private part");
               Add_Production
                 (Result, Private_Kind, Current (Probe),
                  Label & " private part");
            elsif L = "procedure" or else L = "function" then
               Add_Production
                 (Result, Production_Subprogram_Declaration,
                  Current (Probe), "protected operation subprogram declaration");
               Add_Production
                 (Result, Production_Protected_Operation_Declaration,
                  Current (Probe), "protected operation declaration");
            elsif L = "pragma" then
               declare
                  Pragma_Probe : Cursor := Probe;
               begin
                  Parse_Pragma (Pragma_Probe, Result);
               end;
            elsif L = "entry" then
               Add_Production
                 (Result, Production_Entry_Declaration, Current (Probe),
                  "entry declaration");
               declare
                  Entry_Probe : Cursor := Probe;
               begin
                  Advance (Entry_Probe);
                  if not At_End (Entry_Probe)
                    and then (Current (Entry_Probe).Kind = Token_Identifier
                              or else Current (Entry_Probe).Kind = Token_Keyword)
                  then
                     Add_Production
                       (Result, Production_Entry_Identifier,
                        Current (Entry_Probe), "entry identifier");
                     Advance (Entry_Probe);
                  end if;

                  if not At_End (Entry_Probe)
                    and then To_String (Current (Entry_Probe).Text) = "("
                  then
                     declare
                        Family_Open : constant Token_Info := Current (Entry_Probe);
                        Scan        : Cursor := Entry_Probe;
                        Depth       : Natural := 0;
                        Has_Range   : Boolean := False;
                        Has_Profile_Separator : Boolean := False;
                        Closed      : Boolean := False;
                     begin
                        while not At_End (Scan) loop
                           if To_String (Current (Scan).Text) = "(" then
                              Depth := Depth + 1;
                           elsif To_String (Current (Scan).Text) = ")" then
                              if Depth = 0 then
                                 exit;
                              end if;
                              Depth := Depth - 1;
                              if Depth = 0 then
                                 Closed := True;
                                 exit;
                              end if;
                           elsif Current_Lower (Scan) = "range"
                             or else To_String (Current (Scan).Text) = ".."
                           then
                              Has_Range := True;
                           elsif Depth = 1
                             and then (To_String (Current (Scan).Text) = ":"
                                       or else To_String (Current (Scan).Text) = ";")
                           then
                              Has_Profile_Separator := True;
                           end if;
                           Advance (Scan);
                        end loop;

                        if Closed and then not Has_Profile_Separator then
                           Add_Production
                             (Result, Production_Entry_Family_Definition,
                              Family_Open, "entry family definition");
                           if Lookahead_Lower (Entry_Probe, 1) = ")" then
                              Add_Production
                                (Result,
                                 Production_Entry_Family_Empty_Definition_Recovery_Boundary,
                                 Family_Open,
                                 "entry family empty definition recovery boundary");
                              Add_Production
                                (Result, Production_Recovery_Point, Family_Open,
                                 "expected entry family discrete subtype definition");
                           else
                              Add_Production
                                (Result,
                                 Production_Entry_Family_Discrete_Subtype_Definition,
                                 Family_Open,
                                 "entry family discrete subtype definition");
                              Add_Production
                                (Result, Production_Entry_Family_Index_Subtype,
                                 Family_Open, "entry family index subtype");
                              if Has_Range then
                                 Add_Production
                                   (Result, Production_Entry_Family_Range_Definition,
                                    Family_Open, "entry family range definition");
                              end if;
                           end if;
                           Entry_Probe := Scan;
                           Advance (Entry_Probe);
                        end if;
                     end;
                  end if;

                  if not At_End (Entry_Probe)
                    and then To_String (Current (Entry_Probe).Text) = "("
                  then
                     Add_Production
                       (Result, Production_Entry_Parameter_Profile,
                        Current (Entry_Probe), "entry parameter profile");
                  end if;

                  declare
                     Tail  : Cursor := Probe;
                     Depth : Natural := 0;
                     Done  : Boolean := False;
                  begin
                     while not Done and then not At_End (Tail) loop
                        declare
                           TT : constant String := To_String (Current (Tail).Text);
                           TL : constant String := Current_Lower (Tail);
                        begin
                           if TT = "(" then
                              Depth := Depth + 1;
                           elsif TT = ")" and then Depth > 0 then
                              Depth := Depth - 1;
                           elsif TT = ";" and then Depth = 0 then
                              Add_Production
                                (Result, Production_Entry_Terminator,
                                 Current (Tail),
                                 "entry declaration terminator");
                              Done := True;
                           elsif Depth = 0
                             and then (TL = "private" or else TL = "end")
                           then
                              Add_Production
                                (Result,
                                 Production_Entry_Missing_Terminator_Recovery_Boundary,
                                 Current (Probe),
                                 "entry declaration missing terminator recovery boundary");
                              Done := True;
                           end if;
                        end;
                        if not Done then
                           Advance (Tail);
                        end if;
                     end loop;
                  end;
               end;
            elsif L = "with" then
               Add_Production
                 (Result, Production_Entry_Aspect_Specification,
                  Current (Probe), "entry aspect placement");
               Add_Production
                 (Result, Production_Protected_Operation_Aspect_Specification,
                  Current (Probe), "protected operation aspect specification");
               Add_Production
                 (Result, Production_Protected_Operation_Aspect_Attachment,
                  Current (Probe), "protected operation aspect attachment");
               declare
                  Aspect_Position : Cursor := Probe;
               begin
                  Parse_Aspect_Specification (Aspect_Position, Result);
               end;
            elsif L = "end" then
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Advance (Probe);
               end if;
               Position := Probe;
               exit;
            end if;
            Advance (Probe);
         end;
      end loop;
   end Add_Concurrent_Definition_Part_Productions;
