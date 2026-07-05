with Editor.Ada_Dataflow_Global_Depends_Legality;

package Editor.Ada_Integrated_Semantic_Closure.Dataflow is

   --  Case 1123 bridge from Global/Depends dataflow legality into integrated
   --  semantic closure.  Dataflow rows become ordinary closure contexts so
   --  the existing closure diagnostic feed, index, and provenance paths expose
   --  read/write/Depends blockers as semantic legality blockers.

   function Build_With_Dataflow
     (Contexts : Integrated_Closure_Context_Model;
      Dataflow : Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Dataflow;
