with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Panel_Focus;

package body Editor.Panel_Focus.Tests is

   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;

   function Name
     (T : Panel_Focus_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Panel_Focus.Tests");
   end Name;

   procedure Test_Defaults_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Assert
        (Editor.Panel_Focus.Target (State) = Editor.Panel_Focus.Editor_Text_Focus,
         "new panel focus state should target editor text");
      Assert
        (Editor.Panel_Focus.Bottom_Content (State) = Editor.Panel_Focus.No_Bottom_Focus,
         "new panel focus state should have no bottom-panel content");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (State),
         "editor text should report focus by default");
      Assert
        (not Editor.Panel_Focus.Bottom_Panel_Has_Focus (State),
         "bottom panel should not report focus by default");
   end Test_Defaults_To_Editor_Text;

   procedure Test_Focus_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_Bottom_Panel
        (State, Editor.Panel_Focus.Search_Results_Focus);
      Editor.Panel_Focus.Focus_Editor_Text (State);
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (State),
         "Focus_Editor_Text should restore editor text focus");
      Assert
        (Editor.Panel_Focus.Bottom_Content (State) = Editor.Panel_Focus.No_Bottom_Focus,
         "Focus_Editor_Text should clear bottom-panel content");
   end Test_Focus_Editor_Text;

   procedure Test_Focus_Search_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_Bottom_Panel
        (State, Editor.Panel_Focus.Search_Results_Focus);
      Assert
        (Editor.Panel_Focus.Bottom_Panel_Has_Focus (State),
         "Search Results focus should mark bottom panel focused");
      Assert
        (Editor.Panel_Focus.Bottom_Content (State) = Editor.Panel_Focus.Search_Results_Focus,
         "Search Results focus should store focused bottom content");
   end Test_Focus_Search_Results;

   procedure Test_Focus_Problems
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_Bottom_Panel
        (State, Editor.Panel_Focus.Problems_Focus);
      Assert
        (Editor.Panel_Focus.Bottom_Panel_Has_Focus (State),
         "Problems focus should mark bottom panel focused");
      Assert
        (Editor.Panel_Focus.Bottom_Content (State) = Editor.Panel_Focus.Problems_Focus,
         "Problems focus should store focused bottom content");
   end Test_Focus_Problems;

   procedure Test_Clear_Bottom_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_Bottom_Panel
        (State, Editor.Panel_Focus.Search_Results_Focus);
      Editor.Panel_Focus.Clear_Bottom_Focus (State);
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (State),
         "Clear_Bottom_Focus should restore editor text focus");
      Assert
        (not Editor.Panel_Focus.Bottom_Panel_Has_Focus (State),
         "Clear_Bottom_Focus should clear bottom panel focus");
   end Test_Clear_Bottom_Focus;



   procedure Test_Focus_File_Tree
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_File_Tree (State);
      Assert
        (Editor.Panel_Focus.Target (State) = Editor.Panel_Focus.File_Tree_Focus,
         "Focus_File_Tree should set file tree focus target");
      Assert
        (Editor.Panel_Focus.File_Tree_Has_Focus (State),
         "File_Tree_Has_Focus should report true for file tree focus");
      Assert
        (not Editor.Panel_Focus.Bottom_Panel_Has_Focus (State),
         "file tree focus must not report bottom panel focus");
      Assert
        (Editor.Panel_Focus.Bottom_Content (State) = Editor.Panel_Focus.No_Bottom_Focus,
         "file tree focus must clear bottom-panel content");
   end Test_Focus_File_Tree;

   procedure Test_File_Tree_Focus_Cleared_By_Other_Focuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_File_Tree (State);
      Editor.Panel_Focus.Focus_Bottom_Panel
        (State, Editor.Panel_Focus.Problems_Focus);
      Assert
        (not Editor.Panel_Focus.File_Tree_Has_Focus (State),
         "bottom panel focus should clear file tree focus");

      Editor.Panel_Focus.Focus_File_Tree (State);
      Editor.Panel_Focus.Focus_Editor_Text (State);
      Assert
        (not Editor.Panel_Focus.File_Tree_Has_Focus (State),
         "editor text focus should clear file tree focus");
   end Test_File_Tree_Focus_Cleared_By_Other_Focuses;

   procedure Register_Tests
     (T : in out Panel_Focus_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Defaults_To_Editor_Text'Access,
         "new Panel_Focus_State defaults to editor text focus");
      Register_Routine
        (T, Test_Focus_Editor_Text'Access,
         "Focus_Editor_Text sets editor focus");
      Register_Routine
        (T, Test_Focus_File_Tree'Access,
         "Focus_File_Tree sets file tree focus");
      Register_Routine
        (T, Test_File_Tree_Focus_Cleared_By_Other_Focuses'Access,
         "file tree focus is cleared by editor or bottom focus");
      Register_Routine
        (T, Test_Focus_Search_Results'Access,
         "Focus_Bottom_Panel supports Search Results focus");
      Register_Routine
        (T, Test_Focus_Problems'Access,
         "Focus_Bottom_Panel supports Problems focus");
      Register_Routine
        (T, Test_Clear_Bottom_Focus'Access,
         "Clear_Bottom_Focus returns to editor text focus");
   end Register_Tests;

end Editor.Panel_Focus.Tests;
