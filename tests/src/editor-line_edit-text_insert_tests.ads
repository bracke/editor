with AUnit.Test_Cases;

package Editor.Line_Edit.Text_Insert_Tests is

   type TextInsert_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : TextInsert_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out TextInsert_Test_Case);

end Editor.Line_Edit.Text_Insert_Tests;
