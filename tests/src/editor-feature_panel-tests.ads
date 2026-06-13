with AUnit.Test_Cases;

package Editor.Feature_Panel.Tests is
   type Feature_Panel_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Feature_Panel_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Feature_Panel_Test_Case);
end Editor.Feature_Panel.Tests;
