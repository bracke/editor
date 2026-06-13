with AUnit.Test_Cases;

package Editor.Line_Edit.Tests is

   type Line_Edit_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Line_Edit_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Line_Edit_Test_Case);

end Editor.Line_Edit.Tests;
