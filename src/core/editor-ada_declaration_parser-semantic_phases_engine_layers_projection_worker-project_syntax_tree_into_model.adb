with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
procedure Project_Syntax_Tree_Into_Model
  (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
   Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
   Source_Text : String)
is
begin
   Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection.Project_Syntax_Tree_Into_Model
     (Analysis    => Analysis,
      Tree        => Tree,
      Source_Text => Source_Text);
end Project_Syntax_Tree_Into_Model;
