with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Navigation_History;
with Ada.Strings.Unbounded;

package body Editor.Navigation_History.Tests is

   overriding function Name
     (T : Navigation_History_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Navigation_History");
   end Name;

   function Loc (Buffer, Line, Column : Natural)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      return
        (Buffer_Id    => Buffer,
         Line         => Line,
         Column       => Column,
         Viewport_Row => 0,
         Reason       => Editor.Navigation_History.Navigation_Reason_Unknown,
         others       => <>);
   end Loc;

   function File_Loc (Path : String; Buffer, Line, Column : Natural)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      return
        (Buffer_Id     => Buffer,
         Has_File_Path => True,
         File_Path     => Ada.Strings.Unbounded.To_Unbounded_String (Path),
         Display_Path  => Ada.Strings.Unbounded.To_Unbounded_String (Path),
         Line          => Line,
         Column        => Column,
         Viewport_Row  => 0,
         Reason        => Editor.Navigation_History.Navigation_Reason_Unknown);
   end File_Loc;

   procedure Test_Initial_State_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Assert (not Editor.Navigation_History.Has_Back (State),
              "navigation history must start with no previous location");
      Assert (not Editor.Navigation_History.Has_Forward (State),
              "navigation history must start with no next location");

      Editor.Navigation_History.Record_Explicit_Navigation (State, Loc (1, 2, 3));
      Editor.Navigation_History.Record_Forward_Navigation (State, Loc (1, 4, 5));
      Editor.Navigation_History.Clear (State);

      Assert (Editor.Navigation_History.Back_Count (State) = 0,
              "clear must remove previous-location entries");
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "clear must remove next-location entries");
   end Test_Initial_State_And_Clear;

   procedure Test_Record_Suppresses_Adjacent_Duplicates_And_Clears_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Navigation_History.Navigation_History_State;
      Target : Editor.Navigation_History.Navigation_Location;
      Found  : Boolean;
   begin
      Editor.Navigation_History.Record_Explicit_Navigation (State, Loc (1, 1, 0));
      Editor.Navigation_History.Record_Explicit_Navigation (State, Loc (1, 1, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 1,
              "adjacent duplicate locations must not be pushed");

      Editor.Navigation_History.Record_Forward_Navigation (State, Loc (1, 9, 0));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "test setup must have a forward entry");

      Editor.Navigation_History.Record_Explicit_Navigation (State, Loc (1, 2, 0));
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "new explicit navigation must clear the forward stack");

      Found := Editor.Navigation_History.Pop_Back (State, Target);
      Assert (Found and then Target.Line = 2,
              "latest previous location must pop first");
   end Test_Record_Suppresses_Adjacent_Duplicates_And_Clears_Forward;

   procedure Test_File_Path_Identity_Coalesces_Across_Buffer_Tokens
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Editor.Navigation_History.Record_Explicit_Navigation
        (State, File_Loc ("src/a.adb", 1, 10, 2));
      Editor.Navigation_History.Record_Explicit_Navigation
        (State, File_Loc ("src/a.adb", 99, 10, 2));
      Assert (Editor.Navigation_History.Back_Count (State) = 1,
              "same file/line/column must coalesce even if a buffer token changed");

      Editor.Navigation_History.Record_Explicit_Navigation
        (State, File_Loc ("src/a.adb", 99, 11, 2));
      Assert (Editor.Navigation_History.Back_Count (State) = 2,
              "different one-based line must create a distinct history entry");
   end Test_File_Path_Identity_Coalesces_Across_Buffer_Tokens;


   procedure Test_Column_Zero_Is_Treated_As_Unavailable_For_Equality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Navigation_History.Locations_Equal
                (File_Loc ("src/a.adb", 1, 10, 0),
                 File_Loc ("src/a.adb", 1, 10, 7)),
              "zero column must compare as unavailable rather than distinct");
      Assert (not Editor.Navigation_History.Locations_Equal
                (File_Loc ("src/a.adb", 1, 10, 2),
                 File_Loc ("src/a.adb", 1, 10, 7)),
              "two non-zero captured columns on the same line remain distinct");
   end Test_Column_Zero_Is_Treated_As_Unavailable_For_Equality;


   procedure Test_Unrecordable_Current_Target_Aware_Record_Clears_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Editor.Navigation_History.Record_Forward_Navigation (State, Loc (1, 7, 0));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "test setup must create a forward entry");

      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (State, Loc (1, 0, 0), Loc (2, 4, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 0,
              "unrecordable current location must not push back history");
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "successful new navigation with unrecordable current location must clear forward history");
   end Test_Unrecordable_Current_Target_Aware_Record_Clears_Forward;


   procedure Test_Target_Aware_Record_Does_Not_Clear_When_Both_Unrecordable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Editor.Navigation_History.Record_Forward_Navigation (State, Loc (1, 9, 0));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "test setup must create a forward entry");

      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (State, Loc (1, 0, 0), Loc (2, 0, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 0,
              "two unrecordable locations must not push back history");
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "no structured target means no committed new navigation branch");
   end Test_Target_Aware_Record_Does_Not_Clear_When_Both_Unrecordable;

   procedure Test_Target_Aware_Record_Skips_Same_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Editor.Navigation_History.Record_Forward_Navigation (State, Loc (1, 9, 0));

      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (State, Loc (1, 4, 0), Loc (1, 4, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 0,
              "same active/target location must not push a duplicate transition");
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "same active/target location must not clear forward history");

      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (State, Loc (1, 4, 0), Loc (1, 5, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 1,
              "different target must record the previous location");
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "successful different target navigation must clear forward history");
   end Test_Target_Aware_Record_Skips_Same_Target;



   procedure Test_Same_File_Different_Line_Is_Distinct_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Navigation_History.Navigation_History_State;
      Target : Editor.Navigation_History.Navigation_Location;
      Found  : Boolean := False;
   begin
      Editor.Navigation_History.Record_Explicit_Navigation_If_Target_Changed
        (State, File_Loc ("src/editor/executor.adb", 1, 20, 0),
                File_Loc ("src/editor/executor.adb", 1, 120, 0));

      Assert (Editor.Navigation_History.Back_Count (State) = 1,
              "same file with a different line must record the previous line");
      Found := Editor.Navigation_History.Pop_Back (State, Target);
      Assert (Found and then Target.Line = 20,
              "same-file navigation must preserve the execution-time source line");
   end Test_Same_File_Different_Line_Is_Distinct_Target;


   procedure Test_Back_Forward_Destination_Stacks_Coalesce_Captured_Anchors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Navigation_History.Navigation_History_State;
   begin
      Editor.Navigation_History.Record_Back_Navigation
        (State, File_Loc ("src/a.adb", 1, 25, 0));
      Editor.Navigation_History.Record_Back_Navigation
        (State, File_Loc ("src/a.adb", 1, 25, 0));
      Assert (Editor.Navigation_History.Back_Count (State) = 1,
              "back destination stack must coalesce repeated captured anchors");

      Editor.Navigation_History.Record_Forward_Navigation
        (State, File_Loc ("src/b.adb", 2, 30, 0));
      Editor.Navigation_History.Record_Forward_Navigation
        (State, File_Loc ("src/b.adb", 2, 30, 0));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "forward destination stack must coalesce repeated captured anchors");
   end Test_Back_Forward_Destination_Stacks_Coalesce_Captured_Anchors;

   procedure Test_Bounded_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Navigation_History.Navigation_History_State;
      Target : Editor.Navigation_History.Navigation_Location;
      Found  : Boolean;
   begin
      for I in 1 .. Editor.Navigation_History.Max_History_Depth + 10 loop
         Editor.Navigation_History.Record_Explicit_Navigation (State, Loc (1, I, 0));
      end loop;

      Assert (Editor.Navigation_History.Back_Count (State) =
                Editor.Navigation_History.Max_History_Depth,
              "navigation history must remain bounded");

      Found := Editor.Navigation_History.Pop_Back (State, Target);
      Assert (Found and then Target.Line = Editor.Navigation_History.Max_History_Depth + 10,
              "bounded stack must keep the most recent location");
   end Test_Bounded_History;

   overriding procedure Register_Tests
     (T : in out Navigation_History_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Initial_State_And_Clear'Access,
         "initial state and clear");
      Register_Routine
        (T, Test_Record_Suppresses_Adjacent_Duplicates_And_Clears_Forward'Access,
         "duplicate suppression and forward clearing");
      Register_Routine
        (T, Test_File_Path_Identity_Coalesces_Across_Buffer_Tokens'Access,
         "file path identity coalesces across buffer tokens");
      Register_Routine
        (T, Test_Column_Zero_Is_Treated_As_Unavailable_For_Equality'Access,
         "column zero is unavailable for equality");
      Register_Routine
        (T, Test_Unrecordable_Current_Target_Aware_Record_Clears_Forward'Access,
         "unrecordable current target-aware record clears forward");
      Register_Routine
        (T, Test_Target_Aware_Record_Does_Not_Clear_When_Both_Unrecordable'Access,
         "target-aware record ignores two unrecordable locations");
      Register_Routine
        (T, Test_Target_Aware_Record_Skips_Same_Target'Access,
         "target-aware record skips same target");
      Register_Routine
        (T, Test_Same_File_Different_Line_Is_Distinct_Target'Access,
         "same-file different line is distinct target");
      Register_Routine
        (T, Test_Back_Forward_Destination_Stacks_Coalesce_Captured_Anchors'Access,
         "back/forward destination stacks coalesce captured anchors");
      Register_Routine
        (T, Test_Bounded_History'Access,
         "bounded stack keeps recent locations");
   end Register_Tests;

end Editor.Navigation_History.Tests;
