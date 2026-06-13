with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Core_Editing_Workflow;
with Editor.Cursors;
with Editor.Overlay_Focus;
with Editor.Selection;
with Editor.State;
with Text_Buffer;

package body Editor.Core_Editing_Workflow.Tests is

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
      S.File_Info.Path := To_Unbounded_String ("/tmp/example.adb");
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
      S.File_Info.Path := To_Unbounded_String ("/tmp/example.adb");
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

   procedure Test_Phase540_Text_Editing_Primitives_Are_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Core_Editing_Workflow.Assert_Text_Editing_Primitives_Coherent,
         "Phase 540 text editing primitives must have coherent descriptors, " &
         "classification, mutation boundaries, and stable command names");
   end Test_Phase540_Text_Editing_Primitives_Are_Coherent;

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
         "Phase 575: dirty close remains available and execution opens explicit review");
      Assert (R.Dirty_Close_Guard_Coherent,
              "Phase 575: audit recognizes Executor-owned dirty-close review guard");
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

   overriding procedure Register_Tests
     (T : in out Core_Editing_Workflow_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Initialized_State_Is_Coherent'Access,
         "Phase 532 initialized core editing workflow is coherent");
      Register_Routine
        (T, Test_File_And_Dirty_Labels_Are_Projection_Only'Access,
         "Phase 532 file and dirty labels are projection only");
      Register_Routine
        (T, Test_Availability_Reasons_For_Core_File_Commands'Access,
         "Phase 532 core file command availability reasons");
      Register_Routine
        (T, Test_Caret_And_Selection_Bounds_Audit'Access,
         "Phase 532 caret and selection bounds audit");
      Register_Routine
        (T, Test_Command_Classification_Covers_Core_Editing_Surface'Access,
         "Phase 532 command classification covers core editing surface");
      Register_Routine
        (T, Test_Phase540_Text_Editing_Primitives_Are_Coherent'Access,
         "Phase 540 text editing primitives are coherent");
      Register_Routine
        (T, Test_No_Active_Buffer_And_No_Selection_Reasons'Access,
         "Phase 532 no active buffer and no selection reasons");
      Register_Routine
        (T, Test_Prompt_Boundary_Audit_Rejects_Editing_Payload_Leak'Access,
         "Phase 532 prompt boundary rejects editing payload leaks");
      Register_Routine
        (T, Test_Buffer_Lifecycle_Availability_And_Dirty_Close_Guard'Access,
         "Phase 532 buffer lifecycle availability and dirty close guard");
      Register_Routine
        (T, Test_Input_Bridge_Boundary_Detects_Overlay_Conflict'Access,
         "Phase 532 input bridge boundary detects overlay conflicts");
   end Register_Tests;

end Editor.Core_Editing_Workflow.Tests;
