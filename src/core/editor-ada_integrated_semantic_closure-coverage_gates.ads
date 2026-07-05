with Editor.Ada_Semantic_Coverage_Gates;

package Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates is

   --  Case 1135 bridge from semantic coverage gates into integrated semantic
   --  closure.  Gate failures become first-class closure blockers so semantic
   --  diagnostics cannot present confident legality conclusions when the
   --  required parser, AST, metadata, cross-unit, or consumer coverage is
   --  incomplete.

   function Build_With_Coverage_Gates
     (Contexts : Integrated_Closure_Context_Model;
      Gates    : Editor.Ada_Semantic_Coverage_Gates.Gate_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates;
