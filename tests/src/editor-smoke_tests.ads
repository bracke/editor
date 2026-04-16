with AUnit.Test_Cases;

package Editor.Smoke_Tests is

   type Smoke_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Smoke_Test_Case)
      return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Smoke_Test_Case);

end Editor.Smoke_Tests;