with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication is

   package Phase_Types renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
   package Declaration_Collection renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;

   type Context (Node_Capacity : Positive) is record
      Metadata_Facts       : Phase_Types.Metadata_Fact_Table (1 .. Node_Capacity);
      Metadata_Fact_Count  : Natural := 0;
      Aspect_Facts_Applied : Natural := 0;
      Pragma_Facts_Applied : Natural := 0;
      Variant_Facts_Applied : Natural := 0;
      Facts_Collected      : Boolean := False;
      Completed            : Boolean := False;
   end record;

   procedure Collect_Facts
     (Phase                   : in out Context;
      Declaration_Is_Complete : Boolean;
      Declarations            : Declaration_Collection.Context;
      Analysis                : Editor.Ada_Language_Model.Analysis_Result;
      Tree                    : Editor.Ada_Syntax_Tree.Tree_Type);

   procedure Apply_Aspects
     (Phase                  : in out Context;
      Analysis               : in out Editor.Ada_Language_Model.Analysis_Result;
      Representation_Context :
        Editor.Ada_Declaration_Parser.Representation_Application.Application_Context);

   procedure Finish
     (Phase                         : in out Context;
      Analysis                      : in out Editor.Ada_Language_Model.Analysis_Result;
      Executable_Binding_Is_Complete : Boolean;
      Legality_Is_Complete          : Boolean);

   function Facts_Are_Collected (Phase : Context) return Boolean;
   function Is_Complete (Phase : Context) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
