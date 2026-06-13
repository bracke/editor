with AUnit.Test_Cases;

package Editor.Missing_Stale_Recovery.Tests is

   type Missing_Stale_Recovery_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Missing_Stale_Recovery_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Missing_Stale_Recovery_Test_Case);

end Editor.Missing_Stale_Recovery.Tests;
