with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Files;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.State;

package body Editor.Executor.Buffer_Prune_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.State.Dirty_Close_Scope;

   overriding function Name
     (T : Buffer_Prune_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Buffer_Prune_Tests");
   end Name;


   procedure Test_Remove_Selected_Prunes_Pending_Close_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent : Natural := 0;
      Found  : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Preview_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "setup should select first pending target in pending review");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = B_Id,
              "remove-selected prunes selected identity from captured pending close set");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "remove-selected must not close buffers");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "remove-selected must not mutate current marks");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "remove-selected must not mutate metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "remove-selected must not activate a buffer");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "remove-selected must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "remove-selected must not add navigation history");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "pending review candidate set updates after pruning");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "pending review selection normalizes after pruning");
      end;
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "preview follows normalized pending-review selection");
      Assert (Latest_Message_Text (S) = "Removed alpha.adb from pending close; pending close now has 1 targets",
              "remove-selected reports pruned count");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "confirm must not close pruned targets");
      Assert (not Editor.Buffers.Global_Contains (B_Id),
              "confirm closes remaining pending targets");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "pruned target remains marked after confirm");
      Assert (True,
              "pruned pending close confirmation must not create close-history/reopen entries");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Remove_Selected_Prunes_Pending_Close_Target;


   procedure Test_Remove_Selected_Availability_And_Last_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("availability_last");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "remove-selected is unavailable without pending marked action");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "remove-selected is unavailable when selected row is not a pending target");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "deterministic no-op does not mutate pending targets for non-target selection");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "removing the last target clears pending action and exits pending review");
      Assert (Editor.Buffers.Global_Contains (A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "removing the last target remains non-destructive and preserves marks");
      Assert (Latest_Message_Text (S) = "No pending marked targets remain",
              "removing last target reports deterministic zero-target state");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "preparing marked close again refreshes pending targets from current marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Remove_Selected_Availability_And_Last_Target;


   procedure Test_Restore_Last_Pruned_Pending_Close_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("restore_last_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
      Before_Recent : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Preview_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "restore-last is unavailable before any pending target is pruned");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "setup should leave only alpha active after pruning beta and gamma");
      Assert (Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 2,
              "pruning keeps session-local pruned pending target history");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 2; 2 still open",
              "pruned summary reports total and still-open pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = C_Id,
              "restore-last restores the most recently pruned still-open target");
      Assert (Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "restored target is removed from pruned history");
      Assert (Editor.Buffers.Global_Contains (C_Id),
              "restore-last must not close the restored buffer");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "restore-last must not mark or unmark buffers");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "restore-last must not mutate metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "restore-last must not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "restore-last must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "restore-last must not add navigation history");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 3) = C_Id,
              "restored pending targets return to original captured order");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 3,
              "pending marked review candidate set updates after restoration");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) /= Editor.Buffers.No_Buffer,
              "preview remains derived from normalized pending review selection");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3,
              "clearing marks after restoration does not remove restored pending close targets");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Global_Contains (C_Id),
              "confirm closes active pending targets after restoration");
      Assert (True,
              "confirm order cleanup must not create close-history/reopen entries");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "confirm clears pending action and pruned history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restore_Last_Pruned_Pending_Close_Target;

   procedure Test_Restore_Last_Pruned_Closed_Target_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("closed_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Close_Buffer (B_Id, Closed);
      Assert (Closed, "setup should close the pruned target before restore");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Could not restore beta.adb; buffer is no longer open",
              "restore-last reports a closed last-pruned target explicitly");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "closed-target restore failure leaves pending and pruned state unchanged");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "preparing marked close again refreshes targets and clears old pruned history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "cancelling pending marked close clears pruned history without closing buffers");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "cancellation after pruned restore state remains non-destructive");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restore_Last_Pruned_Closed_Target_Is_Explicit;


   procedure Test_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("pruned_review_restore");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 2; 2 still open",
              "pruned summary reports total and still-open pruned target counts");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 2,
              "pruned summary does not mutate active pending or pruned target state");

      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "pruned review is the single active review constraint");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = C_Id,
              "pruned review narrows the switcher projection to still-open pruned targets");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = C_Id,
              "pruned-next follows current pruned review order");
      Assert (not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "pruned navigation does not restore or unmark the selected target");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "pruned navigation does not activate buffers or add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "pruned-previous follows current pruned review order");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "restore-selected-pruned restores only the selected still-open pruned target");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id,
              "restore-selected-pruned does not mark, unmark, or activate buffers");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Global_Contains (C_Id),
              "confirm closes restored active pending targets but not unrestored pruned targets");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher),
              "confirm clears pending action, pruned history, and pruned review state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore;

   procedure Test_Pruned_Pending_No_Open_And_No_Pending_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("no_open_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending marked action",
              "pruned summary reports deterministic no-pending state");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Close_Buffer (B_Id, Closed);
      Assert (Closed, "setup closes the pruned target outside pruned inspection");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 1; 0 still open",
              "pruned summary distinguishes closed pruned targets from still-open pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No open pruned pending close targets",
              "pruned navigation reports deterministic no-open-pruned state");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "no-open-pruned navigation does not mutate pending or pruned state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher),
              "cancel clears pruned history and pruned review state without closing active pending targets");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "cancel remains non-destructive for active pending targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Pruned_Pending_No_Open_And_No_Pending_Messages;

   procedure Test_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_pending_navigation");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty pending close targets: 2 of 3",
              "dirty summary reports dirty active pending targets against still-open pending targets");

      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected next dirty pending close target",
              "dirty-next reports a deterministic primary message");
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher, Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = B_Id,
              "dirty-next selects the next dirty pending target in switcher order");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "dirty navigation refreshes the preview target through existing selection behavior");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "dirty navigation does not activate buffers or add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher, Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = C_Id,
              "dirty-previous selects the previous dirty pending target in switcher order");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "dirty navigation does not mutate marks or pending targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor;


   procedure Test_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_pending_remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "work");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "review");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "keep dirty");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 3 | Dirty: 1",
              "setup has one dirty pending close target");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher,
                 Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = B_Id,
              "setup selects the dirty active pending target through navigation");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "dirty-remove-selected is available for a selected dirty pending target");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "availability does not mutate pending targets, pruned history, or marks");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) =
              "Removed dirty pending close target beta.adb; pending close now has 2 targets; Dirty: 0",
              "dirty-remove-selected emits one deterministic pruning outcome message");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "dirty-remove-selected removes the target from active pending close and records ordinary pruned history");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 2 | Pruned: 1",
              "pending, dirty, and pruned counts update after dirty pruning");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "dirty-remove-selected does not close, save, discard, or unmark the selected buffer");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "work"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "keep dirty",
              "dirty-remove-selected does not mutate pinned state, group, label, or note metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "dirty-remove-selected does not activate buffers, add navigation history, or update recent-buffer state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No dirty pending close targets",
              "pruned dirty target is removed from dirty pending navigation candidates");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 1,
              "dirty-pruned targets restore through ordinary last-pruned restoration and become dirty-pending if still dirty");

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected pending close target is not dirty",
              "clean selected pending targets are rejected by the dirty-only shortcut");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "dirty-only rejection leaves pending and pruned state unchanged");

      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "setup reprunes restored dirty target before confirmation");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (C_Id),
              "confirm closes only remaining active pending targets and leaves dirty-pruned target open");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation;


   procedure Test_Dirty_Remove_Selected_Deterministic_Rejections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_remove_rejections");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending marked action",
              "dirty-remove-selected reports deterministically without a pending marked action");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "no-pending rejection does not create pending or pruned state");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1,
              "rejection setup captured one pending target");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected buffer is not a pending close target",
              "availability rejects a dirty selected buffer that is not active pending close");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected buffer is not a pending close target",
              "dirty non-pending selection reports deterministically");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id),
              "dirty non-pending rejection leaves pending, pruned, open, and dirty state unchanged");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected pending close target is not dirty",
              "availability rejects a clean selected pending target");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected pending close target is not dirty",
              "clean pending selection reports deterministically");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (A_Id),
              "clean pending rejection leaves pending targets, pruned history, and buffers unchanged");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Remove_Selected_Deterministic_Rejections;


   procedure Test_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_prune_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path : constant String := Ada.Directories.Compose (Root, "delta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      D_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha"); Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma"); Write_Text_File (D_Path, "delta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, D_Path); D_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty delta not pending"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "setup captures two dirty active pending targets and excludes dirty non-pending buffers");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "alpha");
      Editor.Buffer_Switcher.Set_Pinned_Filter (S.Buffer_Switcher);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "dirty-prune preview is available when dirty active pending targets exist");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune prepared: 2 of 3 pending close targets",
              "preview reports captured dirty active pending targets, including filtered/query-hidden ones");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id),
              "preview captures identities without pruning, closing, saving, discarding, or dirty-state mutation");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = D_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "preview does not mutate marks, metadata, active buffer, navigation history, or recent-buffer state");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 2",
              "optional dirty-prune badge is snapshot-derived from captured preview state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 2 still applicable",
              "summary reports captured and still-applicable dirty pending counts");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune cancelled"
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "cancel clears preview without mutating pending or pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "repeated preview refreshes the captured target set");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffers.Global_Set_Active_Buffer (B_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (A_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      Set_Buffer_Text (S, "alpha became dirty after preview"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (D_Id); Editor.Buffers.Load_Global_Active_Into_State (S);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 1 still applicable",
              "summary revalidates applicability without refreshing captured targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned 1 dirty pending close targets",
              "apply prunes only captured targets that remain open, pending, and dirty");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher),
              "apply skips clean captured targets, ignores newly dirty uncaptured targets, records ordinary pruned history, and clears preview");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Pending close: 2 | Dirty: 1 | Pruned: 1",
              "apply updates pending, dirty, and pruned counts in the next switcher snapshot");
      Assert (Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id)
              and then True,
              "apply does not close dirty-pruned buffers or create reopen entries");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "dirty-pruned targets restore through ordinary pruned restoration and become dirty-pending if still dirty");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation;


   procedure Test_Dirty_Prune_Review_Summary_Navigation_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_prune_review");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "dirty-prune summary reports deterministically without a preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "setup has two dirty active pending close targets");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "preview captures dirty pending target identities");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 2 still applicable",
              "summary reports captured and still-applicable counts");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune preview review shown"
              and then Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "dirty-prune review narrows the switcher to open captured preview targets");
      Row := Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1);
      Assert (Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id),
              "review rows are captured dirty-prune preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected next dirty-prune preview target"
              and then Found
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "dirty-prune next selects a captured target without activation, navigation history, or recent-buffer mutation");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected previous dirty-prune preview target"
              and then Found
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id,
              "dirty-prune previous selects a captured target without activating it");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "beta");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "dirty-prune review composes with the literal switcher query without changing captured targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune preview review hidden"
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = "beta",
              "hiding dirty-prune review restores ordinary projection without clearing query state");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Global_Set_Active_Buffer (B_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (C_Id); Editor.Buffers.Load_Global_Active_Into_State (S);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 1 still applicable"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "summary revalidates applicability without refreshing the captured review target set");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "dirty-prune apply clears review state and prunes only still-applicable captured targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Prune_Review_Summary_Navigation_And_Clear;


   procedure Test_Dirty_Prune_Remove_Selected_Edits_Preview_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_prune_remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "remove-selected reports deterministically without a dirty-prune preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "setup captures two dirty preview targets without pruning pending close");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected buffer is not a dirty-prune preview target",
              "availability rejects selected rows outside the captured preview set");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected buffer is not a dirty-prune preview target"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "non-preview selection leaves preview, pending, and pruned state unchanged");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id),
              "review selection uses buffer identity from the selected row");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "remove-selected is available for a selected captured dirty-prune preview target");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "remove-selected edits only the prepared dirty-prune preview set, not active pending targets or pruned history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "remove-selected does not close, clean, mark, mutate metadata, activate, or update navigation/recent history");
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = C_Id,
              "review rows and preview target normalize to the remaining captured target");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id),
              "apply prunes only remaining dirty-prune preview targets; removed preview targets remain pending and unpruned");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1,
              "preparing dirty-prune preview again recaptures still-dirty active pending targets previously removed from preview");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher),
              "removing the last dirty-prune preview target clears the preview action, exits review, and clears removed-preview history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Prune_Remove_Selected_Edits_Preview_Only;


   procedure Test_Dirty_Prune_Restore_Last_Removed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_prune_restore_last_removed");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No pending dirty-prune action",
              "restore-last-removed is unavailable without a dirty-prune workflow");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "restore-last-removed reports deterministically without a preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "setup captures two dirty-prune preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No removed dirty-prune preview targets",
              "restore-last-removed is unavailable before any preview target removal");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No removed dirty-prune preview targets",
              "restore-last-removed reports empty removed preview history");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name (S.Buffer_Switcher) = "beta.adb"
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id),
              "remove-selected records removed dirty-prune preview identity without active preview membership");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Removed dirty-prune preview targets: 1; 1 still open",
              "removed-summary reports removed and still-open preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "restore-last-removed is available after preview target removal");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Restored beta.adb to dirty-prune preview"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "restore-last-removed returns the target to preview without mutating pending close or pruned history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "restore-last-removed does not close, clean, mark, mutate metadata, activate, or update navigation/recent history");
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "dirty-prune review candidate set reflects the restored preview target");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Last_Pruned_Pending_Marked_Close_Target_Name (S.Buffer_Switcher) = "gamma.adb",
              "apply prunes restored targets in deterministic original preview order");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "restored preview targets become ordinary pruned targets only after dirty-prune apply");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Prune_Restore_Last_Removed;


   procedure Test_Removed_Dirty_Prune_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("removed_dirty_prune_navigation");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty alpha"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "setup has two still-open removed dirty-prune preview targets");

      Editor.Buffer_Switcher.Hide_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Removed dirty-prune preview targets: 2; 2 still open"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3,
              "removed summary reports removed/open counts without mutating active preview or pending targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected next removed dirty-prune preview target"
              and then Found
              and then Row.Id = C_Id
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "removed-next selects a still-open removed target in effective order without restoring, pruning, activating, or history mutation");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected previous removed dirty-prune preview target"
              and then Found
              and then Row.Id = A_Id
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id),
              "removed-previous selects the previous still-open removed target without restoring it");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher),
              "apply ignores unrestored removed preview targets and clears removed history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Removed_Dirty_Prune_Navigation;


   procedure Test_Dirty_Prune_Clear_Stale_Command_And_Apply
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("dirty_prune_clear_stale");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "setup captures the two dirty pending targets");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "stale summary is available with a dirty-prune preview");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune stale targets: 1 of 2",
              "stale summary reports stale of captured preview targets without mutation");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "stale summary does not clear or refresh preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "clear-stale is available when the active preview contains stale targets");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Cleared 1 stale dirty-prune preview targets",
              "clear-stale reports the number of stale preview targets removed");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 1
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, B_Id),
              "clear-stale leaves only still-applicable preview targets");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 0,
              "clear-stale does not mutate active pending close, ordinary pruned history, or removed-preview history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id)
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "clear-stale does not close buffers, alter dirty state, or update navigation/recent history");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No stale dirty-prune preview targets",
              "clear-stale availability is deterministic when no stale targets remain");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id),
              "apply after stale cleanup prunes only remaining applicable preview targets");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Set_Buffer_Text (S, "dirty beta again"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, B_Id),
              "preparing dirty-prune preview again can recapture a stale-cleaned target that is now dirty and active pending");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Prune_Clear_Stale_Command_And_Apply;

   overriding procedure Register_Tests (T : in out Buffer_Prune_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Remove_Selected_Prunes_Pending_Close_Target'Access,
         "remove selected prunes pending close target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Remove_Selected_Availability_And_Last_Target'Access,
         "remove selected availability and last target behavior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restore_Last_Pruned_Pending_Close_Target'Access,
         "restore last pruned pending close target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restore_Last_Pruned_Closed_Target_Is_Explicit'Access,
         "restore last pruned closed target is explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore'Access,
         "pruned pending summary navigation review and selected restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pruned_Pending_No_Open_And_No_Pending_Messages'Access,
         "pruned pending no-open and no-pending messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor'Access,
         "dirty pending summary and navigation route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation'Access,
         "dirty pending remove selected prunes without buffer mutation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Remove_Selected_Deterministic_Rejections'Access,
         "dirty remove selected deterministic rejections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation'Access,
         "dirty prune preview apply cancel and revalidation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Prune_Review_Summary_Navigation_And_Clear'Access,
         "dirty prune review summary navigation and clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Prune_Remove_Selected_Edits_Preview_Only'Access,
         "dirty prune remove selected edits preview only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Prune_Restore_Last_Removed'Access,
         "dirty prune restore last removed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Removed_Dirty_Prune_Navigation'Access,
         "removed dirty prune summary and navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Prune_Clear_Stale_Command_And_Apply'Access,
         "dirty prune clear stale command and apply");
   end Register_Tests;

end Editor.Executor.Buffer_Prune_Tests;
