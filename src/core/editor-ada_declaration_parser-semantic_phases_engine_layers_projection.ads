with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection is

   procedure Project_Syntax_Tree_Into_Model
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text : String);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection;
