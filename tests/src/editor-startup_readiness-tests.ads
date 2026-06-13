with AUnit.Test_Cases;

package Editor.Startup_Readiness.Tests is

   type Startup_Readiness_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Startup_Readiness_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Startup_Readiness_Test_Case);

end Editor.Startup_Readiness.Tests;
