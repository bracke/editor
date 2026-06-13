with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Syntax;
with Editor.Syntax_Overlays;

package body Editor.Syntax_Overlays.Tests is

   use type Editor.Syntax.Syntax_Kind;

   function Name (T : Syntax_Overlays_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Overlays.Tests");
   end Name;

   procedure Test_Precedence_And_Merge (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Syntax_Overlays.Merge
                (Editor.Syntax.Keyword, Editor.Syntax_Overlays.Diagnostic_Error_Overlay) =
              Editor.Syntax.Diagnostic_Error,
              "diagnostic error overlay overrides lexical token");
      Assert (Editor.Syntax_Overlays.Merge
                (Editor.Syntax.String_Literal, Editor.Syntax_Overlays.Search_Match_Overlay) =
              Editor.Syntax.Search_Match,
              "search overlay overrides string token");
      Assert (Editor.Syntax_Overlays.Precedence (Editor.Syntax.Selection_Overlay) >
              Editor.Syntax_Overlays.Precedence (Editor.Syntax.Search_Match),
              "selection must outrank search");
      Assert (Editor.Syntax_Overlays.Precedence (Editor.Syntax.Search_Match) >
              Editor.Syntax_Overlays.Precedence (Editor.Syntax.Diagnostic_Error),
              "search precedence follows the documented overlay order");
   end Test_Precedence_And_Merge;

   procedure Register_Tests (T : in out Syntax_Overlays_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Precedence_And_Merge'Access, "overlay merge and precedence");
   end Register_Tests;

end Editor.Syntax_Overlays.Tests;
