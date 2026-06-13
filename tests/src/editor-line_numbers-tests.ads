with AUnit.Test_Cases;

package Editor.Line_Numbers.Tests is

   type Line_Numbers_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Line_Numbers_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Line_Numbers_Test_Case);

end Editor.Line_Numbers.Tests;
