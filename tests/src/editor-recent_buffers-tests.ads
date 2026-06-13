with AUnit.Test_Cases;

package Editor.Recent_Buffers.Tests is

   type Recent_Buffers_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Recent_Buffers_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Recent_Buffers_Test_Case);

end Editor.Recent_Buffers.Tests;
