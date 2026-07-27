with Editor.Ada_Language_Model;
with Editor.Folding;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;

package Editor.State_Syntax is

   type Syntax_Runtime_State is record
      Folding  : Editor.Folding.Folding_State;
      Cache    : Editor.Syntax_Cache.Syntax_Cache;
      Symbols  : Editor.Syntax_Semantics.Semantic_Map;
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
   end record;

end Editor.State_Syntax;
