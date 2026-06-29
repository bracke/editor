with AUnit.Test_Cases;

package Editor.Configuration_Audit.Tests is

   type Configuration_Audit_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Configuration_Audit_Test_Case) return AUnit.Message_String;

   overriding procedure Set_Up
     (T : in out Configuration_Audit_Test_Case);

   overriding procedure Tear_Down
     (T : in out Configuration_Audit_Test_Case);

   overriding procedure Register_Tests
     (T : in out Configuration_Audit_Test_Case);

end Editor.Configuration_Audit.Tests;
