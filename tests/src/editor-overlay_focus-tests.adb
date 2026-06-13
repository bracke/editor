with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;

package body Editor.Overlay_Focus.Tests is

   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Overlay_Focus.Previous_Focus_Target;

   function Name
     (T : Overlay_Focus_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Overlay_Focus.Tests");
   end Name;

   procedure Test_Defaults_To_No_Overlay
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Overlay_Focus.Overlay_Focus_State;
   begin
      Assert
        (Editor.Overlay_Focus.Active_Overlay (State) = Editor.Overlay_Focus.No_Overlay,
         "new overlay-focus state should have no active overlay");
      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (State),
         "new overlay-focus state should not report active overlay");
      Assert
        (not Editor.Overlay_Focus.Has_Previous_Focus (State),
         "new overlay-focus state should not have previous focus");
   end Test_Defaults_To_No_Overlay;

   procedure Test_Activate_Command_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Overlay_Focus.Overlay_Focus_State;
      Focus : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Overlay_Focus.Activate
        (State, Editor.Overlay_Focus.Command_Palette_Overlay, Focus);
      Assert
        (Editor.Overlay_Focus.Is_Active
           (State, Editor.Overlay_Focus.Command_Palette_Overlay),
         "Activate should make command palette the active overlay");
      Assert
        (Editor.Overlay_Focus.Previous_Focus (State) =
           Editor.Overlay_Focus.Previous_Editor_Text,
         "activation from default panel focus should store editor text");
   end Test_Activate_Command_Palette;

   procedure Test_Replacement_Preserves_Previous_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Overlay_Focus.Overlay_Focus_State;
      Focus : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_File_Tree (Focus);
      Editor.Overlay_Focus.Activate
        (State, Editor.Overlay_Focus.Command_Palette_Overlay, Focus);
      Editor.Panel_Focus.Focus_Editor_Text (Focus);
      Editor.Overlay_Focus.Activate
        (State, Editor.Overlay_Focus.Quick_Open_Overlay, Focus);
      Assert
        (Editor.Overlay_Focus.Is_Active
           (State, Editor.Overlay_Focus.Quick_Open_Overlay),
         "second activation should replace active overlay identity");
      Assert
        (Editor.Overlay_Focus.Previous_Focus (State) =
           Editor.Overlay_Focus.Previous_File_Tree,
         "replacement should not overwrite the original previous focus");
   end Test_Replacement_Preserves_Previous_Focus;

   procedure Test_Dismiss_Clears_Active_Overlay
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Overlay_Focus.Overlay_Focus_State;
      Focus : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Overlay_Focus.Activate
        (State, Editor.Overlay_Focus.Project_Search_Bar_Overlay, Focus);
      Editor.Overlay_Focus.Dismiss
        (State, Editor.Overlay_Focus.Dismiss_Escape);
      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (State),
         "Dismiss should clear active overlay");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (State) = Editor.Overlay_Focus.No_Overlay,
         "Dismiss should reset active overlay identity to No_Overlay");
      Assert
        (Editor.Overlay_Focus.Has_Previous_Focus (State),
         "Dismiss should leave previous focus available for executor restoration");
   end Test_Dismiss_Clears_Active_Overlay;

   procedure Test_Current_Panel_Focus_Target_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Focus : Editor.Panel_Focus.Panel_Focus_State;
   begin
      Editor.Panel_Focus.Focus_File_Tree (Focus);
      Assert
        (Editor.Overlay_Focus.Current_Panel_Focus_Target (Focus) =
           Editor.Overlay_Focus.Previous_File_Tree,
         "file-tree panel focus should map to file-tree previous focus");

      Editor.Panel_Focus.Focus_Bottom_Panel
        (Focus, Editor.Panel_Focus.Search_Results_Focus);
      Assert
        (Editor.Overlay_Focus.Current_Panel_Focus_Target (Focus) =
           Editor.Overlay_Focus.Previous_Search_Results,
         "Search Results panel focus should map to Search Results previous focus");

      Editor.Panel_Focus.Focus_Bottom_Panel
        (Focus, Editor.Panel_Focus.Problems_Focus);
      Assert
        (Editor.Overlay_Focus.Current_Panel_Focus_Target (Focus) =
           Editor.Overlay_Focus.Previous_Problems,
         "Problems panel focus should map to Problems previous focus");
   end Test_Current_Panel_Focus_Target_Mapping;

   procedure Register_Tests
     (T : in out Overlay_Focus_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Defaults_To_No_Overlay'Access,
         "new Overlay_Focus_State defaults to no overlay");
      Register_Routine
        (T, Test_Activate_Command_Palette'Access,
         "Activate stores active command palette and previous focus");
      Register_Routine
        (T, Test_Replacement_Preserves_Previous_Focus'Access,
         "replacement preserves original previous focus");
      Register_Routine
        (T, Test_Dismiss_Clears_Active_Overlay'Access,
         "Dismiss clears active overlay");
      Register_Routine
        (T, Test_Current_Panel_Focus_Target_Mapping'Access,
         "panel focus maps to previous overlay-focus target");
   end Register_Tests;

end Editor.Overlay_Focus.Tests;
