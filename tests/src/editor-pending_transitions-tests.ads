with AUnit.Test_Cases;

package Editor.Pending_Transitions.Tests is

   type Pending_Transitions_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Pending_Transitions_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Pending_Transitions_Test_Case);

end Editor.Pending_Transitions.Tests;
