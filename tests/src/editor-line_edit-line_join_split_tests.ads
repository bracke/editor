with AUnit.Test_Cases;

package Editor.Line_Edit.Line_Join_Split_Tests is

   type LineJoinSplit_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : LineJoinSplit_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out LineJoinSplit_Test_Case);

end Editor.Line_Edit.Line_Join_Split_Tests;
