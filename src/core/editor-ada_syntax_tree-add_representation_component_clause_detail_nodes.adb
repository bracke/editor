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
   procedure Add_Representation_Component_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean    : constant String := Strip_Terminator (Text);
      Target   : constant String := Segment_Before (Clean, "at");
      Location : constant String := Segment_Before (Segment_After (Clean, "at"), "range");
      Bits     : constant String := Segment_After (Clean, "range");
   begin
      if Clean = "" then
         return;
      end if;

      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Target, Target);
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Item, "at " & Location);
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Range_Expression, Bits);
   end Add_Representation_Component_Clause_Detail_Nodes;
