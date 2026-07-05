with Editor.Outline.Tests;
with Editor.Syntax.Tests;
with Editor.Syntax_Cache.Tests;
with Editor.Syntax_Semantics.Tests;

package body Ada_Parser_Outline_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Syntax.Tests.Syntax_Test_Case);
      Ret.Add_Test (new Editor.Syntax_Cache.Tests.Syntax_Cache_Test_Case);
      Ret.Add_Test (new Editor.Syntax_Semantics.Tests.Syntax_Semantics_Test_Case);
      Ret.Add_Test (new Editor.Outline.Tests.Outline_Test_Case);
      return Ret;
   end Suite;

end Ada_Parser_Outline_Suite;
