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
   function Code_Preserving_Literals_For_Retention (Line : String) return String is
      In_String : Boolean := False;
      I         : Natural := Line'First;
   begin
      --  Syntax classification still uses the generic sanitized line, but
      --  retained pragma argument nodes need literal text.  Operator-symbol
      --  pragma targets and pragma string arguments are semantically relevant
      --  to the bounded language model, so strip comments while preserving
      --  Ada string and character literals for syntax-tree children.
      while I <= Line'Last loop
         if In_String then
            if Line (I) = '"' then
               if I + 1 <= Line'Last and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Line, I, Line'Last) then
            I := I + 2;
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '-'
           and then I + 1 <= Line'Last
           and then Line (I + 1) = '-'
         then
            if I = Line'First then
               return "";
            else
               return Line (Line'First .. I - 1);
            end if;
         end if;
         I := I + 1;
      end loop;

      return Line;
   end Code_Preserving_Literals_For_Retention;
