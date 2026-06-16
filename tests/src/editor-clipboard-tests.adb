with AUnit.Assertions;  use AUnit.Assertions;
with Ada.Containers;
with AUnit.Test_Cases;
with AUnit;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Clipboard;
with Editor.Commands;
with Editor.Buffers;
with Editor.Input_Field;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Render_Model;
with Editor.Search;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor;
with Editor.Executor.History;
with Editor.Executor.Clipboard;
use type Editor.Executor.Clipboard.Clipboard_Execution_Status;
use type Editor.Commands.Command_Id;
use type Editor.Commands.Command_Category;
use type Editor.Commands.Command_Visibility;
use type Ada.Containers.Count_Type;
with Editor.History;
with Editor.State;
with Editor.Workspace_Persistence;
with Editor.Go_To_Line;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Buffer_Switcher;
with Editor.Recent_Buffers;
with Editor.Bookmarks;
with Editor.Input_Bridge;
with Editor.Keybindings;

package body Editor.Clipboard.Tests is

   function Paste (S : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String (S);
      return Cmd;
   end Paste;

   procedure Reset_Transient_State is
   begin
      Editor.Clipboard.Clear;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.History.Clear_Operation_Status;
   end Reset_Transient_State;


   function Undo_Count return Natural is
   begin
      return Natural (Editor.History.Undo_Stack.Length);
   end Undo_Count;

   function Redo_Count return Natural is
   begin
      return Natural (Editor.History.Redo_Stack.Length);
   end Redo_Count;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
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

   procedure Mark_Clean (S : in out Editor.State.State_Type) is
   begin
      Editor.State.Set_Dirty (S, False);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Clean;

   procedure Assert_Clipboard_State
     (Expected_Has_Text : Boolean;
      Expected_Text     : String;
      Why               : String)
   is
   begin
      Assert (Editor.Clipboard.Has_Text = Expected_Has_Text,
              Why & " has-text mismatch");
      Assert (To_String (Editor.Clipboard.Get_Text) = Expected_Text,
              Why & " text mismatch");
   end Assert_Clipboard_State;

   procedure Assert_No_Navigation_History_Change
     (S              : Editor.State.State_Type;
      Expected_Back  : Natural;
      Expected_Fwd   : Natural;
      Why            : String)
   is
   begin
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Expected_Back,
              Why & " must not change navigation back stack");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = Expected_Fwd,
              Why & " must not change navigation forward stack");
   end Assert_No_Navigation_History_Change;

   procedure Set_Primary_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Cursor_Index;
      Pos    : Cursor_Index)
   is
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Pos,
           Anchor                => Anchor,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
   end Set_Primary_Selection;

   procedure Set_Primary_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index) is
   begin
      Set_Primary_Selection (S, Pos, Pos);
   end Set_Primary_Caret;

   overriding function Name
     (T : Clipboard_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Clipboard");
   end Name;

   procedure Test_Phase373_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Copy) =
         "edit.copy",
         "copy must have the Phase 373 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Cut) =
         "edit.cut",
         "cut must have the Phase 373 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Paste) =
         "edit.paste",
         "paste must have the Phase 373 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Clipboard_Clear) =
         "edit.clipboard.clear",
         "clipboard clear must have the Phase 373 stable command name");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Copy).Category =
         Editor.Commands.Edit_Category,
         "copy must be an Edit command");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Cut).Bindable,
         "cut must be bindable");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Paste).Visibility =
         Editor.Commands.Palette_Command,
         "paste must be visible in the command palette");
   end Test_Phase373_Command_Metadata;

   procedure Test_Phase373_Copy_Selected_Text_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;

      Set_Primary_Selection (S, 1, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);

      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "copy must store the selected text exactly");
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "copy must not mutate active-buffer text");
      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "copy must not create an undo entry");
   end Test_Phase373_Copy_Selected_Text_Only;

   procedure Test_Phase373_No_Selection_Copy_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;
      Set_Primary_Caret (S, 3);

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert
        (not Editor.Commands.Is_Available (A),
         "copy without a selected range must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No selected text",
         "copy without selection must report No selected text");
   end Test_Phase373_No_Selection_Copy_Is_Unavailable;

   procedure Test_Phase373_Cut_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;

      Set_Primary_Selection (S, 1, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);

      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "cut must publish the selected text after deletion succeeds");
      Assert
        (Editor.State.Current_Text (S) = "aef",
         "cut must delete the selected range through the edit path");
      Assert
        (not Editor.History.Undo_Stack.Is_Empty,
         "cut must create one undoable edit when text changes");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "undo after cut must restore deleted text");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "undo must not mutate clipboard contents");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Editor.State.Current_Text (S) = "aef",
         "redo after cut must delete the text again");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "redo must not mutate clipboard contents");
   end Test_Phase373_Cut_Undo_Redo;

   procedure Test_Phase373_Paste_At_Caret_And_Over_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abef"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("cd"));

      Set_Primary_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "paste with no selection must insert at the caret");
      Assert
        (not Editor.History.Undo_Stack.Is_Empty,
         "paste at caret must create an undoable edit");

      Set_Primary_Selection (S, 2, 4);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("XY"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (Editor.State.Current_Text (S) = "abXYef",
         "paste with selection must replace the selected text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "undo after paste-over-selection must restore previous text");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "XY",
         "undo after paste must not mutate clipboard contents");
   end Test_Phase373_Paste_At_Caret_And_Over_Selection;


   procedure Test_Phase373_Paste_Identical_Selection_No_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("cd"));

      Set_Primary_Selection (S, 2, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "pasting identical clipboard text over the selected text must leave text unchanged");
      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "pasting identical selected text must not create an undo entry");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "cd",
         "degenerate paste must not clear or mutate clipboard contents");
   end Test_Phase373_Paste_Identical_Selection_No_Edit;

   procedure Test_Phase373_Empty_Clipboard_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Paste);
      Assert
        (not Editor.Commands.Is_Available (A),
         "paste with empty clipboard must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "Clipboard is empty",
         "paste with empty clipboard must report Clipboard is empty");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clipboard_Clear);
      Assert
        (not Editor.Commands.Is_Available (A),
         "clipboard clear with empty clipboard must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "Clipboard is empty",
         "clipboard clear with empty clipboard must report Clipboard is empty");
   end Test_Phase373_Empty_Clipboard_Availability;

   procedure Test_Phase373_Redo_Invalidation_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("A"));
      Reset_Transient_State;

      Set_Primary_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "setup must leave redo available after undo");

      Set_Primary_Selection (S, 0, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "copy after undo must preserve redo history");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("C"));
      Set_Primary_Caret (S, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (Editor.History.Redo_Stack.Is_Empty,
         "successful paste after undo must clear redo history");
   end Test_Phase373_Redo_Invalidation_Policies;

   procedure Test_Phase373_Clipboard_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("abc"));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clipboard_Clear);
      Assert
        (not Editor.Clipboard.Has_Text,
         "clipboard clear must clear transient clipboard text");
      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "clipboard clear must not create undo history");
   end Test_Phase373_Clipboard_Clear;


   procedure Test_Phase374_Backward_Selection_Copy_Cut
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;

      Set_Primary_Selection (S, 4, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "backward copy must extract the same text as a forward selection");
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "backward copy must not mutate text");

      Set_Primary_Selection (S, 4, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "bcd",
         "backward cut must publish the normalized selected text");
      Assert
        (Editor.State.Current_Text (S) = "aef",
         "backward cut must delete the normalized selected range");
   end Test_Phase374_Backward_Selection_Copy_Cut;

   procedure Test_Phase374_Invalid_Selection_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));

      Set_Primary_Selection (S, 2, 99);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Cut);
      Assert
        (not Editor.Commands.Is_Available (A),
         "out-of-range cut selection must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "Invalid selection",
         "out-of-range cut selection must report Invalid selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert
        (Editor.State.Current_Text (S) = "abcdef",
         "failed cut must not mutate buffer text");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "old",
         "failed cut must leave the previous clipboard intact");
      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "failed cut must not create undo history");
   end Test_Phase374_Invalid_Selection_Is_Atomic;

   procedure Test_Phase541_Multiline_Clipboard_Text_Is_Supported
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ab" & ASCII.LF & "cd"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));

      Set_Primary_Selection (S, 1, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert
        (Editor.Executor.Clipboard.Last_Status =
           Editor.Executor.Clipboard.Clipboard_Copied,
         "multiline clipboard copy must copy the selected range");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "b" & ASCII.LF & "c",
         "multiline copy must preserve selected line breaks");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("x" & ASCII.LF & "y"));
      Set_Primary_Caret (S, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (Editor.Executor.Clipboard.Last_Status =
           Editor.Executor.Clipboard.Clipboard_Pasted,
         "multiline clipboard paste must be accepted");
      Assert
        (Editor.State.Current_Text (S) = "ax" & ASCII.LF & "yb" & ASCII.LF & "cd",
         "multiline paste must insert clipboard text at the caret");
   end Test_Phase541_Multiline_Clipboard_Text_Is_Supported;

   procedure Test_Phase374_Redo_Preserved_By_Non_Text_Clipboard_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("A"));
      Reset_Transient_State;

      Set_Primary_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "setup must leave redo available after undo");

      Set_Primary_Selection (S, 0, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "copy after undo must preserve redo history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clipboard_Clear);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "clipboard clear after undo must preserve redo history");
   end Test_Phase374_Redo_Preserved_By_Non_Text_Clipboard_Commands;

   procedure Test_Phase374_No_Op_Paste_Preserves_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("AB"));
      Reset_Transient_State;

      Set_Primary_Caret (S, 2);
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "setup must leave redo available after undo");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("B"));
      Set_Primary_Selection (S, 1, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (Editor.State.Current_Text (S) = "AB",
         "no-op paste over identical selected text must preserve buffer text");
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "no-op paste after undo must preserve redo history");
   end Test_Phase374_No_Op_Paste_Preserves_Redo;

   procedure Test_Phase374_Successful_Cut_Clears_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("ABC"));
      Reset_Transient_State;

      Set_Primary_Caret (S, 3);
      Editor.Executor.Execute_No_Log (S, Paste ("D"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "setup must leave redo available after undo");

      Set_Primary_Selection (S, 1, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert
        (Editor.State.Current_Text (S) = "AC",
         "successful cut after undo must mutate the buffer");
      Assert
        (Editor.History.Redo_Stack.Is_Empty,
         "successful cut after undo must clear redo history");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "B",
         "successful cut must publish the cut text");
   end Test_Phase374_Successful_Cut_Clears_Redo;


   procedure Test_Phase374_Failed_Paste_Preserves_Clipboard_And_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("AB"));
      Reset_Transient_State;

      Set_Primary_Caret (S, 2);
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "setup must leave redo available after undo");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Z"));
      Set_Primary_Selection (S, 1, 99);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert
        (Editor.Executor.Clipboard.Last_Status =
           Editor.Executor.Clipboard.Clipboard_Invalid_Selection,
         "paste over an invalid selection must report Invalid selection");
      Assert
        (Editor.State.Current_Text (S) = "AB",
         "failed paste must not mutate buffer text");
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "Z",
         "failed paste must preserve clipboard text");
      Assert
        (not Editor.History.Redo_Stack.Is_Empty,
         "failed paste after undo must preserve redo history");
      Assert
        (Editor.History.Undo_Stack.Is_Empty,
         "failed paste must not create undo history");
   end Test_Phase374_Failed_Paste_Preserves_Clipboard_And_Redo;

   procedure Test_Phase374_Clipboard_Independent_Of_Undo_Redo_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("AB"));
      Reset_Transient_State;

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Z"));
      Set_Primary_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "Z",
         "paste must not clear or rewrite clipboard text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "Z",
         "undo after paste must not mutate clipboard text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "Z",
         "redo after paste must not mutate clipboard text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert
        (To_String (Editor.Clipboard.Get_Text) = "Z",
         "history clear must not mutate clipboard text");
   end Test_Phase374_Clipboard_Independent_Of_Undo_Redo_Clear;


   procedure Test_Phase375_Copy_Workflow_Is_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Back   : Natural;
      Before_Fwd    : Natural;
      Before_Undo   : Natural;
      Before_Redo   : Natural;
      Before_Find_Q : Unbounded_String;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Mark_Clean (S);
      Reset_Transient_State;

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Before_Find_Q := S.Active_Find_Query;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Undo := Undo_Count;
      Before_Redo := Redo_Count;

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);

      Assert_Clipboard_State (True, "Beta", "copy workflow");
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "copy must not mutate active-buffer text");
      Assert (not Editor.State.Is_Dirty (S),
              "copy must not dirty a clean buffer");
      Assert (Undo_Count = Before_Undo and then Redo_Count = Before_Redo,
              "copy must preserve undo and redo stacks");
      Assert (S.Active_Find_Query = Before_Find_Q
              and then not S.Active_Find_Stale
              and then Natural (S.Active_Find_Matches.Length) = 1,
              "copy must preserve current Find/Replace state");
      Assert_No_Navigation_History_Change (S, Before_Back, Before_Fwd,
                                           "copy workflow");
      Assert (Active_Message_Text (S) = "Copied selection",
              "copy must emit one primary copied-selection message");
   end Test_Phase375_Copy_Workflow_Is_Non_Mutating;

   procedure Test_Phase375_Forward_Backward_Paste_Over_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Forward  : Editor.State.State_Type;
      Backward : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (Forward);
      Editor.Executor.Execute_No_Log (Forward, Paste ("Alpha X Gamma"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Beta"));

      Set_Primary_Selection (Forward, 6, 7);
      Editor.Executor.Execute_Command (Forward, Editor.Commands.Command_Paste);

      Reset_Transient_State;
      Editor.State.Init (Backward);
      Editor.Executor.Execute_No_Log (Backward, Paste ("Alpha X Gamma"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Beta"));

      Set_Primary_Selection (Backward, 7, 6);
      Editor.Executor.Execute_Command (Backward, Editor.Commands.Command_Paste);

      Assert (Editor.State.Current_Text (Forward) = "Alpha Beta Gamma",
              "forward paste-over-selection must replace the selected range");
      Assert (Editor.State.Current_Text (Backward) = "Alpha Beta Gamma",
              "backward paste-over-selection must normalize the same selected range");
      Assert (Undo_Count = 1,
              "backward paste-over-selection must create one undo entry");
      Assert_Clipboard_State (True, "Beta",
                              "paste-over-selection normalization");
   end Test_Phase375_Forward_Backward_Paste_Over_Selection;

   procedure Test_Phase375_Paste_At_Caret_Undo_Redo_And_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural;
      Before_Fwd  : Natural;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha  Gamma"));
      Mark_Clean (S);
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Beta"));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Primary_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "paste at caret must insert clipboard text at the insertion point");
      Assert (Undo_Count = 1 and then Redo_Count = 0,
              "paste at caret must create exactly one undoable edit and no redo");
      Assert (Editor.State.Is_Dirty (S),
              "paste at caret must update dirty state through the canonical edit path");
      Assert_Clipboard_State (True, "Beta",
                              "paste at caret must preserve clipboard contents");
      Assert_No_Navigation_History_Change (S, Before_Back, Before_Fwd,
                                           "paste at caret");
      Assert (Active_Message_Text (S) = "Pasted clipboard",
              "paste must emit one primary pasted message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "Alpha  Gamma",
              "undo after paste must remove inserted clipboard text");
      Assert_Clipboard_State (True, "Beta",
                              "undo after paste must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "redo after paste must reinsert clipboard text");
      Assert_Clipboard_State (True, "Beta",
                              "redo after paste must not mutate clipboard");
   end Test_Phase375_Paste_At_Caret_Undo_Redo_And_Message;

   procedure Test_Phase375_Cut_Atomicity_Dirty_Find_And_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural;
      Before_Fwd  : Natural;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Mark_Clean (S);
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Previous"));
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);

      Assert_Clipboard_State (True, "Beta",
                              "successful cut must publish only after deletion");
      Assert (Editor.State.Current_Text (S) = "Alpha  Gamma",
              "cut must delete the selected active-buffer text");
      Assert (Undo_Count = 1 and then Redo_Count = 0,
              "cut must create one undo entry and clear redo only after mutation");
      Assert (Editor.State.Is_Dirty (S),
              "cut must update dirty state through the canonical edit path");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "cut must invalidate Find/Replace through the canonical text-edit hook");
      Assert_No_Navigation_History_Change (S, Before_Back, Before_Fwd,
                                           "cut workflow");
      Assert (Active_Message_Text (S) = "Cut selection",
              "cut must emit one primary cut message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "undo after cut must restore the exact prior text");
      Assert_Clipboard_State (True, "Beta", "undo after cut");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "Alpha  Gamma",
              "redo after cut must reapply the deletion");
      Assert_Clipboard_State (True, "Beta", "redo after cut");
   end Test_Phase375_Cut_Atomicity_Dirty_Find_And_Undo_Redo;

   procedure Test_Phase375_Failed_Cut_Paste_Preserve_Redo_Clipboard_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("AB"));
      Reset_Transient_State;
      Set_Primary_Caret (S, 2);
      Editor.Executor.Execute_No_Log (S, Paste ("C"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "setup must leave redo available after undo");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Previous"));
      Set_Primary_Selection (S, 1, 99);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert
        (Active_Message_Text (S) = "Invalid selection",
         "failed cut must report invalid selection through command availability");
      Assert_Clipboard_State (True, "Previous",
                              "failed cut must preserve clipboard");
      Assert (Editor.State.Current_Text (S) = "AB",
              "failed cut must preserve buffer text");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "failed cut must preserve redo stack");

      Set_Primary_Selection (S, 1, 99);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Editor.Executor.Clipboard.Last_Status =
                Editor.Executor.Clipboard.Clipboard_Invalid_Selection,
              "failed paste must report invalid selection");
      Assert_Clipboard_State (True, "Previous",
                              "failed paste must preserve clipboard");
      Assert (Editor.State.Current_Text (S) = "AB",
              "failed paste must preserve buffer text");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
              "failed paste must preserve redo stack");
   end Test_Phase375_Failed_Cut_Paste_Preserve_Redo_Clipboard_Text;

   procedure Test_Phase375_Availability_Render_Snapshot_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Before_Text    : Unbounded_String;
      Before_Clip    : Unbounded_String;
      Before_Undo    : Natural;
      Before_Redo    : Natural;
      Before_Stale   : Boolean;
      A              : Editor.Commands.Command_Availability;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Clip"));
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Set_Primary_Selection (S, 6, 10);

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Undo := Undo_Count;
      Before_Redo := Redo_Count;
      Before_Stale := S.Active_Find_Stale;

      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (Editor.Commands.Is_Available (A),
              "copy availability must see the non-empty active selection");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Cut);
      Assert (Editor.Commands.Is_Available (A),
              "cut availability must see the non-empty active selection");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Paste);
      Assert (Editor.Commands.Is_Available (A),
              "paste availability must reflect Clipboard_Has_Text");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clipboard_Clear);
      Assert (Editor.Commands.Is_Available (A),
              "clipboard clear availability must reflect Clipboard_Has_Text");

      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "render and availability checks must not mutate buffer text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "render and availability checks must not extract or mutate clipboard text");
      Assert (Undo_Count = Before_Undo and then Redo_Count = Before_Redo,
              "render and availability checks must not mutate edit history");
      Assert (S.Active_Find_Stale = Before_Stale,
              "render and availability checks must not mutate Find/Replace state");
      Assert (Snapshot.Find_Visible and then Snapshot.Find_Match_Count = 1,
              "render snapshot must expose current Find ranges only when not stale");
   end Test_Phase375_Availability_Render_Snapshot_Side_Effect_Free;

   procedure Test_Phase375_Active_Buffer_Switch_Clipboard_Shared_History_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Buffer_A : Editor.Buffers.Buffer_Id;
   begin
      Reset_Transient_State;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      Buffer_A := Editor.Buffers.Global_Active_Buffer;

      Set_Primary_Selection (S, 0, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert_Clipboard_State (True, "Alpha", "copy before buffer switch");
      Assert (Undo_Count = 0,
              "copy in buffer A must not create an undo entry");

      Editor.Executor.Execute_New_Buffer (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Beta"));
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Primary_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert (Editor.State.Current_Text (S) = "BetaAlpha",
              "paste after active-buffer switch must mutate the new active buffer only");
      Assert_Clipboard_State (True, "Alpha",
                              "clipboard must survive active-buffer switches");
      Assert (Undo_Count = 1,
              "paste in buffer B must create buffer-local undo history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "Beta",
              "undo in buffer B must undo only the paste");

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Editor.State.Current_Text (S) = "Alpha",
              "buffer A must remain unchanged by buffer B paste");
   end Test_Phase375_Active_Buffer_Switch_Clipboard_Shared_History_Isolated;

   procedure Test_Phase375_Buffer_Close_Reopen_Clipboard_Survives
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Buffer_A : Editor.Buffers.Buffer_Id;
   begin
      Reset_Transient_State;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      Buffer_A := Editor.Buffers.Global_Active_Buffer;

      Set_Primary_Selection (S, 0, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert_Clipboard_State (True, "Alpha",
                              "clipboard populated before buffer close");

      Editor.Executor.Execute_New_Buffer (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Beta"));
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Close_Buffer (S, Buffer_A);
      Set_Primary_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert (Editor.State.Current_Text (S) = "BetaAlpha",
              "clipboard must remain pasteable after source buffer close");
      Assert_Clipboard_State (True, "Alpha",
                              "buffer close must not clear session clipboard");
      Assert (Undo_Count = 1,
              "paste after buffer close must create history only for active target buffer");

      null;
      Assert_Clipboard_State (True, "Alpha",
                              "buffer reopen must not restore or replace clipboard state");
   end Test_Phase375_Buffer_Close_Reopen_Clipboard_Survives;

   procedure Test_Phase375_Command_Palette_Route_Surface_Is_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Before_Text : Unbounded_String;
      Before_Clip : Unbounded_String;

      function Candidate_Available (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         if Candidates.Is_Empty then
            return False;
         end if;
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates.Element (I).Id = Id then
               return Candidates.Element (I).Available;
            end if;
         end loop;
         return False;
      end Candidate_Available;

      procedure Assert_Stable (Name : String; Expected : Editor.Commands.Command_Id) is
         Found : Boolean := False;
         Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (Found and then Id = Expected,
                 Name & " must resolve to the canonical clipboard command id");
      end Assert_Stable;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Clip"));
      Set_Primary_Selection (S, 0, 5);

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Clip := Editor.Clipboard.Get_Text;
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      Assert_Stable ("edit.copy", Editor.Commands.Command_Copy);
      Assert_Stable ("edit.cut", Editor.Commands.Command_Cut);
      Assert_Stable ("edit.paste", Editor.Commands.Command_Paste);
      Assert_Stable ("edit.clipboard.clear",
                     Editor.Commands.Command_Clipboard_Clear);
      Assert (Candidate_Available (Editor.Commands.Command_Copy),
              "command palette must project copy availability without extraction side effects");
      Assert (Candidate_Available (Editor.Commands.Command_Cut),
              "command palette must project cut availability without mutation");
      Assert (Candidate_Available (Editor.Commands.Command_Paste),
              "command palette must project paste availability from Clipboard_Has_Text");
      Assert (Candidate_Available (Editor.Commands.Command_Clipboard_Clear),
              "command palette must project clipboard.clear availability from Clipboard_Has_Text");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "command palette projection must not mutate active-buffer text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "command palette projection must not mutate clipboard text");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "command palette projection must not create or clear edit history");
   end Test_Phase375_Command_Palette_Route_Surface_Is_Canonical;

   procedure Test_Phase375_Feature_Independence_During_Clipboard_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                        : Editor.State.State_Type;
      Added                    : Boolean := False;
      Before_Goto_Text         : constant String := "42";
      Before_Quick_Query       : constant String := "quick token";
      Before_Project_Query     : constant String := "project token";
      Before_Switcher_Filter   : constant String := "buffer token";
      Before_Bookmark_Count    : Natural := 0;
      Before_Recent_Count      : Natural := 0;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Reset_Transient_State;

      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, Before_Goto_Text);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Before_Quick_Query);
      Editor.Project_Search.Set_Query (S.Project_Search, Before_Project_Query);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text
        (S.Buffer_Switcher, Before_Switcher_Filter);
      Editor.Bookmarks.Show (S.Bookmarks);
      Editor.Bookmarks.Toggle
        (S.Bookmarks, "alpha.adb", "alpha.adb", 1, 0, True, Added);
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, 17);
      Before_Bookmark_Count := Editor.Bookmarks.Count (S.Bookmarks);
      Before_Recent_Count := Editor.Recent_Buffers.Count (S.Recent_Buffers);

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Set_Primary_Caret (S, Natural (Editor.State.Current_Text (S)'Length));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clipboard_Clear);

      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = Before_Goto_Text,
              "clipboard commands must not mutate Go To Line state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = Before_Quick_Query,
              "clipboard commands must not mutate Quick Open state");
      Assert (Editor.Project_Search.Query (S.Project_Search) = Before_Project_Query,
              "clipboard commands must not mutate Project Search state");
      Assert (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) =
                Before_Switcher_Filter,
              "clipboard commands must not mutate Open Buffer Switcher filters");
      Assert (Editor.Bookmarks.Count (S.Bookmarks) = Before_Bookmark_Count
              and then Editor.Bookmarks.Is_Visible (S.Bookmarks),
              "clipboard commands must not mutate bookmarks or bookmark surface state");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = Before_Recent_Count,
              "clipboard commands must not update recent-buffer history");
   end Test_Phase375_Feature_Independence_During_Clipboard_Workflow;

   procedure Test_Phase375_Project_Lifecycle_Clears_Clipboard
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Execute_Open_Project (S, ".");
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Sensitive copied text"));
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Alpha");
      Assert (Editor.Clipboard.Has_Text,
              "setup must leave clipboard populated before lifecycle cleanup");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert_Clipboard_State (False, "",
                              "project lifecycle cleanup must clear clipboard");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Active_Message_Text (S) = "No active buffer."
              or else Active_Message_Text (S) = "Clipboard is empty",
              "paste after lifecycle cleanup must not restore clipboard text");
   end Test_Phase375_Project_Lifecycle_Clears_Clipboard;

   procedure Test_Phase375_Persistence_And_Non_Goal_Command_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snap    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Found   : Boolean := True;
      Id      : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Visible buffer text"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Sensitive copied text"));
      Set_Primary_Selection (S, 0, 7);
      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert (Ada.Strings.Unbounded.Index (Summary, "Sensitive copied text") = 0,
              "workspace snapshot debug summary must not contain clipboard text");
      Assert (Ada.Strings.Unbounded.Index (Summary, "Clipboard") = 0,
              "workspace snapshot debug summary must not contain clipboard fields");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.copy-line", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "copy-line must not be exposed as a Phase 375 command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.cut-line", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "cut-line must not be exposed as a Phase 375 command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.copy-rich", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "rich-text copy must not be exposed");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.paste-special", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "paste-special must not be exposed");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.paste-history", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "paste-history must not be exposed");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.system-clipboard.sync", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "system clipboard synchronization must not be exposed");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.clipboard.persist", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "persistent clipboard command must not be exposed");
   end Test_Phase375_Persistence_And_Non_Goal_Command_Exclusion;



   procedure Test_Phase375_Input_Bridge_Keybindings_Route_Clipboard_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;

      function Ctrl (Key : Editor.Keybindings.Key_Code)
        return Editor.Keybindings.Key_Chord
      is
      begin
         return Editor.Keybindings.Key_Chord'
           (Key       => Key,
            Modifiers =>
              (Ctrl  => True,
               Shift => False,
               Alt   => False,
               Meta  => False));
      end Ctrl;
   begin
      Reset_Transient_State;
      Editor.Keybindings.Bind
        (Ctrl (Editor.Keybindings.Key_C), Editor.Commands.Command_Copy);
      Editor.Keybindings.Bind
        (Ctrl (Editor.Keybindings.Key_X), Editor.Commands.Command_Cut);
      Editor.Keybindings.Bind
        (Ctrl (Editor.Keybindings.Key_V), Editor.Commands.Command_Paste);
      Editor.Keybindings.Bind
        (Ctrl (Editor.Keybindings.Key_L), Editor.Commands.Command_Clipboard_Clear);

      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Reset_Transient_State;
      Set_Primary_Selection (S, 6, 10);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Ctrl (Editor.Keybindings.Key_C));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Clipboard_State (True, "Beta",
                              "Input_Bridge copy keybinding route");
      Assert (Editor.State.Current_Text (After) = "Alpha Beta Gamma",
              "Input_Bridge copy route must not mutate buffer text locally");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "Input_Bridge copy route must not create edit history");

      Set_Primary_Selection (After, 6, 10);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Ctrl (Editor.Keybindings.Key_X));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (After) = "Alpha  Gamma",
              "Input_Bridge cut keybinding route must use canonical cut behavior");
      Assert_Clipboard_State (True, "Beta",
                              "Input_Bridge cut keybinding route");
      Assert (Undo_Count = 1,
              "Input_Bridge cut route must create exactly one canonical undo entry");

      Set_Primary_Caret (After, 6);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Ctrl (Editor.Keybindings.Key_V));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (After) = "Alpha Beta Gamma",
              "Input_Bridge paste keybinding route must use canonical paste behavior");
      Assert_Clipboard_State (True, "Beta",
                              "Input_Bridge paste keybinding route");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Ctrl (Editor.Keybindings.Key_L));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Clipboard_State (False, "",
                              "Input_Bridge clipboard.clear keybinding route");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase375_Input_Bridge_Keybindings_Route_Clipboard_Commands;

   procedure Test_Phase375_Clipboard_Commands_Emit_One_Primary_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Assert_Message_Count
        (Expected_Text : String;
         Why           : String)
      is
      begin
         Assert (Editor.Messages.Count (S.Messages) = 1,
                 Why & " must emit exactly one primary message");
         Assert (Active_Message_Text (S) = Expected_Text,
                 Why & " primary message text mismatch");
         Editor.Messages.Clear (S.Messages);
      end Assert_Message_Count;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Reset_Transient_State;

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert_Message_Count ("Copied selection", "copy");

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert_Message_Count ("Cut selection", "cut");

      Set_Primary_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert_Message_Count ("Pasted clipboard", "paste");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clipboard_Clear);
      Assert_Message_Count ("Clipboard cleared", "clipboard.clear");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert_Message_Count ("Clipboard is empty", "failed paste");
   end Test_Phase375_Clipboard_Commands_Emit_One_Primary_Message;

   procedure Test_Phase375_Dirty_Matrix_Copy_Clear_And_Noop_Paste
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta Gamma"));
      Mark_Clean (S);
      Reset_Transient_State;

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (not Editor.State.Is_Dirty (S),
              "copy must not dirty a clean buffer");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "copy must not change edit history in the dirty matrix");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Clipboard_Clear);
      Assert (not Editor.State.Is_Dirty (S),
              "clipboard.clear must not dirty a clean buffer");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "clipboard.clear must preserve edit history");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Beta"));
      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "no-op paste over identical selection must preserve buffer text");
      Assert (not Editor.State.Is_Dirty (S),
              "no-op paste over identical selection must not dirty a clean buffer");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "no-op paste over identical selection must preserve edit history");
      Assert_Clipboard_State (True, "Beta",
                              "no-op paste must preserve clipboard state");
   end Test_Phase375_Dirty_Matrix_Copy_Clear_And_Noop_Paste;

   procedure Test_Phase375_Paste_Invalidates_Find_And_Preserves_Replace_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha  Gamma"));
      Mark_Clean (S);
      Reset_Transient_State;

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Delta");
      Assert (not S.Active_Find_Stale
              and then S.Active_Find_Matches.Is_Empty
              and then S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Delta",
              "setup must have current Find state and populated Replace state");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Beta"));
      Set_Primary_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);

      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "paste must insert text before Find/Replace invalidation assertions");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "paste must invalidate or clear stale Find matches through the canonical text-edit hook");
      Assert (S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Delta"
              and then Length (S.Active_Replace_Error_Message) = 0,
              "paste invalidation must preserve Replace prompt text without corruption");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (not S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "undo after paste must recompute restored Find state without stale ranges");
      Assert (S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Delta",
              "undo after paste must not corrupt Replace text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (not S.Active_Find_Stale
              and then Natural (S.Active_Find_Matches.Length) = 1,
              "redo after paste must recompute Find state for restored pasted text");
      Assert (S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Delta",
              "redo after paste must not corrupt Replace text");
   end Test_Phase375_Paste_Invalidates_Find_And_Preserves_Replace_State;

   procedure Test_Phase376_Canonical_Clipboard_State_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Text : Unbounded_String;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("Alpha Beta"));
      Reset_Transient_State;

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Clip"));
      Assert_Clipboard_State (True, "Clip",
                              "Set_Text must populate only canonical text state");
      Editor.Clipboard.Set_Text (Null_Unbounded_String);
      Assert_Clipboard_State (False, "",
                              "empty Set_Text must canonicalize to an empty clipboard");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Clip"));
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Set_Primary_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) /= Before_Text,
              "paste availability and inserted text must come from canonical Clipboard_Has_Text/Text");
      Assert_Clipboard_State (True, "Clip",
                              "paste must not rewrite canonical clipboard state");
   end Test_Phase376_Canonical_Clipboard_State_Only;

   procedure Test_Phase376_Default_Keybindings_Target_Canonical_Clipboard_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Assert_Only_Canonical_Clipboard_Targets is
         Id   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
         Name : Unbounded_String := Null_Unbounded_String;
      begin
         if Editor.Keybindings.Bound_Command_Count > 0 then
            for I in 1 .. Editor.Keybindings.Bound_Command_Count loop
               Id := Editor.Keybindings.Bound_Command_At (I);
               Name := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
               if Ada.Strings.Unbounded.Index (Name, "copy") /= 0
                 or else Ada.Strings.Unbounded.Index (Name, "cut") /= 0
                 or else Ada.Strings.Unbounded.Index (Name, "paste") /= 0
                 or else Ada.Strings.Unbounded.Index (Name, "clipboard") /= 0
               then
                  Assert
                    (Id = Editor.Commands.Command_Copy
                     or else Id = Editor.Commands.Command_Cut
                     or else Id = Editor.Commands.Command_Paste
                     or else Id = Editor.Commands.Command_Clipboard_Clear,
                     To_String (Name) & " must be a canonical Clipboard command if bound");
               end if;
            end loop;
         end if;
      end Assert_Only_Canonical_Clipboard_Targets;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert_Only_Canonical_Clipboard_Targets;
   end Test_Phase376_Default_Keybindings_Target_Canonical_Clipboard_Commands;

   procedure Test_Phase376_Copy_Cut_Availability_Uses_Canonical_Selection_Helper
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Reset_Transient_State;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abcdef"));
      Reset_Transient_State;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("existing"));

      Set_Primary_Selection (S, 1, 4);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (Editor.Commands.Is_Available (A),
              "valid copy selection must be accepted by the canonical selection helper");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Cut);
      Assert (Editor.Commands.Is_Available (A),
              "valid cut selection must be accepted by the canonical selection helper");

      Set_Primary_Selection (S, 1, 99);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Commands.Is_Available (A),
              "out-of-range copy selection must be rejected before extraction");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Invalid selection",
              "copy must report the canonical invalid-selection reason");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Cut);
      Assert (not Editor.Commands.Is_Available (A),
              "out-of-range cut selection must be rejected before extraction");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Invalid selection",
              "cut must report the canonical invalid-selection reason");

      Assert_Clipboard_State (True, "existing",
                              "availability checks must not mutate canonical clipboard state");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "availability checks must not mutate edit history");
   end Test_Phase376_Copy_Cut_Availability_Uses_Canonical_Selection_Helper;

   procedure Test_Phase376_Local_Input_Paste_Reads_Canonical_Text_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Before_Status : Editor.Executor.Clipboard.Clipboard_Execution_Status;
      Text          : Unbounded_String;
   begin
      Reset_Transient_State;
      Editor.Executor.Clipboard.Clear_Status;
      Editor.Clipboard.Clear;

      Text := Editor.Executor.Clipboard.Text_For_Local_Input;
      Assert (Length (Text) = 0,
              "local input paste helper must return empty text when clipboard is empty");

      Editor.Clipboard.Set_Text (To_Unbounded_String ("Local paste"));
      Before_Status := Editor.Executor.Clipboard.Last_Status;
      Text := Editor.Executor.Clipboard.Text_For_Local_Input;

      Assert (To_String (Text) = "Local paste",
              "local input paste helper must read canonical Clipboard_Text only");
      Assert (Editor.Executor.Clipboard.Last_Status = Before_Status,
              "local input paste helper must not alter command status");
      Assert_Clipboard_State (True, "Local paste",
                              "local input paste helper must not mutate clipboard state");
      Assert (Undo_Count = 0 and then Redo_Count = 0,
              "local input paste helper must not mutate edit history");
   end Test_Phase376_Local_Input_Paste_Reads_Canonical_Text_Only;

   overriding procedure Register_Tests
     (T : in out Clipboard_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Command_Metadata'Access,
         "Phase 373 Clipboard Command Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Copy_Selected_Text_Only'Access,
         "Phase 373 Copy Selected Text Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_No_Selection_Copy_Is_Unavailable'Access,
         "Phase 373 No Selection Copy Unavailable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Cut_Undo_Redo'Access,
         "Phase 373 Cut Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Paste_At_Caret_And_Over_Selection'Access,
         "Phase 373 Paste At Caret And Over Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Paste_Identical_Selection_No_Edit'Access,
         "Phase 373 Paste Identical Selection No Edit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Empty_Clipboard_Availability'Access,
         "Phase 373 Empty Clipboard Availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Redo_Invalidation_Policies'Access,
         "Phase 373 Redo Invalidation Policies");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase373_Clipboard_Clear'Access,
         "Phase 373 Clipboard Clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Backward_Selection_Copy_Cut'Access,
         "Phase 374 Backward Selection Copy Cut");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Invalid_Selection_Is_Atomic'Access,
         "Phase 374 Invalid Selection Is Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase541_Multiline_Clipboard_Text_Is_Supported'Access,
         "Phase 374 Multiline Clipboard Policy Is Single Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Redo_Preserved_By_Non_Text_Clipboard_Commands'Access,
         "Phase 374 Redo Preserved By Non Text Clipboard Commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_No_Op_Paste_Preserves_Redo'Access,
         "Phase 374 No Op Paste Preserves Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Successful_Cut_Clears_Redo'Access,
         "Phase 374 Successful Cut Clears Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Failed_Paste_Preserves_Clipboard_And_Redo'Access,
         "Phase 374 Failed Paste Preserves Clipboard And Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase374_Clipboard_Independent_Of_Undo_Redo_Clear'Access,
         "Phase 374 Clipboard Independent Of Undo Redo Clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Copy_Workflow_Is_Non_Mutating'Access,
         "Phase 375 Copy Workflow Is Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Forward_Backward_Paste_Over_Selection'Access,
         "Phase 375 Forward Backward Paste Over Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Paste_At_Caret_Undo_Redo_And_Message'Access,
         "Phase 375 Paste At Caret Undo Redo And Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Cut_Atomicity_Dirty_Find_And_Undo_Redo'Access,
         "Phase 375 Cut Atomicity Dirty Find And Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Failed_Cut_Paste_Preserve_Redo_Clipboard_Text'Access,
         "Phase 375 Failed Cut Paste Preserve Redo Clipboard Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Availability_Render_Snapshot_Side_Effect_Free'Access,
         "Phase 375 Availability Render Snapshot Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Active_Buffer_Switch_Clipboard_Shared_History_Isolated'Access,
         "Phase 375 Active Buffer Switch Clipboard Shared History Isolated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Buffer_Close_Reopen_Clipboard_Survives'Access,
         "Phase 375 Buffer Close Reopen Clipboard Survives");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Command_Palette_Route_Surface_Is_Canonical'Access,
         "Phase 375 Command Palette Route Surface Is Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Feature_Independence_During_Clipboard_Workflow'Access,
         "Phase 375 Feature Independence During Clipboard Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Input_Bridge_Keybindings_Route_Clipboard_Commands'Access,
         "Phase 375 Input Bridge Keybindings Route Clipboard Commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Clipboard_Commands_Emit_One_Primary_Message'Access,
         "Phase 375 Clipboard Commands Emit One Primary Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Dirty_Matrix_Copy_Clear_And_Noop_Paste'Access,
         "Phase 375 Dirty Matrix Copy Clear And Noop Paste");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Paste_Invalidates_Find_And_Preserves_Replace_State'Access,
         "Phase 375 Paste Invalidates Find And Preserves Replace State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Project_Lifecycle_Clears_Clipboard'Access,
         "Phase 375 Project Lifecycle Clears Clipboard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase375_Persistence_And_Non_Goal_Command_Exclusion'Access,
         "Phase 375 Persistence And Non Goal Command Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase376_Canonical_Clipboard_State_Only'Access,
         "Phase 376 Canonical Clipboard State Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase376_Copy_Cut_Availability_Uses_Canonical_Selection_Helper'Access,
         "Phase 376 Copy Cut Availability Uses Canonical Selection Helper");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase376_Local_Input_Paste_Reads_Canonical_Text_Only'Access,
         "Phase 376 Local Input Paste Reads Canonical Text Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase376_Default_Keybindings_Target_Canonical_Clipboard_Commands'Access,
         "Phase 376 Default Keybindings Target Canonical Clipboard Commands");
   end Register_Tests;

end Editor.Clipboard.Tests;
