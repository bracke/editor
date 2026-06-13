with AUnit.Test_Cases;

package Editor.Problems.Tests is

   type Problems_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Problems_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Problems_Test_Case);

end Editor.Problems.Tests;
