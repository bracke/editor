with AUnit.Test_Suites; use AUnit.Test_Suites;
with Editor.Diagnostics.Tests;
with Editor.Diagnostics_Review_UX.Tests;
with Editor.Problems.Tests;

package body Diagnostics_Problems_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Problems.Tests.Problems_Test_Case);
      Ret.Add_Test (new Editor.Diagnostics.Tests.Diagnostics_Test_Case);
      Ret.Add_Test (new Editor.Diagnostics_Review_UX.Tests.Diagnostics_Review_UX_Test_Case);
      return Ret;
   end Suite;

end Diagnostics_Problems_Suite;
