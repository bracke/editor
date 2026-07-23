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
   function Subprogram_Profile_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
   begin
      if Contains (Clean, "(") then
         return Segment_Between_First_Parens (Clean);
      else
         return "";
      end if;
   end Subprogram_Profile_Text;
