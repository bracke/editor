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
   procedure Add_Detail_Node
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Label  : String)
   is
   begin
      Detail_Nodes.Add_Detail_Node (Tree, Parent, Depth, Line, Kind, Label);
   end Add_Detail_Node;
