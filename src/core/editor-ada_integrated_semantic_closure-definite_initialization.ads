with Editor.Ada_Definite_Initialization_Flow_Legality;

package Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization is

   --  Pass1122 bridge from definite-initialization/flow legality into the
   --  integrated semantic closure model.  The bridge keeps initialization
   --  facts snapshot-owned and deterministic by translating the Pass1121 rows
   --  into ordinary closure contexts; the existing closure, diagnostic-feed,
   --  diagnostic-index, and provenance paths then consume them as first-class
   --  semantic blockers.

   function Build_With_Definite_Initialization
     (Contexts       : Integrated_Closure_Context_Model;
      Initialization : Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization;
