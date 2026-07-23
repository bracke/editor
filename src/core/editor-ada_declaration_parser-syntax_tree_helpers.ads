with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers is

   function First_Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String;

end Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers;
