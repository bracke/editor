with AUnit.Test_Cases;

package Editor.Executor.Tests is

   type Executor_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Executor_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Executor_Test_Case);

end Editor.Executor.Tests;