with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers is

   function To_Model_Range
     (R : Editor.Ada_Syntax_Tree.Source_Range)
      return Editor.Ada_Language_Model.Source_Range;

   function First_Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String;

   function Source_Index_For
     (Source_Text : String;
      Line        : Positive;
      Column      : Positive) return Natural;

   function Full_Declaration_Default_Text
     (Source_Text   : String;
      N             : Editor.Ada_Syntax_Tree.Node_Info;
      Existing_Text : String) return String;

   function Is_Declaration_Node
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean;

   function Has_Child_Kind
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean;

   function Has_Ancestor_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Id   : Editor.Ada_Syntax_Tree.Node_Id;
      Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean;

   function Has_Direct_Generic_Parent
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info) return Boolean;

end Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
