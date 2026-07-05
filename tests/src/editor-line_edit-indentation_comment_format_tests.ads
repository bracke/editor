with AUnit.Test_Cases;

package Editor.Line_Edit.Indentation_Comment_Format_Tests is

   type IndentationCommentFormat_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : IndentationCommentFormat_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out IndentationCommentFormat_Test_Case);

end Editor.Line_Edit.Indentation_Comment_Format_Tests;
