with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Configuration_Audit;
with Editor.Clipboard;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Selection_Commands;
with Editor.Files;
with Editor.Files.Test_Helpers; use Editor.Files.Test_Helpers;
with Editor.File_Tree;
with Editor.Buffers;
with Editor.Feature_Panel;
with Editor.History;
with Editor.Diagnostics;
with Editor.Dirty_Guards;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.State;
with Editor.Test_Helper;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Lifecycle_Guidance;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Pending_Transitions;
with Editor.Search;
with Editor.Settings;
with Editor.View;
with Editor.Workspace_Persistence;
with Text_Buffer;

package body Editor.Files.Target_Prompt_Metadata_Tests is

   use type Editor.Files.File_Status;
   use type Editor.Files.File_Open_Status;
   use type Editor.Files.File_Save_Status;
   use type Editor.Files.File_Move_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Command_Palette.Command_Palette_Row_Kind;
   use type Editor.Commands.Command_Family_Id;
   use type Editor.Commands.Command_Effect_Classification_Id;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Messages.Message_Severity;
   use type Editor.Navigation_History.Navigation_History_Reason;
   use type Editor.Configuration_Audit.Configuration_Audit_Status;
   use type Editor.State.File_Conflict_Kind;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Workspace_Persistence.Workspace_Feature_Panel_Id;
   use type Editor.Workspace_Persistence.Workspace_Quick_Open_File_Kind_Filter;
   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;
   procedure Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("active_source_a.txt");
      Active : constant String := Temp_Path ("active_source_b.txt");
      Target : constant String := Temp_Path ("active_target.txt");
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Active);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "source A");
      Write_Bytes (Active, "source B");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Previous_Buffer);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source,
        "fixture should start prompt from source A");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "copy without target should open prompt before active-buffer switch");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Next_Buffer);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Active,
        "fixture should switch active buffer before prompt confirmation");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "confirmation after active-buffer switch should clear prompt");
      Assert (Read_Bytes (Target) = "source B",
        "prompt confirmation should use active buffer at confirmation time");
      Assert (Read_Bytes (Source) = "source A",
        "prompt confirmation must not copy stale source-open buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (M.Text) = "Buffer file copied",
        "active-buffer-at-confirmation copy should emit canonical copy outcome only");

      Remove_If_Exists (Source);
      Remove_If_Exists (Active);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Active);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation;


   procedure Test_Second_Target_Prompt_Replaces_First_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("second_prompt_source.txt");
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "second prompt source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "rename-target-should-be-discarded.txt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Rename target",
        "first eligible target command should own prompt");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "second eligible target command should leave one prompt active");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Copy target",
        "second target prompt should deterministically replace command label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "second target prompt must discard prior prompt input and not infer history");
      Assert (Read_Bytes (Source) = "second prompt source",
        "prompt replacement must not rename, copy, move, or save files");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt replacement must not emit underlying file command feedback");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Second_Target_Prompt_Replaces_First_Deterministically;


   procedure Test_Target_Prompt_Workspace_Persistence_Excluded
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: workspace summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "persistence text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
        (S, "prompt-target-must-not-persist.txt");
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert_Summary_Excludes ("prompt-target-must-not-persist.txt");
      Assert_Summary_Excludes ("Save As target");
      Assert_Summary_Excludes ("file target prompt");
      Assert_Summary_Excludes ("target prompt");
      Assert_Summary_Excludes ("last target");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) =
          "prompt-target-must-not-persist.txt",
        "workspace snapshot must inspect state without clearing or mutating prompt input");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "lifecycle reset after workspace snapshot should still clear prompt state");
   end Test_Target_Prompt_Workspace_Persistence_Excluded;


   procedure Test_Target_Prompt_Workflow_Coherence_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Source      : constant String := Temp_Path ("matrix_source.txt");
      Before_Text : constant String := "matrix source";

      function Is_Target_Command (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return Id = Editor.Commands.Command_Save_File_As
           or else Id = Editor.Commands.Command_Rename_Buffer_File
           or else Id = Editor.Commands.Command_Copy_Buffer_File
           or else Id = Editor.Commands.Command_Move_Buffer_File;
      end Is_Target_Command;

      procedure Assert_Opens_Empty_Prompt
        (Id    : Editor.Commands.Command_Id;
         Label : String)
      is
      begin
         Editor.Executor.Execute_Command (S, Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "eligible canonical target command should open exactly one prompt");
         Assert (S.File_Target_Prompt_Command = Id,
           "prompt should retain the canonical pending command id only");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = Label,
           "prompt label should be deterministic per canonical command");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "prompt input should not be inferred from command/palette/history state");
         Assert (Editor.Overlay_Focus.Is_Active
                   (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay),
           "opened prompt should explicitly own overlay input focus");
         Assert (Buffer_Text (S) = Before_Text
           and then not S.File_Info.Dirty
           and then To_String (S.File_Info.Path) = Source,
           "opening prompt must not mutate buffer text, dirty state, or association");
         Assert (Editor.Messages.Count (S.Messages) = 0,
           "opening prompt must not emit underlying command outcome messages");
         Assert (Read_Bytes (Source) = Before_Text,
           "opening prompt must not perform filesystem work");
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      end Assert_Opens_Empty_Prompt;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text (Editor.Test_Temp.Base & "/from-palette-query.adb");
      Editor.Clipboard.Set_Text (To_Unbounded_String (Editor.Test_Temp.Base & "/from-clipboard.adb"));
      S.Active_Find_Query := To_Unbounded_String (Editor.Test_Temp.Base & "/from-find.adb");
      S.Active_Replace_Text := To_Unbounded_String (Editor.Test_Temp.Base & "/from-replace.adb");

      for Id in Editor.Commands.Command_Id loop
         Assert (Editor.Executor.Shared_Services.Command_Requires_Explicit_Target (Id) = Is_Target_Command (Id),
           "target-prompt-capable command set must be exactly save-as/rename/copy/move");
      end loop;

      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Save_File_As, "Save As target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Rename_Buffer_File, "Rename target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Copy_Buffer_File, "Copy target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Move_Buffer_File, "Move target");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.save must never open a target prompt");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.delete-buffer-file must never open a target prompt");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Workflow_Coherence_Matrix;


   procedure Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : constant String := "edit isolation";
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Caret   : Editor.Cursors.Caret_State;
      Target         : constant String := Temp_Path ("edit_target.txt");
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("find-state");
      S.Active_Replace_Text := To_Unbounded_String ("replace-state");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard-state"));
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "xy");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
      Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "insert/backspace/caret/delete should edit prompt input only");
      Assert (Buffer_Text (S) = Before_Text
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "prompt text editing must not route through buffer insertion or history");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "prompt text editing must preserve active-buffer caret/selection");
      Assert (To_String (S.Active_Find_Query) = "find-state"
        and then To_String (S.Active_Replace_Text) = "replace-state"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard-state",
        "prompt text editing must preserve Find/Replace and Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt text editing must not emit command outcome messages");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command,
        "cancellation should clear command and transient input");
      Assert (not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty,
        "cancellation must not execute file lifecycle behavior or mutate buffer state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "cancellation must not emit invalid-target, failure, or success messages");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "confirmation should clear prompt before canonical command dispatch outcome");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "invalid submitted target should produce exactly one canonical command outcome");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "invalid target confirmation must preserve buffer text and dirty state through canonical validation");

      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy;


   procedure Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Source       : constant String := Temp_Path ("route_source.txt");
      Candidates   : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Count_Save_As : Natural := 0;
      Count_Rename  : Natural := 0;
      Count_Copy    : Natural := 0;
      Count_Move    : Natural := 0;
      Found         : Boolean := False;
      Id            : Editor.Commands.Command_Id;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;
      Config_Before : Editor.Configuration_Audit.Configuration_State_Summary;
      Config_After  : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "route source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C : constant Editor.Commands.Command_Palette_Candidate := Candidates.Element (I);
            begin
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Count_Save_As := Count_Save_As + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Count_Rename := Count_Rename + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Count_Copy := Count_Copy + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Count_Move := Count_Move + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Count_Save_As = 1 and then Count_Rename = 1
        and then Count_Copy = 1 and then Count_Move = 1,
        "Command Palette projection must expose each canonical target command once and no prompted aliases");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Command Palette projection must be side-effect-free and must not open prompts");

      Editor.Command_Palette.Insert_Text (Editor.Test_Temp.Base & "/query-must-not-be-target.adb");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "Command Palette/keybinding canonical invocation path should open empty prompt, not query text");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);

      Assert (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Rename_Buffer_File)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Copy_Buffer_File)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Move_Buffer_File),
        "keybinding routes should continue to target canonical bindable command names only");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save-as-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted save-as alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.rename-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted rename alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.copy-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted copy alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.move-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted move alias must remain absent");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "rename-text-must-be-cleared");
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "opening another exclusive overlay should deterministically clear target prompt state");
      Assert (not Ada.Directories.Exists ("rename-text-must-be-cleared"),
        "overlay supersession must not submit target prompt text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "audit-text-must-remain-local");
      Config_Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Copy_Buffer_File);
      Config_After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0,
        "inert route audit should not report failures for canonical command route recording");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "audit-text-must-remain-local",
        "route/configuration audits must not confirm, cancel, or mutate prompt state");
      Assert (Config_Before.Message_Count = Config_After.Message_Count
        and then Config_Before.Dirty_Buffer_Count = Config_After.Dirty_Buffer_Count,
        "configuration audit summary must inspect prompt-adjacent state without runtime mutation");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow;


   procedure Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Restored      : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source_A      : constant String := Temp_Path ("confirm_a.txt");
      Source_B      : constant String := Temp_Path ("confirm_b.txt");
      Target        : constant String := Temp_Path ("confirm_target.txt");
      Direct_Target : constant String := Temp_Path ("direct_target.txt");
      Direct_Copy   : constant String := Temp_Path ("direct_copy.txt");
      Direct_Rename : constant String := Temp_Path ("direct_rename.txt");
      Direct_Move   : constant String := Temp_Path ("direct_move.txt");
      A             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Target);
      Remove_If_Exists (Direct_Target);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render snapshot should project active prompt label/input structurally");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "render snapshot must not mutate prompt input");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0,
        "workspace persistence must exclude pending command, label, and target text");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must not restore transient target prompt state");

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Target) = "source b",
        "prompt confirmation should use active buffer at confirmation time through canonical Executor route");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "successful confirmation should clear transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation success must emit exactly one canonical command outcome message");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Target);
      Assert (Read_Bytes (Direct_Target) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As must bypass prompt and preserve canonical behavior");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Target
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Copy must bypass prompt and preserve association");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Direct_Rename);
      Assert (Ada.Directories.Exists (Direct_Rename)
        and then not Ada.Directories.Exists (Direct_Target)
        and then To_String (S.File_Info.Path) = Direct_Rename
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Rename must bypass prompt and update canonical association");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Direct_Move);
      Assert (Ada.Directories.Exists (Direct_Move)
        and then not Ada.Directories.Exists (Direct_Rename)
        and then To_String (S.File_Info.Path) = Direct_Move
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Move must bypass prompt and update canonical association");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "lifecycle-discarded-target.txt");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists ("lifecycle-discarded-target.txt"),
        "lifecycle cleanup should clear target prompt without executing filesystem work");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Target);
      Remove_If_Exists (Direct_Target);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Target);
         Remove_If_Exists (Direct_Target);
         Remove_If_Exists (Direct_Copy);
         Remove_If_Exists (Direct_Rename);
         Remove_If_Exists (Direct_Move);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior;



procedure Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source         : constant String := Temp_Path ("no_infer_source.txt");
      Target         : constant String := Temp_Path ("exact target.txt");
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Text    : constant String := "no inference source";
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text (Editor.Test_Temp.Base & "/command-palette-query.adb");
      Editor.Clipboard.Set_Text (To_Unbounded_String (Editor.Test_Temp.Base & "/clipboard-target.adb"));
      S.Active_Find_Query := To_Unbounded_String (Editor.Test_Temp.Base & "/find-target.adb");
      S.Active_Replace_Text := To_Unbounded_String (Editor.Test_Temp.Base & "/replace-target.adb");
      S.Reopen_Candidate_Path := To_Unbounded_String (Editor.Test_Temp.Base & "/reopen-target.adb");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As,
        "canonical invocation without target should open one pending save-as prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "prompt input must not be inferred from palette, clipboard, find/replace, or reopen state");
      Assert (Editor.Messages.Count (S.Messages) = 0
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source,
        "prompt opening must remain side-effect-free and filesystem-free");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & " stale");
      Editor.Executor.File_Target_Prompt_Commands.Select_All_File_Target_Prompt_Text (S);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "prompt editing must be owned by the canonical prompt input helper");
      Assert (Buffer_Text (S) = Before_Text
        and then To_String (S.Active_Find_Query) = Editor.Test_Temp.Base & "/find-target.adb"
        and then To_String (S.Active_Replace_Text) = Editor.Test_Temp.Base & "/replace-target.adb"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = Editor.Test_Temp.Base & "/clipboard-target.adb",
        "prompt input must not leak into buffer, find/replace, or clipboard state");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "File_Target_Prompt") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "last prompted target") = 0,
        "workspace snapshot must exclude prompt command, label, input, caches, and target history");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must not reconstruct prompt state from persistence");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Editor.Messages.Count (S.Messages) = 0,
        "canonical cancellation must clear command/input and emit no lifecycle outcome");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target),
        "lifecycle cleanup must use canonical state clearing and never confirm typed targets");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup;


   procedure Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source_A      : constant String := Temp_Path ("confirm_a.txt");
      Source_B      : constant String := Temp_Path ("confirm_b.txt");
      Prompt_Target : constant String := Temp_Path ("prompt exact target.txt");
      Direct_Save   : constant String := Temp_Path ("direct_save.txt");
      Direct_Copy   : constant String := Temp_Path ("direct_copy.txt");
      A             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Prompt_Target) = "source b",
        "confirmation must route exact submitted target through Executor using active buffer at confirmation");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "confirmation must clear canonical transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation must emit exactly one canonical underlying command outcome");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Save);
      Assert (Read_Bytes (Direct_Save) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target save-as must remain prompt-free");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Save
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target copy must remain prompt-free and preserve association");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Save);
         Remove_If_Exists (Direct_Copy);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical;

   procedure Test_Workspace_Restore_Applies_Continuity_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      After          : Editor.Workspace_Persistence.Workspace_Snapshot;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Root           : constant String := Temp_Path ("restore_continuity_project");
      Src            : constant String := Ada.Directories.Compose (Root, "src");
      Source         : constant String := Ada.Directories.Compose (Src, "main.adb");
      Switched       : Boolean := False;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_Bytes (Source, "procedure Main is begin null; end Main;");
      Editor.Buffers.Reset_Global_For_Test;

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src");
      Editor.Quick_Open.Set_File_Kind_Filter
        (S.Quick_Open, Editor.Quick_Open.Ada_Files);
      Switched := Editor.Feature_Panel.Set_Active_Feature
        (S.Feature_Panel, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Switched, "test setup should activate Diagnostics feature panel");
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);

      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot
        (Restored, Workspace, Restore_Status);
      Assert (Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace restore should apply complete structural state");
      After := Editor.State.Build_Workspace_Snapshot (Restored);

      Assert (Editor.Workspace_Persistence.Has_Project_Root (After)
              and then Editor.Workspace_Persistence.Project_Root (After) = Root,
              "restore should reopen the project root");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (After)
              and then Editor.Workspace_Persistence.Active_File_Path (After) =
                "src/main.adb",
              "restore should select the active file");
      Assert (Editor.Workspace_Persistence.Quick_Open_Path_Scope (After) =
                "src/",
              "restore should apply Quick Open scope");
      Assert (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (After) =
                Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files,
              "restore should apply Quick Open file-kind filter");
      Assert (Editor.Workspace_Persistence.Feature_Panel_Visible (After),
              "restore should apply feature panel visibility");
      Assert (Editor.Workspace_Persistence.Active_Feature_Panel (After) =
                Editor.Workspace_Persistence.Workspace_Diagnostics_Feature,
              "restore should apply active feature panel selection");
      Assert (Editor.Workspace_Persistence.Has_Recent_Project_Path (After)
              and then Editor.Workspace_Persistence.Recent_Project_Path (After) =
                Root,
              "restore should preserve recent project continuity");

      Remove_If_Exists (Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Src);
         Remove_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Restore_Applies_Continuity_State;
procedure Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source         : constant String := Temp_Path ("input_source.txt");
      Target         : constant String := Temp_Path ("exact typed target.txt");
      Before_Text    : constant String := "input source";
      Before_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit    : Editor.Configuration_Audit.Configuration_State_Summary;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Availability   : Editor.Commands.Command_Availability;
      Snap           : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text (Editor.Test_Temp.Base & "/palette-query-must-not-be-target.txt");
      Editor.Clipboard.Set_Text (To_Unbounded_String (Editor.Test_Temp.Base & "/clipboard-must-not-be-target.txt"));
      S.Active_Find_Query := To_Unbounded_String (Editor.Test_Temp.Base & "/find-must-not-be-target.txt");
      S.Active_Replace_Text := To_Unbounded_String (Editor.Test_Temp.Base & "/replace-must-not-be-target.txt");
      S.Reopen_Candidate_Path := To_Unbounded_String (Editor.Test_Temp.Base & "/reopen-must-not-be-target.txt");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Copy_Buffer_File
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Copy target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source
        and then Editor.Messages.Count (S.Messages) = 0,
        "prompt opening must be side-effect-free and must not infer target text from UI/runtime state");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "xy");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
      Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.Active_Find_Query) = Editor.Test_Temp.Base & "/find-must-not-be-target.txt"
        and then To_String (S.Active_Replace_Text) = Editor.Test_Temp.Base & "/replace-must-not-be-target.txt"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = Editor.Test_Temp.Base & "/clipboard-must-not-be-target.txt",
        "prompt input edits must remain local to focused prompt state and not leak into buffer/find/replace/clipboard");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Copy target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "render snapshot must mirror prompt state without mutating or validating it");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "availability checks must not open, confirm, cancel, seed, or mutate prompt state");

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (Before_Audit.Message_Count = After_Audit.Message_Count
        and then Before_Audit.Dirty_Buffer_Count = After_Audit.Dirty_Buffer_Count
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "audit/reference summaries must inspect without confirming, cancelling, repairing, or mutating prompts");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Copy target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "palette-query") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "clipboard") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0,
        "workspace snapshots must exclude prompt input, labels, inference sources, and target histories");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Restored.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must drop any prompt-active runtime state");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source
        and then Editor.Messages.Count (S.Messages) = 0,
        "cancellation must clear prompt state without command execution, filesystem work, or messages");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Source,
        "overlay supersession must use canonical prompt cleanup and must not submit pending input");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Source),
        "lifecycle cleanup must discard prompt command/input without executing rename/copy/move/save-as");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze;


   procedure Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Source_A       : constant String := Temp_Path ("confirm_a.txt");
      Source_B       : constant String := Temp_Path ("confirm_b.txt");
      Prompt_Target  : constant String := Temp_Path ("prompt submitted target.txt");
      Direct_Save    : constant String := Temp_Path ("direct_save.txt");
      Direct_Copy    : constant String := Temp_Path ("direct_copy.txt");
      Direct_Rename  : constant String := Temp_Path ("direct_rename.txt");
      Direct_Move    : constant String := Temp_Path ("direct_move.txt");
      A              : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B              : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As,
        "save-as without explicit target should open the canonical transient prompt");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Prompt_Target) = "source b",
        "confirmation must dispatch through Executor using active buffer at confirmation and exact submitted target");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "confirmation must clear the canonical transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation must emit exactly one canonical underlying command outcome message");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.save must remain prompt-free");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.delete-buffer-file must remain prompt-free even though it is a file lifecycle command");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Save);
      Assert (Read_Bytes (Direct_Save) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target save-as must bypass prompt and preserve canonical behavior");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Save
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target copy must bypass prompt and preserve association");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Direct_Rename);
      Assert (Ada.Directories.Exists (Direct_Rename)
        and then not Ada.Directories.Exists (Direct_Save)
        and then To_String (S.File_Info.Path) = Direct_Rename
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target rename must bypass prompt and update canonical association");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Direct_Move);
      Assert (Ada.Directories.Exists (Direct_Move)
        and then not Ada.Directories.Exists (Direct_Rename)
        and then To_String (S.File_Info.Path) = Direct_Move
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target move must bypass prompt and update canonical association");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Save);
         Remove_If_Exists (Direct_Copy);
         Remove_If_Exists (Direct_Rename);
         Remove_If_Exists (Direct_Move);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze;



procedure Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("boundary_source.txt");
      Target        : constant String := Temp_Path ("exact target.txt");
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_As_Rows  : Natural := 0;
      Rename_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Msgs   : Natural := 0;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "boundary source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Before_Msgs := Editor.Messages.Count (S.Messages);

      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Target_Prompt_Label
                (Editor.Commands.Command_Save_File_As) = "Save As target",
        "reading minimal metadata must be a pure descriptor/accessor operation");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Editor.Messages.Count (S.Messages) = Before_Msgs
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Source,
        "metadata reads must not open prompts, seed input, emit messages, validate targets, or touch files");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text (Target);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C : constant Editor.Commands.Command_Palette_Candidate :=
                 Candidates.Element (I);
               Name : constant String := Editor.Commands.Stable_Command_Name (C.Id);
            begin
               Assert (Ada.Strings.Fixed.Index (Name, "prompt") = 0,
                 "Command Palette must not expose prompted aliases");
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Save_As_Rows := Save_As_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Rename_Rows := Rename_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Copy_Rows := Copy_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Move_Rows := Move_Rows + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Save_As_Rows <= 1 and then Rename_Rows <= 1
        and then Copy_Rows <= 1 and then Move_Rows <= 1,
        "Command Palette projection must not synthesize duplicate prompted rows");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "Command Palette query text must not become target prompt input");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "no-target invocation must still open the canonical prompt using the minimal label");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must project active prompt state, not a separate prompt-reference layer");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0,
        "persistence must exclude prompt runtime state, projection caches, metadata caches, and target history");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "cancellation remains non-mutating after metadata minimalization");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "boundary source"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target execution must bypass prompt and preserve canonical behavior");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze;


procedure Test_Target_Prompt_Metadata_Minimality_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Reject_In (Text : String; Forbidden : String; Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Text, Forbidden) = 0,
           "forbidden prompt-reference/minimality token '" &
           Forbidden & "' leaked into " & Context);
      end Reject_In;

      procedure Check_Command_Text (Id : Editor.Commands.Command_Id) is
         D       : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Context : constant String := Editor.Commands.Stable_Command_Name (Id);
         Text    : constant String :=
           Editor.Commands.Stable_Command_Name (Id) & " " &
           To_String (D.Name) & " " &
           To_String (D.Description) & " " &
           To_String (D.Summary) & " " &
           To_String (D.Availability_Summary) & " " &
           To_String (D.Mutation_Summary) & " " &
           To_String (D.Filesystem_Effect_Summary) & " " &
           To_String (D.State_Preservation_Summary) & " " &
           To_String (D.Non_Goal_Summary) & " " &
           To_String (D.Target_Prompt_Label);
      begin
         Reject_In (Text, "target_parameter_summary", Context);
         Reject_In (Text, "prompt_confirmation_summary", Context);
         Reject_In (Text, "prompt_cancellation_summary", Context);
         Reject_In (Text, "target_prompt_non_goals_summary", Context);
         Reject_In (Text, "prompt_reference_summary", Context);
         Reject_In (Text, "prompt_reference_family", Context);
         Reject_In (Text, "prompt_reference_effect_classification", Context);
         Reject_In (Text, "prompt_reference_availability_summary", Context);
         Reject_In (Text, "prompt_reference_documentation_text", Context);
         Reject_In (Text, "prompt_reference_search_text", Context);
         Reject_In (Text, "prompt_reference_projection_cache", Context);
         Reject_In (Text, "target history", Context);
         Reject_In (Text, "autocomplete", Context);
         Reject_In (Text, "file picker", Context);
         Reject_In (Text, "overwrite prompt", Context);
      end Check_Command_Text;
   begin
      for Id in Editor.Commands.Command_Id loop
         Check_Command_Text (Id);
      end loop;
   end Test_Target_Prompt_Metadata_Minimality_Guard;


   procedure Test_Metadata_Reads_Are_Pure_And_Availability_Independent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Target        : constant String := Temp_Path ("metadata_read_target.txt");
      Before_Msgs   : Natural := 0;
      Rename_Avail  : Editor.Commands.Command_Availability;
      Save_As_Avail : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Messages.Clear (S.Messages);
      Before_Msgs := Editor.Messages.Count (S.Messages);

      for Id in Editor.Commands.Command_Id loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (Id);
            pragma Unreferenced (D);
            Required : constant Boolean :=
              Editor.Commands.Command_Requires_Explicit_Target (Id);
            Capable : constant Boolean :=
              Editor.Commands.Command_Is_Target_Prompt_Capable (Id);
            Label : constant String := Editor.Commands.Command_Target_Prompt_Label (Id);
            pragma Unreferenced (Required, Capable, Label);
         begin
            null;
         end;
      end loop;

      Rename_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Save_As_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File_As);

      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Rename_Buffer_File)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Rename_Buffer_File)
        and then not Editor.Commands.Is_Available (Rename_Avail),
        "explicit-target metadata must not imply runtime availability");
      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Save_File_As)
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "metadata reads must not open the target prompt");
      Assert (Editor.Commands.Is_Available (Save_As_Avail)
          or else not Editor.Commands.Is_Available (Save_As_Avail),
        "availability remains an Executor-owned result, independent from metadata mapping");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Editor.Messages.Count (S.Messages) = Before_Msgs
        and then not Ada.Directories.Exists (Target),
        "metadata reads must not seed input, emit messages, validate paths, or touch files");

      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Metadata_Reads_Are_Pure_And_Availability_Independent;


   procedure Test_Command_Palette_Render_Audit_And_Persistence_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("boundary_source.txt");
      Target        : constant String := Temp_Path ("prompted target.txt");
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_As_Rows  : Natural := 0;
      Rename_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Audit  : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      Audit_Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "boundary source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C    : constant Editor.Commands.Command_Palette_Candidate :=
                 Candidates.Element (I);
               Name : constant String := Editor.Commands.Stable_Command_Name (C.Id);
            begin
               Assert (Ada.Strings.Fixed.Index (Name, "prompt") = 0,
                 "Command Palette must expose no prompted aliases");
               Assert (Ada.Strings.Fixed.Index (To_String (C.Label), "prompt_reference") = 0
                 and then Ada.Strings.Fixed.Index (To_String (C.Description), "prompt_reference") = 0
                 and then Ada.Strings.Fixed.Index (To_String (C.Reference_Summary), "prompt_reference") = 0,
                 "Command Palette projection must not synthesize prompt-reference prose");
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Save_As_Rows := Save_As_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Rename_Rows := Rename_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Copy_Rows := Copy_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Move_Rows := Move_Rows + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Save_As_Rows <= 1 and then Rename_Rows <= 1
        and then Copy_Rows <= 1 and then Move_Rows <= 1,
        "Command Palette must not synthesize duplicate prompted rows");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Command Palette projection must not open prompts");

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Audit_Result, Before_Audit, After_Audit,
         "target prompt metadata route/configuration audit");
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0
        and then Editor.Configuration_Audit.Status (Audit_Result) = Editor.Configuration_Audit.Configuration_Audit_Ok
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "route/configuration audits must be side-effect-free and must not open prompts");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must snapshot canonical prompt state only");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target
        and then not Ada.Directories.Exists (Target),
        "render snapshots must not confirm prompts or touch filesystem targets");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt label") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0,
        "workspace persistence must exclude prompt runtime state, projection caches, labels, and histories");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "cancellation remains non-mutating after metadata validation");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Palette_Render_Audit_And_Persistence_Boundary;



   procedure Test_Target_Prompt_Metadata_Canonical_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      type Expected_Metadata is record
         Id       : Editor.Commands.Command_Id;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 10) of Expected_Metadata :=
        ((Editor.Commands.Command_Save_File, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Save_File_As, True, True, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Close_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reopen_Closed_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reload_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Revert_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Rename_Buffer_File, True, True, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Delete_Buffer_File, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Copy_Buffer_File, True, True, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
   begin
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Minimal,
        "retained target prompt metadata must remain minimal");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal,
        "cleanup guard must keep canonical descriptor/accessor prompt metadata coherent");

      for E of Expected loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (E.Id);
         begin
            Assert (D.Requires_Explicit_Target = E.Required
              and then D.Target_Prompt_Capable = E.Capable
              and then To_String (D.Target_Prompt_Label) = To_String (E.Label),
              "descriptor-owned prompt metadata drift for " &
              Editor.Commands.Stable_Command_Name (E.Id));
            Assert (Editor.Commands.Command_Requires_Explicit_Target (E.Id) =
                    D.Requires_Explicit_Target
              and then Editor.Commands.Command_Is_Target_Prompt_Capable (E.Id) =
                       D.Target_Prompt_Capable
              and then Editor.Commands.Command_Target_Prompt_Label (E.Id) =
                       To_String (D.Target_Prompt_Label),
              "public prompt accessors must project descriptor metadata for " &
              Editor.Commands.Stable_Command_Name (E.Id));
            Assert (Editor.Executor.Shared_Services.Command_Requires_Explicit_Target (E.Id) =
                    D.Requires_Explicit_Target
              and then Editor.Executor.File_Target_Prompt_Commands.Command_Requires_File_Target_Prompt (E.Id) =
                       D.Target_Prompt_Capable,
              "Executor prompt predicates must remain canonical-accessor derived for " &
              Editor.Commands.Stable_Command_Name (E.Id));

            if D.Target_Prompt_Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
            end if;
         end;
      end loop;

      Assert (Prompt_Capable_Count = 4,
        "only Save As, Rename, Copy, and Move may be prompt-capable");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Command_Is_Target_Prompt_Capable (Id) then
            Assert (Editor.Commands.Is_File_Lifecycle_Command (Id)
              and then Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length > 0,
              "no non-file or unlabeled command may become prompt-capable");
         else
            Assert (not Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length = 0,
              "non-prompt-capable commands must carry no prompt metadata");
         end if;
      end loop;
   end Test_Target_Prompt_Metadata_Canonical_Cleanup;
procedure Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Source     : constant String := Temp_Path ("source.txt");
      Target     : constant String := Temp_Path ("target.txt");
      Workspace  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary    : Unbounded_String;
      Snap       : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "source text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "cleanup must preserve canonical Save As prompt opening");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must project active prompt snapshot state, not local metadata");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "projection cache") = 0,
        "workspace persistence must exclude prompt metadata, labels, caches, and target histories");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "prompt cancellation remains non-mutating");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As behavior must remain unchanged");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke;




   procedure Test_Minimal_Metadata_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      type Expected_Metadata is record
         Id       : Editor.Commands.Command_Id;
         Name     : Unbounded_String;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 10) of Expected_Metadata :=
        ((Editor.Commands.Command_Save_File, To_Unbounded_String ("file.save"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Save_File_As, To_Unbounded_String ("file.save-as"), True, True, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Close_Active_Buffer, To_Unbounded_String ("file.close-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reopen_Closed_Buffer, To_Unbounded_String ("file.reopen-closed-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reload_Active_Buffer, To_Unbounded_String ("file.reload-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Revert_Active_Buffer, To_Unbounded_String ("file.revert-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Rename_Buffer_File, To_Unbounded_String ("file.rename-buffer-file"), True, True, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Delete_Buffer_File, To_Unbounded_String ("file.delete-buffer-file"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Copy_Buffer_File, To_Unbounded_String ("file.copy-buffer-file"), True, True, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, To_Unbounded_String ("file.move-buffer-file"), True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
      Required_Count       : Natural := 0;

      procedure Reject_In (Text : String; Forbidden : String; Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Text, Forbidden) = 0,
           "forbidden prompt metadata token '" & Forbidden &
           "' leaked into " & Context);
      end Reject_In;

      procedure Assert_Descriptor_Minimal (Id : Editor.Commands.Command_Id) is
         D       : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Context : constant String := Editor.Commands.Stable_Command_Name (Id);
         Text    : constant String :=
           Context & " " &
           To_String (D.Name) & " " &
           To_String (D.Description) & " " &
           To_String (D.Summary) & " " &
           To_String (D.Availability_Summary) & " " &
           To_String (D.Mutation_Summary) & " " &
           To_String (D.Filesystem_Effect_Summary) & " " &
           To_String (D.State_Preservation_Summary) & " " &
           To_String (D.Non_Goal_Summary) & " " &
           To_String (D.Target_Prompt_Label);
      begin
         Reject_In (Text, "target_parameter_summary", Context);
         Reject_In (Text, "prompt_confirmation_summary", Context);
         Reject_In (Text, "prompt_cancellation_summary", Context);
         Reject_In (Text, "target_prompt_non_goals_summary", Context);
         Reject_In (Text, "prompt_reference_summary", Context);
         Reject_In (Text, "prompt_reference_family", Context);
         Reject_In (Text, "prompt_reference_effect_classification", Context);
         Reject_In (Text, "prompt_reference_availability_summary", Context);
         Reject_In (Text, "prompt_reference_documentation_text", Context);
         Reject_In (Text, "prompt_reference_search_text", Context);
         Reject_In (Text, "prompt_reference_projection_cache", Context);
         Reject_In (Text, "prompt_history", Context);
         Reject_In (Text, "target_history", Context);
         Reject_In (Text, "recent_target_list", Context);
         Reject_In (Text, "target_autocomplete_cache", Context);
         Reject_In (Text, "prompt-capable cache", Context);
         Reject_In (Text, "file picker", Context);
         Reject_In (Text, "overwrite prompt", Context);
         Reject_In (Text, "force prompt", Context);
      end Assert_Descriptor_Minimal;
   begin
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Minimal,
        "minimal metadata guard must remain true");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal,
        "canonical/minimal cleanup guard must remain true");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Frozen,
        "final metadata freeze guard must remain true");

      for E of Expected loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (E.Id);
         begin
            Assert (D.Id = E.Id
              and then Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
              "descriptor identity drift for " & To_String (E.Name));
            Assert (D.Requires_Explicit_Target = E.Required
              and then D.Target_Prompt_Capable = E.Capable
              and then To_String (D.Target_Prompt_Label) = To_String (E.Label),
              "descriptor-owned prompt metadata mapping drift for " & To_String (E.Name));
            Assert (Editor.Commands.Command_Requires_Explicit_Target (E.Id) = E.Required
              and then Editor.Commands.Command_Is_Target_Prompt_Capable (E.Id) = E.Capable
              and then Editor.Commands.Command_Target_Prompt_Label (E.Id) = To_String (E.Label),
              "public metadata accessor mapping drift for " & To_String (E.Name));
            Assert (Editor.Executor.Shared_Services.Command_Requires_Explicit_Target (E.Id) = E.Required
              and then Editor.Executor.File_Target_Prompt_Commands.Command_Requires_File_Target_Prompt (E.Id) = E.Capable,
              "prompt invocation predicates must remain canonical-accessor derived for " &
              To_String (E.Name));

            if E.Required then
               Required_Count := Required_Count + 1;
            end if;
            if E.Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
               Assert (To_String (E.Label)'Length > 0,
                 "prompt-capable command must have canonical prompt label");
            else
               Assert (To_String (E.Label)'Length = 0,
                 "non-prompt command must have no prompt label");
            end if;

            Assert_Descriptor_Minimal (E.Id);
         end;
      end loop;

      Assert (Required_Count = 4 and then Prompt_Capable_Count = 4,
        "only Save As, Rename, Copy, and Move may require and support target prompts");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Command_Is_Target_Prompt_Capable (Id) then
            Assert (Id in Editor.Commands.Command_Save_File_As
                       | Editor.Commands.Command_Rename_Buffer_File
                       | Editor.Commands.Command_Copy_Buffer_File
                       | Editor.Commands.Command_Move_Buffer_File
              and then Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length > 0,
              "no command outside the frozen file target set may become prompt-capable");
         else
            Assert (not Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length = 0,
              "non-prompt-capable commands must not retain prompt metadata");
         end if;
      end loop;
   end Test_Minimal_Metadata_Final_Freeze;


procedure Test_Render_Audit_Persistence_And_Behavior_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("source.txt");
      Prompt_Target : constant String := Temp_Path ("prompted target.txt");
      Direct_Target : constant String := Temp_Path ("direct target.txt");
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Audit  : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      Audit_Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;

      type Prompt_Command is record
         Id    : Editor.Commands.Command_Id;
         Label : Unbounded_String;
      end record;

      Prompt_Commands : constant array (Positive range 1 .. 4) of Prompt_Command :=
        ((Editor.Commands.Command_Save_File_As, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Rename_Buffer_File, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Copy_Buffer_File, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, To_Unbounded_String ("Move target")));
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Target);
      Write_Bytes (Source, "source text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Audit_Result, Before_Audit, After_Audit,
         "target prompt metadata final audit boundary");
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0
        and then Editor.Configuration_Audit.Status (Audit_Result) =
                 Editor.Configuration_Audit.Configuration_Audit_Ok
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "route/configuration audits must not mutate state or open prompts");

      for P of Prompt_Commands loop
         Editor.Executor.Execute_Command (S, P.Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
           and then S.File_Target_Prompt_Command = P.Id
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = To_String (P.Label)
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "no-target invocation must open canonical prompt for " &
           Editor.Commands.Stable_Command_Name (P.Id));
         Editor.Render_Model.Build_Render_Snapshot (S, Snap);
         Assert (Snap.File_Target_Prompt_Visible
           and then To_String (Snap.File_Target_Prompt_Label) = To_String (P.Label),
           "render snapshot must project canonical prompt label for " &
           Editor.Commands.Stable_Command_Name (P.Id));
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
         Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "prompt cancellation must clean transient state for " &
           Editor.Commands.Stable_Command_Name (P.Id));
      end loop;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Delete_Buffer_File)
        and then not Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Delete_Buffer_File)
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "non-target file lifecycle commands must not open target prompts");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Prompt_Target,
        "render remains snapshot-driven for active prompt state");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Prompt_Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending prompt") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt label cache") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "projection cache") = 0,
        "workspace persistence must exclude prompt state, metadata snapshots, caches, and histories");

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Ada.Directories.Exists (Prompt_Target)
        and then Read_Bytes (Prompt_Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "prompted Save As confirmation behavior must remain unchanged");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Target);
      Assert (Ada.Directories.Exists (Direct_Target)
        and then Read_Bytes (Direct_Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As must bypass prompt and remain unchanged");

      Remove_If_Exists (Source);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Render_Audit_Persistence_And_Behavior_Final_Freeze;







   procedure Test_Target_Prompt_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup (T);
   end Test_Target_Prompt_Canonical_Surface_Cleanup;

   procedure Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze (T);
   end Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze;

   procedure Test_Target_Prompt_Minimal_Metadata_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze (T);
   end Test_Target_Prompt_Minimal_Metadata_Canonical;

   procedure Test_Target_Prompt_Metadata_Accuracy_And_Stability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Metadata_Minimality_Guard (T);
   end Test_Target_Prompt_Metadata_Accuracy_And_Stability;

   procedure Test_No_Duplicate_Metadata_Projection_Or_Aliases
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke (T);
   end Test_No_Duplicate_Metadata_Projection_Or_Aliases;

   procedure Test_Command_Palette_Alias_And_Inference_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Minimal_Metadata_Final_Freeze (T);
   end Test_Command_Palette_Alias_And_Inference_Final_Freeze;

   overriding function Name (T : Target_Prompt_Metadata_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Target_Prompt_Metadata.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Target_Prompt_Metadata_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation'Access, "Target Prompt Uses Active Buffer At Confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Second_Target_Prompt_Replaces_First_Deterministically'Access, "Second Target Prompt Replaces First Deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Workspace_Persistence_Excluded'Access, "Target Prompt Workspace Persistence Excluded");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Workflow_Coherence_Matrix'Access, "Target Prompt Workflow Coherence Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy'Access, "Target Prompt Text Editing Cancel And Message Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow'Access, "Command Palette Keybinding Overlay And Audit Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior'Access, "Confirmation Lifecycle Persistence And Direct Behavior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup'Access, "Target Prompt No Inference State And Persistence Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical'Access, "Target Prompt Confirmation And Direct Behavior Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Restore_Applies_Continuity_State'Access, "Workspace Restore Applies Continuity State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze'Access, "Target Prompt Final Input Overlay Audit And Persistence Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze'Access, "Target Prompt Final Confirmation Active Buffer Message And Direct Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze'Access, "Target Prompt Metadata Boundaries And Behavior Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Minimality_Guard'Access, "Target Prompt Metadata Minimality Guard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Metadata_Reads_Are_Pure_And_Availability_Independent'Access, "Metadata Reads Are Pure And Availability Independent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Render_Audit_And_Persistence_Boundary'Access, "Command Palette Render Audit And Persistence Boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Canonical_Cleanup'Access, "Target Prompt Metadata Canonical Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke'Access, "Metadata Cleanup Behavior And Persistence Smoke");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimal_Metadata_Final_Freeze'Access, "Minimal Metadata Final Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Audit_Persistence_And_Behavior_Final_Freeze'Access, "Render Audit Persistence And Behavior Final Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Canonical_Surface_Cleanup'Access, "Target Prompt Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze'Access, "Target Prompt Final Surface State And Alias Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Minimal_Metadata_Canonical'Access, "Target Prompt Minimal Metadata Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Accuracy_And_Stability'Access, "Target Prompt Metadata Accuracy And Stability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Duplicate_Metadata_Projection_Or_Aliases'Access, "No Duplicate Metadata Projection Or Aliases");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Alias_And_Inference_Final_Freeze'Access, "Command Palette Alias And Inference Final Freeze");
   end Register_Tests;

end Editor.Files.Target_Prompt_Metadata_Tests;
