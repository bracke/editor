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
   function If_Action_Text (Code : String) return String is
      Clean : constant String := Trim (Code);
      L     : constant String := Lower (Clean);
      Then_Pos : Natural := 0;
   begin
      for I in Clean'Range loop
         if I + 4 <= Clean'Last
           and then L (I .. I + 4) = " then"
           and then (I + 5 > Clean'Last or else not Is_Word_Char (L (I + 5)))
         then
            Then_Pos := I;
         end if;
      end loop;

      if Then_Pos = 0 or else Then_Pos + 5 > Clean'Last then
         return "";
      end if;

      return Trim (Clean (Then_Pos + 5 .. Clean'Last));
   end If_Action_Text;
