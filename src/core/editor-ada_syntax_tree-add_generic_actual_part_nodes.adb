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
   procedure Add_Generic_Actual_Part_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Actuals : constant String := Segment_Between_First_Parens (Text);
      Part    : Node_Id;
   begin
      if Actuals = "" then
         return;
      end if;

      Part := Add_Node
        (Tree, Node_Generic_Actual_Part,
         (Line, 1, Line, Last_Column_For (Actuals)), Parent, Depth, Actuals);
      Add_Association_List_Nodes
        (Tree, Part, Depth + 1, Line, Actuals, Node_Generic_Actual_Association);
   end Add_Generic_Actual_Part_Nodes;
