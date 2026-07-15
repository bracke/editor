with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Editor.Bookmarks;
with Editor.Buffers;
with Editor.Commands;
with Editor.Command_Execution;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Messages;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Buffer_Switcher;
with Editor.State;
with Editor.Render_Model;
with Editor.Gutter_Markers;
with Editor.Workspace_Persistence;

package body Editor.Bookmarks.Tests is

   use type Ada.Containers.Count_Type;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Command_Execution.Command_Execution_Status;

   function Name
     (T : Bookmarks_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Bookmarks");
   end Name;


   procedure Assert_Bookmarks_Coherent
     (State : Editor.Bookmarks.Bookmark_State;
      Note  : String)
   is
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Prior    : Editor.Bookmarks.Bookmark_Entry;
      Current  : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (Snapshot.Bookmark_Count = Editor.Bookmarks.Count (State),
              Note & ": snapshot count matches state count");
      Assert (Natural (Snapshot.Bookmark_Rows.Length) = Editor.Bookmarks.Count (State),
              Note & ": row count matches bookmark count");
      Assert (Snapshot.Bookmark_Selected_Index = Editor.Bookmarks.Selected_Index (State),
              Note & ": selected index matches selected key");
      if Editor.Bookmarks.Count (State) = 0 then
         Assert (Snapshot.Bookmark_Selected_Index = 0,
                 Note & ": empty state has no selected row");
         Assert (not Snapshot.Bookmark_Has_Selected_Key,
                 Note & ": empty state has no selected key");
      else
         for I in 1 .. Editor.Bookmarks.Count (State) loop
            Current := Editor.Bookmarks.Entry_At (State, I);
            if I > 1 then
               Prior := Editor.Bookmarks.Entry_At (State, I - 1);
               Assert
                 (To_String (Prior.File_Path) < To_String (Current.File_Path)
                    or else (To_String (Prior.File_Path) = To_String (Current.File_Path)
                      and then Prior.Line_Number < Current.Line_Number)
                    or else (To_String (Prior.File_Path) = To_String (Current.File_Path)
                      and then Prior.Line_Number = Current.Line_Number
                      and then Prior.Column < Current.Column),
                  Note & ": bookmark rows are deterministic and unique");
            end if;
         end loop;
         if Snapshot.Bookmark_Selected_Index /= 0 then
            Assert (Snapshot.Bookmark_Selected_Index in 1 .. Editor.Bookmarks.Count (State),
                    Note & ": selected index points at an existing row");
            Assert (Snapshot.Bookmark_Has_Selected_Key,
                    Note & ": selected key flag is coherent");
         end if;
      end if;
   end Assert_Bookmarks_Coherent;


   procedure Assert_Bookmarks_File_Lifecycle_Observation_Coherent
     (State : Editor.Bookmarks.Bookmark_State;
      Note  : String)
   is
   begin
      Assert_Bookmarks_Coherent (State, Note);
      Assert
        (Editor.Bookmarks.Bookmarks_No_Duplicate_Lifecycle_State (State),
         Note & ": no duplicate lifecycle observation state");
      Assert
        (Editor.Bookmarks.Bookmarks_No_Prompt_State (State),
         Note & ": no Bookmark-owned target prompt state");
      Assert
        (Editor.Bookmarks.Bookmark_Selection_Source_Target_Boundary (State),
         Note & ": selection remains UI state, not lifecycle source/target");
      Assert
        (Editor.Bookmarks.Bookmark_Row_Projection_Canonical (State),
         Note & ": row projection derives only retained bookmark fields");
      Assert
        (Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Canonical (State),
         Note & ": canonical observation predicate holds");
      Assert
        (Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Frozen (State),
         Note & ": frozen observation predicate holds");
      Assert
        (Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Reliable (State),
         Note & ": reliable observation predicate holds");
      Assert
        (Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Cleanup_Canonical (State),
         Note & ": cleanup/canonicalization predicate holds");
      Assert
        (Editor.Bookmarks.Bookmarks_File_Lifecycle_Observation_Final_Frozen (State),
         Note & ": final freeze predicate holds");
   end Assert_Bookmarks_File_Lifecycle_Observation_Coherent;


   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Base & "/editor-tests");
      return Ada.Directories.Compose
        (Editor.Test_Temp.Base & "/editor-tests", "" & Name);
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Remove_If_Exists (Path);
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Text);
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         raise;
   end Write_File;

   procedure Setup_Active_File
     (S     : in out Editor.State.State_Type;
      Path  : String;
      Text  : String;
      Dirty : Boolean := False) is
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String (Ada.Directories.Simple_Name (Path));
      S.File_Info.Dirty := Dirty;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Setup_Active_File;

   procedure Assert_Same_Retained_Bookmark_Rows
     (Before : Editor.Bookmarks.Bookmark_Snapshot;
      After  : Editor.Bookmarks.Bookmark_Snapshot;
      Note   : String) is
   begin
      Assert (Before.Bookmark_Count = After.Bookmark_Count,
              Note & ": bookmark count preserved");
      Assert (Natural (Before.Bookmark_Rows.Length) = Natural (After.Bookmark_Rows.Length),
              Note & ": row count preserved");
      if Before.Bookmark_Rows.Length > 0 then
         for I in Before.Bookmark_Rows.First_Index .. Before.Bookmark_Rows.Last_Index loop
            Assert (To_String (Before.Bookmark_Rows (I).File_Path) =
                      To_String (After.Bookmark_Rows (I).File_Path),
                    Note & ": retained file path preserved");
            Assert (To_String (Before.Bookmark_Rows (I).File_Display_Path) =
                      To_String (After.Bookmark_Rows (I).File_Display_Path),
                    Note & ": retained display path preserved");
            Assert (Before.Bookmark_Rows (I).Line_Number = After.Bookmark_Rows (I).Line_Number
                      and then Before.Bookmark_Rows (I).Column = After.Bookmark_Rows (I).Column
                      and then Before.Bookmark_Rows (I).Has_Column = After.Bookmark_Rows (I).Has_Column,
                    Note & ": retained position preserved");
         end loop;
      end if;
   end Assert_Same_Retained_Bookmark_Rows;

   procedure Assert_Retained_Bookmark_Snapshot_Frozen
     (Before : Editor.Bookmarks.Bookmark_Snapshot;
      After  : Editor.Bookmarks.Bookmark_Snapshot;
      Note   : String) is
   begin
      Assert (Before.Bookmarks_Visible = After.Bookmarks_Visible,
              Note & ": visible flag preserved");
      Assert (Before.Bookmark_Count = After.Bookmark_Count,
              Note & ": bookmark count preserved");
      Assert (Before.Bookmark_Selected_Index = After.Bookmark_Selected_Index,
              Note & ": selected row identity preserved");
      Assert (Before.Bookmark_Has_Selected_Key = After.Bookmark_Has_Selected_Key,
              Note & ": selected-key flag preserved");
      Assert (To_String (Before.Bookmark_Selected_Key_File_Path) =
                To_String (After.Bookmark_Selected_Key_File_Path)
                and then Before.Bookmark_Selected_Key_Line_Number =
                  After.Bookmark_Selected_Key_Line_Number
                and then Before.Bookmark_Selected_Key_Column =
                  After.Bookmark_Selected_Key_Column
                and then Before.Bookmark_Selected_Key_Has_Column =
                  After.Bookmark_Selected_Key_Has_Column,
              Note & ": selected key retained");
      Assert_Same_Retained_Bookmark_Rows (Before, After, Note);
      if After.Bookmark_Rows.Length > 0 then
         for I in After.Bookmark_Rows.First_Index .. After.Bookmark_Rows.Last_Index loop
            Assert (Before.Bookmark_Rows (I).Is_Selected = After.Bookmark_Rows (I).Is_Selected,
                    Note & ": selection marker preserved");
            Assert (not After.Bookmark_Rows (I).Is_Open
                      and then not After.Bookmark_Rows (I).Is_Active
                      and then not After.Bookmark_Rows (I).Is_Dirty,
                    Note & ": Bookmark state stores no open/active/dirty cache");
         end loop;
      end if;
   end Assert_Retained_Bookmark_Snapshot_Frozen;


   function Latest_Message_Text
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String
   is
      M : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Latest_Message_Text;

   procedure Assert_Latest_Message_Contains
     (S        : Editor.State.State_Type;
      Fragment : String;
      Note     : String)
   is
      Found : Boolean := False;
      Text  : constant String := Latest_Message_Text (S, Found);
   begin
      Assert (Found, Note & ": command emitted one primary message");
      Assert (Index (Text, Fragment) /= 0,
              Note & ": expected message containing '" & Fragment & "', got '" & Text & "'");
   end Assert_Latest_Message_Contains;

   procedure Assert_Optional_Bookmark_Command_Absent
     (Name : String)
   is
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "optional/rejected bookmark command must not be exposed: " & Name);
   end Assert_Optional_Bookmark_Command_Absent;

   procedure Toggle_Adds_Removes_And_Orders
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Assert (Added, "first toggle should add");
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Assert (Editor.Bookmarks.Count (State) = 2, "two bookmarks expected");
      Assert (To_String (Editor.Bookmarks.Entry_At (State, 1).Display_Path) = "a.adb",
              "bookmarks should be path ordered");
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Assert (not Added, "second toggle at same location should remove");
      Assert (Editor.Bookmarks.Count (State) = 1, "duplicate bookmark must not remain");
   end Toggle_Adds_Removes_And_Orders;

   procedure Selection_Wraps_And_Clear_Resets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Select_Previous (State);
      Assert (Editor.Bookmarks.Selected_Index (State) = 2,
              "previous from first bookmark should wrap to last");
      Editor.Bookmarks.Select_Next (State);
      Assert (Editor.Bookmarks.Selected_Index (State) = 1,
              "next from last bookmark should wrap to first");
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Clear_Bookmarks (State);
      Assert (Editor.Bookmarks.Count (State) = 0, "clear bookmarks removes bookmarks");
      Assert (Editor.Bookmarks.Is_Visible (State), "user clear preserves visible surface");
      Assert (Editor.Bookmarks.Selected_Index (State) = 0, "user clear resets selection");
      Editor.Bookmarks.Clear (State);
      Assert (not Editor.Bookmarks.Is_Visible (State), "lifecycle clear hides bookmark surface");
   end Selection_Wraps_And_Clear_Resets;

   procedure Snapshot_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (Snapshot.Bookmarks_Visible, "snapshot should expose visibility");
      Assert (Snapshot.Bookmark_Count = 1, "snapshot should expose count");
      Assert (Natural (Snapshot.Bookmark_Rows.Length) = 1, "snapshot should expose rows");
      Assert (Editor.Bookmarks.Count (State) = 1, "snapshot must not mutate bookmarks");
      Assert (Editor.Bookmarks.Selected_Index (State) = 1, "snapshot must not mutate selection");
   end Snapshot_Is_Side_Effect_Free;

   procedure Snapshot_Rows_Expose_Selected_Location
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle (State, "/project/src/main.adb", "src/main.adb", 42, 3, True, Added);
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (Natural (Snapshot.Bookmark_Rows.Length) = 1, "one row expected");
      Assert (To_String (Snapshot.Bookmark_Rows (1).File_Display_Path) = "src/main.adb",
              "row exposes display path");
      Assert (Snapshot.Bookmark_Rows (1).Line_Number = 42, "row exposes line");
      Assert (Snapshot.Bookmark_Rows (1).Has_Column, "row exposes optional column flag");
      Assert (Snapshot.Bookmark_Rows (1).Column = 3, "row exposes column");
      Assert (Snapshot.Bookmark_Rows (1).Is_Selected, "first shown row is selected");
      Assert (not Snapshot.Bookmark_Rows (1).Is_Open, "open marker is derived later, not by bookmark state");
      Assert (not Snapshot.Bookmark_Rows (1).Is_Active, "active marker is derived later, not by bookmark state");
      Assert (not Snapshot.Bookmark_Rows (1).Is_Dirty, "dirty marker is derived later, not by bookmark state");
   end Snapshot_Rows_Expose_Selected_Location;


   procedure Snapshot_Rows_Expose_Project_Relative_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle
        (State,
         File_Path    => "/project/src/main.adb",
         Display_Path => "src/main.adb",
         Line_Number  => 42,
         Column       => 3,
         Has_Column   => True,
         Added        => Added,
         Project_Relative_Path     => "src/main.adb",
         Has_Project_Relative_Path => True);
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (Natural (Snapshot.Bookmark_Rows.Length) = 1, "one row expected");
      Assert (Snapshot.Bookmark_Rows (1).Has_Project_Relative_Path,
              "row should expose project-relative identity when known");
      Assert (To_String (Snapshot.Bookmark_Rows (1).Project_Relative_Path) = "src/main.adb",
              "row preserves project-relative path");
   end Snapshot_Rows_Expose_Project_Relative_Path;

   procedure Selection_Stays_With_Key_Across_Sorted_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Found : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found, "new visible bookmark should be selected");
      Assert (To_String (Item.Display_Path) = "a.adb", "visible add selects newly inserted bookmark by key");
      Editor.Bookmarks.Select_Next (State);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (To_String (Item.Display_Path) = "b.adb", "next selects second key");
      Editor.Bookmarks.Toggle (State, "/p/aa.adb", "aa.adb", 12, 1, True, Added);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (To_String (Item.Display_Path) = "aa.adb", "visible add selects newly added key");
   end Selection_Stays_With_Key_Across_Sorted_Insert;

   procedure Hidden_Add_Does_Not_Steal_Existing_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Found : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Hide (State);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found, "hidden add preserves existing selected key");
      Assert (To_String (Item.Display_Path) = "b.adb", "hidden add must not select new bookmark");
   end Hidden_Add_Does_Not_Steal_Existing_Selection;

   procedure Remove_Selected_Normalizes_To_Next_Then_Previous
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Removed : Boolean := False;
      Removed_Entry : Editor.Bookmarks.Bookmark_Entry;
      Found : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/c.adb", "c.adb", 30, 1, True, Added);
      Editor.Bookmarks.Select_Previous (State);
      Editor.Bookmarks.Remove_Selected (State, Removed, Removed_Entry);
      Assert (Removed, "selected bookmark should be removed");
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "c.adb",
              "removing middle bookmark selects next sorted bookmark");
      Editor.Bookmarks.Remove_Selected (State, Removed, Removed_Entry);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "a.adb",
              "removing last bookmark selects previous sorted bookmark");
      Editor.Bookmarks.Remove_Selected (State, Removed, Removed_Entry);
      Assert (not Editor.Bookmarks.Has_Selected (State), "removing final bookmark clears selection");
   end Remove_Selected_Normalizes_To_Next_Then_Previous;

   procedure Reveal_Current_Uses_Exact_Later_Then_First_In_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Reveal_Current_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 30, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 5, 1, True, Added);
      Editor.Bookmarks.Reveal_Current (State, "/p/a.adb", 10, Status, Item);
      Assert (Status = Editor.Bookmarks.Reveal_Selected_Exact, "exact line bookmark wins");
      Assert (Item.Line_Number = 10, "exact selected line expected");
      Editor.Bookmarks.Reveal_Current (State, "/p/a.adb", 20, Status, Item);
      Assert (Status = Editor.Bookmarks.Reveal_Selected_Nearest_In_File, "later in-file bookmark should be selected");
      Assert (Item.Line_Number = 30, "first later bookmark selected");
      Editor.Bookmarks.Reveal_Current (State, "/p/a.adb", 99, Status, Item);
      Assert (Item.Line_Number = 10, "wrap to first bookmark in active file when none later");
      Editor.Bookmarks.Reveal_Current (State, "/p/missing.adb", 1, Status, Item);
      Assert (Status = Editor.Bookmarks.Reveal_No_Bookmark_In_Active_File,
              "missing active file bookmark reports no in-file bookmark");
   end Reveal_Current_Uses_Exact_Later_Then_First_In_File;

   procedure Sorted_Order_Uses_File_Identity_Not_Display_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle (State, "/project/z.adb", "a.adb", 1, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/project/a.adb", "z.adb", 1, 1, True, Added);
      Assert (To_String (Editor.Bookmarks.Entry_At (State, 1).File_Path) = "/project/a.adb",
              "bookmark ordering must use file identity before display text");
      Assert (To_String (Editor.Bookmarks.Entry_At (State, 2).File_Path) = "/project/z.adb",
              "second row should follow file identity ordering");
   end Sorted_Order_Uses_File_Identity_Not_Display_Path;

   procedure Removing_Non_Selected_Preserves_Selected_Key
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Removed : Boolean := False;
      Found : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/c.adb", "c.adb", 30, 1, True, Added);
      Editor.Bookmarks.Select_Previous (State);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "b.adb",
              "test setup should select the middle bookmark");
      Editor.Bookmarks.Remove (State, "/p/a.adb", 10, Removed);
      Assert (Removed, "non-selected bookmark should be removed");
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "b.adb",
              "removing a different bookmark must preserve selected key");
   end Removing_Non_Selected_Preserves_Selected_Key;

   procedure Toggle_Remove_Selected_By_Location_Normalizes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Found : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 7, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Select_Previous (State);
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "a.adb",
              "test setup should select the first bookmark");
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 0, False, Added);
      Assert (not Added, "toggle at same file and line removes existing bookmark regardless of column source");
      Item := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Item.Display_Path) = "b.adb",
              "removing the selected bookmark by same location should select the next sorted bookmark");
   end Toggle_Remove_Selected_By_Location_Normalizes;

   procedure Goto_Targets_Use_Current_Location_And_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 30, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 5, 1, True, Added);

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/a.adb", 1, 1, True, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_Target_Found, "next should find a target");
      Assert (To_String (Item.File_Path) = "/p/a.adb" and then Item.Line_Number = 10,
              "next before first in file opens first bookmark");
      Assert (Editor.Bookmarks.Selected_Index (State) = 1,
              "goto next should synchronize selected bookmark");

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/a.adb", 10, 1, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/a.adb" and then Item.Line_Number = 30,
              "next from exact bookmark opens following bookmark");

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/b.adb", 5, 1, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/a.adb" and then Item.Line_Number = 10,
              "next wraps from last bookmark to first");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, True, "/p/b.adb", 99, 1, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/b.adb" and then Item.Line_Number = 5,
              "previous after last opens last bookmark");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, True, "/p/a.adb", 10, 1, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/b.adb" and then Item.Line_Number = 5,
              "previous from first bookmark wraps to last");
   end Goto_Targets_Use_Current_Location_And_Wrap;

   procedure Goto_Targets_Fallback_Without_Active_Location
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Select_Next_From_Location
        (State, False, "", 0, 0, False, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_No_Bookmarks,
              "goto next without bookmarks reports no bookmarks");

      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);

      Editor.Bookmarks.Select_Next_From_Location
        (State, False, "", 0, 0, False, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/a.adb",
              "goto next without a bookmarkable location opens first global bookmark");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, False, "", 0, 0, False, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/b.adb",
              "goto previous without a bookmarkable location opens last global bookmark");
   end Goto_Targets_Fallback_Without_Active_Location;


   procedure Goto_Targets_Respect_Exact_And_Column_Position
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 5, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 20, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 5, 1, True, Added);

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/a.adb", 10, 4, True, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_Target_Found,
              "next should find same-line bookmark after current column");
      Assert (To_String (Item.File_Path) = "/p/a.adb"
                and then Item.Line_Number = 10
                and then Item.Column = 5,
              "next before bookmark column should target the same line bookmark");

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/a.adb", 10, 5, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/a.adb"
                and then Item.Line_Number = 20,
              "next from exact bookmark column should skip to the following bookmark");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, True, "/p/a.adb", 10, 6, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/a.adb"
                and then Item.Line_Number = 10
                and then Item.Column = 5,
              "previous after bookmark column should target the same line bookmark");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, True, "/p/a.adb", 10, 5, True, Status, Item);
      Assert (To_String (Item.File_Path) = "/p/b.adb"
                and then Item.Line_Number = 5,
              "previous from exact first bookmark should wrap to the last bookmark");
   end Goto_Targets_Respect_Exact_And_Column_Position;

   procedure Goto_Target_Selection_Does_Not_Force_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
      Found : Boolean := False;
      Selected : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/a.adb", "a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/b.adb", "b.adb", 20, 1, True, Added);
      Assert (not Editor.Bookmarks.Is_Visible (State),
              "bookmark surface starts hidden in the model");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, False, "", 0, 0, False, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_Target_Found,
              "goto previous without active location should find a target");
      Assert (not Editor.Bookmarks.Is_Visible (State),
              "direct goto selection must not show the bookmark surface");

      Selected := Editor.Bookmarks.Selected (State, Found);
      Assert (Found and then To_String (Selected.File_Path) = "/p/b.adb",
              "direct goto still synchronizes selected bookmark state");

      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (not Snapshot.Bookmarks_Visible,
              "snapshot keeps hidden bookmark surface hidden after direct goto");
      Assert (Snapshot.Bookmark_Selected_Index = 2,
              "hidden snapshot still exposes synchronized selected bookmark key");
   end Goto_Target_Selection_Does_Not_Force_Visibility;


   procedure Coherent_Multi_Step_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Removed : Boolean := False;
      Removed_Entry : Editor.Bookmarks.Bookmark_Entry;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/src/editor/executor.adb", "src/editor/executor.adb", 42, 1, True, Added);
      Assert (Added, "workflow starts by adding executor line 42");
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle (State, "/p/src/editor/executor.adb", "src/editor/executor.adb", 88, 1, True, Added);
      Assert (Added, "workflow adds executor line 88");
      Assert_Bookmarks_Coherent (State, "after two toggles");
      Assert (Editor.Bookmarks.Count (State) = 2, "two bookmark rows remain after add workflow");
      Assert (Editor.Bookmarks.Selected_Index (State) = 2,
              "visible toggle-add selects the newly inserted bookmark");

      Editor.Bookmarks.Toggle (State, "/p/src/editor/executor.adb", "src/editor/executor.adb", 42, 0, False, Added);
      Assert (not Added, "toggling an existing line removes it instead of duplicating it");
      Assert (Editor.Bookmarks.Count (State) = 1, "duplicate prevention leaves one bookmark");
      Assert (Editor.Bookmarks.Entry_At (State, 1).Line_Number = 88,
              "remaining bookmark is the non-toggled line");
      Assert_Bookmarks_Coherent (State, "after toggle removal");

      Editor.Bookmarks.Remove_Selected (State, Removed, Removed_Entry);
      Assert (Removed, "remove-selected removes the remaining selected bookmark");
      Assert (Editor.Bookmarks.Count (State) = 0, "remove-selected clears final bookmark");
      Assert (not Editor.Bookmarks.Has_Selected (State), "remove-selected clears final selection");
      Assert_Bookmarks_Coherent (State, "after remove selected final row");

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/src/editor/executor.adb", 88, 1, True, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_No_Bookmarks,
              "direct goto reports no bookmarks after the last bookmark is removed");

      Editor.Bookmarks.Toggle (State, "/p/src/a.adb", "src/a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/src/b.adb", "src/b.adb", 20, 1, True, Added);
      Editor.Bookmarks.Clear_Bookmarks (State);
      Assert (Editor.Bookmarks.Count (State) = 0, "clear-all removes all bookmark state");
      Assert (Editor.Bookmarks.Is_Visible (State), "user clear-all preserves the existing surface visibility policy");
      Assert_Bookmarks_Coherent (State, "after clear all");
   end Coherent_Multi_Step_Workflow;

   procedure Reveal_And_Goto_Synchronize_Selected_Key
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Reveal_Status : Editor.Bookmarks.Reveal_Current_Status;
      Goto_Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
   begin
      Editor.Bookmarks.Toggle (State, "/p/src/a.adb", "src/a.adb", 10, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/src/a.adb", "src/a.adb", 20, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/src/b.adb", "src/b.adb", 5, 1, True, Added);
      Editor.Bookmarks.Hide (State);

      Editor.Bookmarks.Reveal_Current (State, "/p/src/a.adb", 15, Reveal_Status, Item);
      Assert (Reveal_Status = Editor.Bookmarks.Reveal_Selected_Nearest_In_File,
              "reveal-current selects first later bookmark in the active file");
      Assert (To_String (Item.File_Path) = "/p/src/a.adb" and then Item.Line_Number = 20,
              "reveal-current selected src/a.adb:20");
      Assert (not Editor.Bookmarks.Is_Visible (State),
              "model reveal selection does not force visibility; executor owns show policy");
      Assert_Bookmarks_Coherent (State, "after reveal current");

      Editor.Bookmarks.Select_Next_From_Location
        (State, True, "/p/src/a.adb", 20, 1, True, Goto_Status, Item);
      Assert (Goto_Status = Editor.Bookmarks.Bookmark_Goto_Target_Found,
              "goto-next finds the next global bookmark");
      Assert (To_String (Item.File_Path) = "/p/src/b.adb" and then Item.Line_Number = 5,
              "goto-next follows deterministic global order");
      Assert (not Editor.Bookmarks.Is_Visible (State),
              "direct goto does not force the bookmark surface visible");
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Assert (Snapshot.Bookmark_Selected_Index = 3,
              "direct goto synchronizes the selected key for later surface display");

      Editor.Bookmarks.Select_Previous_From_Location
        (State, True, "/p/src/a.adb", 10, 1, True, Goto_Status, Item);
      Assert (To_String (Item.File_Path) = "/p/src/b.adb" and then Item.Line_Number = 5,
              "goto-previous wraps from the first global bookmark to the last");
      Assert_Bookmarks_Coherent (State, "after direct goto previous wrap");
   end Reveal_And_Goto_Synchronize_Selected_Key;

   procedure Stale_And_Out_Of_Range_Targets_Are_Not_Pruned
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Added : Boolean := False;
      Status : Editor.Bookmarks.Bookmark_Goto_Status;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Toggle (State, "/p/src/stale.adb", "src/stale.adb", 12, 1, True, Added);
      Editor.Bookmarks.Toggle (State, "/p/src/editor/executor.adb", "src/editor/executor.adb", 200, 1, True, Added);
      Editor.Bookmarks.Show (State);
      Assert (Editor.Bookmarks.Count (State) = 2, "stale and out-of-range bookmarks remain ordinary entries");

      Editor.Bookmarks.Select_Next_From_Location
        (State, False, "", 0, 0, False, Status, Item);
      Assert (Status = Editor.Bookmarks.Bookmark_Goto_Target_Found,
              "direct goto selects a target without probing filesystem validity");
      Assert (Editor.Bookmarks.Count (State) = 2,
              "direct goto does not prune stale or out-of-range bookmarks");
      Assert (To_String (Item.File_Path) = "/p/src/editor/executor.adb"
                or else To_String (Item.File_Path) = "/p/src/stale.adb",
              "direct goto returns one of the structured bookmark keys");
      Assert_Bookmarks_Coherent (State, "after stale/out-of-range goto");

      Editor.Bookmarks.Clear_Bookmarks (State);
      Assert (Editor.Bookmarks.Count (State) = 0,
              "only explicit clear removes stale/out-of-range bookmarks");
   end Stale_And_Out_Of_Range_Targets_Are_Not_Pruned;

   procedure Editor_Surface_Markers_Are_Derived_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/editor/executor.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("executor.adb");

      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/editor/executor.adb", "src/editor/executor.adb", 2, 1, True, Added);
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/editor/executor.adb", "src/editor/executor.adb", 99, 1, True, Added);
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/other.adb", "src/other.adb", 1, 1, True, Added);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Editor.Gutter_Markers.Has_Marker
                (Snap.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
              "active open buffer renders an in-range bookmark marker on line 2");
      Assert (not Editor.Gutter_Markers.Has_Marker
                (Snap.Gutter_Markers, 98, Editor.Gutter_Markers.Bookmark_Marker),
              "out-of-range bookmark line is not rendered as an editor marker");
      Assert (not Editor.Gutter_Markers.Has_Marker
                (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
              "bookmark for another file is not rendered in the active buffer");
      Assert (not Editor.Gutter_Markers.Has_Marker
                (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
              "render snapshot derivation does not mutate stored gutter markers");
      Assert (Editor.State.Line_Count (S) = 3, "marker derivation does not change line count");
      Assert (Editor.State.Current_Text (S) = "one" & ASCII.LF & "two" & ASCII.LF & "three",
              "marker derivation does not alter line text");
      Assert_Bookmarks_Coherent (S.Bookmarks, "after marker snapshot");
   end Editor_Surface_Markers_Are_Derived_And_Bounded;

   procedure Lifecycle_Reset_Clears_Bookmarks_And_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/a.adb");
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/a.adb", "src/a.adb", 1, 1, True, Added);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Bookmark_Count = 1, "setup has one bookmark before lifecycle reset");

      Editor.State.Reset_Project_Scoped_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 0, "project lifecycle reset clears bookmarks");
      Assert (not Editor.Bookmarks.Is_Visible (S.Bookmarks), "project lifecycle reset hides bookmark surface");
      Assert (Snap.Bookmark_Count = 0, "later snapshots expose no old-project bookmark rows");
      Assert (not Editor.Gutter_Markers.Has_Marker
                (Snap.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
              "later snapshots expose no old-project editor marker");
      Assert_Bookmarks_Coherent (S.Bookmarks, "after lifecycle reset");
   end Lifecycle_Reset_Clears_Bookmarks_And_Markers;

   procedure Workspace_Snapshot_Excludes_Bookmark_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Added : Boolean := False;
      Before_Debug : Unbounded_String;
   begin
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/a.adb");
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/a.adb", "src/a.adb", 1, 1, True, Added);
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/stale.adb", "src/stale.adb", 50, 1, True, Added);
      Editor.Bookmarks.Show (S.Bookmarks);
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Before_Debug := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert (Index (To_String (Before_Debug), "bookmark") = 0
                and then Index (To_String (Before_Debug), "Bookmark") = 0,
              "workspace debug summary contains no bookmark section or marker state");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 2,
              "building a workspace snapshot does not clear or repair bookmark state");
      Assert (Editor.Bookmarks.Is_Visible (S.Bookmarks),
              "building a workspace snapshot does not mutate bookmark surface visibility");
   end Workspace_Snapshot_Excludes_Bookmark_State;



   procedure Executor_Bookmark_Commands_Emit_One_Message_And_Preserve_Independence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Project_Search_Query : Unbounded_String;
      Before_Quick_Open_Query : Unbounded_String;
      Before_Switcher_Marked : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/editor/executor.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("executor.adb");
      Editor.Project_Search.Set_Query (S.Project_Search, "executor");
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "src/");
      Before_Project_Search_Query := To_Unbounded_String (Editor.Project_Search.Query (S.Project_Search));
      Before_Quick_Open_Query := To_Unbounded_String (Editor.Quick_Open.Query_Text (S.Quick_Open));
      Before_Switcher_Marked := Editor.Buffer_Switcher.Marked_Count (S.Buffer_Switcher);

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Toggle_Current_Location);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "toggle-current-location executes through Executor");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "executor toggle adds exactly one session-local bookmark");
      Assert_Latest_Message_Contains (S, "Bookmark added", "toggle add");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Show);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "bookmark.show executes through Executor");
      Assert (Editor.Bookmarks.Is_Visible (S.Bookmarks),
              "show makes bookmark surface visible");
      Assert_Latest_Message_Contains (S, "Bookmarks shown", "bookmark show");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Next);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "bookmark.next executes through Executor");
      Assert (Editor.Bookmarks.Selected_Index (S.Bookmarks) = 1,
              "next keeps the only bookmark selected");
      Assert_Latest_Message_Contains (S, "Selected next bookmark", "bookmark next");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Previous);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "bookmark.previous executes through Executor");
      Assert (Editor.Bookmarks.Selected_Index (S.Bookmarks) = 1,
              "previous keeps the only bookmark selected");
      Assert_Latest_Message_Contains (S, "Selected previous bookmark", "bookmark previous");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Reveal_Current);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "bookmark.reveal-current executes through Executor");
      Assert (Editor.Bookmarks.Selected_Index (S.Bookmarks) = 1,
              "reveal-current selects the active-location bookmark");
      Assert_Latest_Message_Contains (S, "Selected bookmark", "bookmark reveal current");

      Assert (Editor.Project_Search.Query (S.Project_Search) = To_String (Before_Project_Search_Query),
              "bookmark commands do not mutate Project Search query state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = To_String (Before_Quick_Open_Query),
              "bookmark commands do not mutate Quick Open query state");
      Assert (Editor.Buffer_Switcher.Marked_Count (S.Buffer_Switcher) = Before_Switcher_Marked,
              "bookmark commands do not mutate Open Buffer Switcher marked state");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Clear_All);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "bookmark.clear-all executes through Executor");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 0,
              "clear-all clears bookmark state");
      Assert_Latest_Message_Contains (S, "Cleared", "bookmark clear all");
      Assert_Bookmarks_Coherent (S.Bookmarks, "after executor command sequence");
   end Executor_Bookmark_Commands_Emit_One_Message_And_Preserve_Independence;

   procedure Executor_Stale_Selected_Bookmark_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Added : Boolean := False;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => "/definitely/not/present/bookmark-stale.adb",
         Display_Path => "src/stale.adb",
         Line_Number  => 12,
         Column       => 1,
         Has_Column   => True,
         Added        => Added);
      Assert (Added and then Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "test setup creates one stale selected bookmark");

      Editor.Messages.Dismiss_All (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Bookmark_Open_Selected);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "open-selected stale target reports unavailable after command-path warning");
      Assert_Latest_Message_Contains (S, "file not found", "stale open-selected failure");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "stale open failure does not prune the bookmark");
      Assert (Editor.Bookmarks.Selected_Index (S.Bookmarks) = 1,
              "stale open failure preserves selected bookmark");
      Assert (Editor.Bookmarks.Is_Visible (S.Bookmarks),
              "open-selected stale failure keeps/shows the bookmark surface per policy");
      Assert_Bookmarks_Coherent (S.Bookmarks, "after stale open-selected failure");
   end Executor_Stale_Selected_Bookmark_Failure_Preserves_State;

   procedure Availability_And_Command_Name_Boundaries_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Before_Count : Natural := 0;
      Before_Selected : Natural := 0;
      Before_Visible : Boolean := False;
      Before_Project_Query : Unbounded_String;
      Before_Quick_Query : Unbounded_String;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/a.adb");
      Editor.Project_Search.Set_Query (S.Project_Search, "unchanged");
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "unchanged");
      Editor.Bookmarks.Toggle (S.Bookmarks, "/p/src/a.adb", "src/a.adb", 1, 1, True, Added);
      Editor.Bookmarks.Show (S.Bookmarks);
      Before_Count := Editor.Bookmarks.Count (S.Bookmarks);
      Before_Selected := Editor.Bookmarks.Selected_Index (S.Bookmarks);
      Before_Visible := Editor.Bookmarks.Is_Visible (S.Bookmarks);
      Before_Project_Query := To_Unbounded_String (Editor.Project_Search.Query (S.Project_Search));
      Before_Quick_Query := To_Unbounded_String (Editor.Quick_Open.Query_Text (S.Quick_Open));

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Bookmark_Toggle_Current_Location);
      Assert (Editor.Commands.Is_Available (Availability),
              "toggle-current-location availability should be true for bookmarkable active buffer");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Bookmark_Goto_Next);
      Assert (Editor.Commands.Is_Available (Availability),
              "goto-next availability should be true when bookmarks exist");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Bookmark_Open_Selected);
      Assert (Editor.Commands.Is_Available (Availability),
              "open-selected availability should be true when a selected bookmark exists");

      Assert (Editor.Bookmarks.Count (S.Bookmarks) = Before_Count,
              "availability checks must not mutate bookmark count");
      Assert (Editor.Bookmarks.Selected_Index (S.Bookmarks) = Before_Selected,
              "availability checks must not mutate selected bookmark");
      Assert (Editor.Bookmarks.Is_Visible (S.Bookmarks) = Before_Visible,
              "availability checks must not mutate surface visibility");
      Assert (Editor.Project_Search.Query (S.Project_Search) = To_String (Before_Project_Query),
              "availability checks must not mutate Project Search state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = To_String (Before_Quick_Query),
              "availability checks must not mutate Quick Open state");
      Assert_Bookmarks_Coherent (S.Bookmarks, "after availability checks");

      Assert_Optional_Bookmark_Command_Absent ("bookmark.persist");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.label-selected");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.open-all");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.goto-next-in-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.goto-previous-in-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.click-marker");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.toggle-gutter");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.search-bookmarks");
   end Availability_And_Command_Name_Boundaries_Are_Side_Effect_Free;

   procedure Retained_Row_Projection_Is_Observation_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Expected_Row : Editor.Bookmarks.Bookmark_Row;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Toggle
        (State,
         File_Path    => "/p/src/main.adb",
         Display_Path => "src/main.adb",
         Line_Number  => 42,
         Column       => 7,
         Has_Column   => True,
         Added        => Added,
         Project_Relative_Path     => "src/main.adb",
         Has_Project_Relative_Path => True);
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Expected_Row := Editor.Bookmarks.Build_Bookmark_Row_From_Bookmark_Entry
        (Editor.Bookmarks.Entry_At (State, 1), True);

      Assert (Natural (Snapshot.Bookmark_Rows.Length) = 1,
              "setup has one retained bookmark row");
      Assert (To_String (Snapshot.Bookmark_Rows (1).File_Path) = "/p/src/main.adb",
              "bookmark path comes from retained bookmark target data");
      Assert (To_String (Snapshot.Bookmark_Rows (1).File_Display_Path) = "src/main.adb",
              "bookmark display path comes from retained bookmark label data");
      Assert (Snapshot.Bookmark_Rows (1).Line_Number = 42
                and then Snapshot.Bookmark_Rows (1).Column = 7
                and then Snapshot.Bookmark_Rows (1).Has_Column,
              "bookmark position comes from retained bookmark target data");
      Assert (Snapshot.Bookmark_Rows (1).Is_Selected = Expected_Row.Is_Selected,
              "selection marker is retained Bookmark UI state");
      Assert (not Snapshot.Bookmark_Rows (1).Is_Open
                and then not Snapshot.Bookmark_Rows (1).Is_Active
                and then not Snapshot.Bookmark_Rows (1).Is_Dirty,
              "base Bookmark rows do not cache open/active/dirty lifecycle observation state");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (State, "retained row projection");
   end Retained_Row_Projection_Is_Observation_Only;

   procedure Selection_And_Target_Text_Are_Not_Lifecycle_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Added : Boolean := False;
      Found : Boolean := False;
      Selected : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "active buffer text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/active.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("active.adb");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => "/p/src/bookmark-target-looking-path.adb",
         Display_Path => "src/bookmark-target-looking-path.adb",
         Line_Number  => 9,
         Column       => 1,
         Has_Column   => True,
         Added        => Added);
      Selected := Editor.Bookmarks.Selected (S.Bookmarks, Found);

      Assert (Found, "setup has a selected bookmark row");
      Assert (To_String (Selected.File_Path) /= To_String (S.File_Info.Path),
              "selected bookmark intentionally differs from canonical active buffer");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (Editor.Commands.Is_Available (Availability),
              "file lifecycle availability still follows active buffer state, not bookmark selection");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "selected row source boundary");

      Assert_Optional_Bookmark_Command_Absent ("bookmark.save");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.save-as");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.rename-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.delete-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.copy-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.move-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.prompt-save-as");
   end Selection_And_Target_Text_Are_Not_Lifecycle_Source;

   procedure Copy_Move_Rename_Targets_Are_Not_Promoted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Before_Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      After_Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle
        (State, "/p/src/original.adb", "src/original.adb", 3, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (State, Before_Snapshot);

      --  deliberately has no Bookmark API for last save-as/rename/
      --  copy/move/delete targets.  Rebuilding projection cannot manufacture
      --  rows from operation history, prompt text, or copied/moved paths.
      Editor.Bookmarks.Build_Snapshot (State, After_Snapshot);
      Assert (Natural (After_Snapshot.Bookmark_Rows.Length) =
                Natural (Before_Snapshot.Bookmark_Rows.Length),
              "snapshot rebuild does not promote operation targets into bookmarks");
      Assert (To_String (After_Snapshot.Bookmark_Rows (1).File_Path) = "/p/src/original.adb",
              "retained bookmark target remains the only row path");
      Assert (Index (To_String (After_Snapshot.Bookmark_Rows (1).File_Path), "copied") = 0
                and then Index (To_String (After_Snapshot.Bookmark_Rows (1).File_Path), "moved") = 0
                and then Index (To_String (After_Snapshot.Bookmark_Rows (1).File_Path), "renamed") = 0,
              "row path contains no synthetic lifecycle target history");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (State, "no target promotion");
   end Copy_Move_Rename_Targets_Are_Not_Promoted;

   procedure Render_Snapshot_Does_Not_Mutate_Bookmark_Observation_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After : Editor.Bookmarks.Bookmark_Snapshot;
      Snap : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/p/src/rendered.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("rendered.adb");
      S.File_Info.Dirty := True;
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/p/src/rendered.adb", "src/rendered.adb", 1, 1, True, Added);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After);

      Assert (Natural (Before.Bookmark_Rows.Length) = Natural (After.Bookmark_Rows.Length),
              "render snapshot does not add/remove Bookmark rows");
      Assert (To_String (Before.Bookmark_Rows (1).File_Path) =
                To_String (After.Bookmark_Rows (1).File_Path),
              "render snapshot does not rewrite retained Bookmark path");
      Assert (Before.Bookmark_Rows (1).Is_Dirty = After.Bookmark_Rows (1).Is_Dirty
                and then not After.Bookmark_Rows (1).Is_Dirty,
              "render-enriched dirty hints are not persisted back into Bookmark state");
      Assert (Editor.State.Current_Text (S) = "one" & ASCII.LF & "two",
              "render snapshot remains side-effect-free for buffer text");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "render boundary");
   end Render_Snapshot_Does_Not_Mutate_Bookmark_Observation_State;

   procedure Adjacent_Observation_Freezes_Remain_Intact
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen
                (S.Buffer_Switcher),
              "Open Buffer Switcher observation freeze remains intact");
      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open)
                and then Editor.Quick_Open.Query_Text (S.Quick_Open) = "",
              "Quick Open baseline state remains unopened and query-local");
      Assert (Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen
                (S.Project_Search),
              "Project Search observation freeze remains intact");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "adjacent freezes baseline");
   end Adjacent_Observation_Freezes_Remain_Intact;

   procedure Save_And_Copy_Observation_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("save_copy_source.txt");
      Copy_Target : constant String := Temp_Path ("save_copy_target.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Save_State : Editor.Bookmarks.Bookmark_Snapshot;
      After_Copy_State : Editor.Bookmarks.Bookmark_Snapshot;
      Render_Before : Editor.Render_Model.Render_Snapshot;
      Render_After : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Copy_Target);
      Write_File (Path, "before");
      Setup_Active_File (S, Path, "after", Dirty => True);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, Path, Ada.Directories.Simple_Name (Path), 1, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);
      Editor.Render_Model.Build_Render_Snapshot (S, Render_Before);
      Assert (Render_Before.Bookmark_Rows (1).Is_Open
                and then Render_Before.Bookmark_Rows (1).Is_Active
                and then Render_Before.Bookmark_Rows (1).Is_Dirty,
              "setup exposes dirty active open marker only in render snapshot");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Save_State);
      Editor.Render_Model.Build_Render_Snapshot (S, Render_After);

      Assert_Same_Retained_Bookmark_Rows
        (Before, After_Save_State, "save observation");
      Assert (not S.File_Info.Dirty, "save clears canonical dirty state");
      Assert (not Render_After.Bookmark_Rows (1).Is_Dirty,
              "render dirty hint follows canonical clean buffer after save");
      Assert (not After_Save_State.Bookmark_Rows (1).Is_Dirty,
              "dirty hint is not cached in Bookmark state after save");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Target);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Copy_State);
      Assert_Same_Retained_Bookmark_Rows
        (After_Save_State, After_Copy_State, "copy observation");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "copy does not add copied target as a bookmark");
      Assert (To_String (After_Copy_State.Bookmark_Rows (1).File_Path) = Path,
              "copy preserves retained source bookmark path");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "save/copy reliability");

      Remove_If_Exists (Path);
      Remove_If_Exists (Copy_Target);
   end Save_And_Copy_Observation_Reliability;

   procedure Rename_Move_Delete_Target_Boundary_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Original : constant String := Temp_Path ("rename_move_original.txt");
      Renamed : constant String := Temp_Path ("rename_move_renamed.txt");
      Moved : constant String := Temp_Path ("rename_move_moved.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Rename : Editor.Bookmarks.Bookmark_Snapshot;
      After_Move : Editor.Bookmarks.Bookmark_Snapshot;
      After_Delete : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Original);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Moved);
      Write_File (Original, "rename move delete");
      Setup_Active_File (S, Original, "rename move delete");
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle (S.Bookmarks, Original, "retained/original.txt", 3, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Rename);
      Assert (To_String (S.File_Info.Path) = Renamed,
              "rename updates canonical active buffer association");
      Assert_Same_Retained_Bookmark_Rows
        (Before, After_Rename, "rename retained target boundary");
      Assert (Index (To_String (After_Rename.Bookmark_Rows (1).File_Path), "renamed") = 0,
              "rename target is not promoted into retained bookmark path");

      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Move);
      Assert (To_String (S.File_Info.Path) = Moved,
              "move updates canonical active buffer association");
      Assert_Same_Retained_Bookmark_Rows
        (After_Rename, After_Move, "move retained target boundary");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "move does not create a duplicate bookmark row");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Delete);
      Assert (not S.File_Info.Has_Path,
              "delete clears canonical active buffer association");
      Assert_Same_Retained_Bookmark_Rows
        (After_Move, After_Delete, "delete retained target boundary");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "delete does not create a recovery bookmark or prune retained target");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "rename/move/delete reliability");

      Remove_If_Exists (Original);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Moved);
   end Rename_Move_Delete_Target_Boundary_Reliability;

   procedure Failed_And_Blocked_Operations_Preserve_Observation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("failed_blocked_source.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Invalid_Rename : Editor.Bookmarks.Bookmark_Snapshot;
      After_Dirty_Move : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_File (Path, "blocked");
      Setup_Active_File (S, Path, "blocked");
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle (S.Bookmarks, Path, "failed_blocked_source.txt", 4, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "   ");
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Invalid_Rename);
      Assert_Same_Retained_Bookmark_Rows
        (Before, After_Invalid_Rename, "invalid rename preservation");
      Assert (To_String (S.File_Info.Path) = Path,
              "invalid rename does not adopt failed target path");

      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Temp_Path ("dirty_move_target.txt"));
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Dirty_Move);
      Assert_Same_Retained_Bookmark_Rows
        (After_Invalid_Rename, After_Dirty_Move, "dirty move blocked preservation");
      Assert (To_String (S.File_Info.Path) = Path,
              "dirty move does not adopt blocked target path");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "failed/blocked reliability");

      Remove_If_Exists (Path);
      Remove_If_Exists (Temp_Path ("dirty_move_target.txt"));
   end Failed_And_Blocked_Operations_Preserve_Observation;

   procedure Selection_Prompt_Render_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Active : constant String := Temp_Path ("selection_active.txt");
      Explicit_Target : constant String := Temp_Path ("selection_explicit_target.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After : Editor.Bookmarks.Bookmark_Snapshot;
      Snap : Editor.Render_Model.Render_Snapshot;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Active);
      Remove_If_Exists (Explicit_Target);
      Write_File (Active, "selection source");
      Setup_Active_File (S, Active, "selection source");
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => Temp_Path ("bookmark_selected_should_not_be_target.txt"),
         Display_Path => "bookmark_selected_should_not_seed_prompt.txt",
         Line_Number  => 12,
         Column       => 1,
         Has_Column   => True,
         Added        => Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (S, Editor.Commands.Command_Rename_Buffer_File, Explicit_Target);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (To_String (S.File_Info.Path) = Explicit_Target,
              "prompted-equivalent target path comes from explicit Executor parameter");
      Assert (To_String (Before.Bookmark_Rows (1).File_Path) /= Explicit_Target,
              "selected bookmark was intentionally not the explicit target");
      Assert_Same_Retained_Bookmark_Rows
        (Before, After, "selection and prompt boundary");
      Assert (Natural (Snap.Bookmark_Rows.Length) = Natural (After.Bookmark_Rows.Length),
              "render snapshot does not add prompt-derived bookmark rows");
      Assert (Index (To_String (Summary), "bookmark") = 0
                and then Index (To_String (Summary), "Bookmark") = 0
                and then Index (To_String (Summary), "selection_explicit_target") = 0,
              "workspace persistence excludes Bookmark lifecycle observation state");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "selection/prompt/render/persistence boundary");

      Remove_If_Exists (Active);
      Remove_If_Exists (Explicit_Target);
   end Selection_Prompt_Render_And_Persistence_Boundaries;



   procedure Canonical_Row_Helpers_Rebuild_From_Retained_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Rows : Editor.Bookmarks.Bookmark_Row_Vectors.Vector;
      Added : Boolean := False;
      Item : Editor.Bookmarks.Bookmark_Entry;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle
        (State,
         File_Path    => "/p/src/z.adb",
         Display_Path => "src/z.adb",
         Line_Number  => 20,
         Column       => 2,
         Has_Column   => True,
         Added        => Added,
         Project_Relative_Path     => "src/z.adb",
         Has_Project_Relative_Path => True);
      Editor.Bookmarks.Toggle
        (State,
         File_Path    => "/p/src/a.adb",
         Display_Path => "src/a.adb",
         Line_Number  => 3,
         Column       => 1,
         Has_Column   => True,
         Added        => Added,
         Project_Relative_Path     => "src/a.adb",
         Has_Project_Relative_Path => True);

      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Rows := Editor.Bookmarks.Build_Bookmark_Rows_From_Retained_State (State);

      Assert (Natural (Rows.Length) = 2, "retained helper returns retained rows only");
      for I in Rows.First_Index .. Rows.Last_Index loop
         Item := Editor.Bookmarks.Entry_At (State, I);
         Assert (To_String (Rows (I).File_Path) = To_String (Snapshot.Bookmark_Rows (I).File_Path),
                 "helper and snapshot agree on retained file identity");
         Assert (To_String (Rows (I).File_Display_Path) =
                   To_String (Editor.Bookmarks.Bookmark_Path_Label_From_Retained_Target (Item)),
                 "path label helper derives from retained bookmark target label");
         Assert (Rows (I).Is_Selected = Snapshot.Bookmark_Rows (I).Is_Selected,
                 "selection marker remains Bookmark UI state");
         Assert (not Rows (I).Is_Open and then not Rows (I).Is_Active and then not Rows (I).Is_Dirty,
                 "retained helper does not cache open/active/dirty lifecycle state");
         Assert (not Editor.Bookmarks.Bookmark_Dirty_Hint_From_Retained_State (Item),
                 "retained bookmark entry does not own dirty hint state");
      end loop;

      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (State, "canonical row helper cleanup");
   end Canonical_Row_Helpers_Rebuild_From_Retained_State;

   procedure File_Lifecycle_Cleanup_Preserves_Retained_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Original : constant String := Temp_Path ("original.txt");
      Copy_Target : constant String := Temp_Path ("copy_target.txt");
      Renamed : constant String := Temp_Path ("renamed.txt");
      Moved : constant String := Temp_Path ("moved.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Save : Editor.Bookmarks.Bookmark_Snapshot;
      After_Copy : Editor.Bookmarks.Bookmark_Snapshot;
      After_Rename : Editor.Bookmarks.Bookmark_Snapshot;
      After_Move : Editor.Bookmarks.Bookmark_Snapshot;
      After_Delete : Editor.Bookmarks.Bookmark_Snapshot;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Original);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Moved);
      Write_File (Original, "original");
      Setup_Active_File (S, Original, "changed", Dirty => True);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, Original, "retained/original.txt", 5, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Save);
      Assert_Same_Retained_Bookmark_Rows
        (Before, After_Save, "save cleanup retains bookmark target");
      Assert (not After_Save.Bookmark_Rows (1).Is_Dirty,
              "save cleanup leaves no dirty cache in Bookmark state");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Target);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Copy);
      Assert_Same_Retained_Bookmark_Rows
        (After_Save, After_Copy, "copy cleanup retains bookmark target");
      Assert (Index (To_String (After_Copy.Bookmark_Rows (1).File_Path), "copy_target") = 0,
              "copy target is not recorded as Bookmark target history");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Rename);
      Assert_Same_Retained_Bookmark_Rows
        (After_Copy, After_Rename, "rename cleanup retains bookmark target");
      Assert (Index (To_String (After_Rename.Bookmark_Rows (1).File_Path), "renamed") = 0,
              "rename target is not migrated into Bookmark state");

      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Move);
      Assert_Same_Retained_Bookmark_Rows
        (After_Rename, After_Move, "move cleanup retains bookmark target");
      Assert (Index (To_String (After_Move.Bookmark_Rows (1).File_Path), "moved") = 0,
              "move target is not recorded as Bookmark target history");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Delete);
      Assert_Same_Retained_Bookmark_Rows
        (After_Move, After_Delete, "delete cleanup retains bookmark target");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "delete does not create repair, recovery, or pruning behavior");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "lifecycle cleanup retained target preservation");

      Remove_If_Exists (Original);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Moved);
   end File_Lifecycle_Cleanup_Preserves_Retained_Targets;

   procedure Selection_Prompt_And_Route_Cleanup_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Active : constant String := Temp_Path ("active.txt");
      Explicit_Target : constant String := Temp_Path ("explicit_target.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After : Editor.Bookmarks.Bookmark_Snapshot;
      Availability : Editor.Commands.Command_Availability;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Active);
      Remove_If_Exists (Explicit_Target);
      Write_File (Active, "active");
      Setup_Active_File (S, Active, "active");
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks,
         File_Path    => Temp_Path ("bookmark_selected_not_target.txt"),
         Display_Path => "bookmark_selected_not_target.txt",
         Line_Number  => 8,
         Column       => 1,
         Has_Column   => True,
         Added        => Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
              "lifecycle availability is driven by canonical active buffer, not Bookmark selection");
      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (S, Editor.Commands.Command_Rename_Buffer_File, Explicit_Target);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After);

      Assert (To_String (S.File_Info.Path) = Explicit_Target,
              "explicit target command uses Executor target, not Bookmark row text");
      Assert_Same_Retained_Bookmark_Rows
        (Before, After, "prompt/source/target cleanup boundary");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.save");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.save-as");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.rename-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.delete-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.copy-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.move-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.prompt-rename-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.prompt-copy-buffer-file");
      Assert_Optional_Bookmark_Command_Absent ("bookmark.prompt-move-buffer-file");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "selection prompt and route cleanup");

      Remove_If_Exists (Active);
      Remove_If_Exists (Explicit_Target);
   end Selection_Prompt_And_Route_Cleanup_Boundaries;

   procedure Render_And_Persistence_Cleanup_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("render_persist.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After : Editor.Bookmarks.Bookmark_Snapshot;
      Render : Editor.Render_Model.Render_Snapshot;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_File (Path, "render");
      Setup_Active_File (S, Path, "render dirty", Dirty => True);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle (S.Bookmarks, Path, "render_persist.txt", 2, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Render_Model.Build_Render_Snapshot (S, Render);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Render.Bookmark_Rows (1).Is_Open
                and then Render.Bookmark_Rows (1).Is_Active
                and then Render.Bookmark_Rows (1).Is_Dirty,
              "render enriches bookmark rows only from canonical buffer/open-buffer state");
      Assert_Same_Retained_Bookmark_Rows
        (Before, After, "render cleanup does not mutate Bookmark state");
      Assert (not After.Bookmark_Rows (1).Is_Open
                and then not After.Bookmark_Rows (1).Is_Active
                and then not After.Bookmark_Rows (1).Is_Dirty,
              "render-enriched fields are not cached in Bookmark state");
      Assert (Index (To_String (Summary), "bookmark") = 0
                and then Index (To_String (Summary), "Bookmark") = 0,
              "workspace persistence excludes Bookmark lifecycle cleanup state");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "render and persistence cleanup");

      Remove_If_Exists (Path);
   end Render_And_Persistence_Cleanup_Are_Side_Effect_Free;

   procedure Final_Source_Row_Identity_Order_Selection_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Bookmarks.Bookmark_State;
      Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      Rows : Editor.Bookmarks.Bookmark_Row_Vectors.Vector;
      Item : Editor.Bookmarks.Bookmark_Entry;
      Added : Boolean := False;
   begin
      Editor.Bookmarks.Show (State);
      Editor.Bookmarks.Toggle
        (State, "/p/z.adb", "src/z.adb", 30, 4, True, Added,
         Project_Relative_Path => "src/z.adb", Has_Project_Relative_Path => True);
      Editor.Bookmarks.Toggle
        (State, "/p/a.adb", "src/a.adb", 10, 1, True, Added,
         Project_Relative_Path => "src/a.adb", Has_Project_Relative_Path => True);
      Editor.Bookmarks.Toggle
        (State, "/p/m.adb", "src/m.adb", 20, 2, True, Added,
         Project_Relative_Path => "src/m.adb", Has_Project_Relative_Path => True);
      Editor.Bookmarks.Build_Snapshot (State, Snapshot);
      Rows := Editor.Bookmarks.Build_Bookmark_Rows_From_Retained_State (State);

      Assert (Snapshot.Bookmarks_Visible, "source freeze keeps visible flag");
      Assert (Snapshot.Bookmark_Count = 3 and then Natural (Rows.Length) = 3,
              "source freeze has three retained rows");
      Assert (Snapshot.Bookmark_Selected_Index = 2,
              "selection marker follows retained Bookmark selection policy");

      for I in 1 .. 3 loop
         Item := Editor.Bookmarks.Entry_At (State, I);
         Assert (To_String (Rows (I).File_Path) = To_String (Item.File_Path),
                 "row identity derives from retained bookmark identity");
         Assert (To_String (Rows (I).File_Display_Path) =
                   To_String (Editor.Bookmarks.Bookmark_Path_Label_From_Retained_Target (Item)),
                 "row label derives from retained bookmark target label");
         Assert (Rows (I).Is_Selected = (I = Snapshot.Bookmark_Selected_Index),
                 "row selection marker derives from Bookmark selection only");
         Assert (not Rows (I).Is_Open and then not Rows (I).Is_Active and then not Rows (I).Is_Dirty,
                 "retained rows contain no lifecycle observation cache");
      end loop;

      Assert (To_String (Rows (1).File_Path) = "/p/a.adb"
                and then To_String (Rows (2).File_Path) = "/p/m.adb"
                and then To_String (Rows (3).File_Path) = "/p/z.adb",
              "row order derives from retained Bookmark ordering only");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (State, "final retained source/identity/order freeze");
   end Final_Source_Row_Identity_Order_Selection_Freeze;

   procedure Final_Operation_Observation_And_Prompt_Equivalence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Direct : Editor.State.State_Type;
      Prompted : Editor.State.State_Type;
      Direct_Source : constant String := Temp_Path ("direct_source.txt");
      Prompt_Source : constant String := Temp_Path ("prompt_source.txt");
      Direct_Copy : constant String := Temp_Path ("direct_copy.txt");
      Prompt_Copy : constant String := Temp_Path ("prompt_copy.txt");
      Direct_Rename : constant String := Temp_Path ("direct_renamed.txt");
      Before_Direct : Editor.Bookmarks.Bookmark_Snapshot;
      After_Direct_Copy : Editor.Bookmarks.Bookmark_Snapshot;
      Before_Prompt : Editor.Bookmarks.Bookmark_Snapshot;
      Prompt_Open : Editor.Bookmarks.Bookmark_Snapshot;
      After_Prompt_Copy : Editor.Bookmarks.Bookmark_Snapshot;
      After_Direct_Rename : Editor.Bookmarks.Bookmark_Snapshot;
      Render_After_Rename : Editor.Render_Model.Render_Snapshot;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Direct_Source);
      Remove_If_Exists (Prompt_Source);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Prompt_Copy);
      Remove_If_Exists (Direct_Rename);
      Write_File (Direct_Source, "direct source");
      Write_File (Prompt_Source, "prompt source");

      Setup_Active_File (Direct, Direct_Source, "direct source");
      Editor.Bookmarks.Show (Direct.Bookmarks);
      Editor.Bookmarks.Toggle
        (Direct.Bookmarks, Direct_Source, "direct_source.txt", 1, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (Direct.Bookmarks, Before_Direct);
      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (Direct, Editor.Commands.Command_Copy_Buffer_File, Direct_Copy);
      Editor.Bookmarks.Build_Snapshot (Direct.Bookmarks, After_Direct_Copy);
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before_Direct, After_Direct_Copy, "direct copy observation");
      Assert (Direct.File_Info.Has_Path
                and then To_String (Direct.File_Info.Path) = Direct_Source,
              "direct copy preserves canonical source association");

      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (Direct, Editor.Commands.Command_Rename_Buffer_File, Direct_Rename);
      Editor.Bookmarks.Build_Snapshot (Direct.Bookmarks, After_Direct_Rename);
      Editor.Render_Model.Build_Render_Snapshot (Direct, Render_After_Rename);
      Assert (To_String (Direct.File_Info.Path) = Direct_Rename,
              "rename updates only canonical active buffer association");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (After_Direct_Copy, After_Direct_Rename, "rename retained target boundary");
      Assert (not Render_After_Rename.Bookmark_Rows (1).Is_Open
                and then not Render_After_Rename.Bookmark_Rows (1).Is_Active,
              "retained static old target is not repaired or migrated after rename");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (Direct.Bookmarks, "direct operation final freeze");

      Added := False;
      Setup_Active_File (Prompted, Prompt_Source, "prompt source");
      Editor.Bookmarks.Show (Prompted.Bookmarks);
      Editor.Bookmarks.Toggle
        (Prompted.Bookmarks, Prompt_Source, "bookmark-label-must-not-seed-copy-target.txt",
         1, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (Prompted.Bookmarks, Before_Prompt);
      Editor.Executor.Execute_Command (Prompted, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Bookmarks.Build_Snapshot (Prompted.Bookmarks, Prompt_Open);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Prompted),
              "prompted copy opens canonical target prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (Prompted) = "Copy target",
              "prompt label remains descriptor-owned");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Prompted) = "",
              "prompt input is not seeded from Bookmark label or target text");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before_Prompt, Prompt_Open, "prompt opening observation");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (Prompted, Prompt_Copy);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (Prompted);
      Editor.Bookmarks.Build_Snapshot (Prompted.Bookmarks, After_Prompt_Copy);
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before_Prompt, After_Prompt_Copy, "prompted copy observation");
      Assert (Prompted.File_Info.Has_Path
                and then To_String (Prompted.File_Info.Path) = Prompt_Source,
              "prompted copy preserves canonical source association");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (Prompted.Bookmarks, "prompted operation final freeze");

      Remove_If_Exists (Direct_Source);
      Remove_If_Exists (Prompt_Source);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Prompt_Copy);
      Remove_If_Exists (Direct_Rename);
   end Final_Operation_Observation_And_Prompt_Equivalence_Freeze;

   procedure Final_Selection_Activation_Target_Boundary_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Active : constant String := Temp_Path ("active.txt");
      Bookmark_Target : constant String := Temp_Path ("bookmark_target.txt");
      Copy_Target : constant String := Temp_Path ("selected_row_must_not_be_target.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Select : Editor.Bookmarks.Bookmark_Snapshot;
      After_Copy : Editor.Bookmarks.Bookmark_Snapshot;
      Availability : Editor.Commands.Command_Availability;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Active);
      Remove_If_Exists (Bookmark_Target);
      Remove_If_Exists (Copy_Target);
      Write_File (Active, "active");
      Write_File (Bookmark_Target, "bookmark target");
      Setup_Active_File (S, Active, "active");
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, Bookmark_Target, Copy_Target, 7, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);

      Editor.Bookmarks.Select_Next (S.Bookmarks);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Select);
      Assert (To_String (After_Select.Bookmark_Rows (1).File_Display_Path) = Copy_Target,
              "selected row deliberately contains target-like text");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Active,
              "Bookmark selection does not override active buffer source");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
              "lifecycle availability still follows canonical active buffer");
      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (S, Editor.Commands.Command_Copy_Buffer_File, Copy_Target);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Copy);

      Assert (Ada.Directories.Exists (Copy_Target),
              "explicit copy target comes from Executor argument");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Active,
              "selected bookmark path did not become lifecycle source");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (After_Select, After_Copy, "selection target boundary");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before, After_Copy, "activation-free selected row boundary");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "selection/target/text final freeze");

      Remove_If_Exists (Active);
      Remove_If_Exists (Bookmark_Target);
      Remove_If_Exists (Copy_Target);
   end Final_Selection_Activation_Target_Boundary_Freeze;

   procedure Final_Render_Persistence_Adjacent_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("render_persist.txt");
      Before : Editor.Bookmarks.Bookmark_Snapshot;
      After_Render : Editor.Bookmarks.Bookmark_Snapshot;
      After_Save : Editor.Bookmarks.Bookmark_Snapshot;
      Render_Before : Editor.Render_Model.Render_Snapshot;
      Render_After_Save : Editor.Render_Model.Render_Snapshot;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Added : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_File (Path, "render persistence");
      Setup_Active_File (S, Path, "render persistence dirty", Dirty => True);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle (S.Bookmarks, Path, "render_persist.txt", 2, 1, True, Added);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Before);
      Editor.Render_Model.Build_Render_Snapshot (S, Render_Before);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Render);

      Assert (Render_Before.Bookmark_Rows (1).Is_Open
                and then Render_Before.Bookmark_Rows (1).Is_Active
                and then Render_Before.Bookmark_Rows (1).Is_Dirty,
              "render derives open/active/dirty from canonical buffer state");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before, After_Render, "render does not cache enriched Bookmark fields");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Bookmarks.Build_Snapshot (S.Bookmarks, After_Save);
      Editor.Render_Model.Build_Render_Snapshot (S, Render_After_Save);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Render_After_Save.Bookmark_Rows (1).Is_Open
                and then Render_After_Save.Bookmark_Rows (1).Is_Active
                and then not Render_After_Save.Bookmark_Rows (1).Is_Dirty,
              "dirty hint follows canonical clean state after save");
      Assert_Retained_Bookmark_Snapshot_Frozen
        (Before, After_Save, "save does not persist dirty-hint cache");
      Assert (Index (To_String (Summary), "bookmark") = 0
                and then Index (To_String (Summary), "Bookmark") = 0,
              "workspace persistence excludes Bookmark lifecycle observation state");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen
                (S.Buffer_Switcher),
              "preserves Open Buffer Switcher lifecycle freeze");
      Assert (Editor.Quick_Open.Quick_Open_File_Lifecycle_Observation_Frozen
                (S.Quick_Open),
              "preserves Quick Open lifecycle freeze");
      Assert (Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen
                (S.Project_Search),
              "preserves Project Search lifecycle freeze");
      Assert_Bookmarks_File_Lifecycle_Observation_Coherent
        (S.Bookmarks, "render/persistence/adjacent final freeze");

      Remove_If_Exists (Path);
   end Final_Render_Persistence_Adjacent_Freeze;

   procedure Stable_Command_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Toggle_Current_Location) =
              "bookmark.toggle-current-location", "toggle command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Clear_All) =
              "bookmark.clear-all", "clear-all command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Next) =
              "bookmark.next", "next command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Previous) =
              "bookmark.previous", "previous command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Goto_Next) =
              "bookmark.goto-next", "goto next command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Goto_Previous) =
              "bookmark.goto-previous", "goto previous command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Open_Selected) =
              "bookmark.open-selected", "open-selected command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Reveal_Current) =
              "bookmark.reveal-current", "reveal-current command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Remove_Selected) =
              "bookmark.remove-selected", "remove-selected command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Show) =
              "bookmark.show", "show command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Hide) =
              "bookmark.hide", "hide command stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Bookmark_Toggle) =
              "bookmark.toggle", "toggle surface command stable name");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Bookmark_Next).Category =
              Editor.Commands.Bookmarks_Category, "bookmark commands use bookmark category");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Goto_Next),
              "goto next should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Goto_Previous),
              "goto previous should be bindable");
      Assert (not Editor.Commands.Is_Destructive_Command
                (Editor.Commands.Command_Bookmark_Goto_Next),
              "goto next is navigation, not destructive");
      Assert (not Editor.Commands.Is_Destructive_Command
                (Editor.Commands.Command_Bookmark_Goto_Previous),
              "goto previous is navigation, not destructive");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Toggle_Current_Location),
              "toggle current location should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Next),
              "surface next should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Previous),
              "surface previous should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Open_Selected),
              "open selected should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Reveal_Current),
              "reveal current should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Remove_Selected),
              "remove selected should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Clear_All),
              "clear all should be bindable");
      Assert (Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Bookmark_Toggle),
              "bookmark surface toggle should be bindable");
   end Stable_Command_Names;

   procedure Register_Tests
     (T : in out Bookmarks_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Toggle_Adds_Removes_And_Orders'Access,
                        "toggle adds, removes, and orders session bookmarks");
      Register_Routine (T, Selection_Wraps_And_Clear_Resets'Access,
                        "selection wraps and clear resets transient state");
      Register_Routine (T, Snapshot_Is_Side_Effect_Free'Access,
                        "snapshot exposes bookmark rows without side effects");
      Register_Routine (T, Snapshot_Rows_Expose_Selected_Location'Access,
                        "snapshot rows expose selected bookmark location fields");
      Register_Routine (T, Snapshot_Rows_Expose_Project_Relative_Path'Access,
                        "snapshot rows preserve project-relative identity when available");
      Register_Routine (T, Selection_Stays_With_Key_Across_Sorted_Insert'Access,
                        "selection follows bookmark key across sorted inserts");
      Register_Routine (T, Hidden_Add_Does_Not_Steal_Existing_Selection'Access,
                        "hidden add preserves selected bookmark key");
      Register_Routine (T, Remove_Selected_Normalizes_To_Next_Then_Previous'Access,
                        "remove selected normalizes to next or previous bookmark");
      Register_Routine (T, Reveal_Current_Uses_Exact_Later_Then_First_In_File'Access,
                        "reveal current selects exact, later, then first in active file");
      Register_Routine (T, Sorted_Order_Uses_File_Identity_Not_Display_Path'Access,
                        "bookmark rows sort by file identity before display text");
      Register_Routine (T, Removing_Non_Selected_Preserves_Selected_Key'Access,
                        "removing a non-selected bookmark preserves selected key");
      Register_Routine (T, Toggle_Remove_Selected_By_Location_Normalizes'Access,
                        "toggle-removing selected bookmark by location normalizes selection");
      Register_Routine (T, Goto_Targets_Use_Current_Location_And_Wrap'Access,
                        "bookmark goto targets use current location and wrap");
      Register_Routine (T, Goto_Targets_Fallback_Without_Active_Location'Access,
                        "bookmark goto falls back to first or last without active location");
      Register_Routine (T, Goto_Targets_Respect_Exact_And_Column_Position'Access,
                        "bookmark goto respects exact and column positions");
      Register_Routine (T, Goto_Target_Selection_Does_Not_Force_Visibility'Access,
                        "bookmark goto selection does not force surface visibility");
      Register_Routine (T, Coherent_Multi_Step_Workflow'Access,
                        "coherent toggle/remove/clear bookmark workflow");
      Register_Routine (T, Reveal_And_Goto_Synchronize_Selected_Key'Access,
                        "reveal and direct goto synchronize selected key");
      Register_Routine (T, Stale_And_Out_Of_Range_Targets_Are_Not_Pruned'Access,
                        "stale and out-of-range bookmarks are not pruned by navigation");
      Register_Routine (T, Editor_Surface_Markers_Are_Derived_And_Bounded'Access,
                        "editor-surface bookmark markers are derived and bounded");
      Register_Routine (T, Lifecycle_Reset_Clears_Bookmarks_And_Markers'Access,
                        "project lifecycle clears bookmark state and markers");
      Register_Routine (T, Workspace_Snapshot_Excludes_Bookmark_State'Access,
                        "workspace snapshots exclude bookmark state");
      Register_Routine (T, Executor_Bookmark_Commands_Emit_One_Message_And_Preserve_Independence'Access,
                        "executor bookmark commands emit one message and preserve adjacent surfaces");
      Register_Routine (T, Executor_Stale_Selected_Bookmark_Failure_Preserves_State'Access,
                        "executor stale selected bookmark failure preserves bookmark state");
      Register_Routine (T, Availability_And_Command_Name_Boundaries_Are_Side_Effect_Free'Access,
                        "bookmark availability and absent command boundaries are side-effect-free");
      Register_Routine (T, Retained_Row_Projection_Is_Observation_Only'Access,
                        "retained bookmark row projection is observation-only");
      Register_Routine (T, Selection_And_Target_Text_Are_Not_Lifecycle_Source'Access,
                        "bookmark selection and text are not lifecycle source/target");
      Register_Routine (T, Copy_Move_Rename_Targets_Are_Not_Promoted'Access,
                        "lifecycle target paths are not promoted into bookmarks");
      Register_Routine (T, Render_Snapshot_Does_Not_Mutate_Bookmark_Observation_State'Access,
                        "render snapshot does not persist bookmark lifecycle observation state");
      Register_Routine (T, Adjacent_Observation_Freezes_Remain_Intact'Access,
                        "preserves adjacent lifecycle observation freezes");
      Register_Routine (T, Save_And_Copy_Observation_Reliability'Access,
                        "save and copy observation reliability");
      Register_Routine (T, Rename_Move_Delete_Target_Boundary_Reliability'Access,
                        "rename/move/delete retained target boundary reliability");
      Register_Routine (T, Failed_And_Blocked_Operations_Preserve_Observation'Access,
                        "failed and blocked operations preserve bookmark observation");
      Register_Routine (T, Selection_Prompt_Render_And_Persistence_Boundaries'Access,
                        "selection, prompt, render, and persistence boundaries");
      Register_Routine (T, Canonical_Row_Helpers_Rebuild_From_Retained_State'Access,
                        "canonical row helpers rebuild from retained state");
      Register_Routine (T, File_Lifecycle_Cleanup_Preserves_Retained_Targets'Access,
                        "file lifecycle cleanup preserves retained targets");
      Register_Routine (T, Selection_Prompt_And_Route_Cleanup_Boundaries'Access,
                        "selection prompt and route cleanup boundaries");
      Register_Routine (T, Render_And_Persistence_Cleanup_Are_Side_Effect_Free'Access,
                        "render and persistence cleanup are side-effect-free");
      Register_Routine (T, Final_Source_Row_Identity_Order_Selection_Freeze'Access,
                        "final source row identity order and selection freeze");
      Register_Routine (T, Final_Operation_Observation_And_Prompt_Equivalence_Freeze'Access,
                        "final operation observation and prompt equivalence freeze");
      Register_Routine (T, Final_Selection_Activation_Target_Boundary_Freeze'Access,
                        "final selection activation and target boundary freeze");
      Register_Routine (T, Final_Render_Persistence_Adjacent_Freeze'Access,
                        "final render persistence and adjacent freeze");
      Register_Routine (T, Stable_Command_Names'Access,
                        "bookmark command descriptors use stable command names");
   end Register_Tests;

end Editor.Bookmarks.Tests;
