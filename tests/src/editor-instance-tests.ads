with AUnit.Test_Cases;

package Editor.Instance.Tests is

   type Instance_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Instance_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Instance_Test_Case);

end Editor.Instance.Tests;