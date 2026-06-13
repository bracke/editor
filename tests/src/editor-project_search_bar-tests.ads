with AUnit.Test_Cases;

package Editor.Project_Search_Bar.Tests is

   type Project_Search_Bar_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Project_Search_Bar_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Project_Search_Bar_Test_Case);

end Editor.Project_Search_Bar.Tests;
