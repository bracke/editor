with AUnit.Test_Cases;

package Editor.Project_Lifecycle.Tests is

   type Project_Lifecycle_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Project_Lifecycle_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Project_Lifecycle_Test_Case);

end Editor.Project_Lifecycle.Tests;
