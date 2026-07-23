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
   procedure Parse_Representation_Target
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is
      pragma Suppress (Overflow_Check);
      Tok : constant Token_Info := Current (Position);

      function At_Representation_Target_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         S : constant String := To_String (Current (Position).Text);
      begin
         return S = ")"
           or else L = "private"
           or else L = "begin"
           or else L = "end"
           or else L = "with"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "type"
           or else L = "subtype"
           or else L = "task"
           or else L = "protected";
      end At_Representation_Target_Boundary;
   begin
      Add_Production
        (Result, Production_Representation_Target, Tok, To_String (Tok.Text));

      --  A representation/operational item target is a local_name/name before
      --  either ``use`` or an attribute designator.  Keep selected-name,
      --  indexed-prefix, and dereference shape, but deliberately stop before
      --  a top-level apostrophe so the following attribute_designator remains
      --  a distinct grammar production.
      while not At_End (Position)
        and then To_String (Current (Position).Text) /= Stop
        and then Current_Lower (Position) /= "use"
        and then To_String (Current (Position).Text) /= ";"
      loop
         if At_Representation_Target_Boundary then
            Add_Production
              (Result,
               Production_Representation_Target_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "representation target stopped at declaration boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected use or attribute designator after representation target");
            exit;
         end if;

         declare
            T : constant Token_Info := Current (Position);
            S : constant String := To_String (T.Text);
         begin
            if T.Kind = Token_Identifier or else T.Kind = Token_Keyword then
               Add_Production (Result, Production_Name, T, S);
               Advance (Position);
            elsif S = "." then
               Parse_Selected_Name_Suffix
                 (Position, Result, Tok, "representation target");
            elsif S = "(" then
               Add_Production
                    (Result, Production_Call_Or_Indexed_Component, Tok,
                     "call or indexed component suffix");
                  Add_Production (Result, Production_Indexed_Component, Tok, To_String (Tok.Text));
               Parse_Association_List (Position, Result);
            else
               Advance (Position);
            end if;
         end;
      end loop;
   end Parse_Representation_Target;
