with AUnit.Test_Cases;

package Test_Ada_Final_Semantic_Stabilized_Closure_Legality_Pass1209 is
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Test_Case);
end Test_Ada_Final_Semantic_Stabilized_Closure_Legality_Pass1209;
