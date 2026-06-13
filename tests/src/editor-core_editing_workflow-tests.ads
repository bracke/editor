with AUnit.Test_Cases;

package Editor.Core_Editing_Workflow.Tests is

   type Core_Editing_Workflow_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Core_Editing_Workflow_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Core_Editing_Workflow_Test_Case);

end Editor.Core_Editing_Workflow.Tests;
