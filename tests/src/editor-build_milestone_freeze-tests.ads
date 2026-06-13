with AUnit.Test_Cases;

package Editor.Build_Milestone_Freeze.Tests is

   type Build_Milestone_Freeze_Test_Case is
     new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Build_Milestone_Freeze_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Build_Milestone_Freeze_Test_Case);

end Editor.Build_Milestone_Freeze.Tests;
