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
   function Segment_Between_First_Parens_After
     (Text   : String;
      Marker : String) return String
   is
      L : constant String := Lower (Text);
   begin
      for I in L'Range loop
         if I + Marker'Length - 1 <= L'Last
           and then L (I .. I + Marker'Length - 1) = Marker
         then
            if I + Marker'Length <= Text'Last then
               return Segment_Between_First_Parens
                 (Text (I + Marker'Length .. Text'Last));
            end if;
            return "";
         end if;
      end loop;

      return "";
   end Segment_Between_First_Parens_After;
