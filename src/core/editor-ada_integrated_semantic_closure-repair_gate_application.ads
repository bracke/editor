with Editor.Ada_AST_Coverage_Repair_Gate_Application;

package Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application is

   --  Case 1149 bridge from repair-applied coverage-gate results into
   --  integrated semantic closure.  Case 1148 decides whether concrete parser,
   --  AST, metadata, or consumer repairs clear widened legality coverage-gate
   --  enforcement rows.  This package feeds those repaired or still-blocking
   --  results back into closure so the unified diagnostic path sees restored
   --  confident semantic conclusions only when the repair actually cleared the
   --  gate.

   function Build_With_Repair_Gate_Application
     (Contexts     : Integrated_Closure_Context_Model;
      Applications : Editor.Ada_AST_Coverage_Repair_Gate_Application.Application_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application;
