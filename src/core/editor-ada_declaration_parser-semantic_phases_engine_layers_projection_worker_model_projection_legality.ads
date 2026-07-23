with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality is

   package Publication renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;

   type Context is record
      Representation_Facts_Applied : Natural := 0;
      Completed                    : Boolean := False;
   end record;

   procedure Run
     (Phase                      : in out Context;
      Facts                      : Publication.Context;
      Analysis                   : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree                       : Editor.Ada_Syntax_Tree.Tree_Type;
      Representation_Context     :
        Editor.Ada_Declaration_Parser.Representation_Application.Application_Context;
      Target_Static_Metadata_Applied : Boolean;
      Apply_Metadata_To_Target   : not null access procedure
        (Target_Name : String;
         Flags       : Editor.Ada_Language_Model.Declaration_Flags));

   function Is_Complete (Phase : Context) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
