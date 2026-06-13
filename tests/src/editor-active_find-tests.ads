with AUnit.Test_Cases;

package Editor.Active_Find.Tests is

   type Active_Find_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Active_Find_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Active_Find_Test_Case);

end Editor.Active_Find.Tests;
