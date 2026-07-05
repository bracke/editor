with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Files;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Recent_Buffers;
with Editor.Render_Model;
with Editor.State;

package body Editor.Executor.Lifecycle_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.State.Dirty_Close_Scope;

   function Pending_Test_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   end Pending_Test_Summary;

   overriding function Name
     (T : Lifecycle_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Lifecycle_Tests");
   end Name;

   procedure Test_Close_Clean_File_And_Reopen
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("reopen_clean.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);

      Assert
        (not Editor.Buffers.Global_Contains (Id),
         "clean close removes the closed buffer through canonical close");
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "clean associated close creates only the canonical path candidate");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (Editor.Buffers.Global_Count = 1,
         "canonical reopen must add exactly one file-backed buffer");
      Assert
        (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
         "canonical reopen must activate the candidate path");
      Assert
        (Editor.State.Current_Text (S) = "alpha body",
         "canonical reopen must read disk contents through file-open");
      Assert
        (not S.Has_Reopen_Candidate,
         "successful canonical reopen consumes the path candidate");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_Clean_File_And_Reopen;

   procedure Test_Reopen_Reverse_Order_After_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := Temp_Path ("a.txt");
      B_Path : constant String := Temp_Path ("b.txt");
      C_Path : constant String := Temp_Path ("c.txt");
   begin
      Remove_File_If_Exists (A_Path);
      Remove_File_If_Exists (B_Path);
      Remove_File_If_Exists (C_Path);
      Write_Text_File (A_Path, "a");
      Write_Text_File (B_Path, "b");
      Write_Text_File (C_Path, "c");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_All_Clean_Buffers (S);

      Assert (True,
              "removed-name close-history stack must not drive reopen after cleanup");
      Assert (not S.Has_Reopen_Candidate,
              "removed-name cleanup closes must not synthesize canonical reopen candidates");

      Remove_File_If_Exists (A_Path);
      Remove_File_If_Exists (B_Path);
      Remove_File_If_Exists (C_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (A_Path);
         Remove_File_If_Exists (B_Path);
         Remove_File_If_Exists (C_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reopen_Reverse_Order_After_Cleanup;

   procedure Test_Reopen_Unavailable_With_No_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (not Editor.Commands.Is_Available (A),
         "reopen must be unavailable with no candidate");
      Assert
        (To_String (A.Reason) = "No closed buffer to reopen",
         "no-candidate reopen unavailable reason must be deterministic");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reopen_Unavailable_With_No_Candidate;

   procedure Test_Blocked_Dirty_Close_Does_Not_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("dirty_blocked.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);

      Assert (True, "blocked dirty close must not create a reopen entry");
      Assert
        (Editor.Buffers.Global_Contains (Id),
         "blocked dirty close must leave the buffer open");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Blocked_Dirty_Close_Does_Not_Record;

   procedure Test_Reopen_Already_Open_File_Focuses_Existing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("existing.txt");
      Closed : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Count  : Natural := 0;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "existing");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Closed := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Closed);
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "duplicate-open scenario starts from canonical path candidate");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Count := Editor.Buffers.Global_Count;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);

      Assert
        (Editor.Buffers.Global_Count = Count,
         "duplicate reopen must focus an already-open file instead of duplicating it");
      Assert
        (To_String (S.File_Info.Path) = Path,
         "duplicate reopen must focus the existing candidate buffer");
      Assert
        (not S.Has_Reopen_Candidate,
         "successful duplicate reopen consumes the path candidate");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reopen_Already_Open_File_Focuses_Existing;

   procedure Test_Missing_File_Reopen_Fails_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("missing.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "missing");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);
      Remove_File_If_Exists (Path);
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "missing-file scenario starts from canonical path candidate");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (Editor.Buffers.Global_Count = 0,
         "failed reopen must not create a placeholder buffer");
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "failed reopen retains the path candidate for deterministic retry");
      Assert
        (Latest_Message_Text (S) = "Could not reopen closed buffer",
         "failed reopen emits the canonical failure message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Missing_File_Reopen_Fails_Deterministically;

   procedure Test_Dirty_Close_Cancel_And_Discard_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("dirty_close_cancel_discard.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "dirty active close must open an explicit close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Active_Buffer_Close_Scope,
              "dirty active close must record active-buffer close scope");
      Assert (Editor.Buffers.Global_Contains (Id),
              "dirty active close must not close before confirmation");
      Assert (Buffer_Text (S) = "dirty text",
              "dirty active close prompt must preserve text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Assert (not S.Dirty_Close_Prompt_Active,
              "cancel must clear dirty close prompt state");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.No_Dirty_Close_Scope,
              "cancel must clear dirty close prompt scope");
      Assert (Editor.Buffers.Global_Contains (Id),
              "cancel must keep the dirty buffer open");
      Assert (Buffer_Text (S) = "dirty text",
              "cancel must preserve dirty text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "discard confirmation must clear dirty close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "discard confirmation must close the dirty buffer");
      Assert (Ada.Directories.Exists (Path),
              "discard close must not delete the backing file");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Close_Cancel_And_Discard_Are_Explicit;

   procedure Test_Save_And_Close_Uses_File_Lifecycle_And_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("save_and_close.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "saved then closed");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "save-and-close starts from dirty close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Active_Buffer_Close_Scope,
              "save-and-close review records active-buffer scope");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "successful save-and-close must clear close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "successful save-and-close must close the buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "saved then closed",
              "save-and-close must persist through File_Lifecycle save path");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_And_Close_Uses_File_Lifecycle_And_Closes;

   procedure Test_Save_And_Close_Revalidates_Clean_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("save_close_revalidate_clean.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty before prompt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "revalidation test starts from dirty close review");

      Set_Buffer_Text (S, "clean before confirmation");
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "clean revalidation must clear close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "clean revalidation must still close the target buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "baseline",
              "clean revalidation must not write an already-clean target");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_And_Close_Revalidates_Clean_Target;

   procedure Test_Stale_Close_Target_Revalidates_And_Clears
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("stale_close_target.txt");
      Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed       : Boolean := False;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty target");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "stale target test starts from dirty close review");
      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      Assert (Closed, "fixture removes prompt target after review opens");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "stale prompt target must not offer save-and-close");
      Assert (To_String (Availability.Reason) = "Selected buffer is no longer open",
              "stale prompt target reports precise unavailable reason");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "stale prompt target must not offer discard-and-close");
      Assert (To_String (Availability.Reason) = "Selected buffer is no longer open",
              "stale discard target reports precise unavailable reason");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "stale save-and-close target clears prompt without mutation");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty target again");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "stale discard test starts from dirty close review");
      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      Assert (Closed, "fixture removes discard target after review opens");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "stale discard target clears prompt without failure state");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Stale_Close_Target_Revalidates_And_Clears;

   procedure Test_Save_And_Close_Conflict_Overwrite_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("save_close_conflict.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty close overwrite");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Write_Text_File (Path, "external replacement with different size");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "conflict close starts from dirty close review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "conflict save-and-close transfers ownership to file conflict prompt");
      Assert (S.File_Conflict_Prompt_Active,
              "save-and-close must surface conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "save-and-close must remember close-after-overwrite transiently");
      Assert (not S.File_Conflict_Close_After_Overwrite_All_Buffers,
              "single-buffer save-and-close must not resume close-all after overwrite");
      Assert (Editor.Buffers.Global_Contains (Id),
              "conflicted buffer remains open before explicit overwrite");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "overwrite-after-close must clear the file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "explicit overwrite after save-and-close must close the buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "dirty close overwrite",
              "overwrite-after-close must write buffer text before closing");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_And_Close_Conflict_Overwrite_Closes;

   procedure Test_Close_All_Save_Conflict_Overwrite_Continues
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path_1  : constant String := Temp_Path ("close_all_conflict_1.txt");
      Path_2  : constant String := Temp_Path ("close_all_conflict_2.txt");
      Id_1    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Id_2    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result  : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path_1);
      Remove_File_If_Exists (Path_2);
      Write_Text_File (Path_1, "baseline one");
      Write_Text_File (Path_2, "baseline two");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path_1);
      Id_1 := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty one after conflict");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path_2);
      Id_2 := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty two saved normally");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Write_Text_File (Path_1, "external replacement");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "close-all save starts from dirty review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (S.File_Conflict_Prompt_Active,
              "close-all save conflict must surface file conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite_All_Buffers,
              "close-all save conflict must remember close-all resume scope");
      Assert (Editor.Buffers.Global_Contains (Id_1),
              "conflicted close-all buffer remains open before overwrite");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "close-all overwrite must clear file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Id_1),
              "close-all overwrite must close conflicted buffer after successful write");
      Assert (not Editor.Buffers.Global_Contains (Id_2),
              "close-all overwrite resume must continue save-and-close for remaining buffers");
      Result := Editor.Files.Open_File (Path_1);
      Assert (To_String (Result.Contents) = "dirty one after conflict",
              "close-all overwrite must write conflicted buffer text");
      Result := Editor.Files.Open_File (Path_2);
      Assert (To_String (Result.Contents) = "dirty two saved normally",
              "close-all overwrite resume must save remaining file-backed buffers");

      Remove_File_If_Exists (Path_1);
      Remove_File_If_Exists (Path_2);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path_1);
         Remove_File_If_Exists (Path_2);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Save_Conflict_Overwrite_Continues;

   procedure Test_Discard_Pending_Unavailable_For_Reload_Revert
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("reload_discard_unavailable.txt");
      A    : Editor.Commands.Command_Availability;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty reload text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Active_Buffer);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Discard_Pending_Transition);
      Assert (not Editor.Commands.Is_Available (A),
              "discard pending must not be available for reload/revert confirmations");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Discard_Pending_Unavailable_For_Reload_Revert;

   procedure Test_Discard_Pending_Close_Buffer_Revalidates_Clean_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("pending_close_clean_revalidated.txt");
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean before pending close");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Id /= Editor.Buffers.No_Buffer,
              "pending-close fixture must open a real buffer");

      Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("pending close target"),
         Buffer_Id  => Natural (Id),
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Contains (Id),
              "pending-close target starts open before confirmation");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Discard_Pending_Transition);

      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "clean revalidated pending close clears transition");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "pending close discard closes reviewed clean target");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Discard_Pending_Close_Buffer_Revalidates_Clean_Target;

   procedure Test_Dirty_Close_Distinguishes_Save_Failure_From_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("save_failure_prompt_counts.txt");
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty after failed save");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      S.File_Info.External_Change_Surfaced := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "dirty close must open review for failed-save dirty buffer");
      Assert (S.Dirty_Close_Prompt_Save_Failure_Count = 1,
              "close review must classify prior save failure separately");
      Assert (S.Dirty_Close_Prompt_Conflicted_Count = 0,
              "prior save failure must not be reported as an external file conflict");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Close_Distinguishes_Save_Failure_From_Conflict;

   procedure Test_Unbacked_Close_Does_Not_Offer_Save_And_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "scratch dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "unbacked dirty close must open explicit review");
      Assert (S.Dirty_Close_Prompt_Untitled_Count = 1,
              "unbacked dirty close must classify scratch buffers");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "unbacked dirty close must not offer save-and-close without Save As");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "unbacked dirty close must still offer explicit discard");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "clean scratch close confirmation must be available after revalidation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Assert (Editor.State.Has_Active_Buffer (S),
              "cancelling unbacked close must preserve scratch buffer");
      Assert (Buffer_Text (S) = "scratch dirty text",
              "cancelling unbacked close must preserve scratch text");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Unbacked_Close_Does_Not_Offer_Save_And_Close;

   procedure Test_Single_Close_Save_Action_Revalidates_Path_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      A          : Editor.Commands.Command_Availability;
      Snap       : Editor.Render_Model.Render_Snapshot;
      Path       : constant String := Temp_Path ("single_close_path_revalidate.txt");
      Scratch_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Scratch_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "scratch becomes file-backed");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "path-revalidation fixture starts scratch close review");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "dirty scratch close initially hides save-and-close");

      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("single_close_path_revalidate.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "save-and-close must be exposed when target gains a path");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "render must expose save when close target gains a path");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Editor.Buffers.Global_Set_Active_Buffer (Scratch_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);

      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("scratch");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "path-loss fixture restarts dirty close review");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "save-and-close must be hidden when target loses its path");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "render must hide save when close target loses its path");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "discard remains available after live path loss");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Single_Close_Save_Action_Revalidates_Path_State;

   procedure Test_Render_Model_Projects_Dirty_Close_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Path : constant String := Temp_Path ("render_dirty_close_actions.txt");
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty render review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Prompt_Visible,
              "render snapshot must expose dirty close prompt visibility");
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "render snapshot must expose save-and-close action for file-backed dirty buffer");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "render snapshot must expose discard action");
      Assert (Snap.Dirty_Close_Cancel_Action_Available,
              "render snapshot must expose cancel action");
      Assert (Length (Snap.Dirty_Close_Buffer_Ids) > 0,
              "render snapshot must expose reviewed close candidate ids");
      Assert (Length (Snap.Dirty_Close_Dirty_Buffer_Ids) > 0,
              "render snapshot must expose reviewed dirty candidate ids");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "scratch render review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Dirty_Close_Prompt_Visible,
              "render snapshot must expose scratch dirty close prompt");
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "render snapshot must not expose save-and-close for scratch buffer without Save As");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "render snapshot must still expose discard for scratch buffer");
      Assert (Snap.Dirty_Close_Cancel_Action_Available,
              "render snapshot must still expose cancel for scratch buffer");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "render snapshot must revalidate clean scratch target for save-and-close");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Render_Model_Projects_Dirty_Close_Actions;

   procedure Test_Close_All_Review_Stale_Buffer_Set_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "close-all review starts from explicit dirty close prompt");
      Assert (S.Dirty_Close_Prompt_Buffer_Count = 2,
              "close-all review records the transient candidate count");

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 3,
              "fixture creates a stale close-all candidate set");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "stale close-all review must not offer save-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "stale close-all save reports precise reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "stale close-all review must not offer discard-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "stale close-all discard reports precise reason");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "stale close-all confirmation clears transient review");
      Assert (Editor.Buffers.Global_Count = 3,
              "stale close-all confirmation must not close changed buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Stale_Buffer_Set_Is_Revalidated;

   procedure Test_Close_All_Review_Stale_Same_Count_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      First  : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "close-all replacement fixture starts explicit review");
      Assert (S.Dirty_Close_Prompt_Buffer_Count = 2,
              "replacement fixture records original count");
      Assert (S.Dirty_Close_Prompt_Buffer_Fingerprint /= 0,
              "replacement fixture records original buffer identity fingerprint");

      Editor.Buffers.Global_Force_Close_Buffer (First, Closed);
      Assert (Closed, "replacement fixture force closes one candidate");
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "replacement dirty candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Count = 2,
              "replacement fixture preserves all-buffer count");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "same-count replacement must not offer discard-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "same-count replacement reports stale close review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "same-count replacement clears stale review");
      Assert (Editor.Buffers.Global_Count = 2,
              "same-count replacement must not close new buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Stale_Same_Count_Is_Revalidated;

   procedure Test_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second clean close-all candidate");
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "newly-dirty fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 1,
              "newly-dirty fixture records original dirty count");
      Assert (S.Dirty_Close_Prompt_Dirty_Fingerprint /= 0,
              "newly-dirty fixture records original dirty identity fingerprint");

      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Set_Buffer_Text (S, "second buffer dirtied after review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Count = 2,
              "newly-dirty fixture preserves all-buffer count");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "newly dirty buffer must stale discard-and-close review");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "newly dirty buffer reports stale close review");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "newly dirty buffer must stale save-and-close review");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "newly dirty save reports stale close review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "newly dirty stale review clears after confirmation attempt");
      Assert (Editor.Buffers.Global_Count = 2,
              "newly dirty stale review must not close reviewed buffers");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated;

   procedure Test_Close_All_Review_All_Clean_Revalidated_As_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second dirty close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "cleaned-all fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 2,
              "cleaned-all fixture records original dirty count");

      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "all-clean reviewed set must still offer save-and-close as close confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "render snapshot must expose save action for all-clean reviewed set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "all-clean reviewed set clears prompt after close confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "all-clean reviewed set closes all buffers without stale refusal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_All_Clean_Revalidated_As_Close;

   procedure Test_Close_All_Review_All_Clean_Discard_Revalidated_As_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty discard close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second dirty discard close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "cleaned-all discard fixture starts explicit close-all review");

      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "all-clean reviewed set must still offer discard as close confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "render snapshot must expose discard action for all-clean reviewed set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "all-clean discard reviewed set clears prompt after close confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "all-clean discard reviewed set closes all buffers without stale refusal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_All_Clean_Discard_Revalidated_As_Close;

   procedure Test_Close_All_Review_Subset_Dirty_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first reviewed dirty buffer cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second reviewed dirty buffer remains dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "subset-dirty fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 2,
              "subset-dirty fixture records both reviewed dirty buffers");

      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "reviewed dirty subset must still offer discard confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "render must expose discard when remaining dirty buffers were reviewed");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "reviewed dirty subset clears prompt after discard confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "reviewed dirty subset closes the unchanged reviewed buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Subset_Dirty_Revalidated;

   procedure Test_Close_All_Review_Subset_Scratch_Save_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      Snap  : Editor.Render_Model.Render_Snapshot;
      First : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first reviewed scratch cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second reviewed scratch remains dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "scratch subset fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Untitled_Count = 2,
              "scratch subset fixture records reviewed scratch buffers");

      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "reviewed scratch subset must not offer save-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Buffer has no file path.",
              "reviewed scratch subset reports Save As requirement");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "reviewed scratch subset must still offer explicit discard");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "render must hide save when remaining reviewed dirty set is scratch-only");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "render must keep discard for reviewed scratch subset");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "reviewed scratch subset clears prompt after discard confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "reviewed scratch subset closes all buffers after explicit discard");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Subset_Scratch_Save_Unavailable;

   procedure Test_Close_All_Review_Message_Summarizes_Dirty_Set
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("close_all_review_message.txt");
      File_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      File_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty file");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "dirty scratch");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);

      Assert (S.Dirty_Close_Prompt_Active,
              "close-all dirty review should remain active");
      Assert (Editor.Buffers.Global_Contains (File_Id),
              "close-all review must not close file buffer before confirmation");
      Assert (Latest_Message_Text (S) =
              "2 dirty buffers require confirmation (1 file-backed, 1 scratch).",
              "close-all dirty review message should summarize count and categories");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Review_Message_Summarizes_Dirty_Set;

   procedure Test_Close_All_Save_Failure_Rebuilds_Remaining_Review
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("close_all_partial_save_failure.txt");
      File_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A       : Editor.Commands.Command_Availability;
      Result  : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Text_File (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      File_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "file saved before scratch failure");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Scratch := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "scratch remains after save failure");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "mixed close-all fixture starts explicit review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not Editor.Buffers.Global_Contains (File_Id),
              "partial close-all save should close saved file-backed buffers");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "file saved before scratch failure",
              "partial close-all save should use File_Lifecycle for file-backed buffers");
      Assert (Editor.Buffers.Global_Contains (Scratch),
              "partial close-all save should keep unbacked dirty buffers open");
      Assert (S.Dirty_Close_Prompt_Active,
              "partial close-all save should rebuild review for remaining dirty buffers");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 1,
              "rebuilt close-all review should describe the remaining scratch buffer");
      Assert (S.Dirty_Close_Prompt_Save_Failure_Count = 1,
              "rebuilt close-all review should retain the save failure summary");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "rebuilt close-all review must still allow explicit discard of remaining dirty buffers");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "discard after rebuilt review clears the close prompt");
      Assert (Editor.Buffers.Global_Count = 0,
              "discard after rebuilt review closes the remaining scratch buffer");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_All_Save_Failure_Rebuilds_Remaining_Review;

   procedure Test_Close_Others_Closes_Clean_And_Skips_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Other_Buffers (S);

      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "close-others must keep active buffer selected");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "close-others must close clean non-active buffers");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "close-others must skip dirty non-active buffers");
      Assert (Editor.Buffers.Global_Contains (C_Id),
              "close-others must keep the active buffer open");
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "close-others must remove closed buffers from recent order");
      declare
         Found : Boolean := False;
         M     : Editor.Messages.Editor_Message;
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert
           (Found and then To_String (M.Text) = "Buffers: closed 1, skipped 1 dirty",
            "close-others feedback must be compact and deterministic");
      end;

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_Others_Closes_Clean_And_Skips_Dirty;

   procedure Test_Close_Clean_Closes_Clean_And_Preserves_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Replace_Buffer_Contents (S, "dirty buffer");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Close_Commands.Execute_Close_All_Clean_Buffers (S);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "close-clean must close clean inactive buffers");
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "close-clean may close the active clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "close-clean must preserve dirty buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "close-clean must choose deterministic dirty fallback");
      Assert (Buffer_Text (S) = "dirty buffer",
              "close-clean must preserve dirty buffer content");
      Assert (S.File_Info.Dirty,
              "close-clean must preserve dirty markers");
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "close-clean must remove closed clean buffers from recent order");
      declare
         Found : Boolean := False;
         M     : Editor.Messages.Editor_Message;
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert
           (Found and then To_String (M.Text) = "Buffers: closed 2, skipped 1 dirty",
            "close-clean feedback must be compact and deterministic");
      end;

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_Clean_Closes_Clean_And_Preserves_Dirty;

   procedure Test_Cleanup_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_Other_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "close-others must remain discoverable with dirty review guards");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_All_Clean_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "close-clean must be discoverable as a safe no-discard workflow");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.close-other-buffers", Found) = Editor.Commands.Command_Close_Other_Buffers
         and then Found,
         "close-others canonical stable name must resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.close-clean-buffers", Found) = Editor.Commands.Command_Close_All_Clean_Buffers
         and then Found,
         "close-clean canonical stable name must resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-active", Found) = Editor.Commands.Command_Close_Active_Buffer
         and then Found,
         "expected buffer.close-active alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-selected", Found) = Editor.Commands.Command_Buffer_Switcher_Selected_Close
         and then Found,
         "expected buffer.close-selected alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-all", Found) = Editor.Commands.Command_Close_All_Buffers
         and then Found,
         "expected buffer.close-all alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-clean", Found) = Editor.Commands.Command_Close_All_Clean_Buffers
         and then Found,
         "expected buffer.close-clean alias must resolve without payload");
   end Test_Cleanup_Command_Descriptors;

   overriding procedure Register_Tests (T : in out Lifecycle_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Clean_File_And_Reopen'Access,
         "close clean file and reopen");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Others_Closes_Clean_And_Skips_Dirty'Access,
         "close others closes clean and skips dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Clean_Closes_Clean_And_Preserves_Dirty'Access,
         "close clean closes clean and preserves dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cleanup_Command_Descriptors'Access,
         "cleanup command descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reopen_Reverse_Order_After_Cleanup'Access,
         "cleanup close history avoids reopen candidates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reopen_Unavailable_With_No_Candidate'Access,
         "reopen unavailable with no candidate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Dirty_Close_Does_Not_Record'Access,
         "blocked dirty close does not record");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reopen_Already_Open_File_Focuses_Existing'Access,
         "reopen already-open file focuses existing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Missing_File_Reopen_Fails_Deterministically'Access,
         "missing file reopen fails deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Close_Cancel_And_Discard_Are_Explicit'Access,
         "dirty close cancel and discard are explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_And_Close_Uses_File_Lifecycle_And_Closes'Access,
         "save and close uses file lifecycle and closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_And_Close_Revalidates_Clean_Target'Access,
         "save and close revalidates clean target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stale_Close_Target_Revalidates_And_Clears'Access,
         "stale close target revalidates and clears");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_And_Close_Conflict_Overwrite_Closes'Access,
         "save and close conflict overwrite closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Save_Conflict_Overwrite_Continues'Access,
         "close-all save conflict overwrite continues");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Discard_Pending_Unavailable_For_Reload_Revert'Access,
         "discard pending unavailable for reload/revert");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Discard_Pending_Close_Buffer_Revalidates_Clean_Target'Access,
         "discard pending close-buffer revalidates clean target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Close_Distinguishes_Save_Failure_From_Conflict'Access,
         "dirty close distinguishes save failure from conflict");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unbacked_Close_Does_Not_Offer_Save_And_Close'Access,
         "unbacked close does not offer save and close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Single_Close_Save_Action_Revalidates_Path_State'Access,
         "single close save action revalidates path state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Model_Projects_Dirty_Close_Actions'Access,
         "render model projects dirty close actions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Stale_Buffer_Set_Is_Revalidated'Access,
         "close-all review stale buffer set is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Stale_Same_Count_Is_Revalidated'Access,
         "close-all review stale same-count replacement is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated'Access,
         "close-all review newly dirty buffer is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_All_Clean_Revalidated_As_Close'Access,
         "close-all review allows unchanged buffer set when reviewed dirty buffers became clean");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_All_Clean_Discard_Revalidated_As_Close'Access,
         "close-all discard review allows unchanged buffer set when reviewed dirty buffers became clean");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Subset_Dirty_Revalidated'Access,
         "close-all review allows remaining dirty subset when all current dirty buffers were reviewed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Subset_Scratch_Save_Unavailable'Access,
         "close-all reviewed scratch subset hides save and keeps discard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Review_Message_Summarizes_Dirty_Set'Access,
         "close-all review message summarizes dirty set");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_All_Save_Failure_Rebuilds_Remaining_Review'Access,
         "close-all save failure rebuilds remaining review");
   end Register_Tests;

end Editor.Executor.Lifecycle_Tests;
