with Editor.Ada_Coverage_Gated_Semantic_Results;

package Editor.Ada_Integrated_Semantic_Closure.Gated_Results is

   --  Pass1136 bridge from coverage-gated semantic conclusions into
   --  integrated semantic closure.  Unlike the raw coverage-gate bridge, this
   --  path preserves the original semantic conclusion family and consumer for
   --  every suppressed, degraded, repaired, or cross-unit-required legality
   --  result.

   function Build_With_Gated_Results
     (Contexts : Integrated_Closure_Context_Model;
      Results  : Editor.Ada_Coverage_Gated_Semantic_Results.Gated_Result_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Gated_Results;
