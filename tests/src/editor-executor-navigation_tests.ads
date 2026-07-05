with AUnit.Test_Cases;

package Editor.Executor.Navigation_Tests is

   type Navigation_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Navigation_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Navigation_Test_Case);

end Editor.Executor.Navigation_Tests;
