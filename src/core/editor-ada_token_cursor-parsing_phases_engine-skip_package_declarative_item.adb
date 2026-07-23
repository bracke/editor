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
   procedure Skip_Package_Declarative_Item
     (Position      : in out Cursor;
      Result        : in out Grammar_Result;
      Boundary_Kind : Production_Kind;
      Boundary_Text : String) is
      pragma Suppress (Overflow_Check);
      Start_L0  : constant String := Current_Lower (Position);
      Depth     : Natural := 0;
      Seen_Tok  : Boolean := False;
      Saw_Begin : Boolean := False;
      Last_L    : Ada.Strings.Unbounded.Unbounded_String;

      procedure Add_Declarative_Boundary_Metadata
        (Tok : Token_Info;
         Lower_Text : String) is
      begin
         Add_Production (Result, Boundary_Kind, Tok, Boundary_Text);
         Add_Production
           (Result, Production_Package_Declarative_Recovery_Boundary,
            Tok, "package declarative recovery boundary");
         Add_Production
           (Result, Production_Package_Nested_Declarative_Item_Recovery_Boundary,
            Tok, "package nested declarative item recovery boundary");

         if Lower_Text = "private" then
            Add_Production
              (Result, Production_Package_Declarative_Private_Boundary, Tok,
               "package declarative private boundary");
         elsif Lower_Text = "begin" then
            Add_Production
              (Result, Production_Package_Declarative_Begin_Boundary, Tok,
               "package declarative begin boundary");
         elsif Lower_Text = "end" then
            Add_Production
              (Result, Production_Package_Declarative_End_Boundary, Tok,
               "package declarative end boundary");
         end if;
      end Add_Declarative_Boundary_Metadata;
   begin
      if (Start_L0 = "procedure" or else Start_L0 = "function")
        and then Has_Token_Before_Semicolon (Position, "separate")
      then
         declare
            Stub_Position : Cursor := Position;
         begin
            Parse_Subprogram_Construct (Stub_Position, Result);
         end;
      end if;

      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            N : constant String := Lookahead_Lower (Position, 1);
            T : constant String := To_String (Current (Position).Text);
         begin
            if Seen_Tok and then Depth = 0 then
               if L = "private"
                 and then not (Start_L0 = "type"
                               and then Ada.Strings.Unbounded.To_String (Last_L) = "is")
               then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               elsif L = "begin" or else L = "end" then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               elsif Starts_Strong_Package_Declarative_Item (Position) then
                  Add_Production (Result, Boundary_Kind, Current (Position), Boundary_Text);
                  return;
               end if;
            end if;

            if T = ";" and then Depth = 0 then
               Advance (Position);
               return;
            elsif L = "is" then
               if (Start_L0 = "package"
                   or else Start_L0 = "task"
                   or else Start_L0 = "protected"
                   or else Start_L0 = "procedure"
                   or else Start_L0 = "function"
                   or else Start_L0 = "entry")
                 and then N /= "new"
                 and then N /= "separate"
                 and then N /= "null"
                 and then N /= "abstract"
                 and then N /= "("
                 and then N /= ";"
               then
                  Depth := Depth + 1;
               end if;
            elsif L = "begin" then
               if Depth > 0 then
                  Saw_Begin := True;
                  Depth := Depth + 1;
               end if;
            elsif L = "record" or else L = "case" then
               if (Depth > 0 or else Start_L0 = "type" or else Start_L0 = "for")
                 and then not
                   (L = "record"
                    and then Ada.Strings.Unbounded.To_String (Last_L) = "null")
               then
                  Depth := Depth + 1;
               end if;
            elsif L = "end" then
               if Depth = 0 then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               end if;
               Depth := Depth - 1;
               if Depth = 0 or else (Saw_Begin and then Depth = 1) then
                  Advance (Position);
                  if not At_End (Position)
                    and then To_String (Current (Position).Text) = ";"
                  then
                     Advance (Position);
                  end if;
                  return;
               end if;
            end if;
         end;
         Seen_Tok := True;
         Last_L := Ada.Strings.Unbounded.To_Unbounded_String (Current_Lower (Position));
         Advance (Position);
      end loop;
   end Skip_Package_Declarative_Item;
