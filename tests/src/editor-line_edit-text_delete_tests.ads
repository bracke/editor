with AUnit.Test_Cases;

package Editor.Line_Edit.Text_Delete_Tests is

   type TextDelete_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : TextDelete_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out TextDelete_Test_Case);

end Editor.Line_Edit.Text_Delete_Tests;
