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
   function Split_Before_Top_Level_Arrow (Text : String) return String is
      Arrow : constant Natural := Top_Level_Arrow_Position (Text);
   begin
      if Arrow = 0 then
         return Trim (Text);
      elsif Arrow = Text'First then
         return "";
      else
         return Trim (Text (Text'First .. Arrow - 1));
      end if;
   end Split_Before_Top_Level_Arrow;
