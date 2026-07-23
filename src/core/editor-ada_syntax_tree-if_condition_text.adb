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
   function If_Condition_Text (Code, Prefix : String) return String is
      Clean : constant String := Trim (Code);
      L     : constant String := Lower (Clean);
      Start : Natural := Clean'First + Prefix'Length;
      Then_Pos : Natural := 0;
   begin
      while Start <= Clean'Last and then Clean (Start) = ' ' loop
         Start := Start + 1;
      end loop;

      for I in Clean'Range loop
         if I + 4 <= Clean'Last
           and then L (I .. I + 4) = " then"
           and then (I + 5 > Clean'Last or else not Is_Word_Char (L (I + 5)))
         then
            Then_Pos := I;
         end if;
      end loop;

      if Then_Pos = 0 or else Then_Pos <= Start then
         return "";
      end if;

      return Trim (Clean (Start .. Then_Pos - 1));
   end If_Condition_Text;
