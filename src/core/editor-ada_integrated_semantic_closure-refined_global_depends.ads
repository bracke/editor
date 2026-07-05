with Editor.Ada_Refined_Global_Depends_Conformance_Legality;

package Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends is

   --  Case 1154 bridge from Refined_Global / Refined_Depends body-spec
   --  conformance into integrated semantic closure.  This package makes the
   --  Case 1153 checker a first-class closure consumer instead of leaving its
   --  body/spec refinement failures isolated from the semantic-closure model.

   function Build_With_Refined_Global_Depends
     (Contexts : Integrated_Closure_Context_Model;
      Refined  : Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends;
