with AUnit.Test_Cases;

package Editor.Input_Bridge.Tests is

   type Input_Bridge_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Input_Bridge_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Input_Bridge_Test_Case);

end Editor.Input_Bridge.Tests;
