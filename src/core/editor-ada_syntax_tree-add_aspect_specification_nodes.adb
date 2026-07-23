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
   procedure Add_Aspect_Specification_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Tail : constant String := Strip_Leading_With (Segment_After (Text, "with"));
      Spec : Node_Id;
   begin
      if Tail = "" then
         return;
      end if;

      Spec := Add_Node
        (Tree, Node_Aspect_Specification, (Line, 1, Line, Last_Column_For (Tail)),
         Parent, Depth, Tail);
      Add_Association_List_Nodes
        (Tree, Spec, Depth + 1, Line, Tail, Node_Aspect_Association);
   end Add_Aspect_Specification_Nodes;
