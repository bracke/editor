with AUnit.Test_Cases;

package Editor.Focus_Management.Tests is

   type Focus_Management_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Focus_Management_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Focus_Management_Test_Case);

end Editor.Focus_Management.Tests;
