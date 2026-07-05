with Editor.Ada_AST_Semantic_Coverage_Audit;

package Editor.Ada_Integrated_Semantic_Closure.AST_Coverage is

   --  Case 1133 bridge from parser/AST semantic coverage audit rows into
   --  integrated semantic closure.  Coverage gaps become closure blockers so
   --  missing Ada 2022 parser structure, metadata, or legality consumers cannot
   --  silently degrade widened semantic checking.

   function Build_With_AST_Coverage
     (Contexts : Integrated_Closure_Context_Model;
      Coverage : Editor.Ada_AST_Semantic_Coverage_Audit.Coverage_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.AST_Coverage;
