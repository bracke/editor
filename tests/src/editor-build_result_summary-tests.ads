with AUnit.Test_Cases;

package Editor.Build_Result_Summary.Tests is

   type Build_Result_Summary_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Build_Result_Summary_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Build_Result_Summary_Test_Case);

end Editor.Build_Result_Summary.Tests;
