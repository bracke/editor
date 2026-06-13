with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Go_To_Line;
with Editor.State;
with Editor.Executor;
with Editor.Commands;
with Editor.Navigation;
with Editor.Navigation_History;
with Editor.Messages;
with Editor.Render_Model;
with Editor.Input_Bridge;
with Editor.Workspace_Persistence;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Bookmarks;
with Editor.Buffer_Switcher;

use type Editor.Go_To_Line.Go_To_Line_Validation_Status;
use type Editor.Commands.Command_Availability_Status;
use type Editor.Commands.Command_Id;
use type Editor.Commands.Command_Category;
use type Editor.Commands.Command_Visibility;
use type Editor.Project_Search.Project_Search_Status;

package body Editor.Go_To_Line.Tests is

   overriding function Name
     (T : Go_To_Line_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Go_To_Line");
   end Name;

   function Active_Message_Text
     (S : Editor.State.State_Type) return String;


   procedure Test_Command_Metadata_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      D      : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Line);
      Found  : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Avail  : Editor.Commands.Command_Availability;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Goto_Line) = "navigation.goto-line.show",
         "go-to-line show command must have the stable Phase 351 persisted name");
      Resolved := Editor.Commands.Command_Id_From_Stable_Name
        ("navigation.goto-line.show", Found);
      Assert
        (Resolved = Editor.Commands.Command_Goto_Line and then Found,
         "stable go-to-line command name must resolve back to the command id");
      Assert
        (D.Category = Editor.Commands.Navigation_Category
         and then D.Visibility = Editor.Commands.Palette_Command
         and then D.Bindable,
         "go-to-line descriptor must be a bindable visible Navigation command");
      Assert
        (Editor.Commands.Descriptor_Is_Complete
           (Editor.Commands.Command_Goto_Line),
         "go-to-line descriptor metadata must be complete");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Goto_Line_Toggle) =
         "navigation.goto-line.toggle",
         "go-to-line toggle must have a stable prompt-command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Goto_Line_Prefill_Current) =
         "navigation.goto-line.prefill-current",
         "go-to-line prefill-current must have a stable prompt-command name");
      Resolved := Editor.Commands.Command_Id_From_Stable_Name
        ("navigation.goto-line.prefill-current", Found);
      Assert
        (Resolved = Editor.Commands.Command_Goto_Line_Prefill_Current and then Found,
         "stable prefill-current command name must resolve back to the command id");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Line_Prefill_Current).Category
           = Editor.Commands.Navigation_Category
         and then Editor.Commands.Descriptor
           (Editor.Commands.Command_Goto_Line_Prefill_Current).Visibility
           = Editor.Commands.Palette_Command
         and then Editor.Commands.Descriptor
           (Editor.Commands.Command_Goto_Line_Prefill_Current).Bindable,
         "prefill-current descriptor must be a bindable visible Navigation command");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Goto_Line_Query_Set) =
         "navigation.goto-line.query.set",
         "go-to-line query set must have a stable prompt-command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Goto_Line_Query_Clear) =
         "navigation.goto-line.query.clear",
         "go-to-line query clear must have a stable prompt-command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Accept_Goto_Line) =
         "navigation.goto-line.accept",
         "go-to-line accept must have a stable context-command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Close_Goto_Line) =
         "navigation.goto-line.hide",
         "go-to-line hide must have a stable context-command name");

      Editor.State.Init (S);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);
      Assert
        (Avail.Status = Editor.Commands.Command_Unavailable
         and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
         "prefill-current availability must require an active buffer without mutating state");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);
      Assert
        ((not Editor.Go_To_Line.Is_Open (S.Go_To_Line))
         and then Active_Message_Text (S) = "No active buffer.",
         "prefill-current without an active buffer must report a deterministic no-op and not open the prompt");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "9");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Line);
      Assert
        (Avail.Status = Editor.Commands.Command_Available,
         "go-to-line show availability must not require an active buffer");
      Assert
        (Editor.Go_To_Line.Is_Open (S.Go_To_Line)
         and then Editor.Go_To_Line.Text (S.Go_To_Line) = "9",
         "go-to-line availability must not mutate prompt state");

      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);
      Assert
        (Avail.Status = Editor.Commands.Command_Unavailable
         and then Editor.Commands.Unavailable_Reason (Avail) = "No current caret location",
         "prefill-current availability must reject an active buffer without a current caret location");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);
      Assert
        (Active_Message_Text (S) = "No current caret location",
         "prefill-current without a caret must report a deterministic no-op");
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "go-to-line command execution must open the prompt for active buffers");
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "   ");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Goto_Line);
      Assert
        (Avail.Status = Editor.Commands.Command_Available,
         "go-to-line accept availability must let the Executor handler report empty prompt failures");
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Goto_Line);
      Assert
        (Avail.Status = Editor.Commands.Command_Available,
         "go-to-line accept availability must allow non-empty prompt input");
   end Test_Command_Metadata_And_Availability;

   procedure Test_Open_Close_And_Printable_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Go_To_Line.Go_To_Line_State;
   begin
      Editor.Go_To_Line.Open (State);
      Assert (Editor.Go_To_Line.Is_Open (State), "go-to-line input must open");

      Editor.Go_To_Line.Insert_Text (State, "12:3x");
      Assert (Editor.Go_To_Line.Text (State) = "12:3x",
              "go-to-line input must accept printable text so invalid typed queries can be reported on accept");

      Editor.Go_To_Line.Close (State);
      Assert (not Editor.Go_To_Line.Is_Open (State), "go-to-line input must close");
   end Test_Open_Close_And_Printable_Input;

   procedure Test_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Go_To_Line.Go_To_Line_State;
      Result : Editor.Go_To_Line.Go_To_Line_Validation_Result;
   begin
      Editor.Go_To_Line.Open (State);

      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Empty,
              "empty go-to-line input must be deterministic");

      Editor.Go_To_Line.Set_Text (State, "0");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "line zero must be invalid");

      Editor.Go_To_Line.Set_Text (State, "-1");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "negative line number must be invalid");

      Editor.Go_To_Line.Set_Text (State, "abc");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "non-numeric line number must be invalid");

      Editor.Go_To_Line.Set_Text (State, "4");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Out_Of_Range,
              "line beyond buffer end must be out of range");

      Editor.Go_To_Line.Set_Text (State, " 3 ");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Valid
              and then Result.Line = 3
              and then not Result.Has_Column,
              "valid one-based line number must be accepted with surrounding whitespace");

      Editor.Go_To_Line.Set_Text (State, "2:7");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Valid
              and then Result.Line = 2
              and then Result.Has_Column
              and then Result.Column = 7,
              "line:column input must parse one-based line and column numbers");

      Editor.Go_To_Line.Set_Text (State, "2,7");
      Result := Editor.Go_To_Line.Validate (State, 3);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Valid
              and then Result.Line = 2
              and then Result.Has_Column
              and then Result.Column = 7,
              "line,column input must parse one-based line and column numbers");

      Editor.Go_To_Line.Set_Text (State, "42:abc");
      Result := Editor.Go_To_Line.Validate (State, 100);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "malformed column input must be invalid");

      Editor.Go_To_Line.Set_Text (State, "42:");
      Result := Editor.Go_To_Line.Validate (State, 100);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "missing column after separator must be invalid");

      Editor.Go_To_Line.Set_Text (State, ":7");
      Result := Editor.Go_To_Line.Validate (State, 100);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Invalid,
              "missing line before separator must be invalid");

      Editor.Go_To_Line.Set_Text (State, "");
      Result := Editor.Go_To_Line.Validate (State, 100);
      Assert (Result.Status = Editor.Go_To_Line.Go_To_Line_Empty,
              "empty target must remain a distinct validation result");
   end Test_Validation;

   function Active_Message_Text
     (S : Editor.State.State_Type) return String
   is
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Active_Message_Text;

   procedure Assert_Caret
     (S              : Editor.State.State_Type;
      Expected_Row   : Natural;
      Expected_Column : Natural;
      Context        : String)
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Editor.Navigation.Line_Column_For_Index
        (S, Natural (S.Carets.First_Element.Pos), Row, Col);
      Assert (Row = Expected_Row and then Col = Expected_Column, Context);
   end Assert_Caret;

   procedure Test_Accept_Moves_Caret_And_Records_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3:2");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Assert_Caret (S, 2, 1,
                    "go-to-line accept must move caret to the requested one-based line:column");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "successful go-to-line must record the previous active location");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "successful explicit go-to-line must leave no forward entry");
      Assert (Active_Message_Text (S) = "Went to line 3:2",
              "successful go-to-line message must identify the target");
      Assert ((not Editor.Go_To_Line.Is_Open (S.Go_To_Line))
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = ""
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "successful accept must hide the prompt and clear transient query/error state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert_Caret (S, 0, 0,
                    "navigation back after go-to-line must restore the previous same-buffer line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert_Caret (S, 2, 1,
                    "navigation forward after go-to-line must restore the goto target");
   end Test_Accept_Moves_Caret_And_Records_History;

   procedure Test_Invalid_And_Same_Target_Do_Not_Record_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "500");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "out-of-range go-to-line must not record navigation history");
      Assert_Caret (S, 0, 0, "failed go-to-line must not move the caret");
      Assert (Active_Message_Text (S) = "Line 500 is outside the active buffer",
              "out-of-range go-to-line must report the requested line");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "1");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "same-location go-to-line must not record navigation history");
      Assert (Active_Message_Text (S) = "Already at line 1",
              "same-location go-to-line must report a deterministic no-op");
   end Test_Invalid_And_Same_Target_Do_Not_Record_History;


   procedure Test_Goto_Line_Clears_Forward_Stack_After_Back
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert_Caret (S, 2, 0, "setup must place caret at line 3");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert_Caret (S, 1, 0, "navigation back must restore line 2");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "back must create a forward history entry before branch navigation");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "1");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert_Caret (S, 0, 0, "new go-to-line after back must move to line 1");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "successful new go-to-line navigation must clear the forward stack");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 2,
              "successful branch go-to-line must record the execution-time current line");
   end Test_Goto_Line_Clears_Forward_Stack_After_Back;


   procedure Test_Prompt_Query_Commands_And_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "show must make the go-to-line prompt visible without an active buffer");

      Editor.Executor.Execute_Goto_Line_Set_Query (S, "42:7");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "42:7",
              "query.set must replace the prompt query through Executor");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Query_Clear);
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "",
              "query.clear must clear the prompt query through Executor");

      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "9");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Toggle);
      Assert ((not Editor.Go_To_Line.Is_Open (S.Go_To_Line))
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = "",
              "toggle-hide must hide and clear transient go-to-line query state");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Toggle);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "toggle-show must reopen the transient go-to-line prompt");

      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "77");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Quick_Open);
      Assert ((not Editor.Go_To_Line.Is_Open (S.Go_To_Line))
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = ""
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "replacing the go-to-line overlay must use go-to-line hide policy and clear query/error state");
   end Test_Prompt_Query_Commands_And_Lifecycle;

   procedure Test_Prefill_Current_Location_And_Error_Clearing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Natural := 0;
      Snap   : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "bad");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "setup must leave a stale prompt error after failed accept");

      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert_Caret (S, 1, 0, "setup must move the caret to line 2");
      Before := Editor.Navigation_History.Back_Count (S.Navigation_History);

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "999");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);

      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line)
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = "2"
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "prefill-current must show the prompt, replace query with current line, and clear errors");
      Assert_Caret (S, 1, 0,
                    "prefill-current must not move the caret");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "prefill-current must not record navigation history");
      Assert (Active_Message_Text (S) = "Go To Line target: 2",
              "prefill-current must report target preparation, not navigation success");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Goto_Line_Visible
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "2"
              and then Ada.Strings.Unbounded.To_String
                (Snap.Goto_Line_Error_Message) = "",
              "render snapshot must expose prefilled query and cleared error from stored prompt state");

      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Editor.Executor.Execute_Goto_Line_Set_Query (S, "3");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "3"
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "query.set must clear stale go-to-line errors");

      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Query_Clear);
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = ""
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "query.clear must clear stale go-to-line errors");

      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Assert
        (Editor.Executor.Command_Availability
           (S, Editor.Commands.Command_Goto_Line_Query_Clear).Status
         = Editor.Commands.Command_Available,
         "query.clear must remain available for an empty query when it can clear a stale error");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Query_Clear);
      Assert ((not Editor.Go_To_Line.Has_Error (S.Go_To_Line))
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = "",
              "query.clear must clear an empty-query stale error through the command path");

      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "stale error");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line)
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = ""
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "ordinary show must preserve existing query policy and clear errors");
   end Test_Prefill_Current_Location_And_Error_Clearing;


   procedure Test_Prefill_Preserves_Forward_History_And_Routes_Through_Input_Bridge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert_Caret (S, 0, 0, "setup must navigate back to line 1");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "setup must leave a forward history entry");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "prefill-current after back must preserve the forward stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert_Caret (S, 2, 0,
                    "forward must still navigate after prefill-current");

      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Goto_Line_Prefill_Current);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Goto_Line_Visible
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "3",
              "runtime binding for prefill-current must route through Input_Bridge to Executor");
   end Test_Prefill_Preserves_Forward_History_And_Routes_Through_Input_Bridge;

   procedure Test_Prompt_Failure_State_And_Render_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Accept_Goto_Line);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "empty accept must keep the go-to-line prompt visible");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "",
              "empty accept must preserve the empty prompt query");
      Assert (Editor.Go_To_Line.Error_Text (S.Go_To_Line) =
                "No go-to-line target",
              "empty accept must expose deterministic prompt error state");
      Assert (Active_Message_Text (S) = "No go-to-line target",
              "empty accept must emit the goto failure message");

      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "abc");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "invalid accept must keep the prompt visible");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "abc",
              "invalid accept must preserve the failing query");
      Assert (Editor.Go_To_Line.Error_Text (S.Go_To_Line) =
                "Invalid go-to-line target",
              "invalid accept must expose prompt error state");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Goto_Line_Visible,
              "render snapshot must include go-to-line prompt visibility");
      Assert (Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "abc",
              "render snapshot must include go-to-line query text");
      Assert
        (Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Error_Message) =
           "Invalid go-to-line target",
         "render snapshot must include go-to-line prompt error text");
   end Test_Prompt_Failure_State_And_Render_Snapshot;


   procedure Test_Failed_Accept_Preserves_Forward_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert_Caret (S, 0, 0, "setup back must restore the original line");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "setup back must leave one forward location");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "abc");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line)
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = "abc",
              "failed prompt accept must keep visible query state for correction");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "failed prompt accept after back must not clear the forward stack");
      Assert_Caret (S, 0, 0,
                    "failed prompt accept after back must not move the caret");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert_Caret (S, 2, 0,
                    "forward must still navigate after failed go-to-line accept");
   end Test_Failed_Accept_Preserves_Forward_History;


   procedure Test_Input_Bridge_Routes_Goto_Line_Prompt_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Goto_Line);
      declare
         Query : constant String := "3";
      begin
         for Ch of Query loop
         Cmd.Kind := Editor.Commands.Insert_Text_Input;
         Cmd.Ch := Ch;
         Cmd.Text := To_Unbounded_String (String'(1 => Ch));
         Editor.Input_Bridge.Handle (Cmd);
         end loop;
      end;
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Goto_Line_Visible
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "3",
              "printable input while go-to-line owns overlay must edit only the prompt query");
      Assert (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) = 0,
              "typing into the go-to-line prompt must not move or edit the active buffer");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.LF;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.LF));
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert ((not Snap.Goto_Line_Visible)
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "",
              "Enter routed through Input_Bridge must accept via the Executor and clear the prompt");
      Assert (Snap.Caret_Count > 0 and then Natural (Snap.Caret_Pos (1)) > 0,
              "Enter routed through Input_Bridge must perform the go-to-line caret movement");

      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Goto_Line);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := '9';
      Cmd.Text := To_Unbounded_String (String'(1 => '9'));
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Kind := Editor.Commands.Close_Goto_Line;
      Editor.Input_Bridge.Handle (Cmd);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert ((not Snap.Goto_Line_Visible)
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "",
              "Escape/close routing must hide and clear go-to-line state without history mutation");
   end Test_Input_Bridge_Routes_Goto_Line_Prompt_Input;


   procedure Test_Prefill_Does_Not_Mutate_Other_Overlay_Or_Surface_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Added : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "quick-query");
      Editor.Project_Search.Set_Query (S.Project_Search, "search-query");
      Editor.Project_Search.Set_Status
        (S.Project_Search, Editor.Project_Search.Project_Search_Ok);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "/tmp/a.adb", "a.adb", 1, 0, False, Added);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text
        (S.Buffer_Switcher, "switch-query");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);

      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "1",
              "prefill-current must use the active caret line even when other surfaces have state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "quick-query",
              "prefill-current must not mutate Quick Open query state");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "search-query"
              and then Editor.Project_Search.Status (S.Project_Search)
                = Editor.Project_Search.Project_Search_Ok,
              "prefill-current must not mutate Project Search query or status");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = 1,
              "prefill-current must not add, remove, or select bookmark state");
      Assert (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher)
              = "switch-query",
              "prefill-current must not mutate Open Buffer Switcher filter state");
   end Test_Prefill_Does_Not_Mutate_Other_Overlay_Or_Surface_State;


   procedure Test_Dirty_Buffer_Safety
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.State.Set_Dirty (S, True);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);
      Editor.Executor.Execute_Goto_Line_Set_Query (S, "2");
      Assert (Editor.State.Is_Dirty (S),
              "showing and editing the go-to-line prompt must not clean or save a dirty buffer");

      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.State.Is_Dirty (S),
              "successful go-to-line navigation must preserve dirty-buffer state");
      Assert_Caret (S, 1, 0,
                    "successful go-to-line in a dirty buffer must still move the caret");

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "500");
      Editor.Executor.Execute_Accept_Goto_Line (S);
      Assert (Editor.State.Is_Dirty (S),
              "failed go-to-line navigation must preserve dirty-buffer state");
      Assert_Caret (S, 1, 0,
                    "failed go-to-line in a dirty buffer must not move the caret");
   end Test_Dirty_Buffer_Safety;


   procedure Test_Project_Lifecycle_And_Persistence_Exclude_Goto_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2:7");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "prior failure");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "42:7");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "Invalid go-to-line target");
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := Ada.Strings.Unbounded.To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert (Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "goto") = 0
              and then Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary), "42:7") = 0
              and then Ada.Strings.Fixed.Index
                (Ada.Strings.Unbounded.To_String (Summary),
                 "Invalid go-to-line target") = 0,
              "workspace snapshot/debug summary must not persist prompt query, error, or target state");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert ((not Editor.Go_To_Line.Is_Open (S.Go_To_Line))
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = ""
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line),
              "project lifecycle reset must hide go-to-line and clear query/error state");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "project lifecycle reset must retain navigation-history lifecycle semantics");
   end Test_Project_Lifecycle_And_Persistence_Exclude_Goto_Line;


   procedure Test_Render_Snapshot_Is_Read_Only_For_Goto_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Natural := 0;
      Snap   : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Before := Editor.Navigation_History.Back_Count (S.Navigation_History);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Goto_Line_Visible
              and then Ada.Strings.Unbounded.To_String (Snap.Goto_Line_Query) = "2",
              "render snapshot must reflect go-to-line prompt state");
      Assert_Caret (S, 0, 0,
                    "building a render snapshot must not execute go-to-line movement");
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line)
              and then Editor.Go_To_Line.Text (S.Go_To_Line) = "2",
              "building a render snapshot must not mutate prompt state");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before,
              "building a render snapshot must not mutate navigation history");
   end Test_Render_Snapshot_Is_Read_Only_For_Goto_Line;


   overriding procedure Register_Tests
     (T : in out Go_To_Line_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Command_Metadata_And_Availability'Access,
         "command metadata and availability are deterministic");
      Register_Routine
        (T, Test_Open_Close_And_Printable_Input'Access,
         "open, close, and printable prompt input");
      Register_Routine
        (T, Test_Validation'Access,
         "line-number validation");
      Register_Routine
        (T, Test_Prompt_Query_Commands_And_Lifecycle'Access,
         "prompt query commands and lifecycle");
      Register_Routine
        (T, Test_Prefill_Current_Location_And_Error_Clearing'Access,
         "prefill-current uses active caret line and clears prompt errors");
      Register_Routine
        (T, Test_Prefill_Preserves_Forward_History_And_Routes_Through_Input_Bridge'Access,
         "prefill-current preserves forward history and routes through input bridge");
      Register_Routine
        (T, Test_Prompt_Failure_State_And_Render_Snapshot'Access,
         "prompt failures preserve state and render snapshot fields");
      Register_Routine
        (T, Test_Accept_Moves_Caret_And_Records_History'Access,
         "accept moves caret and records navigation history");
      Register_Routine
        (T, Test_Invalid_And_Same_Target_Do_Not_Record_History'Access,
         "invalid and same-target go-to-line do not record history");
      Register_Routine
        (T, Test_Goto_Line_Clears_Forward_Stack_After_Back'Access,
         "go-to-line clears forward stack after prior back navigation");
      Register_Routine
        (T, Test_Failed_Accept_Preserves_Forward_History'Access,
         "failed accept preserves forward history after back");
      Register_Routine
        (T, Test_Input_Bridge_Routes_Goto_Line_Prompt_Input'Access,
         "input bridge routes go-to-line prompt input through Executor paths");
      Register_Routine
        (T, Test_Prefill_Does_Not_Mutate_Other_Overlay_Or_Surface_State'Access,
         "prefill-current does not mutate other overlay or feature-surface state");
      Register_Routine
        (T, Test_Dirty_Buffer_Safety'Access,
         "go-to-line prompt and navigation preserve dirty buffer state");
      Register_Routine
        (T, Test_Project_Lifecycle_And_Persistence_Exclude_Goto_Line'Access,
         "project lifecycle and workspace persistence exclude go-to-line state");
      Register_Routine
        (T, Test_Render_Snapshot_Is_Read_Only_For_Goto_Line'Access,
         "render snapshot is read-only for go-to-line prompt state");
   end Register_Tests;

end Editor.Go_To_Line.Tests;
