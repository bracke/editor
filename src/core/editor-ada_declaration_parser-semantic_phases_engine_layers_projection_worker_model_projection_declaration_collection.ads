with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection is

   package Phase_Types renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;

   type Context (Node_Capacity : Positive) is record
      Node_Symbols      : Phase_Types.Node_Symbol_Map (1 .. Node_Capacity) :=
        (others => Editor.Ada_Language_Model.No_Symbol);
      Declaration_Count : Natural := 0;
      Completed         : Boolean := False;
   end record;

   procedure Run
     (Phase   : in out Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type);

   function Is_Complete (Phase : Context) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Declaration_Collection;
