with AUnit.Test_Cases;

package Test_Ada_Shared_State_Stabilization_Gate_Legality_Pass1222 is
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Test_Case);
end Test_Ada_Shared_State_Stabilization_Gate_Legality_Pass1222;
