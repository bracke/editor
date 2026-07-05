with AUnit.Test_Cases;

package Test_Slice_Rules.Tests is

   type Test_Slice_Rules_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Test_Slice_Rules_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Test_Slice_Rules_Test_Case);

end Test_Slice_Rules.Tests;
