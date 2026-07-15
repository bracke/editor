with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.Core_Editing_Workflow;
with Editor.Cursors;
with Editor.Dirty_Lines;
with Editor.Executor;
with Editor.Executor.Selection_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Feature_Search_Results;
with Editor.Layout;
with Editor.Outline;
with Editor.Outline.Fixtures;
with Editor.Overlay_Focus;
with Editor.Selection;
with Editor.State;
with Editor.Test_Helper;
with Editor.View;
with Text_Buffer;

package body Editor.Core_Editing_Workflow.Tests is

   use Editor.Cursors;
   use type Editor.Dirty_Lines.Dirty_Line_Kind;

   overriding function Name
     (T : Core_Editing_Workflow_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Core_Editing_Workflow");
   end Name;

   procedure Test_Initialized_State_Is_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Core_Editing_Workflow.Core_Editing_Workflow_Result;
   begin
      Editor.State.Initialize (S);
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);

      Assert (R.Active_Buffer_State_Coherent, "initialized state has an active caret");
      Assert (R.File_State_Coherent, "initialized file state is coherent");
      Assert (R.Dirty_State_Coherent, "initialized dirty baseline is coherent");
      Assert (R.Caret_State_Coherent, "initialized caret is in bounds");
      Assert (R.Selection_State_Coherent, "initialized selection state is in bounds");
      Assert (R.Persistence_Boundary_Coherent, "initialized persistence boundary is coherent");
      Assert (R.Transient_Boundary_Coherent, "initialized transient boundary is coherent");
      Assert (R.Command_Availability_Coherent, "initialized availability reasons are coherent");
      Assert (R.Prompt_Boundary_Coherent, "initialized prompt boundary is coherent");
      Assert (R.Dirty_Close_Guard_Coherent, "initialized dirty close guard is coherent");
      Assert (R.Caret_Command_Coverage_Coherent, "caret command coverage is coherent");
      Assert (R.Selection_Command_Coverage_Coherent, "selection command coverage is coherent");
      Assert (R.Text_Mutation_Command_Coverage_Coherent, "text mutation command coverage is coherent");
      Assert (R.Input_Bridge_Boundary_Coherent, "input bridge boundary is coherent");
      Assert (R.Coherent, "core editing workflow audit is coherent");
   end Test_Initialized_State_Is_Coherent;

   procedure Test_File_And_Dirty_Labels_Are_Projection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Revision : Natural;
   begin
      Editor.State.Initialize (S);
      Before_Revision := S.Buffer_Revision;

      Assert (Editor.Core_Editing_Workflow.Buffer_Dirty_Label (S) = "Clean",
              "clean initialized buffer has clean label");
      Assert (Editor.Core_Editing_Workflow.Buffer_File_State_Label (S) = "Unbacked buffer",
              "initialized buffer is explicitly unbacked");
      Assert (not S.File_Info.Dirty, "dirty label does not dirty buffer");
      Assert (S.Buffer_Revision = Before_Revision, "labels do not mutate buffer revision");

      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/example.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("example.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      Before_Revision := S.Buffer_Revision;

      Assert (Editor.Core_Editing_Workflow.Buffer_Dirty_Label (S) = "Dirty - save failed",
              "dirty save-failure label is explicit");
      Assert (Editor.Core_Editing_Workflow.Buffer_File_State_Label (S) = "File-backed",
              "file-backed label follows retained path state");
      Assert (S.File_Info.Dirty, "dirty label did not clear dirty flag");
      Assert (S.Buffer_Revision = Before_Revision, "file label does not mutate buffer revision");
   end Test_File_And_Dirty_Labels_Are_Projection_Only;

   procedure Test_Availability_Reasons_For_Core_File_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);

      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Save_File) = "No file path for active buffer",
         "save reports missing file path for unbacked active buffer");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Save_File_As) = "",
         "save-as is available for an active unbacked buffer");

      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/example.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("example.adb");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Save_File) = "",
         "save is available when active buffer has a path");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Reload_Active_Buffer) = "",
         "reload is available for a clean file-backed buffer");

      S.File_Info.Dirty := True;
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Reload_Active_Buffer) = "Dirty buffer cannot be reloaded",
         "dirty reload exposes retained guard reason");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Revert_Active_Buffer) = "",
         "revert is available for dirty file-backed buffer");
   end Test_Availability_Reasons_For_Core_File_Commands;

   procedure Test_Caret_And_Selection_Bounds_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Core_Editing_Workflow.Core_Editing_Workflow_Result;
   begin
      Editor.State.Initialize (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.Selection.Apply_Active_Buffer_Selection (S, 1, 4);

      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (R.Caret_State_Coherent, "caret remains in bounds after selection");
      Assert (R.Selection_State_Coherent, "selection remains in bounds after selection");
      Assert (R.Coherent, "selected editing state remains coherent");

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos => Editor.Cursors.Cursor_Index (Text_Buffer.Length (S.Buffer) + 1),
            Anchor => 0,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (not R.Caret_State_Coherent, "audit detects caret beyond buffer bounds");
      Assert (not R.Coherent, "out-of-bounds caret makes workflow incoherent");
   end Test_Caret_And_Selection_Bounds_Audit;



   procedure Test_Command_Classification_Covers_Core_Editing_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Open_File),
         "open file is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Close_Active_Buffer),
         "close active buffer is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Next_Buffer),
         "buffer switching is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Save_File),
         "save is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Move_Left),
         "caret movement is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Selection_Delete),
         "selection delete is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Indent_Increase),
         "indent is part of the core editing workflow");
      Assert
        (Editor.Core_Editing_Workflow.Is_Buffer_Lifecycle_Command
           (Editor.Commands.Command_Open_File),
         "open file is classified as buffer lifecycle");
      Assert
        (Editor.Core_Editing_Workflow.Is_Buffer_Lifecycle_Command
           (Editor.Commands.Command_Close_Active_Buffer),
         "close active buffer is classified as buffer lifecycle");
      Assert
        (Editor.Core_Editing_Workflow.Is_Buffer_Lifecycle_Command
           (Editor.Commands.Command_Next_Buffer),
         "next buffer is classified as buffer lifecycle");
      Assert
        (not Editor.Core_Editing_Workflow.Is_Buffer_Lifecycle_Command
           (Editor.Commands.Command_Build_Run),
         "build.run is not classified as buffer lifecycle");
      Assert
        (not Editor.Core_Editing_Workflow.Is_Core_Editing_Command
           (Editor.Commands.Command_Build_Run),
         "build.run remains outside the editing workflow surface");

      Assert
        (Editor.Core_Editing_Workflow.Requires_File_Backed_Buffer
           (Editor.Commands.Command_Save_File),
         "save active requires a file-backed buffer");
      Assert
        (not Editor.Core_Editing_Workflow.Requires_File_Backed_Buffer
           (Editor.Commands.Command_Save_File_As),
         "save-as supplies an explicit target and does not require an existing path");
      Assert
        (Editor.Core_Editing_Workflow.Mutates_Or_Replaces_Buffer_Text
           (Editor.Commands.Command_Insert_Newline),
         "newline mutates active-buffer text");
      Assert
        (not Editor.Core_Editing_Workflow.Mutates_Or_Replaces_Buffer_Text
           (Editor.Commands.Command_Move_Left),
         "caret movement does not mutate active-buffer text");
      Assert
        (Editor.Core_Editing_Workflow.Is_Caret_Navigation_Command
           (Editor.Commands.Command_Goto_Line),
         "goto line is classified as caret navigation");
      Assert
        (not Editor.Core_Editing_Workflow.Is_Caret_Navigation_Command
           (Editor.Commands.Command_Build_Run),
         "build.run is not caret navigation");
      Assert
        (Editor.Core_Editing_Workflow.Is_Selection_Command
           (Editor.Commands.Command_Select_All),
         "select all is classified as a selection command");
      Assert
        (Editor.Core_Editing_Workflow.Is_Selection_Command
           (Editor.Commands.Command_Selection_Delete),
         "delete selection is classified as a selection command");
      Assert
        (Editor.Core_Editing_Workflow.Is_Text_Editing_Command
           (Editor.Commands.Command_Indent_Increase),
         "indent is classified as a text editing command");
      Assert
        (not Editor.Core_Editing_Workflow.Is_Text_Editing_Command
           (Editor.Commands.Command_Save_File),
         "save is file lifecycle, not direct text editing");
      Assert
        (not Editor.Core_Editing_Workflow.Is_Text_Editing_Command
           (Editor.Commands.Command_Copy_Buffer_File),
         "copy file is file lifecycle, not direct text editing");
   end Test_Command_Classification_Covers_Core_Editing_Surface;

   procedure Test_Text_Editing_Primitives_Are_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Core_Editing_Workflow.Assert_Text_Editing_Primitives_Coherent,
         "text editing primitives must have coherent descriptors, " &
         "classification, mutation boundaries, and stable command names");
   end Test_Text_Editing_Primitives_Are_Coherent;

   procedure Test_No_Active_Buffer_And_No_Selection_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Initialize (S);
      S.Carets.Clear;

      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Save_File) = "No active buffer.",
         "save reports no active buffer before file-path checks");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Move_Left) = "No active buffer.",
         "caret movement reports no active buffer");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Selection_Clear) = "No active buffer.",
         "selection clear reports no active buffer");

      Editor.State.Initialize (S);
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Copy) = "No selection",
         "copy reports no selection for active buffer without selection");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Selection_Delete) = "No selection",
         "delete-selection reports no selection for active buffer without selection");
   end Test_No_Active_Buffer_And_No_Selection_Reasons;

   procedure Test_Prompt_Boundary_Audit_Rejects_Editing_Payload_Leak
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Core_Editing_Workflow.Core_Editing_Workflow_Result;
   begin
      Editor.State.Initialize (S);
      S.File_Target_Prompt_Active := True;
      S.File_Target_Prompt_Command := Editor.Commands.Command_Save_File_As;
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (R.Prompt_Boundary_Coherent,
              "save-as target prompt is a coherent transient editing prompt");
      Assert (R.Coherent,
              "valid target prompt does not make editing workflow incoherent");

      S.File_Target_Prompt_Command := Editor.Commands.Command_Build_Run;
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (not R.Prompt_Boundary_Coherent,
              "build command cannot occupy file target prompt payload");
      Assert (not R.Coherent,
              "editing audit rejects non-editing prompt payload leak");
   end Test_Prompt_Boundary_Audit_Rejects_Editing_Payload_Leak;



   procedure Test_Buffer_Lifecycle_Availability_And_Dirty_Close_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Core_Editing_Workflow.Core_Editing_Workflow_Result;
   begin
      Editor.State.Initialize (S);

      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Open_File) = "",
         "open file does not require an active file-backed buffer");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_New_Buffer) = "",
         "new buffer is available without a file path");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Close_Active_Buffer) = "",
         "clean active buffer may close directly");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Next_Buffer) = "",
         "buffer switch does not require saving or discarding changes");

      S.File_Info.Dirty := True;
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Close_Active_Buffer) = "",
         "dirty close remains available and execution opens explicit review");
      Assert (R.Dirty_Close_Guard_Coherent,
              "audit recognizes Executor-owned dirty-close review guard");
      Assert (R.Coherent,
              "dirty but review-guarded active buffer remains workflow-coherent");

      S.Carets.Clear;
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Close_Active_Buffer) = "No active buffer.",
         "close reports no active buffer before dirty guard checks");
      Assert
        (Editor.Core_Editing_Workflow.Editing_Availability_Reason
           (S, Editor.Commands.Command_Next_Buffer) = "No active buffer.",
         "buffer switching reports no active buffer");
   end Test_Buffer_Lifecycle_Availability_And_Dirty_Close_Guard;


   procedure Test_Input_Bridge_Boundary_Detects_Overlay_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Core_Editing_Workflow.Core_Editing_Workflow_Result;
   begin
      Editor.State.Initialize (S);
      S.File_Target_Prompt_Active := True;
      S.File_Target_Prompt_Command := Editor.Commands.Command_Save_File_As;
      Editor.Overlay_Focus.Activate_With_Previous
        (S.Overlay_Focus,
         Editor.Overlay_Focus.File_Target_Prompt_Overlay,
         Editor.Overlay_Focus.Previous_Editor_Text);

      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (R.Input_Bridge_Boundary_Coherent,
              "file target prompt overlay owns target-path text input");
      Assert (R.Coherent,
              "matching target prompt overlay keeps editing workflow coherent");

      Editor.Overlay_Focus.Activate_With_Previous
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Command_Palette_Overlay,
         Editor.Overlay_Focus.Previous_Editor_Text);
      R := Editor.Core_Editing_Workflow.Audit_Core_Editing_Workflow (S);
      Assert (not R.Input_Bridge_Boundary_Coherent,
              "file target prompt cannot sit underneath command palette text input");
      Assert (not R.Coherent,
              "overlay/input conflict makes editing workflow incoherent");
   end Test_Input_Bridge_Boundary_Detects_Overlay_Conflict;

   procedure Test_Dirty_Lines_Insert_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "new buffer should start with zero dirty lines");

      Cmd := Editor.Test_Helper.Insert (0, 'X');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "insert into empty buffer should mark one dirty line");
      Assert (Editor.Dirty_Lines.Kind_For_Row (S.Dirty_Lines, 0) =
                Editor.Dirty_Lines.Modified_Line,
              "edit of baseline empty row should be modified");

      Cmd.Kind := Editor.Commands.Undo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "undo back to baseline should clear dirty-line rows");

      Cmd.Kind := Editor.Commands.Redo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "redo should recompute dirty-line rows");
   end Test_Dirty_Lines_Insert_And_Undo;

   procedure Test_Dirty_Lines_Save_Clears_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
      Path : constant String := Temp_Path ("save.txt");
   begin
      Remove_File_If_Exists (Path);
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save.txt");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "edit before save should mark dirty-line state");

      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "successful save should clear dirty-line state");
      Assert (S.File_Info.Dirty = False,
              "successful save should keep file-level dirty state clean");
      Remove_File_If_Exists (Path);
   end Test_Dirty_Lines_Save_Clears_Baseline;

   procedure Test_Dirty_Lines_Buffer_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Cmd      : Editor.Commands.Command;
      A_Id     : Editor.Buffers.Buffer_Id;
      B_Id     : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Cmd := Editor.Test_Helper.Insert (1, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "editing buffer A should mark A dirty lines");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "new buffer B should start without dirty lines");

      Cmd := Editor.Test_Helper.Insert (0, 'B');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "editing buffer B should mark B dirty lines");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "switching back to A should restore A dirty-line state");

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "switching back to B should restore B dirty-line state");
   end Test_Dirty_Lines_Buffer_Isolation;

   procedure Test_Dirty_Lines_Save_Without_Path_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "setup edit should mark one dirty row before failed save");

      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "save without path should preserve dirty-line state");
   end Test_Dirty_Lines_Save_Without_Path_Preserves_State;

   procedure Test_Dirty_Lines_Open_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "setup edit should mark one dirty row before failed open");

      Cmd.Kind := Editor.Commands.Open_File;
      Cmd.Path := To_Unbounded_String (Temp_Path ("missing_open.txt"));
      Remove_File_If_Exists (To_String (Cmd.Path));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "failed open should preserve active dirty-line state");
      Assert (Editor.State.Current_Text (S) = "base!",
              "failed open should preserve active buffer contents");
   end Test_Dirty_Lines_Open_Failure_Preserves_State;

   procedure Test_Dirty_Lines_Save_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      A_Path : constant String := Temp_Path ("save_a_only.txt");
   begin
      Remove_File_If_Exists (A_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "A");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (A_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_a_only.txt");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Cmd := Editor.Test_Helper.Insert (1, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Cmd := Editor.Test_Helper.Insert (0, 'B');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "saving active buffer A should clear A dirty-line state");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "saving buffer A must not clear buffer B dirty-line state");

      Remove_File_If_Exists (A_Path);
   end Test_Dirty_Lines_Save_Active_Buffer_Only;

   procedure Test_Executor_Set_Rectangular_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text_Length : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcd" & ASCII.LF & "xy" & ASCII.LF & "12345");
      Before_Text_Length := Text_Buffer.Length (S.Buffer);

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 2, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Selection_Commands.Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => (Row => 0, Column => 1),
         Cursor => (Row => 2, Column => 4));

      Assert (S.Rect_Select_Active,
              "set rectangle must activate rectangular selection");
      Assert (S.Rect_Anchor_Row = 0 and then S.Rect_Anchor_Col = 1,
              "set rectangle must preserve the anchor");
      Assert (S.Carets.Length = 3,
              "set rectangle must project one caret/span per row");
      Assert (Text_Buffer.Length (S.Buffer) = Before_Text_Length,
              "rectangular selection must not mutate text");
      Assert (not S.File_Info.Dirty,
              "rectangular selection must not mark file dirty");
   end Test_Executor_Set_Rectangular_Selection;

   procedure Test_Executor_Clear_Rectangular_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcd" & ASCII.LF & "efgh");

      Editor.Executor.Selection_Commands.Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => (Row => 0, Column => 1),
         Cursor => (Row => 1, Column => 3));

      Editor.Executor.Selection_Commands.Execute_Clear_Rectangular_Selection (S);

      Assert (not S.Rect_Select_Active,
              "clear rectangle must leave rectangular mode");
      Assert (S.Carets.Length = 1,
              "clear rectangle must collapse to one primary caret");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor =
         S.Carets (S.Carets.First_Index).Pos,
         "clear rectangle must collapse selection");
   end Test_Executor_Clear_Rectangular_Selection;


   procedure Test_Insert_Newline_Dirty_And_Cursor
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "ab");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 1,
            Anchor                => 1,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.LF;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.LF));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "a" & ASCII.LF & "b",
              "newline insertion must preserve surrounding text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 2,
              "caret must advance after newline insertion");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 2,
              "selection must be cleared after insertion");
      Assert (S.File_Info.Dirty, "successful insertion must dirty buffer");
   end Test_Insert_Newline_Dirty_And_Cursor;

   procedure Test_Insert_Replaces_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 5,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abXf",
              "typing over selection must replace selected text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "caret must land after replacement text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 3,
              "selection must clear after replacement");
      Assert (S.File_Info.Dirty, "selection replacement must dirty buffer");
   end Test_Insert_Replaces_Selection;

   procedure Test_Backspace_At_Buffer_Start_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abc",
              "backspace at start must not mutate buffer");
      Assert (not S.File_Info.Dirty,
              "backspace no-op must not dirty clean buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "backspace no-op must not bump buffer revision");
      Assert (S.Carets (S.Carets.First_Index).Pos = 0,
              "caret must remain valid after no-op backspace");
   end Test_Backspace_At_Buffer_Start_Is_No_Op;

   procedure Test_Paste_Replaces_Multiline_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 11,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String ("X" & ASCII.LF & "Y");

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "onX" & ASCII.LF & "Yee",
              "single-selection paste must replace the selected multiline range");
      Assert (S.Carets (S.Carets.First_Index).Pos = 5,
              "caret must land after pasted multiline replacement text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 5,
              "selection must clear after paste replacement");
      Assert (S.File_Info.Dirty,
              "pasting over a selection must dirty the buffer");
   end Test_Paste_Replaces_Multiline_Selection;

   procedure Test_Empty_Paste_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 5,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := Null_Unbounded_String;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abcdef",
              "empty paste must not mutate buffer content");
      Assert (S.Carets (S.Carets.First_Index).Pos = 5,
              "empty paste must preserve caret position");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 2,
              "empty paste must preserve the existing selection");
      Assert (not S.File_Info.Dirty,
              "empty paste must not dirty a clean buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "empty paste must not bump buffer revision");
   end Test_Empty_Paste_Is_No_Op;


   procedure Test_Paste_Normalizes_Line_Endings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String
        ("A" & ASCII.CR & ASCII.LF
         & "B" & ASCII.CR
         & "C" & ASCII.LF
         & "D");

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "A" & ASCII.LF
              & "B" & ASCII.LF
              & "C" & ASCII.LF
              & "D",
              "paste must normalize CRLF, lone CR, and LF to LF");
      Assert (S.Carets (S.Carets.First_Index).Pos = 7,
              "caret must land after normalized pasted text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 7,
              "selection must remain clear after normalized paste");
      Assert (S.File_Info.Dirty,
              "normalized paste with content must dirty the buffer");
   end Test_Paste_Normalizes_Line_Endings;

   procedure Test_Paste_Trailing_Newline_Over_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 4,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String ("X" & ASCII.LF & "Y" & ASCII.LF);

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abX" & ASCII.LF & "Y" & ASCII.LF & "ef",
              "paste with trailing newline must preserve the trailing empty line boundary");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "caret must land after pasted trailing newline");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 6,
              "selection must clear after trailing-newline replacement paste");
      Assert (S.File_Info.Dirty,
              "trailing-newline paste replacement must dirty the buffer");
   end Test_Paste_Trailing_Newline_Over_Selection;

   procedure Test_Empty_Paste_Preserves_Dirty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 1,
            Anchor                => 1,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := Null_Unbounded_String;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abc",
              "empty paste must preserve buffer content");
      Assert (S.Carets (S.Carets.First_Index).Pos = 1,
              "empty paste must preserve caret");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 1,
              "empty paste must preserve selection state");
      Assert (not S.File_Info.Dirty,
              "empty paste must not dirty the buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "empty paste must not bump revision");
   end Test_Empty_Paste_Preserves_Dirty_State;

   procedure Test_Edit_Invalidates_Feature_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Result : Editor.Outline.Outline_Refresh_Result;
      pragma Unreferenced (Result);
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha" & ASCII.LF & "beta");

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages,
         Editor.Feature_Messages.Info_Message,
         "targeted message",
         Has_Target => True,
         Buffer     => S.Registry_Token,
         Line       => 1,
         Column     => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "targeted diagnostic",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results,
         Query         => "alpha",
         Snapshot_Text => Buffer_Text (S),
         Source_Label  => "active",
         Target_Buffer => S.Registry_Token,
         Snapshot_Version => Editor.State.Current_Buffer_Revision (S));
      Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (S.Outline);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "targeted Messages rows for edited buffer must be removed");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "targeted Diagnostics rows for edited buffer must be removed");
      Assert (Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "Search Results must be generation-marked stale after edit");
      Assert (Editor.Outline.Filtered_Row_Count (S.Outline) = 0,
              "Outline rows must be cleared after buffer edit");
   end Test_Edit_Invalidates_Feature_Targets;


   procedure Test_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Cmd := Editor.Test_Helper.Insert (0, 'X');

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Text_Buffer.Length (S.Buffer) = 1, "Insert failed");
      Assert (Text_Buffer.Element (S.Buffer, 1) = 'X', "Wrong char");
   end Test_Insert;

   procedure Test_Backspace_Delete
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 2,
         Anchor => 2,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  -- caret after 'b'

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 2,
         "Backspace delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Backspace delete first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'c',
         "Backspace delete second char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 1,
         "Backspace delete caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "Backspace delete anchor failed");
   end Test_Backspace_Delete;

   procedure Test_Forward_Delete
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 1,
         Anchor => 1,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret after 'a', before 'b'

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 2,
         "Forward delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Forward delete first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'c',
         "Forward delete second char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 1,
         "Forward delete caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "Forward delete anchor failed");
   end Test_Forward_Delete;

   procedure Test_Backspace_Delete_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 4,
         Anchor => 4,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret at start of second line

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 6,
         "Backspace newline delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Backspace newline first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'b',
         "Backspace newline second char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Backspace newline third char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 4) = 'd',
         "Backspace newline fourth char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 3,
         "Backspace newline caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 3,
         "Backspace newline anchor failed");
   end Test_Backspace_Delete_Newline;

   procedure Test_Forward_Delete_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret before newline

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 6,
         "Forward delete newline length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Forward delete newline first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'b',
         "Forward delete newline second char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Forward delete newline third char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 4) = 'd',
         "Forward delete newline fourth char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 3,
         "Forward delete newline caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 3,
         "Forward delete newline anchor failed");
   end Test_Forward_Delete_Newline;

   procedure Test_Preferred_Column_Up_Down
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abcdef\nxy\nabcdef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('f')));
      Text_Buffer.Insert (S.Buffer, 6,  ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 7, Character'Val (Character'Pos ('x')));
      Text_Buffer.Insert (S.Buffer, 8, Character'Val (Character'Pos ('y')));
      Text_Buffer.Insert (S.Buffer, 9,  ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 10, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 11, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 12, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 13, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 14, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 15, Character'Val (Character'Pos ('f')));

      Editor.State.Rebuild_After_Buffer_Change (S);

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 5,
         Anchor => 5,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  column 5 on first line
      S.Preferred_Column := 5;

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 9,
         "Move_Down should clamp to end of short middle line");

      Cmd.Kind := Editor.Commands.Move_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 15,
         "Second Move_Down should restore preferred column on longer line");
   end Test_Preferred_Column_Up_Down;

   procedure Test_Home_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abc\ndef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));
      Editor.State.Rebuild_After_Buffer_Change (S);

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 6,
         Anchor => 6,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      S.Preferred_Column := 2;

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Home;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "Home must move to start of current line");

      Cmd.Kind := Editor.Commands.Move_End;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "End must move to end of current line");
   end Test_Home_End;


   procedure Test_Word_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha  beta,++gamma");

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "word-right from word start must land at next word start");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 11,
         "word-right from word start must stop at the following boundary");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 11, Anchor => 11, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Left;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "word-left from word end must stop at word start");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 14, Anchor => 14, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Left;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 11,
         "word-left must treat symbol runs separately from words");
   end Test_Word_Navigation;

   procedure Test_Shift_Word_Right_Selects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta");

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0,
         "shift-word-right must keep the original anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 6,
         "shift-word-right must move caret to next word start");
   end Test_Shift_Word_Right_Selects;

   procedure Test_Document_Start_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Document_End;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "document-end must move to buffer end");

      Cmd.Kind := Editor.Commands.Move_Document_Start;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 0,
         "document-start must move to buffer start");
   end Test_Document_Start_End;

   procedure Test_Page_Down_Uses_Visible_Row_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "0" & ASCII.LF &
         "1" & ASCII.LF &
         "2" & ASCII.LF &
         "3" & ASCII.LF &
         "4" & ASCII.LF &
         "5");

      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Editor.Layout.Cell_H * 3);

      Cmd.Kind := Editor.Commands.Move_Page_Down;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "page-down must move by visible row count minus one");
   end Test_Page_Down_Uses_Visible_Row_Count;

   procedure Test_Select_Word_And_Whitespace_At_Point
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Select_Word_At_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_Y := 0;

      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 1 * Editor.Layout.Cell_W;
      Cmd.Click_X := X;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0
         and then S.Carets (S.Carets.First_Index).Pos = 5,
         "double-click inside a word must select the complete word run");

      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 5 * Editor.Layout.Cell_W;
      Cmd.Click_X := X;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor =
         S.Carets (S.Carets.First_Index).Pos,
         "double-click whitespace must place a caret without creating a selection");
   end Test_Select_Word_And_Whitespace_At_Point;

   procedure Test_Select_Line_At_Point
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "defg");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Select_Line_At_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S));
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 4,
         "triple-click line selection must anchor at logical line start");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 8,
         "triple-click last-line selection must end at the line length");
   end Test_Select_Line_At_Point;

   procedure Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural := Editor.Layout.Text_Origin_X (Layout, 1);
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc");
      Editor.View.Reset_Scroll;

      if X > 0 then
         X := X - 1;
      end if;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := X;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Pos = 0,
         "mouse hit before text origin must clamp to column zero");
   end Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero;

   procedure Test_Drag_Creates_Normal_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1)
        + 1 * Editor.Layout.Cell_W;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1)
        + 4 * Editor.Layout.Cell_W;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "drag selection must preserve the mouse-down anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "drag selection must update the caret to the drag point");
      Assert
        (not S.Rect_Select_Active,
         "normal drag must not enable rectangle selection");
   end Test_Drag_Creates_Normal_Selection;

   procedure Test_Gutter_Click_Moves_To_Line_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural := Editor.Layout.Text_Origin_X (Layout, 2);
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.View.Reset_Scroll;

      if X > 0 then
         X := X - 1;
      end if;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "gutter click on second row must move caret to that line start");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 4,
         "gutter click without shift must collapse selection at line start");
   end Test_Gutter_Click_Moves_To_Line_Start;

   procedure Test_Shift_Page_Down_Extends_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "0" & ASCII.LF &
         "1" & ASCII.LF &
         "2" & ASCII.LF &
         "3");

      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Editor.Layout.Cell_H * 2);

      Cmd.Kind := Editor.Commands.Select_Page_Down;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0,
         "select-page-down must keep the original anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 2,
         "select-page-down must move by visible rows minus one");
   end Test_Shift_Page_Down_Extends_Selection;

   procedure Test_Multi_Caret_Shift_Word_Right_Selects_All
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta gamma");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 6, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "shift-word-right must preserve both carets");
      Assert
        (S.Carets (0).Anchor = 0 and then S.Carets (0).Pos = 6,
         "first caret must extend to the next word start");
      Assert
        (S.Carets (1).Anchor = 6 and then S.Carets (1).Pos = 11,
         "second caret must extend to the next word start");
   end Test_Multi_Caret_Shift_Word_Right_Selects_All;


   procedure Test_Multi_Caret_Move_Right_Applies_To_All
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "move-right must preserve non-overlapping multi-carets");
      Assert
        (S.Carets (0).Pos = 1 and then S.Carets (0).Anchor = 1,
         "first caret must move right and collapse its anchor");
      Assert
        (S.Carets (1).Pos = 4 and then S.Carets (1).Anchor = 4,
         "second caret must move right and collapse its anchor");
   end Test_Multi_Caret_Move_Right_Applies_To_All;

   procedure Test_Select_Right_Extends_All_Carets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "select-right must preserve non-overlapping multi-carets");
      Assert
        (S.Carets (0).Anchor = 0 and then S.Carets (0).Pos = 1,
         "first caret must preserve anchor and extend right");
      Assert
        (S.Carets (1).Anchor = 3 and then S.Carets (1).Pos = 4,
         "second caret must preserve anchor and extend right");
   end Test_Select_Right_Extends_All_Carets;

   procedure Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Before : constant String := "abc" & ASCII.LF & "def";
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, Before);
      Editor.State.Reset_Dirty_Line_Baseline (S);

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Move_Page_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Editor.State.Current_Text (S) = Before,
         "navigation commands must not mutate buffer text");
      Assert
        (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
         "navigation commands must not create dirty-line state");
      Assert
        (not S.File_Info.Dirty,
         "navigation commands must not mark the file dirty");
   end Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines;

   procedure Test_Delete_Semantics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abc\ndef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      --  Backspace joins lines from start of second line
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 4,
         Anchor => 4,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Cmd.Kind := Editor.Commands.Delete_Char;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Backspace must remove newline before caret");

      --  Reset
      Init_Executor_Test_State (S);
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      --  Delete joins lines from end of first line
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Delete must remove newline at caret");
   end Test_Delete_Semantics;


   overriding procedure Register_Tests
     (T : in out Core_Editing_Workflow_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Initialized_State_Is_Coherent'Access,
         "initialized core editing workflow is coherent");
      Register_Routine
        (T, Test_File_And_Dirty_Labels_Are_Projection_Only'Access,
         "file and dirty labels are projection only");
      Register_Routine
        (T, Test_Availability_Reasons_For_Core_File_Commands'Access,
         "core file command availability reasons");
      Register_Routine
        (T, Test_Caret_And_Selection_Bounds_Audit'Access,
         "caret and selection bounds audit");
      Register_Routine
        (T, Test_Command_Classification_Covers_Core_Editing_Surface'Access,
         "command classification covers core editing surface");
      Register_Routine
        (T, Test_Text_Editing_Primitives_Are_Coherent'Access,
         "text editing primitives are coherent");
      Register_Routine
        (T, Test_No_Active_Buffer_And_No_Selection_Reasons'Access,
         "no active buffer and no selection reasons");
      Register_Routine
        (T, Test_Prompt_Boundary_Audit_Rejects_Editing_Payload_Leak'Access,
         "prompt boundary rejects editing payload leaks");
      Register_Routine
        (T, Test_Buffer_Lifecycle_Availability_And_Dirty_Close_Guard'Access,
         "buffer lifecycle availability and dirty close guard");
      Register_Routine
        (T, Test_Input_Bridge_Boundary_Detects_Overlay_Conflict'Access,
         "input bridge boundary detects overlay conflicts");
      Register_Routine
        (T, Test_Dirty_Lines_Insert_And_Undo'Access,
         "dirty lines insert undo redo");
      Register_Routine
        (T, Test_Dirty_Lines_Save_Clears_Baseline'Access,
         "dirty lines save clears baseline");
      Register_Routine
        (T, Test_Dirty_Lines_Buffer_Isolation'Access,
         "dirty lines buffer isolation");
      Register_Routine
        (T, Test_Dirty_Lines_Save_Without_Path_Preserves_State'Access,
         "failed save preserves dirty-line state");
      Register_Routine
        (T, Test_Dirty_Lines_Open_Failure_Preserves_State'Access,
         "failed open preserves dirty-line state");
      Register_Routine
        (T, Test_Dirty_Lines_Save_Active_Buffer_Only'Access,
         "save clears active buffer dirty lines only");
      Register_Routine
        (T, Test_Executor_Set_Rectangular_Selection'Access,
         "executor set rectangular selection");
      Register_Routine
        (T, Test_Executor_Clear_Rectangular_Selection'Access,
         "executor clear rectangular selection");
      Register_Routine
        (T, Test_Insert_Newline_Dirty_And_Cursor'Access,
         "insert newline dirty cursor");
      Register_Routine
        (T, Test_Insert_Replaces_Selection'Access,
         "insert replaces selection");
      Register_Routine
        (T, Test_Backspace_At_Buffer_Start_Is_No_Op'Access,
         "backspace start no-op");
      Register_Routine
        (T, Test_Paste_Replaces_Multiline_Selection'Access,
         "paste replaces multiline selection");
      Register_Routine
        (T, Test_Empty_Paste_Is_No_Op'Access,
         "empty paste is no-op");
      Register_Routine
        (T, Test_Paste_Normalizes_Line_Endings'Access,
         "paste normalizes line endings");
      Register_Routine
        (T, Test_Paste_Trailing_Newline_Over_Selection'Access,
         "paste trailing newline over selection");
      Register_Routine
        (T, Test_Empty_Paste_Preserves_Dirty_State'Access,
         "empty paste preserves dirty state");
      Register_Routine
        (T, Test_Edit_Invalidates_Feature_Targets'Access,
         "edit invalidates feature targets");
      Register_Routine
        (T, Test_Insert'Access,
         "Insert");
      Register_Routine
        (T, Test_Backspace_Delete'Access,
         "Backspace");
      Register_Routine
        (T, Test_Forward_Delete'Access,
         "Forward Delete");
      Register_Routine
        (T, Test_Home_End'Access,
         "Home / End");
      Register_Routine
        (T, Test_Preferred_Column_Up_Down'Access,
         "Preferred_Column Up/Down");
      Register_Routine
        (T, Test_Forward_Delete_Newline'Access,
         "Forward Delete Newline");
      Register_Routine
        (T, Test_Backspace_Delete_Newline'Access,
         "Backspace Delete Newline");
      Register_Routine
        (T, Test_Delete_Semantics'Access,
         "Delete Semantics");
      Register_Routine
        (T, Test_Word_Navigation'Access,
         "Word Navigation");
      Register_Routine
        (T, Test_Shift_Word_Right_Selects'Access,
         "Shift Word Selection");
      Register_Routine
        (T, Test_Document_Start_End'Access,
         "Document Start/End");
      Register_Routine
        (T, Test_Page_Down_Uses_Visible_Row_Count'Access,
         "Page Down Rows");
      Register_Routine
        (T, Test_Select_Word_And_Whitespace_At_Point'Access,
         "Double Click Word");
      Register_Routine
        (T, Test_Select_Line_At_Point'Access,
         "Triple Click Line");
      Register_Routine
        (T, Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero'Access,
         "Mouse Hit Clamp");
      Register_Routine
        (T, Test_Drag_Creates_Normal_Selection'Access,
         "Drag Selection");
      Register_Routine
        (T, Test_Gutter_Click_Moves_To_Line_Start'Access,
         "Gutter Click");
      Register_Routine
        (T, Test_Shift_Page_Down_Extends_Selection'Access,
         "Select Page Down");
      Register_Routine
        (T, Test_Multi_Caret_Shift_Word_Right_Selects_All'Access,
         "Multi-Caret Shift Word");
      Register_Routine
        (T, Test_Multi_Caret_Move_Right_Applies_To_All'Access,
         "multi-caret move right");
      Register_Routine
        (T, Test_Select_Right_Extends_All_Carets'Access,
         "multi-caret select right");
      Register_Routine
        (T, Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines'Access,
         "navigation non-mutating");
   end Register_Tests;

end Editor.Core_Editing_Workflow.Tests;
