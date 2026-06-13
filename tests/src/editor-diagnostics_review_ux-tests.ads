with AUnit.Test_Cases;

package Editor.Diagnostics_Review_UX.Tests is

   type Diagnostics_Review_UX_Test_Case is new AUnit.Test_Cases.Test_Case
     with null record;

   overriding function Name
     (T : Diagnostics_Review_UX_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Diagnostics_Review_UX_Test_Case);

end Editor.Diagnostics_Review_UX.Tests;
