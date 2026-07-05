with AUnit.Test_Cases;

package Editor.Command_Surface.Public_Build_Input_Tests is

   type Public_Build_Input_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Public_Build_Input_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Public_Build_Input_Test_Case);

end Editor.Command_Surface.Public_Build_Input_Tests;
