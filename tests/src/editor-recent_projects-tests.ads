with AUnit.Test_Cases;

package Editor.Recent_Projects.Tests is

   type Recent_Projects_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Recent_Projects_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Recent_Projects_Test_Case);

end Editor.Recent_Projects.Tests;
