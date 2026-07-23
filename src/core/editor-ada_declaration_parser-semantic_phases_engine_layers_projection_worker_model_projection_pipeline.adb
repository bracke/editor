package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline is

   procedure Run
     (Pipeline            : in out Context;
      Analysis            : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree                : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text         : String;
      Representation_Context :
        Editor.Ada_Declaration_Parser.Representation_Application.Application_Context;
      Target_Actions      : Target_Derivation.Operations;
      Apply_Metadata_To_Target : not null access procedure
        (Target_Name : String;
         Flags       : Editor.Ada_Language_Model.Declaration_Flags))
   is
   begin
      Declaration_Collection.Run
        (Pipeline.Declaration,
         Analysis,
         Tree);
      Publication.Collect_Facts
        (Pipeline.Publish,
         Declaration_Collection.Is_Complete (Pipeline.Declaration),
         Pipeline.Declaration,
         Analysis,
         Tree);
      Target_Derivation.Run
        (Pipeline.Target,
         Declaration_Collection.Is_Complete (Pipeline.Declaration),
         Tree,
         Source_Text,
         Target_Actions);
      Publication.Apply_Aspects
        (Pipeline.Publish,
         Analysis,
         Representation_Context);
      Executable_Binding.Run
        (Pipeline.Binding,
         Pipeline.Publish,
         Analysis);
      Legality.Run
        (Pipeline.Legal,
         Pipeline.Publish,
         Analysis,
         Tree,
         Representation_Context,
         Target_Derivation.Static_Metadata_Is_Applied
           (Pipeline.Target),
         Apply_Metadata_To_Target);
      Publication.Finish
        (Pipeline.Publish,
         Analysis,
         Executable_Binding.Is_Complete (Pipeline.Binding),
         Legality.Is_Complete (Pipeline.Legal));
   end Run;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline;
