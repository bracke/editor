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
   procedure Add_Package_Declaration_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Probe          : Cursor := Position;
      Found_Is       : Boolean := False;
      In_Private     : Boolean := False;
      Visible_Opened : Boolean := False;
      Private_Opened : Boolean := False;
   begin
      while not At_End (Probe) loop
         declare
            L : constant String := Current_Lower (Probe);
            T : constant String := To_String (Current (Probe).Text);
         begin
            if not Found_Is then
               if L = "is" then
                  Found_Is := True;
                  Advance (Probe);
                  if not At_End (Probe)
                    and then Current_Lower (Probe) /= "private"
                    and then Current_Lower (Probe) /= "end"
                    and then To_String (Current (Probe).Text) /= ";"
                  then
                     Visible_Opened := True;
                     Add_Production
                       (Result, Production_Package_Visible_Part,
                        Current (Probe), "package visible part");
                  end if;
                  goto Continue_Scan;
               elsif T = ";" then
                  return;
               end if;

            elsif L = "begin" then
               if In_Private then
                  Add_Production
                    (Result, Production_Package_Private_Begin_Recovery_Boundary,
                     Current (Probe), "package private declarative begin recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Package_Unexpected_Begin_Boundary,
                  Current (Probe), "unexpected begin in package declaration");
               Add_Production
                 (Result, Production_Package_Declarative_Recovery_Boundary,
                  Current (Probe), "package declaration recovery boundary");
               return;

            elsif L = "private" and then In_Private then
               Add_Production
                 (Result, Production_Package_Duplicate_Private_Boundary,
                  Current (Probe), "duplicate package private boundary");
               Add_Production
                 (Result, Production_Package_Private_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "package private declarative item recovery boundary");
               Add_Production
                 (Result, Production_Package_Nested_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "package nested declarative item recovery boundary");
               Advance (Probe);
               goto Continue_Scan;

            elsif L = "private" and then not In_Private then
               In_Private := True;
               Private_Opened := True;
               Add_Production
                 (Result, Production_Package_Private_Declarative_Part,
                  Current (Probe), "package private declarative part");
               Advance (Probe);
               goto Continue_Scan;

            elsif L = "end" then
               Add_Production
                 (Result, Production_Package_Declaration_End_Keyword,
                  Current (Probe), "package declaration end keyword");
               Advance (Probe);
               if Current (Probe).Kind = Token_Identifier
                 or else Current (Probe).Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Package_Declaration_End_Name,
                     Current (Probe), "package declaration end name");
                  Advance (Probe);
               end if;
               if To_String (Current (Probe).Text) = ";" then
                  Add_Production
                    (Result, Production_Package_Declaration_End_Terminator,
                     Current (Probe), "package declaration end terminator");
               else
                  Add_Production
                    (Result,
                     Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary,
                     Current (Probe),
                     "package declaration missing end terminator recovery boundary");
               end if;
               return;

            elsif Starts_Package_Declarative_Item (Probe) then
               if In_Private then
                  if not Private_Opened then
                     Private_Opened := True;
                     Add_Production
                       (Result, Production_Package_Private_Declarative_Part,
                        Current (Probe), "package private declarative part");
                  end if;
                  Add_Production
                    (Result, Production_Package_Private_Declarative_Item,
                     Current (Probe), "package private declarative item");
               else
                  if not Visible_Opened then
                     Visible_Opened := True;
                     Add_Production
                       (Result, Production_Package_Visible_Part,
                        Current (Probe), "package visible part");
                  end if;
                  Add_Production
                    (Result, Production_Package_Visible_Declarative_Item,
                     Current (Probe), "package visible declarative item");
               end if;
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
               if (Current_Lower (Probe) = "procedure"
                   or else Current_Lower (Probe) = "function")
                 and then Has_Token_Before_Semicolon (Probe, "separate")
               then
                  declare
                     Item_Position : Cursor := Probe;
                  begin
                     Parse_Subprogram_Construct (Item_Position, Result);
                  end;
               end if;
               if In_Private then
                  Skip_Package_Declarative_Item
                    (Probe, Result,
                     Production_Package_Private_Declarative_Item_Recovery_Boundary,
                     "package private declarative item recovery boundary");
               else
                  Skip_Package_Declarative_Item
                    (Probe, Result,
                     Production_Package_Visible_Declarative_Item_Recovery_Boundary,
                     "package visible declarative item recovery boundary");
               end if;
               goto Continue_Scan;
            end if;
         end;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Package_Declaration_Part_Productions;
