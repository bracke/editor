with AUnit.Test_Cases;

package Editor.Command_Surface.Lifecycle_Surface_Tests is

   type Lifecycle_Surface_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Lifecycle_Surface_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Lifecycle_Surface_Test_Case);

end Editor.Command_Surface.Lifecycle_Surface_Tests;
