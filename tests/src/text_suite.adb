with Buffer_Tests;

package body Text_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Buffer_Tests.Text_Buffer_Test_Case);
      return Ret;
   end Suite;

end Text_Suite;
