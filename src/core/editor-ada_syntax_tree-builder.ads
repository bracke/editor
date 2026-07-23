package Editor.Ada_Syntax_Tree.Builder is

   procedure Clear (Tree : in out Tree_Type);

   function Add_Node
     (Tree        : in out Tree_Type;
      Kind        : Node_Kind;
      Source_Span : Source_Range;
      Parent      : Node_Id := No_Node;
      Depth       : Natural := 0;
      Label       : String := "") return Node_Id;

end Editor.Ada_Syntax_Tree.Builder;
