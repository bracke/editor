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
   function Strip_Leading_With (Text : String) return String is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if Starts_With_Word (L, "with") then
         if T'Length <= 4 then
            return "";
         end if;
         return Trim (T (T'First + 4 .. T'Last));
      end if;
      return T;
   end Strip_Leading_With;
