with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

separate (Editor.Ada_Syntax_Tree)
   function Top_Level_Arrow_Position (Text : String) return Natural is
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Text'First;
   begin
      if Text'Length < 2 then
         return 0;
      end if;

      while I <= Text'Last - 1 loop
         if In_String then
            if Text (I) = '"' then
               if I + 1 <= Text'Last and then Text (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Text, I, Text'Last) then
            I := I + 2;
         elsif Text (I) = '"' then
            In_String := True;
         elsif Text (I) = '(' then
            Level := Level + 1;
         elsif Text (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Text (I) = '=' and then Text (I + 1) = '>' and then Level = 0 then
            return I;
         end if;
         I := I + 1;
      end loop;
      return 0;
   end Top_Level_Arrow_Position;
