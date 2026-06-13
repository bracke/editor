with AUnit.Test_Cases;

package Editor.Command_Extension_Readiness.Tests is

   type Command_Extension_Readiness_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Command_Extension_Readiness_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Command_Extension_Readiness_Test_Case);

end Editor.Command_Extension_Readiness.Tests;
