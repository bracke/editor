with AUnit.Test_Cases;

package Editor.Executor.Lifecycle_Tests is

   type Lifecycle_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Lifecycle_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Lifecycle_Test_Case);

end Editor.Executor.Lifecycle_Tests;
