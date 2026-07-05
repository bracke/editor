with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;

package Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping is

   --  Case 1181 bridge from generic replay source/instance backmapping into
   --  integrated semantic closure.  This layer preserves generic body source,
   --  instantiation, formal, actual, substitution, replay-CPD, and overload/type
   --  edge blocker families as closure-visible semantic evidence.  It performs
   --  no parsing, file IO, dirty-state mutation, command routing, rendering, or
   --  diagnostic projection work.

   package Backmap renames
     Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;

   function Build_With_Generic_Backmapping
     (Contexts : Integrated_Closure_Context_Model;
      Backmaps : Backmap.Generic_Backmap_Model) return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
