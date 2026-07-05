with AUnit.Assertions; use AUnit.Assertions;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Files.Test_Helpers; use Editor.Files.Test_Helpers;
with Editor.Messages;
with Editor.Render_Model;
with Editor.State;

package body Editor.Files.Target_Prompt_Tests is

   use type Editor.Messages.Message_Severity;
   use type Ada.Directories.File_Kind;
   procedure Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Target : constant String := Temp_Path ("prompt_save_as.txt");
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "prompt text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Append_Character ('/');
      Editor.Command_Palette.Append_Character ('q');
      Editor.Command_Palette.Append_Character ('u');
      Editor.Command_Palette.Append_Character ('e');
      Editor.Command_Palette.Append_Character ('r');
      Editor.Command_Palette.Append_Character ('y');

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Save As without explicit target should open the transient target prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target",
        "Save As prompt should expose the deterministic label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "prompt input must start empty and not infer a target");
      Assert (Buffer_Text (S) = "prompt text" and then S.File_Info.Dirty,
        "prompt opening must not mutate buffer text or dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt opening must not emit an underlying command outcome message");
      Assert (not Ada.Directories.Exists (Target),
        "prompt opening must not perform filesystem work");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "x");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "prompt editing must update prompt input only");
      Assert (Buffer_Text (S) = "prompt text",
        "prompt editing must not insert text into the active buffer");

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "prompt confirmation should clear transient prompt state");
      Assert (Read_Bytes (Target) = "prompt text",
        "prompt confirmation should dispatch the exact target to canonical Save As");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "prompt confirmation must emit exactly the canonical Save As outcome message");
      Remove_If_Exists (Target);
   end Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation;

   procedure Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Text : constant String := "cancel text";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "discarded-target.txt");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "cancellation should clear pending file target prompt state");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "cancellation should discard typed target text");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "cancellation must not mutate active buffer text or dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "cancellation must not emit underlying file operation feedback");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "lifecycle-target.txt");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "lifecycle reset must clear transient prompt state and input");
      Assert (Buffer_Text (S) = Before_Text,
        "lifecycle prompt cleanup must not edit buffer text");
   end Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup;

   procedure Test_Target_Requiring_Command_Prompt_Eligibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("source.txt");

      procedure Assert_Opens
        (Id    : Editor.Commands.Command_Id;
         Label : String)
      is
      begin
         Editor.Executor.Execute_Command (S, Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "eligible target command should open prompt");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = Label,
           "eligible target command should expose canonical prompt label");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "eligible target command prompt should not infer target text");
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      end Assert_Opens;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Assert (not S.File_Info.Dirty and then S.File_Info.Has_Path,
        "fixture should be a clean associated active buffer");
      Editor.Messages.Clear (S.Messages);

      Assert_Opens (Editor.Commands.Command_Save_File_As, "Save As target");
      Assert_Opens (Editor.Commands.Command_Rename_Buffer_File, "Rename target");
      Assert_Opens (Editor.Commands.Command_Copy_Buffer_File, "Copy target");
      Assert_Opens (Editor.Commands.Command_Move_Buffer_File, "Move target");
      Assert (Read_Bytes (Source) = "source",
        "opening target prompts must not perform source filesystem mutation");

      S.File_Info.Dirty := True;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open rename prompt under preferred policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open copy prompt under preferred policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open move prompt under preferred policy");

      Remove_If_Exists (Source);
   end Test_Target_Requiring_Command_Prompt_Eligibility;

   procedure Test_Render_Projects_File_Target_Prompt_Without_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Before_Text     : constant String := "render text";
      Before_Messages : Natural := 0;
      Snap            : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "render-target.txt");
      Before_Messages := Editor.Messages.Count (S.Messages);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible,
        "render snapshot should project visible file target prompt");
      Assert (To_String (Snap.File_Target_Prompt_Label) = "Save As target",
        "render snapshot should project prompt label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "render-target.txt",
        "render snapshot must not mutate prompt input");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "render snapshot must not mutate buffer state");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
        "render snapshot must not emit command feedback");
   end Test_Render_Projects_File_Target_Prompt_Without_Mutation;

   overriding function Name
     (T : Target_Prompt_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Target_Prompt.Tests");
   end Name;

   overriding procedure Register_Tests
     (T : in out Target_Prompt_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation'Access,
         "Target Prompt Opening Input And Save As Confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup'Access,
         "Target Prompt Cancellation And Lifecycle Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Requiring_Command_Prompt_Eligibility'Access,
         "Target Requiring Command Prompt Eligibility");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Projects_File_Target_Prompt_Without_Mutation'Access,
         "Render Projects File Target Prompt Without Mutation");
   end Register_Tests;

end Editor.Files.Target_Prompt_Tests;
