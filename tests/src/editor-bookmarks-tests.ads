with AUnit.Test_Cases;

package Editor.Bookmarks.Tests is

   type Bookmarks_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Bookmarks_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Bookmarks_Test_Case);

end Editor.Bookmarks.Tests;
