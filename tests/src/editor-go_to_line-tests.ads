with AUnit.Test_Cases;

package Editor.Go_To_Line.Tests is

   type Go_To_Line_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Go_To_Line_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Go_To_Line_Test_Case);

end Editor.Go_To_Line.Tests;
