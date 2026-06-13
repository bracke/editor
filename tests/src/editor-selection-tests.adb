with AUnit.Assertions;  use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers;    use Ada.Containers;
with Editor.Commands;   use Editor.Commands;
with Editor.State;
with Editor.Executor;
with Editor.Test_Helper;
with Text_Buffer;
with Editor.Layout;
with Editor.Rectangle_Selection;
with Editor.Clipboard;
with Editor.History;
with Editor.Messages;
with Editor.Keybindings;
with Editor.Buffers;
with Editor.Command_Palette;
with Editor.Render_Model;

use type Editor.Keybindings.Binding_Result;

package body Editor.Selection.Tests is

   overriding function Name
     (T : Selection_Test_Case)
      return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Selection");
   end Name;

   function Paste (S : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String (S);
      return Cmd;
   end Paste;



   function Last_Message_Text
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
   end Last_Message_Text;

   procedure Test_Phase377_Selection_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Select_All) =
         "selection.select-all",
         "select-all must have stable persisted command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Selection_Clear) =
         "selection.clear",
         "clear-selection must have stable persisted command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Select_Word) =
         "selection.select-word",
         "select-word must have the canonical Phase 541 command name");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Select_All).Category =
         Editor.Commands.Selection_Category,
         "select-all belongs to the Selection category");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Select_All),
         "select-all must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Selection_Clear),
         "clear-selection must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Select_Word),
         "canonical select-word command must be bindable");
   end Test_Phase377_Selection_Command_Descriptors;




   procedure Test_Phase377_Default_Keybinding_Select_All
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.Keybindings.Reset_To_Defaults;

      Assert
        (Editor.Keybindings.Resolve
           ((Key => Editor.Keybindings.Key_A,
             Modifiers =>
               (Ctrl => True, Shift => False, Alt => False, Meta => False)),
            Actual) = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Select_All,
         "Phase 377 Ctrl+A must route to canonical select-all command id");
   end Test_Phase377_Default_Keybinding_Select_All;

   procedure Test_Phase377_Select_All_Command_Selects_Buffer_Without_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Undo_Count : Natural := 0;
      Redo_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.State.Set_Dirty (S, False);
      Undo_Count := Natural (Editor.History.Undo_Stack.Length);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);

      Assert (S.Carets (S.Carets.First_Index).Anchor = 0,
              "select-all anchor must be beginning of buffer");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "select-all caret must be end of buffer");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "abc",
              "select-all must not mutate text");
      Assert (not Editor.State.Is_Dirty (S),
              "select-all must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Count,
              "select-all must create no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "select-all must not clear redo entries");
      Assert (Last_Message_Text (S) = "Selected all",
              "select-all must report one deterministic message");
   end Test_Phase377_Select_All_Command_Selects_Buffer_Without_Edit;

   procedure Test_Phase377_Select_All_Then_Copy_Uses_Canonical_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcdef");
      Editor.Clipboard.Clear;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);

      Assert (Editor.Clipboard.Has_Text, "copy after select-all must populate clipboard");
      Assert (To_String (Editor.Clipboard.Get_Text) = "abcdef",
              "copy after select-all must copy the full buffer text");
   end Test_Phase377_Select_All_Then_Copy_Uses_Canonical_Selection;

   procedure Test_Phase377_Clear_Selection_Command_Collapses_At_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Undo_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abcdef");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 4, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.State.Set_Dirty (S, False);
      Undo_Count := Natural (Editor.History.Undo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);

      Assert (S.Carets (S.Carets.First_Index).Pos = 4,
              "clear-selection must preserve the active caret endpoint");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 4,
              "clear-selection must collapse to the caret endpoint");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "abcdef",
              "clear-selection must not mutate text");
      Assert (not Editor.State.Is_Dirty (S),
              "clear-selection must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Count,
              "clear-selection must create no undo entry");
      Assert (Last_Message_Text (S) = "Selection cleared",
              "clear-selection must report its command outcome");
   end Test_Phase377_Clear_Selection_Command_Collapses_At_Caret;

   procedure Test_Phase377_Current_Word_Selects_Strict_Ascii_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "xx Execute_Command Foo.Bar A_B2");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 5, Anchor => 5, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);

      Assert (S.Carets (S.Carets.First_Index).Anchor = 3,
              "current-word must anchor at token start");
      Assert (S.Carets (S.Carets.First_Index).Pos = 18,
              "current-word must place caret at token end");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "Execute_Command",
              "current-word then copy must copy exactly the selected token");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 23, Anchor => 23, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "Bar",
              "caret after Foo dot must select only Bar");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 27, Anchor => 27, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "A_B2",
              "current-word must include underscores and digits");
   end Test_Phase377_Current_Word_Selects_Strict_Ascii_Token;

   procedure Test_Phase377_Current_Word_Failure_Preserves_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc . def");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 3, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 4, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);

      Assert (S.Carets (S.Carets.First_Index).Anchor = 0
              and then S.Carets (S.Carets.First_Index).Pos = 4,
              "current-word failure on punctuation/space must preserve existing selection");
      Assert (Last_Message_Text (S) = "No selectable word at cursor",
              "current-word failure must report a deterministic no-op message");
   end Test_Phase377_Current_Word_Failure_Preserves_Selection;



   procedure Test_Phase378_Select_All_Empty_Buffer_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.Clipboard.Clear;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);

      Assert (S.Carets (S.Carets.First_Index).Anchor = 0
              and then S.Carets (S.Carets.First_Index).Pos = 0,
              "Phase 378 select-all on empty buffer must leave a valid empty range");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 378 empty buffer must not expose an active selection");
      Assert (Last_Message_Text (S) = "Nothing to select",
              "Phase 378 empty select-all must report deterministic no-op");
      Assert (not Editor.Clipboard.Has_Text,
              "Phase 378 select-all must not mutate clipboard text");
   end Test_Phase378_Select_All_Empty_Buffer_Is_No_Op;

   procedure Test_Phase378_Current_Word_EOF_And_Punctuation_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run(); Execute_Command A_B2");
      Editor.Clipboard.Clear;

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Assert (Last_Message_Text (S) = "No selectable word at cursor",
              "Phase 378 caret on punctuation must not select preceding word");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 13, Anchor => 13, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "Execute_Command",
              "Phase 378 underscore token must be copied exactly after current-word");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 27, Anchor => 27, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "A_B2",
              "Phase 378 EOF caret must select the preceding token only");
   end Test_Phase378_Current_Word_EOF_And_Punctuation_Boundaries;

   procedure Test_Phase378_Invalid_Stale_Selection_Is_Not_Consumable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 99, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 378 invalid stale range must not be reported as a selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "old",
              "Phase 378 copy must not consume invalid stale selection text");
      Assert (Last_Message_Text (S) = "Invalid selection"
              or else Last_Message_Text (S) = "No selected text",
              "Phase 378 invalid stale copy must fail deterministically");
   end Test_Phase378_Invalid_Stale_Selection_Is_Not_Consumable;

   procedure Test_Phase378_Clear_Selection_Preserves_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 378 precondition: undo must leave one redo entry");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 1, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);

      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 378 clear-selection must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 378 redo must still work after a selection-only command");
   end Test_Phase378_Clear_Selection_Preserves_Redo;

   procedure Test_Phase378_Select_All_Does_Not_Leak_Across_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Buffer_A : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Buffer_A := Editor.Buffers.Global_Active_Buffer;
      Editor.Clipboard.Clear;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_New_Buffer (S);
      Editor.State.Load_Text (S, "Beta");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Clipboard.Has_Text,
              "Phase 378 copy in Buffer B must not consume Buffer A selection");
      Assert (Last_Message_Text (S) = "No selected text",
              "Phase 378 Buffer B copy must use Buffer B selection only");

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Editor.State.Current_Text (S) = "Alpha",
              "Phase 378 Buffer A text must remain isolated after Buffer B copy");
   end Test_Phase378_Select_All_Does_Not_Leak_Across_Buffers;

   procedure Test_Phase378_Current_Word_Feeds_Find_From_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha Beta_2 alpha");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 8, Anchor => 8, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Find_From_Selection);

      Assert (To_String (S.Active_Find_Query) = "Beta_2",
              "Phase 378 find-from-selection must consume exact current-word selection text");
   end Test_Phase378_Current_Word_Feeds_Find_From_Selection;



   function Command_With_Text
     (Kind : Editor.Commands.Command_Kind;
      Text : String) return Editor.Commands.Command
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Kind;
      Cmd.Text := To_Unbounded_String (Text);
      return Cmd;
   end Command_With_Text;

   procedure Assert_Primary_Range
     (S      : Editor.State.State_Type;
      Anchor : Natural;
      Pos    : Natural;
      Why    : String)
   is
   begin
      Assert (S.Carets.Length > 0, Why & ": expected a primary caret");
      Assert (Natural (S.Carets (S.Carets.First_Index).Anchor) = Anchor,
              Why & ": wrong selection anchor");
      Assert (Natural (S.Carets (S.Carets.First_Index).Pos) = Pos,
              Why & ": wrong selection caret position");
   end Assert_Primary_Range;

   function Selected_Text_By_Copy
     (S : in out Editor.State.State_Type) return String
   is
   begin
      Editor.Clipboard.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      if Editor.Clipboard.Has_Text then
         return To_String (Editor.Clipboard.Get_Text);
      else
         return "";
      end if;
   end Selected_Text_By_Copy;

   procedure Assert_Selection_Command_No_Edit_Effects
     (S           : Editor.State.State_Type;
      Before_Text : String;
      Before_Dirty : Boolean;
      Before_Undo : Natural;
      Before_Redo : Natural;
      Before_Clipboard_Has_Text : Boolean;
      Before_Clipboard_Text : String;
      Why         : String)
   is
   begin
      Assert (Editor.State.Current_Text (S) = Before_Text,
              Why & ": selection command must not mutate buffer text");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              Why & ": selection command must not mutate dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              Why & ": selection command must not create undo entries");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              Why & ": selection command must not clear redo entries");
      Assert (Editor.Clipboard.Has_Text = Before_Clipboard_Has_Text,
              Why & ": selection command must not mutate clipboard presence");
      if Before_Clipboard_Has_Text then
         Assert (To_String (Editor.Clipboard.Get_Text) = Before_Clipboard_Text,
                 Why & ": selection command must not mutate clipboard text");
      end if;
   end Assert_Selection_Command_No_Edit_Effects;

   procedure Test_Phase379_Select_All_Current_Text_And_Clipboard_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Undo : Natural;
      Before_Redo : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, True);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);

      Assert_Primary_Range (S, 0, 16,
                            "Phase 379 select-all must cover current in-memory text");
      Assert (Selected_Text_By_Copy (S) = "Alpha Beta Gamma",
              "Phase 379 copy must consume the canonical select-all range");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 379 select-all and copy must create no undo entries");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 379 select-all and copy must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 379 select-all/copy must not clean a dirty buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert (Editor.State.Current_Text (S) = "",
              "Phase 379 cut after select-all must delete exactly the selected buffer text");
      Assert (To_String (Editor.Clipboard.Get_Text) = "Alpha Beta Gamma",
              "Phase 379 cut must publish the pre-cut full selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo + 1,
              "Phase 379 cut must be the only undoable operation in the workflow");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "Phase 379 undo must restore text removed by select-all cut");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "",
              "Phase 379 redo must reapply the select-all cut");
   end Test_Phase379_Select_All_Current_Text_And_Clipboard_Workflow;

   procedure Test_Phase379_Select_All_Paste_Replace_And_No_Op_Preserves_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Redo_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Replacement"));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Editor.State.Current_Text (S) = "Replacement",
              "Phase 379 paste over select-all must replace the full active selection");
      Assert (To_String (Editor.Clipboard.Get_Text) = "Replacement",
              "Phase 379 paste must not consume or mutate clipboard text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 379 paste-over-selection must create exactly one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "Phase 379 undo must restore the full pre-paste buffer");
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("Alpha Beta Gamma"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Editor.State.Current_Text (S) = "Alpha Beta Gamma",
              "Phase 379 no-op paste over identical select-all text must leave buffer unchanged");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 379 no-op paste must preserve redo after a selection command");
   end Test_Phase379_Select_All_Paste_Replace_And_No_Op_Preserves_Redo;

   procedure Test_Phase379_Clear_Selection_Workflow_And_Caret_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Undo : Natural;
      Before_Redo : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("X"));
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 5, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);

      Assert_Primary_Range (S, 5, 5,
                            "Phase 379 clear-selection must collapse to the caret endpoint");
      Assert_Selection_Command_No_Edit_Effects
        (S, "Alpha Beta", False, Before_Undo, Before_Redo, True, "X",
         "Phase 379 clear-selection");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "X",
              "Phase 379 copy after clear-selection must not replace clipboard text");
      Assert (Last_Message_Text (S) = "No selected text",
              "Phase 379 copy after clear-selection must report no selected text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Editor.State.Current_Text (S) = "AlphaX Beta",
              "Phase 379 paste after clear-selection must insert at caret, not replace the old selection");
   end Test_Phase379_Clear_Selection_Workflow_And_Caret_Insert;

   procedure Test_Phase379_Current_Word_Boundary_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Execute_Command A_B2 Foo.Bar Run(); x 123abc abc123 snake_case_42 leading trailing");
      Editor.Clipboard.Clear;

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Selected_Text_By_Copy (S) = "Execute_Command",
              "Phase 379 current-word at token start must include underscore token");

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 18, Anchor => 18, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Selected_Text_By_Copy (S) = "A_B2",
              "Phase 379 current-word on digit/underscore token must select A_B2");

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 24, Anchor => 24, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Selected_Text_By_Copy (S) = "Foo",
              "Phase 379 current-word before dot must select only Foo");

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 28, Anchor => 28, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Selected_Text_By_Copy (S) = "Bar",
              "Phase 379 current-word after dot must select only Bar");

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 34, Anchor => 34, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Last_Message_Text (S) = "No selectable word at cursor",
              "Phase 379 current-word on semicolon/punctuation must fail deterministically");

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 56, Anchor => 56, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (Selected_Text_By_Copy (S) = "snake_case_42",
              "Phase 379 current-word must preserve full snake_case_42 token");
   end Test_Phase379_Current_Word_Boundary_Matrix;

   procedure Test_Phase379_Current_Word_Clipboard_Cut_Paste_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "call Execute_Command;");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 8, Anchor => 8, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "Execute_Command",
              "Phase 379 copy must consume exact current-word selection");
      Assert (Editor.State.Current_Text (S) = "call Execute_Command;",
              "Phase 379 copy must not mutate current-word source text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 379 current-word and copy must not create undo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert (Editor.State.Current_Text (S) = "call ;",
              "Phase 379 cut must delete only the current-word token");
      Assert (To_String (Editor.Clipboard.Get_Text) = "Execute_Command",
              "Phase 379 current-word cut must keep token in clipboard");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 379 current-word cut must create exactly one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Editor.State.Current_Text (S) = "call Execute_Command;",
              "Phase 379 undo must restore current-word cut token");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "call ;",
              "Phase 379 redo must reapply current-word cut token deletion");
   end Test_Phase379_Current_Word_Clipboard_Cut_Paste_Workflow;

   procedure Test_Phase379_Selection_Feeds_Find_And_Does_Not_Mutate_Replace
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Beta Gamma");
      S.Active_Replace_Text := To_Unbounded_String ("Gamma");
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 8, Anchor => 8, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Assert (To_String (S.Active_Find_Query) = "",
              "Phase 379 select-word must not mutate Find state directly");
      Assert (To_String (S.Active_Replace_Text) = "Gamma",
              "Phase 379 select-word must not mutate Replace text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Find_From_Selection);
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 379 find-from-selection must consume canonical current selection");
      Assert (To_String (S.Active_Replace_Text) = "Gamma",
              "Phase 379 find-from-selection must not disturb Replace text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Find_From_Selection);
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 379 failed find-from-selection after clear must preserve Find query");
      Assert (Last_Message_Text (S) = "No selected text",
              "Phase 379 failed find-from-selection after clear must report no selected text");
   end Test_Phase379_Selection_Feeds_Find_And_Does_Not_Mutate_Replace;

   procedure Test_Phase379_Selection_With_Replace_And_Edit_Invalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Beta Gamma");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_No_Log
        (S, Command_With_Text (Editor.Commands.Active_Find_Query_Set, "Beta"));
      Editor.Executor.Execute_No_Log
        (S, Command_With_Text (Editor.Commands.Active_Replace_Text_Set, "Delta"));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 379 select-all must not mutate Find query before Replace");
      Assert (To_String (S.Active_Replace_Text) = "Delta",
              "Phase 379 select-all must not mutate Replace text before Replace");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Replace_All);
      Assert (Editor.State.Current_Text (S) = "Alpha Delta Delta Gamma",
              "Phase 379 replace-all must operate from Find state, not active selection text");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 379 selection must be validly cleared/collapsed after replace-all edit invalidation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 379 replace-all, not selection commands, must create the undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Last_Message_Text (S) = "No selected text",
              "Phase 379 copy after replace invalidation must not extract stale select-all text");
   end Test_Phase379_Selection_With_Replace_And_Edit_Invalidation;

   procedure Test_Phase379_Active_Buffer_Isolation_And_Reopen_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Buffer_A : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Buffer_A := Editor.Buffers.Global_Active_Buffer;
      Editor.Clipboard.Clear;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_New_Buffer (S);
      Editor.State.Load_Text (S, "Beta");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Clipboard.Has_Text,
              "Phase 379 Buffer B copy must not consume Buffer A selection");
      Assert (Last_Message_Text (S) = "No selected text",
              "Phase 379 Buffer B without selection must report no selected text");

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_A);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Clipboard.Has_Text,
              "Phase 379 Buffer A clear-selection must affect only Buffer A and leave no copyable stale selection");
   end Test_Phase379_Active_Buffer_Isolation_And_Reopen_Cleanup;

   procedure Test_Phase379_Selection_Commands_Preserve_Redo_And_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Redo_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_No_Log (S, Paste ("B"));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Assert (Redo_Count = 1, "Phase 379 precondition: undo leaves redo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);

      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 379 selection commands must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 379 redo must remain available after selection-only commands");
   end Test_Phase379_Selection_Commands_Preserve_Redo_And_Navigation_History;

   procedure Test_Phase379_Availability_And_Palette_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text : constant String := "Alpha";
      Before_Clip : constant String := "clip";
      A : Editor.Commands.Command_Availability;
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      Editor.Clipboard.Set_Text (To_Unbounded_String (Before_Clip));
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(Pos => 5, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 379 copy availability should see the valid active selection");
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Select_Word);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 379 current-word availability may be broad but must be side-effect free");
      Editor.Command_Palette.Filtered_Commands (Filtered);
      Assert (Filtered.Length > 0,
              "Phase 379 palette filter should return visible command descriptors");

      Assert_Primary_Range (S, 0, 5,
                            "Phase 379 availability/palette must not mutate selection range");
      Assert (Editor.State.Current_Text (S) = Before_Text,
              "Phase 379 availability/palette must not mutate text");
      Assert (To_String (Editor.Clipboard.Get_Text) = Before_Clip,
              "Phase 379 availability/palette must not mutate clipboard text");
   end Test_Phase379_Availability_And_Palette_Are_Side_Effect_Free;

   procedure Test_Phase379_Non_Goal_Selection_Commands_Are_Not_Exposed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.selection.expand", Found);
      Assert ((not Found) and then Id = Editor.Commands.No_Command,
              "Phase 379 must not expose selection expansion command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.selection.block", Found);
      Assert ((not Found) and then Id = Editor.Commands.No_Command,
              "Phase 379 must not expose block selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.selection.multi-cursor.add", Found);
      Assert ((not Found) and then Id = Editor.Commands.No_Command,
              "Phase 379 must not expose multi-cursor selection command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.copy-line", Found);
      Assert ((not Found) and then Id = Editor.Commands.No_Command,
              "Phase 379 must not expose copy-line without selection");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.cut-line", Found);
      Assert ((not Found) and then Id = Editor.Commands.No_Command,
              "Phase 379 must not expose cut-line without selection");
   end Test_Phase379_Non_Goal_Selection_Commands_Are_Not_Exposed;


   procedure Test_Phase380_Command_Palette_Projects_Canonical_Selection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Candidates : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Select_All_Count    : Natural := 0;
      Clear_Count         : Natural := 0;
      Select_Word_Count   : Natural := 0;
   begin
      Editor.Command_Palette.Filtered_Commands (Candidates);

      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Select_All then
            Select_All_Count := Select_All_Count + 1;
         elsif C.Id = Editor.Commands.Command_Selection_Clear then
            Clear_Count := Clear_Count + 1;
         elsif C.Id = Editor.Commands.Command_Select_Word then
            Select_Word_Count := Select_Word_Count + 1;
         end if;
      end loop;

      Assert (Select_All_Count = 1,
              "Phase 380 palette must expose exactly one canonical select-all row");
      Assert (Clear_Count = 1,
              "Phase 380 palette must expose exactly one canonical clear-selection row");
      Assert (Select_Word_Count = 1,
              "Phase 541 palette must expose exactly one canonical select-word row");
   end Test_Phase380_Command_Palette_Projects_Canonical_Selection_Only;

   procedure Test_Phase380_Canonical_Selection_Validation_And_Extraction
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : Editor.Selection.Selection_Validation_Status;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 6, Anchor => 10, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Status := Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Assert (Status = Editor.Selection.Selection_Ok,
              "Phase 380 backward selection must validate canonically");
      Assert (Natural (Selection_Range.Low) = 6 and then Natural (Selection_Range.High) = 10,
              "Phase 380 canonical validation must normalize backward ranges");
      Assert (To_String (Editor.Selection.Extract_Selected_Text (S)) = "Beta",
              "Phase 380 canonical extraction must read active-buffer text only");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Status := Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Assert (Status = Editor.Selection.Selection_Empty,
              "Phase 380 collapsed range is no selected text");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 99, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Status := Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Assert (Status = Editor.Selection.Selection_Invalid,
              "Phase 380 out-of-range selection is invalid and not consumable");
      Assert (Length (Editor.Selection.Extract_Selected_Text (S)) = 0,
              "Phase 380 invalid selection extraction must return no text");
   end Test_Phase380_Canonical_Selection_Validation_And_Extraction;

   procedure Test_Phase380_Clipboard_And_Find_Consume_Canonical_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 10, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "Beta",
              "Phase 380 copy must consume canonical normalized active selection");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Find_From_Selection);
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 380 find-from-selection must consume canonical selected text");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 99, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Clipboard.Set_Text (To_Unbounded_String ("old"));
      S.Active_Find_Query := To_Unbounded_String ("old-query");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (To_String (Editor.Clipboard.Get_Text) = "old",
              "Phase 380 invalid canonical selection must not replace clipboard text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Find_From_Selection);
      Assert (To_String (S.Active_Find_Query) = "old-query",
              "Phase 380 invalid canonical selection must not replace Find query");
   end Test_Phase380_Clipboard_And_Find_Consume_Canonical_Selection;

   procedure Test_Phase380_Select_All_And_Current_Word_Use_Canonical_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Selection_Range : Editor.Selection.Active_Selection_Range;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Foo.Bar snake_case_42");
      Selection_Range := Editor.Selection.Select_All_Range_For_Buffer (S);
      Assert (Natural (Selection_Range.Low) = 0 and then Natural (Selection_Range.High) = 21,
              "Phase 380 select-all helper must cover current in-memory text");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Selection_Range := Editor.Selection.Current_Word_Range_At_Caret (S, Found);
      Assert (Found and then Natural (Selection_Range.Low) = 4 and then Natural (Selection_Range.High) = 7,
              "Phase 380 current-word helper must stop at dotted-name boundary");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 8, Anchor => 8, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Selection_Range := Editor.Selection.Current_Word_Range_At_Caret (S, Found);
      Assert (Found and then Natural (Selection_Range.Low) = 8 and then Natural (Selection_Range.High) = 21,
              "Phase 380 current-word helper must use [A-Za-z0-9_] token policy");
   end Test_Phase380_Select_All_And_Current_Word_Use_Canonical_Helpers;


   procedure Test_Phase380_Secondary_And_Invalid_Ranges_Are_Not_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Render_Model.Render_Snapshot;
      A        : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'(Pos => 6, Anchor => 10, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 380 copy availability must ignore secondary previous selection ranges");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 380 canonical has-selection must use primary active selection only");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Selection_Count = 0,
              "Phase 380 render snapshot must ignore secondary previous selection ranges");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 99, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Copy);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 380 copy availability must reject invalid canonical selection ranges");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Selection_Count = 0,
              "Phase 380 render snapshot must not expose invalid stale selection ranges");
   end Test_Phase380_Secondary_And_Invalid_Ranges_Are_Not_Canonical;

   procedure Test_Start_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'a'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Assert (S.Carets (0).Anchor /= S.Carets (0).Pos, "Selection active");
      Assert (S.Carets (0).Anchor = 1, "Anchor captured");
      Assert (S.Carets (0).Pos = 0, "End follows caret");
   end Test_Start_Selection;

   procedure Test_Extend_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Assert (S.Carets (0).Anchor /= S.Carets (0).Pos, "Selection active");
      Assert (S.Carets (0).Anchor = 2, "Anchor stable");
      Assert (S.Carets (0).Pos = 0, "End equals caret");
   end Test_Extend_Selection;

   procedure Test_Reverse_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Assert (S.Carets (0).Anchor /= S.Carets (0).Pos, "Selection active");
      Assert (S.Carets (0).Anchor = 2, "Anchor unchanged");
      Assert (S.Carets (0).Pos < S.Carets (0).Anchor,
              "Selection may cross anchor");
   end Test_Reverse_Selection;

   procedure Test_Collapse_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => False));

      Assert (S.Carets (0).Anchor = S.Carets (0).Pos, "Selection collapsed");
   end Test_Collapse_Selection;

   procedure Test_Replace_Selection_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Assert (Text_Buffer.Length (S.Buffer) = 2,
              "Replace shrinks buffer");
      Assert (S.Carets (0).Anchor = S.Carets (0).Pos,
              "Selection collapsed after replace");
   end Test_Replace_Selection_Insert;

   procedure Test_Delete_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Delete (0));

      Assert (Text_Buffer.Length (S.Buffer) = 1,
              "Delete removes span");
      Assert (S.Carets (0).Anchor = S.Carets (0).Pos,
              "Selection collapsed");
   end Test_Delete_Selection;

   procedure Test_Undo_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'a'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);

      Assert (S.Carets (0).Anchor /= S.Carets (0).Pos,
              "Undo restores snapshot");
      Assert (S.Carets (0).Anchor = 1, "Anchor restored");
      Assert (S.Carets (0).Pos = 0, "End restored");
   end Test_Undo_Selection;

   procedure Test_Rectangle_Selection_Creates_One_Caret_Per_Line
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abcd" & ASCII.LF & "efgh" & ASCII.LF & "ijkl"));

      Cmd.Kind := Editor.Commands.Start_Rectangle_Selection;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1) + Editor.Layout.Cell_W;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Drag_Rectangle_To_Point;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1) + 3 * Editor.Layout.Cell_W;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 2 * Editor.Layout.Cell_H;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Carets.Length = 3,
            "Rectangle selection must create one caret per touched line");

      for C of S.Carets loop
         Assert (C.Anchor /= C.Pos,
               "Each rectangle caret must represent a selection span");
      end loop;
   end Test_Rectangle_Selection_Creates_One_Caret_Per_Line;

   procedure Test_Rectangle_Insert_Replaces_Per_Line
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      --  "abcd\nefgh\nijkl"
      Editor.Executor.Execute_No_Log
      (S, Paste ("abcd" & ASCII.LF &
                  "efgh" & ASCII.LF &
                  "ijkl"));

      --  Select columns 1..3 on each line:
      --  abcd  => select "bc"  indices 1..3
      --  efgh  => select "fg"  indices 6..8
      --  ijkl  => select "jk"  indices 11..13
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 1,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      S.Carets.Append (Caret_State'(
         Pos => 8,
         Anchor => 6,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      S.Carets.Append (Caret_State'(
         Pos => 13,
         Anchor => 11,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Insert (0, 'X'));

      --  Expected: "aXd\neXh\niXl"
      Assert (Text_Buffer.Length (S.Buffer) = 11,
            "Rectangle replace length failed");

      Assert (Text_Buffer.Element (S.Buffer, 1) = 'a', "line1 start");
      Assert (Text_Buffer.Element (S.Buffer, 2) = 'X', "line1 replacement");
      Assert (Text_Buffer.Element (S.Buffer, 3) = 'd', "line1 end");

      Assert (Text_Buffer.Element (S.Buffer, 5) = 'e', "line2 start");
      Assert (Text_Buffer.Element (S.Buffer, 6) = 'X', "line2 replacement");
      Assert (Text_Buffer.Element (S.Buffer, 7) = 'h', "line2 end");

      Assert (Text_Buffer.Element (S.Buffer, 9) = 'i', "line3 start");
      Assert (Text_Buffer.Element (S.Buffer, 10) = 'X', "line3 replacement");
      Assert (Text_Buffer.Element (S.Buffer, 11) = 'l', "line3 end");
   end Test_Rectangle_Insert_Replaces_Per_Line;

   procedure Test_Rectangle_Paste_Per_Line
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      --  "abcd\nefgh"
      Editor.Executor.Execute_No_Log
      (S, Paste ("abcd" & ASCII.LF &
                  "efgh"));

      --  Zero-width rectangle carets at start of both lines.
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 0,
         Anchor => 0,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      S.Carets.Append (Caret_State'(
         Pos => 5,
         Anchor => 5,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Editor.Executor.Execute_No_Log (S, Paste ("Z"));

      --  Expected: "Zabcd\nZefgh"
      Assert (Text_Buffer.Length (S.Buffer) = 11,
            "Rectangle paste length failed");

      Assert (Text_Buffer.Element (S.Buffer, 1) = 'Z', "line1");
      Assert (Text_Buffer.Element (S.Buffer, 7) = 'Z', "line2");
   end Test_Rectangle_Paste_Per_Line;

   procedure Test_Rectangle_Undo_Restores_All_Lines
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("abcd" & ASCII.LF & "efgh"));

      Cmd.Kind := Editor.Commands.Start_Rectangle_Selection;
      Cmd.Click_X := 8;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Drag_Rectangle_To_Point;
      Cmd.Click_X := 16;
      Cmd.Click_Y := 20;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Insert (0, 'X'));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);

      Assert (Text_Buffer.Length (S.Buffer) = 9,
            "Undo must restore original text");
   end Test_Rectangle_Undo_Restores_All_Lines;

   procedure Test_Virtual_Column_Paste
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));

      Editor.Executor.Execute_No_Log (S, Paste ("X"));

      Assert (Text_Buffer.Length (S.Buffer) = 6,
            "Virtual column paste length failed");

      Assert (Text_Buffer.Element (S.Buffer, 4) = ' ',
            "First padding space");

      Assert (Text_Buffer.Element (S.Buffer, 5) = ' ',
            "Second padding space");

      Assert (Text_Buffer.Element (S.Buffer, 6) = 'X',
            "Inserted character");
   end Test_Virtual_Column_Paste;

   procedure Test_Virtual_Column_Insert_Text_Input
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      S.Carets.Clear;
      S.Carets.Append
      (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Insert (0, 'X'));

      Assert (Text_Buffer.Length (S.Buffer) = 4,
            "Canonical text input must not materialize virtual-column padding");

      Assert (Text_Buffer.Element (S.Buffer, 4) = 'X',
            "Canonical text input inserts at the physical caret");

      Assert (S.Carets.Length = 1,
            "Canonical text input preserves a single caret");

      Assert (S.Carets (S.Carets.First_Index).Virtual_Column = 0,
            "Canonical text input clears virtual-column insertion state");
   end Test_Virtual_Column_Insert_Text_Input;

   procedure Test_Multi_Caret_Virtual_Column_Insert_Text_Input
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("abc" & ASCII.LF & "de"));

      --  End of first line at physical pos 3, virtual col 5.
      --  End of second line at physical pos 6, virtual col 5.
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));
      S.Carets.Append (Caret_State'(
         Pos => 6,
         Anchor => 6,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Insert (0, 'X'));

      --  Phase 413 removed removed all-caret insertion.  The canonical text
      --  insert path accepts only one active-buffer caret and rejects the
      --  former virtual-column multi-caret insertion model.
      Assert (Text_Buffer.Length (S.Buffer) = 6,
            "Canonical text input must reject multi-caret virtual insertion");

      Assert (Text_Buffer.Element (S.Buffer, 4) = ASCII.LF,
            "Rejected multi-caret insertion must preserve the original text");

      Assert (S.Carets.Length = 1,
            "Rejected multi-caret insertion normalizes to one canonical caret");
   end Test_Multi_Caret_Virtual_Column_Insert_Text_Input;

   procedure Test_Move_Right_Creates_Virtual_Column
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      Assert (S.Carets (0).Pos = 3,
            "Precondition: paste leaves caret at physical EOL");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Right);

      Assert (S.Carets (0).Pos = 3,
            "Virtual movement must not move physical position");

      Assert (S.Carets (0).Virtual_Column = 4,
            "Move_Right at EOL must enter virtual column 4");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Right);

      Assert (S.Carets (0).Virtual_Column = 5,
            "Second virtual Move_Right must advance virtual column");
   end Test_Move_Right_Creates_Virtual_Column;

   procedure Test_Move_Left_Leaves_Virtual_Column
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      --  enter virtual column 5
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Right);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Right);

      Assert (S.Carets (0).Virtual_Column = 5,
            "Precondition: must be in virtual column 5");

      --  step back inside virtual space
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);

      Assert (S.Carets (0).Virtual_Column = 4,
            "Move_Left must decrease virtual column");

      --  leave virtual space
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);

      Assert (S.Carets (0).Virtual_Column = 0,
            "Move_Left must exit virtual space");

      Assert (S.Carets (0).Pos = 3,
            "Caret must be at physical EOL");

      --  now normal movement
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);

      Assert (S.Carets (0).Pos = 2,
            "Move_Left must move physically after leaving virtual space");
   end Test_Move_Left_Leaves_Virtual_Column;

   procedure Test_Move_Down_Preserves_Virtual_Column
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("abc" & ASCII.LF & "de"));

      --  Paste leaves caret at end of second line.
      --  Move home/end setup manually to first line EOL for clarity.
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos            => 3,
         Anchor         => 3,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));

      S.Preferred_Column := 5;

      declare
         Cmd : Editor.Commands.Command;
      begin
         Cmd.Kind := Editor.Commands.Move_Down;
         Editor.Executor.Execute_No_Log (S, Cmd);
      end;

      Assert (S.Carets (0).Pos = 6,
            "Move_Down must clamp physical position to second-line EOL");

      Assert (S.Carets (0).Virtual_Column = 5,
            "Move_Down must preserve virtual column on shorter line");
   end Test_Move_Down_Preserves_Virtual_Column;

   procedure Test_Move_Up_Preserves_Virtual_Column
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
      (S, Paste ("abc" & ASCII.LF & "de"));

      --  place caret on second line, virtual column 5
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 6,
         Anchor => 6,
         Virtual_Column => 5,
         Anchor_Virtual_Column => 0
      ));

      S.Preferred_Column := 5;

      Cmd.Kind := Editor.Commands.Move_Up;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Carets (0).Pos = 3,
            "Move_Up must clamp to first-line EOL");

      Assert (S.Carets (0).Virtual_Column = 5,
            "Move_Up must preserve virtual column");
   end Test_Move_Up_Preserves_Virtual_Column;

   procedure Test_Virtual_Selection_Extends
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      --  move to virtual column 4
      Cmd.Kind := Editor.Commands.Move_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);

      --  start selection into virtual column 5
      Cmd.Shift := True;
      Editor.Executor.Execute_No_Log (S, Cmd);

      declare
         C : constant Caret_State := S.Carets (0);
      begin
         Assert (C.Virtual_Column = 5,
               "Caret must be in virtual column 5");

         Assert (C.Anchor_Virtual_Column = 4,
               "Anchor must be at virtual column 4");

         Assert (C.Pos = C.Anchor,
               "Physical position must be equal");
      end;
   end Test_Virtual_Selection_Extends;


   procedure Test_Rectangle_Normalize_Up_Left
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      R : constant Editor.Rectangle_Selection.Rectangle_Range :=
        Editor.Rectangle_Selection.Normalize
          (Anchor_Row => 5,
           Anchor_Col => 9,
           Cursor_Row => 2,
           Cursor_Col => 3);
   begin
      Assert (R.First_Row = 2, "First row normalized");
      Assert (R.Last_Row = 5, "Last row normalized");
      Assert (R.First_Col = 3, "First column normalized");
      Assert (R.Last_Col = 9, "Last column normalized");
   end Test_Rectangle_Normalize_Up_Left;

   procedure Test_Phase373_Rectangle_Copy_Uses_Primary_Plain_Text
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
      R : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
        (S, Paste ("abcd" & ASCII.LF & "e" & ASCII.LF & "ijk"));

      R := Editor.Rectangle_Selection.Normalize
        (Anchor_Row => 0,
         Anchor_Col => 1,
         Cursor_Row => 2,
         Cursor_Col => 3);
      S.Rect_Select_Active := True;
      Editor.Rectangle_Selection.Build_Carets (S, R);

      Editor.Executor.Execute_No_Log
        (S, (Kind => Editor.Commands.Copy_Selection, others => <>));

      Assert (To_String (Editor.Clipboard.Get_Text) = "bc",
              "Phase 373 copy command must use the primary plain selected text only");
   end Test_Phase373_Rectangle_Copy_Uses_Primary_Plain_Text;

   procedure Test_Rectangle_Delete_Removes_Per_Row
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
      R : Editor.Rectangle_Selection.Rectangle_Range;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
        (S, Paste ("abcd" & ASCII.LF & "efgh" & ASCII.LF & "ijkl"));

      R := Editor.Rectangle_Selection.Normalize
        (Anchor_Row => 0,
         Anchor_Col => 1,
         Cursor_Row => 2,
         Cursor_Col => 3);
      S.Rect_Select_Active := True;
      Editor.Rectangle_Selection.Build_Carets (S, R);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Delete (0));

      Assert (Text_Buffer.Length (S.Buffer) = 8,
              "Rectangle delete must remove two characters from each row");
      Assert (Text_Buffer.Element (S.Buffer, 1) = 'a', "row 1 left kept");
      Assert (Text_Buffer.Element (S.Buffer, 2) = 'd', "row 1 right kept");
      Assert (Text_Buffer.Element (S.Buffer, 4) = 'e', "row 2 left kept");
      Assert (Text_Buffer.Element (S.Buffer, 5) = 'h', "row 2 right kept");
      Assert (Text_Buffer.Element (S.Buffer, 7) = 'i', "row 3 left kept");
      Assert (Text_Buffer.Element (S.Buffer, 8) = 'l', "row 3 right kept");
   end Test_Rectangle_Delete_Removes_Per_Row;

   procedure Test_Phase68_Normalize_Rectangular_Range_Orders_Rows_Columns
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Rectangular_Range :=
        Normalize_Rectangular_Range
          ((Row => 7, Column => 9),
           (Row => 2, Column => 3));
   begin
      Assert (R.Start_Row = 2, "Phase 68 rectangle start row normalized");
      Assert (R.End_Row = 7, "Phase 68 rectangle end row normalized");
      Assert (R.Start_Column = 3, "Phase 68 rectangle start column normalized");
      Assert (R.End_Column = 9, "Phase 68 rectangle end column normalized");
      Assert (not R.Is_Empty, "Phase 68 reversed rectangle is non-empty");
   end Test_Phase68_Normalize_Rectangular_Range_Orders_Rows_Columns;

   procedure Test_Phase68_Normalize_Rectangular_Range_Zero_Width_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Rectangular_Range :=
        Normalize_Rectangular_Range
          ((Row => 1, Column => 4),
           (Row => 3, Column => 4));
   begin
      Assert (R.Start_Row = 1 and then R.End_Row = 3,
              "Phase 68 zero-width rectangle keeps row span");
      Assert (R.Start_Column = 4 and then R.End_Column = 4,
              "Phase 68 zero-width rectangle has half-open equal columns");
      Assert (R.Is_Empty, "Phase 68 zero-width rectangle is empty");
   end Test_Phase68_Normalize_Rectangular_Range_Zero_Width_Empty;

   procedure Test_Phase68_Normalize_Rectangular_Range_One_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : constant Rectangular_Range :=
        Normalize_Rectangular_Range
          ((Row => 0, Column => 5),
           (Row => 2, Column => 6));
   begin
      Assert (R.Start_Column = 5, "Phase 68 one-column start");
      Assert (R.End_Column = 6, "Phase 68 one-column half-open end");
      Assert (not R.Is_Empty, "Phase 68 one-column rectangle is non-empty");
   end Test_Phase68_Normalize_Rectangular_Range_One_Column;


   procedure Test_Phase66_Normalize_Text_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Text_Range;
   begin
      R := Normalize_Range
        ((Row => 3, Column => 4),
         (Row => 1, Column => 2));
      Assert
        (R.Start_Position.Row = 1 and then R.Start_Position.Column = 2,
         "Normalize_Range must order earlier position first");
      Assert
        (R.End_Position.Row = 3 and then R.End_Position.Column = 4,
         "Normalize_Range must preserve later position as end");
      Assert (not R.Is_Empty, "Non-equal positions must not be empty");

      R := Normalize_Range
        ((Row => 2, Column => 7),
         (Row => 2, Column => 7));
      Assert (R.Is_Empty, "Equal positions must produce an empty range");
      Assert
        (Is_Before ((Row => 2, Column => 3), (Row => 2, Column => 4)),
         "Is_Before must compare columns within a row");
      Assert
        (Is_Equal ((Row => 2, Column => 7), (Row => 2, Column => 7)),
         "Is_Equal must compare row and column");
   end Test_Phase66_Normalize_Text_Range;

   procedure Test_Phase66_Word_Range_At_Word_And_End_Edge
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello world");

      Target := Word_Range_At (S, 0, 1);
      Assert (Target.Found, "Word_Range_At must find a word from the middle");
      Assert
        (Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Column = 5,
         "Word_Range_At must select the whole word as [0, 5)");

      Target := Word_Range_At (S, 0, 5);
      Assert
        (not Target.Found,
         "Word_Range_At on whitespace must not select a word");

      Editor.State.Load_Text (S, "abc");
      Target := Word_Range_At (S, 0, 3);
      Assert (Target.Found, "End-of-line word edge must inspect the previous character");
      Assert
        (Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Column = 3,
         "End-of-line word edge must select [0, 3)");
   end Test_Phase66_Word_Range_At_Word_And_End_Edge;

   procedure Test_Phase66_Word_Range_At_Underscore_Digits_And_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "foo_bar9");
      Target := Word_Range_At (S, 0, 4);
      Assert (Target.Found, "Underscore and digits must be word characters");
      Assert
        (Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Column = 8,
         "foo_bar9 must select as one word run");

      Editor.State.Load_Text (S, "a == b");
      Target := Word_Range_At (S, 0, 2);
      Assert (Target.Found, "Symbol run must be selectable");
      Assert
        (Target.Selection_Range.Start_Position.Column = 2
         and then Target.Selection_Range.End_Position.Column = 4,
         "Contiguous symbol run must select as [2, 4)");
   end Test_Phase66_Word_Range_At_Underscore_Digits_And_Symbols;

   procedure Test_Phase66_Word_Range_Clamps_And_Stays_On_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Target := Word_Range_At (S, 99, 99);
      Assert (Target.Found, "Out-of-range position must clamp deterministically");
      Assert
        (Target.Selection_Range.Start_Position.Row = 1
         and then Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Row = 1
         and then Target.Selection_Range.End_Position.Column = 3,
         "Clamped range must select only the final line word");

      Target := Word_Range_At (S, 0, 3);
      Assert (Target.Found, "End of first line must inspect previous character");
      Assert
        (Target.Selection_Range.Start_Position.Row = 0
         and then Target.Selection_Range.End_Position.Row = 0,
         "Word_Range_At must not cross line boundaries");

      Editor.State.Load_Text (S, "");
      Target := Word_Range_At (S, 0, 0);
      Assert (not Target.Found, "Empty line/buffer must have no word target");
   end Test_Phase66_Word_Range_Clamps_And_Stays_On_Line;


   procedure Test_Phase67_Line_Range_Non_Last_Includes_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Editor.Selection.Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Target := Editor.Selection.Line_Range_At (S, 0);
      Assert (Target.Found, "Line range must be found for a valid row");
      Assert
        (Target.Selection_Range.Start_Position.Row = 0
         and then Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Row = 1
         and then Target.Selection_Range.End_Position.Column = 0,
         "Non-last line must select through next row column zero");
   end Test_Phase67_Line_Range_Non_Last_Includes_Newline;

   procedure Test_Phase67_Line_Range_Last_Ends_At_Line_Length
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Editor.Selection.Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "defg");

      Target := Editor.Selection.Line_Range_At (S, 1);
      Assert
        (Target.Selection_Range.Start_Position.Row = 1
         and then Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Row = 1
         and then Target.Selection_Range.End_Position.Column = 4,
         "Last line must select only through its line length");
   end Test_Phase67_Line_Range_Last_Ends_At_Line_Length;

   procedure Test_Phase67_Lines_Range_Normalizes_Reversed_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : Editor.Selection.Selection_Target;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc");

      Target := Editor.Selection.Lines_Range (S, 2, 0);
      Assert
        (Target.Selection_Range.Start_Position.Row = 0
         and then Target.Selection_Range.Start_Position.Column = 0
         and then Target.Selection_Range.End_Position.Row = 2
         and then Target.Selection_Range.End_Position.Column = 3,
         "Reversed line ranges must normalize and include the final line length");
   end Test_Phase67_Lines_Range_Normalizes_Reversed_Rows;

   procedure Test_Phase67_Executor_Select_Line_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "defg");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 5, Anchor => 5, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Select_Line;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 4
         and then S.Carets (S.Carets.First_Index).Pos = 8,
         "Select Line command must select the current last line boundaries");
      Assert
        (Text_Buffer.Length (S.Buffer) = 8,
         "Select Line command must not mutate text");
   end Test_Phase67_Executor_Select_Line_Command;


   procedure Test_Phase67_Extend_Line_Selection_Preserves_Direction
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "a" & ASCII.LF & "bb" & ASCII.LF & "ccc" & ASCII.LF & "dddd");

      Editor.Executor.Execute_Select_Line_At (S, 2);
      Editor.Executor.Execute_Extend_Selection_To_Line (S, 1);

      Assert
        (S.Carets (S.Carets.First_Index).Pos = Editor.State.Line_Start (S, 1),
         "Upward line extension must leave the cursor at the target line start");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = Editor.State.Line_Start (S, 3),
         "Upward line extension must anchor at the far line boundary");

      Editor.Executor.Execute_Select_Line_At (S, 1);
      Editor.Executor.Execute_Extend_Selection_To_Line (S, 3);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = Editor.State.Line_Start (S, 1),
         "Downward line extension must keep the anchor at the start boundary");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = Editor.State.Line_End (S, 3),
         "Downward line extension through the final line must end at final line length");
   end Test_Phase67_Extend_Line_Selection_Preserves_Direction;

   procedure Test_Phase66_Executor_Select_Word_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 2, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Select_Word;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0
         and then S.Carets (S.Carets.First_Index).Pos = 5,
         "Select Word command must select the primary caret word");
      Assert
        (Text_Buffer.Length (S.Buffer) = 10,
         "Select Word command must not mutate text");
   end Test_Phase66_Executor_Select_Word_Command;
   procedure Test_Phase209_Move_Left_Collapses_To_Selection_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left);

      Assert (S.Carets (0).Pos = 1,
              "Phase 209 Move_Left must collapse to selection start");
      Assert (S.Carets (0).Anchor = 1,
              "Phase 209 Move_Left must clear selection after collapse");
   end Test_Phase209_Move_Left_Collapses_To_Selection_Start;

   procedure Test_Phase209_Move_Right_Collapses_To_Selection_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc"));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Move_Right);

      Assert (S.Carets (0).Pos = 3,
              "Phase 209 Move_Right must collapse to selection end");
      Assert (S.Carets (0).Anchor = 3,
              "Phase 209 Move_Right must clear selection after collapse");
   end Test_Phase209_Move_Right_Collapses_To_Selection_End;

   procedure Test_Phase209_Move_Line_End_Collapses_To_Line_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "def"));

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 5,
            Anchor => 1,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Line_End;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Carets (0).Pos = 7,
              "Phase 209 Move_Line_End must collapse to the active line end");
      Assert (S.Carets (0).Anchor = 7,
              "Phase 209 Move_Line_End must clear selection after collapse");
   end Test_Phase209_Move_Line_End_Collapses_To_Line_End;

   procedure Test_Phase209_Shift_Down_Extends_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Paste ("abc" & ASCII.LF & "def"));

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 1,
            Anchor => 1,
            Virtual_Column => 0,
            Anchor_Virtual_Column => 0));
      S.Preferred_Column := 1;

      Cmd.Kind := Editor.Commands.Move_Down;
      Cmd.Shift := True;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Carets (0).Pos = 5,
              "Phase 209 Shift-Down must move caret to matching column on next line");
      Assert (S.Carets (0).Anchor = 1,
              "Phase 209 Shift-Down must preserve the original selection anchor");
   end Test_Phase209_Shift_Down_Extends_Selection;



   procedure Test_Phase541_Selection_Count_Helpers_Normalize_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");

      --  Reversed anchor/focus must be counted through the same normalized
      --  active selection range used by clipboard and render projection.
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 0, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Assert
        (Editor.Selection.Selected_Character_Count (S) = 4,
         "Phase 541 selected-character count must use normalized active range");
      Assert
        (Editor.Selection.Selected_Line_Count (S) = 1,
         "Phase 541 full first-line selection must count one logical line");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         (Pos => 0, Anchor => 5, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Assert
        (Editor.Selection.Selected_Line_Count (S) = 2,
         "Phase 541 partial second-line selection must count two logical lines");
   end Test_Phase541_Selection_Count_Helpers_Normalize_Range;


   procedure Test_Phase541_Selection_Count_Helpers_Ignore_Invalid_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'(Pos => 1, Anchor => 99, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Assert
        (Editor.Selection.Selected_Character_Count (S) = 0,
         "Phase 541 invalid selection must not expose selected-character count");
      Assert
        (Editor.Selection.Selected_Line_Count (S) = 0,
         "Phase 541 invalid selection must not expose selected-line count");
   end Test_Phase541_Selection_Count_Helpers_Ignore_Invalid_State;


   overriding procedure Register_Tests
     (T : in out Selection_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Selection_Command_Descriptors'Access,
         "Phase 377 Selection Command Descriptors");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Default_Keybinding_Select_All'Access,
         "Phase 377 Default Keybinding Select All");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Select_All_Command_Selects_Buffer_Without_Edit'Access,
         "Phase 377 Select All Command Selects Buffer Without Edit");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Select_All_Then_Copy_Uses_Canonical_Selection'Access,
         "Phase 377 Select All Then Copy Uses Canonical Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Clear_Selection_Command_Collapses_At_Caret'Access,
         "Phase 377 Clear Selection Command Collapses At Caret");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Current_Word_Selects_Strict_Ascii_Token'Access,
         "Phase 377 Current Word Selects Strict ASCII Token");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase377_Current_Word_Failure_Preserves_Selection'Access,
         "Phase 377 Current Word Failure Preserves Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Select_All_Empty_Buffer_Is_No_Op'Access,
         "Phase 378 Select All Empty Buffer Is No Op");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Current_Word_EOF_And_Punctuation_Boundaries'Access,
         "Phase 378 Current Word EOF And Punctuation Boundaries");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Invalid_Stale_Selection_Is_Not_Consumable'Access,
         "Phase 378 Invalid Stale Selection Is Not Consumable");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Clear_Selection_Preserves_Redo'Access,
         "Phase 378 Clear Selection Preserves Redo");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Select_All_Does_Not_Leak_Across_Buffers'Access,
         "Phase 378 Select All Does Not Leak Across Buffers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase378_Current_Word_Feeds_Find_From_Selection'Access,
         "Phase 378 Current Word Feeds Find From Selection");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Select_All_Current_Text_And_Clipboard_Workflow'Access,
         "Phase 379 Select All Current Text And Clipboard Workflow");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Select_All_Paste_Replace_And_No_Op_Preserves_Redo'Access,
         "Phase 379 Select All Paste Replace And No Op Preserves Redo");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Clear_Selection_Workflow_And_Caret_Insert'Access,
         "Phase 379 Clear Selection Workflow And Caret Insert");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Current_Word_Boundary_Matrix'Access,
         "Phase 379 Current Word Boundary Matrix");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Current_Word_Clipboard_Cut_Paste_Workflow'Access,
         "Phase 379 Current Word Clipboard Cut Paste Workflow");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Selection_Feeds_Find_And_Does_Not_Mutate_Replace'Access,
         "Phase 379 Selection Feeds Find And Does Not Mutate Replace");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Selection_With_Replace_And_Edit_Invalidation'Access,
         "Phase 379 Selection With Replace And Edit Invalidation");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Active_Buffer_Isolation_And_Reopen_Cleanup'Access,
         "Phase 379 Active Buffer Isolation And Reopen Cleanup");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Selection_Commands_Preserve_Redo_And_Navigation_History'Access,
         "Phase 379 Selection Commands Preserve Redo And Navigation History");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Availability_And_Palette_Are_Side_Effect_Free'Access,
         "Phase 379 Availability And Palette Are Side Effect Free");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase379_Non_Goal_Selection_Commands_Are_Not_Exposed'Access,
         "Phase 379 Non Goal Selection Commands Are Not Exposed");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase380_Command_Palette_Projects_Canonical_Selection_Only'Access,
         "Phase 380 Command Palette Projects Canonical Selection Only");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase380_Canonical_Selection_Validation_And_Extraction'Access,
         "Phase 380 Canonical Selection Validation And Extraction");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase380_Clipboard_And_Find_Consume_Canonical_Selection'Access,
         "Phase 380 Clipboard And Find Consume Canonical Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase380_Select_All_And_Current_Word_Use_Canonical_Helpers'Access,
         "Phase 380 Select All And Current Word Use Canonical Helpers");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase380_Secondary_And_Invalid_Ranges_Are_Not_Canonical'Access,
         "Phase 380 Secondary And Invalid Ranges Are Not Canonical");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Start_Selection'Access, "Start Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Extend_Selection'Access, "Extend Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reverse_Selection'Access, "Reverse Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Collapse_Selection'Access, "Collapse Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase209_Move_Left_Collapses_To_Selection_Start'Access,
         "Phase 209 Move Left Collapses To Selection Start");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase209_Move_Right_Collapses_To_Selection_End'Access,
         "Phase 209 Move Right Collapses To Selection End");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase209_Move_Line_End_Collapses_To_Line_End'Access,
         "Phase 209 Move Line End Collapses To Line End");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase209_Shift_Down_Extends_Selection'Access,
         "Phase 209 Shift Down Extends Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Selection_Insert'Access, "Replace Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Selection'Access, "Delete Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Selection'Access, "Undo Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rectangle_Selection_Creates_One_Caret_Per_Line'Access,
        "Rectangle Selection Creates One Caret Per Line");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rectangle_Insert_Replaces_Per_Line'Access,
        "Rectangle Insert Replaces Per Line");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rectangle_Paste_Per_Line'Access,
        "Rectangle Paste Per Line");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rectangle_Undo_Restores_All_Lines'Access,
        "Rectangle Undo Restores All Lines");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Virtual_Column_Paste'Access,
        "Virtual Column Paste");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Virtual_Column_Insert_Text_Input'Access,
        "Virtual Column Text Insert");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Multi_Caret_Virtual_Column_Insert_Text_Input'Access,
        "Multi Caret Virtual Column Text Insert Rejected");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Move_Right_Creates_Virtual_Column'Access,
        "Move Right Creates Virtual Column");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Move_Left_Leaves_Virtual_Column'Access,
        "Move Left Leaves Virtual Column");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Move_Down_Preserves_Virtual_Column'Access,
        "Move Down Preserves Virtual Column");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Move_Up_Preserves_Virtual_Column'Access,
        "Move Up Preserves Virtual Column");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Virtual_Selection_Extends'Access,
        "Virtual Selection Extends");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Rectangle_Normalize_Up_Left'Access,
        "Rectangle Normalize Up Left");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase373_Rectangle_Copy_Uses_Primary_Plain_Text'Access,
        "Phase 373 Rectangle Copy Uses Primary Plain Text");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Rectangle_Delete_Removes_Per_Row'Access,
        "Rectangle Delete Removes Per Row");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase68_Normalize_Rectangular_Range_Orders_Rows_Columns'Access,
        "Phase 68 Rectangular Source_Span Orders Rows Columns");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase68_Normalize_Rectangular_Range_Zero_Width_Empty'Access,
        "Phase 68 Rectangular Source_Span Zero Width Empty");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase68_Normalize_Rectangular_Range_One_Column'Access,
        "Phase 68 Rectangular Source_Span One Column");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase66_Normalize_Text_Range'Access,
        "Phase 66 Normalize Text Source_Span");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase66_Word_Range_At_Word_And_End_Edge'Access,
        "Phase 66 Word Source_Span Word And End Edge");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase66_Word_Range_At_Underscore_Digits_And_Symbols'Access,
        "Phase 66 Word Source_Span Underscore Digits Symbols");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase66_Word_Range_Clamps_And_Stays_On_Line'Access,
        "Phase 66 Word Source_Span Clamps And Line Boundary");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase66_Executor_Select_Word_Command'Access,
        "Phase 66 Executor Select Word Command");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase67_Line_Range_Non_Last_Includes_Newline'Access,
        "Phase 67 Line Source_Span Non Last Includes Newline");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase67_Line_Range_Last_Ends_At_Line_Length'Access,
        "Phase 67 Line Source_Span Last Ends At Length");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase67_Lines_Range_Normalizes_Reversed_Rows'Access,
        "Phase 67 Lines Source_Span Normalizes Reversed Rows");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase67_Executor_Select_Line_Command'Access,
        "Phase 67 Executor Select Line Command");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase67_Extend_Line_Selection_Preserves_Direction'Access,
        "Phase 67 Extend Line Selection Preserves Direction");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase541_Selection_Count_Helpers_Normalize_Range'Access,
        "Phase 541 Selection Count Helpers Normalize Source_Span");

      AUnit.Test_Cases.Registration.Register_Routine
         (T, Test_Phase541_Selection_Count_Helpers_Ignore_Invalid_State'Access,
        "Phase 541 Selection Count Helpers Ignore Invalid State");

   end Register_Tests;

end Editor.Selection.Tests;