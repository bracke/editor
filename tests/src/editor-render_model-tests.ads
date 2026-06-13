with AUnit.Test_Cases;

package Editor.Render_Model.Tests is

   type Render_Model_Test_Case is
     new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Render_Model_Test_Case)
      return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Render_Model_Test_Case);

end Editor.Render_Model.Tests;