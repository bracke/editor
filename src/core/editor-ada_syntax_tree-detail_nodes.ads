package Editor.Ada_Syntax_Tree.Detail_Nodes is

   function Last_Column_For (Text : String) return Positive;

   procedure Add_Name_Tokens
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String);

   procedure Add_Expression_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String);

   procedure Add_Detail_Node
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Label  : String);

end Editor.Ada_Syntax_Tree.Detail_Nodes;
