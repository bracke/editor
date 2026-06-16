with AUnit.Test_Cases;

package Editor.Dogfood_Workflow.Tests is

   type Dogfood_Workflow_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Dogfood_Workflow_Test_Case) return AUnit.Message_String;

   overriding procedure Set_Up (T : in out Dogfood_Workflow_Test_Case);

   overriding procedure Tear_Down (T : in out Dogfood_Workflow_Test_Case);

   overriding procedure Register_Tests (T : in out Dogfood_Workflow_Test_Case);

end Editor.Dogfood_Workflow.Tests;
