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
   procedure Add_Representation_Clause_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean  : constant String := Strip_Terminator (Text);
      Clause : Node_Id;
   begin
      if Clean = "" then
         return;
      end if;

      Clause := Add_Node
        (Tree, Node_Representation_Clause,
         (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);
      Add_Representation_Clause_Detail_Nodes
        (Tree, Clause, Depth + 1, Line, Clean);
   end Add_Representation_Clause_Nodes;
