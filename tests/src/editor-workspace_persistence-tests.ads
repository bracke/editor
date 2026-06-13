with AUnit.Test_Cases;

package Editor.Workspace_Persistence.Tests is

   type Workspace_Persistence_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Workspace_Persistence_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Workspace_Persistence_Test_Case);

end Editor.Workspace_Persistence.Tests;
