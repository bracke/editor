with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;

package Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain is

   --  Case 1172 bridge from the repaired/gated semantic consumer chain into
   --  integrated semantic closure.  This package keeps the Case 1163-Case 1171
   --  chain visible to closure consumers by preserving the direct blocker
   --  family implied by generic replay representation contract-predicate-
   --  dataflow rows, instead of flattening those rows into an anonymous
   --  diagnostic projection.

   package GRR renames
     Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;

   function Build_With_Consumer_Chain
     (Contexts       : Integrated_Closure_Context_Model;
      Generic_Replay : GRR.Generic_Replay_Representation_Model)
      return Integrated_Closure_Model;

end Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
