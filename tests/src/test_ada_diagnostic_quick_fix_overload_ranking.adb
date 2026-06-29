with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Overload_Ranking_Provenance;
with Editor.Ada_Semantic_Diagnostic_Index;

package body Test_Ada_Diagnostic_Quick_Fix_Overload_Ranking is

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Quick_Fix_Overload_Ranking");
   end Name;

   procedure Test_Empty_Integration_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model;
      Model : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
   begin
      Model := Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build_With_Overload_Ranking
        (Index, Ranking_Provenance);

      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Current (Model),
         "empty accepted diagnostic index should remain current");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidate_Count (Model) = 0,
         "empty index and ranking provenance should produce no quick-fix candidates");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Overload_Ranking_Candidate_Count
           (Model) = 0,
         "empty ranking provenance should not produce overload-ranking candidates");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Count_Action
           (Model,
            Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Overload_Ranking) = 0,
         "empty model should not report overload-ranking quick-fix actions");
   end Test_Empty_Integration_Is_Deterministic;

   procedure Test_Absent_Ranking_Action_Is_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model;
      Model : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model :=
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build_With_Overload_Ranking
          (Index, Ranking_Provenance);
      Candidate : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate;
   begin
      Candidate := Editor.Ada_Diagnostic_Quick_Fix_Skeleton.First_For_Diagnostic
        (Model,
         Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry);
      Assert
        (not Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Has_Candidate (Candidate),
         "absent diagnostic lookup should return no quick-fix candidate");
   end Test_Absent_Ranking_Action_Is_Empty;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Integration_Is_Deterministic'Access,
         "Pass1074 keeps empty overload-ranking quick-fix integration deterministic");
      Register_Routine
        (T, Test_Absent_Ranking_Action_Is_Empty'Access,
         "Pass1074 absent overload-ranking quick-fix lookup returns no candidate");
   end Register_Tests;

end Test_Ada_Diagnostic_Quick_Fix_Overload_Ranking;
