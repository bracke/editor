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
   procedure Add_Discriminant_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is
      Inside : constant String := Segment_Between_First_Parens (Code);
   begin
      if Inside /= "" and then Contains (Inside, ":") then
         Add_Association_List_Nodes
           (Tree, Parent, Depth, Line, Inside, Node_Discriminant_Specification);
      end if;
   end Add_Discriminant_Nodes;
