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
   function Segment_After (Text, Marker : String) return String is
      Marker_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Text), Lower (Marker));
      First : Natural;
   begin
      if Marker_Pos = 0 then
         return "";
      end if;
      First := Marker_Pos + Marker'Length;
      if First > Text'Last then
         return "";
      end if;
      return Trim (Text (First .. Text'Last));
   end Segment_After;
