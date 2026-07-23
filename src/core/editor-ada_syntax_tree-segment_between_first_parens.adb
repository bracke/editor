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
   function Segment_Between_First_Parens (Text : String) return String is
      Open_Pos  : Natural := 0;
      Close_Pos : Natural := 0;
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Text'First;
   begin
      --  This helper is used for retained syntax-tree children such as
      --  pragma arguments and generic actuals.  It must find the balancing
      --  close parenthesis of the outer construct, not a parenthesis that
      --  happens to occur inside a string or character literal.
      while I <= Text'Last loop
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
            if Open_Pos = 0 then
               Open_Pos := I;
            end if;
            Level := Level + 1;
         elsif Text (I) = ')' and then Level > 0 then
            Level := Level - 1;
            if Level = 0 then
               Close_Pos := I;
               exit;
            end if;
         end if;
         I := I + 1;
      end loop;

      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos + 1 then
         return "";
      end if;
      return Trim (Text (Open_Pos + 1 .. Close_Pos - 1));
   end Segment_Between_First_Parens;
