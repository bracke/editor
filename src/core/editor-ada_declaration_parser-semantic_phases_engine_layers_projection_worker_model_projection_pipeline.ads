with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline is

   package Declaration_Collection renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
   package Target_Derivation renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
   package Legality renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
   package Executable_Binding renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
   package Publication renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;

   type Context (Node_Capacity : Positive) is record
      Declaration        : Declaration_Collection.Context (Node_Capacity);
      Target             : Target_Derivation.Context (Node_Capacity);
      Legal              : Legality.Context;
      Binding            : Executable_Binding.Context;
      Publish            : Publication.Context (Node_Capacity);
   end record;

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
         Flags       : Editor.Ada_Language_Model.Declaration_Flags));

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Pipeline;
