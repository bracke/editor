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
   function Strip_Terminator (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         return Trim (T (T'First .. T'Last - 1));
      end if;
      return T;
   end Strip_Terminator;
