with AUnit.Test_Cases;

package Editor.Dirty_Guards.Tests is

   type Dirty_Guards_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Dirty_Guards_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Dirty_Guards_Test_Case);

end Editor.Dirty_Guards.Tests;
