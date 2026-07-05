with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Overload_Ranking_Provenance;

package body Test_Ada_Overload_Ranking_Provenance is

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Overload_Ranking_Provenance");
   end Name;

   procedure Test_Empty_Models_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Rankings    : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Model       : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model;
   begin
      Model := Editor.Ada_Overload_Ranking_Provenance.Build (Diagnostics, Rankings);
      Assert
        (Editor.Ada_Overload_Ranking_Provenance.Item_Count (Model) = 0,
         "empty diagnostics and rankings should produce no provenance items");
      Assert
        (Editor.Ada_Overload_Ranking_Provenance.Exact_Outcome_Count (Model) = 0,
         "empty model should not report exact ranking provenance");
      Assert
        (Editor.Ada_Overload_Ranking_Provenance.Unlinked_Diagnostic_Count (Model) = 0,
         "empty model should not report unlinked diagnostics");
      Assert
        (Editor.Ada_Overload_Ranking_Provenance.Unlinked_Ranking_Count (Model) = 0,
         "empty model should not report unlinked rankings");
   end Test_Empty_Models_Are_Deterministic;

   procedure Test_No_Item_Lookups_Are_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Rankings    : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Model       : constant Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model :=
        Editor.Ada_Overload_Ranking_Provenance.Build (Diagnostics, Rankings);
      Item        : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item;
   begin
      Item := Editor.Ada_Overload_Ranking_Provenance.First_For_Ranking
        (Model, Editor.Ada_Overload_Ranking.No_Overload_Ranking);
      Assert
        (not Editor.Ada_Overload_Ranking_Provenance.Has_Item (Item),
         "lookup for an absent ranking should return no item");

      Item := Editor.Ada_Overload_Ranking_Provenance.First_For_Diagnostic
        (Model, Editor.Ada_Expression_Diagnostics.No_Expression_Diagnostic);
      Assert
        (not Editor.Ada_Overload_Ranking_Provenance.Has_Item (Item),
         "lookup for an absent diagnostic should return no item");
   end Test_No_Item_Lookups_Are_Empty;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Models_Are_Deterministic'Access,
         "Case 1072 keeps empty overload-ranking provenance deterministic");
      Register_Routine
        (T, Test_No_Item_Lookups_Are_Empty'Access,
         "Case 1072 absent provenance lookups return no item");
   end Register_Tests;

end Test_Ada_Overload_Ranking_Provenance;
