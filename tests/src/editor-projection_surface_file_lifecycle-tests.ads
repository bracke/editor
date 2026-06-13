with AUnit.Test_Cases;

package Editor.Projection_Surface_File_Lifecycle.Tests is

   type Projection_Surface_File_Lifecycle_Test_Case is
     new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Projection_Surface_File_Lifecycle_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Projection_Surface_File_Lifecycle_Test_Case);

end Editor.Projection_Surface_File_Lifecycle.Tests;
