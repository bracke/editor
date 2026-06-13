with AUnit.Test_Cases;

package Editor.Input_Field.Tests is

   type Input_Field_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Input_Field_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Input_Field_Test_Case);

end Editor.Input_Field.Tests;
