with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Overload_Ranking_Provenance;
with Editor.Ada_Semantic_Diagnostic_Index;

package body Test_Ada_Diagnostic_Provenance_Overload_Ranking is

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Provenance_Overload_Ranking");
   end Name;

   procedure Test_Empty_Integration_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model;
      Model : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
   begin
      Model := Editor.Ada_Diagnostic_Provenance.Build_With_Overload_Ranking
        (Index, Ranking_Provenance);

      Assert
        (Editor.Ada_Diagnostic_Provenance.Current (Model),
         "empty accepted diagnostic index should remain current");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Item_Count (Model) = 0,
         "empty index and ranking provenance should produce no diagnostic provenance items");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Overload_Ranking_Item_Count (Model) = 0,
         "empty ranking provenance should not produce ranking explanation items");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Count_Stage
           (Model,
            Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Overload_Ranking) = 0,
         "empty model should not report overload-ranking provenance stages");
   end Test_Empty_Integration_Is_Deterministic;

   procedure Test_Absent_Integrated_Lookup_Is_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model;
      Model : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model :=
        Editor.Ada_Diagnostic_Provenance.Build_With_Overload_Ranking
          (Index, Ranking_Provenance);
      Item : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Item;
   begin
      Item := Editor.Ada_Diagnostic_Provenance.First_For_Diagnostic
        (Model,
         Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry);
      Assert
        (not Editor.Ada_Diagnostic_Provenance.Has_Item (Item),
         "absent diagnostic lookup should return no provenance item");
   end Test_Absent_Integrated_Lookup_Is_Empty;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Integration_Is_Deterministic'Access,
         "Case 1073 keeps empty overload-ranking diagnostic provenance deterministic");
      Register_Routine
        (T, Test_Absent_Integrated_Lookup_Is_Empty'Access,
         "Case 1073 absent integrated provenance lookup returns no item");
   end Register_Tests;

end Test_Ada_Diagnostic_Provenance_Overload_Ranking;
