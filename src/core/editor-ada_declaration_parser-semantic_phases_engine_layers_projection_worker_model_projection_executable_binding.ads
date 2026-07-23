with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding is

   package Publication renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;

   type Context is record
      Generic_Actual_Parts_Applied        : Natural := 0;
      Generic_Actual_Associations_Applied : Natural := 0;
      Completed                           : Boolean := False;
   end record;

   procedure Run
     (Phase                  : in out Context;
      Facts                  : Publication.Context;
      Analysis               : in out Editor.Ada_Language_Model.Analysis_Result);

   function Is_Complete (Phase : Context) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
