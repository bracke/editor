with Editor.Executor.Command_Palette_Projection;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Problems_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Project_Search_Surface_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Search_Commands;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Problems;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.State;
with Text_Buffer;

package body Editor.Executor.UI_Tests is

   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Diagnostics.Diagnostic_Index;

   overriding function Name
     (T : UI_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.UI_Tests");
   end Name;



   procedure Test_Focus_Problems_Shows_And_Focuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, False);

      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);

      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "focus Problems should show the bottom panel");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Problems_Content,
         "focus Problems should select Problems bottom content");
      Assert
        (Editor.Panel_Focus.Target (S.Panel_Focus) =
           Editor.Panel_Focus.Bottom_Panel_Focus
         and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "focus Problems should move keyboard ownership to Problems");
      Assert
        (Editor.Problems.Selected_Row_Index (S.Problems_View) = 1,
         "focus Problems should select the first diagnostic row");
   end Test_Focus_Problems_Shows_And_Focuses;

   procedure Test_Problems_Move_Is_Selection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Pos : Editor.Cursors.Cursor_Index := 0;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Pos := S.Carets (S.Carets.First_Index).Pos;
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning, Message => "second");
      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);

      Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Move_Down (S);

      Assert
        (Editor.Problems.Selected_Row_Index (S.Problems_View) = 2,
         "focused Down should move Problems selection only");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = Before_Pos,
         "focused Down must not move the editor caret");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "focused movement should keep Problems focus");
   end Test_Problems_Move_Is_Selection_Only;

   procedure Test_Problems_Open_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning, Message => "second");
      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);
      Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Move_Down (S);

      Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Open_Selected (S);

      Assert
        (S.Active_Diagnostic.Has_Active
         and then S.Active_Diagnostic.Index = 2,
         "Enter should open the selected diagnostic");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "selected diagnostic open should move caret to diagnostic target");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Enter should return focus to editor text after opening a problem");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Enter should keep Problems panel visible");
   end Test_Problems_Open_Returns_To_Editor_Text;

   procedure Test_Problems_Open_No_Selection_Reports
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);
      Editor.Problems.Set_Selected_Row_Index (S.Problems_View, 0);

      Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Open_Selected (S);

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No diagnostic selected",
         "opening with no selected problem should report a deterministic failure");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "opening with no selected problem should preserve Problems focus");
   end Test_Problems_Open_No_Selection_Reports;

   procedure Test_Problems_Escape_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);

      Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Focus_Editor (S);

      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Escape should return focus to editor text");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Escape should not hide the Problems panel");
   end Test_Problems_Escape_Returns_To_Editor_Text;


   procedure Test_Open_Overlays_Activate_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Reset;

      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Assert
        (Editor.Command_Palette.Is_Open,
         "command palette command should open palette surface");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Command_Palette_Overlay,
         "command palette command should activate command-palette overlay");

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Assert
        (not Editor.Command_Palette.Is_Open,
         "quick open should close the command palette surface");
      Assert
        (Editor.Quick_Open.Is_Open (S.Quick_Open),
         "quick open command should open quick-open surface");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Quick_Open_Overlay,
         "quick open command should activate quick-open overlay");

      Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar (S);
      Assert
        (not Editor.Quick_Open.Is_Open (S.Quick_Open),
         "project search bar should close quick open");
      Assert
        (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
         "project search command should open project-search bar");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Project_Search_Bar_Overlay,
         "project search command should activate project-search overlay");
   end Test_Open_Overlays_Activate_Through_Executor;

   procedure Test_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Assert
        (S.Active_Find_Prompt,
         "find command should open the active Find prompt");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay),
         "find command should activate the find overlay");

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);

      Assert
        (S.Active_Find_Prompt,
         "opening quick open should leave active Find prompt visible");
      Assert
        (Editor.Quick_Open.Is_Open (S.Quick_Open),
         "opening quick open should open quick-open surface");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay),
         "quick open should own overlay focus after replacing find input focus");
      Assert
        (not Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay),
         "visible active Find prompt must be inactive while quick open owns input");
   end Test_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open;

   procedure Test_Deactivate_Active_Find_Prompt_Leaves_Surface_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);

      Editor.Executor.Deactivate_Active_Overlay_Only
        (S, Editor.Overlay_Focus.Dismiss_Outside_Click);

      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
         "focus-only deactivation should clear active overlay");
      Assert
        (S.Active_Find_Prompt,
         "focus-only deactivation should keep active Find prompt visible");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "deactivation should restore the previous editor-text focus");
   end Test_Deactivate_Active_Find_Prompt_Leaves_Surface_Open;

   procedure Test_Dismiss_Restores_Valid_File_Tree_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("focus_restore_root");
      S    : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_File_Tree);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);

      Editor.Executor.Quick_Open_Commands.Execute_Close_Quick_Open (S);

      Assert
        (Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus),
         "dismiss should restore valid file-tree focus");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Dismiss_Restores_Valid_File_Tree_Focus;

   function Latest_Message_Text (S : Editor.State.State_Type) return String;

   function Active_Caret_Line (S : Editor.State.State_Type) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         return 0;
      end if;
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      return Row + 1;
   end Active_Caret_Line;


   function Latest_Message_Text (S : Editor.State.State_Type) return String
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      else
         return "";
      end if;
   end Latest_Message_Text;

   procedure Test_Unavailable_Command_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Before := Text_Buffer.Length (S.Buffer);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "save without active buffer must be unavailable");
      Assert (Text_Buffer.Length (S.Buffer) = Before,
              "unavailable command must not mutate the buffer");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command emits one primary message");
      Assert (Latest_Message_Text (S) = "No active buffer.",
              "unavailable feedback must use the canonical user-facing reason");
   end Test_Unavailable_Command_Feedback_Is_Deterministic;

   procedure Test_Build_Command_Feedback_Avoids_Internal_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "public build test seam route remains unavailable");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable build route emits one primary message");
      Assert (Latest_Message_Text (S) = "Build: structured command context required",
              "build route feedback must remain deterministic");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "PATH") = 0,
              "feedback must not expose PATH details");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "--") = 0,
              "feedback must not expose shell-style argv details");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "Command_Build") = 0,
              "feedback must not expose internal enum names");
   end Test_Build_Command_Feedback_Avoids_Internal_Details;

   procedure Test_Target_Activation_Failure_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "old.adb", True, S.Registry_Token + 10, 1, 1);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result :=
        Editor.Executor.Message_Commands.Execute_Message_Row_Activation (S, 2);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale targeted message activation remains non-mutating");
      Assert (Latest_Message_Text (S) = Editor.Commands.Reason_Target_Missing,
              "stale target activation reports concise deterministic feedback");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "generation") = 0,
              "target feedback must not expose projection generation details");
   end Test_Target_Activation_Failure_Feedback;

   procedure Test_Cancel_No_Cancellable_Is_Quiet_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Close;
      Before := Editor.Messages.Count (S.Messages);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Cancel);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "cancel with nothing cancellable is an intentional no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "quiet cancel no-op must not create feedback");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "cancel no-op must not activate overlays");
   end Test_Cancel_No_Cancellable_Is_Quiet_No_Op;

   procedure Test_Cancel_Command_Palette_Is_Cancelled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Close;
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Command_Palette_Overlay);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Cancel);

      Assert (Result.Status = Editor.Executor.Command_Cancelled,
              "Escape/cancel against an active palette is cancellation");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "cancel must dismiss the active overlay");
      Assert (not Editor.Command_Palette.Is_Open,
              "cancel must close the command palette surface");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "palette cancellation remains quiet");
   end Test_Cancel_Command_Palette_Is_Cancelled;

   procedure Test_Feature_Panel_Already_State_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial show feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "showing an already visible feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-visible show reports through availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial focus feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "focusing an already focused feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-focused focus reports through availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial hide feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "hiding an already hidden feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-hidden hide reports through availability");
   end Test_Feature_Panel_Already_State_No_Ops;

   procedure Test_Empty_Clear_Commands_Are_Quiet_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Before := Editor.Messages.Count (S.Messages);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Messages);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Messages is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Messages clear remains quiet");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Clear);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Diagnostics is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Diagnostics clear remains quiet");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Search_Results_Feature);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Search Results is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Search Results clear remains quiet");
   end Test_Empty_Clear_Commands_Are_Quiet_No_Ops;

   procedure Test_Navigation_Boundaries_Are_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Dirty : Boolean;
   begin
      Init_Executor_Test_State (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_New_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "new buffer setup succeeds");
      Before_Dirty := S.File_Info.Dirty;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Left);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "moving left at the start of the buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "boundary navigation must not dirty the buffer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Previous_Buffer);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "previous buffer with only one buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "buffer navigation no-op must not dirty the buffer");
   end Test_Navigation_Boundaries_Are_No_Ops;



   function Availability_Reason
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return String
   is
      A : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Id);
   begin
      return Editor.Commands.Unavailable_Reason (A);
   end Availability_Reason;

   procedure Assert_Unavailable_Reason
     (S        : Editor.State.State_Type;
      Id       : Editor.Commands.Command_Id;
      Expected : String;
      Label    : String)
   is
      A : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Id);
   begin
      Assert (not Editor.Commands.Is_Available (A), Label & " must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = Expected,
              Label & " reason expected '" & Expected & "' but got '" &
              Editor.Commands.Unavailable_Reason (A) & "'");
   end Assert_Unavailable_Reason;

   procedure Test_Common_Availability_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Root : constant String := Temp_Path ("availability_root");
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Save_File, "No active buffer.",
         "buffer command without active buffer");
      Assert_Unavailable_Reason
        (S, Editor.Commands.No_Command, "No command selected.",
         "empty command invocation");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Close_Project, "No project open.",
         "project command without project");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Diagnostics_Open_Selected,
         "No diagnostics.", "diagnostic activation without diagnostics");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action,
         "No diagnostics.", "diagnostic action without diagnostics");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Clear_Selected_Message,
         "No messages", "message action without messages");

      Editor.State.Load_Text (S, "alpha beta");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Project_Search_From_Selection,
         "No project open.", "selection command without project");

      Build_Fixture (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_File_Tree);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 0);
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_File_Tree_Open_Selected,
         "No file selected.", "file tree activation without selection");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Common_Availability_Reasons;

   procedure Test_Availability_Feedback_Matches_Preflight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Reason : Unbounded_String;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Reason := To_Unbounded_String
        (Availability_Reason (S, Editor.Commands.Command_Save_File));
      Before := Text_Buffer.Length (S.Buffer);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "unavailable save command must be classified unavailable");
      Assert (Text_Buffer.Length (S.Buffer) = Before,
              "unavailable command must not mutate buffer text");
      Assert (Latest_Message_Text (S) = To_String (Reason),
              "execution feedback must match availability preflight reason");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command emits one primary message");
   end Test_Availability_Feedback_Matches_Preflight;

   procedure Test_Availability_Checks_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text     : Unbounded_String;
      Before_Messages : Natural;
      Before_Feature_Rows : Natural;
      Before_File_Tree_Rows : Natural;
      A : Editor.Commands.Command_Availability;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "one" & Character'Val (10) & "two");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Feature_Rows := Editor.Feature_Panel.Row_Count (S.Feature_Panel);
      Before_File_Tree_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Commands.Is_Available (A),
              "refresh outline should be available with an active buffer");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "search active buffer without query remains unavailable");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (not Editor.Commands.Is_Available (A),
              "diagnostics open selected remains unavailable without diagnostics");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);
      Assert (not Editor.Commands.Is_Available (A),
              "diagnostics selected action remains unavailable without diagnostics");

      Assert (Editor.State.Current_Text (S) = To_String (Before_Text),
              "availability must not mutate active buffer text");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "availability must not post Messages");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = Before_Feature_Rows,
              "availability must not mutate Feature Panel rows");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_File_Tree_Rows,
              "availability must not mutate File Tree rows");
   end Test_Availability_Checks_Are_Side_Effect_Free;

   procedure Test_Palette_Disabled_Reason_Matches_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
      Expected : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save file");
      Expected := To_Unbounded_String
        (Availability_Reason (S, Editor.Commands.Command_Save_File));

      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Found := True;
            Assert (not Candidate.Available,
                    "palette must show Save File disabled without active buffer");
            Assert (To_String (Candidate.Reason) = To_String (Expected),
                    "palette disabled reason must match Executor preflight");
         end if;
      end loop;

      Assert (Found, "Save File command must be present in palette candidates");
   end Test_Palette_Disabled_Reason_Matches_Executor;


   overriding procedure Register_Tests (T : in out UI_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Focus_Problems_Shows_And_Focuses'Access,
         "focus problems shows and focuses");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Move_Is_Selection_Only'Access,
         "problems move is selection only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Open_Returns_To_Editor_Text'Access,
         "problems open returns to editor text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Open_No_Selection_Reports'Access,
         "problems open no selection reports");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Escape_Returns_To_Editor_Text'Access,
         "problems escape returns to editor text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Overlays_Activate_Through_Executor'Access,
         "open overlays activate through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open'Access,
         "active find prompt remains visible but inactive under quick open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Deactivate_Active_Find_Prompt_Leaves_Surface_Open'Access,
         "deactivate active find prompt leaves surface open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dismiss_Restores_Valid_File_Tree_Focus'Access,
         "dismiss restores valid file tree focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Command_Feedback_Is_Deterministic'Access,
         "unavailable command feedback is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Feedback_Avoids_Internal_Details'Access,
         "build command feedback avoids internal details");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Activation_Failure_Feedback'Access,
         "stale target activation feedback is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cancel_No_Cancellable_Is_Quiet_No_Op'Access,
         "cancel with nothing cancellable is a quiet no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cancel_Command_Palette_Is_Cancelled'Access,
         "command palette cancellation is classified");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Panel_Already_State_No_Ops'Access,
         "already-state feature panel commands are no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Clear_Commands_Are_Quiet_No_Ops'Access,
         "empty clear commands are quiet no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Common_Availability_Reasons'Access,
         "common availability reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Feedback_Matches_Preflight'Access,
         "availability feedback matches preflight");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Checks_Are_Side_Effect_Free'Access,
         "availability checks are side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Disabled_Reason_Matches_Executor'Access,
         "palette disabled reason matches executor");
   end Register_Tests;

end Editor.Executor.UI_Tests;
