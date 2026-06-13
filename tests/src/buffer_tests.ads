with AUnit.Test_Cases;

package Buffer_Tests is

   type Text_Buffer_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding procedure Register_Tests
     (T : in out Text_Buffer_Test_Case);

   overriding function Name
     (T : Text_Buffer_Test_Case) return AUnit.Message_String;

end Buffer_Tests;