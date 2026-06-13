with AUnit.Test_Cases;

package Editor.Empty_State_Guidance.Tests is

   type Empty_State_Guidance_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Empty_State_Guidance_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Empty_State_Guidance_Test_Case);

end Editor.Empty_State_Guidance.Tests;
