with AUnit.Test_Cases;

package Editor.Files.Target_Prompt_Tests is

   type Target_Prompt_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Target_Prompt_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Target_Prompt_Test_Case);

end Editor.Files.Target_Prompt_Tests;
