with AUnit.Assertions; use AUnit.Assertions;
with Editor.State;
with Editor.Executor;
with Editor.Executor.History;
with Editor.Test_Helper;
with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Text_Buffer;
with Editor.Cursors; use Editor.Cursors;
with Editor.Commands;
use type Editor.Commands.Command_Id;
with Editor.History;
with Editor.Messages;
with Editor.Buffers;
with Editor.Render_Model;
with Editor.Navigation_History;
with Editor.Keybindings;
with Editor.Instance;

use type Editor.Commands.Command_Availability_Status;
use type Editor.Commands.Command_Visibility;
use type Editor.Keybindings.Binding_Result;

package body Editor.History.Tests is

   -------------------------------------------------------------------------
   --  Helpers
   -------------------------------------------------------------------------

   function Text (S : Editor.State.State_Type) return String is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Text;

   procedure Set_Caret
     (S : in out Editor.State.State_Type;
      Pos : Cursor_Index;
      Anchor : Cursor_Index := Cursor_Index'Last)
   is
      A : constant Cursor_Index := (if Anchor = Cursor_Index'Last then Pos else Anchor);
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(
          Pos                   => Pos,
          Anchor                => A,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Rect_Select_Active := False;
      Editor.State.Normalize_Carets (S);
   end Set_Caret;

   function Paste (S : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String (S);
      return Cmd;
   end Paste;

   function Forward_Delete return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      return Cmd;
   end Forward_Delete;

   procedure Assert_Text
     (S        : Editor.State.State_Type;
      Expected : String;
      Message  : String) is
   begin
      Assert (Text (S) = Expected, Message & " expected '" & Expected & "' got '" & Text (S) & "'");
   end Assert_Text;

   procedure Set_Buffer_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Text_Buffer.Clear (S.Buffer);
      for Ch of Text loop
         Text_Buffer.Insert (S.Buffer, Text_Buffer.Length (S.Buffer), Ch);
      end loop;
      Editor.State.Rebuild_Line_Index (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
   end Set_Buffer_Text;

   function Latest_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Latest_Message_Text;

   procedure Assert_Stacks
     (Undo_Count : Natural;
      Redo_Count : Natural;
      Message    : String) is
   begin
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Count,
              Message & " undo count");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              Message & " redo count");
   end Assert_Stacks;

   -------------------------------------------------------------------------
   --  Phase 211: direct undo/redo edit units
   -------------------------------------------------------------------------

   procedure Test_Phase211_Single_Insert_Undo_Redo_Unit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Assert_Text (S, "ab", "insert precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "a", "single undo must remove only the most recent typed insertion");
      Assert (S.Carets (S.Carets.First_Index).Pos = 1, "undo restores insertion caret");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ab", "redo must restore the single typed insertion");
      Assert (S.Carets (S.Carets.First_Index).Pos = 2, "redo restores post-insert caret");
   end Test_Phase211_Single_Insert_Undo_Redo_Unit;

   procedure Test_Phase211_Newline_Undo_Redo_Unit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, ASCII.LF));
      Assert_Text (S, "ab" & ASCII.LF, "newline precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "ab", "undo newline restores original line structure");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ab" & ASCII.LF, "redo newline reapplies line break");
   end Test_Phase211_Newline_Undo_Redo_Unit;

   procedure Test_Phase211_Backspace_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      Set_Caret (S, 2);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Delete (0));
      Assert_Text (S, "ac", "backspace precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "abc", "undo backspace restores deleted text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 2, "undo backspace restores caret");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ac", "redo backspace reapplies deletion");
      Assert (S.Carets (S.Carets.First_Index).Pos = 1, "redo backspace restores post-delete caret");
   end Test_Phase211_Backspace_Undo_Redo;

   procedure Test_Phase211_Forward_Delete_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      Set_Caret (S, 1);

      Editor.Executor.Execute_No_Log (S, Forward_Delete);
      Assert_Text (S, "ac", "delete precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "abc", "undo delete restores deleted text");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ac", "redo delete reapplies deletion");
   end Test_Phase211_Forward_Delete_Undo_Redo;

   procedure Test_Phase211_Selected_Replacement_Undo_Redo_Selection_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcd"));
      Set_Caret (S, 3, 1);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Assert_Text (S, "aXd", "replacement precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "abcd", "undo selected replacement restores original text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3
              and then S.Carets (S.Carets.First_Index).Anchor = 1,
              "undo selected replacement restores prior selection");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "aXd", "redo selected replacement reapplies edit");
      Assert (S.Carets (S.Carets.First_Index).Pos = 2
              and then S.Carets (S.Carets.First_Index).Anchor = 2,
              "redo selected replacement restores collapsed post-edit caret");
   end Test_Phase211_Selected_Replacement_Undo_Redo_Selection_Context;

   procedure Test_Phase211_Multiline_Paste_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Set_Caret (S, 1);

      Editor.Executor.Execute_No_Log (S, Paste ("X" & ASCII.LF & ASCII.LF & "Y"));
      Assert_Text (S, "aX" & ASCII.LF & ASCII.LF & "Yb", "multiline paste precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "ab", "undo multiline paste restores original content");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "aX" & ASCII.LF & ASCII.LF & "Yb", "redo multiline paste restores pasted content including empty line");
   end Test_Phase211_Multiline_Paste_Undo_Redo;

   procedure Test_Phase211_Delete_Across_Line_Boundary_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("a" & ASCII.LF & "b"));
      Set_Caret (S, 2, 1);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Delete (0));
      Assert_Text (S, "ab", "line-boundary delete precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "a" & ASCII.LF & "b", "undo line-boundary delete restores newline");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ab", "redo line-boundary delete removes newline again");
   end Test_Phase211_Delete_Across_Line_Boundary_Undo_Redo;

   procedure Test_Phase211_Failed_Edit_Creates_No_Undo_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Delete (0));
      Assert (Editor.History.Undo_Stack.Is_Empty, "failed backspace at buffer start must not create undo entry");
      Assert_Text (S, "", "failed backspace mutates nothing");
   end Test_Phase211_Failed_Edit_Creates_No_Undo_Entry;

   procedure Test_Phase211_Cursor_Movement_Creates_No_Undo_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));

      Assert (Editor.History.Undo_Stack.Is_Empty, "cursor and selection movement must not create undo entries");
      Assert_Text (S, "ab", "cursor and selection movement mutates no text");
   end Test_Phase211_Cursor_Movement_Creates_No_Undo_Entry;

   procedure Test_Phase211_Redo_Cleared_By_New_Edit_Not_Movement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (not Editor.History.Redo_Stack.Is_Empty, "undo creates redo entry");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);
      Assert (not Editor.History.Redo_Stack.Is_Empty, "cursor movement after undo keeps redo history");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Assert (Editor.History.Redo_Stack.Is_Empty, "new edit after undo clears redo history");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "X", "redo unavailable after new edit mutates nothing");
   end Test_Phase211_Redo_Cleared_By_New_Edit_Not_Movement;

   procedure Test_Phase211_Dirty_State_Restored_By_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (not S.File_Info.Dirty, "new buffer starts clean");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Assert (S.File_Info.Dirty, "edit makes clean buffer dirty");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (not S.File_Info.Dirty, "undo of sole edit restores clean dirty state");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert (S.File_Info.Dirty, "redo restores dirty state");
   end Test_Phase211_Dirty_State_Restored_By_Undo_Redo;

   procedure Test_Phase211_Unavailable_Undo_Redo_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Undo);
      Assert (A.Status = Editor.Commands.Command_Unavailable, "empty undo history is unavailable");

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Redo);
      Assert (A.Status = Editor.Commands.Command_Unavailable, "empty redo history is unavailable");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Undo);
      Assert (A.Status = Editor.Commands.Command_Available, "undo is available after edit");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Redo);
      Assert (A.Status = Editor.Commands.Command_Available, "redo is available after undo");
   end Test_Phase211_Unavailable_Undo_Redo_Availability;

   -------------------------------------------------------------------------
   --  Existing replace-batch normalization coverage retained
   -------------------------------------------------------------------------

   procedure Test_Replace_Batch_Normalizes_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));

      Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
      Cmd.Positions.Append (3);
      Cmd.Delete_Counts.Append (1);
      Cmd.Insert_Texts.Append (To_Unbounded_String ("D"));
      Cmd.Positions.Append (1);
      Cmd.Delete_Counts.Append (1);
      Cmd.Insert_Texts.Append (To_Unbounded_String ("B"));

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      Assert_Text (S, "aBcDef", "replace batch normalizes order");
   end Test_Replace_Batch_Normalizes_Order;

   procedure Test_Replace_Batch_Incremental_Line_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("aa" & ASCII.LF & "bb" & ASCII.LF & "cc"));

      Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
      Cmd.Positions.Append (1);
      Cmd.Delete_Counts.Append (0);
      Cmd.Insert_Texts.Append (To_Unbounded_String (String'(1 => ASCII.LF)));
      Cmd.Positions.Append (6);
      Cmd.Delete_Counts.Append (1);
      Cmd.Insert_Texts.Append (To_Unbounded_String ("C"));

      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      Assert (Editor.State.Line_Count (S) = 4, "incremental batch line count");
      Assert (Natural (Editor.State.Line_Start (S, 0)) = 0
              and then Natural (Editor.State.Line_Start (S, 1)) = 2
              and then Natural (Editor.State.Line_Start (S, 2)) = 4
              and then Natural (Editor.State.Line_Start (S, 3)) = 7,
              "incremental batch line starts");
   end Test_Replace_Batch_Incremental_Line_Index;



   -------------------------------------------------------------------------
   --  Phase 369: active-buffer undo/redo command surface
   -------------------------------------------------------------------------

   procedure Test_Phase369_Command_Surface_And_Clear_History
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Undo) = "edit.undo",
         "undo stable command name must be canonical");
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Redo) = "edit.redo",
         "redo stable command name must be canonical");
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Edit_History_Clear) = "edit.history.clear",
         "clear edit history stable command name must be canonical");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Undo).Visibility = Editor.Commands.Palette_Command,
         "undo must be command-palette visible");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Redo).Visibility = Editor.Commands.Palette_Command,
         "redo must be command-palette visible");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Edit_History_Clear).Visibility = Editor.Commands.Palette_Command,
         "clear edit history must be command-palette visible");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (A.Status = Editor.Commands.Command_Available,
        "clear edit history is available when active buffer has undo history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (Editor.History.Undo_Stack.Is_Empty,
        "clear edit history clears undo stack");
      Assert (Editor.History.Redo_Stack.Is_Empty,
        "clear edit history clears redo stack");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Undo history cleared",
        "clear edit history publishes one canonical message");
   end Test_Phase369_Command_Surface_And_Clear_History;




   -------------------------------------------------------------------------
   --  Phase 372: post-final cleanup and canonicalization
   -------------------------------------------------------------------------

   procedure Assert_Removed_Name_Undo_Redo_Name_Rejected (Name : String) is
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      Assert
        (not Found and then Id = Editor.Commands.No_Command,
         "Phase 372 removed undo/redo command name must be rejected: " & Name);
   end Assert_Removed_Name_Undo_Redo_Name_Rejected;

   function Palette_Contains_Stable_Name (Name : String) return Boolean is
      Rows : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      for Row of Rows loop
         if Editor.Commands.Stable_Command_Name (Row.Id) = Name then
            return True;
         end if;
      end loop;

      return False;
   end Palette_Contains_Stable_Name;

   procedure Test_Phase372_Instance_Undo_Redo_Use_Canonical_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      E : Editor.Instance.Editor_Instance;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Instance.Init (E);
      Editor.Instance.Execute (E, Paste ("A"));
      Assert_Stacks (1, 0, "Phase 372 instance setup creates canonical undo entry");

      Editor.Instance.Undo (E);
      Assert_Text (E.State, "", "Phase 372 instance undo restores through canonical stack");
      Assert_Stacks (0, 1, "Phase 372 instance undo transfers canonical entry to redo");
      Assert (Latest_Message_Text (E.State) = "Undid edit",
              "Phase 372 instance undo emits canonical Executor message");

      Editor.Instance.Redo (E);
      Assert_Text (E.State, "A", "Phase 372 instance redo restores through canonical stack");
      Assert_Stacks (1, 0, "Phase 372 instance redo transfers canonical entry to undo");
      Assert (Latest_Message_Text (E.State) = "Redid edit",
              "Phase 372 instance redo emits canonical Executor message");
   end Test_Phase372_Instance_Undo_Redo_Use_Canonical_Route;

   -------------------------------------------------------------------------
   --  Phase 370: undo/redo reliability hardening
   -------------------------------------------------------------------------

   procedure Test_Phase370_Repeated_Undo_Redo_Exact_Text_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("A"));
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Assert_Text (S, "ABC", "phase370 edit precondition");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "AB", "phase370 first undo restores previous text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "A", "phase370 second undo restores earlier text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "AB", "phase370 first redo restores later text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ABC", "phase370 second redo restores latest text");
   end Test_Phase370_Repeated_Undo_Redo_Exact_Text_Order;

   procedure Test_Phase370_No_Op_Log_Does_Not_Clear_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("ab"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "phase370 undo creates redo precondition");

      Before := S;
      Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
      Editor.Executor.History.Log_Edit (Before, S, Cmd);

      Assert (Editor.History.Undo_Stack.Is_Empty,
              "phase370 no-op log does not create undo entry");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "phase370 no-op log must not clear redo stack");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ab", "phase370 redo remains available after no-op log");
   end Test_Phase370_No_Op_Log_Does_Not_Clear_Redo;

   procedure Test_Phase370_No_Op_Edit_Does_Not_Dirty_Or_Clear_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("a"));
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Editor.Executor.Execute_No_Log (S, Paste ("b"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "a", "phase370 no-op edit redo precondition");
      Assert (not Editor.State.Is_Dirty (S),
              "phase370 undo to saved baseline is clean precondition");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "phase370 redo stack exists before no-op edit");

      Set_Caret (S, 1, 0);
      Editor.Executor.Execute_No_Log (S, Paste ("a"));

      Assert_Text (S, "a",
                   "phase370 selected replacement with identical text leaves text unchanged");
      Assert (not Editor.State.Is_Dirty (S),
              "phase370 no-op text edit must not dirty a clean buffer");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "phase370 no-op text edit must not create undo history");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "phase370 no-op text edit must not clear redo history");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "ab",
                   "phase370 redo remains available after a no-op text edit");
   end Test_Phase370_No_Op_Edit_Does_Not_Dirty_Or_Clear_Redo;

   procedure Test_Phase370_History_Stack_Bound_Preserves_Newest
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      for I in 1 .. 105 loop
         Editor.Executor.Execute_No_Log (S, Paste ("x"));
      end loop;

      Assert (Natural (Editor.History.Undo_Stack.Length) = 100,
              "phase370 undo stack is bounded at 100 entries");

      for I in 1 .. 100 loop
         Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      end loop;

      Assert_Text (S, "xxxxx",
                   "phase370 bounded stack discards oldest entries and preserves newest undo path");
   end Test_Phase370_History_Stack_Bound_Preserves_Newest;

   procedure Test_Phase370_Active_Buffer_History_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Buffers.Buffer_Id;
      B : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log (S, Paste ("A"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Text (S, "A", "phase370 buffer A text precondition");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase370 undo affects only active buffer A");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Text (S, "B", "phase370 buffer B text was not affected by buffer A undo");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase370 undo then affects active buffer B");
   end Test_Phase370_Active_Buffer_History_Isolated;

   procedure Test_Phase370_Dirty_Baseline_After_Save_Simulation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("saved"));
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.State.Set_Dirty (S, False);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "",
                   "phase370 undo after saved baseline restores before text");
      Assert (Editor.State.Is_Dirty (S),
              "phase370 undo after save baseline marks divergent text dirty");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "saved",
                   "phase370 redo after saved baseline restores saved text");
      Assert (not Editor.State.Is_Dirty (S),
              "phase370 redo to saved baseline is clean");
   end Test_Phase370_Dirty_Baseline_After_Save_Simulation;

   procedure Test_Phase370_Snapshots_Authoritative_Over_Spans
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      E : Editor.History.History_Entry;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      E := Editor.History.Undo_Stack.Last_Element;
      E.Inverse.Positions.Clear;
      E.Inverse.Delete_Counts.Clear;
      E.Inverse.Insert_Texts.Clear;
      E.Forward.Positions.Clear;
      E.Forward.Delete_Counts.Clear;
      E.Forward.Insert_Texts.Clear;
      Editor.History.Undo_Stack.Replace_Element
        (Editor.History.Undo_Stack.Last_Index, E);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "",
                   "phase370 undo restores exact before snapshot, not inverse spans");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "abc",
                   "phase370 redo restores exact after snapshot, not forward spans");
   end Test_Phase370_Snapshots_Authoritative_Over_Spans;


   procedure Test_Phase370_Stale_Owner_Entry_Cannot_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      E : Editor.History.History_Entry;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      Assert_Text (S, "abc", "phase370 stale-owner precondition");
      E := Editor.History.Undo_Stack.Last_Element;
      E.Owner_Buffer_Token := E.Owner_Buffer_Token + 1;
      Editor.History.Undo_Stack.Replace_Element
        (Editor.History.Undo_Stack.Last_Index, E);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "abc",
                   "phase370 stale-owner undo must not restore into a different buffer identity");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "phase370 stale-owner failure preserves undo stack");
      Assert (Editor.History.Redo_Stack.Is_Empty,
              "phase370 stale-owner failure does not create redo entry");
      Assert (Editor.Executor.History.Last_Operation_Failed,
              "phase370 stale-owner failure is reported to command layer");
   end Test_Phase370_Stale_Owner_Entry_Cannot_Undo;

   procedure Test_Phase370_Stale_Lifecycle_Entry_Cannot_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      E : Editor.History.History_Entry;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase370 stale-lifecycle redo precondition");
      E := Editor.History.Redo_Stack.Last_Element;
      E.Owner_Lifecycle_Generation := E.Owner_Lifecycle_Generation + 1;
      Editor.History.Redo_Stack.Replace_Element
        (Editor.History.Redo_Stack.Last_Index, E);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "",
                   "phase370 stale-lifecycle redo must not restore old lifecycle text");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "phase370 stale-lifecycle redo failure preserves undo stack");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "phase370 stale-lifecycle redo failure preserves redo stack");
      Assert (Editor.Executor.History.Last_Operation_Failed,
              "phase370 stale-lifecycle failure is reported to command layer");
   end Test_Phase370_Stale_Lifecycle_Entry_Cannot_Redo;

   procedure Test_Phase370_Clear_History_Is_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Buffers.Buffer_Id;
      B : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log (S, Paste ("A"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "phase370 clear history clears active buffer A undo stack");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "phase370 clear history does not clear inactive buffer B undo stack");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "",
                   "phase370 inactive buffer B history remains usable after clearing A");
   end Test_Phase370_Clear_History_Is_Active_Buffer_Only;



   -------------------------------------------------------------------------
   --  Phase 371: undo/redo workflow consistency coverage
   -------------------------------------------------------------------------

   procedure Test_Phase371_Basic_Text_Edit_Undo_Redo_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "A");
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Assert_Text (S, "AB", "phase371 ordinary edit precondition");
      Assert_Stacks (1, 0, "phase371 ordinary edit creates one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "A", "phase371 undo restores exact previous text");
      Assert_Stacks (0, 1, "phase371 undo transfers entry to redo");
      Assert (Latest_Message_Text (S) = "Undid edit",
              "phase371 undo emits one primary undo message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "AB", "phase371 redo restores exact later text");
      Assert_Stacks (1, 0, "phase371 redo transfers entry to undo");
      Assert (Latest_Message_Text (S) = "Redid edit",
              "phase371 redo emits one primary redo message");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "phase371 undo/redo must not record navigation history");
   end Test_Phase371_Basic_Text_Edit_Undo_Redo_Workflow;

   procedure Test_Phase371_Repeated_Undo_Redo_Ordering_And_Empty_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Editor.Executor.Execute_No_Log (S, Paste ("D"));
      Assert_Stacks (3, 0, "phase371 three edits are three undo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "ABC", "phase371 undo 1");
      Assert_Stacks (2, 1, "phase371 stack after undo 1");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "AB", "phase371 undo 2");
      Assert_Stacks (1, 2, "phase371 stack after undo 2");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "A", "phase371 undo 3");
      Assert_Stacks (0, 3, "phase371 stack after undo 3");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "A", "phase371 empty undo mutates nothing");
      Assert (Latest_Message_Text (S) = "No edits to undo",
              "phase371 empty undo message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "AB", "phase371 redo 1");
      Assert_Stacks (1, 2, "phase371 stack after redo 1");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "ABC", "phase371 redo 2");
      Assert_Stacks (2, 1, "phase371 stack after redo 2");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "ABCD", "phase371 redo 3");
      Assert_Stacks (3, 0, "phase371 stack after redo 3");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "ABCD", "phase371 empty redo mutates nothing");
      Assert (Latest_Message_Text (S) = "No edits to redo",
              "phase371 empty redo message");
   end Test_Phase371_Repeated_Undo_Redo_Ordering_And_Empty_Messages;

   procedure Test_Phase371_Redo_Invalidation_Success_Failure_And_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "AB", "phase371 redo invalidation precondition");
      Assert_Stacks (1, 1, "phase371 redo invalidation precondition stacks");
      Editor.Executor.Execute_No_Log (S, Paste ("D"));
      Assert_Text (S, "ABD", "phase371 successful new edit applies");
      Assert_Stacks (2, 0, "phase371 successful new edit clears redo only for active buffer");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "ABD", "phase371 redo after invalidation mutates nothing");
      Assert (Latest_Message_Text (S) = "No edits to redo",
              "phase371 redo invalidation message");

      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Stacks (0, 1, "phase371 failed mutation precondition");
      Cmd.Kind := Editor.Commands.Active_Replace_Current;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert_Text (S, "A", "phase371 failed replace.current mutates nothing");
      Assert_Stacks (0, 1, "phase371 failed replace.current preserves redo");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "AB", "phase371 redo survives failed mutation");

      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Editor.Executor.Execute_Find_Set_Query (S, "A");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line_Toggle);
      Assert_Stacks (0, 1, "phase371 read-only commands preserve redo");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "AB", "phase371 redo survives read-only/navigation commands");
   end Test_Phase371_Redo_Invalidation_Success_Failure_And_Read_Only;

   procedure Test_Phase371_History_Clear_Text_Dirty_And_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Dirty_Before : Boolean;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Assert_Stacks (0, 1, "phase371 clear precondition");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert_Text (S, "A", "phase371 history.clear does not mutate text");
      Assert_Stacks (0, 0, "phase371 history.clear clears both stacks");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "phase371 history.clear does not directly mutate dirty flag");
      Assert (Latest_Message_Text (S) = "Undo history cleared",
              "phase371 history.clear emits one cleared message");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Latest_Message_Text (S) = "No edits to undo",
              "phase371 undo after clear reports no undo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (Latest_Message_Text (S) = "No edit history to clear",
              "phase371 empty history.clear message");
   end Test_Phase371_History_Clear_Text_Dirty_And_Isolation;

   procedure Test_Phase371_Replace_Current_And_All_Grouped_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "Run;" & ASCII.LF & "Run;");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);
      Assert_Text (S, "Execute;" & ASCII.LF & "Run;", "phase371 replace.current replaces one match");
      Assert_Stacks (1, 0, "phase371 replace.current creates one undo entry");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "Run;" & ASCII.LF & "Run;", "phase371 replace.current undo restores whole text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "Execute;" & ASCII.LF & "Run;", "phase371 replace.current redo restores replacement");

      Set_Buffer_Text (S, "Run Run Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_All (S);
      Assert_Text (S, "Execute Execute Execute", "phase371 replace.all replaces all matches");
      Assert_Stacks (1, 0, "phase371 replace.all is one grouped undo entry");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "Run Run Run", "phase371 replace.all undo is grouped");
      Assert_Stacks (0, 1, "phase371 replace.all undo transfers one entry");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "Execute Execute Execute", "phase371 replace.all redo is grouped");
      Assert_Stacks (1, 0, "phase371 replace.all redo returns one grouped entry");

      Set_Buffer_Text (S, "aaaa");
      Editor.Executor.Execute_Find_Set_Query (S, "aa");
      Editor.Executor.Execute_Replace_Set_Text (S, "a");
      Editor.Executor.Execute_Replace_All (S);
      Assert_Text (S, "aa", "phase371 span-safe replace.all uses original canonical matches");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "aaaa", "phase371 span-safe undo restores before text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "aa", "phase371 span-safe redo restores after text");
   end Test_Phase371_Replace_Current_And_All_Grouped_Undo_Redo;

   procedure Test_Phase371_Find_Replace_Render_Invalidated_After_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Find_Visible and then Snap.Replace_Visible
              and then Snap.Find_Match_Count = 2,
              "phase371 render precondition exposes two Find ranges");

      Editor.Executor.Execute_Replace_All (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Find_Match_Count = 0,
              "phase371 post replace.all snapshot has no stale old ranges");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert_Text (S, "Run Run", "phase371 undo restores text before render assertion");
      Assert (Snap.Find_Match_Count = 2,
              "phase371 undo recomputes/restores rendered Find ranges for restored text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert_Text (S, "Execute Execute", "phase371 redo restores replaced text before render assertion");
      Assert (Snap.Find_Match_Count = 0,
              "phase371 redo does not render stale pre-undo ranges");
      Assert (To_String (S.Active_Replace_Text) = "Execute",
              "phase371 undo/redo preserves transient replacement text policy");
   end Test_Phase371_Find_Replace_Render_Invalidated_After_Undo_Redo;

   procedure Test_Phase371_Active_Buffer_Redo_And_Clear_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Buffers.Buffer_Id;
      B : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Paste ("A1"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Paste ("B1"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase371 undo in A affects only A");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Text (S, "B1", "phase371 B text unaffected by A undo");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase371 undo in B affects B");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "B1", "phase371 redo in B affects B only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert_Text (S, "A1", "phase371 redo in A restores A only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert_Stacks (0, 0, "phase371 clear applies to active A only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "phase371 B undo stack survives A history.clear");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert_Text (S, "", "phase371 B undo still works after clearing A");
   end Test_Phase371_Active_Buffer_Redo_And_Clear_Isolation;

   procedure Test_Phase371_Availability_Render_And_Route_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      A : Editor.Commands.Command_Availability;
      U : Natural;
      R : Natural;
      Before_Text : Unbounded_String;
   begin
      Editor.State.Init (S);
      Set_Buffer_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      U := Natural (Editor.History.Undo_Stack.Length);
      R := Natural (Editor.History.Redo_Stack.Length);
      Before_Text := To_Unbounded_String (Text (S));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text (S)'Length,
              "phase371 render snapshot reflects text without consuming history");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Undo);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "phase371 undo availability reports current empty undo stack");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Redo);
      Assert (A.Status = Editor.Commands.Command_Available,
              "phase371 redo availability reports non-empty redo stack");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (A.Status = Editor.Commands.Command_Available,
              "phase371 history.clear availability reports non-empty history");

      Assert (Text (S) = To_String (Before_Text),
              "phase371 render/availability does not mutate buffer text");
      Assert_Stacks (U, R, "phase371 render/availability preserves stacks");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Text (S, "AB", "phase371 command route through Executor performs redo once");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Text (S, "A", "phase371 command route through Executor performs undo once");
   end Test_Phase371_Availability_Render_And_Route_Are_Side_Effect_Free;



   overriding function Name
     (T : History_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.History");
   end Name;

   overriding procedure Register_Tests
     (T : in out History_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Single_Insert_Undo_Redo_Unit'Access,
         "Phase 211 single insert undo redo unit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Newline_Undo_Redo_Unit'Access,
         "Phase 211 newline undo redo unit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Backspace_Undo_Redo'Access,
         "Phase 211 backspace undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Forward_Delete_Undo_Redo'Access,
         "Phase 211 forward delete undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Selected_Replacement_Undo_Redo_Selection_Context'Access,
         "Phase 211 selected replacement undo redo selection context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Multiline_Paste_Undo_Redo'Access,
         "Phase 211 multiline paste undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Delete_Across_Line_Boundary_Undo_Redo'Access,
         "Phase 211 delete across line boundary undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Failed_Edit_Creates_No_Undo_Entry'Access,
         "Phase 211 failed edit creates no undo entry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Cursor_Movement_Creates_No_Undo_Entry'Access,
         "Phase 211 cursor movement creates no undo entry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Redo_Cleared_By_New_Edit_Not_Movement'Access,
         "Phase 211 redo cleared by new edit not movement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Dirty_State_Restored_By_Undo_Redo'Access,
         "Phase 211 dirty state restored by undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase211_Unavailable_Undo_Redo_Availability'Access,
         "Phase 211 unavailable undo redo availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase369_Command_Surface_And_Clear_History'Access,
         "Phase 369 command surface and clear history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase372_Instance_Undo_Redo_Use_Canonical_Route'Access,
         "Phase 372 instance undo redo canonical route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Repeated_Undo_Redo_Exact_Text_Order'Access,
         "Phase 370 repeated undo redo exact text order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_No_Op_Log_Does_Not_Clear_Redo'Access,
         "Phase 370 no op log does not clear redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_No_Op_Edit_Does_Not_Dirty_Or_Clear_Redo'Access,
         "Phase 370 no op edit does not dirty or clear redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_History_Stack_Bound_Preserves_Newest'Access,
         "Phase 370 history stack bound preserves newest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Active_Buffer_History_Isolated'Access,
         "Phase 370 active buffer history isolated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Dirty_Baseline_After_Save_Simulation'Access,
         "Phase 370 dirty baseline after save simulation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Snapshots_Authoritative_Over_Spans'Access,
         "Phase 370 snapshots authoritative over spans");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Stale_Owner_Entry_Cannot_Undo'Access,
         "Phase 370 stale owner entry cannot undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Stale_Lifecycle_Entry_Cannot_Redo'Access,
         "Phase 370 stale lifecycle entry cannot redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase370_Clear_History_Is_Active_Buffer_Only'Access,
         "Phase 370 clear history is active buffer only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Basic_Text_Edit_Undo_Redo_Workflow'Access,
         "Phase 371 basic text edit undo redo workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Repeated_Undo_Redo_Ordering_And_Empty_Messages'Access,
         "Phase 371 repeated undo redo ordering and empty messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Redo_Invalidation_Success_Failure_And_Read_Only'Access,
         "Phase 371 redo invalidation success failure and read only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_History_Clear_Text_Dirty_And_Isolation'Access,
         "Phase 371 history clear text dirty and isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Replace_Current_And_All_Grouped_Undo_Redo'Access,
         "Phase 371 replace current and all grouped undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Find_Replace_Render_Invalidated_After_Undo_Redo'Access,
         "Phase 371 find replace render invalidated after undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Active_Buffer_Redo_And_Clear_Isolation'Access,
         "Phase 371 active buffer redo and clear isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase371_Availability_Render_And_Route_Are_Side_Effect_Free'Access,
         "Phase 371 availability render and route side effect free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Batch_Normalizes_Order'Access,
         "Replace batch normalizes order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Batch_Incremental_Line_Index'Access,
         "Replace batch incremental line index");
   end Register_Tests;

end Editor.History.Tests;
