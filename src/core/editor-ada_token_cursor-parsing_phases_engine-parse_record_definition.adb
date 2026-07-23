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
   procedure Parse_Record_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);
      Seen_Variant_Part : Boolean := False;

      procedure Mark_Variant_Choice_Details (From : Cursor) is
         Probe : Cursor := From;
         At_Choice_Start : Boolean := True;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
               L : constant String := Current_Lower (Probe);
            begin
               exit when T = "=>" or else T = ";" or else L = "when" or else L = "end";
               if L = "others" then
                  Add_Production
                    (Result, Production_Variant_Others_Choice,
                     Current (Probe), "variant others choice");
                  At_Choice_Start := False;
               elsif T = "|" then
                  Add_Production
                    (Result, Production_Variant_Choice_Separator,
                     Current (Probe), "variant choice separator");
                  At_Choice_Start := True;
               elsif T = ".." then
                  Add_Production
                    (Result, Production_Variant_Range_Choice,
                     Current (Probe), "variant range choice");
                  At_Choice_Start := False;
               elsif At_Choice_Start then
                  Add_Production
                    (Result, Production_Variant_Discrete_Choice,
                     Current (Probe), "variant discrete choice");
                  At_Choice_Start := False;
               end if;
               Advance (Probe);
            end;
         end loop;
      end Mark_Variant_Choice_Details;
   begin
      Add_Production (Result, Production_Record_Definition, Tok, "record definition");
      if Current_Lower (Position) = "record" then
         Advance (Position);
      end if;
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant String := To_String (Current (Position).Text);
            Item_Tok : constant Token_Info := Current (Position);
         begin
            if L = "end" and then Lookahead_Lower (Position, 1) = "case" then
               Advance (Position);
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Advance (Position);
               end if;
            elsif L = "end" then
               exit;
            elsif L = "case" then
               if Seen_Variant_Part then
                  Add_Production
                    (Result, Production_Nested_Variant_Part, Item_Tok,
                     "nested variant part");
               end if;
               Seen_Variant_Part := True;
               Add_Production (Result, Production_Variant_Part, Item_Tok, "variant part");
               Advance (Position);
               if not At_End (Position) and then Current_Lower (Position) /= "is" then
                  Add_Production
                    (Result, Production_Variant_Part_Discriminant_Name,
                     Current (Position), "variant part discriminant name");
                  Add_Production
                    (Result, Production_Name, Current (Position),
                     To_String (Current (Position).Text));
                  while not At_End (Position)
                    and then Current_Lower (Position) /= "is"
                  loop
                     Advance (Position);
                  end loop;
               end if;
               if Current_Lower (Position) = "is" then
                  Advance (Position);
               else
                  Add_Production
                    (Result, Production_Recovery_Point, Item_Tok,
                     "expected is in variant part");
                  Add_Production
                    (Result, Production_Variant_Recovery_Boundary, Item_Tok,
                     "variant part recovery boundary");
                  Advance_Through_Keyword (Position, "is");
               end if;
            elsif L = "when" then
               Add_Production (Result, Production_Variant, Item_Tok, "variant");
               Advance (Position);
               Add_Production
                 (Result, Production_Variant_Choice_List, Current (Position),
                  "variant choice list");
               Mark_Variant_Choice_Details (Position);
               Parse_Discrete_Choice_List (Position, Result, "=>");
               if To_String (Current (Position).Text) = "=>" then
                  Add_Production
                    (Result, Production_Variant_Choice_Arrow, Current (Position),
                     "variant choice arrow");
                  Advance (Position);
                  Add_Production
                    (Result, Production_Variant_Component_Part, Current (Position),
                     "variant component part");
               else
                  Add_Production
                    (Result, Production_Recovery_Point, Item_Tok,
                     "expected => in variant");
                  Add_Production
                    (Result, Production_Variant_Recovery_Boundary, Item_Tok,
                     "variant recovery boundary");
               end if;
            elsif Seen_Variant_Part and then L = "null" then
               Add_Production
                 (Result, Production_Variant_Null_Component_Part, Item_Tok,
                  "variant null component part");
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Advance (Position);
               end if;
            elsif Current (Position).Kind = Token_Identifier and then Has_Token_Before_Semicolon (Position, ":") then
               if Seen_Variant_Part then
                  Add_Production
                    (Result, Production_Variant_Component_Declaration, Item_Tok,
                     "variant component declaration");
               end if;
               Parse_Component_Declaration (Position, Result);
            elsif T = ";" then
               Advance (Position);
            else
               Advance (Position);
            end if;
         end;
      end loop;
      if Match_Keyword (Position, "end") then
         if Current_Lower (Position) = "case" then
            Advance (Position);
         end if;
         if Current_Lower (Position) = "record" then
            Advance (Position);
         end if;
      end if;
      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Record_Definition;
