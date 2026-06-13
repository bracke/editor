with AUnit.Test_Cases;

package Editor.External_Producers.Tests is

   type External_Producers_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : External_Producers_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out External_Producers_Test_Case);

end Editor.External_Producers.Tests;
