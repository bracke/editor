with AUnit.Test_Cases;

package Editor.Line_Edit.Line_Delete_Duplicate_Move_Tests is

   type LineDeleteDuplicateMove_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : LineDeleteDuplicateMove_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out LineDeleteDuplicateMove_Test_Case);

end Editor.Line_Edit.Line_Delete_Duplicate_Move_Tests;
