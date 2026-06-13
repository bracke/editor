with AUnit.Test_Cases;

package Test_Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality_Pass1248 is
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Test_Case);
end Test_Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality_Pass1248;
