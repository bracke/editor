with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Input_Field;

package body Editor.Input_Field.Tests is

   function Name (T : Input_Field_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Input_Field");
   end Name;

   procedure Test_Empty_Set_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Assert (Editor.Input_Field.Is_Empty (F), "new field must be empty");
      Assert (Editor.Input_Field.Cursor_Column (F) = 0, "new field cursor must be zero");
      Editor.Input_Field.Set_Text (F, "abc");
      Assert (Editor.Input_Field.Text (F) = "abc", "Set_Text must store field text");
      Assert (Editor.Input_Field.Cursor_Column (F) = 3, "Set_Text must place cursor at end");
      Editor.Input_Field.Clear (F);
      Assert (Editor.Input_Field.Text (F) = "", "Clear must remove field text");
      Assert (Editor.Input_Field.Cursor_Column (F) = 0, "Clear must reset cursor");
   end Test_Empty_Set_Clear;

   procedure Test_Insert_And_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Editor.Input_Field.Set_Text (F, "ab");
      Editor.Input_Field.Move_Cursor_Left (F);
      Editor.Input_Field.Insert_Text (F, "X");
      Assert (Editor.Input_Field.Text (F) = "aXb", "Insert_Text must insert at cursor");
      Editor.Input_Field.Select_All (F);
      Assert (Editor.Input_Field.Has_Selection (F), "Select_All must activate selection");
      Assert (Editor.Input_Field.Selected_Text (F) = "aXb", "Selected_Text must return selected text");
      Editor.Input_Field.Insert_Text (F, "z");
      Assert (Editor.Input_Field.Text (F) = "z", "Insert_Text must replace selection");
      Assert (not Editor.Input_Field.Has_Selection (F), "Insert_Text must clear selection");
   end Test_Insert_And_Selection;

   procedure Test_Delete_Operations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Editor.Input_Field.Set_Text (F, "abc");
      Editor.Input_Field.Backspace (F);
      Assert (Editor.Input_Field.Text (F) = "ab", "Backspace must remove previous character");
      Editor.Input_Field.Move_Cursor_Start (F);
      Editor.Input_Field.Backspace (F);
      Assert (Editor.Input_Field.Text (F) = "ab", "Backspace at start must no-op");
      Editor.Input_Field.Delete_Forward (F);
      Assert (Editor.Input_Field.Text (F) = "b", "Delete_Forward must remove character at cursor");
      Editor.Input_Field.Select_All (F);
      Editor.Input_Field.Delete_Forward (F);
      Assert (Editor.Input_Field.Text (F) = "", "Delete_Forward must delete selection");
   end Test_Delete_Operations;

   procedure Test_Cursor_Clamping
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Editor.Input_Field.Set_Text (F, "ab");
      Editor.Input_Field.Set_Cursor_Column (F, 999);
      Assert (Editor.Input_Field.Cursor_Column (F) = 2, "cursor must clamp to text length");
      Editor.Input_Field.Move_Cursor_Right (F);
      Assert (Editor.Input_Field.Cursor_Column (F) = 2, "right movement must clamp at text length");
      Editor.Input_Field.Move_Cursor_Start (F);
      Assert (Editor.Input_Field.Cursor_Column (F) = 0, "Move_Cursor_Start must move to zero");
      Editor.Input_Field.Move_Cursor_Left (F);
      Assert (Editor.Input_Field.Cursor_Column (F) = 0, "left movement must clamp at zero");
      Editor.Input_Field.Move_Cursor_End (F);
      Assert (Editor.Input_Field.Cursor_Column (F) = 2, "Move_Cursor_End must move to text length");
   end Test_Cursor_Clamping;

   procedure Test_Snapshot_And_Normalization
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
      S : Editor.Input_Field.Field_Snapshot;
   begin
      Editor.Input_Field.Insert_Text (F, "abc" & ASCII.LF & "def");
      Assert (Editor.Input_Field.Text (F) = "abc", "field insertion must strip multiline suffix");
      S := Editor.Input_Field.Snapshot (F, 10);
      Assert (To_String (S.Visible_Text) = "abc", "wide snapshot must show all text");
      Editor.Input_Field.Set_Text (F, "abcdef");
      S := Editor.Input_Field.Snapshot (F, 3);
      Assert (To_String (S.Visible_Text)'Length <= 3, "snapshot must not exceed visible width");
      Assert (S.Cursor_Visible_Column <= 3, "snapshot must keep cursor visible");
      Assert (S.First_Visible_Column = 4, "narrow snapshot must right-align around cursor");
   end Test_Snapshot_And_Normalization;


   procedure Test_Extended_Selection_Anchor
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Editor.Input_Field.Set_Text (F, "abcd");
      Editor.Input_Field.Move_Cursor_Start (F);
      Editor.Input_Field.Move_Cursor_Right (F, Extend_Selection => True);
      Editor.Input_Field.Move_Cursor_Right (F, Extend_Selection => True);
      Assert (Editor.Input_Field.Selected_Text (F) = "ab",
              "shift-right twice must extend from the original anchor");
      Editor.Input_Field.Move_Cursor_Left (F, Extend_Selection => True);
      Assert (Editor.Input_Field.Selected_Text (F) = "a",
              "shrinking an extended selection must keep the original anchor");
      Editor.Input_Field.Move_Cursor_Right (F);
      Assert (not Editor.Input_Field.Has_Selection (F),
              "non-extending movement must collapse field selection");
   end Test_Extended_Selection_Anchor;

   procedure Test_Set_Cursor_From_Visible_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      F : Editor.Input_Field.Input_Field_State;
   begin
      Editor.Input_Field.Set_Text (F, "abcdef");
      Editor.Input_Field.Set_Cursor_From_Visible_Column
        (F, Visible_Column => 1, Visible_Columns => 3);
      Assert (Editor.Input_Field.Cursor_Column (F) = 5,
              "visible-column cursor placement must account for snapshot clipping");
      Editor.Input_Field.Set_Cursor_From_Visible_Column
        (F, Visible_Column => 99, Visible_Columns => 3);
      Assert (Editor.Input_Field.Cursor_Column (F) = 6,
              "visible-column cursor placement must clamp to field length");
   end Test_Set_Cursor_From_Visible_Column;

   procedure Register_Tests (T : in out Input_Field_Test_Case) is
   begin
      Register_Routine (T, Test_Empty_Set_Clear'Access, "empty set clear");
      Register_Routine (T, Test_Insert_And_Selection'Access, "insert and selection");
      Register_Routine (T, Test_Delete_Operations'Access, "delete operations");
      Register_Routine (T, Test_Cursor_Clamping'Access, "cursor clamping");
      Register_Routine (T, Test_Snapshot_And_Normalization'Access, "snapshot and normalization");
      Register_Routine (T, Test_Extended_Selection_Anchor'Access, "extended selection anchor");
      Register_Routine (T, Test_Set_Cursor_From_Visible_Column'Access, "cursor from visible column");
   end Register_Tests;

end Editor.Input_Field.Tests;
