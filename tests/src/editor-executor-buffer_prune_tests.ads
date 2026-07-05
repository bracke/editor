with AUnit.Test_Cases;

package Editor.Executor.Buffer_Prune_Tests is

   type Buffer_Prune_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Buffer_Prune_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Buffer_Prune_Test_Case);

end Editor.Executor.Buffer_Prune_Tests;
