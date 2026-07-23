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
   function First_Semicolon (Text : String) return Natural is
   begin
      for I in Text'Range loop
         if Text (I) = ';' then
            return I;
         end if;
      end loop;
      return 0;
   end First_Semicolon;
