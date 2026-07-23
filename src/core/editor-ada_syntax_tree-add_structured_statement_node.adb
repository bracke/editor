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
   procedure Add_Structured_Statement_Node
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Strip_Terminator (Text);
      Kind  : constant Node_Kind := Statement_Node_Kind (Clean);
      Stmt  : Node_Id;
   begin
      if Clean = "" then
         return;
      end if;

      Stmt := Add_Node
        (Tree, Kind, (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);

      if Is_Alternative then
         Add_Detail_Node
           (Tree, Stmt, Depth + 1, Line, Node_Statement_Alternative, Clean);
      end if;

      Attach_Syntax_Details (Tree, Stmt, Kind, Clean, Line, Depth + 1);
   end Add_Structured_Statement_Node;
