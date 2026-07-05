with AUnit.Test_Cases;

package Editor.Command_Surface.Route_Audit_Tests is

   type Route_Audit_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Route_Audit_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Route_Audit_Test_Case);

end Editor.Command_Surface.Route_Audit_Tests;
