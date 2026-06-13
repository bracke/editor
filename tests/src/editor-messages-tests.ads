with AUnit.Test_Cases;

package Editor.Messages.Tests is

   type Messages_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Messages_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Messages_Test_Case);

end Editor.Messages.Tests;
